# Phase 47: Hex Release Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 47-hex-release-foundation
**Areas discussed:** Publish mechanism, License choice, Path to 1.0 criteria, CHANGELOG 0.5.0 framing
**Mode:** Advisor (full_maturity calibration — research-backed comparison tables; advisor model: sonnet)

---

## Publish mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Manual first + tag-triggered CI | Manual 0.5.0 publish, then `publish.yml` on future `v*` tags | |
| Manual first + CI assert-only gate | Manual publish; CI gates clean-tree/build/tests, never auto-publishes | |
| Manual publish only | `mix hex.publish` for 0.5.0, defer all automation | |
| Full release-please now | Stand up release-please config + manifest + publish workflow now | ✓ |

**User's choice:** Full release-please now (chose the heavier canonical path over the recommended manual-first hybrid).
**Notes:** Advisor recommendation was the manual-first hybrid; user opted for full automation completeness/auditability from day one.

### Follow-up: how the first 0.5.0 release is cut

| Option | Description | Selected |
|--------|-------------|----------|
| release-please cuts 0.5.0 too | Seed manifest + `Release-As: 0.5.0` so release-please opens the release PR, tags, and publishes | ✓ |
| Manual 0.5.0, release-please from 0.6.0 | Publish 0.5.0 manually once, hand 0.6.0+ to release-please | |

**User's choice:** release-please cuts 0.5.0 too.
**Notes:** Requires deliberate manifest seeding so the first release lands at 0.5.0, not 0.1.0 or auto-1.0.0.

### Follow-up: pipeline conventions

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror the canonical pipeline | Replicate `bootstrap-elixir-hex-lib` skill's release-please layout | |
| Standard release-please, no skill coupling | Use upstream release-please-action conventions | ✓ |

**User's choice:** Standard release-please, no skill coupling.
**Notes:** Bootstrap skill is greenfield-oriented; this repo predates it and is being retrofitted — keep idiomatic to release-please's own docs.

---

## License choice

| Option | Description | Selected |
|--------|-------------|----------|
| Apache-2.0 | Matches oban/oban_web/ecto/telemetry/ex_doc; patent grant | ✓ |
| MIT | Shortest, universal; matches phoenix/igniter; no patent grant | |
| MPL-2.0 | File-level copyleft; rare in Elixir | |
| Apache-2.0 OR MIT (dual) | Adopters choose; rare in Elixir | |

**User's choice:** Apache-2.0 (matched advisor recommendation).
**Notes:** Uniform license audit across the Apache-2.0 infra core the library wraps.

---

## Path to 1.0 criteria

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid per-surface + window | Per-surface freeze, each gated by ≥1 external host exercise + 2 breaking-change-free minor releases | ✓ |
| Contract-coverage | Freeze enumerated surfaces as a set | |
| Adopter-count | 1.0 after N external adopters | |
| Stability-window only | 1.0 after K minor releases with no breaking change | |

**User's choice:** Hybrid per-surface + window (matched advisor recommendation).
**Notes:** Surfaces — installer/migration contract, Operator API (single+bulk), Telemetry `@contract`, host-ownership boundary. Telemetry contract graduates earliest.

---

## CHANGELOG 0.5.0 framing

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped + Unreleased + path-to-1.0 | Feature-grouped Added + `[Unreleased]` + 0.x/version-confusion note + path-to-1.0 | ✓ |
| Feature-grouped snapshot only | Grouped Added; path-to-1.0 in README instead | |
| Single initial-release entry | One flat "Initial public release" list | |
| Backfilled v1.x history | Reconstruct internal milestones as prior entries (not recommended) | |

**User's choice:** Grouped + Unreleased + path-to-1.0 (matched advisor recommendation).
**Notes:** Satisfies REL-03 path-to-1.0 in the same file; heads off the internal-v1.x-vs-public-0.5.0 confusion (PITFALLS Pitfall 2).

---

## Claude's Discretion

- Exact `:files` list ordering (baseline = PITFALLS Pitfall 1 recommendation).
- CHANGELOG capability bullet wording + README `0.x` stability banner wording.
- Whether to fix the orphan ungrouped guide extra (`forensics-and-runbook-handoffs.md`) in this phase.

## Deferred Ideas

- Isolated hex-consumer verification (`examples/hex_consumer/`) — REL-04 / Phase 51.
- Conventional-commit auto-generated CHANGELOG for 0.6.0+ via release-please.
