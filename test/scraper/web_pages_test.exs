defmodule Scraper.WebPagesTest do
  use Scraper.DataCase, async: true

  alias Scraper.WebPage.{WebPage, WebPageField}
  alias Scraper.WebPages

  describe "create_web_page/1" do
    test "creates web page with valid attributes" do
      user = insert(:user)

      attrs = %{
        url: "https://example.com",
        title: "Example Page",
        user_id: user.id
      }

      assert {:ok, %WebPage{} = web_page} = WebPages.create_web_page(attrs)
      assert web_page.url == "https://example.com"
      assert web_page.title == "Example Page"
      assert web_page.user_id == user.id
      assert web_page.is_completed == false
      assert web_page.id
      assert web_page.inserted_at
      assert web_page.updated_at
    end

    test "creates web page with only required fields" do
      user = insert(:user)

      attrs = %{
        url: "https://minimal.com",
        user_id: user.id
      }

      assert {:ok, %WebPage{} = web_page} = WebPages.create_web_page(attrs)
      assert web_page.url == "https://minimal.com"
      assert web_page.title == nil
      assert web_page.user_id == user.id
      assert web_page.is_completed == false
    end

    test "creates web page with is_completed true" do
      user = insert(:user)

      attrs = %{
        url: "https://completed.com",
        title: "Completed Page",
        user_id: user.id,
        is_completed: true
      }

      assert {:ok, %WebPage{} = web_page} = WebPages.create_web_page(attrs)
      assert web_page.is_completed == true
    end

    test "returns error when url is missing" do
      user = insert(:user)

      attrs = %{
        title: "Page without URL",
        user_id: user.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} = WebPages.create_web_page(attrs)
      assert "can't be blank" in errors_on(changeset).url
    end

    test "returns error when user_id is missing" do
      attrs = %{
        url: "https://orphan.com",
        title: "Orphan Page"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = WebPages.create_web_page(attrs)
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "returns error when both required fields are missing" do
      attrs = %{title: "Invalid Page"}

      assert {:error, %Ecto.Changeset{} = changeset} = WebPages.create_web_page(attrs)
      assert "can't be blank" in errors_on(changeset).url
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "creates web page using factory" do
      web_page = insert(:web_page)

      assert web_page.url
      assert web_page.title
      assert web_page.user_id
      assert web_page.id
    end
  end

  describe "update_web_page/2" do
    test "updates web page with valid attributes" do
      web_page = insert(:web_page)

      attrs = %{
        url: "https://updated.com",
        title: "Updated Title",
        is_completed: true
      }

      assert {:ok, %WebPage{} = updated_web_page} = WebPages.update_web_page(web_page.id, attrs)
      assert updated_web_page.id == web_page.id
      assert updated_web_page.url == "https://updated.com"
      assert updated_web_page.title == "Updated Title"
      assert updated_web_page.is_completed == true
      assert updated_web_page.user_id == web_page.user_id
    end

    test "updates only some fields" do
      web_page = insert(:web_page, url: "https://original.com", title: "Original Title")
      attrs = %{title: "New Title Only"}

      assert {:ok, %WebPage{} = updated_web_page} = WebPages.update_web_page(web_page.id, attrs)
      assert updated_web_page.url == "https://original.com"
      assert updated_web_page.title == "New Title Only"
    end

    test "marks web page as completed" do
      web_page = insert(:web_page, is_completed: false)
      attrs = %{is_completed: true}

      assert {:ok, %WebPage{} = updated_web_page} = WebPages.update_web_page(web_page.id, attrs)
      assert updated_web_page.is_completed == true
    end

    test "returns error for non-existent web page" do
      attrs = %{url: "https://updated.com"}

      assert {:error, :not_found} = WebPages.update_web_page(99_999, attrs)
    end

    test "returns validation error for invalid attributes" do
      web_page = insert(:web_page)
      attrs = %{url: nil}

      assert {:error, %Ecto.Changeset{} = changeset} =
               WebPages.update_web_page(web_page.id, attrs)

      assert "can't be blank" in errors_on(changeset).url
    end

    test "does not change user_id when not provided" do
      web_page = insert(:web_page)
      original_user_id = web_page.user_id
      attrs = %{title: "Updated Title"}

      assert {:ok, %WebPage{} = updated_web_page} = WebPages.update_web_page(web_page.id, attrs)
      assert updated_web_page.user_id == original_user_id
    end

    test "can update user_id" do
      web_page = insert(:web_page)
      new_user = insert(:user)
      attrs = %{user_id: new_user.id}

      assert {:ok, %WebPage{} = updated_web_page} = WebPages.update_web_page(web_page.id, attrs)
      assert updated_web_page.user_id == new_user.id
    end
  end

  describe "list_web_pages/1" do
    test "returns paginated web pages ordered by newest first" do
      # Create web pages with specific timestamps
      user = insert(:user)
      old_page = insert(:web_page, user: user, title: "Old Page")
      new_page = insert(:web_page, user: user, title: "New Page")

      # Update timestamps to ensure order
      Repo.update_all(
        from(w in WebPage, where: w.id == ^old_page.id),
        set: [inserted_at: ~U[2023-01-01 00:00:00Z]]
      )

      Repo.update_all(
        from(w in WebPage, where: w.id == ^new_page.id),
        set: [inserted_at: ~U[2023-12-31 00:00:00Z]]
      )

      page_result = WebPages.list_web_pages(1)

      assert %Scrivener.Page{} = page_result
      assert page_result.page_number == 1
      assert length(page_result.entries) == 2

      # Verify newest first
      [first_entry, second_entry] = page_result.entries
      assert first_entry.title == "New Page"
      assert second_entry.title == "Old Page"
    end

    test "returns empty page when no web pages exist" do
      page_result = WebPages.list_web_pages(1)

      assert %Scrivener.Page{} = page_result
      assert page_result.entries == []
      assert page_result.page_number == 1
      assert page_result.total_entries == 0
    end

    test "handles pagination correctly" do
      user = insert(:user)
      # Create more pages than default page size to test pagination
      for i <- 1..25 do
        insert(:web_page, user: user, title: "Page #{i}")
      end

      # Test first page
      page1 = WebPages.list_web_pages(1)
      assert %Scrivener.Page{} = page1
      assert page1.page_number == 1
      assert length(page1.entries) > 0
      assert page1.total_entries == 25

      # Test that we can get a second page (assuming default page size < 25)
      if page1.total_pages > 1 do
        page2 = WebPages.list_web_pages(2)
        assert page2.page_number == 2
        assert length(page2.entries) > 0
      end
    end

    test "returns correct page for higher page numbers" do
      user = insert(:user)
      insert(:web_page, user: user, title: "Single Page")

      # Request a page that doesn't exist - Scrivener returns page 1 when out of bounds
      page_result = WebPages.list_web_pages(5)
      assert %Scrivener.Page{} = page_result
      assert page_result.page_number == 1
      assert length(page_result.entries) == 1
    end
  end

  describe "create_web_page_field/1" do
    test "creates web page field with valid attributes" do
      web_page = insert(:web_page)

      attrs = %{
        name: "title",
        value: "Example",
        full_value: "Example Title",
        web_page_id: web_page.id
      }

      assert {:ok, %WebPageField{} = field} = WebPages.create_web_page_field(attrs)
      assert field.name == "title"
      assert field.value == "Example"
      assert field.full_value == "Example Title"
      assert field.web_page_id == web_page.id
      assert field.id
      assert field.inserted_at
      assert field.updated_at
    end

    test "creates multiple fields for same web page" do
      web_page = insert(:web_page)

      attrs1 = %{
        name: "title",
        value: "Title",
        full_value: "Full Title",
        web_page_id: web_page.id
      }

      attrs2 = %{
        name: "description",
        value: "Desc",
        full_value: "Full Description",
        web_page_id: web_page.id
      }

      assert {:ok, field1} = WebPages.create_web_page_field(attrs1)
      assert {:ok, field2} = WebPages.create_web_page_field(attrs2)

      assert field1.web_page_id == web_page.id
      assert field2.web_page_id == web_page.id
      assert field1.name != field2.name
    end

    test "returns error when name is missing" do
      web_page = insert(:web_page)

      attrs = %{
        value: "Value",
        full_value: "Full Value",
        web_page_id: web_page.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} = WebPages.create_web_page_field(attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns error when value is missing" do
      web_page = insert(:web_page)

      attrs = %{
        name: "field_name",
        full_value: "Full Value",
        web_page_id: web_page.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} = WebPages.create_web_page_field(attrs)
      assert "can't be blank" in errors_on(changeset).value
    end

    test "returns error when full_value is missing" do
      web_page = insert(:web_page)

      attrs = %{
        name: "field_name",
        value: "Value",
        web_page_id: web_page.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} = WebPages.create_web_page_field(attrs)
      assert "can't be blank" in errors_on(changeset).full_value
    end

    test "returns error when web_page_id is missing" do
      attrs = %{
        name: "field_name",
        value: "Value",
        full_value: "Full Value"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = WebPages.create_web_page_field(attrs)
      assert "can't be blank" in errors_on(changeset).web_page_id
    end

    test "returns error when all required fields are missing" do
      attrs = %{}

      assert {:error, %Ecto.Changeset{} = changeset} = WebPages.create_web_page_field(attrs)
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).value
      assert "can't be blank" in errors_on(changeset).full_value
      assert "can't be blank" in errors_on(changeset).web_page_id
    end

    test "creates web page field using factory" do
      field = insert(:web_page_field)

      assert field.name
      assert field.value
      assert field.full_value
      assert field.web_page_id
      assert field.id
    end
  end

  describe "integration tests" do
    test "create web page and add fields to it" do
      user = insert(:user)

      # Create web page
      web_page_attrs = %{
        url: "https://integration-test.com",
        title: "Integration Test Page",
        user_id: user.id
      }

      assert {:ok, web_page} = WebPages.create_web_page(web_page_attrs)

      # Add fields to the web page
      field_attrs = %{
        name: "main_heading",
        value: "Welcome",
        full_value: "Welcome to our site",
        web_page_id: web_page.id
      }

      assert {:ok, field} = WebPages.create_web_page_field(field_attrs)
      assert field.web_page_id == web_page.id
    end

    test "update web page completion status and verify it persists" do
      web_page = insert(:web_page, is_completed: false)

      # Mark as completed
      assert {:ok, updated_page} = WebPages.update_web_page(web_page.id, %{is_completed: true})
      assert updated_page.is_completed == true

      # Verify it's in the list
      page_result = WebPages.list_web_pages(1)
      found_page = Enum.find(page_result.entries, &(&1.id == web_page.id))
      assert found_page.is_completed == true
    end

    test "create multiple web pages and verify listing order" do
      user = insert(:user)

      # Create pages with manual timestamp control
      {:ok, page1} = WebPages.create_web_page(%{url: "https://first.com", user_id: user.id})
      {:ok, page2} = WebPages.create_web_page(%{url: "https://second.com", user_id: user.id})

      # Update timestamps to ensure order
      Repo.update_all(
        from(w in WebPage, where: w.id == ^page1.id),
        set: [inserted_at: ~U[2023-01-01 00:00:00Z]]
      )

      Repo.update_all(
        from(w in WebPage, where: w.id == ^page2.id),
        set: [inserted_at: ~U[2023-12-31 00:00:00Z]]
      )

      # List should show newest first
      page_result = WebPages.list_web_pages(1)
      [first_listed, second_listed] = page_result.entries

      assert first_listed.id == page2.id
      assert second_listed.id == page1.id
    end
  end
end
