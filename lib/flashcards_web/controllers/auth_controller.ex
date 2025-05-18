defmodule FlashcardsWeb.AuthController do
  use FlashcardsWeb, :controller
  use AshAuthentication.Phoenix.Controller

  def success(conn, activity, user, _token) do
    return_to = get_session(conn, :return_to) || ~p"/"

    message =
      case activity do
        {:confirm_new_user, :confirm} -> "Your email address has now been confirmed"
        {:password, :reset} -> "Your password has successfully been reset"
        _ -> "You are now signed in"
      end

    conn
    |> delete_session(:return_to)
    |> store_in_session(user)
    |> assign(:current_user, user)
    |> put_resp_cookie("user_email", user.email, sign: true)
    |> put_resp_cookie("user_email_display", to_string(user.email), sign: false, path: "/", http_only: false)
    |> put_flash(:info, message)
    |> put_flash(:set_user_email, user.email)
    |> redirect(to: return_to)
  end

  def failure(conn, activity, reason) do
    message =
      case {activity, reason} do
        {_,
         %AshAuthentication.Errors.AuthenticationFailed{
           caused_by: %Ash.Error.Forbidden{
             errors: [%AshAuthentication.Errors.CannotConfirmUnconfirmedUser{}]
           }
         }} ->
          """
          You have already signed in another way, but have not confirmed your account.
          You can confirm your account using the link we sent to you, or by resetting your password.
          """

        _ ->
          "Incorrect email or password"
      end

    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/sign-in")
  end

  def sign_out(conn, _params) do
    conn
    |> clear_session()
    |> put_resp_cookie("user_email", "", sign: true, max_age: 0)
    |> put_resp_cookie("user_email_display", "", max_age: 0)
    |> put_flash(:info, "You are now signed out")
    |> put_flash(:clear_user_email, true)
    |> redirect(to: "/")
  end
end
