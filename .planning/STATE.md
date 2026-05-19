# Project State

## Project Reference
**Core Value:** Oban Powertools provides an "Ultimate Batteries-Included" background job operations layer for Phoenix applications in the szTheory ecosystem. It guarantees Ecto-native safety, transparent observability, and durable idempotency while rejecting per-worker limits and implicit magic.
**Current Focus:** Phase 4 execution for Lifeline & Repair Center, with backend plans complete and native UI still pending.

## Current Position
- **Phase:** 4
- **Plan:** 05
- **Status:** In Progress
- **Progress:** `[================----] 80%` (4/5 phases complete)

## Performance Metrics
- **Phases Complete:** 4/5
- **Plans Complete:** 16/17
- **Metrics:** Phase 0 Plan 01 completed in 15m (Tasks: 3, Files: 5); Phase 1 Plan 01 completed in 12m (Tasks: 3, Files: 6); Phase 2 Plans 01-05 completed on 2026-05-19 with persistence, limiter, explain, cron, and native UI verification; Phase 3 Plans 01-05 completed on 2026-05-19 with durable DAG persistence, runtime signaling, workflow telemetry, and native workflow inspection; Phase 4 Plans 01-04 completed on 2026-05-19 with durable lifeline persistence, heartbeat/incident services, repair preview/execute, and archive-prune retention.

## Accumulated Context
- **Decisions:** 
  - Using a 3-layer Hybrid Web UI Strategy (Powertools Shell wrapping Oban Web).
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
  - Phase 4 now includes durable heartbeat, incident, repair preview, and archive tables plus backend lifeline services for health classification, incident projection, repair preview/execute, and archive-before-delete retention.
- **Todos:** None
- **Blockers:** None

## Session Continuity
- **Last Action:** Implemented and verified Phase 4 backend plans 01-04, including persistence contracts, heartbeat/incident services, repair preview/execute, and archive/prune retention.
- **Next Action:** Execute Phase 4 Plan 05 to mount the `/ops/jobs/lifeline` route and native LiveView UI on top of the completed backend.
