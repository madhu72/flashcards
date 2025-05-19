defmodule Flashcards.Flashcards.Test do
  use Ash.Resource,
    domain: Flashcards.Flashcards,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "tests"
    repo Flashcards.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :user_id, :uuid, allow_nil?: false
    attribute :group_id, :uuid, allow_nil?: false
    attribute :know_count, :integer, default: 0
    attribute :dont_know_count, :integer, default: 0
    attribute :show_count, :integer, default: 0
    timestamps()
  end

  relationships do
    has_many :scores, Flashcards.Flashcards.Score, destination_attribute: :test_id
  end

  actions do
    create :create do
      accept [:user_id, :group_id, :know_count, :dont_know_count, :show_count]
    end
    update :update do
      accept [:know_count, :dont_know_count, :show_count]
    end
    defaults [:read, :destroy]
  end
end
