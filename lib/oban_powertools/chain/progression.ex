defmodule ObanPowertools.Chain.Progression do
  @moduledoc """
  Event-scoped callback dispatcher for linear chain progression.
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias ObanPowertools.Callback
  alias ObanPowertools.Chain

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
    case insert_next_job(repo, row, oban) do
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

  defp insert_next_job(_repo, %Callback{payload: %{"next_step" => nil}}, _oban), do: :ok

  defp insert_next_job(
         repo,
         %Callback{
           payload: %{"next_step" => %{"step" => step, "remaining" => remaining}} = payload
         },
         oban
       )
       when is_map(step) and is_list(remaining) do
    with {:ok, changeset, progression_key} <- next_job_changeset(repo, step, remaining, payload) do
      if progression_job_exists?(repo, progression_key) do
        :ok
      else
        case do_oban_insert(oban, changeset) do
          {:ok, _job} -> :ok
          {:error, reason} -> {:error, reason}
        end
      end
    end
  end

  defp insert_next_job(_repo, _row, _oban), do: {:error, :invalid_next_step}

  defp next_job_changeset(repo, step, remaining, payload) do
    worker = fetch_descriptor!(step, "worker")
    queue = Map.get(step, "queue") || "default"
    opts = Map.get(step, "opts") || %{}
    args = resolve_args(repo, step, payload)
    progression_key = progression_key(payload, step)

    meta =
      (Map.get(step, "meta") || %{})
      |> Map.merge(%{
        "batch_id" => fetch_payload!(payload, "batch_id"),
        "chain_id" => fetch_payload!(payload, "chain_id"),
        "chain_step_name" => fetch_descriptor!(step, "name"),
        "chain_step_index" => fetch_descriptor!(step, "index"),
        "chain_step_count" => fetch_payload!(payload, "step_count"),
        "upstream_job_id" => fetch_payload!(payload, "upstream_job_id"),
        "chain_progression_key" => progression_key
      })
      |> maybe_put_next_tail(remaining)

    oban_opts =
      opts
      |> atomize_option_keys()
      |> Keyword.merge(worker: worker, queue: queue, meta: meta)

    {:ok, Oban.Job.new(args, oban_opts), progression_key}
  end

  defp progression_key(payload, step) do
    "chain.step_succeeded:#{fetch_payload!(payload, "chain_id")}:#{fetch_descriptor!(step, "index")}:#{fetch_payload!(payload, "upstream_job_id")}"
  end

  defp progression_job_exists?(repo, progression_key) do
    repo.one(
      from(job in Oban.Job,
        where: fragment("?->>? = ?", job.meta, "chain_progression_key", ^progression_key),
        select: job.id,
        limit: 1
      )
    ) != nil
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

  defp resolve_args(repo, %{"args_builder" => %{} = builder}, payload) do
    upstream_job_id = fetch_payload!(payload, "upstream_job_id")

    with {:ok, upstream_payload} <- Chain.fetch_upstream_result(repo, upstream_job_id),
         {:ok, module} <- builder_module(builder),
         {:ok, function} <- builder_function(builder),
         :ok <- safe_builder?(module),
         {:ok, args} <-
           apply_builder(module, function, upstream_payload, Map.get(builder, "extra_args") || []) do
      args
    else
      {:error, reason} -> throw({:chain_args_builder_failed, reason})
    end
  end

  defp resolve_args(_repo, step, _payload), do: Map.get(step, "args") || %{}

  defp builder_module(%{"module" => module}) when is_binary(module) do
    {:ok, Module.safe_concat([module])}
  rescue
    ArgumentError -> {:error, {:unsafe_args_builder, module}}
  end

  defp builder_module(%{"module" => module}) when is_atom(module), do: {:ok, module}
  defp builder_module(_builder), do: {:error, :invalid_args_builder}

  defp builder_function(%{"function" => function}) when is_binary(function) do
    {:ok, String.to_existing_atom(function)}
  rescue
    ArgumentError -> {:error, {:invalid_args_builder, function}}
  end

  defp builder_function(%{"function" => function}) when is_atom(function), do: {:ok, function}
  defp builder_function(_builder), do: {:error, :invalid_args_builder}

  defp safe_builder?(module) do
    if Code.ensure_loaded?(module) and
         function_exported?(module, :__powertools_chain_args_builder__, 0) and
         module.__powertools_chain_args_builder__() == true do
      :ok
    else
      {:error, {:unsafe_args_builder, module}}
    end
  end

  defp apply_builder(module, function, upstream_payload, extra_args) when is_list(extra_args) do
    if function_exported?(module, function, 2) do
      case apply(module, function, [upstream_payload, extra_args]) do
        {:ok, args} when is_map(args) -> {:ok, args}
        args when is_map(args) -> {:ok, args}
        {:error, reason} -> {:error, reason}
        other -> {:error, {:invalid_args_builder_return, other}}
      end
    else
      {:error, {:invalid_args_builder, {module, function}}}
    end
  rescue
    error -> {:error, error}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp apply_builder(module, function, _upstream_payload, _extra_args),
    do: {:error, {:invalid_args_builder, {module, function}}}

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
