---
phase: 12-fresh-host-install-path-example-fixture-repair
plan: 03
subsystem: testing
tags: [phoenix, liveview, oban, ecto, fixture, host-contract]
requires:
  - phase: 12-01
    provides: fresh-host execution proof and root fixture-shell pattern
  - phase: 12-02
    provides: canonical fixture migrations and seeded ops-demo/nightly_sync data
provides:
  - fixture-local native first-session proof for cron pause audit flow
  - root host-contract helper for deterministic first_session fixture execution
  - CI-friendly contract coverage for ops-demo pausing nightly_sync with pause_cron_entry
affects: [DOC-01, examples/phoenix_host, host-contract-proof, phase-12]
tech-stack:
  added: []
  patterns: [fixture-local native proof lane, dedicated root first_session shell helper, TDD proof gating]
key-files:
  created:
    - examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs
    - .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-03-SUMMARY.md
  modified:
    - test/support/example_host_contract.ex
    - test/oban_powertools/example_host_contract_test.exs
key-decisions:
  - "Use the native `/ops/jobs/cron` LiveView as the sole first-session proof surface rather than broadening the phase into bridge parity or browser E2E."
  - "Keep the root contract deterministic by adding a dedicated `first_session!` helper that runs only the fixture proof file after copying the canonical example host."
patterns-established:
  - "First-session proof lanes should assert both durable preview consumption and persisted audit evidence for one concrete operator mutation."
  - "Root host-contract proofs should shell into the fixture with a dedicated helper per authoritative lane instead of folding native evidence into compile-only smoke checks."
requirements-completed: [DOC-01]
duration: 6min
completed: 2026-05-22
---

# Phase 12 Plan 03: Fresh Host Install Path Example Fixture Repair Summary

**Native cron first-session proof for ops-demo pausing nightly_sync with durable audit evidence, plus a root first_session harness lane that reruns it deterministically**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-22T14:10:00Z
- **Completed:** 2026-05-22T14:16:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added a fixture-local Phoenix LiveView proof that authenticates as `ops-demo`, previews and executes `pause_cron_entry` against `nightly_sync`, and asserts both consumed preview state and durable audit evidence.
- Extended the root example-host harness with a dedicated `first_session!` helper that shells into `examples/phoenix_host` and runs only the canonical proof file.
- Promoted the first-session lane into the root contract suite so CI now fails if the native audited mutation, seeded actor/resource, or audit trail disappears.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the fixture-local native first-session integration proof** - `d3934fa` (test), `af61f73` (feat)
2. **Task 2: Wire the root host-contract harness to run the first-session lane deterministically** - `4619ff4` (test), `6149fe0` (feat)

## Files Created/Modified

- `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` - Canonical native first-session proof for the cron pause flow and its durable audit evidence.
- `test/support/example_host_contract.ex` - Root fixture-shell helper with the dedicated `first_session!` lane.
- `test/oban_powertools/example_host_contract_test.exs` - Contract tests for the dedicated first-session proof alongside the older native-only, bridge-enabled, and upgrade lanes.

## Decisions Made

- Used the native cron LiveView as the authoritative first-session surface because the phase goal was one honest native mutation proof, not broader UI coverage.
- Kept the root contract lane narrow and explicit by running the single fixture test file rather than embedding first-session assertions inside compile/reset smoke outputs.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first Task 1 assertion assumed the seeded fixture source would render as `Code`; the actual UI contract renders non-`code` sources as `Runtime`, so the proof was updated to the existing supported vocabulary before final verification.
- The full root contract suite was slow to surface the new RED failure because the older proof lanes run first. A focused `--only first_session` run kept the TDD gate tight before the full suite verification.

## User Setup Required

None - no external service configuration required.

## Threat Flags

None.

## Next Phase Readiness

- Phase 12 now has a deterministic authoritative first-session proof chain from fixture-native interaction through root CI harness execution.
- The remaining docs and workflow updates in `12-04` can cite this lane as the `DOC-01` evidence authority.

## Self-Check: PASSED

- Verified `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-03-SUMMARY.md` exists.
- Verified task commits `d3934fa`, `af61f73`, `4619ff4`, and `6149fe0` exist in git history.

---
*Phase: 12-fresh-host-install-path-example-fixture-repair*
*Completed: 2026-05-22*
