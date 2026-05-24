# Phase 19: Await Registration, Signal Facts & Expiry Authority - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/workflow/runtime.ex` | service | event-driven | `lib/oban_powertools/workflow/runtime.ex` | exact |
| `lib/oban_powertools/workflow.ex` | service | request-response | `lib/oban_powertools/workflow.ex` | exact |
| `lib/oban_powertools/workflow/await.ex` | model | CRUD | `lib/oban_powertools/workflow/await.ex` | exact |
| `lib/oban_powertools/workflow/signal_record.ex` | model | event-driven | `lib/oban_powertools/workflow/signal_record.ex` | exact |
| `lib/oban_powertools/workflow/step.ex` | model | transform | `lib/oban_powertools/workflow/step.ex` | exact |
| `lib/oban_powertools/workflow/command_attempt.ex` | model | append-only | `lib/oban_powertools/workflow/command_attempt.ex` | exact |
| `lib/oban_powertools/workflow/workflow.ex` | model | CRUD | `lib/oban_powertools/workflow/workflow.ex` | exact |
| `lib/oban_powertools/explain.ex` | utility | request-response | `lib/oban_powertools/explain.ex` | exact |
| `lib/mix/tasks/oban_powertools.install.ex` | config | migration | `lib/mix/tasks/oban_powertools.install.ex` | exact |
| `test/support/migrations/2_phase_3_tables.exs` | migration | CRUD | `test/support/migrations/2_phase_3_tables.exs` | exact |
| `test/oban_powertools/workflow_runtime_test.exs` | test | event-driven | `test/oban_powertools/workflow_runtime_test.exs` | exact |

## Pattern Assignments

### `lib/oban_powertools/workflow/runtime.ex` (service, event-driven)

**Analog:** `lib/oban_powertools/workflow/runtime.ex`

**Imports + module vocabulary** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:11))
```elixir
import Ecto.Query

alias Ecto.Multi
alias ObanPowertools.{Audit, RuntimeConfig, Telemetry}

alias ObanPowertools.Workflow.{
  Await,
  CallbackOutbox,
  CommandAttempt,
  Edge,
  RecoveryAttempt,
  RecoverySession,
  Result,
  SignalRecord,
  Step,
  Workflow
}
```

**Public API stays thin, then routes into the command core** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:355), [workflow.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow.ex:101))
```elixir
def await_step(repo, workflow_id, step_name, attrs \\ %{}) do
  execute_command(repo, %{
    action: "await_step",
    scope: "step",
    workflow_id: workflow_id,
    step_name: to_string(step_name),
    attrs: attrs,
    source: "runtime"
  })
end
```

**Await registration pattern: `Ecto.Multi` plus step mirror update plus reconcile** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:366))
```elixir
Multi.new()
|> Multi.run(:await, fn repo, _changes ->
  existing =
    repo.one(
      from(await in Await,
        where: await.step_id == ^step.id and await.status == "waiting",
        limit: 1
      )
    )

  await_attrs = %{
    workflow_id: workflow.id,
    step_id: step.id,
    signal_name: signal_name,
    correlation_key: correlation_key,
    dedupe_key: dedupe_key,
    status: "waiting",
    resolution_policy: "ignore_late",
    deadline_at: deadline_at
  }

  if existing, do: repo.update(Await.changeset(existing, await_attrs)),
    else: repo.insert(Await.changeset(%Await{}, await_attrs))
end)
|> Multi.insert(:command_attempt, CommandAttempt.changeset(%CommandAttempt{}, ...))
|> Multi.run(:step, fn repo, %{await: await_row} ->
  step
  |> Step.changeset(%{
    state: "awaiting_signal",
    blocker_codes: ["waiting_on_signal"],
    blocker_details: %{
      "signal_name" => await_row.signal_name,
      "correlation_key" => await_row.correlation_key,
      "deadline_at" => deadline_iso8601(await_row.deadline_at)
    },
    awaiting_signal_name: signal_name,
    await_correlation_key: correlation_key,
    await_dedupe_key: dedupe_key,
    await_deadline_at: deadline_at,
    last_transition_at: now
  })
  |> repo.update()
end)
|> Multi.run(:reconcile, fn repo, _changes -> reconcile_workflow(repo, workflow.id, now) end)
```

**Signal ingress pattern: canonical fact insert first, duplicate becomes durable evidence instead of destructive overwrite** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:457))
```elixir
case repo.insert(SignalRecord.changeset(%SignalRecord{}, signal_attrs), returning: true) do
  {:ok, signal_record} ->
    persist_signal_attempt(repo, command, signal_record, "completed")
    reconcile_signals_for_signal(repo, signal_name, correlation_key, now)
    {:ok, mark_signal_late_if_expired(repo, signal_record)}

  {:error, reason} ->
    existing =
      repo.get_by(SignalRecord,
        signal_name: signal_name,
        correlation_key: correlation_key,
        dedupe_key: dedupe_key
      )

    if existing do
      persist_signal_attempt(repo, command, existing, "duplicate",
        reason_code: "duplicate_signal",
        reason_message: "signal dedupe key already exists"
      )

      {:ok, existing}
    else
      {:error, reason}
    end
end
```

**Authoritative expiry and reconcile path** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:769))
```elixir
def reconcile_workflow(repo, workflow_id, now \\ DateTime.utc_now()) do
  do_reconcile(repo, workflow_id, now, 0)
end

defp do_reconcile(repo, workflow_id, now, passes) do
  expire_waits(repo, workflow_id, now)
  reconcile_signals_for_workflow(repo, workflow_id, now)
  ...
end
```

**Expiry mutation pattern: await row first, then step truth** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:1053))
```elixir
repo.update!(
  Await.changeset(await_row, %{
    status: "expired",
    resolved_at: now
  })
)

repo.update!(
  Step.changeset(step, %{
    state: "expired",
    blocker_codes: ["expired_wait"],
    blocker_details: %{
      "signal_name" => await_row.signal_name,
      "correlation_key" => await_row.correlation_key
    },
    terminal_cause: "expired_wait",
    finished_at: now,
    last_transition_at: now
  })
)
```

**Signal-to-await resolution pattern** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:1109))
```elixir
repo.update!(
  Await.changeset(await_row, %{
    status: "resolved",
    resolved_at: now,
    resolved_signal_id: signal_record.id
  })
)

repo.update!(
  SignalRecord.changeset(signal_record, %{
    status: "consumed",
    workflow_id: await_row.workflow_id,
    matched_step_id: await_row.step_id,
    await_id: await_row.id
  })
)

repo.update!(
  Step.changeset(step, %{
    state: "available",
    blocker_codes: [],
    blocker_details: %{},
    awaiting_signal_name: nil,
    await_correlation_key: nil,
    await_dedupe_key: nil,
    await_deadline_at: nil,
    terminal_cause: nil,
    last_transition_at: now
  })
)
```

**Command evidence shape for signal attempts** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:1420), [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:1468))
```elixir
%{
  workflow_id: workflow && workflow.id,
  step_id: step && step.id,
  signal_record_id: signal_record && signal_record.id,
  scope: command.scope,
  action: command_action_name(command),
  status: status,
  reason_code: Keyword.get(opts, :reason_code),
  reason_message: Keyword.get(opts, :reason_message),
  actor_id: command.actor_id,
  source: command.source,
  requested_at: command.requested_at,
  completed_at: Keyword.get(opts, :completed_at, command.requested_at),
  before_snapshot: command_before_snapshot(command),
  after_snapshot: Keyword.get(opts, :after_snapshot, %{}),
  metadata: Keyword.get(opts, :metadata, %{})
}
```

**If Phase 19 adds a due-wait sweeper, copy lock-aware discovery from callback claiming** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:1512))
```elixir
repo.all(
  from(callback in CallbackOutbox,
    where:
      callback.status in ["pending", "failed", "claimed"] and
        (is_nil(callback.available_at) or callback.available_at <= ^now) and
        (is_nil(callback.lease_expires_at) or callback.lease_expires_at <= ^now),
    order_by: [asc: callback.available_at, asc: callback.inserted_at],
    limit: ^limit,
    lock: "FOR UPDATE SKIP LOCKED"
  )
)
```

### `lib/oban_powertools/workflow/await.ex` (model, CRUD)

**Analog:** `lib/oban_powertools/workflow/await.ex`

**Schema and constraint pattern** ([await.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/await.ex:11))
```elixir
schema "oban_powertools_workflow_awaits" do
  field(:signal_name, :string)
  field(:correlation_key, :string)
  field(:dedupe_key, :string)
  field(:status, :string, default: "waiting")
  field(:resolution_policy, :string, default: "ignore_late")
  field(:deadline_at, :utc_datetime_usec)
  field(:resolved_at, :utc_datetime_usec)

  belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
  belongs_to(:step, ObanPowertools.Workflow.Step, type: :binary_id)
  belongs_to(:resolved_signal, ObanPowertools.Workflow.SignalRecord, type: :binary_id)

  timestamps(updated_at: false)
end
```

**Validation posture: narrow cast + unique partial-index hook** ([await.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/await.ex:27))
```elixir
|> validate_required([
  :workflow_id,
  :step_id,
  :signal_name,
  :correlation_key,
  :dedupe_key,
  :status,
  :resolution_policy
])
|> unique_constraint(:step_id, name: :oban_powertools_workflow_awaits_step_id_status_index)
```

**Planner note:** if Phase 19 adds workflow-resolved authority or an active-await pointer, keep the row-level truth here and preserve the same changeset style: explicit fields, required invariants, DB-enforced uniqueness.

### `lib/oban_powertools/workflow/signal_record.ex` (model, event-driven)

**Analog:** `lib/oban_powertools/workflow/signal_record.ex`

**Canonical signal fact schema** ([signal_record.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/signal_record.ex:11))
```elixir
schema "oban_powertools_workflow_signals" do
  field(:signal_name, :string)
  field(:correlation_key, :string)
  field(:dedupe_key, :string)
  field(:status, :string, default: "pending")
  field(:payload, :map, default: %{})
  field(:received_at, :utc_datetime_usec)

  belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
  belongs_to(:matched_step, ObanPowertools.Workflow.Step, type: :binary_id)
  belongs_to(:await, ObanPowertools.Workflow.Await, type: :binary_id)
end
```

**Uniqueness seam for canonical identity** ([signal_record.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/signal_record.ex:26))
```elixir
|> unique_constraint([:signal_name, :correlation_key, :dedupe_key],
  name: :oban_powertools_workflow_signals_dedupe_index
)
```

**Planner note:** if Phase 19 changes matching authority from correlation-only to workflow-resolved authority, extend this schema and migration in the same style rather than moving correctness to metadata blobs.

### `lib/oban_powertools/workflow/step.ex` (model, transform)

**Analog:** `lib/oban_powertools/workflow/step.ex`

**Diagnosis-facing wait mirror fields live here, but remain thin** ([step.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/step.ex:11))
```elixir
field(:awaiting_signal_name, :string)
field(:await_correlation_key, :string)
field(:await_dedupe_key, :string)
field(:await_deadline_at, :utc_datetime_usec)
```

**Changeset pattern for mirror fields** ([step.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/step.ex:46))
```elixir
|> cast(params, [
  ...,
  :awaiting_signal_name,
  :await_correlation_key,
  :await_dedupe_key,
  :await_deadline_at,
  ...
])
```

**Planner note:** if Phase 19 adds `active_await_id` or similar operator-facing projection, this is the analog to copy. Keep it as projection-only, not the source of semantic truth.

### `lib/oban_powertools/workflow/command_attempt.ex` (model, append-only)

**Analog:** `lib/oban_powertools/workflow/command_attempt.ex`

**Append-only evidence schema for accepted/rejected mutations and signal ingress attempts** ([command_attempt.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/command_attempt.ex:11))
```elixir
schema "oban_powertools_workflow_command_attempts" do
  field(:scope, :string, default: "workflow")
  field(:action, :string)
  field(:status, :string, default: "completed")
  field(:reason_code, :string)
  field(:reason_message, :string)
  field(:actor_id, :string)
  field(:source, :string, default: "runtime")
  field(:requested_at, :utc_datetime_usec)
  field(:completed_at, :utc_datetime_usec)
  field(:before_snapshot, :map, default: %{})
  field(:after_snapshot, :map, default: %{})
  field(:metadata, :map, default: %{})

  belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
  belongs_to(:step, ObanPowertools.Workflow.Step, type: :binary_id)
  belongs_to(:signal_record, ObanPowertools.Workflow.SignalRecord, type: :binary_id)
end
```

**Planner note:** if Phase 19 keeps duplicate/replay evidence inside the existing ledger instead of a new table, copy this shape and the `persist_signal_attempt/5` caller pattern from `runtime.ex`.

### `lib/oban_powertools/workflow/workflow.ex` (model, CRUD)

**Analog:** `lib/oban_powertools/workflow/workflow.ex`

**Workflow associations define the durable truth graph** ([workflow.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/workflow.ex:29))
```elixir
has_many(:awaits, ObanPowertools.Workflow.Await, foreign_key: :workflow_id)
has_many(:signal_records, ObanPowertools.Workflow.SignalRecord, foreign_key: :workflow_id)
has_many(:callback_outbox, ObanPowertools.Workflow.CallbackOutbox, foreign_key: :workflow_id)
has_many(:recovery_attempts, ObanPowertools.Workflow.RecoveryAttempt, foreign_key: :workflow_id)
has_many(:command_attempts, ObanPowertools.Workflow.CommandAttempt, foreign_key: :workflow_id)
```

**Planner note:** if Phase 19 adds a new evidence schema, wire its association here in the same direct style.

### `lib/oban_powertools/workflow.ex` (service, request-response)

**Analog:** `lib/oban_powertools/workflow.ex`

**Public paved-road wrapper pattern** ([workflow.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow.ex:92))
```elixir
def await_step(repo, workflow_id, step_name, attrs \\ []),
  do:
    ObanPowertools.Workflow.Runtime.await_step(
      repo,
      workflow_id,
      step_name,
      Enum.into(attrs, %{})
    )

def deliver_signal(repo, attrs),
  do: ObanPowertools.Workflow.Runtime.deliver_signal(repo, Enum.into(attrs, %{}))
```

**Planner note:** keep any new Phase 19 API narrow and context-like. Do not expose raw reconciliation structs or lower-level signal-routing internals.

### `lib/oban_powertools/explain.ex` (utility, request-response)

**Analog:** `lib/oban_powertools/explain.ex`

**Diagnosis surface pattern for workflow/step stories** ([explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:137))
```elixir
%{
  diagnosis: Runtime.workflow_diagnosis(workflow, steps),
  semantics: Runtime.semantics_profile(workflow),
  latest_rejection: latest_rejection,
  rejection_summary: rejection_summary(latest_rejection),
  callback_posture: callback_posture(repo, workflow.id),
  latest_recovery_session: latest_recovery_session(repo, workflow.id)
}
```

**Rejection lookup pattern** ([explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:164))
```elixir
from(attempt in CommandAttempt,
  where: attempt.workflow_id == ^workflow_id and attempt.status == "rejected",
  order_by: [desc: attempt.requested_at, desc: attempt.inserted_at],
  limit: 1
)
```

**Runtime diagnosis helpers to reuse if Phase 19 expands operator-facing reason strings** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:773))
```elixir
def workflow_diagnosis(%Workflow{} = workflow, steps) do
  cond do
    workflow.state == "cancel_requested" or not is_nil(workflow.cancel_requested_at) -> "cancel_requested"
    workflow.state == "expired" -> "expired_wait"
    workflow.terminal_cause -> workflow.terminal_cause
    step = Enum.find(steps, &(step_diagnosis(&1) != nil)) -> step_diagnosis(step)
    true -> workflow.state
  end
end
```

### `lib/mix/tasks/oban_powertools.install.ex` (config, migration)

**Analog:** `lib/mix/tasks/oban_powertools.install.ex`

**Installer-owned workflow semantics migration block** ([oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:466))
```elixir
|> Igniter.Libs.Ecto.gen_migration(
  repo_module(igniter),
  "oban_powertools_workflow_semantics",
  timestamp: migration_timestamp(24),
  body: """
    def change do
      create table(:oban_powertools_workflow_awaits, primary_key: false) do
        ...
      end

      create table(:oban_powertools_workflow_signals, primary_key: false) do
        ...
      end
    end
  """
)
```

**Separate migration for command evidence ledger** ([oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:581))
```elixir
|> Igniter.Libs.Ecto.gen_migration(
  repo_module(igniter),
  "oban_powertools_workflow_command_attempts",
  timestamp: migration_timestamp(25),
  body: """
    def change do
      create table(:oban_powertools_workflow_command_attempts, primary_key: false) do
        ...
      end
    end
  """
)
```

**Planner note:** any schema change in Phase 19 needs matching edits here. Keep the generated migration bodies explicit, narrow, and index-driven.

### `test/support/migrations/2_phase_3_tables.exs` (migration, CRUD)

**Analog:** `test/support/migrations/2_phase_3_tables.exs`

**Test migration mirrors production semantics tables exactly** ([2_phase_3_tables.exs](/Users/jon/projects/oban_powertools/test/support/migrations/2_phase_3_tables.exs:145))
```elixir
create table(:oban_powertools_workflow_awaits, primary_key: false) do
  add(:id, :uuid, primary_key: true)
  add(:workflow_id, references(:oban_powertools_workflows, type: :uuid, on_delete: :delete_all), null: false)
  add(:step_id, references(:oban_powertools_workflow_steps, type: :uuid, on_delete: :delete_all), null: false)
  add(:signal_name, :string, null: false)
  add(:correlation_key, :string, null: false)
  add(:dedupe_key, :string, null: false)
  add(:status, :string, null: false, default: "waiting")
  ...
end
```

**Signal table and canonical dedupe index** ([2_phase_3_tables.exs](/Users/jon/projects/oban_powertools/test/support/migrations/2_phase_3_tables.exs:181))
```elixir
create unique_index(
  :oban_powertools_workflow_signals,
  [:signal_name, :correlation_key, :dedupe_key],
  name: :oban_powertools_workflow_signals_dedupe_index
)
```

**Planner note:** every Phase 19 installer migration change must be mirrored here in lockstep or tests will diverge from install-time schema.

### `test/oban_powertools/workflow_runtime_test.exs` (test, event-driven)

**Analog:** `test/oban_powertools/workflow_runtime_test.exs`

**Proof lane for pre-await consumption** ([workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:113))
```elixir
assert {:ok, _signal} =
         Workflow.deliver_signal(TestRepo,
           signal_name: "approval_received",
           correlation_key: workflow.id,
           dedupe_key: "approval-1",
           payload: %{approved_by: "ops"}
         )

assert {:ok, _await} =
         Workflow.await_step(TestRepo, workflow.id, :approval,
           signal_name: "approval_received",
           correlation_key: workflow.id,
           dedupe_key: "approval-1"
         )

assert step.state == "available"
assert signal.status == "consumed"
assert await_row.status == "resolved"
```

**Proof lane for authoritative expiry and late signal evidence** ([workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:144))
```elixir
assert {:ok, _await} =
         Workflow.await_step(TestRepo, workflow.id, :approval,
           signal_name: "approval_received",
           correlation_key: workflow.id,
           dedupe_key: "approval-expired",
           registered_at: now,
           deadline_at: DateTime.add(now, -5, :second)
         )

assert step.state == "expired"
assert step.terminal_cause == "expired_wait"
assert persisted_workflow.state == "expired"

assert {:ok, signal} = Workflow.deliver_signal(TestRepo, ...)
assert signal.status == "late"
```

**Proof lane for durable rejection/evidence posture** ([workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:248), [workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:292))
```elixir
assert {:error, rejection} = Workflow.recover_step(...)
assert rejection.status == :rejected
assert rejection.reason_code == "illegal_transition"

rejected_attempt =
  TestRepo.get_by!(CommandAttempt,
    workflow_id: workflow.id,
    step_id: ...,
    status: "rejected"
  )
```

**Planner note:** add new Phase 19 cases in this file first. The repo already treats runtime tests as the proof lane for await/signal/expiry semantics.

## Shared Patterns

### DB-First Truth
**Sources:** [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:769), [17-CONTEXT.md](/Users/jon/projects/oban_powertools/.planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md:1), [19-CONTEXT.md](/Users/jon/projects/oban_powertools/.planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md:1)

Apply to runtime, schema, and tests: facts are persisted first; wakeups and late/expiry outcomes are derived by reconciliation over rows, not transient wake paths.

### Thin Step Mirror, Rich Await Truth
**Sources:** [step.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/step.ex:25), [await.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/await.ex:11), [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:423)

Apply to step/await changes: keep operator-visible summary fields on `workflow_steps`, but store semantic resolution details on `workflow_awaits`.

### Canonical Row Plus Durable Duplicate Evidence
**Sources:** [signal_record.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/signal_record.ex:26), [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:473), [command_attempt.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/command_attempt.ex:11)

Apply to signal ingress and replay handling: one canonical signal row is protected by a unique index; duplicates/replays are preserved through an evidence row rather than destructive upsert.

### Explicit Diagnosis Strings
**Sources:** [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:773), [explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:151)

Apply to diagnosis-facing mirrors and tests: expose bounded reason strings like `"waiting_on_signal"` and `"expired_wait"` from durable fields, not inferred UI-only semantics.

### Installer/Test Migration Lockstep
**Sources:** [oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:466), [2_phase_3_tables.exs](/Users/jon/projects/oban_powertools/test/support/migrations/2_phase_3_tables.exs:145), [4_phase_5_tables.exs](/Users/jon/projects/oban_powertools/test/support/migrations/4_phase_5_tables.exs:5)

Apply to all schema changes: update the install task and test-support migration mirrors together.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/oban_powertools/workflow/signal_attempt.ex` | model | append-only | No dedicated signal-ingress evidence table exists yet; nearest analog is `lib/oban_powertools/workflow/command_attempt.ex` plus `persist_signal_attempt/5`. |
| `test/oban_powertools/workflow_signal_ingress_test.exs` | test | event-driven | Await/signal semantics are currently proven inside `test/oban_powertools/workflow_runtime_test.exs`; no dedicated ingress-only test module exists. |

## Metadata

**Analog search scope:** `lib/oban_powertools/workflow/`, `lib/oban_powertools/`, `lib/mix/tasks/`, `test/oban_powertools/`, `test/support/migrations/`
**Files scanned:** 13
**Pattern extraction date:** 2026-05-24
