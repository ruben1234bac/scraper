defmodule Scraper.Account.Guardian do
  @moduledoc false

  use Guardian, otp_app: :scraper

  alias Scraper.Accounts

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    user = Accounts.get_user!(id)
    {:ok, user}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
    Ecto.Query.CastError -> {:error, :resource_not_found}
    ArgumentError -> {:error, :resource_not_found}
  end
end
