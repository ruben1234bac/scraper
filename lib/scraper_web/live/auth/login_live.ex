defmodule ScraperWeb.Auth.LoginLive do
  use ScraperWeb, :live_view

  alias Scraper.Account.Guardian
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
      <.simple_form for={@form} id="login_form" phx-submit="login">
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
      <.link
        navigate={~p"/register"}
        class="w-full text-center text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
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
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)

        Accounts.create_session(%{
          user_id: user.id,
          session_token: token
        })

        {:noreply, redirect(socket, to: "/start_session?token=#{token}")}

      {:error, :invalid_credentials} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid credentials")}
    end
  end
end
