defmodule FinTrackWeb.UserAuth do
  @moduledoc """
  User authentication plug pipeline.
  """

  use FinTrackWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias FinTrack.Accounts

  def init(opts), do: opts

  def call(conn, opts) do
    case opts do
      :fetch_current_user -> fetch_current_user(conn, [])
      :require_authenticated_user -> require_authenticated_user(conn, [])
      :redirect_if_user_is_authenticated -> redirect_if_user_is_authenticated(conn, [])
    end
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/login")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp assign_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_id = session["user_id"] do
        get_user_safely(user_id)
      end
    end)
  end

  def log_in_user(conn, user) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

    # Store user ID in session for simple session management
    conn
    |> put_session(:user_token, token)
    |> put_session(:user_id, user.id)
    |> put_session(:live_socket_id, "users_sessions:#{token}")
    |> redirect(to: signed_in_path(conn))
  end

  def log_out_user(conn) do
    conn
    |> clear_session()
    |> redirect(to: ~p"/login")
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  def fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = user_id && get_user_safely(user_id)
    assign(conn, :current_user, user)
  end

  defp get_user_safely(user_id) do
    try do
      Accounts.get_user!(user_id)
    rescue
      Ecto.NoResultsError -> nil
    end
  end

  defp signed_in_path(_conn), do: ~p"/"

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
