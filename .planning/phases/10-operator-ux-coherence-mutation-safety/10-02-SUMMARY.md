---
phase: 10
plan: 02
subsystem: web
tags: [operator-ux, liveview, read-only, audit, preview]
requires: ["10-01"]
provides: ["shared native read-only and support-truth vocabulary across cron, lifeline, audit, and workflows"]
affects:
  - lib/oban_powertools/web/live_auth.ex
  - lib/oban_powertools/web/cron_live.ex
  - lib/oban_powertools/web/lifeline_live.ex
  - lib/oban_powertools/web/audit_live.ex
  - lib/oban_powertools/web/workflows_live.ex
  - test/oban_powertools/web/live/cron_live_test.exs
  - test/oban_powertools/web/live/lifeline_live_test.exs
  - test/oban_powertools/web/live/audit_live_test.exs
  - test/oban_powertools/web/live/workflows_live_test.exs
decisions:
  - Centralized native permission, read-only, preview, and audit copy in LiveAuth so native pages stop drifting in operator vocabulary.
  - Kept Audit and Workflows read-only while making their support-truth explicit: native Powertools pages own preview, reason, and audited mutations; Oban Web remains inspection-only.
completed_at: 2026-05-21
---

# Phase 10 Plan 02: Operator Vocabulary and Read-Only Coherence Summary

Shared operator language now spans the native Powertools LiveViews: cron and lifeline use one permission/read-only/preview/audit vocabulary, while audit and workflows expose the same read-only support-truth without adding mutation controls.

## What Changed

- `LiveAuth` now owns the shared user-facing vocabulary for `permission`, `read-only`, `preview`, `reason`, and `audit` messaging, including normalized mutation error keys such as `preview_not_available`, `preview_drifted`, `preview_expired`, `preview_consumed`, `reason_required`, and `reason_too_short`.
- `CronLive` now renders a page-level read-only banner for viewer-only operators, uses centralized disabled-control explanations, and keeps preview/audit consequence wording aligned with Lifeline.
- `LifelineLive` now renders the same page-level read-only framing for view-only operators, disables preview and execute controls with inline explanations, and surfaces shared preview status and audit consequence copy near the acted-on resource.
- `AuditLive` remains read-only, but now explicitly frames itself as the cross-surface audit destination while reinforcing that native pages keep local preview/reason/audit evidence close to the mutation.
- `WorkflowsLive` remains read-only, now states that Powertools-native pages own preview/reason/audited mutations, and keeps Oban Web positioned as the generic job inspection destination.

## Verification

- `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs`
  - Passed (`14 tests, 0 failures`)
- `mix test test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs`
  - Passed (`6 tests, 0 failures`)
- `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs`
  - Passed (`20 tests, 0 failures`)

## Commits

- `889eb64` `test(10-02): add shared operator vocabulary assertions`
- `3fdbc25` `feat(10-02): unify native operator mutation vocabulary`
- `c25b21f` `test(10-02): add read-only support-truth assertions`
- `76b0ef0` `feat(10-02): align read-only support-truth pages`

## Deviations from Plan

None. The plan executed as written within the allowed file scope.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Verified all committed task hashes exist in `git log`.
- Verified the summary file exists at `.planning/phases/10-operator-ux-coherence-mutation-safety/10-02-SUMMARY.md`.
