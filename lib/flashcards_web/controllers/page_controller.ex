defmodule FlashcardsWeb.PageController do
  use FlashcardsWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: {FlashcardsWeb.Layouts, :app})
  end
end
