# Roadmap

## Core Objective

**v2.0 Powertools Identity**: Replace ad-hoc inline Tailwind markup across the 9 `/ops/jobs` LiveViews with a library-owned, isolated, themeable Powertools design system whose source of truth is a written brand book — proven correct (and kept correct) by a dev-only showcase plus visual-regression and automated-a11y harnesses that make every future change forward-only and regression-gated.

## Phases

- [x] **Phase 70: Brand Book & Identity Foundation** — Author the brand book as the single source of truth for all visual/verbal decisions. (completed 2026-06-18)
- [x] **Phase 71: Token Layer & Isolated Theming Engine** — Ship the library-owned `--obpt-*` token layer + precompiled CSS asset + dark/light/system (system default), zero leakage. (completed 2026-06-18)
- [x] **Phase 72: Stress Fixtures & Showcase Skeleton** — Deterministic dev/test fixtures + the dev-only `/ops/jobs/_showcase` with theme + viewport switchers. (completed 2026-06-19)
- [x] **Phase 73: Visual-Regression & A11y Harness** — Playwright snapshots + axe gate in CI, established *before* any page changes. (completed 2026-06-19)
- [x] **Phase 74: Primitives Library** — Token-driven `Phoenix.Component` primitives as showcase stories under VRT/a11y. (completed 2026-07-11)
- [x] **Phase 75: Form Components** — Accessible form primitives on `to_form`. (completed 2026-07-11)
- [x] **Phase 76: Navigation & App Shell** — Responsive Powertools shell (header, nav, theme toggle, actor). (completed 2026-07-12)
- [x] **Phase 77: Data-Display & Operator Patterns** — Shared data components + unified status taxonomy. *[split-risk]* — verification gap closure required (completed 2026-07-13)
- [x] **Phase 78: Component Groups (Meta-Components)** — Operator meta-patterns encapsulating "explain, then act". (completed 2026-07-19)
- [ ] **Phase 79: Page Migration Wave 1** — Overview, Cron, Limiters, Audit.
- [ ] **Phase 80: Page Migration Wave 2** — Jobs + Forensics. *[split-risk]*
- [ ] **Phase 81: Page Migration Wave 3** — Batches, Workflows, Lifeline. *[split-risk]*
- [ ] **Phase 82: Cross-Cutting A11y/Motion/Responsive Sweep** — System-wide AA + reduced-motion + 320→wide + microcopy closure.
- [ ] **Phase 83: Showcase Completion & Documentation** — Full showcase coverage + design-system/idempotency docs.
- [ ] **Phase 84: v2.0 Milestone Audit & Idempotency Proof** — Trace every REQ to shipped behavior + prove forward-only idempotency.

## Phase Details

> Every phase ends with a **deep-research input** (subagent research per decision: idiomatic Elixir/Phoenix, ecosystem lessons right+wrong, DX, UX/JTBD/user-psychology, brand alignment) and an **adversarial-judge review** at its level of abstraction.

### Phase 70: Brand Book & Identity Foundation

**Goal**: Author the brand book as the single source of truth for all later visual/verbal decisions.
**Depends on**: — (root)
**Requirements**: BRAND-01, BRAND-02, BRAND-03, BRAND-04, BRAND-05, DOC-03 (initial)
**Success Criteria** (what must be TRUE):

  1. A versioned brand book exists in-repo and renders at a dev route; it covers essence/positioning, the color story (light/dark/high-contrast with contrast targets), type/space/radii/elevation, motion principles, voice/microcopy, and IA principles.
  2. Every planned token category has a named brand decision behind it (traceability table).
  3. The "explain, then act" principle and danger/confirmation voice are codified as enforceable rules.
  4. No code/UI changes to the 9 pages (brand book is documentation + intent).

**Plans**: 2 plans

- [x] 70-01-PLAN.md — Author guides/brand-book.md (all 22 decisions + BRAND-05 traceability table) + content-assertion harness + HexDocs registration (wave 1)
- [x] 70-02-PLAN.md — Dev-only BrandBookLive route + zero-dep Markdown render + dev/test config + render & prod-exclusion checks + README link (wave 2)

### Phase 71: Token Layer & Isolated Theming Engine

**Goal**: Ship the library-owned, namespaced, self-contained token + theming layer (light/dark/system; system default).
**Depends on**: Phase 70
**Requirements**: TOKEN-01, TOKEN-02, TOKEN-03, TOKEN-04, TOKEN-05, MOTION-01, A11Y-03 (contrast tokens)
**Success Criteria** (what must be TRUE):

  1. All brand-book values exist as two-tier `--obpt-*` CSS custom properties under `.obpt-root`; the library ships its own compiled CSS asset (Plug-served, md5-hashed, immutable) independent of the host Tailwind build.
  2. Light/dark/high-contrast themes resolve from tokens; **system is default**; explicit choice persists under a namespaced key; `prefers-reduced-motion`/`prefers-color-scheme` honored.
  3. No style leakage in or out of the namespace, proven against `examples/phoenix_host` (host pages outside `/ops/jobs` unchanged; `<html>`/host storage untouched).
  4. The asset build is byte-stable on re-run; theme switch causes no FOUC/layout shift. A proof seam (`jobs_live.ex` badge/tab/modal) is migrated onto tokens to validate end-to-end.

**Plans**: 5/5 plans complete

- [x] 71-01-PLAN.md — Wave 0 validation harness for token/theme/assets/proof-seam/isolation checks (wave 0)
- [x] 71-02-PLAN.md — Scoped token CSS, theme JS, deterministic build task, and compiled assets (wave 1)
- [x] 71-03-PLAN.md — MD5 immutable asset Plug/routes plus `priv` package inclusion (wave 2)
- [x] 71-04-PLAN.md — Powertools ThemeShell live-session integration with `.obpt-root` system default (wave 3)
- [x] 71-05-PLAN.md — JobsLive proof seam and example-host isolation closure (wave 4)

### Phase 72: Stress Fixtures & Showcase Skeleton

**Goal**: Stand up deterministic fixtures + the dev-only showcase shell that hosts the systematic audit, VRT, and a11y scans.
**Depends on**: Phase 71
**Requirements**: FIX-01, FIX-02, FIX-03, SHOW-01 (skeleton), SHOW-02, SHOW-03
**Success Criteria** (what must be TRUE):

  1. A seedable, deterministic, dev/test-only named-scenario catalog covers normal + adversarial states across all domains and per-persona JTBD scenarios; excluded from the hex tarball (verified).
  2. The dev-only `/ops/jobs/_showcase` route renders (initially tokens + theming) with a theme switcher (light/dark/system/high-contrast) and a 320/tablet/wide viewport toggle; it compiles to no route in prod.
  3. The showcase runs from `examples/phoenix_host` with no host changes.

**Plans**: 4 plans

- [x] 72-01-PLAN.md — RED fixture catalog and package exclusion contracts (wave 1)
- [x] 72-02-PLAN.md — RED showcase route, control, selector, and example-host contracts (wave 1)
- [x] 72-03-PLAN.md — Canonical deterministic scenario catalog implementation (wave 2)
- [x] 72-04-PLAN.md — Dev-only showcase LiveView, route, token-backed shell CSS, and final proof gates (wave 3)

### Phase 73: Visual-Regression & A11y Harness

**Goal**: Establish VRT + axe-core a11y gates **before** any page is touched, so every later change is regression-caught.
**Depends on**: Phase 72
**Requirements**: VRT-01, VRT-02, VRT-03, A11Y-01
**Success Criteria** (what must be TRUE):

  1. An external Node Playwright harness snapshots showcase stories across themes × {320, tablet, wide} in a pinned Docker image; baselines are committed; CI fails on unintended diff; baseline update is explicit/reviewable.
  2. An axe-core scan (WCAG 2.2 AA tags, open-state variants) runs over the showcase in CI; 0 critical/serious is merge-blocking.
  3. The harness is hermetic against fixtures (re-run = identical results); animations disabled, timestamps/IDs masked, fonts ready.

**Plans**: 5 plans
**Wave 1**

- [x] 73-01-PLAN.md — Root Node tooling, exact Playwright/axe lockfile, generated showcase manifest, and manifest validation (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 73-02-PLAN.md — Deterministic Playwright config, pinned Docker/example-host runners, and browser structure smoke (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 73-03-PLAN.md — Axe-core serious/critical gate, full JSON artifacts, and narrow current-showcase a11y fixes if needed (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 73-04-PLAN.md — Story-level VRT spec plus 108 Docker-generated committed PNG baselines (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 73-05-PLAN.md — `visual_a11y` CI lane, `ci-gate` fan-in, artifact uploads, and guardrail documentation (wave 5)

### Phase 74: Primitives Library

**Goal**: Build the token-driven primitive components and register them as showcase stories under VRT/a11y.
**Depends on**: Phase 71, Phase 73
**Requirements**: COMP-01, COMP-02, COMP-03, COMP-04, MOTION-02, A11Y-02, SHOW-01 (primitive stories)
**Success Criteria** (what must be TRUE):

  1. Primitives (Button, Icon button, Link, Badge/Tag/StatusPill, Card/Surface, Divider, Spinner/Skeleton, Tooltip, Kbd, Stat) ship as `Phoenix.Component`s, tokens-only, with documented attrs/slots — only those the 9 pages use.
  2. Each primitive is keyboard-operable, SR-correct, renders in all themes and at 320px, has showcase stories, and passes the VRT + a11y gates.
  3. No raw hex/px in primitive source (lint/grep clean).

**Plans**: 5/5 plans complete
**Wave 1**

- [x] 74-01-PLAN.md — Primitive component API and ExUnit contract tests (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 74-02-PLAN.md — Token-only primitive CSS, tooltip behavior, and compiled assets (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 74-03-PLAN.md — Primitive story catalog and showcase rendering (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 74-04-PLAN.md — Unified Playwright manifest and VRT/a11y target integration (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 74-05-PLAN.md — Primitive behavior checks, VRT baselines, and full gate closure (wave 5)

### Phase 75: Form Components

**Goal**: Build accessible form primitives on `Phoenix.Component`/`to_form`, as showcase stories.
**Depends on**: Phase 74
**Requirements**: FORM-01, FORM-02, COMP-* (form set), A11Y-02
**Success Criteria** (what must be TRUE):

  1. Input/Textarea/Select/Checkbox/Radio/Switch/Combobox/FieldGroup/Label/Hint/Error ship, tokens-only.
  2. Every field has a programmatic label + error association + visible focus; disabled vs read-only are distinct; validation never relies on color alone; passes the a11y gate.
  3. Stories cover valid/invalid/disabled/loading across themes; VRT green.

**Plans**: 6/6 plans complete
**Wave 1**

- [x] 75-01-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 75-02-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 75-03-PLAN.md

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 75-04-PLAN.md

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 75-05-PLAN.md

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 75-06-PLAN.md

### Phase 76: Navigation & App Shell

**Goal**: Build the responsive Powertools app-shell (header, nav across 9 surfaces, theme toggle, actor/context).
**Depends on**: Phase 74
**Requirements**: NAV-01, NAV-02, NAV-03, NAV-04, A11Y-02, COPY-* (nav labels)
**Success Criteria** (what must be TRUE):

  1. The shell component owns header/nav/theme-toggle/actor display; mobile-first, collapsible below breakpoint, no horizontal scroll at 320px.
  2. Active-route + breadcrumb + skip-to-content + logical focus order; a11y gate green.
  3. The shell has a showcase story across themes/viewports; VRT green.

**Plans**: 5/5 plans complete
**Wave 1**

- [x] 76-01-PLAN.md — RED AppShell render, layout/current-path, catalog, and browser behavior contracts (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 76-02-PLAN.md — AppShell component API, closed nine-surface nav model, ThemeShell integration, and LiveAuth current-path assigns (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 76-03-PLAN.md — Scoped AppShell CSS, disclosure JS, compiled assets, and static asset guards (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 76-04-PLAN.md — Shell story catalog, showcase rendering, schema 4 manifest, and shell target support (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 76-05-PLAN.md — Shell browser behavior proof, VRT baselines, a11y evidence, and validation closeout (wave 5)

### Phase 77: Data-Display & Operator Patterns

**Goal**: Build shared data-display components and unify the status taxonomy. *[split-risk: DataTable + args/redaction viewer may each warrant a plan]*
**Depends on**: Phase 74, Phase 75
**Requirements**: DATA-01, DATA-02, DATA-03, DATA-04, A11Y-02
**Success Criteria** (what must be TRUE):

  1. DataTable (sort/empty/loading/error), KeyValue/DescriptionList, StatusPill (unified taxonomy), Timeline, ProgressBar, MetricCard, CodeBlock/args-viewer with redaction overlay, EmptyState, Toast/Flash ship.
  2. One StatusPill maps every Oban/Powertools state; tables degrade to stacked/card at 320px; explicit empty/loading/unavailable/permission-denied everywhere; long IDs/module names/stacktraces handled.
  3. Redaction is rendered through one shared component; stories + VRT + a11y green over stress fixtures (huge args, thousands of rows).

**Plans**: 9/9 plans complete
**Wave 1**

- [x] 77-01-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 77-02-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 77-03-PLAN.md

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 77-04-PLAN.md

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 77-05-PLAN.md

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 77-06-PLAN.md

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 77-07-PLAN.md

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 77-08-PLAN.md — Close Phoenix flash per-item dismissal/severity and nil-progress semantics gaps (wave 8)

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 77-09-PLAN.md — Make the optional data story catalog fail closed at the Hex package boundary (wave 9)

### Phase 78: Component Groups (Meta-Components)

**Goal**: Assemble operator meta-patterns that encapsulate "explain, then act" + preview/reason/audit.
**Depends on**: Phase 76, Phase 77
**Requirements**: GROUP-01, GROUP-02, FORM-04, COPY-02, A11Y-02
**Success Criteria** (what must be TRUE):

  1. ConfirmActionDialog (dry-run→reason→confirm→result), FilterBar, DetailDrawer/Panel, AttentionCard, AuditEntry, and "Why blocked?" Explainer ship from primitives + data components.
  2. The danger pattern enforces a required reason + consequence/scope copy; a11y (focus trap, Esc, SR announcements, focus restore) green.
  3. Stories + VRT cover each group; pages will compose these, not re-implement.

**Plans**: 8/8 plans complete

- [x] 78-01-PLAN.md
- [x] 78-02-PLAN.md
- [x] 78-03-PLAN.md
- [x] 78-04-PLAN.md
- [x] 78-05-PLAN.md
- [x] 78-06-PLAN.md
- [x] 78-07-PLAN.md
- [x] 78-08-PLAN.md

### Phase 79: Page Migration Wave 1 — Overview, Cron, Limiters, Audit

**Goal**: Migrate the four lighter LiveViews onto shell + primitives + groups with zero behavior regression.
**Depends on**: Phase 78
**Requirements**: PAGE-01, PAGE-05, PAGE-06, PAGE-08, PAGE-10, COPY-01, A11Y-*, MOTION-*
**Success Criteria** (what must be TRUE):

  1. Each page is rebuilt on the shell/components; all existing tests stay green; URLs/actions/audit unchanged.
  2. Each page passes the VRT + a11y gates across themes × breakpoints over fixtures.
  3. Concepts shared with other pages render identically (consistency check).

**Plans**: 4/12 plans executed
**Wave 1**

- [x] 79-01-PLAN.md
- [x] 79-09-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 79-02-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 79-03-PLAN.md
- [ ] 79-04-PLAN.md
- [ ] 79-05-PLAN.md
- [ ] 79-06-PLAN.md

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 79-07-PLAN.md
- [ ] 79-10-PLAN.md
- [ ] 79-11-PLAN.md

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 79-12-PLAN.md

**Wave 6** *(blocked on Wave 5 completion)*

- [ ] 79-08-PLAN.md

### Phase 80: Page Migration Wave 2 — Jobs, Forensics

**Goal**: Migrate the data-dense jobs + forensics surfaces (filter bars, big tables, detail/timeline). *[split-risk: jobs likely its own plan, forensics another]*
**Depends on**: Phase 79
**Requirements**: PAGE-02, PAGE-09, FORM-03, DATA-*, PAGE-10, A11Y-*
**Success Criteria** (what must be TRUE):

  1. Jobs + forensics are rebuilt on FilterBar/DataTable/DetailDrawer/Timeline; URL-serialized filter state preserved; all tests green.
  2. VRT + a11y green over adversarial fixtures (thousands of rows, redacted args, deep timelines).
  3. No functional regression in filter/search/bulk/deep-link behavior.

**Plans**: TBD

### Phase 81: Page Migration Wave 3 — Batches, Workflows, Lifeline

**Goal**: Migrate the three richest operator/repair surfaces (progress, DAG/blocked-state, repair dry-run flows). *[split-risk: three large files; lifeline's repair flow is the single riskiest unit — likely 3 plans]*
**Depends on**: Phase 80
**Requirements**: PAGE-03, PAGE-04, PAGE-07, GROUP-*, PAGE-10, A11Y-*, MOTION-*
**Success Criteria** (what must be TRUE):

  1. Batches, workflows, and lifeline are rebuilt on the shell/groups; the Lifeline-routed preview→reason→execute→audit flows are unchanged; all tests green.
  2. "Why blocked?" and dry-run-repair patterns render via shared groups; a11y green (focus/announcements in dialogs).
  3. VRT green across themes/breakpoints over stress fixtures (saturated limiters, deep workflows, stuck callbacks).

**Plans**: TBD

### Phase 82: Cross-Cutting A11y, Motion & Responsive Hardening Sweep

**Goal**: System-wide sweep to close any AA gaps, motion/reduced-motion correctness, and 320→wide responsiveness left after migration.
**Depends on**: Phase 81
**Requirements**: A11Y-01, A11Y-02, A11Y-03, A11Y-04, MOTION-01, MOTION-02, NAV-02, DATA-03 (final), COPY-01, COPY-02 (final)
**Success Criteria** (what must be TRUE):

  1. 0 critical/serious axe violations across all 9 pages + showcase; AA contrast verified light/dark; high-contrast enhanced ratios met; target size (2.5.8) and focus-not-obscured (2.4.11) checked.
  2. Reduced-motion disables non-essential animation everywhere without hiding content; no motion blocks action.
  3. Full keyboard traversal of every page; no horizontal scroll at 320px anywhere.
  4. A microcopy consistency audit passes against the BRAND-04 voice.

**Plans**: TBD

### Phase 83: Showcase Completion & Documentation

**Goal**: Complete the showcase (every component + page-pattern story) and write the design-system + idempotency-guardrail docs.
**Depends on**: Phase 82
**Requirements**: SHOW-01 (full), DOC-01, DOC-02, DOC-03, COPY-01 (centralized)
**Success Criteria** (what must be TRUE):

  1. The showcase renders every token/primitive/form/data/group/page-pattern with all variants and the theme + viewport switcher; it is the canonical audit surface.
  2. A contributor guide documents the token contract, the "no raw values" lint, how to add/extend a component, and theming rules.
  3. The idempotency guardrails (VRT snapshots, a11y gate, token byte-stability, forward-only quality) are documented; the brand book is linked from the README.

**Plans**: TBD

### Phase 84: v2.0 Identity Milestone Audit & Idempotency Proof

**Goal**: Prove the milestone is complete, regression-free, and re-runnable; close v2.0.
**Depends on**: Phase 83
**Requirements**: all categories (verification), DOC-02 (proof)
**Success Criteria** (what must be TRUE):

  1. Every REQ-ID traces to shipped behavior + a passing test/gate; the full suite is green.
  2. CI proves the idempotency contract: re-running the asset build is byte-stable, VRT baselines match with no `--update-snapshots`, the a11y gate is green, and the "no raw values" lint is clean.
  3. The milestone audit (adopter-first "done" lens) passes; overbuilding watch-out items are reviewed and explicitly accepted/deferred.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 70. Brand Book & Identity Foundation | 2/2 | Complete    | 2026-06-18 |
| 71. Token Layer & Isolated Theming Engine | 5/5 | Complete    | 2026-06-18 |
| 72. Stress Fixtures & Showcase Skeleton | 4/4 | Complete    | 2026-06-19 |
| 73. Visual-Regression & A11y Harness | 5/5 | Complete   | 2026-06-19 |
| 74. Primitives Library | 5/5 | Complete    | 2026-07-11 |
| 75. Form Components | 6/6 | Complete    | 2026-07-11 |
| 76. Navigation & App Shell | 5/5 | Complete    | 2026-07-12 |
| 77. Data-Display & Operator Patterns | 9/9 | Complete    | 2026-07-13 |
| 78. Component Groups (Meta-Components) | 8/8 | Complete    | 2026-07-19 |
| 79. Page Migration Wave 1 | 4/12 | In Progress|  |
| 80. Page Migration Wave 2 | 0/TBD | Not started | — |
| 81. Page Migration Wave 3 | 0/TBD | Not started | — |
| 82. Cross-Cutting A11y/Motion/Responsive Sweep | 0/TBD | Not started | — |
| 83. Showcase Completion & Documentation | 0/TBD | Not started | — |
| 84. v2.0 Milestone Audit & Idempotency Proof | 0/TBD | Not started | — |

## Sequencing Rationale

- **Brand book first (70):** it is the "Identity" and the source every token cites.
- **Tokens before all visuals (71):** primitives/forms/data/pages consume tokens; the isolated theming engine is the load-bearing foundation and theming-idempotency keystone.
- **Fixtures + showcase (72) and VRT + a11y harness (73) BEFORE any page (74+):** the systematic audit needs a surface fed by realistic data, and the regression gates must be live in CI before mass page changes — the structural guarantee of "quality only forward, no regressions."
- **Primitives → forms → shell → data → groups (74–78):** strict bottom-up; groups are assembled from primitives/data, pages compose groups.
- **Pages in three waves, light → heavy (79–81):** validate the migration recipe on cheap pages, then apply to the behavior-critical 47/51/58KB repair surfaces last (highest operator-trust risk).
- **Cross-cutting sweep (82) after migration; docs + audit last (83–84).**

## Idempotency Guardrails

Byte-stable token/asset build (71) · committed VRT snapshots, CI fails on diff (73) · axe gate 0 critical/serious merge-blocking (73) · "no raw values" lint on components (74+) · per-page adversarial regression review (79–81) · end-to-end idempotency re-run proof (84).
