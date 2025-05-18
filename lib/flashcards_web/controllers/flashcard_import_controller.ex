defmodule FlashcardsWeb.FlashcardImportController do
  use FlashcardsWeb, :controller
  alias Flashcards.Flashcards

  def new(conn, _params) do
    flashcards = Flashcards.Flashcard |> Ash.Query.new() |> Ash.read!()
    render(conn, :new, flashcards: flashcards)
  end

  def create(conn, params) do
    IO.inspect(params, label: "IMPORT PARAMS")
    case params do
      %{"file" => %Plug.Upload{} = file, "overwrite" => overwrite} ->
        overwrite_flag = overwrite == "true"
        result = parse_and_import(file, overwrite_flag)
        IO.inspect(result, label: "IMPORT RESULT")
        flashcards = Flashcards.Flashcard |> Ash.Query.new() |> Ash.read!()
        case result do
          {:ok, count} ->
            conn
            |> put_flash(:info, "Successfully imported #{count} flashcards.")
            |> render(:new, flashcards: flashcards)
          {:error, reason} ->
            conn
            |> put_flash(:error, reason)
            |> render(:new, flashcards: flashcards)
        end
      %{ "file" => %Plug.Upload{} = file } ->
        result = parse_and_import(file, false)
        IO.inspect(result, label: "IMPORT RESULT")
        flashcards = Flashcards.Flashcard |> Ash.Query.new() |> Ash.read!()
        case result do
          {:ok, count} ->
            conn
            |> put_flash(:info, "Successfully imported #{count} flashcards.")
            |> render(:new, flashcards: flashcards)
          {:error, reason} ->
            conn
            |> put_flash(:error, reason)
            |> render(:new, flashcards: flashcards)
        end
      _ ->
        conn
        |> put_flash(:error, "Please select a JSON file to import.")
        |> redirect(to: ~p"/flashcards/import")
    end
  end

  defp parse_and_import(%Plug.Upload{path: path}, overwrite) do
    IO.inspect(path, label: "IMPORT FILE PATH")
    with {:ok, json} <- File.read(path),
         {:ok, data} <- Jason.decode(json),
         true <- is_list(data) do
      IO.inspect(data, label: "PARSED DATA")
      Flashcards.import_flashcards(Enum.map(data, fn %{"question" => q, "answer" => a} -> %{question: q, answer: a} end), overwrite)
    else
      error -> IO.inspect(error, label: "IMPORT ERROR"); {:error, "Invalid JSON format. Must be a list of %{question, answer}"}
    end
  end
end
