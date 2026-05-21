---
phase: 6-runtime-config-authorization-hardening
plan: 01
subsystem: infra
tags: [igniter, runtime-config, auth, installer]
requires:
  - phase: 0
    provides: host-owned installer and auth scaffolding
  - phase: 4
    provides: native operator surfaces that depend on repo/auth wiring
provides:
  - centralized repo and auth_module runtime contract
  - installer-emitted config :oban_powertools wiring
  - explicit missing-config failures for auth-gated runtime usage
affects: [phase-6, installer, native-operator-pages, runtime-config]
tech-stack:
  added: []
  patterns: [centralized runtime config, explicit host wiring, fail-fast setup errors]
key-files:
  created: [lib/oban_powertools/runtime_config.ex]
  modified: [lib/oban_powertools/auth.ex, lib/mix/tasks/oban_powertools.install.ex, test/oban_powertools/auth_test.exs, test/mix/tasks/oban_powertools.install_test.exs]
key-decisions:
  - "Repo and auth_module resolution now flows through ObanPowertools.RuntimeConfig instead of scattered direct Application env calls in auth surfaces."
  - "The installer writes explicit config :oban_powertools repo/auth_module guidance into host config instead of inferring runtime dependencies."
patterns-established:
  - "Pattern 1: required runtime wiring fails with stable setup-error copy at the usage boundary."
  - "Pattern 2: installer output remains grep-able and host-owned for Powertools integration."
requirements-completed: [FND-01, FND-02]
duration: 3 min
completed: 2026-05-20
---

# Phase 6 Plan 01: Runtime Config Contract Summary

**Centralized repo/auth_module runtime resolution with fail-fast setup errors and installer-emitted host wiring for `config :oban_powertools`**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-20T21:08:35Z
- **Completed:** 2026-05-20T21:11:08Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `ObanPowertools.RuntimeConfig` with `repo!/0`, `repo/1`, `auth_module!/0`, and centralized setup-error messaging.
- Rewired `ObanPowertools.Auth` to stop silently degrading when `:auth_module` is required on native operator surfaces.
- Extended the Igniter installer to emit explicit host-owned `config :oban_powertools, repo: ..., auth_module: ...` wiring and pinned it with source assertions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add a centralized runtime config contract for repo and auth-module lookups**
2. `3db1b1f` `test(6-01): add failing runtime config contract tests`
3. `d92fb6a` `feat(6-01): centralize runtime config resolution`
4. **Task 2: Make the installer emit the explicit host runtime wiring contract**
5. `cba52f4` `test(6-01): add failing installer runtime wiring test`
6. `3dbf59e` `feat(6-01): emit explicit powertools runtime wiring`

## Files Created/Modified

- `lib/oban_powertools/runtime_config.ex` - central runtime config contract and setup-error messages.
- `lib/oban_powertools/auth.ex` - required auth-module lookups now route through the shared contract.
- `lib/mix/tasks/oban_powertools.install.ex` - installer now injects explicit Powertools runtime config into host config.
- `test/oban_powertools/auth_test.exs` - covers configured lookups and explicit missing-config failures.
- `test/mix/tasks/oban_powertools.install_test.exs` - asserts the installer source exposes the `config :oban_powertools` contract.

## Decisions Made

- Left `ObanPowertools.Application` unchanged so missing config fails at required usage boundaries rather than at unconditional application boot.
- Used `Igniter.Project.Config.configure_group/6` to write the host config contract directly instead of relying on comments or runtime inference.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

- `lib/mix/tasks/oban_powertools.install.ex:35` keeps the generated auth module `current_actor/1` TODO because host applications must implement their own session lookup.
- `lib/mix/tasks/oban_powertools.install.ex:41` keeps the generated auth module `can_perform_action?/3` TODO because host applications must implement their own authorization policy.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Runtime wiring is explicit and test-backed.
- Phase 6 Plan 02 can focus on cron preview authorization ordering without reopening installer or auth-module fallback behavior.

## Verification

- `mix test test/oban_powertools/auth_test.exs` -> PASS
- `mix test test/mix/tasks/oban_powertools.install_test.exs` -> PASS
- `mix test test/oban_powertools/auth_test.exs test/mix/tasks/oban_powertools.install_test.exs` -> PASS

## Self-Check: PASSED

- Found `.planning/phases/6-runtime-config-authorization-hardening/6-01-SUMMARY.md`
- Verified task commits `3db1b1f`, `d92fb6a`, `cba52f4`, and `3dbf59e`
