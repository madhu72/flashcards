defmodule FlashcardsWeb.FlashcardsComponent do
  use Phoenix.LiveComponent
  require Ash.Query
  alias Flashcards.Flashcards
  alias Flashcards.Flashcard
  alias Flashcards.FlashcardGroup

  @page_size 6

  # Ensure groups and flashcards are always lists on first render
  def mount(socket) do
    socket =
      socket
      |> assign_new(:groups, fn -> [] end)
      |> assign_new(:flashcards, fn -> [] end)
      |> assign(:page_size, @page_size)

    {:ok, socket}
  end

  def update(assigns, socket) do
    IO.inspect(assigns, label: "FLASHCARDS COMPONENT ASSIGNS (update)")
    page = assigns[:page] || 1
    current_user = Map.get(assigns, :current_user) || Map.get(socket.assigns, :current_user)

    user_id =
      Map.get(assigns, :user_id) || Map.get(socket.assigns, :user_id) ||
        (current_user && current_user.id)

    IO.inspect(current_user, label: "CURRENT USER (update)")
    IO.inspect(user_id, label: "USER ID USED FOR GROUPS (update)")

    groups =
      if user_id do
        FlashcardGroup
        |> Ash.Query.filter(created_by: user_id)
        |> Ash.Query.load([:id, :name, :created_by, :inserted_at, :updated_at])
        |> Ash.read!()
      else
        []
      end

    IO.inspect(groups, label: "GROUPS BEFORE SAFE GROUPS")
    IO.inspect(is_list(groups), label: "IS GROUPS A LIST?")

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

    IO.inspect(safe_groups, label: "SAFE GROUPS ASSIGNED TO TEMPLATE (final)")
    selected_group_id = Map.get(assigns, :selected_group_id, socket.assigns[:selected_group_id])
    # Ensure selected_group_id is always in assigns for correct dropdown state
    assigns = Map.put(assigns, :selected_group_id, selected_group_id)

    {flashcards, total_count} =
      paginated_flashcards(
        page,
        @page_size,
        Map.merge(assigns, %{groups: groups, selected_group_id: selected_group_id})
      )

    safe_flashcards = flashcards

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:groups, safe_groups)
     |> assign(:flashcards, safe_flashcards)
     |> assign(:total_count, total_count)
     |> assign(:page, page)
     |> assign(:page_size, @page_size)}
  end

  def handle_event("select_group", %{"group_id" => group_id}, socket) do
    selected_group_id = if group_id == "", do: nil, else: group_id
    page = 1
    assigns = Map.put(socket.assigns, :selected_group_id, selected_group_id)
    {flashcards, total_count} = paginated_flashcards(page, socket.assigns.page_size, assigns)

    {:noreply,
     socket
     |> assign(:selected_group_id, selected_group_id)
     |> assign(:page, page)
     |> assign(:flashcards, (is_list(flashcards) && flashcards) || [])
     |> assign(:total_count, total_count)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="w-full max-w-2xl mx-auto mt-8">
        <h3 class="text-xl font-bold text-orange-600 mb-4">My Flashcards</h3>
        <div class="mb-4 flex items-center gap-2">
          <form phx-change="select_group" phx-target={@myself}>
            <label for="group_id" class="mr-2 text-sm text-gray-600">Group:</label>
            <select
              name="group_id"
              id="group_id"
              class="rounded border-gray-300 px-2 py-1 text-sm focus:ring-orange-400 focus:border-orange-400"
            >
              <option value="">All Groups</option>
              <%= for group <- (@groups || []), is_map(group) and Map.has_key?(group, :id) and Map.has_key?(group, :name) do %>
                <option value={group.id} selected={@selected_group_id == group.id}>
                  {group.name}
                </option>
              <% end %>
            </select>
          </form>
        </div>
        <%= if @flashcards == nil or @flashcards == [] do %>
          <div class="text-gray-500">No flashcards found.</div>
        <% else %>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 h-96 overflow-y-auto">
            <%= for card <- (@flashcards || []), is_map(card) and Map.has_key?(card, :question) and Map.has_key?(card, :answer) do %>
              <div class="rounded-lg shadow-lg bg-white p-6 border border-orange-100 flex flex-col gap-2 hover:shadow-2xl transition">
                <div class="flex items-center justify-between mb-2">
                  <span class="text-xs bg-orange-100 text-orange-600 px-2 py-1 rounded font-semibold">
                    Group: {(card.group && card.group.name) || "No Group"}
                  </span>
                  <span class="text-xs bg-blue-100 text-blue-600 px-2 py-1 rounded font-semibold">
                    User: {(card.created_by_user && card.created_by_user.email) || "Unknown"}
                  </span>
                </div>
                <div class="font-semibold text-lg text-zinc-700 mb-1">Q: {card.question}</div>
                <div class="text-md text-zinc-600">A: {card.answer}</div>
              </div>
            <% end %>
          </div>
          <div class="flex justify-between items-center mt-6">
            <button
              phx-click="prev_page"
              phx-target={@myself}
              class="px-4 py-2 rounded bg-orange-500 text-white font-semibold hover:bg-orange-600 transition disabled:opacity-50"
              disabled={@page == 1}
            >
              Prev
            </button>
            <span class="text-gray-600">
              Page {@page} of {max(1, ceil(@total_count / @page_size))}
            </span>
            <button
              phx-click="next_page"
              phx-target={@myself}
              class="px-4 py-2 rounded bg-orange-500 text-white font-semibold hover:bg-orange-600 transition disabled:opacity-50"
              disabled={@page * @page_size >= @total_count}
            >
              Next
            </button>
          </div>
        <% end %>
      </div>
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

    query =
      case Map.get(assigns, :selected_group_id) do
        nil -> query
        group_id -> Ash.Query.filter(query, group_id: group_id)
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
