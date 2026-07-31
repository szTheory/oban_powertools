---
phase: 72-stress-fixtures-showcase-skeleton
plan: 03
subsystem: testing
tags: [showcase, fixtures, deterministic, vrt, accessibility]

requires:
  - phase: 72-01
    provides: RED catalog and package-exclusion contracts
provides:
  - Canonical deterministic scenario catalog for showcase stories
  - Stable domain, scenario, snapshot, and accessibility target helpers
  - Synthetic stress fixtures covering FIX-01 through FIX-03
affects: [phase-72, phase-73, showcase, visual-regression, accessibility]

tech-stack:
  added: []
  patterns:
    - test/support dev-test-only catalog compiled through existing test support path
    - constant map fixtures with stable scenario IDs and target names

key-files:
  created:
    - test/support/showcase_catalog.ex
  modified:
    - test/support/showcase_catalog.ex

key-decisions:
  - "Kept the canonical catalog in test/support/showcase_catalog.ex so fixtures remain dev/test-only and excluded from Hex package files."
  - "Used atom-keyed constant maps and module attributes for deterministic scenario data, with snapshot and a11y targets derived from stable IDs."

patterns-established:
  - "Showcase scenarios expose id, domain, name, persona, jtbd, states, fixtures, and test_targets as a stable public contract."
  - "Fixture values are synthetic constants only; no DB inserts, time calls, UUID generation, random data, or external dependencies."

requirements-completed: [FIX-01, FIX-02, FIX-03]

duration: 9 min
completed: 2026-06-18
status: complete
---

# Phase 72 Plan 03: Canonical Deterministic Scenario Catalog Summary

**Domain-first, deterministic showcase catalog with stable scenario IDs, VRT names, a11y selectors, and synthetic stress fixtures across all operator surfaces.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-18T23:47:10Z
- **Completed:** 2026-06-18T23:56:06Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added `ObanPowertools.ShowcaseCatalog` under the existing test support path.
- Implemented `domains/0`, `required_state_tags/0`, `required_personas/0`, `scenarios/0`, `scenarios_by_domain/0`, `scenario!/1`, `snapshot_name/1`, and `a11y_target/1`.
- Populated nine stable public scenario IDs across overview, jobs, batches, workflows, cron, limiters, lifeline, audit, and forensics.
- Covered the required state tags and persona/JTBD categories with constant synthetic fixture maps.
- Verified the package exclusion assertions remain green while Phase 71 runtime assets stay packaged.

## Task Commits

1. **Task 1: Create catalog module and public API** - `aaf90ef` (feat)
2. **Task 2: Populate domain-first scenarios and targets** - `caee9cb` (feat)

## Files Created/Modified

- `test/support/showcase_catalog.ex` - Canonical deterministic scenario catalog and target helper API.

## Decisions Made

- Kept fixture data in `test/support/showcase_catalog.ex` rather than `lib/` to preserve the dev/test-only package boundary.
- Used constant maps with atom keys to match the Plan 72-01 test contract and keep downstream renderers simple.
- Derived snapshot names and accessibility selectors from scenario IDs, not display copy.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial verification could not run until locked Mix dependencies were fetched in the isolated worktree. `mix deps.get` succeeded without adding or changing dependency declarations.
- A relative `apply_patch` attempt created an untracked catalog file in the orchestrator checkout before implementation continued. That untracked file was removed immediately, the main checkout was verified clean for that path, and subsequent edits used canonical worktree absolute paths.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/showcase_catalog_test.exs` - PASS, 7 tests, 0 failures.
- `! rg 'DateTime\.utc_now|NaiveDateTime\.utc_now|System\.system_time|Ecto\.UUID\.generate|Enum\.random|:rand|Faker' test/support/showcase_catalog.ex` - PASS, no matches.
- `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` - PASS, 36 tests, 0 failures.
- `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/hex_release_test.exs` - PASS, 43 tests, 0 failures.
- `! rg '\bRepo\.|\binsert\(|Oban\.insert|Ecto\.Multi' test/support/showcase_catalog.ex` - PASS, no DB setup calls.

## Known Stubs

None.

## Authentication Gates

None.

## Next Phase Readiness

Plan 72-04 can load `ObanPowertools.ShowcaseCatalog` from test/dev support without duplicating fixture data. Plan 73 can use the stable scenario IDs, snapshot names, and `[data-obpt-story="..."]` selectors as VRT and accessibility targets.

## Self-Check: PASSED

- Found `test/support/showcase_catalog.ex`.
- Found `.planning/phases/72-stress-fixtures-showcase-skeleton/72-03-SUMMARY.md`.
- Found task commits `aaf90ef` and `caee9cb` in git history.

---
*Phase: 72-stress-fixtures-showcase-skeleton*
*Completed: 2026-06-18*
