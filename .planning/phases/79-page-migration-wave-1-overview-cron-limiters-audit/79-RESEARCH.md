# Phase 79 Research: Page Migration Wave 1 — Overview, Cron, Limiters, Audit

**Researched:** 2026-07-19  
**Scope:** Architecture and implementation research only  
**Confidence:** High for repository architecture and behavior; medium for the final browser-fixture count, which planning must lock before baseline generation

## Research Question

How should Overview, Cron, Limiters, and Audit migrate onto the Phase 76–78 shell and component contracts while preserving authorization, URL meaning, data truth, mutation safety, bridge ownership, and durable evidence—and what repository seams and verification architecture should the Phase 79 plan use?

## Executive Summary

Phase 79 is a presentation migration with two tightly bounded data-safety changes: Audit must move from an unbounded load to stable 20-row URL pagination, and page presenters must normalize/redact all data before it reaches shared components. It does not need a new application framework, stateful LiveComponents, new policies, new providers, new mutations, or a new data model.

The repository already has the correct structural foundation:

- `ThemeShell` places every page inside `AppShell`; the page modules should compose page content, not instantiate another shell.
- `Primitives`, `Forms`, `DataDisplay`, and `OperatorPatterns` contain the required surfaces, tables, status treatment, reason field, confirmation dialog, adaptive detail surface, attention card, blocker explanation, and audit entry.
- The four parent LiveViews already own the right orchestration responsibilities: authorization, URL state, repository reads, mutations, preview state, recovery, and navigation.
- `ControlPlanePresenter` is the preferred pure normalization seam. `ObanPowertools.DisplayPolicy`, currently defined in `lib/oban_powertools/runtime_config.ex`, is the redaction/display boundary.
- `OverviewReadModel`, `Cron`, `Explain`, `LimiterHistory`, and `Audit` remain the domain/query boundaries. Repository access must not move into `render/1` or shared components.

The principal implementation risk is not visual styling. It is accidentally changing operational truth while adapting current schemas into shared component maps. The plan should therefore make page presenters explicit, keep URL state canonical, preserve existing behavioral tests, and add focused RED tests for the new contracts before changing markup.

The four migrations have distinct postures:

| Page | Primary posture | Main shared composition | Repository change |
| --- | --- | --- | --- |
| Overview | Stable triage | `attention_card`, `metric_card`, neutral surfaces | Rename/reorder presentation buckets; retain three-item deterministic exemplar bound; replace any unbounded audit support read |
| Cron | Selection-first control | `data_table` + `detail_surface` + `confirm_action_dialog` | UI-only nonblank reason validation; preserve backend preview/execution contracts and double authorization |
| Limiters | Current diagnosis | `data_table` + `detail_surface` + `why_blocked` | Normalize current evidence separately from block-start snapshot/history; batch resource/state reads if practical |
| Audit | Bounded evidence review | `data_table` + `detail_surface` + `audit_entry` | Add exact count and stable 20-row paging ordered by `inserted_at DESC, id DESC` |

## Binding Constraints

The following are planning inputs, not choices to revisit:

- Decisions D-01 through D-45 in `79-CONTEXT.md` are locked.
- The phase fulfills PAGE-01, PAGE-05, PAGE-06, PAGE-08, PAGE-10, COPY-01, the A11Y requirements, and MOTION requirements without expanding control-plane capability.
- Overview, Limiters, and Audit remain read-only. Cron alone retains pause, resume, and run-now.
- The existing paths and query meanings remain compatible: Overview destinations, Cron `entry`, Limiters `resource`, and Audit `resource_type`, `resource_id`, and `event_type`. Audit adds composable `page` and `event` state.
- Parent LiveViews remain the stateful boundary. Shared components remain stateless function components receiving normalized presentation data.
- One semantic DOM must reflow at 320px and 200% zoom. No duplicated desktop/mobile trees, page-level horizontal scrolling, client-only authority, polling, or hidden secret-bearing DOM.
- Copy is operational evidence. Do not expose preview tokens, plan hashes, action atoms, raw event/query syntax, Ecto structs, raw metadata, source tables, ranks, stacktraces, or exceptions.
- Existing tests are behavioral contracts. Obsolete presentation strings may be updated, but authorization, URL, query, transaction, audit, ownership, and destination assertions must remain or become stricter.

No dependency change is indicated. No schema migration or new database index should be added speculatively. The requested bounded Audit query and deterministic tie-break work with the existing schema. If measured production-like query plans later prove an index necessary, that is a separately justified host migration because this library's install/upgrade surface makes migrations materially broader than a page migration.

## Requirement-to-Architecture Map

### PAGE-01: Shared shell and hierarchy

`lib/oban_powertools/web/theme_shell.ex` already wraps LiveViews with `AppShell`. Each page should render a single page-root region inside that shell, using a common page heading/intro pattern and token-owned composition classes. The migration must not wrap pages in a second `AppShell` or recreate shell navigation locally.

### PAGE-05: Overview migration

`EngineOverviewLive.render/1` should consume a normalized `OverviewReadModel.build/1` result in the fixed D-09 order. Counts, destinations, native/bridge ownership, and deterministic three-exemplar ranking remain authoritative. The equal-card grid is the piece being replaced, not the read model's domain inputs.

### PAGE-06: Cron migration

`CronLive.handle_params/3` remains the `?entry=` selection boundary. Existing preview and confirm handlers remain the mutation state machine. Markup moves row actions into selected detail and maps preview/recovery state into `confirm_action_dialog/1`; page-owned form validation enforces the stricter UI reason rule without changing `Cron`'s public `reason_required: false` compatibility value.

### PAGE-08: Limiters migration

`LimitersLive.handle_params/3` and selection loading remain authoritative. The page must distinguish live/current blockers, the historical snapshot captured at block start, and retained history. Only current normalized evidence is passed to `why_blocked/1`.

### PAGE-10: Audit migration

`AuditLive.handle_params/3` becomes the source of truth for filters, page, and selected event. `ObanPowertools.Audit` needs a stable bounded page/count API, while `ControlPlanePresenter` and `DisplayPolicy` produce safe row/detail maps. The page remains read-only.

### COPY-01 and truth requirements

Page-facing labels and exact absence strings should live in centralized pure presenter functions, not be independently reinvented in templates. Exact locked strings include `Resolved continuity`, `Review blockers`, the action-specific Cron labels, `Recorded at`, and Audit absence messages. Current/historical, native/bridge, status/severity, and completeness must remain independent dimensions.

### A11Y and MOTION requirements

The shipped components carry much of the semantic and focus machinery, but pages must supply correct labels, stable targets, logical fallbacks, and modal transitions. Page CSS must use `--obpt-*` tokens, existing motion tokens, and the existing reduced-motion override. Native tables remain tables; this phase must not create ARIA grids.

## Existing Architecture and Reusable Contracts

### Shell and page ownership

`lib/oban_powertools/web/theme_shell.ex` is the integration point for shell-wide layout. `AppShell` already owns navigation, actor context, theme, and the main landmark. Page code should own only the page header, page sections, table/detail/dialog composition, and page-specific orchestration.

The correct ownership line is:

```text
LiveView
  ├── authorize and load repository state
  ├── parse/build canonical URL state
  ├── normalize data through pure presenters/DisplayPolicy
  ├── own forms, selection, preview, recovery, receipts, focus targets
  └── render stateless shared components

Shared component
  ├── validate closed attributes
  ├── render semantics, state, and responsive behavior
  └── emit declared events/links
```

Do not introduce a LiveComponent merely to hold selection or dialog state. That would split URL and authorization ownership and contradict the shipped lifecycle contract.

### Data display APIs

`lib/oban_powertools/web/components/data_display.ex` provides the main scan/read surfaces:

- `data_table/1` accepts a stable `id`, caption, normalized rows, `row_id`, columns, action slot, explicit state, row count, and pagination summary. Its states already include ready, loading, empty, error, unavailable, and permission denied.
- `metric_card/1` is appropriate for compact runnable-capacity context, not incident emphasis.
- `description_list/1`, timestamps, empty states, toast/flash, and supporting evidence patterns should replace raw definition/table/card markup where the semantics fit.

Pages should pass plain maps and scalar display values. Raw Ecto schemas must stop at the LiveView/presenter boundary.

### Operator pattern APIs

`lib/oban_powertools/web/components/operator_patterns.ex` provides the required higher-order patterns:

- `confirm_action_dialog/1` has preview, submitting, partial, failed, expired, drifted, and consumed states, supports a parent-owned `to_form`, and already implements the Phase 78 recovery/focus contract.
- `detail_surface/1` supplies one adaptive dialog/inline detail tree with loading, empty, ready, unavailable, permission-denied, and error states plus a logical fallback target.
- `attention_card/1` requires an honest title, summary, impact, observed time, domain, status, severity, and completeness. It should not be fed synthetic incident facts merely to obtain the appearance.
- `why_blocked/1` consumes a normalized top-level explanation and blocker maps. Current normalization contains label, summary, clearing condition, evidence source, technical code, and evidence kind; D-28 additionally needs affected scope.
- `audit_entry/1` consumes a normalized immutable statement and safe evidence, not an `Audit` schema or metadata map.

Two narrow backward-compatible component/presenter refinements may be warranted:

1. Add optional `affected_scope` support to normalized blocker maps and `why_blocked/1`. Keep existing inputs valid and test the new field independently.
2. Ensure the audit detail visibly associates the absolute time with the label `Recorded at`. This may be done with a backward-compatible optional label in `audit_entry/1` or the containing normalized detail composition; do not fork a page-local audit component.

### Presentation and redaction boundary

`lib/oban_powertools/web/control_plane_presenter.ex` already normalizes filters, statuses, ownership, results, blockers, and audit data. It is the best home for pure page presentation functions as long as they remain cohesive. A narrowly named pure companion module is acceptable if the single module becomes incoherent; duplicating inline formatter functions in four LiveViews is not.

`ObanPowertools.DisplayPolicy` is defined in `lib/oban_powertools/runtime_config.ex`. It provides actor and reason display policy. One important Audit detail: its generic reason fallback is currently different from D-34. The Audit presenter should use the policy for a present value and explicitly emit `No operator reason recorded` when absent. It must not globally change a public fallback merely to satisfy one page unless all callers are audited.

URL construction should use the existing selector/path helpers and ordered parameter lists. Stable ordering is useful for exact URL tests and avoids parallel ad hoc `URI.encode_query/1` implementations.

## Recommended Cross-Page Architecture

All four LiveViews should converge on the same internal flow:

1. Parse canonical URL state in `handle_params/3`.
2. Authorize page/resource/action server-side.
3. Perform bounded repository work outside `render/1`.
4. Normalize schemas/domain structs into plain presentation maps.
5. Render shipped shared components from those maps.
6. Handle component events in the parent LiveView and patch canonical URLs.

The normalized assigns should be deterministic enough to power both LiveView tests and browser showcase fixtures. Prefer one production render path fed by either repository-built assigns or deterministic fixture assigns. Do not maintain a showcase-only HTML imitation of the production pages.

Page-specific CSS should be limited to layout composition—page stack, stable section order, two-to-one column reflow, action stacking, pagination alignment, long-value wrapping—and live in `assets/oban_powertools/tokens.css` under root-scoped selectors. Chrome, borders, buttons, statuses, forms, tables, dialog behavior, and detail treatment remain owned by shared components. Rebuild the checked-in static asset with `mix oban_powertools.assets.build` and prove source/static equality.

## Overview Findings

### Current behavior and seams

`lib/oban_powertools/web/overview_read_model.ex` is already the sole aggregation and ranking boundary. It queries resource state, explanations, cron entries, incidents, retention, and audit support data, then emits six buckets. `AttentionProjection` already gives deterministic within-bucket ordering and a three-exemplar bound.

`lib/oban_powertools/web/engine_overview_live.ex` currently renders raw equal-weight Tailwind-like cards, an implementation-shaped H1, generic historical-attention blocks, and the old `Resolved Recently` phrase. Those presentation choices are the migration target.

The current read-model order is effectively Needs Review, Blocked, Waiting, Runnable, Bridge, Resolved Recently. D-09 requires Needs Review, Blocked, Waiting, Bridge-only Follow-up, Runnable, Resolved continuity. The order should be made explicit in the read model/presenter and asserted by semantic IDs or headings rather than relying on map iteration.

### Recommended data/presentation mapping

- Capture one `now` value at the beginning of `OverviewReadModel.build/1`, preferably injectable through options for deterministic tests.
- Preserve `AttentionProjection` ranking and `Enum.take(3)` behavior. Do not sort in the template.
- Treat the first three buckets as a single `Current attention` region, ordered Needs Review, Blocked, Waiting. Nonzero bucket summaries may use `attention_card/1` only when every required fact is honest.
- Keep exemplars as direct bounded list rows with separators and explicit selector links. Do not nest an attention card per exemplar.
- Render Bridge-only Follow-up as a neutral handoff after current attention. The displayed number is only the number of representative follow-ups shown, not an all-time/global metric. Keep `Inspect in Oban Web` ownership explicit.
- Render Runnable with `metric_card/1` or a compact status summary, not an attention treatment.
- Render Resolved continuity last as neutral retained evidence. Rename helper labels and tests from `Resolved Recently`; no current cutoff supports the word “recently.”
- Use bucket-specific compact zero states with one relevant route. The all-quiet statement must say only that no current native or bridge follow-up was identified from available evidence.

`attention_card/1` requires an observed time and impact. Do not borrow an arbitrary exemplar timestamp and imply it describes the full aggregate. A truthful approach is to use the single read observation time as `observed_at` for an aggregate card and label it as a query observation, with completeness derived from known source availability. If that cannot be stated honestly for a bucket, use a neutral shared surface instead.

### Query and performance implications

The Overview exemplars are already bounded. Preserve that boundary and assert it. The notable outlier is support/audit retrieval through `Audit.list_all/2`; replace page support usage with a bounded latest matching query rather than loading the global table. Do not change domain counts or incident inputs merely to optimize markup.

### Overview regression focus

Extend `test/oban_powertools/web/live/engine_overview_live_test.exs` to retain route, selector encoding, count/source, ownership, and exemplar-bound assertions. Replace only obsolete visual language assertions. Add stable DOM-order, all-quiet, nonzero/long-content, no-live-region, and no raw implementation-token coverage.

## Cron Findings

### Current behavior and seams

`lib/oban_powertools/web/cron_live.ex` already owns:

- `?entry=` selection in `handle_params/3`;
- page and action authorization;
- preview creation and telemetry;
- confirm-time reauthorization with the current principal;
- durable preview expiry, drift, and consumption handling;
- mutation execution and repository reload.

`lib/oban_powertools/cron.ex` is authoritative for durable preview identity, expiry, plan hash, overlap handling, `Ecto.Multi`, and transactional Audit recording. Its public preview currently exposes `reason_required: false`; D-22 explicitly preserves that compatibility contract.

The current template is unsafe for the desired presentation because it places mutation controls in every row, includes an Actions column, shows raw preview/internal values, and uses generic confirmation controls. These are markup/presenter problems, not reasons to replace the state machine.

### Master/detail URL and focus model

Use `data_table/1` for entries. The name is an explicit patch link; the row is not clickable. The table has no Actions column. The selected entry renders through `detail_surface/1`, with schedule, current state, support/history truth, then visible action controls.

Selection/history behavior should be explicit:

- First selection pushes `?entry=name` so Back returns to the list.
- Switching between entries replaces the current selected URL.
- Explicit detail close replaces to the bare Cron list URL.
- Direct/reloaded selected URLs resolve the same state.
- A missing/invalid selection renders a safe unavailable detail or returns to the list; it must not raise through a forged event.

When an action opens, keep `?entry=` but stop rendering the detail surface so the page never has nested dialogs. Dismissal or a recoverable result sets the confirmation state aside and reopens selected detail. Focus returns to the originating selected-detail action, or to the selected row/name fallback if the state changed.

### Reason and confirmation state

Use one page-owned schemaless form, submitted as `confirmation[reason]`, with the shipped Forms reason field. Validate `String.trim(reason) != ""` before backend execution and revalidate in the server confirm handler. Preserve the safe draft on expired, drifted, consumed, skipped, partial, or failed results. Clear it on clean success or an intentional new action. Include the brand-book “do not enter secrets” help.

The form rule is intentionally stricter than the public Cron command API. Do not alter the backend preview's `reason_required: false`, add a global minimum length, or rely on client attributes alone.

Map each action to the exact D-20 labels and warning intent. Consequence copy must state both effect and non-effect. Never render the preview token, plan hash, raw action atom, internal risk/status, or durable command identifiers.

### Execution/result mapping

Authorization occurs before preview and again immediately before execution using the current principal. Existing backend drift/single-use checks remain concurrency authority; button disabling only prevents accidental duplicate browser submissions.

Run-now outcomes require careful wording. The domain may return results such as enqueued, allowed, cancelled previous, queued follow-up, skipped, or duplicate. None proves that a job ran. A skipped or duplicate result remains open and should map to a normalized partial/recovery result with a fresh-preview path. Queued/enqueued results may say that a manual slot claim/result was recorded, with the actual recorded result stated exactly.

On clean success:

- remove the confirmation dialog;
- reload repository truth;
- keep or logically restore the selected context;
- emit one dismissible exact receipt with an Audit destination;
- do not also emit a second generic flash for the same command.

Recent Audit evidence, if retained in selected detail, must use a bounded resource query. The current global `Audit.list_all/2` pattern should not survive the migration.

### Cron regression focus

`test/oban_powertools/web/live/cron_live_test.exs` already covers page/action authorization, durable mutations, telemetry, direct selected URLs, missing principals, expiry/drift/consumption, history, Forensics, and ownership. Preserve those behaviors. Replace assertions that intentionally expose preview tokens/raw state with negative confidentiality assertions and dialog semantics. Add whitespace-only reason rejection, current-principal reauthorization, row-action absence, action-specific labels, skipped/partial stays open, explicit fresh preview, one receipt, URL history, focus restore, and safe invalid selection.

## Limiters Findings

### Current behavior and seams

`lib/oban_powertools/web/limiters_live.ex` already owns `?resource=` selection, resource detail loading, Oban Web destinations, retained history, and Forensics permission checks. It currently renders a raw table and side panel.

The current resource list performs state lookup per resource, creating an N+1 shape. Phase 79 must at least avoid introducing a new N+1 in presenters/details; batching Resource and State rows into one indexed/associated read is a contained improvement if the domain query API supports it without changing meaning.

`Explain.explain_snapshot` and live/current evidence are not interchangeable. `LimiterHistory.summary` is bounded and suitable for retained-history facts, but it does not establish current cause.

### Current, snapshot, and history mapping

Use `data_table/1` with an explicit `Review blockers` action whose accessible name includes the resource. Selection opens `detail_surface/1` and preserves `?resource=` semantics.

The selected detail must render in this order:

1. Resource/current state and support truth.
2. Current blockers through `why_blocked/1`.
3. Snapshot at block start.
4. Retained history and completeness.
5. Runbook, Forensics, and Oban Web destinations.

Build the current-blocker presentation from current Resource/State/Explain facts only. Normalize known limiter blocker types, such as cooldown and limit reached, into:

- consumer label;
- plain summary;
- affected scope;
- clearing condition;
- evidence source;
- observed time;
- completeness/support state.

The existing `ControlPlanePresenter.normalize_blockers/1` should be extended backward-compatibly for optional affected scope. Technical codes may remain internal normalized data only if a shared component needs them for non-display classification; they must not become headlines.

If current evidence is complete and contains no blockers, say `Runnable`. If current evidence is stale, partial, unavailable, or permission denied, state that condition and do not say `No blockers`. The repository does not currently provide a product-approved generic stale threshold, so Phase 79 must not invent one from wall-clock age.

Render the block-start snapshot as explicitly historical, including capture time and completeness. Render retained history separately, with bounded facts and no timeline rail that implies causality. Do not merge either into `why_blocked/1`, call either “root cause,” or let a snapshot override current state.

### Support and authorization truth

`Open in Oban Web` is a generic bridge destination. `Open forensic timeline` appears only when server authorization allows it. Neither is a native limiter action. The page remains read-only and should contain no mutation event handlers, action menus, or client-disabled pseudo-actions.

### Limiters regression focus

Extend `test/oban_powertools/web/live/limiters_live_test.exs` rather than replacing its selected-URL/remount, live-versus-snapshot, Oban link, auth redirect, history, Forensics, ownership, and no-fake-host claims. Add complete-empty Runnable, incomplete-empty not-Runnable, unavailable/invalid selection, locked detail order, resource-specific accessible name, no mutation controls, hidden unauthorized Forensics destination, and no internal evidence leakage.

## Audit Findings

### Current behavior and query gap

`lib/oban_powertools/audit.ex` currently exposes `list/2`, `list_all/1`, and `list_all/2`. `filter_query` already implements the exact three supported filters. Current ordering is newest-first by `inserted_at` only, and `AuditLive` loads all matching rows.

`lib/oban_powertools/web/audit_live.ex` currently renders an unbounded raw table, shows raw query-shaped filter text, uses relative time prominently, and has no URL-owned selection or pagination. These are the primary PAGE-10 gaps.

### Bounded query contract

Add a conventional bounded query API, named consistently with the project (for example `page/2` or `list_page/2`), that:

- accepts only the existing exact filter map plus page options;
- normalizes invalid/missing page values to page 1;
- uses page size 20;
- orders `inserted_at DESC, id DESC`;
- executes an exact count query over the same filtered scope;
- uses `limit 20` and an offset derived from the normalized page;
- returns rows, exact total, page, page size, total pages, and previous/next availability;
- clamps or safely represents an out-of-range page without making records unreachable.

Update existing list ordering to include the same ID tie-break where compatible. Keep `list_all` for public/internal compatibility, but the four Phase 79 page paths must not use it for global rendering. Add a small bounded “latest matching” query for Overview/Cron support evidence if `list/2` does not already provide the needed limit.

Every matching row must remain reachable. Infinite scroll, LiveView streams, or a silent latest-N limit do not satisfy D-36.

### URL state and navigation

`AuditLive.handle_params/3` should parse:

- `resource_type`, `resource_id`, and `event_type` with their current exact meanings;
- positive `page` state;
- optional selected `event` row ID.

Build all links through one canonical ordered URL helper. Applying, removing, or clearing a filter resets page to 1 and removes selection. Previous/Next retains filters and removes or deliberately re-resolves selection. Selecting an event preserves filters and page. Closing selected detail preserves filters/page while removing only `event`. First selection pushes history; switching selected evidence replaces it. Back and direct reload must behave consistently.

An event selection must resolve within the active filter scope. A missing, malformed, or mismatched ID yields a safe unavailable detail/list fallback rather than leaking existence across filter scope or raising. It is acceptable for a matching selected record to remain viewable when it is not among the current page's 20 rows, because the canonical list/page state remains underneath it.

### Row presentation

Each normalized row should contain only:

- a human event/action label;
- a human resource/target label;
- actor display after `DisplayPolicy`;
- a redaction-safe reason summary;
- absolute UTC recorded time as the primary time;
- an explicit `View evidence` action with resource-specific accessible name;
- an independent job target link when the target is a job.

Rows are not clickable. Reason text may be visibly abbreviated only if selected detail contains the complete safe value. Do not include raw dot-separated event names, action atoms, command keys, raw metadata, or relative-only time.

### Selected evidence presentation and allowlist

The selected record should render via `audit_entry/1` inside `detail_surface/1`. Build one immutable past-tense sentence and normalized fields:

- actor via `DisplayPolicy`;
- human action;
- human target;
- complete redaction-safe reason, or exactly `No operator reason recorded`;
- source only from a known allowlisted recorded fact, or `Source not recorded`;
- outcome only from an actual allowlisted recorded result/status/decision, or `Outcome not recorded`;
- `Recorded at` with the schema's absolute UTC `inserted_at`;
- correlation only from a genuine explicit correlation field, or `Correlation not recorded`.

`command_key` is command idempotency, not correlation. The Audit row ID is identity, not causal correlation. Event-name suffixes do not prove outcome. A later result row is a separate immutable record, not evidence that the selected earlier row succeeded.

Structural redaction means the presenter selects safe fields before rendering. Never pass `event.metadata` wholesale. Allowlist only known scalar evidence with consumer labels. Exclude preview tokens, plan hashes, reason duplicates, principal maps, credentials, arguments not processed through policy, exceptions, stacktraces, configuration internals, and provider-specific blobs. Test both visible text and attributes/hidden DOM.

### Filters, retention, and read-only posture

Use the shipped filter composition in submit mode because the three filters already exist. Present applied human labels with individual remove and clear-all paths. Show an exact result/page summary. Do not add actor, free-text, date, saved-view, export, facet, qualifier, or filter-from-detail behavior.

The Repair evidence retention region belongs above results and must explicitly distinguish archived repair evidence from live Audit rows. It cannot claim a retention guarantee for the whole Audit table or use one metric as proof of completeness.

The page must have no mutation controls, row selection checkboxes, action menus, urgency roles, auto-refresh, or outcome color that implies current truth.

### Audit regression focus

Extend `test/oban_powertools/web/live/audit_live_test.exs` for existing DisplayPolicy, retention, read-only, exact-filter, Forensics URL, and auth behavior. Add a focused `Audit` query test file for page size, exact count, same-timestamp ID tie-break, filter compatibility, page reachability, and out-of-range behavior. LiveView tests should cover apply/remove/clear/reset, filter/page preservation, direct selection and close, missing fields, job target links, absolute time, read-only semantics, mismatched selection, and confidentiality.

## Shared Contract Gaps and Compatibility Guidance

The investigation found only two likely shared-component changes and three page-level presenter additions:

| Gap | Smallest compatible change | Avoid |
| --- | --- | --- |
| Limiter affected scope | Add an optional normalized field to `why_blocked` blocker maps and render it with existing evidence structure | A Limiters-only blocker card/component |
| Audit `Recorded at` label | Add optional/standard visible time labeling to `audit_entry` or its normalized field composition | Raw page-specific audit detail markup |
| Page copy | Add pure page presentation helpers in `ControlPlanePresenter` or one cohesive companion | Repeated strings/formatters in templates |
| URL composition | Add/use canonical ordered parameter helpers for Audit filter/page/event and existing selection paths | Hand-built query strings per event handler |
| Receipts | Normalize Cron result-to-receipt maps and use the existing toast/flash component once | Concurrent generic flash plus a second result banner |

Any shared change must retain old callers and the Phase 78 component tests. Closed attrs and fail-closed normalization should remain the rule.

## Showcase, Browser, and Asset Harness Findings

The current showcase stack comprises `ShowcaseCatalog`, `ShowcaseLive`, the generated manifest, `test/browser/support/showcase.ts`, and generic structure/a11y/VRT specs. Existing domain scenario IDs are stable and tests pin the current catalog shape. Current scenario cells are generic fixture inspection, not a sufficiently rich production-page behavior harness.

The lowest-risk extension is a dev/test-only page story catalog added alongside the existing scenario/component catalogs, not a replacement for their IDs. It should be fail-closed, deterministic, excluded from the package/runtime surface as appropriate, and appended to a versioned manifest contract. Browser support should recognize a `page` target kind and activate at most one selected detail or confirmation overlay.

The page stories should render the production page composition from normalized fixture assigns. If directly calling a LiveView's render path is awkward, extract a pure function component inside the page module that both `render/1` and the story host invoke. Do not duplicate the page structure in `ShowcaseLive`.

Planning must lock the exact story IDs and expected screenshot count before implementation. Minimum state coverage across the four pages is:

- Overview: all quiet; nonzero fixed ordering; long/Unicode exemplars.
- Cron: selected detail; permission denied; pause/resume/run-now confirmation; expired; drifted; skipped/partial recovery.
- Limiters: complete empty/Runnable; current blocked with distinct snapshot/history; unavailable or permission denied; Forensics unavailable.
- Audit: empty; filtered boundary page; selected detail with long/Unicode content; selected detail with missing fields.

Each locked story is exercised in light, dark, system, and high contrast at 320px, tablet, and wide. Therefore expected Phase 79 page baselines equal `story_count × 4 × 3`, and the verifier must check this exact equation and the changed-file scope. Existing unrelated showcase baseline residuals should be reported separately; this phase must not claim a globally clean update by hiding aggregate drift.

Browser behavior cannot be proven by static showcase screenshots alone. A connected page behavior spec should cover URL history, focus restoration, modal containment/Escape, resize across detail modes, keyboard traversal, loading/duplicate-submit semantics, and confidential DOM absence. Generic showcase structure, axe, and VRT specs remain the matrix layer.

Page layout CSS belongs in `assets/oban_powertools/tokens.css` with root-scoped selectors and only `--obpt-*` values. After rebuilding, `priv/static/oban_powertools/oban_powertools.css` must match generated source. Extend `theme_tokens_test.exs` and `assets_test.exs` for new selectors, token ownership, reduced motion, 320px reflow, package inclusion, and byte stability.

## Validation Architecture

Phase 79 should use layered, task-local validation with a final integrated gate. Every implementation task needs an automated proof; no long run of presentation changes should defer all feedback to browser baselines.

### Layer 1: Pure/query contracts

Fast ExUnit tests should prove the facts on which rendering depends:

- Overview stable bucket order, exact counts/source preservation, deterministic three-exemplar bound, bridge sample wording inputs, and injected-time determinism.
- Audit exact filter compatibility, 20-row bound, exact count, `inserted_at DESC, id DESC` tie-break, page reachability, and invalid/out-of-range page behavior.
- Presenter human labels, exact missing-value strings, current-versus-history separation, result-to-receipt mapping, and structural metadata allowlists.
- URL helper composition for filters/page/event, removal/reset, and stable encoding.

These tests should fail before the related production change and run in seconds.

### Layer 2: Shared component regressions

If `why_blocked/1` or `audit_entry/1` changes, extend:

```sh
mix test test/oban_powertools/web/components/operator_patterns_test.exs \
  test/oban_powertools/web/live/operator_patterns_harness_test.exs --seed 0
```

Prove optional-field backward compatibility, semantic labels, unavailable/partial behavior, focus/event wiring, and no raw evidence leakage. A diagnostic run during research confirmed the current operator-pattern unit baseline is green: 16 tests, 0 failures.

### Layer 3: Connected LiveView behavior

Use the four existing test files as the primary behavioral gate:

```sh
mix test \
  test/oban_powertools/web/live/engine_overview_live_test.exs \
  test/oban_powertools/web/live/cron_live_test.exs \
  test/oban_powertools/web/live/limiters_live_test.exs \
  test/oban_powertools/web/live/audit_live_test.exs \
  --seed 0
```

Assertions should target semantic IDs, headings, accessible labels, URLs, rendered state, repository effects, and absence of confidential values—not fragile class strings. Include auth denial, authorized read/action, direct links, Back/replace semantics, missing selections, Cron double authorization and stale/single-use recovery, Overview bounds, Limiter evidence truth, Audit pagination/filter preservation, and no mutation controls on read-only pages.

### Layer 4: CSS, assets, catalog, and package boundaries

Run:

```sh
mix oban_powertools.assets.build
mix test test/oban_powertools/web/theme_tokens_test.exs \
  test/oban_powertools/web/assets_test.exs --seed 0
npm run showcase:manifest
node test/browser/support/manifest-smoke.mjs
```

Tests must verify token-only/root-scoped CSS, one responsive tree, source/static equality, deterministic manifest output, stable existing catalog IDs, exact page-story target count, no runtime-only dependencies in fixtures, and package inclusion/exclusion expectations.

### Layer 5: Browser behavior and accessibility

Use real connected LiveViews for interaction truth and the deterministic page targets for matrix coverage. Automated browser assertions should cover:

- one H1 and logical heading/landmark order;
- native table semantics and meaningful captions;
- named links/buttons, resource-specific action names, and target size;
- keyboard traversal and visible, unobscured focus;
- detail open/close history behavior;
- Cron detail-to-confirm transition with only one active dialog;
- dialog focus containment, permitted Escape behavior, and logical focus restoration;
- wide inline detail without a focus trap;
- resize between wide/narrow modes without duplicate DOM or lost state;
- 320px and 200% zoom/reflow without page-level horizontal scrolling;
- reduced-motion instant behavior;
- screen-reader announcement semantics without static Overview/Audit alert noise;
- no secret/internal values in text, attributes, hidden nodes, or serialized fixture payloads;
- axe zero critical/serious violations.

Run the page behavior spec and generic structure/a11y specs through the repository's Docker-backed browser command, for example:

```sh
npm run visual:a11y -- test/browser/specs/page-migration-wave-1.spec.ts
npm run visual:a11y -- \
  test/browser/specs/showcase.structure.spec.ts \
  test/browser/specs/showcase.a11y.spec.ts
```

The exact spec filename may follow current naming conventions, but the responsibilities above should not be diluted across screenshot-only assertions.

### Layer 6: Reviewed visual baselines

Generate new baselines only after structure and axe are green. Lock the exact expected matrix first, review changed PNG scope, then run compare-only VRT:

```sh
npm run vrt:update
npm run visual:a11y -- test/browser/specs/showcase.vrt.spec.ts
```

The Phase 79 verifier should fail if:

- the number of page images differs from `locked story count × 12`;
- any theme or viewport is missing;
- unrelated baseline families changed without explanation;
- compare-only mode still produces differences.

Do not treat baseline generation itself as verification.

### Layer 7: Integrated quality gate

After targeted gates are green, run the repository-wide checks appropriate to the touched surface:

```sh
mix format --check-formatted
mix test --exclude host_contract
mix credo --strict
mix dialyzer
npm run visual:a11y
```

If package or host integration files change, also run the existing package and host-contract gates rather than assuming component tests cover installation. Report known pre-existing browser residuals separately from Phase 79's page-scoped result.

### Manual verification checklist

Automation should be supplemented with explicit observation of:

- heading and landmark order with a screen reader;
- table navigation and control names;
- focus visibility at all breakpoints;
- Cron confirmation focus start, Tab containment, Escape rules, close/recovery/success restoration;
- wide detail no-trap behavior and resizing an open detail/dialog;
- 200% zoom at a 320 CSS-pixel viewport;
- long English, Unicode, bidirectional, and unbroken identifiers;
- high-contrast and color-independent state meaning;
- reduced-motion operation;
- exact action, absence, bridge-ownership, freshness, completeness, and receipt copy.

### Nyquist task rule

The future plan should put a fast automated validation command directly after each substantive task, keep normal feedback below roughly 20 minutes, and avoid three consecutive implementation tasks without a proof. Create `79-VALIDATION.md` early enough to record the exact story matrix, baseline count, commands, manual observations, and known unrelated residuals rather than reconstructing evidence at closeout.

## Common Pitfalls

### Treating migration as a rewrite

Replacing the existing LiveView state machines or domain APIs would create unnecessary authorization, transaction, and URL regressions. Keep orchestration and replace presentation at its existing seams.

### Passing schemas or metadata to components

Shared components cannot be the redaction boundary if they receive raw Ecto schemas or whole metadata maps. Normalize and allowlist first.

### Making historical evidence look current

Limiter block-start snapshots and history, Overview continuity, and Audit records are historical. None should be rendered as current state or causal proof.

### Reusing visual status as semantic truth

Severity, status, ownership, completeness, and support are separate. Avoid broad fills and one color/badge that silently collapses those dimensions.

### Weakening Cron authority during UI cleanup

The reason field, disabled controls, and LiveView loading states do not replace pre-preview auth, confirm-time auth, durable drift checks, preview single use, or the transaction.

### Claiming run-now execution

Run-now may enqueue, queue, skip, or deduplicate a slot claim. Receipts must reflect the recorded result and never say the job ran without evidence.

### Nested dialogs

Rendering `detail_surface` and `confirm_action_dialog` simultaneously at narrow viewports violates modality and focus requirements. Confirmation must temporarily replace the selected detail rendering while keeping URL selection.

### Unstable or lossy Audit pagination

Ordering only by timestamp makes page boundaries nondeterministic. A latest-N cap makes old records unreachable. Use the ID tie-break, exact count, and Previous/Next URLs.

### Inventing Audit correlation/outcome

Command keys, row IDs, and event suffixes are not evidence of correlation or success. Render the locked absence strings.

### Calling incomplete limiter evidence Runnable

Only complete and empty current evidence supports Runnable. Missing, stale, partial, unavailable, and denied are explicit non-success states.

### Creating a second showcase implementation

Static fixture HTML can pass VRT while production pages regress. Feed deterministic presentation assigns through the production page rendering path.

### Duplicating responsive markup

Separate desktop/mobile tables or details cause duplicate IDs, conflicting focus, secret-bearing hidden DOM, and accessibility noise. Reflow one tree with CSS.

### Overfitting tests to classes

Page classes are implementation detail. Preserve semantic selectors, exact URLs, repository effects, accessible names, and confidentiality assertions.

## Concrete File Inventory

Primary production files expected to be involved:

- `lib/oban_powertools/web/engine_overview_live.ex`
- `lib/oban_powertools/web/overview_read_model.ex`
- `lib/oban_powertools/web/cron_live.ex`
- `lib/oban_powertools/web/limiters_live.ex`
- `lib/oban_powertools/web/audit_live.ex`
- `lib/oban_powertools/audit.ex`
- `lib/oban_powertools/web/control_plane_presenter.ex`
- `lib/oban_powertools/web/components/operator_patterns.ex` only for narrow backward-compatible gaps
- the existing canonical selector/path helper used by the web pages
- `assets/oban_powertools/tokens.css`
- generated `priv/static/oban_powertools/oban_powertools.css`

Fixture/harness files likely involved:

- `lib/oban_powertools/web/dev/showcase_live.ex`
- the existing showcase catalog/manifest modules and generated manifest
- `test/browser/support/showcase.ts`
- `test/browser/support/manifest-smoke.mjs`
- `test/browser/specs/showcase.structure.spec.ts`
- `test/browser/specs/showcase.a11y.spec.ts`
- `test/browser/specs/showcase.vrt.spec.ts`
- one connected Phase 79 page behavior spec

Primary test files to extend:

- `test/oban_powertools/web/live/engine_overview_live_test.exs`
- `test/oban_powertools/web/live/cron_live_test.exs`
- `test/oban_powertools/web/live/limiters_live_test.exs`
- `test/oban_powertools/web/live/audit_live_test.exs`
- a focused Audit query/pagination test file
- presenter/selector tests near their current modules
- `test/oban_powertools/web/components/operator_patterns_test.exs`
- `test/oban_powertools/web/live/operator_patterns_harness_test.exs`
- `test/oban_powertools/web/theme_tokens_test.exs`
- `test/oban_powertools/web/assets_test.exs`
- showcase manifest/catalog tests

Files not expected to change without a concrete contradiction:

- `lib/oban_powertools/cron.ex` public command semantics
- Audit schema/migrations
- authorization policy definitions
- route paths
- Oban Web/provider adapters
- AppShell architecture

## Research Conclusions for Planning

The phase is ready to plan. The key dependency order is architectural rather than visual: lock pure normalized page contracts and Audit paging first; then migrate shared component composition and connected behavior; then add deterministic production-rendered page stories and browser matrix evidence. This ordering lets each page be validated without postponing safety checks until VRT.

The planner should treat these as non-negotiable acceptance facts:

- fixed Overview lane order and bounded exemplars;
- Cron selected-detail-only actions, UI reason validation, double authorization, one-dialog lifecycle, exact result truth, and one receipt;
- Limiter current/snapshot/history separation with complete-empty-only Runnable;
- Audit exact filters plus stable reachable 20-row pagination and structurally allowlisted detail;
- one DOM, token-only themes, 320px/200% reflow, reduced motion, and no secret-bearing hidden content;
- deterministic page stories rendered through production composition, with a locked exact matrix and compare-only VRT after reviewed baseline generation.

## Sources Consulted

Canonical planning/product sources:

- `.planning/phases/79-page-migration-wave-1-overview-cron-limiters-audit/79-CONTEXT.md`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `guides/brand-book.md`
- Phase 73, 76, 77, and 78 pattern, UI, security, and validation artifacts cited by Phase 79 context

Repository sources:

- the four LiveViews and their existing tests
- `OverviewReadModel`, `Cron`, `Audit`, limiter explanation/history modules
- `ThemeShell`, `Primitives`, `Forms`, `DataDisplay`, `OperatorPatterns`
- `ControlPlanePresenter` and `ObanPowertools.DisplayPolicy`
- showcase catalog/live/manifest/browser support, theme-token, asset, and package tests

No web research was required: the phase decisions and shipped repository contracts are the authoritative, current sources for this implementation.
