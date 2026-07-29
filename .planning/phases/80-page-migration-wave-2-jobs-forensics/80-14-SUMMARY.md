---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 14
subsystem: security
tags: [forensics, ecto, authorization, audit, liveview]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 13
    provides: Phase closure verification that identified the cross-workflow evidence bypass
provides:
  - Relationally authoritative workflow-step evidence selection
  - Audit scope rebuilt from the validated Step record
  - Context and connected regressions for uniform cross-workflow failure
affects: [forensics, audit, page-verification, PAGE-09]

tech-stack:
  added: []
  patterns:
    - Resolve compound resource authority in one Ecto predicate before downstream reads
    - Rebuild downstream query identity from a validated database record

key-files:
  created: []
  modified:
    - lib/oban_powertools/forensics.ex
    - test/oban_powertools/forensics_test.exs
    - test/oban_powertools/web/live/forensics_live_test.exs

key-decisions:
  - "A workflow-step selector is authoritative only after one Step query matches id, workflow_id, and step_name together."
  - "Audit receives a fresh Scope built from the validated Step row; raw URL resource identity is never reused as query authority."
  - "A relational mismatch returns the same Evidence unavailable result before Audit, presenter, or destination work."

patterns-established:
  - "Relational authorization boundary: syntactic scope validity precedes, but never replaces, database-owned relationship validation."
  - "Uniform non-enumeration: missing and cross-workflow workflow-step scopes share the exact connected unavailable presentation."

requirements-completed: []

coverage:
  - deliverable: Relationally validated workflow-step evidence dispatch
    verification:
      - kind: test
        ref: "test/oban_powertools/forensics_test.exs#workflow-step evidence requires one authoritative resource workflow and step triple"
        status: pass
      - kind: command
        ref: "mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0"
        status: pass
    human_judgment: false
  - deliverable: Uniform connected unavailable output for forged cross-workflow selectors
    verification:
      - kind: test
        ref: "test/oban_powertools/web/live/forensics_live_test.exs#cross-workflow step selectors match ordinary unavailable output and destinations"
        status: pass
    human_judgment: false
  - deliverable: Existing Audit and evidence-bundle compatibility
    verification:
      - kind: command
        ref: "mix test test/oban_powertools/audit_test.exs test/oban_powertools/forensics/evidence_bundle_test.exs --seed 0"
        status: pass
    human_judgment: false

duration: 5m
completed: 2026-07-29
status: complete
---

# Phase 80 Plan 14: Relational Workflow-Step Evidence Authority Summary

**Workflow-step Forensics now validates resource, workflow, and step identity together before any Audit read and fails cross-workflow selectors through the uniform unavailable presentation**

## Performance

- **Duration:** 5m
- **Started:** 2026-07-29T01:33:24Z
- **Completed:** 2026-07-29T01:38:00Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Added a single Step lookup that simultaneously constrains `id`, `workflow_id`, and `step_name`, returning before Audit access when the relationship is absent.
- Rebuilt the successful workflow-step Audit scope entirely from the validated Step row while preserving root-workflow selection and bounded chronology behavior.
- Added adversarial two-workflow context and LiveView regressions proving zero foreign Audit reads, no foreign evidence fields, and byte-equivalent unavailable output with no destinations.

## Task Commits

Task 80-14-01 used one atomic red-green pair:

1. **RED: Reproduce cross-workflow evidence bypass** - `103b27a`
2. **GREEN: Bind step evidence to validated workflow** - `e3a5072`

## Files Created/Modified

- `lib/oban_powertools/forensics.ex` - Exact three-predicate Step resolution, uniform early failure, and database-derived Audit scope.
- `test/oban_powertools/forensics_test.exs` - Two-workflow query-capture and confidentiality regression with valid same-workflow compatibility proof.
- `test/oban_powertools/web/live/forensics_live_test.exs` - Connected forged-selector regression comparing exact unavailable output and destination sets.

## Decisions Made

- Kept `Scope.parse/1` as the pure six-key grammar boundary and added relational authority only inside the repository-backed workflow bundle path.
- Resolved an explicit workflow-step selector before loading workflow stories or Audit evidence; a mismatch cannot fall back to a blocker or first step.
- Preserved existing root-workflow fallback behavior by applying the new resolution only to scopes whose resource type is `workflow_step`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The shared checkout contained substantial unrelated dirty work. It was preserved and excluded from both task commits.

## User Setup Required

None - no external service configuration, dependency, migration, route, or schema change is required.

## Verification

- `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` - 44 tests, 0 failures.
- `mix test test/oban_powertools/audit_test.exs test/oban_powertools/forensics/evidence_bundle_test.exs --seed 0` - 13 tests, 0 failures.
- Exact three-file `mix format --check-formatted ...` command passed.
- Exact three-file `git diff --check -- ...` command passed.
- Source inspection confirms one workflow-step predicate combines `step.id`, `step.workflow_id`, and `step.step_name`.
- The adversarial mismatch performs one relational Step lookup and zero `oban_powertools_audit_events` reads.
- Both task commits pass the plan-scoped file boundary and contain no route, schema, migration, dependency, presenter-shape, or generated-asset change.

## Next Phase Readiness

- CR-01 is closed and PAGE-09 can be re-evaluated after the remaining Phase 80 gap plans execute.
- Ready for Plan 80-15 oversized Jobs URL integer closure.
- No blockers remain from this plan.

## Self-Check: PASSED

- All three declared implementation/test files exist.
- RED/GREEN commits `103b27a` and `e3a5072` exist.
- All task acceptance criteria and plan verification commands pass.
- Cross-workflow selectors return before Audit and expose no foreign event action, actor, status, timestamp, ID, note, or destination.
- Valid same-workflow workflow-step and root-workflow evidence remain bounded and available.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-29*
