# Phase 81: Page Migration Wave 3 — Batches, Workflows, Lifeline - Context

**Gathered:** 2026-07-29
**Status:** Ready for planning
**Mode:** Autonomous smart discuss — recommended decisions accepted by user

<domain>
## Phase Boundary

Migrate Batches, Workflows, and Lifeline onto the existing Powertools app shell,
tokens, forms, data-display components, and operator meta-patterns. Preserve all
existing routes, URL state, authorization, preview/reason/execute behavior,
durable audit evidence, recovery semantics, and domain ownership. This is a
presentation and consistency migration, not a new operator-capability phase.

</domain>

<decisions>
## Implementation Decisions

### Migration Shape and Ownership
- Migrate one production surface at a time in risk order: Batches, Workflows,
  then Lifeline, with focused behavior gates after each surface.
- LiveViews remain coordinators for URL state, authorization, domain calls,
  previews, mutations, receipts, and recovery; shared function components render
  closed presentation maps only.
- Reuse `Primitives`, `Forms`, `DataDisplay`, `OperatorPatterns`,
  `StatusTaxonomy`, and `ControlPlanePresenter`; do not introduce parallel local
  badge, metric, table, dialog, redaction, or blocked-state component systems.
- Preserve all existing route shapes and host ownership boundaries. No runtime
  dependency, schema migration, router surprise, or new operator capability.

### Operator Journeys and Safety
- Batches retain list/detail, progress, callback, retry, and Lifeline-routed
  recovery behavior while adopting shared tables, status, progress, detail, and
  confirmation patterns.
- Workflows retain DAG/step state and existing deep links while using the shared
  taxonomy, timeline/detail surfaces, and `Why blocked?` explanation pattern.
- Lifeline preserves preview → reason → reauthorization → execute → audit
  semantics exactly and renders them through the shared danger pattern; the UI
  must never imply atomic or exactly-once execution.
- Each surface renders only states its production domain can emit. Lifeline's
  single-target seam distinguishes ready, drifted, expired, consumed,
  unauthorized, and successful-with-Audit outcomes; it does not advertise
  aggregate partial/skipped/failed or connection-lifecycle outcomes.

### Responsive and Accessible Composition
- Render one semantic responsive tree per surface; tables reflow rather than
  duplicate, and only bounded labelled machine-content regions may scroll.
- Use conventional controls with durable accessible names, 44px targets,
  visible focus, restrained live regions, dialog containment/Escape/restore,
  and text in addition to color for every status and progress state.
- Support 320px, tablet, wide, 200% zoom, light/dark/system/high-contrast, and
  reduced motion without geometry-moving hover or action-blocking animation.
- Keep the brand’s calm control-room hierarchy: neutral surfaces, restrained
  semantic color, explicit evidence provenance, and “explain, then act” copy.

### Evidence and Completion
- Add deterministic production-composed page stories for Batches, Workflows,
  and Lifeline, including empty/one/many/adversarial, long/unicode/redacted,
  supported partial-evidence/failure/stale states per surface, and open-overlay
  states. Stories must not invent production outcomes.
- Extend the Elixir-owned page catalog and generated manifest rather than
  hard-coding a second browser inventory.
- Require connected behavior, exact ARIA, axe, compare-only VRT across all four
  themes and three viewports, URL/history, authorization-race, confidentiality,
  query-bound, focus, and reduced-motion evidence.
- The phase is complete only when all nine production pages use the shared
  visual contract and the full page-quality graph includes all three new
  families.

### Claude's Discretion
- Private helper/module names, exact plan slicing, finite presenter-map shapes,
  story counts, and token-backed CSS composition are discretionary provided the
  observable behavior, authority boundaries, vocabulary, and verification
  contract above remain intact.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Web.Components.Primitives`, `Forms`, `DataDisplay`, and
  `OperatorPatterns` provide the required presentation layer.
- `StatusTaxonomy` and `ControlPlanePresenter` provide closed status and
  presentation normalization.
- `PageStoryCatalog`, `ShowcaseLive`, the schema-8 manifest, Playwright page
  behavior/ARIA/axe/VRT suites, and exact artifact validators provide the
  established evidence pipeline.

### Established Patterns
- Phase 79 and 80 production pages expose pure page-composition seams used by
  both LiveViews and showcase stories.
- LiveViews own authority and state; components are stateless and filter visual
  escape hatches.
- Database reads, selections, async work, and evidence windows are bounded;
  sensitive values are structurally redacted before assigns and rendering.

### Integration Points
- Production surfaces:
  `lib/oban_powertools/web/batches_live.ex`,
  `lib/oban_powertools/web/workflows_live.ex`, and
  `lib/oban_powertools/web/lifeline_live.ex`.
- Shared presentation:
  `lib/oban_powertools/web/components/`,
  `lib/oban_powertools/web/status_taxonomy.ex`, and
  `lib/oban_powertools/web/control_plane_presenter.ex`.
- Evidence:
  `test/support/page_story_catalog.ex`, `ShowcaseLive`,
  `scripts/showcase_manifest.exs`, and `test/browser/`.

</code_context>

<specifics>
## Specific Ideas

Use the already-verified Phase 79/80 migration recipe and close the exact audit
finding: shared components, taxonomy, groups, showcase stories, VRT, and
accessibility evidence must reach Batches, Workflows, and Lifeline.

</specifics>

<deferred>
## Deferred Ideas

New operator capabilities, alternate route shapes, additional runtime
dependencies, schema changes, and behavior “improvements” beyond parity remain
out of scope.

</deferred>
