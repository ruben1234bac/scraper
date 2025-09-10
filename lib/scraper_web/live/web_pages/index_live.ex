defmodule ScraperWeb.WebPages.IndexLive do
  use ScraperWeb, :live_view

  alias Scraper.Account.Guardian
  alias Scraper.WebPages

  alias Phoenix.PubSub

  def mount(_params, session, socket) do
    current_user = get_current_user(session)

    PubSub.subscribe(Scraper.PubSub, "user:#{current_user.id}")

    {:ok,
     assign(socket,
       web_page_selected: nil,
       current_user: current_user,
       form: to_form(%{}, as: "web_page"),
       web_pages: WebPages.list_web_pages(1)
     )}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Web Pages
    </.header>
    <div class="w-full ">
      <.simple_form for={@form} phx-submit="save">
        <.input field={@form[:url]} type="text" placeholder="URL" required />
        <:actions>
          <.button phx-disable-with="Saving..." class="w-full">
            Save
          </.button>
        </:actions>
      </.simple_form>
    </div>
    <div :if={@web_pages.total_entries > 0 && is_nil(@web_page_selected)} class="w-full mt-10">
      <.label>List of Web Pages</.label>
      <table class="w-full text-sm text-left rtl:text-right text-gray-700 mt-4">
        <thead class="text-xs text-left text-gray-700 uppercase ">
          <tr>
            <th scope="col" class="px-6 py-3">URL</th>
            <th scope="col" class="px-6 py-3">Title</th>
            <th scope="col" class="px-6 py-3">Status</th>
            <th scope="col" class="px-6 py-3">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr :for={web_page <- @web_pages.entries} class="bg-white border-b text-gray-900">
            <td class="px-6 py-4">{web_page.url}</td>
            <td class="px-6 py-4">{web_page.title}</td>
            <td class="px-6 py-4">
              {(web_page.is_completed && "Completed") || (web_page.has_failed && "Failed") ||
                "Pending"}
            </td>
            <td class="px-6 py-4">
              <.button phx-click="detail" phx-value-id={web_page.id}>
                Detail
              </.button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div :if={@web_pages.total_entries == 0} class="w-full mt-10">
      <.label>Add your first web page</.label>
    </div>

    <div :if={!is_nil(@web_page_selected)} class="w-full mt-10">
      <div class="w-full inline-flex items-center">
        <.button phx-click="back">
          Back
        </.button>
        <.label>Liks of {@web_page_selected.url}</.label>
      </div>
      <table class="w-full text-sm text-left rtl:text-right text-gray-700 mt-4">
        <thead class="text-xs text-left text-gray-700 uppercase ">
          <tr>
            <th scope="col" class="px-6 py-3">URL</th>
            <th scope="col" class="px-6 py-3">Content</th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={web_page_field <- @web_page_selected.web_page_fields}
            class="bg-white border-b text-gray-900"
          >
            <td class="px-6 py-4">{web_page_field.value}</td>
            <td class="px-6 py-4">{web_page_field.name}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  def handle_event("back", _params, socket) do
    {:noreply, assign(socket, web_page_selected: nil)}
  end

  def handle_event("detail", %{"id" => id}, socket) do
    web_page = WebPages.get_web_page!(id)
    {:noreply, assign(socket, web_page_selected: web_page)}
  end

  def handle_event("save", %{"web_page" => %{"url" => url}}, socket) do
    case WebPages.create_web_page(%{url: url, user_id: socket.assigns.current_user.id}) do
      {:ok, _web_page} ->
        {:noreply, assign(socket, web_pages: WebPages.list_web_pages(1))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_info({:starting_scraping, data}, socket) do
    {:noreply,
     socket
     |> put_flash(
       :info,
       "Scraping started for id: #{data.web_page_id}, url: #{data.url}, attempt: #{data.attempt}"
     )}
  end

  def handle_info({:scraping_completed, data}, socket) do
    {:noreply,
     socket
     |> assign(web_pages: WebPages.list_web_pages(1))
     |> put_flash(
       :info,
       "Scraping completed for id: #{data.web_page_id}, url: #{data.url}"
     )}
  end

  def handle_info({:scraping_failed, data}, socket) do
    {:noreply,
     socket
     |> assign(web_pages: WebPages.list_web_pages(1))
     |> put_flash(
       :error,
       "Scraping failed for id: #{data.web_page_id}, url: #{data.url}"
     )}
  end

  defp get_current_user(%{"guardian_default_token" => token}) do
    with {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, user} <- Guardian.resource_from_claims(claims) do
      user
    end
  end
end
