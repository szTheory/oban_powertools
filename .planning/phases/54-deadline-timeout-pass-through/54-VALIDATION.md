---
phase: 54
slug: deadline-timeout-pass-through
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-12
---

# Phase 54 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit 1.19.5 with Ecto SQL Sandbox |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/worker_test.exs test/oban_powertools/idempotency_test.exs test/oban_powertools/doctor/checks_test.exs --trace` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/worker_test.exs test/oban_powertools/idempotency_test.exs test/oban_powertools/doctor/checks_test.exs --trace`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 54-TBD-SAFE-01 | TBD | TBD | SAFE-01 | T-54-01 | Compile-time `timeout:` accepts positive integer milliseconds, rejects invalid values, generates overridable `timeout/1`, and never passes `timeout:` to `Oban.Job.new/2` | unit | `mix test test/oban_powertools/worker_test.exs --trace` | Yes | pending |
| 54-TBD-SAFE-02 | TBD | TBD | SAFE-02 | T-54-02 | Enqueue path stores Powertools-owned top-level `meta["__deadline_at__"]` ISO8601 UTC timestamp while preserving caller meta and reserved-key precedence | integration | `mix test test/oban_powertools/idempotency_test.exs --trace` | Yes | pending |
| 54-TBD-SAFE-03 | TBD | TBD | SAFE-03 | T-54-03 | Expired deadline metadata returns `{:cancel, :deadline_expired}` before `process/1`, `on_start/1`, output recording, or post hooks; missing/malformed metadata does not crash | unit | `mix test test/oban_powertools/worker_test.exs --trace` | Yes | pending |
| 54-TBD-SAFE-04 | TBD | TBD | SAFE-04 | T-54-04 | Doctor warns on retryable jobs with expired parseable `__deadline_at__`, remains prefix-safe and read-only, and does not broaden `--strict` semantics | integration | `mix test test/oban_powertools/doctor/checks_test.exs test/oban_powertools/doctor/formatter_test.exs test/mix/tasks/oban_powertools.doctor_test.exs --trace` | Yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/worker_test.exs` - add timeout/deadline worker modules and wrapper-order assertions for SAFE-01 and SAFE-03.
- [ ] `test/oban_powertools/idempotency_test.exs` - add deadline meta insertion, caller meta preservation, reserved-key precedence, and fingerprint coexistence tests for SAFE-02.
- [ ] `test/oban_powertools/doctor/checks_test.exs` - add expired, non-expired, malformed, and prefix-aware deadline warning tests for SAFE-04.
- [ ] `test/oban_powertools/doctor/formatter_test.exs` - assert human and JSON warning output without schema drift for SAFE-04.
- [ ] `test/mix/tasks/oban_powertools.doctor_test.exs` - assert CLI docs/severity table and unchanged `--strict` scope for SAFE-04.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Threat Sampling

| Ref | Threat | Required Verification |
|-----|--------|-----------------------|
| T-54-01 | Invalid or leaked `timeout:` option causes Oban option errors or silently disables timeout enforcement | Compile-time tests prove positive integer validation, option stripping, generated callback, and host override behavior |
| T-54-02 | Caller-supplied `__deadline_at__` spoofs or overrides Powertools deadline metadata | Idempotency/enqueue tests prove Powertools reserved keys win after caller meta merge |
| T-54-03 | Malformed or expired deadline metadata crashes wrapper or starts host work after expiry | Worker tests prove malformed values run normally and expired values cancel before hooks and `process/1` |
| T-54-04 | Doctor deadline query becomes unsafe, noisy, or changes strict failure semantics | Doctor tests prove prefix validation, bounded malformed-meta behavior, warning severity, JSON stability, and unchanged `--strict` scope |

---

## Validation Sign-Off

- [ ] All tasks have automated verification or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90 seconds
- [ ] `nyquist_compliant: true` set in frontmatter after plans bind concrete task IDs

**Approval:** pending
