---
phase: 49-limiter-explain-simulate-cli
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/oban_powertools/limits.ex
  - lib/oban_powertools/limits/glossary.ex
  - lib/mix/tasks/oban_powertools.limiter.explain.ex
  - lib/mix/tasks/oban_powertools.limiter.simulate.ex
findings:
  critical: 1
  warning: 3
  info: 3
  total: 7
status: resolved
remediation:
  fixed: [CR-01, WR-01, WR-02, WR-03]
  deferred: [IN-01, IN-02, IN-03]
  commit: 357f68e
  note: "Critical + all 3 Warnings fixed with regression tests; 3 Info nitpicks deferred."
---

# Phase 49: Code Review Report

**Reviewed:** 2026-05-29
**Depth:** standard
**Files Reviewed:** 4 (production code)
**Status:** issues_found

## Summary

Reviewed the four production files for phase 49 (limiter explain/simulate CLI). The
side-effect-freedom claims on `compute_reservation/4` hold up: the pure core does no
`repo.`, `Telemetry.`, or `record_history_fact` calls, the `simulate` task drives only
`compute_reservation/4`, and the refactor of `attempt_reservation/5` normalizes the
bucket exactly once. Untrusted-input handling is generally sound — `Module.safe_concat`
guards module resolution, `Jason.decode/1` parses `--args` without atomizing keys, and
`--format` maps through a closed `case`.

However, there is one BLOCKER: the `explain --worker` path for a worker that has **no
limits configured** is unreachable dead code, so the task silently reports "runnable" and
exits 0 instead of the contracted exit 2. Three WARNINGs cover missing `--count`
validation (negative/zero produces nonsensical extra simulated requests), the
declared-but-unused `--prefix`/`--oban-name` flags (the plan said to wire `resolve_prefix/1`
but it was never implemented), and missing validation on numeric simulate overrides.

## Critical Issues

### CR-01: `explain --worker` no-limits path is dead code — wrong exit code for workers without `:limits`

**File:** `lib/mix/tasks/oban_powertools.limiter.explain.ex:219-232`
**Issue:** `run_worker_path/3` branches on the return value of
`ObanPowertools.Explain.explain/3`, expecting `{:ok, nil}` or `nil` when a worker has no
limits configured (returning exit 2 with "worker has no limits configured"). But
`Explain.explain/3` (lib/oban_powertools/explain.ex:59-73) never returns `{:ok, nil}` or
`nil`. For a worker with no limits, `Worker.limit_snapshot/2` returns `{:ok, nil}`, the
`with {:ok, snapshot} <-` clause binds `snapshot = nil` and proceeds (it does **not**
short-circuit), `live_blockers(repo, nil, now)` returns `[]`, and `explain/3` returns a
plain map: `%{status: :runnable, blockers: [], live_now: [], snapshot_at_block_start:
nil}`.

Consequently the `{:ok, nil}` and `nil` clauses are unreachable. A worker with no `:limits`
falls into the `is_map(explanation)` clause, prints "runnable", and **exits 0**. This
violates the phase contract truth "An unknown --worker module is a cannot-run error (exit
2)" and the broader D-02 posture that simulate/explain report a no-limits worker as a
cannot-run condition. Operators cannot distinguish "worker exists and is runnable" from
"worker has no limiter at all."

**Fix:** Detect the no-limits case by checking the snapshot before calling `explain/3`, or
by recognizing the empty-blocker/nil-snapshot signature. Cleanest is to call
`ObanPowertools.Worker.limit_snapshot/2` first:

```elixir
defp run_worker_path(repo, opts, format) do
  with {:ok, worker_mod} <- resolve_worker(opts),
       {:ok, parsed_args} <- parse_args_json(opts),
       {:ok, snapshot} when not is_nil(snapshot) <-
         ObanPowertools.Worker.limit_snapshot(worker_mod, parsed_args) do
    explanation = ObanPowertools.Explain.explain(worker_mod, parsed_args, repo: repo)
    normalized = normalize_status(explanation.status)
    print_explanation(%{explanation | status: normalized}, inspect(worker_mod), format)
    0
  else
    {:ok, nil} ->
      Mix.shell().error("worker has no limits configured")
      2

    {:error, :not_loaded, mod_string} ->
      Mix.shell().error("unknown --worker module: #{mod_string}")
      2

    {:error, :invalid_json} ->
      Mix.shell().error("--args must be a valid JSON object string (e.g. '{\"key\":\"value\"}')")
      2
  end
end
```

Note `Worker.limit_snapshot/2` can also raise `ArgumentError` for `partition_by: {:args,
key}` workers with empty args (the same Pitfall 4 the simulate task documents) — guard the
call or rescue and map to exit 2 so the path never crashes instead of returning 2.

## Warnings

### WR-01: `--count <= 0` produces nonsensical extra simulated requests

**File:** `lib/mix/tasks/oban_powertools.limiter.simulate.ex:173,216`
**Issue:** `count = Keyword.get(opts, :count, 1)` is passed unvalidated into
`Enum.reduce(1..count, ...)`. Elixir ranges with a higher start than stop default to step
`-1`, so `--count 0` iterates `1..0` → `[1, 0]` (two requests, including request "0"), and
`--count -2` iterates `1..-2` → `[1, 0, -1, -2]` (four requests with negative request
numbers). Instead of running zero simulations (or erroring on bad input per the D-02 exit-2
posture), the task emits garbage verdicts. Verified against the project's Elixir
(`Enum.to_list(1..0) == [1, 0]`).

**Fix:** Validate `count` is a positive integer at the boundary and return exit 2 on bad
input:

```elixir
count = Keyword.get(opts, :count, 1)

cond do
  not is_integer(count) or count < 1 ->
    Mix.shell().error("--count must be a positive integer")
    2

  true ->
    # ... run simulation
end
```

(`OptionParser` already enforces `:integer`, so the main risk is `<= 0`.)

### WR-02: `--prefix` / `--oban-name` flags declared and documented but never used

**File:** `lib/mix/tasks/oban_powertools.limiter.explain.ex:108-117,37-39`,
`lib/mix/tasks/oban_powertools.limiter.simulate.ex:103-114,32-34`
**Issue:** Both tasks declare `prefix:` and `oban_name:` switches and document them in
`@moduledoc` (the explain task even has a full "Prefix Resolution" section advising "Use
`--prefix` for reliable production results"), but neither task ever reads `:prefix` or
`:oban_name`, and neither defines or calls `resolve_prefix/1`. Plans 49-02 and 49-03
explicitly instructed "Reuse the verbatim `resolve_prefix/1` from doctor.ex" — this was not
done. The explain task queries `ObanPowertools.Explain` / `Resource` / `State` directly via
`repo.one`/`get_by`, none of which apply a schema prefix. The result: operators who pass
`--prefix` (trusting the documented contract) get silently ignored behavior. The
correctness impact is bounded because the powertools limiter tables
(`oban_powertools_blocker_snapshots`, etc.) live in the app's default schema rather than
the Oban prefix, and the reference `limiters_live.ex` queries them prefix-free too — so the
flags are misleading rather than data-corrupting.

**Fix:** Either (a) remove the `prefix`/`oban_name` switches and their `@moduledoc`
sections from both tasks since they are inert, or (b) if a future code path will read them,
add a `# reserved for parity with doctor; not yet consumed` note and stop documenting them
as production-affecting. Do not leave a documented flag that has no effect.

### WR-03: simulate numeric overrides (`--bucket-capacity`, `--bucket-span-ms`, `--weight`) accept zero/negative values without validation

**File:** `lib/mix/tasks/oban_powertools.limiter.simulate.ex:170-172`
**Issue:** `capacity`, `span_ms`, and `weight` are taken straight from `OptionParser`
integers (or the worker config) with no positivity check, unlike the worker macro which
enforces `validate_positive_integer!` on these fields (lib/oban_powertools/worker.ex:182-184).
`--bucket-span-ms 0` makes `normalize_bucket` reset the bucket every call (the
`DateTime.add(bucket_started_at, 0, ...)` reset_at equals start, so `now >= reset_at`
immediately) — every request reports "reserved" regardless of `--count`, which silently
misrepresents the modeled limiter. `--weight 0` lets reservations never advance
`tokens_used`. `--bucket-capacity 0` blocks everything. Because simulate is side-effect-free
the blast radius is "operator sees a wrong preview," but a preview tool that lies is a
quality defect.

**Fix:** Validate the effective values before simulating and return exit 2 with a clear
message on non-positive overrides, mirroring the worker macro's contract:

```elixir
with :ok <- positive!(capacity, "--bucket-capacity"),
     :ok <- positive!(span_ms, "--bucket-span-ms"),
     :ok <- positive!(weight, "--weight") do
  # run simulation
end
```

## Info

### IN-01: redundant `b[:retry_at] || b[:retry_at]` in JSON blocker serialization

**File:** `lib/mix/tasks/oban_powertools.limiter.explain.ex:325`
**Issue:** `retry_at: format_datetime(b[:retry_at] || b[:retry_at])` ORs a value with
itself — a copy-paste artifact. Functionally a no-op (likely meant `b[:retry_at] ||
b.retry_at` or just `b[:retry_at]`), but it signals the line was not reviewed.
**Fix:** Replace with `format_datetime(b[:retry_at])`.

### IN-02: dead defensive code — `limits[:scope]` is never nil

**File:** `lib/mix/tasks/oban_powertools.limiter.simulate.ex:335`
**Issue:** `scope_kind = (limits[:scope] || :global) |> Atom.to_string()` defends against a
nil `:scope`, but `Worker.normalize_limits_config!/2` requires `:scope` via `fetch_limit!`
and validates it is `:global` or `:partitioned` (lib/oban_powertools/worker.ex:167,178-180),
so `__powertools_limits__/0` always returns a non-nil atom scope. The `|| :global` branch is
unreachable. Harmless and arguably good defense-in-depth, but the plan's premise that "scope
is nil for default-scoped workers" is factually wrong — scope is always present.
**Fix:** Optional. Keep as defense-in-depth, or simplify to
`Atom.to_string(limits[:scope])` and drop the now-misleading comment.

### IN-03: `--weight` resolved twice (redundant but consistent)

**File:** `lib/mix/tasks/oban_powertools.limiter.simulate.ex:330,172`
**Issue:** `resolve_worker_config/2` already applies the `--weight` override into
`config.weight` (line 330: `Keyword.get(opts, :weight, limits[:default_weight] || 1)`), and
then `run_simulate/2` re-reads it (line 172: `Keyword.get(opts, :weight, config.weight)`).
Both default to the same resolved value so the outcome is correct, but the double resolution
is confusing and invites future drift if one is changed without the other.
**Fix:** Resolve `weight` in one place. Either have `resolve_worker_config/2` return the raw
`default_weight` and let `run_simulate/2` own the override, or drop the second
`Keyword.get`.

---

## Remediation (commit 357f68e)

- **CR-01 — FIXED.** `run_worker_path/3` now resolves the worker's declared snapshot via
  `Worker.limit_snapshot/2` first and exits 2 when it is `nil` ("worker has no limits
  configured"). The empty-args `ArgumentError` (partition_by/weight_by, Pitfall 4) is
  rescued to exit 2. Dead `:unknown_module`/`nil` clauses removed.
- **WR-01 — FIXED.** `--count` is validated as a positive integer (exit 2 otherwise).
- **WR-03 — FIXED.** `--bucket-capacity`/`--bucket-span-ms`/`--weight` effective values are
  validated positive via `validate_positive/1` (exit 2 otherwise).
- **WR-02 — FIXED.** Inert `--prefix`/`--oban-name` switches and their `@moduledoc`
  sections removed from both tasks.
- **IN-01/IN-02/IN-03 — DEFERRED** (cosmetic nitpicks; no behavioral impact).

Source-inspection regression tests added for CR-01 (explain) and WR-01/WR-03 (simulate).

_Reviewed: 2026-05-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
