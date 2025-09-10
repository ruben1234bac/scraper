defmodule Scraper.Account.UserTest do
  use Scraper.DataCase, async: true

  alias Scraper.Account.User

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      }

      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
      assert changeset.changes.username == "testuser"
      assert String.starts_with?(changeset.changes.password, "$2b$")
      # is_active has a default value so it won't be in changes unless explicitly set
      assert changeset.data.is_active == true
    end

    test "valid changeset with all fields" do
      attrs = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123",
        is_active: false
      }

      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
      assert changeset.changes.username == "testuser"
      assert String.starts_with?(changeset.changes.password, "$2b$")
      assert changeset.changes.is_active == false
    end

    test "invalid changeset when username is missing" do
      attrs = %{password: "password123"}
      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).username
    end

    test "invalid changeset when password is missing" do
      attrs = %{username: "testuser"}
      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).password
    end

    test "invalid changeset when password confirmation doesn't match" do
      attrs = %{username: "testuser", password: "password123", password_confirmation: "different"}
      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "does not match confirmation" in errors_on(changeset).password_confirmation
    end

    test "valid changeset when password confirmation matches" do
      attrs = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      }

      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
    end

    test "invalid changeset when username is too short" do
      attrs = %{username: "ab", password: "password123", password_confirmation: "password123"}
      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "should be at least 3 character(s)" in errors_on(changeset).username
    end

    test "invalid changeset when username is too long" do
      attrs = %{
        username: String.duplicate("a", 256),
        password: "password123",
        password_confirmation: "password123"
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).username
    end

    test "invalid changeset when password is too short" do
      attrs = %{username: "testuser", password: "1234567", password_confirmation: "1234567"}
      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end

    test "invalid changeset when password is too long" do
      long_password = String.duplicate("a", 256)

      attrs = %{
        username: "testuser",
        password: long_password,
        password_confirmation: long_password
      }

      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).password
    end

    test "username must be unique" do
      attrs = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      }

      {:ok, _user1} = %User{} |> User.changeset(attrs) |> Repo.insert()

      attrs2 = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      }

      assert {:error, changeset} =
               %User{}
               |> User.changeset(attrs2)
               |> Repo.insert()

      assert "has already been taken" in errors_on(changeset).username
    end
  end

  describe "factory" do
    test "user factory creates valid user struct" do
      user = build(:user)
      assert %User{} = user
      assert user.username
      assert user.password == "test_password123"
      assert user.is_active == true
    end

    test "user can be created with changeset attributes" do
      attrs = %{
        username: "changesetuser",
        password: "test_password123",
        password_confirmation: "test_password123"
      }

      changeset = User.changeset(%User{}, attrs)
      assert changeset.valid?
      assert {:ok, user} = Repo.insert(changeset)
      assert user.id
      assert user.inserted_at
      assert user.updated_at
      assert String.starts_with?(user.password, "$2b$")
    end

    test "user factory generates unique usernames" do
      user1 = build(:user)
      user2 = build(:user)
      assert user1.username != user2.username
    end
  end

  describe "password hashing" do
    test "password is hashed when changeset is valid" do
      attrs = %{
        username: "testuser",
        password: "password123",
        password_confirmation: "password123"
      }

      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
      assert String.starts_with?(changeset.changes.password, "$2b$")
      refute changeset.changes.password == "password123"
    end

    test "password is not hashed when changeset is invalid" do
      attrs = %{username: "testuser", password: "password123", password_confirmation: "different"}
      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert changeset.changes.password == "password123"
    end

    test "password hash can be verified" do
      attrs = %{
        username: "hashuser",
        password: "test_password123",
        password_confirmation: "test_password123"
      }

      {:ok, user} = %User{} |> User.changeset(attrs) |> Repo.insert()
      assert Bcrypt.verify_pass("test_password123", user.password)
      refute Bcrypt.verify_pass("wrong_password", user.password)
    end
  end
end
