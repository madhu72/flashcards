defmodule FlashcardsWeb.SummaryLive do
  use Phoenix.LiveView
  alias Flashcards.Flashcards.Test

  def mount(_params, %{"user_id" => user_id}, socket) do
    tests = get_tests(user_id)
    {:ok, assign(socket, tests: tests, user_id: user_id)}
  end

  import Ash.Query
  import Ash.Filter
  import Ash.Expr

  defp get_tests(user_id) do
    Test
    |> filter(expr(user_id == ^user_id))
    |> sort(inserted_at: :desc)
    |> Ash.read!()
  end

  def render(assigns) do
    nonzero_tests = Enum.filter(assigns.tests, fn test ->
      (test.know_count > 0) or (test.dont_know_count > 0) or (test.show_count > 0)
    end)
    assigns = Map.put(assigns, :nonzero_tests, nonzero_tests)
    ~H"""
    <div class="mt-8 p-8 bg-white rounded-xl shadow">
      <h2 class="text-2xl font-bold text-green-700 mb-6 text-center">Test Summary Report</h2>
      <%= if Enum.empty?(@nonzero_tests) do %>
        <div class="text-gray-500 text-center">No tests found.</div>
      <% else %>
        <table class="min-w-full border text-left text-sm">
          <thead>
            <tr class="bg-green-100">
              <th class="py-2 px-4 border-b">Date</th>
              <th class="py-2 px-4 border-b">Group</th>
              <th class="py-2 px-4 border-b">Known</th>
              <th class="py-2 px-4 border-b">Don't Know</th>
              <th class="py-2 px-4 border-b">Show Answer</th>
            </tr>
          </thead>
          <tbody>
            <%= for test <- @nonzero_tests do %>
              <tr>
                <td class="py-2 px-4 border-b"><%= Timex.format!(test.inserted_at, "%Y-%m-%d %H:%M", :strftime) %></td>
                <td class="py-2 px-4 border-b"><%= test.group_id %></td>
                <td class="py-2 px-4 border-b text-green-800 font-bold"><%= test.know_count %></td>
                <td class="py-2 px-4 border-b text-yellow-800 font-bold"><%= test.dont_know_count %></td>
                <td class="py-2 px-4 border-b text-blue-800 font-bold"><%= test.show_count %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end
end
