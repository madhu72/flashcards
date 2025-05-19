defmodule Flashcards.Flashcards.Score do
  use Ash.Resource,
    domain: Flashcards.Flashcards,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "scores"
    repo Flashcards.Repo
  end

  actions do
    create :create do
      accept [:card_id, :know, :dont_know, :status, :test_id]
    end

    update :update do
      accept [:know, :dont_know, :status]
    end

    defaults [:read, :destroy]
  end

  attributes do
    uuid_primary_key :id
    attribute :card_id, :uuid, allow_nil?: false
    attribute :know, :boolean, allow_nil?: false, default: false
    attribute :dont_know, :boolean, allow_nil?: false, default: false
    attribute :status, :string
    attribute :test_id, :uuid, allow_nil?: false
    timestamps()
  end

  relationships do
    belongs_to :test, Flashcards.Flashcards.Test, source_attribute: :test_id
    belongs_to :card, Flashcards.Flashcards.Flashcard, source_attribute: :card_id
  end
end
