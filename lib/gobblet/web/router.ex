defmodule Gobblet.Web.Router do
  use Gobblet.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Gobblet.Web.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Gobblet.Web do
    pipe_through :browser # Use the default browser stack

    get "/", PlayerController, :new
    resources "/players", PlayerController, only: [:create, :delete]
  end

  scope "/", Gobblet.Web do
    pipe_through [:browser, :authenticate_player]
    resources "/games", GameController, only: [:new, :create, :show], param: "name"
  end
end
