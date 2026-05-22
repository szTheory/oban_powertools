---
phase: 12-fresh-host-install-path-example-fixture-repair
plan: 02
subsystem: database
tags: [phoenix, oban, ecto, fixture, docs]
requires:
  - phase: 12-01
    provides: fresh-host installer output and deterministic migration naming
provides:
  - canonical fixture Powertools migration set
  - narrow first-session seed state for ops-demo and nightly_sync
  - curated provenance docs and deterministic regeneration script
affects: [PKG-01, DOC-01, examples/phoenix_host, host-contract-proof]
tech-stack:
  added: []
  patterns: [installer-faithful checked-in migrations, curated fixture provenance buckets, narrow first-session seed lane]
key-files:
  created:
    - examples/phoenix_host/priv/repo/migrations/20260522000001_oban_powertools_audit_events.exs
    - examples/phoenix_host/priv/repo/migrations/20260522000034_oban_powertools_repair_archives.exs
    - .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-02-SUMMARY.md
  modified:
    - examples/phoenix_host/priv/repo/seeds.exs
    - examples/phoenix_host/README.md
    - examples/phoenix_host/regenerate.sh
key-decisions:
  - "Checked in the installer-faithful Powertools migration set as literal fixture files so ecto.reset proves the same schema shape maintainers review in git."
  - "Seeded only ops-demo and nightly_sync so the fixture supports one honest first-session lane without drifting into showcase data."
  - "Documented fixture provenance in three buckets: mix phx.new, mix oban_powertools.install, and manual host-owned follow-up."
patterns-established:
  - "Canonical fixture migrations mirror installer output instead of generating schema state at runtime."
  - "Curated fixture prose must separate generated buckets from manual host-owned seams."
requirements-completed: [PKG-01, DOC-01]
duration: 7min
completed: 2026-05-22
---

# Phase 12 Plan 02: Fresh Host Install Path Example Fixture Repair Summary

**Installer-faithful Powertools fixture migrations, narrow ops-demo/nightly_sync seed state, and curated provenance docs for the canonical Phoenix host**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-22T13:58:00Z
- **Completed:** 2026-05-22T14:05:31Z
- **Tasks:** 2
- **Files modified:** 20

## Accomplishments

- Checked in the full Powertools migration set under `examples/phoenix_host/priv/repo/migrations` so the canonical fixture resets into a native-operator-complete schema.
- Replaced the placeholder seed output with an idempotent first-session seed that defines operator `ops-demo` and cron entry `nightly_sync`.
- Rewrote the fixture README and regeneration script around honest curated provenance, with explicit manual host-owned follow-up markers.

## Task Commits

Each task was committed atomically:

1. **Task 1: Check in the full Powertools migration set and the narrow seeded first-session state** - `b78e97f` (feat)
2. **Task 2: Rewrite the fixture README and regeneration script around honest curated-fixture provenance** - `fbfb0fe` (docs)

**Plan metadata:** pending

## Files Created/Modified

- `examples/phoenix_host/priv/repo/migrations/*.exs` - Canonical checked-in Powertools schema baseline for the fixture host.
- `examples/phoenix_host/priv/repo/seeds.exs` - Idempotent seed for `ops-demo` and `nightly_sync`.
- `examples/phoenix_host/README.md` - Curated support-truth and provenance contract for the fixture.
- `examples/phoenix_host/regenerate.sh` - Deterministic regeneration script that rebuilds generated buckets and flags manual host seams.

## Decisions Made

- Used literal checked-in migration files from the installer contract rather than clever seed-time generation so `MIX_ENV=test mix ecto.reset` remains the fixture proof path.
- Kept the seed set intentionally narrow and operator-facing, avoiding showcase-only records.
- Treated README and regeneration copy as part of the public contract, so the fixture now states its generated-vs-manual boundary explicitly.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Parallel verification briefly raced on the example host build lock. Rerunning `MIX_ENV=test mix ecto.reset && MIX_ENV=test mix run priv/repo/seeds.exs` sequentially produced the expected clean verification signal.
- `regenerate.sh` initially assumed fresh Phoenix output already contained the Oban dependency. The script was corrected before commit to patch the stock `{:postgrex, ">= 0.0.0"}` dependency block instead.

## User Setup Required

None - no external service configuration required.

## Known Stubs

- `examples/phoenix_host/regenerate.sh:59` - Intentional TODO marker for reapplying the real auth/session seam after regeneration.
- `examples/phoenix_host/regenerate.sh:60` - Intentional TODO marker for reapplying the real display policy after regeneration.
- `examples/phoenix_host/regenerate.sh:61` - Intentional TODO marker for restoring curated seeds and README wording after regeneration.
- `examples/phoenix_host/regenerate.sh:62` - Intentional TODO marker to diff the regenerated tree before replacing the checked-in fixture.

## Threat Flags

None.

## Next Phase Readiness

- The canonical fixture now resets into Powertools-complete schema state and carries the narrow seeded operator lane required for later proof work.
- The provenance story is explicit enough for future docs and proof tasks to reference without overstating generator coverage.

## Self-Check: PASSED

- Verified `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-02-SUMMARY.md` exists.
- Verified task commits `b78e97f` and `fbfb0fe` exist in git history.

---
*Phase: 12-fresh-host-install-path-example-fixture-repair*
*Completed: 2026-05-22*
