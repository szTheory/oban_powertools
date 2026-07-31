---
phase: 81-page-migration-wave-3-batches-workflows-lifeline
plan: 15
subsystem: ui-testing
tags: [elixir, typescript, playwright, manifest, accessibility, visual-regression]
requires:
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 06
    provides: exact ordered 99-story nine-family Elixir page catalog
provides:
  - schema-8 manifest contract for 99 page stories and 163 total targets
  - exact 297-file page ARIA snapshot contract
  - exact 1,188-file page screenshot contract
affects: [81-08, 81-09, 81-11, 81-12, 81-13, 81-14, page-quality]
tech-stack:
  added: []
  patterns:
    - derive browser inventory from the generated Elixir catalog
    - reject exact artifact-set and git-state drift
key-files:
  created: []
  modified:
    - scripts/showcase_manifest.exs
    - test/browser/support/manifest.ts
    - test/browser/support/manifest-smoke.mjs
    - test/browser/support/verify-page-baselines.mjs
    - test/browser/support/verify-page-aria-snapshots.mjs
key-decisions:
  - "Retain manifest schema 8 because the Wave 3 catalog adds inventory without changing serialized fields."
  - "Keep the nine-family allowlist closed in validators while deriving every story ID and artifact path from PageStoryCatalog."
  - "Apply the same missing, extra, untracked, renamed/copied, and out-of-scope rejection model to ARIA evidence as screenshot evidence."
patterns-established:
  - "Catalog authority: Elixir owns story identity and order; browser validators own only closed schema and cardinality checks."
  - "Exact evidence: filesystem, tracked set, and changed scope are independently validated."
requirements-completed: [PAGE-03, PAGE-04, PAGE-07, PAGE-10, A11Y-01, A11Y-03, A11Y-04]
duration: 9min
completed: 2026-07-29
status: complete
---

# Phase 81 Plan 15: Nine-Family Browser Contract Summary

**The schema-8 browser graph now validates all 99 page stories and 163 showcase targets while enforcing exact 297-ARIA and 1,188-PNG evidence sets.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-29T08:46:00Z
- **Completed:** 2026-07-29T08:54:54Z
- **Tasks:** 1
- **Files modified:** 5

## Accomplishments

- Extended the generated schema-8 manifest from six to nine closed page families without adding a second story registry.
- Locked browser validation to 99 page stories, 163 total targets, and the original non-page target prefix.
- Expanded exact screenshot validation to 1,188 paths across four themes and three viewports.
- Expanded exact ARIA validation to 297 paths and added tracked, untracked, renamed/copied, unexpected-scope, missing, and extra checks.
- Proved duplicate IDs, invented families, arbitrary activations, and missing targets are rejected.

## Task Commits

1. **Task 81-15-01: Extend schema-8 manifest and exact browser validators** — `b91406f`

## Files Created/Modified

- `scripts/showcase_manifest.exs` - Enforces the 99-story and 163-target generated cardinalities.
- `test/browser/support/manifest.ts` - Types and validates the closed nine-family schema-8 graph.
- `test/browser/support/manifest-smoke.mjs` - Smoke-validates exact generated inventory and target equality.
- `test/browser/support/verify-page-baselines.mjs` - Enforces the exact 1,188-PNG matrix.
- `test/browser/support/verify-page-aria-snapshots.mjs` - Enforces the exact 297-ARIA matrix and git-state scope.

## Decisions Made

- Retained schema version 8 because no serialized field changed.
- Preserved the fixed 64-target non-page prefix and appended all 99 catalog-derived page targets in catalog order.
- Added ARIA validator self-tests and changed-scope support so missing, unexpected, untracked, and renamed evidence cannot silently pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added git-state enforcement to page ARIA evidence**

- **Found during:** Task 81-15-01 exact artifact validator review
- **Issue:** The existing ARIA validator checked filesystem equality and contents but did not independently reject untracked, renamed/copied, or out-of-scope changed artifacts.
- **Fix:** Added tracked-set equality, porcelain rename/copy parsing, changed-scope enforcement, and focused self-tests matching the screenshot validator's fail-closed model.
- **Files modified:** `test/browser/support/verify-page-aria-snapshots.mjs`
- **Verification:** `--contract` reports 297 paths and `--self-test` rejects missing, extra, untracked, renamed, and unexpected-scope inputs.
- **Committed in:** `b91406f`

---

**Total deviations:** 1 auto-fixed (1 missing critical).
**Impact on plan:** The addition closes the artifact-tree trust boundary required by the plan; no product or schema scope changed.

## Issues Encountered

- The 50 new Wave 3 ARIA and screenshot artifacts are intentionally produced by later Phase 81 plans. This plan verifies their exact future matrix with contract and self-test modes rather than fabricating evidence early.

## User Setup Required

None.

## Verification

- `node /Users/jon/.agents/gsd-core/bin/gsd-tools.cjs query verify.key-links .../81-15-PLAN.md` — 1/1 catalog-to-manifest link verified.
- `npm run showcase:manifest && test -f test/browser/.generated/showcase-manifest.json && node test/browser/support/manifest-smoke.mjs` — schema 8; 99 page stories; 163 targets; passed.
- `node test/browser/support/verify-page-baselines.mjs --contract` — exact 1,188-path contract passed.
- `node test/browser/support/verify-page-baselines.mjs --self-test` — missing, extra, untracked, renamed, copied, and non-page scope rejected.
- `node test/browser/support/verify-page-aria-snapshots.mjs --contract` — exact 297-path contract passed.
- `node test/browser/support/verify-page-aria-snapshots.mjs --self-test` — missing, extra, untracked, renamed, and unexpected scope rejected.
- Four manifest mutations — duplicate ID, invented family, arbitrary activation, and missing target were each rejected.
- `npx playwright test test/browser/specs/showcase.a11y.spec.ts --list` — 1,956 generated cases discovered across the expanded graph.
- `git diff --cached --check` — passed.

## Next Phase Readiness

- Plans 81-08/09/11/12 can consume the single generated 99-story inventory.
- Later artifact plans must add exactly 150 Wave 3 ARIA snapshots and 600 Wave 3 PNGs to satisfy the full 297/1,188 contracts.
- No blockers.

## Self-Check: PASSED

- Task commit `b91406f` exists and contains only the five Plan 81-15 files.
- Summary records every plan requirement and exact verification result.
- All unrelated pre-existing dirty work remains unstaged and unchanged.

---
*Phase: 81-page-migration-wave-3-batches-workflows-lifeline*
*Completed: 2026-07-29*
