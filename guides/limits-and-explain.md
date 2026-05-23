# Limits And Explain

Powertools limits are durable Postgres-backed reservations. They are for “this mutation should
not even queue unless capacity exists” cases, not just best-effort runtime throttling.

## Declare the limiter on the worker

```elixir
defmodule MyApp.Sync.SyncCustomerWorker do
  use ObanPowertools.Worker,
    queue: :sync,
    args: [account_id: :integer, cost: :integer],
    limits: [
      name: "customer-sync-api",
      scope: :partitioned,
      partition_by: {:args, :account_id},
      weight_by: {:args, :cost},
      bucket_capacity: 10,
      bucket_span_ms: 60_000
    ]

  @impl true
  def process(_job), do: :ok
end
```

Supported shapes today:

- `scope: :global` for one shared bucket
- `scope: :partitioned` for a bucket per resolved partition key
- `partition_by` from `{:args, :field}` or a worker/module resolver
- `weight_by` from `{:args, :field}` or a worker/module resolver

## What enqueue does when capacity is gone

```elixir
assert {:ok, _job} = MyApp.Sync.SyncCustomerWorker.enqueue(%{account_id: 42, cost: 7})
assert {:ok, _job} = MyApp.Sync.SyncCustomerWorker.enqueue(%{account_id: 42, cost: 3})

assert {:blocked, [%{code: "limit_reached"}]} =
         MyApp.Sync.SyncCustomerWorker.enqueue(%{account_id: 42, cost: 1})
```

A blocked enqueue is not silent:

- the limiter state stays queryable in Postgres
- blocker snapshots are persisted
- normalized audit evidence is written for blocked outcomes

## Explain why something is blocked

```elixir
explanation =
  ObanPowertools.Explain.explain(
    MyApp.Sync.SyncCustomerWorker,
    %{account_id: 42, cost: 1},
    repo: MyApp.Repo
  )

assert explanation.status == :blocked
assert [%{code: "limit_reached"}] = explanation.blockers
```

`Explain.explain/3` gives you:

- `live_now` blockers from current limiter state
- `snapshot_at_block_start` from the persisted blocker snapshot
- one stable shape for rendering diagnostic surfaces

## Administrative limiter actions

Use the lower-level `ObanPowertools.Limits` API when operator flows need explicit capacity
control:

```elixir
{:ok, reservation} =
  ObanPowertools.Limits.reserve(
    MyApp.Repo,
    MyApp.Sync.SyncCustomerWorker,
    %{account_id: 42, cost: 2}
  )

:ok = ObanPowertools.Limits.release(MyApp.Repo, reservation) |> then(fn {:ok, _} -> :ok end)
```

You can also put a resource into cooldown:

```elixir
ObanPowertools.Limits.cooldown(
  MyApp.Repo,
  "customer-sync-api",
  "42",
  DateTime.add(DateTime.utc_now(), 30, :second),
  "429 backoff"
)
```

## When this is the right tool

Use limits when the business rule is “do not queue work beyond this budget.” If the real need is
only “run slower once jobs are already in flight,” plain Oban queue controls may be enough.
