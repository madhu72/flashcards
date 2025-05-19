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
     |> assign(:show_summary, false)}
  end

  def handle_event("toggle_play", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_play, !socket.assigns[:show_play])
     |> assign(:show_flashcards, false)
     |> assign(:show_summary, false)}
  end

  def handle_event("toggle_summary", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_summary, !(socket.assigns[:show_summary] || false))
     |> assign(:show_play, false)
     |> assign(:show_flashcards, false)}
  end

  def render(assigns) do
    flashcards = if is_list(assigns[:flashcards]), do: assigns[:flashcards], else: []
    groups = if is_list(assigns[:groups]), do: assigns[:groups], else: []

    quotes = [
      "Success is the sum of small efforts, repeated day in and day out.",
      "The secret of getting ahead is getting started.",
      "Don’t watch the clock; do what it does. Keep going.",
      "It always seems impossible until it’s done.",
      "Motivation is what gets you started. Habit is what keeps you going.",
      "Great things are done by a series of small things brought together.",
      "Perseverance is not a long race; it is many short races one after the other.",
      "You don’t have to be great to start, but you have to start to be great.",
      "The best way to get something done is to begin.",
      "Dream big and dare to fail.",
      "Opportunities don't happen, you create them.",
      "Don’t let yesterday take up too much of today.",
      "It does not matter how slowly you go as long as you do not stop.",
      "Quality is not an act, it is a habit.",
      "You are never too old to set another goal or to dream a new dream.",
      "Act as if what you do makes a difference. It does.",
      "Setting goals is the first step in turning the invisible into the visible.",
      "Start where you are. Use what you have. Do what you can.",
      "With the new day comes new strength and new thoughts.",
      "What you get by achieving your goals is not as important as what you become by achieving your goals.",
      "You don’t have to see the whole staircase, just take the first step.",
      "If you want to achieve greatness stop asking for permission.",
      "Push yourself, because no one else is going to do it for you.",
      "Sometimes we’re tested not to show our weaknesses, but to discover our strengths.",
      "The harder you work for something, the greater you’ll feel when you achieve it.",
      "Dream it. Wish it. Do it.",
      "Don’t stop when you’re tired. Stop when you’re done.",
      "Wake up with determination. Go to bed with satisfaction.",
      "Little things make big days.",
      "It’s going to be hard, but hard does not mean impossible.",
      "Don’t wait for opportunity. Create it.",
      "Sometimes later becomes never. Do it now.",
      "Great things never come from comfort zones.",
      "Success doesn’t just find you. You have to go out and get it.",
      "The key to success is to focus our conscious mind on things we desire not things we fear.",
      "Don’t be afraid to give up the good to go for the great.",
      "I find that the harder I work, the more luck I seem to have.",
      "If you are not willing to risk the usual, you will have to settle for the ordinary.",
      "Believe you can and you’re halfway there.",
      "Failure will never overtake me if my determination to succeed is strong enough.",
      "Only I can change my life. No one can do it for me.",
      "Good things come to people who wait, but better things come to those who go out and get them.",
      "Don’t watch the clock; do what it does. Keep going.",
      "A river cuts through rock not because of its power, but because of its persistence.",
      "Doubt kills more dreams than failure ever will.",
      "If you can dream it, you can do it.",
      "The only place where success comes before work is in the dictionary.",
      "You miss 100% of the shots you don’t take.",
      "If you want something you never had, you have to do something you’ve never done.",
      "Go the extra mile. It’s never crowded."
    ]

    quote = Enum.random(quotes)

    ~H"""
    <div class="min-h-screen flex flex-col items-center pt-10 bg-gradient-to-br from-blue-100 via-blue-300 to-blue-500">
      <div class="p-8 flex flex-col items-center text-center">
        <!-- Sticky/Flex Header -->
        <div class="w-full flex flex-col items-center pb-4 mb-6 sticky top-0 z-10">
          <h2 class="text-3xl font-bold text-blue-700 mt-2 mb-2">My Dashboard</h2>
          <% user_email = Map.get(assigns, :user_email) %>
          <p class="text-lg text-gray-700 mb-2">
            Welcome to your dashboard{if user_email, do: ", #{user_email}"}!
          </p>
          <div class="flex flex-col sm:flex-row justify-center gap-4">
            <a
              href="/flashcards/import"
              class="flex items-center gap-2 px-6 py-2 rounded bg-gray-200 text-gray-700 font-semibold shadow border-2 border-gray-300 hover:bg-gray-300 hover:border-gray-400 transition"
            >
              <svg
                class="w-5 h-5 text-gray-500"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                viewBox="0 0 24 24"
              >
                <path d="M12 4v12m0 0l-4-4m4 4l4-4" />
              </svg>
              Import
            </a>
            <button
              phx-click="toggle_flashcards"
              phx-target={@myself}
              class="flex items-center gap-2 px-6 py-2 rounded bg-orange-500 text-white font-bold shadow border-2 border-orange-500 hover:bg-orange-600 hover:border-orange-600 transition"
            >
              <svg
                class="w-5 h-5 text-white"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                viewBox="0 0 24 24"
              >
                <rect x="4" y="4" width="16" height="16" rx="2" /><path d="M8 8h8M8 12h8M8 16h4" />
              </svg>
              My Flashcards
            </button>
            <button
              phx-click="toggle_play"
              phx-target={@myself}
              class="flex items-center gap-2 px-6 py-2 rounded bg-blue-600 text-white font-bold shadow border-2 border-blue-600 hover:bg-blue-700 hover:border-blue-800 transition"
            >
              <svg
                class="w-5 h-5 text-white"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                viewBox="0 0 24 24"
              >
                <polygon points="5 3 19 12 5 21 5 3" />
              </svg>
              Play
            </button>
            <button
              phx-click="toggle_summary"
              phx-target={@myself}
              class="flex items-center gap-2 px-6 py-2 rounded bg-green-600 text-white font-bold shadow border-2 border-green-600 hover:bg-green-700 hover:border-green-800 transition"
            >
              <svg
                class="w-5 h-5 text-white"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                viewBox="0 0 24 24"
              >
                <path d="M4 17h16M4 13h16M4 9h16M4 5h16" />
              </svg>
              Summary
            </button>
          </div>
        </div>
        <!-- Motivational Quote -->
        <%= unless Map.get(assigns, :show_flashcards, false) or Map.get(assigns, :show_play, false) or Map.get(assigns, :show_summary, false) do %>
          <div class="mt-4 text-xl italic text-blue-900 bg-blue-100 rounded px-4 py-3 max-w-xl mx-auto shadow">
            {quote}
          </div>
        <% end %>
        <!-- Main Content -->
        <div class="w-full flex flex-col items-center mt-6">
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
            {live_render(@socket, FlashcardsWeb.SummaryLive,
              id: "summary-#{@user_id}",
              session: %{"user_id" => @user_id}
            )}
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
