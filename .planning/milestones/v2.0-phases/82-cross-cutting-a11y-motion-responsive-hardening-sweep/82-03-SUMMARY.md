---
phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
plan: "03"
subsystem: testing
tags: [node-test, accessibility, motion, manifest, ci-policy, redaction]

requires:
  - phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
    provides: Plan 82-01 RED mutation contracts for inventory, motion, exceptions, and CI bypasses
provides:
  - One exported Node owner for Phase 82 inventory, motion-source, exception, and CI policy
  - Parsed production CSS motion inventory with exact source/package equality
  - Bounded deterministic CLI report derived from the schema-8 manifest
affects: [82-05, 82-08, 82-09, 82-10, 82-11]

tech-stack:
  added: []
  patterns:
    - Pure structured validators share one fail-closed policy owner with the repository CLI
    - Manifest inventory is derived at runtime rather than copied into browser code

key-files:
  created:
    - test/browser/support/verify-phase82-quality.mjs
  modified: []

key-decisions:
  - "Derive target, page, and route-family counts directly from the generated schema-8 manifest; keep no production target-ID list."
  - "Keep public validators pure over structured inputs while the CLI owns exact repository traversal and emits only bounded counts."
  - "Parse source CSS into a structured 18-declaration motion inventory and compare packaged CSS byte-for-byte at the same owner boundary."

patterns-established:
  - "Sole policy owner: later token, package, and CI plans import or execute verify-phase82-quality.mjs unchanged."
  - "Bounded diagnostics: CLI output is limited to counts, and failure output to path, line, rule, and count."

requirements-completed:
  - A11Y-01
  - A11Y-04
  - MOTION-01
  - MOTION-02
  - NAV-02
  - DATA-03
  - COPY-01
  - COPY-02

duration: 8min
completed: 2026-07-29
status: complete
---

# Phase 82 Plan 03: Sole Static Quality Policy Summary

**One exported Node validator now mutation-proves generated inventory, production motion sources, exact exceptions, and required CI graph policy while emitting a redacted repository report**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-29T20:11:20Z
- **Completed:** 2026-07-29T20:19:26Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Turned all 39 Plan 82-01 Node mutations green against one exported module without changing the RED contract.
- Added exact production traversal for Elixir/HEEx, JavaScript/TypeScript, source CSS, and packaged CSS, including raw timing/easing, keyframe, scope, reduction, exclusion, and package-drift failures.
- Derived schema 8, 163 targets, 99 page stories, and nine route families from the generated manifest and emitted a bounded report containing 18 parsed source motion declarations.
- Added fail-closed exact, expiring, executable exception validation and ordered required-CI command validation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement the single exported static-quality policy** - `707be93` (feat)

The RED contract was established previously in `267c8c2`; this plan supplies the GREEN implementation.

## Files Created/Modified

- `test/browser/support/verify-phase82-quality.mjs` - Sole pure validator exports, production source walker, CSS motion inventory, and bounded CLI.

## Decisions Made

- The generated manifest remains the only production inventory; route-family equality is derived from page stories rather than maintained as a second list.
- The public API accepts structured inputs for complete mutation coverage, while only the CLI performs repository file traversal.
- Packaged CSS is scanned for unsafe declarations and compared byte-for-byte with the source, but the reported declaration count remains source-owned.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first CLI report counted scanned files but not parsed declarations. The implementation was tightened before commit to expose the real 18-declaration source inventory.

## User Setup Required

None - no external service configuration required.

## Verification Evidence

- `npm run showcase:manifest` — pass; generated schema 8 manifest.
- `node --test test/browser/support/verify-phase82-quality.test.mjs` — pass; 39 tests, 4 suites, zero failures.
- `node test/browser/support/verify-phase82-quality.mjs` — pass; 163 targets, 99 page stories, nine routes, three roots, 30 files, 18 declarations, zero exceptions.
- `npx prettier --check test/browser/support/verify-phase82-quality.mjs test/browser/support/verify-phase82-quality.test.mjs` — pass.
- `git diff --check` for both plan-owned paths — pass.

## Next Phase Readiness

- Plan 82-05 can consume the sole owner for shared token and packaged-asset repairs.
- Plan 82-10 can invoke the unchanged CLI from the required package and CI graph.
- No blocker, new dependency, route, authority change, or parallel policy system was introduced.

## Self-Check: PASSED

- `test/browser/support/verify-phase82-quality.mjs` exists.
- Task commit `707be93` exists.
- All 39 mutation cases and the repository CLI pass.

---
*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Completed: 2026-07-29*
