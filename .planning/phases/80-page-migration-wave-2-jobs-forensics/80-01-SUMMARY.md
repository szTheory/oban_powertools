---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 01
subsystem: database
tags: [ecto, postgres, jobs, url-canonicalization]

requires: []
provides:
  - Predicate-consistent bounded Jobs list, count, grouped-count, and ID-window APIs
  - Pure canonical Jobs URL parsing with retained invalid draft validation
  - Closed ordered Jobs list and full-detail return URL encoders
affects: [80-02, 80-03, 80-04]

tech-stack:
  added: []
  patterns:
    - One shared non-state Ecto predicate pipeline for all Jobs read shapes
    - Applied URL state remains separate from retained draft form state
    - Closed ordered selector allowlists prevent opaque return-context propagation

key-files:
  created:
    - lib/oban_powertools/web/jobs_params.ex
    - test/oban_powertools/web/jobs_params_test.exs
  modified:
    - lib/oban_powertools/jobs.ex
    - lib/oban_powertools/web/selectors.ex
    - test/oban_powertools/jobs_test.exs
    - test/oban_powertools/web/selectors_test.exs

key-decisions:
  - "Canonical Jobs URLs always include state, omit the default first page, and keep quick-review identity outside the Jobs query struct."
  - "Invalid direct URL values collapse to one safe finite notice, while invalid drafts retain exact original strings and expose no applied state."
  - "Filter identity is the deterministic encoded state/filter allowlist with page and quick review excluded."

patterns-established:
  - "Predicate equivalence: rows, exact count, grouped state counts, and ordered IDs share one optional-filter pipeline."
  - "Bounded reads: list pages are fixed at 20 rows and ID scopes read limit plus one only to detect overflow."
  - "Canonical navigation: Jobs list and detail links reorder and strip inputs through closed allowlists."

requirements-completed: ["PAGE-02", "FORM-03", "DATA-*", "PAGE-10"]

duration: 24min
completed: 2026-07-27
status: complete
---

# Phase 80 Plan 01: Jobs Query and URL Foundation Summary

**Predicate-consistent bounded Jobs reads plus pure retained-draft validation and closed canonical list/detail URLs**

## Performance

- **Duration:** 24 min
- **Started:** 2026-07-28T02:14:26Z
- **Completed:** 2026-07-28T02:38:21Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Unified queue, worker, all-required tags, args-map, and meta-map predicates across bounded rows, exact active counts, one grouped seven-state count query, and stable limit-plus-one ID windows.
- Added a pure Jobs parameter boundary that returns safe `%Jobs{page_size: 20}` query state, ordered canonical params, separate quick-review identity, finite replacement truth, and retained draft validation with byte-exact help/error copy.
- Closed Jobs list and full-detail URL emission to deterministic allowlists, preserving existing one-argument detail paths while stripping `job`, `return_to`, and unknown keys from detail context.

## Task Commits

Each task was committed atomically:

1. **Task 80-01-01: Implement bounded predicate-consistent Jobs query APIs** - `7445f6c` (feat)
2. **Task 80-01-02: Implement canonical Jobs params and allowlisted URLs** - `cd2e112` (feat)

## Files Created/Modified

- `lib/oban_powertools/jobs.ex` - Shared optional predicates, exact count, one-query grouped counts, fixed 20-row pages, and bounded stable ID windows.
- `lib/oban_powertools/web/jobs_params.ex` - Pure safe URL parser, retained-draft validator, and deterministic filter identity.
- `lib/oban_powertools/web/selectors.ex` - Closed ordered Jobs list and detail-return encoders with compatible `job_detail_path/1`.
- `test/oban_powertools/jobs_test.exs` - Predicate equivalence, fixed ordering/pages, grouped query count, exact count, and 21-ID overflow proof.
- `test/oban_powertools/web/jobs_params_test.exs` - Seven-state parsing, invalid URL/draft isolation, exact copy, round-trip, and identity contracts.
- `test/oban_powertools/web/selectors_test.exs` - Canonical order, allowlist stripping, delimiter safety, and detail-return regression coverage.

## Decisions Made

- Kept canonical applied URL data as ordered string pairs so selector output and frozen filter identity are byte-stable and independent of map order.
- Treated missing required state as a quiet canonical default requiring replacement; malformed values and unknown keys additionally receive one fixed safe notice.
- Made invalid draft validation all-or-nothing: original optional-field strings and inline errors remain available, but `applied` is `nil` and `patch?` is always false.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/oban_powertools/jobs_test.exs --seed 0` - 15 tests, 0 failures.
- `mix test test/oban_powertools/web/jobs_params_test.exs test/oban_powertools/web/selectors_test.exs --seed 0` - 20 tests, 0 failures.
- `mix test test/oban_powertools/jobs_test.exs test/oban_powertools/web/jobs_params_test.exs test/oban_powertools/web/selectors_test.exs --seed 0` - 35 tests, 0 failures.
- Both plan formatting checks passed.
- The implementation diff from the plan baseline contains exactly the six declared production/test paths.

## Next Phase Readiness

- Plan 80-02 can integrate safe URL canonicalization, exact pagination/count truth, retained submit-mode drafts, and quick-review identity without duplicating parsing or query construction.
- Plan 80-04 can freeze deterministic filter identity and bounded ordered ID scopes without using the legacy unbounded `list_ids/2` path.

## Self-Check: PASSED

- All six declared implementation/test files exist.
- Task commits `7445f6c` and `cd2e112` exist and contain only their declared task paths.
- Every task acceptance criterion and plan verification command passed.
- No schema, migration, dependency, mutation, presenter, LiveView composition, fixture, story, asset, or evidence file was added.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-27*
