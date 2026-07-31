# Phase 79: Page Migration Wave 1 — Overview, Cron, Limiters, Audit - Context

**Gathered:** 2026-07-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Migrate the existing Overview, Cron, Limiters, and Audit LiveViews onto the shipped app shell, primitives, data-display components, and operator-pattern groups. Preserve each page's authorization, operator capability, native-versus-bridge ownership, durable audit behavior, resource destinations, and existing deep-link/filter meaning. This phase may improve presentation hierarchy, microcopy, responsive behavior, focus behavior, and bounded retrieval needed to render the existing review capability safely; it does not add a new control-plane capability, mutation, policy, data source, or provider-shaped UI.

The four pages form one coherent operator flow: **current truth -> one deliberate next action -> durable historical evidence**. Overview prioritizes triage, Cron puts mutations behind context and confirmation, Limiters explains current blockers without conflating history, and Audit supports dense evidence review without pretending chronology proves causality.

</domain>

<decisions>
## Implementation Decisions

### Shared Product, Architecture, and DX Contract

- **D-01:** Reuse `AppShell`, `Primitives`, `Forms`, `DataDisplay`, and `OperatorPatterns`; do not create page-local substitutes for surfaces, buttons, status pills, tables, forms, dialogs, detail drawers, attention cards, blocker explainers, or audit entries. The page LiveViews remain the orchestration boundary.
- **D-02:** Parent LiveViews own authorization, query/mutation lifecycle, URL state, selection, form state, stale-state handling, redaction, navigation, and receipts. Shared components remain stateless `Phoenix.Component` function components with closed attrs and normalized presentation maps. Do not introduce stateful LiveComponents for these migrations.
- **D-03:** Preserve current public operations and support boundaries: Overview, Limiters, and Audit remain read-only; only Cron exposes pause, resume, and run-now; bridge-only work continues in Oban Web. Client-disabled state is never authority. Authorize page access and resource/action access on the server at the same points or more strictly than today.
- **D-04:** Use consumer/operator language, never implementation-shaped headlines. Keep one canonical noun and verb for each concept across pages: job, cron entry, limiter, blocker, audit record, evidence, reason; review, view evidence, open target, pause, resume, run now. Do not expose preview tokens, plan hashes, action atoms, query syntax, Ecto structs, raw metadata, source tables, ranks, or exceptions.
- **D-05:** Visual order follows the shared mental model: current state; plain-language explanation and affected scope; one primary next step; evidence freshness/completeness; technical or historical evidence. Status, ownership, severity, and evidence completeness remain separate dimensions.
- **D-06:** The visual posture is the brand book's calm control room: neutral chrome, restrained borders, sparse semantic color paired with text/icon/position, strong typography and spacing, and no alarm-card wall, badge soup, nested cards, broad status fills, decorative gradients, or gratuitous motion.
- **D-07:** Use one semantic DOM tree per page/component at every viewport. Reflow to 320px and 200% zoom without horizontal page scrolling or duplicated hidden content. Light, dark, system, and high-contrast themes use only `--obpt-*` tokens. Motion is interruptible, nonessential, token-owned, and instant under reduced motion.
- **D-08:** All explicit states remain truthful: empty, loading, ready, unavailable, permission-denied, stale, partial, success, and error where applicable. Unknown is not success, historical evidence is not current state, adjacent events are not causal proof, and an accepted request is not a completed job.

### Overview: Stable, Layered Triage

- **D-09:** Replace the equal six-card grid with this stable semantic and DOM order: `Needs Review -> Blocked -> Waiting -> Bridge-only Follow-up -> Runnable -> Resolved continuity`. Never reorder these lanes by count, timestamp, client state, viewport, or severity color. Preserve `AttentionProjection`'s existing deterministic within-bucket ranking and three-exemplar bound.
- **D-10:** Group the first three buckets beneath **Current attention**. They are the primary scan target because they represent native current work. Wide layouts may use two columns within that lane; the same DOM becomes one column in the locked order at narrow widths.
- **D-11:** Render **Bridge-only Follow-up** immediately after native current attention and before routine capacity. Use a neutral handoff surface with explicit Oban Web ownership and an **Inspect in Oban Web** destination. Do not make the bridge resemble a native Powertools action.
- **D-12:** The bridge count is a bounded representative sample, not a global outstanding total. Say `N representative follow-ups` or `N shown`; do not render it as a comparable total metric. Never disclose the underlying latest-record window, deduplication, or projection mechanics.
- **D-13:** Render **Runnable** as compact current-capacity/status context, not an attention card. Render **Resolved continuity** last as calm retained evidence, not a green success card. Use “Resolved continuity,” because the current query has no real recent-time cutoff; do not claim “recently.”
- **D-14:** Nonzero current buckets may use `attention_card/1` only when title, summary, impact, observed time, and completeness can be supplied honestly. Supporting exemplars are bounded list rows/direct children with separators and explicit links—not nested cards. Runnable uses `metric_card/1` or a status summary; bridge and continuity use neutral surfaces.
- **D-15:** Preserve explicit zero states but make them compact and bucket-specific: one truthful fact plus the relevant next route. Remove repeated generic historical-attention subcards. An all-quiet page must state that no current native or bridge follow-up is identified without implying monitoring completeness beyond available evidence.
- **D-16:** Keep H1 **Overview** and use operator-focused introductory copy such as: “See what needs attention, why it matters, and where to continue.” Static overview state has no `role="alert"` or live region. Preserve every existing count, diagnosis, selector URL, authorization boundary, and read-model source; do not add polling, PubSub, configurable cards, charts, or a feed.

### Cron: Context-First Master/Detail and Safe Mutations

- **D-17:** Use a `DataTable` for schedule scanning and the existing `?entry=` URL-backed `detail_surface/1` for selected context. The entry name is an explicit patch link/control; the row is not wholly clickable. Remove repeated mutation buttons and the Actions column from table rows. Do not replace them with a kebab menu.
- **D-18:** The selected detail is the only mutation venue. It shows schedule, current state, relevant history/support truth, then visible **Pause cron entry** or **Resume cron entry** and **Run cron entry now** controls. Actions stack safely at 320px. Unauthorized actions remain discoverable when useful, disabled with a plain reason; CSS hiding is not authorization.
- **D-19:** All three actions use `confirm_action_dialog/1` and the existing preview -> reason -> confirm -> result server workflow. Opening confirmation first closes/leaves the adaptive detail surface at every viewport while retaining the selected entry and `?entry=` URL, preventing nested modal dialogs. Dismissal or recoverable failure reopens/restores the detail context; success refreshes repository truth and restores to the updated detail or logical row fallback.
- **D-20:** Use warning intent for all three current actions; none is an irreversible delete/cancel. Exact primary/dismiss labels are:
  - **Pause cron entry** / **Keep running**
  - **Resume cron entry** / **Keep paused**
  - **Run cron entry now** / **Keep current schedule**
  Never use generic Confirm/Cancel or “Are you sure?” copy.
- **D-21:** Preview copy states the actual consequence and non-effect:
  - Pause: future schedule claims stop; already running or enqueued work is unaffected.
  - Resume: future schedule claims continue; missed work is not run retroactively.
  - Run now: Powertools attempts a manual schedule-slot claim; overlap policy may skip, queue, or enqueue it.
  Never claim that a job “ran” merely because a run-now claim was accepted or recorded.
- **D-22:** Require a trimmed nonblank operator reason in the migrated UI for all three audited mutations, with calm “do not enter secrets” help and server revalidation. Preserve the public Cron command API/backend compatibility contract where it currently reports `reason_required: false`; do not make an unrelated breaking API change. The page-level UI is stricter because Phase 78 and the current brand book require reasons for audited operator mutations.
- **D-23:** Authorization is checked before preview and again before execution; execution uses the current principal. Existing durable preview identity, expiry, drift, single-use validation, plan hash, overlap policy, `Ecto.Multi`, and audit transaction are authoritative. Render none of those provider/internal fields directly.
- **D-24:** A clean success closes confirmation, reloads repository state, and emits one exact receipt plus an Audit destination. Say only that the entry state changed or a manual slot claim/result was recorded. Expired, drifted, consumed, skipped, partial, or failed results remain open with specific recovery and a fresh-preview path; preserve a safe reason draft, but never silently refresh and execute.
- **D-25:** Dialog focus starts on the labelled consequence, remains contained, closes with Escape only in dismissible states, and restores to the detail action or row fallback. Duplicate-submit prevention uses normal LiveView loading/disabled semantics; it is not concurrency control.

### Limiters: Current Diagnosis Before Historical Evidence

- **D-26:** Use a `DataTable` for resource scanning and the existing `?resource=` URL-backed adaptive `detail_surface/1` for inspection. The explicit row action is **Review blockers** (with a resource-specific accessible name), not a whole-row click. Preserve all current repository inputs, selection URLs, Oban Web destinations, Forensics permission checks, and read-only behavior.
- **D-27:** Detail order is locked: resource/state and support truth; **Current blockers** through `why_blocked/1`; **Snapshot at block start**; **Retained history** and its completeness; then runbook/Forensics/Oban Web destinations. This creates a consistent current truth -> next route -> history progression without merging unlike evidence.
- **D-28:** `why_blocked/1` receives normalized current blocker maps with plain label/summary, affected scope, clearing condition, evidence source, observed time, and completeness. If live evidence is complete and empty, say **Runnable**. If stale, partial, unavailable, or permission-denied, state that limitation; never say “No blockers.”
- **D-29:** Block-start snapshot and retained history are visually and semantically separate from live state. A snapshot says when it was captured and cannot be presented as current. History is diagnostic continuity, not a root-cause claim. Use “current blocker/cause,” never “root cause,” unless the data actually proves causality.
- **D-30:** Keep bridge and runbook destinations secondary and ownership-honest. **Open in Oban Web** is generic inspection; **Open forensic timeline** appears only when authorized; neither becomes a native mutation. Do not add limiter actions, live polling, or a combined event timeline in this phase.

### Audit: Bounded Scan Index Plus One Evidence Detail

- **D-31:** Use the hybrid model: a compact semantic `DataTable` is the global scan/index surface, and one selected record renders through `audit_entry/1` inside `detail_surface/1`. Do not turn the global audit log into a card timeline or connected event rail. The selected record may use `event=<audit-row-id>` while preserving all active filters and page state; direct/reloaded selection must work.
- **D-32:** Summary rows show human event label, target/resource, actor, reason summary, absolute recorded time, and an explicit **View evidence** control with a resource-specific accessible name. Rows are not wholly clickable; job target links remain independent links. A reason may be visibly abbreviated only when its complete redaction-safe value is in selected detail.
- **D-33:** The selected `AuditEntry` is an immutable past-tense statement with actor, action, target, complete reason, source, explicit recorded outcome, recorded time, and only genuinely available correlation/evidence. Use **Recorded at** because the schema supplies `inserted_at`, not a separate occurrence time. Absolute UTC is primary; relative time may be secondary.
- **D-34:** Missing values remain explicit: **No operator reason recorded**, **Outcome not recorded**, **Source not recorded**, or **Correlation not recorded** as applicable. `command_key` is not request correlation, audit row ID is not causal correlation, event-name suffixes do not prove success, and a later result is a later immutable record.
- **D-35:** Preserve the current exact, URL-owned meanings of `resource_type`, `resource_id`, and `event_type`. Present them as human labels/applied filters rather than raw query syntax, with exact result summary and clear/remove paths that retain the remaining scope. Do not add actor/free-text/date search, saved views, exports, qualifier grammar, facets, filter-from-detail, or live tailing.
- **D-36:** Replace the current unbounded `Audit.list_all/2` assignment with conventional 20-record URL-owned Previous/Next pagination. Add a stable newest-first order of `inserted_at DESC, id DESC`, reset to page 1 when filter scope changes, retain filters across pagination and selection, and show a truthful exact result/page summary. Every matching record remains reachable; do not use infinite scroll, a silent latest-N cap, or LiveView streams as a substitute for a bounded query.
- **D-37:** Keep a restrained read-only **Repair evidence retention** region above results. It must distinguish live audit rows from archived repair evidence and say only what the ledger proves. Do not claim the whole audit log has a 90-day retention window, that archived repair records appear in the table, or that a metric proves completeness.
- **D-38:** Redaction is structural. Build both row and detail presentation from allowlisted facts after `DisplayPolicy`; never pass `event.metadata` wholesale or place secret originals, preview tokens, hashes, credentials, raw exceptions, or stacktraces in text, attributes, code blocks, collapsed `<details>`, assigns intended for rendering, or telemetry.
- **D-39:** The Audit page remains visibly and semantically read-only. The permission/support message is neutral information, not an amber alarm. No row checkboxes, bulk controls, action menus, mutation buttons, auto-refresh, urgency role, or decorative outcome color belongs here. History records what was recorded; it does not establish current state or causal relationships.

### Verification, Accessibility, and Regression Contract

- **D-40:** Preserve existing route paths and query semantics: Overview selector destinations, Cron `entry`, Limiters `resource`, and Audit's three exact filters. New Audit `page`/`event` state composes with rather than replaces those URLs. Explicit close restores the filter-preserving list URL; Back and direct links follow the Phase 78 DetailSurface contract.
- **D-41:** Extend existing LiveView tests instead of replacing behavior assertions. Prove authorization, page read-only/mutation boundaries, stable destinations, Cron double authorization/stale preview/single-use/audit behavior, bounded Overview exemplars, Limiters evidence truth, Audit filter compatibility/pagination/tiebreak ordering, and no secret/internal values in text, attributes, or hidden DOM.
- **D-42:** Add deterministic page showcase/browser fixtures for quiet, nonzero, long/Unicode, unavailable, permission-denied, stale, expired/drifted, empty, and selected-detail/dialog states. VRT covers light/dark/system/high-contrast across 320px/tablet/wide. Axe remains zero critical/serious.
- **D-43:** Manually and automatically verify heading/landmark order, native table semantics rather than ARIA grid, named links/buttons, target size, visible/unobscured focus, keyboard traversal, modal containment/Escape/restore, wide detail no-trap behavior, resize mode changes, 200% zoom/reflow, screen-reader announcements, reduced motion, and color-independent meaning.
- **D-44:** Performance acceptance includes bounded Audit queries/DOM, bounded Overview exemplars, no duplicated responsive trees, no page-local polling, no N+1 query introduced by presenters/details, and repository work outside render functions. Presenters and normalization helpers remain pure and deterministic.
- **D-45:** Review through all design pillars: JTBD usefulness; information architecture; plain-language content; accessibility; responsive reflow; visual hierarchy and theming; performance; security/privacy/redaction; authorization and concurrency truth; recovery/support truth; observability without sensitive cardinality; maintainability; public API compatibility; and host-library integration/DX.

### Claude's Discretion

The user explicitly delegated all Phase 79 product, UI/UX, architecture, ecosystem, accessibility, performance, security, and DX decisions after research. Downstream work may choose low-level markup organization, pure helper names, CSS grid details, and test file decomposition only where the choices above and the Phase 76–78 component contracts do not already decide them. Do not reopen the selected information architecture, action placement, evidence semantics, responsive model, or query-bound decisions without a concrete repository contradiction.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** If older prompt language conflicts with the current brand book or shipped Phase 76–78 contracts, `guides/brand-book.md` and the shipped contracts win.

### Product Scope and Current Authority

- `.planning/PROJECT.md` — Product vision, capabilities, support boundaries, and library constraints.
- `.planning/REQUIREMENTS.md` — Phase requirements PAGE-01/05/06/08/10, COPY-01, A11Y, and MOTION acceptance.
- `.planning/ROADMAP.md` — Phase 79 boundary, dependency, and zero-regression success criteria.
- `guides/brand-book.md` — Newest authoritative brand, voice, ownership, state, safety, responsive, theme, and accessibility rules.

### User-Requested Research and Strategy Corpus

- `prompts/oban-powertools-deep-research-original-prompt.md` — Research posture and breadth of product/ecosystem analysis.
- `prompts/oban_powertools_context.md` — Product, domain, architecture, operator, support, and safety context.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — UI strategy, personas, JTBD, information architecture, design-system, and quality-bar guidance.

### Shipped Shell, Data, and Operator Contracts

- `.planning/phases/76-navigation-app-shell/76-PATTERNS.md` — App-shell integration and navigation patterns.
- `.planning/phases/76-navigation-app-shell/76-UI-SPEC.md` — Shell layout, responsive navigation, theme, focus, and route behavior.
- `.planning/phases/77-data-display-operator-patterns/77-PATTERNS.md` — DataTable, metric, state, redaction, and presentation-map implementation patterns.
- `.planning/phases/77-data-display-operator-patterns/77-UI-SPEC.md` — Responsive data-table, empty/loading/error, status, and evidence rendering contracts.
- `.planning/phases/77-data-display-operator-patterns/77-SECURITY.md` — Structural redaction and data-display security boundary.
- `.planning/phases/78-component-groups-meta-components/78-CONTEXT.md` — Locked shared component ownership, lifecycle, truth, accessibility, and copy decisions.
- `.planning/phases/78-component-groups-meta-components/78-PATTERNS.md` — Exact integration patterns for confirmation, adaptive detail, attention, blocker, and audit components.
- `.planning/phases/78-component-groups-meta-components/78-UI-SPEC.md` — Authoritative component APIs, interaction, responsive, motion, and visual contracts.
- `.planning/phases/78-component-groups-meta-components/78-SECURITY.md` — Authorization, reason, redaction, dialog, and evidence threat mitigations.
- `.planning/phases/73-visual-regression-a11y-harness/73-PATTERNS.md` — Existing deterministic browser/VRT/a11y harness conventions.
- `.planning/phases/73-visual-regression-a11y-harness/73-VALIDATION.md` — Existing validation commands and required evidence structure.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `lib/oban_powertools/web/components/app_shell.ex`: required host-safe shell, navigation, main target, theme, and actor context.
- `lib/oban_powertools/web/components/primitives.ex`: token-owned surfaces, actions, links, statuses, and semantic visual building blocks.
- `lib/oban_powertools/web/components/forms.ex`: accessible reason form fields and errors backed by parent-owned `to_form` state.
- `lib/oban_powertools/web/components/data_display.ex`: responsive `DataTable`, `MetricCard`, states, descriptions, timestamps, and redaction-safe evidence.
- `lib/oban_powertools/web/components/operator_patterns.ex`: shipped `ConfirmActionDialog`, `DetailSurface`, `AttentionCard`, `WhyBlocked`, `AuditEntry`, and filter composition contracts.
- `lib/oban_powertools/web/control_plane_presenter.ex` and `lib/oban_powertools/display_policy.ex`: preferred centralized seams for grammatical labels, support truth, actor/reason display, and redaction.

### Established Patterns

- `lib/oban_powertools/web/overview_read_model.ex`: keep query composition and finite overview presentation classification here; it already emits bounded deterministic buckets and should remain the only page-level ranking boundary.
- `lib/oban_powertools/web/cron_live.ex`: preserve current `?entry=` selection, double authorization, durable preview status/identity, drift/expiry/consumption handling, execution transaction, audit recording, and post-result reload.
- `lib/oban_powertools/web/limiters_live.ex`: preserve `?resource=` selection and its separation of live blockers, block-start snapshot, retained history, runbook, Forensics authorization, and Oban Web handoff.
- `lib/oban_powertools/audit.ex`: extend its composable exact-filter query with stable bounded paging/counting rather than loading all rows; do not leak schemas into components.
- `lib/oban_powertools/web/audit_live.ex`: keep filters in `handle_params/3`, make canonical URL params the source of page/selection truth, and keep mutation events absent.
- Current tests in `test/oban_powertools/web/live/engine_overview_live_test.exs`, `cron_live_test.exs`, `limiters_live_test.exs`, and `audit_live_test.exs` are behavioral contracts, not disposable snapshot tests.

### Integration Points

- `EngineOverviewLive.render/1` consumes `OverviewReadModel.build/1`; presentation order and component mapping change here while data/query semantics stay in the read model.
- `CronLive.handle_params/3` and existing preview/reason/confirm handlers remain the state machine; replace page markup and add UI reason validation without weakening execution truth.
- `LimitersLive.handle_params/3` and `load_selection/2` remain the master/detail seam; normalize current/snapshot/history data before shared-component rendering.
- `AuditLive.handle_params/3` parses filter/page/event state and invokes a bounded `Audit` query; selected evidence is normalized through the presenter/DisplayPolicy boundary before rendering.
- Existing showcase manifest, browser targets, VRT, axe, LiveView tests, and package-boundary checks are extended with deterministic Phase 79 page states.

</code_context>

<specifics>
## Specific Ideas

- The decisive cross-page posture is **triage-first Overview, selection-first Cron and Limiters, scan-first Audit**.
- The ideal wide Overview resembles a stable control-room hierarchy, not a configurable dashboard: Current attention first, bridge handoff next, compact capacity context, then resolved continuity.
- Cron follows the familiar successful operator-console pattern of a schedule list leading to selected details and deliberate actions. The user sees the consequence, provides a reason, confirms an action-specific verb, then receives an exact durable result.
- Audit borrows the successful global-audit pattern used by established cloud and source-control consoles: dense bounded index, exact filters, explicit absolute time, and progressive selected evidence. It deliberately does not borrow raw JSON payloads, cryptic qualifier grammar, facet-heavy observability UI, or timeline rails that imply causality.
- Limiters makes the distinction operators most need under pressure: **what blocks progress now** versus **what was captured when blocking began** versus **what retained history can support**.
- UX psychology is recognition over recall, stable spatial order for muscle memory, proximity of explanation and action, progressive disclosure of technical evidence, visible permission/support truth, restrained confirmation friction proportional to risk, and a trustworthy terminal receipt.

</specifics>

<deferred>
## Deferred Ideas

- A configurable Overview, charts, user-reordered cards, page-level dynamic severity scoring, polling, or a unified activity feed. They add capability/churn and conflict with the stable bounded diagnosis model.
- A genuine time-windowed “Resolved recently” metric. It requires a product-defined cutoff and read-model behavior change; until then use “Resolved continuity.”
- New Audit actor/free-text/time-range filters, saved views, export, facets, query grammar, live tail, and cross-record correlation. These are separate audit-product capabilities.
- Audit schema expansion for universal outcome/source/correlation. Phase 79 must render recorded facts and explicit absence; it must not invent evidence.
- Breaking changes to the public Cron command API's current `reason_required` compatibility value. The migrated operator UI may require a reason without broadening that API change into this phase.
- New limiter mutations, inferred root-cause scoring, or native duplication of Oban Web bridge capabilities.

</deferred>

---

*Phase: 79-Page Migration Wave 1 — Overview, Cron, Limiters, Audit*
*Context gathered: 2026-07-19*
