---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 05
subsystem: forensics
tags: [ecto, audit, typed-scope, bounded-queries, canonical-urls, security]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 04
    provides: Bounded Jobs scopes and durable per-target Audit evidence
provides:
  - Closed four-family Forensics scope grammar over exactly six selector keys
  - Canonical ordered Forensics URL encoding with fail-closed invalid destinations
  - Stable 50-row workflow and incident Audit windows with honest coverage metadata
affects: [80-06, 80-07, forensics, audit, selectors]

tech-stack:
  added: []
  patterns:
    - Untrusted selectors parse into one typed family before any evidence read
    - Workflow Audit windows use exact relational counts while incident windows use one-row has-more probes
    - Optional forensic event restrictions are finite allowlisted SQL predicates

key-files:
  created:
    - lib/oban_powertools/forensics/scope.ex
  modified:
    - lib/oban_powertools/audit.ex
    - lib/oban_powertools/web/selectors.ex
    - test/oban_powertools/audit_test.exs
    - test/oban_powertools/forensics_test.exs
    - test/oban_powertools/web/selectors_test.exs

key-decisions:
  - "Scope.parse/1 accepts only workflow, incident, cron_entry, or limiter shapes over the six public keys and replaces every conflict with empty canonical params."
  - "Audit.forensic_window/2 revalidates the supplied Scope struct and requires an explicit repository before issuing a source query."
  - "Workflow and workflow-step windows use authoritative resource_type/resource_id predicates, exact counts, and SQL limit 50."
  - "Incident windows retain total_count: nil and use SQL limit 51 because metadata->>'incident_fingerprint' has no host-owned index."

patterns-established:
  - "Typed selector boundary: parse and canonicalize before source dispatch, with no hidden family precedence."
  - "Coverage-aware bounds: exact totals for indexed relational identity, has-more-only truth for the unindexed incident predicate."
  - "Stable evidence order: inserted_at DESC and id DESC at every Audit window boundary."

requirements-completed: ["PAGE-09", "DATA-*", "PAGE-10", "A11Y-*"]

duration: 11m
completed: 2026-07-28
status: complete
---

# Phase 80 Plan 05: Typed Forensics Scope and Bounded Audit Windows Summary

**Forensics now has one fail-closed four-family selector grammar, one canonical six-key URL encoder, and stable database-bounded workflow and incident Audit windows**

## Performance

- **Duration:** 11m
- **Started:** 2026-07-28T15:38:50Z
- **Completed:** 2026-07-28T15:49:32Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a pure `Forensics.Scope` sum-type parser for workflow, incident, Cron entry, and limiter evidence over exactly six selector keys, including consistent workflow/job context pairs and active/resolved incident views.
- Made invalid, mixed, orphaned, incomplete, unknown, arbitrary-job, duplicate, non-string, and seventh-key inputs fail closed before any source callback with no conflicting values in the canonical destination.
- Closed `Selectors.forensic_path/1` to the exact six-key order while preserving Unicode and delimiter-heavy values through URI encoding.
- Added `Audit.forensic_window/2` with an explicit repository, typed-scope revalidation, authoritative relational predicates, stable timestamp/id ordering, finite SQL event restrictions, and fixed 50-row output.
- Added exact workflow totals plus a deliberate incident 51-row has-more probe with `total_count: nil`, avoiding completeness claims for the unindexed JSONB fingerprint predicate.
- Captured and executed the generated incident SQL with local `EXPLAIN (ANALYZE, BUFFERS)` evidence.

## Task Commits

Each task used an atomic red-green pair:

1. **Task 80-05-01: Implement the typed scope grammar and canonical Forensics URLs**
   - `b493986` — failing typed forensic scope contracts
   - `bb86617` — typed forensic scope grammar
2. **Task 80-05-02: Add stable bounded Audit windows and measure incident predicates**
   - `c23587d` — failing bounded Audit window contracts
   - `91138cb` — bounded forensic Audit windows

## Files Created/Modified

- `lib/oban_powertools/forensics/scope.ex` - Pure closed selector grammar, typed scope, and canonical parameter order.
- `lib/oban_powertools/web/selectors.ex` - Exact six-key ordered Forensics path encoder.
- `lib/oban_powertools/audit.ex` - Explicit-repo typed forensic windows, finite event allowlist, relational count, and incident probe.
- `test/oban_powertools/forensics_test.exs` - Table coverage for all valid families, context pairs, invalid classes, and read-before-parse protection.
- `test/oban_powertools/web/selectors_test.exs` - Ordered canonical URL, encoding, unknown-key, empty-key, and invalid-destination coverage.
- `test/oban_powertools/audit_test.exs` - Stable 55-row bounds, unrelated-scope exclusion, SQL telemetry, allowlist rejection, and local EXPLAIN coverage.

## Decisions Made

- Revalidated even a supplied `%Scope{}` through its canonical parameters before querying, so manually forged or unsupported typed values cannot bypass the closed grammar.
- Used the optional workflow resource pair when present and otherwise derived the authoritative workflow identity from `workflow_id`; workflow-step evidence never falls back to a broad workflow scan.
- Kept allowlisted event restrictions inside both the exact count and row queries, and rejected unknown restrictions before issuing any database query.
- Returned incident coverage as `shown_count` plus `has_more?` only. The absence of an Audit JSONB fingerprint index makes an exact incident count an inappropriate default contract.

## Deviations from Plan

None - the implementation stayed within the declared Scope, Selectors, Audit, and focused test files. No evidence assembly, presenter, route, source, migration, index, schema, dependency, mutation, or seventh selector key was added.

## Issues Encountered

- The deterministic local incident EXPLAIN used a sequential scan over `metadata->>'incident_fingerprint'`, confirming that the predicate is unindexed. The observed local cost and timing apply only to test cardinality and are not a production latency claim; hosts should evaluate a host-owned index at representative scale.

## User Setup Required

None. No migration, index, dependency, or configuration change is required.

## Verification

- `mix test test/oban_powertools/audit_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/selectors_test.exs --seed 0` - 51 tests, 0 failures.
- `mix test test/oban_powertools/audit_test.exs --seed 0` - 9 tests, 0 failures, including generated SQL plus `EXPLAIN (ANALYZE, BUFFERS)`.
- Task 80-05-01 focused scope/selector suite - 42 tests, 0 failures.
- `mix compile --warnings-as-errors` passed.
- All six declared implementation/test paths pass `mix format --check-formatted`, and all four task commits pass `git show --check`.
- Baseline-to-implementation inspection contains exactly the six declared production/test paths, with no migration, dependency, route, schema, or new source.

## Next Phase Readiness

- Plan 80-06 can dispatch only from `%Forensics.Scope{}` and assemble workflow/incident evidence from `Audit.forensic_window/2` without `Audit.list_all/1` or post-load filtering.
- Cron and limiter source boundaries retain their existing fixed history limits, ready for the next plan's bounded four-family evidence assembly.

## Self-Check: PASSED

- All six declared implementation/test files exist and are committed.
- Red/green task commits `b493986`, `bb86617`, `c23587d`, and `91138cb` exist.
- The plan-level suite, both task suites, formatting, compilation, SQL-bound checks, and local EXPLAIN evidence pass.
- Scope and Selectors contain no repository, authorization, clock, rendering, inference, or mutation work.
- No Audit forensic path calls `list_all/1`, post-load `Enum.filter/2`, or issues an unbounded row query.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-28*
