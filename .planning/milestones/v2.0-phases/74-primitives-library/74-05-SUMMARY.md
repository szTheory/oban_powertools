---
phase: 74-primitives-library
plan: 05
subsystem: browser-verification
tags: [playwright, primitives, vrt, accessibility, motion]
requires:
  - phase: 74-primitives-library
    provides: 74-04 unified manifest targets for primitive stories
  - phase: 73-visual-regression-a11y-harness
    provides: Playwright structure, VRT, and axe harness for showcase targets
provides:
  - Targeted primitive browser behavior checks for focus, accessible names, tooltips, overflow, and reduced motion
  - Primitive VRT baselines across all existing showcase viewports and themes
  - Full visual/a11y gate evidence with primitive stories included
affects: [phase-74-primitives, phase-75-forms, phase-83-showcase-docs, visual-a11y]
tech-stack:
  added: []
  patterns:
    - Browser behavior checks consume generated manifest targets instead of local primitive id constants
    - Primitive-only button metrics stay scoped to `obpt-primitive-button`
    - VRT baselines are committed from the existing Docker snapshot update workflow
key-files:
  created:
    - test/browser/specs/primitives.behavior.spec.ts
    - test/browser/__screenshots__/chromium-*/showcase/primitive-*/*.png
  modified:
    - assets/oban_powertools/tokens.css
    - lib/oban_powertools/web/components/primitives.ex
    - priv/static/oban_powertools/oban_powertools.css
    - test/oban_powertools/web/components/primitives_test.exs
    - test/browser/__screenshots__/chromium-*/showcase/*/*.png
key-decisions:
  - "Primitive behavior coverage focuses on browser-observable claims axe cannot prove: accessible names, focus, tooltip dismissal, 320px overflow, and reduced motion."
  - "Button metric refinements are isolated behind `obpt-primitive-button` so existing showcase scenario controls keep their previous layout contract."
  - "Existing scenario baselines were refreshed because the populated primitives section changed story-level screenshot rasterization/scroll position, not scenario content."
patterns-established:
  - "Use generated primitive manifest metadata for targeted behavior checks."
  - "Keep primitive styling refinements scoped to primitive-specific classes when shared base classes are already used by showcase infrastructure."
requirements-completed: [COMP-03, COMP-04, MOTION-02, A11Y-02, SHOW-01]
duration: resumed
completed: 2026-07-11
status: complete
---

# Phase 74 Plan 05: Primitive Behavior And Visual Gate Summary

**Primitive stories now have targeted browser behavior checks, committed VRT baselines, and a green full visual/a11y gate.**

## Performance

- **Completed:** 2026-07-11
- **Tasks:** 2
- **Files modified:** 4 source/test files plus 180 screenshot baselines
- **Primitive baselines:** 84 PNGs for 7 primitive stories x 3 viewports x 4 themes

## Accomplishments

- Added `test/browser/specs/primitives.behavior.spec.ts` to verify icon-button accessible names, visible keyboard focus, tooltip focus/hover/Escape behavior, 320px overflow safety, and reduced-motion loading visibility.
- Isolated primitive button sizing and disabled-state styling behind `obpt-primitive-button`, preserving the shared `.obpt-button` layout used by existing showcase controls.
- Generated primitive VRT baselines for all primitive story targets across `chromium-320`, `chromium-tablet`, and `chromium-wide` in system, light, dark, and high-contrast themes.
- Refreshed existing scenario baselines after the populated primitives section changed story-level screenshot crop rasterization.
- Ran the full browser gate with structure, axe, VRT, and primitive behavior coverage included.

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | Add targeted primitive behavior checks | `6efd258` | test |
| 2a | Isolate primitive button metrics | `c442f03` | fix |
| 2b | Refresh showcase visual baselines | `5c426ff` | test |

## Files Created/Modified

- `test/browser/specs/primitives.behavior.spec.ts` - Targeted browser behavior coverage for primitive focus, accessible names, tooltips, overflow, and reduced motion.
- `assets/oban_powertools/tokens.css` - Adds transparent token and scopes primitive-only button metrics to `obpt-primitive-button`.
- `lib/oban_powertools/web/components/primitives.ex` - Adds `obpt-primitive-button` to primitive button output.
- `priv/static/oban_powertools/oban_powertools.css` - Rebuilt packaged stylesheet.
- `test/oban_powertools/web/components/primitives_test.exs` - Updates primitive button class assertion.
- `test/browser/__screenshots__/chromium-*/showcase/primitive-*/*.png` - Adds primitive visual baselines.
- `test/browser/__screenshots__/chromium-*/showcase/*/*.png` - Refreshes affected existing scenario crops.

## Decisions Made

- Kept behavior checks focused on the explicit Phase 74 automated proof boundary instead of duplicating axe assertions.
- Treated the initial full-gate VRT failures as a source/layout compatibility signal, then scoped primitive button metrics rather than accepting shared scenario drift.
- Committed the scenario PNG refresh separately from the source fix so reviewers can distinguish behavior changes from baseline churn.

## TDD Notes

- **Task 1 RED/GREEN:** Primitive behavior checks were added and verified against `chromium-320` and `chromium-wide` projects after manifest generation.
- **Task 2 GREEN:** Primitive VRT baselines were generated with the existing Docker update workflow and then verified by the full visual/a11y gate.
- **Regression fix:** Full VRT exposed existing scenario drift from shared `.obpt-button` metrics. Scoping those metrics to `obpt-primitive-button` restored compatibility before the final full-gate run.

## Deviations from Plan

- The plan targeted primitive PNG baselines only, but 96 existing scenario PNGs also required refresh. The populated primitives section inserted before catalog stories changed story-level screenshot crop rasterization/scroll position. Scenario source content was not changed; the refresh was verified with the full `npm run visual:a11y` gate.

## Issues Encountered

- `npm run visual:a11y` initially failed on existing scenario snapshots after primitive baselines were generated. Investigation showed the shared `.obpt-button` metric changes affected showcase controls outside primitive stories. The fix isolated primitive metrics and reran the full gate successfully.

## Known Stubs

None.

## Threat Flags

None. This plan added browser tests and static VRT baselines only; it introduced no production route, auth path, external network dependency, package install, or trust-boundary expansion.

Accessibility proof boundary: Phase 74 proves primitive-level automated checks only, covering generated structure targets, axe scans, VRT baselines, and targeted primitive browser behavior. Full manual screen-reader and page traversal verification remains owned by Phase 82.

## User Setup Required

None.

## Verification

- `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/primitives.behavior.spec.ts --project chromium-320` - PASSED during Task 1 checkpoint.
- `npm run showcase:manifest && scripts/with-showcase-server.sh npm run visual:a11y:host -- test/browser/specs/primitives.behavior.spec.ts --project chromium-wide --grep primitive` - PASSED during Task 1 checkpoint.
- `mix test test/oban_powertools/web/components/primitives_test.exs test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs` - PASSED; 25 tests, 0 failures.
- `npm run vrt:update -- --grep primitive` - PASSED; 84 primitive VRT targets.
- `npm run vrt:update` - PASSED; 192 VRT targets.
- `npm run visual:a11y` - PASSED; 420 browser tests.
- `mix test --exclude host_contract && mix compile --warnings-as-errors` - PASSED; 637 tests, 0 failures, 7 excluded, compile clean.

## Orchestrator Coordination

The plan implementation is complete. The central executor should mark `74-05` complete in `.planning/ROADMAP.md`/`.planning/STATE.md` and run phase closeout gates.

## Self-Check: PASSED

- Found `test/browser/specs/primitives.behavior.spec.ts`.
- Found primitive screenshot baselines under `test/browser/__screenshots__/chromium-*/showcase/primitive-*/*.png`.
- Found source fix in `assets/oban_powertools/tokens.css`.
- Found rebuilt packaged CSS in `priv/static/oban_powertools/oban_powertools.css`.
- Confirmed task commits `6efd258`, `c442f03`, and `5c426ff` in git history.
- Confirmed no generated report artifacts were staged.

## Next Phase Readiness

Ready for Phase 75 and downstream consumers to reuse the primitive layer with browser behavior, VRT, and axe coverage already wired into the showcase gate.

---
*Phase: 74-primitives-library*
*Completed: 2026-07-11*
