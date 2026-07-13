---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Identity Milestone Audit & Idempotency Proof
current_phase: 77
current_phase_name: data-display-operator-patterns
status: verifying
stopped_at: Phase 77 verification found 1 gap; plan with /gsd-plan-phase 77 --gaps
last_updated: "2026-07-13T01:33:18.906Z"
last_activity: 2026-07-13
last_activity_desc: Phase 77 re-verification found 1 package-boundary showcase gap
progress:
  total_phases: 15
  completed_phases: 8
  total_plans: 40
  completed_plans: 40
  percent: 53
---

# Project State

## Current Position

Phase: 77 (data-display-operator-patterns) — VERIFICATION GAPS
Plan: 8 of 8
Status: Verification gaps found — gap closure required before Phase 78
Last activity: 2026-07-13 — Phase 77 re-verification found 1 package-boundary showcase gap

## Performance Metrics

| Metric | Target | Current | Notes |
|--------|--------|---------|-------|
| Test Coverage | >95% | - | - |
| Type Checking | 0 Dialyzer errors | 0 | - |
| Linting | 0 Credo warnings | 0 | - |
| Phase 70 Plan 02 | - | ~6m, 4 tasks, 7 files | Brand book dev route + README; 588 tests pass |
| Phase 71 P01 | 7 min | 3 tasks | 4 files |
| Phase 71 P02 | 6 min | 3 tasks | 6 files |
| Phase 71 P03 | 5 min | 2 tasks | 5 files |
| Phase 71 P04 | 4 min | 2 tasks | 2 files |
| Phase 71 P05 | 8 min | 3 tasks | 2 files |
| Phase 73 P01 | 4 min | 2 tasks | 6 files |
| Phase 73 P02 | 18 min | 3 tasks | 7 files |
| Phase 73 P03 | 24 min | 2 tasks | 3 files |
| Phase 73 P04 | 22 min | 2 tasks | 109 files |
| Phase 73 P05 | 34 min | 2 tasks | 5 files |
| Phase 74 P01 | 9 min | 2 tasks | 2 files |
| Phase 74 P02 | 8 min | 2 tasks | 6 files |
| Phase 74 P03 | 6 min | 2 tasks | 4 files |
| Phase 74 P04 | 8 min | 2 tasks | 7 files |
| Phase 75 P01 | 4 min | 1 tasks | 1 files |
| Phase 75 P02 | 4 min | 2 tasks | 3 files |
| Phase 75 P03 | 4 min | 2 tasks | 4 files |
| Phase 75 P04 | 10 min | 2 tasks | 4 files |
| Phase 75 P05 | 35 min | 2 tasks | 110 files |
| Phase 75 P06 | 20 min | 3 tasks | 63 files |
| Phase 76 P01 | 12min | 3 tasks | 5 files |
| Phase 76 P02 | 8m11s | 2 tasks | 5 files |
| Phase 76 P03 | 7m51s | 2 tasks | 6 files |
| Phase 76 P04 | 10 min | 2 tasks | 10 files |
| Phase 76 P05 | 25m23s | 2 tasks | 79 files |
| Phase 77 P01 | 8 min | 4 tasks | 4 files |
| Phase 77 P02 | 7 min | 1 tasks | 4 files |
| Phase 77 P03 | 8 min | 2 tasks | 6 files |
| Phase 77 P04 | 10 min | 2 tasks | 6 files |
| Phase 77 P05 | 43 min | 2 tasks | 6 files |
| Phase 77 P06 | 10 min | 2 tasks | 9 files |
| Phase 77 P07 | 31min | 2 tasks | 129 files |
| Phase 77 P08 | 11 min | 3 tasks | 7 files |

## Accumulated Context

### Roadmap Evolution

- Shipped v1.11 Stability & 1.0 Release Prep; published 1.0.0.
- Executed Post-1.0.0 End-of-Roadmap Assessment. Library is functionally complete for its intended *feature* scope.
- Started v2.0 Powertools Identity — a coherence/quality milestone (brand book + design-system overhaul), not new operator capability. Phases 70–84.

### Architectural Decisions

- **Diminishing Returns:** Do not build Chunks, Dynamic Scaler, Relay/Task-await, or Per-field Encryption unless explicitly demanded by real-world adopters.
- **Library-owned isolated theme (v2.0):** ship precompiled, namespaced CSS/JS via a Plug (LiveDashboard/Oban-Web pattern); scope everything under `.obpt-root` with preflight disabled and `obpt:` prefix; tokens as two-tier `--obpt-*` CSS variables; dark/light/system via `data-obpt-theme` on `.obpt-root` (never `<html>`), system default, namespaced `localStorage`. No host Tailwind dependency.
- **Infra (v2.0):** dev-gated custom showcase route (not PhoenixStorybook dep); external Node Playwright for visual-regression + axe a11y; deterministic stress-fixture catalog. Zero new Hex runtime deps.
- **Brand book (70-01):** authored at `guides/brand-book.md` (v2.0.0-draft, Locked 2026-06-18) encoding all 22 locked decisions D-01..D-22 + a BRAND-05 traceability table; gated by `checks.sh` grep harness; registered under a "Design System" HexDocs extras group. Downstream phases 71–84 cite D-xx for traceability. Requirements BRAND-01..05 complete.
- **Brand book delivery (70-02):** `ObanPowertools.Web.Dev.BrandBookLive` renders `guides/brand-book.md` to HTML at compile time via `EarmarkParser.as_ast/2` + a self-contained AST→HTML walk (zero new runtime deps, zero runtime I/O). Mounted at `/ops/jobs/_brand_book` inside the `oban_powertools_routes/1` macro, gated by `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)` — provably absent under `MIX_ENV=prod`. `dev_routes: true` set in dev+test config; `ex_doc` widened to `only: [:dev, :test]` (still `runtime: false`) so `earmark_parser` compiles the view in test. README "Brand Identity" section links the static guide + dev route (DOC-03 initial). The same compile_env idiom is the template for Phase 72's `/ops/jobs/_showcase`. Requirements DOC-03, BRAND-01 complete.

### Known Technical Debt / Todos

- Migrate `state_badge_class/1`, `state_tab_class/1`, and duplicated modal markup in the 9 LiveViews onto the new tokens/components (proof seam in Phase 71, full migration Phases 79–81).

### Blockers / Open Questions

- None blocking. (Continues to welcome real-world adopter feedback / GitHub issues in parallel.)

## Session Continuity

**Last session:** 2026-07-13T01:17:58.751Z
**Stopped at:** Phase 77 verification found 1 gap; plan with /gsd-plan-phase 77 --gaps
**Resume file:** None

- **Last Action:** Closed WR-01/WR-02 with keyed Phoenix flash dismissal, nonnumeric nil progress, and focused browser/a11y/VRT evidence.
- **Next Action:** Re-verify Phase 77, then begin Phase 78 component-group planning.

## Decisions

- [Phase 75]: Keep all form controls stateless and field-first while allowing explicit identity overrides; use native semantics; centrally filter visual escape hatches. — Preserves parent-owned behavior, accessible native controls, and the scoped token-owned visual contract.
- [Phase 75]: Keep deterministic form evidence in a separate dev/test-only catalog rather than domain stress fixtures. — Preserves production packaging and the domain fixture boundary while providing stable form evidence.
- [Phase 75]: D-25: Browser evidence uses native interaction and generated form metadata across themes and viewports. — Proves component semantics without overclaiming Phase 82 page-level manual accessibility.
- [Phase 75]: Switch state text is CSS-synchronized from the native checkbox state, so browser proof stays tied to real form semantics.
- [Phase 75]: Multi-error fields preserve the single-error `-error` id contract and use indexed ids only when multiple messages render.
- [Phase 75]: Scoped form baselines were refreshed for intentional form changes; scenario baselines remain unchanged until their owning phase.
- [Phase 76]: Plan 76-01 remains RED-only: failures are valid only when they point at missing Phase 76 shell, layout, catalog, or manifest implementation artifacts. — Preserves the plan's test-first purpose without adding production shell behavior early.
- [Phase 76]: The Playwright shell behavior file includes a module-load guard so the RED phase proves the generated manifest must export shellStories before browser evidence can run. — Playwright list mode otherwise passed without touching the missing export.
- [Phase 76]: Primary nav remains a closed nine-surface native model and excludes the optional Oban Web bridge. — Preserves the UI-SPEC native route boundary and avoids adding the optional bridge to primary navigation.
- [Phase 76]: Current route context is assigned centrally through the LiveAuth handle_params hook and consumed by ThemeShell. — Keeps active nav and breadcrumbs server-derived without page-owned shell wiring.
- [Phase 76]: ThemeShell keeps the isolated .obpt-root asset boundary while AppShell owns the inner shell, nav, breadcrumb, and main target. — Maintains library-owned theme isolation and avoids global host theme mutation.
- [Phase 76]: AppShell CSS remains fully scoped under .obpt-root and uses the existing semantic token system for visual values.
- [Phase 76]: Mobile nav disclosure state is represented by data-obpt-nav-state on the owning shell and synchronized with the toggle aria-expanded value.
- [Phase 76]: Theme-choice aria-pressed state is synchronized from the existing root-scoped theme controller so selected theme styling stays programmatic and visual.
- [Phase 76]: Shell stories live in ObanPowertools.ShellStoryCatalog, separate from stress fixtures, primitive stories, and form stories.
- [Phase 76]: Showcase AppShell story cells use story-scoped nav/main ids while production AppShell defaults remain obpt-primary-nav and obpt-main.
- [Phase 76]: Manifest schema 4 appends generated shell_stories after form_stories and keeps shell ids Elixir-owned.
- [Phase 76]: Phase 76 shell VRT baselines use the Docker-backed Playwright runner as canonical evidence because npm run vrt:update writes baselines through scripts/playwright-docker.sh.
- [Phase 76]: Phase 76 shell structure proof uses target-kind-inclusive test titles so focused --grep shell commands select existing structure coverage.
- [Phase 77]: Keep status lookup string-keyed while using only compile-time atom literals for all_specs/0 audit records. — Accepts external binary states without atom growth while retaining ergonomic deterministic audit records.
- [Phase 77]: Require a closed status domain and render unknown states as deterministic neutral humanized values within that domain. — Colliding state names have domain-specific meaning, while known-domain unknowns still need truthful stable presentation.
- [Phase 77]: Filter action, visual, title, and semantic override attributes before delegating StatusPill presentation to Primitives. — Keeps the wrapper non-interactive and prevents caller attributes from hiding or misrepresenting status semantics.
- [Phase 77]: Keep exactly one semantic table tree at every viewport and expose mobile labels inside each original data cell. — Avoids duplicate controls, ids, and sensitive values while preserving table semantics.
- [Phase 77]: Keep DataTable sorting parent-owned and emit only the configured event plus opaque sort key. — Preserves stateless presentation and truthful parent-controlled aria-sort state.
- [Phase 77]: Derive responsive selection and action targets from existing spacing tokens and leave packaged JavaScript unchanged. — Meets the 44px accessibility target without introducing table behavior or raw dimensions.
- [Phase 77]: Compose the shared EmptyState only for the explicit empty data category. — Loading, error, unavailable, and permission boundaries require their own truthful status semantics.
- [Phase 77]: Use native progress with visible count and percentage, without inline width or animated value styling. — Preserves native range semantics and the token-owned no-inline-style boundary.
- [Phase 77]: Treat toast tone and urgency separately. — Warning and danger content becomes an alert only when the caller marks the message immediate.
- [Phase 77]: Read normalized map fields with fetch semantics and never project payloads for unavailable or redacted maps. — False availability is security-significant and must remain distinct from a missing key.
- [Phase 77]: Constrain fallback redaction to exact visible [redacted] copy. — Caller-provided fallback text must not become a disclosure channel.
- [Phase 77]: Limit new internal data-display scrolling to the labelled focusable CodeBlock region. — Machine content may scroll without making ordinary data surfaces or the page overflow.
- [Phase 77]: Keep data-display evidence in a separate dev/test support catalog loaded through the compile-gated showcase. — Preserves production packaging and deterministic normalized-only fixture boundaries.
- [Phase 77]: Keep DataTable stateless while ShowcaseLive owns the finite sort key and direction used for browser proof. — Keeps aria-sort truthful without moving presentation state into the shared component or packaged JavaScript.
- [Phase 77]: Manifest schema 5 derives data stories from Elixir and appends them after shell targets. — Keeps one story-ID source while generic browser structure, axe, VRT, and behavior consumers use validated generated metadata.
- [Phase 77]: Require LiveView connection readiness before browser interaction evidence. — Rendered controls are not truthful behavior proof until server-owned events can reach ShowcaseLive.
- [Phase 77]: Derive canonical data baseline equality and change scope independently from schema-5 manifest metadata. — Separating set equality from Git scope prevents discovery-only and aggregate-green false claims.
- [Phase 77]: Keep Phase 77 visual completion limited to exactly 120 data baselines. — The 108 scenario-only residual remains outside this phase and continues to block a global aggregate-green claim.
- [Phase 77]: Canonicalize flash atom/binary aliases to strings, prefer binary aliases, and derive stable DOM ids from URL-safe Base64 keys. — Preserves Phoenix-native per-item dismissal without runtime atom creation or identity collisions.
- [Phase 77]: Treat omitted or nil progress as no measurement and render only the unavailable branch. — Prevents fabricated zero counts and percentages while retaining optional API compatibility.

### Blockers

- Aggregate visual:a11y retains 108 scenario-only VRT baseline failures; all Phase 75 form cases pass.
