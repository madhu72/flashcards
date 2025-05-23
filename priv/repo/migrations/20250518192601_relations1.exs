defmodule Flashcards.Repo.Migrations.Relations1 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    alter table(:flashcards) do
      modify :created_by,
             references(:users,
               column: :id,
               name: "flashcards_created_by_fkey",
               type: :uuid,
               prefix: "public"
             )
    end

    create index(:flashcards, [:created_by])
  end

  def down do
    drop_if_exists index(:flashcards, [:created_by])

    drop constraint(:flashcards, "flashcards_created_by_fkey")

    alter table(:flashcards) do
      modify :created_by, :uuid
    end
  end
end
