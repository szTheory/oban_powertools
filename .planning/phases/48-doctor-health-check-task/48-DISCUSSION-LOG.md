# Phase 48: Doctor Health-Check Task - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 48-doctor-health-check-task
**Areas discussed:** Output format, Severity→exit mapping, Target/config discovery, Migration-drift detection
**Mode:** Advisor (full_maturity calibration tier; vendor_philosophy=thorough-evaluator from project config). Research model: sonnet. NON_TECHNICAL_OWNER=false (technical_background:true overrode inferred signals).

---

## Output Format

| Option | Description | Selected |
|--------|-------------|----------|
| Human-only + exit codes | Sectioned report, auto TTY color, 0/1/2 exit codes only; no new deps (was the advisor recommendation) | |
| Human + `--format json` now | Adds machine-readable output today | ✓ |
| Human + reserved `--format` stub | Ship flag name, reject non-human | |
| Human + `--no-color`/`--quiet` flags | Explicit color/exit-only flags | |

**User's choice:** Human + `--format json` now.
**Notes:** Advisor recommended deferring JSON over a presumed `Jason` dep cost. Verification showed `{:jason, "~> 1.4"}` is **already a declared non-optional runtime dep** (`mix.exs:50`), so JSON adds no dependency and the zero-dep mandate holds — the recommendation's objection was void. Follow-up locked: JSON carries a `schema_version` field and is documented as a stability contract (vs. ship-minimal-and-mark-unstable).

---

## Severity → Exit-Code Mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Conservative + `--strict` | Credible hard-fail default + warning→error promotion flag | ✓ |
| Fixed conservative, no override | Same default, no escape hatch | |
| Fixed lenient | Only hard failures error | |
| Per-check configurable | Operators override each finding | |

**User's choice:** Conservative + `--strict` (advisor recommendation).
**Notes:** Locked per-finding table — invalid index / missing index / migration drift / cannot-run = error(2); uniqueness-timeout risk = warning(1), promoted under `--strict`. `cannot-run` stays error, never a silent skip (honesty principle).

---

## Target / Config Discovery

| Option | Description | Selected |
|--------|-------------|----------|
| Layered precedence | flags > RuntimeConfig > Oban config | ✓ |
| CLI flags only | Explicit `--repo`/`--prefix`/`--oban-name` | |
| RuntimeConfig + app env only | Zero ceremony, but prefix not in RuntimeConfig | |
| Oban.Registry introspection | Live prefix/instances from running Oban | |

**User's choice:** Layered precedence (advisor recommendation).
**Notes:** Follow-up on boot strategy changed the precedence detail — see below. The "live Oban.Registry introspection" lane was dropped in favor of reading the host's Oban config from application env without starting Oban.

---

## Boot Strategy (follow-up under Discovery)

| Option | Description | Selected |
|--------|-------------|----------|
| Repo-only boot, no Oban start | `Ecto.Migrator.with_repo` style; truly side-effect-free | ✓ |
| Full `app.start` (boots Oban) | Simple, enables live introspection, but starts queues/workers | |
| Full boot + queues:false caveat | app.start with documented mitigation | |

**User's choice:** Repo-only boot, no Oban start (advisor recommendation).
**Notes:** Decisive: a read-only health check must not start Oban processing jobs. Consequence — no live Oban.Registry introspection; prefix resolves from flag > host Oban app-env config (read, not started) > "public".

---

## Migration-Drift Detection

| Option | Description | Selected |
|--------|-------------|----------|
| Two-lane: Oban core + PT manifest | Oban version via pg_catalog + Powertools table presence check | ✓ |
| Oban core version only | Misses Powertools table drift | |
| Powertools table presence only | Misses outdated Oban core | |
| Reuse `Oban.Migration.verify_migrated!` | Raises, internal API, no PT coverage | |

**User's choice:** Two-lane (advisor recommendation).
**Notes:** Both lanes strictly read-only, prefix-aware, no migration source files required. Manifest of `oban_powertools_*` tables versioned alongside the install task. `verify_migrated!` explicitly rejected (raises, `@doc false`, needs running pool).

## Claude's Discretion

- Human report section ordering/layout.
- Precise JSON field names/nesting (within the `schema_version` contract).
- Uniqueness-timeout-risk detection heuristic.
- Internal module decomposition.

## Deferred Ideas

- Live count / `oban_met` integration in doctor output — out of scope.
- Multi-instance `--all` enumeration via running Oban — superseded by no-side-effects boot decision.
- Auto-repair / fix mode — out of scope; doctor is read-only diagnosis.
