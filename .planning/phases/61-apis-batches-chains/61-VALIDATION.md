---
phase: 61
slug: apis-batches-chains
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
updated: 2026-06-15
---

# Phase 61 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Ecto SQL Sandbox |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/batch_insert_stream_test.exs test/oban_powertools/chain_test.exs test/oban_powertools/chain_progression_test.exs test/oban_powertools/chain_output_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | 0.5s focused Phase 61 suite on 2026-06-15 |

---

## Sampling Rate

- **After every task commit:** Run the targeted test file for the edited module.
- **After every plan wave:** Run `mix test test/oban_powertools/batch_insert_stream_test.exs test/oban_powertools/chain_test.exs test/oban_powertools/chain_progression_test.exs test/oban_powertools/chain_output_test.exs`.
- **Before `$gsd-verify-work`:** Full suite must be green via `mix test`.
- **Max feedback latency:** Focused Phase 61 command completed in 0.5s on 2026-06-15; keep targeted commands under 30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 61-01-01 | 61-01 | 1 | BAT-02 | T-61-01 | Batch schema and installer persist durable insert counters/failure metadata. | unit/integration | `mix test test/oban_powertools/batch_test.exs test/mix/tasks/oban_powertools.install_test.exs` | Yes | green |
| 61-02-01 | 61-02 | 2 | BAT-02 | T-61-01 | Validate stream chunk/count options, reject append/skip ambiguity, persist partial insert failures. | integration | `mix test test/oban_powertools/batch_insert_stream_test.exs` | Yes | green |
| 61-03-01 | 61-03 | 2 | CHN-01 | T-61-02 | Reject non-linear chains and unsafe dynamic step specs; insert linear first step. | unit/integration | `mix test test/oban_powertools/chain_test.exs` | Yes | green |
| 61-04-01 | 61-04 | 3 | CHN-01 | T-61-03 | Chain callback progression must be event-scoped and must not invoke host workflow callbacks. | integration | `mix test test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/chain_progression_test.exs` | Yes | green |
| 61-05-01 | 61-05 | 4 | CHN-02 | T-61-04 | Downstream output access must use durable `JobRecord` payloads, not copied job args. | unit/integration | `mix test test/oban_powertools/chain_output_test.exs` | Yes | green |
| 61-05-02 | 61-05 | 4 | CHN-02 | T-61-05 | Missing, unrecorded, or expired upstream output must return explicit errors and leave repairable state. | integration | `mix test test/oban_powertools/chain_output_test.exs` | Yes | green |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] `test/oban_powertools/batch_test.exs` - covers durable batch insertion metadata schema, validation, and test database columns.
- [x] `test/mix/tasks/oban_powertools.install_test.exs` - covers host installer migration columns and indexes.
- [x] `test/oban_powertools/batch_insert_stream_test.exs` - covers BAT-02 bounded streaming, compact results, partial failure status, and chunked `Oban.insert_all/2` behavior.
- [x] `test/oban_powertools/chain_test.exs` - covers CHN-01 chain DSL, `from_list/2`, `Chain.insert/2`, and linear-only validation.
- [x] `test/oban_powertools/workflow_callbacks_test.exs` - covers host callback event filtering so chain events are not claimed by workflow dispatch.
- [x] `test/oban_powertools/chain_progression_test.exs` - covers CHN-01 callback-outbox progression and event-scoped callback claiming.
- [x] `test/oban_powertools/chain_output_test.exs` - covers CHN-02 durable upstream output handoff through `JobRecord`.
- [x] Optional migration/schema test if implementation adds durable batch insertion failure metadata.

---

## Requirement Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| BAT-02 | COVERED | `batch_test.exs`, `install_test.exs`, and `batch_insert_stream_test.exs` cover durable insertion metadata, bounded chunk inserts, invalid option rejection, deterministic batch ids, compact results, partial failure, and count mismatch behavior. |
| CHN-01 | COVERED | `chain_test.exs`, `workflow_callbacks_test.exs`, and `chain_progression_test.exs` cover linear chain construction, non-linear rejection, first-step insertion, event-scoped callback dispatch, dedupe, retry failure state, and full four-step progression. |
| CHN-02 | COVERED | `chain_output_test.exs` covers `JobRecord` output handoff, missing/unrecorded/expired output errors, `record_output` validation, safe args builders, output-aware progression, and recoverable callback failure. |

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | BAT-02, CHN-01, CHN-02 | All phase behaviors have automated verification targets and passing focused tests. | N/A |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing test references.
- [x] No watch-mode flags.
- [x] Feedback latency recorded after Wave 0.
- [x] `nyquist_compliant: true` set in frontmatter after Wave 0 tests exist and pass.

**Approval:** approved by retroactive Nyquist audit on 2026-06-15.

## Validation Audit 2026-06-15

| Metric | Count |
|--------|-------|
| Requirements audited | 3 |
| Verification tasks audited | 6 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Command run:** `mix test test/oban_powertools/batch_test.exs test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/batch_insert_stream_test.exs test/oban_powertools/chain_test.exs test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/chain_progression_test.exs test/oban_powertools/chain_output_test.exs`

**Result:** 47 tests, 0 failures.

**Audit conclusion:** Phase 61 is Nyquist-compliant. BAT-02, CHN-01, and CHN-02 have direct automated coverage and no manual-only validation gaps.
