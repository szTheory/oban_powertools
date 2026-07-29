---
phase: 80-page-migration-wave-2-jobs-forensics
reviewed: 2026-07-29T04:21:14Z
depth: standard
files_reviewed: 54
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 80: Code Review Report

**Reviewed:** 2026-07-29T04:21:14Z  
**Depth:** standard  
**Files reviewed:** 54  
**Status:** issues_found

## Summary

The Phase 80 gap-closure work correctly closes the earlier cross-workflow
Forensics disclosure, oversized Jobs list/quick-review parameters, and frozen
batch-result identity defects. Workflow-step evidence is now resolved with one
relational predicate before Audit access, batch terminal results retain their
frozen positions, and Jobs list pagination plus quick-review IDs are bounded to
their PostgreSQL bindings.

One warning remains in the current Phase 80 surface: the canonical full Jobs
detail route uses a separate unbounded integer parser, so an oversized path ID
can still reach `Repo.get/2` and fail Postgrex encoding. No new security,
privacy, concurrency, accessibility, or disclosure-boundary defect was found in
the other reviewed files at standard depth.

The exact review scope was the 54 sorted paths in
`/tmp/gsd-phase80-review-files.txt`. Generated/static asset pairs were also
checked for byte equality. Existing project-wide residual test failures and the
VoiceOver environment limitation documented in `80-VERIFICATION.md` are
inherited/environmental and are not Phase 80 findings.

## Critical Issues

None.

## Warnings

### WR-01: Oversized full-detail path IDs still reach the database unbounded

**Files:** `lib/oban_powertools/web/jobs_live.ex:50-56,1094-1104,1940-1947`; `lib/oban_powertools/web/jobs_params.ex:25-26,208-224`  
**Coverage gap:** `test/oban_powertools/web/live/jobs_live_test.exs:111-128,502,698`; `test/oban_powertools/web/jobs_params_test.exs:103-143`

**Issue:** Phase 80 added signed-64-bit bounds for the Jobs list `page` and
quick-review `job` query parameters in `JobsParams`, but `/ops/jobs/jobs/:id`
does not use that parser. `normalize_detail_job_id/1` accepts every positive
Erlang integer, after which `load_job_detail/3` passes it to
`Jobs.get(repo(), normalized_id)`. A 50-digit path ID is therefore accepted by
the LiveView and bound as an `oban_jobs.id` query parameter even though
Postgrex's bigint encoder accepts only signed 64-bit values.

The existing oversized URL regression covers `?page=` and `?job=`. Detail-route
tests use a large but still signed-64-bit-safe missing ID (`999999999`), so they
do not exercise this path.

**Impact:** A request to the full detail route with an oversized decimal ID can
terminate the render with `DBConnection.EncodeError` instead of returning the
uniform unavailable state. Repeated requests provide a low-cost
application-level denial-of-service and noisy logging path.

**Fix:** Reuse a public bounded job-ID parser or apply the same
`9_223_372_036_854_775_807` upper bound in `normalize_detail_job_id/1` before
authorization or any Repo call. Add connected LiveView regressions for the
maximum accepted path ID and a 50-digit path ID, asserting the latter renders
the existing non-enumerating unavailable state without issuing an `oban_jobs`
query.

## Informational Notes

None.

## Previously Reported Findings

- **CR-01 (closed):** `Forensics.authoritative_workflow_scope/2` now validates
  `step.id`, `step.workflow_id`, and `step.step_name` together and rebuilds the
  Audit scope from the validated row.
- **WR-01 (partially closed):** list-page offsets and quick-review IDs are now
  signed-64-bit safe. The separate full-detail path parser is the remaining
  warning above.
- **WR-02 (closed):** ordered stream terminals are paired with their frozen
  targets, and LiveView reconciliation requires the exact unique ready-position
  set before joining results.

## Verification

- `mix test test/oban_powertools/web/jobs_params_test.exs test/oban_powertools/jobs/batch_coordinator_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` — 112 tests, 0 failures.
- `cmp` checks for `assets/oban_powertools/theme.js` versus its static copy and
  `assets/oban_powertools/tokens.css` versus its static copy — byte-identical.
- `git diff --check 7445f6c^..HEAD` over the exact 54-file scope — clean.
- The passed Phase 80 verification ledger remains valid for its stated gates;
  its documented inherited full-suite residuals and VoiceOver environment gap
  were not reclassified as Phase 80 defects.
