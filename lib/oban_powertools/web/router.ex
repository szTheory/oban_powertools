defmodule ObanPowertools.Web.Router do
  @moduledoc """
  Provides routing helpers to inject the Oban Powertools Web interface.

  Host applications own the outer `"/ops/jobs"` scope and browser pipeline. This
  module owns only the native Powertools route tree mounted inside that host-owned
  shell.
  """

  @doc """
  Mounts the native Powertools route tree inside a host-owned browser scope.

  The public contract for Phase 8 is:

  - the host router owns the outer `"/ops/jobs"` scope
  - the host router owns `pipe_through(:browser)` for that outer scope
  - `oban_powertools_routes("/oban")` owns only the inner native LiveView routes
    beneath that host-owned scope
  - when `Oban.Web.Router` is available, the optional bridge path is `"/oban"`
    beneath the same host-owned outer scope
  - the optional bridge stays limited to `on_mount: [ObanPowertools.Web.LiveAuth]`
    in this phase

  Resolver, redaction, formatter, and broader policy seams are not introduced
  here. That Phase 9 work remains intentionally out of scope for this mount
  contract.
  """
  defmacro oban_powertools_routes(path) do
    if Code.ensure_loaded?(Phoenix.LiveView.Router) do
      quote do
        import Phoenix.LiveView.Router, only: [live: 3, live: 4, live_session: 3]

        live_session :oban_powertools_native,
          on_mount: [ObanPowertools.Web.LiveAuth],
          session: %{"oban_dashboard_path" => unquote(path)} do
          live("/", ObanPowertools.Web.EngineOverviewLive, :index)
          live("/lifeline", ObanPowertools.Web.LifelineLive, :index)
          live("/limiters", ObanPowertools.Web.LimitersLive, :index)
          live("/cron", ObanPowertools.Web.CronLive, :index)
          live("/audit", ObanPowertools.Web.AuditLive, :index)
          live("/workflows", ObanPowertools.Web.WorkflowsLive, :index)
          live("/workflows/:id", ObanPowertools.Web.WorkflowsLive, :show)
        end

        if Code.ensure_loaded?(Oban.Web.Router) do
          import Oban.Web.Router, only: [oban_dashboard: 2]

          oban_dashboard(unquote(path), on_mount: [ObanPowertools.Web.LiveAuth])
        end
      end
    else
      quote do
        # Phoenix LiveView is not available, skip mounting Powertools routes.
      end
    end
  end
end
