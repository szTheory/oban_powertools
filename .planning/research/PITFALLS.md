# Pitfalls Research

**Domain:** Operations/Task Queues — Batches & Composition
**Researched:** 2026-06-14
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Mixing the "DAG" and "Batch" Mental Models

**What goes wrong:**
Developers try to use Batch callbacks (`on_completed`) to string together complex sequences of heterogeneous jobs, or they try to use Workflows (DAGs) to fan out 50,000 identical parallel jobs. The former creates an untraceable callback hell; the latter crashes the database trying to track 50,000 independent dependency edges.

**Why it happens:**
Both Oban Pro and Sidekiq Pro offer "Batches" and "Workflows", but their purposes blur for developers. Batches are for parallel work where you only care about "when the whole group finishes". Workflows are for sequential, heterogeneous pipelines where "Job B must run after Job A."

**How to avoid:**
Powertools must enforce strict boundaries. Treat Batches as "Parallel Groups + Callbacks" and Workflows as "Directed Graphs". Provide "Chains" as a first-class concept to handle simple sequential jobs so developers don't abuse Batches to achieve sequential steps.

**Warning signs:**
A developer passing `batch_id` around to manually schedule the "next step", or a workflow payload defining thousands of identical leaf nodes.

**Phase to address:**
Initial API design phase of v1.9.

---

### Pitfall 2: The "Giant Transaction" Batch Insert

**What goes wrong:**
To insert a batch of 100,000 jobs, the host app calls `insert_all` inside a single `Repo.transaction`. The transaction holds locks, blocks vacuuming, starves the Ecto connection pool, and eventually crashes with a timeout.

**Why it happens:**
Developers want atomic guarantees ("all jobs enqueue or none do"), but Postgres cannot gracefully hold open a massive multi-megabyte job insert lock without collateral damage to other live queries.

**How to avoid:**
Provide an idiomatic `ObanPowertools.Batch.insert_stream/2` that commits in chunks of 1,000 to 5,000 jobs. Explicitly document that massive batches are eventually consistent upon insert and recommend using a generator job to fan out the batch.

**Warning signs:**
DB timeout errors and connection pool exhaustion immediately after a batch enqueue.

**Phase to address:**
Batch Insert API phase in v1.9.

---

### Pitfall 3: Callback Isolation and "Silent Hanging"

**What goes wrong:**
A batch finishes all 10,000 jobs successfully. The `on_completed` callback is enqueued, but the callback job itself raises an exception, exhausts its retries, and moves to the dead/discarded state. To the operator, the batch looks "complete", but the critical side-effect never happened. Sidekiq suffers from this extensively.

**Why it happens:**
Callbacks are just normal jobs. If they die, the batch state machine has no mechanism to alert the operator that "the batch finished but the callback died."

**How to avoid:**
Tie batch callback jobs explicitly to the batch record. If the callback job is discarded, the batch state must transition to a `callback_failed` state. Lifeline should flag batches with dead callbacks, allowing operators to safely retry the callback from the UI.

**Warning signs:**
Users complaining "the batch finished but the email wasn't sent" and finding discarded callback jobs in the queue.

**Phase to address:**
Batch Callback Execution and UI phase.

---

### Pitfall 4: The Dependency Pruning Black Hole

**What goes wrong:**
A workflow (DAG) spans several days. The early jobs (Job A and Job B) complete successfully. Before Job C can run, the Pruner job runs and deletes Job A and Job B because they are "old completed jobs". Job C wakes up, looks for its dependencies, and hangs forever because the dependency records are gone.

**Why it happens:**
Pruning logic is usually global and time-based (e.g., "delete completed jobs older than 24 hours"), completely ignoring workflow or batch graph topologies.

**How to avoid:**
Powertools Pruner *must* be graph-aware. It should never prune jobs that are part of an unexhausted/incomplete Batch or a running Workflow. Alternatively, separate `oban_powertools_batch_jobs` records should track the state separately from the core `oban_jobs` table so Oban can prune freely without breaking the Powertools graph.

**Warning signs:**
Jobs stuck in `available` state waiting on signals that will never arrive.

**Phase to address:**
Data Modeling and Storage phase for Batches.

---

### Pitfall 5: Heavy Data-Flow in Callbacks

**What goes wrong:**
Developers try to pass the result of 10,000 jobs into the final batch callback to generate a report, either by passing massive state via JSON arguments or string-aggregation in the database. This causes OOM (Out of Memory) crashes or massive Postgres payload bloat.

**Why it happens:**
Celery allows "Chords" to pass results downstream, which serializes huge arrays across the broker. Developers expect the same in Batches.

**How to avoid:**
Make it explicit: Batches are Control Flow, not Data Flow. Use the v1.7 `oban_powertools_job_records` table to store individual job outputs, and the callback job should perform a `JobRecord.stream_results(batch_id)` to lazily process the data in memory.

**Warning signs:**
Payloads in `oban_jobs` exceeding 1MB; Ecto out-of-memory errors on job load.

**Phase to address:**
Documentation and UI limits during v1.9.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Using `oban_jobs` meta for Batch state | Saves creating a new `batches` table | Expensive JSONB queries; impossible to accurately count large batches; pruning destroys batch state. | Never. Always use a dedicated `oban_powertools_batches` table. |
| Polling to check batch completion | Easy to write in the worker | Wastes DB IO; creates race conditions. | Never. Use DB triggers or callback outboxes on job state change. |
| Using `on_completed` for cleanup | Seems logical for finalization | If one job is cancelled/discarded, it *never* fires, leaving dangling resources. | Use `on_exhausted` for guaranteed cleanup, `on_completed` only for absolute success paths. |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| **UI Dashboard** | Just showing job lists without linking them back to the batch | Build a top-level Batches UI where operators can see progress bars, failed members, and retry all failed members in one click. |
| **Unique Jobs** | Inserting a batch with unique constraints without conflict policies | Exclude `:executing` from unique states when dynamically inserting subsequent chained jobs, otherwise 5ms race conditions cause false `{:conflict}` rejections. |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| **Lock Contention on Batch Progress** | Deadlocks when 1,000 jobs in a batch finish simultaneously and update the single batch record. | Do not update the `batches` row directly per job completion. Use a fast incremental counter, or calculate dynamically from `batch_jobs` until `completed_count == total_count`. | Breaks at >500 concurrent worker threads updating the same batch. |
| **Giant DAGs** | Inserting 10,000 step workflow | Use a Batch for the 10,000 jobs, and make the Batch callback the next step in a simple Chain. | Breaks >1,000 node graphs. |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Unredacted batch args | Batches often carry PII (e.g. bulk email sends). If batch parent args aren't redacted, they bypass v1.7 protections. | Apply the v1.7 `redact: [:field]` policy to the Batch definitions and UI just as strictly as individual workers. |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Unretryable Callbacks | Operator sees batch "stuck" but cannot figure out how to force the callback to run. | Native UI must explicitly show the callback status and provide a clear "Retry Callback" action routed through Lifeline. |
| Lack of Bulk Action Scope | Retrying a failed job without knowing it's part of a batch messes up the batch completion state. | The Job Detail UI must show a "Part of Batch X" badge and warn if an action disrupts the batch invariants. |

## "Looks Done But Isn't" Checklist

- [ ] **Batch UI:** Often missing the ability to view *just* the failed jobs inside a specific batch — verify operators can filter by `batch_id` and `state=discarded`.
- [ ] **Callback Resilience:** Often missing detection for dead callbacks — verify Lifeline flags batches where `callback_job` is discarded.
- [ ] **Pruner Protection:** Often missing safety against pruning active batch dependencies — verify `mix oban_powertools.pruner` does not delete jobs linked to unexhausted batches.
- [ ] **Metrics:** Often missing Parapet integration — verify `[:oban_powertools, :batch, :completed]` emits telemetry for SLOs.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Callback job died permanently | LOW | Use the UI "Repair Center" (Lifeline) to re-enqueue the specific callback job, resuming the batch lifecycle. |
| Jobs pruned before workflow complete | HIGH | Operator must manually reconstruct the job state or use an API to bypass the missing dependency. Better to prevent via Pruner logic. |
| Batch insert transaction timeout | MEDIUM | Delete the partially inserted batch and use the dry-run CLI to enqueue via the chunked streaming API. |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Mixing DAG and Batch Models | v1.9 (API Design) | Verify `ObanPowertools.Batch` and `ObanPowertools.Chain` are explicitly separated abstractions with no overlapping callbacks. |
| Dependency Pruning Black Hole | v1.9 (Data Storage) | Verify `oban_powertools_batch_jobs` is used to prevent Oban core from pruning graph edges unexpectedly. |
| Callback Silent Hanging | v1.9 (Lifeline / UI) | Verify Lifeline detects discarded batch callbacks as "Stuck Batch" findings with 1-click repair. |
| Lock Contention | v1.9 (Execution) | Verify load-testing 5,000 concurrent batch job completions does not deadlock the DB. |

## Sources

- Oban Pro Public Documentation (Workflows vs Batches, Pruning caveats, Callbacks).
- Sidekiq Batches limitations and OOM historical community discussions.
- Celery Chords lock contentions and data-flow serialization problems.
- `oban_powertools_context.md` (Repo context asserting Ecto-native, distinct tables, explicit lifecycle).
- `oban_powertools_ultimate_ui_strategy_brief.md` (Operator UX focus and Ops Console philosophy).

---
*Pitfalls research for: Oban Powertools — Batches & Composition*
*Researched: 2026-06-14*
