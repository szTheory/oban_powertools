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
