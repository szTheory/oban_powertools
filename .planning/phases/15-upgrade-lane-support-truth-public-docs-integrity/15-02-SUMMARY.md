---
phase: 15-upgrade-lane-support-truth-public-docs-integrity
plan: 02
subsystem: testing
tags: [elixir, phoenix, oban, docs, ci, upgrade-proof]
requires:
  - phase: 15-01
    provides: frozen archived upgrade-source fixture and provenance baseline
provides:
  - archived-fixture upgrade harness wired to documented display-policy updates
  - native post-upgrade proof assertions for ops-demo pausing nightly_sync
  - host-shape upgrade guide with explicit support-truth buckets
affects: [PKG-02, host-contract-proof, upgrade-guide, support-truth]
tech-stack:
  added: []
  patterns: [archived fixture copy for upgrade proof, proof-only native test materialization, claim-based upgrade docs]
key-files:
  created: [guides/upgrade-and-compatibility.md]
  modified: [test/support/example_host_contract.ex, test/oban_powertools/example_host_contract_test.exs]
key-decisions:
  - "Use examples/phoenix_host_upgrade_source as the only upgrade-lane fixture root instead of mutating the current fixture in place."
  - "Prove upgrade success with the native ops-demo -> pause_cron_entry on nightly_sync threshold rather than config restoration alone."
patterns-established:
  - "Upgrade proof copies the archived fixture, applies documented display_policy changes, then runs the native proof command."
  - "Public upgrade guidance names one supported host shape and separates supported, tested, best-effort, host-owned, and intentionally unsupported claims."
requirements-completed: [PKG-02]
duration: 5min
completed: 2026-05-23
---

# Phase 15 Plan 02: Upgrade Lane Summary

**Archived-host upgrade proof with documented display-policy restoration and a native ops-demo pause threshold**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-23T13:28:18Z
- **Completed:** 2026-05-23T13:33:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Rebuilt `upgrade` so the harness copies `examples/phoenix_host_upgrade_source`, rewrites the local Powertools path, restores `display_policy`, and materializes the native proof files needed for the upgraded host.
- Strengthened `upgrade-proof` to assert the same `ops-demo`, `nightly_sync`, and `pause_cron_entry` threshold used by the canonical first-session lane while keeping migration success as secondary evidence.
- Rewrote the public upgrade guide around one supported Phoenix host shape and the five explicit support-truth buckets.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rebuild the upgrade harness around the archived historical fixture** - `5306951` (feat)
2. **Task 2: Strengthen the executable upgrade-proof lane and CI command** - `b09c7bb` (fix)
3. **Task 3: Rewrite the public upgrade guide around the singular supported host shape** - `0c00af5` (docs)

## Files Created/Modified
- `test/support/example_host_contract.ex` - switches the upgrade lane to the archived source fixture, applies documented upgrade actions, and runs the native post-upgrade proof command.
- `test/oban_powertools/example_host_contract_test.exs` - asserts the upgraded host reaches the native cron proof markers instead of stopping at config restoration.
- `guides/upgrade-and-compatibility.md` - documents the singular supported source lane, exact upgrade actions, and support-truth buckets in host-shape terms.

## Decisions Made

- Use the archived fixture as the only `upgrade` source so the guide and proof both point at the same pre-`display_policy` host posture.
- Treat the native cron mutation proof as the required success threshold for upgrades, with `Migrated` retained only as secondary evidence.
- Keep the workflow lane name and command stable; the behavior change lives in the harness and assertions, not CI naming.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed display policy insertion for the archived config shape**
- **Found during:** Task 2 (Strengthen the executable upgrade-proof lane and CI command)
- **Issue:** The first end-to-end `upgrade-proof` run failed because the archived fixture config ended with `auth_module` and the insertion logic assumed a different line shape.
- **Fix:** Replaced the brittle insertion logic with a direct `auth_module` line replacement that reliably appends `display_policy` to the copied archived config.
- **Files modified:** `test/support/example_host_contract.ex`
- **Verification:** `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof`
- **Committed in:** `b09c7bb`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix was required for correctness of the rebuilt upgrade lane. No scope creep.

## Issues Encountered

- The end-to-end `upgrade-proof` lane takes about 83 seconds because it boots and proves a temporary Phoenix host after applying the documented upgrade steps.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 15 Plan 03 can now align support-truth, hardening, troubleshooting, and docs-contract claims against a real archived-host upgrade lane.
- `PKG-02` now has executable proof and matching public upgrade guidance in place.

## Self-Check: PASSED

- Found `.planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-02-SUMMARY.md`
- Verified task commits `5306951`, `b09c7bb`, and `0c00af5` in `git log --oneline --all`

---
*Phase: 15-upgrade-lane-support-truth-public-docs-integrity*
*Completed: 2026-05-23*
