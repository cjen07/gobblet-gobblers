defmodule Gobblet.Web.PageController do
  use Gobblet.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
