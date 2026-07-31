---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 09
subsystem: testing
tags: [showcase, schema-8, playwright, accessibility, visual-regression]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 08
    provides: Exact ordered 49-story Elixir catalog with 18 Jobs and 12 Forensics stories
  - phase: 79-page-migration-wave-1-overview-cron-limiters-audit
    plan: 12
    provides: Schema-8 acceptance metadata and the canonical 83-target task-entry prefix
provides:
  - Deterministic schema-8 manifest with 49 generated page stories and 113 total targets
  - Task-entry byte and SHA-256 proof that the first 83 target values remain unchanged
  - Strict manifest-derived contracts for 147 ARIA snapshots and 588 tracked PNG baselines
  - Generic 49-story acceptance, axe, and VRT discovery across all three Chromium projects
affects: [80-10, 80-11, 80-12, page-quality, aria-snapshots, visual-regression]

tech-stack:
  added: []
  patterns:
    - Derive every browser page target and evidence path from generated page_stories
    - Preserve dirty-worktree prefixes with task-entry compact JSON and SHA-256 evidence
    - Require exact filesystem and tracked baseline equality before accepting visual evidence

key-files:
  created:
    - test/browser/specs/page.acceptance.spec.ts
    - test/browser/support/verify-page-aria-snapshots.mjs
  modified:
    - scripts/showcase_manifest.exs
    - test/browser/support/manifest.ts
    - test/browser/support/manifest-smoke.mjs
    - test/browser/support/verify-page-baselines.mjs

key-decisions:
  - "Keep schema 8 and derive all 49 page stories from the Elixir catalog without a literal Jobs/Forensics browser registry."
  - "Treat the generated manifest as ignored verification output, not a committed Plan 80-09 repository artifact."
  - "Require both filesystem equality and Git-tracked equality for the future 588-PNG baseline set, with rename/copy/untracked/non-page rejection."

patterns-established:
  - "Task-entry prefix integrity: capture compact JSON bytes and SHA-256 before the first generator mutation, then compare identical serialization afterward."
  - "Evidence deferral: contract-only modes prove exact future sets while default verification rejects missing evidence until its owning plan adopts it."

requirements-completed: ["PAGE-02", "PAGE-09", "DATA-*", "PAGE-10", "A11Y-*"]

duration: 12m
completed: 2026-07-28
status: complete
---

# Phase 80 Plan 09: Manifest and Browser Contract Expansion Summary

**Schema-8 discovery now derives all 49 production page stories into 113 deterministic targets, with preserved first-83 bytes and exact 147-ARIA/588-PNG future evidence contracts**

## Performance

- **Duration:** 12m
- **Started:** 2026-07-28T17:40:31Z
- **Completed:** 2026-07-28T17:52:22Z
- **Tasks:** 1
- **Files modified:** 6

## Accomplishments

- Expanded the generated page-story domain from four to the closed ordered six-family set `overview|cron|limiters|audit|jobs|forensics`, yielding 49 page stories and 113 total targets without changing schema 8.
- Preserved the exact task-entry first 83 target values as 47,141 compact JSON bytes with SHA-256 `91b346c787059cd09ca7d7a47005d2687ec0a22f76bd2f6e4cc15f76c0b6c704`.
- Proved repeat generation is byte-stable with whole-manifest SHA-256 `09a8cec297d93c32c05ce5121751d3f6ec6fe8c1a3f311856dd65887dea747b8`.
- Added exact manifest-derived 147-ARIA and 588-tracked-PNG contracts without generating or adopting either evidence family.
- Registered 147 generic acceptance cases, 588 generic page axe cases, and 588 generic page VRT cases with zero skip/fixme markers.

## Task Commits

Task 80-09-01 used one atomic red-green pair:

1. **RED: Lock expanded page discovery contracts** - `6262916`
2. **GREEN: Generate expanded page manifest** - `7d37ef1`

## Files Created/Modified

- `scripts/showcase_manifest.exs` - Keeps schema 8 while requiring 49 generated page stories and 113 aggregate targets.
- `test/browser/support/manifest.ts` - Strictly validates six ordered families, 49 stories, 113 targets, exact fields, family-bound IDs, and derived target order.
- `test/browser/support/manifest-smoke.mjs` - Independently enforces the same closed generated contract and supports isolated negative-manifest verification.
- `test/browser/support/verify-page-baselines.mjs` - Derives 588 exact paths and rejects missing, extra, untracked, renamed, copied, or non-page visual scope.
- `test/browser/support/verify-page-aria-snapshots.mjs` - Derives and verifies the exact 147-path ARIA set.
- `test/browser/specs/page.acceptance.spec.ts` - Discovers every generated story across three projects and applies generic copy, role, order, one-tree, overlay, table, timeline, progress, and confidentiality contracts.

## Decisions Made

- Kept the Elixir `PageStoryCatalog` as the only literal 49-story registry. Browser validators use the generated `page_stories` array and contain no literal Jobs/Forensics story IDs.
- Did not stage `test/browser/.generated/showcase-manifest.json`: it is ignored generated verification output, is absent from Plan 80-09 ownership frontmatter, and is reproducible at the recorded hash.
- Added contract-only validator modes so Plan 80-09 can prove the exact future path cardinalities while default verification continues to reject the 360 missing PNGs and 90 missing ARIA snapshots until Plan 80-12 owns their generation and adoption.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The declared generator/browser files entered the task with uncommitted Phase 79 schema-8 acceptance work. Those related hunks were preserved in place as the required current contract while Plan 80-09 added its cardinality/family changes; unrelated catalog acceptance hunks remain unstaged and untouched.
- The pre-existing untracked Phase 79 ARIA tree remains unmodified. The strengthened default validators correctly reject the not-yet-adopted Phase 80 evidence gap rather than creating artifacts early.

## User Setup Required

None.

## Verification

- RED failed for the intended reason: `page_stories.length must be 49, got 19`.
- `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` - schema 8; 49 page stories; 113 targets; four themes; three viewports.
- Prefix proof - before/after compact JSON files are both 47,141 bytes; `cmp` passed; both SHA-256 values are `91b346c787059cd09ca7d7a47005d2687ec0a22f76bd2f6e4cc15f76c0b6c704`.
- Determinism proof - two additional whole-manifest generations compared byte/hash equal at `09a8cec297d93c32c05ce5121751d3f6ec6fe8c1a3f311856dd65887dea747b8`.
- Cardinality/order proof - first page target index 64; 18 Jobs plus 12 Forensics stories append as the exact 30-target suffix; all 49 page targets equal generated story order.
- Negative smoke proof - unknown fields, missing fields, reordered families, and reordered targets all failed with precise diagnostics; the TypeScript path independently rejected the unknown-field mutation.
- `node test/browser/support/verify-page-baselines.mjs --contract` - exactly 588 paths.
- `node test/browser/support/verify-page-baselines.mjs --self-test` - missing, extra, untracked, renamed, copied, and non-page scope all rejected.
- `node test/browser/support/verify-page-aria-snapshots.mjs --contract` - exactly 147 paths.
- Default evidence verification rejected exactly 360 missing PNG and 90 missing ARIA paths, confirming no premature artifact generation/adoption.
- Playwright list discovery - 147 acceptance, 588 page axe, 588 page VRT, zero skip/fixme; 2,859 aggregate registrations in the three requested files.
- `mix test test/oban_powertools/page_story_catalog_test.exs test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0` - 48 tests, 0 failures.
- Node syntax checks, `mix format --check-formatted scripts/showcase_manifest.exs`, `git diff --check`, and `git show --check` passed.

## Next Phase Readiness

- Plan 80-10 can add its isolated fixture/launcher contracts against the stable 49-story manifest.
- Plan 80-12 can generate, review, stage, and compare the exact 147 ARIA plus 588 PNG evidence sets; Plan 80-09 intentionally leaves those artifacts unchanged.

## Self-Check: PASSED

- RED `6262916` and GREEN `7d37ef1` exist and contain exactly the six declared task files across the pair.
- The summary records the exact task-entry prefix bytes/hash, whole-manifest hash, six-family/cardinality/order proof, negative validation, Playwright census, and evidence deferral.
- No package script, catalog, fixture, launcher, CSS, schema version, dependency, ARIA snapshot, PNG baseline, `.planning/STATE.md`, or `.planning/REQUIREMENTS.md` change was introduced by Plan 80-09.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-28*
