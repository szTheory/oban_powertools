---
phase: 6-runtime-config-authorization-hardening
plan: 02
subsystem: web
tags: [cron, liveview, auth, telemetry]
requires:
  - phase: 6
    provides: explicit runtime repo/auth wiring from Plan 01
provides:
  - auth-before-preview cron mutation flow
  - disabled cron actions with inline permission explanations
  - unauthorized preview telemetry suppression
affects: [phase-6, cron-ui, live-auth, telemetry]
tech-stack:
  added: []
  patterns: [authorize-before-preview, disabled-with-explanation, preview-first mutations]
key-files:
  created: []
  modified: [lib/oban_powertools/web/cron_live.ex, lib/oban_powertools/web/live_auth.ex, test/oban_powertools/web/live/cron_live_test.exs]
key-decisions:
  - "Cron preview authorization now happens before preview state assignment or preview telemetry emission."
  - "Viewer-facing cron actions stay visible but disabled, with inline permission copy rendered server-side."
patterns-established:
  - "Pattern 3: authorize -> preview -> confirm for cron mutations."
  - "Pattern 4: disabled controls still explain missing capability in-page."
requirements-completed: [FND-02, ENG-03]
duration: 8 min
completed: 2026-05-20
---

# Phase 6 Plan 02: Cron Authorization Hardening Summary

**Cron preview now authorizes before any preview side effect, and viewer-only operators see disabled mutation controls with explicit inline permission copy.**

## Performance

- **Duration:** 8 min
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Reordered the cron preview event so unauthorized actors never enter preview state and never emit preview telemetry.
- Extended `LiveAuth.authorize_action/4` to support page-specific unauthorized copy without weakening the default auth guard.
- Refactored cron row rendering to compute action capability up front and show disabled controls with inline explanations for viewers.

## Task Commits

1. **Task 1: Reorder cron preview flow so authorization happens before preview side effects**
2. `8aeae6e` `test(6-02): add failing unauthorized cron preview coverage`
3. `8fda253` `feat(6-02): gate cron previews before side effects`
4. **Task 2: Render disabled cron actions with inline permission explanations**
5. `492fb10` `test(6-02): add failing disabled cron action coverage`
6. `f8bcc05` `feat(6-02): render disabled cron actions with permission explanations`

## Files Created/Modified

- `lib/oban_powertools/web/cron_live.ex` - authorization now gates preview entry and row actions render from explicit capability metadata.
- `lib/oban_powertools/web/live_auth.ex` - action auth accepts optional custom unauthorized copy for in-page feedback.
- `test/oban_powertools/web/live/cron_live_test.exs` - covers unauthorized preview suppression, disabled viewer controls, and preserved authorized preview flow.

## Decisions Made

- Kept confirm-time authorization in place as defense in depth even after moving preview authorization earlier.
- Rendered permission explanations inline in the row instead of relying on hover-only affordances or hidden controls.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The executor stalled after landing a partial patch and failing-test commits, so the remaining disabled-action work, final verification, and summary write were completed inline by the orchestrator.

## Next Phase Readiness

- Cron mutation boundaries are now explicit at render time and enforced again at preview/confirm time.
- Phase 6 Plan 03 can focus on host-like verification and audit closure.

## Verification

- `mix test test/oban_powertools/web/live/cron_live_test.exs` -> PASS

## Self-Check: PASSED

- Found `.planning/phases/6-runtime-config-authorization-hardening/6-02-SUMMARY.md`
- Verified task commits `8aeae6e`, `8fda253`, `492fb10`, and `f8bcc05`
