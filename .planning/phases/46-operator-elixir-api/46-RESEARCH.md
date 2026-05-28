# Phase 46 Research & Architecture Recommendation

## Context
Phase 46 requires creating an `ObanPowertools.Operator` context module to expose typed programmatic functions for single and bulk job mutations (retry, cancel, discard). It must reuse the exact same `Lifeline.preview_repair/4` and `Lifeline.execute_repair/5` pipeline established in the UI phases (Phase 44 and 45) to ensure actor attribution and audit durability. 

## Investigation Findings
1. **Existing Pipeline**: `JobsLive` currently implements bulk actions by mapping over `job_ids` and sequentially calling `Lifeline.preview_repair` followed by `Lifeline.execute_repair` for each job. It tracks successes and failures as simple integer counts.
2. **Telemetry Source**: The `Lifeline.execute_repair/5` function eventually calls `Telemetry.execute_lifeline_event(:repair_executed, ...)` inside `apply_repair/5`. Currently, there is no mechanism to pass caller-provided metadata (like `source: "api"`) into these telemetry events.
3. **API Ergonomics**: While the UI only needs integer counts (`{successes, failures}`) for its flash message, a programmatic API caller typically needs to know *which* specific jobs failed and why, in order to log or handle partial failures.

## Architectural Recommendation

### 1. `ObanPowertools.Operator` API Design
Create a single public module `ObanPowertools.Operator` that exposes:
- **Single Job Actions**:
  - `retry_job(repo, actor, job_id, reason, opts \\ [])`
  - `cancel_job(repo, actor, job_id, reason, opts \\ [])`
  - `discard_job(repo, actor, job_id, reason, opts \\ [])`
- **Bulk Job Actions**:
  - `bulk_retry_jobs(repo, actor, job_ids, reason, opts \\ [])`
  - `bulk_cancel_jobs(repo, actor, job_ids, reason, opts \\ [])`
  - `bulk_discard_jobs(repo, actor, job_ids, reason, opts \\ [])`

### 2. Bulk Execution Semantics
Instead of returning just integer counts, the `bulk_*` functions should return a map: `%{successes: [job_id], failures: [{job_id, error}]}`. 
- This fulfills the "per-job result reporting" requirement far better for programmatic callers than flat integers.
- It iterates the list exactly as the UI does (one `Lifeline` call per job, no single mega-transaction).

### 3. Telemetry Metadata Threading
Update `Lifeline.preview_repair/4` and `Lifeline.execute_repair/5` to extract a `:telemetry_metadata` key from `opts`. 
- Thread this metadata map down to the telemetry execution points (`build_preview/3` / `apply_repair/6` respectively).
- The `Operator` module will automatically inject `telemetry_metadata: %{source: "api"}` into `opts` before delegating to `Lifeline`.
- This ensures compliance with "carries `source: "api"` metadata and remains within the frozen `@contract`".

### 4. Code Reuse
Both single and bulk operations in `Operator` will delegate to a private `do_repair(repo, actor, action, job_id, reason, opts)` that wraps the `preview_repair` + `execute_repair` two-step process in a single convenient call.
