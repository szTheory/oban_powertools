defmodule ObanPowertools.Chain.Progression do
  @moduledoc """
  Event-scoped callback dispatcher for linear chain progression.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias ObanPowertools.Callback

  def dispatch_callbacks(repo, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    limit = Keyword.get(opts, :limit, 25)
    lease_seconds = Keyword.get(opts, :lease_seconds, 30)
    oban = Keyword.get(opts, :oban, Oban)

    dispatcher_id =
      Keyword.get(opts, :dispatcher_id) ||
        "chain:#{node()}:#{System.get_env("USER") || "unknown"}"

    rows = claim_callbacks(repo, now, dispatcher_id, lease_seconds, limit)

    Enum.reduce(rows, %{delivered: 0, failed: 0}, fn row, acc ->
      case dispatch_callback(repo, row, now, oban) do
        :ok -> %{acc | delivered: acc.delivered + 1}
        {:error, _reason} -> %{acc | failed: acc.failed + 1}
      end
    end)
  end

  defp claim_callbacks(repo, now, dispatcher_id, lease_seconds, limit) do
    repo.transaction(fn ->
      lease_expires_at = DateTime.add(now, lease_seconds, :second)

      rows =
        repo.all(
          from(callback in Callback,
            where:
              callback.event == "chain.step_succeeded" and
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

  defp dispatch_callback(repo, %Callback{} = row, now, oban) do
    case insert_next_job(row, oban) do
      :ok ->
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

  defp insert_next_job(%Callback{payload: %{"next_step" => nil}}, _oban), do: :ok

  defp insert_next_job(%Callback{payload: %{"next_step" => %{"step" => step, "remaining" => remaining}} = payload}, oban)
       when is_map(step) and is_list(remaining) do
    changeset = next_job_changeset(step, remaining, payload)

    case do_oban_insert(oban, changeset) do
      {:ok, _job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp insert_next_job(_row, _oban), do: {:error, :invalid_next_step}

  defp next_job_changeset(step, remaining, payload) do
    worker = fetch_descriptor!(step, "worker")
    args = Map.get(step, "args") || %{}
    queue = Map.get(step, "queue") || "default"
    opts = Map.get(step, "opts") || %{}

    meta =
      (Map.get(step, "meta") || %{})
      |> Map.merge(%{
        "batch_id" => fetch_payload!(payload, "batch_id"),
        "chain_id" => fetch_payload!(payload, "chain_id"),
        "chain_step_name" => fetch_descriptor!(step, "name"),
        "chain_step_index" => fetch_descriptor!(step, "index"),
        "chain_step_count" => fetch_payload!(payload, "step_count"),
        "upstream_job_id" => fetch_payload!(payload, "upstream_job_id")
      })
      |> maybe_put_next_tail(remaining)

    oban_opts =
      opts
      |> atomize_option_keys()
      |> Keyword.merge(worker: worker, queue: queue, meta: meta)

    Oban.Job.new(args, oban_opts)
  end

  defp fetch_descriptor!(map, key) do
    case Map.fetch(map, key) do
      {:ok, nil} -> raise ArgumentError, "chain next-step descriptor #{key} is nil"
      {:ok, value} -> value
      :error -> raise ArgumentError, "chain next-step descriptor missing #{key}"
    end
  end

  defp fetch_payload!(map, key) do
    case Map.fetch(map, key) do
      {:ok, nil} -> raise ArgumentError, "chain callback payload #{key} is nil"
      {:ok, value} -> value
      :error -> raise ArgumentError, "chain callback payload missing #{key}"
    end
  end

  defp maybe_put_next_tail(meta, []), do: meta

  defp maybe_put_next_tail(meta, [next_step | remaining]) do
    Map.put(meta, "chain_next_step", %{"step" => next_step, "remaining" => remaining})
  end

  defp atomize_option_keys(opts) when is_map(opts) do
    Enum.map(opts, fn
      {key, value} when is_atom(key) -> {key, value}
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
    end)
  end

  defp atomize_option_keys(_opts), do: []

  defp do_oban_insert(Oban, %Changeset{} = changeset), do: Oban.insert(changeset)
  defp do_oban_insert(oban, %Changeset{} = changeset), do: Oban.insert(oban, changeset)

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
        last_error: inspect(reason)
      })
    )
  end
end
