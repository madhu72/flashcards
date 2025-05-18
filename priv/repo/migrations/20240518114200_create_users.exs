defmodule Flashcards.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :inserted_at, :naive_datetime_usec, null: false
      add :updated_at, :naive_datetime_usec, null: false
    end

    create unique_index(:users, [:email])
  end
end
