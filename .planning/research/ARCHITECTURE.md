# Architecture Patterns

**Domain:** Job Operations Toolkit (Oban Powertools)
**Researched:** 2026-06-14
**Focus:** Batches & Composition (v1.9 Milestone)

## Recommended Architecture

The architecture relies on Ecto-native composition without imposing heavy DAG tables. It uses a **Generalized Callback Outbox** paired with the existing **v1.7 Worker Lifecycle Hooks** to achieve durable orchestration.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `ObanPowertools.Batch` | API for defining and enqueuing batches. | Ecto.Multi, `Oban.insert_all` |
| `ObanPowertools.Chain` | API macro for defining linear sequential jobs. | `CallbackOutbox` |
| `ObanPowertools.CallbackOutbox` | Stores `(target_id, event_type, callback_job)` intent. | Worker Hooks, `Oban` |
| `ObanPowertools.Batch.Tracker` | Enforces exactly-once progress counting per job. | Worker Hooks, `Batches` schema |
| `BatchesLive` (Native UI) | Read-only views and Lifeline-routed bulk repair. | `Lifeline.execute_repair` |

### Data Flow

1. **Enqueueing a Batch:**
   - `Batch.new(jobs)` generates a unique `batch_id`.
   - `Batch.insert()` uses `Ecto.Multi` to transactionally create:
     1. One `oban_powertools_batches` row (total count, initial state).
     2. N `oban_powertools_batch_jobs` rows (mapping `job_id` -> `batch_id` with initial state).
     3. Optional `oban_powertools_callbacks` rows for `:completed` and `:exhausted` events.
     4. N `oban_jobs` rows (with `batch_id` stamped in `meta`).

2. **Execution & Progress Tracking:**
   - A job executes via `ObanPowertools.Worker` wrapper.
   - The wrapper catches completion and fires the v1.7 `on_success/2` or `on_discard/2` hooks.
   - `Batch.Tracker` intercepts these hooks:
     - Issues an atomic `UPDATE oban_powertools_batch_jobs SET state = 'completed' WHERE job_id = ^job.id AND state != 'completed'`.
     - *If and only if* 1 row is updated (preventing double-counting if the worker crashed after the hook but before Oban ACK), it atomically updates the `oban_powertools_batches` tallies.

3. **Callback Dispatch:**
   - If the atomic tally update reaches the batch's `total_count`, the same transaction queries the `CallbackOutbox` for the `:completed` event and inserts the callback job into `oban_jobs`.

4. **Composition (Chains as Linear-DAG Sugar):**
   - Chains bypass the `batches` table entirely.
   - `Chain.new([job_A, job_B, job_C])` translates to `job_A` having `job_B` in its outbox on `:completed`, and `job_B` having `job_C`.
   - When `job_A` completes, its worker hook evaluates the outbox and enqueues `job_B` transactionally.

## Patterns to Follow

### Pattern 1: Generalized Callback Outbox
**What:** A dedicated `oban_powertools_callbacks` table handles orchestration rather than polluting `oban_jobs` meta with complex nesting.
**When:** Orchestrating chains, batches, or custom workflow signals.
**Example:**
```elixir
# Internal DB structure
%CallbackOutbox{
  target_id: "batch_123", # or "job_456" for a chain
  event_type: :completed, # or :exhausted
  job_args: %{worker: "MyApp.CallbackWorker", args: %{...}}
}
```

### Pattern 2: Exactly-Once Progress Accounting
**What:** Worker hooks run *before* Oban transactionally ACKs the job. To avoid double-incrementing a batch if the DB connection drops post-hook, use an intermediate `batch_jobs` state transition as a concurrency guard.
**When:** Updating any aggregated counter from a worker hook.
**Example:**
```elixir
# In the on_success hook
{1, _} = Repo.update_all(
  from(bj in BatchJob, where: bj.job_id == ^job.id and bj.state != :completed),
  set: [state: :completed]
)
# Only if 1 row was updated, proceed to increment Batch total
```

### Pattern 3: UI Mutations Through Lifeline
**What:** Bulk-retrying a failed batch routes through the existing native `Lifeline` repair center, enforcing preview, reason, dry-run, and audit.
**When:** Implementing the "Retry Failed Subset" button on the Batches UI.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Heavy DAG Tables for Linear Chains
**What:** Creating a full `workflows` + `workflow_steps` + `workflow_edges` schema to support simple A -> B -> C job sequences.
**Why bad:** Over-engineers the 80% use case (linear pipelines), creates massive DB bloat, and complicates lifecycle management.
**Instead:** Use the Callback Outbox pattern for chains, saving full DAG tables for future workflow milestones.

### Anti-Pattern 2: Overloading Job `meta` for Orchestration
**What:** Storing the entire serialized list of remaining chain jobs in `meta["chain_remaining"]`.
**Why bad:** Bloats the `oban_jobs` row, breaks searchability, and makes DB-level introspection impossible.
**Instead:** Persist relationships via `batch_jobs` or `callbacks`.

### Anti-Pattern 3: Polling for Batch Completion
**What:** Using a Cron job or Oban plugin to sweep `oban_jobs` and check if all `batch_id` members are done.
**Why bad:** Introduces latency, adds unnecessary DB load, and detaches the callback from the transaction that actually completed the final job.
**Instead:** Rely on inline worker hooks and atomic DB increments.

## Scalability Considerations

| Concern | At 100 users (Small Batches) | At 10K users (Large Batches) | At 1M users (Massive Scale) |
|---------|--------------|--------------|-------------|
| **Row Lock Contention** | Standard `UPDATE` on `batches` row works fine. | Simultaneous job completions cause lock queues on `batches` update. | Defer "Chunks/Growable Batches" until demand proves need. Provide `Oban.Pro`-style aggregator workers if atomic increments bottleneck. |
| **Outbox Size** | Callbacks table is tiny. | Chain definitions can bloat outbox. | Need ephemeral prune routines via `Lifeline` to sweep completed callbacks. |
| **Bulk Inserts** | `insert_all` works natively. | Postgres parameter limits (65,535) exceeded. | Chunk `Ecto.Repo.insert_all` logic into batches of 1,000 within the transaction. |

## Suggested Build Order

1. **Phase 1: Schemas & Foundation**
   - Create `oban_powertools_batches`, `batch_jobs`, and `callbacks` tables.
2. **Phase 2: Execution & Tracker Hooks**
   - Wire `Batch.Tracker` into the existing `v1.7` worker lifecycle outbox (exactly-once guard).
3. **Phase 3: APIs**
   - Implement `Batch` (creation/insertion) and `Chain` (DAG sugar via callbacks).
4. **Phase 4: UI & Lifeline**
   - Build `/ops/jobs/batches` native LiveView and route bulk-retry through `Lifeline.execute_repair`.

## Sources
- Oban Powertools `PROJECT.md` & UI Strategy Brief (Context constraints & prior architectural decisions).
- Ecosystem Analysis (Oban Pro Batches, Sidekiq Pro Batches).
