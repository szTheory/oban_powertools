defmodule ObanPowertools.Web.Selectors do
  @moduledoc """
  Canonical URL selector encoding for Oban Powertools native operator surfaces.

  Centralizes encoding of all `/ops/jobs/...` destination paths behind a single
  helper that applies `URI.encode_query/1` consistently, dropping `nil` and `""`
  values before encoding so callers never need to filter themselves.

  ## Canonical stable selector set

  The following parameter names are the stable public selector contract (Phase 34 D-25):

    - `incident_fingerprint` — incident identity; may contain delimiters (`:`, `/`, `?`, `#`, `%`, ` `, `&`, `=`)
    - `resource_type` — forensic resource scope (`"job"`, `"workflow"`, `"workflow_step"`, `"cron_entry"`, `"limiter"`)
    - `resource_id` — forensic resource identifier
    - `workflow_id` — workflow record ID for workflow-scoped forensic and Lifeline destinations
    - `step` — workflow step name for step-scoped destinations
    - `view` — Lifeline view tab (`"active"`, `"resolved"`)

  ## Permissive non-canonical keys

  The helper is deliberately permissive: non-canonical keys (`row-id`, `action`, `entry`,
  `resource`, `event_type`) pass through `URI.encode_query/1` unchanged so that Lifeline's
  `selection_path/1` and similar callsites can migrate without restructuring their params.

  ## Keyword-list ordering

  Pass a keyword list (not a map) when existing tests assert literal URL order. The helper
  preserves keyword-list iteration order via `URI.encode_query/1` — do NOT convert to a map
  first, because map iteration order is unspecified.

  ## Empty-query behavior

  When all params are `nil` or `""`, the helper returns the bare path without a trailing `?`.
  """

  @canonical_paths %{
    lifeline: "/ops/jobs/lifeline",
    forensics: "/ops/jobs/forensics",
    audit: "/ops/jobs/audit",
    limiters: "/ops/jobs/limiters",
    cron: "/ops/jobs/cron",
    jobs: "/ops/jobs/jobs",
    batches: "/ops/jobs/batches"
  }
  @forensic_keys ~w(resource_type resource_id workflow_id step incident_fingerprint view)
  @jobs_keys ~w(state queue worker tags args meta page job)
  @job_detail_return_keys ~w(state queue worker tags args meta page)

  @doc """
  Encodes `params` for the given `destination` atom and returns the full path.

  `destination` must be one of `:lifeline`, `:forensics`, `:audit`, `:limiters`, `:cron`.
  `params` is a keyword list or map. `nil` and `""` values are dropped before encoding.
  """
  def encode(destination, params) when is_atom(destination) do
    base = Map.fetch!(@canonical_paths, destination)

    query =
      params
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> URI.encode_query()

    if query == "" do
      base
    else
      "#{base}?#{query}"
    end
  end

  @doc "Returns the `/ops/jobs/lifeline` path with the given params encoded."
  def lifeline_path(params), do: encode(:lifeline, params)

  @doc """
  Returns the `/ops/jobs/forensics` path with exactly six keys in canonical order.
  """
  def forensic_path(params), do: encode(:forensics, ordered_params(params, @forensic_keys))

  @doc "Returns the `/ops/jobs/audit` path with the given params encoded."
  def audit_path(params), do: encode(:audit, params)

  @doc "Returns the `/ops/jobs/limiters` path with the given params encoded."
  def limiter_path(params), do: encode(:limiters, params)

  @doc "Returns the `/ops/jobs/cron` path with the given params encoded."
  def cron_path(params), do: encode(:cron, params)

  @doc """
  Returns the `/ops/jobs/jobs` path with closed Jobs params in canonical order.
  """
  def jobs_path(params \\ []) do
    encode(:jobs, ordered_params(params, @jobs_keys))
  end

  @doc "Returns the path for a specific job detail page."
  def job_detail_path(id), do: job_detail_path(id, [])

  @doc """
  Returns a job detail path with only canonical list return context.

  Quick review, opaque `return_to`, and unknown values are never propagated.
  """
  def job_detail_path(id, params) do
    base = "#{@canonical_paths.jobs}/#{id}"
    encode_path(base, ordered_params(params, @job_detail_return_keys))
  end

  @doc "Returns the `/ops/jobs/batches` path with the given params encoded."
  def batches_path(params \\ []), do: encode(:batches, params)

  @doc "Returns the path for a specific batch detail page."
  def batch_detail_path(id), do: "#{@canonical_paths.batches}/#{id}"

  defp ordered_params(params, keys) do
    values = Map.new(params, fn {key, value} -> {to_string(key), value} end)
    Enum.map(keys, &{&1, Map.get(values, &1)})
  end

  defp encode_path(base, params) do
    query =
      params
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> URI.encode_query()

    if query == "", do: base, else: "#{base}?#{query}"
  end
end
