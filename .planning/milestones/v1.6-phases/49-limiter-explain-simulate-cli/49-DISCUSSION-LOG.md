# Phase 49: Limiter Explain/Simulate CLI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 49-limiter-explain-simulate-cli
**Areas discussed:** Explain target contract, Simulate input source
**Mode:** Advisor (repo-grounded, decisive). Per project Decision Posture + USER-PROFILE, clear-cut areas were locked as decisive defaults rather than re-litigated; only the two operator-facing public-flag-contract decisions were escalated.

---

## Explain target contract (OPS-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Resource+partition, worker fallback | `--resource NAME [--partition KEY]` primary (UI/forensics vocabulary), `--worker MOD --args JSON` secondary for `Explain.explain/3` parity | ✓ |
| Worker + args only | Only `--worker MOD --args JSON`, 1:1 with `Explain.explain/3`; simplest but worse production-diagnosis DX | |

**User's choice:** Resource+partition with worker fallback.
**Notes:** Operators diagnosing live blocks think in resource name + partition (what the Limiters UI and forensics show), not worker module + JSON args. → CONTEXT D-03/D-04.

---

## Simulate input source (OPS-07)

| Option | Description | Selected |
|--------|-------------|----------|
| Worker-declared config + overrides | `--worker MOD` reads declared `:limits`; override via `--bucket-capacity/--bucket-span-ms/--weight/--count/--partition` | ✓ |
| Explicit flags only | Operator supplies all numbers via flags; no worker introspection; can't validate real declarations | |

**User's choice:** Worker-declared config with flag overrides.
**Notes:** Both options are pure/in-memory; the question was only config source. Side-effect-freedom is achieved by extracting a pure token-bucket core (not transaction rollback, which leaks telemetry). → CONTEXT D-05/D-06/D-07.

---

## Claude's Discretion

Locked as decisive defaults (resolvable from the repo + Ecto/Elixir norms, per Decision Posture — not escalated):

- **Mirror the Doctor task** (Phase 48) for all CLI conventions: `--repo`/`--prefix`/`--oban-name`, `--format human|json` with `schema_version: 1`, `app.config` + `Ecto.Migrator.with_repo` boot, `Module.safe_concat` resolution, honest exit codes. → D-01/D-02.
- **Pure token-bucket core extraction** to satisfy "no mutation" + "no duplicated logic" simultaneously (rejected rollback-transaction reuse — leaks non-transactional telemetry). → D-06.
- **Glossary** as a `@moduledoc` section from a single shared string that also feeds `guides/limits-and-explain.md`. → D-08.
- Human-format layout, flag short-forms, optional `--glossary` flag, and exact module placement of the pure core left to planner/executor.

## Deferred Ideas

- CLI mutating limiter actions (cooldown/reserve/release) — stays in Elixir API + UI.
- Telemetry/SLO surface + Parapet guide — Phase 50 (TEL-01/02/03).
- Richer time-advancing multi-span simulation timeline — beyond OPS-07; revisit only on adopter demand.
