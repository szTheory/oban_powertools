---
phase: 81-page-migration-wave-3-batches-workflows-lifeline
plan: 13
subsystem: ci-accessibility
tags: [voiceover, guidepup, playwright, github-actions, yaml-validation]
requires:
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 09
    provides: reviewed Batches accessibility and visual artifacts
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 11
    provides: reviewed Workflows accessibility and visual artifacts
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 12
    provides: reviewed Lifeline accessibility and visual artifacts
provides:
  - three exact manifest-derived Wave 3 VoiceOver discovery targets
  - executable structural enforcement of the unfiltered merge-blocking page-quality lane
  - mutation evidence for filtered, duplicated, moved, optional, or detached CI gates
affects: [81-14, page-quality, voiceover, ci-gate]
tech-stack:
  added: []
  patterns:
    - manifest IDs resolve exactly once before screen-reader tests are registered
    - CI policy validators parse job, step, and dependency structure and self-test against mutations
key-files:
  created: []
  modified:
    - test/browser/voiceover/page.voiceover.spec.ts
    - test/browser/support/verify-page-script-order.mjs
    - .github/workflows/ci.yml
key-decisions:
  - "Use the bulk-confirmation, selected-blocked-step, and partial-skipped-failed stories as the three exact Wave 3 VoiceOver representatives."
  - "Treat the existing uncommitted CI workflow as user-owned while validating its exact page_quality and ci-gate structure without restaging it."
requirements-completed:
  - PAGE-03
  - PAGE-04
  - PAGE-07
  - PAGE-10
  - A11Y-01
  - A11Y-02
  - A11Y-03
  - A11Y-04
duration: 8min
completed: 2026-07-29
status: complete
---

# Phase 81 Plan 13: VoiceOver Discovery and Required CI Summary

**Ten exact manifest-backed VoiceOver tests now include the three Wave 3 representatives, while a mutation-tested structural validator makes the complete page-quality command a direct seven-lane merge-gate dependency.**

## Performance

- **Duration:** 8min
- **Started:** 2026-07-29T11:14:00Z
- **Completed:** 2026-07-29T11:22:04Z
- **Tasks:** 2
- **Files modified:** 2 plan-attributable files; 1 pre-existing workflow validated

## Accomplishments

- Registered exactly `page-batches-bulk-confirmation`, `page-workflows-selected-blocked-step`, and `page-lifeline-partial-skipped-failed`, with fail-closed missing-or-duplicate manifest resolution.
- Preserved conditional Guidepup transcript capture and added truthful story-specific announcement requirements without fabricating runtime transcripts.
- Added a dependency-free structural CI parser that proves the exact `npm run verify:pages` step belongs to `jobs.page_quality`, cannot ignore failure, and is directly required by the canonical seven-job `ci-gate.needs` list.
- Added seven mutation fixtures proving the validator rejects duplicate, filtered, moved, optional, detached, duplicated-dependency, and wrong-cardinality contracts.

## Task Commits

1. **Task 81-13-01: Register exact VoiceOver discovery targets** — `f1ca10f`
2. **Task 81-13-02: Require the full page-quality graph in CI** — `cc30ef0`

## Files Created/Modified

- `test/browser/voiceover/page.voiceover.spec.ts` — adds the three exact Wave 3 representatives and unique manifest resolution.
- `test/browser/support/verify-page-script-order.mjs` — parses CI job/step/dependency structure and executes mutation assertions.
- `.github/workflows/ci.yml` — already contained the exact unfiltered `page_quality` step and seven-lane gate as pre-existing dirty work; validated in place and intentionally not staged by this plan.

## Decisions Made

- Chose the named confirmation, blocked-step detail, and mixed Lifeline result stories because their committed ARIA trees expose the consequence, blocker, preview, skipped, and failed evidence required for representative screen-reader traversal.
- Kept CI parsing local and dependency-free so the validator runs under the repository's existing Node toolchain without adding a package solely for one bounded workflow contract.
- Preserved the existing `.github/workflows/ci.yml` diff as user-owned and committed only this plan's attributable validator and VoiceOver changes.

## Deviations from Plan

None — the requested CI structure was already present in the shared dirty worktree, so the task added its executable validator without rewriting or committing pre-existing workflow hunks.

## Issues Encountered

- Real VoiceOver traversal was not run because it requires a supported, configured macOS Guidepup host. Exact discovery was run and passed; no transcript artifact was invented.

## Verification

- `npm run showcase:manifest && npx playwright test --config=voiceover.config.ts --list` — 10 tests listed, including exactly the three Wave 3 IDs.
- `node test/browser/support/verify-page-script-order.mjs` — passed the live workflow and all seven expected-failure mutation fixtures.
- `actionlint .github/workflows/ci.yml` — passed with no output.
- `git diff --check` for plan-owned files and the workflow — passed.

## User Setup Required

None.

## Next Phase Readiness

- Plan 81-14 can run the final whole-phase validators against exact screen-reader discovery and an executable merge-gate contract.
- Real advisory VoiceOver transcript capture remains correctly conditional on the supported macOS Guidepup lane.

## Self-Check: PASSED

- Commits `f1ca10f` and `cc30ef0` exist.
- Both plan-attributable modified files exist and are tracked.
- The exact CI validator and VoiceOver list checks pass.
- The pre-existing `.github/workflows/ci.yml` working-tree change remains unstaged and preserved.

---
*Phase: 81-page-migration-wave-3-batches-workflows-lifeline*
*Completed: 2026-07-29*
