# Phase 74: Primitives Library - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-10
**Phase:** 74-primitives-library
**Areas discussed:** Component Support Boundary, Showcase & Baseline Shape, StatusPill Scope, Strict A11y Contracts

---

## Component Support Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Primitive-only Powertools `Phoenix.Component` layer | Stateless function components for native pages/showcase; Phoenix attrs/slots/global attrs; parent LiveViews own state/events; variants are closed and token-backed. | ✓ |
| Host-facing public UI kit | Market/document primitives as a reusable Phoenix design-system package for hosts. Strong reuse, but every attr/slot becomes public support surface. | |
| CSS class contract only | Continue using `.obpt-*` classes directly. Minimal API, but preserves duplicated HEEx and weak a11y semantics. | |
| Stateful/headless primitives now | Encapsulate state/focus/overlay behavior early. Useful later, but expands Phase 74 into overlay/group territory. | |
| Third-party component/storybook dependency | Pull in a mature component/story framework. Useful inspiration, but wrong runtime/support boundary for this library. | |

**User's choice:** User asked to research all areas and produce coherent one-shot recommendations.
**Notes:** Subagent and local research converged on a narrow internal primitive layer. This aligns with Phoenix.Component idioms, the repo's support-truth posture, and the zero-new-runtime-dependency design-system milestone.

---

## Showcase & Baseline Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Append primitive stories to `ShowcaseCatalog.scenarios/0` | Reuses current manifest path, but pollutes the domain/persona/JTBD stress-fixture contract and breaks the current 9-scenario assumption. | |
| New primitive story registry merged into manifest | Keeps stress fixtures separate, gives primitives their own metadata, and supports future form/data/group/page story registries. | ✓ |
| Atomic variant-per-state baselines | Best diff localization but multiplies PNG count and reviewer fatigue across themes/viewports. | |
| One primitives gallery screenshot | Few screenshots but poor diff localization and weak axe/VRT signal. | |

**User's choice:** User asked for all decision points to be considered through research, DX, UI/UX, and engineering lenses.
**Notes:** Recommendation follows Storybook's rendered-state model without adding Storybook as a dependency. Use matrix stories for static variants and separate targeted stories for open/focus/loading states.

---

## StatusPill Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Tone-only primitives | Keep Phase 74 purely visual/token-level. Simple, but gives Phase 77 less structure. | |
| Primitive plus narrow render-spec shape | Ship non-interactive `StatusPill` with tone/label/icon/a11y hooks and an optional map/struct handoff shape, but no domain registry. | ✓ |
| Complete cross-domain status taxonomy now | Solves consistency early but violates Phase 77 ownership and risks wrong semantics across pages. | |

**User's choice:** User delegated the decision to research-backed synthesis.
**Notes:** Recommendation preserves the roadmap boundary: Phase 74 builds the primitive renderer; Phase 77 maps every Oban/Powertools state consistently.

---

## Strict A11y Contracts

| Option | Description | Selected |
|--------|-------------|----------|
| Prose docs + existing axe/VRT gate only | Cheap but creates false confidence; axe cannot prove keyboard behavior, focus quality, or SR announcement quality. | |
| Strict Phoenix primitive contract + targeted browser assertions | Encode a11y in attrs/semantics and add Playwright checks for behavior axe cannot prove. | ✓ |
| Headless/Web Component a11y dependency | Mature behavior, but adds runtime/support/theming burden and conflicts with Phoenix-native isolated assets. | |
| Manual SR/checklist gate pulled forward | Catches more, but duplicates Phase 82 and is hard to make idempotent or merge-blocking now. | |

**User's choice:** User asked for expert UI/UX/accessibility lenses and a one-shot recommendation.
**Notes:** Recommendation: semantic HTML first, strict labels/loading/tooltip/disabled contracts in the primitive API, targeted browser assertions now, full manual accessibility hardening later in Phase 82.

---

## Claude's Discretion

- Exact component module names, attr names, variant atoms, CSS class names, primitive story source names, manifest schema details, and plan splits are left to research/planning.
- Reuse existing proof-seam classes where they satisfy the primitive contract; avoid churn for its own sake.

## Deferred Ideas

- Full cross-domain status taxonomy: Phase 77.
- Form/filter chips and input primitives: Phase 75 and Phase 77.
- ConfirmActionDialog, drawers/popovers, rich operator groups: Phase 78.
- Page migration: Phases 79-81.
- Manual SR/copy/motion/focus hardening: Phase 82.
- Broad host-facing UI kit: reconsider after internal migrations prove API stability.
