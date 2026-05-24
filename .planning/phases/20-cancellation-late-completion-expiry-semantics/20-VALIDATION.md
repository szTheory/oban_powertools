---
phase: 20
slug: cancellation-late-completion-expiry-semantics
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 20 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix plus grep-based schema and planning-contract checks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/workflow_runtime_test.exs` |
| **Full suite command** | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` |
| **Estimated runtime** | ~20-40 seconds quick run, ~90-180 seconds wave-end targeted proof set when the archived upgrade lane is included |

---

## Sampling Rate

- **After every task commit:** Run the task-specific command from the verification map below.
- **After every plan wave:** Run the full suite command above.
- **Before `$gsd-verify-work`:** Runtime proof, coordinator proof, explain proof, archived upgrade proof, and planning-contract greps must all be green.
- **Max feedback latency:** 180 seconds at wave end because the archived host proof lane remains the slowest targeted check.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01-01 | 01 | 1 | `REC-03` / `SIG-03` | `T-20-01` / `T-20-02` | One canonical reducer distinguishes cancel request evidence from final workflow and step truth. | integration | `mix test test/oban_powertools/workflow_runtime_test.exs` | ✅ | ⬜ pending |
| 20-01-02 | 01 | 1 | `SIG-03` / `VER-02` | `T-20-02` / `T-20-03` | Bounded cause and late-evidence vocabulary lands in runtime schemas and every supported migration path without support-truth drift. | integration + migration integrity | `mix test test/oban_powertools/workflow_runtime_test.exs && rg -n "cancel_requested_at|completed_after_cancel_request|expired_wait|late|operator_cancelled|terminal_cause" lib/mix/tasks/oban_powertools.install.ex test/support/migrations/2_phase_3_tables.exs examples/phoenix_host/priv/repo/migrations examples/phoenix_host_upgrade_source/priv/repo/migrations` | ✅ | ⬜ pending |
| 20-02-01 | 02 | 2 | `REC-03` / `SIG-03` | `T-20-04` / `T-20-05` | Idle work cancels eagerly, in-flight work settles cooperatively, and downstream scheduling stays suppressed after cancel request unless already durably entitled. | integration | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs` | ✅ | ⬜ pending |
| 20-02-02 | 02 | 2 | `DIA-01` / `VER-01` | `T-20-05` / `T-20-06` | Diagnosis helpers and terminal callbacks present final truth before request evidence and preserve late-arrival stories supportably. | integration + explain | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/explain_test.exs && rg -n "completed_after_cancel_request|cancel_requested|expired_wait|workflow\\.terminal|terminal_cause" test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/explain_test.exs lib/oban_powertools/workflow/runtime.ex lib/oban_powertools/explain.ex` | ✅ | ⬜ pending |
| 20-03-01 | 03 | 3 | `VER-01` | `T-20-07` / `T-20-08` | Focused proof covers cancel-versus-complete, cancel-versus-failure, cancel-versus-expiry, late signals after expiry or cancellation, and row-only reconciliation under advisory wakeup loss. | integration + coordinator | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/explain_test.exs` | ✅ | ⬜ pending |
| 20-03-02 | 03 | 3 | `VER-02` / `DIA-01` | `T-20-08` / `T-20-09` | Archived upgrade proof preserves at least one cancel-requested or cancelling workflow and planning artifacts claim only semantics the repo now proves. | upgrade proof + planning grep | `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof && rg -n "REC-03|SIG-03|DIA-01|VER-01|VER-02|completed_after_cancel_request|expired_wait|late" .planning/REQUIREMENTS.md .planning/PROJECT.md test/support/example_host_contract.ex test/oban_powertools/example_host_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md` exists.
- [x] `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-RESEARCH.md` exists.
- [x] `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-PATTERNS.md` exists.
- [x] `lib/oban_powertools/workflow/runtime.ex` already contains the cancel, reconcile, expiry, callback, and diagnosis seams this phase hardens.
- [x] `test/oban_powertools/workflow_runtime_test.exs` already contains cancel-race, late-signal, and callback proof lanes to extend.
- [x] `test/oban_powertools/workflow_coordinator_test.exs` already exists for advisory wakeup and reconcile correctness checks.
- [x] `test/oban_powertools/example_host_contract_test.exs` and `test/support/example_host_contract.ex` already provide the archived upgrade lane to widen for cancel semantics.
- [x] Installer, example-host, archived upgrade-source, and test-support workflow migrations already exist as schema-contract surfaces if new bounded fields land.

---

## Manual-Only Verifications

- Read the final workflow and step diagnosis ordering after execution to confirm terminal truth outranks request evidence once a workflow or step is settled.
- Read the final callback payload shape and support docs to confirm they remain narrow, post-commit, and at-least-once rather than implying a generic event history.
- Read the archived upgrade assertions after execution to confirm they prove explainability for a cancel-requested workflow, not merely migration success.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all required input artifacts
- [x] No watch-mode flags
- [x] Task-level feedback latency < 240s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
