---
phase: 15-upgrade-lane-support-truth-public-docs-integrity
plan: 01
subsystem: packaging
tags: [phoenix, oban, upgrade, fixture, docs]
requires:
  - phase: 12-fresh-host-install-path-example-fixture-repair
    provides: canonical Phoenix host fixture and installer-faithful migration/auth/router seams
  - phase: 14-evidence-chain-cross-phase-verification-closure
    provides: repaired requirement and proof traceability for host-contract work
provides:
  - frozen archived upgrade-source fixture tree
  - commit-pinned provenance for the supported upgrade source lane
  - maintainer-only regeneration helper kept out of CI
affects: [15-02-upgrade-proof, PKG-02, host-contract-docs]
tech-stack:
  added: []
  patterns:
    - separate archived historical fixture from the current canonical fixture
    - pin historical provenance in fixture-local docs and scripts
key-files:
  created:
    - examples/phoenix_host_upgrade_source/config/config.exs
    - examples/phoenix_host_upgrade_source/lib/phoenix_host_web/router.ex
    - examples/phoenix_host_upgrade_source/priv/repo/seeds.exs
    - examples/phoenix_host_upgrade_source/README.md
    - examples/phoenix_host_upgrade_source/regenerate.sh
  modified: []
key-decisions:
  - "Freeze a dedicated pre-display-policy fixture tree instead of synthesizing the upgrade source from examples/phoenix_host."
  - "Anchor the archived source lane to commit a1fed86 and keep regeneration maintainer-only rather than part of CI."
patterns-established:
  - "Historical upgrade fixtures should preserve repo/auth/router/migration prerequisites while omitting forward-only contract seams."
  - "Fixture provenance lives beside the fixture in README.md plus a commit-pinned helper script."
requirements-completed: [PKG-02]
duration: 4min
completed: 2026-05-23
---

# Phase 15 Plan 01: Archived pre-display-policy upgrade-source fixture with commit-pinned provenance

**Frozen historical Phoenix host fixture for the single supported upgrade lane, with pre-`display_policy` config, checked-in Powertools migrations, and a maintainer-only regeneration path tied to commit `a1fed86`.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-23T13:16:00Z
- **Completed:** 2026-05-23T13:19:54Z
- **Tasks:** 2
- **Files modified:** 52

## Accomplishments
- Added `examples/phoenix_host_upgrade_source/` as the archived historical host tree that preserves `repo`, `auth_module`, `/ops/jobs`, `/oban`, migrations, and the narrow `ops-demo` / `nightly_sync` seed story.
- Removed the forward-looking `display_policy` contract from the archived fixture so the source lane stays honestly pre-upgrade.
- Documented commit `a1fed86` as the singular supported upgrade source lane and added a maintainer-only regeneration helper that stays outside CI.

## Task Commits

Each task was committed atomically:

1. **Task 1: Freeze the real supported upgrade-source host shape** - `c37a554` (feat)
2. **Task 2: Document provenance and the maintainer-only regeneration path** - `b976ccd` (docs)

## Files Created/Modified
- `examples/phoenix_host_upgrade_source/config/config.exs` - archived Powertools config with `repo` and `auth_module`, intentionally without `display_policy`
- `examples/phoenix_host_upgrade_source/lib/phoenix_host_web/router.ex` - host-owned `/ops/jobs` scope with nested `/oban` bridge mount preserved in the archived lane
- `examples/phoenix_host_upgrade_source/lib/phoenix_host_web/oban_powertools_auth.ex` - thin host auth seam retained for the supported source posture
- `examples/phoenix_host_upgrade_source/priv/repo/migrations/*` - checked-in Powertools migration set carried into the historical fixture
- `examples/phoenix_host_upgrade_source/priv/repo/seeds.exs` - narrow seeded operator story for `ops-demo` and `nightly_sync`
- `examples/phoenix_host_upgrade_source/README.md` - provenance, support-truth exclusions, and source-lane contract
- `examples/phoenix_host_upgrade_source/regenerate.sh` - commit-pinned maintainer-only regeneration helper

## Decisions Made
- Used a second checked-in fixture tree for the historical source lane so future upgrade proof can start from a real archived host shape instead of mutating the current canonical fixture in place.
- Kept the archive honest by omitting `display_policy` from the source config while preserving the native `/ops/jobs` shell, nested `/oban` mount shape, and migration-complete database posture.
- Treated regeneration as provenance insurance only: commit-pinned, maintainer-facing, and excluded from the normal contract-proof workflow.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `15-02` can now point the upgrade-proof lane at `examples/phoenix_host_upgrade_source` instead of synthesizing a pre-`display_policy` source host.
- Provenance and best-effort exclusions are now fixture-local, so the upgrade guide rewrite can reference one auditable source lane directly.

---
*Phase: 15-upgrade-lane-support-truth-public-docs-integrity*
*Completed: 2026-05-23*

## Self-Check: PASSED

- Summary file exists at `.planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-01-SUMMARY.md`
- Verified task commits `c37a554` and `b976ccd` are present in `git log --oneline --all`
