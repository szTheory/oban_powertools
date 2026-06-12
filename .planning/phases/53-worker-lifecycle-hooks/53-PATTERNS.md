# Phase 53: Worker Lifecycle Hooks - Pattern Map

**Mapped:** 2026-06-12
**Files analyzed:** 8 new/modified files
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/worker.ex` | provider | request-response | `lib/oban_powertools/worker.ex` | exact |
| `lib/oban_powertools/worker/hooks.ex` | service | request-response | `lib/oban_powertools/host_escalation.ex` | role-match |
| `lib/oban_powertools/telemetry.ex` | utility | event-driven | `lib/oban_powertools/telemetry.ex` | exact |
| `test/oban_powertools/worker_test.exs` | test | request-response | `test/oban_powertools/worker_test.exs` | exact |
| `test/oban_powertools/telemetry_test.exs` | test | event-driven | `test/oban_powertools/telemetry_test.exs` | exact |
| `guides/workers-and-idempotency.md` | docs | request-response | `guides/workers-and-idempotency.md` | exact |
| `guides/telemetry-and-slos.md` | docs | event-driven | `guides/telemetry-and-slos.md` | exact |
| `test/oban_powertools/docs_contract_test.exs` | test | file-I/O | `test/oban_powertools/docs_contract_test.exs` | role-match |

## Pattern Assignments

### `lib/oban_powertools/worker.ex` (provider, request-response)

**Analog:** `lib/oban_powertools/worker.ex`

**Macro import and option filtering pattern** (lines 6-24):
```elixir
defmacro __using__(opts) do
  args_config = Keyword.get(opts, :args, [])
  limits_config = Keyword.get(opts, :limits, [])
  oban_opts = opts |> Keyword.delete(:args) |> Keyword.delete(:limits)
  validate_args_config!(args_config)
  normalized_limits = normalize_limits_config!(limits_config, __CALLER__.module)

  fields =
    for {name, type} <- args_config do
      quote do
        field(unquote(name), unquote(type))
      end
    end

  quote do
    use Oban.Worker, unquote(oban_opts)
    @behaviour __MODULE__
    import Ecto.Changeset
    @powertools_limits unquote(Macro.escape(normalized_limits))
```

**Callback contract pattern** (lines 26-32):
```elixir
@callback process(Oban.Job.t()) ::
            :ok
            | {:ok, term()}
            | {:error, term()}
            | {:cancel, term()}
            | {:snooze, integer()}
            | term()
```

Add `on_start/1`, `on_success/2`, `on_failure/2`, and `on_discard/2` callbacks beside this existing `process/1` callback. Generate no-op defaults inside the quoted block and mark them overridable.

**Args validation and wrapper seam pattern** (lines 56-78):
```elixir
def validate(params) do
  %Args{}
  |> Args.changeset(params)
  |> case do
    %{valid?: true} = changeset -> {:ok, apply_changes(changeset)}
    changeset -> {:error, changeset}
  end
end

@impl Oban.Worker
def perform(%Oban.Job{args: args} = job) when is_map(args) do
  case validate(args) do
    {:ok, casted_args} ->
      process(%{job | args: casted_args})

    {:error, changeset} ->
      {:error, changeset}
  end
end

def perform(%Oban.Job{args: %Args{}} = job) do
  process(job)
end
```

Planner should preserve validation-before-execution. Insert `on_start/1` after `{:ok, casted_args}` and before `process/1`; route post hooks after process classification; return the original Oban-compatible result. For `%Args{}` jobs, preserve the direct typed path but add the same hook routing.

**Enqueue path to leave undisturbed** (lines 80-85):
```elixir
@doc """
Enqueues a job with the given arguments, validating them synchronously.
"""
def enqueue(args, opts \\ []) do
  ObanPowertools.Idempotency.transaction(__MODULE__, args, opts)
end
```

Do not move hook behavior into enqueue/idempotency. Phase 53 hooks are execution-time only.

---

### `lib/oban_powertools/worker/hooks.ex` (service, request-response)

**Analog:** `lib/oban_powertools/host_escalation.ex`

**Imports and constants pattern** (lines 1-10):
```elixir
defmodule ObanPowertools.HostEscalation do
  @moduledoc """
  Dispatches optional host-owned follow-up callbacks after native remediation.
  """

  alias ObanPowertools.RuntimeConfig

  @unconfigured_status "host_owned_follow_up_unconfigured"
  @invoked_status "host_owned_follow_up_callback_invoked"
  @failed_status "host_owned_follow_up_callback_failed"
```

For hooks, use `defmodule ObanPowertools.Worker.Hooks`, a short internal moduledoc, and aliases for `Logger`/`ObanPowertools.Telemetry` if needed. Keep status/outcome strings as constants: `"ok"` and `"crash_caught"`.

**Crash-caught dispatch pattern** (lines 23-38):
```elixir
handler ->
  try do
    normalize_handler_result(handler.handle_escalation(event_facts))
  rescue
    error ->
      %{
        status: @failed_status,
        details: %{"reason" => Exception.message(error)}
      }
  catch
    kind, value ->
      %{
        status: @failed_status,
        details: %{"reason" => "#{kind}: #{inspect(value)}"}
      }
  end
```

Copy the `try/rescue/catch` shape, but hook dispatch must ignore the hook return value, warning-log crashes, emit worker hook telemetry after success or caught crash, and never change the job result. Add explicit handling for `throw` and `exit` through `catch`.

**Result normalization pattern** (lines 45-59):
```elixir
def normalize_handler_result(:ok) do
  %{status: @invoked_status, details: %{"result" => "ok"}}
end

def normalize_handler_result({:ok, details}) when is_map(details) do
  %{status: @invoked_status, details: details}
end

def normalize_handler_result({:error, reason}) do
  %{status: @failed_status, details: %{"reason" => inspect(reason)}}
end

def normalize_handler_result(other) do
  %{status: @failed_status, details: %{"reason" => "unexpected_return: #{inspect(other)}"}}
end
```

Use the same small private-normalizer style for hook envelope construction: success, retry failure, terminal discard, explicit discard. Do not persist hook details or expose rich envelopes as telemetry metadata.

**Oban final-attempt classification analog** (`deps/oban/lib/oban/queue/executor.ex` lines 184-188):
```elixir
@spec normalize_state(t()) :: t()
def normalize_state(%__MODULE__{state: :failure, job: job} = exec)
    when job.attempt >= job.max_attempts do
  %{exec | state: :exhausted}
end
```

Use `job.attempt >= job.max_attempts` to route final `{:error, reason}` and caught process failures to `on_discard/2` only. Do not dual-fire `on_failure/2`.

**Oban return semantics analog** (`deps/oban/lib/oban/queue/executor.ex` lines 143-180):
```elixir
case worker.perform(job) do
  :ok ->
    %{exec | state: :success, result: :ok}

  {:ok, _value} = result ->
    %{exec | state: :success, result: result}

  {:cancel, _reason} = result ->
    %{exec | result: result, state: :cancelled, error: perform_error(worker, result)}

  :discard = result ->
    %{exec | result: result, state: :discard, error: perform_error(worker, result)}

  {:discard, _reason} = result ->
    %{exec | result: result, state: :discard, error: perform_error(worker, result)}

  {:error, _reason} = result ->
    %{exec | result: result, state: :failure, error: perform_error(worker, result)}
```

Mirror these return categories for hook routing: success for `:ok`/`{:ok, _}`, discard for `:discard`/`{:discard, _}`, failure or discard for `{:error, _}` depending on attempt counters, no Phase 53 post hook for `{:cancel, _}` or `{:snooze, _}`.

---

### `lib/oban_powertools/telemetry.ex` (utility, event-driven)

**Analog:** `lib/oban_powertools/telemetry.ex`

**Contract pattern** (lines 32-45):
```elixir
@contract %{
  measurement_keys: [:count],
  families: %{
    operator_action: [:action, :source],
    limiter: [:action, :blocker_code, :resource, :scope],
    cron: [:action, :source, :overlap_policy, :catch_up_policy],
    workflow: %{
      step_completed: [:outcome, :terminal_cause, :semantics_version],
      step_unblocked: [:scope, :state, :semantics_version],
      cascade_cancelled: [:scope, :outcome, :terminal_cause, :semantics_version],
      workflow_terminal: [:state, :outcome, :terminal_cause, :semantics_version]
    },
    lifeline: [:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]
  }
}
```

Add `worker_hook: [:hook, :outcome]`. Keep measurement keys unchanged. Do not add worker, queue, job id, args, reason, or stacktrace metadata.

**Metric counter pattern** (lines 88-99 and 166-177):
```elixir
counter = fn name, opts -> apply(Telemetry.Metrics, :counter, [name, opts]) end

[
  # operator_action — :action varies across events so it is useful as a tag
  counter.("oban_powertools.operator_action.previewed.count",
    tags: [:action, :source],
    description: "Operator previewed a cron action"
  ),
```

```elixir
counter.("oban_powertools.lifeline.repair_executed.count",
  tags: [:action, :incident_class, :target_type],
  description: "Lifeline repair executed"
),
```

Add one counter named `oban_powertools.worker_hook.invoked.count` with tags `[:hook, :outcome]` and a terse description.

**Telemetry helper pattern** (lines 216-222):
```elixir
def execute_lifeline_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute(
    [:oban_powertools, :lifeline, event_suffix],
    measurements,
    metadata
  )
end
```

Add `execute_worker_hook_event/3` with prefix `[:oban_powertools, :worker_hook, event_suffix]`.

---

### `test/oban_powertools/worker_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/worker_test.exs`

**Inline test worker pattern** (lines 1-17):
```elixir
defmodule ObanPowertools.WorkerTest do
  use ExUnit.Case, async: true

  defmodule BasicWorker do
    use ObanPowertools.Worker,
      queue: :default,
      args: [
        user_id: :integer,
        email: :string
      ]

    @impl true
    def process(%Oban.Job{args: %__MODULE__.Args{user_id: user_id}}) do
      send(self(), {:processed, user_id})
      :ok
    end
  end
```

Define additional small inline workers for each route. Use `send(self(), ...)` to prove hook ordering, envelopes, and result preservation.

**Validation test style** (lines 24-31):
```elixir
test "validate/1 returns ok with valid args" do
  assert {:ok, %BasicWorker.Args{user_id: 123, email: "foo@bar.com"}} =
           BasicWorker.validate(%{user_id: 123, email: "foo@bar.com"})
end

test "validate/1 returns error with invalid args" do
  assert {:error, %Ecto.Changeset{}} = BasicWorker.validate(%{user_id: "not-an-int"})
end
```

Use direct `perform/1` calls with `%Oban.Job{args: ..., attempt: ..., max_attempts: ...}` to cover routing without requiring a queue.

**Compile-time macro test pattern** (lines 33-43):
```elixir
test "invalid args definitions fail at compile time" do
  assert_raise ArgumentError, ~r/expected :args/, fn ->
    Code.compile_string("""
    defmodule InvalidWorker do
      use ObanPowertools.Worker, args: ["user_id"]

      @impl true
      def process(_job), do: :ok
    end
    """)
  end
end
```

Add a compile or runtime assertion that workers omitting hooks still compile and run via no-op defaults. If implementing override detection, add a test proving omitted hooks do not emit `worker_hook` telemetry.

**Typed args process assertion** (lines 46-52):
```elixir
args = %BasicWorker.Args{user_id: 123, email: "foo@bar.com"}
job = %Oban.Job{args: args}

assert :ok = BasicWorker.process(job)
assert_receive {:processed, 123}
```

For hook tests, assert `on_start/1` receives the same typed `%Oban.Job{}` shape as `process/1`.

---

### `test/oban_powertools/telemetry_test.exs` (test, event-driven)

**Analog:** `test/oban_powertools/telemetry_test.exs`

**Expected contract pattern** (lines 4-18):
```elixir
@expected_contract %{
  measurement_keys: [:count],
  families: %{
    operator_action: [:action, :source],
    limiter: [:action, :blocker_code, :resource, :scope],
    cron: [:action, :source, :overlap_policy, :catch_up_policy],
    workflow: %{
      step_completed: [:outcome, :terminal_cause, :semantics_version],
      step_unblocked: [:scope, :state, :semantics_version],
      cascade_cancelled: [:scope, :outcome, :terminal_cause, :semantics_version],
      workflow_terminal: [:state, :outcome, :terminal_cause, :semantics_version]
    },
    lifeline: [:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]
  }
}
```

Add `worker_hook: [:hook, :outcome]` to the expected contract.

**Metric tag containment pattern** (lines 33-52):
```elixir
test "metrics/0 tags stay within frozen contract" do
  contract = ObanPowertools.Telemetry.contract()
  metrics = ObanPowertools.Telemetry.metrics()

  for metric <- metrics do
    [_oban_powertools, family, suffix | _] = metric.event_name

    allowed_tags =
      case get_in(contract, [:families, family]) do
        %{} = per_suffix_map -> Map.get(per_suffix_map, suffix, [])
        tag_list when is_list(tag_list) -> tag_list
      end

    for tag <- metric.tags do
      assert tag in allowed_tags,
             "Tag #{inspect(tag)} for #{inspect(metric.event_name)} not in contract " <>
               "(allowed: #{inspect(allowed_tags)})"
    end
  end
end
```

This test should pass automatically once the `worker_hook` counter tags match the contract.

**Attach/emit/detach event pattern** (lines 178-200):
```elixir
test "emits lifeline repair_executed event with bounded metadata" do
  :telemetry.attach(
    "lifeline-handler",
    [:oban_powertools, :lifeline, :repair_executed],
    fn name, measurements, metadata, _config ->
      send(self(), {:lifeline_event, name, measurements, metadata})
    end,
    nil
  )

  ObanPowertools.Telemetry.execute_lifeline_event(:repair_executed, %{count: 1}, %{
    action: "execute_repair",
    incident_class: "workflow_stuck",
    target_type: "workflow"
  })

  assert_receive {:lifeline_event, [:oban_powertools, :lifeline, :repair_executed],
                  %{count: 1}, received_metadata}

  assert Enum.all?(Map.keys(received_metadata), fn k -> k in @expected_contract.families.lifeline end)
after
  :telemetry.detach("lifeline-handler")
end
```

Add a worker hook event test using `[:oban_powertools, :worker_hook, :invoked]`, `%{count: 1}`, and exact metadata keys `[:hook, :outcome]`.

---

### `guides/workers-and-idempotency.md` (docs, request-response)

**Analog:** `guides/workers-and-idempotency.md`

**Worker guide shape** (lines 1-13):
```markdown
# Workers And Idempotency

`ObanPowertools.Worker` is the default builder-facing entry point when you want app code to
enqueue typed jobs without pushing validation and duplicate suppression into every caller.

## What the wrapper adds

- typed `args:` declarations backed by an embedded schema
- `validate/1` for synchronous argument validation
- `enqueue/2` for idempotent inserts through the Powertools receipt table
- optional `limits:` declarations when the worker also needs durable rate control

The runtime still executes an `Oban.Worker`. Powertools just makes the builder contract stricter.
```

Add lifecycle hooks as another wrapper feature. Keep the support-truth tone: runtime is still Oban, hooks are observe-only, crash-caught, synchronous in the job process, and not retried independently.

**Minimal worker example pattern** (lines 17-32):
```elixir
defmodule MyApp.Billing.ProcessInvoiceWorker do
  use ObanPowertools.Worker,
    queue: :billing,
    args: [
      account_id: :integer,
      invoice_id: :integer,
      reason: :string
    ]

  @impl true
  def process(%Oban.Job{args: %__MODULE__.Args{} = args}) do
    MyApp.Billing.process_invoice(args.account_id, args.invoice_id, args.reason)
    :ok
  end
end
```

Extend with a compact hook example only if needed. Do not imply hooks can short-circuit execution or replace durable audit.

---

### `guides/telemetry-and-slos.md` (docs, event-driven)

**Analog:** `guides/telemetry-and-slos.md`

**Telemetry posture pattern** (lines 95-103):
```markdown
## Powertools control-plane SLIs

`ObanPowertools.Telemetry.metrics/0` contributes the **control-plane SLIs** that Oban-core
cannot see: what your limiters, lifeline repair pipeline, workflows, and cron scheduler are
doing. These are the events Oban itself is unaware of.

All tags are low-cardinality string values (e.g. `scope: "partitioned"`, `outcome: "ok"`). The
frozen contract explicitly excludes `job_id`, `args`, preview tokens, and free-form reasons.
```

Add worker hooks to the control-plane SLI list. Preserve the low-cardinality warning and explicitly exclude job ids, args, reasons, and stacktraces for `worker_hook`.

**Metric table pattern** (lines 141-155):
```markdown
### Cron schedule events

| Metric | Tags | What it tracks |
|--------|------|---------------|
| `oban_powertools.cron.slot_claimed.count` | `source`, `overlap_policy`, `catch_up_policy` | Cron slots claimed at schedule time |
| `oban_powertools.cron.paused.count` | `source`, `overlap_policy` | Cron entries paused by operator |
| `oban_powertools.cron.resumed.count` | `source`, `overlap_policy` | Cron entries resumed by operator |
| `oban_powertools.cron.run_now.count` | `source`, `overlap_policy` | Cron entries triggered run-now by operator |
```

Add a `### Worker lifecycle hooks` section with `oban_powertools.worker_hook.invoked.count`, tags `hook`, `outcome`, and a description such as "Worker hook dispatch attempts after the hook returned or was crash-caught."

---

### `test/oban_powertools/docs_contract_test.exs` (test, file-I/O)

**Analog:** `test/oban_powertools/docs_contract_test.exs`

**Docs file list pattern** (lines 4-20):
```elixir
@docs_files [
  "README.md",
  "guides/installation.md",
  "guides/first-operator-session.md",
  "guides/forensics-and-runbook-handoffs.md",
  "guides/example-app-walkthrough.md",
  "guides/workers-and-idempotency.md",
  "guides/limits-and-explain.md",
  "guides/workflows.md",
  "guides/lifeline-and-repairs.md",
  "guides/policy-integration-patterns.md",
  "guides/upgrade-and-compatibility.md",
  "guides/optional-oban-web-bridge.md",
  "guides/support-truth-and-ownership-boundaries.md",
  "guides/production-hardening.md",
  "guides/troubleshooting.md"
]
```

If adding contract assertions for worker hook docs, either update `@docs_files` to include `guides/telemetry-and-slos.md` or read that guide directly in the new test.

**Support-truth assertion pattern** (lines 59-79):
```elixir
test "support truth stays locked in docs" do
  source = joined_docs()

  assert source =~ "supported"
  assert source =~ "tested"
  assert source =~ "best-effort"
  assert source =~ "host-owned"
  assert source =~ "intentionally unsupported"
  assert source =~ "best-effort outside tested lanes"
```

Add assertions for the four hook support truths from D-30 if docs are updated: hooks run in the job process, outside any Powertools transaction, hook failure does not fail the job or crash the queue, and hook execution is not retried independently.

## Shared Patterns

### Crash-Caught Host Callback Handling

**Source:** `lib/oban_powertools/host_escalation.ex` lines 23-38
**Apply to:** `lib/oban_powertools/worker/hooks.ex`, hook crash tests

```elixir
try do
  normalize_handler_result(handler.handle_escalation(event_facts))
rescue
  error ->
    %{
      status: @failed_status,
      details: %{"reason" => Exception.message(error)}
    }
catch
  kind, value ->
    %{
      status: @failed_status,
      details: %{"reason" => "#{kind}: #{inspect(value)}"}
    }
end
```

Adapt by logging and returning an internal outcome string, not by returning callback details to the caller.

### Low-Cardinality Telemetry Contract

**Source:** `lib/oban_powertools/telemetry.ex` lines 28-45
**Apply to:** `lib/oban_powertools/telemetry.ex`, `lib/oban_powertools/worker/hooks.ex`, telemetry tests, telemetry guide

```elixir
IDs, job args, preview tokens, and free-form reasons are intentionally excluded from this
public API.

@contract %{
  measurement_keys: [:count],
  families: %{
    operator_action: [:action, :source],
    limiter: [:action, :blocker_code, :resource, :scope],
    cron: [:action, :source, :overlap_policy, :catch_up_policy],
```

For `worker_hook`, metadata must be exactly bounded to hook name and outcome strings.

### Telemetry Event Helper

**Source:** `lib/oban_powertools/telemetry.ex` lines 216-222
**Apply to:** hook dispatcher telemetry emission

```elixir
def execute_lifeline_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute(
    [:oban_powertools, :lifeline, event_suffix],
    measurements,
    metadata
  )
end
```

Implement `execute_worker_hook_event/3` with the same function shape and no extra validation layer.

### Direct ExUnit Telemetry Capture

**Source:** `test/oban_powertools/telemetry_test.exs` lines 54-70
**Apply to:** worker hook telemetry event tests

```elixir
:telemetry.attach(
  "test-handler",
  [:oban_powertools, :operator_action, :complete],
  fn name, measurements, metadata, _config ->
    send(self(), {:telemetry_event, name, measurements, metadata})
  end,
  nil
)

ObanPowertools.Telemetry.execute_operator_action(:complete, %{count: 1}, %{action: "test"})

assert_receive {:telemetry_event, [:oban_powertools, :operator_action, :complete],
                %{count: 1}, %{action: "test"}}
```

Use unique handler IDs per test and detach in `after`.

### Enqueue and Idempotency Boundary

**Source:** `lib/oban_powertools/idempotency.ex` lines 42-51 and `lib/oban_powertools/worker.ex` lines 80-85
**Apply to:** worker wrapper changes

```elixir
def transaction(worker_mod, args, opts \\ []) do
  case worker_mod.validate(args) do
    {:ok, casted_args} ->
      repo = opts[:repo] || infer_repo()
      fingerprint = generate_fingerprint(worker_mod, casted_args)
      do_enqueue(repo, worker_mod, casted_args, fingerprint, opts)

    {:error, changeset} ->
      {:error, changeset}
  end
end
```

Do not add hook dispatch to enqueue transactions; lifecycle hooks belong to `perform/1` only and run outside Powertools transactions.

## No Analog Found

No target file is without an analog. `lib/oban_powertools/worker/hooks.ex` is new, but its crash-caught callback dispatch pattern is covered by `lib/oban_powertools/host_escalation.ex`, while its routing categories are covered by the Oban executor source and existing worker wrapper.

## Metadata

**Analog search scope:** `lib/`, `test/`, `guides/`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `deps/oban/lib/oban/queue/executor.ex`
**Files scanned:** 120+ via `rg --files` and targeted `rg`
**Pattern extraction date:** 2026-06-12
