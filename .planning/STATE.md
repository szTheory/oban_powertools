---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Identity Milestone Audit & Idempotency Proof
current_phase: 80
current_phase_name: page-migration-wave-2-jobs-forensics
status: verifying
stopped_at: Completed 80-16-PLAN.md
last_updated: "2026-07-29T04:16:35.729Z"
last_activity: 2026-07-29
last_activity_desc: Phase 80 execution started
progress:
  total_phases: 15
  completed_phases: 11
  total_plans: 77
  completed_plans: 77
  percent: 73
---

# Project State

## Current Position

Phase: 80 (page-migration-wave-2-jobs-forensics) — EXECUTING
Plan: 16 of 16
Status: Phase complete — ready for verification
Last activity: 2026-07-29 — Phase 80 execution started

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
| Phase 79 P06 | 22 min | 3 tasks | 4 files |
| Phase 79 P07 | 11 min | 1 tasks | 4 files |
| Phase 79 P10 | 79m | 3 tasks | 8 files |
| Phase 79 P11 | 13m | 1 tasks | 4 files |
| Phase 79 P12 | 13m | 1 tasks | 5 files |
| Phase 79 P08 | 2h 57m | 3 tasks | 246 files |
| Phase 80 P01 | 24min | 2 tasks | 6 files |
| Phase 80 P02 | 17min | 2 tasks | 4 files |
| Phase 80 P03 | 1h20m | 3 tasks | 5 files |
| Phase 80 P04 | 34m | 3 tasks | 8 files |
| Phase 80 P05 | 11m | 2 tasks | 6 files |
| Phase 80 P06 | 24m | 1 tasks | 7 files |
| Phase 80 P07 | 30m | 2 tasks | 4 files |
| Phase 80 P08 | 22m | 1 tasks | 5 files |
| Phase 80 P09 | 12m | 1 tasks | 6 files |
| Phase 80 P10 | 28m | 2 tasks | 8 files |
| Phase 80 P11 | 35m | 1 tasks | 3 files |
| Phase 80 P12 | 180 | 3 tasks | 521 files |
| Phase 80 P13 | 94 | 2 tasks | 3 files |
| Phase 80 P14 | 5m | 1 tasks | 3 files |
| Phase 80 P15 | 9m | 2 tasks | 6 files |
| Phase 80 P16 | 40m | 2 tasks | 3 files |

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
- Resolve the 423 measured non-page VRT baseline mismatches plus inherited Credo (260 findings), Dialyzer (62 errors), and dependency-advisory debt recorded by Plan 79-08.

### Blockers / Open Questions

- None blocking. (Continues to welcome real-world adopter feedback / GitHub issues in parallel.)

## Session Continuity

**Last session:** 2026-07-29T04:16:31.626Z
**Stopped at:** Completed 80-16-PLAN.md
**Resume file:** None

- **Last Action:** Completed Plan 79-08's connected accessibility, motion, responsive, confidentiality, and page-only visual evidence.
- **Next Action:** Begin Phase 80 while the formally re-scoped repository-wide quality and non-page VRT debt remains tracked.

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
- [Phase 79]: Keep the exact 19 page-story IDs literal only in the Elixir catalog contract; TypeScript derives page targets and acceptance contracts from schema-8 pageStories. — Preserves one story-ID source and prevents browser registry drift.
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
- [Phase 79]: Resolve selected Audit evidence with its exact filters in one scoped query and use the same unavailable result for missing or out-of-scope IDs. — This prevents transient or stale selection detail from escaping the bounded scan scope.
- [Phase 79]: Project Audit metadata through a narrow structural allowlist before shared presentation and retain only normalized assigns. — This preserves useful evidence while preventing raw or redacted metadata from leaking into render state.
- [Phase 79]: Push the first Audit selection, replace selection switches and closes, and emit URLs in canonical filter-page-event order. — This keeps back-button behavior meaningful and makes URL-owned detail deterministic.
- [Phase 79]: Bind canonical page composition to stable production roots — Preserves the verified semantic DOM while giving all four pages one token-owned layout contract.
- [Phase 79]: Keep page CSS limited to composition — Shared components retain chrome, modality, interaction, and bounded scroll ownership while the page layer owns only geometry and wrapping.
- [Phase 79]: Require source/package equality and repeat-build hash equality together — Both checks are necessary to prove the distributed CSS is current and deterministically generated without JavaScript drift.
- [Phase 79]: Use a unique launcher build path plus Mix recompile hooks so fixture routes and modules follow the explicit opt-in flag across back-to-back runs.
- [Phase 79]: Keep fixture responses closed and public-only while carrying the ephemeral credential exclusively in a request header and Docker environment name.
- [Phase 79]: Open the real Cron preview before applying recovery perturbations; use a future scheduled active job for deterministic skipped and partial evidence.
- [Phase 79]: Keep raw page-story form maps in the package-excluded catalog and materialize Phoenix forms only at the Showcase rendering boundary. — Preserves normalized deterministic fixtures while satisfying production component inputs.
- [Phase 79]: Store only one validated active page-story ID and mount only its matching production page_content tree. — Prevents duplicate page trees, overlays, IDs, and client-persisted fixture payloads.
- [Phase 79]: Append page stories after the unchanged 64-target schema-6 prefix. — Existing scenario and component discovery remains stable while schema 8 adds page acceptance evidence.
- [Phase 79]: Close any active group overlay before page activation, then enforce one active page story and at most one dialog or modal. — The shared structure, axe, and VRT loops can traverse all generated targets without overlapping top-layer state.
- [Phase 79]: Replace the five human observation rows with executable schema-8 copy/role/order contracts, 57 exact ARIA snapshots, connected focus/media E2E, 228 canonical page screenshots, and advisory real-VoiceOver transcripts. — Required verification has zero human execution while intentional snapshot changes remain ordinary code review.
- [Phase 79]: Accept Phase 79 screenshots only after true-theme restoration, exact 228-file equality, page-only scope, and a fresh compare-only pass. — This prevents update-mode generation, theme reset, or unrelated baseline families from masquerading as visual evidence.
- [Phase 79]: Record 423 measured non-page VRT mismatches instead of the planning-time estimate of 108. — The complete stable aggregate and focused non-VRT reconciliation provide the authoritative current repository measurement.
- [Phase 80]: Canonical Jobs URLs always include state, omit the default first page, and keep quick-review identity outside the Jobs query struct. — Preserves one bounded canonical navigation contract.
- [Phase 80]: Invalid direct URL values collapse to one safe finite notice, while invalid drafts retain exact original strings and expose no applied state. — Keeps validation truthful without applying unsafe URL values.
- [Phase 80]: Filter identity is the deterministic encoded state/filter allowlist with page and quick review excluded. — Prevents pagination and review state from changing filter identity.
- [Phase 80]: Jobs index assigns contain finite presenter rows and quick-review maps; raw args, meta, errors, output payloads, and provider values never enter shared composition. — Keeps shared UI redaction-safe and provider-neutral.
- [Phase 80]: Filter change retains and validates draft strings only; one valid submit patches canonical applied URL truth before the three bounded list, count, and grouped-count reads. — Separates draft validation from applied server-owned query state.
- [Phase 80]: The disconnected Jobs index performs no query because the host router does not expose URL query params until the connected phase. — Avoids reads before canonical URL truth is available.
- [Phase 80]: Quick-review authorization uses the same unavailable outcome for missing and unauthorized jobs, and stale review identity is removed with a replace patch. — Prevents existence disclosure and preserves canonical history.
- [Phase 80]: The full detail contract exposes exactly support, actions, identity, timing, errors, data, redaction, and authorized destinations; raw Jobs, exceptions, payloads, and arbitrary evidence never enter shared composition. — Keeps canonical detail closed and redaction-safe.
- [Phase 80]: Only seven allowlisted Jobs list parameters survive into Back to Jobs; opaque return_to, review job, and unknown parameters are discarded. — Prevents attacker-controlled return context propagation.
- [Phase 80]: Preview tokens remain in LiveView socket private state, while shared confirmation receives only finite presenter action, form, result, and recovery truth. — Separates execution capability from rendered presentation.
- [Phase 80]: Any non-success result clears the private execution capability and disables server-side replay until the operator explicitly creates a fresh preview. — Blocks stale or forged action replay.
- [Phase 80]: The application validates jobs_bulk_target_limit before starting children; 100 is the default and only integers from 1 through 1000 are accepted. — Bulk recovery remains bounded at startup and hosts receive actionable configuration failures.
- [Phase 80]: A server-owned Scope contains only frozen ordered unique IDs, deterministic filter identity, exact count, mode, and observation time; filters are never rerun during preview or execution. — Accepted authority stays tied to one bounded observed target set.
- [Phase 80]: Each target receives independent authorization plus real Lifeline preview and execution, while tokens, hashes, reasons, IDs, and internal failures remain outside aggregate messages and telemetry. — Per-target security is preserved without turning shared progress into a disclosure channel.
- [Phase 80]: Only exact all-success closes the dialog; any excluded, skipped, failed, drifted, or interrupted target remains selected and requires a fresh authoritative preview. — Partial or stale outcomes remain recoverable and cannot replay prior capability.
- [Phase 80]: Scope.parse accepts only workflow, incident, cron_entry, or limiter shapes over the six public keys and replaces every conflict with empty canonical params. — Selector ambiguity fails closed before evidence reads.
- [Phase 80]: Audit.forensic_window revalidates the supplied Scope struct and requires an explicit repository before issuing a source query. — Forged typed values cannot bypass the closed grammar or perform ambient reads.
- [Phase 80]: Workflow and workflow-step windows use authoritative resource predicates, exact counts, and SQL limit 50. — Indexed relational identity supports exact bounded coverage claims.
- [Phase 80]: Incident windows retain total_count nil and use SQL limit 51 because the incident fingerprint metadata predicate has no host-owned index. — The UI reports has-more truth without overclaiming completeness or forcing a host migration.
- [Phase 80]: Forensics.bundle parses or revalidates Scope before repository resolution and returns only typed ok, unavailable, or safe error tuples. — Invalid or forged scope values cannot trigger ambient repository access or hidden family precedence.
- [Phase 80]: Workflow and incident evidence use Audit.forensic_window; Cron and limiter output retains only the newest eight source facts and reports unknown totals honestly. — Every evidence family stays source-bounded without inventing completeness.
- [Phase 80]: Audit chronology carries finite status and stable padded event identity while operator reasons and runbook continuity remain structurally absent. — Same-timestamp evidence remains distinct and deterministic without exposing sensitive context.
- [Phase 80]: The Forensics presenter emits destinations only when a supported canonical local URL is present in caller-owned authorized_hrefs. — Noun guidance remains both closed and authorization-bound.
- [Phase 80]: Bare Forensics is a genuine four-type chooser; mixed, orphaned, or unsupported URL parameters replace to bare Forensics before any source read. — Direct URLs fail closed without enumerating evidence or applying ambiguous identity.
- [Phase 80]: Draft changes reveal and validate type-specific fields without patching or querying; only a valid Inspect evidence submit writes canonical selector parameters. — Draft form state stays separate from server-owned applied scope.
- [Phase 80]: Missing and unauthorized valid Forensics scopes share byte-equivalent Evidence unavailable output and expose no destination differences. — Uniform output prevents existence and permission disclosure.
- [Phase 80]: Ready Forensics evidence renders from only the exact page assign contract and uses one bounded shared Timeline with absolute machine-readable timestamps. — Pure composition stays redaction-safe, semantic, and deterministically bounded.
- [Phase 80]: FilterBar accepts an optional validated submit_label while preserving Apply filters as its default. — Page-specific operator language is supported without changing existing callers.
- [Phase 80]: Phase 80 stories live in one appended helper block so the original 19-story prefix remains byte/order-stable and the Phase 80 commit remains valid without pre-existing Phase 79 acceptance hunks. — The new catalog slice stays independently testable while preserving ownership of earlier dirty work.
- [Phase 80]: ShowcaseLive materializes only filter and scope forms, confirmation forms, and selected-job MapSets at the component boundary; catalog fixtures remain finite plain data. — Support fixtures stay deterministic, serializable, and outside runtime authority.
- [Phase 80]: Oversized and all-success Jobs stories render non-dialog rejection or receipt truth, while unresolved preview, progress, partial, drifted, disconnected, and interrupted states retain one confirmation. — Each fixture reflects the production state machine and never manufactures an overlay.
- [Phase 80]: The mixed-results story uses one partial state with separate success, skipped, and failed rows. — Aggregate and per-target outcomes remain independently truthful.
- [Phase 80]: Keep manifest schema 8 and derive all 49 page stories from the Elixir catalog without a literal Jobs or Forensics browser registry. — One generated source of truth prevents discovery and evidence drift.
- [Phase 80]: Treat the generated showcase manifest as ignored verification output rather than a committed Plan 80-09 artifact. — The manifest is reproducible at a recorded hash and is outside the plan ownership frontmatter.
- [Phase 80]: Require both filesystem equality and Git-tracked equality for the future 588-PNG baseline set, including rename, copy, untracked, and non-page rejection. — Visual evidence cannot pass through incomplete or unrelated artifact scope.
- [Phase 80]: Keep Phase 80 as a sibling fixture seam so Phase 79 routes, schemas, and callers remain unchanged. — The new connected evidence can coexist without weakening the earlier fixture contract.
- [Phase 80]: Use one project and run tagged database population with a DB or message barrier; the fixture controls deterministic state but never executes operator actions. — Browser proof observes real production action authority without turning fixtures into a mutation shortcut.
- [Phase 80]: Expose only IDs, counts, states, and audit completion, rejecting unknown or sensitive response fields in the browser client. — The fixture bridge remains a closed public evidence channel.
- [Phase 80]: Reuse the existing validated Phase 79 disposable database and build lifecycle while enabling both fixture generations and independently generated secrets. — Both browser generations share one isolated server and exact cleanup contract.
- [Phase 80]: Keep Wave 1 compatibility independent of manifest position by filtering the four established families and comparing the exact ordered 19 IDs. — Manifest expansion cannot silently change or reorder prior connected coverage.
- [Phase 80]: Scope broad Jobs queries with the fixture public project and run key so concurrent Playwright projects cannot observe one another rows. — Three-project connected execution remains deterministic without changing production authority.
- [Phase 80]: Prove renewed denial adds no audited effect and disconnect adds exactly one effect relative to a measured public evidence baseline. — Authorization and lifecycle proof does not assume a globally empty Audit table.
- [Phase 80]: Filter the existing Wave 1 Audit interaction to its own fixture resource so Wave 1 and Wave 2 remain valid when executed together. — Concurrent fixture generations no longer displace each other from bounded Audit pages.
- [Phase 80]: Preserve the Jobs table conventional scan model inside one labelled horizontal scroll region at tablet widths. — This keeps header-to-cell relationships and dense rows while preventing page-level overflow.
- [Phase 80]: Mirror aria-checked mixed state into the native checkbox indeterminate property. — The native state is required for correct browser rendering and axe semantics.
- [Phase 80]: Fix production and shared-component defects at owning boundaries when locked evidence exposes them. — Axe rules and visual baselines may not be suppressed or updated to mask product defects.
- [Phase 80]: Regenerate only page-jobs-explicit-selection after the tri-state fix. — Hash inventories proved all other 144 ARIA and 576 PNG artifacts stayed byte-identical.
- [Phase 80]: VoiceOver coverage resolves seven exact production-composed stories and fails closed on missing or ambiguous manifest tuples. — Exact identifiers prevent silent assistive-technology coverage loss.
- [Phase 80]: Jobs and Forensics transcript obligations stay open until real Guidepup VoiceOver startup succeeds. — Axe, ARIA snapshots, or invented narration cannot substitute for a real screen-reader transcript.
- [Phase 80]: Use a 15-second Playwright assertion window for full-suite LiveView readiness. — Repeated five-second aggregate timeouts passed isolated reruns and the bounded increase produced a clean 1392-case aggregate.
- [Phase 80]: Closure changes no page baseline, dependency, lockfile, schema, migration, or production route. — Phase 80 closure is validation and production-composed assistive-technology coverage only.
- [Phase 80]: Require workflow-step Forensics authority to resolve id, workflow_id, and step_name together, then rebuild Audit scope from the validated Step row. — Prevents workflow authorization from being combined with foreign step chronology.
- [Phase 80]: Jobs pages are bounded by the largest page whose 20-row offset fits signed 64-bit Postgrex encoding; quick-review IDs are bounded directly by signed 64-bit maximum. — Prevents arbitrary-size URL integers from reaching Postgrex while preserving the fixed 20-row pagination contract.
- [Phase 80]: Execution authorization and Lifeline execution share one per-target timeout, while ordered stream terminals remain paired with their originating frozen targets. — Preserves exact target identity across timeout and outer-exit paths without deriving position from completion order.
- [Phase 80]: LiveView accepts execution results only when their count and exact unique integer position set equal the ready preview positions. — Malformed post-effect results fail closed with interruption and Audit recovery before any result-map lookup.
- [Phase 80]: Only exactly five-space repository test locations are eligible for outer ExUnit attribution; ten-space generated-host diagnostics are ignored. — This mechanically excludes nested output while preserving exact module, title, path, and line provenance.
- [Phase 80]: Current inherited failures are accepted only when isolated calibration, full suite, and failed-test rerun reproduce byte-identical four-field tuples with matching status and printed totals. — Exact independent reproduction distinguishes current out-of-scope debt from a Phase 80 regression without weakening to counts.

### Blockers

- Phase 79 validation is approved by machine evidence; the advisory VoiceOver nightly may harden into a required lane after its quarantine period.
