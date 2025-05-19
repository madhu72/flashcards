defmodule FlashcardsWeb.AuthOverrides do
  @moduledoc """
  Use this module to override AshAuthentication Phoenix UI or behaviour.
  See https://hexdocs.pm/ash_authentication_phoenix/ui-overrides.html for details.
  """
  use AshAuthentication.Phoenix.Overrides

  # Redirect to home page on success
  def after_sign_in(conn, _user, _params) do
    Phoenix.Controller.redirect(conn, to: "/")
  end

  def after_registration(conn, _user, _params) do
    Phoenix.Controller.redirect(conn, to: "/")
  end

  def after_confirmation(conn, _user, _params) do
    Phoenix.Controller.redirect(conn, to: "/")
  end

  def after_failure(conn, _reason, _params) do
    conn
    |> Phoenix.Controller.put_flash(:error, "Authentication failed. Please try again.")
    |> Phoenix.Controller.redirect(to: "/")
  end

  override AshAuthentication.Phoenix.Components.Banner do
    set(:image_url, "/images/flashcards-logo.svg")
    set(:image_class, "block bg-no-repeat h-32 w-32")
  end

  # Override sign-in LiveView layout
  override AshAuthentication.Phoenix.SignInLive do
    set(
      :root_class,
      "min-h-screen min-w-full flex items-center justify-center bg-gradient-to-br from-orange-50 via-pink-100 to-yellow-100 px-4 py-8"
    )
  end

  override AshAuthentication.Phoenix.Components.SignIn do
    set(
      :root_class,
      "mx-auto min-h-192 min-w-128 flex items-center justify-center bg-white bg-opacity-90 rounded-3xl shadow-3xl p-10 md:p-16 flex-col gap-8 border border-orange-100 animate-fade-in"
    )

    set(:form_class, "flex flex-col gap-6")

    # set :button_class, "bg-orange-500 hover:bg-orange-600 text-white font-semibold py-3 rounded-lg shadow transition w-full mt-4"
    set(
      :input_class,
      "border border-orange-200 focus:border-orange-400 focus:ring-orange-100 rounded-lg px-4 py-3 text-zinc-700 bg-white placeholder-zinc-400 w-full"
    )

    set(:label_class, "font-semibold text-orange-600 mb-2 text-lg")
    set(:strategy_class, "mb-6")

    set(
      :authentication_error_container_class,
      "rounded-lg bg-red-50 border border-red-200 text-red-600 px-4 py-2 mb-4 text-center shadow"
    )

    set(:authentication_error_text_class, "text-red-700 font-semibold")
  end

  # Override register form layout
  override AshAuthentication.Phoenix.Components.Password.RegisterForm do
    set(
      :root_class,
      "mx-auto min-h-192 min-w-128 flex items-center justify-center bg-white bg-opacity-90 rounded-3xl shadow-3xl p-10 md:p-16 flex-col gap-8 border border-orange-100 animate-fade-in"
    )

    set(:form_class, "flex flex-col gap-6")

    # set :button_class, "bg-orange-500 hover:bg-orange-600 text-white font-semibold py-3 rounded-lg shadow transition w-full mt-4"
    set(
      :input_class,
      "border border-orange-200 focus:border-orange-400 focus:ring-orange-100 rounded-lg px-4 py-3 text-zinc-700 bg-white placeholder-zinc-400 w-full"
    )

    set(:label_class, "text-3xl font-extrabold text-orange-600 mb-6 text-center")
    set(:button_text, "Create Account")
    set(:disable_button_text, "Registering...")
  end
end
