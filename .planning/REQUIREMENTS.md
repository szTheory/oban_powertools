# Requirements — v2.0 Powertools Identity

**Defined:** 2026-06-18
**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

## Milestone Goal

Give Oban Powertools a coherent visual + verbal identity (a written brand book) and re-found the entire `/ops/jobs` operator UI on a library-owned, isolated, themeable design system — tokens → primitives → patterns → pages — with dark/light/system theming, WCAG 2.2 AA accessibility, mobile-first responsiveness, purposeful motion, and on-brand microcopy. This is a coherence/quality milestone, **not** new operator capability, built so improvement is **idempotent** (re-runnable, forward-only, regression-gated). Every decision is backed by deep per-phase subagent research (idiomatic Elixir/Phoenix, ecosystem lessons, DX, UX/JTBD) and an adversarial-judge review at its level of abstraction.

## v2.0 Requirements

### Brand Book / Identity (BRAND)

- [x] **BRAND-01**: A versioned brand book exists in-repo (Markdown + a dev-rendered route) defining brand essence, positioning, and the "explain, then act" operator-UX principle as the design north star.
- [x] **BRAND-02**: The brand book defines the full color story (semantic roles: surface/elevated/border/text/muted/accent/info/success/warning/danger) for light, dark, and high-contrast, each with documented contrast ratios.
- [x] **BRAND-03**: The brand book defines typography scale, spacing/rhythm, radii, elevation/shadow, iconography rules, and motion principles (purposeful, interruptible, reduced-motion-safe).
- [x] **BRAND-04**: The brand book defines voice & microcopy rules (operator tone, danger/confirmation language, empty/error/loading copy, plain-language IA).
- [x] **BRAND-05**: Every later token/component traces back to a named brand-book decision (traceability table — no orphan styles).

### Tokens & Theming (TOKEN)

- [x] **TOKEN-01**: A single library-owned token layer (two-tier `--obpt-*` CSS custom properties: primitive palette → semantic roles) is the only source of color/space/type/radii/elevation/motion values; no raw hex/px in components.
- [x] **TOKEN-02**: The theme is scoped to a Powertools namespace root (`.obpt-root`, preflight disabled, `obpt:` utility prefix) so it cannot leak into or be overridden by host styles, and host styles cannot bleed in.
- [x] **TOKEN-03**: The library ships its own compiled CSS/JS asset (precompiled, md5-hashed, served by a Plug with immutable caching), independent of the host Tailwind build; the host opts in with no Tailwind config changes.
- [x] **TOKEN-04**: Light/dark/system themes work via `data-obpt-theme` on `.obpt-root` (never `<html>`); **system is default**; explicit choice persists under a namespaced `localStorage` key and respects `prefers-color-scheme` and `prefers-reduced-motion`.
- [x] **TOKEN-05**: The token/asset build is idempotent — re-running yields byte-stable output; no FOUC; theme switch causes no layout shift. Token names are treated as a semver-protected public contract.

### Primitives (COMP)

- [x] **COMP-01**: A primitive library exists as documented `Phoenix.Component` function components (Button, Icon button, Link, Badge/Tag/StatusPill, Card/Surface, Divider, Spinner/Skeleton, Tooltip, Kbd, Stat) — only those the 9 pages actually use.
- [x] **COMP-02**: Each primitive has documented attrs/slots, sensible defaults, and renders only via tokens (no raw values — lint/grep clean).
- [x] **COMP-03**: Each primitive is keyboard-operable and screen-reader-correct (roles, accessible names, `focus-visible`), and looks interactive only when interactive.
- [x] **COMP-04**: Each primitive renders correctly in light/dark/high-contrast and at 320px width, with a showcase story per state.

### Form Components (FORM)

- [x] **FORM-01**: Form primitives (Input, Textarea, Select, Checkbox, Radio, Switch, Combobox/filter, FieldGroup, Label, Hint, Error) are built on `Phoenix.Component`/`to_form`, tokens-only.
- [x] **FORM-02**: Every field has a programmatic label, error association (`aria-describedby`), visible focus, and validation that does not rely on color alone; disabled vs read-only are visually distinct.
- [ ] **FORM-03**: Filter/search controls (jobs/forensics) are rebuilt on form primitives with URL-serialized filter state preserved.
- [ ] **FORM-04**: Destructive-action forms (reason + confirm) use the shared danger pattern with required-reason validation and consequence/scope copy.

### Navigation & App Shell (NAV)

- [x] **NAV-01**: A Powertools app-shell component owns the header, primary nav across the 9 surfaces, theme toggle, and actor/context display.
- [x] **NAV-02**: The shell is mobile-first responsive (320px → wide), collapsible at small widths, with no horizontal scroll and no unusable nested scrolling.
- [x] **NAV-03**: Active-route, breadcrumb, and deep-link affordances follow principle-of-least-surprise; nav labels match domain language.
- [x] **NAV-04**: The shell is keyboard-navigable with a skip-to-content link and logical focus order.

### Data Display & Operator Patterns (DATA)

- [ ] **DATA-01**: Shared data-display components exist (DataTable with sort/empty/loading/error states, KeyValue/DescriptionList, Timeline/event log, ProgressBar, MetricCard, CodeBlock/args-viewer with redaction overlay, EmptyState, Toast/Flash).
- [x] **DATA-02**: The status taxonomy is unified across all 9 pages — one StatusPill maps every Oban/Powertools state consistently.
- [x] **DATA-03**: Tables/lists degrade gracefully at 320px (stacked/card fallback); all show explicit empty vs loading vs unavailable vs permission-denied states; long IDs/module names/URLs/stacktraces are handled (truncation + expansion/tooltip).
- [x] **DATA-04**: Redaction/DisplayPolicy presentation is rendered through one shared component (no per-page reinvention).

### Component Groups / Meta-Components (GROUP)

- [ ] **GROUP-01**: Operator meta-patterns are assembled from primitives + data components: ConfirmActionDialog (dry-run → reason → confirm → result), FilterBar, DetailDrawer/Panel, AttentionCard, AuditEntry, "Why blocked?" Explainer.
- [ ] **GROUP-02**: Each meta-component encapsulates the "explain, then act" preview/reason/audit flow so pages compose rather than re-implement; spacing/hierarchy make the next action obvious and groups hold together at narrow/wide widths.

### Pages & Flows (PAGE)

- [ ] **PAGE-01**: Engine Overview migrated to shell + components, zero behavior regression.
- [ ] **PAGE-02**: Jobs (list + detail, filter bar, big table) migrated; URL filter/search/bulk/deep-link behavior preserved.
- [ ] **PAGE-03**: Batches (list + detail, chain steps) migrated; Lifeline-routed recovery unchanged.
- [ ] **PAGE-04**: Workflows (list + detail, DAG/blocked state) migrated.
- [ ] **PAGE-05**: Cron migrated; pause/resume/run preview-confirm flow unchanged.
- [ ] **PAGE-06**: Limiters migrated.
- [ ] **PAGE-07**: Lifeline (incident triage, repair preview/reason/execute/audit) migrated with mutation flow unchanged.
- [ ] **PAGE-08**: Audit migrated; filters/retention controls unchanged.
- [ ] **PAGE-09**: Forensics (bundle inspection, timeline) migrated.
- [ ] **PAGE-10**: Cross-page consistency — identical concepts look and behave identically across all surfaces.

### Accessibility (A11Y)

- [x] **A11Y-01**: Automated a11y checks (axe-core, WCAG 2.2 AA tags, open-state variants) run in CI against the showcase and pages; 0 critical/serious is merge-blocking.
- [x] **A11Y-02**: All interactive elements are keyboard-reachable/operable with visible focus; color is never the sole information carrier; dialogs trap and restore focus and close on Esc.
- [x] **A11Y-03**: Contrast meets AA in light/dark; high-contrast mode meets enhanced ratios; target sizes are comfortable (2.5.8) and focus is not obscured (2.4.11).
- [ ] **A11Y-04**: Reduced-motion preference disables non-essential animation without hiding content; a manual checklist covers what automation can't (focus order, SR-announcement quality, APG patterns).

### Motion (MOTION)

- [x] **MOTION-01**: Motion tokens (duration/easing) live in the token layer; components use them, never inline timings.
- [ ] **MOTION-02**: Transitions are purposeful, interruptible, and reduced-motion-safe; overlays are origin-aware where feasible; no motion blocks operator action or obscures feedback.

### Microcopy / Voice (COPY)

- [ ] **COPY-01**: Empty/loading/error/confirmation copy across all surfaces follows the BRAND-04 voice and is centralized where avoidable (no scattered literals); the same term is used for the same concept everywhere.
- [ ] **COPY-02**: Danger/confirmation language is consistent and unambiguous (names the object, states consequence + scope); error copy says how to recover.

### Component Showcase (SHOW)

- [ ] **SHOW-01**: A dev-only route (`/ops/jobs/_showcase`, compiled out / guarded in prod via `compile_env` + dev/test `elixirc_paths`) renders every token, primitive, form, data, group, and page-pattern with all variants/states, including `*_open` overlay variants for a11y.
- [ ] **SHOW-02**: The showcase has a theme switcher (light/dark/system/high-contrast) and a 320/tablet/wide viewport toggle; it is the canonical surface for the audit, visual-regression, and a11y scans, with stable per-cell `id`/`data-*`.
- [ ] **SHOW-03**: The showcase is host-independent (runs from `examples/phoenix_host` in dev only) and never leaks into a host's production build (proven via tarball check).

### Visual Regression (VRT)

- [x] **VRT-01**: An external Node Playwright harness captures deterministic snapshots of showcase stories across themes × {320, tablet, wide}, run in a pinned Playwright Docker image.
- [x] **VRT-02**: Baselines are committed (component-scoped PNGs); CI fails on unintended visual diff; baseline updates happen only via reviewed `--update-snapshots` commits.
- [x] **VRT-03**: The harness is hermetic against stress fixtures (stable data → stable pixels): animations disabled, timestamps/IDs masked, fonts ready, fixed viewports.

### Stress Fixtures (FIX)

- [ ] **FIX-01**: A deterministic named-scenario catalog (`test/support/showcase_catalog.ex`, dev/test-only) covers normal + adversarial states: empty/one/many, long IDs/module names/URLs, non-ASCII/emoji/RTL, high counts, mixed severity, permission-denied, stale/disconnected, boundary pagination.
- [ ] **FIX-02**: Fixtures are plain structs by default (no DB insert), use constants (not Faker) for anything a screenshot touches, and are the single source of truth shared by showcase + ExUnit + VRT snapshot names + a11y targets.
- [ ] **FIX-03**: Fixtures exercise per-persona JTBD scenarios (triage, incident, repair, audit review) and are excluded from the hex tarball (verified in CI).

### Documentation (DOC)

- [ ] **DOC-01**: A contributor guide documents how to add/extend a component, the token contract, theming rules, and the "no raw values" lint.
- [ ] **DOC-02**: The idempotency guardrails (VRT snapshots, a11y gate, token byte-stability, forward-only quality) are documented as the explicit quality contract.
- [x] **DOC-03**: The brand book is published to the dev-rendered route and linked from the README.

## Future Requirements (deferred)

- QRY-05 (args/meta filter), QRY-06 (real-time live counts / `oban_met` optional read source), QRY-07 (Lifeline→job deep-link), QRY-08 (cross-page select-all), API-03 (`Operator.list/2`) — deferred-until-signal.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New operator capabilities (Chunks, Dynamic Scaler, Relay/Task-await, per-field encryption) | This is a design-system milestone; honor the existing defer-until-signal posture. |
| PhoenixStorybook as a published-library runtime dependency | Wrong ownership boundary, parallel-bundle drift, prod-leak risk, NIF deps. Use a dev-gated custom showcase instead. |
| Hijacking the host's theme (`<html>.dark` / host `localStorage`) | The library must scope to `.obpt-root` and a namespaced storage key; the host owns its own theme. |
| Depending on the host's Tailwind/daisyUI config | The library ships its own precompiled, namespaced CSS. |
| Shipping a custom webfont in the foundation | Weight/complexity not yet justified; use a system font stack, revisit if the brand requires it. |
| Wallaby/playwright-elixir for visual diffing | Capture-only / alpha + bus-factor; no baseline diffing. Use external Node Playwright. |
| "Improving" behavior during a visual migration | Visual refactor must not touch the Lifeline preview/reason/audit flows — behavior parity is required. |

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| BRAND-01..05 | Phase 70 | Complete |
| TOKEN-01..05 | Phase 71 | Complete |
| MOTION-01 | Phase 71 | Complete |
| FIX-01..03 | Phase 72 | Pending |
| SHOW-01..03 | Phase 72 (skeleton), Phase 83 (full) | Pending |
| VRT-01..03 | Phase 73 | Pending |
| A11Y-01 | Phase 73 | Complete |
| COMP-01..04 | Phase 74 | Complete |
| FORM-01, FORM-02 | Phase 75 | Complete |
| NAV-01..04 | Phase 76 | Pending |
| DATA-01..04 | Phase 77 | Pending |
| GROUP-01..02 | Phase 78 | Pending |
| FORM-04 | Phase 78 | Pending |
| PAGE-01, PAGE-05, PAGE-06, PAGE-08 | Phase 79 | Pending |
| PAGE-02, PAGE-09 | Phase 80 | Pending |
| FORM-03 | Phase 80 | Pending |
| PAGE-03, PAGE-04, PAGE-07 | Phase 81 | Pending |
| PAGE-10 | Phases 79–81 | Pending |
| A11Y-02, A11Y-03, A11Y-04 | Phase 82 | Pending |
| MOTION-02 | Phase 82 | Pending |
| COPY-01, COPY-02 | Phase 82 | Pending |
| DOC-01..03 | Phase 83 | Pending |

**Coverage:**

- v2.0 requirements: 56 total across 15 categories
- Mapped to phases: 56
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-18*
*Last updated: 2026-06-18 after milestone v2.0 initialization*
