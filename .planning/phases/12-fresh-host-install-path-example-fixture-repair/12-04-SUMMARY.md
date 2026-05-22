---
phase: 12-fresh-host-install-path-example-fixture-repair
plan: 04
subsystem: testing
tags: [docs, ci, exunit, phoenix, github-actions]
requires:
  - phase: 12-01
    provides: repaired fresh-host installer, seam generation, and install-to-boot proof
  - phase: 12-02
    provides: curated example fixture provenance and migration-complete host baseline
  - phase: 12-03
    provides: canonical first-session proof for ops-demo pausing nightly_sync
provides:
  - public docs aligned to the repaired day-0 host contract
  - docs contract assertions for install, first-session, and read-only bridge markers
  - CI workflow lanes aligned to the repaired fresh-host and native proof stack
affects: [README, guides, host-contract-proof, docs-contract]
tech-stack:
  added: []
  patterns: [docs-as-contract, explicit-proof-lanes, tdd-for-ci-guardrails]
key-files:
  created: [.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-04-SUMMARY.md]
  modified: [README.md, guides/installation.md, guides/first-operator-session.md, guides/example-app-walkthrough.md, guides/support-truth-and-ownership-boundaries.md, test/oban_powertools/docs_contract_test.exs, .github/workflows/host-contract-proof.yml]
key-decisions:
  - "Define day-0 success as compile plus migrate or reset plus one boot check before the first native operator mutation."
  - "Treat ops-demo pausing nightly_sync via pause_cron_entry as the canonical DOC-01 proof threshold in both docs and tests."
  - "Keep the workflow explicit with a dedicated fresh-host lane instead of folding fresh-host proof into structural checks."
patterns-established:
  - "Public docs must name the same canonical install and first-session markers that the docs contract test asserts."
  - "Workflow lane names are part of the public proof contract and should stay aligned with the underlying proof files."
requirements-completed: [PKG-01, DOC-01]
duration: 17min
completed: 2026-05-22
---

# Phase 12 Plan 04: Public Contract Alignment Summary

**Public docs, docs-contract assertions, and CI lanes now enforce the same fresh-host install, compile/migrate/boot threshold, and ops-demo nightly_sync first-session proof**

## Performance

- **Duration:** 17 min
- **Started:** 2026-05-22T16:24:30Z
- **Completed:** 2026-05-22T16:41:40Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Rewrote the README and day-0 guides around the repaired paved road: `mix phx.new`, add the dependency, run `mix oban_powertools.install`, fill the thin host-owned seams, compile, migrate or reset, boot once, then complete the first native mutation.
- Made the first successful operator session concrete as `ops-demo` executing `pause_cron_entry` on `nightly_sync`, with the optional `/ops/jobs/oban` bridge kept explicitly read-only.
- Tightened docs drift enforcement and split CI proof naming so the workflow now exposes a distinct `fresh-host` lane alongside `structural`, `docs-contract`, `native-only`, and `bridge-enabled`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite the public paved-road docs around the repaired install and first-session contract** - `4174a60` (docs)
2. **Task 2: Tighten docs contract enforcement and CI lanes around the repaired proof stack** - `64ec06c` (test, RED)
3. **Task 2: Tighten docs contract enforcement and CI lanes around the repaired proof stack** - `b8762c0` (feat, GREEN)

## Files Created/Modified
- `README.md` - Defines the repaired install order, host-owned seam posture, and compile/migrate/boot threshold.
- `guides/installation.md` - Pins the exact fresh-host setup sequence and bounded boot check.
- `guides/first-operator-session.md` - Defines the canonical `ops-demo` and `nightly_sync` native proof threshold.
- `guides/example-app-walkthrough.md` - Reframes `examples/phoenix_host` as a curated provenance-true fixture.
- `guides/support-truth-and-ownership-boundaries.md` - Restates the read-only `/ops/jobs/oban` bridge boundary.
- `test/oban_powertools/docs_contract_test.exs` - Enforces repaired install markers, first-session markers, and workflow lane names.
- `.github/workflows/host-contract-proof.yml` - Adds the dedicated `fresh-host` proof job and keeps the docs/example-host lanes explicit.

## Decisions Made
- Define the public day-0 threshold as compile plus migrate or reset plus one boot check before the first native operator mutation, because compile/reset/seed alone was not an honest DOC-01 proof.
- Keep the first-session truth narrow and canonical by naming `ops-demo`, `nightly_sync`, and `pause_cron_entry` directly in both docs and tests.
- Preserve the existing layered proof stack, but make the workflow names honest by separating `fresh-host` from the cheap structural installer checks.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 12 is ready to close with docs, tests, and CI all enforcing the same repaired host contract.
- The next host-contract phases can build on explicit docs and proof-lane naming instead of stale public prose.

## Self-Check

PASSED

- FOUND: `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-04-SUMMARY.md`
- FOUND: `4174a60`
- FOUND: `64ec06c`
- FOUND: `b8762c0`

---
*Phase: 12-fresh-host-install-path-example-fixture-repair*
*Completed: 2026-05-22*
