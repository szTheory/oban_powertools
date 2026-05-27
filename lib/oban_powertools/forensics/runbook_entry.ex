defmodule ObanPowertools.Forensics.RunbookEntry do
  @moduledoc false

  alias ObanPowertools.Forensics.Provenance

  @ownership_labels %{
    powertools_native: "Powertools-native",
    oban_web_bridge: "Oban Web bridge",
    host_owned: "host-owned follow-up"
  }
  @continuity_attempt_states ~w(previewed attempted succeeded drifted expired consumed)

  def from_bundle(bundle) when is_map(bundle) do
    diagnosis = field(bundle, :diagnosis_summary) || %{}
    subject = field(bundle, :subject) || %{}
    completeness = normalize_completeness(field(bundle, :completeness))
    next_paths = field(bundle, :legal_next_paths) || []
    continuity = field(bundle, :continuity) || field(subject, :continuity)

    build(%{
      title: "Open runbook entry",
      diagnosis_state: field(diagnosis, :current) || "unknown",
      why_now:
        field(diagnosis, :detail) || "No diagnosis detail is available for this forensic scope.",
      prerequisites: prerequisites(completeness, next_paths),
      cautions: cautions(completeness, next_paths, continuity),
      ordered_next_paths: ordered_next_paths(next_paths),
      evidence_path: evidence_path(subject),
      unsupported_boundaries: unsupported_boundaries(completeness),
      evidence_completeness: completeness
    })
  end

  def build(attrs) when is_map(attrs) do
    %{
      title: field(attrs, :title) || "Open runbook entry",
      diagnosis_state: to_string(field(attrs, :diagnosis_state) || "unknown"),
      why_now:
        field(attrs, :why_now) || "No diagnosis detail is available for this forensic scope.",
      prerequisites:
        attrs
        |> field(:prerequisites)
        |> List.wrap()
        |> Enum.map(&normalize_prerequisite/1),
      cautions:
        attrs
        |> field(:cautions)
        |> List.wrap()
        |> Enum.map(&normalize_caution/1),
      ordered_next_paths:
        attrs
        |> field(:ordered_next_paths)
        |> List.wrap()
        |> Enum.with_index(1)
        |> Enum.map(fn {path, index} -> normalize_next_path(path, index) end),
      evidence_path: blank_to_nil(field(attrs, :evidence_path)),
      unsupported_boundaries: List.wrap(field(attrs, :unsupported_boundaries)),
      evidence_completeness: normalize_completeness(field(attrs, :evidence_completeness))
    }
  end

  defp prerequisites(completeness, next_paths) do
    [
      %{
        label: "Evidence bundle",
        state: prerequisite_state(completeness.state == :complete),
        detail: completeness.details
      },
      %{
        label: "Legal next path",
        state: prerequisite_state(next_paths != []),
        detail: legal_path_detail(next_paths)
      }
    ]
  end

  defp cautions(completeness, next_paths, continuity) do
    [
      %{
        label: "Advisory boundary",
        detail:
          "Phase 34 runbook guidance is advisory only and evidence-grounded; operators must choose the next honest venue before acting.",
        severity: :info
      },
      degraded_caution(completeness),
      bridge_caution(next_paths),
      host_owned_caution(next_paths),
      continuity_caution(continuity)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp continuity_caution(nil), do: nil

  defp continuity_caution(continuity) when is_map(continuity) do
    attempt_state =
      field(continuity, :attempt_state) ||
        get_in(field(continuity, :runbook_context) || %{}, ["attempt", "state"])

    with normalized_state when normalized_state in @continuity_attempt_states <-
           normalize_attempt_state(attempt_state) do
      selected_path =
        field(continuity, :selected_path) ||
          get_in(field(continuity, :runbook_context) || %{}, ["selected_path"]) ||
          %{}

      ownership = normalize_continuity_ownership(field(selected_path, :ownership))
      venue = field(selected_path, :venue) || ownership
      action = field(continuity, :action) || "native remediation"
      reason = field(continuity, :reason)

      %{
        label: "Remediation continuity",
        detail:
          "Latest Powertools-native remediation attempt state is #{normalized_state}. " <>
            "Action: #{action}. Ownership: #{ownership}. Venue: #{venue}." <>
            continuity_reason_detail(reason),
        severity: :info
      }
    else
      _missing ->
        nil
    end
  end

  defp degraded_caution(%{state: :partial_evidence, details: details}) do
    %{label: "partial evidence", detail: details, severity: :warning}
  end

  defp degraded_caution(%{state: :history_unavailable, details: details}) do
    %{label: "history unavailable", detail: details, severity: :warning}
  end

  defp degraded_caution(%{state: :unknown, details: details}) do
    %{label: "unknown", detail: details, severity: :warning}
  end

  defp degraded_caution(_completeness), do: nil

  defp bridge_caution(next_paths) do
    if Enum.any?(next_paths, &(ownership(&1) == :oban_web_bridge)) do
      %{
        label: "Oban Web bridge",
        detail:
          "Oban Web bridge paths are inspection-only and must not be presented as native action controls.",
        severity: :info
      }
    end
  end

  defp host_owned_caution(next_paths) do
    if Enum.any?(next_paths, &(ownership(&1) == :host_owned)) do
      %{
        label: "host-owned follow-up",
        detail:
          "host-owned follow-up paths point outside Powertools ownership and may require external coordination.",
        severity: :info
      }
    end
  end

  defp ordered_next_paths(next_paths) do
    next_paths
    |> Enum.with_index(1)
    |> Enum.map(fn {path, index} -> normalize_next_path(path, index) end)
  end

  defp normalize_next_path(path, index) when is_map(path) do
    ownership = ownership(path)
    label = field(path, :label) || "Review follow-up path"

    %{
      order: index,
      label: label_for_path(ownership, label),
      venue: field(path, :venue) || @ownership_labels[ownership],
      ownership: @ownership_labels[ownership],
      path: blank_to_nil(field(path, :path)),
      intent: normalize_intent(field(path, :intent) || infer_intent(label))
    }
  end

  defp normalize_next_path(_path, index) do
    %{
      order: index,
      label: "host-owned follow-up: Review follow-up path",
      venue: "host-owned follow-up",
      ownership: "host-owned follow-up",
      path: nil,
      intent: :investigate
    }
  end

  defp label_for_path(:powertools_native, label), do: label

  defp label_for_path(ownership, label) do
    prefix = Map.fetch!(@ownership_labels, ownership)

    if String.starts_with?(label, prefix <> ":") do
      label
    else
      "#{prefix}: #{label}"
    end
  end

  defp ownership(path) do
    venue =
      path
      |> field(:venue)
      |> to_string()
      |> String.downcase()

    cond do
      String.contains?(venue, "powertools-native") -> :powertools_native
      String.contains?(venue, "lifeline") -> :powertools_native
      String.contains?(venue, "inspection only") -> :oban_web_bridge
      String.contains?(venue, "oban web") -> :oban_web_bridge
      true -> :host_owned
    end
  end

  defp evidence_path(subject) do
    type = field(subject, :type)
    id = field(subject, :id)
    resource_type = field(subject, :resource_type) || type
    resource_id = field(subject, :resource_id) || id

    cond do
      type in ["workflow", :workflow] and present?(id) ->
        [
          {"workflow_id", id},
          {"step", field(subject, :step)}
        ]
        |> selector_path()

      type in ["lifeline_incident", :lifeline_incident] and present?(id) ->
        [
          {"incident_fingerprint", id},
          {"view", field(subject, :view)}
        ]
        |> selector_path()

      resource_type in ["cron_entry", :cron_entry] and present?(resource_id) ->
        [
          {"resource_type", "cron_entry"},
          {"resource_id", resource_id}
        ]
        |> selector_path()

      resource_type in ["limiter", :limiter] and present?(resource_id) ->
        [
          {"resource_type", "limiter"},
          {"resource_id", resource_id}
        ]
        |> selector_path()

      true ->
        nil
    end
  end

  defp unsupported_boundaries(completeness) do
    [
      "Phase 34 is advisory only; it does not run actions or record remediation attempts.",
      degraded_boundary(completeness)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp degraded_boundary(%{state: :partial_evidence, details: details}),
    do: "partial evidence: #{details}"

  defp degraded_boundary(%{state: :history_unavailable, details: details}),
    do: "history unavailable: #{details}"

  defp degraded_boundary(%{state: :unknown, details: details}), do: "unknown: #{details}"
  defp degraded_boundary(_completeness), do: nil

  defp normalize_prerequisite(item) when is_map(item) do
    %{
      label: field(item, :label) || "Prerequisite",
      state: normalize_prerequisite_state(field(item, :state)),
      detail: field(item, :detail) || "No prerequisite detail available."
    }
  end

  defp normalize_prerequisite(_item) do
    %{label: "Prerequisite", state: :unknown, detail: "No prerequisite detail available."}
  end

  defp normalize_caution(item) when is_map(item) do
    %{
      label: field(item, :label) || "Caution",
      detail: field(item, :detail) || "No caution detail available.",
      severity: normalize_severity(field(item, :severity))
    }
  end

  defp normalize_caution(_item) do
    %{label: "Caution", detail: "No caution detail available.", severity: :info}
  end

  defp normalize_completeness(%{} = completeness) do
    state = field(completeness, :state)
    details = field(completeness, :details)

    %{
      state: Provenance.normalize_completeness(state),
      details: details || "No evidence completeness details available."
    }
  end

  defp normalize_completeness(_completeness) do
    %{state: :unknown, details: "No evidence completeness details available."}
  end

  defp prerequisite_state(true), do: :met
  defp prerequisite_state(false), do: :missing

  defp normalize_prerequisite_state(state) when state in [:met, :missing, :unknown], do: state
  defp normalize_prerequisite_state("met"), do: :met
  defp normalize_prerequisite_state("missing"), do: :missing
  defp normalize_prerequisite_state(_state), do: :unknown

  defp normalize_severity(severity) when severity in [:info, :warning], do: severity
  defp normalize_severity("warning"), do: :warning
  defp normalize_severity(_severity), do: :info

  defp normalize_intent(intent) when intent in [:investigate, :remediate, :escalate], do: intent
  defp normalize_intent("remediate"), do: :remediate
  defp normalize_intent("escalate"), do: :escalate
  defp normalize_intent(_intent), do: :investigate

  defp normalize_attempt_state(state) when is_atom(state), do: Atom.to_string(state)
  defp normalize_attempt_state(state) when is_binary(state), do: state
  defp normalize_attempt_state(_state), do: nil

  defp normalize_continuity_ownership(label) when is_binary(label) do
    normalized = String.downcase(label)

    cond do
      String.contains?(normalized, "powertools-native") -> @ownership_labels.powertools_native
      String.contains?(normalized, "oban web") -> @ownership_labels.oban_web_bridge
      String.contains?(normalized, "inspection only") -> @ownership_labels.oban_web_bridge
      String.contains?(normalized, "host-owned") -> @ownership_labels.host_owned
      true -> @ownership_labels.host_owned
    end
  end

  defp normalize_continuity_ownership(_label), do: @ownership_labels.host_owned

  defp continuity_reason_detail(reason) when reason in [nil, ""], do: ""
  defp continuity_reason_detail(reason), do: " Reason: #{reason}."

  defp infer_intent(label) do
    label = String.downcase(to_string(label))

    cond do
      String.contains?(label, "retry") -> :remediate
      String.contains?(label, "repair") -> :remediate
      String.contains?(label, "escalat") -> :escalate
      String.contains?(label, "pager") -> :escalate
      true -> :investigate
    end
  end

  defp legal_path_detail([]), do: "No legal next path is available from this evidence bundle."

  defp legal_path_detail(_paths),
    do: "At least one legal next path is available from this evidence bundle."

  defp selector_path(params) do
    params =
      params
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> URI.encode_query()

    "/ops/jobs/forensics?#{params}"
  end

  defp field(nil, _key), do: nil
  defp field(map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp present?(value), do: not is_nil(value) and value != ""
  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value
end
