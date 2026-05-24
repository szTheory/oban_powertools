# Phase 20: Cancellation, Late Completion & Expiry Semantics - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/workflow/runtime.ex` | service | event-driven | `lib/oban_powertools/workflow/runtime.ex` | exact |
| `lib/oban_powertools/workflow.ex` | service | request-response | `lib/oban_powertools/workflow.ex` | exact |
| `lib/oban_powertools/workflow/workflow.ex` | model | transform | `lib/oban_powertools/workflow/workflow.ex` | exact |
| `lib/oban_powertools/workflow/step.ex` | model | transform | `lib/oban_powertools/workflow/step.ex` | exact |
| `lib/oban_powertools/workflow/signal_record.ex` | model | append-only | `lib/oban_powertools/workflow/signal_record.ex` | exact |
| `lib/oban_powertools/workflow/command_attempt.ex` | model | append-only | `lib/oban_powertools/workflow/command_attempt.ex` | exact |
| `lib/oban_powertools/explain.ex` | utility | request-response | `lib/oban_powertools/explain.ex` | exact |
| `lib/mix/tasks/oban_powertools.install.ex` | config | migration | `lib/mix/tasks/oban_powertools.install.ex` | exact |
| `test/support/migrations/2_phase_3_tables.exs` | migration | CRUD | `test/support/migrations/2_phase_3_tables.exs` | exact |
| `test/support/example_host_contract.ex` | test-support | upgrade | `test/support/example_host_contract.ex` | exact |
| `test/oban_powertools/workflow_runtime_test.exs` | test | event-driven | `test/oban_powertools/workflow_runtime_test.exs` | exact |
| `test/oban_powertools/workflow_coordinator_test.exs` | test | event-driven | `test/oban_powertools/workflow_coordinator_test.exs` | exact |
| `test/oban_powertools/example_host_contract_test.exs` | test | upgrade | `test/oban_powertools/example_host_contract_test.exs` | exact |

## Pattern Assignments

### `lib/oban_powertools/workflow/runtime.ex` (service, event-driven)

**Analog:** `lib/oban_powertools/workflow/runtime.ex`

**Command entrypoints stay narrow, then dispatch into one DB-first runtime core** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:224), [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:504))
```elixir
defp dispatch_command(repo, %{action: "request_cancel"} = command),
  do: run_request_cancel(repo, command)

def request_cancel(repo, workflow_id, attrs \\ %{}) do
  execute_command(repo, %{
    action: "request_cancel",
    scope: "workflow",
    workflow_id: workflow_id,
    attrs: attrs,
    source: command_source(attrs, "operator")
  })
end
```

**Cancellation uses `Ecto.Multi`, appends command evidence, then reconciles and refreshes** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:514))
```elixir
Multi.new()
|> Multi.insert(:command_attempt, CommandAttempt.changeset(%CommandAttempt{}, ...))
|> Multi.update(:workflow, Workflow.changeset(workflow, %{...}))
|> Multi.run(:steps, fn repo, _changes -> ... end)
|> Multi.run(:reconcile, fn repo, _changes -> reconcile_workflow(repo, workflow.id, now) end)
|> Multi.run(:workflow_refresh, fn repo, _changes -> {:ok, refresh_workflow(repo, workflow.id, now)} end)
|> Multi.run(:callback, fn repo, %{workflow: old_workflow, workflow_refresh: new_workflow} ->
  maybe_enqueue_terminal_callback(repo, old_workflow, new_workflow, now)
end)
```

**Current diagnosis ordering is runtime-owned and therefore the correct seam to fix** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:777))
```elixir
def workflow_diagnosis(%Workflow{} = workflow, steps) do
  cond do
    workflow.state == "cancel_requested" or not is_nil(workflow.cancel_requested_at) ->
      "cancel_requested"
    workflow.state == "expired" ->
      "expired_wait"
    workflow.terminal_cause ->
      workflow.terminal_cause
```

**Reconcile already centralizes legal expiry and signal handling** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:826))
```elixir
defp do_reconcile(repo, workflow_id, now, passes) do
  claim_workflow_signals(repo, workflow_id)
  expire_waits(repo, workflow_id, now)
  reconcile_signals_for_workflow(repo, workflow_id, now)
  mark_late_signals_for_workflow(repo, workflow_id)
  ...
end
```

**Workflow truth is recomputed from durable step state** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:1236), [runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:1291))
```elixir
state = workflow_state(steps, workflow.cancel_requested_at)

attrs = %{
  state: state,
  terminal_cause: workflow_terminal_cause(steps, workflow.cancel_requested_at),
  ...
}
```

**Terminal callback payloads are built in one place and should stay narrow** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:1376))
```elixir
enqueue_callback(
  repo,
  new_workflow,
  "workflow.terminal",
  "#{new_workflow.state}:#{new_workflow.terminal_cause}",
  %{
    "state" => new_workflow.state,
    "terminal_cause" => new_workflow.terminal_cause,
    "cancel_requested_at" => datetime_or_nil(new_workflow.cancel_requested_at),
    "finished_at" => datetime_or_nil(new_workflow.finished_at)
  },
  now
)
```

**Pattern takeaway for Phase 20:** keep all precedence reduction inside `Runtime`; append evidence through existing ledgers; fix diagnosis and callback truth at the runtime-owned interpretation seam rather than in UI code.

### `lib/oban_powertools/workflow/workflow.ex` and `lib/oban_powertools/workflow/step.ex` (models, transform)

**Analogs:** `lib/oban_powertools/workflow/workflow.ex`, `lib/oban_powertools/workflow/step.ex`

**Workflow rows already hold request and terminal truth fields** ([workflow.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/workflow.ex:11))
```elixir
field(:terminal_cause, :string)
field(:cancel_requested_at, :utc_datetime_usec)
field(:last_transition_at, :utc_datetime_usec)
field(:started_at, :utc_datetime_usec)
field(:finished_at, :utc_datetime_usec)
field(:cancelled_at, :utc_datetime_usec)
```

**Step rows already mirror request timing and terminal cause** ([step.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/step.ex:18))
```elixir
field(:terminal_cause, :string)
field(:active_await_id, :binary_id)
field(:cancel_requested_at, :utc_datetime_usec)
field(:finished_at, :utc_datetime_usec)
field(:cancelled_at, :utc_datetime_usec)
```

**Pattern takeaway for Phase 20:** prefer additive bounded fields or vocabulary changes on these existing durable rows before adding new top-level runtime stores.

### `lib/oban_powertools/workflow/signal_record.ex` and `lib/oban_powertools/workflow/command_attempt.ex` (append-only evidence)

**Analogs:** `lib/oban_powertools/workflow/signal_record.ex`, `lib/oban_powertools/workflow/command_attempt.ex`

**Signals already have bounded durable statuses** ([signal_record.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/signal_record.ex:9))
```elixir
@statuses ["recorded", "consumed", "late", "unmatched", "ambiguous"]
```

**Command attempts already provide append-only evidence with before/after snapshots** ([command_attempt.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/command_attempt.ex:10))
```elixir
field(:action, :string)
field(:status, :string, default: "completed")
field(:reason_code, :string)
field(:reason_message, :string)
field(:before_snapshot, :map, default: %{})
field(:after_snapshot, :map, default: %{})
field(:metadata, :map, default: %{})
```

**Pattern takeaway for Phase 20:** late or duplicate evidence should reuse `SignalRecord` and `CommandAttempt` patterns instead of inventing an unbounded event-history surface.

### `lib/oban_powertools/explain.ex` (utility, request-response)

**Analog:** `lib/oban_powertools/explain.ex`

**Explain helpers are intentionally thin consumers of runtime semantics** ([explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:121), [explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:134))
```elixir
%{
  diagnosis: Runtime.workflow_diagnosis(workflow, steps),
  semantics: Runtime.semantics_profile(workflow),
  latest_rejection: latest_rejection,
  ...
}
```

**Pattern takeaway for Phase 20:** if diagnosis wording changes, prefer runtime helper changes that automatically flow through `Explain` and later native surfaces.

### Migration and upgrade surfaces

**Analogs:** installer migration, test-support migrations, archived host proof lane

**Phase 19 already used lockstep schema parity plus archived upgrade proof** ([19-VALIDATION.md](/Users/jon/projects/oban_powertools/.planning/phases/19-await-registration-signal-facts-expiry-authority/19-VALIDATION.md:1))

**Pattern takeaway for Phase 20:** any new bounded fields or cause vocabulary that affect durable support truth should land together in runtime schema, installer/test/example migrations, and the archived host proof lane.

### Test surfaces

**Analogs:** `workflow_runtime_test.exs`, `workflow_coordinator_test.exs`, `example_host_contract_test.exs`

**Focused runtime tests already prove late expiry evidence and cancel-versus-complete** ([workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:279), [workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:380))

**Callback outbox tests already verify terminal callback delivery** ([workflow_runtime_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_test.exs:514))

**Pattern takeaway for Phase 20:** extend the focused runtime/coordinator/upgrade suites rather than adding broad new test harnesses.

## Implementation Notes

- Keep plan tasks aligned to the repo’s established split: runtime semantics first, proof second, planning-truth updates last.
- Prefer `Ecto.Multi` plus reconcile/refresh over ad hoc row updates.
- Keep terminology bounded and semver-safe: reuse `completed_after_cancel_request` and `expired_wait`, and add only the minimum new durable cause names required to explain real race outcomes.
- Avoid UI-specific artifacts in this phase unless they are pure consumers of runtime semantics and needed for proof.
