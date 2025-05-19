defmodule FlashcardsWeb.MyDashboard do
  use Phoenix.LiveComponent
  import Phoenix.LiveView
  alias FlashcardsWeb.FlashcardsComponent
  on_mount {FlashcardsWeb.LiveUserAuth, :ensure_authenticated}

  def update(assigns, socket) do
    # Ensure user_id is always present in assigns for FlashcardsComponent
    user_id = Map.get(assigns, :user_id)
    socket =
      socket
      |> assign_new(:show_flashcards, fn -> false end)
      |> assign_new(:show_play, fn -> false end)
      |> assign(assigns)
      |> assign(:user_id, user_id)
    {:ok, socket}
  end

  def handle_event("toggle_flashcards", _params, socket) do
    {:noreply,
      socket
      |> assign(:show_flashcards, !socket.assigns[:show_flashcards])
      |> assign(:show_play, false)
      |> assign(:show_summary, false)
    }
  end

  def handle_event("toggle_play", _params, socket) do
    {:noreply,
      socket
      |> assign(:show_play, !socket.assigns[:show_play])
      |> assign(:show_flashcards, false)
      |> assign(:show_summary, false)
    }
  end

  def handle_event("toggle_summary", _params, socket) do
    {:noreply,
      socket
      |> assign(:show_summary, !(socket.assigns[:show_summary] || false))
      |> assign(:show_play, false)
      |> assign(:show_flashcards, false)
    }
  end

  def render(assigns) do
    flashcards = if is_list(assigns[:flashcards]), do: assigns[:flashcards], else: []
    groups = if is_list(assigns[:groups]), do: assigns[:groups], else: []
    ~H"""
    <div class="p-8 text-center">
      <h2 class="text-3xl font-bold text-blue-700 mb-4">My Dashboard</h2>
      <% user_email = Map.get(assigns, :user_email) %>
      <p class="text-lg text-gray-700">Welcome to your dashboard, <%= user_email || "Guest" %>!</p>
      <div class="mt-6 flex flex-col sm:flex-row justify-center gap-4">
        <a href="/flashcards/import"
          class="flex items-center gap-2 px-6 py-2 rounded bg-gray-200 text-gray-700 font-semibold shadow border-2 border-gray-300 hover:bg-gray-300 hover:border-gray-400 transition">
          <svg class="w-5 h-5 text-gray-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M12 4v12m0 0l-4-4m4 4l4-4"/></svg>
          Import
        </a>
        <button phx-click="toggle_flashcards" phx-target={@myself}
          class="flex items-center gap-2 px-6 py-2 rounded bg-orange-500 text-white font-bold shadow border-2 border-orange-500 hover:bg-orange-600 hover:border-orange-600 transition">
          <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="4" y="4" width="16" height="16" rx="2"/><path d="M8 8h8M8 12h8M8 16h4"/></svg>
          My Flashcards
        </button>
        <button phx-click="toggle_play" phx-target={@myself}
          class="flex items-center gap-2 px-6 py-2 rounded bg-blue-600 text-white font-bold shadow border-2 border-blue-600 hover:bg-blue-700 hover:border-blue-800 transition">
          <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polygon points="5 3 19 12 5 21 5 3"/></svg>
          Play
        </button>
        <button phx-click="toggle_summary" phx-target={@myself}
          class="flex items-center gap-2 px-6 py-2 rounded bg-green-600 text-white font-bold shadow border-2 border-green-600 hover:bg-green-700 hover:border-green-800 transition">
          <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M4 17h16M4 13h16M4 9h16M4 5h16"/></svg>
          Summary
        </button>
      </div>
      <%= if @show_flashcards do %>
        <.live_component
          module={FlashcardsComponent}
          id="inline-flashcards"
          current_user={@current_user}
          user_id={Map.get(assigns, :user_id)}
          flashcards={flashcards}
          groups={groups}
        />
      <% end %>
      <%= if assigns[:show_play] do %>
        <.live_component
          module={FlashcardsWeb.PlayComponent}
          id="inline-play"
          current_user={@current_user}
          user_id={Map.get(assigns, :user_id)}
          groups={groups}
        />
      <% end %>
      <%= if assigns[:show_summary] do %>
        <%= live_render(@socket, FlashcardsWeb.SummaryLive, id: "summary-#{@user_id}", session: %{"user_id" => @user_id}) %>
      <% end %>

    </div>
    """
  end
end
