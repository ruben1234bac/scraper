defmodule Scraper.Workers.ScrapingTest do
  use Scraper.DataCase, async: false
  use Oban.Testing, repo: Scraper.Repo

  import ExUnit.CaptureLog
  import Mock

  alias Scraper.Workers.Scraping
  alias Scraper.WebPage.{WebPage, WebPageField}
  alias Phoenix.PubSub

  describe "perform/1" do
    setup do
      user = insert(:user)
      web_page = insert(:web_page, user: user, is_completed: false, has_failed: false)

      job = %Oban.Job{
        args: %{
          "web_page_id" => web_page.id,
          "url" => web_page.url,
          "user_id" => user.id
        },
        attempt: 1
      }

      %{user: user, web_page: web_page, job: job}
    end

    test "successfully processes job with valid HTML containing links", %{
      user: user,
      web_page: web_page,
      job: job
    } do
      html_body = """
      <!DOCTYPE html>
      <html>
        <body>
          <a href="https://example.com">Example Link</a>
          <a href="/relative-link">Relative Link</a>
        </body>
      </html>
      """

      with_mock HTTPoison,
        get: fn _url -> {:ok, %{status_code: 200, body: html_body}} end do
        PubSub.subscribe(Scraper.PubSub, "user:#{user.id}")

        assert :ok = Scraping.perform(job)
        assert called(HTTPoison.get(web_page.url))

        web_page_id = web_page.id
        web_page_url = web_page.url

        assert_receive {:starting_scraping,
                        %{web_page_id: ^web_page_id, url: ^web_page_url, attempt: 1}},
                       1000

        assert_receive {:scraping_completed,
                        %{web_page_id: ^web_page_id, url: ^web_page_url, attempt: 1}},
                       5000

        updated_web_page = Repo.get(WebPage, web_page.id)
        assert updated_web_page.is_completed == true
        assert updated_web_page.has_failed == false

        fields = Repo.all(from(f in WebPageField, where: f.web_page_id == ^web_page.id))
        assert length(fields) == 2

        field_data = Enum.map(fields, &{&1.name, &1.value})
        assert {"Example Link", "https://example.com"} in field_data
        assert {"Relative Link", "/relative-link"} in field_data
      end
    end

    test "successfully processes job with HTML containing no links", %{
      user: user,
      web_page: web_page,
      job: job
    } do
      html_body = """
      <!DOCTYPE html>
      <html>
        <body>
          <h1>No Links Here</h1>
        </body>
      </html>
      """

      with_mock HTTPoison,
        get: fn _url -> {:ok, %{status_code: 200, body: html_body}} end do
        PubSub.subscribe(Scraper.PubSub, "user:#{user.id}")

        assert :ok = Scraping.perform(job)

        assert_receive {:starting_scraping, _}, 1000
        assert_receive {:scraping_completed, _}, 5000

        updated_web_page = Repo.get(WebPage, web_page.id)
        assert updated_web_page.is_completed == true

        fields_count =
          Repo.aggregate(from(f in WebPageField, where: f.web_page_id == ^web_page.id), :count)

        assert fields_count == 0
      end
    end

    test "handles HTTP request failure", %{user: user, web_page: web_page, job: job} do
      error = %HTTPoison.Error{reason: :timeout}

      with_mock HTTPoison,
        get: fn _url -> {:error, error} end do
        PubSub.subscribe(Scraper.PubSub, "user:#{user.id}")

        log_output =
          capture_log(fn ->
            assert :ok = Scraping.perform(job)
          end)

        assert called(HTTPoison.get(web_page.url))
        assert log_output =~ "Error: %HTTPoison.Error{reason: :timeout"

        assert_receive {:starting_scraping, _}, 1000

        web_page_id = web_page.id
        web_page_url = web_page.url

        assert_receive {:scraping_failed,
                        %{web_page_id: ^web_page_id, url: ^web_page_url, attempt: 1}},
                       1000

        updated_web_page = Repo.get(WebPage, web_page.id)
        assert updated_web_page.has_failed == true
        assert updated_web_page.is_completed == false

        fields_count =
          Repo.aggregate(from(f in WebPageField, where: f.web_page_id == ^web_page.id), :count)

        assert fields_count == 0
      end
    end

    test "handles HTTP request with non-200 status code", %{
      user: user,
      web_page: web_page,
      job: job
    } do
      with_mock HTTPoison,
        get: fn _url -> {:ok, %{status_code: 404, body: "Not Found"}} end do
        PubSub.subscribe(Scraper.PubSub, "user:#{user.id}")

        assert_raise CaseClauseError, fn ->
          Scraping.perform(job)
        end

        assert_receive {:starting_scraping, _}, 1000

        updated_web_page = Repo.get(WebPage, web_page.id)
        assert updated_web_page.has_failed == false
        assert updated_web_page.is_completed == false
      end
    end

    test "error processes job with HTML", %{
      user: user,
      web_page: web_page,
      job: job
    } do
      html_body = nil

      with_mock HTTPoison,
        get: fn _url -> {:ok, %{status_code: 200, body: html_body}} end do
        PubSub.subscribe(Scraper.PubSub, "user:#{user.id}")

        assert :ok = Scraping.perform(job)

        assert_receive {:starting_scraping, _}, 1000

        web_page_id = web_page.id
        web_page_url = web_page.url

        assert_receive {:scraping_failed,
                        %{web_page_id: ^web_page_id, url: ^web_page_url, attempt: 1}}

        updated_web_page = Repo.get(WebPage, web_page.id)
        assert updated_web_page.has_failed == true
      end
    end
  end

  describe "new/1" do
    test "creates job changeset with correct arguments" do
      attrs = %{web_page_id: 123, url: "https://example.com", user_id: 456}

      job_changeset = Scraping.new(attrs)

      assert %Ecto.Changeset{} = job_changeset
      assert job_changeset.valid?
      assert job_changeset.changes.worker == "Scraper.Workers.Scraping"

      assert job_changeset.changes.args == %{
               web_page_id: 123,
               url: "https://example.com",
               user_id: 456
             }
    end
  end
end
