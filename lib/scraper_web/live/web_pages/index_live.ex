defmodule ScraperWeb.WebPages.IndexLive do
  use ScraperWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Web Pages
    </.header>
    """
  end
end
