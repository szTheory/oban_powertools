# Phase 72: Stress Fixtures & Showcase Skeleton - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 72-stress-fixtures-showcase-skeleton
**Areas discussed:** Fixture catalog shape, Showcase skeleton, Controls and guardrails

---

## Fixture Catalog Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Domain-first catalog with persona/JTBD tags | Mirrors the 9 operator surfaces while carrying persona scenarios and stable VRT/a11y IDs. | ✓ |
| Persona-first journey tree | Centers triage/incident/repair/audit flows but makes per-domain coverage harder to audit. | |
| Flat story list | Simple at first, but weak as a long-term source of truth for ExUnit, VRT, and axe targets. | |

**User's choice:** Not prompted interactively; selected by Claude per repo decision posture because it best satisfies FIX-01..03 without forcing later renames.
**Notes:** Interactive question tooling was unavailable in Default mode. The repo's PROJECT.md explicitly prefers one-shot, repo-grounded recommendations and discourages re-litigating implementation choices resolvable from requirements and existing patterns.

---

## Showcase Skeleton

| Option | Description | Selected |
|--------|-------------|----------|
| Full future skeleton, token/theme populated now | Reserves stable anchors for future component/page stories while keeping Phase 72 scope narrow. | ✓ |
| Minimal token-only page | Lowest immediate effort but forces later phases to invent structure and selectors. | |
| Full component examples now | Too much scope; primitives/forms/data/groups/pages belong to later phases. | |

**User's choice:** Not prompted interactively; selected by Claude.
**Notes:** Roadmap says the showcase initially renders tokens + theming, while SHOW-01..03 make it the canonical future scan surface. Reserving anchors now avoids churn without implementing later-phase components early.

---

## Controls And Guardrails

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse Phase 71 theme boundary and add stable story viewport controls | Keeps theme state inside `.obpt-root`, preserves host isolation, and gives Playwright/axe stable targets. | ✓ |
| Host-level theme and viewport controls | Violates the library-owned isolation contract and risks host theme bleed. | |
| Wait for Phase 73 harness to decide controls | Delays selector/state contracts until after the showcase exists, increasing churn. | |

**User's choice:** Not prompted interactively; selected by Claude.
**Notes:** Phase 71 already locked the theme controller, `ThemeShell`, md5 assets, and example-host isolation pattern. Phase 72 should extend those seams, not introduce a parallel control surface.

---

## Claude's Discretion

- Exact module names, internal function names, HEEx layout, and copy.
- Cleanest dev/test compilation mechanism for sharing `test/support/showcase_catalog.ex` with the dev-only showcase route, provided data is not duplicated and does not leak into prod/package output.
- Initial showcase layout details within the calm/precise brand-book constraints.

## Deferred Ideas

- Full component stories and page-pattern examples for Phases 74-83.
- Playwright VRT, baseline PNGs, axe CI, Docker pinning, and snapshot-update workflow for Phase 73.
- Operator page migrations for Phases 79-81.
