---
phase: 18-durable-callback-outbox-recovery-attempts
verified: 2026-05-24T12:04:27Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
---

# Phase 18: Durable Callback Outbox & Recovery Attempts Verification Report

**Phase Goal:** Harden workflow callbacks into a supportable durable outbox contract, add workflow-scoped recovery session grouping, and align support-truth language to the exact behavior the repo proves.
**Verified:** 2026-05-24T12:04:27Z
**Status:** passed
**Re-verification:** No — initial closure verification for the working-tree implementation

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Only two workflow-scoped callback events are exposed: `workflow.terminal` and `workflow.recovery_completed`. | ✓ VERIFIED | [callback_outbox.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/callback_outbox.ex:55) validates the allowed events and [callback_handler.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/callback_handler.ex:3) documents the same public seam. |
| 2 | Callback payloads are thin, versioned envelopes with stable callback identity and durable semantic fields. | ✓ VERIFIED | [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:1350) writes `callback_id`, `event`, `workflow_id`, `semantics_version`, `envelope_version`, and `occurred_at`; [workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:349) asserts the envelope. |
| 3 | Callback delivery is claimed durably with lease-safe ownership rather than a plain scan-and-send loop. | ✓ VERIFIED | [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:1511) claims rows with `FOR UPDATE SKIP LOCKED`, `claimed_at`, `claimed_by`, and `lease_expires_at`; [workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:387) verifies lease protection. |
| 4 | Callback delivery failures do not rewrite workflow terminal truth and remain retryable durable evidence. | ✓ VERIFIED | [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:739) records retry posture on failure and [workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:353) proves failure followed by later successful delivery. |
| 5 | Recovery stays step-oriented at the public API while durable workflow-scoped recovery sessions group append-only attempts. | ✓ VERIFIED | [workflow.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow.ex:93) preserves `recover_step/5`; [recovery_session.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/recovery_session.ex:1) and [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:646) add session headers and link attempts. |
| 6 | Diagnosis surfaces can distinguish callback posture from workflow terminal truth and reference the latest recovery session by durable identity. | ✓ VERIFIED | [explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:140) adds callback posture and latest recovery session, and [workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:136) renders both on the native workflow screen. |
| 7 | Repo, installer, test-support, and supported-host example migrations expose the same callback and recovery schema contract. | ✓ VERIFIED | [install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:512), [2_phase_3_tables.exs](/Users/jon/projects/oban_powertools/test/support/migrations/2_phase_3_tables.exs:221), and the two example-host workflow semantics migrations all define recovery sessions plus callback claim fields. |
| 8 | Planning truth and host-facing callback guidance now match the proven narrow, post-commit, at-least-once contract. | ✓ VERIFIED | [runtime_config.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex:67), [PROJECT.md](/Users/jon/projects/oban_powertools/.planning/PROJECT.md:84), and [REQUIREMENTS.md](/Users/jon/projects/oban_powertools/.planning/REQUIREMENTS.md:24) describe the same contract the tests now prove. |

**Score:** 8/8 truths verified

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused callback, explain, Lifeline, and workflow-screen proof bundle | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | `38 tests, 0 failures` | ✓ PASS |
| Contract grep for callback/recovery semantics across runtime, migrations, and planning truth | `rg -n "workflow_callback_handler|workflow\\.terminal|workflow\\.recovery_completed|post-commit|at-least-once|idempotent|recovery_session|claimed_at|claimed_by|lease_expires_at" ...` | expected matches found across runtime, migrations, tests, and planning files | ✓ PASS |

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| `REC-01` | ✓ SATISFIED | durable outbox claim path, retry evidence, and host seam guidance are wired and proven |
| `REC-02` | ✓ SATISFIED | grouped recovery sessions link append-only recovery attempts without widening the public API |
| `VER-02` | ✓ SATISFIED | installer, repo test-support, and supported-host migrations carry the same callback and recovery schema contract |
| `POL-04` | ✓ SATISFIED | runtime config, callback behavior docs, and planning truth now reflect only the narrow semantics the repo proves |

### Deviations And Risk Notes

- Phase 18 execution started from a dirty, partially implemented working tree. This verification pass confirms the resulting behavior and artifacts, but it does not reconstruct the atomic per-task commit history the normal executor protocol expects.
- The remaining open v1.2 workflow requirements are the await, signal, and expiry items (`SIG-01`, `SIG-02`, `SIG-03`), which were intentionally left untouched here.

### Gaps Summary

No Phase 18 callback or recovery-model gaps remain in the focused proof bundle. The remaining milestone work is outside this phase’s callback and grouped-recovery contract.

---

_Verified: 2026-05-24T12:04:27Z_  
_Verifier: Codex (inline execute-phase verification)_
