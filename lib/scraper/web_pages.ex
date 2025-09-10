defmodule Scraper.WebPages do
  @moduledoc """
  This module provides functions for web page management.
  """

  import Ecto.Query

  alias Scraper.Repo

  alias Scraper.WebPage.{
    WebPage,
    WebPageField
  }

  alias Scraper.Workers.Scraping

  @doc """
  Creates a new web page.

  ## Examples

      iex> create_web_page(%{url: "url", title: "title", user_id: 1})
      {:ok, %WebPage{}}

  """
  @spec create_web_page(map()) :: {:ok, WebPage.t()} | {:error, Ecto.Changeset.t()}
  def create_web_page(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:web_page, WebPage.changeset(%WebPage{}, attrs))
    |> Oban.insert("job-2", fn %{web_page: web_page} ->
      Scraping.new(%{web_page_id: web_page.id, url: web_page.url, user_id: web_page.user_id})
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a web page.

  ## Examples

      iex> update_web_page(1, %{url: "url", title: "title", user_id: 1})
      {:ok, %WebPage{}}

  """
  @spec update_web_page(integer(), map()) ::
          {:ok, WebPage.t()} | {:error, Ecto.Changeset.t() | :not_found}
  def update_web_page(id, attrs) do
    case Repo.get(WebPage, id) do
      nil ->
        {:error, :not_found}

      web_page ->
        web_page
        |> WebPage.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Gets a single web page.

  ## Examples

      iex> get_web_page!(1)
      %WebPage{}

  """
  @spec get_web_page!(integer()) :: WebPage.t() | nil
  def get_web_page!(id) do
    WebPage
    |> Repo.get!(id)
    |> Repo.preload(:web_page_fields)
  end

  @doc """
  Lists web pages.

  ## Examples

      iex> list_web_pages(1)
      %Scrivener.Page{entries: [%WebPage{}, ...]}

  """
  @spec list_web_pages(integer()) :: Scrivener.Page.t()
  def list_web_pages(page) do
    WebPage
    |> order_by(desc: :inserted_at)
    |> Repo.paginate(page: page)
  end

  @doc """
  Creates a new web page field.

  ## Examples

      iex> create_web_page_field(%{name: "name", value: "value", full_value: "full_value", web_page_id: 1})
      {:ok, %WebPageField{}}

  """
  @spec create_web_page_field(map()) :: {:ok, WebPageField.t()} | {:error, Ecto.Changeset.t()}
  def create_web_page_field(attrs) do
    %WebPageField{}
    |> WebPageField.changeset(attrs)
    |> Repo.insert()
  end
end
