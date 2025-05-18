defmodule FlashcardsWeb.FlashcardImportController do
  use FlashcardsWeb, :controller
  alias Flashcards.Flashcards

  def new(conn, _params) do
    if conn.assigns[:current_user] do
      user_email = conn.cookies["user_email"]
      flashcards = Flashcards.Flashcard |> Ash.Query.new() |> Ash.read!()
      render(conn, :new, flashcards: flashcards, user_email: user_email)
    else
      conn
      |> Phoenix.Controller.redirect(to: "/sign-in")
      |> Plug.Conn.halt()
    end
  end

  def create(conn, params) do
    if conn.assigns[:current_user] do
      IO.inspect(params, label: "IMPORT PARAMS")
      current_user = Map.get(conn.assigns, :current_user)
      user_id = if current_user, do: current_user.id, else: nil
      group_name = Map.get(params, "group_name", "")
      file = params["file"]
      overwrite_flag = params["overwrite"] == "true"

      cond do
        !user_id ->
          conn |> put_flash(:error, "You must be signed in to import flashcards.") |> redirect(to: ~p"/flashcards/import")
        !file ->
          conn |> put_flash(:error, "Please select a JSON file to import.") |> redirect(to: ~p"/flashcards/import")
        group_name == "" ->
          conn |> put_flash(:error, "Please provide a group name.") |> redirect(to: ~p"/flashcards/import")
        true ->
          # Create the group
          group_result =
            Flashcards.FlashcardGroup
            |> Ash.Changeset.for_create(:create, %{name: group_name, created_by: user_id})
            |> Ash.create()

          case group_result do
            {:ok, group} ->
              # Parse and import flashcards, assigning group_id and created_by
              result = parse_and_import(file, overwrite_flag, group.id, user_id)
              flashcards = Flashcards.Flashcard |> Ash.Query.new() |> Ash.read!()
              case result do
                {:ok, count} ->
                  user_email = conn.cookies["user_email"]
                  conn
                  |> put_flash(:info, "Successfully imported #{count} flashcards to group '#{group_name}'.")
                  |> render(:new, flashcards: flashcards, user_email: user_email)
                {:error, reason} ->
                  conn
                  |> put_flash(:error, reason)
                  |> render(:new, flashcards: flashcards)
              end
            {:error, reason} ->
              IO.inspect(reason, label: "GROUP CREATION ERROR")
              conn |> put_flash(:error, "Failed to create group: #{inspect(reason)}") |> redirect(to: ~p"/flashcards/import")
          end
      end
    else
      conn
      |> Phoenix.Controller.redirect(to: "/sign-in")
      |> Plug.Conn.halt()
    end
  end

  defp parse_and_import(%Plug.Upload{path: path}, overwrite, group_id, user_id) do
    IO.inspect(path, label: "IMPORT FILE PATH")
    with {:ok, json} <- File.read(path),
         {:ok, data} <- Jason.decode(json),
         true <- is_list(data) do
      IO.inspect(data, label: "PARSED DATA")
      # Add group_id and created_by to each flashcard
      flashcards = Enum.map(data, fn %{"question" => q, "answer" => a} ->
        %{question: q, answer: a, group_id: group_id, created_by: user_id}
      end)
      # Ensure all keys are atoms
      flashcards = Enum.map(flashcards, & (for {k, v} <- &1, into: %{}, do: {k, v}))
      Flashcards.import_flashcards(flashcards, overwrite)
    else
      error -> IO.inspect(error, label: "IMPORT ERROR"); {:error, "Invalid JSON format. Must be a list of %{question, answer}"}
    end
  end
end
