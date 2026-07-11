# Phase 75: Form Components - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-11
**Phase:** 75-form-components
**Areas discussed:** Field API shape, Validation/error semantics, Selectable controls, Combobox/filter boundary

---

## Field API Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Separate `Forms` module | Add `ObanPowertools.Web.Components.Forms` beside `Primitives`; use `field={@form[:x]}` and centralize label/hint/error semantics. | yes |
| Extend `Primitives` | Add field components to the existing primitive module. | |
| Page-local helpers | Keep per-LiveView helpers for filters/reasons. | |
| Generated schema/DSL | Define field metadata through a macro/schema and render from it. | |

**User's choice:** Discuss all areas with research-backed recommendations; Claude selected the coherent default.
**Notes:** Subagent research and local code review both favored a separate forms module because Phase 74 intentionally kept primitives narrow and stateless.

---

## Validation/Error Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Strict explicit contract | Require callers to provide every id/label/hint/error/describedby detail. | |
| Permissive caller responsibility | Let callers handle labels, errors, and ARIA wiring manually. | |
| Phoenix `FormField`-derived strict wrapper | Derive id/name/value/errors from `Phoenix.HTML.FormField`, require visible labels, and auto-wire hint/error associations. | yes |

**User's choice:** Discuss all areas with research-backed recommendations; Claude selected the coherent default.
**Notes:** This preserves Phoenix idioms and avoids the current scattered markup footguns while still enforcing FORM-02.

---

## Selectable Controls

| Option | Description | Selected |
|--------|-------------|----------|
| Native inputs with stateless Phoenix wrappers | Wrap native checkbox/radio/switch inputs; parent LiveViews own state/events. | yes |
| ARIA custom controls | Hand-roll roles, keyboard behavior, and hidden form bridges. | |
| Stateful LiveComponents | Let controls own component state and events. | |
| Later group components only | Defer selection semantics entirely to later phases. | |

**User's choice:** Discuss all areas with research-backed recommendations; Claude selected the coherent default.
**Notes:** Native controls are lowest-risk for keyboard, mobile, form submission, and assistive technology. Hidden unchecked values are only for named boolean form fields, not row-selection events.

---

## Combobox/filter Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 75 lightweight filter-capable primitives | Ship filter-ready semantic input/select primitives without popup/typeahead behavior. | yes |
| Defer richer FilterBar/typeahead/chips | Keep shared filter groups, chips, saved filters, and URL grammar for later phases. | yes |
| Build full Phoenix-native headless combobox now | Implement APG combobox popup, keyboard model, async suggestions, and owned state. | |
| Adopt third-party headless combobox/runtime | Use a mature React/headless UI runtime and wrap it. | |

**User's choice:** Discuss all areas with research-backed recommendations; Claude selected the coherent default.
**Notes:** The selected recommendation is a hybrid boundary: Phase 75 ships filter-ready fields and explicitly defers the real combobox/filter group work to Phases 77, 78, and 80.

---

## Claude's Discretion

- Exact component names, CSS class names, story ids, and manifest schema extension.
- Whether text/search/email/number share one polymorphic input component or thin named wrappers.
- Plan split across API/tests, CSS/assets, showcase/manifest, browser gates, and docs/static guards.

## Deferred Ideas

- Full APG combobox/typeahead, async suggestions, multi-select, chips, saved filters, and filter grammar.
- `FilterBar` group/meta-component.
- ConfirmActionDialog and destructive danger-form pattern.
- Page migrations and final manual accessibility/motion/copy sweep.
