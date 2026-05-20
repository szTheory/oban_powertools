# Project State

## Project Reference
**Core Value:** Oban Powertools provides an "Ultimate Batteries-Included" background job operations layer for Phoenix applications in the szTheory ecosystem. It guarantees Ecto-native safety, transparent observability, and durable idempotency while rejecting per-worker limits and implicit magic.
**Current Focus:** Phase 6 complete for Runtime Config & Authorization Hardening, including explicit runtime wiring, auth-before-preview cron enforcement, and refreshed verification evidence that closes `FND-01`, `FND-02`, and `ENG-03`.

## Current Position
- **Phase:** 6
- **Plan:** 03
- **Status:** Complete
- **Progress:** `[==================--]` (7/8 phases complete)

## Performance Metrics
- **Phases Complete:** 7/8
- **Plans Complete:** 25/25
- **Metrics:** Phase 0 Plan 01 completed in 15m (Tasks: 3, Files: 5); Phase 1 Plan 01 completed in 12m (Tasks: 3, Files: 6); Phase 2 Plans 01-05 completed on 2026-05-19 with persistence, limiter, explain, cron, and native UI verification; Phase 3 Plans 01-05 completed on 2026-05-19 with durable DAG persistence, runtime signaling, workflow telemetry, and native workflow inspection; Phase 4 Plans 01-05 completed on 2026-05-19 with durable lifeline persistence, heartbeat/incident services, repair preview/execute, archive-prune retention, and the native Lifeline operator UI; Phase 5 Plans 01-05 completed on 2026-05-20 with traceability repair, restored validation/verification artifacts, normalized summary metadata, and a refreshed milestone audit; Phase 6 Plans 01-03 completed on 2026-05-20 with centralized runtime config, explicit installer wiring, cron auth-before-preview enforcement, and milestone evidence closure for `FND-01`, `FND-02`, and `ENG-03`.

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
  - Phase 4 now includes durable heartbeat, incident, repair preview, and archive tables plus backend lifeline services for health classification, incident projection, repair preview/execute, archive-before-delete retention, and the native `/ops/jobs/lifeline` LiveView operator surface.
  - Phase 5 restored the repo-local evidence chain without rewriting implementation ownership.
  - Phase 6 now centralizes repo/auth runtime wiring, emits explicit installer config, and renders cron mutation permissions before preview entry, leaving only `LIF-02` open for implementation.
- **Todos:** None
- **Blockers:** None

## Session Continuity
- **Last Action:** Executed Phase 6 Plans 01-03, reran the requirement-mapped verification commands, and refreshed the milestone audit so `LIF-02` is the only remaining open gap.
- **Next Action:** Execute Phase 7 to close the remaining Lifeline incident-retirement integrity gap for `LIF-02`.
