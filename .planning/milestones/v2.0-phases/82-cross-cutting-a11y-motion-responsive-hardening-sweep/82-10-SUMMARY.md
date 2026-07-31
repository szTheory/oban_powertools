---
phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
plan: "10"
subsystem: testing
tags: [playwright, accessibility, ci, mutation-testing, voiceover]

requires:
  - phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
    provides: "Sole Phase 82 Node policy owner, exhaustive showcase/page coverage, and exact connected production sweep from Plans 03, 08, and 09"
provides:
  - "Manifest-first package graph with exact ordered Phase 82 validators and browser suites"
  - "Mutation-tested zero-retry VoiceOver and browser evidence ownership"
  - "Direct merge-blocking page_quality and full visual_a11y CI lanes with bounded failure artifacts"
affects: [82-11, milestone-quality, release-proof, ci-gate]

tech-stack:
  added: []
  patterns:
    - "Required browser evidence is an exact ordered package graph validated by source mutations"
    - "Both focused page quality and full unfiltered showcase quality remain direct ci-gate dependencies"

key-files:
  created:
    - voiceover.config.ts
  modified:
    - package.json
    - test/browser/support/verify-page-script-order.mjs
    - .github/workflows/ci.yml

key-decisions:
  - "Run the Plan 82-03 CLI once in the manifest-first validator prefix and persist only its bounded JSON report for CI failure evidence."
  - "Keep PAGE_QUALITY_ONLY exact for the ordered page lane while retaining the separate full unfiltered visual_a11y lane."
  - "Make the canonical VoiceOver config the sole retry owner with explicit numeric retries zero and forbid command-line overrides."

patterns-established:
  - "Graph mutations must first change their fixture and then fail for omission, reorder, duplication, filtering, unsafe evidence mode, detachment, ignored failure, retry drift, or missing gate ownership."

requirements-completed:
  - A11Y-01
  - A11Y-04
  - MOTION-01
  - MOTION-02
  - NAV-02
  - DATA-03
  - COPY-01
  - COPY-02

coverage:
  - id: D1
    description: "Manifest-first validators and all required browser specs execute once in canonical order."
    requirement: A11Y-01
    verification:
      - kind: integration
        ref: "node test/browser/support/verify-page-script-order.mjs"
        status: pass
      - kind: automated_ui
        ref: "npx playwright test test/browser/specs/system-quality.spec.ts --list (27 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "page_quality and full visual_a11y are direct required CI lanes with bounded Phase 82 failure evidence."
    requirement: A11Y-01
    verification:
      - kind: integration
        ref: "node test/browser/support/verify-page-script-order.mjs"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/ci.yml"
        status: pass
    human_judgment: false
  - id: D3
    description: "VoiceOver evidence resolves through the canonical config with explicit numeric zero retries."
    requirement: A11Y-04
    verification:
      - kind: automated_ui
        ref: "npx playwright test --config=voiceover.config.ts --list (10 tests)"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-29
status: complete
---

# Phase 82 Plan 10: Merge-Blocking Quality Graph Summary

**The complete Phase 82 validator and browser graph is now exact, mutation-tested, zero-retry, and directly merge-blocking through both page and full-showcase CI lanes**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-29T22:47:35Z
- **Completed:** 2026-07-29T22:52:05Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Wired the unchanged Plan 82-03 policy CLI into a manifest-first package prefix that emits a bounded report, validates exact PNG/ARIA sets, and then runs the canonical Wave 1 → Wave 2 → Phase 81 fixture → Wave 3 → contract/connected sweep → page acceptance → exhaustive axe/mechanical → compare-only VRT order.
- Expanded the structural validator and mutation fixtures to reject omission, reorder, duplication, filtering, update/watch/UI mode, retries, detached execution, ignored failure, missing bounded artifacts, and missing direct CI edges.
- Made VoiceOver retries explicit numeric zero while preserving exactly ten real-screen-reader discovery targets.
- Kept both `page_quality` and full unfiltered `visual_a11y` directly required by `ci-gate`, with the schema-8 manifest, bounded Phase 82 report, and Playwright results uploaded on page-lane failure.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing quality graph mutations** - `9d7ad5a` (test)
2. **Task 1 GREEN: Wire strict page quality graph** - `64665de` (feat)
3. **Task 2 RED: Require direct bounded CI evidence** - `b9f689e` (test)
4. **Task 2 GREEN: Require both quality lanes** - `68ada14` (ci)

## Files Created/Modified

- `package.json` - Defines the exact manifest-first validator prefix and canonical ordered host/Docker browser graph.
- `voiceover.config.ts` - Owns real-VoiceOver discovery and execution with explicit numeric zero retries.
- `test/browser/support/verify-page-script-order.mjs` - Mutation-tests package, VoiceOver, CI job, artifact, and direct gate ownership.
- `.github/workflows/ci.yml` - Keeps page and full-showcase quality directly merge-blocking and uploads bounded failure evidence.

## Decisions Made

- The sole Phase 82 owner remains `verify-phase82-quality.mjs`; this plan invokes it unchanged and stores only its compact count report.
- `PAGE_QUALITY_ONLY=1` remains exact on the ordered page lane. The separate `visual_a11y` job stays full and unfiltered, so focused page execution cannot replace exhaustive showcase evidence.
- Retry safety is config-owned for VoiceOver (`retries: 0`) and command overrides are forbidden by mutation tests.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first detached-process mutation exposed an end-of-string boundary bug in the new regular expression. The validator was corrected before GREEN verification so a single trailing `&` now fails while `&&` command ordering remains legal.
- The initial pinned-artifact lookup relied on a parsed `uses` field that did not retain the inline action-version comment. Matching the parsed step source preserved exact pin validation and allowed the intended missing-report RED failure.

## User Setup Required

None - no external service configuration required.

## Verification Evidence

- `npm run showcase:manifest` — pass; schema 8, 163 generated targets, 99 page stories.
- `node --test test/browser/support/verify-phase82-quality.test.mjs` — 39/39 mutations passed.
- `node test/browser/support/verify-phase82-quality.mjs` — schema 8; 163 targets; 99 pages; nine routes; three roots; 31 files; 18 declarations; zero exceptions.
- `node test/browser/support/verify-page-script-order.mjs` — exact package, VoiceOver, artifact, CI ownership, and bypass mutations passed.
- `actionlint .github/workflows/ci.yml` — pass.
- `npx playwright test test/browser/specs/system-quality.spec.ts --list` — exactly 27 tests in one file.
- `npx playwright test --config=voiceover.config.ts --list` — exactly ten tests in one file.
- `git diff --check` — pass across the preserved dirty worktree.
- `git status --short test/browser/__aria_snapshots__` — clean; no ARIA snapshot was regenerated or modified.

## Next Phase Readiness

- Plan 82-11 can run the fresh full repository/visual closure against an exact merge-blocking graph and consume the canonical zero-retry VoiceOver config.
- Schema 8, 163 targets, 99 page stories, and the reviewed 297-file ARIA set remain unchanged.

## Self-Check: PASSED

- All four production/test commits exist and contain only Plan 82-10 paths and scoped package/CI hunks.
- All task and plan verification commands pass with exact 27-case connected and ten-case VoiceOver discovery.
- Both CI lanes are direct `ci-gate` dependencies, and the bounded report path is required by mutation.
- No retry, filter, ignored failure, detached process, update mode, or ARIA regeneration was introduced.

---
*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Completed: 2026-07-29*
