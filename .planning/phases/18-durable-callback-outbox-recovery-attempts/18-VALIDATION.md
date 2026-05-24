---
phase: 18
slug: durable-callback-outbox-recovery-attempts
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix plus grep-based contract and migration checks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/workflow_runtime_test.exs` |
| **Full suite command** | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs` |
| **Estimated runtime** | ~20-30 seconds quick run, ~45-75 seconds wave-end targeted proof set |

---

## Sampling Rate

- **After every task commit:** Run the task-specific command from the verification map below.
- **After every plan wave:** Run the full suite command above.
- **Before `$gsd-verify-work`:** The targeted proof set and migration/contract checks must be green.
- **Max feedback latency:** 75 seconds at wave end.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-01-01 | 01 | 1 | `REC-01` | `T-18-01` / `T-18-02` | Callback rows have stable event identity, bounded delivery state, and durable lease-safe claim semantics. | unit + integration | `mix test test/oban_powertools/workflow_runtime_test.exs` | ✅ | ⬜ pending |
| 18-01-02 | 01 | 1 | `REC-01` / `VER-02` | `T-18-03` | Installer, test-support, and example-host migrations all expose the same callback-outbox delivery fields and indexes. | grep + migration integrity | `rg -n "callback_outbox|claimed_at|claim|available_at|attempts|last_error" lib/mix/tasks/oban_powertools.install.ex test/support/migrations examples/phoenix_host/priv/repo/migrations examples/phoenix_host_upgrade_source/priv/repo/migrations` | ✅ | ⬜ pending |
| 18-02-01 | 02 | 2 | `REC-02` | `T-18-04` / `T-18-05` | Recovery session headers group operator/runtime intent while each step attempt remains append-only durable truth. | unit + integration | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/lifeline_test.exs` | ✅ | ⬜ pending |
| 18-02-02 | 02 | 2 | `REC-01` / `POL-04` | `T-18-06` | Callback envelopes stay thin and versioned, and the host seam continues to require idempotent handler behavior rather than exactly-once assumptions. | unit + grep | `mix test test/oban_powertools/workflow_runtime_test.exs && rg -n "workflow_callback_handler|idempotent|at-least-once|workflow\\.terminal|workflow\\.recovery_completed" lib test guides README.md .planning` | ✅ | ⬜ pending |
| 18-03-01 | 03 | 3 | `REC-01` / `POL-04` | `T-18-07` / `T-18-08` | Retry, duplicate-claim, handler-failure, and post-commit workflow-truth semantics remain support-truthful under focused tests. | integration | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ✅ | ⬜ pending |
| 18-03-02 | 03 | 3 | `POL-04` / `VER-02` | `T-18-08` / `T-18-09` | Planning/docs/config artifacts state only the narrow two-event, thin-envelope, post-commit, at-least-once contract. | grep + docs contract | `rg -n "two workflow-scoped callback events|workflow\\.terminal|workflow\\.recovery_completed|post-commit|at-least-once|idempotent|non-goal|recovery session" .planning/REQUIREMENTS.md .planning/PROJECT.md .planning/phases/18-durable-callback-outbox-recovery-attempts lib/oban_powertools/runtime_config.ex lib/oban_powertools/workflow/callback_handler.ex` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md` exists.
- [x] `.planning/phases/18-durable-callback-outbox-recovery-attempts/18-RESEARCH.md` exists.
- [x] `test/oban_powertools/workflow_runtime_test.exs` already contains callback and recovery proof lanes to extend.
- [x] `lib/oban_powertools/workflow/callback_outbox.ex`, `lib/oban_powertools/workflow/recovery_attempt.ex`, and `lib/oban_powertools/runtime_config.ex` already define the main runtime seams.
- [x] Installer, example-host, and test-support workflow migrations already exist as the schema contract surfaces to update in lockstep.

---

## Manual-Only Verifications

- Read the final callback envelope contract after execution to confirm it contains only durable identifiers and narrow semantic fields, not rich snapshots or host payloads.
- Read the final recovery-session model to confirm workflow-level grouping does not replace or obscure per-step recovery attempt truth.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all required input artifacts
- [x] No watch-mode flags
- [x] Task-level feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
