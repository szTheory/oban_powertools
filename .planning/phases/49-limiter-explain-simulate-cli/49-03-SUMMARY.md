---
phase: 49-limiter-explain-simulate-cli
plan: "03"
subsystem: cli
tags: [mix-task, simulate, pure-computation, side-effect-freedom, glossary, ops]
dependency_graph:
  requires: ["49-01"]
  provides:
    - Mix.Tasks.ObanPowertools.Limiter.Simulate (OPS-07)
    - OPS-08 glossary contract locked in docs_contract_test.exs
  affects:
    - lib/mix/tasks/oban_powertools.limiter.simulate.ex
    - test/mix/tasks/oban_powertools.limiter.simulate_test.exs
    - test/oban_powertools/docs_contract_test.exs
tech_stack:
  added: []
  patterns:
    - Doctor task CLI pattern (Mix.Task, with_repo, Module.safe_concat, System.halt outside callback)
    - Pure computation loop via compute_reservation/4 only (zero side effects)
    - Pitfall 4 workaround (__powertools_limits__/0 direct read instead of limit_snapshot/2)
    - Nil-safe scope_kind resolution (limits[:scope] || :global)
    - Three-tier test suite (source-inspection + pure-verdict + side-effect-freedom/no-DB)
key_files:
  created:
    - lib/mix/tasks/oban_powertools.limiter.simulate.ex
    - test/mix/tasks/oban_powertools.limiter.simulate_test.exs
  modified:
    - test/oban_powertools/docs_contract_test.exs
decisions:
  - "Embed glossary text literally in @moduledoc (not via interpolation) so source-inspection tests can assert literal D-08 terms"
  - "Reference ObanPowertools.Limits.Glossary.text/0 as doc comment in @moduledoc header rather than as compiled interpolation"
  - "Guard explain-file OPS-08 test with File.exists? to pass in parallel wave-2 worktree (explain is created by 49-02 in sibling agent)"
  - "Remove resolve_prefix/1 from simulate (not needed — simulate loop is pure and never queries DB with prefix)"
  - "Three separate ExUnit modules: source-inspection (no-DB), pure-verdict (async: true), side-effect-freedom (DataCase, async: false)"
metrics:
  duration: 9m
  completed: "2026-05-29"
  tasks: 2
  files: 3
---

# Phase 49 Plan 03: Limiter Simulate CLI Summary

`mix oban_powertools.limiter.simulate` previewing per-request reserved/blocked verdicts for a worker's declared limits via pure `Limits.compute_reservation/4` with zero side effects, proven by telemetry-handler and DB-count tests; OPS-08 glossary contract locked across the guide, simulate, and explain (post-merge) source files.

## Tasks Completed

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | Create the limiter.simulate Mix task | a4d9a7c | Complete |
| 2 | Test simulate + glossary docs contract | 3bb4fcf | Complete |

## What Was Built

### Task 1: mix oban_powertools.limiter.simulate (OPS-07)

Created `lib/mix/tasks/oban_powertools.limiter.simulate.ex` implementing `Mix.Tasks.ObanPowertools.Limiter.Simulate` following the Doctor task CLI conventions (D-01):

- `Mix.Task.run("app.config")` → `OptionParser.parse` → `resolve_repo` → `Ecto.Migrator.with_repo` → `System.halt` outside callback
- `@switches` declares: `worker`, `bucket_capacity`, `bucket_span_ms`, `weight`, `count`, `partition`, `repo`, `prefix`, `oban_name`, `format`
- `--format` mapped via closed `case` to `:json` | `:human` (never `String.to_atom`)
- `Module.safe_concat/1` for `--worker` and `--repo` resolution (T-49-08 / T-48-05)
- Worker config read via `worker_mod.__powertools_limits__/0` directly (avoids Pitfall 4: `limit_snapshot/2` raises ArgumentError for `partition_by: {:args, key}` with empty args)
- `scope_kind = (limits[:scope] || :global) |> Atom.to_string()` — nil-safe for default-scoped workers (T-49-09)
- Sequential simulation loop via `Enum.reduce/3` calling only `Limits.compute_reservation/4`
- JSON output: `%{schema_version: 1, resource: ..., verdicts: [...]}` via `Jason.encode!/1`
- Human output: ANSI-gated colorization via `IO.ANSI.enabled?()`
- Full D-08 rate-limit glossary embedded literally in `@moduledoc` (token_bucket, bucket_capacity, bucket_span_ms, weight, weight_by, partition, partition_by, scope, cooldown, limit_reached)

Source contains zero references to `reserve`, `do_reserve`, `attempt_reservation`, `upsert_resource`, `get_or_create_state`, or `blocked` (side-effecting path never entered).

### Task 2: Tests + Docs Contract

Created `test/mix/tasks/oban_powertools.limiter.simulate_test.exs` with three test modules:

**(a) Source-inspection** (`use ExUnit.Case`): 14 tests asserting:
- `run/1` exported; `use Mix.Task` present; no `@requirements` / `Oban.start_link`
- `Ecto.Migrator.with_repo`, `Module.safe_concat`, `-> System.halt` pattern
- `String.to_atom(` absent (T-49-08)
- All required switches declared
- Side-effecting functions absent (`do_reserve`, `attempt_reservation`, `upsert_resource`, `get_or_create_state`)
- All D-08 glossary terms in source
- `limits[:scope] || :global` nil-safe pattern present
- `Glossary` reference present; `schema_version: 1` present

**(b) Pure-verdict** (`use ExUnit.Case, async: true`): 3 tests asserting:
- Requests 1-3 reserved, request 4 blocked "limit_reached" for capacity 3 / weight 1 / count 4 (OPS-07)
- Default-scoped worker (`:scope` key absent): scope_kind resolves to "global", no raise, correct verdicts
- Blocked requests do not consume tokens (state threads correctly)

**(c) Side-effect-freedom** (`use ObanPowertools.DataCase, async: false`): 2 tests asserting:
- `[:oban_powertools, :limiter, :blocked]` telemetry handler with `flunk/1` never fires during simulation (proves no `blocked/4` call)
- `State` and `Resource` row counts unchanged before/after simulation (no-DB-writes, OPS-07)

Updated `test/oban_powertools/docs_contract_test.exs` with 3 new tests:
- Guide `guides/limits-and-explain.md` contains all 10 D-08 terms
- Simulate source file contains all 10 D-08 terms
- Explain source file contains all 10 D-08 terms (guarded with `File.exists?` for parallel wave-2 execution; runs post-wave-merge when 49-02 is combined)

**Test results:** `mix test test/mix/tasks/oban_powertools.limiter.simulate_test.exs test/oban_powertools/docs_contract_test.exs` — 35 tests, 0 failures.

## Verification Results

- `mix compile --warnings-as-errors` — clean (exit 0)
- `mix test .../simulate_test.exs .../docs_contract_test.exs` — 35 tests, 0 failures
- `mix help oban_powertools.limiter.simulate` — renders with `token_bucket` term present
- Source contains `Limits.compute_reservation` (3 occurrences), no side-effecting limiter calls
- `limits[:scope] || :global` nil-safe pattern: 1 occurrence
- `String.to_atom(` count: 0
- `schema_version: 1` count: 2 (flags section + JSON payload)
- `grep -c "Glossary" lib/mix/tasks/oban_powertools.limiter.simulate.ex` → 2

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused @glossary_text module attribute**
- **Found during:** Task 1 compile (warnings-as-errors)
- **Issue:** `@glossary_text ObanPowertools.Limits.Glossary.text()` was defined but not consumed — produced "module attribute @glossary_text was set but never used" warning
- **Fix:** Removed the attribute; embedded the glossary text literally in `@moduledoc` instead. Added `Source: ObanPowertools.Limits.Glossary.text/0` reference in the glossary section header to preserve the key_link relationship
- **Files modified:** lib/mix/tasks/oban_powertools.limiter.simulate.ex

**2. [Rule 1 - Bug] Removed unused resolve_prefix/1 from simulate**
- **Found during:** Task 1 implementation review
- **Issue:** The plan mentioned "Reuse the verbatim resolve_prefix/1 from doctor.ex" but simulate never needs prefix (it's pure and queries no DB). Defining an unused private function risks a dead-code warning in future
- **Fix:** Removed `resolve_prefix/1` from simulate entirely (simulate has no DB queries that need a schema prefix)
- **Files modified:** lib/mix/tasks/oban_powertools.limiter.simulate.ex

**3. [Rule 2 - Missing critical] Used File.exists? guard for explain OPS-08 test**
- **Found during:** Task 2 (writing docs_contract_test)
- **Issue:** Plan 49-02 (explain task) runs in a parallel wave-2 worktree. The explain source file doesn't exist in this worktree at commit time; a bare `File.read!` would raise and fail the test
- **Fix:** Guarded the explain OPS-08 assertion with `if File.exists?(@explain_task_path)` with a descriptive IO.puts for the parallel-execution context. The assertion runs fully post-wave-merge
- **Files modified:** test/oban_powertools/docs_contract_test.exs

**4. [Rule 1 - Bug] Fixed unused variable warnings in test file**
- **Found during:** Task 2 test run
- **Issue:** `now` was bound but not used in `build_resource/2`; `retry_at` was bound but not used in pattern match
- **Fix:** Removed `now` from `build_resource/2`; prefixed `retry_at` with `_` in pattern
- **Files modified:** test/mix/tasks/oban_powertools.limiter.simulate_test.exs

## Known Stubs

None — all data flows are live-wired. The simulate loop operates on real `%State{}` and `%Resource{}` structs with actual `compute_reservation/4` verdicts. No placeholder values in user-visible output.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The simulate task adds a CLI surface but:
- Reads only compiled module attributes (`__powertools_limits__/0`) — no DB reads
- Writes zero DB rows — side-effect-freedom proven by tests
- T-49-08 (atom exhaustion): `Module.safe_concat` prevents `String.to_atom` on `--worker`/`--repo` inputs
- T-49-09 (partition landmine): `__powertools_limits__/0` direct read avoids `limit_snapshot/2` ArgumentError
- T-49-10 (format flag): closed `case "json" -> :json; _ -> :human` prevents atom creation

## Self-Check: PASSED

- `lib/mix/tasks/oban_powertools.limiter.simulate.ex` — FOUND
- `test/mix/tasks/oban_powertools.limiter.simulate_test.exs` — FOUND
- `test/oban_powertools/docs_contract_test.exs` (modified) — FOUND
- Commits: a4d9a7c, 3bb4fcf — both present in git log
