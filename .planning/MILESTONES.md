# Milestones

## v1

- **Status:** Shipped 2026-05-21
- **Phases:** 0-7
- **Plans:** 28
- **Timeline:** 2026-05-19 -> 2026-05-21
- **Git range:** `ced2a92` -> `c94a0f8`

### Delivered

- Installer, auth, telemetry, and native Powertools shell foundation.
- Typed worker args, synchronous enqueue validation, and durable idempotency receipts.
- Global/partitioned limiters, explainability, dynamic cron, and native operator actions.
- Persisted workflow DAGs with runtime signaling and native inspection UI.
- Lifeline repair center, archive retention, runtime/auth hardening, and durable incident retirement closure.

## v1.1

- **Status:** Shipped 2026-05-23
- **Phases:** 8-15
- **Plans:** 27
- **Timeline:** 2026-05-21 -> 2026-05-23
- **Git range:** `d954292` -> `4d22f81`

### Delivered

- Froze the public host-owned install, router, supervision, auth, display-policy, and telemetry contract around `/ops/jobs`.
- Repaired the fresh-host installer and canonical fixture so day-0 install, migrate/reset, boot, and first-session proof all run end to end.
- Proved native-only operation without `oban_web` while keeping the optional `/ops/jobs/oban` bridge explicitly read-only.
- Repaired the Phase 8-10 evidence chain so policy, telemetry, and operator UX requirements are audit-closeable again.
- Replaced the synthetic upgrade path with a real archived-host upgrade lane.
- Unified README, guides, hardening, troubleshooting, and fixture docs around one explicit support-truth vocabulary.

## v1.2

- **Status:** Shipped 2026-05-25
- **Phases:** 16-26
- **Plans:** 31
- **Timeline:** 2026-05-23 -> 2026-05-25
- **Git range:** `4d22f81` -> `afa1f11`

### Delivered

- Froze the v2 workflow and step lifecycle contract with explicit durable terminal causes and a compatibility path for pre-v1.2 rows.
- Routed runtime and operator workflow mutations through one DB-first command pipeline with durable command-attempt, callback, recovery, cancel, await, signal, and expiry evidence.
- Added shared diagnosis vocabulary across native workflow and Lifeline surfaces while keeping the workflow page diagnosis-first and bounded actions routed through Lifeline.
- Closed the milestone with focused race-path proof, singular supported upgrade proof, low-cardinality telemetry markers, and support-truth docs aligned to the verified semantics.
- Backfilled the missing phase verification artifacts, repaired requirement traceability, and preserved both the failed and passed v1.2 milestone audit chain.
- Normalized the historical Phase 12 UAT artifact and cleared the remaining archival blocker so the milestone can ship from a clean closeout state.

## v1.3

- **Status:** Shipped 2026-05-26
- **Phases:** 27-31
- **Plans:** 15
- **Timeline:** 2026-05-25 -> 2026-05-26
- **Git range:** `1f92965` -> `b5c3aab`

### Delivered

- Froze one shared control-plane vocabulary and ownership contract across overview, cron, limiters, workflows, Lifeline, audit, and bounded Oban Web handoffs.
- Rebuilt `/ops/jobs` into a diagnosis-first operator overview with durable attention buckets and context-preserving drilldowns.
- Unified preview, reason, refusal, and audit posture across bounded native mutation surfaces without widening scope into a native generic queue or job dashboard.
- Aligned limiters, workflows, Lifeline, cron, and audit follow-up around one continuity-safe operator story and shared resource identity.
- Closed the milestone with support-truthful docs, repo-local proof, and example-host proof that keep the native-shell versus bridge-only contract honest.

## v1.4

- **Status:** Shipped 2026-05-27
- **Phases:** 32-42
- **Plans:** 28
- **Timeline:** 2026-05-26 -> 2026-05-27
- **Git range:** `15ff9ae` -> `b1a2f2d`
- **Files changed:** 190 | **LOC:** +26,997 / −328

### Delivered

- Durable forensic timelines and evidence bundles with shared v1.3 control-plane vocabulary, provenance model, and `/ops/jobs/forensics` investigative destination.
- Limiter history projection and cron missed-fire/delayed-fire diagnostics with explicit retention-boundary support truth for both surfaces.
- Diagnosis-first historical attention projection and advisory runbook entry surfaces that distinguish native, bridge-only, and host-owned follow-up paths.
- Runbook-guided remediation continuity — `runbook_context` persisted through preview→execute→audit — and host-owned escalation hook seams with explicit `unconfigured/invoked/failed` statuses.
- Canonical phase-level verification backfills for FRN-01/02/03 (Phase 37) and OPS-01/02 (Phase 37), closing orphaned audit traceability.
- Support-truthful docs and 10-test docs-contract coverage for the forensics/runbook operator journey (Phase 38, DOC-05 closed).
- Four named CI continuity lanes (`continuity-ver04-c1..c4`) making milestone-proof coverage merge-blocking and reproducible (Phase 39, VER-04 closed).
- Automated acceptance proxies replaced Phase 34 human UAT gates for OPS-03, RNB-01, RNB-02 (Phase 40).
- Centralized URL selector encoding and bounded atom normalization hardening; 226 tests, 0 failures (Phase 41).
- Nyquist validation compliance sweep clearing all validation gaps across phases 33, 34, 38, 39 (Phase 42).
