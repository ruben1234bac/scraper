defmodule Scraper.Repo.Migrations.CreateWebPagesField do
  use Ecto.Migration

  def change do
    create table(:web_page_fields) do
      add :name, :string
      add :value, :string
      add :full_value, :string
      add :web_page_id, references(:web_pages, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end
  end
end
