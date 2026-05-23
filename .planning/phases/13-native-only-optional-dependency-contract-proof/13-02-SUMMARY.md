---
phase: 13-native-only-optional-dependency-contract-proof
plan: 02
subsystem: docs
tags: [readme, guides, support-truth, optional-dependency, phoenix, oban]
requires:
  - phase: 12-04
    provides: public docs aligned to the repaired day-0 host contract
provides:
  - native-first README and installation wording
  - first-session guidance that treats `/ops/jobs` as the default mutation surface
  - bridge and compatibility guides narrowed to an optional read-only annex posture
affects: [README, guides, docs-contract, host-contract-proof]
tech-stack:
  added: []
  patterns: [native-first support truth, additive read-only bridge wording, tested-lane naming]
key-files:
  created: [.planning/phases/13-native-only-optional-dependency-contract-proof/13-02-SUMMARY.md]
  modified: [README.md, guides/installation.md, guides/first-operator-session.md, guides/optional-oban-web-bridge.md, guides/upgrade-and-compatibility.md]
key-decisions:
  - "Use the exact D-17 native-first wording in README and installation guidance so the public default matches the proof lanes."
  - "Keep `/ops/jobs/oban` documented as an additive read-only inspection annex, never as a co-equal mutation surface."
  - "Rename compatibility lanes to native-first and optional bridge to acknowledge two tested lanes without implying parity."
patterns-established:
  - "Public docs should lead with the native `/ops/jobs` shell and treat `oban_web` as optional."
  - "Compatibility docs should name only the tested lanes and leave everything else best-effort."
requirements-completed: [PKG-03, DOC-03]
duration: 9min
completed: 2026-05-23
---

# Phase 13 Plan 02 Summary

**README and operator guides now present `/ops/jobs` as the native-first paved road while keeping `/ops/jobs/oban` explicitly optional, additive, and read-only**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-23T09:55:00Z
- **Completed:** 2026-05-23T10:04:19Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Reframed `README.md`, `guides/installation.md`, and `guides/first-operator-session.md` around the native `/ops/jobs` shell as the default mutation surface.
- Narrowed the optional bridge guide so `/ops/jobs/oban` is described as an additive read-only inspection annex that reuses host-owned seams.
- Renamed the compatibility lanes to `tested native-first lane` and `tested optional bridge lane` while preserving the canonical `examples/phoenix_host` proof-host reference.

## Task Commits

None - no commits were requested for this plan.

## Files Created/Modified

- `README.md` - Adds the exact native-first support-truth wording and makes `/ops/jobs` the default mental model.
- `guides/installation.md` - Leads the day-0 path with the native shell and keeps `oban_web` explicitly optional.
- `guides/first-operator-session.md` - Keeps `ops-demo`, `nightly_sync`, and `pause_cron_entry` as the success threshold and subordinates the bridge to native mutation proof.
- `guides/optional-oban-web-bridge.md` - Describes `/ops/jobs/oban` as an additive read-only inspection annex with shared host seams.
- `guides/upgrade-and-compatibility.md` - Names the tested lanes honestly and preserves `examples/phoenix_host` as the canonical proof host.
- `.planning/phases/13-native-only-optional-dependency-contract-proof/13-02-SUMMARY.md` - Records plan completion and the native-first docs posture.

## Decisions Made

- Followed the plan exactly by applying the required D-17 wording verbatim where specified.
- Kept the compatibility guide scoped to supported-host reality instead of broadening the support matrix.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The docs now match the Phase 13 native-only and optional-bridge support story expected by the proof lanes.
- Plan 13-03 can lock this wording into docs-contract assertions and workflow naming without further docs reframing.

---
*Phase: 13-native-only-optional-dependency-contract-proof*
*Completed: 2026-05-23*
