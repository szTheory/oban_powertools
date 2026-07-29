---
phase: 81-page-migration-wave-3-batches-workflows-lifeline
plan: 14
subsystem: validation
tags: [nyquist, playwright, exunit, accessibility, evidence-ledger]
requires:
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 13
    provides: exact VoiceOver discovery and merge-blocking page-quality structure
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 15
    provides: whole-nine-family browser contract reconciliation
provides:
  - fresh exact repository and compare-only page-quality evidence
  - closed Phase 81 Nyquist ledger with exact inventory and finite bounds
affects: [phase-81-verification, milestone-audit]
tech-stack:
  added: []
  patterns:
    - completion stays false until the exact unfiltered compare-only command passes
    - optional host-facing web dependencies establish compile ordering without forcing the bridge
key-files:
  created:
    - .planning/phases/81-page-migration-wave-3-batches-workflows-lifeline/81-14-SUMMARY.md
  modified:
    - .planning/phases/81-page-migration-wave-3-batches-workflows-lifeline/81-VALIDATION.md
    - test/browser/specs/page-migration-wave-1.spec.ts
    - lib/oban_powertools/web/lifeline_live.ex
    - lib/oban_powertools/web/batches_live.ex
    - mix.exs
key-decisions:
  - "Use CI=1 only to select Playwright's deterministic one-worker execution; keep the exact verify:pages script and all seven specifications unfiltered."
  - "Emit Lifeline aria-controls only while the referenced preview dialog exists."
  - "Declare Phoenix LiveView as an optional package dependency so native hosts compile direct component usage before the optional bridge."
requirements-completed:
  - PAGE-03
  - PAGE-04
  - PAGE-07
  - GROUP-01
  - GROUP-02
  - PAGE-10
  - A11Y-01
  - A11Y-02
  - A11Y-03
  - A11Y-04
  - MOTION-01
  - MOTION-02
duration: 3h 30m
completed: 2026-07-29
status: complete
---

# Phase 81 Plan 14: Final Nyquist Evidence Summary

**The repository gate is green at 950 ExUnit tests, the unfiltered browser
gate is green at 2,790 tests, and the exact Phase 81 inventory is locked at 99
page stories, 163 targets, 297 ARIA snapshots, and 1,188 PNGs.**

## Accomplishments

- Reran the corrected 89-test page quick suite, 50-test catalog suite, disabled
  and enabled fixture-host contracts, 16-case native and Docker Wave 3
  contracts, artifact validators, VoiceOver discovery, CI structure, format,
  compilation, and the full 950-test ExUnit suite.
- Reconciled the old Wave 1 browser guard with the exact schema-8 nine-family
  graph instead of leaving a stale 49-story assertion in the global gate.
- Closed a real Lifeline accessibility defect by removing `aria-controls` when
  the referenced preview dialog is absent; the focused 240-case Lifeline axe
  matrix passed afterward.
- Preserved exact focus restoration without invalid ARIA by tracking the
  pre-open Lifeline invoker through a non-ARIA `data-obpt-controls`
  relationship; the corrected case passed in all three browser projects.
- Closed full-suite package and host-contract regressions: optional Phoenix
  LiveView compile ordering, current control-plane copy, and concurrent-index
  migration locking.
- Replaced the draft validation strategy with a command-by-command evidence
  ledger containing the exact 150-ARIA/600-PNG Wave 3 delta and all twelve
  finite saturated cases.

## Task Commits

1. **Task 81-14-01: Repair and rerun final gates**
   - `872218e` — accept the nine-family page graph in the Wave 1 gate
   - `37365c1` — close the final format and ARIA gates
   - `fa1ef20` — close package and generated-host contract gates
   - `5618805` — restore Lifeline dialog focus without invalid ARIA
2. **Task 81-14-02: Close Nyquist status truthfully** — final documentation
   commit

## Deviations from Plan

The final gate found defects, so Plan 81-14 made bounded repairs before
recording evidence:

- The legacy Wave 1 specification still required 49 page stories. It now
  accepts the exact closed nine-family union and requires 99.
- Closed Lifeline triggers advertised a dialog ID that was not rendered. The
  ARIA relationship is now conditional on the real dialog.
- Native generated hosts could compile package components before Phoenix
  LiveView because no direct dependency edge existed. The dependency is now
  explicit and optional.
- Host smoke/copy assertions retained superseded copy, and the upgrade fixture
  used concurrent indexes while retaining the migration lock. Contracts now
  match production copy and the concurrent migration disables that lock.
- The first serial full browser run exposed missing focus restoration after the
  invalid `aria-controls` relationship was removed. A separate non-ARIA
  control/owner association now preserves the invoker for restoration, and a
  fresh full unfiltered rerun passed all 2,790 tests.

An initial local four-worker browser attempt exposed shared fixture HTTP 409
contention. It was not accepted as evidence. The final command uses `CI=1`,
which is the repository's real one-worker CI mode, without grep, snapshot
updates, retries, ignored failures, or any change to `npm run verify:pages`.

## Gate Evidence

- Corrected quick suite — 89 tests, 0 failures.
- Catalog/manifest suite — 50 tests, 0 failures.
- Fixture host disabled/enabled — 2/0 and 4/0.
- Native and Docker connected Wave 3 — 16/16 each.
- Generated manifest — schema 8, 99 page stories, 163 targets.
- Exact artifact validators — 297 page ARIA snapshots and 1,188 page PNGs.
- VoiceOver list — 10 tests, including exactly 3 Wave 3 representatives.
- `mix format --check-formatted` — passed.
- `mix compile --warnings-as-errors` — passed.
- `mix test --seed 0` — 950 tests, 0 failures in 373.5 seconds.
- `CI=1 npm run verify:pages` — 2,790 tests passed in 1.6 hours.

## Security and Evidence Integrity

- Completion flags were promoted only after every required command exited 0.
- No snapshot update/watch command, filtered subset, retry, or ignored failure
  is used as final evidence.
- Closed presenter, confidentiality, uniform-denial, reauthorization, finite
  bound, and truthful partial-result contracts all pass in the fresh full
  suite and connected browser coverage.
- Unrelated dirty worktree content remains unstaged and unchanged.

## User Setup Required

None.

## Next Phase Readiness

Phase verification may begin from the approved Nyquist ledger.

## Self-Check: PASSED

- All four repair commits exist.
- The validation ledger and this summary exist.
- Repository, inventory, connected, and artifact gates are green.
- The exact unfiltered full page-quality command passed 2,790 tests.

---
*Phase: 81-page-migration-wave-3-batches-workflows-lifeline*
*Completed: 2026-07-29*
