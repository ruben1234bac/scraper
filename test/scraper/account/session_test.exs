defmodule Scraper.Account.SessionTest do
  use Scraper.DataCase, async: true

  alias Scraper.Account.Session

  describe "changeset/2" do
    test "valid changeset with required fields" do
      user = insert(:user)
      attrs = %{user_id: user.id, session_token: "test_token"}
      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.user_id == user.id
      assert changeset.changes.session_token == "test_token"
    end

    test "valid changeset with all fields" do
      user = insert(:user)
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      device_info = %{"browser" => "Firefox", "os" => "Linux"}

      attrs = %{
        user_id: user.id,
        session_token: "test_token",
        last_active_at: now,
        device_info: device_info
      }

      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert changeset.changes.user_id == user.id
      assert changeset.changes.session_token == "test_token"
      assert changeset.changes.last_active_at == now
      assert changeset.changes.device_info == device_info
    end

    test "invalid changeset when user_id is missing" do
      attrs = %{session_token: "test_token"}
      changeset = Session.changeset(%Session{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "invalid changeset when session_token is missing" do
      user = insert(:user)
      attrs = %{user_id: user.id}
      changeset = Session.changeset(%Session{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).session_token
    end

    test "session_token and user_id combination must be unique" do
      user = insert(:user)

      session_attrs =
        build(:session)
        |> Map.from_struct()
        |> Map.put(:user_id, user.id)
        |> Map.put(:session_token, "unique_token")

      {:ok, _session1} = %Session{} |> Session.changeset(session_attrs) |> Repo.insert()

      attrs = %{user_id: user.id, session_token: "unique_token"}

      assert {:error, changeset} =
               %Session{}
               |> Session.changeset(attrs)
               |> Repo.insert()

      assert "has already been taken" in errors_on(changeset).user_id
    end

    test "same session_token can be used for different users" do
      user1 = insert(:user)
      user2 = insert(:user)
      session_token = "shared_token"

      _session1 = insert(:session, user: user1, session_token: session_token)

      attrs = %{user_id: user2.id, session_token: session_token}
      changeset = Session.changeset(%Session{}, attrs)

      assert changeset.valid?
      assert {:ok, _session2} = Repo.insert(changeset)
    end
  end

  describe "factory" do
    test "session factory creates valid session" do
      session = build(:session)
      assert %Session{} = session
      assert session.session_token
      assert session.last_active_at
      assert session.device_info
      assert session.user
    end

    test "session factory can be inserted into database" do
      session = insert(:session)
      assert session.id
      assert session.user_id
      assert session.inserted_at
      assert session.updated_at
    end

    test "session factory generates unique session tokens" do
      session1 = build(:session)
      session2 = build(:session)
      assert session1.session_token != session2.session_token
    end

    test "session factory can create session for specific user" do
      user = insert(:user)
      session = insert(:session, user: user)
      assert session.user_id == user.id
    end

    test "session factory creates associated user by default" do
      session = insert(:session)
      user = Repo.get(Scraper.Account.User, session.user_id)
      assert user
      assert user.username
    end
  end

  describe "associations" do
    test "session belongs to user" do
      user = insert(:user)
      session = insert(:session, user: user)

      session_with_user =
        Session
        |> Repo.get(session.id)
        |> Repo.preload(:user)

      assert session_with_user.user.id == user.id
      assert session_with_user.user.username == user.username
    end
  end
end
