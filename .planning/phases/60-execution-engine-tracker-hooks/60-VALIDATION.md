---
phase: 60
slug: execution-engine-tracker-hooks
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
updated: 2026-06-15
---

# Phase 60 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Mix |
| **Config file** | `mix.exs`, `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/batch_test.exs test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/batch/tracker_test.exs test/oban_powertools/worker_test.exs test/oban_powertools/batch_job_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~3s focused, ~280s full suite |

---

## Sampling Rate

- **After every task commit:** Run the plan-specific `mix test ...` command from the task verify block.
- **After every plan wave:** Run the focused Phase 60 test set above.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** ~5 minutes for full suite, under 10 seconds for focused Phase 60 coverage.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | BAT-03, BAT-04 | T-60-01 | `completed_at` is nullable, castable, and available as the completion race guard. | unit/schema | `mix test test/oban_powertools/batch_test.exs` | yes | green |
| 60-01-02 | 01 | 1 | BAT-03, BAT-04 | T-60-01 | Installer and test support migrations create `completed_at` on `oban_powertools_batches`. | contract/schema | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/batch_test.exs` | yes | green |
| 60-02-01 | 02 | 2 | BAT-03, BAT-04 | T-60-02, T-60-03 | `BatchJob` insert idempotency prevents double increments; completion callback enqueue is guarded by `completed_at IS NULL`; counters use `update_all inc`. | unit/integration | `mix test test/oban_powertools/batch/tracker_test.exs test/oban_powertools/batch_job_test.exs` | yes | green |
| 60-03-01 | 03 | 3 | BAT-03, BAT-04 | T-60-04 | Worker hooks record success/discard before host hooks, skip cancel/snooze, record terminal errors/exceptions as discards, and mark exhausted callbacks `callback_failed`. | integration | `mix test test/oban_powertools/worker_test.exs test/oban_powertools/batch/tracker_test.exs` | yes | green |

*Status: pending = not run; green = automated verification passed; red = failing; flaky = unstable.*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- ExUnit test infrastructure already exists in `test/test_helper.exs`.
- Test support database migrations include Phase 59 batch/callback tables.
- No new framework or fixture bootstrap is required.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Audit 2026-06-15

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

### Gap Resolution

| Requirement | Gap | Resolution | Verification |
|-------------|-----|------------|--------------|
| BAT-03, BAT-04 | Plan 01 had summary-time checks for `completed_at`, but no persistent automated test proving the Batch schema accepts the field and migrations expose the column. | Added `completed_at` assertions to `test/oban_powertools/batch_test.exs` and installer source coverage in `test/mix/tasks/oban_powertools.install_test.exs`. | `mix test test/oban_powertools/batch_test.exs test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/batch/tracker_test.exs test/oban_powertools/worker_test.exs test/oban_powertools/batch_job_test.exs` - PASS, 57 tests, 0 failures. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or existing infrastructure coverage.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 300s for full suite and < 10s for focused Phase 60 coverage.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-15
