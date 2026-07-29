# Phase 81: Page Migration Wave 3 — Batches, Workflows, Lifeline - Research

**Researched:** 2026-07-29
**Domain:** Phoenix LiveView presentation migration, operator safety, deterministic page-quality evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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
- Each surface should render only states its production domain can emit.
  Lifeline's single-target seam supports ready, drifted, expired, consumed,
  authorization refusal, and success with Audit evidence; aggregate and
  connection-lifecycle outcomes would be unsupported product claims.

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
  states without inventing production outcomes.
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

### Deferred Ideas (OUT OF SCOPE)

New operator capabilities, alternate route shapes, additional runtime
dependencies, schema changes, and behavior “improvements” beyond parity remain
out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAGE-03 | Batches (list + detail, chain steps) migrated; Lifeline-routed recovery unchanged. | Preserve `BatchesLive` URL, selection, callback, and Lifeline event ownership; add closed presenters plus shared table/progress/detail/blocked/confirmation composition and production page seams. |
| PAGE-04 | Workflows (list + detail, DAG/blocked state) migrated. | Preserve PubSub refresh and `?step=` deep links; use a semantic bounded step sequence, shared status/blocked/detail presentation, and diagnosis-only Lifeline handoff. |
| PAGE-07 | Lifeline (incident triage, repair preview/reason/execute/audit) migrated with mutation flow unchanged. | Keep `Lifeline.preview_repair/4` and `execute_repair/5` as authority; replace local cards/dialog markup with closed danger-confirmation, detail, metric, table, and timeline maps. |
| GROUP-01 | Operator meta-patterns are assembled from primitives + data components. | Reuse the shipped `filter_bar/1`, `detail_surface/1`, `confirm_action_dialog/1`, `attention_card/1`, `why_blocked/1`, and `audit_entry/1`; do not create page-local equivalents. |
| GROUP-02 | Meta-components encapsulate “explain, then act” preview/reason/audit composition. | Map all Batch/Lifeline preview and result states into the existing closed group APIs while leaving authorization and execution in parent LiveViews. |
| PAGE-10 | Identical concepts look and behave identically across all surfaces. | Use the same status taxonomy, presenter vocabulary, pure production page seams, catalog, manifest, ARIA, axe, and VRT pipeline established by Phases 79–80. |
| A11Y-01 | Automated axe checks run in CI against showcase and pages with zero critical/serious findings. | Extend the manifest-derived page families and required CI lane to Batches, Workflows, and Lifeline; add connected behavior where static showcase checks are insufficient. |
| A11Y-02 | Keyboard operation, visible focus, non-color meaning, and correct dialog behavior. | Add connected keyboard, selection, focus containment/Escape/restore, and authorization-race tests for the three real LiveViews. |
| A11Y-03 | Contrast, target size, and unobscured focus meet the accessibility contract. | Reuse semantic tokens/components and mechanically verify 44px targets, 320px reflow, 200% zoom, and all four themes. |
| A11Y-04 | Reduced motion, exact ARIA, screen-reader, focus, and recovery evidence. | Add exact ARIA snapshots for every new story, three representative VoiceOver targets, reduced-motion connected checks, and sparse announcement assertions. |
| MOTION-01 | Motion uses token-layer durations/easing. | Page CSS must use shipped `--obpt-motion-*` tokens only; no inline timings or animated progress/DAG order. |
| MOTION-02 | Motion is purposeful, interruptible, and reduced-motion safe. | Test dialog/detail transitions with reduced motion and prove focus/action availability is never delayed. |
</phase_requirements>

## Summary

Phase 81 should be planned as a presentation-boundary migration with three
sequential production gates, not as a rewrite of the Batches, Workflows, or
Lifeline domains. The repository already contains the required shared component
library, status registry, presenter, production-composition precedent, schema-8
manifest, connected browser harness, exact ARIA snapshots, axe checks, and
compare-only VRT. The three target LiveViews already implement the operator
journeys that must survive. [VERIFIED: `81-CONTEXT.md`, `81-UI-SPEC.md`,
`lib/oban_powertools/web/components/`, and Phase 79–80 summaries]

The migration is nevertheless security- and correctness-sensitive because
presentation and authority are currently intertwined. `BatchesLive` contains
local badges, progress bars, tables, confirmation markup, raw fallback
serialization, and page-local multi-target execution orchestration.
`WorkflowsLive` contains literal route construction, an unbounded workflow scan,
`Repo.get!/2` detail loading, local status/highlight styling, and result/detail
composition. `LifelineLive` contains local incident tables, metrics, preview
composition, status styling, reason controls, and audit cards; it also currently
renders the repair preview token and retains `inspect/1` fallbacks. Those raw
identity and fallback paths must be removed from the presentation boundary
without changing the server-owned preview identity or mutation state machine.
[VERIFIED: repository inspection of the three target LiveViews on 2026-07-29]

The planner should establish closed presenter contracts and pure production
composition seams first, migrate Batches, then Workflows, then Lifeline, and
only afterward freeze the exact story inventory and browser cardinalities.
Connected tests must remain the authority proof; showcase stories prove
composition, responsive semantics, accessibility, and visual stability but
must never simulate successful authorization or execution. [VERIFIED:
Phase 79–80 `page_content/1` pattern and `81-CONTEXT.md`]

**Primary recommendation:** Implement closed safe page maps plus public pure
`page_content/1` seams, migrate the three LiveViews in the locked risk order,
then extend the single catalog/manifest/browser graph with an exact 50-story
Wave 3 inventory.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| URL parsing, history, selected row/step/incident | Frontend Server (LiveView) | Browser / Client | LiveViews own canonical state; the browser applies patches, focus, and adaptive geometry. [VERIFIED: target LiveViews and Phase 79–80 patterns] |
| Page/resource/action authorization | API / Backend | Frontend Server (LiveView) | `LiveAuth` and domain functions are authoritative; visible controls are presentation only. [VERIFIED: `LiveAuth` call sites] |
| Batch/callback/repair preview and execution | API / Backend | Database / Storage | `Lifeline` creates durable previews, revalidates, executes, and records evidence. [VERIFIED: `lib/oban_powertools/lifeline.ex`] |
| Workflow diagnosis and step evidence | API / Backend | Database / Storage | `Explain`, workflow records, steps, edges, and results own causal/domain truth. [VERIFIED: `WorkflowsLive.load_workflow_detail/3`] |
| Closed labels, redaction, state/result maps | Frontend Server (SSR) | API / Backend | `ControlPlanePresenter` projects already-authorized domain truth into finite render-safe maps. [VERIFIED: Phase 79–80 presenters] |
| Semantic tables, detail, blocked explanation, confirmation | Frontend Server (SSR) | Browser / Client | Function components render one DOM tree; shipped JS controls focus/adaptive detail only. [VERIFIED: `DataDisplay` and `OperatorPatterns`] |
| Responsive geometry, focus mechanics, reduced motion | Browser / Client | Frontend Server (SSR) | Token CSS and shipped hooks adapt one semantic server-rendered tree. [VERIFIED: token assets and browser harness] |
| Page stories and quality inventory | Test / Dev support | Browser test runner | Elixir owns normalized fixtures and the generated manifest; Playwright consumes that inventory. [VERIFIED: `PageStoryCatalog` and schema-8 manifest] |

## Current Baseline

- The focused target suite passed **36 tests with 0 failures** on 2026-07-29:
  `mix test test/oban_powertools/web/live/batches_live_test.exs
  test/oban_powertools/web/live/workflows_live_test.exs
  test/oban_powertools/web/live/lifeline_live_test.exs
  test/oban_powertools/web/status_taxonomy_test.exs --seed 0`.
  [VERIFIED: fresh local test run]
- The generated page catalog currently contains exactly 49 page stories:
  Overview 3, Cron 8, Limiters 4, Audit 4, Jobs 18, and Forensics 12.
  The schema-8 manifest locks 113 total showcase targets, 147 page ARIA
  snapshots, and 588 page PNGs. [VERIFIED: fresh catalog evaluation plus
  `scripts/showcase_manifest.exs` and validators]
- The three target pages do not expose public `page_content/1` functions and are
  not in `ShowcaseLive.@page_story_pages`; the six already migrated families do.
  [VERIFIED: source grep]
- Graphify is disabled and `.planning/graphs/graph.json` is absent, so no graph
  context was used. [VERIFIED: `gsd-tools graphify status`]

## Standard Stack

No package installation is required or permitted for Phase 81.

### Core

| Library / subsystem | Resolved version | Purpose | Why Standard Here |
|---------------------|------------------|---------|-------------------|
| Elixir | `~> 1.19` project constraint | Runtime and test language | Existing project contract. [VERIFIED: `mix.exs`] |
| Phoenix | 1.8.7 | Routing and server rendering | Existing host-integrated web stack. [VERIFIED: `mix deps`] |
| Phoenix LiveView | 1.1.31 | URL/event orchestration and server-rendered UI | Existing implementation and test model. [VERIFIED: `mix deps`] |
| Ecto SQL / Postgrex | 3.14.0 / 0.22.2 | Bounded domain reads and durable evidence | Existing database stack; no migration is planned. [VERIFIED: `mix deps`] |
| Oban | 2.23.0 | Job records and supported job mutation substrate | Existing dependency behind domain authorities. [VERIFIED: `mix deps`] |
| Local design system | repository version | Semantic tokens, forms, data display, operator patterns | Required reuse target; eliminates parallel page-local UI systems. [VERIFIED: `81-CONTEXT.md`] |

### Supporting

| Library / tool | Resolved version | Purpose | When to Use |
|----------------|------------------|---------|-------------|
| ExUnit + Phoenix.LiveViewTest | project stack | Pure presenter, component, LiveView, authorization, URL, and query tests | Every production task. [VERIFIED: existing tests] |
| LazyHTML | resolved project dependency | Semantic rendered-HTML assertions | Component/page structure contracts. [VERIFIED: `mix.exs`] |
| Playwright | 1.61.0 | Connected browser behavior, exact ARIA, VRT, zoom, focus, motion | Wave 3 browser and full page-quality gates. [VERIFIED: lockfile] |
| axe-core / axe Playwright | 4.11.4 / 4.11.3 | Automated WCAG-tagged accessibility scans | Every generated new page story in the existing axe matrix. [VERIFIED: lockfile and browser specs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing local components | New page-local components or third-party UI library | Forbidden by locked scope; would fork semantics, themes, focus, and evidence. [VERIFIED: `81-CONTEXT.md`] |
| Semantic ordered step list | Canvas or ARIA graph widget | Would make DAG truth depend on spatial/pointer interpretation and add a new dependency. [VERIFIED: `81-UI-SPEC.md`] |
| Elixir-owned story catalog | TypeScript story inventory | Would create a second source of truth and weaken exact manifest checks. [VERIFIED: Phase 79–80 architecture] |

## Package Legitimacy Audit

Not applicable. Phase 81 installs no external package and must not change
`mix.exs`, `mix.lock`, `package.json`, or `package-lock.json` for feature work.
[VERIFIED: locked scope]

## Existing Architecture and Integration Seams

### Shared presentation APIs to use

| Module | Existing symbols | Phase 81 usage |
|--------|------------------|----------------|
| `Components.Primitives` | `button/1`, `link/1`, `status_pill/1`, `surface/1`, `divider/1`, `stat/1` | Page actions and neutral structure only. [VERIFIED: source] |
| `Components.Forms` | `input/1`, `textarea/1`, `select/1`, `checkbox/1`, `radio_group/1`, `field_group/1` | Batch filters/selection and shared reason form. [VERIFIED: source] |
| `Components.DataDisplay` | `data_table/1`, `state_message/1`, `description_list/1`, `machine_value/1`, `timeline/1`, `progress_bar/1`, `metric_card/1`, `args_viewer/1`, `redacted_value/1` | All three page families. [VERIFIED: source] |
| `Components.OperatorPatterns` | `confirm_action_dialog/1`, `detail_surface/1`, `filter_bar/1`, `attention_card/1`, `why_blocked/1`, `audit_entry/1` | All grouped operator journeys; no local substitutes. [VERIFIED: source] |
| `StatusTaxonomy` | `spec/2`, `all_specs/0` | Batch/member/callback/workflow/step/Lifeline/continuity/operator-result statuses. Existing domains already cover all target families. [VERIFIED: registry inspection] |
| `ControlPlanePresenter` | existing page presenters, status/copy, workflow refusal, audit helpers, result normalization | Extend with closed Batches, Workflows, and Lifeline page maps. [VERIFIED: source] |
| `Selectors` | Batches, Lifeline, Jobs, Forensics, Audit helpers | Add a closed Workflows helper and close Batches/Lifeline accepted key ordering where needed without changing route shapes. [VERIFIED: source] |

### Production composition pattern

Use the Phase 79–80 flow:

```text
URL / connected event
        |
        v
LiveView parse + authorize + bounded domain read
        |
        v
ControlPlanePresenter closed safe map
        |
        v
public pure page_content/1
        |
        +--> production LiveView render
        |
        `--> deterministic PageStoryCatalog fixture via ShowcaseLive
```

The pure page seam must not read the Repo, call authorization, capture current
time, start processes, or serialize raw domain structs. [VERIFIED: Phase 80
source audits and `81-CONTEXT.md`]

## Page-Specific Findings

### Batches

`BatchesLive` already owns the required index/detail routes, status/name/queue/
worker/chain/page URL state, page-local failed-member selection, callback
preview, reason, execute, pagination, and back-path logic. `Batches.list/3`
applies a page limit/offset, while `count_by_status/2` currently issues one
query per status. [VERIFIED: `BatchesLive` and `Batches`]

The template must be decomposed into two pure seams:

1. `page_content/1` for the Batches scan.
2. `detail_page_content/1` for the full route detail and its one confirmation.

Recommended closed maps:

- `present_batch_row/2`: safe identity, `StatusTaxonomy.spec(:batch, state)`,
  progress value/max, failed/retryable counts, callback posture, updated
  absolute/relative copy captured before presentation, chain label, and explicit
  inspect path.
- `present_batch_detail/2`: identity facts, status, progress, one blocked map,
  finite failed-member rows, finite callback rows, chain description items,
  finite audit entries, permissions, and safe destinations.
- `present_batch_retry_preview/2` and result maps: counts, exclusions,
  consequence, non-effect, confirmation state, and finite per-target outcomes;
  never preview tokens or before/after maps.

The existing `payload_copy/1` fallback to `inspect/1`, local badge-class
functions, inline `style="width:..."` progress, raw callback/member last-error
rendering, and literal `<table>`/dialog markup must disappear from page
composition. [VERIFIED: `BatchesLive` source and `81-UI-SPEC.md`]

Do not redesign bulk execution in this phase. Preserve page-local selection and
per-target Lifeline preview/execute behavior, but revalidate the current finite
eligible set and action authorization at the existing boundaries before
execution. Add tests proving the presentation migration neither broadens the
selected scope nor leaks preview identity. [VERIFIED: locked phase boundary]

### Workflows

`WorkflowsLive` is read-only and already preserves selected step state through
PubSub refresh, derives domain stories through `Explain`, routes legal actions
to Lifeline, routes evidence to Forensics, and routes generic job identity to
Oban Web. It currently builds workflow and step URLs locally, reads all
workflows, loads detail with `Repo.get!/2`, and renders the DAG as local cards.
[VERIFIED: `WorkflowsLive`]

Recommended closed maps:

- `present_workflow_row/2`: workflow name/identity, shared operator status,
  step count, callback posture summary, and inspect path.
- `present_workflow_detail/2`: status, diagnosis, runnable count, semantics,
  callback posture, latest recovery evidence, and optional safe refusal map.
- `present_workflow_step/2`: position, dependency labels, status, diagnosis,
  refusal, selected state, and explicit step path.
- `present_workflow_step_detail/3`: safe worker/identity, status/diagnosis,
  result availability and redacted summary, dependency reasons/items,
  Forensics path, optional Lifeline handoff, and optional inspection-only Oban
  Web path.

Add `Selectors.workflows_path/1` and `workflow_detail_path/2` with exactly the
existing route shapes and a closed `step` query key. Replace `Repo.get!/2` with
a uniform unavailable branch after resource authorization so malformed,
missing, and unauthorized detail states do not crash or enumerate. Bound the
workflow scan and step/result/evidence windows to finite values and expose
completeness when truncated; do not change workflow semantics or add search or
pagination UI. [VERIFIED: `81-UI-SPEC.md` query-bound and unavailable contracts]

Render the DAG as one semantic ordered list with visible dependency
relationships. `Edge` records may inform ordering/relationships, but visual or
chronological adjacency must not be promoted to causal proof. [VERIFIED:
`81-UI-SPEC.md`]

### Lifeline

`LifelineLive` is the highest-risk file. It owns incident projection and views,
workflow handoff rows, selected incident state, preview creation, reason,
reauthorization, execution, durable audit lookup, Forensics/Oban Web
destinations, continuity, healthy executors, and archive/retention evidence.
[VERIFIED: `LifelineLive`]

The migration should keep those event/domain calls in place while extracting:

- `present_lifeline_summary/1`
- `present_incident_row/2`
- `present_incident_detail/2`
- `present_repair_confirmation/3`
- `present_repair_result/2`
- `present_lifeline_audit_entry/2`
- `present_executor_row/1` and `present_archive_summary/1`

The current page visibly renders `Preview Token`, raw action/target identity,
snapshot fallback via `inspect/1`, and generic `error_message(reason) ->
inspect(reason)`. These are direct violations of the locked confidentiality
contract and must be removed rather than visually hidden. The server may retain
the preview struct/token in assigns because execution requires it, but
`page_content/1`, story assigns, rendered text/attributes, browser channels,
logs, and telemetry must receive only closed projections. [VERIFIED:
`LifelineLive` and `81-UI-SPEC.md`]

Use `confirm_action_dialog/1` with danger intent and its complete state set:
`:preview`, `:submitting`, `:partial`, `:failed`, `:expired`, `:drifted`, and
`:consumed`. Keep reason in a `Phoenix.HTML.Form`; validate blank and fewer than
eight trimmed characters in the parent. At most one detail or confirmation may
be modal: close/leave adaptive incident detail before opening confirmation.
[VERIFIED: existing group API and UI spec]

`Lifeline.list_incidents/2`, executor expansion, audit history, healthy
executors, and retention evidence must have explicit finite query/render
bounds. Preserve current projection semantics; add completeness copy rather
than silently truncating. [VERIFIED: `81-CONTEXT.md` Evidence and Completion]

## Recommended Story Inventory

Freeze the following exact **50 new stories** before generating any baseline.
This recommendation yields 99 page stories, 163 total showcase targets, 297
page ARIA snapshots (`99 × 3`), and 1,188 page PNGs (`99 × 4 × 3`) if the
manifest object contract remains schema 8.

### Batches — 18 stories

1. `page-batches-empty-unfiltered`
2. `page-batches-empty-filtered`
3. `page-batches-one-progress`
4. `page-batches-many-boundary-page`
5. `page-batches-high-count-progress`
6. `page-batches-adversarial-redacted`
7. `page-batches-output-unavailable-chain`
8. `page-batches-output-expired-chain`
9. `page-batches-mixed-selection`
10. `page-batches-permission-denied`
11. `page-batches-saturated-failed-members`
12. `page-batches-stuck-callbacks`
13. `page-batches-callback-unavailable`
14. `page-batches-bulk-confirmation`
15. `page-batches-callback-confirmation`
16. `page-batches-drifted-recovery`
17. `page-batches-partial-disconnected`
18. `page-batches-clean-receipt-audit`

### Workflows — 12 stories

1. `page-workflows-empty-chooser`
2. `page-workflows-one-running`
3. `page-workflows-many-deep-bounded`
4. `page-workflows-all-complete`
5. `page-workflows-blocked-dag`
6. `page-workflows-selected-blocked-step`
7. `page-workflows-dependency-reasons`
8. `page-workflows-callback-recovery-posture`
9. `page-workflows-result-unavailable`
10. `page-workflows-adversarial-redacted`
11. `page-workflows-refusal-lifeline-handoff`
12. `page-workflows-unavailable-restricted`

### Lifeline — 20 stories

1. `page-lifeline-no-active-incidents`
2. `page-lifeline-active-one`
3. `page-lifeline-active-saturated`
4. `page-lifeline-resolved-history`
5. `page-lifeline-healthy-archive`
6. `page-lifeline-dead-executor`
7. `page-lifeline-stuck-workflow`
8. `page-lifeline-callback-variant`
9. `page-lifeline-adversarial-redacted`
10. `page-lifeline-permission-restricted`
11. `page-lifeline-unavailable`
12. `page-lifeline-partial-unknown-evidence`
13. `page-lifeline-host-follow-up-states`
14. `page-lifeline-preview-open`
15. `page-lifeline-invalid-short-reason`
16. `page-lifeline-execute-loading-auth-race`
17. `page-lifeline-drifted-preview`
18. `page-lifeline-expired-preview`
19. `page-lifeline-consumed-preview`
20. `page-lifeline-clean-success-audit`

Story fixtures may combine adjacent named states inside one bounded page only
when every state remains visible and independently asserted. Never overload one
story by switching hidden state after activation; exact ARIA and screenshots
must represent the named state deterministically.

## Recommended Sequencing

1. **Contract foundation:** add failing presenter, selector, composition-boundary,
   confidentiality, and bounded-query tests; define finite map shapes.
2. **Batches production:** implement presenters and index/detail pure seams;
   switch LiveView rendering to shared components while preserving events.
3. **Batches connected gate:** prove URL/back/selection/callback/bulk/auth-race/
   drift behavior and no confidential DOM/browser-channel data.
4. **Workflows production:** add closed selectors, uniform unavailable handling,
   finite reads/presenters, semantic DAG, pure seam, and shared detail/blocked
   composition.
5. **Workflows connected gate:** prove direct/reload/patch/PubSub selection
   parity, legal Lifeline handoff, and diagnosis-only ownership.
6. **Lifeline projection foundation:** build closed incident/preview/result/audit
   maps and tests before changing markup.
7. **Lifeline production:** migrate metrics/table/detail/blocked/danger dialog/
   result/timeline while preserving the exact preview/reason/reauthorize/execute
   calls.
8. **Lifeline connected gate:** prove every recovery state, duplicate-submit
   suppression, focus, Escape, authorization race, and durable Audit evidence.
9. **Catalog/showcase/styles:** append the locked 50 stories, delegate to the
   three production seams, extend all exact family/count validators, and
   regenerate the packaged CSS byte-identically.
10. **Connected fixture/browser graph:** add isolated Wave 3 fixtures and the
    Wave 3 Playwright spec; extend `verify:pages` in preserved order.
11. **Evidence closure:** generate/review exact ARIA and PNG additions, run fresh
    compare-only tests, targeted VoiceOver discovery, full ExUnit, format, and
    compile warnings gates.

Do not generate or update screenshots before production seams, story IDs,
activation states, and exact counts are frozen.

## File and Symbol Integration Map

### Production

| File | Symbols / change |
|------|------------------|
| `lib/oban_powertools/web/batches_live.ex` | Keep mount/params/events/loaders; add `page_content/1` and `detail_page_content/1`; remove page-local badges/progress/tables/dialog/redaction fallback. |
| `lib/oban_powertools/web/workflows_live.ex` | Keep PubSub and selection; add pure `page_content/1`; use closed selectors, safe detail branch, shared table/list/detail/blocked patterns. |
| `lib/oban_powertools/web/lifeline_live.ex` | Keep preview/reason/execute/data ownership; add pure `page_content/1`; replace local metrics/table/preview/audit composition; remove token/raw fallback rendering. |
| `lib/oban_powertools/web/control_plane_presenter.ex` | Add closed row/detail/preview/result/audit map functions for all three families; centralize timestamps, status specs, completeness, redaction, and copy. |
| `lib/oban_powertools/web/selectors.ex` | Add Workflows helpers and closed/order-stable Batches/Lifeline parameter helpers without changing paths. |
| `lib/oban_powertools/batches.ex` | Only if needed for grouped counts or explicit finite detail windows; preserve public behavior. |
| `lib/oban_powertools/lifeline.ex` | Only if explicit list/window limits cannot be expressed by existing options; do not alter mutation semantics. |
| `lib/oban_powertools/web/dev/showcase_live.ex` | Add aliases/families/count and direct calls to the three production page seams. |
| `assets/oban_powertools/tokens.css` | Token-backed Wave 3 page composition, semantic DAG/list, reflow, selection, progress, detail, dialog, and reduced-motion styles. |
| `priv/static/oban_powertools/oban_powertools.css` | Regenerate from source; require byte-equality contract. |

### Unit and LiveView tests

- `test/oban_powertools/web/live/batches_live_test.exs`
- `test/oban_powertools/web/live/workflows_live_test.exs`
- `test/oban_powertools/web/live/lifeline_live_test.exs`
- `test/oban_powertools/web/control_plane_presenter_test.exs`
- `test/oban_powertools/web/selectors_test.exs`
- `test/oban_powertools/web/status_taxonomy_test.exs`
- relevant `Batches`, `Lifeline`, and Audit context tests if query APIs change
- component tests only when a generic shipped component defect is found

### Catalog, fixture, browser, and contract files

- `test/support/page_story_catalog.ex`
- `test/oban_powertools/page_story_catalog_test.exs`
- `test/oban_powertools/showcase_catalog_test.exs`
- `test/oban_powertools/web/live/showcase_live_test.exs`
- `scripts/showcase_manifest.exs`
- `test/browser/support/manifest.ts`
- `test/browser/support/manifest-smoke.mjs`
- `test/browser/support/verify-page-baselines.mjs`
- `test/browser/support/verify-page-aria-snapshots.mjs`
- new `test/browser/specs/page-migration-wave-3.spec.ts`
- new Wave 3 connected fixture support in the isolated example host
- `package.json` only to append the Wave 3 connected spec to existing ordered
  commands, not to add dependencies
- exact new YAML under `test/browser/__aria_snapshots__/`
- exact reviewed PNGs under `test/browser/__screenshots__/`
- `test/browser/voiceover/page.voiceover.spec.ts` for three representative
  production-composed stories

### Files that should not change

- production router route shapes
- database migrations and schemas
- domain mutation authority or authorization model
- `mix.exs`, `mix.lock`, and dependency versions
- manifest schema version unless a genuinely new serialized field is required
- existing Wave 1/2 baselines except intentional shared-style changes reviewed
  and attributed explicitly

## Architecture Patterns

### Pattern 1: Parent-owned truth, component-owned composition

The LiveView loads and authorizes; the presenter closes the map; the component
renders it:

```elixir
# Source: repository Phase 79–80 production-composition pattern
def render(assigns), do: page_content(assigns)

attr :rows, :list, required: true
attr :detail, :map, default: nil
attr :confirmation, :map, default: nil

def page_content(assigns) do
  ~H"""
  <DataDisplay.data_table
    id="resource-table"
    caption="Resources"
    rows={@rows}
    row_id={& &1.id}
  >
    <:col :let={row} label="Status">
      <DataDisplay.status_pill domain={row.status.domain} state={row.status.state} />
    </:col>
  </DataDisplay.data_table>
  """
end
```

### Pattern 2: Closed preview projection

Pass only consequence and finite result truth to
`confirm_action_dialog/1`. Keep the preview struct/token exclusively in
server-owned assigns. [VERIFIED: `OperatorPatterns.confirm_action_dialog/1`]

### Pattern 3: One semantic tree

Use one native table/list/detail tree. CSS and the existing adaptive controller
change geometry; breakpoint code must not duplicate content or mutate URL,
selection, reason, or preview state. [VERIFIED: `81-UI-SPEC.md`]

### Pattern 4: Canonical URLs before reads

Parse and normalize recognized keys, reject or canonicalize incompatible
values, then authorize and query. Use `Selectors`; do not concatenate raw query
values into paths. [VERIFIED: Phase 80 selector pattern]

### Anti-Patterns to Avoid

- Local `*_badge_class`, `*_tab_class`, `primary_button_class`, metric-card,
  table, dialog, blocked card, progress, or timeline helpers.
- `inspect/1`, `Jason.encode!/1`, raw metadata, raw reasons, raw errors, preview
  tokens, plan hashes, or snapshots at the render boundary.
- `Repo.get!/2` for user-selected details where missing and unauthorized must be
  indistinguishable.
- Whole-row click targets, duplicate mobile markup, ARIA grids, canvas-only
  DAGs, nested dialogs, and modal detail beneath confirmation.
- Unbounded `Repo.all`, incident expansion, audit history, callback/member
  lists, step lists, or story DOM.
- Updating snapshots to make tests pass before reviewing changed scope.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Status color/label/icon | Page-specific class switch | `StatusTaxonomy` + `DataDisplay.status_pill/1` | Closed unknown behavior and cross-page consistency. |
| Progress | Inline-width div | `DataDisplay.progress_bar/1` | Native semantics, clamping, unavailable state, reduced-motion safety. |
| Tables/reflow | Local table plus mobile cards | `DataDisplay.data_table/1` | One semantic tree, captions, responsive labels. |
| Empty/error/unavailable | Ad hoc cards/copy | `state_message/1` with page-specific detail slot | Shared state semantics and roles. |
| Detail focus/adaptation | Custom modal/drawer JS | `OperatorPatterns.detail_surface/1` | Existing adaptive/focus contract. |
| Confirmation/reason/results | Local modal/form/result markup | `confirm_action_dialog/1` | Explain-before-act, form association, state/focus/recovery semantics. |
| Blocked explanation | Raw blocker arrays | `why_blocked/1` fed by presenter | Human reason, completeness, evidence, next move. |
| Audit history | Local cards | `timeline/1` or `audit_entry/1` | Current/history distinction and semantic ordering. |
| Redaction | Truncation or CSS hiding | `DisplayPolicy` + closed presenter maps | Secret originals never enter DOM/attributes. |
| Story inventory | TS array or copied markup | `PageStoryCatalog` + generated manifest | One exact source of truth. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Existing batches, workflow/step/result rows, Lifeline incidents/previews, callbacks, heartbeats, archives, and audit events remain authoritative; no stored identifier is renamed. [VERIFIED: schemas and locked no-migration scope] | No data migration. Test against representative retained states and preserve read/write semantics. |
| Live service config | Host repo, auth adapter, display policy, dashboard path, PubSub, and optional fixture flags remain host/runtime owned. [VERIFIED: LiveView/domain source] | No production config change. Any Wave 3 fixture endpoint must remain test-compiled and explicit opt-in. |
| OS-registered state | No service/task/daemon name changes are in scope. [VERIFIED: migration is page presentation only] | None. |
| Secrets/env vars | Existing Phase 79/80 browser fixture secrets are test-only. Wave 3 needs an isolated secret or a safely generalized existing fixture contract; secrets must never enter HTML/log assertions. [VERIFIED: browser fixture source and UI spec] | Add only test launcher wiring; no production env var or secret rename. |
| Build artifacts / installed packages | Source CSS and packaged `priv/static` CSS, generated manifest, tracked ARIA YAML, and PNG baselines encode the current six-family graph. [VERIFIED: validators] | Regenerate exact artifacts after inventory freeze; do not reinstall or add packages. |

## Threat and Risk Analysis

| Threat / failure mode | Where it exists | Required mitigation and proof |
|-----------------------|-----------------|-------------------------------|
| Preview-token / plan-hash disclosure | Lifeline currently renders `Preview Token`; previews also contain raw snapshots/metadata. | Closed confirmation map; DOM, attributes, page-story serialization, console/network/websocket body scan must exclude token/hash/snapshot sentinels. |
| Raw error/payload disclosure or XSS | Batches and Lifeline retain `inspect/1`/serialization fallbacks and raw error material. | Structural `DisplayPolicy` projection before assigns; hostile HTML/Unicode/RTL/secret sentinels in unit, story, and connected browser tests. |
| IDOR / resource enumeration | Workflow `Repo.get!/2`, page/detail distinctions, action races. | Parse → authorize → scoped safe lookup; identical unavailable rendering and zero/bounded query evidence for malformed/unauthorized IDs. |
| Authorization race | Batch/Lifeline preview may outlive permissions or target state. | Reauthorize immediately before execute; connected fixture revokes permission after preview and proves no mutation plus persistent recovery guidance. |
| Replay / duplicate execution | Double submit, stale ready preview, reconnect. | Server-owned single-use preview, native loading/disabled state, duplicate-submit browser test, consumed/drifted/expired recovery states. |
| Scope drift in batch selection | Selected IDs can become ineligible between render and execute. | Recompute finite eligible membership and Lifeline preview each target; report skipped/failed independently; test mixed transition. |
| Unbounded read/DOM denial of service | Workflow list/steps, Lifeline incident expansion/history, Batch status counts. | Explicit SQL/result limits, limit-plus-one completeness, stable order, bounded stories, query-count/row-count assertions. |
| Causal overclaim | DAG adjacency, callbacks, recovery history. | Presenter keeps current status, diagnosis, callback posture, recovery attempt, provenance, and completeness independent. |
| Focus loss / nested modality | Adaptive detail plus confirmation, patch/PubSub refresh. | One modal maximum; close detail before confirmation; exact Escape/contain/restore/result-focus tests across breakpoints. |
| False-green visual evidence | Hard-coded counts/families or broad baseline update. | Elixir-owned exact inventory, generated manifest equality, changed-scope validator, fresh compare-only run in required CI. |
| Route/query injection or state confusion | Literal Workflows paths; permissive Lifeline/Batches selectors. | Closed accepted keys/order, encoded values, incompatible-value canonicalization before query, selector property/adversarial tests. |
| Motion obscures state/action | Local CSS transitions or animated progress/reorder. | Token-only duration/easing, no progress/order animation, reduced-motion browser assertion, focus/action timing proof. |

## Common Pitfalls

### Treating this as a CSS-only phase

**What goes wrong:** Raw structs, tokens, errors, and local status semantics
remain in templates under new classes.

**Avoidance:** Presenter contracts and confidentiality tests precede markup.

### Letting stories own special markup

**What goes wrong:** VRT passes against a prettier test-only surface while the
real LiveView remains different.

**Avoidance:** Stories call public production seams and provide normalized
assigns only.

### Weakening authority while simplifying dialogs

**What goes wrong:** Preview readiness is treated as authorization, or execution
moves into the component.

**Avoidance:** Components receive labels/state only; LiveViews retain every
authorize/preview/execute call.

### Combining adaptive detail and confirmation

**What goes wrong:** Two modals exist, focus is trapped in the wrong layer, or
hidden sensitive detail remains behind the confirmation.

**Avoidance:** One modality at a time and one DOM tree.

### Silent truncation

**What goes wrong:** A bounded query appears to prove complete evidence.

**Avoidance:** Carry exact/has-more/completeness truth in closed maps and copy.

### Broad baseline churn

**What goes wrong:** Shared CSS changes alter prior 588 PNGs, and updates are
accepted without attribution.

**Avoidance:** Review changed scope by family/theme/viewport; existing Wave 1/2
changes require explicit rationale.

## Validation Architecture

Nyquist validation is enabled because
`.planning/config.json` does not set `workflow.nyquist_validation` to `false`.
[VERIFIED: config inspection]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit/Phoenix.LiveViewTest plus Playwright 1.61.0 and axe-core 4.11.4 |
| Config file | `.formatter.exs`, `playwright.config.ts`, `voiceover.config.ts` |
| Quick run command | `mix test test/oban_powertools/web/live/batches_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/control_plane_presenter_test.exs test/oban_powertools/web/selectors_test.exs --seed 0` |
| Story contract command | `mix test test/oban_powertools/page_story_catalog_test.exs test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0` |
| Connected Wave 3 command | `PAGE_QUALITY_ONLY=1 npx playwright test test/browser/specs/page-migration-wave-3.spec.ts --project=chromium-wide` |
| Full page-quality command | `npm run verify:pages` |
| Full repository gate | `mix format --check-formatted && mix compile --warnings-as-errors && mix test --seed 0` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PAGE-03 | Batches scan/detail/chain/callback/selection/retry parity | LiveView + connected E2E | `mix test test/oban_powertools/web/live/batches_live_test.exs --seed 0` then Wave 3 Playwright grep `Batches` | ✅ extend / ❌ Wave 0 browser |
| PAGE-04 | Workflows scan/DAG/step/PubSub/deep-link/Lifeline handoff | LiveView + connected E2E | `mix test test/oban_powertools/web/live/workflows_live_test.exs --seed 0` then Wave 3 Playwright grep `Workflows` | ✅ extend / ❌ Wave 0 browser |
| PAGE-07 | Lifeline incident/preview/reason/reauthorize/execute/audit parity | LiveView + connected E2E | `mix test test/oban_powertools/web/live/lifeline_live_test.exs --seed 0` then Wave 3 Playwright grep `Lifeline` | ✅ extend / ❌ Wave 0 browser |
| GROUP-01/02 | Pages use shipped grouped components; no local substitutes | Source contract + component render | `mix test test/oban_powertools/web/components/operator_patterns_test.exs test/oban_powertools/web/components/data_display_test.exs --seed 0` | ✅ extend source assertions |
| PAGE-10 | Production seams, exact nine-family catalog/manifest | Unit + generated contract | `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs test/browser/.generated/showcase-manifest.json` | ✅ extend |
| A11Y-01 | Zero critical/serious axe across all stories | Browser axe matrix | `PAGE_QUALITY_ONLY=1 npx playwright test test/browser/specs/showcase.a11y.spec.ts` | ✅ inventory-driven |
| A11Y-02 | Keyboard, focus, dialog, non-color meaning | Connected + ARIA | Wave 3 spec plus `showcase.a11y.spec.ts` | ❌ Wave 0 connected cases |
| A11Y-03 | 44px, contrast themes, 320px and 200% zoom | Connected + VRT | Wave 3 spec plus `showcase.vrt.spec.ts` | ❌ Wave 0 connected cases / ✅ VRT harness |
| A11Y-04 | Exact ARIA, reduced motion, focus/recovery, VoiceOver targets | Snapshot + connected + discovery | `node test/browser/support/verify-page-aria-snapshots.mjs` and `npx playwright test --config=voiceover.config.ts --list` | ✅ extend inventory/spec |
| MOTION-01/02 | Token-only, reduced-safe, nonblocking transitions | CSS contract + browser | asset contract tests plus Wave 3 reduced-motion case | ✅ extend / ❌ Wave 0 case |

### Exact Unit/LiveView Assertions

Add assertions for:

- public pure `page_content/1` functions render from normalized assigns without
  Repo, authorization, clock, Task, or process work;
- closed presenter maps have exact keys and reject raw structs/unknown values;
- no `preview_token`, `plan_hash`, raw before/after/evidence maps, raw reason,
  exception, callback payload, job payload, or secret sentinel reaches rendered
  HTML;
- each page contains exactly one H1, each table has one caption, each status
  uses taxonomy-backed presentation, and each page has at most one dialog;
- Batches preserves canonical filter/page/back URLs, page-local eligible
  selection, mixed state, preview/execute reauthorization, and finite outcomes;
- Workflows preserves `?step=`, reload/PubSub selection, uniform unavailable
  detail, one ordered step tree, and diagnosis-only handoff;
- Lifeline preserves view/selection, one preview, blank/short reason errors,
  drift/expiry/consumption, duplicate suppression, authorization refusal,
  clean receipt, and Audit evidence;
- query counts and returned/rendered rows remain bounded for saturated fixtures.

### Exact Connected Browser Assertions

Create `page-migration-wave-3.spec.ts` and prove:

1. connected production URLs, never Showcase routes;
2. Batches status/filter/page/detail/back history and mixed selection;
3. callback and bulk confirmation, Escape, focus containment/restore, target
   drift, permission revocation, partial result, and Audit follow-up;
4. Workflows direct detail/step URL, patch, reload, PubSub refresh, semantic
   dependency reading order, unavailable resource, Forensics/Lifeline/Oban Web
   ownership;
5. Lifeline view/incident/workflow handoff URL, preview, invalid reason,
   execute loading, duplicate click, authorization race, drift/expiry/consumed,
   and clean success, with every state produced through the real domain seam;
6. browser-channel sentinel scans across HTML, console, page errors, requests,
   responses, WebSocket frames, attributes, titles, hidden text, and URLs;
7. 320px no page overflow, 200% zoom, 44px targets, visible focus, one semantic
   tree, one modal maximum, reduced motion, and sparse live announcements.

### Sampling Rate

- **Per task:** owning focused ExUnit file(s), under 30 seconds.
- **Per page migration:** owning LiveView/context/presenter/selector suite plus
  the page-family connected Playwright grep.
- **Per catalog/style wave:** catalog/showcase/asset tests plus manifest and
  validator contracts.
- **Phase gate:** full repository gate and fresh `npm run verify:pages` with
  exact counts and compare-only VRT.

### Wave 0 Gaps

- [ ] Extend presenter and selector tests with exact closed-map/key contracts.
- [ ] Add pure composition/source-boundary tests for Batches, Workflows, and
  Lifeline.
- [ ] Lock the exact 50-story ID/order/family/activation inventory in
  `page_story_catalog_test.exs`.
- [ ] Add isolated Wave 3 connected fixture routes/state/control helpers,
  guarded by test compilation plus an explicit nonblank secret.
- [ ] Add `test/browser/specs/page-migration-wave-3.spec.ts`.
- [ ] Extend exact counts/families in manifest smoke, TypeScript manifest,
  ShowcaseLive, baseline, ARIA, and catalog validators.
- [ ] Add three exact VoiceOver discovery targets: one Batches confirmation,
  one blocked Workflow step, and one Lifeline preview/result.

No framework installation gap exists.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Indirectly | Preserve host/session actor establishment; Phase 81 adds no auth mechanism. [VERIFIED: `LiveAuth`] |
| V3 Session Management | Indirectly | Do not persist reason/preview identity client-side; preserve LiveView session boundaries. [VERIFIED: UI spec] |
| V4 Access Control | Yes | Page/resource/action authorization and immediate pre-execute reauthorization; uniform unavailable states. [VERIFIED: context] |
| V5 Validation, Sanitization and Encoding | Yes | Closed URL keys, canonical parsing, HEEx escaping, structural display-policy projection. [VERIFIED: selectors and UI spec] |
| V6 Stored Cryptography | No new control | No cryptographic primitive or secret storage change. [VERIFIED: scope] |
| V7 Error Handling and Logging | Yes | Closed error vocabulary; no `inspect/1`, secrets, preview identity, reasons, or raw metadata in DOM/logs/telemetry. [VERIFIED: UI spec] |
| V10 Malicious Code / Input | Yes | Hostile fixture strings remain escaped and redacted before rendering; no arbitrary HTML. [VERIFIED: existing adversarial story pattern] |
| V13 API / Service Communication | Indirectly | Connected fixture endpoints are test-only, secret-gated, finite, and fail closed. [VERIFIED: Phase 80 fixture pattern] |

### Known Threat Patterns

The concrete STRIDE-style threats and mitigations are enumerated in
`## Threat and Risk Analysis`; every high-risk item must map to at least one
automated unit/LiveView assertion and one connected or artifact assertion where
the browser boundary is relevant.

## Environment Availability

This phase has no new external service or package dependency. The local Elixir,
PostgreSQL-backed test harness, Node, and Playwright infrastructure are already
operational: the focused ExUnit baseline passed and the existing manifest can
be generated. [VERIFIED: fresh local commands]

The only known optional environment limitation inherited from Phase 80 is real
VoiceOver execution, which requires one-time Guidepup macOS setup. The planner
must keep exact VoiceOver discovery and fail-closed target registration in the
phase, but must not invent transcripts when the OS setup is unavailable.
[VERIFIED: `80-VALIDATION.md`]

## State of the Art in This Repository

| Old approach on target pages | Current approved approach | Impact |
|------------------------------|---------------------------|--------|
| Page-local Tailwind-like class strings and badge switches | Token CSS plus shared taxonomy/components | Exact cross-page status and theme behavior. |
| Template receives domain structs/raw values | Closed presenter maps before page assigns | Confidentiality and deterministic stories. |
| Local tables/cards/dialogs | `DataDisplay` and `OperatorPatterns` | One semantic responsive tree and shared focus behavior. |
| Story-specific or no production seam | Public pure `page_content/1` used by production and Showcase | VRT/a11y exercises real composition. |
| Manual duplicated browser counts | Elixir catalog → schema-8 generated manifest → exact validators | One quality inventory and false-green resistance. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. Recommendations are derived from repository code, locked phase documents, and fresh local commands. | — | — |

## Open Questions — Resolved Inline

All planning questions are resolved; execution must use these decisions without
reopening scope:

1. **Exact finite query limits — resolved.**
   - Workflows uses scan/steps/results/evidence limits of **50/100/50/25** and
     therefore fetches **51/101/51/26** to prove completeness.
   - Batches uses members/callbacks/results/audit limits of **50/25/50/25** and
     therefore fetches **51/26/51/26**.
   - Lifeline uses incidents/executors/audit/archive limits of
     **50/25/50/25** and therefore fetches **51/26/51/26**.
   - Plans and tests must assert both repository-side limit-plus-one reads and
     rendered caps with explicit incomplete guidance.
2. **Wave 3 fixture generalization — resolved.**
   - Add a sibling, secret-gated Phase 81 fixture. It remains test-only,
     explicit-opt-in, POST-only, closed-schema, and independently credentialed;
     Phase 79/80 fixture ownership and route-off behavior remain unchanged.
3. **Shared component extension — resolved.**
   - Make no shared-component changes unless execution demonstrates a generic,
     tested gap that affects more than a Phase 81 page composition. Otherwise
     all Phase 81 additions stay in presenters and page composition and reuse
     the shipped APIs unchanged.
4. **VoiceOver execution — resolved.**
   - Exact manifest-derived discovery of the three Wave 3 targets is mandatory
     on every environment. Real transcript capture is conditional on a
     supported, configured macOS Guidepup/VoiceOver host; unsupported
     environments must record that limitation honestly and must never invent
     transcript evidence.

## Sources

### Primary (HIGH confidence)

- `.planning/phases/81-page-migration-wave-3-batches-workflows-lifeline/81-CONTEXT.md`
- `.planning/phases/81-page-migration-wave-3-batches-workflows-lifeline/81-UI-SPEC.md`
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`
- Phase 79 and 80 research, plans, patterns, summaries, validation, and
  verification artifacts
- Target LiveViews, `Batches`, `Lifeline`, `Audit`, `Selectors`,
  `ControlPlanePresenter`, `StatusTaxonomy`, and shared component source
- `PageStoryCatalog`, `ShowcaseLive`, schema-8 manifest, exact validators,
  Playwright specs, and package scripts
- Fresh focused test run and fresh catalog evaluation on 2026-07-29

### Secondary / Tertiary

None. No external documentation lookup was necessary because Phase 81 adds no
package or unfamiliar framework capability and is constrained to established
repository patterns.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — resolved from current dependency graph and lockfiles.
- Architecture: HIGH — dictated by locked context and two completed migration waves.
- Page findings: HIGH — derived from direct target source/test inspection.
- Validation: HIGH — extends an existing operational exact-count harness.
- Story count: MEDIUM — exact IDs/count are a concrete discretionary
  recommendation; the planner may change them only before baseline generation
  while retaining every required state.

**Research date:** 2026-07-29
**Valid until:** 2026-08-28, or until shared component/catalog contracts change.
