---
phase: 78-component-groups-meta-components
plan: 08
subsystem: testing
tags: [operator-patterns, playwright, axe, vrt, accessibility, package-boundary]
requires:
  - phase: 78-component-groups-meta-components
    plan: 07
    provides: connected behavior and five-story mechanical 200 percent zoom contracts
provides:
  - zero-critical-or-serious axe evidence for all 276 group story/theme/viewport cases
  - exact group-only 276-file canonical Docker visual baseline set and compare-only proof
  - keyboard-accessible narrow DetailSurface scrolling with inline-mode tab-stop synchronization
  - final focused, package, asset, manifest, connected structure, zoom, and protected-boundary evidence
affects: [79, 80, 81, 82]
tech-stack:
  added: []
  patterns: [manifest-derived exact baseline scope, update-then-compare VRT, keyboard-scroll baseline with responsive tab-stop ownership, cumulative and worktree protected audits]
key-files:
  created:
    - test/browser/__screenshots__/chromium-320/showcase/group-*/
    - test/browser/__screenshots__/chromium-tablet/showcase/group-*/
    - test/browser/__screenshots__/chromium-wide/showcase/group-*/
  modified:
    - .planning/phases/78-component-groups-meta-components/78-VALIDATION.md
    - lib/oban_powertools/web/components/operator_patterns.ex
    - assets/oban_powertools/theme.js
    - priv/static/oban_powertools/oban_powertools.js
    - test/browser/specs/operator-patterns.behavior.spec.ts
    - test/browser/specs/showcase.vrt.spec.ts
    - test/oban_powertools/web/assets_test.exs
    - test/oban_powertools/web/components/operator_patterns_test.exs
key-decisions:
  - "Keep the detail body keyboard-scrollable in the server-rendered narrow baseline, then remove its tab stop whenever the connected controller places the surface inline."
  - "Derive and audit the visual set exclusively from schema-6 group targets; retain the unrelated 108 scenario PNGs without treating them as Phase 78 evidence."
  - "Give screenshot stability 15 seconds for large deterministic story crops while preserving Playwright's ordinary pixel-comparison semantics."
patterns-established:
  - "A new scroll owner must have a no-JavaScript keyboard baseline and a controller-owned responsive tab-stop policy."
  - "Canonical VRT completion requires manifest-derived exact-set verification, changed-scope verification, and a fresh compare-only run after updates."
requirements-completed: [GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02]
duration: 1h 27m
completed: 2026-07-18
status: complete
---

# Phase 78 Plan 08: Accessibility, Visual Baselines, and Final Gate Summary

**All 23 operator-group stories now have exact 276-case axe and canonical visual evidence, keyboard-accessible responsive detail scrolling, and a green final package/scope gate.**

## Performance

- **Duration:** 1h 27m
- **Started:** 2026-07-18T20:17:00-04:00
- **Completed:** 2026-07-18T21:44:00-04:00
- **Tasks:** 3
- **Files modified:** 284

## Accomplishments

- Passed the complete connected behavior suite with 37 passes and 20 intentional project gates, connected structure with 12 passes, and the exact five-story wide zoom gate with zero skips.
- Passed all 276 group axe cases with zero critical or serious violations after correcting narrow DetailSurface keyboard scrolling.
- Added exactly 276 group-only PNG baselines across 23 stories, four themes, and three viewports; exact-set and changed-scope verification passed, followed by a fresh 276-pass compare-only run.
- Passed format, warnings-as-errors compilation, 157 focused ExUnit contracts, schema-6/64-target manifest smoke, repeated asset-build equality, optional-catalog package fallback, and cumulative/worktree protected-boundary audits.
- Reconciled every Phase 78 task and RED-to-green seam in VALIDATION while preserving the 108 unrelated scenario baselines and Phase 82 manual/cross-page boundaries.

## Task Commits

Each task was committed atomically:

1. **Task 78-08-01: Execute connected behavior, exact zoom, structure, and group axe** - `b8ca6af` (fix)
2. **Task 78-08-02: Generate and verify the exact group visual baseline set** - `a915871` (test)
3. **Task 78-08-03: Run the final focused gate and reconcile Nyquist evidence** - `dfe4044` (docs)

**Plan summary:** committed separately after the three atomic task commits.

## Files Created/Modified

- `test/browser/__screenshots__/chromium-{320,tablet,wide}/showcase/group-*/*.png` - Exact 276-case group visual baseline matrix.
- `.planning/phases/78-component-groups-meta-components/78-VALIDATION.md` - Complete task/evidence map, final green gates, residual boundaries, and Nyquist sign-off.
- `lib/oban_powertools/web/components/operator_patterns.ex` - Server-rendered keyboard-access baseline for the DetailSurface scroll body.
- `assets/oban_powertools/theme.js` and `priv/static/oban_powertools/oban_powertools.js` - Responsive detail-body tab-stop synchronization with deterministic package equality.
- `test/browser/specs/operator-patterns.behavior.spec.ts` - Connected keyboard-scroll regression coverage.
- `test/browser/specs/showcase.vrt.spec.ts` - Explicit 15-second stability allowance for large deterministic story crops.
- `test/oban_powertools/web/assets_test.exs` and `test/oban_powertools/web/components/operator_patterns_test.exs` - Packaged-controller and server-baseline regressions.

## Decisions Made

- Used `tabindex="0"` as the safe server baseline because narrow drawer content must remain keyboard-scrollable without client execution; the controller removes it in inline mode to avoid an unnecessary wide-layout tab stop.
- Kept VRT recovery group-only and project-serial after initial new-crop timeouts, then required the complete parallel compare-only matrix to pass before accepting baselines.
- Treated manual screen-reader quality and representative aesthetic inspection as explicit unclaimed boundaries rather than inferring them from axe or pixel equality.

## Deviations from Plan

### Auto-fixed Issues

**1. Made the narrow DetailSurface scroll region keyboard accessible**
- **Found during:** Task 78-08-01 full group axe matrix
- **Issue:** Eight narrow DetailSurface cases reported serious `scrollable-region-focusable` violations across two stories and four themes.
- **Fix:** Added a server-rendered focusable scroll baseline and synchronized the body tab stop with effective drawer/inline mode in the packaged controller.
- **Files modified:** `lib/oban_powertools/web/components/operator_patterns.ex`, `assets/oban_powertools/theme.js`, `priv/static/oban_powertools/oban_powertools.js`, and focused tests.
- **Verification:** The affected 8-case axe slice passed, then the complete 276-case matrix passed with zero critical or serious violations.
- **Committed in:** `b8ca6af`

**2. Increased screenshot stability time for large deterministic story crops**
- **Found during:** Task 78-08-02 canonical baseline generation
- **Issue:** New tablet/wide long-content crops sometimes needed more than Playwright's default five seconds to produce two consecutive stable screenshots.
- **Fix:** Set the existing screenshot assertion timeout to 15 seconds without changing comparison thresholds or target scope.
- **Files modified:** `test/browser/specs/showcase.vrt.spec.ts`
- **Verification:** Serial recovery completed the exact set, both verifiers passed, and a fresh parallel compare-only run passed 276/276.
- **Committed in:** `a915871`

---

**Total deviations:** 2 auto-fixed correctness/stability issues.
**Impact on plan:** Both fixes were required to make the locked accessibility and visual contracts deterministic; no dependency, route, data, production-page, or authority scope expanded.

## Issues Encountered

- A stale exact test-server listener initially served old component code; only that identified listener was stopped, after which fresh connected runs used the current worktree.
- The first parallel new-baseline update timed out 39 large crops. Group-only tablet/wide serial recovery generated the missing files before the required complete compare-only pass.
- One early behavior run had a transient tablet LiveView connection miss; its exact case and then the complete suite passed on fresh reruns, and only the repeat green result is recorded.
- Docker dependency resolution continued to print the repository's existing advisory set and expired local Hex-auth warning. Public dependencies resolved; Phase 78 changed no dependency manifest or lockfile.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phases 79–81 can adopt the six group components with connected behavior, accessibility, visual, asset, package, and server-authority contracts already pinned.
- Phase 82 retains the broader cross-page manual screen-reader, representative visual, and zoom sweep; Phase 78 does not claim those manual checks.
- No protected production, dependency, schema, route, authorization, query, mutation, or audit-storage boundary is left modified outside the five planned component/showcase seams.

## Self-Check: PASSED

- All three task commits exist in order, all declared artifacts exist, and the plan-local cumulative diff contains 284 expected files.
- Format, warnings-as-errors compile, 157 focused ExUnit tests, manifest smoke, exact 276-baseline verification, 12 connected structure cases, five exact zoom cases, 276 axe cases, and 276 compare-only VRT cases pass.
- The immutable start SHA resolves; cumulative and final worktree/untracked protected audits are empty outside the five allowed production seams.
- Exactly 276 group PNGs exist; changed screenshot scope is group-only, the unrelated 108 scenario PNGs remain preserved, and manual-only boundaries remain unclaimed.

---
*Phase: 78-component-groups-meta-components*
*Completed: 2026-07-18*
