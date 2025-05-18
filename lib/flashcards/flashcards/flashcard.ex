defmodule Flashcards.Flashcards.Flashcard do
  use Ash.Resource,
    domain: Flashcards.Flashcards,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "flashcards"
    repo Flashcards.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :question, :string, allow_nil?: false
    attribute :answer, :string, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  actions do
    defaults [ :read]

    create :create do
      primary? true
      accept [:question, :answer]
    end
    update :update do
      primary? true
      accept [:question, :answer]
    end
    destroy :destroy do
      primary? true
    end
  end
end
