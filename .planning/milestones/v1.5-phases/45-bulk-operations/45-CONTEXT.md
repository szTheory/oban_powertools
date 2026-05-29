# Phase 45: Bulk Operations - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver bulk actions (retry, cancel, discard) from the job list page (QRY-04), building upon the audited Lifeline pipeline established in Phase 44. This ensures bulk actions require a reason, provide a count-preview before committing, and execute individually rather than in a monolithic transaction to prevent partial failures from reverting the entire batch.

</domain>

<decisions>
## Implementation Decisions

### Selection State
- **D-01:** Selection state will be maintained in the `JobsLive` socket assigns as a `MapSet` of stringified `job.id`s. 
- **D-02:** Changing the state filter, queue, worker, or tag filter will clear the active selection to avoid confusing off-screen bulk actions. Pagination changes will *preserve* selection, allowing cross-page selection if desired.

### Bulk Action Modal and Execution
- **D-03:** The bulk action preview modal will mirror the single-action modal, displaying the count of selected jobs rather than a single Job ID.
- **D-04:** Each selected job must run its own independent `Lifeline.preview_repair` (to get a token) followed by `Lifeline.execute_repair`. 
- **D-05:** Results of the bulk execution will be aggregated (e.g., `%{"success" => 5, "error" => 2}`) and displayed to the user via a flash message or a results modal, fulfilling the "reported honestly, not collapsed" requirement.

</decisions>

<canonical_refs>
## Canonical References

### Roadmap and phase requirements
- `.planning/ROADMAP.md` — Phase 45 scope, dependencies, and success criteria.
- `.planning/phases/45-bulk-operations/45-UI-SPEC.md` — UI design contract for checkboxes and bulk action bar.

### Prior phase context
- `.planning/phases/44-single-job-actions/44-CONTEXT.md` — Single job actions context.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/oban_powertools/web/jobs_live.ex`: The primary UI file to modify. We will add a checkbox column to the table and a bulk action bar at the top or bottom of the list.
- `lib/oban_powertools/lifeline.ex`: The backend pipeline. It already handles retry, cancel, and discard natively. We will utilize it in a loop for the bulk operations.

</code_context>

---

*Phase: 45-bulk-operations*
*Context gathered: 2026-05-28*
