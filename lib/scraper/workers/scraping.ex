defmodule Scraper.Workers.Scraping do
  use Oban.Worker, queue: :default

  require Logger

  alias Scraper.WebPages

  alias Phoenix.PubSub

  def perform(
        %Oban.Job{} = %{
          args: %{"web_page_id" => web_page_id, "url" => url, "user_id" => user_id},
          attempt: attempt
        }
      ) do
    PubSub.broadcast(
      Scraper.PubSub,
      "user:#{user_id}",
      {:starting_scraping, %{web_page_id: web_page_id, url: url, attempt: attempt}}
    )

    with {:ok, body} <- request_url(url),
         {:ok, links} <- get_links(body) do
      Enum.map(links, fn {[link], text} ->
        WebPages.create_web_page_field(%{name: text, value: link, web_page_id: web_page_id})
        :timer.sleep(500)
      end)

      WebPages.update_web_page(web_page_id, %{is_completed: true})

      PubSub.broadcast(
        Scraper.PubSub,
        "user:#{user_id}",
        {:scraping_completed, %{web_page_id: web_page_id, url: url, attempt: attempt}}
      )

      :ok
    else
      {:error, error} ->
        Logger.error("Error: #{inspect(error)}")

        WebPages.update_web_page(web_page_id, %{has_failed: true})

        PubSub.broadcast(
          Scraper.PubSub,
          "user:#{user_id}",
          {:scraping_failed, %{web_page_id: web_page_id, url: url, attempt: attempt}}
        )
    end
  end

  defp request_url(url) do
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, body}

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_links(body) do
    try do
      Floki.parse_document!(body)
      |> Floki.find("a")
      |> Enum.map(fn link ->
        {Floki.attribute(link, "href"), Floki.text(link)}
      end)
      |> then(&{:ok, &1})
    catch
      _, error -> {:error, "Error parsing document: #{inspect(error)}"}
    end
  end
end
