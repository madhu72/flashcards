defmodule Flashcards.Flashcards do
  use Ash.Domain

  resources do
    resource Flashcards.Flashcards.Flashcard
    resource Flashcards.Flashcards.FlashcardGroup
    resource Flashcards.Accounts.User
    resource Flashcards.Flashcards.Test
    resource Flashcards.Flashcards.Score
  end

  alias Flashcards.Flashcards.Flashcard

  @doc """
  Import flashcards from a list of %{question, answer} maps.
  If overwrite is true, deletes all flashcards first.
  Returns {:ok, count} or {:error, reason}.
  """
  def import_flashcards(data, overwrite \\ false) when is_list(data) do
    if overwrite do
      # Delete all flashcards
      Flashcard |> Ash.Query.new() |> Ash.read!() |> Enum.each(&Ash.destroy!/1)
    end

    filtered =
      data
      |> Enum.filter(&is_map(&1) and Map.has_key?(&1, :question) and Map.has_key?(&1, :answer))
    IO.inspect(filtered, label: "FILTERED DATA TO IMPORT")

    imported =
      filtered
      |> Enum.map(fn card ->
        IO.inspect(card, label: "CARD TO CREATE")
        result = Ash.create(Flashcard, card)
        IO.inspect({card, result}, label: "CREATE RESULT")
        case result do
          {:ok, _card} -> :ok
          {:error, err} -> IO.inspect(err, label: "CREATE ERROR"); :error
        end
      end)

    {:ok, Enum.count(imported, & &1 == :ok)}
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Returns all flashcards, sorted by newest first.
  """
  def list_flashcards do
    Flashcards.Flashcards.Flashcard
    |> Ash.Query.new()
    |> Ash.Query.sort(:inserted_at, :desc)
    |> Ash.read!()
  end
end
