---
phase: 50
slug: telemetry-metrics-slo-guide
status: draft
nyquist_compliant: false
wave_0_complete: false
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

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-XX-XX | TBD | 0 | TEL-01 | — | N/A | unit | `mix test test/oban_powertools/telemetry_test.exs` | ❌ W0 (extend existing) | ⬜ pending |
| 50-XX-XX | TBD | 1 | TEL-01 | — | `metrics/0` returns non-empty list of `Telemetry.Metrics` structs | unit | `mix test test/oban_powertools/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| 50-XX-XX | TBD | 1 | TEL-01 | — | every metric `event_name` is within a frozen `@contract` family | unit | `mix test test/oban_powertools/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| 50-XX-XX | TBD | 1 | TEL-01 / SC-4 | — | every metric `:tags` ⊆ contract's per-family allowed metadata keys; no `job_id`/`args` | unit | `mix test test/oban_powertools/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| 50-XX-XX | TBD | 1 | TEL-02 | — | `metrics/0` raises clear actionable error when `Telemetry.Metrics` unloaded (not `[]`) | unit | `mix test test/oban_powertools/telemetry_test.exs` | ❌ W0 (may be manual-only) | ⬜ pending |
| 50-XX-XX | TBD | 1 | TEL-02 | — | optional deps absent → library still compiles in prod tree | smoke | `MIX_ENV=prod mix compile` | ❌ W0 | ⬜ pending |
| 50-XX-XX | TBD | 1 | TEL-03 | — | guide present at `guides/telemetry-and-slos.md`, grouped under Operations | smoke | `test -f guides/telemetry-and-slos.md` | ❌ W0 | ⬜ pending |
| 50-XX-XX | TBD | 1 | TEL-03 | — | guide code samples compile; docs build clean | smoke | `mix docs` | ❌ W0 | ⬜ pending |

*Task IDs are placeholders until plans are written; the planner/executor binds each row to a real task. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/telemetry_test.exs` — extend existing file with `metrics/0` structural tests (TEL-01, SC-4 tag containment)
- [ ] `{:telemetry_metrics, "~> 1.0", optional: true}` (+ a test/dev availability path so `Telemetry.Metrics.*` is loaded under `mix test`) added to `mix.exs`; run `mix deps.get`
- [ ] No new test framework — ExUnit already configured

*Guide (`guides/telemetry-and-slos.md`) needs no Wave 0 stub — it is a Wave 1 deliverable verified by `test -f` + `mix docs`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `metrics/0` raises when `:telemetry_metrics` truly absent | TEL-02 | Hard to simulate an unloaded module inside a suite that has the dep loaded for other tests | In a scratch app WITHOUT `:telemetry_metrics`, call `ObanPowertools.Telemetry.metrics/0`; confirm it raises an actionable error naming the missing dep, not `[]`. (Prefer an automated conditional/guard test if the planner finds a clean way.) |

*Prefer to automate the TEL-02 absence path if the planner can express it cleanly; otherwise it stays here.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
