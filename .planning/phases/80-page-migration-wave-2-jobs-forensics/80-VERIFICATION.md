---
phase: 80-page-migration-wave-2-jobs-forensics
verified: 2026-07-28T20:30:00-04:00
status: gaps_found
score: "63/73 must-haves fully verified"
must_haves_total: 73
must_haves_verified: 63
must_haves_partial_or_failed: 10
requirements_total: 12
requirements_satisfied: 9
requirements_partial: 2
requirements_failed: 1
review_findings:
  critical_open: 1
  warnings_open: 2
human_items: 1
next_action: "Fix CR-01, WR-01, and WR-02 with adversarial regressions, stabilize the 100 ms coordinator integration assertion, then re-run Phase 80 verification; capture VoiceOver transcripts on a Guidepup-configured macOS runner when available."
---

# Phase 80 Verification Report

**Phase goal:** Migrate the data-dense Jobs and Forensics surfaces onto the
shared filter, table, detail, confirmation, and timeline system without behavior
or safety regression.

**Result:** Gaps found. The page migration, shared component composition,
bounded ordinary reads, deterministic evidence matrix, and automated
accessibility/visual gates are substantially complete. The phase cannot pass
while a reproduced cross-workflow authorization/evidence flaw remains open.
Two additional runtime defects undermine the promised invalid-URL recovery and
stable frozen bulk-result contract.

This result does not attribute the five inherited full-repository failures to
Phase 80. It also keeps the real VoiceOver environment gap distinct from the
product defects.

## Goal Achievement

| Goal / success criterion | Status | Independent evidence |
|---|---|---|
| Jobs uses shared `FilterBar`, `DataTable`, `DetailSurface`, and confirmation patterns | VERIFIED | `JobsLive.page_content/1` calls the shared components at `jobs_live.ex:523`, `:656`, `:766`, `:817`, and `:1054`; presenters keep the rendered inputs finite. |
| Forensics uses a shared typed chooser and `Timeline` in one full-page composition | PARTIAL | The shared composition is present (`forensics_live.ex:188`, `:396`), but a workflow-step selector is not relationally validated and can combine authorized workflow A with Audit evidence for workflow B. |
| URL filter/search/deep-link behavior is safe and canonical | PARTIAL | Ordinary and malformed cases are covered, but a 50-digit positive `page` or `job` is accepted without an invalid notice and later reaches Postgrex. |
| Single and bulk Jobs mutations preserve Lifeline authority and truthful recovery | PARTIAL | Normal paths use Lifeline and per-target authorization. An outer stream timeout loses the frozen target position, which can create duplicate/missing positions and crash LiveView reconciliation after effects. |
| Adversarial page VRT and automated accessibility are green | VERIFIED | The retained locked run reports 1,392/1,392 compare-only page tests. Fresh validators independently found exactly 147 tracked ARIA YAML files and 588 tracked page PNG files. |
| No functional regression in bulk, authorization, and deep-link behavior | FAILED | CR-01, WR-01, and WR-02 are actual uncovered regressions at the phase's main authority and recovery boundaries. |

## Requirement Coverage

All requirement IDs and wildcard patterns named by the 13 plan frontmatters
were expanded against `.planning/REQUIREMENTS.md`. `DATA-*` expands to
DATA-01 through DATA-04; `A11Y-*` expands to A11Y-01 through A11Y-04.

| Requirement | Status | Evidence and remaining gap |
|---|---|---|
| PAGE-02 | PARTIAL | Jobs list/detail, filter, quick review, single action, and ordinary frozen-bulk paths are migrated. WR-01 permits oversized positive URL integers to crash database encoding; WR-02 can lose target identity and crash bulk result reconciliation after effects. |
| PAGE-09 | FAILED | The diagnosis-first Forensics page and bounded source windows exist, but CR-01 allows a workflow-A authorization to disclose workflow-B step Audit chronology. This violates the core Forensics authority contract. |
| FORM-03 | SATISFIED | Jobs and Forensics use submit-mode shared form primitives, retain invalid draft state separately, and serialize canonical applied state. |
| DATA-01 | SATISFIED | Shared `DataTable`, detail/data display, timeline, progress, and empty/unavailable components are used by production composition. |
| DATA-02 | SATISFIED | Jobs and Forensics use the shared finite status presentation rather than page-local status chrome. |
| DATA-03 | SATISFIED | The retained browser matrix covers 320px, 200% zoom, long values, explicit states, and bounded 20-row/50-event presentation. WR-01 remains recorded under PAGE-02 because it is a URL/database-boundary failure rather than a responsive presentation failure. |
| DATA-04 | SATISFIED | Closed presenters and shared redaction/data components replace raw page-local payload rendering. |
| PAGE-10 | SATISFIED | Both pages compose the same shared primitives and production page seams used by the showcase; exact manifest and artifact contracts prevent a parallel page system. |
| A11Y-01 | SATISFIED | Retained exact page gate: axe, acceptance, ARIA, and compare-only VRT passed 1,392/1,392; tracked artifact validators independently pass. |
| A11Y-02 | SATISFIED | Connected/browser evidence covers keyboard reachability, focus, modal behavior, target sizing, and one semantic tree; the tri-state and scrollable-dialog axe fixes are present. |
| A11Y-03 | SATISFIED | Four themes, three viewports, contrast modes, 320px/200% reflow, visible focus, and target geometry are represented in the locked matrix. |
| A11Y-04 | PARTIAL | Exact ARIA and interaction contracts exist, and VoiceOver discovery finds exactly seven production-composed cases. Real Jobs/Forensics transcripts remain open because Guidepup cannot mount VoiceOver preferences on this Mac. Plan 80-13 explicitly permits this supported-environment gap without substituting axe, so it is not the reason for `gaps_found`; milestone-level A11Y-04 evidence is still incomplete. |

## Must-Have Evidence by Plan

The 13 plans contain 73 truth-level must-haves. Sixty-three are fully
supported by code, tests, and retained evidence. Ten are partial or contradicted
because the three runtime defects and current test reliability gap cut across
their repeated closure claims.

| Plan | Verification result |
|---|---|
| 80-01 | Bounded ordinary Jobs queries, predicate reuse, ordering, canonical key allowlists, and draft separation are present. The claim that every invalid direct URL is removed before querying is false for arbitrary-size positive integers. |
| 80-02 | Shared Jobs browse/filter/table/review composition and exact-count pagination are present. Its safe direct-URL claim inherits WR-01. |
| 80-03 | Closed detail presentation, uniform unavailable state, allowlisted return context, and Lifeline-owned single actions are present. |
| 80-04 | Limit validation, frozen scopes, supervised work, and ordinary partial-result recovery are present. Stable frozen ordering is false on an outer `async_stream_nolink` exit/timeout because `length(results)` is fabricated as the target position. |
| 80-05 | The six-key grammar, bounded Audit windows, stable ordering, and honest incident has-more truth are present. Syntactic scope validation does not establish the workflow/step/resource relationship. |
| 80-06 | Closed evidence bundles and presenters are present. A parsed scope is not necessarily authoritative: raw `resource_id` can select foreign Audit rows independently of the workflow and selected step. |
| 80-07 | The chooser, page order, one-tree timeline, and pure composition are present. A relationally invalid but syntactically valid workflow-step scope renders evidence instead of the uniform unavailable state. |
| 80-08 | The catalog has 49 production-composed page stories and 113 targets, with bounded 20-row Jobs and 50-event Forensics fixtures. |
| 80-09 | Schema-8 discovery and strict 147-ARIA/588-PNG validators are present and pass. |
| 80-10 | The Phase 80 host fixture seam is test-only, opt-in, secret-protected, and route-off tested according to source and retained evidence. |
| 80-11 | Real connected routes and the combined Wave 1/2 harness are present. The broad claim that browser tests prove all authorization races, URL bounds, and timeout ordering is overbroad because the three reproduced adversarial cases are absent. |
| 80-12 | Root-scoped token ownership, deterministic packaged assets, exact artifact inventory, original-resolution review, axe, ARIA, and compare-only evidence are supported. |
| 80-13 | Exact closure counts and the seven-case VoiceOver contract are present. Claims that every authority/regression contract is covered and that no high-severity threat remains are false. The literal full-ExUnit-green claim is also not current: five inherited repository failures are documented, and the focused coordinator integration test reproduced a separate 100 ms timing failure during this verification. |

## Blocking and Warning Gaps

### CR-01 — Cross-workflow Audit evidence bypass

**Severity:** Critical / blocking  
**Requirements:** PAGE-09, PAGE-10; Phase decisions D-61, D-67, D-68, D-77,
D-88

The review finding is valid:

- `Scope.workflow/1` accepts any nonblank `workflow_step` `resource_id` and
  `step`; it checks no database relationship
  (`forensics/scope.ex:126-146`).
- `Forensics.workflow_bundle/2` loads workflow A by `workflow_id` and chooses a
  step by name from workflow A, but passes the original scope to
  `Audit.forensic_window/2` (`forensics.ex:79-100`).
- `Audit.forensic_window/2` queries the raw `resource_type/resource_id`
  independently (`audit.ex:346-375`).
- the LiveView authorization resource contains only the workflow kind and
  `workflow_id` (`forensics_live.ex:661-675`).

A direct parser probe independently confirmed that
`workflow_id=workflow-A`, `step=step-name-from-A`, and
`resource_id=step-from-workflow-B` is accepted as `{:ok, %Scope{}}`. The code
then has no relational guard before the foreign Audit lookup. This can disclose
foreign event existence, actor, action, status, and timing while presenting a
false combined diagnosis.

**Required closure:** Resolve the step with one query constrained by
`step.id`, `step.workflow_id`, and `step.step_name`; derive the Audit identity
from that validated record; return the byte-equivalent unavailable state before
Audit access when it does not match; add a two-workflow authorization
regression.

### WR-01 — Oversized positive Jobs URL integers reach Postgrex

**Severity:** Warning / product reliability and denial-of-service risk  
**Requirement:** PAGE-02

`JobsParams.parse_positive_integer/2` accepts every positive Erlang integer
(`jobs_params.ex:206-218`). `Jobs.list/3` multiplies the page into an offset and
`Jobs.get/2` passes the job ID to Repo (`jobs.ex:95-102`, `:170-172`).

An independent runtime probe accepted 50-digit page and job values and returned
no invalid notice:

```text
page=99999999999999999999999999999999999999999999999999
job=88888888888888888888888888888888888888888888888888
notices=[]
```

After canonical replacement, the same values become applied state and reach
Postgrex, which only encodes signed 64-bit integers.

**Required closure:** Add distinct bounded page/job parsers, canonicalize
oversized values before any Repo call, and add direct connected regressions for
both parameters.

### WR-02 — Outer batch exit loses frozen target identity

**Severity:** Warning / post-effect recovery integrity  
**Requirement:** PAGE-02

`execute_targets/9` uses unordered `Task.Supervisor.async_stream_nolink/6`.
For `{:exit, reason}`, it assigns `length(results)` as the position
(`batch_coordinator.ex:415-438`). Completion count is not frozen position.
Later positions may already have completed, so results can contain duplicate
positions and omit the timed-out one. `JobsLive.finalize_bulk_execution/2`
turns results into a position map and uses `Map.fetch!/2` for every ready
preview position (`jobs_live.ex:1611-1623`), which raises when a position is
missing.

This confirms the review's `[0, 2, 2]` reproduction is consistent with the
actual reducer and reconciliation code.

**Required closure:** Preserve the original target identity for every stream
terminal result, validate an exact unique position set before reconciliation,
fail closed instead of `Map.fetch!/2`, and add an outer-authorization-timeout
regression where later positions finish first.

### V-TEST-01 — Coordinator integration assertion is timing-sensitive

**Severity:** Verification warning  
**Requirement:** PAGE-02

The owning three-file test command completed with `47 tests, 1 failure`.
The failing test was
`real Lifeline preview and execution run once per target with independent Audit evidence`
at `batch_coordinator_test.exs:400`; its implicit 100 ms
`assert_receive` expired before the supervised database-backed preview
completed. An immediate isolated rerun reproduced `1 test, 1 failure`, after
which the sandbox owner exited while preview tasks still held connections.

This does not erase the retained earlier 901/901 lane, but it means the
"all focused files green" claim is not repeatable under the current runtime.
Use a bounded explicit timeout appropriate for the integration path and prove
the complete owning suite repeatedly.

## Evidence That Remains Valid

- Retained final scoped ExUnit lane: 901 tests, 0 failures, 7 host-contract
  exclusions.
- Retained exact page gate: 1,392/1,392 passed in compare-only mode.
- Schema-8 contract: 49 page stories, 113 targets, four themes, three
  viewports.
- Fresh exact artifact validation: 147 tracked ARIA YAML files and 588 tracked
  page PNG files; both validators pass.
- Fresh VoiceOver discovery: exactly seven production-composed tests.
- Shared production composition is real: Jobs calls FilterBar, DataTable,
  DetailSurface, and confirmation components; Forensics calls FilterBar and
  Timeline.
- The full repository diagnostic's five failures remain inherited dirty CI and
  example-host contract drift. They are not evidence for CR-01, WR-01, or
  WR-02 and are not counted as Phase 80 product gaps.

## Human / Supported-Environment Item

| Item | Classification | Closure |
|---|---|---|
| Real VoiceOver transcripts for Jobs full detail and Forensics partial incident remediation | Supported-environment gap; not a substitute-able automated pass | Run the exact seven-story suite on macOS after `@guidepup/setup` can mount VoiceOver preferences. Preserve transcript and cursor attachments. |

If the three product defects were closed, Phase 80's explicit Plan 80-13
allowance would permit automated phase acceptance with this environment item
documented, while A11Y-04 remains visibly partial until the real transcripts
are captured. The current `gaps_found` status is instead compelled by CR-01 and
the two runtime warnings.

## Planning-State Note

`80-13-SUMMARY.md` exists and `.planning/STATE.md` says Plan 13 is complete,
while `ROADMAP.md` still says `12/13` and leaves `80-13-PLAN.md` unchecked.
That bookkeeping mismatch should be reconciled only after the blocking product
gaps are fixed and verification passes.

## Next Action

Fix CR-01 first, then WR-01 and WR-02, add the adversarial tests described
above, stabilize the coordinator integration assertion, and rerun the focused
Elixir lane plus the exact compare-only page gate. Re-verify Phase 80 before
marking PAGE-02, PAGE-09, or the phase complete.

---

_Verified: 2026-07-28_  
_Verifier: Codex independent phase verifier_
