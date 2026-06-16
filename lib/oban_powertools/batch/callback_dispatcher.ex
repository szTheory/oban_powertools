defmodule ObanPowertools.Batch.CallbackDispatcher do
  @moduledoc """
  Event-scoped dispatcher for converting batch callback rows into enqueued 
  `ObanPowertools.Worker.BatchCallback` jobs.
  """

  alias ObanPowertools.Callback
  alias ObanPowertools.Worker.BatchCallback

  @doc false
  def dispatch_callback(repo, %Callback{} = row, now, oban) do
    # Expected payload format:
    # %{
    #   "callback" => %{"module" => "MyApp.Callback", "function" => "handle_batch", "queue" => "callbacks"},
    #   "batch_id" => "123",
    #   "event" => "completed", # or exhausted
    #   ...
    # }

    with {:ok, callback_def} <- fetch_callback_def(row.payload),
         {:ok, args} <- build_args(callback_def, row),
         opts <- build_opts(callback_def),
         changeset <- BatchCallback.new(args, opts) do
      case do_oban_insert(oban, changeset) do
        {:ok, _job} ->
          mark_delivered(repo, row, now)
          :ok

        {:error, reason} ->
          mark_failed(repo, row, now, reason)
          {:error, reason}
      end
    else
      {:error, :no_callback_defined} ->
        # No callback to run, just mark as delivered
        mark_delivered(repo, row, now)
        :ok

      {:error, reason} ->
        mark_failed(repo, row, now, reason)
        {:error, reason}
    end
  rescue
    error ->
      mark_failed(repo, row, now, error)
      {:error, error}
  catch
    kind, reason ->
      caught = {kind, reason}
      mark_failed(repo, row, now, caught)
      {:error, caught}
  end

  defp fetch_callback_def(%{"callback" => %{"module" => _} = callback_def}),
    do: {:ok, callback_def}

  defp fetch_callback_def(_payload), do: {:error, :no_callback_defined}

  defp build_args(%{"module" => module} = callback_def, row) do
    function = Map.get(callback_def, "function", "process")

    # We pass the entire row payload to the host callback
    args = %{
      "module" => module,
      "function" => function,
      "payload" => row.payload
    }

    {:ok, args}
  end

  defp build_opts(callback_def) do
    opts = []

    opts =
      if queue = Map.get(callback_def, "queue") do
        Keyword.put(opts, :queue, String.to_existing_atom(queue))
      else
        opts
      end

    opts =
      if max_attempts = Map.get(callback_def, "max_attempts") do
        Keyword.put(opts, :max_attempts, max_attempts)
      else
        opts
      end

    opts
  end

  defp do_oban_insert(Oban, changeset), do: Oban.insert(changeset)
  defp do_oban_insert(oban, changeset), do: Oban.insert(oban, changeset)

  defp mark_delivered(repo, %Callback{} = row, now) do
    repo.update!(
      Callback.changeset(row, %{
        status: "delivered",
        attempts: row.attempts + 1,
        delivered_at: now,
        lease_expires_at: nil,
        last_error: nil
      })
    )
  end

  defp mark_failed(repo, %Callback{} = row, now, reason) do
    repo.update!(
      Callback.changeset(row, %{
        status: "failed",
        attempts: row.attempts + 1,
        available_at: DateTime.add(now, 30, :second),
        lease_expires_at: nil,
        last_error: String.slice(inspect(reason), 0, 255)
      })
    )
  end
end
