defmodule ObanPowertools.Web.Router do
  @moduledoc """
  Provides routing helpers to inject the Oban Powertools Web interface.
  """

  @doc """
  Mounts the Oban Powertools Web interface at the given path.
  """
  defmacro oban_powertools_routes(path) do
    if Code.ensure_loaded?(Oban.Web.Router) do
      quote do
        import Phoenix.LiveView.Router, only: [live_session: 3]
        import Oban.Web.Router, only: [oban_dashboard: 1]

        live_session :oban_powertools, on_mount: [] do
          oban_dashboard(unquote(path))
        end
      end
    else
      quote do
        # Oban Web is not available, provide fallback or skip
      end
    end
  end
end