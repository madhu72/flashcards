defmodule FlashcardsWeb.PlayComponent do
  use Phoenix.LiveComponent
  require Ash.Query
  import Ash.Filter
  import Ash.Expr
  alias Flashcards.Flashcards.FlashcardGroup
  alias Flashcards.Flashcards.Flashcard

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign_new(:groups, fn -> [] end)
      |> assign_new(:flashcards, fn -> [] end)
      |> assign(:current_index, 0)
      |> assign(:show_answer, false)
      |> assign(:selected_group_id, nil)
      |> assign(:test_id, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    current_user = Map.get(assigns, :current_user) || Map.get(socket.assigns, :current_user)

    user_id =
      Map.get(assigns, :user_id) || Map.get(socket.assigns, :user_id) ||
        (current_user && current_user.id)

    groups =
      if user_id do
        FlashcardGroup
        |> Ash.Query.filter(created_by: user_id)
        |> Ash.Query.load([:id, :name])
        |> Ash.read!()
      else
        []
      end

    safe_groups =
      if is_list(groups) do
        Enum.map(groups, fn
          %_{} = struct -> %{id: Map.get(struct, :id), name: Map.get(struct, :name)}
          map when is_map(map) -> %{id: Map.get(map, :id), name: Map.get(map, :name)}
          _ -> nil
        end)
        |> Enum.filter(& &1)
      else
        []
      end

    selected_group_id = Map.get(assigns, :selected_group_id, socket.assigns[:selected_group_id])
    flashcards = fetch_flashcards(user_id, selected_group_id)
    # If test_id is not set, create a new Test resource for this play session
    test_id = socket.assigns[:test_id]

    test_id =
      if is_nil(test_id) and not is_nil(selected_group_id),
        do: create_test(user_id, selected_group_id),
        else: test_id

    socket =
      socket
      |> assign(assigns)
      |> assign(:groups, safe_groups)
      |> assign(:flashcards, flashcards)
      |> assign(:selected_group_id, selected_group_id)
      |> assign(:current_index, 0)
      |> assign(:show_answer, false)
      |> assign(:test_id, test_id)

    socket =
      if is_nil(selected_group_id) do
        assign(socket, :error_msg, "Please select a group to start a test.")
      else
        assign(socket, :error_msg, nil)
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("select_group", %{"group_id" => group_id}, socket) do
    user_id =
      socket.assigns[:user_id] ||
        (socket.assigns[:current_user] && socket.assigns[:current_user].id)

    group_id = if group_id == "", do: nil, else: group_id
    flashcards = fetch_flashcards(user_id, group_id)
    test_id = if group_id, do: create_test(user_id, group_id), else: nil

    socket =
      socket
      |> assign(:selected_group_id, group_id)
      |> assign(:flashcards, flashcards)
      |> assign(:current_index, 0)
      |> assign(:show_answer, false)
      |> assign(:test_id, test_id)

    socket =
      if is_nil(group_id) do
        assign(socket, :error_msg, "Please select a group to start a test.")
      else
        assign(socket, :error_msg, nil)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_answer", _params, socket) do
    {:noreply, assign(socket, :show_answer, true)}
  end

  @impl true
  def handle_event("know_card", _params, socket) do
    test_id = socket.assigns[:test_id]
    card = Enum.at(socket.assigns[:flashcards], socket.assigns[:current_index])
    IO.inspect(test_id, label: "KNOW_CARD TEST_ID")
    IO.inspect(card, label: "KNOW_CARD CARD")

    if test_id && card do
      create_score(test_id, card.id, true, false, "answered")
      increment_test_count(test_id, :know_count)
    end

    next_index = socket.assigns.current_index + 1
    {:noreply, assign(socket, current_index: next_index, show_answer: false)}
  end

  @impl true
  def handle_event("dont_know_card", _params, socket) do
    test_id = socket.assigns[:test_id]
    card = Enum.at(socket.assigns[:flashcards], socket.assigns[:current_index])
    IO.inspect(test_id, label: "DONT_KNOW_CARD TEST_ID")
    IO.inspect(card, label: "DONT_KNOW_CARD CARD")

    if test_id && card do
      create_score(test_id, card.id, false, true, "answered")
      increment_test_count(test_id, :dont_know_count)
    end

    next_index = socket.assigns.current_index + 1
    {:noreply, assign(socket, current_index: next_index, show_answer: false)}
  end

  @impl true
  def handle_event("restart_test", _params, socket) do
    user_id =
      socket.assigns[:user_id] ||
        (socket.assigns[:current_user] && socket.assigns[:current_user].id)

    group_id = socket.assigns[:selected_group_id]
    flashcards = fetch_flashcards(user_id, group_id)
    test_id = if group_id, do: create_test(user_id, group_id), else: nil

    {:noreply,
     socket
     |> assign(:test_id, test_id)
     |> assign(:flashcards, flashcards)
     |> assign(:current_index, 0)
     |> assign(:show_answer, false)}
  end

  def handle_event("show_answer", _params, socket) do
    test_id = socket.assigns[:test_id]
    card = Enum.at(socket.assigns[:flashcards], socket.assigns[:current_index])

    if test_id && card do
      increment_test_count(test_id, :show_count)
    end

    {:noreply, assign(socket, :show_answer, true)}
  end

  defp fetch_flashcards(_user_id, nil), do: []

  defp fetch_flashcards(user_id, group_id) do
    query =
      Flashcard
      |> Ash.Query.filter(expr(created_by == ^user_id and group_id == ^group_id))
      |> Ash.Query.sort(inserted_at: :desc)

    Ash.read!(query)
    |> Enum.map(fn card ->
      %{id: card.id, question: card.question, answer: card.answer, group_id: card.group_id}
    end)
  end

  defp create_test(_user_id, nil), do: nil

  defp create_test(user_id, group_id) do
    attrs = %{
      user_id: user_id,
      group_id: group_id,
      know_count: 0,
      dont_know_count: 0,
      show_count: 0
    }

    result =
      Flashcards.Flashcards.Test |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

    IO.inspect(result, label: "TEST CREATE RESULT")

    case result do
      {:ok, test} -> test.id
      _ -> nil
    end
  end

  defp create_score(test_id, card_id, know, dont_know, status) do
    attrs = %{
      test_id: test_id,
      card_id: card_id,
      know: know,
      dont_know: dont_know,
      status: status
    }

    result =
      Flashcards.Flashcards.Score |> Ash.Changeset.for_create(:create, attrs) |> Ash.create()

    IO.inspect(result, label: "SCORE CREATE RESULT")
    result
  end

  defp increment_test_count(test_id, field) do
    test = Flashcards.Flashcards.Test |> Ash.Query.filter(expr(id == ^test_id)) |> Ash.read_one!()

    if test do
      value = Map.get(test, field, 0) + 1
      Ash.Changeset.for_update(test, :update, %{field => value}) |> Ash.update()
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-md mx-auto mt-10 bg-white p-8 rounded-xl shadow-lg">
      <h2 class="text-2xl font-bold text-blue-700 mb-6 text-center">Play Flashcards</h2>
      <form phx-change="select_group" phx-target={@myself}>
        <label for="group_id" class="mr-2 text-sm text-gray-600">Group:</label>
        <select
          name="group_id"
          id="group_id"
          class="rounded border-gray-300 px-2 py-1 text-sm focus:ring-blue-400 focus:border-blue-400"
        >
          <option value="" disabled selected={is_nil(@selected_group_id) or @selected_group_id == ""}>
            Choose Group
          </option>
          <%= for group <- @groups || [], is_map(group) and Map.has_key?(group, :id) and Map.has_key?(group, :name) do %>
            <option value={group.id} selected={@selected_group_id == group.id}>{group.name}</option>
          <% end %>
        </select>
      </form>
      <%= if Enum.empty?(@flashcards) do %>
        <div class="text-gray-500 mt-8 text-center">No flashcards found for this group.</div>
      <% else %>
        <%= if is_nil(@selected_group_id) or @selected_group_id == "" do %>
          <div class="mt-8 text-center text-lg text-red-600 font-semibold">
            Please choose a group to start a session.
          </div>
        <% else %>
          <div class="mt-8 flex flex-col items-center">
            <%= if @current_index < length(@flashcards) do %>
              <% card = Enum.at(@flashcards, @current_index) %>
              <div class="mb-4 p-6 rounded-lg shadow bg-blue-50 w-full">
                <div class="text-lg font-semibold text-blue-800 mb-2">Question:</div>
                <div class="text-xl font-bold text-blue-900 mb-4">{card.question}</div>
                <%= if @show_answer do %>
                  <div class="text-base font-semibold text-green-800 mb-2">Answer:</div>
                  <div class="text-lg text-green-900 mb-4">{card.answer}</div>
                <% end %>
              </div>
              <div class="flex gap-4 mt-2">
                <button
                  phx-click="show_answer"
                  phx-target={@myself}
                  class="px-4 py-2 rounded bg-gray-400 text-white font-semibold hover:bg-gray-500 transition"
                  disabled={@show_answer}
                >
                  Show
                </button>
                <button
                  phx-click="know_card"
                  phx-target={@myself}
                  class="px-4 py-2 rounded bg-green-600 text-white font-semibold hover:bg-green-700 transition"
                >
                  Know
                </button>
                <button
                  phx-click="dont_know_card"
                  phx-target={@myself}
                  class="px-4 py-2 rounded bg-red-600 text-white font-semibold hover:bg-red-700 transition"
                >
                  Don't Know
                </button>
              </div>
              <div class="mt-4 text-sm text-gray-600">
                Card {@current_index + 1} of {length(@flashcards)}
              </div>
            <% else %>
              <div class="text-xl text-blue-700 font-bold mt-8 text-center">
                You finished all cards! 🎉
              </div>
              <%= if @test_id do %>
                <% test =
                  Flashcards.Flashcards.Test
                  |> Ash.Query.filter(expr(id == ^@test_id))
                  |> Ash.read_one!() %>
                <% total = test.know_count + test.dont_know_count %>
                <% percent_known =
                  if total > 0, do: Float.round(test.know_count / total * 100, 1), else: 0 %>
                <% percent_dont_know =
                  if total > 0, do: Float.round(test.dont_know_count / total * 100, 1), else: 0 %>
                <div class="mt-6 p-6 rounded-lg bg-green-50 shadow text-center">
                  <div class="text-lg font-semibold text-green-800 mb-2">Test Summary</div>
                  <div class="text-base text-green-900 mb-1">
                    Known: {test.know_count} ({percent_known}%)
                  </div>
                  <div class="text-base text-yellow-900 mb-1">
                    Don't Know: {test.dont_know_count} ({percent_dont_know}%)
                  </div>
                  <div class="text-base text-blue-900 mb-1">Show Answer: {test.show_count}</div>
                  <button
                    type="button"
                    phx-click="restart_test"
                    phx-target={@myself}
                    class="mt-4 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition"
                  >
                    Restart Session
                  </button>
                </div>
                <% dont_know_scores =
                  Flashcards.Flashcards.Score
                  |> Ash.Query.filter(expr(test_id == ^@test_id and dont_know == true))
                  |> Ash.read!() %>
                <% if Enum.any?(dont_know_scores) do %>
                  <div class="mt-8 p-6 rounded-lg bg-yellow-50 shadow">
                    <div class="text-lg font-semibold text-yellow-800 mb-2">Cards to Review</div>
                    <ul class="list-disc list-inside text-left">
                      <%= for score <- dont_know_scores do %>
                        <% card =
                          Flashcards.Flashcards.Flashcard
                          |> Ash.Query.filter(expr(id == ^score.card_id))
                          |> Ash.read_one!() %>
                        <li class="mb-2">
                          <span class="font-semibold text-blue-900">Q:</span> {card.question}<br />
                          <span class="font-semibold text-green-900">A:</span> {card.answer}
                        </li>
                      <% end %>
                    </ul>
                  </div>
                <% end %>
              <% end %>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
