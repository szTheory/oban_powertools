# Phase 77: Data-Display & Operator Patterns - Context

**Gathered:** 2026-07-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 77 builds the shared data-display layer for the v2.0 Powertools Identity milestone. It ships reusable Phoenix function components for dense operator data, unifies status presentation across Oban/Powertools domains, and adds data-display showcase, VRT, axe, and targeted browser evidence.

This phase is a component-foundation phase, not a page migration and not a new operator capability. It gives later group and page phases a reliable substrate for tables, description lists, status pills, timelines, progress, metrics, code/args rendering, redaction marks, empty states, and toast/flash feedback.

The approved `77-UI-SPEC.md` already locks the visual, interaction, accessibility, redaction, copy, evidence, and scope contracts. No additional user-facing gray area required escalation in this discuss pass.

In scope:

- Shared `Phoenix.Component` data-display components: DataTable, stacked table rows, KeyValue/DescriptionList, Timeline, ProgressBar, MetricCard, CodeBlock, ArgsViewer, RedactedValue, EmptyState, and Toast/Flash.
- A unified status taxonomy that maps all known Oban/Powertools states to `StatusPill` presentation data.
- Explicit loading, empty, error, unavailable, and permission-denied states for data components.
- 320px-safe stacked/card table fallback, long-value handling, bounded code overflow, and copy/expand affordances where needed.
- Shared redaction and `DisplayPolicy` rendering through one component path.
- Dev/test-only data-display story catalog, generated manifest schema extension, VRT/a11y targets, targeted Playwright behavior checks, and static guards.

Out of scope:

- FilterBar, saved filters, filter grammar, chips, and jobs/forensics URL filter migration.
- ConfirmActionDialog, danger forms, required-reason confirmations, dry-run result groups, DetailDrawer/Panel, AttentionCard, AuditEntry, and "Why blocked?" explainer components.
- Migration of the nine operator page bodies onto the new components.
- New operator capabilities, behavior changes, mutation-flow redesign, or client-side table virtualization.
- New runtime dependencies, JavaScript table packages, PhoenixStorybook, shadcn, Radix, React, Web Components, or host Tailwind/daisyUI integration.
- Full manual screen-reader audit, page-level keyboard traversal, 200% zoom/reflow closure, and the final cross-page a11y/motion/copy sweep.

</domain>

<decisions>
## Implementation Decisions

### Approved UI Contract
- **D-01:** Treat `.planning/phases/77-data-display-operator-patterns/77-UI-SPEC.md` as the binding Phase 77 implementation contract. Downstream agents must not reopen component scope, visual tokens, status tones, redaction copy, showcase targets, or out-of-scope boundaries unless the spec itself is changed.
- **D-02:** Do not ask the user to choose between implementation details that the UI-SPEC, prior phase contexts, Phoenix/LiveView norms, or existing code already resolve. The remaining work is planner/researcher execution, not product vision clarification.

### Component Boundaries
- **D-03:** Add data-display components on top of the existing `ObanPowertools.Web.Components.Primitives` and `ObanPowertools.Web.Components.Forms` layers. Keep them as stateless `Phoenix.Component` function components with `attr/3`, `slot/3`, closed values, explicit assigns, and safe `:global` passthrough.
- **D-04:** Prefer `ObanPowertools.Web.Components.DataDisplay` for component APIs and a small pure supporting module, such as `ObanPowertools.Web.StatusTaxonomy`, for reusable presentation mapping. Exact names are left to planning, but the data-display layer must not bloat primitive or form modules.
- **D-05:** Parent LiveViews own data fetching, authorization, sorting state, pagination state, selection state, URL state, mutation events, and Lifeline/audit flows. Components own semantic markup, visual variants, empty/loading/error rendering, safe formatting, redaction display, and accessibility wiring.
- **D-06:** Preserve the existing visual boundary: no caller `class` or `style` escape hatch, no raw hex in component source, no raw component spacing when a token exists, no host selectors/theme mutation, and no new runtime dependency.

### Data Table And Data States
- **D-07:** DataTable renders a semantic `<table>` at tablet/wide widths with explicit header, body, caption/summary, optional toolbar slot, row key, row count, pagination summary, and state slot. Do not use ARIA grid roles for ordinary data tables.
- **D-08:** Sortable headers are real buttons inside `<th scope="col">`; the sorted column sets truthful `aria-sort`. Parent LiveViews own sort state/events.
- **D-09:** At 320px, DataTable uses a stacked/card row fallback with visible column labels and no page-level horizontal scroll. Row selection remains a labelled checkbox with a 44px effective hit target.
- **D-10:** Loading, empty, error, unavailable, and permission-denied are explicit rendered states inside the table/data region, not absent markup. Loading uses named skeleton/status text and `aria-busy`; error/recovery copy follows the UI-SPEC copy contract.
- **D-11:** Code, args, JSON, URLs, stacktraces, and other machine values may use bounded internal overflow. Ordinary table/list/card surfaces must wrap, truncate visibly, stack, or provide copy/expand affordance rather than causing page overflow.

### Status Taxonomy
- **D-12:** Implement one shared status taxonomy that maps every known Oban/Powertools state to the existing `Primitives.status_pill/1` presentation shape: `%{label: "...", tone: :neutral | :info | :success | :warning | :danger, icon: :dot | :info | :check | :alert, sr_prefix: "..."}`.
- **D-13:** Use the UI-SPEC tone rules as canonical: neutral for pending/ordinary/unknown, info for active/running/ready, success for completed/healthy/resolved, warning for retryable/waiting/stale/drifted/ambiguous, and danger for failed/cancelled/discarded/deleted/expired/permission-denied.
- **D-14:** Unknown state strings render as humanized neutral status with the nearest domain `sr_prefix`, and tests/log evidence must make unknowns deterministic so new domain states are intentionally added to the table.
- **D-15:** Phase 77 creates the shared taxonomy and evidence. Full page migration away from local helpers such as `state_badge_tone/1`, `status_badge_class/1`, and `preview_badge_class/1` belongs to later page migration phases unless a narrow in-phase story/test needs a fixture.

### Redaction And Display Policy
- **D-16:** All args, meta, callback payloads/errors, job errors, recorded output, and workflow result payloads render through the shared ArgsViewer/CodeBlock/RedactedValue path.
- **D-17:** `DisplayPolicy.render_job_field/3` tuple values map consistently: `{:raw_json, json}` to labelled JSON CodeBlock, `{:string, text}` to labelled string/text display, and `{:fallback, msg}` to RedactedValue.
- **D-18:** Enqueue-time overlays use visible copy `Redacted at enqueue`; host policy redaction uses `Hidden by display policy`; fallback `[redacted]` is allowed only as RedactedValue payload, never as an unstyled literal.
- **D-19:** Original sensitive values must never be present in DOM text, `title`, tooltip text, `data-*`, copy buffers, expanded views, or JSON pretty-printing output.
- **D-20:** The shared redaction renderer preserves non-redacted sibling fields and does not mutate host-returned policy strings/maps.

### Showcase And Verification
- **D-21:** Add a separate dev/test-only `DataDisplayStoryCatalog`; do not mix data-display component stories into domain stress fixtures, primitive stories, form stories, or shell stories.
- **D-22:** Extend the generated manifest with first-class `data_stories` and data targets, increment schema version from 4 to 5, and append `data_stories` after `shell_stories`. Do not hardcode data target ids in TypeScript.
- **D-23:** Required story targets are `data-table-sort-states`, `data-table-320-stacked`, `data-table-explicit-states`, `data-status-taxonomy-all`, `data-description-list-long-values`, `data-timeline-event-log`, `data-progress-metric-cards`, `data-code-args-redaction`, `data-empty-toast-flash`, and `data-table-thousands-row-stress`.
- **D-24:** VRT snapshots must render real component states across themes `system`, `light`, `dark`, `high-contrast` and viewports `320`, `tablet`, `wide`. Do not mask status colors, focus rings, sort state, stacked labels, redaction overlays, empty/error copy, progress labels, metric values, or toast severity.
- **D-25:** Add targeted Playwright checks beyond axe for sort keyboard/click semantics, `aria-sort`, stacked 320 rows, no page overflow, row selection labels, long value handling, bounded code scrolling, redaction non-exposure, toast roles, and focus visibility.

### Claude's Discretion
- Exact component names, attr names, slot names, CSS class names, helper module names, story catalog internals, fixture shapes, browser spec file names, and plan split are left to research/planning as long as decisions D-01 through D-25 hold.
- The planner may decide whether `MetricCard` composes `Primitives.stat/1` directly or wraps it with a data-display API, provided metrics remain non-interactive unless explicitly rendered as a Link/Button.
- The planner may decide whether the first implementation keeps page-local helpers untouched until page migrations or adds narrow deprecation/static-guard coverage now. It must not turn Phase 77 into a nine-page migration.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` - Phase 77 goal, dependencies, requirements DATA-01..04/A11Y-02, split-risk note, and success criteria.
- `.planning/REQUIREMENTS.md` - v2.0 DATA-01..04, A11Y-02..04, SHOW-01..03, VRT-01..03, FIX-01..03, MOTION-02, COPY-01..02, and later GROUP/PAGE boundaries.
- `.planning/PROJECT.md` - decision posture, no-new-operator-capability milestone boundary, research-first defaults, and Phoenix/LiveView/Ecto/Postgres preference.
- `.planning/STATE.md` - current Phase 77 state, Phase 76 carry-forward decisions, and browser/VRT continuity notes.

### Locked Design And Prior Phase Contracts
- `.planning/phases/77-data-display-operator-patterns/77-UI-SPEC.md` - binding Phase 77 UI, accessibility, redaction, status taxonomy, showcase, and verification contract.
- `guides/brand-book.md` - token, typography, color-as-information, copy, motion, and "explain, then act" source of truth.
- `.planning/phases/74-primitives-library/74-CONTEXT.md` - primitive API boundary, closed variants, `StatusPill` primitive scope, no visual escape hatches, story catalog pattern, and accessibility contracts.
- `.planning/phases/74-primitives-library/74-UI-SPEC.md` - primitive visual/interaction contract that data-display components must compose.
- `.planning/phases/75-form-components/75-CONTEXT.md` - field/form component boundary, native choice controls, filter-ready but not FilterBar scope, generated form story pattern, and URL/filter deferred boundaries.
- `.planning/phases/75-form-components/75-UI-SPEC.md` - form visual/interaction contract data-display row selection and filter-adjacent examples must respect.
- `.planning/phases/76-navigation-app-shell/76-UI-SPEC.md` - shell/showcase/manifest continuation, app-shell context, and Phase 76 visual contract.
- `.planning/phases/76-navigation-app-shell/76-VERIFICATION.md` - latest shell evidence and non-blocking aggregate visual/a11y context.
- `.planning/phases/73-visual-regression-a11y-harness/73-CONTEXT.md` - Docker-backed Playwright/VRT/axe harness, baseline update workflow, artifact policy, and automation limits.
- `guides/visual-regression-and-a11y.md` - current commands, generated manifest workflow, baseline update process, and accessibility claim boundary.

### Existing Code And Tests
- `lib/oban_powertools/web/components/primitives.ex` - existing primitive component APIs, safe rest filtering, `status_pill/1`, `spinner/1`, `skeleton/1`, `tooltip/1`, and `stat/1`.
- `lib/oban_powertools/web/components/forms.ex` - form component API, native inputs, row-selection checkbox boundary, `aria-describedby` merging, and no fake combobox roles.
- `lib/oban_powertools/web/components/app_shell.ex` - shell component pattern and root-scoped composition.
- `lib/oban_powertools/web/dev/showcase_live.ex` - dev-only showcase rendering, component story sections, and story target attributes.
- `test/support/primitive_story_catalog.ex` - separate primitive story catalog pattern.
- `test/support/form_story_catalog.ex` - separate form story catalog pattern.
- `test/support/shell_story_catalog.ex` - separate shell story catalog pattern and schema 4 predecessor.
- `test/support/showcase_catalog.ex` - deterministic domain stress fixtures and adversarial payload examples.
- `scripts/showcase_manifest.exs` - manifest generator to extend with schema 5 and `data_stories`.
- `test/browser/support/manifest.ts` - TypeScript manifest validation to extend for data stories.
- `test/browser/support/showcase.ts` - target location/theme/viewport helper to reuse.
- `test/browser/specs/showcase.vrt.spec.ts` - VRT target pattern data stories must join.
- `test/browser/specs/showcase.a11y.spec.ts` - axe target pattern data stories must join.
- `test/browser/specs/primitives.behavior.spec.ts`, `test/browser/specs/forms.behavior.spec.ts`, and `test/browser/specs/shell.behavior.spec.ts` - targeted behavior-test style to replicate for data-display semantics.
- `assets/oban_powertools/tokens.css` - `.obpt-root` token layer and component CSS source.
- `priv/static/oban_powertools/oban_powertools.css` - compiled package asset that must be updated through the existing deterministic asset path.
- `lib/oban_powertools/runtime_config.ex` - `DisplayPolicy` rendering and redaction fallback behavior that ArgsViewer/RedactedValue must consume safely.
- `lib/oban_powertools/web/jobs_live.ex`, `lib/oban_powertools/web/batches_live.ex`, `lib/oban_powertools/web/workflows_live.ex`, `lib/oban_powertools/web/lifeline_live.ex`, `lib/oban_powertools/web/forensics_live.ex`, `lib/oban_powertools/web/audit_live.ex`, `lib/oban_powertools/web/cron_live.ex`, and `lib/oban_powertools/web/control_plane_presenter.ex` - current local status, table, progress, redaction, timeline, and data-display patterns to consolidate or preserve for later migrations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Web.Components.Primitives` already provides stateless components, closed visual variants, safe rest filtering, `StatusPill`, named loading primitives, tooltip semantics, and compact metric/stat treatment.
- `ObanPowertools.Web.Components.Forms` already provides field-first native inputs, label/hint/error wiring, event-driven row-selection checkbox behavior, and filter-ready native controls.
- `ObanPowertools.Web.Components.AppShell` and `ThemeShell` preserve the `.obpt-root` boundary and current shell/showcase context.
- Existing story catalogs prove the right dev/test-only registry shape: component-specific catalog modules under `test/support`, generated manifest entries, and showcase render sections.
- `DisplayPolicy.render_job_field/3` and `DisplayPolicy.workflow_result/2` already normalize host policy output into tuple/map shapes; Phase 77 should render those shapes safely rather than reinterpreting host policy.
- Existing LiveViews contain concrete migration examples for data tables, progress bars, status badges, redaction disclosures, timelines, key/value details, empty states, and copy boundaries.

### Established Patterns
- Components are Phoenix function components, not LiveComponents, JavaScript table libraries, or host-facing UI-kit abstractions.
- Parent LiveViews own behavior and state; component modules own semantics, safe presentation, token-backed classes, and accessibility.
- Visual values live in `.obpt-root`-scoped token CSS and compiled package CSS. Raw Tailwind-style literals in new component code are not acceptable.
- Showcase targets are generated from Elixir-owned catalogs; TypeScript validates and consumes generated data instead of hardcoding story IDs.
- Browser evidence is Docker-backed Playwright over the real example-host showcase route, with VRT, axe, and targeted behavior specs used together.

### Integration Points
- Add data-display component code under `lib/oban_powertools/web/components/`, likely as `data_display.ex`.
- Add a shared pure presenter/taxonomy module under `lib/oban_powertools/web/` or a nearby namespace for status mappings and redaction presentation helpers.
- Add render/static tests under `test/oban_powertools/web/components/`, mirroring primitive/form component tests.
- Add `test/support/data_display_story_catalog.ex` and render it from `lib/oban_powertools/web/dev/showcase_live.ex`.
- Extend `scripts/showcase_manifest.exs`, `test/browser/support/manifest.ts`, `test/browser/support/manifest-smoke.mjs`, and generated manifest fixtures for schema 5.
- Add or extend browser specs for data-display behavior, then let the existing VRT/a11y specs pick up generated data targets.
- Update `assets/oban_powertools/tokens.css` and rebuild `priv/static/oban_powertools/oban_powertools.css` through the existing deterministic asset process.

</code_context>

<specifics>
## Specific Ideas

- Use the UI-SPEC required story IDs exactly unless planning finds a naming collision: `data-table-sort-states`, `data-table-320-stacked`, `data-table-explicit-states`, `data-status-taxonomy-all`, `data-description-list-long-values`, `data-timeline-event-log`, `data-progress-metric-cards`, `data-code-args-redaction`, `data-empty-toast-flash`, and `data-table-thousands-row-stress`.
- Favor examples using real operator nouns: Job, Worker, Queue, Batch, Callback, Workflow, Step, Lifeline preview, Limiter, Cron, Audit log, Args, Meta, Result, Reason, Repair, Blocked.
- Required copy examples are locked by UI-SPEC: `Refresh data`, `No rows match the current filters`, `Clear filters or widen the time window.`, `Data did not load. Retry the request or check the host logs.`, `Redacted at enqueue`, and `Hidden by display policy`.
- Stress fixtures should include huge args/meta payloads, nested redaction, long IDs, long module names, long URLs, stacktraces, non-ASCII text, emoji, RTL text, empty/loading/unavailable/permission-denied/stale/disconnected states, boundary pagination, and thousands-of-rows windowing.
- This discuss pass intentionally did not generate a broad option menu. The repo's current decision posture prefers carrying forward locked contracts and one coherent recommendation set when no product-level fork remains.

</specifics>

<deferred>
## Deferred Ideas

- FilterBar, saved filters, filter grammar, chips, and Jobs/Forensics URL filter migration remain Phase 78 and Phase 80 work.
- ConfirmActionDialog, danger forms, required-reason confirmation, dry-run result groups, DetailDrawer/Panel, AttentionCard, AuditEntry, and "Why blocked?" explainer remain Phase 78 work.
- Migrating the nine operator page bodies onto data-display/group components remains Phases 79-81 work.
- Full page-level keyboard traversal, manual screen-reader review, 200% zoom/reflow, final motion/copy hardening, and final cross-page accessibility closure remain Phase 82 work.
- Showcase completion and contributor documentation remain Phase 83 work.
- No matching TODOs were folded or reviewed during this discuss pass.

</deferred>

---

*Phase: 77-Data-Display & Operator Patterns*
*Context gathered: 2026-07-12*
