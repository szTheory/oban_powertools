# Phase 45: Bulk Operations - Research

## Objective
Investigate how to implement bulk selection and execution of job actions (retry, cancel, discard) in the `JobsLive` list view, honoring the Lifeline constraint that each action must be individually previewed and executed.

## Investigation Areas

### 1. Checkbox State Management in LiveView
**Question:** How should we track the selected jobs across the LiveView lifecycle?
**Findings:**
- We can add a `selected_jobs` assign initialized as `MapSet.new()`.
- The checkbox inputs can use `phx-click="toggle_job"` with `phx-value-id={job.id}` to update the MapSet.
- A "Select All" checkbox in the table header can use `phx-click="toggle_all"` to add all currently visible job IDs to the MapSet (or clear them if all are currently selected).
- When a filter (state, queue, worker, tags) changes, we should clear the `selected_jobs` MapSet to prevent operators from acting on jobs they can no longer see. Pagination can optionally preserve the selection.

### 2. Bulk Action Bar Placement and Visibility
**Question:** Where should the bulk action buttons appear?
**Findings:**
- The action buttons should appear above the list, perhaps replacing the standard text or appearing as a sticky banner when `MapSet.size(selected_jobs) > 0`.
- Only actions valid for the *current state* tab should be visible. (e.g., `job_retry` is only valid for `retryable`, `cancelled`, `discarded`, `completed`. `job_cancel` and `job_discard` for `available`, `scheduled`, `executing`, `retryable`).
- Because the list is filtered by state, all jobs in the current list share the same valid actions. This simplifies the bulk action bar rendering.

### 3. Execution Pipeline and Aggregation
**Question:** How do we orchestrate N individual `Lifeline.execute_repair` calls safely?
**Findings:**
- We cannot use an `Ecto.Multi` to wrap all `execute_repair` calls because `execute_repair` may do its own transaction management and the requirement dictates: "no single Ecto.Multi wraps all N jobs".
- The LiveView handler for `"execute_bulk"` should iterate over `selected_jobs`.
- For each job ID:
  1. Fetch the job to ensure it exists and we have the target data.
  2. Call `Lifeline.preview_repair` to generate a preview token.
  3. Call `Lifeline.execute_repair` with the token and reason.
- Collect the results into a summary (e.g., `%{successes: [...], errors: [...]}`).
- If the list of jobs is large (max 100), this iteration might block the LiveView process for a moment. Given the limit of 100, a sequential loop in the `handle_event` is acceptable and avoids complex async task management for this phase.
- The outcome should be presented. A multi-line flash message or a dedicated "results view" in the modal is best.

## Conclusion
The path is clear. We will implement MapSet-based selection, render a bulk action bar conditionally, and execute repairs sequentially in the LiveView handler, accumulating results for display.