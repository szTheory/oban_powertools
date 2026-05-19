# Domain Pitfalls

**Domain:** Operational toolkit for background jobs
**Researched:** 2024

## Critical Pitfalls

Mistakes that cause rewrites, data corruption, or severe production incidents.

### Pitfall 1: Split-Brain State (The Redis Trap)
**What goes wrong:** A job is inserted into the PostgreSQL `oban_jobs` table transactionally alongside business data, but its rate limit token or uniqueness lock is stored in an external Redis instance.
**Why it happens:** Redis is perceived as "faster" for counting and locking.
**Consequences:** Network partitions or crashes between the PG transaction and the Redis call lead to phantom jobs, dropped limits, or stuck locks.
**Prevention:** Strictly enforce an Ecto-native, Postgres-only architecture. All state, limiters, receipts, and uniqueness constraints must live in Postgres.
**Detection:** Architectural reviews and strict prohibition of Redis/Memcached dependencies.

### Pitfall 2: Naive Time-Based Job Rescue
**What goes wrong:** A background worker rescues/retries any job that has been in the `executing` state for more than 15 minutes.
**Why it happens:** Developers want to prevent "stuck" jobs without implementing liveness checks.
**Consequences:** Long-running healthy jobs (like heavy DB migrations or large imports) get forcefully duplicated, causing massive data corruption or external API floods.
**Prevention:** Implement GenServer-based heartbeats. Only rescue jobs if the *node/executor* has stopped heartbeating, not based on job runtime.
**Detection:** Unexplained job duplications during heavy processing periods.

### Pitfall 3: The "Exactly-Once" Guarantee Myth
**What goes wrong:** Promising developers that a job will only ever execute exactly one time.
**Why it happens:** Misunderstanding of distributed systems; assuming that uniqueness at enqueue time prevents double execution.
**Consequences:** If a worker crashes mid-execution after external side effects but before acknowledging the job, Oban will retry it. Without idempotency, data is corrupted or users are double-billed.
**Prevention:** Educate users on "At-Least-Once" execution. Provide built-in `Idempotency Receipt` patterns in the `ObanPowertools.Worker` macro.
**Detection:** Side-effects repeating during deployment rollouts or worker crashes.

## Moderate Pitfalls

### Pitfall 4: Per-Worker Rate Limiting
**What goes wrong:** Setting a rate limit of 100/min on a queue, but it's enforced locally in memory.
**Prevention:** Explicitly distinguish between `local_limit` (concurrency per node) and `rate_limit` (global token bucket in Postgres). Use Postgres atomic updates for true global limits.

### Pitfall 5: Workflow "Zombie" States
**What goes wrong:** Step A completes but fails to notify Step B, or Step A is manually cancelled by an admin, leaving Step B blocked forever in the queue.
**Prevention:** Expose explicit telemetry events (`on_workflow_stuck`) and provide a Repair Center UI that highlights unresolved workflow graphs.

## Minor Pitfalls

### Pitfall 6: High-Cardinality Metrics
**What goes wrong:** Injecting `job_id` or `user_email` into Prometheus/Erlang `:telemetry` metric labels.
**Prevention:** Implement strict redaction and cardinality policies. Keep high-cardinality data strictly inside Postgres `Audit` tables and `metadata` payloads, never in metric labels.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Smart Engine / Limits | Atomic race conditions in Postgres. | Heavy use of `UPDATE ... RETURNING` and property-based concurrency testing. |
| Workflows / DAGs | Heavy DB polling killing performance. | Use `Phoenix.PubSub` / Postgres Listen/Notify for immediate signaling instead of polling. |
| Dashboard UI | Direct DB manipulation bypassing validations. | Require all LiveView actions to route through a public Elixir API boundary (e.g., `Jobs.retry()`). |

## Sources

- Sidekiq Enterprise and Oban Pro architectural warnings.
- Celery / Hangfire community issue trackers.