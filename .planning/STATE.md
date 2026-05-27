---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: milestone
current_plan: 2
status: executing
stopped_at: Completed 35-01-PLAN.md
last_updated: "2026-05-27T08:18:02.000Z"
progress:
  total_phases: 5
  completed_phases: 2
  total_plans: 13
  completed_plans: 9
  percent: 40
---

# Project State

## Project Reference

**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.
**Current Focus:** Phase 35 — runbook-guided-remediation-alert-hook-boundaries

## Current Position

Phase: 35 (runbook-guided-remediation-alert-hook-boundaries) — EXECUTING
Plan: 2 of 3

- **Phase:** 35
- **Plan:** 35-01 complete
- **Current Plan:** 2
- **Total Plans in Phase:** 3
- **Status:** Executing Phase 35
- **Progress:** [███████---] 67%
- **Canonical sequencing:** `.planning/ROADMAP.md`
- **Milestone requirements:** `.planning/REQUIREMENTS.md`
- **Strategic source of truth:** `.planning/MILESTONE-ARC.md`

## Performance Metrics

- **Phases Complete:** 2/5 active
- **Plans Complete:** 6/15 active
- **Metrics:** v1.4 has completed Phase 32 forensic bundle foundations, Phase 33 limiter/cron history diagnostics, and Phase 35 Plan 01 continuity-first remediation evidence for native runbook flows.
- **Latest Plan Metric:** 35-01 completed in 4m 39s across 3 tasks and 11 files; targeted Lifeline/Forensics and LiveView tests passed with 57 tests.

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
  - With v1.3 shipped, the default next candidate is `v1.4 Operator Forensics & SRE Runbooks`: deepen historical evidence, investigative UX, and runbook-guided remediation on top of the now-stable control-plane contract.
  - Keep the v1.4 wedge focused on investigative leverage and support truth, not on broad native queue-dashboard replacement or machine-facing automation contracts.
  - Treat missed-fire history, limiter history, evidence bundles, and remediation runbooks as Powertools-owned operator surfaces that must reuse the shared v1.3 vocabulary instead of inventing a parallel incident language.
  - Preserve explicit host-owned seams for alert delivery, escalation routing, and provider-specific runbook destinations; Powertools should explain and link, not pretend to own every downstream SRE system.
  - Phase 32 now provides the shared forensic bundle contract, chronology helpers, `/ops/jobs/forensics` destination, and stable selector continuity for workflow and Lifeline evidence.
  - Phase 33 now promotes limiter and cron into first-class forensic destinations using bounded limiter history facts, cron coverage facts, shared read models, and diagnosis-first history summaries.
  - Phase 34-01 keeps historical attention inside the existing diagnosis-first overview buckets instead of creating a raw event feed.
  - Phase 34-01 keeps overview attention links selector-only, excluding reason text, rendered copy, and preview tokens from URLs.
  - Phase 34-02 keeps runbook entries advisory read-model data rather than persisted action state.
  - Phase 34-02 uses only existing durable selectors for evidence links: workflow_id, step, incident_fingerprint, view, resource_type, and resource_id.
  - Phase 34-02 renders bridge-only and host-owned follow-up paths as bordered guidance rather than filled native action controls.
- Phase 35-01 keeps native remediation continuity as structured `runbook_context` metadata projected through audit, forensics, and LiveView evidence surfaces.
- **Todos:** None
- **Blockers:** None

## Session Continuity

- **Last session:** 2026-05-27T08:18:02.000Z
- **Stopped At:** Completed 35-01-PLAN.md
- **Resume File:** .planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-01-SUMMARY.md
- **Last Action:** Completed Phase 35 Plan 01 with continuity metadata preservation, forensic projection, and continuity-first LiveView rendering.
- **Next Action:** Execute Phase 35 Plan 02 to add explicit host-owned alert/escalation hook seams.
