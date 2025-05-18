defmodule FlashcardsWeb.FlashcardsComponent do
  use Phoenix.LiveComponent
  alias Flashcards.Flashcards
  alias Flashcards.Flashcard

  @page_size 5

  def mount(socket) do
    page = 1
    {flashcards, total_count} = paginated_flashcards(page, @page_size, socket.assigns)
    {:ok,
      assign(socket,
        flashcards: flashcards,
        page: page,
        total_count: total_count,
        page_size: @page_size
      )
    }
  end

  def update(assigns, socket) do
    page = assigns[:page] || 1
    {flashcards, total_count} = paginated_flashcards(page, @page_size, assigns)
    {:ok,
      socket
      |> assign(assigns)
      |> assign(:flashcards, flashcards)
      |> assign(:total_count, total_count)
      |> assign(:page, page)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="w-full max-w-2xl mx-auto mt-8">
      <h3 class="text-xl font-bold text-orange-600 mb-4">My Flashcards</h3>
      <%= if Enum.empty?(@flashcards) do %>
        <div class="text-gray-500">No flashcards found.</div>
      <% else %>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <%= for card <- @flashcards do %>
            <div class="rounded-lg shadow-lg bg-white p-6 border border-orange-100 flex flex-col gap-2 hover:shadow-2xl transition">
              <div class="flex items-center justify-between mb-2">
                <span class="text-xs bg-orange-100 text-orange-600 px-2 py-1 rounded font-semibold">Group: {card.group && card.group.name || "No Group"}</span>
                <span class="text-xs bg-blue-100 text-blue-600 px-2 py-1 rounded font-semibold">User: {card.created_by_user && card.created_by_user.email || "Unknown"}</span>
              </div>
              <div class="font-semibold text-lg text-zinc-700 mb-1">Q: {card.question}</div>
              <div class="text-md text-zinc-600">A: {card.answer}</div>
            </div>
          <% end %>
        </div>
        <div class="flex justify-between items-center mt-6">
          <button phx-click="prev_page" phx-target={@myself} class="px-4 py-2 rounded bg-orange-500 text-white font-semibold hover:bg-orange-600 transition disabled:opacity-50" disabled={@page == 1}>Prev</button>
          <span class="text-gray-600">Page {@page} of {max(1, ceil(@total_count / @page_size))}</span>
          <button phx-click="next_page" phx-target={@myself} class="px-4 py-2 rounded bg-orange-500 text-white font-semibold hover:bg-orange-600 transition disabled:opacity-50" disabled={@page * @page_size >= @total_count}>Next</button>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("prev_page", _params, socket) do
    page = max(socket.assigns.page - 1, 1)
    {flashcards, _} = paginated_flashcards(page, socket.assigns.page_size, socket.assigns)
    {:noreply, assign(socket, flashcards: flashcards, page: page)}
  end

  def handle_event("next_page", _params, socket) do
    max_page = ceil(socket.assigns.total_count / socket.assigns.page_size)
    page = min(socket.assigns.page + 1, max_page)
    {flashcards, _} = paginated_flashcards(page, socket.assigns.page_size, socket.assigns)
    {:noreply, assign(socket, flashcards: flashcards, page: page)}
  end

  defp paginated_flashcards(page, page_size, assigns) do
    query =
      Flashcards.Flashcard
      |> Ash.Query.new()
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.Query.load(:group)
      |> Ash.Query.load(:created_by_user)

    query =
      case Map.get(assigns, :current_user) do
        %{} = user -> Ash.Query.filter(query, created_by: user.id)
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
end
