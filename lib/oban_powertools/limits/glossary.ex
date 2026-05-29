defmodule ObanPowertools.Limits.Glossary do
  @moduledoc """
  Single-source rate-limit glossary for ObanPowertools limiters.

  `text/0` returns the canonical glossary markdown string consumed by both
  Mix task `@moduledoc` sections and `guides/limits-and-explain.md`.
  """

  @text """
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
  """

  @doc """
  Returns the canonical rate-limit glossary as a markdown string.

  This single string is the source of truth consumed by both Mix task
  `@moduledoc` sections (`oban_powertools.limiter.explain` and
  `oban_powertools.limiter.simulate`) and `guides/limits-and-explain.md`.
  """
  @spec text() :: String.t()
  def text, do: @text
end
