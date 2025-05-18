defmodule FlashcardsWeb.MyDashboard do
  use Phoenix.LiveComponent
  on_mount {FlashcardsWeb.LiveUserAuth, :ensure_authenticated}
  # You can expand this with more props as needed
  def render(assigns) do
    ~H"""
    <div class="p-8 text-center">
      <h2 class="text-3xl font-bold text-blue-700 mb-4">My Dashboard</h2>
      <% user_email = Map.get(assigns, :user_email) %>
      <p class="text-lg text-gray-700">Welcome to your dashboard, <%= user_email || "Guest" %>!</p>
      <div class="mt-8">
        <!-- Add dashboard widgets and stats here -->
        <span class="text-gray-500">(Dashboard content coming soon!)</span>
      </div>
    </div>
    """
  end
end
