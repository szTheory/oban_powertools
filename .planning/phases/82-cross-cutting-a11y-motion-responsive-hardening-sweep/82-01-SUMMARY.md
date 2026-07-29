---
phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
plan: "01"
subsystem: testing
tags: [playwright, node-test, accessibility, motion, responsive, ci-policy]

requires:
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    provides: schema-8 manifest with 163 targets and 99 page stories
provides:
  - RED browser contracts for contrast, target geometry, focus, reflow, zoom, motion, system theme, and axe policy
  - RED mutation contracts for inventory, motion sources, exceptions, and required CI bypass prevention
affects: [82-03, 82-04, 82-05, 82-08, 82-09, 82-10]

tech-stack:
  added: []
  patterns:
    - Dynamic imports keep RED suites discoverable before their implementation seams exist
    - Every static mutation proves structured input changed before requiring an exact diagnostic

key-files:
  created:
    - test/browser/specs/system-quality-contract.spec.ts
    - test/browser/support/verify-phase82-quality.test.mjs
  modified: []

key-decisions:
  - "Keep normative 24×24-or-spacing geometry and the named 44px operator comfort policy as separate executable contracts."
  - "Use dynamic imports inside individual tests so all cases are enumerated while failures remain attributable only to missing Phase 82 support modules."
  - "Represent source scans, exceptions, inventory, and CI wiring as structured mutation inputs with exact path, line, selector, threshold, and mechanism diagnostics."

patterns-established:
  - "RED seam: tests enumerate fully and fail only on a future public module import."
  - "Fail-closed mutation: prove the mutation landed, invoke one policy owner, and require an exact diagnostic."

requirements-completed:
  - A11Y-01
  - A11Y-02
  - A11Y-03
  - A11Y-04
  - MOTION-01
  - MOTION-02
  - NAV-02
  - DATA-03

duration: 18min
completed: 2026-07-29
status: complete
---

# Phase 82 Plan 01: System Quality RED Contracts Summary

**Discoverable Playwright and Node contracts now specify the exact WCAG, motion, inventory, exception, and CI-bypass behavior that Phase 82 must implement**

## Performance

- **Duration:** 18 min
- **Started:** 2026-07-29T19:47:00Z
- **Completed:** 2026-07-29T20:05:29Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added 33 browser cases covering unrounded sRGB and alpha contrast, normative and comfort target geometry, strict focus visibility, bounded reflow, restored zoom, independent motion reduction, system-theme computed-role equivalence, and fail-closed axe policy.
- Added 39 Node mutation cases covering schema-8 and 163/99 inventory integrity, exact route-family equality, every declared motion source root and exclusion, source/package drift, exception lifecycle, and required CI graph bypasses.
- Preserved a strict Wave 0 boundary: no production helper, validator, dependency, page behavior, story, package, or CI implementation was added.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write RED browser algorithm fixtures** - `6b04f3b` (test)
2. **Task 2: Write RED validator and bypass mutation fixtures** - `267c8c2` (test)

## Files Created/Modified

- `test/browser/specs/system-quality-contract.spec.ts` - Browser contract tables and bounded DOM fixtures for the future shared quality and axe helpers.
- `test/browser/support/verify-phase82-quality.test.mjs` - Pure structured mutation fixtures for the future sole Node policy owner.

## Decisions Made

- Kept the WCAG 2.5.8 24×24-or-spacing algorithm independent from the project's separate 44px comfort-control rule.
- Used per-test dynamic imports so Playwright lists all 33 cases and Node reports all 39 cases before their future modules exist.
- Required path-and-line diagnostics for production HEEx/Elixir, LiveView, client JavaScript, source CSS, and packaged CSS mutations.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Both prescribed commands fail with the intended missing-module errors, while discovery and formatting succeed.

## User Setup Required

None - no external service configuration required.

## Verification Evidence

- `npx playwright test test/browser/specs/system-quality-contract.spec.ts --list --project=chromium-wide` — exit 0; 33 tests discovered.
- `npx playwright test test/browser/specs/system-quality-contract.spec.ts --project=chromium-wide` — intentional RED exit 1; 33/33 failures identify missing `test/browser/support/system-quality`.
- `node --test test/browser/support/verify-phase82-quality.test.mjs` — intentional RED exit 1; 39/39 failures identify missing `test/browser/support/verify-phase82-quality.mjs`; zero cancelled/skipped.
- `npx prettier --check test/browser/specs/system-quality-contract.spec.ts test/browser/support/verify-phase82-quality.test.mjs` — pass.
- `git diff --check` — pass.

## Next Phase Readiness

- Plan 82-03 can implement the sole Node policy owner against the 39 mutation cases.
- Plan 82-04 can implement shared browser auditors and strict axe policy against the 33 browser cases.
- No blockers or architectural changes were introduced.

## Self-Check: PASSED

- Both created files exist.
- Both task commits exist.
- All intended RED failures are attributable to the missing Phase 82 implementation seams.

---
*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Completed: 2026-07-29*
