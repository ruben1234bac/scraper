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

  def web_page_factory do
    %Scraper.WebPage.WebPage{
      url: sequence(:url, &"https://example#{&1}.com"),
      title: sequence(:title, &"Example Page #{&1}"),
      is_completed: false,
      user: build(:user)
    }
  end

  def web_page_field_factory do
    %Scraper.WebPage.WebPageField{
      name: sequence(:field_name, &"field_#{&1}"),
      value: sequence(:field_value, &"value_#{&1}"),
      full_value: sequence(:full_value, &"full_value_for_field_#{&1}"),
      web_page: build(:web_page)
    }
  end
end
