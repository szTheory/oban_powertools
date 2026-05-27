---
phase: 34-historical-attention-projection-runbook-entry-surfaces
reviewed: 2026-05-27T07:11:48Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - examples/phoenix_host/priv/repo/migrations/20260522000015_oban_powertools_limiter_history_facts.exs
  - examples/phoenix_host/priv/repo/migrations/20260522000016_oban_powertools_cron_coverages.exs
  - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000015_oban_powertools_limiter_history_facts.exs
  - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000016_oban_powertools_cron_coverages.exs
  - lib/oban_powertools/forensics.ex
  - lib/oban_powertools/forensics/attention_projection.ex
  - lib/oban_powertools/forensics/cron_history.ex
  - lib/oban_powertools/forensics/limiter_history.ex
  - lib/oban_powertools/forensics/runbook_entry.ex
  - lib/oban_powertools/web/control_plane_presenter.ex
  - lib/oban_powertools/web/cron_live.ex
  - lib/oban_powertools/web/engine_overview_live.ex
  - lib/oban_powertools/web/forensics_live.ex
  - lib/oban_powertools/web/lifeline_live.ex
  - lib/oban_powertools/web/limiters_live.ex
  - lib/oban_powertools/web/overview_read_model.ex
  - lib/oban_powertools/web/workflows_live.ex
  - test/oban_powertools/forensics_test.exs
  - test/oban_powertools/web/live/cron_live_test.exs
  - test/oban_powertools/web/live/engine_overview_live_test.exs
  - test/oban_powertools/web/live/forensics_live_test.exs
  - test/oban_powertools/web/live/lifeline_live_test.exs
  - test/oban_powertools/web/live/limiters_live_test.exs
  - test/oban_powertools/web/live/workflows_live_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 34: Code Review Report

**Reviewed:** 2026-05-27T07:11:48Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Reviewed the Phase 34 migrations, forensics/history modules, LiveView surfaces, overview read model, and scoped tests. The new history and runbook surfaces are covered by targeted tests and the scoped suite passes, but two correctness/security gaps remain: overview links do not encode incident fingerprints, and runbook/provenance normalization can create atoms from untrusted strings.

Verification run:

```bash
mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs
```

Result: 61 tests, 0 failures.

## Warnings

### WR-01: Incident fingerprint links are built without query encoding

**File:** `lib/oban_powertools/web/overview_read_model.ex:199`
**Issue:** `incident.incident_fingerprint` is interpolated directly into Lifeline and Forensics URLs on lines 199-200, 215-218, 263-266, and 419. Incident fingerprints can include values derived from executor/resource identity. If a fingerprint contains `&`, `=`, `#`, or other query delimiters, the generated link can lose selector fidelity or inject extra query parameters. This directly affects the Phase 34 attention projection and runbook entry handoff paths.
**Fix:** Build these URLs with `URI.encode_query/1` or `URI.encode_www_form/1`, matching the cron and limiter paths in the same module.

```elixir
defp lifeline_incident_path(view, incident) do
  "/ops/jobs/lifeline?" <>
    URI.encode_query(%{
      "view" => view,
      "incident_fingerprint" => incident.incident_fingerprint
    })
end

defp forensic_incident_path(incident) do
  "/ops/jobs/forensics?" <>
    URI.encode_query(%{"incident_fingerprint" => incident.incident_fingerprint})
end
```

Add a regression test with an incident fingerprint containing `&` or `=` and assert the rendered links preserve it as one encoded selector.

### WR-02: Runbook/provenance normalization creates atoms from arbitrary strings

**File:** `lib/oban_powertools/forensics/runbook_entry.ex:273`
**Issue:** `normalize_completeness/1` converts every string key in the completeness map with `String.to_atom/1`, and then passes string state values into `Provenance.normalize_completeness/1`, which also atomizes strings. The presenter has the same pattern for forensic labels in `lib/oban_powertools/web/control_plane_presenter.ex:101` and `lib/oban_powertools/web/control_plane_presenter.ex:109`. Phase 34 introduces these helpers on request-rendered runbook/forensics paths; repeated novel strings can grow the VM atom table, and unknown values should degrade without creating atoms.
**Fix:** Normalize only the known string values and read string/atom keys explicitly. Do not call `String.to_atom/1` for request, database, or caller-provided values.

```elixir
defp normalize_completeness(%{} = completeness) do
  state = Map.get(completeness, :state) || Map.get(completeness, "state")
  details = Map.get(completeness, :details) || Map.get(completeness, "details")

  %{
    state: normalize_completeness_state(state),
    details: details || "No evidence completeness details available."
  }
end

defp normalize_completeness_state(value) when value in [:complete, "complete"], do: :complete
defp normalize_completeness_state(value) when value in [:partial_evidence, "partial_evidence"], do: :partial_evidence
defp normalize_completeness_state(value) when value in [:history_unavailable, "history_unavailable"], do: :history_unavailable
defp normalize_completeness_state(value) when value in [:unknown, "unknown"], do: :unknown
defp normalize_completeness_state(_value), do: :unknown
```

Apply the same whitelist approach to `forensic_provenance_label/1` and `forensic_completeness_label/1`, and add a regression test that passes a novel string without increasing atom usage or raising.

---

_Reviewed: 2026-05-27T07:11:48Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
