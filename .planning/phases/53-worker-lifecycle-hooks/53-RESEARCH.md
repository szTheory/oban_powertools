# Phase 53: Worker Lifecycle Hooks - Research

**Researched:** 2026-06-12  
**Domain:** Elixir/Oban worker execution wrapper, lifecycle callbacks, telemetry contract  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for this entire verbatim section: [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]

### Locked Decisions

### Lifecycle Semantics
- **D-01:** Hook dispatch is state-transition-oriented, not event fan-out. A single post-execution hook fires for a given process outcome.
- **D-02:** `on_start/1` fires after Powertools args validation/casting and before `process/1`. It receives the typed `%Oban.Job{}` that `process/1` will receive.
- **D-03:** `:ok` and `{:ok, value}` route to `on_success/2`.
- **D-04:** Retry-eligible `{:error, reason}` returns and rescued/caught process failures route to `on_failure/2`.
- **D-05:** Final-attempt `{:error, reason}` returns and final-attempt raised/caught failures route to `on_discard/2` only. Do not dual-fire `on_failure/2` and `on_discard/2`; that creates duplicate alerts and side effects.
- **D-06:** `:discard` and `{:discard, reason}` route to `on_discard/2`.
- **D-07:** `{:cancel, reason}` remains Oban `cancelled` semantics and does not route to `on_failure/2` or `on_discard/2` in Phase 53. If Powertools needs cancellation callbacks, that is a future explicit `on_cancel/2` decision or handled through Oban job telemetry, not by overloading discard.
- **D-08:** Timeout kills may bypass wrapper-level failure hooks because Oban uses BEAM exit timers around `perform/1`. Timeout observability belongs to Oban `[:oban, :job, :exception]` telemetry and future docs, not `on_failure/2`.
- **D-09:** Operator-initiated Lifeline discards do not fire worker execution hooks. They are already audited through the Lifeline repair pipeline and are not in this phase.

### Callback Payload Shape
- **D-10:** `on_start/1` receives only the typed `%Oban.Job{}`.
- **D-11:** Post hooks use a small event envelope map as their second argument rather than only raw tuples. This gives downstream users stable, pattern-matchable context without callback arity churn.
- **D-12:** `on_success/2` receives `%{state: :success, result: :ok | {:ok, term()}, value: term() | nil}`.
- **D-13:** `on_failure/2` receives `%{state: :failure, reason: term(), result: {:error, term()} | nil, kind: :error | :exit | :throw | nil, stacktrace: list() | nil, terminal?: false}`.
- **D-14:** `on_discard/2` receives `%{state: :discard, reason: term(), result: :discard | {:discard, term()} | {:error, term()} | nil, kind: atom() | nil, stacktrace: list() | nil, terminal?: true}`.
- **D-15:** Keep envelopes intentionally narrow. Do not include job ids, args, queue, worker name, reasons, or stacktraces in Powertools telemetry metadata. Rich event data can be passed to hooks but must not become metric labels.
- **D-16:** Hook return values are ignored. Hook exceptions and throws are caught, logged at warning level, and never change the job result returned to Oban.

### Dispatch Architecture
- **D-17:** Primary hook dispatch is owned by the generated `ObanPowertools.Worker.perform/1` wrapper, not by per-worker `:telemetry.attach` handlers on Oban job events.
- **D-18:** Add a private/internal dispatcher module, recommended as `ObanPowertools.Worker.Hooks`, so quoted macro code stays small. The wrapper owns lifecycle ordering; the dispatcher owns crash-catching, event envelope construction, telemetry emission, and callback invocation.
- **D-19:** Do not add a GenServer, ETS registry, global `attach_hook/1`, or new supervision tree for Phase 53. Hooks run synchronously in the job process.
- **D-20:** Recommended wrapper order for Phase 53: validate/cast args -> call `on_start/1` safely -> call `process/1` under wrapper rescue/catch -> normalize result against attempt/max_attempts -> dispatch exactly one post hook safely -> return the original Oban-compatible result.
- **D-21:** Later phases may insert behavior into this wrapper in fixed positions: deadline pre-check before `on_start`/`process`, output recording before `on_success`, redaction at enqueue/recording boundaries. Do not choose a dispatch architecture that blocks this composition.

### Telemetry Contract
- **D-22:** Phase 53 must emit hook telemetry because HOOK-05 and the roadmap success criteria require it. Do not defer all telemetry or create a contract-only no-op.
- **D-23:** Add `worker_hook: [:hook, :outcome]` to `ObanPowertools.Telemetry.contract/0`.
- **D-24:** Add helper `execute_worker_hook_event/3` following the existing telemetry helper pattern.
- **D-25:** Emit event `[:oban_powertools, :worker_hook, :invoked]` with measurement `%{count: 1}`.
- **D-26:** Emit metadata as low-cardinality strings: `hook: "on_start" | "on_success" | "on_failure" | "on_discard"` and `outcome: "ok" | "crash_caught"`.
- **D-27:** Emit hook telemetry only for actual hook dispatch attempts after the hook returns or is caught. Do not emit for omitted no-op defaults if the planner can cheaply detect that the worker did not override the hook; otherwise document the chosen behavior explicitly in the plan.
- **D-28:** Add one `metrics/0` counter: `oban_powertools.worker_hook.invoked.count`, with tags `[:hook, :outcome]`.
- **D-29:** Do not emit span-style hook telemetry, hook durations, worker module names, job ids, queue names, args, reasons, or stacktraces in the public Powertools telemetry contract for this phase.

### Documentation and Tests
- **D-30:** Document four support-truth answers for hooks: they run in the job process, outside any Powertools transaction; hook failure does not fail the job; hook failure does not crash the queue; hook execution is not retried independently.
- **D-31:** Tests must cover every routing branch: start, success, retry-eligible failure, terminal failure, explicit discard, explicit cancel non-dispatch, hook crash swallowed, omitted hooks no-op, and telemetry emitted with only allowed metadata.
- **D-32:** Include a test proving final-attempt failure does not double-fire `on_failure/2` and `on_discard/2`.

### the agent's Discretion
- The user explicitly asked for subagent-backed research and a one-shot cohesive recommendation set so they would not need to select implementation options manually. The locked decisions above reflect the synthesized recommendation.

### Deferred Ideas (OUT OF SCOPE)

- `on_cancel/2` for explicit cancellation/deadline expiry belongs in a later phase if adopter demand or Phase 54 deadline UX needs it.
- Global `attach_hook/1` registry remains deferred until adoption signal.
- Hook latency spans or duration summaries are deferred; Phase 53 only needs counter-style invocation/health telemetry.
- Operator/Lifeline-initiated discard callbacks are out of scope; Lifeline already owns audited operator actions.
- Output recording, deadline/timeout pass-through, and redaction are separate v1.7 phases that should reuse this wrapper seam without expanding Phase 53 scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HOOK-01 | Worker can declare `on_start/1` callback that fires before `process/1`; observe-only, crash-caught, no-op default | Existing generated `perform/1` validates args before calling `process/1`, so insert safe `on_start/1` after validation and before process. [VERIFIED: lib/oban_powertools/worker.ex] |
| HOOK-02 | Worker can declare `on_success/2` callback for `:ok` and `{:ok, _}` | Oban treats `:ok` and `{:ok, value}` as completed success, with tuple value ignored by Oban. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| HOOK-03 | Worker can declare `on_failure/2` callback for `{:error, _}` or raises | Oban treats `{:error, error}` and unhandled exception/exit/throw as failure with retry if attempts remain. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| HOOK-04 | Worker can declare `on_discard/2` callback after retry exhaustion | Oban marks `{:error, error}` as discarded when `max_attempts` is exhausted, and its executor normalizes failure to exhausted when `job.attempt >= job.max_attempts`. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] [VERIFIED: deps/oban/lib/oban/queue/executor.ex] |
| HOOK-05 | Hook invocations emit telemetry under `worker_hook` with `hook` and `outcome` keys | Existing Powertools telemetry contract centralizes families, helper functions, and metric tag containment tests; add `worker_hook: [:hook, :outcome]` and one counter. [VERIFIED: lib/oban_powertools/telemetry.ex] [VERIFIED: test/oban_powertools/telemetry_test.exs] |
</phase_requirements>

## Summary

Phase 53 should be planned as a small internal execution-wrapper refactor plus an additive telemetry contract extension. [VERIFIED: lib/oban_powertools/worker.ex] The current `ObanPowertools.Worker.__using__/1` macro already owns the generated `perform/1` wrapper, validates/casts args, and delegates directly to `process/1`; that is the correct insertion point for lifecycle ordering. [VERIFIED: lib/oban_powertools/worker.ex] The hook dispatcher should live in a new internal `ObanPowertools.Worker.Hooks` module to keep quoted macro code small and to centralize crash-catching, envelope construction, telemetry emission, and callback invocation. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]

No new runtime dependency is needed. [VERIFIED: .planning/PROJECT.md] Oban 2.23.0, Telemetry 1.4.2, and Telemetry.Metrics 1.1.0 are already locked and sufficient for this phase. [VERIFIED: mix deps] The implementation must not use Oban telemetry handlers as the primary hook dispatcher because Phase 53 locked wrapper-owned dispatch and because hooks must receive typed args after Powertools validation. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] [VERIFIED: lib/oban_powertools/worker.ex]

**Primary recommendation:** Plan one wave for the internal dispatcher and worker macro defaults/routing, one wave for telemetry contract/metrics, and one wave for docs plus branch-complete tests covering all hook routes and crash safety. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists at the repository root, so no AGENTS-specific directives apply. [VERIFIED: shell `test -f AGENTS.md`]

No project-local `.codex/skills/`, `.agents/skills/`, or `rules/*.md` files were found. [VERIFIED: shell `find . -maxdepth 4 ...`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Hook lifecycle ordering | API / Backend | Oban executor process | `perform/1` is generated in library backend code and runs inside Oban's job process. [VERIFIED: lib/oban_powertools/worker.ex] [VERIFIED: deps/oban/lib/oban/queue/executor.ex] |
| Hook callback crash safety | API / Backend | Logger, telemetry | Safe dispatch must catch hook exceptions/throws and return the original job result. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |
| Discard vs failure classification | API / Backend | Oban executor semantics | Final-attempt failures are identified with `job.attempt >= job.max_attempts`, matching Oban executor normalization. [VERIFIED: deps/oban/lib/oban/queue/executor.ex] |
| Hook telemetry contract | API / Backend | Metrics reporter in host app | Powertools owns its public telemetry contract; reporters consume optional `Telemetry.metrics/0`. [VERIFIED: lib/oban_powertools/telemetry.ex] |
| Worker docs and examples | Static / Docs | API / Backend | Docs must explain support truth while code enforces no-op defaults and crash safety. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / OTP | Elixir 1.19.5, OTP 28 | Macro generation, behaviours, try/rescue/catch, Logger | Project runtime and test environment use Elixir 1.19.5. [VERIFIED: `elixir --version`] |
| Oban | 2.23.0 | Worker return semantics and job execution process | Locked dependency; official docs define success, failure, cancel, snooze, and discard return semantics. [VERIFIED: mix deps] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| `:telemetry` | 1.4.2 | Low-cardinality hook invocation event emission | Locked dependency and existing Powertools telemetry helper pattern. [VERIFIED: mix deps] [VERIFIED: lib/oban_powertools/telemetry.ex] |
| ExUnit | Elixir 1.19.5 bundled | Unit and integration tests | Existing suite uses ExUnit and includes worker/telemetry tests to extend. [VERIFIED: test/oban_powertools/worker_test.exs] [VERIFIED: test/oban_powertools/telemetry_test.exs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `telemetry_metrics` | 1.1.0 optional/test/dev | `Telemetry.metrics/0` counter definition | Add the `oban_powertools.worker_hook.invoked.count` counter only inside existing `metrics/0`. [VERIFIED: mix deps] [VERIFIED: lib/oban_powertools/telemetry.ex] |
| Ecto | 3.14.0 | Args embedded schema and changeset casting | Existing worker validation uses `Ecto.Schema` and `Ecto.Changeset`; no new Ecto schema is needed in Phase 53. [VERIFIED: mix deps] [VERIFIED: lib/oban_powertools/worker.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Generated wrapper dispatch | Per-worker `:telemetry.attach` to Oban job events | Rejected by locked decision D-17; telemetry handlers see Oban outcome events but not the exact typed `process/1` wrapper seam before return. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |
| Internal dispatcher module | Inline all hook logic in quoted macro | Inline code would make macro expansion larger and harder to test; D-18 recommends a dispatcher module. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |
| Synchronous in-process hooks | GenServer/Task hook supervisor | Rejected by D-19; async dispatch would add ordering and supervision semantics outside this phase. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |

**Installation:** No install command. Phase 53 should add no packages. [VERIFIED: .planning/PROJECT.md]

**Version verification:** `mix deps` reports Oban 2.23.0, Telemetry 1.4.2, Telemetry.Metrics 1.1.0, Ecto 3.14.0, and Postgrex 0.22.2. [VERIFIED: mix deps]

## Package Legitimacy Audit

Phase 53 installs no external packages, so the package legitimacy gate does not apply to a new dependency. [VERIFIED: .planning/PROJECT.md] `slopcheck` is available as version 0.6.1, but no package names need auditing for this phase. [VERIFIED: `slopcheck --version`]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | none | - | - | - | not run | Approved: no new packages |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: no new packages]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no new packages]

## Architecture Patterns

### System Architecture Diagram

```text
Oban Queue Executor
  -> generated ObanPowertools.Worker.perform/1
      -> validate/cast args with Args.changeset/2
          -> validation failed?
              -> return {:error, changeset} to Oban
          -> validation ok
              -> safe dispatch on_start/1
              -> call process/1 inside try/rescue/catch
                  -> :ok or {:ok, value}
                      -> safe dispatch on_success/2
                      -> return original success result
                  -> {:error, reason} or raised/caught failure
                      -> job.attempt >= job.max_attempts?
                          -> safe dispatch on_discard/2
                          -> return original error or reraised-equivalent result
                      -> safe dispatch on_failure/2
                      -> return original error or reraised-equivalent result
                  -> :discard or {:discard, reason}
                      -> safe dispatch on_discard/2
                      -> return original discard result
                  -> {:cancel, reason} or {:snooze, period} or other
                      -> no Phase 53 post-hook dispatch unless explicitly routed by decisions
                      -> return original result

safe dispatch
  -> call worker hook only when worker overrides default, if cheap detection is implemented
  -> catch exceptions/throws/exits
  -> Logger.warning on crash
  -> ObanPowertools.Telemetry.execute_worker_hook_event(:invoked, %{count: 1}, %{hook, outcome})
  -> never changes returned job result
```

This flow mirrors Oban executor normalization for final-attempt failure and keeps the original return value as Oban's source of job outcome. [VERIFIED: deps/oban/lib/oban/queue/executor.ex]

### Recommended Project Structure

```text
lib/
└── oban_powertools/
    ├── worker.ex              # generated defaults, defoverridable hooks, perform/1 ordering
    ├── worker/
    │   └── hooks.ex           # internal safe dispatcher and envelope construction
    └── telemetry.ex           # worker_hook contract, helper, metric counter

test/
└── oban_powertools/
    ├── worker_test.exs        # hook routing, no-op defaults, crash swallowing
    └── telemetry_test.exs     # worker_hook event, metric tags, metadata boundary
```

The file targets match existing code and test locations. [VERIFIED: lib/oban_powertools/worker.ex] [VERIFIED: lib/oban_powertools/telemetry.ex] [VERIFIED: test/oban_powertools/worker_test.exs] [VERIFIED: test/oban_powertools/telemetry_test.exs]

### Pattern 1: Optional Hook Defaults via `defoverridable`

**What:** Generate no-op hook functions inside `use ObanPowertools.Worker`, then mark them overridable. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]  
**When to use:** Every worker using the macro should compile without implementing hooks, while custom workers can override only selected hooks. [VERIFIED: .planning/REQUIREMENTS.md]

```elixir
# Source: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md
def on_start(_job), do: :ok
def on_success(_job, _event), do: :ok
def on_failure(_job, _event), do: :ok
def on_discard(_job, _event), do: :ok

defoverridable on_start: 1, on_success: 2, on_failure: 2, on_discard: 2
```

### Pattern 2: Dispatcher Returns Original Result

**What:** Wrap hook invocation in a function that always returns `:ok` or an internal dispatch result, never the job result. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]  
**When to use:** Any lifecycle callback invocation. [VERIFIED: .planning/REQUIREMENTS.md]

```elixir
# Source: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md
def safe_invoke(worker, hook, job, event \\ nil) do
  outcome =
    try do
      apply(worker, hook, hook_args(hook, job, event))
      "ok"
    rescue
      error ->
        Logger.warning("Worker hook #{hook} crashed: #{Exception.message(error)}")
        "crash_caught"
    catch
      kind, reason ->
        Logger.warning("Worker hook #{hook} threw/caught #{inspect({kind, reason})}")
        "crash_caught"
    end

  ObanPowertools.Telemetry.execute_worker_hook_event(:invoked, %{count: 1}, %{
    hook: Atom.to_string(hook),
    outcome: outcome
  })

  :ok
end
```

### Pattern 3: Final-Attempt Failure Routing

**What:** Classify `{:error, reason}` and rescued/caught process failures as discard when `job.attempt >= job.max_attempts`, otherwise failure. [VERIFIED: deps/oban/lib/oban/queue/executor.ex]  
**When to use:** Post-`process/1` dispatch classification. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]

```elixir
# Source: deps/oban/lib/oban/queue/executor.ex
defp terminal_attempt?(%Oban.Job{attempt: attempt, max_attempts: max_attempts}) do
  attempt >= max_attempts
end
```

### Anti-Patterns to Avoid

- **Hook dispatch from Oban telemetry handlers:** Contradicts D-17 and loses the typed wrapper ordering. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]
- **Letting hook errors bubble:** A crashing hook would become an Oban job failure, violating HOOK-01 through HOOK-04. [VERIFIED: .planning/REQUIREMENTS.md]
- **Dual-firing `on_failure/2` and `on_discard/2` on final attempt:** D-05 explicitly rejects this because it duplicates alerts and side effects. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]
- **Adding job ids, args, reasons, stacktraces, worker modules, or queues to Powertools hook telemetry metadata:** D-15 and D-29 forbid high-cardinality metadata in this family. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Job lifecycle execution | Custom queue executor or Oban internals patch | Existing generated `perform/1` wrapper | Oban already owns persistence and retry state; Powertools only needs observe-only callbacks. [VERIFIED: deps/oban/lib/oban/queue/executor.ex] |
| Hook crash isolation | New supervisor, Task, ETS registry, async queue | Synchronous `try/rescue/catch` dispatcher | Locked D-19 forbids new process infrastructure in Phase 53. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |
| Metrics reporter | Custom metrics storage | Existing `:telemetry` event plus optional `Telemetry.Metrics.counter/2` | Powertools already exposes opt-in metrics over telemetry families. [VERIFIED: lib/oban_powertools/telemetry.ex] |
| Discard detection from DB state | Polling `oban_jobs.state` inside hook | `job.attempt >= job.max_attempts` before returning to Oban | Oban sets final database state after `perform/1`; wrapper must classify from current job attempt/max_attempts. [VERIFIED: deps/oban/lib/oban/queue/executor.ex] |

**Key insight:** Custom global hook infrastructure is unnecessary because the generated wrapper already has the only ordering information Phase 53 needs: typed job, process result, caught exception, and attempt counters. [VERIFIED: lib/oban_powertools/worker.ex] [VERIFIED: deps/oban/lib/oban/queue/executor.ex]

## Common Pitfalls

### Pitfall 1: Hook Failure Changes Job Outcome

**What goes wrong:** `on_start/1` or a post-hook raises and Oban retries or discards the job because the hook exception escapes. [VERIFIED: .planning/research/PITFALLS.md]  
**Why it happens:** The generated wrapper is currently a direct call to `process/1`, so adding callbacks inline without safe dispatch would make hook code part of the job outcome path. [VERIFIED: lib/oban_powertools/worker.ex]  
**How to avoid:** Put every hook call behind `ObanPowertools.Worker.Hooks.safe_invoke/4` and assert original return values are preserved. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]  
**Warning signs:** Tests assert hook messages but do not assert the `perform/1` return value after a hook raises. [ASSUMED]

### Pitfall 2: Final-Attempt Failure Double-Fires

**What goes wrong:** A final failed attempt triggers both `on_failure/2` and `on_discard/2`. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]  
**Why it happens:** From `process/1`, final and retry-eligible `{:error, reason}` look the same unless the wrapper checks `attempt >= max_attempts`. [VERIFIED: deps/oban/lib/oban/queue/executor.ex]  
**How to avoid:** Normalize the post-hook target before dispatch and add the D-32 test. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]  
**Warning signs:** Tests only cover `attempt: 1, max_attempts: 20` failures. [ASSUMED]

### Pitfall 3: Timeout Kill Expected to Fire `on_failure/2`

**What goes wrong:** Users expect `on_failure/2` to run after an Oban timeout, but the timeout can terminate the job process before wrapper post-hook code runs. [VERIFIED: deps/oban/lib/oban/queue/executor.ex] [CITED: https://elixir.hexdocs.pm/main/try-catch-and-rescue.html]  
**Why it happens:** Oban starts a timer with `:timer.exit_after`, and Elixir `after` blocks have only a soft guarantee when linked process exits occur. [VERIFIED: deps/oban/lib/oban/queue/executor.ex] [CITED: https://elixir.hexdocs.pm/main/try-catch-and-rescue.html]  
**How to avoid:** Document timeout observability as Oban `[:oban, :job, :exception]`, not Phase 53 hooks. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]  
**Warning signs:** A test tries to assert `on_failure/2` after `timeout/1`. [ASSUMED]

### Pitfall 4: Telemetry Metadata Cardinality Creep

**What goes wrong:** Hook event metadata includes worker names, job ids, args, reasons, or stacktraces. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]  
**Why it happens:** Hook envelopes contain rich data, and implementers may accidentally mirror those fields into telemetry. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]  
**How to avoid:** Emit only `%{hook: string, outcome: string}` and extend telemetry tests to assert exact key sets. [VERIFIED: test/oban_powertools/telemetry_test.exs]  
**Warning signs:** `Telemetry.execute` calls in hook code pass the envelope map as metadata. [ASSUMED]

### Pitfall 5: Defaults Emit Noisy Telemetry

**What goes wrong:** Every worker emits hook telemetry even when it did not override a hook, inflating metrics and obscuring real hook adoption. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]  
**Why it happens:** No-op defaults are real functions, so naive dispatch cannot distinguish default from user hook. [ASSUMED]  
**How to avoid:** Planner should choose and document a cheap override-detection strategy, or explicitly accept telemetry for no-op dispatch. D-27 prefers telemetry only for actual dispatch attempts after real hooks. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]  
**Warning signs:** A worker with no hook definitions produces `:worker_hook` telemetry in tests. [ASSUMED]

## Code Examples

Verified patterns from repo and official sources:

### Existing Generated Worker Wrapper

```elixir
# Source: lib/oban_powertools/worker.ex
def perform(%Oban.Job{args: args} = job) when is_map(args) do
  case validate(args) do
    {:ok, casted_args} ->
      process(%{job | args: casted_args})

    {:error, changeset} ->
      {:error, changeset}
  end
end
```

This is the seam to refactor into validate -> start hook -> process under catch -> post hook -> return original result. [VERIFIED: lib/oban_powertools/worker.ex]

### Existing Telemetry Helper Pattern

```elixir
# Source: lib/oban_powertools/telemetry.ex
def execute_lifeline_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute(
    [:oban_powertools, :lifeline, event_suffix],
    measurements,
    metadata
  )
end
```

Add `execute_worker_hook_event/3` with the same shape and event prefix `[:oban_powertools, :worker_hook, event_suffix]`. [VERIFIED: lib/oban_powertools/telemetry.ex] [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]

### Oban Executor Final-Attempt Normalization

```elixir
# Source: deps/oban/lib/oban/queue/executor.ex
def normalize_state(%__MODULE__{state: :failure, job: job} = exec)
    when job.attempt >= job.max_attempts do
  %{exec | state: :exhausted}
end
```

Mirror this condition for hook routing, but do not change the return value sent back to Oban. [VERIFIED: deps/oban/lib/oban/queue/executor.ex] [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Use global job telemetry handlers for worker-local hooks | Wrapper-owned worker-local dispatch with crash-caught callbacks | Phase 53 CONTEXT gathered 2026-06-12 | Planner must ignore older milestone research recommending telemetry-handler dispatch. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |
| Treat final failed attempt as `on_failure` plus terminal event | Route final attempt to `on_discard/2` only | Phase 53 CONTEXT gathered 2026-06-12 | Prevents duplicate alerts/side effects. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |
| Worker hook telemetry deferred | Emit `:worker_hook` telemetry in Phase 53 | Phase 53 CONTEXT gathered 2026-06-12 | HOOK-05 and roadmap success criteria require event and metric coverage now. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |

**Deprecated/outdated:**

- Older `.planning/research/STACK.md` recommends per-worker telemetry-handler dispatch; Phase 53 CONTEXT supersedes that with D-17 through D-21. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] [VERIFIED: .planning/research/STACK.md]
- Older research notes that `{:cancel, reason}` may route to discard; Phase 53 D-07 supersedes this and keeps cancel out of hook routing. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] [VERIFIED: .planning/research/STACK.md]

## Runtime State Inventory

Phase 53 is not a rename, refactor of persisted identifiers, or data migration phase, but it is a wrapper refactor. [VERIFIED: .planning/ROADMAP.md]

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None - Phase 53 adds callbacks and telemetry only, with no schema or stored key changes. [VERIFIED: .planning/ROADMAP.md] | None |
| Live service config | None - no external service configuration is part of Phase 53. [VERIFIED: .planning/ROADMAP.md] | None |
| OS-registered state | None - no OS services, launch agents, or process registrations are involved. [VERIFIED: .planning/ROADMAP.md] | None |
| Secrets/env vars | None - no env var or secret names are added or renamed. [VERIFIED: .planning/ROADMAP.md] | None |
| Build artifacts | Existing compiled `_build/` artifacts may reflect old macro expansion during local work. [VERIFIED: repository listing] | Normal `mix test` recompilation is sufficient; no migration task required. [ASSUMED] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Tests that omit return-value assertions may miss hook crash outcome regressions. | Common Pitfalls | Planner should add explicit return-value assertions. |
| A2 | Workers with no hook definitions can emit noisy telemetry if default override detection is not implemented. | Common Pitfalls | Planner must decide and document override detection behavior. |
| A3 | `_build/` recompilation through normal `mix test` is enough after macro changes. | Runtime State Inventory | If stale compile artifacts persist, planner may need a `mix clean` verification step. |

## Open Questions (RESOLVED)

1. **How should override detection be implemented for D-27?**
   - What we know: D-27 prefers not emitting telemetry for omitted no-op defaults if the planner can cheaply detect no override. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]
   - RESOLVED: Use compile-time override tracking with generated `__powertools_hook_overridden?/1`; omitted defaults emit no `worker_hook` telemetry. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-01-PLAN.md]
   - Recommendation retained: Prefer compile-time module attributes such as `@powertools_hook_defaults` plus generated `__powertools_hook_overridden?/1`, because runtime function presence alone cannot distinguish defaults from overrides. [ASSUMED]

2. **Should rescued `process/1` failures be returned as `{:error, exception}` or reraised after hook dispatch?**
   - What we know: D-04 requires rescued/caught process failures to route to `on_failure/2`, D-05 terminal failures to `on_discard/2`, and D-20 says return the original Oban-compatible result. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]
   - RESOLVED: Dispatch the matching hook and preserve original raised/thrown/exited process semantics by reraising, rethrowing, or exiting after dispatch. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-01-PLAN.md]
   - Recommendation retained: Preserve Oban semantics by dispatching the hook and then reraising/throwing/exiting with original stacktrace where possible, rather than converting exceptions to tuples. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Build/test worker macro changes | yes | 1.19.5 | none |
| Erlang/OTP | Oban execution semantics and tests | yes | 28 / erts-16.3 | none |
| Mix | Dependency/test commands | yes | 1.19.5 | none |
| PostgreSQL server | Existing full test suite boot | yes | `pg_isready` accepting on `/tmp:5432` | `OBAN_POWERTOOLS_SKIP_DB_BOOT=1` for non-DB tests only |
| psql | DB inspection if needed | yes | 14.17 | Ecto SQL queries from tests |
| ctx7 | Documentation lookup fallback | no | - | Official HexDocs via web search/open |
| slopcheck | Package legitimacy gate if packages added | yes | 0.6.1 | Not needed because no packages are added |

**Missing dependencies with no fallback:** none for Phase 53 planning. [VERIFIED: environment probes]  
**Missing dependencies with fallback:** `ctx7` is missing; official HexDocs and local dependency source were used instead. [VERIFIED: environment probes] [CITED: https://hexdocs.pm/oban/Oban.Worker.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit bundled with Elixir 1.19.5. [VERIFIED: `elixir --version`] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/oban_powertools/worker_test.exs test/oban_powertools/telemetry_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| HOOK-01 | `on_start/1` fires after validation and before `process/1`; callback crash does not alter result | unit | `mix test test/oban_powertools/worker_test.exs --trace` | yes, extend |
| HOOK-02 | `on_success/2` receives `:ok` and `{:ok, value}` success envelopes | unit | `mix test test/oban_powertools/worker_test.exs --trace` | yes, extend |
| HOOK-03 | `on_failure/2` receives retry-eligible `{:error, reason}` and raised/caught failure envelopes | unit | `mix test test/oban_powertools/worker_test.exs --trace` | yes, extend |
| HOOK-04 | `on_discard/2` fires exactly once for final-attempt error and explicit discard, not on retry-eligible failure or cancel | unit | `mix test test/oban_powertools/worker_test.exs --trace` | yes, extend |
| HOOK-05 | Hook dispatch emits `[:oban_powertools, :worker_hook, :invoked]` with exact metadata keys `hook` and `outcome`, and metric tags stay in contract | unit | `mix test test/oban_powertools/telemetry_test.exs --trace` | yes, extend |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/worker_test.exs test/oban_powertools/telemetry_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `$gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/oban_powertools/worker_test.exs` - add hook routing, no-op defaults, crash-safety, and final-attempt non-double-fire coverage. [VERIFIED: test/oban_powertools/worker_test.exs]
- [ ] `test/oban_powertools/telemetry_test.exs` - add `worker_hook` contract, helper event, metric counter, and exact metadata-key tests. [VERIFIED: test/oban_powertools/telemetry_test.exs]
- [ ] `lib/oban_powertools/worker/hooks.ex` - add focused unit-testable internal dispatch module. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No user authentication surface changes in Phase 53. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | No session or browser state changes in Phase 53. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | no | No operator mutation or route access changes in Phase 53. [VERIFIED: .planning/ROADMAP.md] |
| V5 Input Validation | yes | Preserve existing Ecto args validation before hooks and process. [VERIFIED: lib/oban_powertools/worker.ex] |
| V6 Cryptography | no | No encryption or crypto is added in Phase 53. [VERIFIED: .planning/ROADMAP.md] |
| V7 Error Handling and Logging | yes | Hook crashes must be caught and warning-logged without leaking high-cardinality telemetry metadata. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |
| V10 Malicious Code | yes | Do not execute untrusted packages or add hook registry/plugin loading. [VERIFIED: .planning/PROJECT.md] |

### Known Threat Patterns for Elixir/Oban Hook Dispatch

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Hook exception causes job retry or duplicate side effect | Denial of Service / Tampering | Catch hook errors and never alter returned job result. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |
| Sensitive data in telemetry labels | Information Disclosure | Emit only `hook` and `outcome` strings, never args/reasons/stacktraces/job ids. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |
| Hook side effects mistaken for durable audit | Repudiation | Document hooks as observe-only, best-effort, in-process, and not retried independently. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |
| Unbounded hook latency blocks job completion | Denial of Service | Keep hooks synchronous by design but document they run in the job process; do not add async fan-out in Phase 53. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md` - locked Phase 53 decisions, telemetry contract, test scope. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - HOOK-01 through HOOK-05 requirements. [VERIFIED: file read]
- `.planning/ROADMAP.md` - Phase 53 goal and success criteria. [VERIFIED: file read]
- `.planning/PROJECT.md` and `.planning/STATE.md` - zero-new-dependency posture and v1.7 ordering. [VERIFIED: file read]
- `lib/oban_powertools/worker.ex` - current macro, validation, generated `perform/1`, enqueue path. [VERIFIED: codebase grep/read]
- `lib/oban_powertools/telemetry.ex` - telemetry contract, metrics, helper pattern. [VERIFIED: codebase grep/read]
- `deps/oban/lib/oban/queue/executor.ex` - Oban executor return normalization, timeout timer, event emission. [VERIFIED: local dependency source]
- `deps/oban/lib/oban/worker.ex` - Oban worker return semantics and timeout callback source. [VERIFIED: local dependency source]
- `https://hexdocs.pm/oban/Oban.Worker.html` - official Oban worker return semantics. [CITED: hexdocs.pm]
- `https://hexdocs.pm/oban/2.23.0/Oban.Telemetry.html` - official Oban job telemetry event metadata. [CITED: hexdocs.pm]
- `https://oban.pro/docs/pro/Oban.Pro.Worker.html` - clean-room comparison for hook safety and state separation. [CITED: oban.pro]
- `https://elixir.hexdocs.pm/main/try-catch-and-rescue.html` - Elixir errors, throws, exits, and `after` soft guarantee. [CITED: hexdocs.pm]

### Secondary (MEDIUM confidence)

- `.planning/research/SUMMARY.md`, `.planning/research/ARCHITECTURE.md`, `.planning/research/PITFALLS.md`, `.planning/research/STACK.md` - milestone-level prior research; superseded where Phase 53 CONTEXT differs. [VERIFIED: file read]
- `mix hex.info oban` - Oban 2.23.0 release date and downloads from Hex. [VERIFIED: Hex CLI]

### Tertiary (LOW confidence)

- None used for recommendations. [VERIFIED: research notes]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions verified from `mix deps`, local lock state, and official Oban docs. [VERIFIED: mix deps] [CITED: https://hexdocs.pm/oban/Oban.Worker.html]
- Architecture: HIGH - locked decisions and existing wrapper seam align. [VERIFIED: .planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md] [VERIFIED: lib/oban_powertools/worker.ex]
- Pitfalls: HIGH for Oban/telemetry/timeout/discard semantics, MEDIUM for override-detection implementation because the exact strategy remains open. [VERIFIED: deps/oban/lib/oban/queue/executor.ex] [ASSUMED]

**Research date:** 2026-06-12  
**Valid until:** 2026-07-12 for repo-local architecture; re-check Oban docs if upgrading Oban before implementation. [ASSUMED]
