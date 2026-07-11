---
phase: 74-primitives-library
plan: 03
subsystem: ui
tags: [phoenix-component, primitives, showcase, accessibility, vrt]
requires:
  - phase: 74-primitives-library
    provides: 74-01 primitive Phoenix.Component API and render/static contracts
  - phase: 74-primitives-library
    provides: 74-02 token-backed primitive CSS and tooltip behavior
provides:
  - Separate `ObanPowertools.PrimitiveStoryCatalog` for Phase 74 primitive story targets
  - Primitive story rendering inside the existing dev-only `_showcase` `primitives` section
  - Stable primitive story ids, metadata, snapshot names, and a11y selectors for later manifest/VRT work
affects: [phase-74-primitives, phase-75-forms, phase-83-showcase-docs]
tech-stack:
  added: []
  patterns:
    - Dev/test support-module catalog loaded at runtime by the dev-only showcase
    - Primitive story cells separate from domain stress fixture stories
    - Story ids as source of truth for snapshot and a11y target derivation
key-files:
  created:
    - test/support/primitive_story_catalog.ex
    - test/oban_powertools/primitive_story_catalog_test.exs
  modified:
    - lib/oban_powertools/web/dev/showcase_live.ex
    - test/oban_powertools/web/live/showcase_live_test.exs
key-decisions:
  - "Primitive stories live in `ObanPowertools.PrimitiveStoryCatalog`, not `ObanPowertools.ShowcaseCatalog.scenarios/0`, preserving the domain stress fixture boundary."
  - "Primitive showcase cells use `data-obpt-primitive-story` plus component/variant/state/a11y metadata so 74-04 can generate unified manifest targets without TypeScript hardcoding."
  - "The showcase renders real primitive component examples while retaining the existing compile-time dev/test route guard and host router contract."
patterns-established:
  - "Primitive story metadata includes `kind`, `component`, `components`, `variant`, `state`, `snapshot`, `a11y`, and `test_targets`."
  - "Showcase story wrappers derive ids, snapshot names, and a11y selectors from stable story ids rather than display copy."
requirements-completed: [COMP-01, COMP-04, A11Y-02, SHOW-01]
duration: 6 min
completed: 2026-07-11
status: complete
---

# Phase 74 Plan 03: Primitive Story Catalog And Showcase Rendering Summary

**Separate primitive story registry with seven real showcase cells rendering the Phase 74 primitive components under stable VRT/a11y selectors**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-11T00:50:33Z
- **Completed:** 2026-07-11T00:56:17Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `ObanPowertools.PrimitiveStoryCatalog` with exactly seven Phase 74 primitive story ids and helpers for `stories/0`, `story!/1`, `snapshot_name/1`, and `a11y_target/1`.
- Added catalog tests proving deterministic ids, full COMP-01 primitive coverage, ID-derived targets, and separation from `ShowcaseCatalog.scenarios/0`.
- Updated the dev-only showcase to load primitive stories and render real `Primitives` examples in the existing `primitives` section with stable `data-obpt-*` metadata.

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | Create the primitive story catalog | `64f090a` | feat |
| 2 | Render primitive stories in the showcase | `b2d93d5` | feat |

## Files Created/Modified

- `test/support/primitive_story_catalog.ex` - Deterministic primitive story registry, coverage metadata, and stable target helpers.
- `test/oban_powertools/primitive_story_catalog_test.exs` - Catalog contract tests for deterministic metadata, helper derivation, and stress-catalog separation.
- `lib/oban_powertools/web/dev/showcase_live.ex` - Runtime primitive catalog loading and real primitive story rendering under `data-obpt-section="primitives"`.
- `test/oban_powertools/web/live/showcase_live_test.exs` - Showcase assertions for primitive story selectors/copy while preserving existing stress story metadata checks.

## Decisions Made

- Kept primitive stories out of the stress fixture catalog per D-17; the existing domain/persona/JTBD stories remain catalog-backed and unchanged.
- Used `data-obpt-primitive-story` for primitive cells instead of overloading `data-obpt-story`, leaving existing stress story selectors intact.
- Rendered representative operator-console examples only; no form/data/group/page placeholders were added to the primitive catalog.

## TDD Notes

- **Task 1 RED:** `mix test test/oban_powertools/primitive_story_catalog_test.exs` failed before implementation with `UndefinedFunctionError` for missing `ObanPowertools.PrimitiveStoryCatalog.stories/0`.
- **Task 1 GREEN:** The same command passed after implementation with 5 tests, 0 failures.
- **Task 2 RED:** `mix test test/oban_powertools/web/live/showcase_live_test.exs` failed before implementation because `data-obpt-primitive-story` values were absent.
- **Task 2 GREEN:** The same command passed after showcase rendering with 7 tests, 0 failures.
- Per executor coordination, commits were kept task-atomic after RED/GREEN verification.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix format` adjusted the Task 1 test after the first Task 1 commit. The formatting-only change was amended into Task 1 before Task 2 was committed, preserving task ownership.

## Known Stubs

- `lib/oban_powertools/web/dev/showcase_live.ex:214` retains a defensive primitive-catalog-unavailable fallback. It is not active in normal dev/test because the primitive catalog loads successfully.
- `lib/oban_powertools/web/dev/showcase_live.ex:219` retains the existing reserved placeholder for later non-primitive sections such as forms, data display, groups, and pages.
- `lib/oban_powertools/web/dev/showcase_live.ex:277` retains the existing catalog-unavailable fallback for the stress fixture index.

## Threat Flags

None. The new catalog-to-showcase trust boundary is the planned T-74-09/T-74-10 surface, covered by deterministic metadata tests, HEEx escaping, and no raw HTML story fields. No router, auth path, production route, package install, or mutation surface was added.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/primitive_story_catalog_test.exs` - RED before implementation, then PASSED with 5 tests, 0 failures.
- `mix test test/oban_powertools/web/live/showcase_live_test.exs` - RED before implementation, then PASSED with 7 tests, 0 failures.
- `mix test test/oban_powertools/primitive_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs` - PASSED with 12 tests, 0 failures.
- `mix test test/oban_powertools/web/components/primitives_test.exs test/oban_powertools/web/live/showcase_live_test.exs` - PASSED with 19 tests, 0 failures.

## Orchestrator Coordination

Per execution coordination, this executor did not update `.planning/STATE.md`, `.planning/ROADMAP.md`, or `.planning/REQUIREMENTS.md`. The central orchestrator owns those shared tracking updates after the wave.

## Self-Check: PASSED

- Found `test/support/primitive_story_catalog.ex`.
- Found `test/oban_powertools/primitive_story_catalog_test.exs`.
- Found `lib/oban_powertools/web/dev/showcase_live.ex`.
- Found `test/oban_powertools/web/live/showcase_live_test.exs`.
- Found summary file at `.planning/phases/74-primitives-library/74-03-SUMMARY.md`.
- Found task commits `64f090a` and `b2d93d5` in git history.

## Next Phase Readiness

Ready for `74-04`: the primitive story registry and rendered story cells provide stable targets for unified Playwright manifest and VRT/a11y integration.

---
*Phase: 74-primitives-library*
*Completed: 2026-07-11*
