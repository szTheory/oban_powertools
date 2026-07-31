# Phase 82: Cross-Cutting A11y, Motion & Responsive Hardening Sweep - Research

**Researched:** 2026-07-29
**Domain:** WCAG 2.2 AA, deterministic browser geometry, reduced motion, responsive reflow, operator microcopy, fail-closed CI
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### One Complete Quality Graph

- **D-01:** Treat the Elixir-owned catalog and its generated schema-8 manifest
  as the only showcase inventory. The sweep covers every currently registered
  primitive, form, data-display, group, and page-story target; it must not
  maintain a hand-written second target list or invent Phase 83 stories.
- **D-02:** Treat the nine authenticated production routes as a separate
  connected acceptance lane. Each route must be exercised through its real
  `AppShell` and production composition, not accepted solely because a
  deterministic showcase story passes.
- **D-03:** Extend the existing required, unfiltered `verify:pages` /
  `page_quality` graph and exact validators. Focused slices may speed local
  iteration, but milestone evidence comes from the complete graph with no
  grep, retry, ignored failure, update mode, or manually omitted target.
- **D-04:** Preserve the established deterministic evidence model: generated
  discovery, exact ARIA snapshots, connected keyboard/focus checks, axe,
  compare-only VRT, and structured VoiceOver evidence. A deliberate snapshot
  change is reviewed as an implementation change and followed by a fresh
  compare-only run; snapshot update mode is never completion evidence.

### WCAG, Contrast, Targets, and Focus

- **D-05:** Axe runs with WCAG 2.2 AA tags against every current showcase
  target in every supported theme and open-state variant, and against all nine
  connected production pages. Zero critical or serious violations is
  merge-blocking. Relevant moderate findings are not silently waived: either
  repair them or record a narrow, standards-backed exception with executable
  regression coverage.
- **D-06:** Add mechanical contrast verification at the token/component
  chokepoints and representative rendered states. Light and dark require WCAG
  AA text contrast (4.5:1 normal text, 3:1 large text) and 3:1 non-text
  contrast; muted text retains its 4.5:1 hard floor. High-contrast requires the
  brand-book enhanced target of at least 7:1 for body text, solid semantic
  boundaries, and a focus indicator at least 2 CSS px thick with at least 3:1
  contrast against both adjacent states. Meaning must remain complete without
  color.
- **D-07:** Enforce WCAG 2.2 2.5.8 mechanically: every pointer target is at
  least 24 by 24 CSS px or has standards-compliant spacing, with any inline or
  essential exception explicit and tested. Retain the shipped stronger
  comfort rule for operator controls: primary actions, icon controls,
  pagination, row actions, selection controls, theme/navigation controls, and
  dialog actions expose an effective 44px target in at least one axis without
  overlap.
- **D-08:** Verify WCAG 2.4.11 with actual keyboard focus after scroll,
  navigation, dialog open/close, validation error, LiveView patch, responsive
  mode change, and recovery. Focus may not be fully obscured by sticky/fixed
  chrome or overlays; it remains visibly outlined, logically ordered, and
  restored to the connected invoker or documented fallback.

### Keyboard, Reflow, and Motion

- **D-09:** Run full keyboard traversal on every production page, including
  skip link, navigation, filters, tables/lists, pagination, adaptive details,
  disclosures, dialogs, confirmations, validation errors, recovery, and
  destinations that exist on that page. Native/APG interaction behavior,
  Escape policy, focus containment, invoker restoration, and live-region
  announcements remain executable contracts; no single-key shortcut is added.
- **D-10:** Every page and current showcase target uses one semantic responsive
  tree from 320px through tablet and wide layouts and at 200% zoom. Page,
  document, and root horizontal overflow must be zero at 320px; duplicated
  mobile/desktop content is forbidden. Only bounded, labelled, keyboard-
  reachable machine-content regions may scroll horizontally, and nested
  scrolling may not make ordinary controls unusable.
- **D-11:** Keep DATA-03 behavior explicit while reflowing: tables/lists stack
  or use their established semantic fallback; long IDs, modules, URLs,
  Unicode/RTL text, and stack traces wrap, visibly truncate with an accessible
  expansion, or use a bounded labelled scroller. Empty, loading, unavailable,
  permission-denied, stale, and partial states remain distinguishable.
- **D-12:** Inventory every animation and transition in the token CSS,
  packaged CSS, components, and page composition. Motion must use token-owned
  duration/easing, communicate a state change rather than decorate, be
  interruptible, and never delay authority, action, focus, content, recovery,
  or feedback.
- **D-13:** Under both `prefers-reduced-motion: reduce` and the root-scoped
  explicit reduced-motion state, non-essential animation becomes instant or
  absent across every target and page. Spinners, skeletons, overlays,
  disclosures, responsive details, theme/nav controls, progress, and
  LiveView-updated content must remain visible and operable; reduced motion
  cannot substitute hidden content or suppress an announcement.

### BRAND-04 Copy and Honest Recovery

- **D-14:** Audit rendered copy and source literals against `guides/brand-book.md`
  D-16 through D-21: plain, consequence-first, precise, calm, honest,
  non-cute, non-hedging, active-voice language. Apply the coherence test to
  every changed string: it should make a stressed operator calmer and more
  certain about what will happen.
- **D-15:** Enforce one term per concept across all nine pages and shared
  components. Centralize repeated state, action, danger, dismissal, and
  recovery literals where doing so prevents drift; retain page-specific
  consequence and support-boundary text when generic copy would become less
  truthful. Do not perform an unrelated gettext or localization migration.
- **D-16:** Every destructive or state-changing confirmation names the object,
  exact count/scope, consequence, reversibility, support boundary, and required
  reason before its action-specific submit. The dismiss label describes the
  state being preserved and never uses ambiguous `Confirm`, `Cancel`, or “Are
  you sure?” wording.
- **D-17:** State and error copy is mechanically audited: empty states give a
  fact plus next action; loading names what is loading; stale, unavailable,
  permission-denied, partial, and empty remain distinct; errors say how to
  recover. Receipts describe only what Powertools actually requested,
  recorded, changed, or audited and never promise a host-owned downstream
  outcome.
- **D-18:** Add a fail-closed BRAND-04 copy contract to the normal quality
  graph. It should combine a finite glossary/forbidden-phrase registry,
  rendered nine-page and showcase scans, and focused ordering assertions for
  confirmations and recovery. It must report the exact page/story and string
  on failure rather than relying on a subjective manual sign-off.

### Remediation and Completion Policy

- **D-19:** Prefer fixes at the shared token, component, copy, presenter, or
  harness seam when the defect crosses pages. Use a page-local repair only
  where the page has genuinely unique semantics; do not create parallel focus,
  motion, responsive, status, copy, or target-size systems.
- **D-20:** Preserve all Phase 79–81 product contracts: routes and URL state,
  server-owned authorization, Lifeline preview/reason/reauthorize/execute/audit,
  redaction and confidentiality, bounded reads, support truth, one semantic
  tree, and production-composed stories. An accessibility fix may not move
  mutation authority into the client or expose raw/provider-shaped data.
- **D-21:** Keep source and packaged CSS byte-identical and repeat-build stable.
  New static validators must fail on inline motion timings, unscoped raw
  visual values, duplicated responsive trees, stale packaged assets, or
  unregistered quality targets.
- **D-22:** Phase completion requires a fresh green unfiltered quality graph,
  focused ExUnit/browser regression suites, formatting, warnings-as-errors
  compilation, exact artifact validators, source/package equality, and full
  repository tests. The validation ledger records exact commands, inventory
  counts, standards mappings, and any legitimate exceptions; no manual
  accessibility claim may stand in for executable evidence.

### Claude's Discretion

Exact plan slicing, helper names, validator decomposition, representative
contrast-state selection, and the internal copy-registry shape are
discretionary. Those choices must retain complete nine-page plus current-
showcase coverage, generated inventory ownership, the numeric standards above,
the existing required CI graph, and the product/authority boundaries already
locked by Phases 70–81.

### Deferred Ideas (OUT OF SCOPE)

- Adding missing showcase stories, a contributor guide, design-system
  documentation, and idempotency-guardrail documentation remains Phase 83.
- The final milestone audit and any archive/completion operation remains Phase
  84 / milestone-completion scope.
- New operator features, route changes, localization infrastructure, new
  runtime dependencies, or a redesign of the established page information
  architecture are outside Phase 82.
</user_constraints>

## Phase Requirements

| ID | Research support |
|----|------------------|
| A11Y-01 | Preserve manifest-derived axe and add connected-route axe; use the current WCAG A/AA/2.1/2.2 tag set, block critical/serious, and fail moderate unless an exact executable exception exists. |
| A11Y-02 | Centralize keyboard, visible-focus, focus-restoration, non-color, and dialog probes and apply them to all nine connected routes plus relevant showcase open states. |
| A11Y-03 | Add standards-accurate contrast, 24px-or-spacing target, 44px operator-control, and focus-not-obscured measurements. |
| A11Y-04 | Preserve 297 exact page ARIA snapshots and ten real-VoiceOver targets; add exhaustive reduced-motion and focus/recovery browser proof without inventing transcripts. |
| MOTION-01 | Parse every source and packaged CSS motion declaration and reject untokened durations/easing or asset drift. |
| MOTION-02 | Exercise both media-query and explicit-root reduction paths; prove content, focus, controls, and announcements remain available immediately. |
| NAV-02 | Exercise the real shell at 320/tablet/wide and 200% zoom with no document overflow or unusable nested scrollers. |
| DATA-03 | Mechanically exercise long/Unicode/RTL/machine content and all distinct data states across the generated target graph. |
| COPY-01 | Create one finite copy/glossary contract and scan source plus all rendered targets/routes with exact diagnostics. |
| COPY-02 | Enforce generic confirmation structure centrally while retaining action-specific consequence and support-truth copy. |

## Summary

Phase 82 should be planned as a **test-contract-first closure sweep**, not a
visual redesign. The production UI already has the correct ownership seams:
Elixir owns the catalog and safe presentation maps, shared components own
semantics, token CSS owns visual/motion behavior, LiveViews own URL and
authority, and Playwright owns connected browser proof. The missing layer is a
small set of reusable mechanical auditors applied exhaustively to those seams.
[VERIFIED: repository inspection and `82-CONTEXT.md`]

The strongest implementation shape is:

1. write RED unit/static/browser contracts for the missing algorithms;
2. centralize reusable browser measurements and the finite copy contract;
3. repair shared tokens/components/copy first;
4. apply page-local fixes only for genuinely page-specific semantics;
5. wire the new checks into the existing exact `verify:pages` and CI validator;
6. finish with compare-only artifacts and full repository verification.

No new package is needed. `@axe-core/playwright`, `axe-core`, Playwright, ExUnit,
Phoenix.LiveViewTest, the generated manifest, and the existing fixture launchers
already provide the required substrate. [VERIFIED: `package.json`,
`package-lock.json`, and repository tests]

## Current Baseline

Fresh local evidence on 2026-07-29:

| Contract | Current result |
|----------|----------------|
| Manifest | schema 8; 9 scenarios, 7 primitive, 9 form, 6 shell, 10 data, 23 group, 99 page stories; **163 total targets** |
| Page families | Overview 3, Cron 8, Limiters 4, Audit 4, Jobs 18, Forensics 12, Batches 18, Workflows 12, Lifeline 20 |
| Themes/viewports | 4 themes (`system`, `light`, `dark`, `high-contrast`) × 3 viewports (320, 768, 1440) |
| Activation inventory | 10 group overlays; page activations: 69 none, 9 detail, 21 confirmation |
| Confirmation coverage seam | 28 targets compose `confirm_action_dialog`; 27 are activated open states |
| Exact page ARIA | **297** = 99 × 3 |
| Exact page PNG | **1,188** = 99 × 4 × 3 |
| Exact full-showcase PNG | **1,956** = 163 × 4 × 3 |
| Full-showcase axe discovery | **1,956 tests** |
| Required page-quality discovery | **2,790 tests** across seven files |
| Connected discovery already in graph | Wave 1 45, Wave 2 24, Phase 81 fixture 18, Wave 3 30 = **117 project-expanded tests** |
| Structured VoiceOver | **10 tests**, covering all nine page families |
| Focused static/catalog/assets suite | **43 tests, 0 failures** |
| Source/package CSS | byte-identical |

[VERIFIED: fresh `npm run showcase:manifest`, Playwright `--list`, exact
validators, `cmp`, and focused `mix test`]

### Current gaps that plans must close

1. `showcase.a11y.spec.ts` is exhaustive over generated targets and themes, but
   the three connected page suites never call axe. [VERIFIED: source]
2. Axe currently throws only for `critical` and `serious`; `moderate` findings
   are written to JSON but are not repaired or exception-gated. [VERIFIED:
   `test/browser/support/axe.ts`]
3. Existing target helpers implement only the stronger “44px in one axis”
   comfort check on selected connected controls. They do not implement the
   normative 24×24-or-spacing algorithm or explicit exception records.
   [VERIFIED: Wave 2/3 specs]
4. Existing visible-focus helpers check outline presence and viewport
   intersection. They do not test author-created occlusion, 2px thickness, or
   focus-indicator contrast. [VERIFIED: Wave 1/2 specs]
5. Reflow/zoom coverage is page-wave-specific; no generated test measures every
   current showcase target for root/body/document overflow, one-tree behavior,
   bounded machine scrollers, or 200% zoom. [VERIFIED: browser specs]
6. Playwright defaults to `reducedMotion: "reduce"` and
   `prepareShowcase/2` forces reduction. This proves reduced presentation but
   never inventories normal-mode computed motion, and explicit
   `data-obpt-motion="reduce"` is not exhaustively rendered. [VERIFIED:
   Playwright config and support code]
7. CSS has 22 `transition` declarations, 16 `transition-duration`
   overrides, 4 `animation` declarations, and 2 keyframe definitions. Existing
   tests check representative token use but do not maintain an exact
   declaration inventory with purpose and paired reduction coverage.
   [VERIFIED: fresh source scan]
8. Page stories contain small duplicated forbidden-phrase lists and selected
   ordering contracts. There is no one finite production copy registry, no
   source-wide rendered-string audit, and no connected nine-route scan.
   [VERIFIED: `PageStoryCatalog` and copy-coherence tests]
9. The CI structural validator fixes seven browser spec paths and the exact
   seven-job gate. It must be extended atomically with Phase 82 specs/scripts;
   otherwise a new check can exist but remain non-blocking. [VERIFIED:
   `verify-page-script-order.mjs`]

## Standard Stack

No package installation is required or permitted.

| Tool | Resolved version | Phase 82 use |
|------|------------------|--------------|
| Elixir / ExUnit | project `~> 1.19` | CSS/source contract tests, copy registry, component/LiveView regression |
| Phoenix / LiveView | 1.8.7 / 1.1.31 | real production composition, patch/focus/recovery tests |
| Playwright | 1.61.0 | computed style, geometry, media emulation, keyboard, zoom, connected route proof |
| axe-core / axe Playwright | 4.11.4 / 4.11.3 | WCAG-tagged automated findings for generated and connected surfaces |
| Guidepup / Guidepup Playwright | 0.29.2 / 0.18.0 | existing real VoiceOver transcript/cursor evidence |
| Schema-8 manifest | repository-owned | only generated showcase target inventory |

[VERIFIED: lockfiles and package manifest]

## Package Legitimacy Audit

Not applicable. Phase 82 should not modify dependency manifests. The required
capabilities already exist in the repository. [VERIFIED: locked scope]

## Architectural Responsibility Map

| Concern | Owner | Phase 82 rule |
|---------|-------|---------------|
| Showcase inventory | Elixir catalogs → schema-8 manifest | Derive every showcase loop; never copy IDs into TypeScript. |
| Connected routes | exact nine-family route map backed by existing authenticated fixtures | Keep separate from showcase inventory, but assert its keys equal manifest page families. |
| Contrast/motion/geometry algorithms | one TypeScript browser-support module | Wave specs and showcase specs import it; no copied per-wave helpers. |
| Copy/glossary contract | one finite Elixir production module or presenter-owned module | Generate browser-readable contract through the manifest or rendered root; do not maintain a TypeScript phrase list. |
| Shared visual repair | `tokens.css` + compiled asset | Modify source, rebuild normally, assert byte equality and repeat-build stability. |
| Semantic repair | shared components/presenters | Use page-local changes only when the semantic truth is page-specific. |
| URL/auth/mutation | existing LiveViews/domain modules | Preserve without moving decisions into browser helpers. |
| Evidence/CI | package scripts + exact Node validator + required jobs | New checks must be direct members of the required graph and mutation-tested. |

## Mechanical WCAG Algorithms

### 1. Text and non-text contrast

Use one browser helper with exact sRGB relative-luminance math:

```text
channel = c/12.92                         when c <= 0.04045
channel = ((c + 0.055)/1.055) ^ 2.4      otherwise
L = 0.2126R + 0.7152G + 0.0722B
ratio = (lighter + 0.05) / (darker + 0.05)
```

Do not round before threshold comparison. Parse computed `rgb()`/`rgba()`,
alpha-compose foreground/background through ancestors until opaque, and fail
closed on gradients/images or unresolved colors rather than guessing.
[VERIFIED: W3C WCAG 2.2 Understanding 1.4.3 and 1.4.11]

For rendered text:

- normal text: ratio `>= 4.5`;
- large text: ratio `>= 3`; large means at least 24 CSS px regular or about
  18.66 CSS px bold (700+), using computed size/weight;
- anything using `--obpt-color-muted`: always `>= 4.5`, even if large;
- placeholders, visible hover text, and visible focused text are included;
- disabled/inactive and purely decorative content may be excluded only by an
  exact documented category.

For non-text UI boundaries, measure the computed border/icon/indicator color
against the color immediately adjacent to it and require `>= 3`. Do not treat
the ordinary light/dark `--obpt-color-border` as a universal semantic boundary:
fresh token math shows only **1.485:1** on light surface and **1.826:1** on dark
surface. Use `border-strong` (7.578:1 light, 7.376:1 dark) wherever the border is
required to identify a control/state; low-contrast decorative separators may
remain only when they carry no information. [VERIFIED: fresh exact token math]

High contrast already has strong raw token candidates: body text 20.173:1,
muted text 16.364:1, focus/surface 13.917:1, and border/surface 13.587:1.
Tests must prove actual rendered adjacency, not merely token definitions.
[VERIFIED: fresh exact token math]

Recommended coverage:

1. ExUnit token-pair table for every semantic foreground/background,
   solid/solid-fg, border, and focus pair in light/dark/high-contrast.
2. Browser checks on representative component chokepoints selected by component
   kind, while the existing exhaustive axe matrix continues to visit all 1,956
   target/theme/viewport combinations.
3. A rendered color-independent assertion for status, error, selected, progress,
   and blocked states: visible text/icon/shape semantics must remain after
   neutralizing semantic foreground colors.

### 2. Focus appearance and 2.4.11

For each actual focused element:

- assert it is still connected, enabled, and the `document.activeElement`;
- require an author-visible indicator (`outline-style != none`, width at least
  2 CSS px, or an explicitly registered equivalent area);
- resolve indicator and adjacent computed colors and require `>= 3:1`;
- intersect its client rect with the viewport;
- use `elementsFromPoint` on a deterministic inset grid over the visible
  intersection; at least one sampled point must resolve to the focused element
  or its descendant;
- separately detect overlapping visible `position: fixed|sticky` and open
  top-layer/overlay rectangles; report their selectors with the focused target;
- require scroll/navigation/patch/resize/dialog/recovery probes to rerun the
  same assertion, not a weaker special case.

WCAG 2.4.11 requires that the component not be entirely hidden by
author-created content; the phase's locked contract is stricter because it also
requires a visibly outlined focus state. [VERIFIED: W3C Understanding 2.4.11
and locked D-08]

### 3. Target size 2.5.8

Build the candidate set from visible enabled pointer targets:
`a[href]`, `button`, non-hidden `input`, `select`, `textarea`, `summary`,
and explicit interactive roles/tabindex. Exclude ancestor/descendant duplicates
that represent one control.

For each target:

1. pass directly when width and height are both at least 24 CSS px;
2. for an undersized target, require an exact exception record:
   `inline`, `equivalent`, `user-agent`, `essential`, or `spacing`;
3. for `spacing`, center a radius-12 circle on the undersized target:
   - distance to another undersized target's center must be at least 24;
   - distance from the center to the nearest point of any other target rect
     must be at least 12;
4. reject overlapping hit rectangles;
5. additionally require the project comfort set to expose at least 44 CSS px in
   one axis and no overlap.

Never silently infer `inline` or `essential` from tag name. Represent exceptions
as a small reviewed data attribute/registry and mutation-test unknown or stale
exceptions. [VERIFIED: W3C Understanding 2.5.8]

### 4. Reflow, 320px, 200% zoom, and machine scrollers

At base geometry, assert for root, body, and document:

```text
ceil(scrollWidth - clientWidth) <= 1
```

At 320px, any descendant with horizontal overflow must:

- be an explicitly registered machine-content region;
- have an accessible name and keyboard reachability;
- have bounded width inside the page;
- not contain ordinary page actions, selection controls, or navigation;
- not create a second vertical/nested scroll trap;
- expose the complete value through wrapping, expansion, or its labelled
  scroller.

Assert zero `[data-obpt-mobile-copy]` and `[data-obpt-desktop-copy]`, at most one
identity for each adaptive detail, and at most one open modal. Exercise 200%
zoom through the existing CDP device-metrics helper, but restore metrics in a
`finally` block so later assertions cannot inherit the override. The W3C reflow
criterion uses the 320 CSS-pixel equivalence; the phase additionally locks 200%
zoom as a separate regression target. [VERIFIED: W3C Understanding 1.4.10 and
existing Phase 79–81 helpers]

## Axe Policy

Keep the existing tag set:

```ts
["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"]
```

Deque documents `wcag22aa` as the WCAG 2.2 AA tag and `runOnly` as the standard
tag-selection mechanism. Axe does not replace keyboard, focus-obscuration,
reflow, motion, or manual/real-screen-reader evidence. [VERIFIED: official
axe-core API and Playwright accessibility documentation]

Change the result policy:

- `critical` and `serious`: always fail;
- `moderate`: fail by default;
- a moderate exception is accepted only through a finite registry containing
  rule ID, exact target/story/route scope, WCAG rationale URL, owner, expiry,
  and an executable compensating assertion;
- stale, broad, expired, unmatched, or unused exceptions fail;
- `minor` remains recorded and visible in artifacts but is not promoted beyond
  locked scope unless it violates another exact contract;
- failure text includes project, theme, route/story, rule, impact, and every
  affected selector (not just the first five).

Add axe to the connected nine-route sweep. Do not weaken the existing 1,956-case
manifest-derived showcase matrix.

## Motion Inventory and Reduced-Motion Contract

Create an exact static motion inventory from parsed declarations rather than a
hand-maintained count. Each normal-mode declaration records:

- selector and property;
- tokenized duration/easing;
- purpose (`state`, `progress`, `overlay`, `disclosure`, `focus/theme`);
- whether transform/position changes;
- paired `prefers-reduced-motion` selector;
- paired root `[data-obpt-motion="reduce"]` selector.

Fail on raw `ms`/`s` timing outside token declarations, inline style timing,
unknown keyframes, unscoped selectors, animation delay that gates content, or a
normal declaration without both reduction paths. Compare the same extracted
inventory against packaged CSS and preserve byte equality.

Browser checks should run both paths:

1. `page.emulateMedia({reducedMotion: "reduce"})`;
2. normal media plus `data-obpt-motion="reduce"` on `.obpt-root`.

For every active target and connected page, compute all visible descendants'
`animationName`, `animationDuration`, `animationIterationCount`,
`transitionDuration`, and `transitionDelay`. Under reduction, require no
non-essential named animation and no duration/delay above the instant token.
Then assert spinners/skeletons still expose named loading content, open overlays
remain visible, disclosures remain operable, progress remains textual/native,
focus is immediate, and live regions still announce. Do not use blanket
`visibility:hidden`, `display:none`, or content-removing reduction.

Normal-mode tests should prove the inventory exists and is interruptible; they
must not wait for animation before authority, action, focus, result, or recovery
becomes available. W3C identifies `prefers-reduced-motion` as a sufficient
technique for suppressing non-essential interaction animation. [VERIFIED: W3C
Understanding 2.3.3; project requirement is stricter than its AAA criterion]

## BRAND-04 Fail-Closed Copy Architecture

Create one production-owned finite contract, recommended as
`ObanPowertools.Web.Copy`, with:

- canonical concept terms and disallowed synonyms;
- forbidden phrases (`Are you sure?`, bare `Confirm`, ambiguous dismiss
  `Cancel`, `Something went wrong`, `An error occurred`, unqualified `N/A`,
  cute/reassuring phrases, and outcome-overclaim phrases);
- shared state headings and recovery stems;
- exact confirmation section order;
- safe-state dismiss label rules;
- host-owned outcome verbs that must not appear in Powertools receipts.

Do not centralize unique consequences merely to reduce literal count. Keep
page-specific scope, reversibility, and support-boundary sentences adjacent to
their presenter when generic wording would lose truth.

Expose the finite contract to browser tests through the generated schema-8
manifest (an additional validated non-inventory field) or a deterministic
attribute rendered from the same Elixir module. Do not copy the phrase registry
into TypeScript. Preserve schema version 8 unless a deliberate repository-wide
schema migration is planned; adding a validated field is sufficient.

Three complementary gates are required:

1. **Source scan:** AST/string-aware scan of production web presenters,
   components, LiveViews, and story fixtures; diagnostics include path, line,
   phrase, and expected canonical term. Exclude the registry definition and
   explicit negative-test fixtures by exact path/scope, not broad grep ignores.
2. **Rendered showcase scan:** every generated target after activation, so
   hidden/open states and all current component kinds are covered.
3. **Connected route scan:** all nine authenticated production pages, including
   confirmation, validation, stale/recovery, partial/unavailable, and receipt
   states produced through existing fixture controls.

Generic DOM ordering for every open `confirm_action_dialog`:

```text
object → scope/count → consequence → reversibility → support boundary
→ reason label/hint/error → action-specific submit + safe-state dismiss
```

Errors must include a recovery action; empty states must contain a fact and next
action; loading must name the resource; distinct state attributes must not
collapse stale/unavailable/permission-denied/partial/empty copy. Receipts may
say only requested, recorded, changed, or audited unless a domain contract
proves more.

## Connected Nine-Page Acceptance

Create one exhaustive page-family map whose keys are checked against the unique
`pageStories.page` families from the manifest. Values contain only connected
route/fixture setup and safe traversal journeys; this is not a second showcase
inventory.

| Family | Connected route seam |
|--------|----------------------|
| Overview | `/ops/jobs` |
| Cron | `/ops/jobs/cron` plus fixture-owned selected entry |
| Limiters | `/ops/jobs/limiters` plus fixture-owned resource |
| Audit | `/ops/jobs/audit` plus fixture-owned event/filter |
| Jobs | `/ops/jobs/jobs` plus fixture-owned detail/bulk states |
| Forensics | `/ops/jobs/forensics` plus fixture-owned exact selector scope |
| Batches | `/ops/jobs/batches` plus fixture-owned batch/detail |
| Workflows | `/ops/jobs/workflows` plus fixture-owned workflow/step |
| Lifeline | `/ops/jobs/lifeline` plus fixture-owned incident/preview |

Each route must:

- authenticate through the existing fixture actor;
- prove `[data-phx-main].phx-connected` and real `AppShell`;
- run axe (all four theme states at wide; exact route failure labels);
- traverse skip link, shell navigation, page controls, and safe page-specific
  journeys with Tab/Shift+Tab/Enter/Space/Escape;
- apply target, visible-focus, not-obscured, one-tree, overflow, motion, and
  copy auditors;
- exercise 320/tablet/wide through Playwright projects and 200% zoom in the wide
  project;
- reuse Wave 1–3 tests for dangerous state transitions rather than blindly
  activating every visible mutation control.

Factor the duplicated Wave 1–3 overflow, zoom, target, and visible-focus helpers
into the shared support module, then update the existing suites to use the
strict implementation. This converts existing dialog/patch/recovery journeys
into 2.4.11 proof instead of adding shallow duplicate tests.

## Performance and Runtime Batching

The existing full page-quality graph required about 1.6 hours in the Phase 81
ledger. Avoid a second full target/theme/viewport navigation matrix.
[VERIFIED: `81-VALIDATION.md`]

Recommended batching:

- enrich the existing manifest-derived axe case after it has already prepared
  and activated a target with contrast, target, copy, and reduced-motion checks;
- run expensive 200% zoom only for `system` + `chromium-wide` inside that
  target case, while every project still receives base reflow;
- run the explicit-root motion path for `system` only; the media-reduction path
  is already the default for every case;
- add only the nine-family connected sweep: **9 × 3 = 27** project-expanded
  tests, looping four themes without reloading the fixture;
- keep compare-only VRT unchanged and do not add new PNG axes.

This preserves the current 2,790 required cases plus 27 connected sweep cases
(projected **2,817**, before any focused mutation fixtures) instead of adding a
new 1,956-case parallel matrix. Full showcase axe remains 1,956 cases; page
ARIA remains 297; page PNG remains 1,188; full PNG remains 1,956.

Use one worker in CI because fixture state and exact artifacts are intentionally
serial. Runtime optimization must come from reuse and bounded DOM evaluation,
not parallel database mutation or retries.

## CI and Artifact Ordering

The required graph should be ordered:

```text
manifest generation
→ exact manifest/artifact validators
→ Wave 1 connected
→ Wave 2 connected
→ Phase 81 fixture + Wave 3 connected
→ Phase 82 connected system sweep
→ page acceptance / exact ARIA
→ exhaustive axe + mechanical quality
→ compare-only VRT
```

Update `verify-page-script-order.mjs` with:

- the new exact spec path in host and Docker scripts;
- one occurrence only;
- no grep, retries, update/watch/UI mode, ignored exit, or `continue-on-error`;
- exact `PAGE_QUALITY_ONLY` behavior;
- direct `page_quality` and full `visual_a11y` ownership;
- direct `ci-gate` dependencies;
- mutation fixtures for omission, reordering, filtering, duplicate execution,
  detached job, stale exception registry, and update mode.

Failure artifacts should include:

- generated schema-8 manifest;
- Playwright HTML/JUnit/trace/screenshots;
- per-target axe JSON;
- a compact Phase 82 JSON report containing exact inventory counts, exception
  usage, contrast/target/focus/motion/copy failures, and route/story labels;
- no fixture secret, raw reason, preview identity, provider payload, or
  browser-channel confidentiality sentinel.

The committed validation ledger records commands and counts. Do not commit
transient test results. Existing 297 ARIA and 1,956 PNG artifacts remain exact;
update only genuine visual/ARIA changes, and follow any update command with a
fresh compare-only pass.

## File and Symbol Integration Map

### Likely additions

| File | Purpose |
|------|---------|
| `lib/oban_powertools/web/copy.ex` | finite canonical glossary/state/dismiss/recovery contract |
| `test/oban_powertools/web/copy_contract_test.exs` | source and semantic copy enforcement |
| `test/browser/support/system-quality.ts` | contrast, target, focus, overflow, one-tree, motion, rendered-copy algorithms |
| `test/browser/support/connected-pages.ts` | exact nine-family route/fixture map, keyed against manifest families |
| `test/browser/specs/system-quality.spec.ts` | 27-case connected sweep |
| `test/browser/support/verify-phase82-quality.mjs` | exact static/CI/inventory/exception validator |

### Likely modifications

| File | Required change |
|------|-----------------|
| `assets/oban_powertools/tokens.css` | only defects proven by RED contrast/target/focus/motion/reflow checks |
| packaged CSS | regenerated from source; never edited independently |
| `Primitives`, `Forms`, `DataDisplay`, `OperatorPatterns`, `AppShell` | shared semantic fixes proven to affect multiple surfaces |
| `ControlPlanePresenter` and page presenters | central copy/state corrections without changing authority |
| `scripts/showcase_manifest.exs` / `manifest.ts` | expose/validate copy contract while preserving generated inventory |
| `test/browser/support/axe.ts` | moderate exception gate and complete diagnostics |
| `showcase.a11y.spec.ts` | piggyback mechanical target/contrast/motion/reflow/copy checks |
| Wave 1–3 specs | import strict shared helpers; delete copied weak helpers |
| `page.acceptance.spec.ts` | generic confirmation/recovery ordering and finite copy contract |
| `package.json` / CI validator / `.github/workflows/ci.yml` | exact required ordering and artifacts |
| theme/assets/catalog/docs contract tests | fail-closed source/package/inventory proof |

### Files that should not change

- domain mutation modules, schemas, migrations, route shapes, permission names;
- page-story IDs/counts except to correct a proven false story (Phase 83 owns
  missing-story expansion);
- dependencies;
- Phase 83 contributor documentation;
- baseline images when no visual repair occurred.

## Wave 0 Tests

Write these before implementation:

1. RED contrast unit fixtures: alpha composition, normal/large thresholds,
   muted hard floor, non-text boundary, high-contrast 7:1, unrounded failure,
   unknown gradient fail-closed.
2. RED target geometry fixtures: 24×24 pass, both-axis undersize, spaced
   undersize, intersecting circles, collision with large target, inline
   exception, stale/unknown exception, 44px comfort and overlap.
3. RED focus fixtures: viewport intersection, sticky full occlusion, partial
   visibility, modal overlay, 2px outline, adjacent contrast, detached focus,
   restoration fallback.
4. RED overflow fixtures: document/root/body overflow, allowed labelled machine
   scroller, unnamed scroller, ordinary control inside scroller, duplicate
   responsive tree, 200% restoration.
5. RED motion fixtures: raw timing, missing easing token, unknown keyframe,
   missing media reduction, missing explicit-root reduction, hidden content,
   delayed focus/action.
6. RED copy fixtures: forbidden phrase, synonym drift, ambiguous dismiss,
   missing confirmation section/order, empty without next action, loading
   without resource, error without recovery, overclaimed receipt, stale unused
   exception.
7. RED manifest/route fixtures: missing target, duplicated target, missing page
   family route, extra route family, hard-coded browser target list.
8. RED CI mutations: omitted/reordered/filtered/duplicated spec, update mode,
   ignored failure, detached required job.

No framework-install Wave 0 task exists.

## Recommended Sequencing

1. **Contracts and shared auditors:** add RED fixtures and the reusable
   TypeScript/Elixir seams.
2. **Contrast/focus/target token closure:** repair shared tokens and primitives,
   rebuild assets, run focused component browser tests.
3. **Motion and reflow closure:** exact CSS inventory, both reduction paths,
   exhaustive target geometry piggybacked on axe.
4. **Copy closure:** production copy registry, source scan, shared
   confirmation/state repairs, rendered scans.
5. **Connected nine-page sweep:** factor strict helpers into Wave 1–3 journeys
   and add exact 27-case cross-cutting spec.
6. **CI/evidence closure:** exact order validator, mutation tests, reports,
   compare-only artifacts, VoiceOver discovery.
7. **Full validation:** format, warnings-as-errors, focused suites, exact
   validators, source/package equality, `verify:pages`, full visual/a11y,
   VoiceOver where supported, full ExUnit.

## Architecture Patterns

### Generated inventory, executable policy

```text
Elixir catalogs + Copy contract
              |
              v
      schema-8 manifest
              |
       +------+-------+
       |              |
 showcase exhaustive  connected nine-family map
       |              |
       +------v-------+
      shared auditors
       | axe | contrast | target | focus
       | reflow | motion | copy
              |
              v
       exact required CI
```

### Repair the owner, not the symptom

- token ratio fails across themes → token;
- every dialog focus fails → `OperatorPatterns`/JS;
- all row actions are small → shared table/action component;
- one page has unique overflow → page composition;
- repeated recovery text drifts → Copy/presenter;
- one domain consequence is inaccurate → page presenter, not generic Copy.

### Do not hand-roll

- a second story/target array;
- pixel screenshot contrast sampling when computed CSS colors are available;
- a custom accessibility tree instead of semantic HTML + axe/ARIA/VoiceOver;
- a new dialog trap, focus stack, theme engine, responsive DOM, or status
  taxonomy;
- a regex-only CSS parser for nested at-rules if an existing project parser or
  deterministic declaration extractor can safely handle the source;
- retries or sleeps to make focus/motion tests pass;
- manual exception prose without executable scope and expiry.

## Threat and Risk Analysis

| Threat | Failure mode | Required mitigation |
|--------|--------------|---------------------|
| False-green inventory | browser check silently omits targets/routes | derive showcase from manifest; assert route keys exactly equal nine manifest families |
| CI bypass | new spec exists but is filtered/detached/optional | exact command/YAML parser plus mutation tests and direct `ci-gate` dependency |
| Exception laundering | broad axe/target/copy exception hides future regressions | exact rule+target+owner+expiry+compensating test; unused/stale exceptions fail |
| Artifact tampering | update-mode output reported as verification | validators reject update/watch modes; fresh compare-only run required |
| Secret disclosure | fixture credentials/reasons appear in reports | structured summaries only; reuse browser-channel sentinel scan; never attach DOM dumps containing secrets |
| DOM denial of service | exhaustive scans repeatedly walk all 163-story hidden DOM trees | scope to activated target/stage, bound nodes/diagnostics, reuse prepared page |
| Geometry spoofing | hidden/zero-size/covered elements satisfy target/focus checks | computed visibility, rect, hit testing, enabled state, activeElement, overlay detection |
| Color parser ambiguity | gradient/alpha/inherited background produces guessed pass | alpha-compose; fail closed on unknown/gradient adjacency |
| Mutation authority drift | accessibility helper activates unsafe operations | connected map defines safe journeys; existing server fixture/domain tests own mutations |
| Copy leak/overclaim | generic repair exposes provider/raw truth or promises host outcome | closed presenter maps, source/render scans, existing confidentiality sentinels |
| Asset split-brain | source fixed but shipped CSS stale | build task, byte equality, repeated-build stability |
| Cross-test contamination | zoom/theme/root-motion state leaks | restore CDP/media/root attributes in `finally`; serial fixture ownership |

## Security Domain

`security_enforcement: true` — this phase touches merge-blocking evidence and
connected authenticated routes even though it adds no product authority.

| ASVS category | Applies | Control |
|---------------|---------|---------|
| V1 Architecture | Yes | one generated inventory, shared auditors, exact required graph |
| V2 Authentication | Indirect | use existing authenticated fixture actor; no bypass/showcase substitute |
| V3 Session | Indirect | do not persist fixture secret, reason, or preview identity in browser artifacts |
| V4 Access Control | Yes | accessibility tests never become mutation authority; preserve immediate reauthorization |
| V5 Validation/Encoding | Yes | strict manifest schema, closed exception registry, safe selectors, HEEx escaping |
| V7 Error/Logging | Yes | bounded structured diagnostics without raw provider data or secrets |
| V8 Data Protection | Yes | preserve confidentiality scans across DOM, URL, requests, responses, console, reports |
| V10 Malicious Input | Yes | hostile Unicode/RTL/long strings remain escaped and bounded |
| V13 API/Communication | Indirect | existing fixture endpoints stay test-only, secret-gated, POST-only, closed-schema |

## Common Pitfalls

- Treating axe as complete accessibility coverage.
- Rounding a 4.499 or 2.999 ratio up to a pass.
- Measuring only token pairs while rendered alpha/adjacency differs.
- Requiring 44px in one axis and calling that the normative 24×24 test.
- Treating any inline link as automatically exempt.
- Checking focus only with `toBeFocused()` while sticky chrome covers it.
- Testing only `prefers-reduced-motion` while the explicit root mode drifts.
- Running only reduced motion and never inventorying normal motion.
- Adding a second target array to make exhaustive loops easier.
- Scanning the entire showcase DOM instead of the active target, producing
  false copy/geometry findings from hidden stories.
- Centralizing unique consequence text until it becomes vague or untruthful.
- Committing snapshot updates without a later compare-only pass.
- Adding an optional CI job rather than extending the direct required graph.
- Increasing parallel workers against shared mutable fixtures.

## Exact Validation Commands

Focused during implementation:

```bash
mix test test/oban_powertools/web/theme_tokens_test.exs \
  test/oban_powertools/web/assets_test.exs \
  test/oban_powertools/web/copy_contract_test.exs --seed 0

npm run showcase:manifest
node test/browser/support/manifest-smoke.mjs
node test/browser/support/verify-phase82-quality.mjs
node test/browser/support/verify-page-aria-snapshots.mjs
node test/browser/support/verify-page-baselines.mjs
node test/browser/support/verify-page-script-order.mjs

scripts/with-showcase-server.sh npx playwright test \
  test/browser/specs/system-quality.spec.ts --project=chromium-wide
```

Phase completion:

```bash
mix format --check-formatted
MIX_ENV=test mix compile --warnings-as-errors
cmp -s assets/oban_powertools/tokens.css \
  priv/static/oban_powertools/oban_powertools.css
mix test --seed 0
CI=1 npm run verify:pages
CI=1 npm run visual:a11y
npx playwright test --config=voiceover.config.ts --list
```

Run real `npm run verify:voiceover` only on a configured supported macOS
Guidepup/VoiceOver host. Discovery is mandatory everywhere; transcripts may
never be synthesized.

## Environment Availability

Elixir, PostgreSQL-backed tests, Node, Playwright discovery, manifest
generation, exact validators, and asset builds are operational locally.
[VERIFIED: fresh commands]

The full Docker/browser graph was not rerun during research because the Phase
81 ledger records a recent green 2,790-case compare-only run and Phase 82
research is non-implementing. The planner must budget the final graph as a
costly serial gate, not a per-task command. [VERIFIED: `81-VALIDATION.md`]

Real VoiceOver remains platform/setup-dependent. Exact target discovery is
available and currently lists ten tests over all nine page families.
[VERIFIED: fresh `--list`]

## Assumptions Log

| Claim | Confidence | Planning consequence |
|-------|------------|----------------------|
| The 163/99 inventory remains fixed through Phase 82 | HIGH, locked | validators fail if Phase 82 accidentally adds Phase 83 stories |
| Existing action fixtures can drive all required connected recovery states | HIGH | reuse Phase 79–81 fixture controls; add no product endpoint |
| A schema-8 non-inventory copy-contract field is acceptable | MEDIUM | planner may instead render a deterministic contract attribute, but must keep one Elixir owner |
| Piggybacking mechanical checks on axe cases is the best runtime tradeoff | HIGH | avoid a second 1,956-case matrix |

## Open Questions — Resolved Inline

1. **Moderate axe findings:** fail by default; only exact expiring executable
   exceptions are accepted.
2. **Contrast scope:** exhaustive axe plus exact semantic token pairs and
   representative rendered component chokepoints; no screenshot pixel sampling.
3. **Target exceptions:** explicit finite registry/data only; never inferred.
4. **Focus obscuration:** actual focused-element hit testing plus fixed/sticky
   overlay diagnostics.
5. **200% coverage:** base all projects; CDP zoom in system/wide per generated
   target and per connected family, restored after each probe.
6. **Copy ownership:** one Elixir production contract exposed to browser
   validation; page-specific truth stays in presenters.
7. **Runtime:** reuse active axe pages and add only 27 connected cases.
8. **VoiceOver:** keep ten exact targets; run real transcripts only where the
   supported macOS setup exists.

## Sources

### Primary — repository (HIGH confidence)

- `82-CONTEXT.md`, `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`
- `guides/brand-book.md`
- Phase 70–81 contexts, UI specs, validations, verifications, UI/security reviews
- `tokens.css`, packaged CSS/JS, shared component and presenter modules
- schema-8 catalogs, manifest generator/validator, exact artifact validators
- Playwright, axe, VoiceOver, Wave 1–3, package-script, and CI sources
- fresh manifest, artifact, discovery, source/package, and focused test results

### Primary — external standards/tool documentation

- W3C WCAG 2.2 normative standard:
  `https://www.w3.org/TR/WCAG22/`
- W3C Understanding 1.4.1 Use of Color:
  `https://www.w3.org/WAI/WCAG22/Understanding/use-of-color`
- W3C Understanding 1.4.3 Contrast Minimum:
  `https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum`
- W3C Understanding 1.4.10 Reflow:
  `https://www.w3.org/WAI/WCAG22/Understanding/reflow`
- W3C Understanding 1.4.11 Non-text Contrast:
  `https://www.w3.org/WAI/WCAG22/understanding/non-text-contrast.html`
- W3C Understanding 2.4.11 Focus Not Obscured:
  `https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum`
- W3C Understanding 2.4.13 Focus Appearance:
  `https://www.w3.org/WAI/WCAG22/Understanding/focus-appearance`
- W3C Understanding 2.5.8 Target Size:
  `https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum`
- W3C Understanding 2.3.3 Animation from Interactions:
  `https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html`
- Playwright accessibility testing and emulation:
  `https://playwright.dev/docs/accessibility-testing`,
  `https://playwright.dev/docs/emulation`
- axe-core official API/tag documentation:
  `https://github.com/dequelabs/axe-core/blob/develop/doc/API.md`

No external source introduced a package recommendation.

## Metadata

**Confidence breakdown:**

- Repository baseline/counts: HIGH — fresh exact commands.
- WCAG numeric algorithms: HIGH — current W3C normative/Understanding sources.
- Axe/Playwright APIs: HIGH — official current documentation and installed code.
- Architecture and CI recommendations: HIGH — direct extension of shipped seams.
- Runtime projection: MEDIUM — exact test cardinality is known, wall-clock impact
  depends on final DOM work and CI host.

**Research date:** 2026-07-29
**Valid until:** 2026-08-28, or until schema-8 inventory, package scripts, or
shared component/token contracts change.
