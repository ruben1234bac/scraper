defmodule ScraperWeb.PageController do
  use ScraperWeb, :controller

  def session(conn, params) do
    conn
    |> renew_session()
    |> put_token_in_session(params["token"])
    |> redirect(to: ~p"/")
  end

  defp renew_session(conn) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:guardian_default_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end
end
