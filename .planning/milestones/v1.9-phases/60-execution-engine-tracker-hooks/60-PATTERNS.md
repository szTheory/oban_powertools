# Phase 60: Execution Engine & Tracker Hooks - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/batch/tracker.ex` | service | transactional / CRUD | `lib/oban_powertools/cron.ex` | role-match |
| `test/oban_powertools/batch/tracker_test.exs` | test | transactional | `test/oban_powertools/batch_test.exs` | role-match |
| `lib/oban_powertools/worker/hooks.ex` | hook | event-driven | `lib/oban_powertools/worker/hooks.ex` | exact (self) |

## Pattern Assignments

### `lib/oban_powertools/batch/tracker.ex` (service, transactional / CRUD)

**Analog:** `lib/oban_powertools/cron.ex`

**Imports pattern** (lines 5-7):
```elixir
  import Ecto.Query

  alias Ecto.Multi
```

**Core Multi and Idempotency Pattern** (lines 35-49):
```elixir
    Multi.new()
    |> Multi.insert(
      :slot,
      Slot.changeset(%Slot{}, %{
        entry_id: entry.id,
        slot_at: slot_at,
        state: "pending",
        claimed_at: now,
        attempt_count: 0,
        policy_snapshot: policy_snapshot(entry),
        metadata: %{"source" => source, "manual" => manual?}
      }),
      on_conflict: :nothing,
      conflict_target: [:entry_id, :slot_at],
      returning: true
    )
```

**Transaction Handling Pattern** (lines 66-75):
```elixir
    |> repo.transaction()
    |> case do
      {:ok, %{decision: decision, job: job, updated_slot: slot}} ->
        maybe_record_coverage(repo, entry, slot_at, manual?)
        emit_claim_telemetry(repo, entry, slot, decision)
        {:ok, %{slot: slot, job: job, decision: decision}}

      {:error, :decision, reason, _} ->
        {:error, reason}

      {:error, _step, reason, _} ->
        {:error, reason}
    end
```

**Atomic Updates (from RESEARCH.md since strictly required):**
```elixir
{1, [batch]} =
  repo.update_all(
    from(b in ObanPowertools.Batch,
      where: b.id == ^batch_id,
      update: [inc: [{^inc_field, 1}]],
      select: b
    ),
    []
  )
```

---

### `test/oban_powertools/batch/tracker_test.exs` (test, transactional)

**Analog:** `test/oban_powertools/batch_test.exs`

**Test Structure Pattern** (lines 1-8):
```elixir
defmodule ObanPowertools.BatchTest do
  use ObanPowertools.DataCase, async: true

  alias ObanPowertools.Batch

  describe "changeset/2" do
    test "validates integer constraints" do
```

---

### `lib/oban_powertools/worker/hooks.ex` (hook, event-driven)

**Analog:** `lib/oban_powertools/worker/hooks.ex` (self)

**Hook Result Capture Pattern** (lines 12-25):
```elixir
  def after_result(worker_mod, %Oban.Job{} = job, result) do
    case result do
      :ok ->
        safe_invoke(worker_mod, :on_success, [
          job,
          %{state: :success, result: :ok, value: nil}
        ])

      {:ok, value} = success_result ->
        safe_invoke(worker_mod, :on_success, [
          job,
          %{state: :success, result: success_result, value: value}
        ])
```

**Exception Hook Pattern** (lines 59-71):
```elixir
  def after_exception(worker_mod, %Oban.Job{} = job, kind, reason, stacktrace) do
    if terminal_attempt?(job) do
      safe_invoke(worker_mod, :on_discard, [
        job,
        discard_event(reason, nil, kind, stacktrace)
      ])
    else
      safe_invoke(worker_mod, :on_failure, [
        job,
        failure_event(reason, nil, kind, stacktrace)
      ])
    end
  end
```
*(Note: Batch tracker calls should be woven around these `safe_invoke` paths for `job` matching batch metadata.)*

---

## Shared Patterns

### Idempotency
**Source:** `lib/oban_powertools/batch_job.ex` + RESEARCH.md
**Apply to:** `lib/oban_powertools/batch/tracker.ex`
```elixir
# Unique constraint on batch_id and job_id enables exactly-once inserts:
repo.insert_all(ObanPowertools.BatchJob, [...], on_conflict: :nothing)
```

## Metadata

**Analog search scope:** `lib/oban_powertools/**/*.ex`, `test/oban_powertools/**/*_test.exs`
**Files scanned:** 6 (hooks, cron, batch, batch_job, callbacks)
**Pattern extraction date:** 2026-06-14
