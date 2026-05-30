defmodule HexConsumerWeb.Router do
  use HexConsumerWeb, :router

  require ObanPowertools.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HexConsumerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HexConsumerWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/ops/jobs" do
    pipe_through :browser

    ObanPowertools.Web.Router.oban_powertools_routes("/oban")
  end

  # Other scopes may use custom stacks.
  # scope "/api", HexConsumerWeb do
  #   pipe_through :api
  # end
end
