---
phase: 62-operations-console-lifeline-ui
plan: 05
subsystem: web
tags: [phoenix, liveview, batches, lifeline, operator-ui]
requires:
  - phase: 62-operations-console-lifeline-ui
    provides: routes, selectors, auth copy, Batches read model, and callback retry Lifeline support
provides:
  - Native `/ops/jobs/batches` index LiveView
  - Native `/ops/jobs/batches/:id` detail LiveView
  - Failed-member bulk retry controls routed through Lifeline
  - Callback retry preview/execute controls routed through Lifeline
affects: [batches-ui, lifeline, callbacks, audit]
tech-stack:
  added: []
  patterns: [Phoenix LiveView HEEx, URL-backed filters, Lifeline modal preview, read-only helper copy]
key-files:
  created:
    - lib/oban_powertools/web/batches_live.ex
  modified: []
key-decisions:
  - "The LiveView performs no Ecto SQL; batch list/detail data comes from `ObanPowertools.Batches`."
  - "Failed-member retry and callback retry are UI affordances only; all mutations go through Lifeline preview/execute."
  - "Read-only controls remain visible with permission helper copy so operators can inspect evidence without implied authority."
patterns-established:
  - "Batch selection is page-local and validates selected job ids against server-derived retry-eligible failed members."
  - "Callback retry controls validate current detail callback eligibility before Lifeline preview."
  - "Batch UI uses dense table-first operator-console layout from the Phase 62 UI spec."
requirements-completed: [BUI-01, BUI-02, BUI-03, BUI-04]
duration: 8 min
completed: 2026-06-15
---

# Phase 62 Plan 05: Native Batches LiveView Summary

**Dense batch operations console with read-model-backed evidence and Lifeline-routed recovery actions**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-15T03:08:38Z
- **Completed:** 2026-06-15T03:16:47Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Added `ObanPowertools.Web.BatchesLive` under the Phoenix LiveView availability guard.
- Implemented `/ops/jobs/batches` with locked copy, read-only banner, metrics, status tabs, URL-backed filters, empty/error states, dense table rows, progress bars, callback summaries, and batch detail links.
- Implemented `/ops/jobs/batches/:id` with identity, progress, blocked explanation, failed-member inspection, callback outbox, chain context, bridge inspection copy, and manual intervention history.
- Implemented failed-member selection and bulk `job_retry` through Lifeline preview/execute with reason gating and honest success/failure reporting.
- Implemented eligible callback `callback_retry` preview/execute through Lifeline with reason gating and drift/expired/consumed/unauthorized error copy.

## Task Commits

The implementation was committed as one cohesive LiveView file:

1. **Tasks 1-3: Add native BatchesLive index/detail and recovery interactions** - `9f07380` (feat)

## Files Created/Modified

- `lib/oban_powertools/web/batches_live.ex` - Native batch index/detail UI, URL filters, failed-member retry, callback retry, and modal rendering.

## Decisions Made

The UI keeps the operational console quiet and table-first, matching the Phase 62 UI contract and existing `JobsLive` style. It intentionally does not introduce images, icons, marketing layout, or a standalone chain surface.

## Deviations from Plan

The requested browser human-check was not run because this repository is a library with only a test endpoint configured as `server: false`; the test router also relies on signed session state injected by `LiveViewTest` for authorization. The practical verification surface is the LiveView integration suite plus source guards.

**Total deviations:** 0 auto-fixed. **Impact:** No product scope change; visual verification remains covered by rendered LiveView tests rather than a running browser session.

## Issues Encountered

The first bulk retry rendering showed two actionable `preview_bulk_retry` buttons after selection. The header control now stays as read-only/empty-selection copy, while the selected banner owns the active retry button, keeping the LiveView test selector unambiguous.

## Verification

- `mix test test/oban_powertools/web/live/batches_live_test.exs --only phase62_batches_render` passed: `2 tests, 0 failures`.
- `mix test test/oban_powertools/web/live/batches_live_test.exs --only phase62_batch_bulk_retry` passed: `2 tests, 0 failures`.
- `mix test test/oban_powertools/web/live/batches_live_test.exs --only phase62_batch_callback_retry` passed: `2 tests, 0 failures`.
- `mix test test/oban_powertools/batches_test.exs test/oban_powertools/lifeline_callback_test.exs test/oban_powertools/web/live/batches_live_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/selectors_test.exs` passed: `28 tests, 0 failures`.
- `rg -n "from\\(|join:|where\\(|repo\\.all|Oban\\.retry_job|Ecto\\.Multi" lib/oban_powertools/web/batches_live.ex` emitted no matches.
- Source scan found required `LiveAuth.authorize_page`, `Batches.list/get/count_by_status`, `Lifeline.preview_repair/execute_repair`, selector, and retry permission references.

## Self-Check: PASSED

- BUI-01 native batch index/detail rendering is implemented.
- BUI-02 blocked-state explanations are rendered from the read model.
- BUI-03 failed-member retry is Lifeline-routed and page-local.
- BUI-04 callback retry is Lifeline-routed and drift-aware.
- The LiveView owns no direct SQL and performs no direct Oban job mutation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Phase 62 completion verification and tracking updates.

---
*Phase: 62-operations-console-lifeline-ui*
*Completed: 2026-06-15*
