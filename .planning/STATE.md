---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Identity Milestone Audit & Idempotency Proof
current_phase: 76
current_phase_name: navigation-and-app-shell
status: ready_for_planning
stopped_at: Phase 75 complete; ready for Phase 76 planning
last_updated: "2026-07-11T18:48:21Z"
last_activity: 2026-07-11
last_activity_desc: Phase 75 plan 75-06 completed
progress:
  total_phases: 15
  completed_phases: 6
  total_plans: 27
  completed_plans: 27
  percent: 40
---

# Project State

## Project Reference

**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

**Current Focus:** Phase 76 — navigation-and-app-shell

## Current Position

Phase: 76 (navigation-and-app-shell) — READY FOR PLANNING
Plan: TBD
Status: Phase 75 complete; ready to plan Phase 76
Last activity: 2026-07-11 — Phase 75 plan 75-06 completed

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

**Last session:** 2026-07-11T18:48:21Z
**Stopped at:** Phase 75 complete; ready for Phase 76 planning
**Resume file:** None

- **Last Action:** Executed and committed `75-06-PLAN.md`, closing WR-01, WR-02, and WR-03.
- **Next Action:** Plan Phase 76 navigation-and-app-shell.
- **Active Context:** Phase 75 form components are complete; aggregate visual:a11y still has scenario-only VRT drift outside the form surface.

## Decisions

- [Phase 75]: Keep all form controls stateless and field-first while allowing explicit identity overrides; use native semantics; centrally filter visual escape hatches. — Preserves parent-owned behavior, accessible native controls, and the scoped token-owned visual contract.
- [Phase 75]: Keep deterministic form evidence in a separate dev/test-only catalog rather than domain stress fixtures. — Preserves production packaging and the domain fixture boundary while providing stable form evidence.
- [Phase 75]: D-25: Browser evidence uses native interaction and generated form metadata across themes and viewports. — Proves component semantics without overclaiming Phase 82 page-level manual accessibility.
- [Phase 75]: Switch state text is CSS-synchronized from the native checkbox state, so browser proof stays tied to real form semantics.
- [Phase 75]: Multi-error fields preserve the single-error `-error` id contract and use indexed ids only when multiple messages render.
- [Phase 75]: Scoped form baselines were refreshed for intentional form changes; scenario baselines remain unchanged until their owning phase.

### Blockers

- Aggregate visual:a11y retains 108 scenario-only VRT baseline failures; all Phase 75 form cases pass.
