# Phase 61: APIs (Batches & Chains) - Pattern Map

**Mapped:** 2026-06-14
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/batch.ex` | model/API | streaming + CRUD | `lib/oban_powertools/batch.ex` + `lib/oban_powertools/batch/tracker.ex` | role-match |
| `lib/oban_powertools/batch/tracker.ex` | service | event-driven + CRUD | `lib/oban_powertools/batch/tracker.ex` | exact |
| `lib/oban_powertools/callback.ex` | model | event-driven | `lib/oban_powertools/callback.ex` | exact |
| `lib/oban_powertools/chain.ex` | API/DSL | request-response + transform | `lib/oban_powertools/workflow.ex` | role-match |
| `lib/oban_powertools/chain/progression.ex` | service | event-driven + CRUD | `lib/oban_powertools/workflow/runtime.ex` | role-match |
| `lib/oban_powertools/job_record.ex` | model/service | CRUD | `lib/oban_powertools/job_record.ex` | exact |
| `lib/oban_powertools/worker.ex` | provider/macro | request-response | `lib/oban_powertools/worker.ex` | exact |
| `lib/oban_powertools/worker/hooks.ex` | hook/middleware | event-driven | `lib/oban_powertools/worker/hooks.ex` | exact |
| `test/oban_powertools/batch_test.exs` | test | streaming + CRUD | `test/oban_powertools/batch/tracker_test.exs` | role-match |
| `test/oban_powertools/chain_test.exs` | test | request-response + transform | `test/oban_powertools/workflow_test.exs` | role-match |
| `test/oban_powertools/chain_progression_test.exs` | test | event-driven + CRUD | `test/oban_powertools/workflow_callbacks_test.exs` | role-match |
| `test/oban_powertools/chain_output_test.exs` | test | CRUD | `test/oban_powertools/job_record_test.exs` + `test/oban_powertools/worker_test.exs` | role-match |

## Pattern Assignments

### `lib/oban_powertools/batch.ex` (model/API, streaming + CRUD)

**Analog:** `lib/oban_powertools/batch.ex`, `lib/oban_powertools/batch/tracker.ex`, `lib/oban_powertools/lifeline.ex`

**Schema/changeset pattern** (`lib/oban_powertools/batch.ex` lines 6-21):
```elixir
use Ecto.Schema
import Ecto.Changeset

@primary_key {:id, :binary_id, autogenerate: true}

schema "oban_powertools_batches" do
  field(:status, :string, default: "executing")
  field(:total_count, :integer, default: 0)
  field(:success_count, :integer, default: 0)
  field(:discard_count, :integer, default: 0)
  field(:cancelled_count, :integer, default: 0)
  field(:snooze_count, :integer, default: 0)
  field(:completed_at, :utc_datetime_usec)

  timestamps()
end
```

**Validation pattern** (`lib/oban_powertools/batch.ex` lines 23-47):
```elixir
def changeset(struct, params) do
  struct
  |> cast(params, [:status, :total_count, :success_count, :discard_count, :cancelled_count, :snooze_count, :completed_at])
  |> validate_required([:status, :total_count, :success_count, :discard_count, :cancelled_count, :snooze_count])
  |> validate_number(:total_count, greater_than_or_equal_to: 0)
  |> validate_number(:success_count, greater_than_or_equal_to: 0)
  |> validate_number(:discard_count, greater_than_or_equal_to: 0)
  |> validate_number(:cancelled_count, greater_than_or_equal_to: 0)
  |> validate_number(:snooze_count, greater_than_or_equal_to: 0)
end
```

**Bulk insert pattern** (`lib/oban_powertools/lifeline.ex` lines 570-587):
```elixir
rows =
  Enum.map(events, fn event ->
    %{
      resource_type: archive_resource_type(event.resource),
      resource_id: archive_resource_id(event.resource),
      action: event.action,
      archived_at: now,
      inserted_at: DateTime.to_naive(now)
    }
  end)

{count, _} = repo.insert_all("oban_powertools_repair_archives", rows)
{count, event_ids}
```

**Planner note:** no existing `Oban.insert_all/2` call exists in the repo. For `Batch.insert_stream/2`, copy the project result/error struct style from Workflow/JobRecord tagged tuples, but use Oban's bulk changeset insertion per RESEARCH.md.

---

### `lib/oban_powertools/batch/tracker.ex` (service, event-driven + CRUD)

**Analog:** `lib/oban_powertools/batch/tracker.ex`

**Imports/aliases pattern** (lines 6-11):
```elixir
import Ecto.Query

alias Ecto.Multi
alias ObanPowertools.Batch
alias ObanPowertools.BatchJob
alias ObanPowertools.Callback
```

**Exactly-once progress pattern** (lines 15-31):
```elixir
def record_progress(repo, %Oban.Job{} = job, state) when state in @valid_states do
  case batch_id_from_meta(job.meta) do
    nil -> {:ok, :ignored}
    batch_id ->
      now = timestamp()

      case insert_batch_job(repo, batch_id, job, state, now) do
        :inserted ->
          with {:ok, batch} <- increment_batch(repo, batch_id, state, now) do
            maybe_complete_batch(repo, batch)
          end

        :duplicate -> {:ok, :duplicate}
      end
  end
end
```

**Callback failure pattern** (lines 37-50):
```elixir
def record_callback_exhaustion(repo, %Oban.Job{} = job) do
  case callback_batch_id(repo, job) do
    nil -> {:ok, :ignored}
    batch_id ->
      {count, _rows} =
        repo.update_all(
          from(batch in Batch, where: batch.id == ^batch_id),
          set: [status: "callback_failed", updated_at: timestamp()]
        )

      if count == 1, do: {:ok, :callback_failed}, else: {:ok, :ignored}
  end
end
```

**Completion outbox pattern** (lines 144-187):
```elixir
Multi.new()
|> Multi.update_all(:batch, from(candidate in Batch, where: candidate.id == ^batch.id and is_nil(candidate.completed_at)), set: [completed_at: completed_at, status: status])
|> Multi.run(:callback, fn repo, %{batch: {updated_count, _rows}} ->
  if updated_count == 1 do
    insert_callback(repo, batch.id, event)
  else
    {:ok, :already_completed}
  end
end)
|> repo.transaction()
```

---

### `lib/oban_powertools/callback.ex` (model, event-driven)

**Analog:** `lib/oban_powertools/callback.ex`

**Schema pattern** (lines 11-28):
```elixir
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
end
```

**Validation/event vocabulary pattern** (lines 49-58):
```elixir
|> validate_required([:event, :dedupe_key, :status, :payload, :attempts])
|> validate_inclusion(:event, ["workflow.terminal", "workflow.recovery_completed", "batch.completed", "batch.exhausted"])
|> validate_number(:attempts, greater_than_or_equal_to: 0)
|> unique_constraint(:dedupe_key)
```

**Planner note:** extend the event inclusion list for chain events and update dispatch claiming so Workflow dispatch does not claim chain events.

---

### `lib/oban_powertools/chain.ex` (API/DSL, request-response + transform)

**Analog:** `lib/oban_powertools/workflow.ex`

**Public struct/API pattern** (lines 6-17, 31-39, 84-90):
```elixir
alias Ecto.Changeset
alias Ecto.Multi

defstruct name: nil,
          workflow_context: %{},
          definition_version: 1,
          steps: [],
          edges: []

def new(opts) when is_list(opts) do
  %__MODULE__{
    name: normalize_optional_name(Keyword.get(opts, :name)),
    workflow_context: Keyword.get(opts, :workflow_context, %{}),
    definition_version: Keyword.get(opts, :definition_version, 1)
  }
end

def insert(%__MODULE__{} = workflow, repo) do
  with {:ok, normalized} <- normalize(workflow) do
    persist(repo, normalized)
  end
end
```

**Job changeset normalization pattern** (lines 263-279):
```elixir
defp normalize_job_definition(%Changeset{} = changeset) do
  worker = Changeset.get_field(changeset, :worker)
  input = Changeset.get_field(changeset, :args) || %{}
  queue = Changeset.get_field(changeset, :queue) || "default"
  meta = Changeset.get_field(changeset, :meta) || %{}

  if is_nil(worker) do
    raise ArgumentError, "workflow steps require a job changeset with a worker"
  end

  %{worker: worker, input: normalize_payload(input), context: normalize_payload(meta), queue: to_string(queue)}
end
```

**Validation pattern** (lines 331-377):
```elixir
defp validate_duplicate_step_names(steps) do
  names = Enum.map(steps, & &1.name)

  case Enum.find(names, fn name -> Enum.count(names, &(&1 == name)) > 1 end) do
    nil -> :ok
    name -> {:error, {:validation, {:duplicate_step_name, name}}}
  end
end
```

**JSON normalization pattern** (lines 397-414):
```elixir
defp ensure_json(value) do
  normalized = normalize_payload(value)
  Jason.encode!(normalized)
  {:ok, normalized}
rescue
  Protocol.UndefinedError -> {:error, {:validation, :non_serializable_payload}}
end

defp normalize_payload(map) when is_map(map) do
  Map.new(map, fn {key, value} -> {to_string(key), normalize_payload(value)} end)
end
```

---

### `lib/oban_powertools/chain/progression.ex` (service, event-driven + CRUD)

**Analog:** `lib/oban_powertools/workflow/runtime.ex`

**Dispatcher claim/retry pattern** (lines 735-777):
```elixir
rows = claim_callbacks(repo, now, dispatcher_id, lease_seconds, limit)

Enum.reduce(rows, %{delivered: 0, failed: 0}, fn row, acc ->
  case handler.handle_workflow_callback(row.payload) do
    :ok ->
      repo.update!(
        Callback.changeset(row, %{status: "delivered", attempts: row.attempts + 1, delivered_at: now, lease_expires_at: nil, last_error: nil})
      )
      %{acc | delivered: acc.delivered + 1}

    {:error, reason} ->
      repo.update!(
        Callback.changeset(row, %{status: "failed", attempts: row.attempts + 1, available_at: DateTime.add(now, 30, :second), lease_expires_at: nil, last_error: inspect(reason)})
      )
      %{acc | failed: acc.failed + 1}
  end
end)
```

**Outbox enqueue pattern** (lines 1453-1480):
```elixir
callback_id = Ecto.UUID.generate()

%Callback{id: callback_id}
|> Callback.changeset(%{
  workflow_id: workflow.id,
  event: event,
  dedupe_key: "#{workflow.id}:#{event}:#{dedupe_suffix}",
  status: "pending",
  payload: Map.merge(%{"callback_id" => callback_id, "event" => event, "workflow_id" => workflow.id, "envelope_version" => @callback_envelope_version}, payload),
  attempts: 0,
  available_at: now
})
|> repo.insert(on_conflict: :nothing, conflict_target: [:dedupe_key])
```

**Lease-protected claim pattern** (lines 1677-1711):
```elixir
repo.transaction(fn ->
  lease_expires_at = DateTime.add(now, lease_seconds, :second)

  rows =
    repo.all(
      from(callback in Callback,
        where: callback.status in ["pending", "failed", "claimed"] and
          (is_nil(callback.available_at) or callback.available_at <= ^now) and
          (is_nil(callback.lease_expires_at) or callback.lease_expires_at <= ^now),
        order_by: [asc: callback.available_at, asc: callback.inserted_at],
        limit: ^limit,
        lock: "FOR UPDATE SKIP LOCKED"
      )
    )
end)
```

**Planner note:** add an event filter to this query for chain progression and to `Workflow.Runtime` for workflow events. Current code claims all pending callback rows.

---

### `lib/oban_powertools/job_record.ex` (model/service, CRUD)

**Analog:** `lib/oban_powertools/job_record.ex`

**Fetch API pattern** (lines 92-123):
```elixir
def fetch_result(%Oban.Job{} = job), do: configured_repo() |> fetch_result(job)
def fetch_result(oban_job_id) when is_integer(oban_job_id), do: configured_repo() |> fetch_result(oban_job_id)
def fetch_result(repo, %Oban.Job{id: oban_job_id}), do: fetch_result(repo, oban_job_id)

def fetch_result(repo, oban_job_id) when is_integer(oban_job_id) do
  case fetch_record(repo, oban_job_id) do
    {:ok, %__MODULE__{payload: payload}} -> {:ok, payload}
    {:error, :not_found} -> {:error, :not_found}
  end
end
```

**Durable output record pattern** (lines 70-82):
```elixir
def record(repo, worker_name, %Oban.Job{} = job, payload, opts) do
  repo = repo || configured_repo()
  retention = retention_policy(opts)
  limit = output_limit(opts)

  with {:ok, normalized} <- safe_normalize(payload, job),
       {:ok, encoded} <- safe_encode(normalized, job),
       :ok <- ensure_within_limit(encoded, limit, job),
       {:ok, attrs} <- record_attrs(worker_name, job, normalized, encoded, retention, opts) do
    insert_record(repo, attrs, job)
  else
    {:error, _reason} -> :ok
  end
end
```

**Output unavailable mapping:** `Chain.fetch_upstream_result/1` should call `JobRecord.fetch_result/2` and convert `{:error, :not_found}` to the explicit chain error chosen by the plan, e.g. `{:error, :output_unavailable}`.

---

### `lib/oban_powertools/worker.ex` (provider/macro, request-response)

**Analog:** `lib/oban_powertools/worker.ex`

**Record-output config pattern** (lines 8-41):
```elixir
record_output_config = Keyword.get(opts, :record_output, false)
output_limit_config = Keyword.get(opts, :output_limit, 65_536)
output_retention_config = Keyword.get(opts, :output_retention, :standard)

normalized_output_recording =
  normalize_output_recording_config!(
    record_output_config,
    output_limit_config,
    output_retention_config,
    __CALLER__
  )
```

**Worker introspection pattern** (lines 89-92):
```elixir
def __powertools_limits__, do: @powertools_limits
def __powertools_deadline_ms__, do: @powertools_deadline_ms
def __powertools_output_recording__, do: @powertools_output_recording
def __powertools_redact__, do: @powertools_redact
```

**Output recording order pattern** (lines 174-178, 216-229):
```elixir
result = process(job)
__powertools_record_output__(job, result)
ObanPowertools.Worker.Hooks.after_result(__MODULE__, job, result)
result

case result do
  {:ok, payload} ->
    settings = __powertools_output_recording__()
    if settings.record_output do
      ObanPowertools.JobRecord.record(nil, __MODULE__, job, payload, Map.to_list(settings))
    end
    :ok
  _other -> :ok
end
```

**Planner note:** chain build/insert validation for output-dependent steps should use `worker_module.__powertools_output_recording__()` when the worker module is known.

---

### `lib/oban_powertools/worker/hooks.ex` (hook/middleware, event-driven)

**Analog:** `lib/oban_powertools/worker/hooks.ex`

**Observe-only hook + tracker pattern** (lines 16-33):
```elixir
def after_result(worker_mod, %Oban.Job{} = job, result) do
  case result do
    :ok ->
      record_batch_progress(job, :success)
      safe_invoke(worker_mod, :on_success, [job, %{state: :success, result: :ok, value: nil}])

    {:ok, value} = success_result ->
      record_batch_progress(job, :success)
      safe_invoke(worker_mod, :on_success, [job, %{state: :success, result: success_result, value: value}])
  end
end
```

**Callback job isolation pattern** (lines 92-125):
```elixir
defp record_batch_progress(%Oban.Job{} = job, state) do
  unless callback_job?(job) do
    with repo when not is_nil(repo) <- RuntimeConfig.repo() do
      _ = Tracker.record_progress(repo, job, state)
    end
  end

  :ok
end

defp callback_meta?(meta) when is_map(meta) do
  Map.has_key?(meta, "callback_id") or
    Map.has_key?(meta, :callback_id) or
    Map.has_key?(meta, "oban_powertools_callback_id") or
    Map.has_key?(meta, :oban_powertools_callback_id)
end
```

**Planner note:** preserve observe-only hook semantics. Chain progression belongs in callback/outbox code, not worker `on_success/2`.

## Test Pattern Assignments

### Batch Streaming Tests

**Analog:** `test/oban_powertools/batch/tracker_test.exs`, `test/oban_powertools/batch_test.exs`

**DataCase/import pattern** (`test/oban_powertools/batch/tracker_test.exs` lines 1-7):
```elixir
defmodule ObanPowertools.Batch.TrackerTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Batch
  alias ObanPowertools.Batch.Tracker
  alias ObanPowertools.BatchJob
  alias ObanPowertools.Callback
end
```

**State/callback assertions** (`test/oban_powertools/batch/tracker_test.exs` lines 45-60):
```elixir
assert {:ok, :completed} = Tracker.record_progress(TestRepo, job, :success)

batch = TestRepo.get!(Batch, batch.id)
assert batch.status == "completed"
assert batch.success_count == 1
assert %DateTime{} = batch.completed_at

callback = TestRepo.get_by!(Callback, batch_id: batch.id)
assert callback.event == "batch.completed"
assert callback.status == "pending"
```

### Chain DSL Tests

**Analog:** `test/oban_powertools/workflow_test.exs`

**Builder normalization test pattern** (lines 11-20, 27-35):
```elixir
workflow = WorkflowFixtures.workflow_fixture()

assert {:ok, %WorkflowRecord{} = persisted} = Workflow.insert(workflow, TestRepo)
assert persisted.name == "sync_customer"
assert persisted.state == "available"
assert persisted.step_count == 4

assert Enum.map(steps, & &1.step_name) == ["fetch_customer", "sync_billing", "sync_support", "notify"]
assert Enum.map(steps, & &1.position) == [0, 1, 2, 3]
assert Enum.map(steps, & &1.state) == ["available", "pending", "pending", "pending"]
```

**Validation rejection pattern** (`test/oban_powertools/workflow_test.exs` lines 87-95):
```elixir
workflow =
  Workflow.new(name: "duplicate_names")
  |> Workflow.add(:fetch, FetchCustomerWorker.new(%{"account_id" => 1}))
  |> Workflow.add(:fetch, FetchCustomerWorker.new(%{"account_id" => 2}))

assert {:error, {:validation, {:duplicate_step_name, "fetch"}}} =
         Workflow.insert(workflow, TestRepo)
```

### Chain Progression Tests

**Analog:** `test/oban_powertools/workflow_callbacks_test.exs`

**Outbox retry test pattern** (lines 38-70):
```elixir
outbox = TestRepo.get_by!(Callback, workflow_id: workflow.id, event: "workflow.terminal")
assert outbox.status == "pending"
assert outbox.payload["callback_id"] == outbox.id

assert %{failed: 1, delivered: 0} = Workflow.dispatch_callbacks(TestRepo, dispatcher_id: "node-a")
failed = TestRepo.get!(Callback, outbox.id)
assert failed.status == "failed"
assert failed.attempts == 1

assert %{failed: 0, delivered: 1} =
         Workflow.dispatch_callbacks(TestRepo, dispatcher_id: "node-b", now: DateTime.add(DateTime.utc_now(), 31, :second))
```

**Lease protection pattern** (lines 89-104):
```elixir
outbox
|> Callback.changeset(%{
  status: "claimed",
  claimed_at: DateTime.utc_now(),
  claimed_by: "node-a",
  lease_expires_at: future
})
|> TestRepo.update!()

assert %{failed: 0, delivered: 0} =
         Workflow.dispatch_callbacks(TestRepo, dispatcher_id: "node-b", handler: WorkflowNoopCallbackTestHandler)
```

### Chain Output Tests

**Analog:** `test/oban_powertools/job_record_test.exs`, `test/oban_powertools/worker_test.exs`

**Fetch latest output pattern** (`test/oban_powertools/job_record_test.exs` lines 138-162):
```elixir
assert {:error, :not_found} = JobRecord.fetch_result(TestRepo, job.id)

assert :ok = JobRecord.record(TestRepo, "MyApp.Worker", %{job | attempt: 1}, %{"attempt" => 1}, [])
assert :ok = JobRecord.record(TestRepo, "MyApp.Worker", %{job | attempt: 2}, %{"attempt" => 2}, [])

assert {:ok, %{"attempt" => 2}} = JobRecord.fetch_result(TestRepo, job)
```

**Worker recording-before-hook pattern** (`test/oban_powertools/worker_test.exs` lines 123-137, 391-397):
```elixir
defmodule RecordingConfiguredWorker do
  use ObanPowertools.Worker,
    queue: :default,
    args: [user_id: :integer],
    record_output: true

  @impl true
  def process(_job), do: {:ok, %{"recorded" => true}}
end

assert {:ok, %{"recorded" => true}} = RecordingConfiguredWorker.perform(job)
assert {:ok, %{"recorded" => true}} = JobRecord.fetch_result(TestRepo, job.id)
```

## Shared Patterns

### DataCase / SQL Sandbox
**Source:** `test/support/data_case.ex` lines 1-21  
**Apply to:** all Phase 61 database tests
```elixir
defmodule ObanPowertools.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias ObanPowertools.TestRepo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import ObanPowertools.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ObanPowertools.TestRepo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(ObanPowertools.TestRepo, {:shared, self()})
    end
    :ok
  end
end
```

### Durable Outbox Statuses
**Source:** `lib/oban_powertools/workflow/runtime.ex` lines 735-777; `lib/oban_powertools/callback.ex` lines 11-22  
**Apply to:** chain callback rows and event-scoped callback claiming

Use `pending -> claimed -> delivered` on success, and `pending/failed/claimed -> claimed -> failed` with `available_at` retry delay on failure. Keep `last_error` as `inspect(reason)`.

### Thin Callback Payloads
**Source:** `lib/oban_powertools/workflow/runtime.ex` lines 1453-1476; `lib/oban_powertools/batch/tracker.ex` lines 177-187  
**Apply to:** batch callbacks and chain progression callbacks

Payloads should carry ids, event name, envelope/version fields, and references such as upstream job id. Do not copy full business payloads into callback rows.

### Worker Hooks Are Observe-Only
**Source:** `lib/oban_powertools/worker/hooks.ex` lines 127-157  
**Apply to:** Chain progression design

Hook crashes are caught and logged; they must not become orchestration control flow. Keep chain progression in Powertools-owned callback processing.

### Recorded Output Boundary
**Source:** `lib/oban_powertools/job_record.ex` lines 70-123; `lib/oban_powertools/worker.ex` lines 216-229  
**Apply to:** `Chain.fetch_upstream_result/1` and output-dependent arg builders

Only `{:ok, payload}` worker results are recorded when `record_output: true`; downstream chain APIs should fetch by upstream job id and return explicit errors for unavailable output.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/oban_powertools/chain.ex` | API/DSL | request-response + transform | No existing linear chain API; use `Workflow` builder/normalization pattern without DAG features. |
| `lib/oban_powertools/chain/progression.ex` | service | event-driven + CRUD | No existing chain dispatcher; use `Workflow.Runtime` callback claim/retry pattern with event scoping. |
| `ObanPowertools.Batch.insert_stream/2` internals | API/service | streaming | No existing `Oban.insert_all/2` usage; use project `repo.insert_all` style plus Oban bulk insert guidance from RESEARCH.md. |

## Metadata

**Analog search scope:** `lib/`, `test/`, `test/support/`  
**Files scanned:** 78 source/test files from `rg --files lib test` plus phase context/research artifacts  
**Pattern extraction date:** 2026-06-14
