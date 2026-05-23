# Technology Stack

**Project:** oban_powertools
**Scope:** v1.2 workflow semantics and recovery only
**Researched:** 2026-05-23

## Recommended Stack

### Core Runtime
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | `~> 1.19` | Runtime and OTP primitives | Already the project baseline in `mix.exs`; no stack change needed. Use OTP processes only for coordination and fanout, not as workflow truth. |
| Oban | `~> 2.22` | Workflow-adjacent job lifecycle, cancellation, scheduled expiry work, cluster-safe notification | This milestone should lean harder on current Oban primitives: `cancel_job`, `cancel_all_jobs`, `Oban.Job.query/1`, `Oban.Worker` terminal returns, and `Oban.Notifier`. Oban is already the durable execution substrate; do not add a second orchestration engine. |
| Ecto / Ecto SQL | `~> 3.14` | Transactional workflow state machine, recovery writes, lock-aware diagnosis queries | `Ecto.Multi` remains the right primitive for callback state transitions, signal consumption, cancellation requests, and expiry promotion because these must commit atomically with workflow row updates. |
| Postgrex | `~> 0.22` | Postgres-native transport and diagnostics access | Needed for `LISTEN/NOTIFY` through Oban’s Postgres notifier path and for direct read-only diagnosis queries against `pg_locks` / `pg_stat_activity` when explaining stuck graphs. |

### Infrastructure
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| PostgreSQL | `16+` or `18 current` | Durable workflow truth, lock coordination, expiry scanning, diagnosis | This milestone is still firmly Postgres-native. Use row locks with `FOR UPDATE SKIP LOCKED` for sweepers and transaction-scoped advisory locks only where a single workflow reconcile pass must be serialized. |
| Oban Notifier with Postgres backend | bundled with Oban `2.22.x` | Cross-node workflow wakeups and cancellation fanout | Replace workflow-runtime dependence on ad hoc `Phoenix.PubSub` broadcasts with `Oban.Notifier.notify/3`. It is already required by Oban control actions and matches the project’s “Postgres/Ecto-native over split control planes” rule. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:telemetry` | `~> 1.4` | Low-cardinality public events for callback, await, cancellation, expiry, and diagnosis transitions | Extend the existing public workflow family instead of adding a new metrics stack. Use for counters and state labels only; keep high-cardinality evidence in tables. |
| `:phoenix_pubsub` | `~> 2.2` | UI-local fanout only | Add as a direct dependency only if the library continues to own LiveView refresh fanout. It should not be the durable workflow signal bus. |
| `oban_web` | `~> 2.12`, optional | Generic job drill-down from workflow diagnosis screens | Keep optional and unchanged. It is still useful as a bridge for raw job inspection, but it is not the place to implement workflow semantics. |

## Required Changes

### 1. Align declared dependency ranges with the already-locked runtime

The repo is currently locked to newer packages than `mix.exs` declares:

| Package | `mix.exs` now | `mix.lock` now | Recommendation |
|---------|---------------|----------------|----------------|
| `oban` | `~> 2.18` | `2.22.1` | Change to `~> 2.22` |
| `ecto_sql` | `~> 3.10` | `3.13.5` | Change to `~> 3.14` |
| `postgrex` | `~> 0.17` | `0.22.2` | Change to `~> 0.22` |
| `telemetry` | `~> 1.4` | `1.4.2` | Keep |
| `phoenix_pubsub` | transitive only | `2.2.0` | Make direct if workflow/UI code keeps using it |

This is not cosmetic. The milestone depends on current Oban notifier and cancellation behavior, and the manifest should describe the tested support matrix accurately.

### 2. Move workflow wakeups to durable Oban signaling

Use:

- `Oban.Notifier.notify/3` for workflow events such as `step_completed`, `signal_received`, `await_satisfied`, `cancel_requested`, and `expiry_fired`
- a small internal adapter that rebroadcasts to `Phoenix.PubSub` for LiveView updates when needed

Do not use:

- plain in-memory process messages as workflow truth
- a Phoenix-only PubSub channel as the only cross-node wakeup mechanism

Reason: current code uses `Phoenix.PubSub` in [`lib/oban_powertools/workflow/coordinator.ex`](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/coordinator.ex:1) and [`lib/oban_powertools/workflow/signal.ex`](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/signal.ex:1). That is acceptable for UI refresh, but not strong enough as the sole recovery-semantic bus in a clustered Oban system.

### 3. Add internal workers, not external libraries

Add internal typed workers for:

| Worker | Purpose | Why it fits |
|--------|---------|-------------|
| `Workflow.ReconcileWorker` | Re-run dependency and callback reconciliation for workflows that lost a wakeup or are suspected stale | Uses existing Oban execution, retries, and auditability. |
| `Workflow.ExpiryWorker` | Promote expired awaits, deadlines, and callback retry windows into terminal workflow transitions | Scheduled Oban jobs are the natural durable timer primitive here. |
| `Workflow.CallbackDispatchWorker` | Drain durable callback/outbox records and retry delivery safely | Keeps callback side effects explicit, replayable, and independent from step completion DB transactions. |
| `Workflow.DiagnosisWorker` | Periodically compute durable stuck/orphaned/waiting diagnoses for operator UI and Lifeline integration | Reuses current operator model instead of inventing a second incident system. |

No extra dependency is needed for any of these. Use the project’s existing `ObanPowertools.Worker` wrapper and `Ecto.Multi`.

## Persistence Patterns To Add

### Durable signal inbox

Add a table for externally meaningful signals, e.g. `oban_powertools_workflow_signals`:

- `workflow_id`
- `step_id` nullable
- `signal_key`
- `payload`
- `status` (`received`, `consumed`, `expired`, `cancelled`)
- `recorded_at`
- `expires_at`
- `consumed_at`
- idempotency key / unique constraint for duplicate suppression

Indexes:

- unique active signal key per workflow/correlation key
- `(workflow_id, status)`
- `(status, expires_at)`

Use this for signal/await semantics. The notifier wakes reconciler processes; the table is the source of truth.

### Await registration table

Add a table for pending waits, e.g. `oban_powertools_workflow_awaits`:

- `workflow_id`
- `step_id`
- `await_key`
- `await_kind` (`signal`, `workflow`, `callback`)
- `state` (`waiting`, `satisfied`, `expired`, `cancelled`)
- `registered_at`
- `deadline_at`
- `resolved_at`
- `resolution_reason`
- `details`

Indexes:

- unique active await per step/key
- `(state, deadline_at)` for expiry sweeps
- `(workflow_id, state)`

This is the missing durable primitive for “signal/await” support. Do not model awaits as only a blocker string on `workflow_steps`.

### Callback outbox table

Add a durable outbox, e.g. `oban_powertools_workflow_callbacks`:

- `workflow_id`
- `step_id` nullable
- `event` (`completed`, `retryable`, `failed`, `cancelled`, `expired`)
- `target`
- `payload`
- `delivery_state` (`pending`, `delivered`, `retryable`, `discarded`)
- `attempt`
- `next_attempt_at`
- `last_error`
- `delivered_at`

This separates “workflow state committed” from “side effect delivered”. That is the right recovery boundary for callback semantics.

### Workflow/step columns

Add fields rather than new libraries for:

- `expires_at`
- `cancel_requested_at`
- `cancel_reason`
- `terminal_reason`
- `last_progress_at`
- `last_reconciled_at`

These columns make stuck-graph diagnosis explainable without inventing a separate state machine package.

## Runtime Primitives To Prefer

| Primitive | Use | Why |
|-----------|-----|-----|
| `Ecto.Multi` | callback commit + await resolution + workflow counter refresh in one transaction | Existing project pattern; keeps workflow truth atomic. |
| `Ecto.Query.lock/2` with `FOR UPDATE` / `FOR UPDATE SKIP LOCKED` | leasing stale workflows, consuming await rows, draining callback outbox | Correct Postgres-native concurrency control for sweepers. |
| transaction-scoped advisory locks | serialize reconcile of a single workflow when row locks alone are awkward | Use sparingly around “one workflow, one coordinator pass” boundaries only. |
| `Oban.cancel_job/2` and `Oban.cancel_all_jobs/2` | workflow cancellation propagation | Existing Oban semantics already match the required contract. |
| scheduled Oban jobs | deadlines, expiry, retry windows, delayed callback dispatch | Durable timers without adding Quartz-like schedulers or cron daemons. |
| `pg_locks` / `pg_stat_activity` read queries | operator diagnosis of blocked/orphaned workflows | Better than adding an external observability dependency for this milestone. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Workflow wakeup bus | `Oban.Notifier` on Postgres | `Phoenix.PubSub` as the only runtime bus | Too weak as the sole durable cluster wakeup path for recovery semantics. |
| Durable timers | scheduled Oban jobs + expiry rows | separate scheduler library / OS cron | Splits timing truth away from workflow state and loses auditability. |
| Callback reliability | DB outbox + Oban dispatch worker | inline HTTP/side-effect callbacks inside workflow transaction | Couples commit success to external side effects and creates ambiguous recovery. |
| Reconcile serialization | row locks + narrow advisory locks | distributed lock service / Redis | Violates the project’s Postgres-native constraint for little gain. |
| Stuck diagnosis | Ecto + direct Postgres system views | Prometheus/OpenTelemetry-first diagnosis stack | Metrics help alerting, but they are not the durable evidence model this milestone needs. |
| Workflow engine | extend current Oban/Ecto model | Temporal/Commanded/Broadway/GenStage/EventStore | Massive contract expansion, duplicate orchestration layer, and a bad fit for the existing shipped operator model. |

## What Not To Add

- No Redis, RabbitMQ, Kafka, or any separate coordination broker.
- No Temporal/Cadence-style external workflow engine.
- No event-sourcing framework just to model callbacks or cancellation.
- No generic state-machine dependency. The workflow state machine already lives in durable Ecto schemas.
- No new metrics backend dependency for this milestone. Extend the existing telemetry contract instead.
- No full native replacement for generic Oban Web screens.

## Installation

```bash
# New explicit runtime dependency only if UI fanout stays PubSub-backed
mix deps.unlock --unused

# Then align declarations with the versions already proven in mix.lock
# mix.exs
{:oban, "~> 2.22"}
{:ecto_sql, "~> 3.14"}
{:postgrex, "~> 0.22"}
{:telemetry, "~> 1.4"}
{:phoenix_pubsub, "~> 2.2"} # only if retained directly
{:oban_web, "~> 2.12", optional: true}
```

## Sources

- HIGH: Oban package versions: https://hex.pm/packages/oban and https://hex.pm/packages/oban/versions
- HIGH: Oban notifier docs: https://hexdocs.pm/oban/Oban.Notifier.html
- HIGH: Oban core job and cancellation docs: https://hexdocs.pm/oban/Oban.html and https://hexdocs.pm/oban/Oban.Job.html
- HIGH: Oban worker terminal return semantics: https://hexdocs.pm/oban/Oban.Worker.html
- HIGH: Oban telemetry docs: https://hexdocs.pm/oban/Oban.Telemetry.html
- HIGH: Ecto transaction and lock primitives: https://hexdocs.pm/ecto/Ecto.Multi.html and https://hexdocs.pm/ecto/Ecto.Query.html
- HIGH: Ecto SQL current package versions: https://hex.pm/packages/ecto_sql
- HIGH: Postgrex current package versions: https://hex.pm/packages/postgrex
- HIGH: Phoenix PubSub current package versions: https://hex.pm/packages/phoenix_pubsub
- HIGH: PostgreSQL locking and queue-consumer primitives: https://www.postgresql.org/docs/current/sql-select.html and https://www.postgresql.org/docs/17/explicit-locking.html
- HIGH: PostgreSQL lock inspection and LISTEN/NOTIFY references: https://www.postgresql.org/docs/current/view-pg-locks.html and https://www.postgresql.org/docs/17/sql-listen.html
