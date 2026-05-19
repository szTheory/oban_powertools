defmodule ObanPowertools.Idempotency do
  @moduledoc """
  Handles durable idempotency receipts and atomic job insertion.
  """
  alias Ecto.Multi
  alias ObanPowertools.Idempotency.Receipt

  defmodule Receipt do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "oban_powertools_idempotency_receipts" do
      field :worker, :string
      field :fingerprint, :string
      field :job_id, :integer
      field :state, :string, default: "available"
      field :expires_at, :utc_datetime

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
    |> Multi.insert(:receipt, Receipt.changeset(%Receipt{}, %{
      worker: worker_name,
      fingerprint: fingerprint,
      state: "available"
    }), on_conflict: [set: [state: "available"]], conflict_target: [:worker, :fingerprint], returning: true)
    |> Multi.run(:job, fn repo, %{receipt: receipt} ->
      # If it has a job_id, it was already successfully enqueued
      if is_nil(receipt.job_id) do
        args_map = if is_struct(args), do: Map.from_struct(args), else: args
        job_changeset = worker_mod.new(args_map, opts)
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
    data = [inspect(worker_mod), args_map] |> Jason.encode!()
    :crypto.hash(:sha256, data) |> Base.encode16()
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
end
