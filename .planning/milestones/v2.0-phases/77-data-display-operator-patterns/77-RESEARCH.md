# Phase 77: Data-Display & Operator Patterns - Research

**Researched:** 2026-07-12  
**Domain:** Phoenix function components, semantic operator data display, status presentation, redaction-safe rendering, and manifest-driven browser evidence  
**Confidence:** HIGH for repository architecture and locked Phase 77 behavior; MEDIUM-HIGH for the exact public component API, which remains planner discretion

## Research Question

What does the planner need to know to plan Phase 77 well?

## Executive Summary

Phase 77 should be planned as a component-foundation phase with three independently risky implementation seams:

1. A pure, domain-aware status taxonomy that feeds the existing `Primitives.status_pill/1` shape.
2. A semantic DataTable that sorts through parent-owned LiveView state and reflows one DOM tree into labelled cards at 320px.
3. A redaction-safe CodeBlock/ArgsViewer/RedactedValue path that consumes existing `DisplayPolicy` results without decoding, reinterpreting, or leaking hidden values.

The existing repository already supplies the correct lower layers: stateless Phoenix components, safe global-attribute filtering, native form controls, an isolated `.obpt-root` token layer, a deterministic asset build, separate dev/test story catalogs, generated browser targets, Docker-backed Playwright VRT, and axe. No dependency upgrade or client-side table package is needed. [VERIFIED: `lib/oban_powertools/web/components/primitives.ex`, `lib/oban_powertools/web/components/forms.ex`, `scripts/showcase_manifest.exs`, `playwright.config.ts`, `mix.exs`]

The strongest DataTable implementation is a single semantic `<table>` whose cells contain a mobile-only visible column label. At 320px, CSS converts rows and cells into cards while preserving the original `<table>/<thead>/<tbody>/<th>/<td>` structure and one set of row-selection inputs. Rendering a second mobile card tree would duplicate checkbox names, element ids, action controls, and potentially sensitive content. W3C guidance requires table relationships to remain available when responsive tables change format, and the Phase 77 UI contract requires visible mobile labels. [VERIFIED: `77-UI-SPEC.md`; [W3C table tips](https://www.w3.org/WAI/tutorials/tables/tips/)]

The taxonomy must take both `domain` and `state`; inferring from state alone is insufficient. `active`, `pending`, `expired`, and `blocked` have domain-specific meaning, aliases, labels, or tones. The UI-SPEC table is the minimum authoritative registry, but the codebase audit found additional currently displayed states that should be deliberately included, such as Lifeline health (`healthy`, `late`, `missing`), batch output availability (`output_unavailable`, `output_expired`), forensics completeness (`complete`, `partial_evidence`, `history_unavailable`), cron history (`missed_fire`, `overlap_relevant`, `unknown`), and host follow-up statuses. [VERIFIED: `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/batches.ex`, `lib/oban_powertools/forensics/cron_history.ex`, `lib/oban_powertools/web/control_plane_presenter.ex`, `lib/oban_powertools/host_escalation.ex`]

The redaction component must receive only normalized policy output, never both a raw secret and a display value. `DisplayPolicy.render_job_field/3` already returns `{:raw_json, json}`, `{:string, text}`, `{:fallback, "[redacted]"}`, or a recorded-output map; `workflow_result/2` returns a display map with `redacted?`. Phase 77 should render these shapes and leave policy interpretation in `DisplayPolicy`. [VERIFIED: `lib/oban_powertools/runtime_config.ex`]

Recommended plan split: RED contracts; taxonomy; DataTable/states/responsive CSS; secondary data components; args/redaction path; story/showcase/manifest schema 5; browser/VRT/axe closeout. DataTable and redaction should not share an implementation plan because both have substantial security/accessibility test matrices and the roadmap already marks them as split risks. [VERIFIED: `.planning/ROADMAP.md`]

## Binding Constraints

The planner must carry forward `77-CONTEXT.md` decisions D-01 through D-25 and the approved `77-UI-SPEC.md` without reopening them. The most consequential boundaries are:

- Add `ObanPowertools.Web.Components.DataDisplay` above `Primitives` and `Forms`; do not bloat either existing module.
- Keep production components stateless. Parent LiveViews own data retrieval, authorization, sort state, pagination, selection, URL state, events, and mutation flows.
- Do not migrate the nine production page bodies in this phase. Existing helpers such as `state_badge_tone/1`, `status_badge_class/1`, and `preview_badge_class/1` are migration inventory, not Phase 77 deletion targets.
- Use closed attrs/slots and token-backed classes. Caller `class` and `style` remain forbidden; no host selectors, raw component colors/spacing, or new runtime dependencies.
- Preserve semantic HTML: ordinary tables are tables, timelines are ordered lists, key/value groups are description lists, code is `<pre><code>`, and sortable headers are buttons within `<th scope="col">`.
- Render loading, empty, error, unavailable, and permission-denied states explicitly.
- Never place original sensitive values in DOM text, `title`, tooltips, `data-*`, copy buffers, expanded content, or pretty-printed JSON.
- Add exactly the ten locked `data-*` story targets, manifest schema 5, VRT, axe, and targeted behavior proof.

No root `CLAUDE.md`, `.claude/CLAUDE.md`, root `AGENTS.md`, `.claude/skills`, or `.agents/skills` directory applies to this phase. The only discovered `AGENTS.md` is below `examples/phoenix_host_upgrade_source/` and is outside the Phase 77 working scope. [VERIFIED: project file scan]

The worktree contains unrelated deleted planning files and untracked review/worktree artifacts. Plans and executors must preserve them and avoid broad cleanup. [VERIFIED: `git status --short`]

## Requirement-to-Architecture Map

| Requirement | Planning implication | Primary proof |
|---|---|---|
| DATA-01 | Implement DataTable, DescriptionList, taxonomy-backed StatusPill wrapper, Timeline, ProgressBar, MetricCard, CodeBlock, ArgsViewer, RedactedValue, EmptyState, and Toast/Flash as stateless function components. | Component render/source tests plus data stories |
| DATA-02 | Add a domain-aware pure taxonomy and render every known state in one generated audit story. Phase 77 creates the shared source; later page phases adopt it. | Pure exhaustive tests plus `data-status-taxonomy-all` |
| DATA-03 | Make table/card reflow, explicit states, and long-content handling first-class APIs, not story-only CSS. | 320px Playwright behavior, overflow assertions, component tests |
| DATA-04 | Normalize every policy display shape through ArgsViewer/CodeBlock/RedactedValue, with secret-sentinel negative assertions. | Unit/render security matrix plus browser DOM inspection |
| A11Y-02 | Use native controls and semantics, visible focus, text/icon status channels, labelled selection, and truthful `aria-sort`/progress/live-region behavior. | Targeted Playwright behavior plus axe |

## Existing Stack and Reusable Patterns

### Production component layer

`Primitives` establishes the exact implementation style to copy:

- `use Phoenix.Component`, documented `attr/3` and `slot/3`, closed atom values, explicit normalization, and HEEx escaping.
- `visual_safe_rest/2` converts keys to strings, removes `class` and `style`, and suppresses action attributes on non-interactive components.
- `status_pill/1` already accepts `%{label, tone, icon, sr_prefix}` and suppresses action attrs.
- `spinner/1` and `skeleton/1` already enforce named loading semantics.
- `stat/1` already provides label/value/trend semantics and tabular metric styling.

[VERIFIED: `lib/oban_powertools/web/components/primitives.ex`]

`Forms` establishes row-selection behavior and ARIA wiring:

- `checkbox/1` uses a native checkbox and emits a hidden unchecked input only for named boolean form fields.
- If `phx-click` is present and the caller did not explicitly provide a name, it treats the checkbox as event-driven selection and omits the hidden input/name.
- Global attrs have `class`, `style`, and invented popup ARIA stripped.

[VERIFIED: `lib/oban_powertools/web/components/forms.ex`]

The DataTable story should use `Forms.checkbox/1` for selection evidence rather than inventing another checkbox component.

### Phoenix table composition

Phoenix LiveView 1.1.31 is locked locally, and its `Phoenix.Component` supports repeated named slots with slot attributes and `render_slot(slot, row)`. The installed Phoenix generator uses the same `rows`, `row_id`, `:col`, and `render_slot(col, row)` pattern proposed for DataTable. [VERIFIED: `mix.lock`, `deps/phoenix_live_view/lib/phoenix_component.ex`, `deps/phoenix/installer/templates/phx_web/components/core_components.ex.eex`; [official Phoenix.Component docs](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)]

No LiveView/Phoenix upgrade is needed.

### CSS and assets

All component CSS belongs in `assets/oban_powertools/tokens.css` under `.obpt-root`. The checked-in package CSS is a normalized copy produced by:

```text
mix oban_powertools.assets.build
```

The build is intentionally simple and byte-stable. Plans that modify CSS must rebuild `priv/static/oban_powertools/oban_powertools.css` and run the existing byte-stability test. [VERIFIED: `lib/mix/tasks/oban_powertools.assets.build.ex`, `test/oban_powertools/web/assets_test.exs`]

### Story and browser layer

Primitive, form, and shell stories are separate test-support modules. Their ids generate story DOM ids, snapshot paths, and axe selectors. `scripts/showcase_manifest.exs` currently produces schema 4 and target order:

```text
scenarios ++ primitive_stories ++ form_stories ++ shell_stories
```

Phase 77 must append `data_stories`, bump the schema literal to 5 in both TypeScript and the smoke test, export `dataStories`, and teach `showcase.ts` structure assertions about `kind: "data"`. The generic VRT and axe files already iterate `targets`; they should not receive hardcoded data ids. [VERIFIED: `scripts/showcase_manifest.exs`, `test/browser/support/manifest.ts`, `test/browser/support/manifest-smoke.mjs`, `test/browser/support/showcase.ts`, `test/browser/specs/showcase.vrt.spec.ts`, `test/browser/specs/showcase.a11y.spec.ts`]

## Recommended Production Architecture

### Modules

Use two production modules:

```text
ObanPowertools.Web.StatusTaxonomy
ObanPowertools.Web.Components.DataDisplay
```

`StatusTaxonomy` should be pure and free of Phoenix rendering. `DataDisplay` should alias `Primitives`, `Forms` only where needed by internal examples, and `StatusTaxonomy`.

Do not add a generic presenter framework or macro DSL. The set is finite, domain-owned, and grep-friendly.

### Status taxonomy API

Recommended public shape:

```elixir
StatusTaxonomy.spec(domain, state)
# => %{label: "Retryable", tone: :warning, icon: :alert, sr_prefix: "Job state"}

StatusTaxonomy.all_specs()
# deterministic audit/story/test list
```

Recommended DataDisplay wrapper:

```heex
<DataDisplay.status_pill domain={:job} state={job.state} />
```

Key rules:

- `domain` should be a closed atom registry. Unknown domains should raise because no truthful nearest `sr_prefix` can be inferred.
- `state` may be atom or binary and should normalize to a string without `String.to_atom/1` or `String.to_existing_atom/1`.
- Unknown states within a known domain should return a neutral/dot/humanized spec with that domain's `sr_prefix`.
- Aliases belong in the registry: Lifeline preview `pending -> ready`, `executed -> consumed`; callback lease expiry should be an explicit derived presentation such as `lease_expired` rather than changing the stored callback status.
- `all_specs/0` must be deterministic and include domain/state metadata for tests and the audit story, while `spec/2` must return exactly the presentation map accepted by `Primitives.status_pill/1`.
- Pure tests are sufficient deterministic evidence for unknown states; avoid adding logging as a side effect to every render unless an existing logging requirement demands it.

Do not implement `spec(state)` without a domain. Several strings collide semantically:

- `active` means a Lifeline incident needs review, not generic running info.
- `expired` is danger for a terminal workflow/preview state, while `output_expired` is a warning about data availability.
- `pending` is neutral in callbacks/archives but a legacy alias to `ready` for repair previews.
- `blocked` is warning in an incident/archive workflow context but danger in the limiter/control-plane contract.

### Taxonomy inventory

The approved UI-SPEC mapping table is mandatory. Planning should also include a source audit task that reconciles these additional codebase states rather than silently falling through to unknown:

| Domain | Additional code-discovered values | Recommended treatment derived from the locked tone rules |
|---|---|---|
| Lifeline health | `healthy`, `late`, `missing` | success, warning, danger |
| Batch blocked/data output | `output_unavailable`, `output_expired` | warning; these are availability problems, not terminal object expiration |
| Cron slot/history | `claimed`, `skipped`, `queued_follow_up`, `cancelled`, `missed_fire`, `overlap_relevant`, `unknown` | info, warning, warning, danger, warning, neutral/info, neutral |
| Forensics completeness | `complete`, `partial_evidence`, `history_unavailable`, `unknown` | success, warning, warning, neutral |
| Continuity attempt | `previewed`, `attempted`, `succeeded`, `drifted`, `expired`, `consumed` | neutral/info, info, success, warning, danger, success |
| Host follow-up | `host_owned_follow_up_unconfigured`, `host_owned_follow_up_callback_invoked`, `host_owned_follow_up_callback_failed` | warning, success/info, danger |

The planner should pin final labels and tones in tests from the approved semantics; it should not treat existing Tailwind colors in page-local helpers as authoritative.

### DataTable API and DOM strategy

Use a required `state` with closed values:

```text
ready | loading | empty | error | unavailable | permission_denied
```

Recommended core attrs/slots:

- Required: `id`, `caption`, `rows`, `row_id`, `state`.
- Data metadata: `row_count`, `pagination_summary`, named loading/resource copy.
- Sorting: `sort_key`, `sort_direction`, `sort_event`; the parent receives the event and re-renders new sort state.
- Slots: optional `toolbar`, required repeated `col` with `label` and optional `sort_key`, optional `selection`, optional `action`, and an optional constrained state-detail slot.
- Safe `rest`: allow ids and supported `aria-*`/`data-*`; remove `class`, `style`, role overrides, and inline browser handlers.

Use Phoenix's established repeated slot pattern:

```heex
<DataDisplay.data_table ...>
  <:col :let={job} label="Job ID" sort_key="id">...</:col>
  <:col :let={job} label="Worker" sort_key="worker">...</:col>
</DataDisplay.data_table>
```

Render one table tree. Each cell should include the column label as a real mobile label next to the slot-rendered value. At the 24rem/320px breakpoint:

- reflow `<tbody>`, `<tr>`, and `<td>` visually into card rows;
- keep the sortable header buttons visible in a wrapping compact header strip;
- visually hide non-interactive header cells without removing structural relationships;
- display each cell's mobile label;
- preserve one selection checkbox and one action control per row;
- ensure ordinary values use `min-width: 0` and wrapping/truncation, with no page overflow.

This avoids two dangerous alternatives:

1. A separate desktop table and mobile card list duplicates ids, field names, events, and hidden sensitive content.
2. A generic horizontally scrolling table technically uses the WCAG data-table exception but violates the locked Phase 77 card-fallback contract and is poorer operator UX at 320px. W3C permits isolated table scrolling but recommends preserving reflow for surrounding and cell content; Phase 77 intentionally chooses the stronger stacked design. [[W3C Reflow understanding](https://www.w3.org/WAI/WCAG21/Understanding/reflow)]

Sortable headers must use a native button inside `<th scope="col">`. Apply `aria-sort="ascending"` or `"descending"` to only the active `<th>`; omit it elsewhere. WAI-ARIA says `aria-sort` belongs on a table/grid header and should appear on only one header at a time. [[WAI-ARIA 1.2](https://www.w3.org/TR/wai-aria/)]

The table state belongs inside the table/data region:

- loading: wrapper/table region `aria-busy="true"`, named status text, skeleton rows;
- empty: shared EmptyState with the locked fact-plus-next-action copy;
- error: recovery copy and `role="alert"` only when the failure is newly/immediately surfaced;
- unavailable and permission denied: dedicated state treatments, not EmptyState and not absent markup.

For the thousands-row story, render a bounded deterministic window (for example 20 rows), set `row_count` to a large total, and pin first/last visible keys. Do not mount thousands of rows in the showcase: every browser target loads the full showcase DOM, so a literal thousand-row story would slow all VRT/axe targets and contradict the no-virtualization/parent-pagination boundary.

### Long machine values

DATA-03 needs a shared solution, not per-story CSS. Add a narrow `machine_value/1` helper/component or make it an explicit DescriptionList value mode. Recommended behavior:

- server-side middle truncation for ids;
- preserve the trailing worker/module segment;
- provide the full non-sensitive value through native `<details>/<summary>` expansion or another explicit expansion affordance;
- never use `title` as the only full-value access path;
- never enable expansion for RedactedValue.

Native `<details>` avoids new JavaScript and clipboard handling. CodeBlock copy is optional in the UI-SPEC, so Phase 77 does not need to add a clipboard controller. This materially simplifies the D-19 proof that redacted content never enters a copy buffer.

### Secondary component semantics

| Component | Recommended implementation detail |
|---|---|
| DescriptionList / KeyValue | `<dl>` with repeated labelled items; support ordinary vs machine value modes; `min-width: 0`; no table semantics. |
| Timeline | `<ol>` with timestamp, title, actor/source, optional taxonomy pill, and optional detail slot/CodeBlock. |
| ProgressBar | Prefer native `<progress value max>` plus visible label/count/percent. This avoids forbidden inline width styles. Clamp values before rendering. For unavailable progress, omit `aria-valuenow` and render `Progress unavailable`. |
| MetricCard | One token-owned article/card wrapping `Primitives.stat/1`; do not nest cards or make it interactive without an explicit Link/Button. |
| CodeBlock | `<figure><figcaption>...<pre tabindex="0"><code>...`; HEEx-escaped text; bounded internal overflow; no raw HTML. |
| EmptyState | Heading, body, optional action slot rendered with an existing Button/Link; empty only, not loading/permission denied. |
| Toast/Flash | Closed tone plus explicit announcement urgency; polite status by default, assertive alert only for immediate failures; optional parent-owned dismiss event; no focus steal. |

Native `<progress>` carries range semantics without an inline `style="width: ..."`. WAI-ARIA requires known min/max/value data for determinate progress and says indeterminate progress should omit `aria-valuenow`. [[WAI-ARIA 1.2](https://www.w3.org/TR/wai-aria/)]

### ArgsViewer and redaction architecture

`DisplayPolicy` already has the correct policy boundary:

```text
{:raw_json, json}  -> labelled JSON CodeBlock
{:string, text}    -> labelled string/text CodeBlock
{:fallback, msg}   -> RedactedValue
job_recorded map   -> metadata plus payload or unavailable/redacted state
workflow result map -> summary/payload plus available?/redacted?/status
```

Plan ArgsViewer around these normalized display values. Do not pass an original/raw value alongside them, and do not call the host display policy from inside a Phoenix component. Parents/query presenters already call `DisplayPolicy`; keeping that call outside rendering makes the component deterministic and prevents duplicate policy invocation.

`RedactedValue` should have the narrowest API in the module:

- closed reasons such as `:enqueue`, `:policy`, and `:fallback`;
- exact visible copy `Redacted at enqueue` and `Hidden by display policy`;
- fallback payload `[redacted]` allowed only inside this component;
- no arbitrary inner slot, copy button, tooltip, `title`, or general `data-*` passthrough;
- optional stable id only if needed for association.

This is stricter than the other data components because accepting arbitrary global attributes would let a caller accidentally put a secret in `data-value` or `title`.

Important existing behavior to preserve:

- Enqueue-time redacted fields are removed before persistence and `DisplayPolicy` overlays marker strings while preserving non-redacted siblings.
- If a host policy returns a string or map, `DisplayPolicy` does not add the enqueue overlay again.
- Policy errors fall back to `{:fallback, "[redacted]"}`.
- Recorded output and workflow result displays use map shapes and explicit `redacted?`/`available?` values.

[VERIFIED: `lib/oban_powertools/worker/redaction.ex`, `lib/oban_powertools/runtime_config.ex`, `test/oban_powertools/web/live/jobs_live_test.exs`, `test/oban_powertools_test.exs`]

The security matrix must use a unique secret sentinel and assert it is absent from the full rendered HTML, including attributes. Positive assertions for `Redacted at enqueue`, `Hidden by display policy`, `[redacted]`, and non-redacted sibling values are not sufficient on their own.

## Showcase and Manifest Plan

Add `test/support/data_display_story_catalog.ex` with exactly these stable ids and order:

1. `data-table-sort-states`
2. `data-table-320-stacked`
3. `data-table-explicit-states`
4. `data-status-taxonomy-all`
5. `data-description-list-long-values`
6. `data-timeline-event-log`
7. `data-progress-metric-cards`
8. `data-code-args-redaction`
9. `data-empty-toast-flash`
10. `data-table-thousands-row-stress`

Each story should follow the existing catalog schema (`id`, `kind`, `component`, `components`, `name`, `description`, `variant`, `state`, `test_targets`) and use:

```text
kind: :data
story id: obpt-data-story-{id}
snapshot: showcase/{id}
a11y: [data-obpt-data-story="{id}"]
```

`DataDisplayStoryCatalog` may own deterministic component-specific fixtures; it must remain separate from the nine domain/persona scenarios. Reuse constants from `ShowcaseCatalog` only when doing so does not create support-module compile-order coupling. Plain maps and deterministic comprehensions are preferred; no Faker and no database inserts.

`ShowcaseLive` needs a new optional runtime-loaded catalog path/module, `@data_stories`, and real rendering in the existing `data-display` section. The sort story must be behaviorally real: add dev/test-only LiveView sort assigns and a narrow sort event handler so a browser click/Enter changes `aria-sort`. Production DataTable remains stateless; the showcase parent owns the state, exactly like a production parent would.

Manifest/schema work is broader than one generator edit. Plan all of these together:

- `scripts/showcase_manifest.exs`: schema 5, `data_stories`, appended data targets;
- `test/browser/support/manifest.ts`: `ShowcaseDataStory`, schema literal 5, collection validation, target union, `dataStories` export;
- `test/browser/support/manifest-smoke.mjs`: schema/count/order/selector validation and updated success output;
- `test/browser/support/showcase.ts`: structure assertions for `kind === "data"` and `data-obpt-data-story`;
- `test/browser/specs/showcase.structure.spec.ts`: update title copy if focused `--grep data` needs target-kind-inclusive titles, following Phase 76's shell lesson.

Ten stories across four themes and three viewports create exactly 120 new VRT PNG baselines. Plan a cardinality assertion for 120 files.

## Recommended Plan Decomposition

The planner can adjust numbering, but this dependency shape keeps risks bounded:

| Plan | Scope | Why separate |
|---|---|---|
| 77-01 | RED ExUnit contracts for taxonomy/components/catalog and RED Playwright behavior contract | Nyquist/Wave 0; pins API and security invariants before implementation |
| 77-02 | `StatusTaxonomy` and taxonomy-backed DataDisplay StatusPill | Pure, independently testable DATA-02 foundation |
| 77-03 | DataTable markup, explicit states, sorting contract, selection seam, responsive CSS | Highest semantic/responsive risk; roadmap split-risk |
| 77-04 | DescriptionList, Timeline, ProgressBar, MetricCard, machine value, EmptyState, Toast/Flash | Cohesive lower-risk presentation set |
| 77-05 | CodeBlock, ArgsViewer, RedactedValue and policy-shape security matrix | Highest confidentiality risk; roadmap split-risk |
| 77-06 | DataDisplayStoryCatalog, ShowcaseLive rendering/state, schema 5 manifest/browser support | Keeps dev/test registry and schema migration atomic |
| 77-07 | Targeted Playwright behavior, 120 Docker VRT baselines, focused axe/VRT, validation closeout | Expensive evidence only after stable rendering |

Plans 77-03 through 77-05 all touch `DataDisplay` and CSS, so they should normally be sequential even if their logical work is independent. Parallelizing them would create unnecessary edit conflicts. Taxonomy implementation can precede DataTable and be reused in its stories.

Do not create a plan that globally rejects all old status helpers. D-15 explicitly defers page migration. If a static drift guard is desired now, use one of these narrow forms:

- forbid new status maps/helpers in `DataDisplay`, story code, and newly added modules;
- record an allowlist of the known legacy page helpers for later migration;
- assert all new status stories use `StatusTaxonomy`.

## Validation Architecture

Nyquist validation is enabled. Phase 77 needs a Wave 0 contract layer before implementation and a layered evidence model; axe or screenshots alone cannot prove the critical behavior.

### Layer 1: Pure taxonomy tests

Create `test/oban_powertools/web/status_taxonomy_test.exs` before the taxonomy module lands.

Cover:

- every UI-SPEC domain/value mapping and exact four-key presentation shape;
- all supplemental code-discovered states selected by planning;
- atom and binary inputs producing the same spec;
- legacy preview aliases;
- exact `sr_prefix` per domain;
- unknown state fallback label/tone/icon with deterministic repeated results;
- unknown domain failure;
- deterministic, unique `all_specs/0` output;
- no dynamic atom creation in source.

Fast command:

```text
mix test test/oban_powertools/web/status_taxonomy_test.exs --seed 0
```

### Layer 2: Component render/source tests

Create `test/oban_powertools/web/components/data_display_test.exs` using the existing `Phoenix.LiveViewTest.__render_component__/4` pattern.

Required render assertions:

- DataTable native elements, caption, `scope="col"`, body rows, row ids, total/pagination summary, toolbar, action and selection seams;
- sorted header button and one truthful `aria-sort`;
- explicit state markup/copy for all six states and `aria-busy` for loading;
- visible mobile label text present in each cell's DOM;
- DescriptionList `<dl>/<dt>/<dd>`, Timeline `<ol>`, CodeBlock `<pre><code>`, native progress, metric semantics, toast live roles, dismiss accessible name;
- caller `class`, `style`, `role`, `title`, and unsafe action attrs removed where prohibited;
- hostile strings escaped.

Required source assertions:

- `use Phoenix.Component`, attrs/slots, `visual_safe_rest` equivalent;
- no raw hex, raw `px` component literals, host selectors, raw HTML APIs, JS table library hooks, `String.to_atom`, or inline width styles;
- no global role override and no ARIA grid role.

Fast command:

```text
mix test test/oban_powertools/web/components/data_display_test.exs --seed 0
```

### Layer 3: Redaction security matrix

Use component tests plus existing DisplayPolicy fixtures/modules to exercise:

- `{:raw_json, json}`;
- `{:string, text}`;
- `{:fallback, "[redacted]"}`;
- enqueue overlay with non-redacted siblings;
- host-returned map and string passthrough;
- invalid/raising policy fallback;
- recorded output available/unavailable/redacted maps;
- workflow result available/unavailable/redacted maps;
- nested maps/arrays, HTML-looking strings, Unicode, emoji, RTL, long URLs, and stacktraces.

For each redacted case, assert the unique original secret sentinel is absent from the entire rendered HTML and from all `title`, tooltip, `data-*`, details/expanded, and copy-related markup. Assert the non-redacted sibling remains visible. This layer directly gates DATA-04.

### Layer 4: CSS and packaged asset tests

Extend `test/oban_powertools/web/theme_tokens_test.exs` with a data-component class family and property allowlist patterned after primitive/shell checks. Extend `test/oban_powertools/web/assets_test.exs` with representative compiled selectors.

Verify:

- every selector begins below `.obpt-root`;
- visual declarations use `var(--obpt-*)` except the existing small literal allowlist;
- 24rem stacked-table rules, mobile labels, sort focus, 44px-equivalent token calculations, bounded code overflow, status/toast tones, and reduced-motion rules exist;
- source and checked-in CSS match after `mix oban_powertools.assets.build`;
- repeated asset builds are byte-stable.

Commands:

```text
mix oban_powertools.assets.build
mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs --seed 0
```

### Layer 5: Catalog, showcase, and manifest contracts

Add:

- `test/oban_powertools/data_display_story_catalog_test.exs` for exact ten-id order, metadata, deterministic fixtures, target derivation, row-window bounds, and all taxonomy states;
- showcase LiveView assertions that the `data-display` placeholder is gone, every story renders once, hooks/ids are stable, redaction copy is present, and the secret sentinel is absent;
- manifest smoke checks for schema 5, exactly ten data stories, target append order, and generated selectors.

Commands:

```text
mix test test/oban_powertools/data_display_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0
npm run showcase:manifest
node test/browser/support/manifest-smoke.mjs
npx playwright test --list test/browser/specs/data-display.behavior.spec.ts
```

### Layer 6: Targeted browser behavior

Create `test/browser/specs/data-display.behavior.spec.ts`, importing `dataStories` from the generated manifest. Do not hardcode the complete story list in TypeScript; named lookup helpers for individual required ids are consistent with prior behavior specs.

Browser checks must prove:

- click and Enter/Space on a sort button update parent-owned state and `aria-sort`;
- only one sorted header exists;
- keyboard-visible focus in all four themes;
- 320 rows are visually stacked, mobile labels are visible, and document/body/story overflow is <= 1px;
- row-selection checkbox accessible names and 44px effective hit area;
- long ids/modules retain useful beginning/end or expose native expansion;
- CodeBlock has bounded internal overflow, is focusable, and can scroll without page overflow;
- redaction copy is visible and the secret sentinel is absent from `textContent`, `title`, `data-*`, and details content;
- toast roles/live regions match urgency and dismiss controls do not steal focus;
- progress values are clamped and unavailable progress omits fake value semantics;
- the thousands-row story reports the large total while DOM row count remains bounded and keys stable.

Run behavior at minimum on `chromium-320` and `chromium-wide`; run theme-loop focus checks across all themes.

### Layer 7: VRT and axe

The generic manifest loops will add 120 VRT and 120 axe cases. Update and compare VRT with the canonical Docker runner because Phase 76 proved host macOS rendering differs from Docker-written baselines.

Use focused data commands during implementation and record exact commands/results in `77-VALIDATION.md`. A representative pattern is:

```text
npm run showcase:manifest
scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.vrt.spec.ts --grep "data data-" --update-snapshots=changed
scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.vrt.spec.ts --grep "data data-"
scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/showcase.a11y.spec.ts --grep "data data-"
```

The exact grep should be validated with `--list`; Phase 76 needed target-kind-inclusive test titles for focused selection.

The repository currently documents 108 unrelated scenario-only VRT baseline failures in the broad aggregate gate. Phase 77 must not refresh those scenario baselines. Record them as an existing residual, prove all focused data targets green, and avoid claiming the unrelated aggregate is green. [VERIFIED: `.planning/STATE.md`, `.planning/phases/76-navigation-app-shell/76-VALIDATION.md`]

### Final phase gate

At closeout, run:

```text
mix format --check-formatted
mix compile --warnings-as-errors
mix test <all Phase 77 focused ExUnit files> --seed 0
npm run showcase:manifest
node test/browser/support/manifest-smoke.mjs
npx playwright test --list test/browser/specs/data-display.behavior.spec.ts
<server-backed focused behavior, axe, and canonical Docker VRT commands>
<120-baseline cardinality check>
```

Do not mark the phase complete based only on test discovery or baseline existence. Record executed server-backed behavior, axe, and Docker VRT compare evidence.

## Planning Pitfalls

1. **Duplicating mobile markup.** Two responsive DOM trees create duplicate ids, checkboxes, events, and hidden content. Reflow one table tree.
2. **Inferring taxonomy from state alone.** Domain collisions make this incorrect; require a closed domain.
3. **Treating the UI-SPEC list as the entire code audit.** It is the mandatory minimum, but several currently displayed Powertools states live outside that table and need deliberate inclusion or documented exclusion.
4. **Converting unknown strings to atoms.** Never use `String.to_atom/1`; string-keyed registries avoid atom growth and accept host/DB state safely.
5. **Calling DisplayPolicy inside components.** That mixes host callbacks into rendering and risks multiple calls. Render normalized results only.
6. **Passing raw and redacted values together.** A component cannot leak a secret it never receives.
7. **Allowing general rest attrs on RedactedValue.** `data-*` and `title` are explicit leak channels; keep the API closed.
8. **Using inline `style` for progress width.** Native `<progress>` satisfies the visual/semantic need and preserves the no-inline-style contract.
9. **Rendering literal thousands of rows.** The showcase loads every story for every target; use a bounded window plus truthful total count.
10. **Migrating production pages now.** That expands the phase into Phases 79-81 and conflicts with D-15.
11. **Globally forbidding existing local badge helpers.** They are known migration debt; guard only new code in this phase.
12. **Updating all VRT baselines.** Only data baselines belong to Phase 77; use Docker and focused target selection.
13. **Using axe as behavior proof.** Axe cannot prove sorting state changes, visible focus geometry, hit target size, bounded overflow, or secret absence.

## Primary Files the Plans Will Touch

### New

- `lib/oban_powertools/web/status_taxonomy.ex`
- `lib/oban_powertools/web/components/data_display.ex`
- `test/oban_powertools/web/status_taxonomy_test.exs`
- `test/oban_powertools/web/components/data_display_test.exs`
- `test/support/data_display_story_catalog.ex`
- `test/oban_powertools/data_display_story_catalog_test.exs`
- `test/browser/specs/data-display.behavior.spec.ts`
- 120 PNG files below `test/browser/__screenshots__/chromium-*/showcase/data-*`

### Modified

- `assets/oban_powertools/tokens.css`
- `priv/static/oban_powertools/oban_powertools.css`
- `lib/oban_powertools/web/dev/showcase_live.ex`
- `scripts/showcase_manifest.exs`
- `test/browser/support/manifest.ts`
- `test/browser/support/manifest-smoke.mjs`
- `test/browser/support/showcase.ts`
- `test/oban_powertools/web/live/showcase_live_test.exs`
- `test/oban_powertools/web/theme_tokens_test.exs`
- `test/oban_powertools/web/assets_test.exs`

No `mix.exs`, `mix.lock`, `package.json`, or `package-lock.json` change should be necessary.

## Sources

### Binding project sources

- `.planning/phases/77-data-display-operator-patterns/77-CONTEXT.md`
- `.planning/phases/77-data-display-operator-patterns/77-UI-SPEC.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/phases/74-primitives-library/74-CONTEXT.md`
- `.planning/phases/75-form-components/75-CONTEXT.md`
- `.planning/phases/76-navigation-app-shell/76-VALIDATION.md`
- `guides/brand-book.md`
- `guides/visual-regression-and-a11y.md`

### Code and test sources

- `lib/oban_powertools/web/components/primitives.ex`
- `lib/oban_powertools/web/components/forms.ex`
- `lib/oban_powertools/runtime_config.ex`
- `lib/oban_powertools/worker/redaction.ex`
- `lib/oban_powertools/jobs.ex`
- `lib/oban_powertools/batches.ex`
- `lib/oban_powertools/workflow/runtime.ex`
- `lib/oban_powertools/control_plane.ex`
- `lib/oban_powertools/lifeline.ex`
- `lib/oban_powertools/lifeline/repair_preview.ex`
- `lib/oban_powertools/forensics/cron_history.ex`
- `lib/oban_powertools/web/control_plane_presenter.ex`
- `test/support/showcase_catalog.ex`
- `test/support/primitive_story_catalog.ex`
- `test/support/form_story_catalog.ex`
- `test/support/shell_story_catalog.ex`
- `scripts/showcase_manifest.exs`
- `test/browser/support/manifest.ts`
- `test/browser/specs/primitives.behavior.spec.ts`
- `test/browser/specs/forms.behavior.spec.ts`
- `test/browser/specs/shell.behavior.spec.ts`
- `assets/oban_powertools/tokens.css`

### Primary external references

- [Phoenix.Component slots and `render_slot/2`](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)
- [W3C Tables Tutorial](https://www.w3.org/WAI/tutorials/tables/)
- [W3C responsive table tips](https://www.w3.org/WAI/tutorials/tables/tips/)
- [W3C Understanding Reflow](https://www.w3.org/WAI/WCAG21/Understanding/reflow)
- [WAI-ARIA 1.2: `aria-sort` and progressbar states](https://www.w3.org/TR/wai-aria/)
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)

---

*Research complete: 2026-07-12*
