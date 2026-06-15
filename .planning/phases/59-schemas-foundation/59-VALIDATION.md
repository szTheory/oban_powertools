---
phase: 59
slug: schemas-foundation
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
updated: 2026-06-15
---

# Phase 59 - Validation Strategy

Per-phase validation contract for feedback sampling during execution and retroactive Nyquist audit.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/batch_test.exs test/oban_powertools/batch_job_test.exs test/oban_powertools/callback_test.exs test/mix/tasks/oban_powertools.install_test.exs` |
| **Phase run command** | `mix test test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/doctor/checks_test.exs test/oban_powertools/batch_test.exs test/oban_powertools/batch_job_test.exs test/oban_powertools/callback_test.exs test/mix/tasks/oban_powertools.install_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | Quick: < 1s; Phase: < 2s; Full: ~326s |

---

## Sampling Rate

- **After every task commit:** Run the quick run command.
- **After every plan wave:** Run the phase run command.
- **Before `$gsd-verify-work`:** Run `mix test`.
- **Max feedback latency:** < 2s for task/wave validation sampling; full-suite validation is slower and reserved for phase sign-off.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01-01 | 01 | 1 | BAT-01 | T-59-01 | Batch schemas expose explicit counters and reject negative counts. | unit | `mix test test/oban_powertools/batch_test.exs test/oban_powertools/batch_job_test.exs` | yes | green |
| 59-01-02 | 01 | 1 | BAT-01 | T-59-02 | Callback schema uses generalized `oban_powertools_callbacks`, allows workflow or batch ownership, and permits batch events. | unit | `mix test test/oban_powertools/callback_test.exs` | yes | green |
| 59-01-03 | 01 | 1 | BAT-01 | - | Workflow runtime and callback dispatch use `ObanPowertools.Callback`, including batch callback events. | integration | `mix test test/oban_powertools/workflow_callbacks_test.exs` | yes | green |
| 59-02-01 | 02 | 2 | BAT-01 | T-59-02 | Installer emits a safe rename/alter migration, adds `batch_id`, makes `workflow_id` nullable, indexes callback batch ownership, and creates batch tables. | unit | `mix test test/mix/tasks/oban_powertools.install_test.exs` | yes | green |
| 59-02-02 | 02 | 2 | BAT-01 | T-59-02 | Test migration renames the callback outbox and creates batch tables before schema tests run. | integration | `mix test test/oban_powertools/batch_test.exs test/oban_powertools/doctor/checks_test.exs` | yes | green |
| 59-02-03 | 02 | 2 | BAT-01 | - | Schema unit tests cover required attributes, allowed callback events, nullable ownership, timestamp fields, and durable insertion metadata. | unit | `mix test test/oban_powertools/batch_test.exs test/oban_powertools/batch_job_test.exs test/oban_powertools/callback_test.exs` | yes | green |

*Status: green = passing in current audit run.*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Audit 2026-06-15

| Metric | Count |
|--------|-------|
| Gaps found | 2 |
| Resolved | 2 |
| Escalated | 0 |

Resolved gaps:

- Added installer test coverage for `alter table(:oban_powertools_callbacks)`, `add :batch_id, :uuid`, and nullable `workflow_id`.
- Added installer test coverage for `create index(:oban_powertools_callbacks, [:batch_id])`.

Verification evidence:

- `mix test test/oban_powertools/batch_test.exs test/oban_powertools/batch_job_test.exs test/oban_powertools/callback_test.exs test/mix/tasks/oban_powertools.install_test.exs` - 19 tests, 0 failures.
- `mix test test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/doctor/checks_test.exs test/oban_powertools/batch_test.exs test/oban_powertools/batch_job_test.exs test/oban_powertools/callback_test.exs test/mix/tasks/oban_powertools.install_test.exs` - 42 tests, 0 failures.
- `mix test` - 583 tests, 0 failures in 325.7s.

---

## Validation Sign-Off

- [x] All tasks have automated verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 59s for task/wave sampling commands.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-15
