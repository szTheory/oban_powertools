---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 04
subsystem: jobs
tags: [phoenix-liveview, lifeline, supervision, bulk-actions, audit, accessibility]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 03
    provides: Canonical Jobs detail, shared Lifeline confirmation, and finite recovery states
provides:
  - Validated 100-default/1000-max Jobs bulk target configuration and named Task Supervisor
  - Frozen explicit/all-matching scope with real per-target Lifeline preview and bounded supervised execution
  - Exact Jobs bulk confirmation, progress, receipt, partial-result, and fresh-preview recovery truth
affects: [80-05, jobs, lifeline, audit, forensics]

tech-stack:
  added: []
  patterns:
    - All-matching membership is frozen once through a limit-plus-one ordered ID window
    - Preview capabilities remain in a nonlinked supervised coordinator and never enter rendered assigns
    - Accepted target work is independent, max-four, timeout-bounded, stably ordered, and individually audited

key-files:
  created:
    - lib/oban_powertools/jobs/batch_coordinator.ex
    - test/oban_powertools/jobs/batch_coordinator_test.exs
  modified:
    - lib/oban_powertools/application.ex
    - lib/oban_powertools/runtime_config.ex
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools/application_test.exs
    - test/oban_powertools/auth_test.exs
    - test/oban_powertools/web/live/jobs_live_test.exs

key-decisions:
  - "The application validates :jobs_bulk_target_limit before starting children; 100 is the default and only integers from 1 through 1000 are accepted."
  - "A server-owned Scope contains only frozen ordered unique IDs, deterministic filter identity, exact count, mode, and observation time; filters are never rerun during preview or execution."
  - "Each target receives independent authorization plus real Lifeline preview and execution, while tokens, hashes, reasons, IDs, and internal failures remain outside aggregate messages and telemetry."
  - "Only exact all-success closes the dialog; any excluded, skipped, failed, drifted, or interrupted target remains selected and requires a fresh authoritative preview."

patterns-established:
  - "Bounded bulk authority: configuration, limit-plus-one membership, maximum concurrency four, 30-second target timeout, 50-row result pages, and 1,000 safe retained outcomes."
  - "Disconnect-safe acceptance: preview/execution coordinators are nonlinked children of ObanPowertools.Jobs.TaskSupervisor, so LiveView ownership does not define accepted-work lifetime."
  - "Durable recovery boundary: aggregate socket state is explicitly ephemeral while individual Lifeline Audit rows remain the recovery authority."

requirements-completed: ["PAGE-02", "FORM-03", "DATA-*", "A11Y-*"]

duration: 34m
completed: 2026-07-28
status: complete
---

# Phase 80 Plan 04: Supervised Frozen Jobs Bulk Recovery Summary

**Jobs bulk retry, cancel, and discard now operate on a bounded frozen scope through nonlinked supervised Lifeline work with exact progress, partial-result recovery, and durable per-target Audit evidence**

## Performance

- **Duration:** 34m
- **Started:** 2026-07-28T15:00:19Z
- **Completed:** 2026-07-28T15:34:25Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added startup-validated `:jobs_bulk_target_limit` configuration with an exact default of 100, hard maximum of 1,000, actionable invalid-value errors, and one named library-owned Jobs Task Supervisor.
- Added `BatchCoordinator` scope and preview contracts that freeze stable unique IDs, reauthorize every target, call real Lifeline previews, retain capabilities server-side, and disclose only finite safe display truth.
- Added max-four nonlinked execution with fixed 30-second per-target timeout, crash/timeout isolation, frozen-order reconstruction, bounded safe outcomes, aggregate progress, closed telemetry metadata, and owner-death continuation.
- Replaced deferred query authority and sequential bulk mutation in JobsLive with explicit cross-page selection, opt-in all-matching freeze, exact reason/count confirmation, accessible progress, all-success receipts, and unresolved-ID fresh-preview recovery.

## Task Commits

Each task used an atomic red-green pair:

1. **Task 80-04-01: Add the validated bulk limit and named Task Supervisor**
   - `fe1daf5` — failing bulk runtime bounds
   - `e52d0c8` — bounded supervised Jobs bulk work
2. **Task 80-04-02: Implement frozen preview and supervised execution in BatchCoordinator**
   - `a3e813f` — failing batch coordinator contracts
   - `e81c8ba` — frozen Jobs batch coordination
3. **Task 80-04-03: Integrate bulk scope, confirmation, progress, and recovery into JobsLive**
   - `6222cfd` — failing Jobs bulk workflow contracts
   - `c50731e` — supervised Jobs bulk recovery integration

## Files Created/Modified

- `lib/oban_powertools/application.ex` - Startup validation and the named Jobs Task Supervisor child.
- `lib/oban_powertools/runtime_config.ex` - Validated 100-default/1000-max bulk target accessor.
- `lib/oban_powertools/jobs/batch_coordinator.ex` - Frozen scope, real preview, supervised execution, progress, results, and confidential telemetry.
- `lib/oban_powertools/web/jobs_live.ex` - Explicit/all-matching selection, confirmation, progress, receipts, partial results, and fresh-preview recovery.
- `test/oban_powertools/application_test.exs` - Supervisor identity, lifecycle, and startup validation coverage.
- `test/oban_powertools/auth_test.exs` - Runtime bound defaults, valid overrides, and invalid configuration classes.
- `test/oban_powertools/jobs/batch_coordinator_test.exs` - Scope, confidentiality, concurrency, ordering, isolation, audit, timeout, and owner-lifecycle coverage.
- `test/oban_powertools/web/live/jobs_live_test.exs` - Frozen query, overflow, confirmation, result, recovery, and forged-event coverage.

## Decisions Made

- Used a single bounded ordered-ID query only when the operator explicitly broadens a fully selected page to all matching results. A forged early event is ignored server-side without issuing the query.
- Stored the opaque coordinator handle in LiveView private state and joined safe position-based outcomes to frozen IDs only inside the server-rendered LiveView.
- Kept accepted execution independent from the observing socket, while allowing abandoned previews to be explicitly cancelled instead of occupying a supervisor child until expiry.
- Guarded execution on the server-owned preview state as well as typed ready count and trimmed reason, preventing duplicate or replayed submit events from starting accepted work twice.

## Deviations from Plan

### Auto-fixed Issues

- **Cancelled abandoned preview coordinators.** Closing, replacing, or resetting a preview now sends a run-ref-scoped cancel message so unused previews release their supervised process immediately.
- **Rejected forged all-matching activation before eligibility.** The server verifies the page-selection offer before making the bounded membership query.
- **Added server-side duplicate-submit protection.** Execution starts only from the authoritative preview state, independent of client button disabling.

No scope-expanding schema, migration, dependency, route, direct Oban mutation, durable batch ledger, or public `Operator.bulk_*` API was added.

## Issues Encountered

- The repository's unfiltered `mix test` command includes intentionally heavy host-contract lanes with 180-second per-module timeouts, so it was not used as the Plan 80-04 completion gate. The plan-focused, shared-component, and existing Operator/Lifeline compatibility suites all completed cleanly.
- The existing `test/oban_powertools/operator_test.exs` unused-variable compiler warning remains outside this plan; production compilation passes with warnings treated as errors.

## User Setup Required

None - the default bound and Task Supervisor are installed automatically. Hosts may optionally set `config :oban_powertools, jobs_bulk_target_limit: n` for an integer from 1 through 1,000.

## Verification

- `mix test test/oban_powertools/jobs/batch_coordinator_test.exs test/oban_powertools/auth_test.exs test/oban_powertools/application_test.exs test/oban_powertools/web/live/jobs_live_test.exs --seed 0` - 67 tests, 0 failures.
- `mix test test/oban_powertools/web/components/operator_patterns_test.exs --seed 0` - 20 tests, 0 failures.
- `mix test test/oban_powertools/operator_test.exs test/oban_powertools/lifeline_test.exs --seed 0` - 35 tests, 0 failures.
- `mix compile --force --warnings-as-errors` passed across 102 files.
- All eight declared code/test paths pass `mix format --check-formatted` and `git diff --check`.
- Baseline-to-HEAD inspection contains exactly the eight declared implementation/test paths, with no migration, dependency, route, direct Oban mutation, unbounded `Jobs.list_ids`, or public Operator API change.

## Next Phase Readiness

- Plan 80-05 can build on bounded Jobs scopes, real per-target Audit evidence, and the now-complete selection/confirmation/recovery vocabulary.
- Jobs list, canonical detail, single-target actions, and supervised bulk actions now share the same server-owned authority and safe presentation boundaries.

## Self-Check: PASSED

- All eight declared implementation/test files exist and are committed.
- Red/green task commits `fe1daf5`, `e52d0c8`, `a3e813f`, `e81c8ba`, `6222cfd`, and `c50731e` exist.
- Every Plan 80-04 verification command and compatibility suite passes.
- No preview token, plan hash, reason, actor, target ID, filter value, worker, raw error, or payload enters aggregate messages or telemetry.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-28*
