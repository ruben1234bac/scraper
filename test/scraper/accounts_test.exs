defmodule Scraper.AccountsTest do
  use Scraper.DataCase, async: true

  alias Scraper.Account.{Session, User}
  alias Scraper.Accounts

  describe "create_session/1" do
    test "creates session with valid attributes" do
      user = insert(:user)

      attrs = %{
        user_id: user.id,
        session_token: "session_token"
      }

      assert {:ok, %Session{} = session} = Accounts.create_session(attrs)
      assert session.user_id == user.id
      assert session.session_token == "session_token"
      assert session.id
      assert session.inserted_at
      assert session.updated_at
    end

    test "return error when params is empty" do
      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_session(%{})
      assert "can't be blank" in errors_on(changeset).user_id
      assert "can't be blank" in errors_on(changeset).session_token
    end
  end

  describe "create_user/0" do
    test "return error when params is empty" do
      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user()
      assert "can't be blank" in errors_on(changeset).username
      assert "can't be blank" in errors_on(changeset).password
    end
  end

  describe "create_user/1" do
    test "creates user with valid attributes" do
      attrs = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      }

      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.username == "testuser"
      assert user.is_active == true
      assert String.starts_with?(user.password, "$2b$")
      assert user.id
      assert user.inserted_at
      assert user.updated_at
    end

    test "creates user with optional is_active field" do
      attrs = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123",
        is_active: false
      }

      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.username == "testuser"
      assert user.is_active == false
    end

    test "creates user with default empty attributes" do
      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user()

      assert "can't be blank" in errors_on(changeset).username
      assert "can't be blank" in errors_on(changeset).password
    end

    test "returns error when username is missing" do
      attrs = %{
        password: "password123",
        password_confirmation: "password123"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(attrs)
      assert "can't be blank" in errors_on(changeset).username
    end

    test "returns error when password is missing" do
      attrs = %{
        username: "testuser",
        password_confirmation: "password123"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(attrs)
      assert "can't be blank" in errors_on(changeset).password
    end

    test "returns error when password confirmation doesn't match" do
      attrs = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "different"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(attrs)
      assert "does not match confirmation" in errors_on(changeset).password_confirmation
    end

    test "returns error when username is too short" do
      attrs = %{
        username: "ab",
        password: "password123",
        password_confirmation: "password123"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(attrs)
      assert "should be at least 3 character(s)" in errors_on(changeset).username
    end

    test "returns error when password is too short" do
      attrs = %{
        username: "testuser",
        password: "1234567",
        password_confirmation: "1234567"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(attrs)
      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end

    test "returns error when username already exists" do
      attrs = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      }
      {:ok, _user1} = Accounts.create_user(attrs)

      attrs2 = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(attrs2)
      assert "has already been taken" in errors_on(changeset).username
    end
  end

  describe "authenticate_user/2" do
    setup do
      attrs = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      }

      {:ok, user} = Accounts.create_user(attrs)

      %{user: user}
    end

    test "authenticates user with correct username and password", %{user: user} do
      assert {:ok, authenticated_user} = Accounts.authenticate_user("testuser", "password123")
      assert authenticated_user.id == user.id
      assert authenticated_user.username == user.username
    end

    test "returns error with incorrect password", %{user: _user} do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("testuser", "wrongpassword")
    end

    test "returns error with non-existent username" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("nonexistent", "password123")
    end

    test "returns error with empty username" do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user("", "password123")
    end

    test "returns error with empty password", %{user: _user} do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user("testuser", "")
    end

    test "returns error with nil username" do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user(nil, "password123")
    end

    test "returns error with nil password", %{user: _user} do
      assert {:error, :invalid_credentials} = Accounts.authenticate_user("testuser", nil)
    end

    test "authentication is case sensitive for username", %{user: _user} do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("TESTUSER", "password123")

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("TestUser", "password123")
    end

    test "authentication works with inactive user", %{user: _user} do
      attrs = %{
        username: "inactiveuser",
        password: "password123",
        password_confirmation: "password123",
        is_active: false
      }

      {:ok, inactive_user} = Accounts.create_user(attrs)

      assert {:ok, authenticated_user} = Accounts.authenticate_user("inactiveuser", "password123")
      assert authenticated_user.id == inactive_user.id
      assert authenticated_user.is_active == false
    end
  end

  describe "edge cases and integration" do
    test "create_user and authenticate_user work together" do
      attrs = %{
        username: "integrationuser",
        password: "secretpassword",
        password_confirmation: "secretpassword"
      }

      assert {:ok, %User{} = user} = Accounts.create_user(attrs)

      assert {:ok, authenticated_user} =
               Accounts.authenticate_user("integrationuser", "secretpassword")

      assert authenticated_user.id == user.id

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("integrationuser", "wrongpassword")
    end

    test "multiple users can be created and authenticated independently" do
      attrs1 = %{
        username: "user1",
        password: "test_password123",
        password_confirmation: "test_password123"
      }
      attrs2 = %{
        username: "user2",
        password: "test_password123",
        password_confirmation: "test_password123"
      }

      {:ok, user1} = Accounts.create_user(attrs1)
      {:ok, user2} = Accounts.create_user(attrs2)

      assert user1.id != user2.id
      assert user1.username != user2.username

      assert {:ok, auth_user1} = Accounts.authenticate_user(user1.username, "test_password123")
      assert {:ok, auth_user2} = Accounts.authenticate_user(user2.username, "test_password123")

      assert auth_user1.id == user1.id
      assert auth_user2.id == user2.id
    end

    test "password is properly hashed and cannot be read in plain text" do
      attrs = %{
        username: "secureuser",
        password: "mysecretpassword",
        password_confirmation: "mysecretpassword"
      }

      {:ok, user} = Accounts.create_user(attrs)

      assert user.password != "mysecretpassword"
      assert String.starts_with?(user.password, "$2b$")

      assert {:ok, _} = Accounts.authenticate_user("secureuser", "mysecretpassword")
    end
  end
end
