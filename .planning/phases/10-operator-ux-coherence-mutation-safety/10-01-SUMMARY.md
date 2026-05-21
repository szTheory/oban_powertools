---
phase: 10
plan: 01
subsystem: operator-ux
tags: [preview-contract, cron, lifeline, liveview]
requires: [HST-02]
provides: [shared-durable-preview-contract, cron-durable-preview-flow]
affects:
  - lib/oban_powertools/lifeline/repair_preview.ex
  - lib/oban_powertools/lifeline.ex
  - lib/oban_powertools/cron.ex
  - lib/oban_powertools/web/cron_live.ex
  - test/oban_powertools/lifeline_test.exs
  - test/oban_powertools/cron_test.exs
  - test/oban_powertools/web/live/lifeline_live_test.exs
  - test/oban_powertools/web/live/cron_live_test.exs
tech_stack:
  added: []
  patterns:
    - shared durable preview rows
    - preview-token execution boundary
    - explicit preview status vocabulary
key_files:
  created: []
  modified:
    - lib/oban_powertools/lifeline/repair_preview.ex
    - lib/oban_powertools/lifeline.ex
    - lib/oban_powertools/cron.ex
    - lib/oban_powertools/web/cron_live.ex
    - test/oban_powertools/lifeline_test.exs
    - test/oban_powertools/cron_test.exs
    - test/oban_powertools/web/live/lifeline_live_test.exs
    - test/oban_powertools/web/live/cron_live_test.exs
decisions:
  - Reused `ObanPowertools.Lifeline.RepairPreview` as the single durable preview persistence seam for lifeline and cron.
  - Standardized native preview lifecycle state to `ready`, `drifted`, `expired`, and `consumed`.
  - Moved cron mutation execution behind persisted preview tokens and server-side preview-state rechecks.
metrics:
  completed_at: 2026-05-21
  task_commits: [5ea33ef, f42b90d]
---

# Phase 10 Plan 01: Shared Durable Preview Contract Summary

Shared durable preview rows now back both Lifeline repairs and native cron mutations, with one explicit lifecycle: `ready`, `drifted`, `expired`, `consumed`.

## Outcomes

- Generalized `RepairPreview` from a lifeline-only `pending/executed` model into the shared native mutation contract, including canonical status checks and shared metadata keys for summary, risk, and resource.
- Updated `Lifeline` to create `ready` previews, consume them as `consumed`, mark drift with an operator-visible `drift_reason`, and count active previews via the new vocabulary.
- Reworked `Cron` so preview generation persists or reuses a durable preview row before pause/resume/run execution, and execute rejects missing, drifted, expired, or consumed previews before any mutation write.
- Moved `CronLive` off socket-only preview state so it renders preview status and token from the persisted row and surfaces shared error states like `preview_drifted`, `preview_expired`, and `preview_consumed`.
- Extended backend and LiveView coverage for durable cron previews, invalid preview-state rejection, and the shared preview vocabulary.

## Verification

- `mix test test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs`
  Result: passed
- `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs`
  Result: passed
- `mix test test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs`
  Result: passed

## Deviations from Plan

None. The existing Lifeline preview table was reused as the shared durable preview contract, and cron was moved onto the same preview-token execution boundary.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/10-operator-ux-coherence-mutation-safety/10-01-SUMMARY.md`.
- Task commit `5ea33ef` exists.
- Task commit `f42b90d` exists.
