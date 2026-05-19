defmodule ObanPowertools.Lifeline.HeartbeatWriter do
  @moduledoc """
  Periodically refreshes durable executor heartbeats from a configured provider.
  """

  use GenServer

  alias ObanPowertools.Lifeline

  @default_interval_ms 15_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    state = %{
      repo: Keyword.get(opts, :repo, Application.fetch_env!(:oban_powertools, :repo)),
      interval_ms:
        Keyword.get(
          opts,
          :interval_ms,
          Application.get_env(:oban_powertools, :lifeline_heartbeat_interval_ms, @default_interval_ms)
        ),
      provider:
        Keyword.get(opts, :provider, Application.get_env(:oban_powertools, :lifeline_executor_provider))
    }

    schedule_refresh(state.interval_ms)
    {:ok, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    executors =
      case state.provider do
        provider when is_function(provider, 0) -> provider.()
        _ -> []
      end

    _ = Lifeline.refresh_heartbeats(state.repo, executors)
    schedule_refresh(state.interval_ms)
    {:noreply, state}
  end

  defp schedule_refresh(interval_ms) do
    Process.send_after(self(), :refresh, interval_ms)
  end
end
