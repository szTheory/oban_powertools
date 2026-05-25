---
phase: 23
slug: verification-upgrade-proof-telemetry-support-truth-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 23 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix plus grep-based planning-contract and docs/CI contract checks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/workflow_compatibility_test.exs` |
| **Full suite command** | `mix test test/oban_powertools/workflow_runtime_transitions_test.exs test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/workflow_compatibility_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` |
| **Estimated runtime** | ~30-60 seconds quick run, ~120-240 seconds for the full targeted proof set because the upgrade lane rebuilds a host fixture |

---

## Sampling Rate

- **After every task commit:** Run the task-specific command from the verification map below.
- **After every plan wave:** Run the full suite command above.
- **Before `$gsd-verify-work`:** Focused runtime proof, repo-local compatibility proof, supported upgrade proof, telemetry contract, docs contract, and CI lane naming checks must all be green.
- **Max feedback latency:** 240 seconds at wave end because `upgrade-proof` is the slowest targeted check.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 23-01-01 | 01 | 1 | `VER-01` | `T-23-01` / `T-23-02` | Duplicate, late, dropped, ambiguous, and race-path workflow evidence remains durable and proven in the focused runtime suites. | integration | `mix test test/oban_powertools/workflow_runtime_transitions_test.exs test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/workflow_coordinator_test.exs` | ✅ | ⬜ pending |
| 23-01-02 | 01 | 1 | `VER-02` | `T-23-02` / `T-23-03` | Waiting, retrying, cancelling, and recovering historical workflow meaning stays explainable in repo-local compatibility proof without widening the supported host lane. | integration + compatibility | `mix test test/oban_powertools/workflow_compatibility_test.exs test/oban_powertools/workflow_runtime_commands_test.exs && rg -n "compatibility|legacy|cancel_requested|recovery|waiting_on_signal" test/oban_powertools/workflow_compatibility_test.exs test/oban_powertools/workflow_runtime_commands_test.exs guides/upgrade-and-compatibility.md README.md` | ✅ | ⬜ pending |
| 23-02-01 | 02 | 2 | `VER-02` | `T-23-04` / `T-23-05` | The supported upgrade lane stays singular and proves only the documented host updates plus one sentinel waiting-workflow continuity case. | host acceptance | `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof && rg -n "upgrade-proof|workflow-compatibility|supported|tested" .github/workflows/host-contract-proof.yml guides/upgrade-and-compatibility.md README.md test/support/example_host_contract.ex test/oban_powertools/example_host_contract_test.exs` | ✅ | ⬜ pending |
| 23-02-02 | 02 | 2 | `POL-04` / `VER-02` | `T-23-05` / `T-23-06` | CI lane names, fixture helpers, and guide wording do not imply a covert host compatibility matrix broader than the locked support posture. | CI + docs grep | `rg -n "supported|tested|best-effort|workflow-compatibility|upgrade-proof" .github/workflows/host-contract-proof.yml README.md guides/upgrade-and-compatibility.md guides/support-truth-and-ownership-boundaries.md` | ✅ | ⬜ pending |
| 23-03-01 | 03 | 3 | `POL-04` | `T-23-07` / `T-23-08` | Public workflow telemetry remains under one bounded family with event-specific low-cardinality metadata and no leaked IDs or free-form detail. | contract + integration | `mix test test/oban_powertools/telemetry_test.exs && rg -n "workflow|semantics_version|terminal_cause|scope|state|outcome" lib/oban_powertools/telemetry.ex lib/oban_powertools/workflow/runtime.ex test/oban_powertools/telemetry_test.exs` | ✅ | ⬜ pending |
| 23-03-02 | 03 | 3 | `POL-04` / `VER-01` / `VER-02` | `T-23-08` / `T-23-09` | README, guides, exact docs block, and docs-contract tests describe only semantics and support claims the repo now proves. | docs contract | `mix test test/oban_powertools/docs_contract_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof && rg -n "workflow-semantics-contract|supported|tested|best-effort|intentionally unsupported|\\[:oban_powertools, :workflow, \\*\\]" README.md guides/workflows.md guides/upgrade-and-compatibility.md guides/production-hardening.md test/oban_powertools/docs_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-CONTEXT.md` exists.
- [x] `.planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-RESEARCH.md` exists.
- [x] `.planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-PATTERNS.md` exists.
- [x] Focused workflow runtime suites already exist in `test/oban_powertools/workflow_runtime_transitions_test.exs`, `workflow_runtime_signals_test.exs`, `workflow_runtime_commands_test.exs`, and `workflow_callbacks_test.exs`.
- [x] Repo-local historical continuity proof already exists in `test/oban_powertools/workflow_compatibility_test.exs`.
- [x] Supported host upgrade proof already exists in `test/oban_powertools/example_host_contract_test.exs`, `test/support/example_host_contract.ex`, and `.github/workflows/host-contract-proof.yml`.
- [x] Public telemetry contract seams already exist in `lib/oban_powertools/telemetry.ex` and `test/oban_powertools/telemetry_test.exs`.
- [x] Docs-contract enforcement already exists in `test/oban_powertools/docs_contract_test.exs` and `guides/workflows.md`.

---

## Manual-Only Verifications

- Read the final support-truth wording in README and upgrade docs to confirm the supported host lane still feels singular and explicit.
- Read the final workflow telemetry contract after execution to confirm event names tell request/evidence/outcome stories without turning telemetry into a second semantic engine.
- Read the final docs block in `guides/workflows.md` to confirm it stays short, exact, and directly traceable to runtime proof.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all required input artifacts
- [x] No watch-mode flags
- [x] Task-level feedback latency < 240s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
