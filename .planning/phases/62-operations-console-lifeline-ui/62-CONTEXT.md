# Phase 62: Operations Console & Lifeline UI - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the native `/ops/jobs/batches` LiveView operator surface for batch and chain inspection, with Lifeline-routed recovery for failed batch members and stuck or failed callbacks. This phase covers BUI-01 through BUI-04: batch progress/status visibility, explainable blocked states, failed-member bulk retry, and callback recovery visibility.

This phase does not add new batch or chain runtime semantics. Fixed-size batches, linear chains, the generalized callback outbox, and durable output handoff were locked in Phases 59-61.

</domain>

<spec_lock>
## UI Contract Locked

The Phase 62 UI contract is locked in `62-UI-SPEC.md`. It does not contain a numbered `## Requirements` list, but it does lock the visual, copy, layout, interaction, accessibility, and source-decision constraints for this phase.

Downstream agents MUST read `.planning/phases/62-operations-console-lifeline-ui/62-UI-SPEC.md` before planning or implementing.

**In scope from the UI contract:** native route and selector helper for `/ops/jobs/batches`; table-first batch index; URL-addressable batch detail; metrics, status tabs, URL-backed filters, page-local selection, failed member inspection, callback outbox inspection, chain context, blocked-state explanations, Lifeline preview/reason/execute flows, and audit/manual intervention evidence where available.

**Out of scope from the UI contract:** third-party UI registries, a marketing layout, decorative hero content, generic Oban Web replacement work, cross-page select-all, cancel/delete/prune/retention editing, new batch runtime semantics, dynamic/growable batches, nested batches, arbitrary DAGs, and direct Oban mutation paths.

</spec_lock>

<decisions>
## Implementation Decisions

### Page Shape and Navigation
- **D-01:** Use a URL-addressable batch detail route as the canonical detail pattern: `/ops/jobs/batches/:id`. Inline expansion may be used for compact previews, but it must not be the only way to inspect a batch. This matches `JobsLive`, supports shareable URLs, and gives forensics/audit/runbook handoffs a stable target.
- **D-02:** Add native router and selector support for batches. Extend `ObanPowertools.Web.Router` with `/batches` and `/batches/:id`, and extend `ObanPowertools.Web.Selectors` with `batches_path/1` and `batch_detail_path/1`.
- **D-03:** Keep the index table-first and operator-dense: metrics, status tabs, URL-backed filters, page-local selection, selected banner, table panel, empty/read-only/error states. Do not add realtime counts or cross-page select-all in this phase; those remain future requirements.

### Read Model and Query Boundary
- **D-04:** Add a dedicated read/query context for batches, analogous to `ObanPowertools.Jobs`. The LiveView should not own ad hoc cross-table queries. The read model should own list/detail queries, counts, filters, pagination, and the joins needed to inspect batch members, callbacks, chain metadata, and associated Oban jobs.
- **D-05:** Use the existing offset pagination style from `JobsLive` unless planning finds a concrete performance blocker. Preserve a single-function upgrade path to keyset pagination rather than designing a broader pagination abstraction now.
- **D-06:** Detail data should gather identity, progress counters, failed/discarded members, callback rows, chain step metadata, output dependency status, and manual intervention/audit evidence. Use display/redaction policy seams for job args/meta/error-like payloads instead of leaking raw internals by default.

### Recovery and Mutation Boundaries
- **D-07:** Failed batch member retry must route through the existing Lifeline job repair pipeline. Bulk retry runs independent per-job preview/execute attempts and reports successes, skips, and failures honestly. Do not call `Oban.retry_job` directly from the batches UI, and do not wrap N jobs in one all-or-nothing `Ecto.Multi`.
- **D-08:** Callback retry must become an explicit Lifeline repair target/action for callback outbox rows if the current Lifeline surface does not already support it. Preview must show event, dedupe key, attempts, last error, batch/chain context, before/after state, audit consequence, preview status, and preview token. Execute requires an acceptable reason and a ready preview, and must handle drift, expired previews, consumed previews, unauthorized actors, and per-row failure.
- **D-09:** Only offer callback recovery for visibly blocked or failed callback states, such as failed rows or claimed rows whose lease has expired. Do not offer retry for delivered callbacks or healthy pending callbacks. The UI must show the callback state before it offers execution.
- **D-10:** Native Powertools pages own audited mutations. Generic Oban job internals continue to deep-link to the optional `/ops/jobs/oban` bridge for inspection only.

### Blocked State Semantics
- **D-11:** Show blocked states in specific support-truth language, not as generic "running" or "attention" states. At minimum: `insert_failed`, `callback_failed`, unavailable or expired upstream output, executing-but-not-complete, exhausted with failed/discarded members, and completed.
- **D-12:** For `insert_failed`, surface failed chunk, inserted count, total count, stored failure kind/message, and failed timestamp from the batch insertion fields.
- **D-13:** For `callback_failed`, surface the failed callback event, dedupe key, attempts, last error, availability/claim/delivery timestamps, and whether retry is available.
- **D-14:** For output-unavailable or output-expired chain states, derive the explanation from chain metadata and callback failure evidence. Show upstream job id, step name/index/count, and the locked copy that the upstream output contract must be corrected before retry.

### Chain Presentation
- **D-15:** Chains appear as batch-backed rows with a `Chain` badge. Do not create a separate chain route, chain table, or chain-specific operator surface in this phase.
- **D-16:** Batch detail must show chain context when chain metadata is present: chain id/name when available, current or last known step, step index/count, upstream job id, next-step/output dependency state, and explicit output-unavailable copy.

### Auth, Read-Only, and Audit
- **D-17:** Add batch page/detail permissions and read-only copy to `ObanPowertools.Web.LiveAuth`. Use the same posture as existing native pages: pages remain inspectable when authorized for viewing, while preview/execute controls are disabled with adjacent helper copy when mutation permissions are missing.
- **D-18:** The read-only banner should use the copy locked in `62-UI-SPEC.md` once permission naming exists. Until then, keep copy consistent with the existing `LiveAuth.page_read_only_banner/1` style.
- **D-19:** Show manual intervention history by reusing existing Lifeline/Audit presentation or deep-link patterns where evidence exists. Do not invent audit rows or imply evidence that has not been written.

### Agent's Discretion
- The user approved creating context from the locked UI spec, prior phase decisions, and advisor-mode recommendations. Planning may resolve ordinary implementation details such as exact module names, helper function boundaries, query shapes, component extraction, and test file organization, as long as the decisions above and `62-UI-SPEC.md` remain intact.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope and Locked Phase Context
- `.planning/ROADMAP.md` - Phase 62 goal and success criteria for `/ops/jobs/batches`, failed-member retry, and callback unblocking.
- `.planning/REQUIREMENTS.md` - BUI-01 through BUI-04 definitions plus deferred/out-of-scope constraints.
- `.planning/STATE.md` - Current focus and active context after UI-SPEC approval.
- `.planning/phases/62-operations-console-lifeline-ui/62-UI-SPEC.md` - Locked visual, copy, layout, interaction, accessibility, and source-decision contract for Phase 62.
- `.planning/phases/59-schemas-foundation/59-CONTEXT.md` - Dedicated batch tables, generalized callback outbox, explicit counters, and no separate chains table.
- `.planning/phases/60-execution-engine-tracker-hooks/60-CONTEXT.md` - Exactly-once progress tracking, callback enqueueing, `callback_failed` recovery posture, and Lifeline repair requirement.
- `.planning/phases/61-apis-batches-chains/61-CONTEXT.md` - Fixed-size batch API, linear chain API, durable output handoff, explicit output failure semantics, and Phase 62 UI implications.
- `.planning/phases/61-apis-batches-chains/61-VERIFICATION.md` - Verified implementation surfaces and data-flow trace for Phase 61 batch/chain APIs.

### Product and UI Strategy
- `prompts/oban_powertools_context.md` - Product posture, support-truth language, operator personas, clean-room constraints, and decision posture.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` - Hybrid Powertools native console plus optional Oban Web bridge strategy.

### Existing Native Web Surfaces
- `lib/oban_powertools/web/router.ex` - Host-owned `/ops/jobs` route tree and optional Oban Web bridge boundary.
- `lib/oban_powertools/web/selectors.ex` - Canonical URL selector helper pattern.
- `lib/oban_powertools/web/jobs_live.ex` - Native jobs list/detail, URL-backed filters, page-local selection, bulk preview modal, and Lifeline-routed job mutations.
- `lib/oban_powertools/web/lifeline_live.ex` - Rich preview/reason/execute flow, drift/expired/consumed handling, read-only behavior, and audit/forensics proximity.
- `lib/oban_powertools/web/live_auth.ex` - Authorization, read-only banners, mutation errors, permission messages, and audit consequence copy.
- `lib/oban_powertools/jobs.ex` - Read model boundary pattern for LiveView query ownership.

### Batch, Callback, and Chain Implementation Surfaces
- `lib/oban_powertools/batch.ex` - Batch schema, insert counters, insertion failure metadata, `insert_stream/2`, and fixed-size invariants.
- `lib/oban_powertools/batch_job.ex` - Batch member tracking and batch/job uniqueness.
- `lib/oban_powertools/batch/tracker.ex` - Exactly-once progress tracking, batch completion/exhaustion, callback insertion, and `callback_failed` marking.
- `lib/oban_powertools/callback.ex` - Generalized callback outbox schema, status fields, event vocabulary, dedupe key, attempts, lease, delivery, and last-error fields.
- `lib/oban_powertools/chain.ex` - Linear chain DSL, backing batch insert, metadata, output fetch API, and explicit output error semantics.
- `lib/oban_powertools/chain/progression.ex` - Chain callback claiming, next-job insertion, builder failures, failed callback marking, and lease retry behavior.
- `lib/oban_powertools/job_record.ex` - Durable recorded-output boundary for upstream output handoff.
- `lib/oban_powertools/display_policy.ex` - Display/redaction policy seam for operator-facing job data.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Web.JobsLive`: Reuse the URL-backed filter flow, state-tab pattern, page-local selection, selected banner, table-first index layout, pagination shape, job detail route pattern, and per-job Lifeline preview/execute posture.
- `ObanPowertools.Web.LifelineLive`: Reuse the stronger repair preview model: preview status badges, reason gating, disabled helper copy, drift/expired/consumed/unauthorized handling, audit consequence copy, and adjacent evidence links.
- `ObanPowertools.Web.Selectors`: Extend this rather than building paths inline.
- `ObanPowertools.Web.LiveAuth`: Extend permission/read-only copy for batch pages and callback/batch recovery controls.
- `ObanPowertools.Jobs`: Use as the model for a dedicated `Batches` read context that owns query construction outside LiveView.
- `ObanPowertools.Batch`, `BatchJob`, `Callback`, `Batch.Tracker`, `Chain`, and `Chain.Progression`: Existing schemas and runtime data provide the batch, member, callback, chain, and output-state evidence the UI must expose.

### Established Patterns
- Host applications own the outer `/ops/jobs` scope; Powertools owns only native pages under that shell.
- Native Powertools pages own audited mutations; the optional Oban Web bridge is inspection-only for this boundary.
- LiveViews use Tailwind utility classes directly, dense table-first layouts, small status badges, and compact modal/detail panels.
- List filters are serialized into URL query parameters via `push_patch` and selector helpers.
- Selection is page-local and cleared when status/filter context changes.
- Lifeline preview, reason, execute, preview token, drift handling, and audit evidence are mandatory for mutations.
- Read-only mode keeps evidence visible and disables mutation controls with explicit helper copy.

### Integration Points
- Router: add `/batches` and `/batches/:id` inside `oban_powertools_routes/1`.
- Selectors: add canonical batch index/detail path helpers.
- Auth: add batch view/mutation permission copy and read-only banner support.
- Read model: add batch list/detail query ownership for metrics, filters, members, callbacks, and chain metadata.
- Lifeline: add or reuse bounded repair targets for failed job retry and callback retry.
- Tests: cover router/selectors, LiveView index/detail rendering, URL filter patches, read-only behavior, selection reset, Lifeline preview/execute gating, callback retry states, blocked-state copy, and failure/empty/load-error states.

</code_context>

<specifics>
## Specific Ideas

- Treat `JobsLive` as the structural skeleton for the batch index/detail pair, but use `LifelineLive` as the behavioral standard for preview execution and error handling.
- Prefer the UI-SPEC's URL-addressable detail route over inline-only expansion because batch/chain/callback evidence needs stable links for audit, forensics, support handoffs, and reloads.
- When data is insufficient to know whether a batch is blocked, say what is known from stored counters/callback rows rather than inventing state.
- Use `Chain` metadata and callback `last_error` to explain output handoff failures; do not hide output failures behind a generic callback badge.

</specifics>

<deferred>
## Deferred Ideas

- Realtime/live counts (`QRY-06`) remain deferred.
- Cross-page select-all (`QRY-08`) remains deferred.
- Args/meta filtering (`QRY-05`), Lifeline-to-job deep-link polish (`QRY-07`), and programmatic job query API (`API-03`) remain future work.
- Dynamic/growable batches, nested batches, chunking, arbitrary DAGs, and external dependencies remain out of scope for this milestone.

</deferred>

---

*Phase: 62-Operations Console & Lifeline UI*
*Context gathered: 2026-06-14*
