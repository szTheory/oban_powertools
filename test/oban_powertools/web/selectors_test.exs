defmodule ObanPowertools.Web.SelectorsTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Web.Selectors

  test "maps each named destination to its canonical path" do
    assert Selectors.lifeline_path([]) == "/ops/jobs/lifeline"
    assert Selectors.forensic_path([]) == "/ops/jobs/forensics"
    assert Selectors.audit_path([]) == "/ops/jobs/audit"
    assert Selectors.limiter_path([]) == "/ops/jobs/limiters"
    assert Selectors.cron_path([]) == "/ops/jobs/cron"
  end

  test "drops nil and empty string values before encoding" do
    result =
      Selectors.lifeline_path([{"view", "active"}, {"incident_fingerprint", nil}, {"step", ""}])

    assert result == "/ops/jobs/lifeline?view=active"
  end

  test "returns bare path when no params survive filtering" do
    assert Selectors.forensic_path([{"incident_fingerprint", nil}]) == "/ops/jobs/forensics"
    assert Selectors.forensic_path([]) == "/ops/jobs/forensics"
  end

  test "preserves keyword-list ordering in the encoded query" do
    result = Selectors.lifeline_path([{"view", "active"}, {"incident_fingerprint", "fp-123"}])
    assert result == "/ops/jobs/lifeline?view=active&incident_fingerprint=fp-123"

    # Reversed order
    result2 = Selectors.lifeline_path([{"incident_fingerprint", "fp-123"}, {"view", "active"}])
    assert result2 == "/ops/jobs/lifeline?incident_fingerprint=fp-123&view=active"
  end

  test "encodes delimiter-heavy values (: / ? # % space & =) so they decode back to the original binary" do
    fingerprint = "dead_executor:exec/path?frag#tag with%20space&query=value"
    result = Selectors.lifeline_path([{"view", "active"}, {"incident_fingerprint", fingerprint}])

    assert String.starts_with?(result, "/ops/jobs/lifeline?")
    query_string = result |> String.split("?", parts: 2) |> List.last()
    decoded = URI.decode_query(query_string)
    assert decoded["incident_fingerprint"] == fingerprint
    assert decoded["view"] == "active"

    # Raw fingerprint must NOT appear unencoded
    refute result =~ "incident_fingerprint=dead_executor:exec/path"
  end

  test "accepts permissive non-canonical keys (row-id, action, entry, resource, event_type)" do
    result =
      Selectors.lifeline_path([
        {"view", "active"},
        {"incident_fingerprint", "fp-1"},
        {"row-id", "row-42"},
        {"action", "job_rescue"},
        {"entry", "nightly"},
        {"resource", "payments-api"},
        {"event_type", "lifeline.repair_executed"}
      ])

    assert result =~ "row-id="
    assert result =~ "action=job_rescue"
    assert result =~ "entry=nightly"
    assert result =~ "resource="
    assert result =~ "event_type="
  end
end
