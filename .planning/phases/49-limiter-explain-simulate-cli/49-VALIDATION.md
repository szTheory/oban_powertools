---
phase: 49
slug: limiter-explain-simulate-cli
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
validated: 2026-05-29
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/oban_powertools.limiter.explain_test.exs test/mix/tasks/oban_powertools.limiter.simulate_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `{quick run command}`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | OPS-07 | T-49-01 / T-49-02 | Pure `compute_reservation/4` leaks no side effects (no telemetry/DB/history); `reserve/3` regression-clean | unit (tdd) | `mix test test/oban_powertools/limits_test.exs --max-failures 1` | ✅ | ✅ green |
| 49-01-02 | 01 | 1 | OPS-08 | T-49-SC / — | Single-source `Glossary.text/0` covers full D-08 term set (incl. bare `weight`, `scope`); guide carries verbatim copy | unit | `mix test test/oban_powertools/limits/glossary_test.exs` | ✅ | ✅ green |
| 49-02-01 | 02 | 2 | OPS-06, OPS-08 | T-49-03 / T-49-04 / T-49-05 / T-49-06 | Module flags via `Module.safe_concat` (no `String.to_atom`); read-only DB; unknown worker → exit 2; glossary in `@moduledoc` | source + compile | `mix compile --warnings-as-errors 2>&1 \| tail -5 && grep -c "Explain.explain_snapshot" lib/mix/tasks/oban_powertools.limiter.explain.ex` | ✅ | ✅ green |
| 49-02-02 | 02 | 2 | OPS-06 | T-49-03 | Source-inspection (safe input conventions) + DB-integration: resource-primary path, honest empty state, unknown-worker exit 2 | unit + DB | `mix test test/mix/tasks/oban_powertools.limiter.explain_test.exs` | ✅ | ✅ green |
| 49-03-01 | 03 | 2 | OPS-07, OPS-08 | T-49-07 / T-49-08 / T-49-09 / T-49-10 | Simulate calls only `compute_reservation/4` (never reserve/blocked/upsert); safe module/format resolution; Pitfall-4 avoided; nil-safe scope | source + compile | `mix compile --warnings-as-errors 2>&1 \| tail -5 && grep -c "Limits.compute_reservation" lib/mix/tasks/oban_powertools.limiter.simulate.ex` | ✅ | ✅ green |
| 49-03-02 | 03 | 2 | OPS-07, OPS-08 | T-49-07 | Pure per-request verdicts; zero `limiter.blocked` telemetry; zero State/Resource DB writes; glossary no-drift across guide + both `@moduledoc`s | unit + DB (telemetry + count harness) | `mix test test/mix/tasks/oban_powertools.limiter.simulate_test.exs test/oban_powertools/docs_contract_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 (execution-time test scaffolding) must create/extend the following before the production tasks can be verified. Source: RESEARCH.md "Validation Architecture" / "Wave 0 Gaps".

- [x] `test/mix/tasks/oban_powertools.limiter.explain_test.exs` — NEW. Source-inspection module (safe-input conventions: `refute String.to_atom`, `assert Module.safe_concat`, `assert import Ecto.Query`, `assert with_repo`, halt-outside-callback, switch + `@shortdoc` + glossary-term assertions) plus DB-integration module (`use ObanPowertools.DataCase, async: false`) covering the resource-primary `explain_snapshot/2` path, honest empty state, and unknown-`--worker` exit 2. Covers OPS-06. (Plan 49-02 Task 2.)
- [x] `test/mix/tasks/oban_powertools.limiter.simulate_test.exs` — NEW. (a) Source-inspection (no side-effecting limiter calls, safe resolution); (b) pure-verdict module (capacity 3 / weight 1 / count 4 → reserved×3 then blocked "limit_reached"; plus a default-scoped worker case proving nil-safe `scope`); (c) side-effect-freedom + no-DB-writes harness. Covers OPS-07. (Plan 49-03 Task 2.)
- [x] `test/oban_powertools/docs_contract_test.exs` — EXTEND. Add glossary single-source-of-truth assertions locking the full D-08 term set (`token_bucket`, `bucket_capacity`, `bucket_span_ms`, bare `weight`, `weight_by`, `partition`, `partition_by`, `scope`, `cooldown`, `limit_reached`) across all three surfaces: `guides/limits-and-explain.md`, `oban_powertools.limiter.explain.ex` `@moduledoc`, and `oban_powertools.limiter.simulate.ex` `@moduledoc`. Covers OPS-08 no-drift. (Plan 49-03 Task 2.)
- [x] `test/oban_powertools/limits/glossary_test.exs` — NEW. Asserts `ObanPowertools.Limits.Glossary.text()` is a binary containing every D-08 term (incl. bare `weight` and `scope`), and that the guide contains each term. Covers OPS-08 source-of-truth. (Plan 49-01 Task 2.)
- [x] `test/oban_powertools/limits_test.exs` — EXTEND. Add `compute_reservation/4` unit cases (reserved/blocked/cooldown/expired-bucket) and the side-effect-freedom telemetry-handler harness: a `[:oban_powertools, :limiter, :blocked]` handler that asserts ZERO events fire across direct `compute_reservation/4` calls including a blocked verdict (OPS-07). Existing tests serve as the `reserve/3` regression suite (must pass unchanged). (Plan 49-01 Task 1.)
- [x] Simulate side-effect-freedom harness — telemetry handler that flunks on `[:oban_powertools, :limiter, :blocked]` plus `repo().aggregate(State|Resource, :count)` before/after assertions, proving simulate emits no blocked telemetry and writes no `oban_powertools_limit_states` / `oban_powertools_limit_resources` rows (OPS-07 hard property). Lives in the simulate test file above. (Plan 49-03 Task 2.)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `mix help oban_powertools.limiter.explain` renders glossary | OPS-08 | `mix help` output is not easily asserted in ExUnit | Run `mix help oban_powertools.limiter.explain` and confirm glossary terms present |
| `mix help oban_powertools.limiter.simulate` renders glossary | OPS-08 | `mix help` output is not easily asserted in ExUnit | Run `mix help oban_powertools.limiter.simulate` and confirm glossary terms present |

*Note: the glossary term content of each `@moduledoc` is additionally locked by automated source-inspection assertions in `docs_contract_test.exs`; the manual `mix help` check confirms the rendered help surface only.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved (Nyquist-compliant; Wave 0 scaffolding enumerated, executed at run time)

---

## Validation Audit 2026-05-29

Retroactive audit (`/gsd-validate-phase 49`) reconciling the plan-time draft against post-execution reality. All 6 per-task rows cross-referenced to live test files and re-run.

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Evidence:**
- `mix compile --warnings-as-errors` → exit 0, clean
- `mix test` (5 phase-49 files) → **91 tests, 0 failures** (exit 0)
- All 6 Wave 0 scaffolding items present and green
- OPS-07 hard property verified live: `[:oban_powertools, :limiter, :blocked]` telemetry `flunk` handler + `repo().aggregate(State|Resource, :count)` before/after assertions present in both `limits_test.exs` and `simulate_test.exs`
- OPS-08 glossary no-drift: `docs_contract_test.exs` asserts D-08 term set across guide + simulate + explain `@moduledoc` sources (explain guard now resolves post-merge)
- T-49-03/08 safe-input: `refute String.to_atom`, `assert Module.safe_concat` source-inspection assertions present

All requirements have automated verification. No gaps to fill; no auditor spawn required.
</content>
