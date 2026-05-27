---
phase: 34
slug: historical-attention-projection-runbook-entry-surfaces
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
updated: 2026-05-27
---

# Phase 34 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` with Phoenix.LiveViewTest |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60 seconds targeted, repo-dependent for full suite |
| **Latency note** | The full targeted sweep is intentionally wider than the 30s Nyquist warning threshold because Phase 34 spans shared forensics, overview, and four drill-down surfaces. Plans also include narrower per-task commands for early feedback before the full wave sweep. |

## Sampling Rate

- **After every task commit:** Run the targeted quick command for the files touched by the task, expanding from the command above as needed.
- **After every plan wave:** Run `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs`.
- **Before `$gsd-verify-work`:** `mix test` must be green, or any repo-wide unrelated failures must be documented with targeted Phase 34 proof.
- **Max feedback latency:** 120 seconds for targeted Phase 34 feedback.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01 | 34-01 | 1 | OPS-03 / RNB-01 | TBD | Attention projection stays bounded, diagnosis-first, and evidence-honest | unit + LiveView | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/forensics_test.exs` | ✅ | ✅ green |
| 34-02 | 34-02 | 2 | RNB-01 / RNB-02 | TBD | Runbook entries expose prerequisites, cautions, venue ownership, evidence links, and unsupported boundaries before action | unit + LiveView | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs` | ✅ | ✅ green |
| 34-03 | 34-03 | 3 | OPS-03 / RNB-02 | TBD | Shared wording preserves Powertools-native, Oban Web bridge, and host-owned follow-up truth | unit + LiveView | `mix test test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs` | ✅ | ✅ green |

## Wave 0 Requirements

- [x] Planner must add or update focused tests for bounded historical attention projection before relying on overview UI changes. (`test/oban_powertools/web/live/engine_overview_live_test.exs` — visual hierarchy proxy)
- [x] Planner must add or update focused tests for canonical forensic runbook entries before rendering compact runbook summaries elsewhere. (`test/oban_powertools/forensics_test.exs`, `test/oban_powertools/web/live/forensics_live_test.exs`)
- [x] Planner must add or update focused tests for native, bridge-only, host-owned, partial-evidence, and history-unavailable wording states. (`test/oban_powertools/web/live/runbook_copy_contract_test.exs` — added Phase 40)

## Manual-Only Verifications

> Both manual gates were retired to deterministic ExUnit/LiveView proxy tests by Phase 40 plan 40-01.
> CI shift-left into `continuity-ver04-c3` and `continuity-ver04-c4` performed by Phase 40 plan 40-02.

| Behavior | Requirement | Why Automated | Proxy Test | Status |
|----------|-------------|---------------|------------|--------|
| Overview remains scannable and not feed-like | OPS-03 | Phase 40 encoded DOM-order assertions for bucket headings versus exemplar markers and refuted feed-like section headings | `test/oban_powertools/web/live/engine_overview_live_test.exs` — `"visual hierarchy proxy: bucket-grid headings precede historical exemplars and no feed-like section is rendered"` | ✅ green |
| Runbook entry decision point is honest | RNB-01 / RNB-02 | Phase 40 encoded ownership triad, evidence-boundary, refusal ordering, and anti-overclaim assertions | `test/oban_powertools/web/live/runbook_copy_contract_test.exs` — `"runbook surfaces honor the automated copy contract across workflow and lifeline bundles"` | ✅ green |

## Verification Reference

Phase 34 verification was completed at `2026-05-27T15:39:48Z` with status `verified` and score `15/15`.
See `.planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-VERIFICATION.md`.

Targeted Phase 34 proof command:
```sh
mix test test/oban_powertools/forensics_test.exs \
  test/oban_powertools/web/live/engine_overview_live_test.exs \
  test/oban_powertools/web/live/forensics_live_test.exs \
  test/oban_powertools/web/live/workflows_live_test.exs \
  test/oban_powertools/web/live/lifeline_live_test.exs \
  test/oban_powertools/web/live/cron_live_test.exs \
  test/oban_powertools/web/live/limiters_live_test.exs
```
Result: `61 tests, 0 failures` (34-VERIFICATION.md behavioral spot-check).

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter after Phase 34 proof is green

**Approval:** complete (Phase 40 plan 40-01 retired the two open human gates to deterministic proxy tests; 34-VERIFICATION.md status: verified 2026-05-27T15:39:48Z)
