defmodule ObanPowertools.Operator do
  @moduledoc """
  Programmatic API for host applications to perform operational mutations 
  on jobs and workflows.
  """

  alias ObanPowertools.Lifeline
  alias ObanPowertools.Jobs

  @doc """
  Lists jobs matching the given filters.
  Filters can be a map, keyword list, or a `%ObanPowertools.Jobs{}` struct.
  """
  def list(repo, filters \\ %{}, opts \\ []) do
    filters =
      case filters do
        %Jobs{} = struct ->
          struct

        kw when is_list(kw) ->
          struct(Jobs, kw)

        map when is_map(map) ->
          atom_map =
            Map.new(map, fn
              {k, v} when is_binary(k) ->
                try do
                  {String.to_existing_atom(k), v}
                rescue
                  ArgumentError -> {k, v}
                end

              {k, v} ->
                {k, v}
            end)

          struct(Jobs, atom_map)
      end

    Jobs.list(repo, filters, opts)
  end

  @doc """
  Retries a job from its current state, routing through the native repair flow.
  """
  def retry_job(repo, actor, job_id, reason, opts \\ []) do
    do_repair(repo, actor, "job_retry", job_id, reason, opts)
  end

  @doc """
  Cancels a job, routing through the native repair flow.
  """
  def cancel_job(repo, actor, job_id, reason, opts \\ []) do
    do_repair(repo, actor, "job_cancel", job_id, reason, opts)
  end

  @doc """
  Discards a job, routing through the native repair flow.
  """
  def discard_job(repo, actor, job_id, reason, opts \\ []) do
    do_repair(repo, actor, "job_discard", job_id, reason, opts)
  end

  @doc """
  Retries a list of jobs from their current state, routing through the native repair flow.
  Returns `%{successes: [job_id], failures: [{job_id, error}]}`.
  """
  def bulk_retry_jobs(repo, actor, job_ids, reason, opts \\ []) do
    do_bulk_repair(repo, actor, "job_retry", job_ids, reason, opts)
  end

  @doc """
  Cancels a list of jobs, routing through the native repair flow.
  Returns `%{successes: [job_id], failures: [{job_id, error}]}`.
  """
  def bulk_cancel_jobs(repo, actor, job_ids, reason, opts \\ []) do
    do_bulk_repair(repo, actor, "job_cancel", job_ids, reason, opts)
  end

  @doc """
  Discards a list of jobs, routing through the native repair flow.
  Returns `%{successes: [job_id], failures: [{job_id, error}]}`.
  """
  def bulk_discard_jobs(repo, actor, job_ids, reason, opts \\ []) do
    do_bulk_repair(repo, actor, "job_discard", job_ids, reason, opts)
  end

  defp do_bulk_repair(repo, actor, action, job_ids, reason, opts) do
    Enum.reduce(job_ids, %{successes: [], failures: []}, fn job_id, acc ->
      try do
        case do_repair(repo, actor, action, job_id, reason, opts) do
          {:ok, _result} ->
            %{acc | successes: [job_id | acc.successes]}

          {:error, error} ->
            %{acc | failures: [{job_id, error} | acc.failures]}
        end
      rescue
        Ecto.NoResultsError ->
          %{acc | failures: [{job_id, :not_found} | acc.failures]}
      end
    end)
    |> Map.update!(:successes, &Enum.reverse/1)
    |> Map.update!(:failures, &Enum.reverse/1)
  end

  defp do_repair(repo, actor, action, job_id, reason, opts) do
    opts = Keyword.put(opts, :telemetry_metadata, %{source: "api"})

    attrs = %{
      action: action,
      target_type: "job",
      target_id: job_id
    }

    with {:ok, preview} <- Lifeline.preview_repair(repo, actor, attrs, opts),
         {:ok, result} <-
           Lifeline.execute_repair(repo, actor, preview.preview_token, reason, opts) do
      {:ok, result}
    end
  end
end
