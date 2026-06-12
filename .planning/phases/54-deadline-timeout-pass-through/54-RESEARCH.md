# Phase 54: deadline: / timeout: Pass-through - Research

**Researched:** 2026-06-12  
**Domain:** Elixir Oban worker macro, enqueue metadata, and Doctor PostgreSQL diagnostics  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Timeout Semantics
- **D-01:** `timeout:` is a compile-time worker default in milliseconds. It must
  generate a `timeout/1` callback that returns the configured value and lets
  Oban 2.23's existing executor enforce the kill timer.
- **D-02:** Do not pass `timeout:` through to `Oban.Job.new/2` or queue/runtime
  options. Oban treats timeout as a worker callback, not a job changeset option.
- **D-03:** The generated timeout callback should remain overridable by an
  explicitly defined host `timeout/1` callback. Host-defined dynamic timeout
  logic is the escape hatch for advanced per-job behavior.
- **D-04:** Validate timeout values as positive integer milliseconds when a
  default is declared. Absence of `timeout:` keeps Oban's default `:infinity`.

### Deadline Semantics
- **D-05:** `deadline:` is a soft wall-clock expiry, not an execution-duration
  timeout. It prevents stale queued work from starting; it never interrupts a
  job that is already running.
- **D-06:** `deadline:` stores `meta["__deadline_at__"]` as an ISO8601 UTC
  timestamp at Powertools enqueue time. The timestamp is derived from enqueue
  time plus the declared deadline duration.
- **D-07:** The deadline duration should accept the roadmap style
  `deadline: :timer.hours(24)` and normalize to positive integer milliseconds
  for runtime use.
- **D-08:** Existing caller `meta` must be preserved, but Powertools reserved
  keys win. A host-supplied `__deadline_at__` must not spoof or override the
  worker's declared deadline.
- **D-09:** Deadline metadata belongs at top-level Oban job meta as
  `__deadline_at__`, matching the requirement and keeping the value visible in
  the existing job detail meta rendering.

### Wrapper Ordering
- **D-10:** Deadline expiry is checked after args validation/casting and before
  `on_start/1`, `process/1`, output recording, or any post hook. Expired jobs
  should not trigger host lifecycle hooks because no host execution is starting.
- **D-11:** If `__deadline_at__` is in the past, `perform/1` returns
  `{:cancel, :deadline_expired}` without calling `process/1`.
- **D-12:** Deadline cancellation follows Phase 53's locked cancellation
  semantics: `{:cancel, reason}` does not route to `on_failure/2` or
  `on_discard/2`.
- **D-13:** Malformed or missing deadline meta must not crash the job wrapper.
  Powertools-generated meta should be parseable; host-corrupted or bypassed
  meta should be handled defensively and leave normal execution behavior intact.

### Idempotency and Enqueue Path
- **D-14:** Keep the idempotency fingerprint based on validated args and worker
  identity. Adding deadline meta must not change the fingerprint or duplicate
  semantics.
- **D-15:** Deadline metadata is added in the existing
  `ObanPowertools.Idempotency.transaction/3` path before `worker_mod.new/2`
  builds the Oban job changeset.
- **D-16:** Deadline expiry does not invalidate active idempotency receipts. A
  duplicate enqueue while a receipt is active should still return the existing
  conflict; fresh deadline behavior comes after the receipt window allows a new
  job.

### Doctor Integration
- **D-17:** `mix oban_powertools.doctor` reports `retryable` jobs whose
  parseable `meta["__deadline_at__"]` is already past as a warning.
- **D-18:** The deadline doctor check should be read-only and prefix-aware,
  following the existing `Doctor.Checks` pattern.
- **D-19:** Do not broaden `--strict` semantics unless planning explicitly
  updates the CLI contract. The existing docs scope `--strict` to the
  uniqueness-timeout risk check; expired deadlines should remain warnings.
- **D-20:** The doctor check should never fail the whole run because a host
  inserted malformed deadline metadata. Query errors are findings; malformed
  values should be ignored or surfaced as bounded warnings, not crashes.

### Support Truth
- **D-21:** Document the distinction clearly: `timeout:` is per-attempt runtime
  enforced by Oban and can produce `Oban.TimeoutError`; `deadline:` is
  Powertools soft pre-run cancellation.
- **D-22:** Document that Oban timeout kills may bypass worker hooks, as locked
  in Phase 53. Timeout observability belongs to Oban job exception telemetry,
  not Powertools lifecycle hooks.
- **D-23:** Do not add a Powertools telemetry family for deadline expiry in this
  phase unless a later plan proves it is required. SAFE-01 through SAFE-04 do
  not require a new public telemetry contract.

### Tests and Documentation
- **D-24:** Worker tests must prove generated `timeout/1`, timeout validation,
  deadline meta insertion, deadline pre-run cancellation, and no `process/1` or
  hook dispatch for expired jobs.
- **D-25:** Idempotency tests must prove deadline meta coexists with existing
  limiter/idempotency meta and does not perturb duplicate detection.
- **D-26:** Doctor tests must cover expired retryable jobs, non-expired
  retryable jobs, malformed meta, prefix handling, formatter output, JSON
  schema stability, and CLI docs.
- **D-27:** Update worker and doctor docs with support-truth language for
  timeout units, soft deadline behavior, and the absence of hard interruption.

### the agent's Discretion
- The user approved the locked-context path after analysis found no material
  unresolved gray areas. Downstream agents should implement the recommendation
  set above rather than reopening ordinary implementation choices.

### Deferred Ideas (OUT OF SCOPE)
No deferred ideas section was present in `54-CONTEXT.md`. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SAFE-01 | Worker can declare `timeout: milliseconds` in `use ObanPowertools.Worker` opts to generate a compile-time `timeout/1` callback default. [VERIFIED: .planning/REQUIREMENTS.md] | Oban `timeout/1` is a worker callback returning `:infinity | pos_integer()`, and Oban's executor calls it before `perform/1`. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [VERIFIED: deps/oban/lib/oban/worker.ex, deps/oban/lib/oban/queue/executor.ex] |
| SAFE-02 | Worker can declare `deadline: duration`; job stores `__deadline_at__` ISO8601 timestamp in meta at enqueue time. [VERIFIED: .planning/REQUIREMENTS.md] | `Oban.Job.new/2` accepts `:meta`, and the current Powertools enqueue path merges meta before `worker_mod.new/2`. [CITED: https://hexdocs.pm/oban/Oban.Job.html] [VERIFIED: lib/oban_powertools/idempotency.ex] |
| SAFE-03 | `perform/1` checks `__deadline_at__` before `process/1`; returns `{:cancel, :deadline_expired}` when expired. [VERIFIED: .planning/REQUIREMENTS.md] | Current generated `perform/1` validates and casts args before calling `__powertools_perform__/1`; the deadline check belongs at the top of `__powertools_perform__/1`, before hook dispatch. [VERIFIED: lib/oban_powertools/worker.ex] |
| SAFE-04 | Doctor surfaces `retryable` jobs whose `__deadline_at__` has passed as a warning. [VERIFIED: .planning/REQUIREMENTS.md] | Existing Doctor checks are read-only repo queries returning `%Finding{}` values and composed by `Doctor.run/2`; add one warning-producing check. [VERIFIED: lib/oban_powertools/doctor.ex, lib/oban_powertools/doctor/checks.ex] |
</phase_requirements>

## Summary

Use no new dependencies. [VERIFIED: .planning/STATE.md, .planning/PROJECT.md] Implement `timeout:` entirely in `ObanPowertools.Worker.__using__/1` by stripping the Powertools-only option before `use Oban.Worker`, validating it as a positive integer, generating `timeout/1`, and marking it `defoverridable` so host workers can replace it. [VERIFIED: lib/oban_powertools/worker.ex] Oban 2.23.0 already enforces worker `timeout/1` through `:timer.exit_after/2` and converts expiry into `Oban.TimeoutError`. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [VERIFIED: deps/oban/lib/oban/queue/executor.ex]

Implement `deadline:` as Powertools metadata and wrapper control flow, not as an Oban option. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md] The enqueue seam is `ObanPowertools.Idempotency.transaction/3`: it validates args, computes the fingerprint, reserves limits, merges meta, builds `worker_mod.new/2`, and inserts the job. [VERIFIED: lib/oban_powertools/idempotency.ex] Add `__deadline_at__` there after fingerprint calculation and before `worker_mod.new/2`, ensuring Powertools reserved keys win over caller-supplied meta. [VERIFIED: lib/oban_powertools/idempotency.ex]

For execution, check parsed deadline metadata after validation/casting and before `on_start/1` or `process/1`. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md] If expired, return `{:cancel, :deadline_expired}` and do not dispatch Phase 53 lifecycle hooks. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] Doctor should add a read-only prefix-aware warning for retryable jobs with expired, parseable `meta["__deadline_at__"]`, without changing `--strict`. [VERIFIED: lib/mix/tasks/oban_powertools.doctor.ex]

**Primary recommendation:** Add a small internal deadline helper plus scoped changes in `Worker`, `Idempotency`, and `Doctor.Checks`; do not add new tables, timers, telemetry families, or dependencies. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists in the repository root, so there are no additional project-level agent directives to enforce. [VERIFIED: shell `test -f AGENTS.md`]

Project-local skill directories `.codex/skills/` and `.agents/skills/` were absent, so no project skill rules apply. [VERIFIED: shell `find .codex/skills .agents/skills -maxdepth 2 -name SKILL.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Compile-time `timeout:` worker option | API / Backend | Oban executor | Worker macro owns generated callbacks; Oban executor owns runtime kill enforcement. [VERIFIED: lib/oban_powertools/worker.ex] [VERIFIED: deps/oban/lib/oban/queue/executor.ex] |
| Enqueue-time deadline timestamp | API / Backend | Database / Storage | Powertools enqueue transaction computes metadata; `oban_jobs.meta` persists it. [VERIFIED: lib/oban_powertools/idempotency.ex] [VERIFIED: deps/oban/lib/oban/job.ex] |
| Pre-run deadline cancellation | API / Backend | Oban executor | Generated `perform/1` wrapper decides whether host work starts; Oban records `{:cancel, reason}` as cancellation. [VERIFIED: lib/oban_powertools/worker.ex] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Doctor expired deadline warning | API / Backend | Database / Storage | Doctor runs read-only SQL against `oban_jobs`; formatter renders findings. [VERIFIED: lib/oban_powertools/doctor.ex] [VERIFIED: lib/oban_powertools/doctor/checks.ex] |
| Job detail visibility | Browser / Client | API / Backend | Existing job detail renders meta through DisplayPolicy; storing top-level meta makes value visible without a new data model. [VERIFIED: lib/oban_powertools/web/jobs_live.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Macro compilation, test runner, DateTime helpers. | Project is an Elixir library using Mix; local runtime verified. [VERIFIED: shell `elixir --version`, `mix --version`] |
| Oban | 2.23.0 | Worker callback contract, job changesets, execution timeout enforcement. | Locked dependency; official docs and vendored source confirm `timeout/1`, `new/2`, `meta`, and `{:cancel, reason}` semantics. [VERIFIED: mix deps + Hex] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Ecto SQL | 3.14.0 | Doctor read-only SQL queries and test database access. | Existing Doctor uses repo queries and `Ecto.Migrator.with_repo/2`. [VERIFIED: mix deps + Hex] [VERIFIED: lib/mix/tasks/oban_powertools.doctor.ex] |
| Postgrex | 0.22.2 | PostgreSQL driver for Doctor and test DB. | Locked driver; test DB is reachable on local PostgreSQL. [VERIFIED: mix deps + Hex] [VERIFIED: shell `pg_isready`] |
| Jason | 1.4.5 | JSON encoding for existing fingerprint canonicalization and Doctor JSON output. | Existing code already uses Jason for fingerprints and formatter output; no new JSON dependency needed. [VERIFIED: mix deps] [VERIFIED: lib/oban_powertools/idempotency.ex, lib/oban_powertools/doctor/formatter.ex] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | 1.19.5 | Worker macro, idempotency, Doctor, and CLI tests. | Use for all Phase 54 tests. [VERIFIED: shell `mix test --help`] |
| Ecto SQL Sandbox | 3.14.0 | Database test isolation. | Existing `DataCase` checks out `ObanPowertools.TestRepo` sandbox for DB tests. [VERIFIED: test/support/data_case.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Oban `timeout/1` callback | Custom task or timer around `process/1` | Rejected because Oban already enforces worker timeouts and Phase 54 locks pass-through semantics. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md] |
| Top-level `meta["__deadline_at__"]` | New Powertools table or nested meta namespace | Rejected because requirement names top-level meta and existing job detail already renders meta. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/oban_powertools/web/jobs_live.ex] |
| Soft pre-run cancellation | Hard mid-execution deadline | Rejected as out of scope; hard interruption requires additional supervision complexity and is deferred. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/PROJECT.md] |

**Installation:**
```bash
# No new packages. Phase 54 uses existing locked dependencies.
mix deps.get
```

**Version verification:** `mix deps`, `mix hex.info oban`, `mix hex.info ecto_sql`, and `mix hex.info postgrex` verified Oban 2.23.0, Ecto SQL 3.14.0, Postgrex 0.22.2, and Jason 1.4.5 in the active dependency graph. [VERIFIED: command output]

## Package Legitimacy Audit

No external packages are recommended for installation in this phase, so the Package Legitimacy Gate is not applicable. [VERIFIED: .planning/STATE.md] Existing package names above are already present in `mix.exs` and `mix.lock`; they are not new install recommendations. [VERIFIED: mix.exs, mix.lock]

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: no new packages recommended]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no new packages recommended]

## Architecture Patterns

### System Architecture Diagram

```text
Worker module compile
  -> use ObanPowertools.Worker(opts)
    -> strip Powertools-only :timeout and :deadline
    -> validate timeout/deadline positive integer milliseconds
    -> use Oban.Worker(oban_opts)
    -> generate overridable timeout/1 when configured
    -> expose internal __powertools_deadline_ms__/0

enqueue(args, opts)
  -> Idempotency.transaction(worker, args, opts)
    -> validate args
    -> compute fingerprint from validated args
    -> reserve limits
    -> merge caller meta + limits meta + deadline meta
    -> worker_mod.new(args_map, opts_with_meta)
    -> repo.insert(oban job)

Oban executor starts attempt
  -> worker.timeout(job)
    -> Oban :timer.exit_after(timeout)
  -> worker.perform(job)
    -> validate/cast args
    -> parse meta["__deadline_at__"]
      -> expired? yes -> return {:cancel, :deadline_expired}
      -> expired? no/missing/malformed -> on_start -> process -> hooks

mix oban_powertools.doctor
  -> Ecto.Migrator.with_repo
    -> Doctor.run(repo, prefix)
      -> existing checks
      -> expired_deadline_jobs(repo, prefix)
        -> read-only oban_jobs query for retryable + expired deadline meta
    -> Formatter human/json
```

### Recommended Project Structure

```text
lib/
├── oban_powertools/
│   ├── worker.ex                 # macro option normalization, generated timeout, perform ordering
│   ├── worker/
│   │   └── deadlines.ex          # recommended helper for normalize/compute/expired? parsing
│   ├── idempotency.ex            # enqueue-time deadline meta merge
│   └── doctor/
│       ├── checks.ex             # expired retryable deadline warning
│       └── formatter.ex          # likely no schema change, but tests should assert output
└── mix/tasks/
    └── oban_powertools.doctor.ex # CLI docs and severity table update
```

### Pattern 1: Macro-owned Option Normalization

**What:** Extract `:timeout` and `:deadline` before passing options to `use Oban.Worker`; validate them in the outer macro context. [VERIFIED: lib/oban_powertools/worker.ex]  
**When to use:** Any Powertools compile-time option that Oban does not accept as a worker option. [VERIFIED: deps/oban/lib/oban/worker.ex]

**Example:**
```elixir
# Source: deps/oban/lib/oban/worker.ex + lib/oban_powertools/worker.ex
timeout_config = Keyword.get(opts, :timeout)
deadline_config = Keyword.get(opts, :deadline)

oban_opts =
  opts
  |> Keyword.delete(:args)
  |> Keyword.delete(:limits)
  |> Keyword.delete(:timeout)
  |> Keyword.delete(:deadline)
```

### Pattern 2: Overridable Generated Timeout

**What:** Generate `timeout/1` only when `timeout:` is configured and include it in `defoverridable`. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]  
**When to use:** Worker has a static default but may need host dynamic override. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]

**Example:**
```elixir
# Source: https://hexdocs.pm/oban/Oban.Worker.html
@impl Oban.Worker
def timeout(_job), do: unquote(timeout_ms)

defoverridable timeout: 1
```

### Pattern 3: Metadata Merge With Reserved-Key Precedence

**What:** Merge caller meta first, then Powertools meta so reserved keys cannot be spoofed. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]  
**When to use:** Adding `__deadline_at__` in `Idempotency.transaction/3`. [VERIFIED: lib/oban_powertools/idempotency.ex]

**Example:**
```elixir
# Source: lib/oban_powertools/idempotency.ex
caller_meta = Keyword.get(opts, :meta, %{})
powertools_meta = %{"__deadline_at__" => DateTime.to_iso8601(deadline_at)}

Keyword.put(opts, :meta, deep_merge(caller_meta, powertools_meta))
```

### Pattern 4: Prefix-Aware Read-Only Doctor Check

**What:** Use parameterized SQL for values and validate schema identifiers before interpolation. [VERIFIED: lib/oban_powertools/doctor/checks.ex]  
**When to use:** Querying `prefix.oban_jobs` for expired retryable deadlines. [VERIFIED: lib/oban_powertools/doctor/checks.ex]

**Example:**
```elixir
# Source: lib/oban_powertools/doctor/checks.ex
if valid_identifier?(prefix) do
  sql = """
  SELECT id, worker, meta->>$1
  FROM #{prefix}.oban_jobs
  WHERE state = 'retryable'
    AND meta ? $1
  """

  repo.query(sql, ["__deadline_at__"], log: false)
end
```

### Anti-Patterns to Avoid

- **Passing `:timeout` to `Oban.Job.new/2`:** Oban job options include `:meta`, `:queue`, `:scheduled_at`, and related fields, not `:timeout`; timeout is a worker callback. [VERIFIED: deps/oban/lib/oban/job.ex] [CITED: https://hexdocs.pm/oban/Oban.Job.html]
- **Checking deadline before args validation:** Phase context requires validation/casting first, then deadline check. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]
- **Dispatching hooks for deadline cancellation:** Phase 53 cancellation semantics say `{:cancel, reason}` does not route to `on_failure/2` or `on_discard/2`; Phase 54 specifically avoids `on_start/1` for expired jobs. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]
- **Making malformed deadline meta crash jobs or Doctor:** Locked decision D-13 and D-20 require defensive parsing. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-attempt execution kill timer | Custom `Task`, `Process.exit`, GenServer watchdog, or supervision tree | Oban worker `timeout/1` callback | Oban already starts and cancels a timeout timer around execution. [VERIFIED: deps/oban/lib/oban/queue/executor.ex] |
| ISO8601 timestamp formatting | Custom string formatting | `DateTime.to_iso8601/1` | Elixir standard library already emits ISO8601 DateTime strings. [ASSUMED] |
| Deadline parsing | Ad hoc string comparisons | `DateTime.from_iso8601/1`, then `DateTime.compare/2` or `DateTime.diff/3` | Comparing parsed DateTimes avoids lexical/timezone mistakes. [ASSUMED] |
| JSON output for Doctor | Manual JSON concatenation | Existing `Doctor.Formatter` + Jason | Formatter already maps findings to schema-versioned JSON. [VERIFIED: lib/oban_powertools/doctor/formatter.ex] |
| Prefix-safe SQL helper | Raw interpolation of arbitrary CLI prefix | Existing `valid_identifier?/1` pattern before interpolation | Current Doctor already defends prefix interpolation. [VERIFIED: lib/oban_powertools/doctor/checks.ex] |

**Key insight:** Oban already owns hard per-attempt execution timeouts; Powertools only needs to improve declaration ergonomics and add soft stale-work cancellation. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Letting Powertools Options Reach Oban Validation
**What goes wrong:** `:deadline` or `:timeout` remains in `oban_opts`, and Oban's worker option validation may reject unknown options or treat public behavior incorrectly. [VERIFIED: deps/oban/lib/oban/worker.ex]  
**Why it happens:** Current macro strips only `:args` and `:limits`. [VERIFIED: lib/oban_powertools/worker.ex]  
**How to avoid:** Delete `:timeout` and `:deadline` before `use Oban.Worker`. [VERIFIED: lib/oban_powertools/worker.ex]  
**Warning signs:** Compile failures around Oban worker option validation or unexpected `__opts__/0` contents. [VERIFIED: deps/oban/lib/oban/worker.ex]

### Pitfall 2: Perturbing Idempotency Fingerprints
**What goes wrong:** Deadline metadata changes duplicate detection or causes an enqueue conflict to behave differently. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]  
**Why it happens:** Fingerprint generation hashes worker identity and validated args; adding deadline before hashing would change the payload if mixed into args. [VERIFIED: lib/oban_powertools/idempotency.ex]  
**How to avoid:** Compute fingerprint exactly as now, then merge deadline into meta before `worker_mod.new/2`. [VERIFIED: lib/oban_powertools/idempotency.ex]  
**Warning signs:** Existing duplicate enqueue tests fail or two enqueues with same args create different jobs only because deadline time advanced. [VERIFIED: test/oban_powertools/idempotency_test.exs]

### Pitfall 3: Deadline Cancellation Fires Hooks
**What goes wrong:** Expired jobs run `on_start/1`, `on_failure/2`, or `on_discard/2`, causing host side effects for work that never started. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]  
**Why it happens:** Deadline check is inserted after `on_start/1` or implemented as `process/1` wrapper logic. [VERIFIED: lib/oban_powertools/worker.ex]  
**How to avoid:** Put deadline check as the first step inside `__powertools_perform__/1`, before hook dispatch. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]  
**Warning signs:** Tests receive hook/process messages for expired jobs. [VERIFIED: test/oban_powertools/worker_test.exs]

### Pitfall 4: Treating Malformed Metadata as Fatal
**What goes wrong:** Jobs inserted outside Powertools or manually edited crash during `perform/1`, or Doctor aborts instead of returning findings. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]  
**Why it happens:** `DateTime.from_iso8601/1` failure is pattern-matched too strictly or SQL casts invalid JSONB text. [ASSUMED]  
**How to avoid:** In worker execution, malformed or missing deadline means normal execution; in Doctor, filter in Elixir or use SQL guarded enough that malformed values do not crash the whole run. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]  
**Warning signs:** A single bad `meta["__deadline_at__"]` produces a job error or Doctor exception. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]

### Pitfall 5: Broadening `--strict`
**What goes wrong:** Existing CI users see expired deadline warnings promoted to errors under `--strict`, changing the CLI contract. [VERIFIED: lib/mix/tasks/oban_powertools.doctor.ex]  
**Why it happens:** New Doctor check reuses uniqueness-timeout severity logic. [VERIFIED: lib/oban_powertools/doctor/checks.ex]  
**How to avoid:** Expired deadlines are always warnings unless a future phase explicitly changes the CLI contract. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]  
**Warning signs:** `--strict` test expectations change outside uniqueness-timeout risk. [VERIFIED: test/oban_powertools/doctor/checks_test.exs]

## Code Examples

Verified patterns from official or repo sources:

### Oban Timeout Callback
```elixir
# Source: https://hexdocs.pm/oban/Oban.Worker.html
@impl Oban.Worker
def timeout(_job), do: :timer.seconds(30)
```

### Existing Enqueue Meta Merge Extension Point
```elixir
# Source: lib/oban_powertools/idempotency.ex
job_changeset =
  worker_mod.new(args_map, merge_limits_meta(opts, worker_mod, args, fingerprint))
```

### Existing Doctor Finding Shape
```elixir
# Source: lib/oban_powertools/doctor/checks.ex
%ObanPowertools.Doctor.Finding{
  check: :expired_deadline_jobs,
  severity: :warning,
  message: "Retryable job has expired __deadline_at__ metadata",
  remediation: "Allow the next attempt to cancel or manually cancel stale jobs."
}
```

### Existing Perform Wrapper Insertion Point
```elixir
# Source: lib/oban_powertools/worker.ex
defp __powertools_perform__(%Oban.Job{} = job) do
  with :ok <- ObanPowertools.Worker.Deadlines.allow_start?(job) do
    ObanPowertools.Worker.Hooks.on_start(__MODULE__, job)
    result = process(job)
    ObanPowertools.Worker.Hooks.after_result(__MODULE__, job, result)
    result
  else
    {:cancel, :deadline_expired} -> {:cancel, :deadline_expired}
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Host workers hand-write `timeout/1` when they need a kill timer. | Powertools generates a default `timeout/1`, while host override remains possible. | Phase 54 planning, 2026-06-12. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md] | Better DX without replacing Oban enforcement. |
| Earlier milestone research suggested checking deadline around `on_start` and older return wording. | Phase 54 context locks check before `on_start/1` and return `{:cancel, :deadline_expired}`. | Phase 54 context, 2026-06-12. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md] | Planner must follow Phase 54, not older research. |
| Doctor only reports index/migration/table/uniqueness health. | Add expired retryable deadline warning. | Phase 54. [VERIFIED: .planning/REQUIREMENTS.md] | Operators see jobs that will cancel on next attempt. |

**Deprecated/outdated:**
- `{:discard, :deadline_exceeded}` from older research is outdated; use `{:cancel, :deadline_expired}`. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]
- Deadline check after `on_start/1` is outdated; check before lifecycle hooks. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `DateTime.to_iso8601/1`, `DateTime.from_iso8601/1`, and `DateTime.compare/2` are the right standard library helpers for deadline formatting and parsing. | Don't Hand-Roll | Low; implementation can verify against Elixir docs while coding. |
| A2 | SQL casting invalid ISO8601 strings directly may raise, so malformed Doctor metadata should be filtered defensively. | Common Pitfalls | Medium; planner should include a test with malformed deadline meta before finalizing query shape. |

## Open Questions

1. **Should malformed deadline metadata be ignored or warning-surfaced in Doctor?**
   - What we know: Phase context allows ignored or bounded warnings, but requires no crash. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]
   - What's unclear: The exact operator UX for malformed host-corrupted meta is not locked. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]
   - Recommendation: Ignore malformed values in the expired-deadline count for Phase 54 unless tests show a cheap bounded warning can be added without noisy false positives. [ASSUMED]

2. **Should the Doctor warning list individual job ids or aggregate count?**
   - What we know: Current Doctor findings are human-readable single findings and JSON entries with stable schema version 1. [VERIFIED: lib/oban_powertools/doctor/formatter.ex]
   - What's unclear: Phase context requires a warning, not exact message granularity. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md]
   - Recommendation: Emit one aggregate warning including count and prefix to avoid excessive output for large queues. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile and tests | Yes | 1.19.5 | None |
| Mix | Compile and tests | Yes | 1.19.5 | None |
| PostgreSQL server | Doctor/idempotency DB tests | Yes | `/tmp:5432 accepting connections` | None |
| psql | Manual DB inspection | Yes | 14.17 | Ecto SQL queries |
| ctx7 | Documentation lookup fallback | No | - | Official HexDocs and vendored source used |

**Missing dependencies with no fallback:** none for planning. [VERIFIED: environment probes]  
**Missing dependencies with fallback:** `ctx7`; official HexDocs and `deps/oban` source were used. [VERIFIED: shell `ctx7 not found`] [CITED: https://hexdocs.pm/oban/Oban.Worker.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit 1.19.5 with Ecto SQL Sandbox. [VERIFIED: shell `mix test --help`, test/support/data_case.ex] |
| Config file | `test/test_helper.exs` bootstraps migrations and `ObanPowertools.TestRepo`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/oban_powertools/worker_test.exs test/oban_powertools/idempotency_test.exs test/oban_powertools/doctor/checks_test.exs --trace` |
| Full suite command | `mix test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SAFE-01 | Worker `timeout: 5_000` generates default `timeout/1`, validates positive integer, and host `timeout/1` override wins. | unit | `mix test test/oban_powertools/worker_test.exs --trace` | Yes, extend |
| SAFE-02 | Worker `deadline: :timer.hours(24)` stores top-level `meta["__deadline_at__"]` ISO8601 and preserves existing meta with reserved-key precedence. | integration | `mix test test/oban_powertools/idempotency_test.exs --trace` | Yes, extend |
| SAFE-03 | Expired `__deadline_at__` returns `{:cancel, :deadline_expired}` without `process/1` or hooks; malformed/missing metadata runs normally. | unit | `mix test test/oban_powertools/worker_test.exs --trace` | Yes, extend |
| SAFE-04 | Doctor reports expired retryable deadlines as warnings and does not alter strict semantics. | integration | `mix test test/oban_powertools/doctor/checks_test.exs test/oban_powertools/doctor/formatter_test.exs test/mix/tasks/oban_powertools.doctor_test.exs --trace` | Yes, extend |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/worker_test.exs test/oban_powertools/idempotency_test.exs test/oban_powertools/doctor/checks_test.exs --trace`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `$gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/oban_powertools/worker_test.exs` - add timeout/deadline worker modules and wrapper-order assertions. [VERIFIED: existing file]
- [ ] `test/oban_powertools/idempotency_test.exs` - add deadline meta/fingerprint coexistence tests. [VERIFIED: existing file]
- [ ] `test/oban_powertools/doctor/checks_test.exs` - add expired, non-expired, malformed, and prefix tests. [VERIFIED: existing file]
- [ ] `test/oban_powertools/doctor/formatter_test.exs` - assert human/JSON warning output and schema stability. [VERIFIED: existing file]
- [ ] `test/mix/tasks/oban_powertools.doctor_test.exs` - assert CLI docs/severity table and `--strict` scope. [VERIFIED: existing file]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 54 does not add user authentication surfaces. [VERIFIED: .planning/REQUIREMENTS.md] |
| V3 Session Management | no | No session behavior changes. [VERIFIED: .planning/REQUIREMENTS.md] |
| V4 Access Control | no | Doctor remains repo/CLI scoped and no new UI mutation is added. [VERIFIED: lib/mix/tasks/oban_powertools.doctor.ex] |
| V5 Input Validation | yes | Compile-time positive integer validation for `timeout:` and `deadline:`; defensive ISO8601 parsing for meta; prefix identifier validation for Doctor. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md] [VERIFIED: lib/oban_powertools/doctor/checks.ex] |
| V6 Cryptography | no | No new cryptography; existing fingerprint hashing remains unchanged. [VERIFIED: lib/oban_powertools/idempotency.ex] |

### Known Threat Patterns for Elixir/Ecto/PostgreSQL

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Host-supplied `__deadline_at__` spoofing | Tampering | Powertools reserved-key precedence in meta merge. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md] |
| Prefix SQL injection in Doctor | Tampering / Elevation of privilege | Reuse `valid_identifier?/1` before interpolating schema prefix; bind all values as query parameters. [VERIFIED: lib/oban_powertools/doctor/checks.ex] |
| Malformed deadline metadata denial of service | Denial of service | Defensive parsing in worker and Doctor; malformed data must not crash wrapper or run. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md] |
| High-cardinality telemetry leakage | Information disclosure | Do not add a deadline telemetry family in Phase 54. [VERIFIED: .planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `54-CONTEXT.md` - locked Phase 54 decisions and scope. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - SAFE-01 through SAFE-04. [VERIFIED: file read]
- `.planning/STATE.md` and `.planning/PROJECT.md` - zero-new-runtime-dependency posture and v1.7 build order. [VERIFIED: file read]
- `lib/oban_powertools/worker.ex` - macro and generated wrapper insertion point. [VERIFIED: codebase grep/read]
- `lib/oban_powertools/idempotency.ex` - enqueue transaction, fingerprint, and meta merge. [VERIFIED: codebase grep/read]
- `lib/oban_powertools/doctor.ex`, `lib/oban_powertools/doctor/checks.ex`, `lib/oban_powertools/doctor/formatter.ex`, `lib/mix/tasks/oban_powertools.doctor.ex` - Doctor composition, query patterns, output, and CLI contract. [VERIFIED: codebase grep/read]
- `deps/oban/lib/oban/worker.ex`, `deps/oban/lib/oban/job.ex`, `deps/oban/lib/oban/queue/executor.ex` - Oban worker callback, job option, and executor timeout source. [VERIFIED: vendored dependency source]
- HexDocs Oban Worker v2.23.0 - timeout and return semantics. [CITED: https://hexdocs.pm/oban/Oban.Worker.html]
- HexDocs Oban Job v2.23.0 - `:meta` job option. [CITED: https://hexdocs.pm/oban/Oban.Job.html]

### Secondary (MEDIUM confidence)
- `mix hex.info oban`, `mix hex.info ecto_sql`, `mix hex.info postgrex` - locked versions and release recency. [VERIFIED: Hex registry]
- `.planning/research/STACK.md` and `.planning/research/PITFALLS.md` - prior milestone research, superseded where Phase 54 context differs. [VERIFIED: file read]

### Tertiary (LOW confidence)
- Elixir DateTime helper selection for parsing/formatting, not independently fetched from official docs in this session. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all packages are existing locked dependencies verified by Mix/Hex and vendored source. [VERIFIED: mix deps + Hex]
- Architecture: HIGH - phase context locks the semantics and code integration points are present in current source. [VERIFIED: 54-CONTEXT.md, lib/oban_powertools/worker.ex, lib/oban_powertools/idempotency.ex]
- Pitfalls: HIGH for option stripping, idempotency, hook ordering, and strict semantics; MEDIUM for exact Doctor malformed-meta query shape. [VERIFIED: codebase/read] [ASSUMED]

**Research date:** 2026-06-12  
**Valid until:** 2026-07-12 for local architecture; re-check HexDocs if Oban is upgraded before implementation. [ASSUMED]
