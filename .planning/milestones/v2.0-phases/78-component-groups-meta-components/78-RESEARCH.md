# Phase 78: Component Groups (Meta-Components) - Research

**Researched:** 2026-07-18
**Domain:** Phoenix function-component composition, modal and adaptive detail behavior, operator confirmation/filter/explanation patterns, and manifest-driven browser evidence
**Confidence:** HIGH for repository architecture, locked behavior, and validation seams; MEDIUM-HIGH for the exact attr/map names, which remain planner discretion

## Research Question

What does the planner need to know to plan Phase 78 well?

## Executive Summary

Phase 78 should be planned as a stateless presentation layer with three behaviorally risky seams, not as six unrelated markup components:

1. **Authoritative confirmation flow:** `confirm_action_dialog/1` renders a parent-owned preview/reason/count/result state machine, but authorization, preview freshness, membership, validation, execution, and audit durability remain server-owned. The existing Lifeline preview path already proves expiry, drift, single use, an eight-character trimmed reason, and transactional audit behavior; Phase 78 must compose that truth without exposing tokens, plan hashes, raw errors, or backend structs.
2. **Adaptive detail modality:** `detail_surface/1` must keep one native `<dialog>` tree while switching between nonmodal `show()` on wide layouts and modal `showModal()` on constrained layouts. The packaged Powertools JavaScript is a standalone asset and does not register custom hooks with a host application's `LiveSocket`, so the robust library boundary is a scoped, idempotent data-attribute controller in `theme.js`, plus LiveView's built-in `JS.ignore_attributes("open")` where useful. Do not require hosts to merge a custom hook map.
3. **Live interaction evidence:** component render tests cannot prove focus trapping/restoration, Escape, native inertness, resize mode changes, URL history, duplicate-submit suppression, or live-region behavior. The dev-only `ShowcaseLive` must act as the parent/harness for those transitions, and targeted Playwright tests must exercise them on a connected socket.

The repository already supplies the correct lower layers: `Primitives`, `Forms`, `DataDisplay`, `StatusTaxonomy`, the scoped token stylesheet and packaged JS, `Phoenix.Component.focus_wrap`, LiveView focus/navigation JS, deterministic test-support catalogs, a generated manifest, axe, and Docker-backed VRT. No dependency change is needed.

The production component boundary should be one new module:

```text
ObanPowertools.Web.Components.OperatorPatterns
```

It should export exactly the six locked function components:

```text
confirm_action_dialog/1
filter_bar/1
detail_surface/1
attention_card/1
audit_entry/1
why_blocked/1
```

Pure normalization/copy helpers may extend `ControlPlanePresenter` or live in one narrowly named pure companion, but components must consume presentation maps and complete grammatical copy rather than inspect Ecto schemas, action atoms, metadata, or exceptions.

The 23 locked group stories create **276 new VRT baselines**: 23 stories x 4 themes x 3 viewports. Manifest schema 5 should bump exactly once to schema 6 and append `group_stories` after `data_stories`. Overlay stories require an activation protocol so each browser case opens only its own confirmation or modal drawer; opening every modal story when the full showcase mounts would stack top-layer dialogs, inert unrelated stories, and invalidate axe/VRT evidence.

Recommended implementation order: Wave 0 RED contracts; shared normalizers and non-overlay explanation/audit groups; FilterBar; ConfirmActionDialog plus connected validation harness; adaptive DetailSurface plus packaged client controller; story/showcase/schema-6 integration; then browser/VRT/axe closeout. Confirmation and DetailSurface should remain separate implementation plans because their focus and state risks are independent and both touch client behavior.

## Binding Constraints

Planning must carry forward `78-CONTEXT.md` decisions D-01 through D-61. The highest-leverage constraints are:

- Components are stateless Phoenix function components. Parent LiveViews own data, authorization, open state, draft/applied state, URL grammar, navigation, preview creation, execution, redaction, result normalization, and durable audit writes.
- Compose Phase 74-77 components. Do not restyle raw buttons, fields, pills, tables, progress, alerts, or evidence viewers inside every group.
- Keep closed attrs/slots and token-backed styles. No caller `class`, `style`, arbitrary visual globals, raw color/size escape hatch, or raw HTML.
- Repeated filters, blockers, and result rows use narrow presentation maps. Never accept arbitrary backend structs.
- The information order is current state -> plain-language explanation -> impact/scope -> next safe action -> evidence freshness/completeness -> technical evidence/history.
- Never infer safety, freshness, causality, current truth, success, or audit durability. Unknown stays unknown.
- Do not migrate production pages in Phase 78. Phases 79-81 adopt the groups.
- Do not add a bulk executor, saved filters, a filter DSL, audit schema fields, causal inference, full-detail routes, or new operator capabilities.
- Stories and test fixtures stay dev/test-only and fail closed when excluded from the Hex package.

No root `CLAUDE.md`, `.claude/CLAUDE.md`, root `AGENTS.md`, or project-local skill directory applies. The only discovered `AGENTS.md` is below `examples/phoenix_host_upgrade_source/`, outside this phase's scope.

The worktree has unrelated deleted old planning files and untracked review/worktree artifacts. Executors must preserve them and avoid broad cleanup.

`STATE.md` contains stale/contradictory bookkeeping (`status: verifying` and “Phase complete” while also saying `Plan: Not started` and `stopped_at: Phase 78 context gathered`). The actual source of truth is the Phase 78 directory plus ROADMAP: context exists, but no Phase 78 plans or implementation exist.

## Requirement-to-Architecture Map

| Requirement | Planning implication | Primary proof |
|---|---|---|
| GROUP-01 | Ship all six documented functions in `OperatorPatterns`, composed from existing primitives/forms/data displays with explicit state contracts. | Component render/source tests plus 23 real stories |
| GROUP-02 | Pin one shared information hierarchy and parent contract; prove narrow/wide cohesion and the `Attention -> Why blocked -> action -> confirm -> result -> Audit` chain. | Component tests, connected showcase harness, 320/wide behavior, VRT |
| FORM-04 | Confirmation always contains consequence/scope/reversibility and a required reason; bulk adds exact frozen-count confirmation; parent/server revalidates. | Render contracts, changeset/LiveView tests, stale/replay integration tests |
| COPY-02 | Require complete action-specific copy and recovery guidance; forbid generic confirm/cancel/error claims and raw error inspection. | Presenter/component tests and exact story copy assertions |
| A11Y-02 | Confirmation traps/restores focus and closes on Escape when dismissible; drawer is modal only when constrained; filter disclosure and all actions are keyboard-operable and non-color. | Connected Playwright behavior plus axe and focus assertions |

## Existing Stack and Reuse Patterns

### Component APIs

`Primitives` already provides closed, stateless, token-owned `button`, `icon_button`, `link`, `status_pill`, `surface`, `card`, `divider`, `spinner`, `skeleton`, and `stat` components. Its `visual_safe_rest` pattern strips `class`/`style`, and descriptive primitives suppress action attrs. Reuse it rather than adding raw controls.

`Forms` is field-first and parent-owned. It accepts `Phoenix.HTML.FormField`, provides labels/hints/errors/required state, and strips visual/popup semantic overrides. `confirm_action_dialog/1` should accept a parent-created `Phoenix.HTML.Form` and render `Forms.textarea`/`Forms.input` fields; `filter_bar/1` should accept the Phase 75 form and field slots.

`DataDisplay` supplies `status_pill`, `data_table`, `description_list`, `timeline`, `progress_bar`, `code_block`, `args_viewer`, `empty_state`, `toast`, and `flash_group`. Useful direct compositions are:

- deterministic result rows through `DataDisplay.data_table` or a semantic list plus `DataDisplay.status_pill`;
- audit facts through `DataDisplay.description_list`;
- evidence through `DataDisplay.code_block`/`args_viewer`, never raw `<pre>` payloads;
- exact success receipts through existing Toast/Flash rather than a second notification system.

`StatusTaxonomy` has no generic operator-result domain. If result rows need shared pills for `success | failed | skipped`, extend it with one closed domain rather than borrowing workflow semantics or creating local color mappings. Keep the registry string-keyed and atom-safe.

### Phoenix/LiveView behavior available in the pinned stack

The repository pins Phoenix LiveView 1.1.31. Local dependency source confirms:

- `Phoenix.Component.focus_wrap/1` renders the built-in `Phoenix.FocusWrap` hook and wrap sentinels;
- `Phoenix.LiveView.JS.focus/2`, `focus_first/2`, `push_focus/2`, and `pop_focus/1` are available;
- `JS.ignore_attributes/2` is explicitly documented for native dialog `open` state across LiveView patches;
- `push_patch/2` invokes `handle_params/3`, preserves scroll position, and supports `replace: true`.

Use `focus_wrap` for ConfirmActionDialog as locked in D-20. Do not wrap adaptive DetailSurface unconditionally: wide inline mode must allow focus to leave the panel.

The WAI-ARIA modal dialog pattern requires focus to enter the dialog, Tab/Shift-Tab containment, Escape close, a visible close control, an accessible label, and focus return to the invoker or a logical successor. It also recommends focusing a static `tabindex="-1"` title/intro for structured or destructive content rather than the dangerous button. This matches D-20/D-21. See [WAI-ARIA APG Modal Dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/).

Native `HTMLDialogElement.showModal()` supplies top-layer modality and makes the rest of the document inert; `show()` is modeless. Switching an already-open dialog between them must close and reopen it safely, preserving an internal focus target when possible. See [MDN HTMLDialogElement](https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement).

### Packaged JavaScript boundary

`assets/oban_powertools/theme.js` is an immediately invoked standalone controller loaded inside `.obpt-root`. It uses delegated document events and fixed `data-obpt-*` selectors. The example host creates `LiveSocket` without a Powertools hook map. Therefore:

- do not add `phx-hook="OperatorDetail"` that requires host registration;
- add fixed selectors such as `[data-obpt-detail-surface]`, `[data-obpt-filter-toggle]`, and `[data-obpt-detail-close]` to the packaged controller;
- scope every lookup through the nearest `.obpt-root`;
- use idempotent `sync...` functions plus a narrowly filtered `MutationObserver` for inserted/patched surfaces;
- keep client state presentational only; no IDs, reason text, filter values, preview tokens, or result payloads in logging/storage;
- rebuild `priv/static/oban_powertools/oban_powertools.js` and prove byte equality/idempotence.

### Server truth seams

`Lifeline.preview_repair/4`, `Lifeline.execute_repair/5`, and `RepairPreview` already encode the authoritative confirmation boundary:

- statuses `ready`, `drifted`, `expired`, `consumed`;
- execution rejects consumed, drifted, or expired previews;
- execution rechecks drift and requires a trimmed reason of at least eight characters;
- successful execution consumes the preview and records audit evidence transactionally.

Phase 78 must not recreate that engine. The showcase/harness can model states deterministically, while focused integration tests should reuse existing Lifeline APIs to prove stale/replay rejection.

`Audit` provides actor, action/event type, command key, resource identity, metadata, immutable insertion time, reason, and principal helpers. It does not provide a universal outcome column. `audit_entry/1` must accept an already-normalized presentation entry and show missing reason/outcome explicitly rather than infer success from action names or metadata proximity.

`Explain` separates `live_now` blockers from `snapshot_at_block_start`. `why_blocked/1` must preserve that distinction and never relabel historical snapshots as current truth.

## Recommended Production Architecture

### Module boundary

Add:

```text
lib/oban_powertools/web/components/operator_patterns.ex
```

Prefer one helper seam:

- extend `lib/oban_powertools/web/control_plane_presenter.ex` for canonical labels/sentences and Audit/Explain conversion; or
- add one pure narrowly named presenter/normalizer if keeping `ControlPlanePresenter` cohesive becomes impractical.

Do not create a new design-system hierarchy, stateful LiveComponents, or generic schema-driven rendering DSL.

### Presentation-map rules

Implement finite key fetchers with compile-time atom/string aliases, required text validation, closed enum normalization, deterministic ordering, and explicit unknown fallbacks. Unknown keys should never become DOM attributes. Never call `String.to_atom/1`, render `inspect(error)`, or store the raw input map in `data-*`.

Recommended normalized shapes:

| Data | Required presentation keys | Optional keys |
|---|---|---|
| active filter | stable `id`, grammatical `label`, display `value`, canonical removal destination | accessible remove label |
| result row | stable `id`, object label, `outcome: success | failed | skipped`, specific message | recovery guidance, audit destination |
| blocker | stable `id`, label, summary, clearing condition, evidence source | technical code, redaction-safe detail |
| audit entry | sentence, outcome copy, actor, action, target, reason copy, source, absolute display time, ISO datetime | correlation, redaction-safe change/evidence |

### `confirm_action_dialog/1`

Recommended closed component state:

```text
preview | submitting | partial | failed | expired | drifted | consumed
```

A clean authoritative success normally removes the dialog and lets the parent emit exactly one Toast/Flash receipt. Partial/failed/skipped/stale terminal states remain open.

The API should require:

- `id`, `intent: warning | danger`, lifecycle state;
- complete title/object/scope/consequence/reversibility/support-boundary copy;
- parent `Phoenix.HTML.Form`, action-specific confirm label, safe retained-state dismiss label;
- submit/cancel events or constrained LiveView JS commands;
- logical fallback id;
- optional frozen bulk count, pending copy, result map/rows, support/evidence and audit/recovery slots.

Key implementation rules:

- wrap the dialog in `focus_wrap`, render `role="dialog"`, `aria-modal="true"`, and `aria-labelledby`;
- focus a static title/consequence node with `tabindex="-1"` on mount, not the danger button;
- render the reason through `Forms.textarea` with required state and secret-warning hint;
- if bulk count exists, render a second required exact-count field and explicit out-of-view scope copy;
- in preview state, confirmation enablement is parent-owned form validity, but HTML required fields are still present;
- in submitting state, set `aria-busy`, use `phx-disable-with`, disable repeat inputs/actions, name the work, and state when it can no longer be canceled;
- partial rows keep `success`, `failed`, and `skipped` distinct and deterministic; the result heading receives focus with `tabindex="-1"`;
- expired/drifted/consumed states offer an explicit fresh-preview action and may preserve reason only through parent-owned safe state;
- never use click-away dismissal for a destructive confirmation;
- cancel/Escape should pop focus. A small fallback restoration controller may focus the required logical fallback only when the pushed invoker no longer exists.

The component cannot enforce server authority by itself. The connected harness and actual execution tests must revalidate trimmed reason, exact count, authorization/freshness, and single use.

### `filter_bar/1`

Recommended attrs/slots:

- required `id`, parent form, result summary, results target id;
- closed `mode: submit | instant` (default `submit`);
- parent-owned draft dirty state and exact active-filter maps;
- submit/change events, canonical clear/removal destinations;
- primary fields and advanced fields slots.

Render one top-of-results form. In submit mode, `phx-change` may validate but must not alter results or URL; only Apply does. In instant mode, do not render a misleading Apply action. Keep active filters, exact result summary, individual removal, and Clear filters outside the narrow disclosure.

Use a real disclosure button with `aria-expanded` and `aria-controls`, one DOM tree, and packaged scoped behavior. The WAI-ARIA disclosure pattern requires a button and synchronized expanded state; see [APG Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/). Do not use StatusPill as an interactive chip.

The component must not serialize routes or query grammar. `ShowcaseLive`/consumer parents own canonical URL params, `handle_params/3`, pagination reset, and `push_patch` history.

### `detail_surface/1`

Recommended attrs/slots:

- required `id`, `title`, resource-specific close label, open boolean/state, logical fallback id;
- closed `variant: adaptive | inline | drawer` and explicit content state (`loading | empty | ready | unavailable | permission_denied | error`);
- close event/JS and optional full-details destination;
- one body slot plus constrained action/evidence slots.

Render exactly one `<dialog>` tree. The client controller determines effective mode:

- `inline`: call `show()`, no `aria-modal`, no trap or background inertness;
- `drawer`: call `showModal()`, modal semantics and native inertness;
- `adaptive`: wide uses inline, constrained uses modal drawer, and 320px CSS becomes full-screen.

When mode changes, close before reopening, preserve a focused descendant when safe, and resynchronize mode/ARIA after LiveView patches. Record the invoker when opening; on close, restore it if connected, otherwise focus the required fallback id. Escape/cancel must route through the visible close action so parent URL state also closes.

Parent examples/tests must put `aria-expanded` and `aria-controls` on the selected trigger and use push-on-first-open, replace-on-selection-switch, replace-on-explicit-close semantics. Direct links need a fallback because no invoker exists.

Never nest ConfirmActionDialog inside a modal drawer. The parent must close/leave the drawer first or navigate to full details.

### `attention_card/1`

Require human title, summary, impact/scope, observed-at time, explicit evidence completeness, separate domain status and severity/priority, and one primary action slot. Default to no live role. Only an explicitly dynamic update chooses polite status or urgent alert semantics.

Use neutral card chrome with restrained `data-obpt-severity`; pair severity with icon/text and never color alone. Do not make it dismissible or nest cards.

### `why_blocked/1`

Accept all caller-supplied normalized blocker maps and preserve their order. Render direct answer, blockers and clearing conditions, impact, legal next action, freshness/completeness, then technical evidence. Current and block-start snapshot labels must remain distinct.

Do not say “root cause” without proven causality. Do not render “No blockers” from empty, stale, partial, unavailable, or permission-denied evidence. Permission-disabled actions remain visible with the reason through existing button semantics.

### `audit_entry/1`

Render one `<article>` intended for a timeline/list item. Use a complete event sentence as heading, an absolute `<time datetime="...">`, and a description list for actor/action/target/reason/source/correlation/outcome. Compose status/evidence through existing DataDisplay components.

Missing fields are explicit: “No operator reason recorded” and “Outcome not recorded.” A later outcome remains a later entry. Never mutate historical copy into current status or treat an audit record as causal proof.

## Showcase and Manifest Architecture

Add a dev/test-only `ObanPowertools.OperatorPatternStoryCatalog` with the exact 23 IDs and order from D-58 through D-60. Its fixtures must contain normalized presentation data only, deterministic absolute timestamps, stable long/Unicode content, and no original secrets.

Extend `ShowcaseLive` with an optional, list-validated group catalog loaded through the same fail-closed support-module pattern as Phase 77. Keep it excluded from the Hex package and add isolated package-boundary coverage for absent/non-list stories.

Manifest schema 6 should add:

```text
group_stories
kind: "group"
activation: "none" | "overlay"
```

Append group targets after data targets. Keep IDs, snapshots, selectors, and activation metadata Elixir-owned and validated independently in TypeScript/smoke tests.

Overlay preparation is essential:

1. Mount the showcase and wait for `.phx-connected`.
2. For a group target with `activation: overlay`, activate only that story through a deterministic parent-owned event/query.
3. Assert only one modal/confirmation is open.
4. Snapshot/axe the activated story stage.
5. Every Playwright test gets a fresh page, so no overlay state leaks between targets.

Do not render all confirmation stories as fixed open overlays on initial mount and do not call `showModal()` on multiple detail stories.

Baseline cardinality is exactly:

```text
23 stories x 4 themes x 3 viewports = 276 PNGs
```

Add an independent `verify-group-baselines.mjs` equivalent rather than trusting manifest generation alone.

## Recommended Plan Decomposition

| Plan | Scope | Why separate |
|---|---|---|
| 78-01 | Wave 0 RED component/presenter/catalog contracts and guarded browser behavior file | Pins public surface, security, and behavior before implementation |
| 78-02 | Pure presentation normalizers plus AttentionCard, WhyBlocked, AuditEntry and component/CSS tests | Nonmodal explain/history foundation; shared evidence vocabulary |
| 78-03 | FilterBar, disclosure client behavior, and parent-owned draft/applied harness | URL/draft truth is a distinct state machine |
| 78-04 | ConfirmActionDialog markup, form/result states, focus JS, and connected reason/count/stale/replay tests | Highest mutation/copy/focus risk |
| 78-05 | DetailSurface, native-dialog controller, responsive CSS, URL/focus harness | Highest client/modal/history risk |
| 78-06 | Group catalog, ShowcaseLive rendering/activation, schema-6 manifest/browser support, package fallback | Keeps dev/test and generated-target boundaries atomic |
| 78-07 | Targeted connected Playwright behavior across groups | Proves transitions static tests cannot |
| 78-08 | Focused axe, 276 Docker VRT baselines, exact scope/cardinality, and validation closeout | Expensive evidence after rendering stabilizes |

Plans 78-02 through 78-05 all touch `operator_patterns.ex` and CSS, so execute them sequentially to avoid conflicts. JavaScript changes in FilterBar and DetailSurface should also be sequential and rebuilt after each relevant plan. The planner may combine 78-07/08 if task size permits, but should not combine ConfirmActionDialog and DetailSurface implementation.

## Validation Architecture

Nyquist validation is applicable. Phase 78 needs meaningful Wave 0 tests before implementation and layered evidence; axe/screenshots alone cannot prove the critical contracts.

### Wave 0 gap table

| Behavior gap | Test file to create/extend first | Expected RED seam |
|---|---|---|
| Six public functions, closed attrs/maps, copy order, safe attrs | `test/oban_powertools/web/components/operator_patterns_test.exs` | Missing module/functions |
| Presenter normalization, missing/unknown truth, audit time/copy | `test/oban_powertools/web/operator_pattern_presenter_test.exs` or presenter test | Missing normalizers |
| Required reason/count, stale/replay, partial ordering, draft/applied, URL/detail harness | `test/oban_powertools/web/live/operator_patterns_harness_test.exs` or focused ShowcaseLive tests | Missing parent events/state |
| Exact 23-story order/fixtures/targets | `test/oban_powertools/operator_pattern_story_catalog_test.exs` | Missing catalog |
| Focus, Escape, inertness, resize, restore, announcements, URL history | `test/browser/specs/operator-patterns.behavior.spec.ts` with schema-6 guard | Missing `groupStories` export/connected behavior |

### Layer 1: Pure presenter/normalizer tests

Cover:

- atom/string key parity without dynamic atom creation;
- required keys, trimmed grammatical copy, closed states and completeness values;
- stable result/blocker/filter ordering and unique ids;
- unknown completeness defaults to unknown, never complete;
- missing audit reason/outcome exact copy;
- absolute display time plus valid machine-readable datetime;
- current vs snapshot blocker labels;
- hostile HTML/Unicode remains ordinary escaped text;
- raw errors, tokens, hashes, reason originals, or backend structs are never accepted as render contracts.

### Layer 2: Component render/source tests

Create `operator_patterns_test.exs` using the repository's existing `Phoenix.LiveViewTest.__render_component__/4` and slot-map helpers.

Required assertions:

- all six functions render their semantic roots and locked information order;
- existing Primitives/Forms/DataDisplay calls are present; raw duplicate controls/styles are absent;
- confirmation requires nonempty object/scope/consequence/reversibility/dismiss/confirm copy, contains required reason/count fields, role/label/modal semantics, `focus_wrap`, named pending state, and deterministic result rows;
- generic “Are you sure?”, “Confirm”, ambiguous “Cancel”, “Something went wrong”, and `inspect(error)` paths are absent;
- FilterBar has one form/field tree, proper disclosure wiring, visible applied summary/removals/clear, and submit/instant differences;
- DetailSurface has one dialog/body tree, explicit state branches, visible labelled close, and no nested dialog;
- AttentionCard is persistent and not alert by default; status and severity are distinct/non-color;
- WhyBlocked renders all blockers and honest unknown/unavailable branches;
- AuditEntry renders article, heading, `<time datetime>`, and description semantics;
- hostile caller `class`, `style`, role, title, inline handlers, arbitrary data payloads, and secret sentinels are absent from full HTML.

Fast command:

```text
mix test test/oban_powertools/web/components/operator_patterns_test.exs --seed 0
```

### Layer 3: Connected LiveView/server tests

Use ShowcaseLive or a dev/test-only harness as the parent; keep production components stateless.

Prove:

- blank/short reason and wrong bulk count keep preview open with inline errors;
- a valid reason/count submits once, and server code revalidates parameters rather than trusting disabled state;
- expired/drifted/consumed preview execution is rejected and requires fresh preview;
- partial results retain deterministic `success`, `failed`, `skipped` rows and recovery/audit destinations;
- draft filter edits do not change applied results/URL; Apply does; invalid draft is retained; invalid direct URL canonicalizes with replace;
- initial detail open pushes history, selection switch replaces, close replaces to filter-preserving URL, Back closes after initial open, direct URL loads;
- no dialog is nested when transitioning drawer -> confirmation.

Reuse focused Lifeline integration where practical rather than simulating expiry/drift/consumption only in assigns.

### Layer 4: CSS, JS, and packaged assets

Extend `theme_tokens_test.exs` and `assets_test.exs`; add focused JS source assertions where existing tests do.

Verify:

- every component selector is below `.obpt-root` and uses semantic tokens;
- 320px reflow has no page horizontal scroll;
- detail drawer/modal/inline selectors and one-body-scroll rules exist;
- focus-visible and high-contrast non-color indicators exist;
- reduced-motion collapses transform/opacity feedback without hiding content;
- JS selectors are fixed/scoped, mode changes close before reopen, and synchronization is idempotent;
- no host selectors, custom LiveSocket hook registration requirement, localStorage of component state, dynamic evaluation, or sensitive logging;
- source/static CSS and JS are byte-identical after `mix oban_powertools.assets.build` and repeated builds are stable.

### Layer 5: Catalog, showcase, manifest, and package boundary

Cover exact 23 IDs/order, deterministic fixtures, stable activation metadata, no secrets, schema 6, append order, 64 total targets (9 scenarios + 7 primitive + 9 form + 6 shell + 10 data + 23 group), and generic structure support for kind `group`.

Run:

```text
mix test test/oban_powertools/operator_pattern_story_catalog_test.exs \
  test/oban_powertools/web/live/showcase_live_test.exs --seed 0
npm run showcase:manifest
node test/browser/support/manifest-smoke.mjs
npx playwright test --list test/browser/specs/operator-patterns.behavior.spec.ts
```

Add fresh child-VM/package tests proving an absent or malformed optional group catalog reaches the existing Operator Groups placeholder without adding support files to the Hex package.

### Layer 6: Targeted Playwright behavior

At minimum, run `chromium-320` and `chromium-wide`; use tablet for adaptive transition coverage.

ConfirmActionDialog checks:

- initial focus on title/consequence;
- Tab and Shift-Tab wrap; Escape and visible dismiss close dismissible states;
- focus returns to invoker, or fallback when invoker is removed;
- pending is busy, duplicate control activation is suppressed, and non-dismissible copy is explicit;
- partial patch focuses result heading and preserves rows/recovery;
- exact one polite success receipt; no fake host-completion claim.

FilterBar checks:

- disclosure button Enter/Space, `aria-expanded`, `aria-controls`, and collapsed tab order;
- draft/applied divergence, Apply, active removal, Clear, exact result summary, and restrained one-time status announcement;
- URL/history behavior and 320 overflow.

DetailSurface checks:

- `dialog.matches(':modal')` in drawer mode and not in wide inline mode;
- outside content is inert/unavailable only while modal;
- modal Tab containment, Escape/visible close, invoker/fallback restore;
- wide inline focus can move back to results (no trap);
- resize wide -> narrow -> wide changes effective mode safely with one dialog tree;
- direct link, selection replacement, close, and Back semantics.

Explanation/audit checks:

- no default alert on static AttentionCard;
- severity has visible text/icon, not color alone;
- all blockers/clearing conditions and current-vs-snapshot labels are present;
- unknown evidence never renders “No blockers”;
- AuditEntry absolute time and missing-field copy;
- secret sentinel absent from text, attributes, details, and action destinations.

Exact status-message text/cardinality is the automated screen-reader announcement proof. Axe cannot judge announcement timing/quality by itself, so record the intended announcement strings and roles in browser assertions; broader manual SR sweep remains the Phase 82 cross-page gate.

### Layer 7: Axe and VRT

The generic schema-6 target loop adds 276 group axe cases and 276 group screenshots. Activate overlay stories one at a time before scanning/snapshotting. Use canonical Docker commands and focused `group group-` grep after confirming discovery with `--list`.

Run update once, then a compare-only pass. Verify exactly 276 group PNGs and changed scope limited to group paths. Do not refresh the 108 unrelated scenario-only residual recorded by Phase 76/77, and do not claim the repository-wide visual aggregate is green unless that independent residual is actually resolved.

### Final phase gate

```text
mix format --check-formatted
mix compile --warnings-as-errors
mix test <all Phase 78 focused ExUnit files> --seed 0
npm run showcase:manifest
node test/browser/support/manifest-smoke.mjs
node test/browser/support/verify-group-baselines.mjs
npx playwright test --list test/browser/specs/operator-patterns.behavior.spec.ts
<connected 320/tablet/wide behavior>
<focused group axe>
<canonical Docker group VRT compare-only>
```

Do not mark complete from test discovery, static markup, or baseline existence. Record executed connected behavior, axe, compare-only VRT, exact baseline equality, asset equality, and package fallback evidence in `78-VALIDATION.md`.

## Planning Pitfalls

1. **Migrating pages now.** Page adoption belongs to Phases 79-81; use a harness and real stories.
2. **Treating the component as authorization/execution.** The browser preview is presentation, never an execution plan.
3. **Accepting backend structs or raw error maps.** Normalize before rendering; never `inspect(error)`.
4. **Creating local leaf controls/status colors.** Compose Phase 74-77 components and extend the shared taxonomy if needed.
5. **Letting valid-looking form state replace server validation.** Recheck reason/count/freshness/authorization/single-use on submit.
6. **Closing partial/failed results.** Keep evidence/recovery visible and distinguish skipped from failed.
7. **Using `alertdialog` everywhere or focusing danger first.** This is a structured workflow; use dialog and static initial focus.
8. **Wrapping adaptive detail in `focus_wrap`.** That traps wide inline content incorrectly.
9. **Adding a custom `phx-hook` without host integration.** The packaged asset cannot assume the host passes Powertools hooks to LiveSocket.
10. **Rendering two responsive detail trees.** Duplicates ids, controls, events, and sensitive content.
11. **Opening every modal story on showcase mount.** Multiple top-layer dialogs break visibility, inertness, axe, and VRT.
12. **Letting native Escape close only the DOM dialog.** Route cancel/close through the parent action so URL/open state cannot immediately reopen it.
13. **Inferring current blockers from audit/snapshot history.** Current and historical evidence remain separate.
14. **Using relative time alone in audit.** Always include visible absolute time and machine `datetime`.
15. **Using axe/screenshots as behavior proof.** They cannot prove history, focus restoration, resize modality, duplicate submit, or announcement timing.
16. **Refreshing unrelated baselines.** Add exactly 276 group images and preserve prior residuals.

## Primary Files the Plans Will Touch

### New

- `lib/oban_powertools/web/components/operator_patterns.ex`
- optional pure presenter/normalizer test/source if not extending `ControlPlanePresenter`
- `test/oban_powertools/web/components/operator_patterns_test.exs`
- `test/oban_powertools/web/live/operator_patterns_harness_test.exs` or equivalent focused ShowcaseLive tests
- `test/support/operator_pattern_story_catalog.ex`
- `test/oban_powertools/operator_pattern_story_catalog_test.exs`
- `test/browser/specs/operator-patterns.behavior.spec.ts`
- `test/browser/support/verify-group-baselines.mjs`
- 276 group PNGs under `test/browser/__screenshots__/chromium-*/showcase/group-*`

### Modified

- `lib/oban_powertools/web/control_plane_presenter.ex` (if selected presenter seam)
- `lib/oban_powertools/web/status_taxonomy.ex` (only if adding closed operator-result states)
- `assets/oban_powertools/tokens.css`
- `assets/oban_powertools/theme.js`
- `priv/static/oban_powertools/oban_powertools.css`
- `priv/static/oban_powertools/oban_powertools.js`
- `lib/oban_powertools/web/dev/showcase_live.ex`
- `scripts/showcase_manifest.exs`
- `test/browser/support/manifest.ts`
- `test/browser/support/manifest-smoke.mjs`
- `test/browser/support/showcase.ts`
- `test/browser/specs/showcase.structure.spec.ts`
- `test/browser/specs/showcase.a11y.spec.ts` and VRT helper calls only as needed for activation
- `test/oban_powertools/web/live/showcase_live_test.exs`
- `test/oban_powertools/web/theme_tokens_test.exs`
- `test/oban_powertools/web/assets_test.exs`
- `test/oban_powertools/web/status_taxonomy_test.exs` if taxonomy changes
- `.planning/phases/78-component-groups-meta-components/78-VALIDATION.md`

No `mix.exs`, `mix.lock`, `package.json`, or `package-lock.json` change should be necessary.

## Sources

### Binding project sources

- `.planning/phases/78-component-groups-meta-components/78-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`
- `guides/brand-book.md`
- Phase 75 form artifacts, Phase 76 shell artifacts, and Phase 77 data-display artifacts

### Code and test sources

- `lib/oban_powertools/web/components/primitives.ex`
- `lib/oban_powertools/web/components/forms.ex`
- `lib/oban_powertools/web/components/data_display.ex`
- `lib/oban_powertools/web/status_taxonomy.ex`
- `lib/oban_powertools/web/control_plane_presenter.ex`
- `lib/oban_powertools/lifeline.ex`
- `lib/oban_powertools/lifeline/repair_preview.ex`
- `lib/oban_powertools/audit.ex`
- `lib/oban_powertools/explain.ex`
- `assets/oban_powertools/theme.js`
- `assets/oban_powertools/tokens.css`
- `lib/oban_powertools/web/dev/showcase_live.ex`
- `test/support/data_display_story_catalog.ex`
- `scripts/showcase_manifest.exs`
- `test/browser/support/manifest.ts`
- `test/browser/support/showcase.ts`
- existing component, LiveView, behavior, axe, and VRT tests

### Official technical references

- [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html)
- [Phoenix.LiveView.JS](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html)
- [Phoenix.LiveView navigation](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#push_patch/2)
- [WAI-ARIA APG Modal Dialog](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
- [WAI-ARIA APG Disclosure](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/)
- [WCAG 2.2 Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)
- [MDN HTMLDialogElement](https://developer.mozilla.org/en-US/docs/Web/API/HTMLDialogElement)

---

*Research complete: 2026-07-18*
