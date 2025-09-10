defmodule Scraper.Account.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          username: String.t() | nil,
          password: String.t() | nil,
          is_active: boolean(),
          password_confirmation: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @required_fields ~w(username password)a
  @optional_fields ~w(is_active)a
  @virtual_fields ~w(password_confirmation)a

  schema "users" do
    field :username, :string
    field :password, :string
    field :is_active, :boolean, default: true
    field :password_confirmation, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.

  ## Examples

      iex> changeset(%User{}, %{username: "user", password: "password"})
      %Ecto.Changeset{data: %User{}}

  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields ++ @virtual_fields)
    |> validate_required(@required_fields)
    |> validate_length(:username, min: 3, max: 255)
    |> validate_length(:password, min: 8, max: 255)
    |> validate_confirmation(:password)
    |> unique_constraint(:username)
    |> put_password_hash()
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, password: Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset
end
