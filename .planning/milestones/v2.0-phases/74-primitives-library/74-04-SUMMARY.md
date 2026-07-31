---
phase: 74-primitives-library
plan: 04
subsystem: testing
tags: [playwright, axe, manifest, primitives, vrt, accessibility]
requires:
  - phase: 74-primitives-library
    provides: 74-03 primitive story catalog and rendered primitive showcase cells
  - phase: 73-visual-regression-a11y-harness
    provides: Playwright structure, VRT, and axe harness for showcase targets
provides:
  - Schema v2 showcase manifest with scenarios, primitive stories, and unified generated targets
  - TypeScript and smoke validators for primitive metadata, target provenance, and schema drift
  - Browser structure, VRT, and axe specs that consume generated unified targets
affects: [phase-74-primitives, phase-75-forms, phase-83-showcase-docs, visual-a11y]
tech-stack:
  added: []
  patterns:
    - Elixir catalog data generates Playwright manifest targets
    - TypeScript validates manifest provenance before specs execute
    - Browser specs loop over discriminated scenario/primitive targets
key-files:
  created: []
  modified:
    - scripts/showcase_manifest.exs
    - test/browser/support/manifest.ts
    - test/browser/support/manifest-smoke.mjs
    - test/browser/support/showcase.ts
    - test/browser/specs/showcase.structure.spec.ts
    - test/browser/specs/showcase.vrt.spec.ts
    - test/browser/specs/showcase.a11y.spec.ts
key-decisions:
  - "Manifest schema is deliberately bumped to v2 while preserving the existing `scenarios` array for Phase 73 compatibility."
  - "Primitive browser targets are generated from `ObanPowertools.PrimitiveStoryCatalog` and validated as manifest data, not copied into TypeScript arrays."
  - "VRT and axe result names include target kind so primitive and scenario provenance remains visible in artifacts."
patterns-established:
  - "Use `targets` for browser structure, VRT, and axe loops while keeping `storyLocator(page, scenario)` as a compatibility wrapper."
  - "Validate `targets` against derived scenario and primitive metadata to catch hardcoded drift."
requirements-completed: [COMP-04, A11Y-02, SHOW-01]
duration: 8 min
completed: 2026-07-11
status: complete
---

# Phase 74 Plan 04: Unified Playwright Manifest And Target Integration Summary

**Schema v2 showcase manifest and browser specs now include seven primitive stories in the same generated VRT/a11y target matrix as the nine stress scenarios**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-11T01:01:43Z
- **Completed:** 2026-07-11T01:09:31Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Extended `scripts/showcase_manifest.exs` to emit schema v2 with `scenarios`, `primitive_stories`, and unified `targets` generated from Elixir catalog data.
- Added TypeScript and smoke validation for primitive story ids, component metadata, snapshot/a11y selectors, target counts, and target provenance.
- Converted browser structure, VRT, and axe specs to loop over generated `targets` so primitive stories join the existing theme and viewport harness.

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | Generate and validate unified manifest targets | `21f9e04` | feat |
| 2 | Convert structure, VRT, and axe specs to unified targets | `36574a4` | feat |

## Files Created/Modified

- `scripts/showcase_manifest.exs` - Emits schema v2 manifest data from both `ShowcaseCatalog` and `PrimitiveStoryCatalog`.
- `test/browser/support/manifest.ts` - Validates schema v2 and exports `scenarios`, `primitiveStories`, `targets`, `themes`, and `viewports`.
- `test/browser/support/manifest-smoke.mjs` - Mirrors schema v2 runtime validation for smoke checks.
- `test/browser/support/showcase.ts` - Adds `targetLocator` and validates scenario and primitive target structure.
- `test/browser/specs/showcase.structure.spec.ts` - Checks generated scenario and primitive targets render.
- `test/browser/specs/showcase.vrt.spec.ts` - Loops screenshots over generated targets.
- `test/browser/specs/showcase.a11y.spec.ts` - Loops axe scans over generated targets and names artifacts by target kind.

## Decisions Made

- Kept `scenarios` unchanged for Phase 73 compatibility, then added `primitive_stories` and `targets` rather than replacing the old contract.
- Made the Elixir manifest the source of truth for primitive targets; TypeScript validators only validate and derive from manifest content.
- Preserved the existing `storyLocator(page, scenario)` helper as a wrapper around `targetLocator` for compatibility with future scenario-only tests.

## TDD Notes

- **Task 1 RED:** After tightening validators, the existing generator failed as expected with `schema_version must be 2, got 1`.
- **Task 1 GREEN:** `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` passed with 9 scenarios, 7 primitive stories, and 16 targets.
- **Task 2 RED:** Before spec conversion, the primitive-filtered axe command failed as expected with `No tests found`.
- **Task 2 GREEN:** Structure passed 4 checks and primitive-filtered axe passed 28 checks on `chromium-320`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The example-host server wrapper printed pre-existing Hex dependency security advisory output while resolving unchanged dependencies. The browser commands still completed successfully. No package installs or upgrades were performed in this plan.

## Known Stubs

None. Stub scan found only `const expectedTargets = []` in `test/browser/support/manifest-smoke.mjs`; it is a local validation accumulator populated before checks and does not flow to UI rendering.

## Threat Flags

None. This plan changed generated test manifest and browser test surfaces only; it added no production route, auth path, network endpoint, package install, or host trust-boundary change beyond the planned manifest validation boundary.

## User Setup Required

None - no external service configuration required.

## Verification

- `npm run showcase:manifest` - PASSED; generated schema v2 manifest.
- `node test/browser/support/manifest-smoke.mjs` - PASSED; 9 scenarios, 7 primitive stories, 16 targets, 4 themes, 3 viewports.
- `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/showcase.structure.spec.ts --project chromium-320` - PASSED; 4 tests, 0 failures.
- `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/showcase.a11y.spec.ts --project chromium-320 --grep primitive` - PASSED; 28 tests, 0 failures.

## Orchestrator Coordination

Per execution coordination, this executor did not update `.planning/STATE.md`, `.planning/ROADMAP.md`, or `.planning/REQUIREMENTS.md`. The central orchestrator owns those shared tracking updates after the wave.

## Self-Check: PASSED

- Found `scripts/showcase_manifest.exs`.
- Found `test/browser/support/manifest.ts`.
- Found `test/browser/support/manifest-smoke.mjs`.
- Found `test/browser/support/showcase.ts`.
- Found `test/browser/specs/showcase.structure.spec.ts`.
- Found `test/browser/specs/showcase.vrt.spec.ts`.
- Found `test/browser/specs/showcase.a11y.spec.ts`.
- Found summary file at `.planning/phases/74-primitives-library/74-04-SUMMARY.md`.
- Found task commits `21f9e04` and `36574a4` in git history.

## Next Phase Readiness

Ready for `74-05`: primitive behavior checks and VRT baseline generation can consume the unified manifest target contract without hardcoded primitive target lists.

---
*Phase: 74-primitives-library*
*Completed: 2026-07-11*
