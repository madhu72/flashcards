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
    attribute :created_by, :uuid, allow_nil?: false
    attribute :group_id, :uuid, allow_nil?: false
    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :group, Flashcards.Flashcards.FlashcardGroup, source_attribute: :group_id
    belongs_to :created_by_user, Flashcards.Accounts.User, source_attribute: :created_by, allow_nil?: true
  end

  actions do
    defaults [ :read]

    create :create do
      primary? true
      accept [:question, :answer, :created_by, :group_id]
    end
    update :update do
      primary? true
      accept [:question, :answer, :created_by, :group_id]
    end
    destroy :destroy do
      primary? true
    end
  end
end
