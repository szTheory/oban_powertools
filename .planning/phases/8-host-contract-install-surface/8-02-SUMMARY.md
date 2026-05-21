---
phase: 8-host-contract-install-surface
plan: 02
subsystem: web
tags: [elixir, phoenix, liveview, oban_web, routing]
requires: []
provides:
  - "Explicit host-owned /ops/jobs mount contract in ObanPowertools.Web.Router"
  - "Executable proof for native /ops/jobs pages and optional /ops/jobs/oban bridge"
affects: [phase-9-policy-boundaries, phase-11-contract-proof, HST-01]
tech-stack:
  added: []
  patterns: ["host-owned outer scope plus library-owned inner route macro", "optional oban_web bridge limited to shared on_mount auth hook"]
key-files:
  created: [".planning/phases/8-host-contract-install-surface/8-02-SUMMARY.md"]
  modified: ["lib/oban_powertools/web/router.ex", "test/oban_powertools/web/router_test.exs"]
key-decisions:
  - "Document the outer /ops/jobs scope and browser pipeline as host-owned public contract in router docs."
  - "Keep the optional oban_web bridge frozen to /ops/jobs/oban plus ObanPowertools.Web.LiveAuth, with resolver work deferred to Phase 9."
patterns-established:
  - "Host routers mount Powertools by owning the outer scope and calling oban_powertools_routes(\"/oban\") inside it."
  - "Bridge assertions prove mount path and shared LiveAuth hook without expanding Phase 8 into resolver policy work."
requirements-completed: [HST-01]
duration: 2min
completed: 2026-05-21
---

# Phase 8 Plan 02: Route Contract Summary

**Host-owned `/ops/jobs` shell contract with a documented nested `/oban` bridge and executable route proof**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-21T18:14:07+02:00
- **Completed:** 2026-05-21T18:15:25Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Documented the public ownership split in `ObanPowertools.Web.Router`: host owns the outer `/ops/jobs` browser scope, library owns the inner native routes.
- Locked the optional `oban_web` bridge docs to the nested `"/oban"` path and shared `ObanPowertools.Web.LiveAuth` mount hook only.
- Added router tests proving native `/ops/jobs/*` routes, conditional `/ops/jobs/oban` bridge routing, and the absence of a root-level `/oban` mount.

## Task Commits

Each task was committed atomically:

1. **Task 1: Document the host-owned mount boundary directly in `ObanPowertools.Web.Router`** - `d954292` (`docs`)
2. **Task 2: Prove native and optional bridge mount shape with router tests** - `83ff46f` (`test`)

## Files Created/Modified

- `lib/oban_powertools/web/router.ex` - expanded public docs for the host-owned outer scope, nested `/oban` bridge path, and explicit Phase 9 deferral.
- `test/oban_powertools/web/router_test.exs` - added route-contract assertions for `/ops/jobs/oban`, root-level `/oban`, and the shared `ObanPowertools.Web.LiveAuth` mount hook.
- `.planning/phases/8-host-contract-install-surface/8-02-SUMMARY.md` - execution summary with verification evidence and self-check.

## Decisions Made

- Document the host-owned `/ops/jobs` scope directly in the public router macro docs so the ownership boundary is visible where hosts integrate it.
- Prove the bridge contract with route metadata plus a source-level `resolver:` refutation, rather than expanding Phase 8 into any new resolver hook.

## Verification Results

- `rg -n 'host router owns the outer .*/ops/jobs|host router owns \`pipe_through\\(:browser\\)\`|optional bridge path is \`"/oban"\`|Resolver, redaction, formatter|Phase 9' lib/oban_powertools/web/router.ex` — PASS
- `mix test test/oban_powertools/web/router_test.exs` after Task 1 — PASS (`2 tests, 0 failures`)
- `rg -n '/ops/jobs/oban|/oban|ObanPowertools.Web.LiveAuth|resolver:' test/oban_powertools/web/router_test.exs` — PASS
- `mix test test/oban_powertools/web/router_test.exs` after Task 2 — PASS (`4 tests, 0 failures`)
- Plan verification `mix test test/oban_powertools/web/router_test.exs` — PASS (`4 tests, 0 failures`)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced stale task verify flag**
- **Found during:** Task 1 verification
- **Issue:** The plan-specified `mix test ... -x` command is unsupported by the installed Mix version and fails before running the router tests.
- **Fix:** Re-ran the verification with the supported command `mix test test/oban_powertools/web/router_test.exs`.
- **Files modified:** None
- **Verification:** Router test file passed after the command adjustment.
- **Committed in:** Not applicable (verification-only deviation)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep. The only deviation was a tooling-level verification command adjustment; all planned behavior and proof landed as intended.

## Issues Encountered

- Task 2 was marked `tdd="true"`, but the route behavior already existed after Task 1 and the added assertions served as proof of shipped behavior rather than driving a new router implementation change.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 9 can now build policy seams on a locked route contract: host owns the outer scope, Powertools owns the inner native tree, and the optional bridge is frozen to the nested mount path plus shared LiveAuth hook.
- No blocker was introduced by this plan.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/8-host-contract-install-surface/8-02-SUMMARY.md`
- Task commit `d954292` is present in `git log`
- Task commit `83ff46f` is present in `git log`
