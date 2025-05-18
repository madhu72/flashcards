defmodule FlashcardsWeb.DashboardLive do
  use Phoenix.LiveView, layout: {FlashcardsWeb.Layouts, :app}
  on_mount {FlashcardsWeb.LiveUserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, session, socket) do
    IO.inspect(session, label: "SESSION IN DASHBOARD MOUNT")
    IO.inspect(socket.assigns, label: "DASHBOARD SOCKET ASSIGNS")
    current_user = Map.get(socket.assigns, :current_user, nil)
    user_id = Map.get(session, "user_id") || (current_user && current_user.id)
    IO.inspect(user_id, label: "USER ID ASSIGNED TO SOCKET")
    socket =
      socket
      |> assign(current_user: current_user)
      |> assign_new(:current_user, fn -> current_user end)
      |> assign(user_id: user_id)
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={FlashcardsWeb.MyDashboard} id="my-dashboard" current_user={@current_user} user_email={@user_email} user_id={@user_id} />
    """
  end
end
