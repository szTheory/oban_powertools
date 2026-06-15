defmodule ObanPowertools.Web.RouterTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Web.ObanWebBridge
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
             phoenix_live_view: {ObanPowertools.Web.ForensicsLive, :index, _, _}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/forensics", "localhost")

    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ObanPowertools.Web.WorkflowsLive, :index, _, _}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/workflows", "localhost")

    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ObanPowertools.Web.BatchesLive, :index, _, _}
           } =
             Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/batches", "localhost")

    assert %{
             plug: Phoenix.LiveView.Plug,
             phoenix_live_view: {ObanPowertools.Web.BatchesLive, :show, _, _}
           } =
             Phoenix.Router.route_info(
               TestRouter,
               "GET",
               "/ops/jobs/batches/batch-1",
               "localhost"
             )
  end

  test "the host-owned outer scope does not expose the bridge at the router root" do
    assert :error = Phoenix.Router.route_info(TestRouter, "GET", "/oban", "localhost")
  end

  test "the optional oban_web bridge mounts under /ops/jobs/oban with the bounded powertools bridge contract" do
    if Code.ensure_loaded?(Oban.Web.Router) do
      assert %{
               plug: Phoenix.LiveView.Plug,
               route: "/ops/jobs/oban",
               phoenix_live_view: {Oban.Web.DashboardLive, :home, _, metadata}
             } =
               Phoenix.Router.route_info(TestRouter, "GET", "/ops/jobs/oban", "localhost")

      assert %{
               extra: %{
                 session:
                   {Oban.Web.Router, :__session__, ["/ops/jobs/oban", nil, resolver, _, _, _, _]},
                 on_mount: on_mount_hooks
               }
             } = metadata

      assert resolver == ObanPowertools.Web.ObanWebBridge

      assert Enum.any?(on_mount_hooks, fn %{id: id} ->
               id == {ObanPowertools.Web.LiveAuth, :default}
             end)

      assert Enum.any?(on_mount_hooks, fn %{id: id} ->
               id == {Oban.Web.Authentication, :default}
             end)
    end
  end

  test "the optional oban_web bridge stays a read-only inspection surface behind the shared powertools auth seam" do
    if Code.ensure_loaded?(Oban.Web.Router) do
      assert ObanWebBridge.resolve_access(%{id: "ops-1", permissions: [:view_oban_web]}) ==
               :read_only

      assert ObanWebBridge.resolve_access(%{id: "ops-2", permissions: []}) ==
               {:forbidden, "/ops/jobs"}
    end
  end

  test "bridge docs state the phase 10 support truth" do
    assert moduledoc(ObanWebBridge) =~ "read-only"
    assert moduledoc(ObanWebBridge) =~ "Powertools-native pages"
    assert moduledoc(ObanWebBridge) =~ "Inspection only"
    assert moduledoc(ObanWebBridge) =~ "Audited action"
    assert moduledoc(ObanPowertools.Web.Router) =~ "audited mutations"
  end

  defp moduledoc(module) do
    {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} = Code.fetch_docs(module)
    moduledoc
  end
end
