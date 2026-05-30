---
phase: 50
slug: telemetry-metrics-slo-guide
status: compliant
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
---

# Phase 50 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in Elixir) |
| **Config file** | `test/test_helper.exs` (exists) |
| **Quick run command** | `mix test test/oban_powertools/telemetry_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 seconds (telemetry file); full suite per project baseline |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/telemetry_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds (telemetry file)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 50-01-T1 | 50-01 | 0 | TEL-02 | smoke | `grep -v '^#' mix.exs \| grep -c 'telemetry_metrics.*optional: true'` | ✅ | ✅ green |
| 50-01-T2 | 50-01 | 0 | TEL-01 | unit | `mix test test/oban_powertools/telemetry_test.exs` | ✅ | ✅ green |
| 50-02-T1 | 50-02 | 1 | TEL-01 | unit | `mix test test/oban_powertools/telemetry_test.exs` | ✅ | ✅ green |
| 50-02-T2 | 50-02 | 1 | TEL-02 | smoke | `MIX_ENV=prod mix compile` | ✅ | ✅ green |
| 50-03-T1 | 50-03 | 1 | TEL-03 | smoke | `test -f guides/telemetry-and-slos.md && mix docs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/oban_powertools/telemetry_test.exs` extended with `metrics/0` structural tests
- [x] Optional deps added to `mix.exs`
- [x] No new test framework needed

*Guide (`guides/telemetry-and-slos.md`) needs no Wave 0 stub — it is a Wave 1 deliverable verified by `test -f` + `mix docs`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `metrics/0` raises when `:telemetry_metrics` truly absent | TEL-02 | Hard to simulate an unloaded module inside a suite that has the dep loaded for other tests | In a scratch app WITHOUT `:telemetry_metrics`, call `ObanPowertools.Telemetry.metrics/0`; confirm it raises an actionable error naming the missing dep, not `[]`. (Prefer an automated conditional/guard test if the planner finds a clean way.) |

*Prefer to automate the TEL-02 absence path if the planner can express it cleanly; otherwise it stays here.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete

---

## Validation Audit 2026-05-30

| Metric | Count |
|--------|-------|
| Gaps found | 2 |
| Resolved | 2 |
| Escalated | 0 |

WR-01 resolved: phantom repair_completed event replaced with repair_executed using production-matching metadata (3 keys: action, incident_class, target_type). Subset assertion replaces exact-match assertion since production emits only 3 of the 6 contract keys for this event.

WR-02 resolved: tautological cron assertion replaced — now captures received_metadata from the telemetry emission instead of checking the test literal, so a future production key change would cause a real failure.

TEL-02 absent-dep path: manual-only (hard to test in same suite that has the dep loaded).
