defmodule FlashcardsWeb.FlashcardsLive do
  require Ash.Query
  import Ash.Filter
  import Ash.Expr
  use Phoenix.LiveView, layout: {FlashcardsWeb.Layouts, :app}
  on_mount {FlashcardsWeb.LiveUserAuth, :ensure_authenticated}
  alias Flashcards.Flashcards
  alias Flashcards.Flashcards.Flashcard

  @impl true
  @page_size 6

  def mount(_params, _session, socket) do
    page = 1
    {flashcards, total_count} = paginated_flashcards(page, @page_size)
    current_user = Map.get(socket.assigns, :current_user, nil)

    socket =
      socket
      |> assign(
        flashcards: flashcards,
        page: page,
        total_count: total_count,
        page_size: @page_size,
        current_user: current_user
      )
      |> assign_new(:current_user, fn -> current_user end)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    current_user = Map.get(socket.assigns, :current_user, nil)
    {:noreply, assign(socket, current_user: current_user)}
  end

  @impl true

  defp paginated_flashcards(page, page_size, assigns \\ %{}) do
    query =
      Flashcards.Flashcard
      |> Ash.Query.new()
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.Query.load(:group)
      |> Ash.Query.load(:created_by_user)

    # If current_user is present, filter by created_by
    query =
      case Map.get(assigns, :current_user) do
        %{} = user -> Ash.Query.filter(query, expr(created_by == ^user.id))
        _ -> query
      end

    total_count = Ash.count!(query)
    flashcards =
      query
      |> Ash.Query.offset((page - 1) * page_size)
      |> Ash.Query.limit(page_size)
      |> Ash.read!()
    {flashcards, total_count}
  end

  # Update mount/3 and handle_params/3 to use the new arity
  def mount(_params, session, socket) do
    page = 1
    {flashcards, total_count} = paginated_flashcards(page, @page_size, socket.assigns)
    current_user = Map.get(socket.assigns, :current_user, nil)
    user_email = Map.get(session, "user_email")

    socket =
      socket
      |> assign(
        flashcards: flashcards,
        page: page,
        total_count: total_count,
        page_size: @page_size,
        current_user: current_user,
        user_email: user_email
      )
      |> assign_new(:current_user, fn -> current_user end)

    {:ok, socket}
  end

  def handle_params(_params, _uri, socket) do
    current_user = Map.get(socket.assigns, :current_user, nil)
    page = socket.assigns.page || 1
    {flashcards, total_count} = paginated_flashcards(page, @page_size, Map.put(socket.assigns, :current_user, current_user))
    {:noreply, assign(socket, current_user: current_user, flashcards: flashcards, total_count: total_count)}
  end

  defp parse_and_import(%Plug.Upload{path: path}, true = _overwrite) do
    # Overwrite: delete all, then import
    :ok = Ash.Resource.destroy_all!(Flashcard)
    parse_and_import(%Plug.Upload{path: path}, false)
  end
  defp parse_and_import(%Plug.Upload{path: path}, false) do
    with {:ok, json} <- File.read(path),
         {:ok, data} <- Jason.decode(json),
         true <- is_list(data) do
      count =
        data
        |> Enum.filter(&is_map(&1) and Map.has_key?(&1, "question") and Map.has_key?(&1, "answer"))
        |> Enum.map(fn %{"question" => q, "answer" => a} ->
          Flashcards.Flashcard |> Ash.Changeset.for_create(:create, %{question: q, answer: a}) |> Ash.create!()
        end)
        |> length()
      {:ok, count}
    else
      _ -> {:error, "Invalid JSON format. Must be a list of %{question, answer}"}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col items-center pt-10 bg-gradient-to-br from-blue-100 via-blue-300 to-blue-500">
      <main class="w-full max-w-2xl flex flex-col items-center justify-center flex-1">
        <div class="w-full flex justify-start mb-2">
          <.link patch="/dashboard" class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition">
            ← Back to Dashboard
          </.link>
        </div>
        <h2 class="text-3xl font-bold mb-6 mt-6 text-blue-700 text-center">All Flashcards</h2>
        <div class="flex-1 overflow-y-auto rounded-xl shadow-lg bg-white p-6 mb-4 w-full" style="max-height: 60vh;">
          <ul class="divide-y divide-gray-200">
                <%= for card <- @flashcards do %>
                  <li class="my-6">
                    <div
                      id={if card.id, do: "flashcard-#{card.id}"}
                      class={"rounded-xl shadow p-4 bg-gradient-to-br from-blue-50 to-blue-100 border border-blue-200"}
                    >
                      <div class="text-base font-semibold text-blue-800 mb-2">Question</div>
                      <div class="text-xl font-bold text-blue-900 mb-4"> <%= card.question %> </div>
                      <div class="text-base font-semibold text-green-800 mb-2">Answer</div>
                      <div class="text-lg font-medium text-green-900"> <%= card.answer %> </div>
                      <div class="text-sm text-gray-700 mt-2">
                        <span class="font-semibold">Group:</span>
                        <%= if card.group && card.group.name, do: card.group.name, else: "-" %>
                        &nbsp;|&nbsp;
                        <span class="font-semibold">Imported by:</span>
                        <%= if card.created_by_user && card.created_by_user.email do %>
                          <%= card.created_by_user.email %>
                        <% else %>
                          -
                        <% end %>
                      </div>
                    </div>
                  </li>
                <% end %>
                <%= if Enum.empty?(@flashcards) do %>
                  <li class="py-4 text-gray-400 italic text-center">No flashcards found.</li>
                <% end %>
              </ul>
            </div>
            <div class="flex justify-between items-center mt-2 mb-4 px-2">
              <button
                phx-click="prev_page"
                class={"px-4 py-2 rounded font-semibold disabled:opacity-50 " <>
                  if @page == 1, do: "bg-blue-100 text-blue-400", else: "bg-blue-200 text-blue-900"}
                disabled={@page == 1}
              >Prev</button>
              <span class="text-gray-700 px-2">Page <%= @page %> of <%= ceil(@total_count / @page_size) %></span>
              <button
                phx-click="next_page"
                class={"px-4 py-2 rounded font-semibold disabled:opacity-50 " <>
                  if @page * @page_size >= @total_count, do: "bg-blue-100 text-blue-400", else: "bg-blue-200 text-blue-900"}
                disabled={@page * @page_size >= @total_count}
              >Next</button>
            </div>
        </main>
      </div>
    """
  end

  @impl true
  def handle_event("prev_page", _params, socket) do
    page = max(socket.assigns.page - 1, 1)
    {flashcards, _} = paginated_flashcards(page, socket.assigns.page_size)
    {:noreply, assign(socket, flashcards: flashcards, page: page)}
  end

  @impl true
  def handle_event("next_page", _params, socket) do
    max_page = ceil(socket.assigns.total_count / socket.assigns.page_size)
    page = min(socket.assigns.page + 1, max_page)
    {flashcards, _} = paginated_flashcards(page, socket.assigns.page_size)
    {:noreply, assign(socket, flashcards: flashcards, page: page)}
  end
end
