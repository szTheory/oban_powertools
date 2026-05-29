---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: Release & Operability
status: ready_to_plan
last_updated: "2026-05-29T19:24:50.567Z"
last_activity: 2026-05-29 -- Phase 49 execution started
progress:
  total_phases: 5
  completed_phases: 2
  total_plans: 8
  completed_plans: 5
  percent: 40
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-28)

**Core value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.
**Current focus:** Phase 49 — limiter-explain-simulate-cli

## Current Position

Phase: 49 (limiter-explain-simulate-cli) — EXECUTING
Plan: 1 of 3
Next: Phase 48 (doctor-health-check) — not yet planned.
Last activity: 2026-05-29 -- Phase 49 execution started

Release automation (beyond the original 47 plans): full shift-left CI/CD shipped — ci.yml (ci-gate), release.yml (release-please→gate-ci-green→publish), publish-hex.yml recovery, pr-title lint, Dependabot, SHA-pinned actions, branch protection (ci-gate + host-contract-gate), RELEASE_PLEASE_TOKEN + HEX_API_KEY. Tag v0.5.0 + oban_powertools-v0.5.0 both exist; future tags are v* (include-component-in-tag: false). See memory: hex-release-pipeline-gotchas.

## Accumulated Context

Decisions, blockers, and todos carried from v1.5:

### Decisions

See PROJECT.md Key Decisions section for the full locked decision list.

**Post-v1.5 assessment decisions (2026-05-28, see `threads/2026-05-28-post-v1.5-next-milestone.md`):**

- Hex publication is a near-term goal; first public release at `0.x` (recommend `0.5.0`) before committing to `1.0`.
- Recommended next milestone = v1.6 Release & Operability (now active).
- Worker-Lifecycle (v1.7) must precede Batches (v1.8).
- Done-% ~87%; ship the release before adding more capability.

**v1.6 conventions:**

- Zero new runtime dependencies (ExDoc dev-only; `telemetry_metrics`/`telemetry_poller` optional, gated like `oban_web`).
- Phase verification / milestone audit must assert a clean working tree (or per-phase commit existence) — graduated from v1.5 (phases 44/45 audited `passed` while uncommitted).
- [Phase ?]: CHANGELOG.md in Keep-a-Changelog format with 0.5.0 entry and path-to-1.0 gate
- [Phase ?]: Apache-2.0 LICENSE verbatim text at repo root; SPDX id matches planned package/0 declaration (D-06/D-07)

### Blockers

None.

### Todos

- Next: `/gsd:plan-phase 47` to plan the Hex Release Foundation phase.

## Operator Next Steps

- `/clear`, then `/gsd:discuss-phase 47` (gather context) or `/gsd:plan-phase 47` (plan directly).

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 47-hex-release-foundation P01 | 145 | 2 tasks | 2 files |
| Phase 47-hex-release-foundation P02 | 3m | 3 tasks | 2 files |
