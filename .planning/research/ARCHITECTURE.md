# Architecture Patterns

**Domain:** Operational toolkit for background jobs
**Researched:** 2024

## Recommended Architecture

The system utilizes an Ecto-native, Postgres-only architecture where all job state, limiters, workflows, and audit trails are durable tables accessed via `Ecto.Multi`. The system relies on Erlang's `:telemetry` for asynchronous observability and OTP GenServers for non-blocking liveness (heartbeats) and local event signaling.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| Web/Dashboard | Operator interface, data filtering, and action triggers. | Public API boundary (`ObanPowertools.Jobs.retry`). |
| Public API Layer | Elixir-facing functions that wrap `Ecto.Multi` transactions. | Ecto Repos, Auditing System, Telemetry. |
| Smart Engine / Limits | Validates if a job can run against global/rate capacities. | Postgres (`oban_powertools_limiters`), Oban executors. |
| Workflow Coordinator | GenServer that listens for step completions and unblocks DAG edges. | Phoenix.PubSub, Postgres (`oban_powertools_workflow_edges`). |
| Lifeline/Repair | GenServer tracking executor heartbeats to detect/rescue orphans. | Postgres (`oban_powertools_heartbeats`). |

## Patterns to Follow

### Pattern 1: Idempotency Receipts
**What:** Writing a durable "receipt" to a database table within the same transaction as the side-effect to guarantee a job's core logic only executes once.
**When:** Whenever a job performs critical mutations (billing, data sync) and could be retried due to network faults or worker crashes.
**Example:**
```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:receipt, %Receipt{idempotency_key: hash}, on_conflict: :nothing)
|> Ecto.Multi.run(:check, fn _, %{receipt: r} -> if r.id, do: {:ok, :continue}, else: {:error, :already_done} end)
|> Repo.transaction()
```

### Pattern 2: Atomic Rate Limiting
**What:** Performing token consumption via `UPDATE ... RETURNING` directly in SQL rather than reading the row, doing math in Elixir, and writing it back.
**When:** Evaluating rate limits (e.g., token bucket) for external API constraints.
**Example:**
```sql
UPDATE oban_powertools_limiters
SET tokens = LEAST(capacity, tokens + extract(...) * rate) - 1, last_refilled_at = now()
WHERE id = 1 AND (tokens + ...) >= 1 RETURNING *;
```

### Pattern 3: Explainability ("Why am I blocked?")
**What:** Limiters and constraint engines must explicitly return the reason for blocking, enabling the UI to surface operator insights instead of silent queues.
**When:** A job is available but cannot be dispatched.
**Example:**
```elixir
{:blocked, {:rate_limit_exhausted, "github_api", resets_at: ~U[...]}}
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: "The Celery Trap" (Per-Worker Limits)
**What:** Applying rate limits at the local worker level rather than globally across the database.
**Why bad:** Users scale from 1 to 5 workers, accidentally turning a `100 req/min` limit into a `500 req/min` limit, triggering downstream API bans.
**Instead:** Global/Partition rate limit state must be stored in the central PG database.

### Anti-Pattern 2: Silently Swallowing Uniqueness Conflicts
**What:** Returning a boolean `true/false` when a job insertion hits a uniqueness constraint.
**Why bad:** Hides the conflict from developers, causing confusion over missing data or dropped jobs.
**Instead:** Return explicit tagged tuples from the API: `{:ok, job}` or `{:conflict, existing_job}`.

### Anti-Pattern 3: Time-Based Naive Rescues
**What:** Assuming a job is dead (orphaned) simply because it has been executing for > 10 minutes.
**Why bad:** Long-running jobs that are perfectly healthy get duplicate executions.
**Instead:** Use active node heartbeats (`oban_powertools_heartbeats`). If a heartbeat stops, the node is dead and its jobs can be safely rescued.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| Rate Limit Contention | Standard row updates | Row lock contention | Switch to highly optimized partial indexes, potential shard-based capacity tracking. |
| Job Table Size | Unnoticeable | Index bloat starts | Implement the `DynamicPruner` early to archive/delete cold job states aggressively to preserve cache hit ratios. |

## Sources

- Oban OSS / Pro public documentation analysis.
- Sidekiq ecosystem best practices.