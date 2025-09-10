defmodule Scraper.Accounts do
  @moduledoc """
   This module provides functions for user authentication and management.

  """

  import Ecto.Query

  alias Scraper.Account.{Session, User}

  alias Scraper.Repo

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{username: "user", password: "password123", password_confirmation: "password123"})
      {:ok, %User{}}

      iex> create_user(%{username: "user", password: "short", password_confirmation: ""})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_user() :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single user.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      nil

  """
  @spec get_user!(binary() | integer()) :: User.t() | nil
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a session.

  ## Examples

      iex> create_session(%{user_id: 123, session_token: "token"})
      {:ok, %Session{}}

      iex> create_session(%{user_id: 123, session_token: ""})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_session(map()) :: {:ok, Session.t()} | {:error, Ecto.Changeset.t()}
  def create_session(attrs) do
    %Session{}
    |> Session.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Authenticates the user with the given username and password.

  ## Examples

      iex> authenticate_user("testuser", "password123")
      {:ok, %User{}}

      iex> authenticate_user("testuser", "invalid_password")
      {:error, :invalid_credentials}

  """
  @spec authenticate_user(String.t(), String.t()) ::
          {:ok, User.t()} | {:error, :invalid_credentials}
  def authenticate_user(username, plain_text_password)
      when is_binary(username) and is_binary(plain_text_password) do
    query = from(u in User, where: u.username == ^username)

    case Repo.one(query) do
      nil ->
        {:error, :invalid_credentials}

      user ->
        validate_password(plain_text_password, user)
    end
  end

  def authenticate_user(_username, _plain_text_password) do
    {:error, :invalid_credentials}
  end

  defp validate_password(plain_text_password, user) do
    if Bcrypt.verify_pass(plain_text_password, user.password) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end
end
