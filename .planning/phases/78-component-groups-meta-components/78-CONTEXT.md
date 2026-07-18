# Phase 78: Component Groups (Meta-Components) - Context

**Gathered:** 2026-07-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 78 ships a stateless, documented `ObanPowertools.Web.Components.OperatorPatterns` layer that composes the Phase 74–77 primitives, forms, navigation, and data-display components into six reusable operator patterns: `confirm_action_dialog/1`, `filter_bar/1`, an adaptive `detail_surface/1` covering drawer and panel behavior, `attention_card/1`, `audit_entry/1`, and `why_blocked/1`.

The phase defines their typed presentation contracts, interaction state machines, accessibility behavior, truthful microcopy hierarchy, showcase stories, visual-regression coverage, and focused component/browser tests. It may add small pure presentation normalizers and scoped client behavior required by those components. It does not migrate product pages, add operator capabilities, change authorization or Ecto query semantics, invent a new execution engine, or expand the audit/forensics schemas. Parent LiveViews continue to own data loading, URL state, authorization, preview generation, execution, durable audit writes, and navigation.

</domain>

<decisions>
## Implementation Decisions

### Shared Architecture and Consumer Contract

- **D-01:** Add the public functions to one discoverable `ObanPowertools.Web.Components.OperatorPatterns` module, matching the repository's established `Primitives`, `Forms`, and `DataDisplay` convention. Keep implementation helpers private or in narrowly named support modules; do not create a parallel design-system hierarchy.
- **D-02:** All six patterns are stateless Phoenix function components with declared, closed `attr` values and named slots. Do not use stateful LiveComponents. The calling LiveView owns open/closed state, draft/applied state, loading, authorization, redaction, Ecto access, mutations, result normalization, URL construction, and audit destinations.
- **D-03:** Compose existing primitives, `Forms`, and `DataDisplay`; do not restyle raw buttons, inputs, pills, tables, alerts, or progress indicators inside each group. No caller-provided `class`, `style`, arbitrary global attributes, raw color, or size escape hatch may bypass the token and semantic contracts.
- **D-04:** Repeated data such as active filters, blockers, and result rows uses a narrow documented presentation-map shape normalized by pure helpers. Caller-owned links/actions/evidence use constrained named slots. Never accept arbitrary backend structs or derive user-facing copy by inspecting Ecto schemas, action atoms, errors, or metadata.
- **D-05:** The consistent information order is: current state, plain-language explanation, impact/scope, next safe action, evidence freshness/completeness, then technical evidence/history. Provider-shaped identifiers, tokens, selectors, snapshots, and payloads are supporting evidence, never the headline.
- **D-06:** Each pattern renders every explicit state it can receive—empty, loading, ready, stale, unavailable, permission-denied, invalid, pending, success, partial, and error as applicable. Unknown evidence must remain unknown; no component infers success, safety, freshness, or current truth.
- **D-07:** Centralized presenters supply complete, grammatical, domain-vocabulary copy. Components enforce structure and tone but do not fabricate sentences from raw nouns and verbs. Extend `ControlPlanePresenter` or a tightly scoped pure companion instead of starting a second vocabulary.
- **D-08:** Component telemetry, if any, is low-cardinality and semantic. Never emit job IDs, actor data, reason text, blocker codes, query values, or result payloads as metric labels.

### ConfirmActionDialog: Authoritative Preview to Durable Result

- **D-09:** Use the lifecycle `preview -> valid confirmation -> submitting -> authoritative terminal result`. Preview and execution must share the same server decision path. A browser-rendered summary is not authorization and must never be treated as the execution plan.
- **D-10:** The preview names the object, exact scope/count, consequence, reversibility, and support boundary before confirmation is enabled. It also identifies out-of-view bulk scope. Never use bare “Are you sure?” or generic Confirm/Cancel labels.
- **D-11:** Every audited operator mutation represented by this pattern requires a trimmed reason. Use the existing eight-character minimum where Lifeline requires it, validate through a parent-owned `Phoenix.HTML.Form` backed by a schemaless Ecto changeset or equivalent pure validation, and revalidate on the server. Include calm microcopy telling operators not to enter secrets.
- **D-12:** Friction follows blast radius: a single reversible action uses reason plus a warning-weight, action-specific button; a single irreversible action uses reason plus a danger-weight button; every bulk action additionally requires typing the exact frozen count and states whether membership extends beyond the current page.
- **D-13:** The dismiss label describes the safe retained state—such as “Keep running” or “Keep current state”—and never mirrors the destructive verb. No click-away dismissal is allowed for a destructive confirmation.
- **D-14:** Use a stateless component API with closed intent (`:warning | :danger`), lifecycle state, semantic copy fields, a `Phoenix.HTML.Form`, a narrow result map, and constrained support-details/action slots. Do not expose preview tokens, action atoms, plan hashes, raw errors, or audit storage fields in the UI contract.
- **D-15:** On submit, use LiveView's normal loading semantics (`phx-disable-with`/loading classes), set `aria-busy`, disable confirmation inputs against duplicate clicks, and name the work (“Retrying 12 jobs…”). This is duplicate-submit protection only; authorization, membership, count, reason, expiry, drift, and single-use validation remain server-authoritative.
- **D-16:** A clean authoritative success closes the dialog, restores focus, and emits one exact polite receipt using the existing Toast/Flash/status pattern. The receipt states only what Powertools actually changed, requested, or recorded and whether audit evidence was recorded; it never claims the host job completed or was “fixed.” All-success bulk may close only when membership was frozen and the returned count matches that scope.
- **D-17:** Partial, failed, skipped, expired, drifted, or consumed outcomes keep the dialog open and replace the form with a persistent result/recovery view. Focus moves to a result heading with `tabindex="-1"`; show deterministic per-item rows with distinct `:success`, `:failed`, and `:skipped` outcomes, specific messages, recovery guidance, and an audit link when durable evidence exists. Never merge “failed or skipped.”
- **D-18:** Expired, drifted, and consumed previews require an explicit fresh preview. Preserve the entered reason when safe, explain what changed, and never silently refresh and execute or replay a stale token.
- **D-19:** For ordinary synchronous LiveView work, pending is short and no fake percentage is shown. For genuinely asynchronous host work, accept only real processed/total progress and state that closing does not cancel it. Do not pair a spinner and progress bar for the same operation.
- **D-20:** Use `Phoenix.Component.focus_wrap`, `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, `JS.push_focus`, explicit initial focus or `focus_first`, and `JS.pop_focus`. The initial target is normally the title/consequence block, not the dangerous button. Escape and the visible dismiss control close every dismissible state; once execution has been accepted, any brief non-dismissible state must explicitly say it can no longer be canceled and must not pretend Escape cancels server work.
- **D-21:** Restore focus to the invoker when it remains; otherwise use a required logical fallback supplied by the caller, such as the affected row, bulk toolbar, or page heading. Use `role="dialog"`, not blanket `alertdialog`, because this is a structured preview/form/result workflow.
- **D-22:** Require authorization before preview and again before execution. Results and reasons are escaped, normalized, and redacted before rendering; raw `inspect(error)` output and secret originals are prohibited even in hidden disclosures or data attributes.
- **D-23:** The component contract assumes frozen canonical bulk membership or an equivalent durable preview identifier, exact total/scope, and per-item results. It does not implement a bulk executor. The current unbounded `Jobs.list_ids` plus sequential LiveView execution is a migration/performance risk for Phase 80, not a reason to weaken Phase 78's truth contract.

### FilterBar: Deliberate, Shareable Filtering

- **D-24:** Ship one top-of-results `filter_bar/1`, not a persistent left sidebar. This preserves width for dense tables and follows the Oban Web lesson that a queue sidebar consumed valuable space without enough operator value.
- **D-25:** Use a closed `mode={:submit | :instant}` API with `:submit` as the default. Multi-field Jobs/Forensics filtering uses explicit **Apply filters** so a draft becomes one coherent query. `phx-change` may validate the draft but must not change results or the URL until submit.
- **D-26:** Reserve `:instant` for one cheap, unambiguous criterion such as a state tab or sort selector. If a page deliberately chooses instant text search, debounce it and replace rather than stack history entries. Never silently change apply semantics at a breakpoint.
- **D-27:** Parent LiveViews own draft/applied values, parsing, validation, authorization, Ecto queries, canonical URL serialization, pagination reset, `handle_params/3`, and `push_patch/2`. The applied URL is the shareable source of truth. Invalid drafts retain their entered values and inline errors without mutating results/URL; invalid direct URLs canonicalize with history replacement.
- **D-28:** Preserve the established query meaning: AND between categories, OR within multiple values of one category. URLs serialize stable domain values, not display labels; the component does not mandate a route or query grammar.
- **D-29:** Keep applied filters, exact result summary, per-filter removal, and **Clear filters** visible when filter fields are collapsed. Each applied item reads as a noun/value pair such as “Queue: critical” and has a real named button or link with a caller-supplied canonical removal path. Do not make `StatusPill` masquerade as an interactive chip.
- **D-30:** In submit mode, disclose draft divergence with subtle truthful copy such as “Changes not applied.” Applying or clearing filters moves/announces results through a restrained `role="status"` summary without chatty announcements for every validation keystroke.
- **D-31:** At narrow widths, use a conventional `Filters (3 applied)` disclosure with `aria-expanded` and `aria-controls`; keep applied filters and result count outside it, and place Apply after the fields. Use one DOM and the existing scoped disclosure approach. No horizontal page scroll or duplicate mobile control tree.
- **D-32:** The API accepts the Phase 75 form plus constrained primary/advanced field slots, events or caller-owned JS commands, active-filter maps, clear/removal destinations, result summary, dirty state, and results target. Phase 78 does not add saved filters, async suggestions, comboboxes, a filter query language, or page-specific Ecto behavior.

### Detail Drawer/Panel: One Adaptive Master/Detail Surface

- **D-33:** Deliver the requirement as one `detail_surface/1` with closed variants `:adaptive | :inline | :drawer`; default to `:adaptive`. This gives consumers one content contract while making modality explicit. Do not render separate hidden desktop/mobile detail trees.
- **D-34:** In adaptive mode, use a content-driven wide breakpoint around `64rem`: a nonmodal inline-end panel on sufficiently wide layouts, a modal full-height drawer below it, and a full-screen surface at 320px. Inline preserves comparison; drawer preserves focus on constrained widths. Long, mutation-heavy, or structurally complex content gets an **Open full details** route rather than overloading the drawer.
- **D-35:** Use one native `<dialog>` content tree with a small scoped, idempotent client hook that calls `show()` for nonmodal inline presentation and `showModal()` for modal presentation, safely changes mode on resize, and resynchronizes after LiveView patches. This uses platform inertness/focus containment without a new dependency. Do not wrap adaptive content unconditionally in `focus_wrap`, which would wrongly trap the wide inline panel.
- **D-36:** Modal drawer behavior: background is inert, focus enters the labelled surface, Tab/Shift-Tab remain contained, Escape and the visible close button close it, and focus returns to the invoker or a caller-supplied logical fallback. Inline behavior: no trap, no inert background, and the results remain interactive. Both modes have a visible heading and a close button with a resource-specific accessible name.
- **D-37:** The selected trigger/row is indicated by text/icon plus visual treatment and programmatically with `aria-expanded`/`aria-controls`; color alone is insufficient. A successful content replacement may receive one polite announcement such as “Job 123 details loaded.”
- **D-38:** Parent LiveViews own selection, fetching, authorization, redaction, mutations, route grammar, and history. Initial open pushes a meaningful detail URL; switching selected rows while open replaces that entry; explicit close replaces with the filter-preserving list URL; Back after initial open closes naturally; direct/reloaded URLs work with a logical focus fallback.
- **D-39:** Use one body scroll region for a narrow drawer and avoid nested page/panel scrolling on wide layouts, except bounded machine-data blocks. Motion is restrained transform/opacity feedback and becomes instant under reduced motion.
- **D-40:** Loading, unavailable, permission-denied, error, empty, and ready content are explicit inputs. Never lazy-fetch from the component, hide sensitive duplicate DOM, or place a dialog inside the modal drawer. A confirmation launched from a drawer must first leave/close the drawer or use a full details route so modal dialogs are never nested.

### AttentionCard and “Why Blocked?”: Current Operator Truth

- **D-41:** `attention_card/1` answers “What needs attention?”; `why_blocked/1` answers “What currently prevents progress, what is affected, and what is safe next?” Keep them distinct from notifications, toasts, audit history, and generic alert boxes.
- **D-42:** Keep domain status separate from severity/attention priority. Require a human title and summary, impact/scope, observed-at time, and evidence completeness (`:complete | :partial | :unknown | :unavailable`). Missing completeness defaults to `:unknown`, never `:complete`.
- **D-43:** AttentionCard is persistent and contextual while its condition remains, not dismissible and not automatically `role="alert"`. Permit one primary next action and restrained secondary destinations such as Audit or Forensics. A deliberately dynamic update may use `role="status"` or `role="alert"` according to urgency but must not steal focus.
- **D-44:** Use urgency sparingly: neutral chrome dominates; severity color is paired with icon/text/position; no nested cards, badge soup, decorative status color, or alarm fatigue. The whole answer and primary next step remain readable at 320px.
- **D-45:** `why_blocked/1` accepts multiple blocker presentation maps and shows every blocker the caller deliberately supplies. Each gives a plain label/summary, clearing condition, evidence source, and optional technical code. The visible order is direct answer, current blockers and clearing conditions, impact, what the operator can do, freshness/completeness, then technical evidence.
- **D-46:** Say “current blocker/cause,” not “root cause,” unless causality is proven. Label current state and block-start snapshot separately. Never infer current truth from an audit event, timeline proximity, or a partial snapshot; never say “No blockers” when evidence is stale, partial, unavailable, or permission-denied.
- **D-47:** Permission-disabled actions remain discoverable with the reason. If no legal action exists, provide an honest next route or clearing condition rather than inventing a button. Small redaction-safe evidence may use native `<details>`; large payloads link to Forensics and are not placed in collapsed DOM.

### AuditEntry: Immutable Historical Evidence

- **D-48:** `audit_entry/1` is an immutable historical statement answering who did/requested what, to which target, why, when, through which source, and with what recorded outcome. It is not current status, causal proof, a notification, or the forensic event log.
- **D-49:** Render an `<article>` within the existing Timeline/list composition. Use a complete event sentence as its heading, explicit outcome/status, an absolute `<time datetime>` value (relative time may supplement), and a description list for actor, action, target, reason, source, and correlation. Optional redaction-safe changes/evidence are progressively disclosed.
- **D-50:** Existing records with missing fields remain explicit: “No operator reason recorded” and “Outcome not recorded,” never `N/A`, invented success, or hidden absence. System/policy actors are valid and named. A later outcome is a later entry; do not mutate an old entry to resemble current state.
- **D-51:** Use the existing `Audit` schema and normalized metadata only where already recorded. No Phase 78 schema expansion. Presenters supply grammatical summaries and already-redacted before/after values; secrets may not exist anywhere in rendered DOM, copy payloads, titles, or `data-*` attributes.

### JTBD, Design Pillars, and Quality Bar

- **D-52:** Optimize for four users: the on-call operator scanning during an incident; support/admin staff inspecting a resource with permission-aware actions; the application developer opening technical evidence only when needed; and the auditor reviewing immutable actor/reason/outcome history. The maintainer consuming the library gets predictable, compile-visible component APIs and examples without learning backend implementation details.
- **D-53:** The core flow is `AttentionCard -> Why blocked? -> next safe action -> preview/reason/confirm -> exact result -> AuditEntry`. Every link in that chain uses the same nouns and verbs and states what the user provides, what Powertools does with it, and what evidence they receive in return.
- **D-54:** Apply these pillars as merge criteria: usefulness/JTBD; information architecture and progressive disclosure; accessibility/WCAG 2.2 AA; support-truth and recovery; security/privacy/redaction; reliability and concurrency truth; responsive reflow; performance/bounded DOM; consistent tokens, vocabulary, and affordances; calm visual hierarchy; reduced-motion-safe feedback; localization-resistant layout/long content; and developer ergonomics/documentation.
- **D-55:** Follow familiar platform and Phoenix patterns, recognition over recall, one primary next action per local decision, proximity between explanation and action, comfortable target sizes, visible focus, and a strong terminal receipt. Interaction feedback should normally begin within 300ms; never animate keyboard interaction or make motion necessary to understand state.
- **D-56:** Verify light, dark, system, and high-contrast themes at 320px, tablet, and wide viewports; 200% zoom; reduced motion; axe with zero critical/serious issues; keyboard focus order/trapping/restoration; screen-reader announcement quality; no color-only state; long IDs/Unicode/missing fields; stale/unavailable/permission states; and redacted originals absent from the full DOM.

### Showcase, Documentation, and Acceptance Stories

- **D-57:** Add a dedicated operator-pattern story catalog and integrate it with the existing showcase/manifest fail-closed architecture. Bump the manifest schema exactly once for the new catalog and preserve stable story IDs/open-state targets for VRT and accessibility tests.
- **D-58:** Confirmation stories: `group-confirm-single-reversible`, `group-confirm-single-destructive`, `group-confirm-bulk-count`, `group-confirm-pending`, `group-confirm-partial-results`, and `group-confirm-drifted-error`.
- **D-59:** Filter/detail stories: `group-filter-submit`, `group-filter-instant`, `group-filter-active-clear`, `group-filter-unapplied-invalid`, `group-detail-inline`, `group-detail-modal`, `group-detail-loading-unavailable`, and `group-detail-long-content`.
- **D-60:** Explanation/audit stories: `group-attention-status-severity-matrix`, `group-attention-long-content-and-actions`, `group-why-blocked-multiple-causes`, `group-why-blocked-live-vs-snapshot`, `group-why-blocked-unavailable-evidence`, `group-audit-entry-actor-outcome-matrix`, `group-audit-entry-missing-fields`, `group-audit-entry-redacted-changes`, and `group-explain-audit-narrow-layout`.
- **D-61:** Tests must prove contracts, not only screenshots: reason/count server validation; stale preview rejection; duplicate-submit protection; partial row ordering/recovery; URL/history semantics in a harness LiveView; direct-link/focus fallback; modal inert/focus/Escape/restore and no wide focus trap; resize mode changes; filter draft vs applied truth; disclosure keyboard behavior; absolute audit time; no nested interactivity/dialogs; no hidden secrets; and honest unknown fallbacks.

### Claude's Discretion

The maintainer explicitly delegated all Phase 78 product, architecture, DX, and UI/UX decisions after asking for broad/deep research and a coherent one-shot recommendation. Planning may choose private helper names, exact token-backed spacing, the precise breakpoint after testing real table/content pressure, and the internal normalized-map implementation. It may not reopen the public behavior, ownership boundaries, state semantics, copy contract, modal rules, or scope decisions above without new contradictory evidence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** The current `guides/brand-book.md` is authoritative wherever older prompt material conflicts with it.

### Product Scope and Requirements

- `.planning/PROJECT.md` — product vision, host/library boundaries, operator guarantees, and mutation ownership.
- `.planning/ROADMAP.md` — Phase 78 boundary and success criteria; Phase 79/80 page-migration boundary.
- `.planning/REQUIREMENTS.md` — GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02, and adjacent quality requirements.
- `.planning/STATE.md` — current milestone state and prior decisions.
- `guides/brand-book.md` — canonical identity, explain-then-act, copy, danger, theming, motion, and support-truth rules.

### Requested Research and Product Strategy Inputs

- `prompts/oban-powertools-deep-research-original-prompt.md` — original competitive, ecosystem, architecture, and operations research lenses.
- `prompts/oban_powertools_context.md` — product context, personas, vocabulary, and backend capability inventory.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — UI strategy, flows, information hierarchy, accessibility, and design-system direction; defer to the newer brand book on conflicts.

### Component Contracts Already Established

- `.planning/phases/74-primitives-library/74-CONTEXT.md` — stateless primitive API, semantic variants, token-only styling, and no escape-hatch decisions.
- `.planning/phases/74-primitives-library/74-UI-SPEC.md` — primitive visual/accessibility contract.
- `.planning/phases/75-form-components/75-CONTEXT.md` — `Phoenix.HTML.Form`, parent-owned form state/events, filter-ready fields, validation, and accessibility ownership.
- `.planning/phases/75-form-components/75-PATTERNS.md` — established form composition examples and prohibitions.
- `.planning/phases/75-form-components/75-UI-SPEC.md` — form visual, responsive, focus, and error-state rules.
- `.planning/phases/76-navigation-app-shell/76-PATTERNS.md` — URL/navigation ownership, focus restoration, responsive same-DOM behavior, and shell integration.
- `.planning/phases/76-navigation-app-shell/76-UI-SPEC.md` — responsive shell and client disclosure behavior.
- `.planning/phases/77-data-display-operator-patterns/77-CONTEXT.md` — status taxonomy, explicit data states, redaction, story-catalog, and parent-owned data decisions.
- `.planning/phases/77-data-display-operator-patterns/77-PATTERNS.md` — reusable DataDisplay API and same-DOM responsive rules.
- `.planning/phases/77-data-display-operator-patterns/77-UI-SPEC.md` — table, timeline, status, toast, long-content, and evidence visual contracts.

### Existing Runtime and Showcase Integration

- `lib/oban_powertools/web/components/primitives.ex` — buttons, links, surfaces, disclosure-adjacent primitives, semantic tones, and focus-visible styling.
- `lib/oban_powertools/web/components/forms.ex` — form controls and validation building blocks.
- `lib/oban_powertools/web/components/data_display.ex` — StatusPill, Timeline, Toast/Flash, progress, empty/data states, and redacted evidence presentation.
- `lib/oban_powertools/web/control_plane_presenter.ex` — existing centralized operator vocabulary/presentation seam.
- `lib/oban_powertools/lifeline/repair_preview.ex` — preview statuses, token/scope/evidence fields, expiry/drift/consumption, and reason requirements.
- `lib/oban_powertools/lifeline.ex` — authoritative execute/recheck/audit transaction and reason validation.
- `lib/oban_powertools/audit.ex` — available immutable audit fields and helper vocabulary.
- `lib/oban_powertools/explain.ex` — structured explainability inputs.
- `lib/oban_powertools/batches.ex` — current blocked-state inputs and bulk semantics.
- `lib/oban_powertools/web/jobs_live.ex` — current filtering, modal duplication, preview, bulk, and URL behavior that later migration must preserve/improve.
- `lib/oban_powertools/web/batches_live.ex` — current confirmation/result and reason behavior.
- `lib/oban_powertools/web/lifeline_live.ex` — mature preview/reason/expiry/drift/execute flow and current eight-character rule.
- `lib/oban_powertools/web/workflows_live.ex` — existing URL-selected inline detail precedent.
- `assets/oban_powertools/theme.js` — existing scoped client interaction and focus behavior; integration point for an idempotent adaptive-dialog hook.
- `test/support/showcase_catalog.ex` — showcase manifest/catalog integration and reserved operator-group surface.
- `test/support/data_display_story_catalog.ex` — adjacent fail-closed story-catalog pattern.
- `scripts/showcase_manifest.exs` — manifest schema generation and package-boundary behavior.
- `test/browser/specs/showcase.a11y.spec.ts` — automated accessibility matrix.
- `test/browser/specs/showcase.structure.spec.ts` — behavioral/DOM contract tests.
- `test/browser/specs/showcase.vrt.spec.ts` — theme/viewport visual-regression matrix.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Primitives`, `Forms`, and `DataDisplay`: provide nearly all leaf UI; Phase 78 should primarily compose and add state semantics.
- `Phoenix.Component.focus_wrap` and pinned LiveView `JS.push_focus/focus_first/pop_focus`: implement confirmation focus behavior without a new dependency.
- Native `<dialog>` plus a scoped hook: supports the adaptive detail surface's modal/nonmodal distinction with one DOM tree.
- `RepairPreview` and `Lifeline.execute_repair/5`: already encode authoritative preview, drift, expiry, single-use, reason, execution, and audit guarantees.
- `ControlPlanePresenter`, `Explain`, `Batches.blocked_state`, and `Audit` helpers: provide the normalization seams for human explanations and immutable entries.
- Existing story catalogs and manifest reservation: allow a distinct operator-pattern catalog rather than mixing group fixtures into leaf-component catalogs.

### Established Patterns

- Parent LiveViews own server and navigation semantics; components render caller-supplied state and events/JS commands.
- Same-DOM responsive behavior prevents duplicate IDs, duplicate controls, secret leakage, and divergent keyboard behavior.
- URL state is canonical and shareable; `handle_params/3` parses it and `push_patch/2` changes it without replacing page ownership.
- Redaction is structural and fail-closed before rendering; hiding a value visually does not make it safe.
- Theme and spacing values come from the isolated token layer; four themes and 320px behavior are first-class acceptance criteria.

### Integration Points

- Add `OperatorPatterns` beside the three existing component modules and make it available through the same documented import/use path.
- Add only the minimal adaptive-dialog behavior to the existing shipped JS lifecycle, with tests for reconnect, patch, resize, and reduced motion.
- Extend presenter helpers rather than embedding domain branching in HEEx.
- Register operator-group stories in the showcase manifest/schema and add component, LiveView harness, browser structure, accessibility, and VRT coverage.
- Phases 79 and 80 replace current page-local markup with these contracts; Phase 78 may use harness stories but must not migrate page behavior itself.

</code_context>

<specifics>
## Specific Ideas

The visual and interaction direction is a calm operations console: cool neutral chrome, sparse semantic color, consequence-first copy, strong noun/verb consistency, progressive disclosure of technical evidence, and conventional browser/Phoenix affordances. The UI should optimize recognition and recovery under incident stress, not advertise backend architecture.

External patterns considered in the recommendation include WAI-ARIA APG modal dialogs; Phoenix function components, form bindings, URL patching, and focus JS; Primer confirmation/delete/filter/dialog guidance; Carbon modal/filter/data-table guidance; PatternFly toolbar, drawer, warning-modal, alert, and status/severity patterns; GOV.UK/MOJ errors and applied filters; Kubernetes conditions/events/dry-run truth semantics; Grafana current-state/history/runbook separation; Oban Web's shareable filters and removed queue sidebar; and operational lessons from Sidekiq, GoodJob, GitHub Actions, Argo, and Cloudscape.

The lessons retained are: use ecosystem-native composition; keep URLs shareable; make friction proportional to blast radius; preview through the real execution path; retain partial results as evidence; separate status, severity, current explanation, and history; keep dense-table width; use progressive disclosure without hiding required answers; and never claim outcomes or causality the available evidence cannot prove.

</specifics>

<deferred>
## Deferred Ideas

- Phase 79/80 page migrations, including concrete route/query grammars and replacing current page-local modals/filters/details.
- A scalable asynchronous/batched bulk executor for large Jobs selections; Phase 80 should address the current unbounded ID list and sequential LiveView loop without changing Phase 78's presentation contract.
- Saved filters, async value suggestions, comboboxes, filter query languages, personal presets, or a persistent filter sidebar.
- New audit columns/schemas, causal inference, a unified backend “root cause” engine, or treating event history as current state.
- New operator actions, permissions, mutation semantics, support boundaries, or runtime dependencies.
- Full-detail pages or new route structures beyond the component's escape-hatch slot and parent-owned navigation contract.

</deferred>

---

*Phase: 78-Component Groups (Meta-Components)*
*Context gathered: 2026-07-18*
