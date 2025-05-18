defmodule FlashcardsWeb.FlashcardsLive do
  use Phoenix.LiveView, layout: {FlashcardsWeb.Layouts, :app}
  on_mount {FlashcardsWeb.LiveUserAuth, :maybe_authenticated}
  alias Flashcards.Flashcards
  alias Flashcards.Flashcards.Flashcard

  @impl true
  @page_size 5

  def mount(_params, _session, socket) do
    page = 1
    {flashcards, total_count} = paginated_flashcards(page, @page_size)
    {:ok,
      assign(socket,
        flashcards: flashcards,
        page: page,
        total_count: total_count,
        page_size: @page_size
      )
    }
  end

  @impl true

  defp paginated_flashcards(page, page_size) do
    query =
      Flashcards.Flashcard
      |> Ash.Query.new()
      |> Ash.Query.sort(inserted_at: :desc)

    total_count = Ash.count!(query)
    flashcards =
      query
      |> Ash.Query.offset((page - 1) * page_size)
      |> Ash.Query.limit(page_size)
      |> Ash.read!()
    {flashcards, total_count}
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
    <div class="w-screen h-screen flex flex-col">
      <!-- Header -->
      <header class="flex-none h-16 bg-blue-700 text-white flex items-center px-8 shadow z-10">
        <h1 class="text-2xl font-bold tracking-tight">Flashcards App</h1>
      </header>
      <div class="flex flex-1 overflow-hidden">
        <!-- Left Nav -->
        <nav class="flex-none w-48 bg-blue-50 border-r border-blue-100 flex flex-col items-center py-8">
          <div class="mb-6 font-semibold text-blue-700">Navigation</div>
          <ul class="space-y-4 w-full text-center">
            <li><a href="/flashcards" class="text-blue-700 hover:underline font-medium">All Flashcards</a></li>
            <li><a href="/flashcards/import" class="text-blue-700 hover:underline font-medium">Import</a></li>
          </ul>
        </nav>
        <!-- Main Content -->
        <main class="flex-1 flex flex-col items-center justify-center bg-gray-50 overflow-hidden">
          <div class="w-full max-w-2xl flex-1 flex flex-col">
            <h2 class="text-3xl font-bold mb-6 mt-6 text-blue-700 text-center">All Flashcards</h2>
            <div class="flex-1 overflow-y-auto rounded-xl shadow-lg bg-white p-6 mb-4" style="max-height: 60vh;">
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
              <span class="text-gray-700">Page <%= @page %> of <%= ceil(@total_count / @page_size) %></span>
              <button
                phx-click="next_page"
                class={"px-4 py-2 rounded font-semibold disabled:opacity-50 " <>
                  if @page * @page_size >= @total_count, do: "bg-blue-100 text-blue-400", else: "bg-blue-200 text-blue-900"}
                disabled={@page * @page_size >= @total_count}
              >Next</button>
            </div>
          </div>
        </main>
        <!-- Right Nav -->
        <aside class="flex-none w-48 bg-blue-50 border-l border-blue-100 flex flex-col items-center py-8">
          <div class="mb-6 font-semibold text-blue-700">Quick Links</div>
          <ul class="space-y-4 w-full text-center">
            <li><a href="https://hexdocs.pm/ash" class="text-blue-700 hover:underline font-medium" target="_blank">Ash Docs</a></li>
            <li><a href="https://hexdocs.pm/phoenix_live_view" class="text-blue-700 hover:underline font-medium" target="_blank">LiveView Docs</a></li>
          </ul>
        </aside>
      </div>
      <!-- Footer -->
      <footer class="flex-none h-12 bg-gray-100 border-t border-gray-200 flex items-center justify-center text-gray-500 text-sm">
        &copy; <%= Date.utc_today().year %> Flashcards App. All rights reserved.
      </footer>
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
