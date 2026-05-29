# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **Semantic Versioning** headings like **`[0.5.0]`** for **published
Hex releases**. The maintainer tracks internal planning milestones (v1, v1.1, v1.2,
v1.3, v1.4, v1.5, etc.) in `.planning/` — those labels describe shipped tranches of
work, **not** a second installable version axis on Hex. The library stayed at `0.1.0`
internally through five milestones before its first Hex publication. Do not map planning
milestone numbers to Hex versions.

This library remains **0.x** on Hex until a real **1.0.0** after real adopter feedback.
See [Path to 1.0](#path-to-10) below for the explicit gate.

## [Unreleased]

<!-- Phases 48-51 accumulate entries here -->

## [0.5.0] - 2026-05-29

First public release of Oban Powertools — an Ecto-native operations layer for
Oban-backed Phoenix applications that extends Oban with typed worker contracts,
durable idempotency, explicit limiter and cron controls, durable workflow semantics,
and native operator surfaces for diagnosis, repair, and audited manual operations.

### Added

#### Workers & Idempotency

- Typed worker arg schemas with `field/3` macro — compile-time validation of job
  arguments against declared types, with support for `required:`, `default:`, and
  `redact:` options.
- Synchronous enqueue validation — `insert/2` returns `{:error, changeset}` on
  invalid args before the job reaches the queue.
- Durable idempotency receipts — `idempotency_key/1` hashes worker args to produce
  a stable fingerprint; duplicate enqueues within the observation window are
  deduplicated at the DB level without requiring the caller to manage uniqueness
  tokens.

#### Limiters & Explain

- Global and partitioned rate limiters — `ObanPowertools.Limits` with configurable
  token-bucket windows, per-resource partitioning, and explicit `blocker_code`
  vocabulary for diagnosing blocked jobs.
- Explainable blocking state — `ObanPowertools.Explain` surfaces why a job is
  currently blocked (limiter, cron overlap, or queue depth) with structured output
  suitable for operator dashboards and CLI tooling.

#### Cron

- Dynamic cron with overlap policies — `ObanPowertools.Cron` manages named cron
  entries with explicit `overlap_policy` (`:skip`, `:replace`, `:run_anyway`) and
  `catch_up_policy` (`:run_once`, `:run_all`, `:skip`) so missed-fire behavior is
  documented and auditable, not silently dropped.

#### Workflows

- Explicit persisted workflow DAGs — `ObanPowertools.Workflow` stores step graphs in
  a dedicated `oban_powertools_workflows` table with durable terminal-cause vocabulary
  and additive semantics versioning.
- Coordinator signaling for rapid progression — `Workflow.signal/2` lets a completing
  step unblock its dependents without polling, reducing workflow latency under load.
- Native workflow state inspection UI — the `/ops/jobs` shell renders workflow
  progress, step outcomes, and terminal causes at `/ops/jobs/workflows`.

#### Lifeline & Repairs

- Heartbeat-backed executor health tracking — `ObanPowertools.Lifeline` monitors
  Oban queue health and surfaces stalled executors with structured incident classes.
- Dry-run repair center with durable closure behavior — all operator repairs go through
  a preview → reason → execute → audit pipeline; repairs are idempotent and
  self-closing.
- Audit logging for manual UI operations — every operator action writes a durable
  audit record via `ObanPowertools.AuditLog` with actor attribution, action type,
  target identity, and outcome.
- Archive-before-delete retention flows — `ObanPowertools.Archive` moves jobs and
  workflow records to retention tables before deletion, preserving forensic history.

#### Native `/ops/jobs` Shell

- Full native job lifecycle surface at `/ops/jobs/jobs` — browse jobs by state,
  queue, worker, and tags with URL-serialized filter state and `DisplayPolicy`
  redaction on args/meta; inspect full job detail.
- Single-job retry, cancel, and discard through the Lifeline preview/reason/execute/audit
  pipeline with a concurrent-modification guard.
- Bulk operations with independent per-job repairs and honest per-job
  success/failure reporting — no silent partial failures.
- `DisplayPolicy` behaviour for host-controlled field redaction and display formatting
  across all native operator surfaces.

#### Operator API (Single + Bulk)

- `ObanPowertools.Operator` — typed, actor-attributed programmatic surface for
  single-job mutations (retry, cancel, discard) routed through the Lifeline pipeline
  and emitting `source: "api"` telemetry within the frozen low-cardinality contract.
- Bulk Operator API — `Operator.retry_all/2`, `cancel_all/2`, `discard_all/2` run
  an independent repair per job and return per-job success/failure results; no single
  `Ecto.Multi` over N jobs, no silent bulk failure.

#### Telemetry Contract

- Frozen low-cardinality telemetry contract — `ObanPowertools.Telemetry` defines and
  publishes five event families under `[:oban_powertools, family, event_suffix]`:
  `:operator_action`, `:limiter`, `:cron`, `:workflow`, and `:lifeline`. The public
  measurement key is `:count`. Metadata keys are enumerated per family in the frozen
  `@contract` — IDs, job args, preview tokens, and free-form reasons are intentionally
  excluded.

#### Install & Migrations

- Igniter-powered installer — `mix oban_powertools.install` adds the dependency,
  configures the router, sets up auth hooks, and generates all required migrations via
  `Igniter.Libs.Ecto.gen_migration/4` directly into the host's `priv/repo/migrations/`.
- Deterministic Ecto migrations for all Powertools tables with a documented upgrade
  path and `mix ecto.migrate` idempotency.

#### Optional Oban Web Bridge

- Optional `oban_web` bridge — when `{:oban_web, optional: true}` is present, the
  `/ops/jobs` shell embeds the Oban Web dashboard at `/ops/jobs/oban` as a narrower,
  read-only complement to the native surfaces. The bridge is compile-time optional;
  the native shell is fully functional without it.

---

## Path to 1.0

Oban Powertools uses a **hybrid per-surface + stability-window gate** to determine
when each named public surface is ready to freeze at `1.0`. The library will NOT bump
to `1.0.0` until all four surfaces below have met their gate criteria — and in
practice, not until at least one **non-szTheory host** has exercised the install,
Operator API, and upgrade path in production.

**Gate criteria** (must be met for each surface):

1. The surface is **explicitly enumerated** (listed below).
2. The surface has been **exercised by at least one non-szTheory host** in a real application.
3. The surface is **free of any known breaking change** at time of evaluation.
4. The surface has survived **at least two consecutive 0.x minor releases** without a breaking change.

### Surface Checklist

#### Installer / Migration Contract

The `mix oban_powertools.install` Igniter task and the set of Ecto migrations it
generates — including the table schemas for `oban_powertools_workflows`,
`oban_powertools_workflow_steps`, `oban_powertools_audit_logs`, and all supporting
tables — constitute the installer/migration contract surface.

- [ ] Explicitly enumerated: YES (this document)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (as of 0.5.0)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

#### Operator Elixir API (Single + Bulk)

The public functions in `ObanPowertools.Operator` — `retry/2`, `cancel/2`,
`discard/2`, `retry_all/2`, `cancel_all/2`, `discard_all/2` — and their `actor:` and
`opts:` argument shapes constitute the Operator API surface.

- [ ] Explicitly enumerated: YES (this document)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (as of 0.5.0)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

#### Frozen Telemetry `@contract`

The five event families (`[:oban_powertools, family, event_suffix]`), the public
measurement key (`:count`), and the per-family allowed low-cardinality metadata keys
defined in `ObanPowertools.Telemetry.@contract` constitute the telemetry surface.
This surface was frozen at Phase 8 (v1.1) and has not changed since.

- [ ] Explicitly enumerated: YES (this document + `ObanPowertools.Telemetry` moduledoc)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (frozen since v1.1)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

#### Host-Ownership Boundary

The host-ownership boundary governs which concerns Oban Powertools owns vs. which
the host app must provide: the router mount point (`live "/ops/jobs", ...`), the auth
callback hook (`ObanPowertools.Auth` behaviour), `DisplayPolicy` module pointing, and
the supervision tree wiring. Changes to this boundary require host-app code changes.

- [ ] Explicitly enumerated: YES (this document + `guides/support-truth-and-ownership-boundaries.md`)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (as of 0.5.0)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

---

*The 1.0 clock starts when a non-szTheory host reports a successful install. At that
point, each surface enters the stability observation window and tracks
0.x minor releases without breaking changes toward the graduation gate.*
