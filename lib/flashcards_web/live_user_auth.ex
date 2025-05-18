defmodule FlashcardsWeb.LiveUserAuth do
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
