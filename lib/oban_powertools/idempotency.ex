defmodule ObanPowertools.Idempotency do
  @moduledoc """
  Handles durable idempotency receipts and atomic job insertion.
  """

  alias Ecto.Multi
  alias ObanPowertools.{Audit, Explain, Limits}
  alias ObanPowertools.Idempotency.Receipt

  defmodule Receipt do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "oban_powertools_idempotency_receipts" do
      field(:worker, :string)
      field(:fingerprint, :string)
      field(:job_id, :integer)
      field(:state, :string, default: "available")
      field(:expires_at, :utc_datetime)

      timestamps()
    end

    def changeset(struct, params) do
      struct
      |> cast(params, [:worker, :fingerprint, :job_id, :state, :expires_at])
      |> validate_required([:worker, :fingerprint])
    end
  end

  @doc """
  Enqueues a job with idempotency check.
  """
  def enqueue(worker_mod, args, opts \\ []) do
    transaction(worker_mod, args, opts)
  end

  @doc """
  Validates args and atomically inserts the receipt plus Oban job.
  """
  def transaction(worker_mod, args, opts \\ []) do
    case worker_mod.validate(args) do
      {:ok, casted_args} ->
        repo = opts[:repo] || infer_repo()
        fingerprint = generate_fingerprint(worker_mod, casted_args)
        do_enqueue(repo, worker_mod, casted_args, fingerprint, opts)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp do_enqueue(repo, worker_mod, args, fingerprint, opts) do
    worker_name = inspect(worker_mod)

    Multi.new()
    |> Multi.run(:limit_reservation, fn repo, _changes ->
      case Limits.reserve(repo, worker_mod, args, opts) do
        {:blocked, blockers} -> {:error, {:blocked, blockers}}
        other -> other
      end
    end)
    |> Multi.insert(
      :receipt,
      Receipt.changeset(%Receipt{}, %{
        worker: worker_name,
        fingerprint: fingerprint,
        state: "available"
      }),
      on_conflict: [set: [state: "available"]],
      conflict_target: [:worker, :fingerprint],
      returning: true
    )
    |> Multi.run(:job, fn repo, %{receipt: receipt} ->
      # If it has a job_id, it was already successfully enqueued
      if is_nil(receipt.job_id) do
        args_map = if is_struct(args), do: Map.from_struct(args), else: args

        job_changeset =
          worker_mod.new(args_map, merge_powertools_meta(opts, worker_mod, args, fingerprint))

        repo.insert(job_changeset)
      else
        {:error, :conflict}
      end
    end)
    |> Multi.run(:update_receipt, fn repo, %{job: job, receipt: receipt} ->
      repo.update(Receipt.changeset(receipt, %{job_id: job.id}))
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{job: job}} ->
        {:ok, job}

      {:error, :limit_reservation, {:blocked, blockers}, _} ->
        persist_blocked_outcome(repo, worker_mod, args, blockers, opts)
        {:blocked, blockers}

      {:error, :job, :conflict, _} ->
        existing_receipt = repo.get_by(Receipt, worker: worker_name, fingerprint: fingerprint)
        existing_job = repo.get(Oban.Job, existing_receipt.job_id)
        {:conflict, existing_job}

      {:error, _name, reason, _} ->
        {:error, reason}
    end
  end

  defp generate_fingerprint(worker_mod, args) do
    args_map = if is_struct(args), do: Map.from_struct(args), else: args

    canonical_payload =
      %{
        worker: inspect(worker_mod),
        args: canonicalize(args_map)
      }
      |> Jason.encode!()

    :crypto.hash(:sha256, canonical_payload) |> Base.encode16(case: :lower)
  end

  defp infer_repo do
    # Just a placeholder to check if Oban is configured
    try do
      Oban.Config.node_name()
    rescue
      _ -> nil
    end

    # In a real app, we'd probably get it from Oban config or Application env
    Application.get_env(:oban_powertools, :repo)
  end

  defp canonicalize(%_{} = struct), do: struct |> Map.from_struct() |> canonicalize()

  defp canonicalize(map) when is_map(map) do
    map
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, value} -> {to_string(key), canonicalize(value)} end)
    |> Map.new()
  end

  defp canonicalize(list) when is_list(list), do: Enum.map(list, &canonicalize/1)
  defp canonicalize(value), do: value

  defp merge_powertools_meta(opts, worker_mod, args, fingerprint) do
    meta = Keyword.get(opts, :meta, %{})
    now = Keyword.get(opts, :now, DateTime.utc_now())
    opts_for_job = Keyword.delete(opts, :now)

    limits_meta =
      case ObanPowertools.Worker.limit_snapshot(worker_mod, args) do
        {:ok, nil} ->
          %{}

        {:ok, snapshot} ->
          %{
            "oban_powertools" => %{
              "idempotency_fingerprint" => fingerprint,
              "limits" => snapshot.binding
            }
          }
      end

    deadline_ms =
      if function_exported?(worker_mod, :__powertools_deadline_ms__, 0) do
        worker_mod.__powertools_deadline_ms__()
      end

    deadline_meta = ObanPowertools.Worker.Deadlines.build_meta(deadline_ms, now)
    powertools_meta = deep_merge(limits_meta, deadline_meta)
    merged_meta = deep_merge(meta, powertools_meta)

    Keyword.put(opts_for_job, :meta, merged_meta)
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, a, b -> deep_merge(a, b) end)
  end

  defp deep_merge(_left, right), do: right

  defp persist_blocked_outcome(repo, worker_mod, args, blockers, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with {:ok, snapshot} when not is_nil(snapshot) <-
           ObanPowertools.Worker.limit_snapshot(worker_mod, args) do
      Audit.record(
        "limiter.blocked",
        %{type: :limiter, id: snapshot.resource_name},
        %{
          "partition_key" => snapshot.partition_key,
          "blocker_codes" => Enum.map(blockers, & &1.code)
        },
        repo: repo
      )

      Explain.persist_snapshot(repo, snapshot, blockers, now: now)
    end
  end
end
