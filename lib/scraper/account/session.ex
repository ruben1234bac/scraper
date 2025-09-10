defmodule Scraper.Account.Session do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          user_id: integer() | nil,
          session_token: String.t() | nil,
          last_active_at: DateTime.t() | nil,
          device_info: map() | nil,
          user: Scraper.Account.User.t() | Ecto.Association.NotLoaded.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @required_fields ~w(user_id session_token)a
  @optional_fields ~w(device_info last_active_at)a

  schema "sessions" do
    field :session_token, :string
    field :last_active_at, :utc_datetime
    field :device_info, :map

    belongs_to :user, Scraper.Account.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.

  ## Examples

      iex> changeset(%Session{}, %{user_id: 1, session_token: "token"})
      %Ecto.Changeset{data: %Session{}}

  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(session, attrs) do
    session
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :session_token], name: :sessions_user_id_session_token_index)
  end
end
