---
phase: 73-visual-regression-a11y-harness
plan: 05
subsystem: ci-docs
tags: [github-actions, playwright, axe, visual-regression, docs]

requires:
  - phase: 73-04
    provides: Story-level visual regression spec and committed Docker-generated baselines
provides:
  - Merge-blocking `visual_a11y` CI lane through `ci-gate`
  - Short-retention failure artifacts for Playwright, axe, and generated manifest output
  - Contributor documentation for normal runs, baseline updates, artifacts, and accessibility claim boundaries
affects: [phase-73, ci, docs, visual-regression, accessibility]

tech-stack:
  added: []
  patterns:
    - CI runs `npm run visual:a11y` in compare mode only and never updates snapshots
    - Baseline updates are documented as Docker-only, changed-only, and reviewable
    - Docs contracts assert the CI lane, artifact names, update command semantics, and narrow axe claim

key-files:
  created:
    - guides/visual-regression-and-a11y.md
  modified:
    - .github/workflows/ci.yml
    - README.md
    - mix.exs
    - test/oban_powertools/docs_contract_test.exs

key-decisions:
  - "Pinned `actions/setup-node` v4 to full SHA `49933ea5288caeca8642d1e84afbd3f7d6820020` after resolving it with `git ls-remote`."
  - "Reused the repository's existing pinned `actions/upload-artifact` v4 SHA and limited uploads to `playwright-report/`, `test-results/`, and `test/browser/.generated/showcase-manifest.json` with `retention-days: 7`."
  - "Documented the required baseline-update sentence exactly: `Update snapshots only when the visual change is intentional; explain the reason in the PR.`"
  - "Documented the required axe claim exactly: `Automated axe gate passed for critical and serious findings on the captured showcase targets.`"

patterns-established:
  - "`visual_a11y` mirrors the test lane's Postgres and setup path before running `npm ci` and `npm run visual:a11y`."
  - "`ci-gate` now fans in `VISUAL_A11Y` with the same result-loop pattern as the existing required checks."
  - "`guides/visual-regression-and-a11y.md` is linked from the README and grouped under the ExDoc Design System guide set."

requirements-completed: [VRT-02, VRT-03, A11Y-01]

duration: 34 min
completed: 2026-06-19
status: complete
---

# Phase 73 Plan 05: CI Guardrail and Documentation Summary

**The showcase visual and accessibility harness is now wired into the required CI gate, with contributor documentation and docs contracts preserving the review workflow.**

## Performance

- **Duration:** 34 min
- **Completed:** 2026-06-19
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `.github/workflows/ci.yml` job `visual_a11y` on `ubuntu-latest` with Postgres service parity, pinned Beam and Node setup actions, `npm ci`, and `npm run visual:a11y`.
- Added `visual_a11y` to `ci-gate.needs`, exposed `VISUAL_A11Y`, and included it in the existing result verification loop.
- Configured failure-only artifact upload for `playwright-report/`, `test-results/`, and `test/browser/.generated/showcase-manifest.json` with 7-day retention.
- Added `guides/visual-regression-and-a11y.md` documenting normal runs, Docker-only changed baseline updates, narrow update examples, artifact names, the 108 PNG baseline matrix, and axe claim boundaries.
- Linked the guide from the README, grouped it under the ExDoc Design System guide set, and added docs contract assertions for the CI and documentation semantics.

## Task Commits

1. **Task 1: Add `visual_a11y` CI lane and `ci-gate` fan-in** - `0c14c3a` (ci)
2. **Task 2: Document guardrail commands, artifacts, and claim boundaries** - `c927474` (docs)

## Files Created/Modified

- `.github/workflows/ci.yml` - `visual_a11y` job, artifact upload, and `ci-gate` fan-in.
- `guides/visual-regression-and-a11y.md` - Contributor guardrail workflow and claim-boundary guide.
- `README.md` - Guide index link.
- `mix.exs` - ExDoc Design System grouping for the new guide.
- `test/oban_powertools/docs_contract_test.exs` - Contract coverage for Phase 73 CI and docs semantics.

## Decisions Made

- Pinned `actions/setup-node` by full SHA rather than using a moving tag.
- Kept CI in compare mode only; no snapshot update command or flag appears in the workflow.
- Kept artifacts allowlisted instead of uploading the workspace or broad directories.
- Made moderate, minor, and incomplete axe results review artifacts rather than merge-blocking claims.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Non-blocking] Used Node verifier because local Ruby was unavailable**
- **Found during:** Task 1 verification
- **Issue:** The plan's inline Ruby workflow verifier could not run locally because no Ruby version was selected for the shell.
- **Fix:** Ran an equivalent Node-based workflow contract check after `actionlint`.
- **Files modified:** None.
- **Verification:** `actionlint .github/workflows/ci.yml` passed and the Node contract printed `ci workflow lint contract ok`.
- **Committed in:** N/A

---

**Total deviations:** 1 auto-fixed (0 blocking)
**Impact on plan:** No implementation change was needed; the CI workflow semantics were verified with an equivalent local checker.

## Issues Encountered

- `mix docs` completed but continued to print existing hidden/private reference warnings unrelated to Phase 73.

## User Setup Required

Docker must be available for local `npm run visual:a11y` and `npm run vrt:update` browser runs.

## Verification

- `actionlint .github/workflows/ci.yml` - PASS.
- Node CI workflow contract check - PASS, `ci workflow lint contract ok`.
- `mix test test/oban_powertools/docs_contract_test.exs` - PASS, 19 tests.
- `mix docs` - PASS, with existing hidden/private reference warnings.
- `npm run visual:a11y` - PASS, 228 tests.

## Next Phase Readiness

Phase 73 is complete and the final implementation can rely on CI, docs, and committed baselines to guard showcase visual and accessibility regressions.

## Self-Check: PASSED

- Found `visual_a11y`, `VISUAL_A11Y`, and `npm run visual:a11y` in `.github/workflows/ci.yml`.
- Found no snapshot update flag in CI.
- Found `guides/visual-regression-and-a11y.md` linked from `README.md` and grouped in `mix.exs`.
- Found docs contract assertions for artifact names, changed-only baseline updates, and the narrow axe claim.
- Found task commits `0c14c3a` and `c927474` in git history.

---
*Phase: 73-visual-regression-a11y-harness*
*Completed: 2026-06-19*
