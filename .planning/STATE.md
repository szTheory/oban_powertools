---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Unified Control Plane & Explainability
current_plan: 3
status: verifying
stopped_at: Completed 29-03-PLAN.md
last_updated: "2026-05-25T19:36:55.475Z"
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 15
  completed_plans: 9
  percent: 60
---

# Project State

## Project Reference

**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.
**Current Focus:** Phase 29 — shared-preview-reason-refusal-audit-contract (ready for verification)

## Current Position

Phase: 29 (shared-preview-reason-refusal-audit-contract) — VERIFYING
Plan: 3 of 3

- **Phase:** 29
- **Plan:** 3
- **Current Plan:** 3
- **Total Plans in Phase:** 3
- **Status:** Phase complete — ready for verification
- **Progress:** [██████████] 100%
- **Canonical sequencing:** `.planning/ROADMAP.md`
- **Milestone requirements:** `.planning/REQUIREMENTS.md`
- **Strategic source of truth:** `.planning/MILESTONE-ARC.md`

## Performance Metrics

- **Phases Complete:** 3/5
- **Plans Complete:** 9/15
- **Metrics:** Milestone v1.3 planning opened on 2026-05-25 after an adopter-facing assessment concluded the library is already strong for serious Phoenix SaaS teams, with the main remaining high-leverage gap being cross-surface operator cohesion rather than missing foundational runtime capability.

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
  - Treat the current public product story as a host-owned Oban operations layer, not as a generic orchestration platform or a mandatory Oban Web replacement.
  - The highest-leverage next milestone after v1.2 is `v1.3 Unified Control Plane & Explainability`: unify operator vocabulary, diagnosis, action policy, and overview flow across cron, limits, workflows, Lifeline, and audit so the native shell feels like one coherent product.
  - Defer full native generic job UI, broader automation/API surfaces, and feature-family expansion until the unified control-plane wedge proves real adopter leverage.
  - Keep v1.3 honest about scope: native Powertools pages plus deliberate Oban Web handoffs for generic job and queue inspection, not a surprise queue-dashboard rewrite.
  - Anchor the first concrete win on the `/ops/jobs` operator journey: what needs attention, why, and where to go next without vocabulary drift between pages.
- **Todos:** None
- **Blockers:** None

## Session Continuity

- **Last session:** 2026-05-25T19:36:55.008Z
- **Stopped At:** Completed 29-03-PLAN.md
- **Resume File:** None
- **Last Action:** Executed Phase 29 end-to-end, normalizing shared preview, reason, refusal, and audit follow-up contracts across cron, workflows, Lifeline, and the audit destination.
- **Next Action:** Run `$gsd-verify-work 29` before advancing to Phase 30.
