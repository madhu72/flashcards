defmodule Flashcards.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        Flashcards.Accounts.User,
        _opts,
        _context
      ) do
    Application.fetch_env(:flashcards, :token_signing_secret)
  end
end
