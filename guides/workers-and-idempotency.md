# Workers And Idempotency

`ObanPowertools.Worker` is the default builder-facing entry point when you want app code to
enqueue typed jobs without pushing validation and duplicate suppression into every caller.

## What the wrapper adds

- typed `args:` declarations backed by an embedded schema
- `validate/1` for synchronous argument validation
- `enqueue/2` for idempotent inserts through the Powertools receipt table
- optional `limits:` declarations when the worker also needs durable rate control

The runtime still executes an `Oban.Worker`. Powertools just makes the builder contract stricter.

## Minimal worker

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

## What callers do

```elixir
case MyApp.Billing.ProcessInvoiceWorker.enqueue(%{
       account_id: 42,
       invoice_id: 9001,
       reason: "manual_retry"
     }) do
  {:ok, job} ->
    {:ok, job.id}

  {:conflict, job} ->
    {:ok, job.id}

  {:error, %Ecto.Changeset{} = changeset} ->
    {:error, changeset}
end
```

Important behavior:

- invalid args fail before the job is inserted
- the worker receives a casted `%__MODULE__.Args{}` struct
- duplicate enqueue attempts return `{:conflict, job}` for the original durable insert

That gives callers one stable API instead of ad hoc validation and “did we already queue this?”
checks spread across controllers, LiveViews, and services.

## Validation without enqueue

Use `validate/1` when you want to fail fast before presenting or persisting a user-facing action:

```elixir
MyApp.Billing.ProcessInvoiceWorker.validate(%{
  account_id: 42,
  invoice_id: 9001,
  reason: "manual_retry"
})
```

## When to stay on the wrapper

Use `ObanPowertools.Worker` when your job benefits from:

- a stable typed argument shape
- duplicate suppression at enqueue time
- a durable limiter binding

Use plain `Oban.Worker` only when you explicitly do not want those guarantees.
