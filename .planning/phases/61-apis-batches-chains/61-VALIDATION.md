---
phase: 61
slug: apis-batches-chains
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
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
| **Estimated runtime** | TBD during Wave 0 |

---

## Sampling Rate

- **After every task commit:** Run the targeted test file for the edited module.
- **After every plan wave:** Run `mix test test/oban_powertools/batch_insert_stream_test.exs test/oban_powertools/chain_test.exs test/oban_powertools/chain_progression_test.exs test/oban_powertools/chain_output_test.exs`.
- **Before `$gsd-verify-work`:** Full suite must be green via `mix test`.
- **Max feedback latency:** TBD during Wave 0; keep targeted commands under 30 seconds if practical.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 61-01-01 | TBD | 0 | BAT-02 | T-61-01 | Validate stream chunk and count options before enqueueing. | unit/integration | `mix test test/oban_powertools/batch_insert_stream_test.exs` | No - W0 | pending |
| 61-01-02 | TBD | 0 | CHN-01 | T-61-02 | Reject non-linear chains and unsafe dynamic step specs. | unit/integration | `mix test test/oban_powertools/chain_test.exs` | No - W0 | pending |
| 61-01-03 | TBD | 0 | CHN-01 | T-61-03 | Chain callback progression must be event-scoped and must not invoke host workflow callbacks. | integration | `mix test test/oban_powertools/chain_progression_test.exs` | No - W0 | pending |
| 61-01-04 | TBD | 0 | CHN-02 | T-61-04 | Downstream output access must use durable `JobRecord` payloads, not copied job args. | unit/integration | `mix test test/oban_powertools/chain_output_test.exs` | No - W0 | pending |
| 61-01-05 | TBD | 0 | CHN-02 | T-61-05 | Missing, unrecorded, or oversized upstream output must return explicit errors and leave repairable state. | integration | `mix test test/oban_powertools/chain_output_test.exs` | No - W0 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/batch_insert_stream_test.exs` - covers BAT-02 bounded streaming, compact results, partial failure status, and chunked `Oban.insert_all/2` behavior.
- [ ] `test/oban_powertools/chain_test.exs` - covers CHN-01 chain DSL, `from_list/2`, `Chain.insert/2`, and linear-only validation.
- [ ] `test/oban_powertools/chain_progression_test.exs` - covers CHN-01 callback-outbox progression and event-scoped callback claiming.
- [ ] `test/oban_powertools/chain_output_test.exs` - covers CHN-02 durable upstream output handoff through `JobRecord`.
- [ ] Optional migration/schema test if implementation adds durable batch insertion failure metadata.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None planned | BAT-02, CHN-01, CHN-02 | All phase behaviors have automated verification targets. | N/A |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing test references.
- [ ] No watch-mode flags.
- [ ] Feedback latency recorded after Wave 0.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 tests exist and pass.

**Approval:** pending
