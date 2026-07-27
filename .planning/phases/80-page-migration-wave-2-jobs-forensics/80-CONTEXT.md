# Phase 80: Page Migration Wave 2 — Jobs, Forensics - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Rebuild the existing Jobs and Forensics operator surfaces on the shared Phase 77–79 design-system contracts: `FilterBar`, `DataTable`, `DetailSurface`, `Timeline`, confirmation/result patterns, canonical URL state, page stories, visual regression, and accessibility coverage. Preserve the current operator capabilities and routes while making large job sets, redacted payloads, bulk mutations, and deep or incomplete evidence histories safe, comprehensible, responsive, and performant.

This is a coherence and quality phase, not a feature-expansion phase. It may replace unsafe or unbounded implementation details required to preserve existing behavior, but it does not add new job actions, evidence source types, causal analysis, saved searches, exports, or a new durable bulk-workflow product.

</domain>

<decisions>
## Implementation Decisions

### Product authority and cohesive operator journey

- **D-01:** Resolve conflicts in this order: `guides/brand-book.md`; current project, roadmap, requirements, and state; shipped Phase 77–79 contracts; then older prompt research. The current brand book supersedes visual or vocabulary advice embedded in older prompts.
- **D-02:** Both pages follow one operator journey: canonical URL-owned scope → bounded scan → selected read-only context → canonical full detail or diagnosis/current truth → one safe route or action → explicit freshness/completeness → technical chronology → exact mutation or audit evidence.
- **D-03:** Optimize for the operator JTBD, not backend topology. Operators choose human-recognizable scopes and actions; Ecto field names, provider metadata, raw atoms, selector precedence, preview tokens, plan hashes, and storage structure never become the interface.
- **D-04:** Jobs answers “Which jobs need review, what is true now, and what can I safely do?” Forensics answers “What is the supported diagnosis, what should I do next, and what evidence is retained?” Do not make either page impersonate the other.
- **D-05:** Keep current truth, historical evidence, provenance, and completeness as separate concepts. Chronological adjacency never implies cause, and the newest event never becomes a diagnosis merely because it is newest.
- **D-06:** Preserve existing routes and legal capabilities. Native Jobs remains authoritative; older bridge-first prompt advice is obsolete. Forensics remains read-only.
- **D-07:** Use the brand vocabulary consistently: “Jobs,” “Review job,” “Full job details,” “Forensics,” “Event log” for the forensic timeline, and “Audit log” for exhaustive audit evidence. Avoid synonyms that make one concept appear to be several.
- **D-08:** Every surface states its support boundary honestly. Empty, unavailable, partial, stale, interrupted, skipped, and failed are first-class states rather than variants of success.

### Jobs browse-to-detail

- **D-09:** Use a hybrid browse-to-review model. The Jobs list is the scan-and-select surface. An explicit `Review job` control opens a read-only adaptive `detail_surface/1`; `/jobs/:id` remains the canonical rich, mutation-capable page.
- **D-10:** Serialize quick review as the allowlisted `job=<id>` query parameter on the Jobs list URL. The parent LiveView owns parsing, authorization, loading, canonicalization, and presentation mapping; the detail component remains stateless.
- **D-11:** Opening the first quick review pushes a history entry. Switching from one reviewed row to another replaces that review entry. Closing replaces to the same filter/page URL without `job`, so browser Back naturally closes a review and deep links reload correctly.
- **D-12:** The quick review contains only: full job identity, current state, full worker identity, queue, attempt/max, the contextually relevant scheduled/attempted timestamp, a structurally redacted latest-error summary, recorded-output availability (not payload), enqueue redaction disclosure, and `Open full job details`.
- **D-13:** Arguments, metadata, recorded-output payloads, stacktraces, complete attempt history, audit history, and all mutations remain on `/jobs/:id`. Do not duplicate complex or mutation-heavy content inside an adaptive dialog/drawer.
- **D-14:** The full detail route carries only allowlisted Jobs list parameters and reconstructs a deterministic back link. Never accept or echo an opaque `return_to`.
- **D-15:** Order full detail for incident response: current state and support truth; legal actions; identity and timing; current error and attempts; arguments/metadata/output plus redaction evidence; then related authorized audit/forensic destinations.
- **D-16:** Mutations occur only on full detail through Lifeline and the shared confirmation contract. Retry uses warning/primary intent; cancel and discard use danger intent. Do not duplicate mutation entry points in quick review.
- **D-17:** Rows are not wholesale click targets. Use a named `Review job` control and a separately labeled checkbox. Mark the reviewed row with a non-color visual and programmatic selected/current state.
- **D-18:** On wide viewports the adaptive surface may present as a drawer; below the established Phase 78 breakpoint it uses the existing modal/full-screen behavior. Preserve correct focus entry, focus containment where modal, Escape/close behavior, focus return, and background inertness.
- **D-19:** Missing and unauthorized quick-review jobs use the same non-enumerating unavailable state. A stale `job` parameter canonicalizes safely without exposing whether the ID exists.

### Jobs filtering, counts, table hierarchy, and pagination

- **D-20:** State remains a required, URL-backed view selector with the seven current states: available, scheduled, executing, retryable, cancelled, discarded, and completed. It is not a removable filter chip.
- **D-21:** Use `filter_bar/1` in submit mode. Queue, Worker module, and Tags are primary fields. `Args contain` and `Meta contain` are advanced JSON-object fields.
- **D-22:** `phx-change` validates draft input and conditional UI only; it does not query. `Apply filters` atomically patches the canonical URL and loads results. Draft values and applied values remain visibly distinct.
- **D-23:** Preserve current filter semantics exactly: optional categories are ANDed; tags use Postgres array containment and require every listed tag; args and meta use JSON map containment. Do not import Oban Web’s qualifier grammar.
- **D-24:** Use explicit microcopy: “Separate tags with commas. Jobs must contain every listed tag.” For JSON fields: “Enter a JSON object. Filter values are stored in the URL; do not enter secrets.” Invalid JSON: “Enter a valid JSON object.”
- **D-25:** Keep invalid draft input visible with an inline field error. Invalid direct URLs canonicalize with `replace`, using safe defaults and a concise explanation rather than silently pretending the invalid filter applied.
- **D-26:** Applied filters render as human noun/value chips with individual removal and `Clear filters`. Removing or clearing filters preserves the state view but resets page, selected review, row selection, and any pending confirmation.
- **D-27:** State or applied-filter changes reset page, selected review, selected jobs, frozen bulk scope, preview, and stale results. Ordinary pagination preserves explicit row selections across pages.
- **D-28:** The table columns are: Selection, Worker, State, Queue, Scheduled, Attempts, Job ID, and Review job. Do not add tags, args, metadata, payloads, or ornamental columns.
- **D-29:** Keep fixed `scheduled_at DESC, id DESC` ordering and the existing 20-row offset page contract. User sorting, cursors, and a changed URL protocol are out of scope.
- **D-30:** Render the full worker value in the DOM and allow safe visual truncation/wrapping without reducing it to an ambiguous module tail. Machine values may use the brand’s restrained monospace treatment; ordinary labels and prose do not.
- **D-31:** Show exact, state-aware summaries such as “143 retryable jobs” and “Showing 21–40 of 143.” Use the exact count to disable `Next`, including the full-size final-page boundary case.
- **D-32:** Replace seven count round trips with one grouped Ecto query over the same non-state filters, then merge the result into the fixed seven-state zero map. Query contexts own Ecto; no query or material transformation runs during HEEx rendering.
- **D-33:** At 320px and 200% zoom, preserve the semantic table data as stacked rows with Worker, State, and Job ID first. Keep checkbox labels such as `Select job 123`, 44px targets, visible focus, and no page-level horizontal scrolling.
- **D-34:** Use native table/list semantics, not an ARIA grid. Keyboard behavior remains conventional browser behavior; do not invent spreadsheet interactions.
- **D-35:** Preserve the existing tags index guidance. Do not promise low-latency tag filtering without the host-owned GIN index already documented by `ObanPowertools.Jobs`.

### Bulk selection and frozen scope

- **D-36:** Support the two existing operator scopes: explicitly selected jobs across pages and all jobs matching the currently applied filters. The interface always names which scope is active.
- **D-37:** Page selection means exactly the IDs on that page. After every eligible page row is selected, a banner may offer `Select all N jobs matching these filters`; it never silently broadens scope.
- **D-38:** Replace `global_select` as execution authority. All-matching selection freezes a server-owned, stable ordered ID list, applied-filter identity, exact count, and observation timestamp before confirmation. Execute only that frozen membership; never rerun or expand the selection query at execution time.
- **D-39:** Add one validated host configuration for bulk target limit: default 100, maximum accepted override 1000. Resolve it centrally through runtime configuration. A value outside the valid range fails configuration clearly rather than weakening the bound.
- **D-40:** Detect an oversized scope with a bounded `limit + 1` ID query (the exact UI count is already available). Do not load an unbounded ID list and do not silently act on the first N. Explain that filters must be narrowed.
- **D-41:** Before confirmation, authorize the page, action, and every target, then run the real Lifeline preview for each frozen job. Classify targets as ready or excluded with a safe reason. Browser disabled state is never authorization.
- **D-42:** Preview tokens, raw authorization detail, plan hashes, and internal errors remain server-side. The presentation model contains only the frozen identity, counts, safe eligibility reason, action consequence, reversibility/support statement, and authorized destinations.
- **D-43:** Confirmation shows selected, ready, excluded, and off-page counts; the exact frozen scope and observation time; what the action changes; its reversibility/support boundary; and that execution is non-atomic.
- **D-44:** Require a trimmed operator reason of at least eight characters and typed confirmation of the exact ready count. If zero targets are ready, execution is unavailable. Count drift or preview drift requires a fresh preview.
- **D-45:** Execute independent Lifeline operations per target. Do not create one all-or-nothing `Ecto.Multi`, and do not call Oban mutation APIs directly from the LiveView or bulk coordinator.
- **D-46:** Do not run the sequential batch inside `handle_event`. Use a library-owned `Task.Supervisor` under the application supervisor and a nonlinked supervised task, with bounded concurrency 4 and a per-target timeout. The LiveView receives low-cardinality progress messages; HEEx only renders assigned presentation state.
- **D-47:** Browser disconnect does not cancel already started work. A node/application restart may interrupt unfinished targets because this phase adds no durable run ledger. Completed Lifeline actions and audit records remain authoritative; copy and recovery guidance must say this plainly.
- **D-48:** Progress is real processed/total progress from completed target attempts, not animation. Keep the target-result order stable even when execution is concurrent.
- **D-49:** Model results as success, skipped, and failed. Never render `inspect(error)` or collapse skipped into success. Map known failures to safe operator language and authorized job/audit links.
- **D-50:** All-success may close after an exact receipt confirms the same frozen scope and count. Partial, skipped, failed, interrupted, or drifted results stay open with a summary and bounded/paged per-job result rows.
- **D-51:** After partial completion, clear successful IDs from selection and retain unresolved/skipped/failed IDs for recovery. Any subsequent attempt performs fresh authorization and preview; there is no silent retry.
- **D-52:** The current connection may show live progress and results, but Audit is the recovery authority after reconnect or process loss. Do not imply durable resumability without a durable run record.

### Forensics scope and investigation narrative

- **D-53:** Keep Forensics a read-only full page. Do not put the whole investigation in `DetailSurface`, tabs, a two-scroll-pane explorer, or an event-first wall.
- **D-54:** Use this page order: page title plus read-only support truth; typed scope `FilterBar`; `Investigation summary`; `What to do next`; optional neutral `Latest remediation evidence`; `Event log`; then combined `Evidence limits and sources`.
- **D-55:** `Investigation summary` identifies the human subject and ownership, states the supported current diagnosis/detail, names provenance, and gives compact coverage. It does not repeat the selector or dump the evidence bundle structure.
- **D-56:** `What to do next` presents one primary Powertools-native legal route with its prerequisite/caution. Additional safe guidance belongs under `Review all guidance` progressive disclosure. It is guidance, not a new mutation surface.
- **D-57:** Show `Latest remediation evidence` only when Lifeline supplies genuine historical repair evidence. Label it as historical; it does not overwrite current diagnosis.
- **D-58:** Present four human evidence types: Workflow, Lifeline incident, Cron entry, and Limiter. Conditional fields are Workflow ID plus optional Step; Incident fingerprint plus optional Incident view; Cron entry ID; or Limiter ID.
- **D-59:** Preserve exactly the existing six canonical URL keys: `resource_type`, `resource_id`, `workflow_id`, `step`, `incident_fingerprint`, and `view`. Workflow and Lifeline may retain legitimate authorized resource context; Cron and Limiter use the existing resource pair. Do not expose raw key names in labels.
- **D-60:** Use submit-mode selection. Draft change validates and reveals the correct conditional fields; `Inspect evidence` patches the canonical URL. Bare `/forensics` is a genuine empty chooser: “Choose evidence to inspect.”
- **D-61:** Reject mixed or conflicting direct scopes rather than applying hidden precedence. Canonicalize with `replace` to the empty chooser and explain that one evidence type must be selected. A well-formed missing or unauthorized scope returns the same `Evidence unavailable` state.
- **D-62:** Do not add global search, typeahead, saved investigations, or inferred selector guessing. Operators arrive with an identifier from a supported Powertools surface or operational handoff.
- **D-63:** Render the shared `timeline/1` component under the `Event log` heading, newest retained evidence first. Each entry contains absolute time, a grammatical event sentence, human source/provenance, human status, structurally redacted notes, and only authorized follow-ups.
- **D-64:** Keep status/severity, provenance, and completeness independent. Provenance examples are durable, supporting, bridge-only, or missing; completeness examples are complete, partial, history unavailable, or unknown.
- **D-65:** Forensics is a curated evidence bundle, not an exhaustive Audit replica. Bound and disclose the newest retained window per source, show `showing N of M` where known, explain retention/source limits, and route to exhaustive scoped Audit evidence.
- **D-66:** Do not add a seventh timeline-pagination URL key in this phase. Deep histories remain bounded in Forensics and fully reachable through the existing scoped Audit page.
- **D-67:** Replace `Audit.list_all |> Enum.filter` with composable, stable, scoped Ecto queries plus bounded limit/count or has-more metadata. Workflow evidence uses authoritative workflow resource identity; incident evidence uses the authoritative incident scope. Measure and document any unindexed JSONB predicate rather than hiding it behind in-memory filtering.
- **D-68:** `Forensics` and `Audit` contexts own Ecto queries. `Selectors` owns canonical URLs. The parent LiveView treats `handle_params` as untrusted input and owns authorization/state. A pure `ControlPlanePresenter` path normalizes grammatical, redacted closed maps before components.
- **D-69:** Structurally redact audit reasons, continuity notes, runbook context, raw errors, stacktraces, and payload-like metadata before assigning render models. Secrets must not appear in visible DOM, hidden fields, attributes, copy payloads, logs, or telemetry.
- **D-70:** Remove obsolete phase-number copy, raw selector summaries, raw action/source atoms, duplicated completeness cards, and repeated paths. One fact has one authoritative presentation.
- **D-71:** Outbound actions use deterministic nouns: `Open workflow`, `Review incident in Lifeline`, `Open cron entry`, `Review limiter blockers`, and `View matching audit evidence`. Render them only when the destination is supported and authorized.
- **D-72:** Jobs links to Forensics only when a stable supported forensic scope exists. An arbitrary Oban job ID alone is not a forensic evidence bundle. Use browser Back and deterministic `Open…` links; do not manufacture `return_to`.

### Architecture, safety, reliability, and developer ergonomics

- **D-73:** Follow idiomatic Phoenix/LiveView boundaries: LiveViews coordinate URL state, async messages, authorization, Ecto context calls, selection, confirmation, and receipts; stateless function components render closed presentation maps.
- **D-74:** Follow idiomatic Ecto boundaries: reusable query composition lives in contexts, repositories are passed explicitly per the existing project convention, stable ordering is part of each query contract, and bounded queries are enforced server-side.
- **D-75:** Follow idiomatic OTP boundaries for work that outlives a socket: supervised nonlinked processes, explicit timeouts, bounded concurrency, stable messages, and honest restart semantics. Do not pretend a LiveView process is a durable job runner.
- **D-76:** Keep the library Phoenix-first and host-friendly: one optional bounded bulk-limit setting, no new runtime dependency, no host schema migration, no router surprise, and no requirement that Oban Web be installed.
- **D-77:** Authorization occurs at page/resource load and again immediately before preview/execute or outbound navigation. Results and unavailable states must not leak existence or policy detail.
- **D-78:** Use low-cardinality telemetry only: surface, action class, scope class, result class, and duration/count buckets. Never include job IDs, worker names, filters, reasons, payloads, selectors, incident fingerprints, or raw errors.
- **D-79:** Mutation receipts use exact, support-truth language. Oban/Lifeline operations are treated as independently committed and potentially at-least-once; UI copy never promises batch atomicity or exactly-once execution.
- **D-80:** No work that scales with thousands of jobs or deep timelines happens in render functions. Bound database reads, async work, result retention, and component input size; use page stories to prove adversarial behavior.

### UI/UX, accessibility, visual system, and verification

- **D-81:** Apply all design pillars together: clarity/information architecture, accessibility, privacy/security, performance/scalability, reliability/operational truth, responsive adaptability, visual consistency/theming, developer ergonomics/testability, and restrained observability.
- **D-82:** Follow the brand’s calm control-room direction: roughly 90% neutral surfaces; indigo for safe primary action and focus; semantic state color only with text/icon; no gradients, broad status fills, badge soup, nested-card walls, or decorative motion.
- **D-83:** Support light, dark, system, and high-contrast behavior with the existing semantic tokens. Hover must not move geometry or erase contrast; focus is always visible; reduced-motion preferences remove nonessential transitions.
- **D-84:** Use conventional semantic controls and 44px interactive targets. Every checkbox, dialog, error, progress update, disclosure, and close action has a durable accessible name and predictable focus behavior.
- **D-85:** Use restrained live regions: filter validation is associated with fields; bulk start/final result is announced once; per-target progress does not flood assistive technology. Progress has text, not color alone.
- **D-86:** Create deterministic page stories for empty, one, many, and thousands of jobs; exact-full last page; invalid JSON; long/unicode/RTL identifiers; redacted args/meta/output/errors; explicit and all-matching selection; oversized, zero-ready, all-success, partial, skipped, failed, drifted, disconnected, and interrupted bulk runs.
- **D-87:** Create Forensics stories for empty chooser; each evidence type; missing/unauthorized; conflicting direct parameters; complete, partial, unknown, and history-unavailable evidence; deep bounded timelines; long URLs/notes; redaction; duplicate destinations; and permission-restricted follow-ups.
- **D-88:** Verification covers exact query/filter semantics, canonical URL replacement, browser history, Back/close behavior, selection reset/persistence rules, authorization races, frozen membership, execution bounds/timeouts, stable result order, redaction absence in rendered HTML, query counts/bounds, 320px and 200% zoom, keyboard/focus, axe, ARIA snapshots, all themes, and VRT.

### Claude's Discretion

The user delegated the unresolved choices. The decisions above are therefore the implementation contract. Planners retain discretion only over private function/module names, exact CSS composition using existing tokens, the precise bounded event/result page size, and whether closely related query helpers share a private base query—provided all observable behavior, bounds, URL contracts, safety semantics, vocabulary, and verification requirements above remain intact.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product, scope, and current authority

- `.planning/PROJECT.md` — Product vision, operator trust model, library boundaries, and quality bar.
- `.planning/ROADMAP.md` — Phase 80 goal, requirements, and explicit migration success criteria.
- `.planning/REQUIREMENTS.md` — PAGE-02, PAGE-09, PAGE-10, FORM-03, DATA, and accessibility requirements.
- `.planning/STATE.md` — Current milestone state, accumulated decisions, and sequencing.
- `guides/brand-book.md` — Current visual, vocabulary, density, color, theming, accessibility, and control-room brand authority.

### Project research corpus

- `prompts/oban-powertools-deep-research-original-prompt.md` — Original ecosystem, product, operator, and architectural research questions; use only where consistent with current product authority.
- `prompts/oban_powertools_context.md` — Historical product/domain context and cross-library comparisons.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — Operator personas, JTBD, control-room information architecture, and UI strategy; current brand book wins on conflicts.

### Shared design-system and page contracts

- `.planning/phases/77-data-display-operator-patterns/77-CONTEXT.md` — Shared data-display and operator-pattern decisions.
- `.planning/phases/77-data-display-operator-patterns/77-PATTERNS.md` — Component semantics, presentation contracts, and usage guidance.
- `.planning/phases/77-data-display-operator-patterns/77-UI-SPEC.md` — Responsive, visual, state, and accessibility contract for data/operator patterns.
- `.planning/phases/77-data-display-operator-patterns/77-SECURITY.md` — Redaction, confirmation, authorization, and component-boundary threats.
- `.planning/phases/78-component-groups-meta-components/78-CONTEXT.md` — FilterBar, DetailSurface, confirmation, explanation, and grouped-component decisions.
- `.planning/phases/78-component-groups-meta-components/78-PATTERNS.md` — Correct component composition and state ownership.
- `.planning/phases/78-component-groups-meta-components/78-UI-SPEC.md` — Adaptive detail, filter, confirmation, results, and accessibility behaviors.
- `.planning/phases/78-component-groups-meta-components/78-SECURITY.md` — Confirmation drift, secret handling, return navigation, and authorization controls.
- `.planning/phases/79-page-migration-wave-1-overview-cron-limiters-audit/79-CONTEXT.md` — Page-level URL, filter, selection, current/history, receipt, and copy precedents.
- `.planning/phases/79-page-migration-wave-1-overview-cron-limiters-audit/79-PATTERNS.md` — Shipped page composition patterns to reuse rather than fork.
- `.planning/phases/79-page-migration-wave-1-overview-cron-limiters-audit/79-UI-SPEC.md` — Page-level responsive and interaction contract.
- `.planning/phases/79-page-migration-wave-1-overview-cron-limiters-audit/79-SECURITY.md` — Page authorization, redaction, URL, mutation, and audit evidence safeguards.
- `.planning/phases/79-page-migration-wave-1-overview-cron-limiters-audit/79-VERIFICATION.md` — Current page-story, browser, VRT, a11y, and acceptance verification conventions.

### Harness and quality gates

- `.planning/phases/73-visual-regression-a11y-harness/73-CONTEXT.md` — Visual/a11y harness scope and invariants.
- `.planning/phases/73-visual-regression-a11y-harness/73-PATTERNS.md` — Deterministic story and screenshot patterns.
- `.planning/phases/73-visual-regression-a11y-harness/73-VALIDATION.md` — Required automated validation approach.
- `guides/visual-regression-and-a11y.md` — Maintainer workflow for page stories, VRT, axe, themes, and viewports.

### Jobs implementation

- `lib/oban_powertools/web/jobs_live.ex` — Current Jobs routes, URL parsing, filters, detail page, selection, bulk workflow, and unsafe sequential/unbounded implementation to replace.
- `lib/oban_powertools/jobs.ex` — Single Ecto query owner, current filter semantics, stable ordering, counts, pagination, and host GIN-index guidance.
- `lib/oban_powertools/lifeline.ex` — Sole supported preview/execute mutation path and receipt/audit semantics.
- `lib/oban_powertools/audit.ex` — Durable mutation evidence and post-disconnect recovery authority.
- `lib/oban_powertools/runtime_config.ex` — Central validated host configuration and display-policy boundary.
- `test/oban_powertools/web/live/jobs_live_test.exs` — Existing Jobs behavior and regression coverage.

### Forensics implementation

- `lib/oban_powertools/web/forensics_live.ex` — Current selector precedence, card-wall rendering, and page integration to migrate.
- `lib/oban_powertools/forensics.ex` — Evidence assembly, runbook/continuity projection, and current in-memory audit filtering to replace.
- `lib/oban_powertools/forensics/evidence_bundle.ex` — Evidence bundle shape, sources, completeness, and provenance.
- `lib/oban_powertools/forensics/chronology.ex` — Current chronology normalization and ordering.
- `lib/oban_powertools/forensics/runbook_entry.ex` — Supported guidance/destination model.
- `lib/oban_powertools/forensics/provenance.ex` — Provenance vocabulary and support boundary.
- `lib/oban_powertools/web/selectors.ex` — Canonical route and six-key selector ownership.
- `lib/oban_powertools/web/control_plane_presenter.ex` — Pure, grammatical, redaction-safe presentation boundary.
- `test/oban_powertools/web/live/forensics_live_test.exs` — Existing LiveView behavior and URL/security regression coverage.
- `test/oban_powertools/forensics_test.exs` — Evidence assembly and source behavior.
- `test/oban_powertools/forensics/evidence_bundle_test.exs` — Bundle completeness/provenance contract.

### Reusable components and adversarial fixtures

- `lib/oban_powertools/web/components/operator_patterns.ex` — `filter_bar/1`, `detail_surface/1`, confirmation, results, attention, and explanation patterns.
- `lib/oban_powertools/web/components/data_display.ex` — `data_table/1`, `timeline/1`, status, code/payload, and explicit state rendering.
- `lib/oban_powertools/web/components/forms.ex` — Typed inputs, validation wiring, labels, help, and error semantics.
- `lib/oban_powertools/web/components/primitives.ex` — Button, dialog, disclosure, feedback, and foundational interaction contracts.
- `lib/oban_powertools/web/components/app_shell.ex` — Page shell, navigation, support truth, and responsive layout.
- `test/oban_powertools/web/components/operator_patterns_test.exs` — Grouped-component behavior and safety tests.
- `test/oban_powertools/web/components/data_display_test.exs` — DataTable/Timeline semantics and adversarial data coverage.
- `test/support/page_story_catalog.ex` — Deterministic page-level story registry and Phase 80 fixture integration.
- `test/oban_powertools/page_story_catalog_test.exs` — Story-catalog contract and required coverage.
- `scripts/showcase_manifest.exs` — Browser manifest generation and fixture metadata.
- `test/browser/specs/page.acceptance.spec.ts` — Page-level browser acceptance conventions.
- `test/browser/specs/showcase.vrt.spec.ts` — Visual regression matrix.
- `test/browser/specs/showcase.a11y.spec.ts` — Automated accessibility matrix.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `OperatorPatterns.filter_bar/1`: Already has submit-mode, applied-state, validation, and responsive behavior required by both pages.
- `OperatorPatterns.detail_surface/1`: Provides the Phase 78 adaptive drawer/modal/full-screen behavior for read-only job review.
- `OperatorPatterns.confirm_action_dialog/1`: Provides exact count, reason, pending, drifted, and partial-result states; extend its presentation input rather than building raw modal markup.
- `DataDisplay.data_table/1`: Provides dense semantic tables and the existing 320px stacked-row contract.
- `DataDisplay.timeline/1`: Provides the retained event-log chronology primitive; Forensics supplies normalized evidence items.
- `ControlPlanePresenter`: Is the correct pure boundary for human sentences, status/provenance/completeness vocabulary, redaction, and closed component maps.
- `Selectors`: Already owns canonical paths and should become the only place that reconstructs list/detail/Forensics/Audit destinations.
- `DisplayPolicy` and `RuntimeConfig`: Already separate host policy/configuration from library behavior; reuse them instead of introducing per-page callbacks.
- Lifeline preview/execute and Audit: Already provide supported mutation safety and durable evidence. Bulk orchestration composes them per target.

### Established Patterns

- Parent LiveViews own stateful concerns; function components remain stateless and receive presentation data.
- Ecto contexts own all queries and accept the repo explicitly; LiveViews never query `oban_jobs` or Audit storage directly.
- Applied URL state is authoritative; draft filter state is not. Direct invalid URLs canonicalize with `replace`.
- Current diagnosis is distinct from history, provenance, and completeness. Redaction occurs structurally before rendering.
- Complex mutation-capable detail remains a full page; an adaptive surface is for bounded review.
- Bulk operations freeze scope, preview against current truth, execute independently, and preserve partial results.
- Visual state is encoded with text/icon/structure as well as color. Machine values alone receive monospace styling.

### Integration Points

- `JobsLive.handle_params/3` gains canonical quick-review selection, submit-mode filters, exact page/count state, and deterministic detail back context.
- `Jobs` gains a reusable non-state base query, grouped state counts, and bounded stable ID-scope retrieval.
- The application supervision tree gains the library-owned task supervisor used for nonlinked bulk execution; LiveView receives progress without owning task lifetime.
- `JobsLive` replaces raw table, raw modals, `global_select`, unbounded `list_ids`, and sequential Lifeline loops with shared patterns and frozen presentation state.
- `ForensicsLive.handle_params/3` gains typed scope parsing/canonicalization and renders one diagnosis-first page.
- `Forensics`/`Audit` gain scoped bounded queries and coverage metadata; `ControlPlanePresenter` receives normalized facts rather than schemas/raw maps.
- `PageStoryCatalog`, showcase manifest, browser acceptance, VRT, a11y, and ARIA snapshot coverage gain deterministic Phase 80 stories.

</code_context>

<specifics>
## Specific Ideas

### External research translated into project decisions

- Oban Web demonstrates that all-filtered selection is valuable, while its documented 1000-job bulk ceiling reinforces that a control-plane bulk action needs an explicit server-side bound. Phase 80 uses a safer default of 100 with an absolute 1000 override cap and never silently truncates. See [Oban Web Filtering](https://hexdocs.pm/oban_web/2.11.0/filtering.html).
- Oban Web’s resolver customization is provider-oriented. Powertools should keep host integration at its existing explicit policy/config/query boundaries instead of exposing provider resolver concepts in operator UI. See [Oban Web Resolver](https://hexdocs.pm/oban_web/Oban.Web.Resolver.html).
- Phoenix LiveView’s `handle_params/3`, live navigation, and process model support canonical URL-owned filters/review, but socket ownership is not durable work ownership. Bulk execution therefore uses supervised nonlinked OTP work and treats Audit as recovery evidence. See [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html).
- Ecto’s query composition is the idiomatic replacement for `Audit.list_all |> Enum.filter`; an all-or-nothing `Ecto.Multi` is intentionally not used across independently actionable jobs. See [Ecto.Multi](https://hexdocs.pm/ecto/Ecto.Multi.html).
- WAI-ARIA’s modal-dialog guidance reinforces the existing adaptive-detail focus contract: meaningful initial focus, contained modal focus, Escape/close behavior, and return focus. See [WAI-ARIA APG Modal Dialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/).
- PatternFly and Carbon both treat bulk selection as explicit scope plus a persistent selection summary, and keep dense operational tables conventional rather than turning every row into a custom control. Phase 80 adopts those lessons within the existing design system. See [PatternFly Toolbar](https://www.patternfly.org/components/toolbar/design-guidelines/) and [Carbon Data Table](https://carbondesignsystem.com/components/data-table/usage/).
- Kubernetes Events’ best-effort/retention limits are the right cautionary precedent for Forensics: a curated event view must disclose source and retention limits rather than claim exhaustive history. See [Kubernetes Event API](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/).
- Successful job dashboards such as Oban Web, Mission Control Jobs, GoodJob, and Sidekiq keep browse/filter/detail fast and familiar; their recurring footguns are provider-shaped filters, dangerously broad bulk scope, raw payload exposure, and ambiguous “all” selection. Powertools keeps the useful conventions while making URL scope, redaction, preview evidence, and partial results explicit.

### Copy and interaction anchors

- Jobs range: `143 retryable jobs` and `Showing 21–40 of 143`.
- Oversized bulk scope: `This action is limited to 100 jobs. Narrow the applied filters before continuing.`
- Frozen scope: `This selection was captured at 17:42:11 UTC. New matching jobs will not be included.`
- Non-atomic confirmation: `Each job is processed independently. Some actions may succeed while others are skipped or fail.`
- Restart truth: `Closing this page will not stop work already started. A service restart may interrupt unfinished jobs; completed actions remain in the Audit log.`
- Forensics empty state: `Choose evidence to inspect.`
- Unavailable state: `Evidence unavailable. It may not exist, may no longer be retained, or you may not have access.`
- Coverage: `Showing the newest 50 of 327 retained events. View matching audit evidence for the full scoped record.`

</specifics>

<deferred>
## Deferred Ideas

- Replacing `/jobs/:id` entirely with a drawer, or adding mutations to quick review.
- Saved Jobs filters, an Oban-style qualifier DSL, additional filter dimensions, or global Forensics search.
- User-configurable Jobs sorting, keyset/cursor URL migration, or a changed pagination protocol.
- A durable, resumable bulk-run ledger/schema, cross-node run recovery, retry-failed-only action, or result export.
- Saved forensic investigations, timeline filtering, live tailing, infinite scroll, or a seventh timeline-pagination URL key.
- New forensic source types, charts, causal/root-cause inference, evidence encryption, or a new evidence persistence schema.
- New job actions, mutation semantics, bridge dependencies, or provider-specific UI.
- A Jobs→Forensics route for arbitrary job IDs without an existing supported evidence scope.

</deferred>

---

*Phase: 80-Page Migration Wave 2 — Jobs, Forensics*
*Context gathered: 2026-07-27*
