---
phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
plan: "02"
subsystem: testing
tags: [exunit, copy-policy, accessibility, confirmations, redaction]

requires:
  - phase: 78-component-groups-meta-components
    provides: shared ConfirmActionDialog with caller-owned operational truth
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    provides: nine migrated page surfaces and preserved authority boundaries
provides:
  - RED finite glossary, source-scan, state, recovery, receipt, exclusion, and diagnostics contract
  - RED semantic ordering and safe-state dismissal contract for shared confirmations
affects: [82-14, 82-17]

tech-stack:
  added: []
  patterns:
    - Public Copy.contract/0 is the sole future source for finite copy policy
    - RED confirmation assertions distinguish caller-owned truth from shared semantic order

key-files:
  created:
    - test/oban_powertools/web/copy_contract_test.exs
  modified:
    - test/oban_powertools/web/components/operator_patterns_test.exs

key-decisions:
  - "Keep page-specific consequence and support-boundary sentences outside the finite shared registry."
  - "Treat action-specific submit before safe-state dismiss as an executable D-16 ordering contract."
  - "Bound copy diagnostics to path, line, rule, phrase, and replacement without raw operator or provider data."

patterns-established:
  - "RED copy seam: all finite policy cases compile and fail only on the absent Copy.contract/0 implementation."
  - "Semantic confirmation fixture: missing and reordered sections produce named assertion failures."

requirements-completed:
  - COPY-01
  - COPY-02
  - A11Y-02

duration: 3min
completed: 2026-07-29
status: complete
---

# Phase 82 Plan 02: Finite Copy and Confirmation RED Contracts Summary

**Executable ExUnit contracts now lock the finite operator glossary, truthful state and receipt language, exact diagnostics, and D-16 confirmation order before production policy repair**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-29T20:08:17Z
- **Completed:** 2026-07-29T20:11:20Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added eight future-facing `Copy.contract/0` cases covering canonical concepts, forbidden phrases, synonym drift, ambiguous dismissal, distinct state requirements, recovery, honest receipts, exact exclusions, and bounded diagnostics.
- Added shared confirmation cases that lock object, scope, consequence, reversibility, support boundary, reason, action-specific submit, and safe-state dismissal semantics while preserving caller and server authority.
- Preserved the Wave 0 RED boundary: no production `copy.ex`, component repair, page copy change, localization migration, or product-flow change was introduced.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the RED finite copy-policy contract** - `be99dd2` (test)
2. **Task 2: Lock generic confirmation order and dismissal semantics** - `aabc47b` (test)

## Files Created/Modified

- `test/oban_powertools/web/copy_contract_test.exs` - Finite policy, negative fixture, exclusion, state, recovery, receipt, and diagnostic contract.
- `test/oban_powertools/web/components/operator_patterns_test.exs` - D-16/D-20 confirmation ordering, reason association, dismissal, and authority assertions.

## Decisions Made

- Kept unique page consequences and support boundaries caller-owned instead of placing runtime prose in the finite registry.
- Required exact bounded diagnostic fields and excluded preview, reason, payload, provider, and credential-shaped data from the policy boundary.
- Required submit to precede the safe-state dismiss action, exposing the existing opposite button order as the single component RED seam.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The focused suites compile and fail only at the two intended RED seams: the absent `ObanPowertools.Web.Copy.contract/0` and the current confirmation submit/dismiss ordering.

## User Setup Required

None - no external service configuration required.

## Verification Evidence

- `mix test test/oban_powertools/web/copy_contract_test.exs --seed 0` — intentional RED exit 2; 8/8 failures identify the absent production `Copy.contract/0`.
- `mix test test/oban_powertools/web/components/operator_patterns_test.exs --seed 0` — intentional RED exit 2; 22 cases pass and the single failure names the D-16 submit-before-safe-dismiss defect.
- Combined focused run — 31 tests, 9 intentional failures: eight missing policy failures and one confirmation ordering failure.
- `mix format` and `git diff --check` — pass for both task-owned files.

## Next Phase Readiness

- Plan 82-17 can implement the finite `Copy` owner against the eight exact policy cases.
- The shared component repair plan can reverse the button semantics without changing authority, preview identity, mutation state, or page-owned truth.
- No blockers or architectural changes were introduced.

## Self-Check: PASSED

- Both task-owned files exist.
- Both task commits exist.
- All intended RED failures are attributable to the planned Phase 82 implementation seams.

---
*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Completed: 2026-07-29*
