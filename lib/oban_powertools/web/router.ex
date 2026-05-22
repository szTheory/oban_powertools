defmodule ObanPowertools.Web.Router do
  @moduledoc """
  Provides routing helpers to inject the Oban Powertools Web interface.

  Host applications own the outer `"/ops/jobs"` scope and browser pipeline. This
  module owns only the native Powertools route tree mounted inside that host-owned
  shell. Native Powertools pages own audited mutations, while the optional
  `/ops/jobs/oban` bridge stays a nested read-only inspection surface.
  """

  @doc """
  Mounts the native Powertools route tree inside a host-owned browser scope.

  The public contract for the optional bridge is:

  - the host router owns the outer `"/ops/jobs"` scope
  - the host router owns `pipe_through(:browser)` for that outer scope
  - `oban_powertools_routes("/oban")` owns only the inner native LiveView routes
    beneath that host-owned scope
  - when `Oban.Web.Router` is available, the optional bridge path is `"/oban"`
    beneath the same host-owned outer scope
  - the optional bridge reuses `ObanPowertools.Web.LiveAuth` plus a Powertools-
    owned resolver adapter over documented `Oban.Web.Resolver` hooks
  - the optional bridge remains read-only, while native Powertools pages own
    audited mutations

  The optional bridge contract stays thin. Powertools owns only the nested
  mount, actor handoff, access mapping, and shared display formatting hooks. It
  does not become a shadow dashboard or generic Oban Web plugin surface, and it
  does not replace native Powertools pages for audited mutations.
  """
  defmacro oban_powertools_routes(path) do
    oban_web_router = Module.concat([Oban, Web, Router])

    if Code.ensure_loaded?(Phoenix.LiveView.Router) do
      bridge_routes =
        if Code.ensure_loaded?(oban_web_router) do
          quote do
            import unquote(oban_web_router), only: [oban_dashboard: 2]

            oban_dashboard(unquote(path),
              resolver: ObanPowertools.Web.ObanWebBridge,
              on_mount: [ObanPowertools.Web.LiveAuth]
            )
          end
        else
          quote(do: nil)
        end

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

        unquote(bridge_routes)
      end
    else
      quote do
        # Phoenix LiveView is not available, skip mounting Powertools routes.
      end
    end
  end
end
