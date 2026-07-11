# Phase 75: Form Components - Context

**Gathered:** 2026-07-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 75 builds the accessible form component layer for the v2.0 Powertools Identity milestone. It adds token-backed `Phoenix.Component` form primitives built on `to_form` / `Phoenix.HTML.FormField`, registers form stories in the existing dev-only showcase, and extends the existing visual-regression, axe, and targeted browser behavior gates.

This phase is still a component-foundation phase. It does not migrate the 9 operator pages, does not own `FilterBar`, does not implement the destructive-action dialog pattern, and does not add new operator capability. It gives later data, group, and page phases a reliable field/control substrate so they do not copy ad hoc labels, inputs, errors, checkboxes, and reason-field markup across LiveViews.

In scope:

- `Phoenix.Component` form primitives for Input, Textarea, Select, Checkbox, Radio, Switch, filter-ready text inputs, FieldGroup, Label, Hint, and Error.
- Default `field={@form[:name]}` API over `Phoenix.HTML.FormField`, with map-backed forms handled through `to_form`.
- Programmatic labels, hint/error association, visible focus, non-color validation signals, and distinct disabled/read-only states.
- Native input semantics for checkbox/radio/switch controls, with token-only styling and no host CSS dependency.
- Form story catalog entries, generated manifest integration, VRT/axe coverage, and targeted browser assertions for label/error wiring and keyboard behavior.

Out of scope:

- Full APG combobox/typeahead, async suggestions, chips, multi-select filter grammar, saved filters, or `FilterBar`; those belong to Phases 77, 78, and 80.
- Destructive reason/confirm meta-patterns such as `ConfirmActionDialog` or `<.danger_form>`; Phase 75 supplies fields, while Phase 78 owns the explain-then-act group.
- Page migration of Jobs, Batches, Cron, Lifeline, Audit, Forensics, Workflows, Limiters, or Overview; that belongs to Phases 79-81.
- A host-facing generic Phoenix UI kit, schema/DSL form generator, third-party headless UI runtime, or production showcase exposure.

</domain>

<decisions>
## Implementation Decisions

### Field API Shape
- **D-01:** Add a separate `ObanPowertools.Web.Components.Forms` module beside `ObanPowertools.Web.Components.Primitives`. Do not extend `Primitives` with form semantics; Phase 74 primitives remain the lower visual/semantic base, while Phase 75 owns label, hint, error, group, and form-field behavior.
- **D-02:** Keep form components stateless function components. Parent LiveViews continue to own changesets/maps, URL serialization, validation events, authorization, mutation flow, and persistence. Form components own semantic markup, token-backed visual states, safe attribute passthrough, and accessibility wiring.
- **D-03:** Make `field={@form[:field]}` the normal high-level API. The component should derive `id`, `name`, `value`, and errors from `Phoenix.HTML.FormField`; map-backed filters should use `to_form(%{}, as: "filter")` or equivalent rather than bypassing the form model.
- **D-04:** Provide narrow typed wrappers such as `input/1`, `textarea/1`, `select/1`, `checkbox/1`, `radio_group/1`, `switch/1`, `field_group/1`, `label/1`, `hint/1`, and `error/1`. Exact names are left to planning, but the API should remain boring, discoverable, and close to Phoenix conventions.
- **D-05:** Do not introduce a schema/macro DSL such as `use Forms.Schema` in this phase. A DSL would overfit a generic CRUD/admin problem, hide HEEx/a11y details, and create a public support promise before the native pages prove the component surface.
- **D-06:** Preserve the Phase 74 visual boundary: no arbitrary caller `class` or `style` escape hatch in normal form components. Allow caller-owned `id`, `phx-*`, `aria-*`, `data-*`, `name`, `value`, `form`, `placeholder`, `autocomplete`, `required`, debounce/throttle attrs, and other native attributes only where the control semantics need them.

### Validation And Error Semantics
- **D-07:** Encode accessibility in the form API. Every high-level field needs a non-empty visible label, or a programmatically associated fieldset/legend for grouped choices. Placeholder text is never the label.
- **D-08:** Auto-wire descriptions. Hints and errors should receive stable ids derived from the field id, such as `#{field.id}-hint` and `#{field.id}-error`; components must merge those ids with any caller-provided `aria-describedby` instead of overwriting it.
- **D-09:** Set `aria-invalid="true"` only when a visible error is actually rendered for the control or group. Errors must be text, not color-only; include an explicit error indicator/prefix in a screen-reader-safe way and a token-backed visual state in light, dark, system, and high-contrast themes.
- **D-10:** Use Phoenix's interaction timing where available. For changeset-backed fields, prefer `Phoenix.Component.used_input?/1` or equivalent logic so validation does not shout before the operator has interacted, while submit-time/action-level errors can still be passed explicitly for existing reason flows.
- **D-11:** Error copy should be field-specific and recovery-oriented. Do not surface raw backend implementation details when a user-facing message is available. Existing action errors such as `reason_required` and `reason_too_short` should render through the shared form error pattern without changing the mutation semantics.
- **D-12:** Disabled and read-only are different states. Native `disabled` is for temporarily unavailable controls that need not be read or submitted. Read-only is for information the operator should review but cannot edit; it must preserve contrast/readability and remove or de-emphasize interactive affordance. When an unavailable control needs an explanation, use a perceivable description and suppress actions rather than silently hiding it.

### Selectable Controls
- **D-13:** Use native HTML inputs for checkbox, radio, and switch primitives. Do not hand-roll ARIA checkbox/radio/switch behavior in Phase 75. Native semantics carry keyboard, form submission, mobile, and assistive-technology behavior with less risk.
- **D-14:** `checkbox/1` should support two distinct use cases: named boolean form fields and event-driven row selection. Emit Phoenix-style hidden unchecked values only for named boolean form fields; do not emit hidden unchecked values for row-selection checkboxes driven by `phx-click` / `phx-value-*`.
- **D-15:** `radio_group/1` should render a `fieldset` and `legend`, with group-level hint/error association. Do not preselect a radio unless there is a real default. If clearing the choice is valid, include an explicit option such as "None" or "Any" rather than relying on browser refresh.
- **D-16:** `switch/1` should be a checkbox-backed visual variant for immediate, reversible binary settings where the affected attribute is clear. It should not replace checkboxes in delayed submit forms merely for visual novelty. The label must name the setting; on/off color is never the only state signal.
- **D-17:** Choice controls need comfortable hit targets, visible focus, label-click behavior, and 320px-safe wrapping. Table row selection can use compact visual treatment, but each checkbox still needs an accessible label or table-header context.

### Combobox And Filter Boundary
- **D-18:** Phase 75 should ship filter-ready text/select primitives, not a full combobox. A useful API may include a narrow `filter_input/1` or `variant={:filter}` on input, but it must remain an ordinary semantic text/search control unless it implements a popup.
- **D-19:** Do not use `role="combobox"` or combobox ARIA attributes on plain filter inputs. A true combobox requires the APG popup, expanded/collapsed state, active descendant, keyboard behavior, and manual accessibility verification.
- **D-20:** Defer `FilterBar`, chips, removable tags, multi-select dropdowns, async queue/worker/tag suggestions, saved filters, and filter-operator grammar to later phases. Phase 77 owns data-display primitives, Phase 78 owns group/meta-components including `FilterBar`, and Phase 80 owns Jobs/Forensics filter migration and URL behavior.
- **D-21:** Preserve canonical URL semantics when later phases migrate filters. Serialize canonical values, not display labels; debounce or batch expensive filter updates; do not auto-submit on option highlight/selection; keep display affordances separate from query semantics.

### Showcase, Evidence, And Testing
- **D-22:** Add a separate dev/test-only form story catalog, analogous to `ObanPowertools.PrimitiveStoryCatalog`, instead of mixing form component stories into the domain stress fixture catalog.
- **D-23:** Extend the generated Playwright manifest with form targets rather than hardcoding form story lists in TypeScript. The target shape may become `kind: "form"` or another planner-chosen schema, but it must keep scenario, primitive, and form stories as first-class generated targets.
- **D-24:** Form stories should cover valid, invalid, required, optional, disabled, read-only, loading/pending, filter-ready, long label/value, and 320px wrapping states across system/light/dark/high-contrast themes.
- **D-25:** Add targeted browser checks beyond axe for label association, hint/error `aria-describedby` merging, `aria-invalid`, keyboard operation of choice controls, disabled/read-only contrast, visible focus, no horizontal overflow at 320px, and reduced-motion-safe transitions.
- **D-26:** Keep static guards aligned with Phase 74: no raw hex in component source, no raw component pixel values where tokens exist, no host selectors, no host theme mutation, no caller visual escape hatches, and no new runtime dependencies.

### Claude's Discretion
- Exact component names, helper function names, CSS class names, story ids, manifest schema extension, and plan split are left to research/planning, provided the decisions above hold.
- The planner may choose whether `input/1` is a polymorphic `type` wrapper or whether text/search/email/number have thin named wrappers. The preferred direction is the smallest API that stays explicit, tested, and easy to grep.
- The planner may reuse existing `.obpt-form-label` and `.obpt-input` proof-seam CSS as implementation material, but Phase 75 must not remain CSS classes only.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Requirements And Scope
- `.planning/ROADMAP.md` section "Phase 75: Form Components" - phase goal, dependency on Phase 74, requirements, and success criteria.
- `.planning/ROADMAP.md` sections "Phase 77", "Phase 78", and "Phase 80" - later ownership for data-display, `FilterBar`, destructive forms, Jobs/Forensics filter migration, and URL-serialized filter state.
- `.planning/REQUIREMENTS.md` section "Form Components (FORM)" - FORM-01 and FORM-02 are Phase 75's direct requirements; FORM-03 and FORM-04 are later-phase boundaries.
- `.planning/REQUIREMENTS.md` sections "Accessibility (A11Y)", "Component Showcase (SHOW)", "Visual Regression (VRT)", "Component Groups / Meta-Components (GROUP)", and "Pages & Flows (PAGE)" - a11y, showcase, browser gate, group, and page-migration constraints.
- `.planning/PROJECT.md` sections "Decision Posture" and "Current Milestone: v2.0 Powertools Identity" - research-first defaults, no new operator capability, Phoenix/LiveView/Ecto/Postgres norms, isolated library-owned design system, and one-shot recommendation posture.

### Prior Locked Decisions
- `guides/brand-book.md` - current brand source of truth; use this over older prompt visual guidance. Especially D-05 color-as-information, color-never-sole-signal, affordance honesty, D-11/D-12 contrast/focus, D-16..D-21 microcopy and explain-then-act rules.
- `.planning/phases/70-brand-book-identity-foundation/70-CONTEXT.md` - locked brand decisions and context behind the brand book.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-02-SUMMARY.md` - token CSS and two-tier `--obpt-*` role contract.
- `.planning/phases/71-token-layer-isolated-theming-engine/71-05-SUMMARY.md` - existing JobsLive proof seam for token-backed form/button/modal classes.
- `.planning/phases/72-stress-fixtures-showcase-skeleton/72-CONTEXT.md` - dev-only showcase route, stable anchors/selectors, and catalog boundary.
- `.planning/phases/73-visual-regression-a11y-harness/73-CONTEXT.md` - Playwright/axe harness, baseline workflow, artifact policy, and automation limits.
- `guides/visual-regression-and-a11y.md` - current VRT/a11y commands, matrix, snapshot update process, and accessibility claim boundary.
- `.planning/phases/74-primitives-library/74-CONTEXT.md` - primitive API, closed variants, no visual escape hatches, strict accessibility contracts, story catalog, and deferred boundaries that Phase 75 extends.
- `.planning/phases/74-primitives-library/74-RESEARCH.md` - implementation-ready primitive research, stack versions, and existing browser harness integration.
- `.planning/phases/74-primitives-library/74-UI-SPEC.md` - visual/interaction contract that Phase 75 form controls should extend.

### User-Requested Prompt Context
- `prompts/oban_powertools_context.md` - Phoenix-first OSS operator layer, personas/JTBD, domain language, dashboard/filter/search expectations, and DX/SRE/devops lenses.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` - Ops Console strategy, hybrid native/bridge posture, dangerous-action vocabulary, filter/search context, and operator UX priorities.
- `prompts/oban-powertools-deep-research-original-prompt.md` - user directive to learn from Oban Pro/Web, Sidekiq, GoodJob, Mission Control, and similar ecosystems while keeping great DX, architecture, CI, and operator experience.

### Existing Implementation Seams
- `lib/oban_powertools/web/components/primitives.ex` - Phase 74 component API/rest-filtering pattern to mirror without bloating primitive scope.
- `test/oban_powertools/web/components/primitives_test.exs` - source/render contract pattern for no raw visual values, closed variants, accessibility requirements, and rest filtering.
- `assets/oban_powertools/tokens.css` - token source and current `.obpt-form-label` / `.obpt-input` proof-seam CSS.
- `priv/static/oban_powertools/oban_powertools.css` - compiled package asset that must be updated through the existing asset build path.
- `lib/oban_powertools/web/dev/showcase_live.ex` - dev-only showcase route, current primitive story rendering, and reserved Forms section.
- `test/support/primitive_story_catalog.ex` - model for a separate component story catalog.
- `scripts/showcase_manifest.exs` - manifest generator to extend for form story targets.
- `test/browser/support/manifest.ts` and `test/browser/support/showcase.ts` - TypeScript manifest validation and target location to extend without hardcoded form targets.
- `test/browser/specs/showcase.vrt.spec.ts` and `test/browser/specs/showcase.a11y.spec.ts` - story-level VRT/axe patterns form targets should join.
- `test/browser/specs/primitives.behavior.spec.ts` - targeted browser behavior-test style to replicate for form semantics.
- `lib/oban_powertools/web/jobs_live.ex` - current Jobs filter fields, row-selection checkboxes, and reason forms that Phase 75 should make easier to migrate later without changing behavior now.
- `lib/oban_powertools/web/batches_live.ex` - current filter fields, `chain_only` boolean checkbox, row-selection checkboxes, and reason forms.
- `lib/oban_powertools/web/cron_live.ex` and `lib/oban_powertools/web/lifeline_live.ex` - existing reason-field and disabled-reason surfaces that will later consume form/group patterns.

### External Standards And Tool Docs
- `https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html` - official Phoenix function component attrs, slots, global attributes, `form/1`, and component model.
- `https://phoenix-live-view.hexdocs.pm/form-bindings.html` - official LiveView form events; form-level `phx-change` / `phx-submit` is the preferred default.
- `https://phoenix-html.hexdocs.pm/Phoenix.HTML.Form.html` - official `Phoenix.HTML.Form` / `FormField` access behavior, `id`, `name`, `value`, and error helpers.
- `https://www.w3.org/WAI/ARIA/apg/patterns/` - WAI-ARIA APG patterns for checkbox, radio, switch, and combobox; use native HTML first where possible.
- `https://www.w3.org/WAI/ARIA/apg/patterns/combobox/` - true combobox popup/keyboard/name/value requirements; do not fake this for plain filters.
- `https://www.w3.org/TR/WCAG22/` and `https://www.w3.org/WAI/WCAG22/quickref/` - WCAG 2.2 source and quick reference for labels, error identification, focus, contrast, target size, and reflow.
- `https://design-system.service.gov.uk/components/error-message/` - field-specific error copy and label/error matching guidance.
- `https://design-system.service.gov.uk/components/checkboxes/` and `https://design-system.service.gov.uk/components/radios/` - conventional checkbox/radio usage, hinting, and label placement.
- `https://carbondesignsystem.com/patterns/forms-pattern/` - form/toggle/select guidance, including labels and when to use select lists over many choices.
- `https://carbondesignsystem.com/patterns/read-only-states-pattern/` - disabled vs read-only state distinction and accessibility implications.
- `https://primer.style/brand/forms/FormControl/` - design-system precedent for a field wrapper responsible for label/validation/ARIA wiring.
- `https://design.va.gov/components/form/` - fieldset/legend rationale for checkbox/radio groups.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Web.Components.Primitives` already proves the intended component style: stateless function components, closed variants, safe rest filtering, token-backed classes, and a11y encoded in API.
- `assets/oban_powertools/tokens.css` already contains proof-seam form classes (`.obpt-form-label`, `.obpt-input`) plus button/focus/modal classes that Phase 75 can formalize or replace behind components.
- `ObanPowertools.Web.Dev.ShowcaseLive` already reserves a `forms` section and knows how to load dev/test-only support catalogs.
- The generated showcase manifest and Playwright specs already run targets across system/light/dark/high-contrast and 320/tablet/wide.
- Current Jobs/Batches/Cron/Lifeline LiveViews expose the concrete migration targets: filter forms, row checkboxes, boolean filters, reason fields, and disabled action reasons.

### Established Patterns
- Dev/test-only showcase artifacts live under `test/support` and stay out of the Hex package.
- Visual source of truth is `.obpt-root`-scoped token CSS; host Tailwind and host theme state are not part of the contract.
- Browser quality gates are committed, deterministic, and Docker-backed. New form story targets should join the existing harness rather than creating a separate browser test lane.
- Parent LiveViews own operational behavior. Components must not own Lifeline preview/reason/execute/audit state, URL filter serialization, or authorization decisions.

### Integration Points
- Add form components under `lib/oban_powertools/web/components/`, likely `forms.ex`.
- Add form render/static tests under `test/oban_powertools/web/components/`, mirroring `primitives_test.exs`.
- Add a form story catalog under `test/support/`, likely `form_story_catalog.ex`.
- Extend `lib/oban_powertools/web/dev/showcase_live.ex` to render form stories in the existing Forms section.
- Extend `scripts/showcase_manifest.exs`, `test/browser/support/manifest.ts`, and browser specs so form stories become generated VRT/a11y targets.
- Add token CSS to `assets/oban_powertools/tokens.css` and rebuild `priv/static/oban_powertools/oban_powertools.css` through the existing deterministic asset path.

</code_context>

<specifics>
## Specific Ideas

- Target API examples:
  - `<Forms.input field={@filter_form[:queue]} label="Queue" placeholder="All queues" />`
  - `<Forms.textarea field={@reason_form[:reason]} label="Reason" hint="Stored in the audit log." required />`
  - `<Forms.select field={@filter_form[:state]} label="State" options={state_options} />`
  - `<Forms.checkbox field={@filter_form[:chain_only]} label="Chain only" />`
  - `<Forms.radio_group field={@form[:theme]} label="Theme" options={theme_options} />`
  - `<Forms.switch field={@form[:auto_refresh]} label="Auto-refresh job list" />`
- Good form story ids should be stable and grep-friendly, such as `form-input-validation-states`, `form-textarea-reason`, `form-select-options`, `form-choice-controls`, `form-switch-disabled-readonly`, and `form-filter-ready-fields`.
- Field examples should use real operator language: Queue, Worker, Tags, Args JSON, Meta JSON, Reason, Chain only, Auto-refresh job list, State.
- Research across subagents converged on the same architecture: strict form semantics, Phoenix-derived ids/errors, native input controls, and deferred combobox/filter groups.
- The user explicitly asked for a one-shot recommendation set rather than broad option menus. No remaining fork requires user escalation because all four gray areas resolve cleanly against Phase 74 decisions, Phoenix idioms, accessibility standards, and roadmap scope.

</specifics>

<deferred>
## Deferred Ideas

- Full APG combobox/typeahead, async suggestions, multi-select dropdowns, removable chips, saved filters, and filter grammar belong to Phases 77, 78, and 80.
- `FilterBar` as a grouped meta-component belongs to Phase 78, after form and data-display primitives exist.
- Destructive-action forms, required-reason plus confirm flows, count-to-confirm bulk friction, and `ConfirmActionDialog` belong to Phase 78.
- Migrating Jobs/Batches/Cron/Lifeline/Audit/Forensics/Workflows/Limiters/Overview onto form components belongs to Phases 79-81.
- Full manual screen-reader quality, complete keyboard traversal across pages, dialog focus trap/restore, 200% zoom/reflow, copy audit, and motion hardening remain Phase 82 work.
- A broad host-facing UI kit or form schema DSL can be reconsidered only after internal page migrations prove the APIs are stable enough to support.

</deferred>

---

*Phase: 75-form-components*
*Context gathered: 2026-07-11*
