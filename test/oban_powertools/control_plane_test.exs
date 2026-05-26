defmodule ObanPowertools.ControlPlaneTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.ControlPlane

  test "freezes the exact shared status and ownership taxonomy" do
    assert ControlPlane.statuses() == [
             :needs_review,
             :blocked,
             :waiting,
             :runnable,
             :resolved,
             :bridge_only
           ]

    assert ControlPlane.ownerships() == [:powertools_native, :oban_web_bridge, :host_owned]
    assert ControlPlane.ownership_badge(:powertools_native) == "Powertools-native"
    assert ControlPlane.ownership_badge(:oban_web_bridge) == "Oban Web bridge"
    assert ControlPlane.venue_label(:host_owned) == "Host-owned"
  end

  test "maps limiter, cron, workflow, lifeline, and bridge contexts into the shared vocabulary" do
    assert ControlPlane.limiter_status(%{cooling_down?: true}) == :waiting
    assert ControlPlane.limiter_status(%{saturation_label: "Blocked"}) == :blocked
    assert ControlPlane.limiter_status(%{}) == :runnable

    assert ControlPlane.cron_status(%{paused_at: DateTime.utc_now()}) == %{
             operator_status: :waiting,
             diagnosis: :paused
           }

    assert ControlPlane.cron_status(%{paused_at: nil}) == %{
             operator_status: :runnable,
             diagnosis: :ready
           }

    assert ControlPlane.workflow_status(%{diagnosis: :waiting_on_dependencies}) == %{
             operator_status: :waiting,
             diagnosis: :waiting_on_dependencies
           }

    assert ControlPlane.workflow_status(%{
             latest_rejection: %{reason_code: "unsupported_legacy_semantics"}
           }) == %{
             operator_status: :needs_review,
             diagnosis: "unsupported_legacy_semantics"
           }

    assert ControlPlane.lifeline_status(%{status: "active"}) == :needs_review
    assert ControlPlane.lifeline_status(%{status: "resolved"}) == :resolved
    assert ControlPlane.audit_status(%{source: :bridge}) == :bridge_only
  end
end
