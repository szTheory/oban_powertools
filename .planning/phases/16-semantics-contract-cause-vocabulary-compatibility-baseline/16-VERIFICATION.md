---
phase: 16-semantics-contract-cause-vocabulary-compatibility-baseline
verified: 2026-05-23T20:47:35Z
status: passed
score: 5/5 truths verified
overrides_applied: 0
---

# Phase 16: Semantics Contract, Cause Vocabulary & Compatibility Baseline Verification Report

**Phase Goal:** Freeze one explicit workflow and step lifecycle contract, publish the pre-v1.2 compatibility posture, and keep diagnosis-facing surfaces on the same durable vocabulary.
**Verified:** 2026-05-23T20:47:35Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The repo exposes one explicit v2 lifecycle contract for workflow states, step states, and terminal causes. | ✓ VERIFIED | [lib/oban_powertools/workflow/runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:19) defines the lifecycle contract, semantics version, and terminal-cause vocabulary. |
| 2 | Workflow and step rows persist enough durable fields to explain cancel-requested, waiting, expired, cancelled, and completed-after-cancel states from row truth. | ✓ VERIFIED | [lib/oban_powertools/workflow/workflow.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/workflow.ex:13) and [lib/oban_powertools/workflow/step.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/step.ex:13) carry semantics version, terminal cause, wait identity, cancel timing, and last-transition timestamps. |
| 3 | Pre-v1.2 workflows follow an explicit compatibility path instead of being silently reinterpreted under v1.2 semantics. | ✓ VERIFIED | [lib/oban_powertools/workflow/runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:52), [.planning/PROJECT.md](/Users/jon/projects/oban_powertools/.planning/PROJECT.md:80), and [.planning/REQUIREMENTS.md](/Users/jon/projects/oban_powertools/.planning/REQUIREMENTS.md:11) all state the additive compatibility posture for historical rows. |
| 4 | Native workflow inspection and Lifeline stuck-workflow evidence use the same runtime-owned diagnosis vocabulary. | ✓ VERIFIED | [lib/oban_powertools/web/workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:120) and [lib/oban_powertools/lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:389) both call into runtime diagnosis helpers. |
| 5 | The lifecycle contract and compatibility posture are covered by automated proof, not only prose. | ✓ VERIFIED | [test/oban_powertools/workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:197) verifies the contract API and legacy compatibility profile; the targeted workflow, UI, and Lifeline test suite passed locally. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/oban_powertools/workflow/runtime.ex` | lifecycle contract and compatibility helpers | ✓ VERIFIED | Defines semantics version `2`, lifecycle vocabulary, terminal causes, and compatibility policy/profile helpers. |
| `lib/oban_powertools/workflow/workflow.ex` | durable workflow-level semantics fields | ✓ VERIFIED | Persists `semantics_version`, `terminal_cause`, cancel timing, and transition timing. |
| `lib/oban_powertools/workflow/step.ex` | durable step-level cause and wait fields | ✓ VERIFIED | Persists wait identity, terminal cause, cancel timing, and transition timing. |
| `lib/oban_powertools/lifeline.ex` | shared workflow diagnosis wording | ✓ VERIFIED | Workflow-stuck incidents use runtime diagnosis rather than a parallel label set. |
| `lib/oban_powertools/web/workflows_live.ex` | shared native workflow diagnosis wording | ✓ VERIFIED | Workflow and step detail panels show runtime diagnosis output directly. |
| `.planning/PROJECT.md` | milestone-level compatibility statement | ✓ VERIFIED | Declares semantics version `2` and the additive pre-v1.2 compatibility posture. |
| `.planning/REQUIREMENTS.md` | baseline + traceability update | ✓ VERIFIED | Adds the Phase 16 baseline and marks `WFS-01` / `WFS-03` ready for completion tracking. |
| `test/oban_powertools/workflow_runtime_test.exs` | lifecycle/compatibility proof | ✓ VERIFIED | Covers the contract vocabulary and the legacy-v1 compatibility profile. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/oban_powertools/workflow/runtime.ex` | `lib/oban_powertools/workflow/workflow.ex` | semantics version and workflow terminal cause | ✓ WIRED | Runtime derives contract meaning from durable workflow fields instead of transient coordinator state. |
| `lib/oban_powertools/workflow/runtime.ex` | `lib/oban_powertools/workflow/step.ex` | wait identity, blocker, and step terminal cause semantics | ✓ WIRED | Runtime diagnosis and reconciliation consume the same persisted step fields they explain. |
| `lib/oban_powertools/workflow/runtime.ex` | `lib/oban_powertools/web/workflows_live.ex` | workflow/step diagnosis helpers | ✓ WIRED | UI calls `Runtime.workflow_diagnosis/2` and `Runtime.step_diagnosis/1` directly. |
| `lib/oban_powertools/workflow/runtime.ex` | `lib/oban_powertools/lifeline.ex` | workflow-stuck diagnosis wording | ✓ WIRED | Lifeline incident summaries reuse `Runtime.step_diagnosis/1` rather than inventing separate blocked wording. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Repo compiles with the frozen semantics contract | `mix compile` | passed | ✓ PASS |
| Workflow runtime, coordinator, workflow UI, and Lifeline proof suite | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/lifeline_test.exs` | `30 tests, 0 failures` | ✓ PASS |
| Contract and compatibility language is present in code/docs | `rg -n "semantics version|compatibility|pre-v1.2|historical rows|terminal cause" .planning/PROJECT.md .planning/REQUIREMENTS.md lib/oban_powertools/workflow/runtime.ex lib/oban_powertools/workflow/workflow.ex` | matched runtime and planning artifacts | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `WFS-01` | `16-01` | One explicit workflow and step lifecycle contract with durable terminal causes. | ✓ SATISFIED | Runtime lifecycle contract and durable row fields in [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:19), [workflow.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/workflow.ex:13), and [step.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/step.ex:13). |
| `WFS-03` | `16-01` | Pre-v1.2 rows reconcile under a documented compatibility strategy without silent meaning drift. | ✓ SATISFIED | Compatibility policy in [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:52), plus the matching milestone/requirements language in [.planning/PROJECT.md](/Users/jon/projects/oban_powertools/.planning/PROJECT.md:80) and [.planning/REQUIREMENTS.md](/Users/jon/projects/oban_powertools/.planning/REQUIREMENTS.md:11). |

### Gaps Summary

No execution gaps were found for Phase 16 plan 01. `WFS-02` remains a later v1.2 follow-on concern and was not claimed complete by this phase plan.

---

_Verified: 2026-05-23T20:47:35Z_  
_Verifier: Codex inline verification_
