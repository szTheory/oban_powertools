defmodule ObanPowertools.Plugin.CallbackDispatcher do
  @moduledoc """
  An Oban Plugin that periodically polls the `oban_powertools_callbacks` table and
  dispatches them to the appropriate handlers safely and deterministically.

  It handles the following events by routing them to domain dispatchers:
  - `"chain.step_succeeded"` -> `ObanPowertools.Chain.Progression`
  - `"batch.completed"`, `"batch.exhausted"` -> `ObanPowertools.Batch.CallbackDispatcher`
  - `"workflow.terminal"`, `"workflow.recovery_completed"` -> `ObanPowertools.Workflow.Runtime`
  """

  use GenServer
  @behaviour Oban.Plugin

  import Ecto.Query

  alias ObanPowertools.Callback

  @type option ::
          {:interval, pos_integer()}
          | {:limit, pos_integer()}
          | {:lease_seconds, pos_integer()}
          | {:dispatcher_id, String.t()}

  @impl Oban.Plugin
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl Oban.Plugin
  def validate(opts) do
    Oban.Validation.validate(opts, fn validate ->
      validate.integer(:interval, min: 1)
      validate.integer(:limit, min: 1)
      validate.integer(:lease_seconds, min: 1)
      validate.string(:dispatcher_id)
    end)
  end

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)

    state = %{
      conf: opts[:conf],
      name: opts[:name],
      interval: Keyword.get(opts, :interval, :timer.seconds(1)),
      limit: Keyword.get(opts, :limit, 25),
      lease_seconds: Keyword.get(opts, :lease_seconds, 30),
      dispatcher_id:
        Keyword.get(opts, :dispatcher_id) ||
          "plugin:#{node()}:#{System.get_env("USER") || "unknown"}",
      timer: nil
    }

    {:ok, schedule_poll(state)}
  end

  @impl GenServer
  def handle_info(:poll, state) do
    meta = %{conf: state.conf, plugin: __MODULE__}

    :telemetry.span([:oban_powertools, :plugin, :callbacks_dispatched], meta, fn ->
      repo = state.conf.repo
      now = DateTime.utc_now()

      rows = claim_callbacks(repo, now, state.dispatcher_id, state.lease_seconds, state.limit)

      stats =
        Enum.reduce(rows, %{delivered: 0, failed: 0}, fn row, acc ->
          try do
            case dispatch_row(repo, row, now, state.conf.name) do
              :ok -> %{acc | delivered: acc.delivered + 1}
              {:error, _reason} -> %{acc | failed: acc.failed + 1}
            end
          rescue
            exception ->
              mark_failed(repo, row, now, Exception.message(exception))
              %{acc | failed: acc.failed + 1}
          catch
            kind, reason ->
              mark_failed(repo, row, now, inspect({kind, reason}))
              %{acc | failed: acc.failed + 1}
          end
        end)

      {stats, Map.merge(meta, stats)}
    end)

    {:noreply, schedule_poll(state)}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp schedule_poll(state) do
    timer = Process.send_after(self(), :poll, state.interval)
    %{state | timer: timer}
  end

  defp claim_callbacks(repo, now, dispatcher_id, lease_seconds, limit) do
    repo.transaction(fn ->
      lease_expires_at = DateTime.add(now, lease_seconds, :second)

      rows =
        repo.all(
          from(callback in Callback,
            where:
              callback.status in ["pending", "failed", "claimed"] and
                (is_nil(callback.available_at) or callback.available_at <= ^now) and
                (is_nil(callback.lease_expires_at) or callback.lease_expires_at <= ^now),
            order_by: [asc: callback.available_at, asc: callback.inserted_at],
            limit: ^limit,
            lock: "FOR UPDATE SKIP LOCKED"
          )
        )

      Enum.map(rows, fn row ->
        {:ok, claimed} =
          row
          |> Callback.changeset(%{
            status: "claimed",
            claimed_at: now,
            claimed_by: dispatcher_id,
            lease_expires_at: lease_expires_at
          })
          |> repo.update()

        claimed
      end)
    end)
    |> case do
      {:ok, rows} -> rows
      {:error, _reason} -> []
    end
  end

  defp dispatch_row(repo, %Callback{event: "chain.step_succeeded"} = row, now, oban_name) do
    ObanPowertools.Chain.Progression.dispatch_callback(
      repo,
      row,
      now,
      Oban.Registry.whereis(oban_name) || Oban
    )
  end

  defp dispatch_row(repo, %Callback{event: event} = row, now, oban_name)
       when event in ["batch.completed", "batch.exhausted"] do
    ObanPowertools.Batch.CallbackDispatcher.dispatch_callback(
      repo,
      row,
      now,
      Oban.Registry.whereis(oban_name) || Oban
    )
  end

  defp dispatch_row(repo, %Callback{event: event} = row, now, _oban_name)
       when event in ["workflow.terminal", "workflow.recovery_completed"] do
    ObanPowertools.Workflow.Runtime.dispatch_callback(repo, row, now)
  end

  defp mark_failed(repo, row, now, error) do
    row
    |> Callback.changeset(%{
      status: "failed",
      attempts: row.attempts + 1,
      available_at: DateTime.add(now, 30, :second),
      last_error: String.slice(error, 0, 255),
      lease_expires_at: nil
    })
    |> repo.update()
  end
end
