defmodule Flashcards.Accounts do
  use Ash.Domain

  resources do
    resource Flashcards.Accounts.User
    resource Flashcards.Accounts.Token
  end
end
