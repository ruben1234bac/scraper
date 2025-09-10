defmodule Scraper.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Scraper.Repo

  def user_factory do
    %Scraper.Account.User{
      username: sequence(:username, &"user#{&1}"),
      password: "test_password123",
      is_active: true
    }
  end

  def user_attrs_factory do
    %{
      username: sequence(:username, &"user#{&1}"),
      password: "test_password123",
      password_confirmation: "test_password123",
      is_active: true
    }
  end

  def session_factory do
    %Scraper.Account.Session{
      user: build(:user),
      session_token:
        sequence(:session_token, &"token_#{&1}_#{System.unique_integer([:positive])}"),
      last_active_at: DateTime.utc_now(),
      device_info: %{
        "browser" => "Chrome",
        "os" => "macOS",
        "ip" => "127.0.0.1"
      }
    }
  end
end
