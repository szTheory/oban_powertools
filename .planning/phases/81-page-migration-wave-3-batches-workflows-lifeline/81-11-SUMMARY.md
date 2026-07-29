---
phase: 81-page-migration-wave-3-batches-workflows-lifeline
plan: 11
subsystem: browser-artifacts
tags: [playwright, aria, visual-regression, docker, workflows]
requires:
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 08
    provides: connected Wave 3 production-route acceptance
provides:
  - 36 exact Workflows ARIA snapshots across three Chromium projects
  - 144 exact Workflows PNG baselines across four themes and three Chromium projects
  - semantically distinct deterministic Workflows fixtures for DAG, blocked, recovery, refusal, and unavailable states
affects: [81-12, 81-14, page-quality]
tech-stack:
  added: []
  patterns:
    - manifest-derived family filters with update followed by fresh compare-only authority
    - named showcase stories must render distinct semantic evidence before baseline acceptance
key-files:
  created:
    - test/browser/__aria_snapshots__/chromium-*/page-workflows-*-aria.yml
    - test/browser/__screenshots__/chromium-*/showcase/page-workflows-*/*.png
  modified:
    - test/support/page_story_catalog.ex
    - test/oban_powertools/page_story_catalog_test.exs
    - test/oban_powertools/web/live/showcase_live_test.exs
key-decisions:
  - "Reject structurally valid but semantically duplicate story baselines; named Workflows states must prove their claimed DAG and recovery truth."
  - "Defer the whole-nine-family global validator pass to Plan 81-14 after Plan 81-12 creates the required Lifeline family."
requirements-completed:
  - PAGE-04
  - GROUP-01
  - GROUP-02
  - PAGE-10
  - A11Y-01
  - A11Y-02
  - A11Y-03
  - A11Y-04
  - MOTION-01
  - MOTION-02
duration: 52min
completed: 2026-07-29
status: complete
---

# Phase 81 Plan 11: Workflows Artifact Family Summary

**The bounded Workflows family now has 36 reviewed ARIA trees and 144 reviewed visual baselines backed by semantically distinct fixtures and fresh Docker compare-only proof.**

## Performance

- **Duration:** 52min
- **Started:** 2026-07-29T09:45:00Z
- **Completed:** 2026-07-29T10:37:00Z
- **Tasks:** 2
- **Files modified:** 183

## Accomplishments

- Generated the exact manifest-derived 12-story Workflows matrix across three ARIA projects and four themes by three viewport projects.
- Replaced duplicate list-only detail fixtures with deterministic DAG, selected blocked step, dependency, callback recovery, refusal, adversarial, and unavailable evidence.
- Reviewed all 36 ARIA files semantically and representative PNGs across viewport, theme, blocked, refusal, and adversarial states; verified headings, roles, blocker explanations, escaping, contrast, wrapping, and clipping.
- Proved update-mode residue is absent with fresh Docker compare-only runs: 36/36 ARIA and 144/144 VRT tests passed.

## Task Commits

1. **Task 81-11-01: Correct Workflows story truth and generate scoped artifacts** — `c753e65`
2. **Task 81-11-02: Review and accept Workflows ARIA and PNG baselines** — `a3e13f9`

## Files Created/Modified

- `test/browser/__aria_snapshots__/chromium-*/page-workflows-*-aria.yml` — 36 exact Workflows accessibility trees.
- `test/browser/__screenshots__/chromium-*/showcase/page-workflows-*/*.png` — 144 exact Workflows visual baselines.
- `test/support/page_story_catalog.ex` — deterministic, semantically distinct Workflows detail fixtures and bounded selections.
- `test/oban_powertools/page_story_catalog_test.exs` — catalog assertions for the named Workflows evidence.
- `test/oban_powertools/web/live/showcase_live_test.exs` — route activation assertions for Workflows detail states.

## Decisions Made

- Baseline cardinality alone is insufficient: named showcase stories must render distinct evidence that proves the UI-SPEC truth they claim.
- Family compare-only runs are Plan 11's acceptance authority. The whole-nine-family validators remain intentionally red only for the not-yet-generated Lifeline family and are mandatory again in Plan 81-14.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1/2 - Bug/Missing critical behavior] Corrected semantically duplicate Workflows fixtures**

- **Found during:** Task 81-11-02 artifact review
- **Issue:** Ten of twelve initial ARIA story trees were effectively identical list-only views because every Workflows fixture supplied `workflow: nil`, `steps: []`, and `selected_step: nil`. The named blocked DAG, selected step, dependency, callback recovery, and refusal stories did not prove their declared truth.
- **Fix:** Added deterministic plain-map detail fixtures with semantic steps, dependency reasons, callback recovery posture, refusal handoff, unavailable/list-only states, and adversarial values; added focused catalog and LiveView assertions.
- **Files modified:** `test/support/page_story_catalog.ex`, `test/oban_powertools/page_story_catalog_test.exs`, `test/oban_powertools/web/live/showcase_live_test.exs`.
- **Verification:** Focused catalog/showcase suites passed 50 tests; regenerated artifacts expose `Workflow steps` in all 24 detail trees and `Why blocked?` in all 12 blocked/refusal trees.
- **Committed in:** `c753e65`.

**2. [Rule 3 - Blocking] Used the exact family token instead of an impossible title anchor**

- **Found during:** Task 81-11-01
- **Issue:** `--grep "^page-workflows-"` matched zero tests because Playwright prepends the describe title to the full test title.
- **Fix:** Used the equivalent exact family token `--grep "page-workflows-"` for ARIA and `--grep "page page-workflows-"` for VRT.
- **Files modified:** None.
- **Verification:** Update and fresh compare-only Docker matrices selected and passed exactly 36 ARIA and 144 VRT tests.

**3. [Rule 3 - Plan ordering] Deferred global validators until the Lifeline family exists**

- **Found during:** Task 81-11-02
- **Issue:** The global validators require 297 ARIA and 1,188 PNG files, but Plan 11 runs before Plan 12. They report only the future Lifeline family missing: 60 ARIA and 240 PNG, with no extras.
- **Fix:** Preserved the exact failure evidence and routed the mandatory whole-matrix pass to Plan 81-14.
- **Files modified:** None.
- **Verification:** Workflows counts are exactly 36/144; both fresh family compare-only runs are green; global set differences contain only `page-lifeline-*`.

---

**Total deviations:** 3 auto-handled (1 semantic fixture correction, 1 title-filter correction, 1 planned ordering dependency)
**Impact on plan:** The Workflows family goal is complete; only the intentionally future-dependent global aggregation check is deferred.

## Issues Encountered

- A local contact-sheet command placed its output before appended inputs and overwrote twelve `unavailable-restricted` PNG inputs. The review caught the dimension mismatch before acceptance; all twelve were regenerated with the exact story filter, re-staged, dimension-checked, and included in the successful 144-test fresh compare-only run.
- Docker dependency setup reports pre-existing advisory output for the example host dependency graph. It did not alter artifact results and is outside this plan's artifact-only scope.

## User Setup Required

None.

## Next Phase Readiness

- Plan 81-12 can generate the disjoint Lifeline artifact family.
- Plan 81-14 must rerun both global validators after all 297 ARIA and 1,188 PNG files are tracked.
- No Workflows-family blocker remains.

## Self-Check: PASSED

- Commits `c753e65` and `a3e13f9` exist.
- Exactly 36 Workflows ARIA files and 144 Workflows PNG files exist and are tracked.
- Focused Elixir results are 50/50; fresh Docker compare-only results are 36/36 ARIA and 144/144 VRT.
- The Workflows artifact family has no working-tree residue after compare-only validation.

---
*Phase: 81-page-migration-wave-3-batches-workflows-lifeline*
*Completed: 2026-07-29*
