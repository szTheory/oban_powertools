---
phase: 49-limiter-explain-simulate-cli
verified: 2026-05-29T00:00:00Z
status: passed
score: 18/18 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 49: Limiter Explain/Simulate CLI Verification Report

**Phase Goal:** Ship `mix oban_powertools.limiter.explain` (OPS-06) and `mix oban_powertools.limiter.simulate` (OPS-07) with a single-source rate-limit glossary (OPS-08).
**Verified:** 2026-05-29
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | `Limits.compute_reservation/4` is public and pure (no DB, no telemetry, no history) | VERIFIED | `def compute_reservation(` at line 148 of `limits.ex`; `defp normalize_bucket` and `defp cooldown_active?` remain private; no `repo.`, `Telemetry.`, or `record_history_fact` in the function body |
| 2  | `attempt_reservation/5` delegates to `compute_reservation/4` and normalizes the bucket exactly once | VERIFIED | `limits.ex:248` calls `normalize_bucket` once into `normalized_state`, then `compute_reservation(normalized_state, ...)` at line 250 |
| 3  | A single shared Glossary module exists with all required D-08 terms | VERIFIED | `lib/oban_powertools/limits/glossary.ex` defines `Glossary.text/0`; all 10 terms present: `token_bucket`, `bucket_capacity`, `bucket_span_ms`, `weight`, `weight_by`, `partition`, `partition_by`, `scope`, `cooldown`, `limit_reached` |
| 4  | `guides/limits-and-explain.md` contains the full glossary under `## Rate-Limit Glossary` | VERIFIED | Heading at line 104; all 10 D-08 terms confirmed by grep |
| 5  | `mix oban_powertools.limiter.explain --resource NAME` explains via `Explain.explain_snapshot/2` | VERIFIED | `run_resource_path/3` queries latest Explain row by `scope_id`, calls `Explain.explain_snapshot/2`; integration test confirms exit 0 |
| 6  | Unknown/no-state resource reports honest empty state (runnable, "no limiter state recorded yet"), exit 0 | VERIFIED | `run_resource_path/3` nil-snapshot branch; integration test asserts output and exit code |
| 7  | `mix oban_powertools.limiter.explain --worker MOD` maps onto `Explain.explain/3` | VERIFIED | `run_worker_path/3` calls `Explain.explain(worker_mod, parsed_args, repo: repo)` |
| 8  | Unknown `--worker` module is a cannot-run error (exit 2) | VERIFIED | `resolve_worker/1` checks `Code.ensure_loaded?`; integration test asserts exit 2 + "unknown --worker module" message |
| 9  | Worker with no `:limits` configured is exit 2 (CR-01 fix) | VERIFIED | `run_worker_path/3` calls `worker_limit_snapshot/2` first; `when not is_nil(snapshot)` guard at line 211; `{:ok, nil}` branch returns exit 2 + "worker has no limits configured"; regression test at line 63 of explain_test asserts `limit_snapshot` wiring and the guard pattern |
| 10 | `explain --format json` emits `schema_version: 1` | VERIFIED | Both `print_empty_state/3` (line 254) and `print_explanation/3` (line 277) JSON branches include `schema_version: 1`; integration test asserts `payload["schema_version"] == 1` |
| 11 | `mix oban_powertools.limiter.simulate --worker MOD` previews verdicts via `Limits.compute_reservation/4` only | VERIFIED | `simulate_reservations/5` calls only `Limits.compute_reservation`; source contains no `do_reserve`, `attempt_reservation`, `upsert_resource`, or `get_or_create_state` |
| 12 | Simulate runs `--count N` reservations against a fresh empty bucket with zero side effects | VERIFIED | `initial_state` struct has `tokens_used: 0`; telemetry side-effect-freedom test attaches `[:oban_powertools, :limiter, :blocked]` handler with `flunk` — confirms zero events fired |
| 13 | Simulate writes zero rows to `oban_powertools_limit_states`/`oban_powertools_limit_resources` | VERIFIED | No-DB-writes test asserts `State` and `Resource` table counts identical before/after simulation loop |
| 14 | Unknown `--worker` or worker with no `:limits` is exit 2 for simulate | VERIFIED | `resolve_worker_config/2` returns `{:error, :no_limits}` when `__powertools_limits__` not exported or `limits == []`; `resolve_worker/1` returns `{:error, :unknown_module, ...}` on nil opts |
| 15 | `simulate --format json` emits `schema_version: 1` | VERIFIED | `print_simulation/6` JSON branch at line 312 includes `schema_version: 1`; source test asserts the pattern |
| 16 | Simulate validates `--count`/`--bucket-capacity`/`--bucket-span-ms`/`--weight` as positive integers (WR-01/WR-03 fix) | VERIFIED | `validate_positive/1` called before simulation loop; all four flags validated; test asserts "must be a positive integer" message |
| 17 | Both task `@moduledoc` sections surface the full D-08 glossary (OPS-08) | VERIFIED | Both task files contain the verbatim glossary text from `Glossary.text/0`; `docs_contract_test.exs` asserts all 10 terms in both source files and the guide |
| 18 | `--prefix`/`--oban-name` inert flags removed (WR-02 fix) | VERIFIED | Neither `prefix` nor `oban_name` appears in the `@switches` declarations or `@moduledoc` of either task |

**Score:** 18/18 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/oban_powertools/limits.ex` | Public pure `compute_reservation/4` + delegating `attempt_reservation/5` | VERIFIED | `def compute_reservation(` line 148; `defp attempt_reservation` delegates at line 250; `defp normalize_bucket` and `defp cooldown_active?` private |
| `lib/oban_powertools/limits/glossary.ex` | Single-source `Glossary.text/0` | VERIFIED | 69 lines; all 10 D-08 terms present; `@spec text() :: String.t()` |
| `guides/limits-and-explain.md` | Glossary section with `token_bucket` and all D-08 terms | VERIFIED | `## Rate-Limit Glossary` heading; all terms confirmed |
| `lib/mix/tasks/oban_powertools.limiter.explain.ex` | Mix.Task with `def run(`, Doctor conventions, Explain reuse | VERIFIED | 421 lines; `use Mix.Task`; `import Ecto.Query`; `Ecto.Migrator.with_repo`; `Module.safe_concat`; `Explain.explain_snapshot` and `Explain.explain(` both present |
| `lib/mix/tasks/oban_powertools.limiter.simulate.ex` | Mix.Task with `def run(`, pure `Limits.compute_reservation/4` loop | VERIFIED | 406 lines; `use Mix.Task`; `Ecto.Migrator.with_repo`; `Module.safe_concat`; `Limits.compute_reservation` only |
| `test/mix/tasks/oban_powertools.limiter.explain_test.exs` | Source-inspection + DB-integration tests | VERIFIED | 247 lines; source-inspection module + `ExplainIntegrationTest` with DataCase |
| `test/mix/tasks/oban_powertools.limiter.simulate_test.exs` | Pure-verdict + side-effect-freedom + no-DB-writes tests | VERIFIED | 345 lines; three test modules: source-inspection, `SimulatePureVerdictTest` (async true), `SimulateSideEffectFreedomTest` (DataCase) |
| `test/oban_powertools/docs_contract_test.exs` | Glossary no-drift contract across both tasks + guide | VERIFIED | `@d08_terms` list of 10 terms; three tests assert all terms in guide, simulate source, and explain source |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `limits.ex attempt_reservation/5` | `Limits.compute_reservation/4` | `case compute_reservation(normalized_state, ...)` | VERIFIED | Line 250; normalized_state bound once at line 248 |
| `limiter.explain.ex run_resource_path/3` | `Explain.explain_snapshot/2` | Direct call line 193 | VERIFIED | `ObanPowertools.Explain.explain_snapshot(snap, repo: repo)` |
| `limiter.explain.ex run_worker_path/3` | `Explain.explain/3` | Direct call line 213 | VERIFIED | `ObanPowertools.Explain.explain(worker_mod, parsed_args, repo: repo)` |
| `limiter.explain.ex` | `ObanPowertools.Limits.Glossary.text/0` | `@moduledoc` attribution at line 48 + verbatim text | VERIFIED | "Source: `ObanPowertools.Limits.Glossary.text/0`" comment; full glossary inline |
| `limiter.simulate.ex simulate_reservations/5` | `Limits.compute_reservation/4` | `case Limits.compute_reservation(state, ...)` | VERIFIED | Line 236; only limiter function called in simulation loop |
| `limiter.simulate.ex` | `ObanPowertools.Limits.Glossary.text/0` | `@moduledoc` attribution at line 46 + verbatim text | VERIFIED | "Source: `ObanPowertools.Limits.Glossary.text/0`" comment; full glossary inline |
| `docs_contract_test.exs` | both task source files + guide | D-08 term assertions | VERIFIED | Three tests asserting all 10 terms across three surfaces |

---

### Data-Flow Trace (Level 4)

Both Mix tasks delegate to pure computation paths (no dynamic rendering from DB state variables). The explain task queries the DB via `Ecto.Migrator.with_repo` and passes the result to `Explain.explain_snapshot/2` — data flows correctly from DB row to output. The simulate task builds synthetic structs and never touches the DB; data flows from CLI flags through `compute_reservation/4` to output.

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `limiter.explain.ex` resource path | `snapshot` (Explain schema row) | `repo.one(from event in ObanPowertools.Explain, ...)` line 178 | Yes — real DB query | FLOWING |
| `limiter.explain.ex` worker path | `explanation` (map from `Explain.explain/3`) | `Explain.explain/3` calls `Worker.limit_snapshot/2` then live DB blockers | Yes | FLOWING |
| `limiter.simulate.ex` | `verdicts` list | `Limits.compute_reservation/4` with synthetic `%Resource{}` + `%State{}` | Yes — pure computation, intentionally no DB | FLOWING (by design) |

---

### Behavioral Spot-Checks

Step 7b skipped: the app cannot be started without a running DB and configured repo. Tasks are Mix tasks that require `Ecto.Migrator.with_repo` and a compiled host app. The integration tests in the test suite (`ExplainIntegrationTest`, `SimulateSideEffectFreedomTest`) serve as the behavioral spot-checks.

---

### Probe Execution

Step 7c: No `probe-*.sh` scripts declared in any PLAN file and none found under `scripts/*/tests/` for this phase.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| OPS-06 | 49-02 | `mix oban_powertools.limiter.explain` explains blocking state reusing Explain API | SATISFIED | Task exists; `Explain.explain_snapshot/2` and `Explain.explain/3` wired; integration tests pass |
| OPS-07 | 49-01, 49-03 | `mix oban_powertools.limiter.simulate` previews behavior without mutating state | SATISFIED | Task exists; pure loop via `compute_reservation/4` only; telemetry + DB-count tests prove zero side effects |
| OPS-08 | 49-01, 49-02, 49-03 | Limiter CLI ships rate-limit glossary in help/documentation | SATISFIED | `Glossary.text/0` single source; verbatim text in both `@moduledoc`s and guide; `docs_contract_test.exs` locks all 10 D-08 terms across all three surfaces |

---

### Design Contract Verification

| Contract | Status | Evidence |
|----------|--------|----------|
| D-06: `compute_reservation/4` is a public pure function; `attempt_reservation/5` delegates to it | VERIFIED | `def compute_reservation` at line 148 with no side-effecting calls; `attempt_reservation` calls it at line 250; telemetry-handler test in `limits_test.exs` asserts zero `[:oban_powertools, :limiter, :blocked]` events from direct calls |
| D-02 exit-code posture: explain exits 0 normally / 2 on cannot-run; simulate exits 0 on success / 2 on bad input | VERIFIED | explain: unknown worker → 2, no-limits worker → 2 (CR-01 fixed), no `--resource`/`--worker` → 2; simulate: unknown worker → 2, no limits → 2, non-positive overrides → 2 |
| D-01: both tasks mirror Doctor conventions | VERIFIED | `Mix.Task.run("app.config")`, `Ecto.Migrator.with_repo`, `Module.safe_concat`, `System.halt` only at outer boundary, `--format human\|json`, `schema_version: 1` for JSON; no `@requirements`, no `Oban.start_link` |
| D-08: single-source `Glossary.text/0`; term parity enforced by `docs_contract_test.exs` | VERIFIED | All 10 D-08 terms in `Glossary.text/0`, both task `@moduledoc`s, and guide; contract test locks all three surfaces |

---

### Review Remediation Verification (commit 357f68e)

| Finding | Claimed Fix | Actually Present |
|---------|-------------|-----------------|
| CR-01: explain `--worker` no-limits → exit 0 instead of 2 | `run_worker_path/3` resolves via `worker_limit_snapshot/2` first; `when not is_nil(snapshot)` guard; `{:ok, nil}` → exit 2 | CONFIRMED — lines 209-212 and 218-219 in explain.ex |
| WR-01: `--count <= 0` garbage results | `validate_positive` checks all four numeric inputs before simulation | CONFIRMED — `validate_positive/1` at line 222 with all four flags |
| WR-02: inert `--prefix`/`--oban-name` documented but ignored | Removed from both tasks | CONFIRMED — neither switch appears in `@switches` or `@moduledoc` of either task |
| WR-03: `--bucket-capacity`/`--bucket-span-ms`/`--weight` accept zero/negative | Same `validate_positive` call covers these | CONFIRMED — all three included in the `validate_positive` pairs list |
| IN-01: `b[:retry_at] \|\| b[:retry_at]` redundant OR | Deferred | CONFIRMED deferred — still present at explain.ex:325 (cosmetic, no behavioral impact) |
| IN-02/IN-03 | Deferred | Not checked (cosmetic) |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `limiter.explain.ex` | 325 | `b[:retry_at] \|\| b[:retry_at]` — ORs a value with itself | Info | No behavioral impact; copy-paste artifact; explicitly deferred in REVIEW.md as IN-01 |

No `TBD`, `FIXME`, or `XXX` markers found in any phase file. No stubs, no empty returns in the implementation path.

---

### Human Verification Required

None. All must-haves are mechanically verifiable:

- Functional correctness of CLI output appearance under ANSI/non-ANSI terminals: this is cosmetic-only and not a correctness contract item.
- The full test suite (426 tests, 0 failures) is noted as passing per the phase submission; `mix compile --warnings-as-errors` is clean. Both are CI gates, not requiring manual human steps for this verification.

---

## Gaps Summary

No gaps. All 18 must-have truths are VERIFIED. All three requirements (OPS-06, OPS-07, OPS-08) are satisfied. All four review findings (CR-01, WR-01, WR-02, WR-03) confirmed fixed in the codebase. Three deferred info-level cosmetic items (IN-01, IN-02, IN-03) have no behavioral impact and are not gaps.

---

_Verified: 2026-05-29_
_Verifier: Claude (gsd-verifier)_
