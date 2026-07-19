defmodule PhoenixHostWeb.Router do
  use PhoenixHostWeb, :router

  require ObanPowertools.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixHostWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  scope "/", PhoenixHostWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/ops/jobs" do
    pipe_through :browser

    ObanPowertools.Web.Router.oban_powertools_routes("/oban")
  end

  if Mix.env() == :test and
       is_binary(Application.compile_env(:phoenix_host, :phase79_fixture_compile_partition)) and
       System.get_env("PHASE79_BROWSER_FIXTURES") == "1" do
    scope "/__phase79_browser_fixtures__", PhoenixHostWeb do
      pipe_through :api

      post "/reset", Phase79BrowserFixturesController, :reset
      post "/actor", Phase79BrowserFixturesController, :actor
      post "/recovery", Phase79BrowserFixturesController, :recovery
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixHostWeb do
  #   pipe_through :api
  # end
end
