---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Powertools Identity
status: planning
last_updated: "2026-06-18T16:17:18.409Z"
last_activity: 2026-06-18 — Milestone v2.0 roadmap created
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

**Current Focus:** v2.0 Powertools Identity — brand book + library-owned design-system overhaul of the `/ops/jobs` operator UI

## Current Position

Phase: 70 — Brand Book & Identity Foundation (not started)
Plan: —
Status: Roadmap created (15 phases, 70–84); ready to plan Phase 70
Last activity: 2026-06-18 — Milestone v2.0 roadmap created

## Performance Metrics

| Metric | Target | Current | Notes |
|--------|--------|---------|-------|
| Test Coverage | >95% | - | - |
| Type Checking | 0 Dialyzer errors | 0 | - |
| Linting | 0 Credo warnings | 0 | - |

## Accumulated Context

### Roadmap Evolution

- Shipped v1.11 Stability & 1.0 Release Prep; published 1.0.0.
- Executed Post-1.0.0 End-of-Roadmap Assessment. Library is functionally complete for its intended *feature* scope.
- Started v2.0 Powertools Identity — a coherence/quality milestone (brand book + design-system overhaul), not new operator capability. Phases 70–84.

### Architectural Decisions

- **Diminishing Returns:** Do not build Chunks, Dynamic Scaler, Relay/Task-await, or Per-field Encryption unless explicitly demanded by real-world adopters.
- **Library-owned isolated theme (v2.0):** ship precompiled, namespaced CSS/JS via a Plug (LiveDashboard/Oban-Web pattern); scope everything under `.obpt-root` with preflight disabled and `obpt:` prefix; tokens as two-tier `--obpt-*` CSS variables; dark/light/system via `data-obpt-theme` on `.obpt-root` (never `<html>`), system default, namespaced `localStorage`. No host Tailwind dependency.
- **Infra (v2.0):** dev-gated custom showcase route (not PhoenixStorybook dep); external Node Playwright for visual-regression + axe a11y; deterministic stress-fixture catalog. Zero new Hex runtime deps.

### Known Technical Debt / Todos

- Migrate `state_badge_class/1`, `state_tab_class/1`, and duplicated modal markup in the 9 LiveViews onto the new tokens/components (proof seam in Phase 71, full migration Phases 79–81).

### Blockers / Open Questions

- None blocking. (Continues to welcome real-world adopter feedback / GitHub issues in parallel.)

## Session Continuity

- **Last Action:** Bootstrapped v2.0 Powertools Identity — milestone-switch, requirements, and roadmap (Phases 70–84).
- **Next Action:** `/gsd-discuss-phase 70` (or `/gsd-plan-phase 70`) — Brand Book & Identity Foundation.
- **Active Context:** Design-system milestone. Brand book is the source of truth; tokens + audit harness precede page migrations; improvement is idempotent (forward-only, regression-gated).
