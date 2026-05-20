defmodule ObanPowertools.Web.RouterTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.TestRouter

  test "oban_powertools_routes is available as a macro" do
    Code.ensure_loaded(ObanPowertools.Web.Router)
    assert Kernel.macro_exported?(ObanPowertools.Web.Router, :oban_powertools_routes, 1)
  end

  test "native powertools routes mount inside the ops/jobs shell" do
    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ObanPowertools.Web.EngineOverviewLive, :index, _, _}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs", "localhost")

    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ObanPowertools.Web.LifelineLive, :index, _, _}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/lifeline", "localhost")

    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ObanPowertools.Web.LimitersLive, :index, _, _}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/limiters", "localhost")

    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ObanPowertools.Web.CronLive, :index, _, _}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/cron", "localhost")

    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ObanPowertools.Web.AuditLive, :index, _, _}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/audit", "localhost")

    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ObanPowertools.Web.WorkflowsLive, :index, _, _}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/workflows", "localhost")
  end
end
