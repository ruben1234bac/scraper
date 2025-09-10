defmodule ScraperWeb.Auth.LoginLive do
  use ScraperWeb, :live_view

  alias Scraper.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def render(assigns) do
    ~H"""
    <.header>
      Login
    </.header>
    <div class="w-full ">
      <.simple_form for={@form} id="reset_password_form" phx-submit="login">
        <.input field={@form[:username]} type="text" placeholder="Username" required />
        <.input field={@form[:password]} type="password" placeholder="Password" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full">
            Login
          </.button>
        </:actions>
      </.simple_form>
    </div>
    <div class="mt-6 w-full">
      <.link class="w-full text-center text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700">
        Register
      </.link>
    </div>
    """
  end

  def handle_event(
        "login",
        %{"user" => %{"username" => username, "password" => password}},
        socket
      ) do
    case Accounts.authenticate_user(username, password) do
      {:ok, _user} ->
        {:noreply, redirect(socket, to: "/")}

      {:error, :invalid_credentials} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid credentials")}
    end
  end
end
