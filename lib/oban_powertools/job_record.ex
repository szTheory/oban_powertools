defmodule ObanPowertools.JobRecord do
  @moduledoc """
  Best-effort durable output records for successful standalone Oban jobs.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @retention_seconds %{
    "ephemeral" => 6 * 60 * 60,
    "standard" => 7 * 24 * 60 * 60,
    "extended" => 30 * 24 * 60 * 60
  }
  @default_output_limit 65_536

  schema "oban_powertools_job_records" do
    field(:oban_job_id, :integer)
    field(:worker, :string)
    field(:attempt, :integer, default: 1)
    field(:status, :string, default: "ok")
    field(:payload, :map, default: %{})
    field(:payload_bytes, :integer, default: 0)
    field(:retention, :string, default: "standard")
    field(:redacted, :boolean, default: false)
    field(:summary, :string)
    field(:recorded_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :oban_job_id,
      :worker,
      :attempt,
      :status,
      :payload,
      :payload_bytes,
      :retention,
      :redacted,
      :summary,
      :recorded_at,
      :expires_at
    ])
    |> validate_required([
      :oban_job_id,
      :worker,
      :attempt,
      :status,
      :payload,
      :payload_bytes,
      :retention,
      :redacted,
      :recorded_at,
      :expires_at
    ])
    |> validate_number(:attempt, greater_than: 0)
    |> validate_number(:payload_bytes, greater_than_or_equal_to: 0)
    |> validate_inclusion(:retention, Map.keys(@retention_seconds))
    |> unique_constraint([:oban_job_id, :attempt])
  end

  def record(repo, worker_name, %Oban.Job{} = job, payload, opts) do
    retention = retention_policy(opts)
    limit = output_limit(opts)

    with {:ok, normalized} <- safe_normalize(payload, job),
         {:ok, encoded} <- safe_encode(normalized, job),
         :ok <- ensure_within_limit(encoded, limit, job),
         {:ok, attrs} <- record_attrs(worker_name, job, normalized, encoded, retention, opts) do
      insert_record(repo, attrs, job)
    else
      {:error, _reason} -> :ok
    end
  rescue
    exception ->
      Logger.warning(
        "could not record output payload for oban_job_id=#{job.id}: #{Exception.message(exception)}"
      )

      :ok
  end

  def fetch_result(%Oban.Job{} = job), do: configured_repo() |> fetch_result(job)

  def fetch_result(oban_job_id) when is_integer(oban_job_id),
    do: configured_repo() |> fetch_result(oban_job_id)

  def fetch_result(repo, %Oban.Job{id: oban_job_id}), do: fetch_result(repo, oban_job_id)

  def fetch_result(repo, oban_job_id) when is_integer(oban_job_id) do
    case fetch_record(repo, oban_job_id) do
      {:ok, %__MODULE__{payload: payload}} -> {:ok, payload}
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  def fetch_record(%Oban.Job{} = job), do: configured_repo() |> fetch_record(job)

  def fetch_record(oban_job_id) when is_integer(oban_job_id),
    do: configured_repo() |> fetch_record(oban_job_id)

  def fetch_record(repo, %Oban.Job{id: oban_job_id}), do: fetch_record(repo, oban_job_id)

  def fetch_record(repo, oban_job_id) when is_integer(oban_job_id) do
    __MODULE__
    |> where([record], record.oban_job_id == ^oban_job_id)
    |> order_by([record], desc: record.recorded_at, desc: record.id)
    |> limit(1)
    |> repo.one()
    |> case do
      nil -> {:error, :not_found}
      %__MODULE__{} = record -> {:ok, record}
    end
  end

  defp safe_normalize(payload, job) do
    {:ok, normalize_payload(payload)}
  rescue
    exception ->
      Logger.warning(
        "could not encode output payload for oban_job_id=#{job.id}: #{Exception.message(exception)}"
      )

      {:error, :normalization_failed}
  end

  defp normalize_payload(%{} = payload) do
    Map.new(payload, fn {key, value} -> {stringify_key(key), normalize_payload(value)} end)
  end

  defp normalize_payload(payload) when is_list(payload),
    do: Enum.map(payload, &normalize_payload/1)

  defp normalize_payload(payload), do: payload

  defp stringify_key(key) when is_binary(key), do: key
  defp stringify_key(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify_key(key), do: to_string(key)

  defp safe_encode(payload, job) do
    {:ok, Jason.encode!(payload)}
  rescue
    exception ->
      Logger.warning(
        "could not encode output payload for oban_job_id=#{job.id}: #{Exception.message(exception)}"
      )

      {:error, :encoding_failed}
  end

  defp ensure_within_limit(encoded, limit, job) do
    size = byte_size(encoded)

    if size <= limit do
      :ok
    else
      Logger.warning(
        "output payload for oban_job_id=#{job.id} exceeds #{limit} bytes; payload_bytes=#{size}"
      )

      {:error, :payload_too_large}
    end
  end

  defp record_attrs(worker_name, %Oban.Job{} = job, payload, encoded, retention, opts) do
    recorded_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    ttl = Map.fetch!(@retention_seconds, retention)

    {:ok,
     %{
       oban_job_id: job.id,
       worker: to_string(worker_name),
       attempt: job.attempt || 1,
       status: to_string(Keyword.get(opts, :status, "ok")),
       payload: payload,
       payload_bytes: byte_size(encoded),
       retention: retention,
       redacted: Keyword.get(opts, :redacted, false),
       summary: Keyword.get(opts, :summary),
       recorded_at: recorded_at,
       expires_at: DateTime.add(recorded_at, ttl, :second)
     }}
  rescue
    exception ->
      Logger.warning(
        "could not prepare output payload record for oban_job_id=#{job.id}: #{Exception.message(exception)}"
      )

      {:error, :invalid_attrs}
  end

  defp insert_record(repo, attrs, job) do
    case repo.insert(changeset(%__MODULE__{}, attrs)) do
      {:ok, _record} ->
        :ok

      {:error, changeset} ->
        Logger.warning(
          "could not insert output payload record for oban_job_id=#{job.id}: #{inspect(changeset.errors)}"
        )

        :ok
    end
  rescue
    exception ->
      Logger.warning(
        "could not insert output payload record for oban_job_id=#{job.id}: #{Exception.message(exception)}"
      )

      :ok
  end

  defp retention_policy(opts) do
    opts
    |> Keyword.get(:output_retention, Keyword.get(opts, :retention, :standard))
    |> normalize_retention()
  end

  defp normalize_retention(retention) when retention in [:ephemeral, :standard, :extended] do
    Atom.to_string(retention)
  end

  defp normalize_retention(retention) when retention in ["ephemeral", "standard", "extended"] do
    retention
  end

  defp normalize_retention(_retention), do: "standard"

  defp output_limit(opts) do
    case Keyword.get(opts, :output_limit, Keyword.get(opts, :limit, @default_output_limit)) do
      limit when is_integer(limit) and limit > 0 -> limit
      _invalid -> @default_output_limit
    end
  end

  defp configured_repo do
    Application.fetch_env!(:oban_powertools, :repo)
  end
end
