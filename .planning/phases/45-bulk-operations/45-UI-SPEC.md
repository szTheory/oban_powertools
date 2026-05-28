# Phase 45: Bulk Operations - UI Spec

## Visual Design Contract

### Checkbox Column
- Add a new `<th>` and `<td>` column as the first column in the job list table.
- The `<th>` contains a "Select All" checkbox.
  - Checked state: If `length(@jobs) > 0` and all currently rendered jobs are in `selected_jobs`.
  - Event: `phx-click="toggle_all"`
- The `<td>` contains an individual job checkbox.
  - Checked state: If `job.id` is in `selected_jobs`.
  - Event: `phx-click="toggle_job"` `phx-value-id={job.id}`

### Bulk Action Bar
- A sticky or inline bar rendered above the table (or replacing the title area) when `MapSet.size(@selected_jobs) > 0`.
- Displays text: `<count> jobs selected`.
- Conditionally displays the action buttons based on the current `@filter.state`.
  - **Retry:** Visible for `retryable`, `cancelled`, `discarded`, `completed`. Classes: `bg-white text-indigo-600 border border-indigo-200 hover:bg-indigo-50`
  - **Cancel:** Visible for `available`, `scheduled`, `executing`, `retryable`. Classes: `bg-white text-red-600 border border-red-200 hover:bg-red-50`
  - **Discard:** Visible for `available`, `scheduled`, `executing`, `retryable`. Classes: `bg-white text-red-600 border border-red-200 hover:bg-red-50`

### Bulk Action Modal
- Triggered by clicking a bulk action button (e.g. `phx-click="preview_bulk"` `phx-value-action="job_retry"`).
- Uses the same modal backdrop structure as the single-job action modal.
- Header: "Bulk Retry <count> Jobs"
- Body text: "You are about to retry <count> jobs. This will execute independent repairs for each job."
- Input: Reason text field (required).
- Actions: "Cancel" and "Confirm Bulk Retry" (disabled if reason is empty).
- Form submission triggers `phx-submit="execute_bulk"`.

### Execution Feedback
- After executing, a flash message displays: "Bulk action complete: <X> successes, <Y> failures."
- The `selected_jobs` MapSet is cleared.
- The job list is re-rendered to reflect the new state of the jobs (many may disappear from the current state view).
