defmodule Scraper.Account.GuardianTest do
  use Scraper.DataCase, async: true

  alias Scraper.Account.Guardian
  alias Scraper.Account.User

  describe "subject_for_token/2" do
    test "returns user id as string for valid user" do
      user = insert(:user)
      claims = %{}

      assert {:ok, subject} = Guardian.subject_for_token(user, claims)
      assert subject == to_string(user.id)
      assert is_binary(subject)
    end

    test "returns user id as string for user with different id" do
      user1 = insert(:user)
      user2 = insert(:user)
      claims = %{}

      assert {:ok, subject1} = Guardian.subject_for_token(user1, claims)
      assert {:ok, subject2} = Guardian.subject_for_token(user2, claims)

      assert subject1 == to_string(user1.id)
      assert subject2 == to_string(user2.id)
      assert subject1 != subject2
    end

    test "works with empty claims" do
      user = insert(:user)
      empty_claims = %{}

      assert {:ok, subject} = Guardian.subject_for_token(user, empty_claims)
      assert subject == to_string(user.id)
    end

    test "works with populated claims (claims are ignored)" do
      user = insert(:user)
      claims = %{"some" => "data", "other" => "info"}

      assert {:ok, subject} = Guardian.subject_for_token(user, claims)
      assert subject == to_string(user.id)
    end

    test "works with user struct with all fields" do
      attrs = build(:user_attrs)
      {:ok, user} = %User{} |> User.changeset(attrs) |> Repo.insert()
      claims = %{}

      assert {:ok, subject} = Guardian.subject_for_token(user, claims)
      assert subject == to_string(user.id)
      assert String.match?(subject, ~r/^\d+$/)
    end
  end

  describe "resource_from_claims/1" do
    test "returns user for valid claims with existing user id" do
      user = insert(:user)
      claims = %{"sub" => to_string(user.id)}

      assert {:ok, returned_user} = Guardian.resource_from_claims(claims)
      assert returned_user.id == user.id
      assert returned_user.username == user.username
      assert %User{} = returned_user
    end

    test "returns user for valid claims with integer user id" do
      user = insert(:user)
      claims = %{"sub" => user.id}

      assert {:ok, returned_user} = Guardian.resource_from_claims(claims)
      assert returned_user.id == user.id
      assert returned_user.username == user.username
    end

    test "returns error for claims with non-existent user id" do
      claims = %{"sub" => "99999"}

      assert {:error, :resource_not_found} = Guardian.resource_from_claims(claims)
    end

    test "returns error for claims with invalid user id format" do
      claims = %{"sub" => "invalid_id"}

      assert {:error, :resource_not_found} = Guardian.resource_from_claims(claims)
    end

    test "returns error for claims with empty sub" do
      claims = %{"sub" => ""}

      assert {:error, :resource_not_found} = Guardian.resource_from_claims(claims)
    end

    test "returns error for claims with nil sub" do
      claims = %{"sub" => nil}

      assert {:error, :resource_not_found} = Guardian.resource_from_claims(claims)
    end

    test "returns error for empty claims" do
      claims = %{}

      # This should raise a FunctionClauseError since the pattern match fails
      assert_raise FunctionClauseError, fn ->
        Guardian.resource_from_claims(claims)
      end
    end

    test "returns error for claims with missing sub field" do
      claims = %{"other_field" => "value"}

      # This should raise a FunctionClauseError since the pattern match fails
      assert_raise FunctionClauseError, fn ->
        Guardian.resource_from_claims(claims)
      end
    end

    test "loads complete user with all associations" do
      attrs = build(:user_attrs)
      {:ok, user} = %User{} |> User.changeset(attrs) |> Repo.insert()
      claims = %{"sub" => to_string(user.id)}

      assert {:ok, returned_user} = Guardian.resource_from_claims(claims)
      assert returned_user.id == user.id
      assert returned_user.username == user.username
      assert returned_user.is_active == user.is_active
      assert returned_user.inserted_at == user.inserted_at
      assert returned_user.updated_at == user.updated_at
    end
  end

  describe "integration with Guardian token operations" do
    test "can encode and decode token for user" do
      user = insert(:user)

      # Test encoding a token
      assert {:ok, token, claims} = Guardian.encode_and_sign(user)
      assert is_binary(token)
      assert is_map(claims)
      assert claims["sub"] == to_string(user.id)

      # Test decoding the token back to user
      assert {:ok, decoded_user, _decoded_claims} = Guardian.resource_from_token(token)
      assert decoded_user.id == user.id
      assert decoded_user.username == user.username
    end

    test "token verification fails for tampered token" do
      user = insert(:user)
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      # Tamper with the token
      tampered_token = token <> "tampered"

      assert {:error, _reason} = Guardian.resource_from_token(tampered_token)
    end

    test "can create and verify tokens for different users" do
      user1 = insert(:user)
      user2 = insert(:user)

      {:ok, token1, _claims1} = Guardian.encode_and_sign(user1)
      {:ok, token2, _claims2} = Guardian.encode_and_sign(user2)

      assert token1 != token2

      {:ok, decoded_user1, _claims1} = Guardian.resource_from_token(token1)
      {:ok, decoded_user2, _claims2} = Guardian.resource_from_token(token2)

      assert decoded_user1.id == user1.id
      assert decoded_user2.id == user2.id
      assert decoded_user1.id != decoded_user2.id
    end

    test "token becomes invalid after user is deleted" do
      user = insert(:user)
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      # Verify token works initially
      assert {:ok, decoded_user, _claims} = Guardian.resource_from_token(token)
      assert decoded_user.id == user.id

      # Delete the user
      Repo.delete(user)

      # Token should now be invalid (user not found)
      assert {:error, :resource_not_found} = Guardian.resource_from_token(token)
    end
  end

  describe "error handling and edge cases" do
    test "handles user with minimum required fields" do
      # Create a user with just the required fields
      attrs = %{
        username: "minuser",
        password: "password123",
        password_confirmation: "password123"
      }

      {:ok, user} = %User{} |> User.changeset(attrs) |> Repo.insert()

      # Should work with subject_for_token
      assert {:ok, subject} = Guardian.subject_for_token(user, %{})
      assert subject == to_string(user.id)

      # Should work with resource_from_claims
      claims = %{"sub" => subject}
      assert {:ok, returned_user} = Guardian.resource_from_claims(claims)
      assert returned_user.id == user.id
    end

    test "handles inactive user" do
      attrs = build(:user_attrs, is_active: false)
      {:ok, inactive_user} = %User{} |> User.changeset(attrs) |> Repo.insert()

      # Guardian should still work with inactive users
      assert {:ok, subject} = Guardian.subject_for_token(inactive_user, %{})

      claims = %{"sub" => subject}
      assert {:ok, returned_user} = Guardian.resource_from_claims(claims)
      assert returned_user.id == inactive_user.id
      assert returned_user.is_active == false
    end

    test "subject_for_token handles user struct variations" do
      user = build(:user, id: 12_345)
      assert {:ok, subject} = Guardian.subject_for_token(user, %{})
      assert subject == "12_345"
    end
  end
end
