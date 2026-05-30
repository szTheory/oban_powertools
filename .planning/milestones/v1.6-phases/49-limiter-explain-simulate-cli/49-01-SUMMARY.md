---
phase: 49-limiter-explain-simulate-cli
plan: "01"
subsystem: limits
tags: [pure-function, refactor, glossary, tdd]
dependency_graph:
  requires: []
  provides:
    - ObanPowertools.Limits.compute_reservation/4
    - ObanPowertools.Limits.Glossary.text/0
  affects:
    - lib/oban_powertools/limits.ex
    - lib/oban_powertools/limits/glossary.ex
    - guides/limits-and-explain.md
tech_stack:
  added: []
  patterns:
    - Pure function extraction (side-effect-free token-bucket decision core)
    - Single-source glossary string via module attribute + text/0
key_files:
  created:
    - lib/oban_powertools/limits/glossary.ex
    - test/oban_powertools/limits/glossary_test.exs
  modified:
    - lib/oban_powertools/limits.ex
    - guides/limits-and-explain.md
    - test/oban_powertools/limits_test.exs
decisions:
  - "compute_reservation/4 lives in ObanPowertools.Limits (not a submodule) to minimize diff surface"
  - "attempt_reservation/5 normalizes the bucket exactly once then passes normalized_state to compute_reservation"
  - "Glossary uses @text module attribute exposed via text/0 (Option A from RESEARCH.md)"
  - "Helper functions build_pure_resource/1 and build_pure_state/1 placed at module level not inside describe block"
metrics:
  duration: 8m
  completed: "2026-05-29"
  tasks: 2
  files: 5
---

# Phase 49 Plan 01: Pure Core + Glossary Summary

Pure token-bucket decision core extracted from `attempt_reservation/5` into public `compute_reservation/4` with zero side effects; single-source D-08 glossary established via `ObanPowertools.Limits.Glossary` with all required terms, embedded verbatim in the guide.

## Tasks Completed

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | Extract pure compute_reservation/4 (TDD) | ac0c836 (RED), a83bc61 (GREEN) | Complete |
| 2 | Create Glossary module and embed in guide | 9586818 | Complete |

## What Was Built

### Task 1: Pure compute_reservation/4

Added `def compute_reservation(%State{} = state, %Resource{} = resource, weight, now)` to `ObanPowertools.Limits`. The function:
- Calls `normalize_bucket/3` (private) to reset expired buckets
- Returns `{:reserved, tokens_used_after}` when capacity permits
- Returns `{:blocked, "cooldown", retry_at, %{reason: ...}}` when cooldown is active
- Returns `{:blocked, "limit_reached", retry_at, %{capacity: ..., used: ...}}` when saturated
- Contains zero repo calls, zero `Telemetry.`, zero `record_history_fact` — proven by telemetry-handler test

Refactored `attempt_reservation/5` to:
1. Call `normalize_bucket` exactly once up front, binding `normalized_state`
2. Delegate the decision to `compute_reservation(normalized_state, resource, snapshot.weight, now)`
3. On `{:reserved, new_tokens_used}` — perform `repo.update` changeset against `normalized_state`
4. On `{:blocked, "cooldown", ...}` — call `cooldown_blocker(resource, normalized_state)` then `blocked/4`
5. On `{:blocked, _, ...}` — call `limit_blocker(resource, normalized_state, now)` then `blocked/4`

6 new tests added covering: fresh reservation, token accumulation, saturation, bucket expiry/normalization, cooldown precedence, and a telemetry-handler assertion proving zero side effects.

### Task 2: Glossary Module + Guide Section

Created `ObanPowertools.Limits.Glossary` with:
- `@text` module attribute containing the full D-08 glossary in markdown
- Public `text/0` function returning the canonical string
- All 10 required D-08 terms present: `token_bucket`, `bucket_capacity`, `bucket_span_ms`, `weight`, `weight_by`, `partition`, `partition_by`, `scope`, `cooldown`, `limit_reached`

Updated `guides/limits-and-explain.md` with `## Rate-Limit Glossary` section containing verbatim definitions for all required terms.

Created `test/oban_powertools/limits/glossary_test.exs` with 23 tests asserting both `Glossary.text()` and the guide file contain every D-08 required term.

## TDD Gate Compliance

Task 1 followed the RED/GREEN/REFACTOR cycle:
- RED: `test(49-01)` commit ac0c836 — 6 tests failing with `UndefinedFunctionError`
- GREEN: `feat(49-01)` commit a83bc61 — all 11 tests passing

## Verification Results

- `mix test test/oban_powertools/limits_test.exs test/oban_powertools/limits/glossary_test.exs` — 34 tests, 0 failures
- `mix compile --warnings-as-errors` — clean, 0 warnings
- `grep -n "def compute_reservation(" lib/oban_powertools/limits.ex` — exactly 1 public definition
- `grep -c "defp normalize_bucket" lib/oban_powertools/limits.ex` — 1 (remains private)
- `grep -c "defp cooldown_active?" lib/oban_powertools/limits.ex` — 1 (remains private)
- No `repo.`, `Telemetry.`, or `record_history_fact` in `compute_reservation/4` body
- `attempt_reservation/5` calls `normalize_bucket(` exactly once (confirmed via awk)
- `attempt_reservation/5` calls `compute_reservation(` (confirmed via grep)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all data is live-wired. `compute_reservation/4` operates on real `%State{}` and `%Resource{}` structs. Glossary text is literal content, not placeholders.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The pure function adds a new public API surface but it is computation-only with no trust boundary crossing.

## Self-Check: PASSED

- `lib/oban_powertools/limits/glossary.ex` — FOUND
- `test/oban_powertools/limits/glossary_test.exs` — FOUND
- `lib/oban_powertools/limits.ex` (compute_reservation/4) — FOUND
- `guides/limits-and-explain.md` (Rate-Limit Glossary section) — FOUND
- Commits: ac0c836, a83bc61, 9586818 — all present in git log
