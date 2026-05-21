# Project State

## Project Reference
**Core Value:** Oban Powertools provides an "Ultimate Batteries-Included" background job operations layer for Phoenix applications in the szTheory ecosystem. It guarantees Ecto-native safety, transparent observability, and durable idempotency while rejecting per-worker limits and implicit magic.
**Current Focus:** Milestone `v1.1` is active with Phase 8 closed and Phase 9 policy-boundary hardening next.

## Current Position
- **Phase:** 9
- **Plan:** —
- **Status:** Phase 8 complete; ready to plan policy boundaries and optional bridge contracts
- **Progress:** `[#####---------------]` (1/4 phases complete)

## Performance Metrics
- **Phases Complete:** 9/9
- **Plans Complete:** 31/31
- **Metrics:** Phase 0 Plan 01 completed in 15m (Tasks: 3, Files: 5); Phase 1 Plan 01 completed in 12m (Tasks: 3, Files: 6); Phase 2 Plans 01-05 completed on 2026-05-19 with persistence, limiter, explain, cron, and native UI verification; Phase 3 Plans 01-05 completed on 2026-05-19 with durable DAG persistence, runtime signaling, workflow telemetry, and native workflow inspection; Phase 4 Plans 01-05 completed on 2026-05-19 with durable lifeline persistence, heartbeat/incident services, repair preview/execute, archive-prune retention, and the native Lifeline operator UI; Phase 5 Plans 01-05 completed on 2026-05-20 with traceability repair, restored validation/verification artifacts, normalized summary metadata, and a refreshed milestone audit; Phase 6 Plans 01-03 completed on 2026-05-20 with centralized runtime config, explicit installer wiring, cron auth-before-preview enforcement, and milestone evidence closure for `FND-01`, `FND-02`, and `ENG-03`; Phase 7 Plans 01-03 completed on 2026-05-21 with atomic incident retirement, evidence-driven reprojection, resolved-view LiveView continuity, and closed `LIF-02` verification; Phase 8 Plans 01-03 completed on 2026-05-21 with explicit host-owned install/config/router guidance, deterministic heartbeat supervision gating, a frozen nested `oban_web` bridge contract, and a documented public telemetry schema.

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
  - Phase 6 now centralizes repo/auth runtime wiring, emits explicit installer config, and renders cron mutation permissions before preview entry.
  - Phase 7 now resolves incident rows atomically during repair execution, reconciles stale active incidents during projection, reuses incident fingerprint rows on reopen, and preserves closure evidence in a resolved Lifeline view.
  - Phase 8 now documents the host-owned install/config/router contract, gates `HeartbeatWriter` startup on repo wiring, freezes the nested `/ops/jobs/oban` bridge shape, and treats the telemetry event schema as public API.
- **Todos:** None
- **Blockers:** None

## Session Continuity
- **Last Action:** Completed Phase 8 with install, supervision, route, telemetry, README, validation, and verification artifacts.
- **Next Action:** Run `$gsd-discuss-phase 9` to define the Phase 9 policy, actor, redaction, and optional-bridge seams before planning.
