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

- one shared operator status such as `Blocked`, `Waiting`, or `Runnable`
- `live_now` blockers from current limiter state
- `snapshot_at_block_start` from the persisted blocker snapshot
- one stable shape for rendering diagnosis-first surfaces with venue and evidence

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

## Rate-Limit Glossary

**token_bucket** — The rate-limiting algorithm used by ObanPowertools limiters. Each
partition has a bucket of `bucket_capacity` tokens. Each reservation consumes `weight`
tokens. The bucket refills (resets to zero tokens used) after `bucket_span_ms`
milliseconds have elapsed since `bucket_started_at`.

**bucket_capacity** — The maximum number of tokens available per bucket window. A
reservation that would bring `tokens_used + weight` above this value is blocked with
the `limit_reached` blocker code.

**bucket_span_ms** — The duration of one bucket window in milliseconds. After this
interval elapses since `bucket_started_at`, the bucket resets and tokens are available
again. Used to compute `retry_at` for a `limit_reached` block.

**weight** — The per-reservation token cost. Defaults to the resource's
`default_weight` (usually 1). Each successful reservation consumes `weight` tokens from
the bucket.

**weight_by** — A dynamic weight resolver declared on the worker (e.g.
`weight_by: {:args, :cost}`). At enqueue time the resolved value is bound to the
reservation snapshot as the effective `weight`.

**partition** — A named isolation group within a limiter resource. Each partition
maintains its own independent token bucket. For `scope: :global` limiters there is
one partition (`__global__`); for `scope: :partitioned` there is one bucket per
resolved `partition_key`.

**partition_by** — A dynamic partition key resolver declared on the worker (e.g.
`partition_by: {:args, :user_id}`). At enqueue time the resolved value becomes the
`partition_key` used to look up the correct bucket.

**scope** — The partitioning strategy for a limiter resource. `global` means one
shared bucket across all callers. `partitioned` means one independent bucket per
resolved `partition_key`, enabling per-user, per-account, or per-tenant limits.

**cooldown** — An operator-set hold on a partition until a specific `DateTime`. While
a cooldown is active, all reservations for that partition are blocked with the
`cooldown` blocker code regardless of remaining bucket capacity. Useful for
propagating backpressure signals (e.g. HTTP 429 responses) into the limiter.

**limit_reached** — Blocker code returned when `tokens_used + weight > bucket_capacity`.
The `retry_at` field indicates when the bucket will reset
(`bucket_started_at + bucket_span_ms`, clamped to at least now).

**cooldown** (blocker code) — Blocker code returned when a resource partition is under
an active operator cooldown. The `retry_at` field is `cooldown_until` — the
`DateTime` at which the cooldown expires and reservations are permitted again.
