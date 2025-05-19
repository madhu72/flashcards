defmodule Flashcards.Flashcards.FlashcardGroup do
  use Ash.Resource,
    domain: Flashcards.Flashcards,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "flashcard_groups"
    repo Flashcards.Repo
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      primary? true
      accept [:name, :created_by]
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :created_by, :uuid, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :flashcards, Flashcards.Flashcards.Flashcard, destination_attribute: :group_id
  end
end
