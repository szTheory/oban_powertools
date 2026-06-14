# Phase 58: Cron Deadline Injection - Research

**Researched:** 2026-06-13
**Domain:** Elixir / Oban Queueing / Meta Injection
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Thread `now` as the fifth parameter through all four `maybe_insert_job` clause heads. The `now` variable is already bound in `claim_slot/4` at line 52; pass it via the `Multi.run` lambda.
- **D-02:** Inject `Deadlines.build_meta(deadline_ms, now)` inside the `function_exported?(:__powertools_limits__, 0)` true branch only — never in the `else` or `rescue` paths.
- **D-03:** Pass deadline meta as `meta: deadline_meta` in opts before the `worker_module.new/2` call so `Redaction.apply/4` merges `__redacted_fields__` on top. Do not post-process the changeset.
- **D-04:** Use `merge_powertools_meta/4` in `idempotency.ex` as the reference implementation for correct merge ordering.

### the agent's Discretion
None — implementation is completely determined by PROJECT.md v1.8 implementation notes.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INT-02 | Cron-scheduled `deadline:`-configured workers inject `__deadline_at__` meta at enqueue | `cron.ex` `claim_slot/4` currently binds `now` but doesn't pass it to `maybe_insert_job`. Threading `now` allows `Deadlines.build_meta` to create deadline meta. Passing this in `opts` to `worker_module.new/2` guarantees composition of `__deadline_at__` with `__redacted_fields__`. |
</phase_requirements>

## Summary

The goal of this phase is to inject `__deadline_at__` meta into the database record for cron-scheduled Oban Powertools workers configured with a `deadline:`. This logic brings the cron enqueue path into alignment with the primary idempotency enqueue path, where deadlines are correctly injected. 

**Primary recommendation:** Follow D-01 through D-04 exactly. Thread `now` into the `maybe_insert_job` heads, construct `deadline_meta` via `ObanPowertools.Worker.Deadlines.build_meta/2`, and inject it into the `opts` list when invoking `worker_module.new(args, queue: queue, meta: deadline_meta)`. 

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Cron Job Enqueueing | API / Backend | Database / Storage | Elixir code computes standard arguments and delegates to Ecto for durable insertion via `Oban.Job.new/2` or `ObanPowertools.Worker.new/2`. |
| Job Meta Construction | API / Backend | — | Computing deadlines relative to a fixed `now` and merging them safely with redaction policies happens entirely in BEAM memory before persistence. |

## Common Pitfalls

### Pitfall 1: Bypassing `new/2` merging logic
**What goes wrong:** Meta keys like `__redacted_fields__` are overwritten or lost.
**Why it happens:** Modifying the Ecto changeset directly after `worker_module.new/2` rather than passing `meta:` in the initialization options.
**How to avoid:** Pass `meta: deadline_meta` directly into `worker_module.new(args, queue: queue, meta: deadline_meta)` (D-03). The Powertools worker's `new/2` macro delegates to `Oban.Job.new/2` and seamlessly deep-merges additional redaction fields safely.

### Pitfall 2: Bounding `now` multiple times
**What goes wrong:** Race conditions and slightly divergent timestamps between the slot claim time and the deadline basis.
**Why it happens:** Calling `DateTime.utc_now()` inside `maybe_insert_job` instead of using the transaction's consistent timeline.
**How to avoid:** Thread the `now` variable that is bound at line 52 of `cron.ex` `claim_slot/4` through to `maybe_insert_job/5` (D-01).

### Pitfall 3: Crashing on invalid worker modules
**What goes wrong:** A misconfigured or deleted worker module referenced in the database causes the entire cron sync process to crash.
**Why it happens:** Using strict introspection against unverified runtime string values.
**How to avoid:** Ensure powertools meta injection only occurs within the existing `try...rescue` block and the `function_exported?` safety checks, reverting to `Oban.Job.new` fallback on failure.

## Code Examples

### Verified Pattern: Threading `now` and passing options to `new/2`
```elixir
# In lib/oban_powertools/cron.ex
defp maybe_insert_job(repo, entry, args, _decision, now) do
  queue = entry.queue

  changeset =
    try do
      worker_module = String.to_existing_atom("Elixir." <> entry.worker)

      if function_exported?(worker_module, :__powertools_limits__, 0) do
        deadline_ms =
          if function_exported?(worker_module, :__powertools_deadline_ms__, 0) do
            worker_module.__powertools_deadline_ms__()
          end

        # build_meta correctly handles nil if no deadline is configured
        deadline_meta = ObanPowertools.Worker.Deadlines.build_meta(deadline_ms, now)

        # Route through new/2 to inherit redaction and meta injection
        worker_module.new(args, queue: queue, meta: deadline_meta)
      else
        # Plain Oban.Worker — keep existing bare insert behavior
        Oban.Job.new(args, worker: entry.worker, queue: queue)
      end
    rescue
      ArgumentError ->
        # Unloaded or removed worker module — degrade gracefully
        Oban.Job.new(args, worker: entry.worker, queue: queue)
    end

  repo.insert(changeset)
end
```

## Assumptions Log

All facts are verified via project source inspection; no assumed claims exist.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/oban_powertools/cron_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INT-02 | `__deadline_at__` injected for `deadline:` cron workers | unit | `mix test test/oban_powertools/cron_test.exs` | ✅ Wave 0 |
| INT-02 | `deadline:` absent for plain powertools cron workers | unit | `mix test test/oban_powertools/cron_test.exs` | ✅ Wave 0 |
| INT-02 | `__deadline_at__` and `__redacted_fields__` compose cleanly | unit | `mix test test/oban_powertools/cron_test.exs` | ✅ Wave 0 |
| INT-02 | Plain non-powertools cron workers are completely unaffected | unit | `mix test test/oban_powertools/cron_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- [ ] `test/oban_powertools/cron_test.exs` requires new test module definitions (`CronDeadlineWorker`, `CronRedactDeadlineWorker`) to simulate deadline configurations.
- [ ] Add explicit assertions targeting `job.meta["__deadline_at__"]` to confirm properties 1-3.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core standard library and Ecto/Oban usage.
- Architecture: HIGH - Fully derived from `58-CONTEXT.md` directives and v1.8 Implementation notes.
- Pitfalls: HIGH - Pulled directly from explicit project patterns around `new/2` execution.

**Research date:** 2026-06-13
**Valid until:** 30 days
