defmodule ObanPowertools.TestRouter do
  use Phoenix.Router

  require ObanPowertools.Web.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:put_root_layout, html: {ObanPowertools.TestLayouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through(:browser)

    get("/", ObanPowertools.TestPageController, :home)
  end

  scope "/ops/jobs" do
    pipe_through(:browser)

    ObanPowertools.Web.Router.oban_powertools_routes("/oban")
  end
end
