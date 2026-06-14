# Phase 59: Schemas & Foundation - Pattern Map

**Mapped:** $(date +%Y-%m-%d)
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/batch.ex` | schema | CRUD | `lib/oban_powertools/workflow/workflow.ex` | role-match |
| `lib/oban_powertools/batch_job.ex` | schema | CRUD | `lib/oban_powertools/workflow/step.ex` | role-match |
| `lib/oban_powertools/callback.ex` | schema | event-driven | `lib/oban_powertools/workflow/callback_outbox.ex` | exact |
| `lib/mix/tasks/oban_powertools.install.ex` | migration | setup | `lib/mix/tasks/oban_powertools.install.ex` | exact |
| `lib/oban_powertools/doctor/checks.ex` | utility | config | `lib/oban_powertools/doctor/checks.ex` | exact |
| `lib/oban_powertools/workflow/workflow.ex` | schema | CRUD | `lib/oban_powertools/workflow/workflow.ex` | exact |
| `test/oban_powertools/batch_test.exs` | test | CRUD | `test/oban_powertools/job_record_test.exs` | role-match |
| `test/oban_powertools/batch_job_test.exs` | test | CRUD | `test/oban_powertools/job_record_test.exs` | role-match |
| `test/oban_powertools/callback_test.exs` | test | event-driven | `test/oban_powertools/workflow_callbacks_test.exs` | exact |

## Pattern Assignments

### `lib/oban_powertools/batch.ex` (schema, CRUD)

**Analog:** `lib/oban_powertools/workflow/workflow.ex`

**Imports pattern:**
```elixir
defmodule ObanPowertools.Batch do
  @moduledoc """
  Durable batch definition plus runtime summary counters.
  """

  use Ecto.Schema
  import Ecto.Changeset
```

**Core CRUD pattern:**
```elixir
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_batches" do
    field(:status, :string, default: "executing")
    field(:total_count, :integer, default: 0)
    field(:success_count, :integer, default: 0)
    field(:discard_count, :integer, default: 0)
    field(:cancelled_count, :integer, default: 0)
    field(:snooze_count, :integer, default: 0)

    timestamps()
  end
```

---

### `lib/oban_powertools/batch_job.ex` (schema, CRUD)

**Analog:** `lib/oban_powertools/workflow/step.ex`

**Imports pattern:**
```elixir
defmodule ObanPowertools.BatchJob do
  @moduledoc """
  Durable batch job join schema.
  """

  use Ecto.Schema
  import Ecto.Changeset
```

**Core CRUD pattern:**
```elixir
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_batch_jobs" do
    field(:job_id, :integer)
    field(:state, :string, default: "available")

    belongs_to(:batch, ObanPowertools.Batch, type: :binary_id)

    timestamps()
  end
```

---

### `lib/oban_powertools/callback.ex` (schema, event-driven)

**Analog:** `lib/oban_powertools/workflow/callback_outbox.ex`

**Core schema pattern:**
```elixir
  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_callbacks" do
    field(:event, :string)
    field(:dedupe_key, :string)
    field(:status, :string, default: "pending")
    field(:payload, :map, default: %{})
    field(:attempts, :integer, default: 0)
    field(:available_at, :utc_datetime_usec)
    field(:claimed_at, :utc_datetime_usec)
    field(:claimed_by, :string)
    field(:lease_expires_at, :utc_datetime_usec)
    field(:delivered_at, :utc_datetime_usec)
    field(:last_error, :string)

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
    belongs_to(:batch, ObanPowertools.Batch, type: :binary_id)
    belongs_to(:recovery_attempt, ObanPowertools.Workflow.RecoveryAttempt, type: :binary_id)

    timestamps()
  end
```

---

### `lib/mix/tasks/oban_powertools.install.ex` (migration, setup)

**Analog:** `lib/mix/tasks/oban_powertools.install.ex`

**Generation pattern:**
```elixir
    |> Igniter.Libs.Ecto.gen_migration(
      repo_module(igniter),
      "oban_powertools_batches",
      timestamp: migration_timestamp(20), # adjust offset appropriately
      body: """
        def change do
          create table(:oban_powertools_batches, primary_key: false) do
            # ...
          end
        end
      """
    )
```

**Table Rename/Alter Pattern:**
```elixir
        def change do
          rename table(:oban_powertools_workflow_callback_outbox), to: table(:oban_powertools_callbacks)
          
          alter table(:oban_powertools_callbacks) do
            modify :workflow_id, :uuid, null: true, from: {:uuid, null: false}
            add :batch_id, references(:oban_powertools_batches, type: :uuid, on_delete: :delete_all)
          end
        end
```

---

### `lib/oban_powertools/doctor/checks.ex` (utility, config)

**Analog:** `lib/oban_powertools/doctor/checks.ex`

**Tables Manifest Pattern:**
```elixir
  @powertools_manifest %{
    # ...
    "batch" => [
      "oban_powertools_batches",
      "oban_powertools_batch_jobs"
    ],
    "workflow" => [
      # ...
      "oban_powertools_callbacks", # renamed from oban_powertools_workflow_callback_outbox
      # ...
    ],
```

---

### `test/oban_powertools/batch_test.exs` (test, CRUD)

**Analog:** `test/oban_powertools/job_record_test.exs`

**Test Imports Pattern:**
```elixir
defmodule ObanPowertools.BatchTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Batch
  alias ObanPowertools.TestRepo
```

---

## Shared Patterns

### Centralized Callback Schema
**Source:** `lib/oban_powertools/callback.ex`
**Apply to:** All generalized outbox queries and dependencies. `has_many` relations in workflows or batches should point to `ObanPowertools.Callback`.

## No Analog Found
*(None, all files matched cleanly with internal analogs.)*

## Metadata
**Analog search scope:** `lib/oban_powertools/**/*.{ex,exs}` and `test/oban_powertools/**/*test.exs`
**Files scanned:** 9 explicit targets
**Pattern extraction date:** $(date +%Y-%m-%d)
