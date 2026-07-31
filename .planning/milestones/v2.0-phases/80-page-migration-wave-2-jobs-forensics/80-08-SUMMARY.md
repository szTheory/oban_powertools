---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 08
subsystem: testing
tags: [liveview, showcase, page-stories, jobs, forensics, accessibility]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 04
    provides: Production Jobs page_content/1 composition and bounded bulk/detail presentation
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 07
    provides: Production Forensics page_content/1 composition and bounded diagnosis-first timeline
provides:
  - Exact ordered 49-story PageStoryCatalog with 18 Jobs and 12 Forensics stories appended after the existing 19
  - Deterministic D-86/D-87 fixture coverage with bounded 20-row and 50-event presentation inputs
  - Direct ShowcaseLive composition through JobsLive.page_content/1 and ForensicsLive.page_content/1
  - Exact 113-target aggregate showcase cardinality and fail-closed package-boundary coverage
affects: [80-09, page-manifest, browser-quality, aria-snapshots, visual-regression]

tech-stack:
  added: []
  patterns:
    - Append capability-owned page stories without rewriting the existing catalog prefix
    - Keep fixtures normalized and materialize Phoenix forms or MapSet values only at the Showcase boundary
    - Exercise production page_content/1 seams with one active tree and at most one overlay

key-files:
  created: []
  modified:
    - test/support/page_story_catalog.ex
    - test/oban_powertools/page_story_catalog_test.exs
    - test/oban_powertools/showcase_catalog_test.exs
    - lib/oban_powertools/web/dev/showcase_live.ex
    - test/oban_powertools/web/live/showcase_live_test.exs

key-decisions:
  - "Phase 80 stories live in one appended helper block so the original 19-story prefix remains byte/order-stable and the Phase 80 commit remains valid without pre-existing Phase 79 acceptance hunks."
  - "ShowcaseLive materializes only filter/scope/confirmation forms and selected-job MapSets at the component boundary; catalog fixtures remain finite plain data."
  - "Oversized and all-success Jobs stories render non-dialog rejection/receipt truth, while unresolved preview, progress, partial, drifted, disconnected, and interrupted states retain one confirmation."
  - "The mixed-results story uses one partial state with separate success, skipped, and failed rows."

patterns-established:
  - "Bounded stress fixture: large source totals are represented independently from fixed DOM windows."
  - "Production composition proof: page stories call the public page seam directly and never copy page markup."
  - "Dirty-tree isolation: selectively stage only plan-owned hunks and verify the exact index tree independently."

requirements-completed: ["PAGE-02", "PAGE-09", "DATA-*", "PAGE-10", "A11Y-*"]

duration: 22m
completed: 2026-07-28
status: complete
---

# Phase 80 Plan 08: Jobs and Forensics Page Story Catalog Summary

**The showcase now exposes 49 deterministic production-composed page stories, including every locked Jobs and Forensics adversarial state with bounded DOM inputs and no copied page markup**

## Performance

- **Duration:** 22m
- **Started:** 2026-07-28T17:13:16Z
- **Completed:** 2026-07-28T17:35:19Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Appended the exact 18 Jobs IDs followed by the exact 12 Forensics IDs after the existing 19-story prefix, yielding 49 unique `page-` stories in the locked order.
- Covered every D-86/D-87 concept, including distinct bulk success/skipped/failed/drifted/disconnected/interrupted truth, every Forensics evidence family, unavailable/conflicting/unknown/history-unavailable states, and adversarial redaction.
- Kept stress rendering bounded: the thousands story exposes a source total of 2,500 with exactly 20 rows, and the deep-timeline story exposes a source total of 80 with exactly 50 events.
- Extended ShowcaseLive to six page families and direct production `JobsLive.page_content/1` / `ForensicsLive.page_content/1` calls, with forms and selected-job sets materialized only at the boundary.
- Locked 113 total showcase targets and retained isolated absent/non-list/malformed catalog failure behavior plus Hex exclusion.

## Task Commits

Task 80-08-01 used one atomic red-green pair:

1. **RED: Lock Jobs and Forensics page-story contracts** - `3746541`
2. **GREEN: Compose deterministic Jobs and Forensics stories** - `b2e0581`

## Files Created/Modified

- `test/support/page_story_catalog.ex` - Appended Phase 80 story registry, deterministic normalized fixtures, acceptance metadata, target derivation, and bounded data helpers.
- `test/oban_powertools/page_story_catalog_test.exs` - Exact ID order/count, D-86/D-87 mapping, activation, copy, bounds, determinism, and confidentiality contracts.
- `test/oban_powertools/showcase_catalog_test.exs` - Exact aggregate 113-target schema-8 cardinality contract.
- `lib/oban_powertools/web/dev/showcase_live.ex` - Six-family registration, direct Jobs/Forensics production composition, and boundary-only form/MapSet materialization.
- `test/oban_powertools/web/live/showcase_live_test.exs` - One-tree/one-overlay, page seam, semantic table/timeline, bounded DOM, and rendered sentinel coverage.

## Decisions Made

- Added Phase 80 stories after the existing compiled `@stories` prefix rather than extending or rewriting the Phase 79 story-spec block. This preserves the original IDs/content/order and keeps the Phase 80 patch independently coherent.
- Kept every catalog fixture to maps, lists, atoms, binaries, integers, and nil; Phoenix form structs and MapSets are created only immediately before production page composition.
- Modeled clean all-success as a receipt with no open confirmation, and oversized scope as an explicit rejection with no preview. Unresolved results remain visible in one bounded confirmation.
- Used the production component's closed confirmation outcome taxonomy: the partial container names mixed truth while separate rows retain success, skipped, and failed outcomes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Component Contract] Represented zero-ready without an invalid bulk scope**

- **Found during:** GREEN production-composition rendering.
- **Issue:** The shared confirmation component correctly rejects a textual bulk scope when `bulk_count` is nil/zero.
- **Fix:** Kept the zero-ready retained failed state and recovery copy, but omitted the inapplicable bulk-scope line.
- **Files modified:** `test/support/page_story_catalog.ex`
- **Verification:** All 49 stories render through production composition; focused suite passes 48/0.
- **Committed in:** `b2e0581`

**2. [Rule 1 - Test Correctness] Distinguished normalized metadata from raw authority data**

- **Found during:** GREEN catalog validation.
- **Issue:** The inherited generic marker scan rejected the normalized `metadata` presentation key required by the production full-detail contract, despite continuing to reject `raw_metadata`, `raw_exception`, tokens, hashes, credentials, and sentinels.
- **Fix:** Removed only the over-broad `metadata` and `exception` words while retaining raw/source authority markers and explicit confidentiality sentinel scans.
- **Files modified:** `test/oban_powertools/page_story_catalog_test.exs`
- **Verification:** Normalized-shape, no-struct, authority-marker, serialized-sentinel, rendered-sentinel, and package-boundary tests all pass.
- **Committed in:** `b2e0581`

---

**Total deviations:** 2 auto-fixed (1 blocking component contract, 1 test correctness).
**Impact on plan:** Both changes align fixtures with existing production contracts; no production page, route, component, dependency, manifest, browser artifact, CSS, schema, or package file changed.

## Issues Encountered

- The shared checkout already contained uncommitted Phase 79 acceptance metadata and attachment hunks in the two catalog-owned files. Those hunks were preserved in the working tree and excluded from both Phase 80 commits through selective index staging.
- Because the working tree's Phase 79 acceptance layer could otherwise mask an index-only dependency, the exact staged tree was archived to an isolated directory and ran the full focused suite: 48 tests, 0 failures.
- A force compilation of all copied dependencies surfaced pre-existing Oban dependency macro warnings; the normal project `MIX_ENV=test mix compile --warnings-as-errors` gate passed.

## User Setup Required

None. No dependency, migration, route, configuration, schema, asset, fixture module, or external service change is required.

## Verification

- `mix test test/oban_powertools/page_story_catalog_test.exs test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0` - 48 tests, 0 failures.
- The exact staged-tree archive, excluding the dirty Phase 79 hunks, ran the same focused command - 48 tests, 0 failures.
- `mix test test/oban_powertools/hex_release_test.exs --seed 0` - 38 tests, 0 failures.
- Exact five-file `mix format --check-formatted ...` command passed.
- `MIX_ENV=test mix compile --warnings-as-errors` passed.
- Catalog proof: 49 total page stories = 19 existing + 18 Jobs + 12 Forensics; all IDs are unique and `page-` prefixed.
- Showcase proof: 113 aggregate targets and page families exactly `[:overview, :cron, :limiters, :audit, :jobs, :forensics]`.
- Bound proof: Jobs source total 2,500 / rendered rows 20; Forensics source total 80 / rendered events 50.
- Composition proof: every activated story renders one production root and H1, Jobs tables and ready Forensics timelines are semantic, and active overlays never exceed one.
- Package proof: optional catalog absence/malformed values fail closed and `test/support/page_story_catalog.ex` remains excluded from Hex/runtime files.
- `git show --check` passes for both task commits.

## Next Phase Readiness

- Plan 80-09 can derive the schema-8 manifest and browser discovery matrix from the locked 49-story Elixir registry without adding another literal registry.
- Plan 80-12 can generate the expected Jobs/Forensics ARIA and PNG evidence from the production-composed stories.
- The pre-existing uncommitted Phase 79 acceptance hunks remain owned by their original workstream and were not absorbed into Plan 80-08.

## Self-Check: PASSED

- Exact RED/GREEN commits exist as `3746541` / `b2e0581`.
- All five authorized implementation/test files are represented across the task commits.
- Exact 49/30 append, 20-row, 50-event, D-86/D-87, 113-target, production seam, package, formatting, and warnings-as-errors contracts pass.
- No `.planning/STATE.md` or `.planning/REQUIREMENTS.md` change was staged or committed.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-28*
