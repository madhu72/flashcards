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
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    current_user = Map.get(assigns, :current_user) || Map.get(socket.assigns, :current_user)
    user_id = Map.get(assigns, :user_id) || Map.get(socket.assigns, :user_id) || (current_user && current_user.id)
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
    {:ok,
      socket
      |> assign(assigns)
      |> assign(:groups, safe_groups)
      |> assign(:flashcards, flashcards)
      |> assign(:selected_group_id, selected_group_id)
      |> assign(:current_index, 0)
      |> assign(:show_answer, false)
    }
  end

  @impl true
  def handle_event("select_group", %{"group_id" => group_id}, socket) do
    user_id = socket.assigns[:user_id] || (socket.assigns[:current_user] && socket.assigns[:current_user].id)
    group_id = if group_id == "", do: nil, else: group_id
    flashcards = fetch_flashcards(user_id, group_id)
    {:noreply,
      socket
      |> assign(:selected_group_id, group_id)
      |> assign(:flashcards, flashcards)
      |> assign(:current_index, 0)
      |> assign(:show_answer, false)
    }
  end

  @impl true
  def handle_event("show_answer", _params, socket) do
    {:noreply, assign(socket, :show_answer, true)}
  end

  @impl true
  def handle_event("know_card", _params, socket) do
    next_index = socket.assigns.current_index + 1
    {:noreply, assign(socket, current_index: next_index, show_answer: false)}
  end

  @impl true
  def handle_event("dont_know_card", _params, socket) do
    next_index = socket.assigns.current_index + 1
    {:noreply, assign(socket, current_index: next_index, show_answer: false)}
  end

  defp fetch_flashcards(user_id, group_id) do
    query =
      Flashcard
      |> Ash.Query.filter(expr(created_by == ^user_id))
      |> Ash.Query.sort(inserted_at: :desc)
    query =
      if group_id do
        Ash.Query.filter(query, expr(group_id == ^group_id))
      else
        query
      end
    Ash.read!(query)
    |> Enum.map(fn card -> %{id: card.id, question: card.question, answer: card.answer, group_id: card.group_id} end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-w-md mx-auto mt-10 bg-white p-8 rounded-xl shadow-lg">
      <h2 class="text-2xl font-bold text-blue-700 mb-6 text-center">Play Flashcards</h2>
      <form phx-change="select_group" phx-target={@myself}>
        <label for="group_id" class="mr-2 text-sm text-gray-600">Group:</label>
        <select name="group_id" id="group_id" class="rounded border-gray-300 px-2 py-1 text-sm focus:ring-blue-400 focus:border-blue-400">
          <option value="">All Groups</option>
          <%= for group <- @groups || [], is_map(group) and Map.has_key?(group, :id) and Map.has_key?(group, :name) do %>
            <option value={group.id} selected={@selected_group_id == group.id}><%= group.name %></option>
          <% end %>
        </select>
      </form>
      <%= if Enum.empty?(@flashcards) do %>
        <div class="text-gray-500 mt-8 text-center">No flashcards found for this group.</div>
      <% else %>
        <div class="mt-8 flex flex-col items-center">
          <%= if @current_index < length(@flashcards) do %>
            <% card = Enum.at(@flashcards, @current_index) %>
            <div class="mb-4 p-6 rounded-lg shadow bg-blue-50 w-full">
              <div class="text-lg font-semibold text-blue-800 mb-2">Question:</div>
              <div class="text-xl font-bold text-blue-900 mb-4"><%= card.question %></div>
              <%= if @show_answer do %>
                <div class="text-base font-semibold text-green-800 mb-2">Answer:</div>
                <div class="text-lg text-green-900 mb-4"><%= card.answer %></div>
              <% end %>
            </div>
            <div class="flex gap-4 mt-2">
              <button phx-click="show_answer" phx-target={@myself} class="px-4 py-2 rounded bg-gray-400 text-white font-semibold hover:bg-gray-500 transition" disabled={@show_answer}>Show</button>
              <button phx-click="know_card" phx-target={@myself} class="px-4 py-2 rounded bg-green-600 text-white font-semibold hover:bg-green-700 transition">Know</button>
              <button phx-click="dont_know_card" phx-target={@myself} class="px-4 py-2 rounded bg-red-600 text-white font-semibold hover:bg-red-700 transition">Don't Know</button>
            </div>
            <div class="mt-4 text-sm text-gray-600">Card <%= @current_index + 1 %> of <%= length(@flashcards) %></div>
          <% else %>
            <div class="text-xl text-blue-700 font-bold mt-8 text-center">You finished all cards! 🎉</div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
