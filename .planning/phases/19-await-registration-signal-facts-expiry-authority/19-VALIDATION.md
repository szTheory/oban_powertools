---
phase: 19
slug: await-registration-signal-facts-expiry-authority
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix plus grep-based schema and planning-contract checks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/workflow_runtime_test.exs` |
| **Full suite command** | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` |
| **Estimated runtime** | ~20-35 seconds quick run, ~90-180 seconds wave-end targeted proof set because the archived upgrade lane rebuilds a host fixture |

---

## Sampling Rate

- **After every task commit:** Run the task-specific command from the verification map below.
- **After every plan wave:** Run the full suite command above.
- **Before `$gsd-verify-work`:** Runtime proof, coordinator proof, archived upgrade proof, and planning-contract greps must all be green.
- **Max feedback latency:** 180 seconds at wave end because the upgrade lane is intentionally heavier than normal runtime-only tests.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | `SIG-01` | `T-19-01` / `T-19-02` | `workflow_awaits` owns active wait truth while `workflow_steps` remains a thin diagnosis-facing mirror with explicit linkage back to the await row. | integration | `mix test test/oban_powertools/workflow_runtime_test.exs` | ✅ | ⬜ pending |
| 19-01-02 | 01 | 1 | `SIG-01` / `VER-02` | `T-19-02` / `T-19-03` | Canonical signal rows and schema migrations stay workflow-scoped, and the archived upgrade lane can preserve an in-flight waiting workflow through migration without semantic drift. | integration + migration integrity | `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof && rg -n "active_await_id|workflow_awaits|workflow_signals|resolved_signal_id|awaiting_signal_name|await_correlation_key|await_dedupe_key|await_deadline_at" lib/mix/tasks/oban_powertools.install.ex test/support/migrations/2_phase_3_tables.exs examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs` | ✅ | ⬜ pending |
| 19-02-01 | 02 | 2 | `SIG-02` | `T-19-04` | Signal ingress persists canonical facts before wakeup and refuses speculative correlation-only consumption. | integration | `mix test test/oban_powertools/workflow_runtime_test.exs` | ✅ | ⬜ pending |
| 19-02-02 | 02 | 2 | `SIG-02` / `VER-01` | `T-19-05` / `T-19-06` | Duplicate, replay, ambiguous, and lost-wakeup paths preserve durable evidence and remain correct from rows alone. | integration + coordinator | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs && rg -n "duplicate|replay|ambiguous|unmatched|already_consumed|deliver_signal|await_step" test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs` | ✅ | ⬜ pending |
| 19-03-01 | 03 | 3 | `SIG-03` / `VER-01` | `T-19-07` / `T-19-08` | Only the shared reconcile path finalizes expiry, and repeated reconcile or missing advisory wakeups do not alter the durable outcome. | integration + coordinator | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs` | ✅ | ⬜ pending |
| 19-03-02 | 03 | 3 | `VER-01` / `VER-02` | `T-19-08` / `T-19-09` | Runtime proof, archived upgrade proof, and planning truth all align on the narrow workflow-scoped await/signal/expiry contract. | integration + upgrade proof + planning grep | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs && mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof && rg -n "SIG-01|SIG-02|SIG-03|VER-01|VER-02|workflow-scoped|late|expired_wait|Postgres" .planning/REQUIREMENTS.md .planning/PROJECT.md test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md` exists.
- [x] `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-RESEARCH.md` exists.
- [x] `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-PATTERNS.md` exists.
- [x] `test/oban_powertools/workflow_runtime_test.exs` already contains the main await/signal and expiry proof lanes to extend.
- [x] `test/oban_powertools/workflow_coordinator_test.exs` already exists for lost-wakeup and advisory-signal correctness checks.
- [x] `test/oban_powertools/example_host_contract_test.exs` and `test/support/example_host_contract.ex` already provide the supported archived upgrade lane to extend.
- [x] Installer, example-host, archived upgrade-source, and test-support workflow migrations already exist as the schema-contract surfaces to update in lockstep.

---

## Manual-Only Verifications

- Read the final wait and signal status vocabulary after execution to confirm it stays bounded, workflow-scoped, and support-truthful rather than implying a generic event bus.
- Read the archived upgrade-proof assertions after execution to confirm they prove migrated waiting rows are explainable and reconcilable, not merely that the host compiles.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all required input artifacts
- [x] No watch-mode flags
- [x] Task-level feedback latency < 240s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
