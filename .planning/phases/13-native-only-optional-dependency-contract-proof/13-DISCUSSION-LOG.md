# Phase 13: Native-Only Optional Dependency Contract Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-23
**Phase:** 13-native-only-optional-dependency-contract-proof
**Areas discussed:** Native-only proof strictness, Proof host shape, Bridge-presence regression scope, Docs/support-truth posture

---

## Native-only proof strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Present-but-unused optional dep | Keep `oban_web` in the fixture and simply avoid bridge usage in the native-only lane | |
| Remove dep in native-only lane | Remove `oban_web` from the copied fixture before `deps.get`/compile so native-only means actual absence | ✓ |
| Separate native-only host | Use a distinct native-only fixture/generated host with no `oban_web` at all | |
| `--no-optional-deps` as primary truth | Define native-only mostly through Mix optional-dependency flags | |

**User's choice:** Shifted-left recommendation accepted: remove `oban_web` from the copied fixture in the native-only lane so the lane proves real dependency absence.
**Notes:** Keep `--no-optional-deps` available later as a supplemental guard, but not as the main semantic definition of native-only support.

---

## Proof host shape

| Option | Description | Selected |
|--------|-------------|----------|
| One canonical fixture with narrow rewrites | Keep a single curated host and allow only small auditable lane rewrites in the harness | |
| Separate checked-in fixtures | Maintain different native-only and bridge-enabled fixture trees | |
| Generate fresh hosts per lane | Use installer-generated hosts as the primary proof host for each lane | |
| Hybrid: canonical fixture + fresh-host backstop | Keep one curated canonical fixture and retain the separate fresh-host installer lane | ✓ |

**User's choice:** Shifted-left recommendation accepted: hybrid proof architecture with one canonical fixture plus the separate fresh-host installer backstop.
**Notes:** Harness rewrites must stay narrow and visible; do not let them evolve into a shadow fixture generator.

---

## Bridge-presence regression scope

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal contract only | Route shape and read-only access only | |
| Moderate contract | Powertools-owned route/auth/display seams plus bounded proof | |
| Broad parity-oriented contract | Richer page interactions and parity-like bridge behavior | |
| Bounded host-contract + one render smoke | Prove mount/auth/resolver/display/read-only seams plus one successful bridge render | ✓ |

**User's choice:** Shifted-left recommendation accepted: bounded host-contract plus one render smoke.
**Notes:** Do not assert broad Oban Web internals or build parity expectations that the project does not intend to support.

---

## Docs/support-truth posture

| Option | Description | Selected |
|--------|-------------|----------|
| Symmetric tested lanes | Present native-only and bridge-enabled as co-equal public surfaces | |
| Native-first, bridge additive | Keep native `/ops/jobs` as the paved road and document the bridge as optional | |
| Bridge-first docs | Lead with the bridge as the main operator experience | |
| Native paved road + read-only inspection annex | Native-first posture expressed with clearer editorial framing for the optional bridge | ✓ |

**User's choice:** Shifted-left recommendation accepted: native-first posture, expressed as one canonical paved road with an optional read-only inspection annex.
**Notes:** Recommended wording is captured in CONTEXT.md to keep README/guides/tests aligned.

---

## the agent's Discretion

- Exact harness implementation for dependency removal in the native-only lane.
- Exact smoke-proof mechanics for the bridge-enabled lane.
- Exact docs/test marker edits needed to keep wording and proof lanes aligned.

## Deferred Ideas

- Separate checked-in native-only fixture tree.
- Broad bridge parity or browser-E2E suite over Oban Web internals.
- Repositioning the bridge as the primary operator plane.
