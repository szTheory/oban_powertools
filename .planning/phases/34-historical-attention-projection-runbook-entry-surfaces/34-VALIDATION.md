---
phase: 34
slug: historical-attention-projection-runbook-entry-surfaces
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
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
| 34-01-TBD | 34-01 | TBD | OPS-03 / RNB-01 | TBD | Attention projection stays bounded, diagnosis-first, and evidence-honest | unit + LiveView | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/forensics_test.exs` | W0 TBD | pending |
| 34-02-TBD | 34-02 | TBD | RNB-01 / RNB-02 | TBD | Runbook entries expose prerequisites, cautions, venue ownership, evidence links, and unsupported boundaries before action | unit + LiveView | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs` | W0 TBD | pending |
| 34-03-TBD | 34-03 | TBD | OPS-03 / RNB-02 | TBD | Shared wording preserves Powertools-native, Oban Web bridge, and host-owned follow-up truth | unit + LiveView | `mix test test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs` | W0 TBD | pending |

## Wave 0 Requirements

- [ ] Planner must add or update focused tests for bounded historical attention projection before relying on overview UI changes.
- [ ] Planner must add or update focused tests for canonical forensic runbook entries before rendering compact runbook summaries elsewhere.
- [ ] Planner must add or update focused tests for native, bridge-only, host-owned, partial-evidence, and history-unavailable wording states.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Overview remains scannable and not feed-like | OPS-03 | Visual density and operator scan quality need reviewer judgment beyond DOM assertions | Open `/ops/jobs`; confirm existing diagnosis buckets remain primary and historical exemplars are bounded to one to three per relevant bucket. |
| Runbook entry decision point is honest | RNB-01 / RNB-02 | Copy tone and support-truth posture need reviewer judgment | Open representative overview, drill-down, and `/ops/jobs/forensics` states; confirm each next path shows venue ownership before navigation or action. |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter after Phase 34 proof is green

**Approval:** pending
