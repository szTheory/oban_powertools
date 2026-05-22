# Phase 12: Fresh Host Install Path & Example Fixture Repair - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-22
**Phase:** 12-fresh-host-install-path-example-fixture-repair
**Areas discussed:** Installer completion threshold, Example fixture provenance, First-session proof depth

---

## Installer Completion Threshold

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal repair | Installer runs again, but host still needs several documented manual seams beyond true business-policy work | |
| Strong paved road | Installer plus true host policy completion yields a compile/migrate/bootable host with minimal surprise | ✓ |
| Maximal scaffolding | Installer generates nearly everything except business auth logic and behaves more like an app template | |

**User's choice:** Shift-left recommendation accepted: strong paved road.
**Notes:** Subagent research and local synthesis both favored restoring a real paved road while keeping host-owned seams explicit. Anti-patterns rejected: fake business auth, hidden optional-dependency assumptions, or template-like overgeneration.

---

## Example Fixture Provenance

| Option | Description | Selected |
|--------|-------------|----------|
| Strict generator provenance | Fixture must stay as close as possible to `mix phx.new` + `mix oban_powertools.install` with only tiny documented seams | |
| Honest curated fixture | Thin real host app with explicit manual seams, regenerate/diff story, and no overclaiming about what the installer did | ✓ |
| Showcase/demo fixture | Polished demo-first host that may drift from the real install path | |

**User's choice:** Shift-left recommendation accepted: honest curated fixture.
**Notes:** Strict generator provenance remains the desired direction, but Phase 12 should not claim that standard until the installer and migration path are actually end-to-end trustworthy again.

---

## First-Session Proof Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Structural proof only | Compile/reset/seed/docs markers with no real operator flow proof | |
| Functional paved-road proof | Compile/reset/seed plus one real native audited mutation path and bounded bridge smoke truth | ✓ |
| Broad UI proof | Multi-page browser or near-E2E parity across native and bridge flows | |

**User's choice:** Shift-left recommendation accepted: functional paved-road proof.
**Notes:** This is the narrowest proof depth that honestly closes `DOC-01` without creating a large flake-prone browser matrix or widening support claims beyond the native audited mutation surface and the read-only bridge.

---

## the agent's Discretion

- Choose the exact starter seam shape for generated modules, provided the code stays thin and visibly host-owned.
- Choose the exact native audited mutation used for the first-session proof, provided it is deterministic and contract-representative.
- Choose the exact fixture diff/rebuild mechanics, provided provenance and manual seams remain explicit.

## Deferred Ideas

- Broad browser-E2E coverage across multiple native pages and the optional bridge.
- A separate polished showcase/demo host distinct from the canonical contract fixture.
- Maximal scaffolding that turns Powertools into an app-template-like generator.
