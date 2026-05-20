defmodule ObanPowertools.Web.Router do
  @moduledoc """
  Provides routing helpers to inject the Oban Powertools Web interface.
  """

  @doc """
  Mounts the Oban Powertools Web interface at the given path.
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
