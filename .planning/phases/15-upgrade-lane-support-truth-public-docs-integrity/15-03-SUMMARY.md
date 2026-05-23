---
phase: 15-upgrade-lane-support-truth-public-docs-integrity
plan: 03
subsystem: docs
tags: [docs, support-truth, troubleshooting, telemetry, upgrade-proof]
requires:
  - phase: 15-02
    provides: real archived-host upgrade lane and singular upgrade guide wording
provides:
  - five-bucket support-truth language across README and guide entrypoints
  - production hardening and troubleshooting guidance tied to host-owned seams
  - a narrowed docs contract that locks stable claims and runtime setup errors
affects: [README, guides, docs-contract, host-adoption]
tech-stack:
  added: []
  patterns: [claim-based docs contract enforcement, five-bucket support-truth vocabulary]
key-files:
  created: [.planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-03-SUMMARY.md]
  modified: [README.md, guides/support-truth-and-ownership-boundaries.md, guides/example-app-walkthrough.md, examples/phoenix_host/README.md, guides/production-hardening.md, guides/troubleshooting.md, test/oban_powertools/docs_contract_test.exs]
key-decisions:
  - "Use the same supported/tested/best-effort/host-owned/intentionally unsupported vocabulary in every public support-truth entrypoint."
  - "Keep production-hardening prose narrative, but anchor troubleshooting claims to the exact RuntimeConfig fail-fast errors."
  - "Expand docs-contract coverage to hardening and troubleshooting guides while asserting markers only, not guide paragraphs."
patterns-established:
  - "Support-truth docs repeat the same five buckets instead of ad hoc bullet lists."
  - "Docs-contract tests protect commands, paths, lane names, bucket labels, and exact runtime errors only."
requirements-completed: [PKG-02, HST-03, DOC-02]
duration: 8min
completed: 2026-05-23
---

# Phase 15 Plan 03: Upgrade Lane, Support Truth & Public Docs Integrity Summary

**Five-bucket support-truth docs, host-owned hardening guidance, and claim-based docs-contract checks aligned to the verified native-first and upgrade-proof lanes**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-23T15:32:00Z
- **Completed:** 2026-05-23T15:40:17Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Rewrote README, support-truth docs, and fixture-facing docs around one explicit five-bucket vocabulary.
- Aligned production hardening and troubleshooting guidance to real host-owned auth, transport, redaction, bridge, and runtime-config seams.
- Narrowed docs-contract enforcement to stable support markers, workflow lane names, and exact fail-fast setup errors.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite the public support-truth surfaces around the five explicit buckets** - `60134e6` (docs)
2. **Task 2: Align hardening and troubleshooting guidance to real host-owned seams** - `32ed9b6` (docs)
3. **Task 3: Narrow docs contract enforcement to stable claim markers** - `62cb15b` (test)

## Files Created/Modified

- `README.md` - front-door support-truth summary with the five public buckets and native-first bridge posture
- `guides/support-truth-and-ownership-boundaries.md` - primary long-form support-truth and ownership split guide
- `guides/example-app-walkthrough.md` - distinguishes the canonical current-state fixture from the frozen upgrade source fixture
- `examples/phoenix_host/README.md` - clarifies current-state fixture purpose versus upgrade-source fixture purpose
- `guides/production-hardening.md` - host-owned production checklist for auth, actor/session, display policy, router, transport, bridge, and telemetry seams
- `guides/troubleshooting.md` - exact runtime-config errors plus operator-host debugging checks
- `test/oban_powertools/docs_contract_test.exs` - stable docs markers for support truth, upgrade-proof lane naming, and fail-fast runtime errors

## Decisions Made

- Repeated the five support-truth buckets verbatim across public entrypoints so support posture no longer depends on local wording.
- Kept production guidance narrative, but treated the `RuntimeConfig` setup errors as the only exact troubleshooting strings worth locking.
- Added hardening and troubleshooting guides to docs-contract coverage without freezing checklist order or explanatory prose.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Task 1's verification command rejected the literal phrase `write parity`, so the unsupported bridge wording was tightened to "using the bridge as a mutation surface" while preserving the same boundary.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 15 now has aligned upgrade, support-truth, hardening, troubleshooting, and docs-contract evidence.
- The reopened v1.1 host-adoption gaps for `PKG-02`, `HST-03`, and `DOC-02` are ready to be marked complete.

## Self-Check

PASSED - summary file exists and task commits `60134e6`, `32ed9b6`, and `62cb15b` are present in git history.

---
*Phase: 15-upgrade-lane-support-truth-public-docs-integrity*
*Completed: 2026-05-23*
