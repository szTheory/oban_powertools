defmodule PhoenixHostWeb.Router do
  use PhoenixHostWeb, :router

  # The test-only route gate depends on an explicit process environment flag.
  # Force Mix to reevaluate this module between opt-in and route-off test runs.
  def __mix_recompile__?, do: Mix.env() == :test

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

  if Mix.env() == :test and System.get_env("PHASE79_BROWSER_FIXTURES") == "1" do
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
