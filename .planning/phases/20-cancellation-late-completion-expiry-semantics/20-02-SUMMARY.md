---
phase: 20-cancellation-late-completion-expiry-semantics
plan: 02
subsystem: workflow
tags: [ecto, postgres, workflow, callbacks, diagnosis]
requires:
  - phase: 20-cancellation-late-completion-expiry-semantics
    provides: canonical request/evidence/outcome reducer and bounded durable vocabulary
provides:
  - cooperative cancellation for in-flight work
  - terminal-truth-first diagnosis and explain surfaces
  - truthful narrow terminal callback payloads after cancellation races
affects: [20-03-proof-closure, DIA-01, REC-03, SIG-03, VER-01]
tech-stack:
  added: []
  patterns:
    - idle work cancels eagerly while executing work settles to its real terminal truth
    - explain and callback surfaces inherit runtime truth instead of inventing precedence rules
key-files:
  created: []
  modified:
    - lib/oban_powertools/workflow/runtime.ex
    - lib/oban_powertools/workflow.ex
    - lib/oban_powertools/explain.ex
    - test/oban_powertools/workflow_runtime_test.exs
    - test/oban_powertools/workflow_coordinator_test.exs
    - test/oban_powertools/explain_test.exs
key-decisions:
  - "Treat cancel as eager only for idle work and cooperative for executing work so support truth follows durable step facts."
  - "Make runtime diagnosis helpers the single precedence source for both explain helpers and terminal callback payloads."
patterns-established:
  - "Late or duplicate arrivals remain evidence only and never reopen terminal workflow meaning."
  - "Public workflow helpers stay narrow while runtime-owned semantics get stricter."
requirements-completed: [REC-03, SIG-03, DIA-01, VER-01]
duration: in-progress working tree plus closure pass
completed: 2026-05-24
---

# Phase 20 Plan 02 Summary

**Cancellation now behaves cooperatively for in-flight work, and both explain/callback surfaces present terminal truth before lingering request evidence.**

## Performance

- **Duration:** in-progress working tree plus closure pass
- **Started:** 2026-05-24T16:10:00Z
- **Completed:** 2026-05-24T17:00:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Hardened cancel propagation so idle work cancels immediately while executing work can still complete or fail truthfully after a cancel request.
- Refactored diagnosis ordering so `workflow_diagnosis/2`, `step_diagnosis/1`, and `ObanPowertools.Explain` all prefer final truth over request evidence.
- Tightened terminal callback payloads and callback outbox behavior around the same bounded runtime semantics.

## Task Commits

This plan was closed from an already-dirty working tree, so atomic task commits were not created during this execution pass.

## Files Created/Modified
- `lib/oban_powertools/workflow/runtime.ex` - cooperative cancellation, callback truth, and diagnosis ordering
- `lib/oban_powertools/workflow.ex` - narrow public workflow contract over the hardened runtime
- `lib/oban_powertools/explain.ex` - support-facing workflow and step stories driven by runtime diagnosis
- `test/oban_powertools/workflow_runtime_test.exs` - cancel-versus-complete, failure, expiry, and callback truth proof
- `test/oban_powertools/workflow_coordinator_test.exs` - advisory wakeup loss/duplication proof stays aligned with DB-first truth
- `test/oban_powertools/explain_test.exs` - terminal-truth-first explain-surface proof

## Decisions Made
- Kept `workflow.terminal` as a single truthful terminal event rather than widening it into an event stream.
- Reused the runtime reducer for diagnosis and callback ordering instead of layering separate explain-time precedence.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The closure pass had to verify behavior from filesystem and tests rather than from task commits because the workspace already contained in-progress semantic changes.

## User Setup Required

None - callback dispatch and explain surfaces keep the same public entrypoints.

## Next Phase Readiness

- `20-03` can focus on full proof coverage, upgrade-lane closure, and planning-truth alignment.
- The runtime now provides one truthful diagnosis contract for later Phase 21 UI work.

---
*Phase: 20-cancellation-late-completion-expiry-semantics*
*Completed: 2026-05-24*

## Self-Check: PASSED

- Idle and waiting work cancels eagerly while executing work settles cooperatively
- Explain helpers inherit terminal-truth-first runtime diagnosis
- Terminal callback payloads stay narrow and truthful after cancel and expiry races
