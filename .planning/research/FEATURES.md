# Feature Landscape

**Domain:** Operational toolkit for background jobs
**Researched:** 2024

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Embedded Dashboard | SREs and solo devs need visibility into queues, retries, and errors out of the box. | Medium | Built on Phoenix LiveView. Must integrate easily with host app routing. |
| Typed Job Arguments | Prevents pervasive KeyError/nil pointer exceptions at execution time. | Low | Implemented via `Ecto.Changeset` integration inside `use ObanPowertools.Worker`. |
| Bulk Queue Actions | Users need to pause/resume queues and mass retry/cancel jobs during incidents. | Low | Must run through `Ecto.Multi` with durable audit logging. |
| Safe Idempotency | Avoiding duplicate execution is a core distributed systems problem. | Medium | Use Idempotency Receipts; unique keys must be transactional on insert. |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| "Why isn't this running?" UX | Explains exactly what limiter, dependency, or setting is blocking a job. | High | Requires deep inspection of rate limiters, workflow DAG state, and queue properties. |
| Ecto-Native Limiters | Global, partition, and rate limits managed in PG atomically without Redis. | High | Token-bucket algorithms using `UPDATE ... RETURNING` in SQL. |
| Repair Center | Surface orphaned jobs or stuck workflows with "dry-run" repair previews. | High | Relies on GenServer heartbeats and structured telemetry instead of naive time-based rescue. |
| Audit Logs | Durable evidence of every operator action (e.g., who paused the queue, who retried the job). | Medium | Ensures accountability, especially when integrating with tools like Threadline. |
| Workflows (DAGs) | Compose multi-step batches, chains, and chunks with explicit completion signaling. | High | Avoids "zombie state" jobs. Requires dedicated DAG tables and PubSub eventing. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| "Exactly-Once" Guarantees | Mathematically impossible in distributed systems; creates false security. | Document at-least-once execution and provide idempotency/receipt patterns. |
| Redis Backing | Splits transactional boundaries, breaking job insertion guarantees. | Keep all state strictly in PostgreSQL using Ecto. |
| MySQL/SQLite Support | Too much effort to support multiple RDBMS nuances (e.g., atomic locks, returning). | Focus entirely on deep PostgreSQL features (advisory locks, `RETURNING`, `JSONB`). |

## Feature Dependencies

```
Typed Workers -> Idempotency Receipts
Telemetry Event Standard -> Audit Logs -> Bulk Actions
Ecto.Multi Primitives -> Rate Limiters -> "Why isn't this running?" UX
GenServer Heartbeats -> Lifeline Repair Center
```

## MVP Recommendation

Prioritize:
1. Telemetry and standard Ecto/DB models (Foundation)
2. Embedded LiveView Dashboard with Bulk Actions (Immediate Day-0 Value)
3. Typed Workers and Idempotency patterns (Developer Ergonomics)

Defer: Autoscaling Adapters and Prioritizers (Advanced edge cases for cloud integrations).

## Sources

- Sidekiq / Oban Pro Feature Sets
- Celery / Hangfire Ecosystem Analysis
- Internal context constraints (`oban_powertools_gsd_research.md`)