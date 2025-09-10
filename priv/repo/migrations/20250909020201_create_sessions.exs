defmodule Scraper.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :user_id, references(:users, on_delete: :nothing)
      add :session_token, :string
      add :last_active_at, :utc_datetime
      add :device_info, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:sessions, [:user_id, :session_token])
  end
end
