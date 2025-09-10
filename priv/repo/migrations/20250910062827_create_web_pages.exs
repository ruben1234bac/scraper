defmodule Scraper.Repo.Migrations.CreateWebPages do
  use Ecto.Migration

  def change do
    create table(:web_pages) do
      add :url, :string
      add :title, :string
      add :is_completed, :boolean, default: false
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end
  end
end
