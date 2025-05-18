defmodule FlashcardsWeb.DashboardLive do
  use Phoenix.LiveView, layout: {FlashcardsWeb.Layouts, :app}
  on_mount {FlashcardsWeb.LiveUserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = Map.get(socket.assigns, :current_user, nil)
    socket =
      socket
      |> assign(current_user: current_user)
      |> assign_new(:current_user, fn -> current_user end)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={FlashcardsWeb.MyDashboard} id="my-dashboard" current_user={@current_user} user_email={@user_email} />
    """
  end
end
