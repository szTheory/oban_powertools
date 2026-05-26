# Workflows

`ObanPowertools.Workflow` is a durable DAG definition and reconciliation layer. It is useful when
your app needs to persist step dependencies, unblock descendants from durable results, and show
why a step is still blocked.

It is not presented as a full orchestration platform. The current public contract is the stored
workflow graph plus the runtime transitions documented here.

## Build a workflow

```elixir
alias ObanPowertools.Workflow

workflow =
  Workflow.new(
    name: "sync_customer",
    workflow_context: %{"account_id" => 42, "label" => "Customer sync"}
  )
  |> Workflow.add(:fetch_customer, MyApp.FetchCustomerWorker.new(%{"account_id" => 42}))
  |> Workflow.add(
    :sync_billing,
    MyApp.SyncBillingWorker.new(%{
      "account_id" => 42,
      "customer" => Workflow.result(:fetch_customer)
    }),
    deps: [:fetch_customer]
  )
  |> Workflow.add(
    :notify,
    MyApp.NotifyWorker.new(%{
      "account_id" => 42,
      "billing" => Workflow.result(:sync_billing)
    }),
    deps: [:sync_billing]
  )
```

Then persist it:

```elixir
{:ok, persisted_workflow} = Workflow.insert(workflow, MyApp.Repo)
```

`Workflow.insert/2` validates:

- duplicate step names
- missing edge targets
- self-loops
- cycle creation
- JSON-safe workflow and step payloads

## Complete a step

The runtime entry point today is `Workflow.complete_step/4`:

```elixir
Workflow.complete_step(
  MyApp.Repo,
  persisted_workflow.id,
  :fetch_customer,
  status: :completed,
  payload: %{customer_id: 1}
)
```

That writes a durable step result, updates workflow counters, and reconciles descendants.

## Current runtime semantics

These are the important builder-facing rules:

- a successful dependency releases children into `available`
- a retryable upstream step keeps descendants `pending`
- terminal failures cascade-cancel descendants by default
- explicit `policy: :continue` edges let cleanup or compensating work continue
- duplicate PubSub delivery does not duplicate child release or stored results
- DB-first reconciliation keeps the workflow correct even if no PubSub follow-up is observed

<!-- workflow-semantics-contract:start -->
## Canonical Workflow Semantics Contract

- Semantics version `2` is the current workflow lifecycle contract.
- Durable workflow, step, await, signal, callback, and recovery rows are the source of truth.
- Duplicate, late, ambiguous, dropped, and replayed signal paths remain durable evidence instead of hidden retries.
- Cancel requests remain durable request evidence, while final workflow outcome is recorded separately.
- Public workflow telemetry stays under `[:oban_powertools, :workflow, *]` with bounded metadata only.
<!-- workflow-semantics-contract:end -->

## Diagnose why a step is still blocked

```elixir
ObanPowertools.Explain.workflow_step(
  persisted_workflow.id,
  :notify,
  repo: MyApp.Repo
)
```

That returns the step state, blocker codes, and dependency snapshot that explain why a step is
still pending.
Rendered operator surfaces should lead with shared control-plane language such as `Needs Review`,
`Blocked`, `Waiting`, or `Runnable`, then preserve raw workflow semantics underneath.

## Good fit

Use workflows when you need:

- a durable dependency graph
- visible blocker causality
- explicit release or cancellation semantics between steps

If you only need “enqueue a few follow-up jobs,” this layer is probably more than you need.
