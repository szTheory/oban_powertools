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

  test "the host-owned outer scope does not expose the bridge at the router root" do
    assert :error = Phoenix.Router.route_info(TestRouter, "GET", "/oban", "localhost")
  end

  test "the optional oban_web bridge mounts under /ops/jobs/oban with shared live auth only" do
    if Code.ensure_loaded?(Oban.Web.Router) do
      assert %{
               plug: Phoenix.LiveView.Plug,
               route: "/ops/jobs/oban",
               phoenix_live_view: {Oban.Web.DashboardLive, :home, _, metadata}
             } =
               Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/oban", "localhost")

      assert %{
               extra: %{
                 on_mount: on_mount_hooks
               }
             } = metadata

      assert Enum.any?(on_mount_hooks, fn %{id: id} ->
               id == {ObanPowertools.Web.LiveAuth, :default}
             end)

      refute File.read!("lib/oban_powertools/web/router.ex") =~ "resolver:"
    end
  end
end
