defmodule ObanPowertools.Web.ControlPlanePresenter do
  @moduledoc """
  Shared control-plane labels, ownership copy, and venue-aware wording.
  """

  alias ObanPowertools.{Audit, ControlPlane}
  alias ObanPowertools.Web.Selectors

  @status_labels %{
    needs_review: "Needs Review",
    blocked: "Blocked",
    waiting: "Waiting",
    runnable: "Runnable",
    resolved: "Resolved",
    bridge_only: "Bridge-only Follow-up"
  }

  @operator_result_states %{
    "success" => :success,
    "failed" => :failed,
    "skipped" => :skipped
  }
  @audit_outcome_states Map.put(@operator_result_states, "unknown", :unknown)
  @blocker_evidence_kinds %{
    "current" => :current,
    "block_start_snapshot" => :block_start_snapshot
  }
  @evidence_completeness %{
    "complete" => :complete,
    "partial" => :partial,
    "unknown" => :unknown,
    "unavailable" => :unavailable
  }
  @prohibited_presentation_source_field_names ~w[
    token hash error authorization password secret credential api_key access_key private_key
  ]
  @prohibited_presentation_source_field_suffixes ~w[
    token hash error authorization password secret credential
  ]

  @doc """
  Normalizes ordered active-filter presentation maps through a finite key contract.
  """
  def normalize_active_filters(filters) when is_list(filters) do
    filters
    |> Enum.map(fn filter ->
      ensure_presentation_map!(filter, "active filter")

      %{
        id: normalize_presentation_id!(presentation_value(filter, :id), "active filter id"),
        label: required_presentation_text!(presentation_value(filter, :label), "filter label"),
        value: required_presentation_text!(presentation_value(filter, :value), "filter value"),
        remove_href:
          required_presentation_text!(
            presentation_value(filter, :remove_href),
            "filter removal destination"
          ),
        remove_label:
          required_presentation_text!(
            presentation_value(filter, :remove_label),
            "filter removal label"
          )
      }
    end)
    |> ensure_unique_presentation_ids!("active filters")
  end

  def normalize_active_filters(_filters),
    do: raise(ArgumentError, "active filters must be a list of presentation maps")

  @doc """
  Normalizes ordered per-object operator results without merging failed and skipped outcomes.
  """
  def normalize_operator_results(results) when is_list(results) do
    results
    |> Enum.map(fn result ->
      ensure_presentation_map!(result, "operator result")

      %{
        id: normalize_presentation_id!(presentation_value(result, :id), "operator result id"),
        object_label:
          required_presentation_text!(
            presentation_value(result, :object_label),
            "operator result object label"
          ),
        outcome:
          normalize_closed_value!(
            presentation_value(result, :outcome),
            @operator_result_states,
            "operator result outcome"
          ),
        message:
          required_presentation_text!(
            presentation_value(result, :message),
            "operator result message"
          ),
        recovery:
          optional_presentation_text(
            presentation_value(result, :recovery),
            "operator result recovery"
          ),
        audit_href:
          optional_presentation_text(
            presentation_value(result, :audit_href),
            "operator result audit destination"
          )
      }
    end)
    |> ensure_unique_presentation_ids!("operator results")
  end

  def normalize_operator_results(_results),
    do: raise(ArgumentError, "operator results must be a list of presentation maps")

  @doc """
  Normalizes every supplied blocker while preserving live versus block-start evidence.
  """
  def normalize_blockers(blockers) when is_list(blockers) do
    blockers
    |> Enum.map(fn blocker ->
      ensure_presentation_map!(blocker, "blocker")

      %{
        id: normalize_presentation_id!(presentation_value(blocker, :id), "blocker id"),
        evidence_kind:
          normalize_closed_value!(
            presentation_value(blocker, :evidence_kind),
            @blocker_evidence_kinds,
            "blocker evidence kind"
          ),
        label: required_presentation_text!(presentation_value(blocker, :label), "blocker label"),
        summary:
          required_presentation_text!(presentation_value(blocker, :summary), "blocker summary"),
        clearing_condition:
          required_presentation_text!(
            presentation_value(blocker, :clearing_condition),
            "blocker clearing condition"
          ),
        evidence_source:
          required_presentation_text!(
            presentation_value(blocker, :evidence_source),
            "blocker evidence source"
          ),
        technical_code:
          optional_presentation_text(
            presentation_value(blocker, :technical_code),
            "blocker technical code"
          )
      }
    end)
    |> ensure_unique_presentation_ids!("blockers")
  end

  def normalize_blockers(_blockers),
    do: raise(ArgumentError, "blockers must be a list of presentation maps")

  @doc """
  Normalizes one immutable audit entry with explicit missing reason and outcome copy.
  """
  def normalize_audit_entry(entry) do
    ensure_presentation_map!(entry, "audit entry")

    changes = presentation_value(entry, :changes)
    evidence = presentation_value(entry, :evidence)
    ensure_safe_presentation_data!(changes, "audit changes")
    ensure_safe_presentation_data!(evidence, "audit evidence")

    %{
      sentence:
        required_presentation_text!(presentation_value(entry, :sentence), "audit sentence"),
      outcome:
        optional_presentation_text(presentation_value(entry, :outcome), "audit outcome") ||
          "Outcome not recorded",
      outcome_state:
        normalize_closed_value!(
          presentation_value(entry, :outcome_state) || :unknown,
          @audit_outcome_states,
          "audit outcome state"
        ),
      actor: required_presentation_text!(presentation_value(entry, :actor), "audit actor"),
      action: required_presentation_text!(presentation_value(entry, :action), "audit action"),
      target: required_presentation_text!(presentation_value(entry, :target), "audit target"),
      reason:
        optional_presentation_text(presentation_value(entry, :reason), "audit reason") ||
          "No operator reason recorded",
      source: required_presentation_text!(presentation_value(entry, :source), "audit source"),
      correlation:
        required_presentation_text!(
          presentation_value(entry, :correlation),
          "audit correlation"
        ),
      occurred_at:
        required_presentation_text!(
          presentation_value(entry, :occurred_at),
          "audit absolute time"
        ),
      occurred_datetime:
        normalize_datetime!(presentation_value(entry, :occurred_datetime), "audit datetime"),
      changes: changes,
      evidence: evidence
    }
  end

  @doc """
  Closes evidence completeness over complete, partial, unknown, and unavailable.
  """
  def normalize_evidence_completeness(value) do
    key = if is_atom(value), do: Atom.to_string(value), else: value
    Map.get(@evidence_completeness, key, :unknown)
  end

  def status_label(status) when is_binary(status) do
    String.to_existing_atom(status) |> status_label()
  rescue
    ArgumentError -> humanize(status)
  end

  def status_label(status), do: Map.get(@status_labels, status, humanize(status))

  def ownership_badge(ownership), do: ControlPlane.ownership_badge(ownership)

  def ownership_posture(:powertools_native), do: "Audited action"
  def ownership_posture(:oban_web_bridge), do: "Inspection only"
  def ownership_posture(:host_owned), do: "Host-owned"

  def continuity_posture, do: "Continuity evidence"

  def runbook_ownership_label(ownership)
      when ownership in [:powertools_native, "powertools_native"],
      do: "Powertools-native"

  def runbook_ownership_label(ownership) when ownership in [:oban_web_bridge, "oban_web_bridge"],
    do: "Oban Web bridge"

  def runbook_ownership_label(ownership) when ownership in [:host_owned, "host_owned"],
    do: "host-owned follow-up"

  def runbook_ownership_label("Powertools-native"), do: "Powertools-native"
  def runbook_ownership_label("Oban Web bridge"), do: "Oban Web bridge"
  def runbook_ownership_label("Inspection only"), do: "Oban Web bridge"
  def runbook_ownership_label("host-owned follow-up"), do: "host-owned follow-up"

  def runbook_ownership_label(ownership) when is_binary(ownership) do
    ownership
    |> String.downcase()
    |> runbook_path_posture()
  end

  def runbook_ownership_label(_ownership), do: "host-owned follow-up"

  def runbook_path_posture(path_or_venue)
      when path_or_venue in [:powertools_native, "powertools_native"],
      do: "Powertools-native"

  def runbook_path_posture(path_or_venue)
      when path_or_venue in [:oban_web_bridge, "oban_web_bridge"],
      do: "Oban Web bridge"

  def runbook_path_posture(path_or_venue) when path_or_venue in [:host_owned, "host_owned"],
    do: "host-owned follow-up"

  def runbook_path_posture(path_or_venue) when is_binary(path_or_venue) do
    normalized = String.downcase(path_or_venue)

    cond do
      String.contains?(normalized, "powertools-native") -> "Powertools-native"
      String.contains?(normalized, "/ops/jobs") -> "Powertools-native"
      String.contains?(normalized, "lifeline") -> "Powertools-native"
      String.contains?(normalized, "oban web") -> "Oban Web bridge"
      String.contains?(normalized, "inspection only") -> "Oban Web bridge"
      true -> "host-owned follow-up"
    end
  end

  def runbook_path_posture(_path_or_venue), do: "host-owned follow-up"

  def follow_up_kind(%{} = follow_up) do
    follow_up
    |> follow_up_value("ownership")
    |> case do
      nil ->
        follow_up
        |> follow_up_value("venue")
        |> follow_up_kind()

      ownership ->
        follow_up_kind(ownership)
    end
  end

  def follow_up_kind(path_or_venue) do
    case runbook_path_posture(path_or_venue) do
      "Powertools-native" -> :powertools_native
      "Oban Web bridge" -> :oban_web_bridge
      _other -> :host_owned
    end
  end

  def follow_up_render_variant(path_or_venue_or_follow_up) do
    case follow_up_kind(path_or_venue_or_follow_up) do
      :powertools_native -> :native_primary
      :oban_web_bridge -> :bridge_guidance
      :host_owned -> :host_guidance
    end
  end

  def runbook_boundary_note(:powertools_native),
    do: "Powertools-native path stays inside the audited native control plane."

  def runbook_boundary_note(:oban_web_bridge),
    do: "Oban Web bridge path is inspection-only and read-only."

  def runbook_boundary_note(:host_owned),
    do: "host-owned follow-up path is outside Powertools delivery and runbook truth."

  def runbook_boundary_note(path_or_venue) do
    case runbook_path_posture(path_or_venue) do
      "Powertools-native" -> runbook_boundary_note(:powertools_native)
      "Oban Web bridge" -> runbook_boundary_note(:oban_web_bridge)
      "host-owned follow-up" -> runbook_boundary_note(:host_owned)
    end
  end

  def native_banner do
    "#{ownership_badge(:powertools_native)} surfaces keep diagnosis, preview, reason, and #{ownership_posture(:powertools_native) |> String.downcase()} together."
  end

  def bridge_banner do
    "#{ownership_badge(:oban_web_bridge)} remains #{ownership_posture(:oban_web_bridge) |> String.downcase()} and read-only."
  end

  def forensic_provenance_label(:durable), do: "durable"
  def forensic_provenance_label("durable"), do: "durable"
  def forensic_provenance_label(:supporting), do: "supporting evidence"
  def forensic_provenance_label("supporting"), do: "supporting evidence"
  def forensic_provenance_label(:bridge_only), do: "Inspection only"
  def forensic_provenance_label("bridge_only"), do: "Inspection only"
  def forensic_provenance_label(:missing), do: "unknown"
  def forensic_provenance_label("missing"), do: "unknown"
  def forensic_provenance_label(_provenance), do: "unknown"

  def forensic_completeness_label(:complete), do: "complete"
  def forensic_completeness_label("complete"), do: "complete"
  def forensic_completeness_label(:partial_evidence), do: "partial evidence"
  def forensic_completeness_label("partial_evidence"), do: "partial evidence"
  def forensic_completeness_label(:history_unavailable), do: "history unavailable"
  def forensic_completeness_label("history_unavailable"), do: "history unavailable"
  def forensic_completeness_label(:unknown), do: "unknown"
  def forensic_completeness_label("unknown"), do: "unknown"
  def forensic_completeness_label(_completeness), do: "unknown"

  def host_follow_up_status_label("host_owned_follow_up_unconfigured"),
    do: "Host-owned follow-up unavailable"

  def host_follow_up_status_label("host_owned_follow_up_callback_invoked"),
    do: "Host-owned follow-up callback invoked"

  def host_follow_up_status_label("host_owned_follow_up_callback_failed"),
    do: "Host-owned follow-up callback failed"

  def host_follow_up_status_label(_status), do: "Host-owned follow-up unavailable"

  def venue_label(venue), do: ControlPlane.venue_label(venue)

  def audit_event_label(event), do: Audit.event_label(event)

  def audit_resource_label(event) do
    identity = Audit.event_resource_identity(event)

    [identity.type, identity.id]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(":")
  end

  def audit_follow_up_path(event) do
    identity = Audit.event_resource_identity(event)

    Selectors.audit_path([
      {"resource_type", identity.type},
      {"resource_id", identity.id},
      {"event_type", Audit.event_label(event)}
    ])
  end

  def workflow_refusal(nil), do: nil

  def workflow_refusal(rejection) do
    %{
      outcome: "Needs Review",
      reason: rejection.message || refusal_reason_label(rejection.code),
      next_move: legal_next_move_label(rejection.legal_next_steps),
      venue: refusal_venue_label(rejection.legal_next_steps),
      code: rejection.code
    }
  end

  defp legal_next_move_label([]),
    do: "Review the workflow diagnosis before retrying a bounded action."

  defp legal_next_move_label(steps) do
    steps
    |> Enum.map(&humanize/1)
    |> Enum.join(", ")
  end

  defp refusal_venue_label(steps) do
    if Enum.any?(steps, &(&1 in ["retry", "cancel"])) do
      "Powertools-native Lifeline"
    else
      "Workflow diagnosis"
    end
  end

  defp refusal_reason_label(nil), do: "This action is not available right now."
  defp refusal_reason_label(code), do: humanize(code)

  defp presentation_value(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end

  defp required_presentation_text!(value, field) do
    optional_presentation_text(value, field) ||
      raise ArgumentError, "#{field} must be non-empty text"
  end

  defp optional_presentation_text(nil, _field), do: nil

  defp optional_presentation_text(value, field) when is_atom(value),
    do: value |> Atom.to_string() |> optional_presentation_text(field)

  defp optional_presentation_text(value, _field) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      text -> text
    end
  end

  defp optional_presentation_text(_value, field),
    do: raise(ArgumentError, "#{field} must be text")

  defp normalize_presentation_id!(value, field) do
    id = required_presentation_text!(value, field)

    if Regex.match?(~r/\A[A-Za-z][A-Za-z0-9_.:-]*\z/, id) do
      id
    else
      raise ArgumentError, "#{field} must be a stable identifier"
    end
  end

  defp normalize_closed_value!(value, values, field) do
    key = if is_atom(value), do: Atom.to_string(value), else: value

    case Map.fetch(values, key) do
      {:ok, normalized} -> normalized
      :error -> raise ArgumentError, "unsupported #{field}"
    end
  end

  defp normalize_datetime!(value, field) do
    datetime = required_presentation_text!(value, field)

    case DateTime.from_iso8601(datetime) do
      {:ok, _parsed, _offset} -> datetime
      {:error, _reason} -> raise ArgumentError, "#{field} must be a valid ISO 8601 datetime"
    end
  end

  defp ensure_unique_presentation_ids!(items, collection) do
    ids = Enum.map(items, & &1.id)

    if Enum.uniq(ids) == ids do
      items
    else
      raise ArgumentError, "#{collection} require unique ids"
    end
  end

  defp ensure_presentation_map!(value, name) when is_map(value) do
    if is_struct(value) do
      raise ArgumentError, "#{name} must be a plain presentation map"
    end

    ensure_safe_presentation_data!(value, name)
  end

  defp ensure_presentation_map!(_value, name),
    do: raise(ArgumentError, "#{name} must be a plain presentation map")

  defp ensure_safe_presentation_data!(nil, _name), do: :ok

  defp ensure_safe_presentation_data!(value, name) when is_struct(value),
    do: raise(ArgumentError, "#{name} must not contain structs")

  defp ensure_safe_presentation_data!(value, name) when is_map(value) do
    Enum.each(value, fn {key, nested} ->
      normalized_key = normalize_presentation_source_key(key)

      if not is_nil(nested) and
           (normalized_key in @prohibited_presentation_source_field_names or
              Enum.any?(@prohibited_presentation_source_field_suffixes, fn suffix ->
                String.ends_with?(normalized_key, "_#{suffix}")
              end)) do
        raise ArgumentError, "#{name} contains a prohibited source field"
      end

      ensure_safe_presentation_data!(nested, name)
    end)
  end

  defp ensure_safe_presentation_data!(value, name) when is_list(value),
    do: Enum.each(value, &ensure_safe_presentation_data!(&1, name))

  defp ensure_safe_presentation_data!(_value, _name), do: :ok

  defp normalize_presentation_source_key(key) do
    key
    |> to_string()
    |> String.replace(~r/([a-z0-9])([A-Z])/, "\\1_\\2")
    |> String.replace(~r/[^A-Za-z0-9]+/, "_")
    |> String.trim("_")
    |> String.downcase()
  end

  def humanize(atom) when is_atom(atom), do: humanize(Atom.to_string(atom))

  def humanize(bin) when is_binary(bin) do
    bin
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp follow_up_value(map, key) do
    Map.get(map, key) || Map.get(map, safe_atom(key))
  end

  defp safe_atom(binary) when is_binary(binary) do
    String.to_existing_atom(binary)
  rescue
    ArgumentError -> nil
  end

  defp safe_atom(_), do: nil
end
