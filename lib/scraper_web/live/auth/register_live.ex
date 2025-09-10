defmodule ScraperWeb.Auth.RegisterLive do
  use ScraperWeb, :live_view

  alias Scraper.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Register
    </.header>
    <div class="w-full ">
      <.simple_form for={@form} id="register_form" phx-submit="register">
        <.input field={@form[:username]} type="text" placeholder="Username" required />
        <.input field={@form[:password]} type="password" placeholder="Password" required />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          placeholder="Password confirmation"
          required
        />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full">
            Save
          </.button>
        </:actions>
      </.simple_form>
    </div>
    <div class="mt-6 w-full">
      <.link
        navigate={~p"/login"}
        class="w-full text-center text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        Login
      </.link>
    </div>
    """
  end

  def handle_event("register", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, _user} ->
        {:noreply, redirect(socket, to: "/login")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
