defmodule ObanPowertools.Web.ControlPlanePresenter do
  @moduledoc """
  Shared control-plane labels, ownership copy, and venue-aware wording.
  """

  alias ObanPowertools.{Audit, ControlPlane}

  @status_labels %{
    needs_review: "Needs Review",
    blocked: "Blocked",
    waiting: "Waiting",
    runnable: "Runnable",
    resolved: "Resolved",
    bridge_only: "Bridge-only Follow-up"
  }

  def status_label(status) when is_binary(status),
    do: status |> String.to_atom() |> status_label()

  def status_label(status), do: Map.get(@status_labels, status, Phoenix.Naming.humanize(status))

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

    [
      {"resource_type", identity.type},
      {"resource_id", identity.id},
      {"event_type", Audit.event_label(event)}
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> URI.encode_query()
    |> then(&"/ops/jobs/audit?#{&1}")
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
    |> Enum.map(&Phoenix.Naming.humanize/1)
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
  defp refusal_reason_label(code), do: Phoenix.Naming.humanize(code)

  defp follow_up_value(map, key) do
    Map.get(map, key) || Map.get(map, String.to_atom(key))
  end
end
