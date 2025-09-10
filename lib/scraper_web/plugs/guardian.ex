defmodule ScraperWeb.Plugs.Guardian do
  @moduledoc false

  use Guardian.Plug.Pipeline,
    otp_app: :scraper,
    module: Scraper.Account.Guardian,
    error_handler: Scraper.Account.SessionErrorHandler

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource
end
