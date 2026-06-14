# Feature Landscape

**Domain:** Ecto-native Background Job Operations (Oban Powertools) - Batches & Composition
**Researched:** 2026-06-14

## Table Stakes

Features users expect for batching and composition based on prior art like Sidekiq Pro, Celery, and Oban Pro. Missing these makes the composition layer feel untrustworthy or incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Dedicated Batch Tracking** | Operators need to see a "Job" as a 10,000-row import, not just 10,000 disconnected rows. | Medium | Use explicit `batches` and `batch_jobs` tables instead of shoving DAG state into metadata. |
| **Lifecycle Callbacks** | The primary developer JTBD is "do X when these N things finish." Needs `completed` and `exhausted` hooks. | Medium | Callbacks must be resilient to enqueue failures. |
| **Linear Chains** | Sequential operations (fetch -> parse -> transform -> notify) are the most common composition pattern. | Low | Can be built as syntactic sugar over a simpler internal DAG structure. |
| **Native Batch Inspection UI** | Operators need to answer "How far along is this import?" and "Which specific items failed?" | Medium | A native page in the Powertools shell is required. |

## Differentiators

Features that set Powertools apart by leveraging Elixir/Phoenix/Ecto strengths and focusing heavily on the Operator/SRE persona.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Lifeline-Routed Bulk Recovery** | "Retry all failed in batch" goes through the audited Lifeline pipeline, preventing concurrent mutation races and ensuring a durable audit trail. | High | Relies on the v1.5 native job surface architecture. |
| **Generalized Callback Outbox** | Prevents the Sidekiq anti-pattern where a callback is dropped because the process crashed between the last job finishing and the callback enqueueing. | High | Transactional isolation for callbacks. |
| **Explainable Blocked State** | Operators don't just see "pending"; they see "waiting on job X in chain" or "waiting for batch completion." | Medium | Directly addresses the "Why isn't my job running?" JTBD. |

## Anti-Features

Features to explicitly NOT build in this milestone to prevent scope creep and reliability footguns.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Nested / Growable Batches** | Adding jobs to a batch *after* it starts executing introduces massive race condition complexity and is Sidekiq's most notorious reliability trap. | Require fixed-size batches on insert. If dynamic scaling is needed, emit a new batch. |
| **Chunking / Size-based batches** | distinct from logical grouping; optimizing throughput via chunking is a different JTBD than logical composition. | Defer Chunks to a separate feature slice or milestone. |
| **Implicit Workflow Callbacks** | Overloading a worker's `on_success` hook to mean "the whole workflow is done." | Use explicit, separate `on_batch_completed` callbacks. |

## Feature Dependencies

- **Worker Lifecycle Hooks (v1.7)** → **Batches** (Batch progress relies on worker `on_success`/`on_failure` hooks to tick the batch counters).
- **Recorded Output (v1.7)** → **Chains** (Passing results from Step A to Step B requires durable output recording).
- **Native Job Actions & Lifeline (v1.5)** → **Batch Bulk Retry** (Batch retry UI must route through the `ObanPowertools.Operator` API to maintain audit and safety boundaries).

## MVP Recommendation

**Prioritize:**
1. **Dedicated Tables:** Clean Ecto schemas for `batches` and `batch_jobs` (do not hack Oban `oban_jobs` metadata for structural integrity).
2. **Explicit Callbacks:** Support `completed` and `exhausted` states via a Callback Outbox.
3. **Linear Chains:** Ergonomic DSL for `JobA |> chain(JobB)`.
4. **Ops Console UI:** A native `/ops/jobs/batches` page showing progress bars, failed members, and Lifeline-routed "Retry Failed" bulk actions.

**Defer:**
- Chunks (timeout/size-based grouping).
- Growable batches.
- Complex fan-in/fan-out DAGs that aren't linear Chains (keep it simple for v1.9).

## Sources

- `PROJECT.md` (v1.9 Batches & Composition scope & constraints)
- `oban_powertools_context.md` (Domain language, Operator personas, Oban Pro & Sidekiq Pro comparison)
- `oban_powertools_ultimate_ui_strategy_brief.md` (Operator UX principles: "Explain, then act")