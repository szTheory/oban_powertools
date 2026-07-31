# Phase 75: Form Components - Research

**Researched:** 2026-07-11 [VERIFIED: system date]
**Domain:** Phoenix LiveView form components, Phoenix.HTML form data, accessibility, and showcase validation [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
**Confidence:** MEDIUM [VERIFIED: official docs fallback + local code review; Context7 unavailable]

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/75-form-components/75-CONTEXT.md`. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

### Locked Decisions

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

### the agent's Discretion
- Exact component names, helper function names, CSS class names, story ids, manifest schema extension, and plan split are left to research/planning, provided the decisions above hold.
- The planner may choose whether `input/1` is a polymorphic `type` wrapper or whether text/search/email/number have thin named wrappers. The preferred direction is the smallest API that stays explicit, tested, and easy to grep.
- The planner may reuse existing `.obpt-form-label` and `.obpt-input` proof-seam CSS as implementation material, but Phase 75 must not remain CSS classes only.

### Deferred Ideas (OUT OF SCOPE)
- Full APG combobox/typeahead, async suggestions, multi-select dropdowns, removable chips, saved filters, and filter grammar belong to Phases 77, 78, and 80.
- `FilterBar` as a grouped meta-component belongs to Phase 78, after form and data-display primitives exist.
- Destructive-action forms, required-reason plus confirm flows, count-to-confirm bulk friction, and `ConfirmActionDialog` belong to Phase 78.
- Migrating Jobs/Batches/Cron/Lifeline/Audit/Forensics/Workflows/Limiters/Overview onto form components belongs to Phases 79-81.
- Full manual screen-reader quality, complete keyboard traversal across pages, dialog focus trap/restore, 200% zoom/reflow, copy audit, and motion hardening remain Phase 82 work.
- A broad host-facing UI kit or form schema DSL can be reconsidered only after internal page migrations prove the APIs are stable enough to support.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FORM-01 | Form primitives built on `Phoenix.Component`/`to_form`, tokens-only. [VERIFIED: .planning/REQUIREMENTS.md] | Use a new `ObanPowertools.Web.Components.Forms` module, `Phoenix.HTML.FormField` field API, and token CSS; no new dependencies. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex][VERIFIED: deps/phoenix_html/lib/phoenix_html/form_field.ex] |
| FORM-02 | Programmatic labels, error association, visible focus, non-color validation, and distinct disabled/read-only states. [VERIFIED: .planning/REQUIREMENTS.md] | Use stable ids, merged `aria-describedby`, visible text errors, `aria-invalid` only when rendered, tokenized focus, and browser assertions. [CITED: https://www.w3.org/WAI/WCAG22/quickref/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| COMP-01..04 | Form set must follow component-library documentation, token-only rendering, keyboard/SR correctness, themes, and 320px behavior. [VERIFIED: .planning/REQUIREMENTS.md] | Mirror Phase 74 primitive source tests, story catalog, generated manifest, VRT, axe, and targeted behavior checks. [VERIFIED: test/oban_powertools/web/components/primitives_test.exs][VERIFIED: test/support/primitive_story_catalog.ex][VERIFIED: test/browser/specs/primitives.behavior.spec.ts] |
| A11Y-02 | Interactive controls are keyboard-reachable/operable with visible focus; color is never the sole information carrier. [VERIFIED: .planning/REQUIREMENTS.md] | Use native inputs for checkbox/radio/switch, fieldset/legend for groups, label-click checks, keyboard checks, and non-color error prefixes. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/][CITED: https://design-system.service.gov.uk/components/error-message/] |
</phase_requirements>

## Project Constraints (from CLAUDE.md / AGENTS.md / Project Skills)

No root `CLAUDE.md`, `.claude/CLAUDE.md`, or root `AGENTS.md` exists in this workspace; no `.claude/skills` or `.agents/skills` project skill files were found. [VERIFIED: file scan]

An `AGENTS.md` exists only under `examples/phoenix_host_upgrade_source/`, so it does not apply as the working-directory project instruction file for Phase 75. [VERIFIED: file scan]

The planner must preserve existing user changes because the worktree already contains unrelated deleted planning files and untracked review/setup artifacts. [VERIFIED: git status --short]

## Summary

Phase 75 should build a narrow form-component layer, not migrate production pages. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] The correct plan starts with a new `ObanPowertools.Web.Components.Forms` module, render/source tests, token CSS additions, a dev/test-only `FormStoryCatalog`, and generated manifest/browser coverage. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][VERIFIED: lib/oban_powertools/web/components/primitives.ex][VERIFIED: scripts/showcase_manifest.exs]

The key technical API is `field={@form[:name]}` with `Phoenix.HTML.FormField` deriving `id`, `name`, `value`, and errors; map-backed showcase and filter examples should use `to_form(%{}, as: "filter")` rather than manual names. [VERIFIED: deps/phoenix_html/lib/phoenix_html/form.ex][VERIFIED: deps/phoenix_html/lib/phoenix_html/form_field.ex][VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex] Phoenix LiveView 1.1.31 in this repo already includes `to_form/2` and `used_input?/1`, so this phase does not need a dependency upgrade. [VERIFIED: mix deps][VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex]

The main planning risk is accessibility wiring, not markup generation. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] The plan must explicitly cover visible labels, hint/error ids, `aria-describedby` merging, non-color error prefixes, native checkbox/radio/switch behavior, fieldset/legend groups, disabled/read-only state differences, and Playwright checks that axe alone cannot prove. [CITED: https://www.w3.org/WAI/WCAG22/quickref/][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/][VERIFIED: test/browser/specs/primitives.behavior.spec.ts]

**Primary recommendation:** Use locked Phoenix/LiveView deps and existing browser harness; add forms as stateless `Phoenix.Component` wrappers over `Phoenix.HTML.FormField`, with accessibility behavior encoded in the API and proven through generated form stories plus targeted Playwright tests. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex][VERIFIED: test/browser/specs/showcase.vrt.spec.ts][VERIFIED: test/browser/specs/showcase.a11y.spec.ts]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Form component rendering | Frontend Server (SSR) | Browser / Client | Phoenix function components render HEEx on the server; browser owns native input semantics after render. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/] |
| Field identity and submitted names | Frontend Server (SSR) | API / Backend | `Phoenix.HTML.FormField` supplies ids/names/values/errors from form data; parent LiveViews/backends own params and validation events. [VERIFIED: deps/phoenix_html/lib/phoenix_html/form_field.ex][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| Validation display timing | Frontend Server (SSR) | Browser / Client | `used_input?/1` uses client-submitted `_unused_*` metadata, while components decide whether to render visible errors. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex] |
| Visual theming | CDN / Static | Frontend Server (SSR) | Token CSS is precompiled and scoped under `.obpt-root`; components only emit token-owned class names and state attributes. [VERIFIED: assets/oban_powertools/tokens.css][VERIFIED: .planning/STATE.md] |
| Form story catalog and manifest targets | Frontend Server (SSR) | Browser / Client | Elixir catalogs generate a JSON manifest; Playwright consumes generated targets for VRT and axe. [VERIFIED: test/support/primitive_story_catalog.ex][VERIFIED: scripts/showcase_manifest.exs][VERIFIED: test/browser/support/manifest.ts] |
| Page filter URL persistence | API / Backend | Frontend Server (SSR) | URL-serialized filters are explicitly deferred to Phase 80; Phase 75 only provides filter-ready controls. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][VERIFIED: .planning/ROADMAP.md] |
| Destructive reason/confirm flows | API / Backend | Frontend Server (SSR) | Required-reason mutation semantics and confirm patterns are deferred to Phase 78; Phase 75 supplies reusable fields only. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][VERIFIED: .planning/ROADMAP.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | locked 1.1.31; latest seen 1.2.6 on Hex as of 2026-07-07. [VERIFIED: mix deps][VERIFIED: mix hex.info phoenix_live_view] | Provides `Phoenix.Component`, `attr/3`, `slot/3`, `form/1`, `to_form/2`, and `used_input?/1`. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex] | It is already the project UI component foundation and Phase 75 is explicitly scoped to `Phoenix.Component`/`to_form`. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| `phoenix_html` | locked/latest 4.3.0; release date 2025-09-28. [VERIFIED: mix deps][VERIFIED: mix hex.info phoenix_html] | Supplies `Phoenix.HTML.Form`, `FormField`, `input_id/2`, `input_name/2`, `input_value/2`, and `normalize_value/2`. [VERIFIED: deps/phoenix_html/lib/phoenix_html/form.ex][VERIFIED: deps/phoenix_html/lib/phoenix_html/form_field.ex] | It is the source of truth for form field ids/names/values and avoids hand-built string naming. [VERIFIED: deps/phoenix_html/lib/phoenix_html/form.ex] |
| Project token CSS | existing `assets/oban_powertools/tokens.css`. [VERIFIED: assets/oban_powertools/tokens.css] | Owns `.obpt-root`, semantic color/space/type/motion tokens, proof-seam `.obpt-form-label`, `.obpt-input`, focus, alert, and primitive classes. [VERIFIED: assets/oban_powertools/tokens.css] | v2.0 locked decisions require token-only, `.obpt-root`-scoped visuals with no host Tailwind dependency. [VERIFIED: .planning/STATE.md][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| ExUnit + `Phoenix.LiveViewTest.__render_component__` | existing test infrastructure. [VERIFIED: test/oban_powertools/web/components/primitives_test.exs] | Renders function components in static contract tests. [VERIFIED: test/oban_powertools/web/components/primitives_test.exs] | Phase 74 already uses it for source/render contracts; Phase 75 should mirror it for forms. [VERIFIED: test/oban_powertools/web/components/primitives_test.exs] |
| Playwright + axe harness | `@playwright/test` locked 1.61.0, `@axe-core/playwright` locked 4.11.3, `axe-core` locked 4.11.4. [VERIFIED: package.json][VERIFIED: npm view] | Runs generated showcase VRT, axe, and targeted browser behavior checks. [VERIFIED: test/browser/specs/showcase.vrt.spec.ts][VERIFIED: test/browser/specs/showcase.a11y.spec.ts][VERIFIED: test/browser/specs/primitives.behavior.spec.ts] | Existing Phase 73/74 quality gates are manifest-driven; forms should join the same matrix. [VERIFIED: guides/visual-regression-and-a11y.md][VERIFIED: scripts/showcase_manifest.exs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix` | locked 1.8.7; latest seen 1.8.9 on Hex as of 2026-07-07. [VERIFIED: mix deps][VERIFIED: mix hex.info phoenix] | Provides the surrounding Phoenix app/runtime used by the example host and LiveView route. [VERIFIED: mix.exs] | Use existing dependency only; do not upgrade for this phase. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| `jason` | locked 1.4.5. [VERIFIED: mix deps] | Encodes generated showcase manifest JSON. [VERIFIED: scripts/showcase_manifest.exs] | Keep using it in `scripts/showcase_manifest.exs` when adding `form_stories`. [VERIFIED: scripts/showcase_manifest.exs] |
| `lazy_html` | existing test-only dependency. [VERIFIED: mix.exs] | HTML parsing support exists for tests if string assertions become too brittle. [VERIFIED: mix.exs] | Use only if form render tests need structural assertions beyond the existing string contract style. [VERIFIED: test/oban_powertools/web/components/primitives_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Phoenix.HTML.FormField` wrappers | Manual `id`, `name`, and `value` attrs everywhere | Manual naming duplicates Phoenix logic and makes map-backed filters diverge from changeset-backed forms. [VERIFIED: deps/phoenix_html/lib/phoenix_html/form.ex][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| Native checkbox/radio/switch inputs | Hand-rolled ARIA widgets | Native controls carry keyboard, form submission, mobile, and assistive-technology behavior; ARIA widgets require full behavior implementation. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| Generated custom showcase | PhoenixStorybook or third-party headless UI runtime | Project requirements explicitly exclude PhoenixStorybook as a published-library runtime dependency and require the existing dev-only showcase. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| Narrow wrappers | Schema/macro form DSL | The phase context explicitly rejects a schema DSL before native page migrations prove the API. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |

**Installation:**
```bash
# No new packages for Phase 75. Use existing locked dependencies.
mix deps.get
npm ci
```
[VERIFIED: mix.exs][VERIFIED: package.json][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

**Version verification performed:**
```bash
mix deps | rg 'phoenix|html'
mix hex.info phoenix_live_view
mix hex.info phoenix_html
mix hex.info phoenix
npm view @playwright/test@1.61.0 version time.modified repository.url scripts.postinstall --json
npm view @axe-core/playwright@4.11.3 version time.modified repository.url scripts.postinstall --json
npm view axe-core@4.11.4 version time.modified repository.url scripts.postinstall --json
```
[VERIFIED: command output]

## Package Legitimacy Audit

Phase 75 should install no new external packages. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][VERIFIED: package.json][VERIFIED: mix.exs]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | none | n/a | n/a | n/a | OK | No new installs; planner should use existing locked deps. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |

Existing npm dev dependencies have no `postinstall` scripts at their locked versions. [VERIFIED: npm view @playwright/test@1.61.0 scripts.postinstall][VERIFIED: npm view @axe-core/playwright@4.11.3 scripts.postinstall][VERIFIED: npm view axe-core@4.11.4 scripts.postinstall]

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy gate not required for new installs]
**Packages flagged as suspicious [SUS]:** none for Phase 75 install plan. [VERIFIED: no new package install plan]

## Architecture Patterns

### System Architecture Diagram

```text
Parent LiveView assigns
  |  (changeset/map -> to_form)
  v
Phoenix.HTML.Form
  |  form[:field]
  v
Phoenix.HTML.FormField
  |  id/name/value/errors
  v
ObanPowertools.Web.Components.Forms
  |-- derive control id/name/value
  |-- require visible label or legend
  |-- derive hint/error ids
  |-- merge caller aria-describedby
  |-- render native input/select/textarea/checkbox/radio
  |-- filter class/style escape hatches
  v
Token-scoped HTML under .obpt-root
  |  data-obpt-* + obpt-* classes
  v
Browser native semantics
  |-- keyboard and label click behavior
  |-- form submission values
  |-- focus-visible state
  v
Existing generated showcase manifest
  |-- scenario targets
  |-- primitive targets
  |-- form targets
  v
Playwright VRT + axe + targeted behavior checks
```
[VERIFIED: deps/phoenix_html/lib/phoenix_html/form.ex][VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex][VERIFIED: scripts/showcase_manifest.exs][VERIFIED: test/browser/specs/showcase.vrt.spec.ts]

### Recommended Project Structure

```text
lib/oban_powertools/web/components/
├── forms.ex                  # Field, label, hint, error, and native control components
└── primitives.ex             # Existing lower-level visual primitives; do not add form semantics here

test/oban_powertools/web/components/
└── forms_test.exs            # Render/source/rest-filter/a11y contract tests

test/support/
└── form_story_catalog.ex     # Dev/test-only form story metadata and examples

test/oban_powertools/
└── form_story_catalog_test.exs

test/browser/specs/
└── forms.behavior.spec.ts    # Label, describedby, invalid, keyboard, focus, overflow checks
```
[VERIFIED: lib/oban_powertools/web/components/primitives.ex][VERIFIED: test/oban_powertools/web/components/primitives_test.exs][VERIFIED: test/support/primitive_story_catalog.ex][VERIFIED: test/browser/specs/primitives.behavior.spec.ts]

### Pattern 1: Field-First Component API

**What:** Accept `field={@form[:queue]}` as the normal path, derive `id`, `name`, `value`, and field errors from `Phoenix.HTML.FormField`, and allow explicit overrides only when native semantics require them. [VERIFIED: deps/phoenix_html/lib/phoenix_html/form_field.ex][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

**When to use:** Use for `input/1`, `textarea/1`, `select/1`, named boolean `checkbox/1`, `radio_group/1`, and checkbox-backed `switch/1`. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

**Example:**
```elixir
# Source: deps/phoenix_html/lib/phoenix_html/form_field.ex
attr(:field, Phoenix.HTML.FormField, required: true)
attr(:label, :string, required: true)
attr(:hint, :string, default: nil)
attr(:rest, :global, default: %{}, include: ~w(placeholder autocomplete required phx-debounce phx-throttle))

def input(assigns) do
  field = assigns.field
  id = assigns.rest["id"] || field.id
  hint_id = if present?(assigns.hint), do: "#{id}-hint"
  error_id = if visible_error?(field), do: "#{id}-error"

  assigns =
    assigns
    |> assign(:id, id)
    |> assign(:name, field.name)
    |> assign(:value, field.value)
    |> assign(:describedby, merge_ids(assigns.rest["aria-describedby"], [hint_id, error_id]))

  ~H"""
  <div class="obpt-field" data-obpt-invalid={visible_error?(@field)}>
    <label class="obpt-form-label" for={@id}>{@label}</label>
    <p :if={@hint} id={@id <> "-hint"} class="obpt-form-hint">{@hint}</p>
    <input id={@id} name={@name} value={@value} aria-describedby={@describedby} />
  </div>
  """
end
```
[VERIFIED: deps/phoenix_html/lib/phoenix_html/form_field.ex][VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex]

### Pattern 2: Description And Error Wiring

**What:** Derive stable ids from the control id, merge caller-provided `aria-describedby`, render visible error text, and set `aria-invalid="true"` only when an error is actually rendered. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][CITED: https://www.w3.org/WAI/WCAG22/quickref/]

**When to use:** Use for every high-level field and group component, including radios and switches. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

**Implementation note:** GOV.UK error guidance prefixes errors for assistive tech and asks labels/errors to match wording, so prefer visible field-specific copy plus a screen-reader-safe "Error:" prefix. [CITED: https://design-system.service.gov.uk/components/error-message/]

### Pattern 3: Native Choice Controls

**What:** Use native `input type="checkbox"` and `input type="radio"` for checkboxes, radio groups, and switch visuals. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][CITED: https://www.w3.org/WAI/ARIA/apg/patterns/]

**When to use:** Use native named boolean checkboxes in forms, event-driven checkboxes for table row selection, `fieldset`/`legend` radio groups, and checkbox-backed switches for immediate reversible settings. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

**Example:**
```elixir
# Source: deps/phoenix_html/lib/phoenix_html/form.ex
def checkbox(assigns) do
  named_form_field? = match?(%Phoenix.HTML.FormField{}, assigns[:field])
  event_driven? = Map.has_key?(assigns.rest, "phx-click")

  assigns =
    assigns
    |> assign(:emit_hidden_unchecked?, named_form_field? and not event_driven?)

  ~H"""
  <input :if={@emit_hidden_unchecked?} type="hidden" name={@field.name} value="false" />
  <label class="obpt-checkbox">
    <input type="checkbox" name={@field && @field.name} value="true" {@rest} />
    <span>{@label}</span>
  </label>
  """
end
```
[VERIFIED: deps/phoenix_html/lib/phoenix_html/form.ex][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

### Pattern 4: Manifest-Driven Form Stories

**What:** Add `ObanPowertools.FormStoryCatalog`, then extend `scripts/showcase_manifest.exs` and `test/browser/support/manifest.ts` with a `form_stories` collection and `kind: "form"` targets. [VERIFIED: test/support/primitive_story_catalog.ex][VERIFIED: scripts/showcase_manifest.exs][VERIFIED: test/browser/support/manifest.ts]

**When to use:** Use for all form VRT/axe targets so TypeScript specs iterate generated targets instead of hardcoded story ids. [VERIFIED: test/browser/specs/showcase.vrt.spec.ts][VERIFIED: test/browser/specs/showcase.a11y.spec.ts]

### Anti-Patterns to Avoid

- **Manual id/name strings for ordinary fields:** This bypasses `Phoenix.HTML.FormField` and makes map-backed and changeset-backed forms diverge. [VERIFIED: deps/phoenix_html/lib/phoenix_html/form.ex]
- **Placeholder-only labels:** WCAG requires labels/instructions and the phase context forbids placeholders as labels. [CITED: https://www.w3.org/WAI/WCAG22/quickref/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
- **Fake combobox role on plain filters:** APG combobox requires popup, state, keyboard, and focus behavior; Phase 75 plain filter inputs must stay ordinary text/search controls. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
- **Hidden unchecked values for row-selection checkboxes:** Row selection is event-driven, not a named boolean form field, so hidden unchecked inputs would submit misleading values. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][VERIFIED: lib/oban_powertools/web/jobs_live.ex]
- **Caller `class`/`style` escape hatches:** Phase 74 already filters visual rest attrs; Phase 75 must preserve the token boundary. [VERIFIED: lib/oban_powertools/web/components/primitives.ex][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Field names and ids | String concatenation for `filter[queue]` and `filter_queue` | `to_form` + `form[:field]` / `Phoenix.HTML.FormField` | Phoenix already derives `id`, `name`, `value`, and errors consistently. [VERIFIED: deps/phoenix_html/lib/phoenix_html/form.ex][VERIFIED: deps/phoenix_html/lib/phoenix_html/form_field.ex] |
| Validation timing | Custom touched-state tracker | `Phoenix.Component.used_input?/1` where changeset/params support it | LiveView already sends `_unused_*` metadata and `used_input?/1` filters early errors. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex] |
| Checkbox/radio keyboard behavior | ARIA-only div/span controls | Native `input` controls | Native controls preserve keyboard, label click, mobile, and submission behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| Combobox/typeahead | Partial ARIA combobox attributes | Defer to later APG-complete component | Combobox requires popup state, active descendant/focus behavior, and manual verification. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| Form story discovery | Hardcoded TypeScript story lists | Generated manifest extension | Existing VRT/axe specs iterate manifest targets. [VERIFIED: test/browser/specs/showcase.vrt.spec.ts][VERIFIED: test/browser/specs/showcase.a11y.spec.ts] |
| Token/focus visuals | Inline CSS, raw hex, raw px in component source | `assets/oban_powertools/tokens.css` and `obpt-*` classes | Project requirements require token-only components and static guards. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: test/oban_powertools/web/components/primitives_test.exs] |

**Key insight:** Build the contract surface first: field API, ids, rest filtering, story metadata, and browser assertions. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][VERIFIED: test/oban_powertools/web/components/primitives_test.exs]

## Common Pitfalls

### Pitfall 1: Showing Errors Before Interaction
**What goes wrong:** Empty required fields show errors on first render or after typing into a different field. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex]
**Why it happens:** Components render every `field.errors` entry without checking `used_input?/1` or explicit submit/action state. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex]
**How to avoid:** Gate changeset-backed field errors with `used_input?/1`, while still allowing explicit submit-time/action errors where parent flows pass them. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
**Warning signs:** Form stories show invalid states by default without a deliberate invalid story state. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

### Pitfall 2: Overwriting Caller Descriptions
**What goes wrong:** A field loses caller-provided `aria-describedby` when a hint or error is rendered. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
**Why it happens:** Components assign their own id string instead of merging ids. [VERIFIED: lib/oban_powertools/web/components/primitives.ex]
**How to avoid:** Normalize and append caller ids with generated hint/error ids, then remove the original rest attr before rendering the input. [VERIFIED: lib/oban_powertools/web/components/primitives.ex]
**Warning signs:** Browser assertions find only one id in `aria-describedby` when both caller description and error exist. [VERIFIED: test/browser/specs/primitives.behavior.spec.ts]

### Pitfall 3: Treating Disabled And Read-Only As The Same State
**What goes wrong:** Operators cannot inspect unavailable fields or understand why a control is unavailable. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
**Why it happens:** Native `disabled` removes controls from submission and usually from tab order, while read-only content needs to remain perceivable. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][CITED: https://carbondesignsystem.com/patterns/read-only-states-pattern/]
**How to avoid:** Use native `disabled` for temporarily unavailable controls that need not submit, and separate read-only styling/content for values the operator should review. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
**Warning signs:** Read-only stories look visually identical to disabled stories or fail contrast checks. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

### Pitfall 4: False Combobox Semantics
**What goes wrong:** A plain search/filter input advertises combobox behavior but has no popup or keyboard model. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/]
**Why it happens:** Designers want a future typeahead affordance before Phase 77/78/80 scope exists. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
**How to avoid:** Ship filter-ready ordinary text/search/select controls only; defer APG combobox work. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
**Warning signs:** `role="combobox"`, `aria-expanded`, or `aria-activedescendant` appears in Phase 75 source. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/]

### Pitfall 5: Manifest Drift
**What goes wrong:** VRT and axe specs miss form stories or rely on hardcoded lists. [VERIFIED: test/browser/specs/showcase.vrt.spec.ts][VERIFIED: test/browser/specs/showcase.a11y.spec.ts]
**Why it happens:** Elixir story catalogs and TypeScript manifest validation are extended inconsistently. [VERIFIED: scripts/showcase_manifest.exs][VERIFIED: test/browser/support/manifest.ts]
**How to avoid:** Update Elixir generator, TS types/validation, structure assertions, VRT/axe loops, and a smoke test in one slice. [VERIFIED: test/browser/specs/showcase.structure.spec.ts]
**Warning signs:** `primitive_stories.length` assertions are updated but no `form_stories` validation exists. [VERIFIED: test/browser/support/manifest.ts]

## Code Examples

Verified patterns from official/local sources:

### Map-Backed Showcase Form
```elixir
# Source: deps/phoenix_live_view/lib/phoenix_component.ex
assign(socket, :filter_form, to_form(%{"queue" => "", "state" => "all"}, as: "filter"))

~H"""
<.form for={@filter_form} phx-change="filter">
  <Forms.input field={@filter_form[:queue]} label="Queue" placeholder="All queues" />
  <Forms.select field={@filter_form[:state]} label="State" options={state_options()} />
</.form>
"""
```
[VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex][VERIFIED: deps/phoenix_html/lib/phoenix_html/form.ex]

### Radio Group With Group-Level Error
```elixir
# Source: https://design.va.gov/components/form/
<fieldset class="obpt-field-group" aria-describedby={@describedby} aria-invalid={@invalid?}>
  <legend class="obpt-form-label">{@label}</legend>
  <p :if={@hint} id={@hint_id} class="obpt-form-hint">{@hint}</p>
  <label :for={option <- @options} class="obpt-radio">
    <input type="radio" id={option.id} name={@field.name} value={option.value} />
    <span>{option.label}</span>
  </label>
  <p :if={@error} id={@error_id} class="obpt-form-error">
    <span class="obpt-sr-only">Error: </span>{@error}
  </p>
</fieldset>
```
[CITED: https://design.va.gov/components/form/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

### Form Story Manifest Extension
```elixir
# Source: scripts/showcase_manifest.exs and test/support/primitive_story_catalog.ex
alias ObanPowertools.FormStoryCatalog

form_stories =
  FormStoryCatalog.stories()
  |> Enum.map(fn story ->
    %{
      id: story.id,
      kind: "form",
      component: Atom.to_string(story.component),
      components: Enum.map(story.components, &Atom.to_string/1),
      state: stringify_list.(story.state),
      story: story.test_targets.story,
      snapshot: FormStoryCatalog.snapshot_name(story.id),
      a11y: FormStoryCatalog.a11y_target(story.id)
    }
  end)
```
[VERIFIED: scripts/showcase_manifest.exs][VERIFIED: test/support/primitive_story_catalog.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Atom form names passed directly to form `for` | `to_form(%{}, as: :name)` or assigned `to_form` data | Phoenix LiveView docs in locked 1.1.31 warn that atom `for` is deprecated. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex] | Phase 75 examples should use `to_form` explicitly. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex] |
| Showing every changeset error immediately | Filter field errors with `used_input?/1` where available | Present in locked `phoenix_live_view` 1.1.31. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex] | Prevents validation from shouting before interaction. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex] |
| Component-specific test lists | Generated manifest targets | Existing Phase 73/74 harness uses generated targets. [VERIFIED: scripts/showcase_manifest.exs][VERIFIED: test/browser/specs/showcase.vrt.spec.ts] | Form stories should become `kind: "form"` targets. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| ARIA recreations of basic inputs | Native HTML controls with token styling | WAI APG documents expected widget behavior; Phase 75 locks native inputs. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] | Less keyboard/submission risk and fewer custom behavior tests. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/] |

**Deprecated/outdated:**
- Passing an atom directly as a form source is deprecated in Phoenix LiveView docs; use `to_form(%{}, as: :filter)` for map-backed filters and showcase stories. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex]
- Using `role="combobox"` for plain filter inputs is out of scope and misleading because true comboboxes require popup and keyboard behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
- Relying on color-only error borders is insufficient because WCAG and project requirements require non-color information channels. [CITED: https://www.w3.org/WAI/WCAG22/quickref/][VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

All claims in this research were verified from local code/config, command output, or official documentation. [VERIFIED: research process]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| none | n/a | n/a | n/a |

## Open Questions

1. **Exact component names are intentionally planner-owned.** [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
   - What we know: The context allows `input/1`, `textarea/1`, `select/1`, `checkbox/1`, `radio_group/1`, `switch/1`, `field_group/1`, `label/1`, `hint/1`, and `error/1`. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
   - What's unclear: Whether `input/1` should stay polymorphic by `type` or split text/search/email/number into thin wrappers. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]
   - Recommendation: Start with one explicit `input/1` plus separate wrappers only for materially different semantics, because the context prefers the smallest grep-friendly API. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Erlang | Mix compile and ExUnit | yes | Elixir 1.19.5 / OTP 28 [VERIFIED: elixir --version] | none needed |
| Mix | Hex deps and tests | yes | Mix 1.19.5 [VERIFIED: mix --version] | none needed |
| Node.js | Playwright harness | yes | v22.14.0 [VERIFIED: node --version] | none needed |
| npm | Manifest/VRT scripts | yes | 11.1.0 [VERIFIED: npm --version] | none needed |
| Docker | `npm run visual:a11y` Docker lane | yes | 29.5.2 [VERIFIED: docker --version][VERIFIED: docker info] | `npm run visual:a11y:host` for local targeted checks. [VERIFIED: package.json] |
| `scripts/playwright-docker.sh` | Pinned browser harness | yes | executable [VERIFIED: file probe] | host Playwright command. [VERIFIED: package.json] |
| `scripts/with-showcase-server.sh` | Showcase server wrapper | yes | executable [VERIFIED: file probe] | manually run host and set `PLAYWRIGHT_TEST_BASE_URL`. [VERIFIED: playwright.config.ts] |
| ripgrep | Static source guards | yes | 15.1.0 [VERIFIED: rg --version] | grep/perl if unavailable. [VERIFIED: environment probe] |

**Missing dependencies with no fallback:**
- None found for Phase 75 implementation and validation. [VERIFIED: environment probes]

**Missing dependencies with fallback:**
- Context7 MCP/CLI was unavailable for research docs lookup; official docs URLs and local dependency source were used instead. [VERIFIED: command -v ctx7][CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix LiveView component render helper; Playwright 1.61.0 with axe-core 4.11.x. [VERIFIED: test/oban_powertools/web/components/primitives_test.exs][VERIFIED: package.json] |
| Config file | `playwright.config.ts`; no separate ExUnit config file beyond standard Mix test setup. [VERIFIED: playwright.config.ts][VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/oban_powertools/web/components/forms_test.exs test/oban_powertools/form_story_catalog_test.exs` after Wave 0 creates those files. [VERIFIED: test structure] |
| Full suite command | `mix test && npm run visual:a11y` [VERIFIED: package.json] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FORM-01 | Components exist, accept `Phoenix.HTML.FormField`, derive id/name/value, and render token-only controls. [VERIFIED: .planning/REQUIREMENTS.md] | unit/static | `mix test test/oban_powertools/web/components/forms_test.exs` | no - Wave 0. [VERIFIED: file scan] |
| FORM-02 | Labels, hints, errors, `aria-describedby`, `aria-invalid`, focus, disabled/read-only, and non-color errors work. [VERIFIED: .planning/REQUIREMENTS.md] | unit + browser | `npm run visual:a11y:host -- test/browser/specs/forms.behavior.spec.ts` | no - Wave 0. [VERIFIED: file scan] |
| COMP-01..04 | Form story catalog covers form set across themes/viewports and static source guards remain clean. [VERIFIED: .planning/REQUIREMENTS.md] | unit + VRT/axe | `npm run showcase:manifest && npm run visual:a11y` | partial - harness exists; form files absent. [VERIFIED: package.json][VERIFIED: file scan] |
| A11Y-02 | Choice controls are keyboard-operable, label-clickable, visibly focused, and 320px-safe. [VERIFIED: .planning/REQUIREMENTS.md] | browser behavior | `npm run visual:a11y:host -- test/browser/specs/forms.behavior.spec.ts` | no - Wave 0. [VERIFIED: file scan] |

### Sampling Rate

- **Per task commit:** Run the relevant ExUnit file plus `npm run showcase:manifest` when story/manifest files change. [VERIFIED: package.json]
- **Per wave merge:** Run `mix test` and targeted Playwright form behavior specs. [VERIFIED: test/browser/specs/primitives.behavior.spec.ts]
- **Phase gate:** Run `mix test && npm run visual:a11y` with updated form baselines only after intentional visual review. [VERIFIED: guides/visual-regression-and-a11y.md][VERIFIED: package.json]

### Wave 0 Gaps

- [ ] `test/oban_powertools/web/components/forms_test.exs` - covers FORM-01, FORM-02, COMP-01..03. [VERIFIED: file scan]
- [ ] `test/support/form_story_catalog.ex` - covers story metadata for FORM-01/FORM-02/COMP-04. [VERIFIED: file scan]
- [ ] `test/oban_powertools/form_story_catalog_test.exs` - mirrors primitive catalog tests for stable ids/targets. [VERIFIED: test/oban_powertools/primitive_story_catalog_test.exs]
- [ ] `test/browser/specs/forms.behavior.spec.ts` - covers A11Y-02 checks beyond axe. [VERIFIED: test/browser/specs/primitives.behavior.spec.ts]
- [ ] `scripts/showcase_manifest.exs` and `test/browser/support/manifest.ts` updates - include generated `form_stories` targets. [VERIFIED: scripts/showcase_manifest.exs][VERIFIED: test/browser/support/manifest.ts]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Components do not authenticate users; parent LiveViews own actor/auth context. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| V3 Session Management | no | Components do not create sessions or cookies. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| V4 Access Control | yes, indirectly | Do not encode authorization in disabled/read-only visuals; parent LiveViews suppress or reject actions. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| V5 Input Validation | yes | Use `Phoenix.HTML.FormField`, filtered rest attrs, escaped HEEx text, visible error messages, and parent-owned validation. [VERIFIED: deps/phoenix_html/lib/phoenix_html/form_field.ex][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| V6 Cryptography | no | Phase 75 adds no crypto or secret handling. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |

### Known Threat Patterns for Phoenix Form Components

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS through labels, hints, errors, or option labels | Tampering / Information Disclosure | Render text through HEEx escaping; do not accept raw HTML labels/errors in Phase 75. [VERIFIED: deps/phoenix_live_view/lib/phoenix_component.ex][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| Event spoofing through visually disabled controls | Tampering | Native `disabled` where appropriate; for explained unavailable controls, suppress action attrs as Phase 74 does and keep parent authorization checks. [VERIFIED: lib/oban_powertools/web/components/primitives.ex][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| Hidden unchecked values corrupting row selection | Tampering | Emit hidden unchecked values only for named boolean fields, not `phx-click` row selection controls. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][VERIFIED: lib/oban_powertools/web/jobs_live.ex] |
| Host style injection through `class`/`style` rest attrs | Tampering | Filter `class` and `style` from normal form components while preserving semantic attrs. [VERIFIED: lib/oban_powertools/web/components/primitives.ex][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |
| Misleading combobox role without behavior | Spoofing / Usability failure | Do not emit combobox roles for plain filters; defer APG-complete combobox. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- Local locked dependency source: `deps/phoenix_live_view/lib/phoenix_component.ex` - `to_form/2`, `used_input?/1`, `form/1`, global attributes. [VERIFIED: codebase grep]
- Local locked dependency source: `deps/phoenix_html/lib/phoenix_html/form.ex` and `deps/phoenix_html/lib/phoenix_html/form_field.ex` - `FormField`, `input_id`, `input_name`, `input_value`, `normalize_value`. [VERIFIED: codebase grep]
- Existing implementation: `lib/oban_powertools/web/components/primitives.ex`, `test/oban_powertools/web/components/primitives_test.exs`, `test/support/primitive_story_catalog.ex`, `scripts/showcase_manifest.exs`, and browser specs. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html - official Phoenix.Component docs. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]
- https://hexdocs.pm/phoenix_live_view/form-bindings.html - official LiveView form bindings docs. [CITED: https://hexdocs.pm/phoenix_live_view/form-bindings.html]
- https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html - official Phoenix.HTML.Form docs. [CITED: https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html]
- https://www.w3.org/WAI/ARIA/apg/patterns/ - WAI-ARIA APG pattern index for native-vs-custom widget behavior. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/]
- https://www.w3.org/WAI/ARIA/apg/patterns/combobox/ - APG combobox requirements. [CITED: https://www.w3.org/WAI/ARIA/apg/patterns/combobox/]
- https://www.w3.org/WAI/WCAG22/quickref/ - WCAG 2.2 quick reference for labels, errors, focus, target size, reflow, and non-color signals. [CITED: https://www.w3.org/WAI/WCAG22/quickref/]
- https://design-system.service.gov.uk/components/error-message/ - error message prefixing and label/error wording guidance. [CITED: https://design-system.service.gov.uk/components/error-message/]
- https://carbondesignsystem.com/patterns/read-only-states-pattern/ - disabled vs read-only design-system guidance. [CITED: https://carbondesignsystem.com/patterns/read-only-states-pattern/]
- https://design.va.gov/components/form/ - fieldset/legend guidance for grouped form controls. [CITED: https://design.va.gov/components/form/]

### Tertiary (LOW confidence)

- None used as authoritative support. [VERIFIED: research process]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and APIs were checked against local lockfiles/source and registry commands. [VERIFIED: mix deps][VERIFIED: mix hex.info phoenix_live_view][VERIFIED: npm view]
- Architecture: HIGH - phase context and existing Phase 74 code/harness directly define the architecture. [VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md][VERIFIED: lib/oban_powertools/web/components/primitives.ex][VERIFIED: scripts/showcase_manifest.exs]
- Pitfalls: MEDIUM - accessibility pitfalls are backed by official standards and project context, but manual screen-reader quality is deferred to Phase 82. [CITED: https://www.w3.org/WAI/WCAG22/quickref/][VERIFIED: .planning/phases/75-form-components/75-CONTEXT.md]

**Research date:** 2026-07-11 [VERIFIED: system date]
**Valid until:** 2026-08-10 for project architecture; re-check Hex/npm versions before installing or upgrading dependencies. [VERIFIED: mix hex.info phoenix_live_view][VERIFIED: npm view]

