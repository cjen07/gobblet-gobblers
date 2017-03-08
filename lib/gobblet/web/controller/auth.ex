defmodule Gobblet.Web.Auth do
  import Plug.Conn
  import Phoenix.Controller

  alias Gobblet.Web.Router.Helpers

  def init(options) do
    options
  end

  def call(conn, _opts) do
    cond do
      player = conn.assigns[:current_player] ->
        put_current_player(conn, player)
      player = get_session(conn, :current_player) ->
        put_current_player(conn, player)
      true ->
        assign(conn, :current_player, nil)
    end
  end

  def login(conn, player) do
    conn
    |> put_current_player(player)
    |> put_session(:current_player, player)
    |> configure_session(renew: true)
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end

  def authenticate_player(conn, _opts) do
    if conn.assigns.current_player do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page")
      |> redirect(to: Helpers.player_path(conn, :new))
      |> halt()
    end
  end

  defp put_current_player(conn, player) do
    conn
    |> assign(:current_player, player)
  end
end
