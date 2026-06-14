---
phase: 61-apis-batches-chains
reviewed: 2026-06-14T21:45:02Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - lib/mix/tasks/oban_powertools.install.ex
  - lib/oban_powertools.ex
  - lib/oban_powertools/batch.ex
  - lib/oban_powertools/batch/tracker.ex
  - lib/oban_powertools/callback.ex
  - lib/oban_powertools/chain.ex
  - lib/oban_powertools/chain/args_builder.ex
  - lib/oban_powertools/chain/progression.ex
  - lib/oban_powertools/workflow/runtime.ex
  - test/mix/tasks/oban_powertools.install_test.exs
  - test/oban_powertools/batch_insert_stream_test.exs
  - test/oban_powertools/batch_test.exs
  - test/oban_powertools/chain_output_test.exs
  - test/oban_powertools/chain_progression_test.exs
  - test/oban_powertools/chain_test.exs
  - test/oban_powertools/workflow_callbacks_test.exs
  - test/support/migrations/8_phase_61_batch_failure_fields.exs
  - test/test_helper.exs
findings:
  critical: 4
  warning: 0
  info: 0
  total: 4
status: issues_found
---

# Phase 61: Code Review Report

**Reviewed:** 2026-06-14T21:45:02Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Reviewed the Phase 61 batch, chain, callback, installer, runtime, and test changes. The main defects are durable-state correctness failures: public APIs can crash instead of returning structured errors, chain insertion can leave orphan batches, and callback dispatch/progress tracking can duplicate or permanently stall jobs around partial failures.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: BLOCKER - `insert_stream/2` Crashes When `:repo` Is Omitted

**File:** `lib/oban_powertools/batch.ex:137`

**Issue:** `validate_insert_stream_opts/1` checks `not is_atom(Keyword.get(opts, :repo))`, but `nil` is an atom in Elixir. A call such as `Batch.insert_stream(stream, total_count: 1)` passes validation and then `Keyword.fetch!(opts, :repo)` raises `KeyError` at line 143 instead of returning the advertised `%Batch.InsertError{reason: {:invalid_option, :repo}}`. This is a public API crash on a missing required option.

**Fix:**
```elixir
cond do
  not Keyword.has_key?(opts, :repo) ->
    invalid_option(:repo, opts)

  not is_atom(Keyword.fetch!(opts, :repo)) or is_nil(Keyword.fetch!(opts, :repo)) ->
    invalid_option(:repo, opts)

  # existing checks...
end
```

### CR-02: BLOCKER - Failed First Chain Insert Leaves an Executing Batch With No Jobs

**File:** `lib/oban_powertools/chain.ex:219`

**Issue:** `Chain.insert/3` creates the batch at lines 219-227 and then inserts the first Oban job at lines 229-248 outside a transaction or cleanup path. If `Oban.insert/2` returns `{:error, reason}` or raises after the batch insert succeeds, the function returns an error while leaving an `executing` batch with `total_count > 0` and no runnable first job. That row can never complete and will mislead operators and downstream batch/chain tracking.

**Fix:**
```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:batch, Batch.changeset(%Batch{}, %{name: chain.name, status: "executing", total_count: length(chain.steps)}))
|> Ecto.Multi.run(:first_job, fn _repo, %{batch: batch} ->
  [first_step | tail] = chain.steps
  first_step.job
  |> put_job_meta(first_job_meta(chain, batch, first_step, tail))
  |> do_oban_insert(Keyword.get(opts, :oban, Oban), Keyword.take(opts, [:timeout]))
end)
|> repo.transaction()
```

Alternatively, mark the batch `insert_failed` or delete it when first-job insertion fails.

### CR-03: BLOCKER - Chain Callback Delivery Is Not Idempotent Around Partial Failure

**File:** `lib/oban_powertools/chain/progression.ex:101`

**Issue:** `dispatch_callback/4` inserts the downstream job through `insert_next_job/3` and only afterwards marks the callback delivered at lines 236-245. If the job insert succeeds but `mark_delivered/3` fails, the callback stays `claimed` until its lease expires and will be retried, inserting the same downstream step again. The dedupe key is only on the callback row, not on the generated Oban job, so this creates duplicate chain steps from one upstream success.

**Fix:**
```elixir
repo.transaction(fn ->
  with :ok <- insert_next_job(repo, row, oban),
       {:ok, _row} <- mark_delivered(repo, row, now) do
    :ok
  else
    {:error, reason} -> repo.rollback(reason)
  end
end)
```

Also add a deterministic uniqueness/idempotency key to the downstream job, for example from `chain_id`, `chain_step_index`, and `upstream_job_id`, so retrying a delivered-but-unmarked callback cannot enqueue duplicates.

### CR-04: BLOCKER - Batch Progress Updates Are Split Across Non-Atomic Writes

**File:** `lib/oban_powertools/batch/tracker.ex:23`

**Issue:** `record_progress/3` inserts the `oban_powertools_batch_jobs` row, increments the batch, and inserts the chain callback as separate writes at lines 23-28. If `maybe_insert_chain_callback/5` fails after `insert_batch_job/5` and `increment_batch/4` have succeeded, the job is now treated as already tracked; a retry returns `{:ok, :duplicate}` and never recreates the missing chain callback, permanently stalling the chain. A stale or invalid `batch_id` in job metadata can also raise from the FK insert at lines 87-103 before the function can return `{:error, :batch_not_found}` or `{:ok, :ignored}`.

**Fix:**
```elixir
Multi.new()
|> Multi.insert_all(:batch_job, BatchJob, [attrs], on_conflict: :nothing, conflict_target: [:batch_id, :job_id])
|> Multi.run(:batch, fn repo, %{batch_job: {count, _}} ->
  if count == 1, do: increment_batch(repo, batch_id, state, now), else: {:ok, :duplicate}
end)
|> Multi.run(:chain_callback, fn repo, changes ->
  if changes.batch == :duplicate, do: {:ok, :ignored}, else: maybe_insert_chain_callback(repo, batch_id, job, state, now)
end)
|> repo.transaction()
```

Handle FK/constraint errors by returning a structured error and avoid committing the batch-job dedupe row unless the counter and required callback write also commit.

---

_Reviewed: 2026-06-14T21:45:02Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
