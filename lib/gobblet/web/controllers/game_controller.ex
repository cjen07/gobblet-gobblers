defmodule Gobblet.Web.GameController do
  use Gobblet.Web, :controller

  plug :scrub_params, "game" when action in [:create]

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"game" => game_params}) do
    case Map.get(game_params, "name") do
      nil ->
        conn
        |> put_flash(:error, "Game name cannot be empty")
        |> render("new.html")
      name ->
        conn
        |> redirect(to: game_path(conn, :show, name))
    end
  end

  def show(conn, %{"name" => name}) do
    render conn, "show.html", name: name
  end
end
