defmodule Scraper.Repo.Migrations.UpdateSessionsTokenSize do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      modify(:session_token, :text)
    end
  end
end
