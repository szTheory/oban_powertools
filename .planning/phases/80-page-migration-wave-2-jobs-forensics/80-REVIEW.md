---
phase: 80-page-migration-wave-2-jobs-forensics
reviewed: 2026-07-29T00:18:43Z
depth: standard
files_reviewed: 67
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 80: Code Review Report

**Reviewed:** 2026-07-29T00:18:43Z  
**Depth:** standard  
**Files reviewed:** 67  
**Status:** issues_found

## Summary

Phase 80's bounded Jobs reads, closed presentation maps, Lifeline-owned mutation
flow, deterministic story/artifact tooling, and bounded Forensics evidence
assembly are generally well structured. The review nevertheless found one
blocking authorization defect: a workflow-scoped Forensics URL can select Audit
evidence belonging to a step in another workflow, while authorization checks
only the URL's workflow ID. Two warnings cover unbounded positive URL integers
that reach Postgrex and an outer batch-task timeout path that loses the frozen
target position and can crash result reconciliation after effects have run.

The exact review scope was the 66 Phase 80 production, host-fixture, browser,
asset, script, and test files outside generated PNG/YAML evidence plus
`80-VALIDATION.md`, for 67 files total. The generated evidence was checked
through its manifest and exact-inventory contracts. A fresh focused run of the
three owning test files passed 47 tests with zero failures. Separate isolated
runtime probes reproduced the cross-workflow evidence mix, Postgrex integer
encoding failure, and duplicate batch positions. The ledger's retained
901/901 focused and 1,392/1,392 browser results remain useful evidence, but the
missing adversarial cases below explain why those green gates did not detect
the findings. The five documented inherited full-suite failures and the
Guidepup/VoiceOver environment gap are not reported as Phase 80 defects.

## Critical Issues

### CR-01: Workflow authorization can be combined with Audit evidence from a different workflow

**Files:** `lib/oban_powertools/forensics/scope.ex:126-146`; `lib/oban_powertools/forensics.ex:79-100,130-143`; `lib/oban_powertools/audit.ex:346-375`; `lib/oban_powertools/web/forensics_live.ex:661-675`  
**Coverage gap:** `test/oban_powertools/forensics_test.exs:108-141,233-285`

**Issue:** The `workflow_step` grammar requires non-empty `resource_id`,
`workflow_id`, and `step`, but never proves that the resource ID identifies that
named step in that workflow. `Forensics.workflow_bundle/2` loads and explains
the workflow named by `workflow_id`; independently, `Audit.forensic_window/2`
queries the raw `resource_type` and `resource_id` from the URL. The LiveView
authorization check covers only `%{type: :workflow, id: workflow_id}`.

Consequently, an actor authorized for workflow A can submit workflow A's ID and
valid step name together with the UUID of a step in workflow B. The resulting
bundle combines workflow A's diagnosis with workflow B's Audit chronology and
uses the foreign step UUID as the subject resource ID, without authorizing
workflow B.

This was reproduced against the test repository in a sandbox transaction: a
scope containing workflow A, A's `sync_billing` step name, and workflow B's
`sync_support` step UUID returned `selected_step: "sync_billing"` while both
`subject.resource_id` and the Audit chronology resource ID were workflow B's
step UUID. Existing “consistent pair” tests prove only the selector shape and
use a synthetic step ID; they do not validate the database relationship.

**Impact:** A resource-specific authorization policy can be bypassed to disclose
the existence, action type, status, actor, and timing of Audit evidence for a
workflow step outside the authorized workflow. The page also presents a false
cross-resource diagnosis.

**Fix:** Resolve a `workflow_step` selector with one query constrained by all
three identities: `step.id == resource_id`, `step.workflow_id == workflow_id`,
and `step.step_name == step`. Return the uniform unavailable result before the
Audit read when that exact relationship is absent. Derive the Audit identity
from the validated record rather than from raw selectors, and add a regression
with two workflows proving that a foreign step UUID causes zero foreign Audit
rows to be returned. If hosts may authorize steps more narrowly than their
parent workflow, authorize the validated step resource as well.

## Warnings

### WR-01: Arbitrary-size positive URL integers can crash Jobs reads in Postgrex

**Files:** `lib/oban_powertools/web/jobs_params.ex:37-81,206-218`; `lib/oban_powertools/jobs.ex:95-102`; `lib/oban_powertools/web/jobs_live.ex:59-82,2033-2047,2073-2080`  
**Coverage gap:** `test/oban_powertools/web/jobs_params_test.exs:82-100`; `test/browser/specs/page-migration-wave-2.spec.ts:413-417`

**Issue:** `parse_positive_integer/2` accepts any positive Erlang integer for
both `page` and `job`. A decimal value larger than PostgreSQL's signed 64-bit
range remains canonical, so `handle_params/3` does not remove it before
`Jobs.list/3` calculates an even larger offset or `Jobs.get/2` binds it as a job
ID.

A direct probe with a 50-digit `page` value produced
`DBConnection.EncodeError`: Postgrex rejected the calculated offset because it
was outside `-9223372036854775808..9223372036854775807`. The same parser is used
for the `job` ID. Existing tests cover malformed and large-but-int64-safe values,
not numeric overflow.

**Impact:** An unauthenticated or low-privilege request can terminate the
connected Jobs render instead of receiving the documented canonical invalid-URL
recovery. Repeated requests provide a cheap application-level denial-of-service
path and noisy error logging.

**Fix:** Give `page` and `job` separate bounded parsers. Reject job IDs above the
database ID range and page numbers whose `(page - 1) * 20` offset cannot be
encoded safely (or apply a smaller explicit product bound). Canonicalize rejected
values before any Repo call and add direct LiveView regressions for oversized
`page` and `job` strings.

### WR-02: Outer batch-task exits fabricate a position and can crash post-effect reconciliation

**Files:** `lib/oban_powertools/jobs/batch_coordinator.ex:402-455,466-488`; `lib/oban_powertools/web/jobs_live.ex:1611-1637`  
**Coverage gap:** `test/oban_powertools/jobs/batch_coordinator_test.exs:276-333`

**Issue:** Execution uses unordered `Task.Supervisor.async_stream_nolink/6`.
When an outer task exits or is killed by the stream timeout, the reducer assigns
`length(results)` as its frozen position. Completion order is unrelated to
frozen position, and ready positions may also be non-contiguous when preview
excluded earlier targets. The existing crash test exits only inside the nested
target call, where `target.position` is still available; it does not exercise an
outer stream exit such as a stalled authorization callback.

A focused probe stalled authorization for frozen position 1 while positions 0
and 2 completed. The coordinator returned three outcomes with positions
`[0, 2, 2]`. `JobsLive` then builds a map by position and calls `Map.fetch!/2`
for every ready preview result, so position 1 is absent and result
reconciliation raises after two target effects have already succeeded.

**Impact:** A slow or killed per-target authorization path can turn an accepted
partially completed batch into a LiveView crash, lose truthful per-target
reporting, and make recovery/retry decisions unreliable.

**Fix:** Ensure every terminal result carries the original frozen position.
Apply the timeout to the entire per-target operation, including authorization,
inside a wrapper that returns `safe_execution_result(target.position, ...)`, or
manage tasks with an explicit ref-to-target map so killed tasks retain identity.
Make final reconciliation validate an exact unique position set and fail closed
with an explanatory batch result rather than `Map.fetch!/2`. Add a regression
where an outer task times out after later positions finish and assert exact
unique frozen positions plus a non-crashing Jobs result surface.

## Informational Notes

None.

## Verification

- `mix test test/oban_powertools/web/jobs_params_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/jobs/batch_coordinator_test.exs --seed 0` — 47 tests, 0 failures.
- Oversized Jobs page probe — reproduced `DBConnection.EncodeError` for a 50-digit positive page accepted by `JobsParams.parse_url/1`.
- Cross-scope Forensics probe — reproduced workflow A diagnosis combined with workflow B step Audit evidence.
- Outer batch-timeout probe — reproduced returned positions `[0, 2, 2]` for frozen positions `[0, 1, 2]`.
- `80-VALIDATION.md` retained evidence — 901 focused tests and 1,392 browser tests green; five inherited full-suite failures and the VoiceOver host setup gap remain excluded from these findings.
