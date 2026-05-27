defmodule ObanPowertools.Forensics.AttentionProjection do
  @moduledoc false

  alias ObanPowertools.Forensics.Provenance

  @bucket_limit 3

  @completeness_labels %{
    complete: "complete",
    partial_evidence: "partial evidence",
    history_unavailable: "history unavailable",
    unknown: "unknown"
  }

  def project(candidates) when is_list(candidates) do
    candidates
    |> Enum.group_by(&field(&1, :bucket))
    |> Map.new(fn {bucket, bucket_candidates} ->
      {bucket, project_bucket(bucket, bucket_candidates)}
    end)
  end

  def project_bucket(bucket, candidates) when is_list(candidates) do
    candidates
    |> Enum.filter(&(field(&1, :bucket) == bucket))
    |> Enum.map(&normalize_candidate/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(&{&1.rank, &1.label, &1.source})
    |> Enum.take(@bucket_limit)
    |> Enum.map(&Map.drop(&1, [:rank]))
  end

  defp normalize_candidate(candidate) when is_map(candidate) do
    path = field(candidate, :path)
    evidence_path = field(candidate, :evidence_path)

    if blank?(path) do
      nil
    else
      completeness =
        candidate
        |> field(:evidence_completeness)
        |> Provenance.normalize_completeness()

      %{
        label: field(candidate, :label),
        fact: field(candidate, :fact) || field(candidate, :attention_reason),
        attention_reason: field(candidate, :attention_reason),
        evidence_completeness: completeness_label(completeness),
        path: path,
        evidence_path: evidence_path,
        venue: field(candidate, :venue),
        ownership: field(candidate, :ownership),
        source: field(candidate, :source),
        rank: rank(candidate, completeness)
      }
    end
  end

  defp rank(candidate, completeness) do
    cond do
      active_lifeline?(candidate) -> 0
      blocked_limiter?(candidate) -> 10
      cron_attention?(candidate) -> 20
      blocked_workflow?(candidate) -> 30
      completeness in [:partial_evidence, :history_unavailable, :unknown] -> 40
      resolved_continuity?(candidate) -> 50
      true -> numeric_field(candidate, :rank, 90)
    end
  end

  defp active_lifeline?(candidate),
    do:
      field(candidate, :family) in [:lifeline, "lifeline"] and
        field(candidate, :status) in [:active, "active"]

  defp blocked_limiter?(candidate),
    do:
      field(candidate, :family) in [:limiter, "limiter"] and
        field(candidate, :status) in [:blocked, "blocked", :cooling_down, "cooling_down"]

  defp cron_attention?(candidate),
    do:
      field(candidate, :family) in [:cron, "cron"] and
        field(candidate, :status) in [
          :missed_fire,
          "missed_fire",
          :unknown,
          "unknown",
          :partial_evidence,
          "partial_evidence"
        ]

  defp blocked_workflow?(candidate),
    do:
      field(candidate, :family) in [:workflow, "workflow"] and
        field(candidate, :status) in [
          :blocked,
          "blocked",
          :waiting_on_dependencies,
          "waiting_on_dependencies"
        ]

  defp resolved_continuity?(candidate),
    do:
      field(candidate, :status) in [
        :resolved,
        "resolved",
        :recently_resolved,
        "recently_resolved"
      ]

  defp completeness_label(completeness), do: Map.fetch!(@completeness_labels, completeness)

  defp field(map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp numeric_field(map, key, default) do
    case field(map, key) do
      value when is_integer(value) -> value
      value when is_float(value) -> value
      _value -> default
    end
  end

  defp blank?(value), do: is_nil(value) or value == ""
end
