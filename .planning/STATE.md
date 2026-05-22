---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: milestone
status: executing
last_updated: "2026-05-22T14:08:50.111Z"
progress:
  total_phases: 8
  completed_phases: 4
  total_plans: 17
  completed_plans: 15
  percent: 50
---

# Project State

## Project Reference

**Core Value:** Oban Powertools provides an "Ultimate Batteries-Included" background job operations layer for Phoenix applications in the szTheory ecosystem. It guarantees Ecto-native safety, transparent observability, and durable idempotency while rejecting per-worker limits and implicit magic.
**Current Focus:** Phase 12 — fresh-host-install-path-example-fixture-repair

## Current Position

Phase: 12 (fresh-host-install-path-example-fixture-repair) — EXECUTING
Plan: 2 of 4

- **Phase:** 12
- **Plan:** 3 of 4
- **Status:** Ready to execute Plan 12-03
- **Progress:** [█████████░] 88%

## Performance Metrics

- **Phases Complete:** 12/12
- **Plans Complete:** 41/41
- **Metrics:** Phase 0 Plan 01 completed in 15m (Tasks: 3, Files: 5); Phase 1 Plan 01 completed in 12m (Tasks: 3, Files: 6); Phase 2 Plans 01-05 completed on 2026-05-19 with persistence, limiter, explain, cron, and native UI verification; Phase 3 Plans 01-05 completed on 2026-05-19 with durable DAG persistence, runtime signaling, workflow telemetry, and native workflow inspection; Phase 4 Plans 01-05 completed on 2026-05-19 with durable lifeline persistence, heartbeat/incident services, repair preview/execute, archive-prune retention, and the native Lifeline operator UI; Phase 5 Plans 01-05 completed on 2026-05-20 with traceability repair, restored validation/verification artifacts, normalized summary metadata, and a refreshed milestone audit; Phase 6 Plans 01-03 completed on 2026-05-20 with centralized runtime config, explicit installer wiring, cron auth-before-preview enforcement, and milestone evidence closure for `FND-01`, `FND-02`, and `ENG-03`; Phase 7 Plans 01-03 completed on 2026-05-21 with atomic incident retirement, evidence-driven reprojection, resolved-view LiveView continuity, and closed `LIF-02` verification; Phase 8 Plans 01-03 completed on 2026-05-21 with explicit host-owned install/config/router guidance, deterministic heartbeat supervision gating, a frozen nested `oban_web` bridge contract, and a documented public telemetry schema; Phase 9 Plans 01-03 completed on 2026-05-21 with an explicit auth and audit-principal contract, a shared display-policy seam across native operator surfaces, and a bounded optional `oban_web` bridge plus proof artifacts; Phase 10 Plan 01 completed on 2026-05-21 with a shared durable preview contract, preview-token execution gating for cron mutations, and durable-preview LiveView coverage; Phase 10 Plan 02 completed on 2026-05-21 with centralized native operator vocabulary, consistent read-only framing, and aligned audit/workflow support-truth copy; Phase 10 Plan 03 completed on 2026-05-21 with a locked read-only `/ops/jobs/oban` bridge contract, route-level proof, and README support-truth aligned to native audited mutation ownership; Phase 11 Plans 01-04 completed on 2026-05-22 with ExDoc-backed day-0/day-2 guides, the canonical `examples/phoenix_host` fixture, a narrow compatibility promise, docs contract tests, and native-only / bridge-enabled / upgrade-proof host verification; Phase 12 Plan 01 completed on 2026-05-22 with repaired fresh-host installer config/router/seam generation, deterministic Powertools migrations, and a real `mix phx.new` install-to-boot proof lane.

## Accumulated Context

- **Decisions:** 
  Added installer-faithful fixture migrations, narrow ops-demo/nightly_sync seed state, and explicit three-bucket curated provenance guidance for examples/phoenix_host.

  - Purely Postgres/Ecto-native state management (no Redis).
  - Explicit rate limiting, explicit workflow DAGs, and a dry-run repair center.
  - Used Igniter.Mix.Task to build the setup task and inject configuration into the host app.
  - Defined strict ObanPowertools.Auth behaviour.
  - Telemetry wrapped to enforce low-cardinality metadata tags.
  - Worker `args` definitions now fail fast at compile time when malformed.
  - Idempotency fingerprints are now generated from canonicalized payloads for stable conflict detection.
  - Phase 2 now includes durable limiter resources/state, durable cron entries/slots, snapshot-backed explain output, and native `/ops/jobs` operator pages.
  - Native cron actions are preview-first and action-level authorized through the host-owned auth behavior.
  - Phase 3 now includes normalized workflow/step/edge/result persistence, explicit workflow builder APIs, DB-first runtime reconciliation, PubSub workflow hints, workflow telemetry/audit hooks, and native `/ops/jobs/workflows` inspection pages.
  - Phase 4 now includes durable heartbeat, incident, repair preview, and archive tables plus backend lifeline services for health classification, incident projection, repair preview/execute, archive-before-delete retention, and the native `/ops/jobs/lifeline` LiveView operator surface.
  - Phase 5 restored the repo-local evidence chain without rewriting implementation ownership.
  - Phase 6 now centralizes repo/auth runtime wiring, emits explicit installer config, and renders cron mutation permissions before preview entry.
  - Phase 7 now resolves incident rows atomically during repair execution, reconciles stale active incidents during projection, reuses incident fingerprint rows on reopen, and preserves closure evidence in a resolved Lifeline view.
  - Phase 8 now documents the host-owned install/config/router contract, gates `HeartbeatWriter` startup on repo wiring, freezes the nested `/ops/jobs/oban` bridge shape, and treats the telemetry event schema as public API.
  - Phase 11 now treats the docs/example-host path as a continuously verified public contract with explicit day-0/day-2 guides and a layered proof workflow.
  - Keep the fast installer regression structural and move real fresh-host proof into a separate execution lane.
  - Use nested Igniter config insertion for fresh hosts while preserving the grouped Powertools config contract.
  - Resolve the optional `oban_web` bridge at macro expansion time so native-only hosts compile cleanly.
- **Todos:** None
- **Blockers:** None

## Session Continuity

- **Last Action:** Completed Plan 12-02 with fixture migrations, narrow seed state, and curated provenance repair.
- **Next Action:** Execute Plan 12-03 for the deterministic first-session proof lane.
