# Note: user_email is set via cookie for LiveView navigation and should be read from session in mount/3 for LiveViews.
defmodule FlashcardsWeb.LiveUserAuth do
  # Use fully qualified assign/3 to avoid import errors

  # Assigns user_email from session to LiveView assigns
  def on_mount(:assign_user_email, _params, session, socket) do
    user_email = Map.get(session, "user_email")
    {:cont, Phoenix.Component.assign(socket, :user_email, user_email)}
  end

  @moduledoc """
  Authentication helpers for LiveView sessions with AshAuthentication.
  """
  import Phoenix.LiveView
  alias AshAuthentication.Phoenix.LiveSession

  # Correct on_mount/4 signature for Phoenix LiveView
  def on_mount(:default, _params, session, socket) do
    LiveSession.on_mount(:default, _params, session, socket)
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    LiveSession.on_mount(:ensure_authenticated, _params, session, socket)
  end

  def on_mount(:maybe_authenticated, _params, session, socket) do
    LiveSession.on_mount(:maybe_authenticated, _params, session, socket)
  end

  # Fallback clause to avoid function clause errors
  def on_mount(_any, _params, _session, socket) do
    {:cont, socket}
  end
end
