---
phase: 53
slug: worker-lifecycle-hooks
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-12
---

# Phase 53 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from RESEARCH.md `## Validation Architecture` (2026-06-12).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/worker_test.exs test/oban_powertools/telemetry_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | quick < 15s for targeted worker/telemetry suites; full suite runtime not re-measured during planning |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/worker_test.exs test/oban_powertools/telemetry_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** targeted suite should stay under 15 seconds; full suite is the phase gate

---

## Per-Task Verification Map

> Task IDs follow the convention `53-XX-YY` once the planner emits PLAN.md.

| Req ID | Behavior | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|------------|-----------------|-----------|-------------------|-------------|--------|
| HOOK-01 | `on_start/1` fires after validation/casting and before `process/1`; hook crashes are swallowed and do not alter the job result | T-53-01 / T-53-02 | Hook failure cannot retry, discard, or otherwise change the Oban job outcome | Unit | `mix test test/oban_powertools/worker_test.exs --trace` | yes, extend | pending |
| HOOK-02 | `on_success/2` receives success envelopes for `:ok` and `{:ok, value}` | T-53-01 | Successful process results remain the original values returned to Oban | Unit | `mix test test/oban_powertools/worker_test.exs --trace` | yes, extend | pending |
| HOOK-03 | `on_failure/2` receives retry-eligible `{:error, reason}` and rescued/caught process failure envelopes | T-53-01 / T-53-02 | Retry-eligible failures remain failures after observe-only hook dispatch | Unit | `mix test test/oban_powertools/worker_test.exs --trace` | yes, extend | pending |
| HOOK-04 | `on_discard/2` fires exactly once for final-attempt error and explicit discard; it does not fire for retry-eligible failures or explicit cancel | T-53-01 | Final-attempt routing does not double-fire `on_failure/2` and `on_discard/2` | Unit | `mix test test/oban_powertools/worker_test.exs --trace` | yes, extend | pending |
| HOOK-05 | Hook dispatch emits `[:oban_powertools, :worker_hook, :invoked]` with exact metadata keys `hook` and `outcome`; metric tags stay inside the frozen contract | T-53-03 | Telemetry labels exclude job ids, args, queues, worker names, reasons, and stacktraces | Unit | `mix test test/oban_powertools/telemetry_test.exs --trace` | yes, extend | pending |

*Status values: pending, green, red, flaky*

---

## Threat References

| Threat Ref | Risk | Mitigation Proof |
|------------|------|------------------|
| T-53-01 | Lifecycle hooks trigger duplicate or wrong side effects by firing on the wrong state transition | Worker routing tests cover start, success, retry failure, terminal discard, explicit discard, explicit cancel non-dispatch, and final-attempt non-double-fire |
| T-53-02 | Hook exceptions or throws escape and change the job outcome | Worker tests assert original `perform/1` return semantics after hook crash paths |
| T-53-03 | Sensitive or high-cardinality values leak into public hook telemetry metadata | Telemetry tests assert the exact metadata key set and metric tags allowed by `ObanPowertools.Telemetry.contract/0` |

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/worker_test.exs` - add hook routing, no-op defaults, crash-safety, final-attempt non-double-fire, and cancel non-dispatch coverage.
- [ ] `test/oban_powertools/telemetry_test.exs` - add `worker_hook` contract, helper event, metric counter, and exact metadata-key tests.
- [ ] `lib/oban_powertools/worker/hooks.ex` - create the internal dispatch module before worker macro integration so it can be tested directly or through small worker fixtures.
- [ ] Framework install: none - existing ExUnit setup covers all Phase 53 behaviors.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|

*None - all phase behaviors have automated verification through worker and telemetry tests.*

---

## Validation Sign-Off

- [ ] All PLAN.md tasks have automated verify commands or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references above
- [ ] No watch-mode flags
- [ ] Feedback latency target documented
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
