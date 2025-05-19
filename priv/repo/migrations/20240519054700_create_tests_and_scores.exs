defmodule Flashcards.Repo.Migrations.CreateTestsAndScores do
  use Ecto.Migration

  def change do
    create table(:tests, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, :uuid, null: false
      add :group_id, :uuid
      add :know_count, :integer, null: false, default: 0
      add :dont_know_count, :integer, null: false, default: 0
      add :show_count, :integer, null: false, default: 0
      timestamps()
    end

    create table(:scores, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :card_id, :uuid, null: false
      add :know, :boolean, null: false, default: false
      add :dont_know, :boolean, null: false, default: false
      add :status, :string
      add :test_id, :uuid, null: false
      timestamps()
    end

    create index(:tests, [:user_id])
    create index(:tests, [:group_id])
    create index(:scores, [:test_id])
    create index(:scores, [:card_id])
  end
end
