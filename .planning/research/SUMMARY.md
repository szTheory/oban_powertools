# Research Summary: Batches and Composition

## Executive Summary

Oban Powertools Batches and Composition (v1.9) aims to provide Ecto-native, reliable background job orchestration. Building these tools effectively means avoiding complex dependency graph libraries or external data stores, and instead leveraging pure Elixir/OTP and Ecto to handle state and logic natively. The industry standard approach for massive parallel operations is to group them into dedicated "Batches" and string sequential tasks into "Chains", maintaining distinct mental models for both.

The recommended approach mandates zero new dependencies (no `libgraph`, no Redis). It leverages existing Powertools foundations (v1.7 Worker Hooks, Output Recording) and relies heavily on a Generalized Callback Outbox to coordinate workflows atomically alongside job execution. A strong focus on Operator UX requires building a native `/ops/jobs/batches` Phoenix LiveView interface with integrated Lifeline capabilities for bulk recovery.

Key risks include lock contention on massive batch inserts and completions, dead callbacks rendering a batch seemingly stuck, and mixing batch (parallel) and workflow (DAG) mental models. Mitigations involve chunking massive inserts, isolating callback logic into robust outboxes with explicit UI for "Retry Callback", and separating the "Chain" API from the "Batch" API so developers don't misuse one for the other.

## Key Findings

### Stack
- **Zero New Dependencies:** Strict mandate to use only Elixir (~> 1.19), PostgreSQL (~> 0.17), Ecto (~> 3.10), and Oban (~> 2.18).
- **No Third-Party DAG Tools:** `libgraph` or similar tools are not permitted.
- **No External Datastores:** Redis is prohibited. State must remain purely in Ecto/Postgres.

### Features
- **Table Stakes:** Dedicated batch tracking (`batches` and `batch_jobs` tables), explicit lifecycle callbacks (completed/exhausted), linear chains, and a native Batch Inspection UI.
- **Differentiators:** Lifeline-Routed Bulk Recovery, Generalized Callback Outbox to prevent dropped callbacks, and Explainable Blocked States.
- **Anti-Features to Avoid:** Growable/nested batches, chunking based on size (defer to future), and implicit workflow callbacks overloading worker hooks.

### Architecture
- **Data Models:** Use explicit Ecto tables (`oban_powertools_batches`, `oban_powertools_batch_jobs`, `oban_powertools_callbacks`) instead of overloading `oban_jobs` metadata.
- **Execution Patterns:** Implement a Generalized Callback Outbox. Use Exactly-Once Progress Accounting via worker lifecycle hooks (`on_success`/`on_discard`) to prevent race conditions during batch state updates.
- **Anti-Patterns:** Avoid heavy DAG tables for simple linear chains, overloading job `meta` for orchestration, and polling for completion via crons.

### Pitfalls
- **Mixing Mental Models:** Using batch callbacks to create complex sequential DAGs, or workflows for parallel jobs.
- **Giant Transaction Batch Inserts:** Enqueueing 100,000 jobs in a single transaction crashes the DB.
- **Callback Isolation (Silent Hanging):** Batch completes but the callback job fails and is discarded, leaving operators blind.
- **Dependency Pruning Black Hole:** Underlying Oban pruning mechanism deleting jobs that are part of an ongoing workflow.
- **Heavy Data-Flow in Callbacks:** Passing huge datasets through callback arguments (OOM crashes) instead of using external record storage.

## Roadmap Implications

Suggested phases: 4

1. **Phase 1: Schemas & Foundation**
   - **Rationale:** The core data model must exist before logic or APIs can be built. Prevents overloading `oban_jobs` meta.
   - **Delivers:** `oban_powertools_batches`, `oban_powertools_batch_jobs`, and `oban_powertools_callbacks` migrations and schemas.
   - **Features:** Dedicated Batch Tracking.
   - **Pitfalls Avoided:** Dependency Pruning Black Hole (jobs pruned before workflow complete).

2. **Phase 2: Execution Engine & Tracker Hooks**
   - **Rationale:** Tracking batch progress and safely dispatching callbacks relies heavily on integrating with existing v1.7 Worker Hooks cleanly.
   - **Delivers:** `Batch.Tracker` wired to `on_success`/`on_discard` hooks, ensuring atomic exactly-once progress counting and callback insertion.
   - **Features:** Lifecycle Callbacks.
   - **Pitfalls Avoided:** Lock Contention on Batch Progress; Heavy data-flow in callbacks (relies on recorded output limits instead).

3. **Phase 3: APIs (Batches & Chains)**
   - **Rationale:** Exposes developer ergonomics after the core engine is solid, defining strict bounds between Batches and Chains.
   - **Delivers:** `Batch.insert_stream/2` for chunked insertions and a `Chain` DSL for linear jobs using the Callback Outbox.
   - **Features:** Linear Chains.
   - **Pitfalls Avoided:** The "Giant Transaction" Batch Insert; Mixing DAG and Batch Models; Giant DAGs.

4. **Phase 4: Operations Console & Lifeline UI**
   - **Rationale:** Brings Operator visibility, which relies on all underlying structures to be readable and actionable.
   - **Delivers:** `/ops/jobs/batches` native Phoenix LiveView interface, integrating with Lifeline for bulk-retry and callback recovery.
   - **Features:** Native Batch Inspection UI, Lifeline-Routed Bulk Recovery, Explainable Blocked State.
   - **Pitfalls Avoided:** Callback Isolation and "Silent Hanging" (by adding "Retry Callback" to UI).

### Research Flags
- **Needs research:** Phase 3 (API ergonomics for the `Chain` DSL to ensure it correctly prevents complex graph abuse).
- **Standard patterns:** Phase 1, Phase 2, Phase 4.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Stack** | HIGH | Strict project mandates provide absolute clarity on tech boundaries. |
| **Features** | HIGH | Distinct table stakes, differentiators, and explicitly prohibited anti-features identified. |
| **Architecture** | HIGH | Based on proven Ecto patterns and the newly established Powertools v1.7 hooks. |
| **Pitfalls** | HIGH | Well-documented industry pain points from Sidekiq, Celery, and Oban Pro. |

**Overall:** HIGH
**Gaps:** API ergonomics for chains need finalization during Phase 3 planning to ensure they don't leak into full DAGs.

## Sources
- `.planning/PROJECT.md`
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md`
- `prompts/oban_powertools_context.md`
- Oban HexDocs & Oban Pro Public Documentation
- Sidekiq Batches limitations and historical community discussions
- Celery Chords lock contention analyses