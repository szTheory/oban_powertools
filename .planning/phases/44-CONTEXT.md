# Phase 44: Single-Job Actions - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver single-job actions (retry, cancel, discard) from the job detail page (QRY-03), utilizing the full audited Lifeline pipeline. This ensures actions are previewed, require a reason, are protected against concurrent state modifications, and are durably audited before execution. No raw `Oban` mutations should occur in the UI layer.

</domain>

<decisions>
## Implementation Decisions

### Modal and UI Implementation
- **D-01:** The action preview modal must be implemented using inline HTML and Tailwind classes directly in `jobs_live.ex` (or a local private UI module) rather than relying on Phoenix `CoreComponents`. `oban_powertools` is a library and cannot assume the host application's `CoreComponents` will be unmodified or present.
- **D-02:** The reason string must be enforced via client-side UI validation (e.g. disabling the submit button when the reason input is blank) in addition to the strict backend validation in `Lifeline`.

### Lifeline Backend Support
- **D-03:** Explicit backend support for the `"job_discard"` action must be added to `Lifeline.ex`. This includes adding it to `@supported_actions`, supporting it in `build_job_preview/5`, determining the `next_job_state`, handling the mutation in `mutate_target/5`, and adding a `repair_summary`.
- **D-04:** Both `"job_cancel"` and `"job_discard"` are destructive actions that transition jobs to a terminal state (`"cancelled"` and `"discarded"` respectively).

### Concurrent Modification Guard
- **D-05:** Rely entirely on the native concurrent modification guard built into `Lifeline.execute_repair/4` via the `plan_hash` drift check. Do not implement a redundant optimistic locking or `updated_at` check in the LiveView layer. If the job state changes between preview and execution, `Lifeline` will return a natural error.

</decisions>

<canonical_refs>
## Canonical References

### Roadmap and phase requirements
- `.planning/ROADMAP.md` — Phase 44 scope, dependencies, and success criteria.
- `.planning/phases/44-UI-SPEC.md` — UI design contract for the action bar, modal structure, and copywriting.

### Prior phase context
- `.planning/phases/43-CONTEXT.md` — (if applicable) Read-only job browse context.
- `.planning/phases/4-CONTEXT.md` — Lifeline pipeline context, outlining the preview/execute paradigm.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/oban_powertools/web/jobs_live.ex`: The primary UI file to modify, appending the action bar to the identity card header and adding the modal markup.
- `lib/oban_powertools/lifeline.ex`: The backend pipeline that securely previews and executes mutations. Ensure `"job_discard"` is integrated cleanly alongside `"job_cancel"`.

</code_context>

---

*Phase: 44-single-job-actions*
*Context gathered: 2026-05-28*
