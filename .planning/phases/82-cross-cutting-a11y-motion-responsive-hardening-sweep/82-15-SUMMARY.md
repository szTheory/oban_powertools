---
phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
plan: "15"
subsystem: ui
tags: [copy-policy, phoenix-liveview, batches, workflows, lifeline, redaction]

requires:
  - phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
    provides: "Finite copy policy, shared dialog semantics, responsive data behavior, and first- and second-page recovery patterns"
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    provides: "Server-owned Batches and Lifeline mutation flows plus read-only Workflows diagnosis"
provides:
  - "Recorded-versus-partial Batches retry receipts with explicit legal recovery"
  - "Contiguous ordered Workflows legacy-semantics machine evidence in the shared machine-value treatment"
  - "Lifeline backend-error redaction that preserves exact trusted authorization messages"
affects: [82-08, 82-09, 82-10, 82-16, page-quality]

tech-stack:
  added: []
  patterns:
    - "Page-owned receipts describe recorded Powertools requests and separate partial outcomes from clean completion"
    - "Trusted LiveAuth messages are tagged before generic backend failures are reduced to finite recovery copy"

key-files:
  created: []
  modified:
    - lib/oban_powertools/web/batches_live.ex
    - lib/oban_powertools/web/workflows_live.ex
    - lib/oban_powertools/web/lifeline_live.ex
    - test/oban_powertools/web/copy_contract_test.exs

key-decisions:
  - "Keep Batches and Lifeline authority unchanged while separating trusted LiveAuth messages from untrusted backend failures at the page-owner boundary."
  - "Render the Workflows machine-code label and value as one shared machine value so the documented outcome-to-code order is executable and accessible."
  - "Describe batch retry success as recorded requests and any mixed result as partial with a fresh-evidence recovery step."

patterns-established:
  - "Wave 3 copy boundary: trusted permission truth remains exact; untrusted binary failures never render verbatim."
  - "Read-only refusal order: outcome, reason, legal next move, venue, then one complete machine-code value."

requirements-completed:
  - COPY-01
  - COPY-02
  - DATA-03
  - A11Y-02

duration: 7min
completed: 2026-07-29
status: complete
---

# Phase 82 Plan 15: Batches, Workflows, and Lifeline Copy Semantics Summary

**Wave 3 pages now report recorded and partial outcomes honestly, expose complete ordered workflow refusal evidence, and provide redaction-safe recovery without moving authority out of the server**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-29T21:21:00Z
- **Completed:** 2026-07-29T21:28:00Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Replaced Batches retry overclaims and raw callback state with recorded-request, partial-result, Audit, and fresh-preview guidance.
- Closed the documented Workflows `Machine code: unsupported_legacy_semantics` ordering contract while retaining the read-only presenter and shared machine-value treatment.
- Prevented Lifeline and callback preview failures from echoing untrusted backend strings while preserving exact permission and principal-attribution messages from LiveAuth.
- Retained all Phase 81 preview, reason, reauthorization, execution, duplicate-suppression, Audit, bounded-read, uniform-denial, and confidentiality behavior.

## Task Commits

TDD work was committed atomically:

1. **Task 1 RED: Lock Wave 3 copy and recovery truth** - `f0b89c9` (test)
2. **Task 1 GREEN: Harden Wave 3 operator copy** - `e086504` (fix)

## Files Created/Modified

- `lib/oban_powertools/web/batches_live.ex` - Honest retry receipts, actionable callback recovery, and tagged trusted authorization feedback.
- `lib/oban_powertools/web/workflows_live.ex` - Complete ordered machine-code evidence without adding workflow mutation authority.
- `lib/oban_powertools/web/lifeline_live.ex` - Finite backend-failure recovery with preserved trusted permission/principal messages.
- `test/oban_powertools/web/copy_contract_test.exs` - Fail-closed Wave 3 source and ordering diagnostics.

## Decisions Made

- Kept successful Lifeline execution receipts intact because they describe the existing proven Powertools mutation and Audit write; only untrusted failure projection changed.
- Preserved exact LiveAuth denial and attribution copy through tagged safe tuples while mapping arbitrary backend strings to one finite recovery sentence.
- Kept the legacy semantics code visible and complete inside `DataDisplay.machine_value`; Workflows remains diagnosis-only.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first Lifeline sanitization pass also hid trusted LiveAuth permission and missing-principal messages. The implementation adopted the established tagged-safe-authorization pattern, restoring exact permission truth while continuing to redact untrusted backend strings; the combined behavior suite then passed.

## User Setup Required

None - no external service configuration required.

## Verification Evidence

- `mix test test/oban_powertools/web/copy_contract_test.exs test/oban_powertools/web/live/batches_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0` — 48 tests, 0 failures.
- `mix test test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0` — 1 test, 0 failures; exact `Machine code: unsupported_legacy_semantics` order closed.
- `node test/browser/support/verify-phase82-quality.mjs` — schema 8; 163 targets; 99 pages; nine routes; three roots; 31 files; 18 declarations; zero exceptions.
- `MIX_ENV=test mix compile --warnings-as-errors` — exit 0.
- Scoped `mix format --check-formatted` and repository `git diff --check` — pass.

## Next Phase Readiness

- Batches, Workflows, and Lifeline are ready for connected page-quality, exact ARIA, and aggregate accessibility validation.
- No route, schema, domain, dependency, story, target-inventory, packaged-asset, or mutation-authority changes were introduced.
- No blockers.

## Self-Check: PASSED

- All four plan-owned implementation/test files exist.
- Task commits `f0b89c9` and `e086504` exist.
- Focused suites, cross-surface coherence, Phase 82 validator, warnings-as-errors compilation, formatting, and diff checks pass.

---
*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Completed: 2026-07-29*
