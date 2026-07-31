---
phase: 75-form-components
plan: 05
subsystem: ui
tags: [playwright, forms, keyboard, accessibility, visual-regression]
requires:
  - phase: 75-04
    provides: Generated nine-story form target contract and unified browser harness
provides:
  - Generated-metadata-backed browser proof for native form semantics and behavior
  - Reviewed 108-image form baseline matrix across four themes and three viewports
  - Nyquist execution evidence for Phase 75 form components
affects: [phase-82, visual-regression, accessibility, form-components]
tech-stack:
  added: []
  patterns: [native browser interaction proof, catalog-derived test targeting, scoped baseline ownership]
key-files:
  created: [test/browser/specs/forms.behavior.spec.ts]
  modified: [.planning/phases/75-form-components/75-VALIDATION.md]
key-decisions:
  - "D-25: Browser evidence uses native clicks and keyboard input to prove associations, choice behavior, state honesty, focus, reduced motion, and 320px reflow."
  - "Only the nine Phase 75 form baseline families are owned by this plan; unrelated scenario baseline drift remains an external visual-gate issue."
patterns-established:
  - "Behavior specs resolve stories through generated formStories metadata rather than local id inventories."
  - "Baseline closeout verifies exact directory and PNG cardinality before commit."
requirements-completed: [FORM-01, FORM-02, COMP-01, COMP-02, COMP-03, COMP-04, A11Y-02]
duration: 35 min
completed: 2026-07-11
status: complete
---

# Phase 75 Plan 05: Form Browser Proof and Baselines Summary

**Native form semantics and behavior are browser-proven, with 108 reviewed form baselines committed across the complete theme and viewport matrix.**

## Performance

- **Duration:** 35 min
- **Completed:** 2026-07-11
- **Tasks:** 2
- **Files modified:** 110

## Accomplishments

- Added 13 generated-metadata-backed Playwright behavior tests covering label identity and activation, description/error ordering, truthful invalid state, hidden boolean values, native checkbox/switch/radio keyboard behavior, disabled/read-only distinction, native filter semantics, focus visibility in four themes, pending ownership, reduced motion, and 320px overflow.
- Generated and reviewed exactly nine form story directories per Chromium viewport with four theme PNGs per story: 108 committed baselines with no masks or report artifacts.
- Closed the Phase 75 fast gate at 19/19 ExUnit tests, targeted browser gates at 13/13 for both chromium-320 and chromium-wide, the scoped Docker form VRT update at 108/108, the non-host-contract suite at 658/658, and warnings-as-errors compilation.

## Task Commits

1. **Task 1: Prove form semantics and behavior beyond axe** - `321e20a`
2. **Task 2: Generate form baselines and record validation evidence** - `e640a55`

## Files Created/Modified

- `test/browser/specs/forms.behavior.spec.ts` - Native interaction and semantic browser contract derived from generated form metadata.
- `test/browser/__screenshots__/chromium-*/showcase/form-*/*.png` - 108 reviewed form visual regression contracts.
- `.planning/phases/75-form-components/75-VALIDATION.md` - Execution evidence and scoped aggregate-gate status.

## Decisions Made

- Kept page traversal, manual screen-reader quality, dialogs, URL filter ownership, destructive flows, schemas, and real combobox behavior outside this component-scoped phase.
- Preserved the plan's narrow baseline ownership and did not replace 96 unrelated scenario PNGs merely to make the aggregate gate green.

## Deviations from Plan

**[Rule 1 - External verification issue] Aggregate scenario VRT baseline drift** — Found during: Task 2 | The exact `npm run visual:a11y` aggregate run passed every Phase 75 form behavior, axe, and VRT case but failed 96 pre-existing scenario screenshots, finishing 579/675. Failure artifacts showed scenario-only baseline drift/partially rendered text; no form target failed. | Fix: preserved failure evidence and scope, did not overwrite unrelated scenario baselines, and separately completed the remaining exact Mix gates. | Files modified: `.planning/phases/75-form-components/75-VALIDATION.md` | Verification: scoped form Docker update 108/108; targeted behavior 13/13 per required viewport; form axe/VRT cases green in aggregate | Commit: `e640a55`

**Total deviations:** 1 external verification issue documented; 0 source or form baseline defects. **Impact:** Phase 75 form evidence is complete and green, while the repository-wide visual gate retains a known scenario-only baseline issue outside this plan's ownership.

## Issues Encountered

- The aggregate browser run completed 579/675 because 96 existing scenario VRT baselines differ; all new form targets and primitive targets passed. Per explicit closeout direction and the plan's `--grep form` ownership boundary, those scenario PNGs were not updated.
- Hex dependency resolution printed existing security advisories and an expired optional Hex authentication warning. No dependency fetch required credentials and this plan introduced no dependencies.

## Verification

- `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/forms.behavior.spec.ts --project chromium-320` — 13 passed.
- `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/forms.behavior.spec.ts --project chromium-wide` — 13 passed.
- `npm run vrt:update -- --grep form` — 108 passed.
- Baseline cardinality — 9 form directories per viewport, 4 PNGs per directory, 108 total.
- `mix test test/oban_powertools/web/components/forms_test.exs test/oban_powertools/form_story_catalog_test.exs` — 19 passed.
- `mix test --exclude host_contract` — 658 passed, 7 excluded.
- `mix compile --warnings-as-errors` — passed.
- `npm run visual:a11y` — 579/675 passed; 96 known external scenario-only VRT failures, with all Phase 75 form cases green.
- `git status --short test/browser/.generated playwright-report test-results` — no generated or report artifacts selected for commit.

## Self-Check: PASSED

## User Setup Required

None.

## Next Phase Readiness

Phase 75 form-component work is complete. The existing scenario VRT baseline drift should be reconciled by the owning visual-regression phase before treating the aggregate `visual:a11y` command as globally green; Phase 82 retains manual screen-reader and page-level accessibility work.

---
*Phase: 75-form-components*
*Completed: 2026-07-11*
