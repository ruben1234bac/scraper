defmodule Scraper.Repo do
  use Ecto.Repo,
    otp_app: :scraper,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end
