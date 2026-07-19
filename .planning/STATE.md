---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Identity Milestone Audit & Idempotency Proof
current_phase: 79
current_phase_name: page-migration-wave-1-overview-cron-limiters-audit
status: executing
stopped_at: Completed 79-05-PLAN.md
last_updated: "2026-07-19T21:01:26.800Z"
last_activity: 2026-07-19
last_activity_desc: Completed Phase 79 Plan 05 limiter scan and current-evidence migration
progress:
  total_phases: 15
  completed_phases: 9
  total_plans: 61
  completed_plans: 55
  percent: 60
---

# Project State

## Current Position

Phase: 79 (page-migration-wave-1-overview-cron-limiters-audit) — EXECUTING
Plan: 6 of 12
Status: Ready to execute
Last activity: 2026-07-19 — Completed Phase 79 Plan 05 limiter scan and current-evidence migration

## Performance Metrics

| Metric | Target | Current | Notes |
|--------|--------|---------|-------|
| Test Coverage | >95% | - | - |
| Type Checking | 0 Dialyzer errors | 0 | - |
| Linting | 0 Credo warnings | 0 | - |
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
| Phase 77 P09 | 6 min | 2 tasks | 3 files |
| Phase 78 P01 | 22 min | 4 tasks | 7 files |
| Phase 78 P02 | 12 min | 3 tasks | 10 files |
| Phase 78 P03 | 27 min | 3 tasks | 9 files |
| Phase 78 P04 | 15 min | 3 tasks | 7 files |
| Phase 78 P05 | 16 min | 3 tasks | 9 files |
| Phase 78 P06 | 24 min | 4 tasks | 12 files |
| Phase 78 P07 | 39 min | 3 tasks | 1 files |
| Phase 78 P08 | 1h 27m | 3 tasks | 284 files |
| Phase 79 P01 | 23 min | 2 tasks | 9 files |
| Phase 79 P09 | 7 min | 1 tasks | 3 files |
| Phase 79 P02 | 15 min | 3 tasks | 3 files |
| Phase 79 P03 | 13 min | 2 tasks | 3 files |
| Phase 79 P04 | 17 min | 3 tasks | 2 files |
| Phase 79 P05 | 14 min | 2 tasks | 4 files |

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

**Last session:** 2026-07-19T21:01:26.796Z
**Stopped at:** Completed 79-05-PLAN.md
**Resume file:** None

- **Last Action:** Completed Plan 79-05's batched limiter scan and current-before-history evidence composition.
- **Next Action:** Execute Plan 79-06 to migrate Audit to a bounded scan and URL-owned immutable evidence detail.

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
- [Phase 77]: Classify only list-valued optional data story catalogs as available, seed only map-valued flash fixtures, and test the package boundary in fresh child VMs with catalog-free application ebins. — Preserves the deliberate test-support boundary, prevents malformed enumeration/injection, and avoids async module-purge races.
- [Phase 78]: Keep Wave 0 strictly RED-only; later Phase 78 waves own all production components, presenter symbols, catalog, manifest support, browser helpers, and baselines. — Preserves test-first seams and makes every failure attributable to a missing phase-owned artifact.
- [Phase 78]: Use exact string-valued phase78_slice tags for incremental component and connected-harness waves, with unfiltered gates deferred until Plan 78-05. — Lets each implementation wave prove only its owned state machine without weakening the complete six-component contract.
- [Phase 78]: Derive group browser behavior and exactly 276 baseline paths from future schema-6 groupStories rather than duplicating the 23 Elixir-owned story IDs in TypeScript. — Maintains one story-ID source and independently checks missing, extra, tracked, untracked, and renamed screenshot scope.
- [Phase 78]: Normalize operator presentation through finite closed projections before rendering. — Stable IDs, explicit missing evidence, and finite aliases keep components truthful and redaction-safe.
- [Phase 78]: Keep persistent attention role-free by default and separate severity from domain status. — Visible non-color severity remains accessible without forcing disruptive live-region semantics.
- [Phase 78]: Remap only semantic group color tokens in high contrast. — Theme changes preserve layout geometry and avoid visual shift.
- [Phase 78]: FilterBar remains presentation-only while parents own forms, validation, query semantics, pagination, results, and canonical URLs. — Preserves the Phase 78 authority boundary and prevents shared UI from inventing domain behavior.
- [Phase 78]: Filter disclosure uses one nearest-root field tree with idempotent hidden and inert synchronization and no persisted filter data. — Keeps narrow accessibility state patch-safe without host hooks or sensitive client storage.
- [Phase 78]: Keep ConfirmActionDialog presentation-only while parents own preview, authorization, mutations, recovery, and receipts. — Prevents rendered previews and disabled controls from becoming authority.
- [Phase 78]: Represent clean confirmation success by removing the dialog; keep partial and stale outcomes visible and focused. — Preserves truthful result and recovery state without overstating host completion.
- [Phase 78]: Use pinned LiveView focus and loading primitives with no new confirmation client controller. — Keeps packaged JavaScript unchanged and avoids a host hook requirement.
- [Phase 78]: Keep DetailSurface presentation-only while parents own selection, authorization, redaction, explicit content states, URLs, history, and confirmation transitions. — Prevents a shared adaptive surface from becoming a data, authority, or navigation boundary.
- [Phase 78]: Use one native dialog tree with show() inline, showModal() in drawer mode, and close-before-reopen modality switching. — Preserves comparison and outside focus wide while retaining native inertness and focus containment constrained.
- [Phase 78]: Track detail focus ownership only in root-scoped ephemeral invoker state and owner-element WeakMaps. — Restores a connected invoker or logical fallback without persisting resource, filter, reason, token, or result payloads.
- [Phase 78]: Keep the 23 group story IDs, ordering, fixtures, and activation metadata Elixir-owned; TypeScript and Node validate generated output without duplicating the registry. — Maintains one deterministic source of truth across showcase and browser discovery.
- [Phase 78]: Load the support-only group catalog through a fail-closed optional seam while ShowcaseLive owns confirmation, filter, detail, URL/history, result, and receipt truth. — Prevents malformed or packaged-absent fixtures from leaking partial UI and keeps production components presentation-only.
- [Phase 78]: Use one shared generated-target activation helper that dispatches the validated LiveView event and enforces one active overlay and at most one modal. — Allows native top-layer dialogs to switch safely while structure, axe, VRT, and behavior share the same path.
- [Phase 78]: Resolve connected behavior fixtures from generated groupStories and shared activation — Preserves one Elixir-owned story registry and prevents browser drift
- [Phase 78]: Use connected parent-result attributes and real LiveView events for history, duplicate suppression, receipts, and focus restoration — Keeps browser proof observational while parent state remains authoritative
- [Phase 78]: Assert adaptive detail through native modal state and one persistent DOM identity — Proves constrained inertness and wide comparison behavior across responsive transitions
- [Phase 78]: Measure 200 percent zoom with Chromium device metrics and mechanical geometry assertions — Makes wrapping, visible focus, one-tree rendering, and overflow objective
- [Phase 78]: Scan complete document text, markup, URLs, values, titles, and attributes for confidentiality sentinels — Covers hidden and non-visible leak channels as well as rendered copy
- [Phase 78]: Give DetailSurface a server-rendered keyboard-scroll baseline and remove the body tab stop when the responsive controller places it inline. — Preserves no-JavaScript narrow accessibility without adding an unnecessary wide-layout tab stop.
- [Phase 78]: Require exact manifest-derived group baseline equality, group-only changed scope, and a fresh compare-only run after VRT updates. — Prevents unrelated scenario residuals or update-mode generation from being reported as group visual success.
- [Phase 79]: Keep Plan 79-01 strictly RED-only so failures name missing Phase 79 behavior rather than partial production scaffolding.
- [Phase 79]: Normalize invalid Audit pages to 1, clamp excessive pages to the last real page, and keep empty scopes at page 1 with zero total pages.
- [Phase 79]: Preserve existing authorization, durable Cron effects, telemetry, audit evidence, selector destinations, and support ownership while migrating presentation.
- [Phase 79]: Keep the exact 19 page-story IDs literal only in the Elixir catalog contract; TypeScript derives page targets from schema-7 pageStories. — Preserves one story-ID source and prevents browser registry drift.
- [Phase 79]: Require the Plan 79-10 Task 79-10-03 authenticated reset, actor, and recovery helper plus PHASE79_BROWSER_FIXTURE_SECRET before connected evidence runs. — Prevents ambient example-host seeds or static story assigns from masquerading as connected database behavior.
- [Phase 79]: Verify page baselines as exactly 19 stories times four themes times three projects with page-only tracked, untracked, renamed, and copied scope. — Keeps the known unrelated scenario residual separate from Phase 79 page evidence.
- [Phase 79]: Count and retrieve Audit rows from the same exact filtered query, then clamp page input before calculating a fixed-size offset. — Keeps count and rows in one exact scope while making every nonempty page reachable under a fixed SQL bound.
- [Phase 79]: Treat page presenters as structural boundaries: accept only plain safe inputs, project fixed fields, and reject sensitive or provider-shaped Audit evidence before display policy or HEEx. — Prevents raw schemas, metadata, credentials, errors, and provider payloads from becoming visible or hidden DOM data.
- [Phase 79]: Keep legacy blocker classifier normalization for callers while removing classifier values from shared HTML and Phase 79 limiter maps. — Preserves compatibility without exposing implementation-shaped technical codes to operators.
- [Phase 79]: Normalize Overview buckets once after the mount-owned repository read so page_content/1 remains a pure reusable rendering boundary.
- [Phase 79]: Treat all-quiet as absence of identified native current attention and bridge follow-up; runnable capacity and retained continuity do not turn quiet state into an alarm.
- [Phase 79]: Use the shared limiter/control-plane status taxonomy for Overview attention lanes while preserving Overview-specific presentation IDs and copy.
- [Phase 79]: Cron actions resolve from server-owned selected entry and preview state, with backend identifiers absent from DOM and URL authority. — Fabricated client resource or action parameters must not become mutation authority.
- [Phase 79]: Skipped and duplicate run-now claims remain recoverable and require an explicit fresh preview while preserving only the trimmed reason draft. — A recorded slot claim is not clean success and must never silently replay or emit a success receipt.
- [Phase 79]: Cron render delegates to public pure page_content/1 after parent-owned reads, URL parsing, authorization, and mutation orchestration. — Deterministic page stories need the exact production composition without external state work.
- [Phase 79]: Reuse the initial batched limiter scan across URL selection patches. — Keeps Resource and State list reads constant while selected-only history and snapshot work stays bounded.
- [Phase 79]: Keep current limiter evidence, block-start snapshot, and retained history as separate finite presentation structures. — Prevents historical or raw repository facts from becoming current or causal page truth.
- [Phase 79]: Only complete empty current evidence may render Runnable. — Unavailable or partial evidence must remain explicit even if retained history describes a prior runnable state.

### Blockers

- Aggregate visual:a11y retains 108 scenario-only VRT baseline failures; all Phase 75 form cases pass.
