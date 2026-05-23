---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: milestone
current_phase: "15"
current_phase_name: upgrade-lane-support-truth-public-docs-integrity
current_plan: 3
status: verifying
stopped_at: Completed 15-03-PLAN.md
last_updated: "2026-05-23T13:41:59.877Z"
progress:
  total_phases: 8
  completed_phases: 8
  total_plans: 27
  completed_plans: 27
  percent: 100
---

# Project State

## Project Reference

**Core Value:** Oban Powertools provides an "Ultimate Batteries-Included" background job operations layer for Phoenix applications in the szTheory ecosystem. It guarantees Ecto-native safety, transparent observability, and durable idempotency while rejecting per-worker limits and implicit magic.
**Current Focus:** Phase 15 — upgrade-lane-support-truth-public-docs-integrity

## Current Position

Phase: 15 (upgrade-lane-support-truth-public-docs-integrity) — VERIFYING
Plan: 3 of 3

- **Phase:** 15
- **Plan:** 3 of 3
- **Current Plan:** 3
- **Total Plans in Phase:** 3
- **Status:** Phase complete — ready for verification
- **Progress:** [██████████] 100%

## Performance Metrics

- **Phases Complete:** 12/12
- **Plans Complete:** 42/42
- **Metrics:** Phase 0 Plan 01 completed in 15m (Tasks: 3, Files: 5); Phase 1 Plan 01 completed in 12m (Tasks: 3, Files: 6); Phase 2 Plans 01-05 completed on 2026-05-19 with persistence, limiter, explain, cron, and native UI verification; Phase 3 Plans 01-05 completed on 2026-05-19 with durable DAG persistence, runtime signaling, workflow telemetry, and native workflow inspection; Phase 4 Plans 01-05 completed on 2026-05-19 with durable lifeline persistence, heartbeat/incident services, repair preview/execute, archive-prune retention, and the native Lifeline operator UI; Phase 5 Plans 01-05 completed on 2026-05-20 with traceability repair, restored validation/verification artifacts, normalized summary metadata, and a refreshed milestone audit; Phase 6 Plans 01-03 completed on 2026-05-20 with centralized runtime config, explicit installer wiring, cron auth-before-preview enforcement, and milestone evidence closure for `FND-01`, `FND-02`, and `ENG-03`; Phase 7 Plans 01-03 completed on 2026-05-21 with atomic incident retirement, evidence-driven reprojection, resolved-view LiveView continuity, and closed `LIF-02` verification; Phase 8 Plans 01-03 completed on 2026-05-21 with explicit host-owned install/config/router guidance, deterministic heartbeat supervision gating, a frozen nested `oban_web` bridge contract, and a documented public telemetry schema; Phase 9 Plans 01-03 completed on 2026-05-21 with an explicit auth and audit-principal contract, a shared display-policy seam across native operator surfaces, and a bounded optional `oban_web` bridge plus proof artifacts; Phase 10 Plan 01 completed on 2026-05-21 with a shared durable preview contract, preview-token execution gating for cron mutations, and durable-preview LiveView coverage; Phase 10 Plan 02 completed on 2026-05-21 with centralized native operator vocabulary, consistent read-only framing, and aligned audit/workflow support-truth copy; Phase 10 Plan 03 completed on 2026-05-21 with a locked read-only `/ops/jobs/oban` bridge contract, route-level proof, and README support-truth aligned to native audited mutation ownership; Phase 11 Plans 01-04 completed on 2026-05-22 with ExDoc-backed day-0/day-2 guides, the canonical `examples/phoenix_host` fixture, a narrow compatibility promise, docs contract tests, and native-only / bridge-enabled / upgrade-proof host verification; Phase 12 Plan 01 completed on 2026-05-22 with repaired fresh-host installer config/router/seam generation, deterministic Powertools migrations, and a real `mix phx.new` install-to-boot proof lane; Phase 12 Plan 03 completed in 6min (Tasks: 2, Files: 3) with a native first-session proof lane and root host-contract harness for `ops-demo`, `nightly_sync`, and `pause_cron_entry`; Phase 12 Plan 04 completed in 17min (Tasks: 2, Files: 7) with repaired public docs, docs-contract enforcement, and a dedicated `fresh-host` CI lane aligned to the canonical proof stack; Phase 14 Plans 01-02 completed on 2026-05-23 with normalized Phase 8/9 closure metadata and a rebuilt Phase 9 REQ-ID verification chain for `POL-01` and `POL-02`; Phase 14 Plan 03 completed in 2min (Tasks: 2, Files: 2) with a new Phase 10 verification artifact that closes `HST-02` through fresh LiveView, router, and docs proof; Phase 14 Plan 04 completed in 3min (Tasks: 3, Files: 2) with a cross-phase closure memo and refreshed milestone audit that mark the repaired Phase 8-10 evidence chain satisfied without moving proof ownership into Phase 14; Phase 15 Plan 01 completed in 4min (Tasks: 2, Files: 52) with a frozen archived upgrade-source fixture and commit-pinned provenance helper for the supported upgrade lane; Phase 15 Plan 02 completed in 5min (Tasks: 3, Files: 3) with a real archived-host upgrade harness, native post-upgrade cron proof, and a rewritten host-shape upgrade guide; Phase 15 Plan 03 completed in 8min (Tasks: 3, Files: 7) with five-bucket support-truth docs, host-owned hardening/troubleshooting guidance, and narrowed docs-contract markers.

## Accumulated Context

- **Decisions:** 
  - Freeze a dedicated pre-display-policy upgrade-source fixture instead of synthesizing the lane from `examples/phoenix_host`.
  - Anchor the archived source lane to commit `a1fed86` and keep regeneration maintainer-only outside CI.

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
  - Use the native `/ops/jobs/cron` LiveView as the authoritative first-session proof surface.
  - Keep the root contract deterministic with a dedicated `first_session!` helper that runs only the canonical fixture proof file.
  - Define day-0 success as compile plus migrate or reset plus one boot check before the first native operator mutation.
  - Treat `ops-demo` pausing `nightly_sync` via `pause_cron_entry` as the canonical `DOC-01` proof threshold in both docs and tests.
  - Keep the workflow explicit with a dedicated `fresh-host` lane instead of folding fresh-host proof into structural checks.
  - Use Phase 9's verification file as the canonical closure layer for `POL-01` and `POL-02` instead of moving proof ownership into Phase 14.
  - Keep `PKG-03` explicitly out of present-tense Phase 9 closure while still retaining router and bridge tests as supporting evidence.
  - Use `10-VERIFICATION.md` as the canonical `HST-02` closure layer instead of shifting proof ownership into Phase 14.
  - Treat `10-VALIDATION.md` and the Phase 10 summaries as closure inputs only while fresh 2026-05-23 reruns carry present-tense verification truth.
  - Keep Phase 14 as the maintainer-facing closure memo and index rather than the canonical proof store.
  - Refresh the milestone audit additively so it records repaired current state without erasing the 2026-05-22 findings.
  - Use `examples/phoenix_host_upgrade_source` as the only upgrade-lane fixture root instead of mutating the current fixture in place.
  - Treat `ops-demo` -> `pause_cron_entry` on `nightly_sync` as the required post-upgrade proof threshold rather than config restoration alone.
  - Use the same supported/tested/best-effort/host-owned/intentionally unsupported vocabulary in every public support-truth entrypoint.
  - Keep production-hardening prose narrative, but anchor troubleshooting claims to the exact RuntimeConfig fail-fast errors.
  - Expand docs-contract coverage to hardening and troubleshooting guides while asserting markers only, not guide paragraphs.
- **Todos:** None
- **Blockers:** None

## Session Continuity

- **Last session:** 2026-05-23T13:41:59.872Z
- **Stopped At:** Completed 15-03-PLAN.md
- **Resume File:** None
- **Last Action:** Completed Phase 15 Plan 03 with five-bucket support-truth docs, host-owned hardening and troubleshooting guidance, and narrowed docs-contract assertions.
- **Next Action:** Run final phase verification and milestone-close review for Phase 15.
