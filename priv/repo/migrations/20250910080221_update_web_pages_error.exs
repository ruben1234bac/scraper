defmodule Scraper.Repo.Migrations.UpdateWebPagesError do
  use Ecto.Migration

  def change do
    alter table(:web_pages) do
      add :has_failed, :boolean, default: false
    end
  end
end
