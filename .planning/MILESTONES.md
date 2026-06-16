# Milestones

## v1.9 Batches & Composition

- **Status:** Shipped 2026-06-16
- **Phases:** 59-63 (5 phases)
- **Plans:** 16
- **Timeline:** 2026-06-14 → 2026-06-16 (2 days)
- **Requirements:** 10/10 satisfied (BAT-01..04, CHN-01..02, BUI-01..04)
- **Test suite:** Full suite passing (583 tests, 0 failures)
- **Audit:** `tech_debt` — all requirements satisfied; non-blocking metadata and docs drift

### Delivered

Provided durable, Ecto-native batch processing and workflow composition primitives (linear chains) with Lifeline-routed recovery and native inspection UI.

- **Schemas & Foundation (BAT-01):** Dedicated `batches`, `batch_jobs`, and `callbacks` tables.
- **Execution Engine & Tracker Hooks (BAT-03, BAT-04):** Exactly-once progress tracking wired transactionally into worker lifecycle hooks. Execution of `completed` and `exhausted` callbacks via the callback outbox when batch targets are met. Includes runtime `CallbackDispatcher` plugin.
- **APIs (BAT-02, CHN-01, CHN-02):** `Batch.insert_stream/2` API for safely enqueuing massive batches via chunked inserts. Ergonomic DSL for linear Chains mapping sequentially to the outbox. State propagation support allowing downstream jobs to access durable upstream output.
- **Operations Console & Lifeline UI (BUI-01..04):** Native `/ops/jobs/batches` LiveView page with batch progress and blocked state visibility. Lifeline-routed bulk recovery action to safely retry failed jobs in a batch or stuck callbacks.

---

## v1.8 Integration Fixes

- **Status:** Shipped 2026-06-14
- **Phases:** 57-58 (2 phases)
- **Plans:** 2
- **Timeline:** 2026-06-13 → 2026-06-14 (2 days)
- **Requirements:** 2/2 satisfied (INT-01, INT-02)
- **Test suite:** Full suite passing (15 targeted integration tests)
- **Audit:** `passed` — all requirements satisfied, integration gaps closed

### Delivered

Closed the two non-blocking integration gaps deferred from the v1.7 audit before expanding capability.

- **Doctor manifest fix (INT-01):** Added `oban_powertools_job_records` to `@powertools_manifest` so Doctor correctly detects missing output-recording tables.
- **Cron deadline injection (INT-02):** Injected `__deadline_at__` meta into the cron enqueue path for `deadline:`-configured Powertools workers. Ensured metadata correctly composes with `__redacted_fields__` without side-effects on plain Oban workers.

---

## v1.7 Worker Lifecycle & Safety

- **Status:** Shipped 2026-06-13
- **Phases:** 53-56 (4 phases)
- **Plans:** 14
- **Timeline:** 2026-06-12 → 2026-06-13 (2 days)
- **Requirements:** 18/18 satisfied (HOOK-01..05, SAFE-01..04, REC-01..05, REDACT-01..04)
- **Test suite:** 507 tests, 0 failures
- **Audit:** `tech_debt` — all requirements satisfied; 2 non-blocking integration gaps deferred to v1.8

### Delivered

Equipped every `ObanPowertools.Worker` with observable lifecycle hooks, soft deadline/timeout pass-through, opt-in output recording, and at-rest field redaction. Zero new runtime dependencies.

- **Worker lifecycle hooks (HOOK-01..05):** `on_start/1`, `on_success/2`, `on_failure/2`, `on_discard/2` — observe-only, crash-caught, wrapper-owned dispatch with final-attempt classification and `worker_hook` telemetry family. Hooks never change job outcome.
- **Soft deadline + timeout (SAFE-01..04):** `deadline: :timer.hours(24)` stores `__deadline_at__` ISO8601 meta at enqueue; `perform/1` cancels expired jobs before `process/1`. `timeout: ms` generates overridable `timeout/1`. Doctor warns on retryable expired-deadline jobs. Docs-contract locked.
- **Output recording (REC-01..05):** New `oban_powertools_job_records` table with `ObanPowertools.JobRecord` schema. `record_output: true` persists `{:ok, payload}` before `on_success` hooks. `fetch_result/1` API. Recorded Output card in `/ops/jobs` detail via `:job_recorded` DisplayPolicy. Lifeline prunes ephemeral records. Best-effort — recording failures log and return `:ok`.
- **At-rest redaction (REDACT-01..04):** `redact: [:ssn]` drops PII from `args` after fingerprint via `new/2` override. `__redacted_fields__` meta injected. Cron path fixed (sentinel routing). "Fields redacted at enqueue" disclosure block in job detail. Per-field "Redacted at enqueue" overlay in args panel. Docs-contract locked.

### Known Deferred Items at Close

- INT-01 (non-blocking): `oban_powertools_job_records` absent from `@powertools_manifest` in Doctor — Doctor silent if Phase 55 migration not run. Fix in v1.8.
- INT-02 (non-blocking): Cron path does not inject `__deadline_at__` meta for `deadline:`-configured workers. Fix in v1.8.
- Nyquist `wave_0_complete: false` in phases 53, 54, 56 — formal TDD wave capture not recorded in VALIDATION.md.

---

## v1.6 Release & Operability

- **Status:** Shipped 2026-05-30
- **Phases:** 47-52.1 (7 phases including inserted 52.1)
- **Plans:** 16
- **Timeline:** 2026-05-29 → 2026-05-30 (2 days)
- **Git range:** `0d5b86f` → `71b0760`
- **Code:** 121 files changed, +16,574 / −222 LOC (new modules: Doctor, Limits.compute_reservation/4, Telemetry, Glossary, Mix.Tasks.ObanPowertools.Doctor, .Limiter.Explain, .Limiter.Simulate)
- **Requirements:** 13/13 satisfied (REL-01..04, OPS-03..08, TEL-01..03); milestone audit `gaps_found` → all closed by Phase 52.1
- **Test suite:** 428 tests, 0 failures

### Delivered

Published Oban Powertools to hex.pm at `0.5.0` and shipped the two named operability footguns with zero new runtime dependencies.

- **Hex publication (REL-01/02/03):** Full release-please CI/CD pipeline — `release-please` → `gate-ci-green` → `publish-hex` → `verify-published`. Zero-touch release automerge via `release-pr-automerge.yml`. Apache-2.0 LICENSE, Keep-a-Changelog CHANGELOG.md with path-to-1.0.
- **Doctor CLI (OPS-03/04/05):** `mix oban_powertools.doctor` — five read-only `pg_catalog` checks (index validity, INVALID detection, migration drift, Powertools tables, uniqueness-timeout risk), human + `schema_version: 1` JSON output, 0/1/2 CI exit codes, actionable remediation hints.
- **Limiter CLI (OPS-06/07/08):** `mix oban_powertools.limiter.explain` (blocking-state diagnosis over existing `Explain` API) and `mix oban_powertools.limiter.simulate` (pure `compute_reservation/4` — no DB, no mutations). Rate-limit glossary locked by `docs_contract_test.exs`.
- **Telemetry metrics (TEL-01/02):** Opt-in `ObanPowertools.Telemetry.metrics/0` — 17 `Telemetry.Metrics` counters over the frozen low-cardinality contract. `telemetry_metrics`/`telemetry_poller` optional deps (gated like `oban_web`). `Code.ensure_loaded?` guard.
- **SLO guide (TEL-03):** `guides/telemetry-and-slos.md` — reporter-agnostic Operations/SLO guide, Parapet as one consumer, explicit no-`oban_met` framing.
- **Published-package verification (REL-04):** `examples/hex_consumer/` Phoenix app with `{:oban_powertools, "~> 0.5"}` hex dep; first-session test proved green via path-dep swap; `verify-published` CI job gates release pipeline on real published tarball; Phase 52.1 fixed Igniter committed-modules conflict.

### Known Deferred Items at Close

- Live CI E2E run for `verify-published` (REL-04) — static fix in place (Phase 52.1); live gate resolves on next release cycle.
- Phase 47 missing `VERIFICATION.md` — process gap; external evidence strong (0.5.0 live, hexdocs renders, VALIDATION.md 35 green tests).
- Doctor/limiter CLI/telemetry in-repo verified but not in published 0.5.0 — awaiting 0.5.1 release-please PR merge.

---

## v1.5 Native Job Surface & Automation API

- **Status:** Shipped 2026-05-28
- **Phases:** 43-46
- **Plans:** 9
- **Timeline:** 2026-05-27 -> 2026-05-28
- **Git range:** `6468cff` -> `0ea569d`
- **Code:** 12 files changed, +2071/-11 (3 new modules: `Jobs`, `Operator`, `Web.JobsLive`)
- **Requirements:** 6/6 satisfied (QRY-01..04, API-01..02); milestone audit `passed`

### Delivered

Closed the UI asymmetry with Oban Web by shipping a native operator job surface, plus a typed Elixir API for the same audited mutations.

- **Native job browse (QRY-01, QRY-02):** Ecto-native `ObanPowertools.Jobs` context with `%JobFilter{}`, state-leading queries, offset pagination (keyset upgrade path documented), and a `/ops/jobs/jobs` list + detail surface — filter by state/queue/worker/tags with URL-serialized filter state and `DisplayPolicy.render_job_field/3` redaction on args/meta.
- **Single-job actions (QRY-03):** Retry/cancel/discard from the detail page through the full Lifeline preview → reason → execute → audit pipeline, with a concurrent-modification (`preview_drifted`) guard and no direct `Oban` calls from the LiveView.
- **Bulk operations (QRY-04):** MapSet-backed multi-select with capped selection, an independent `Lifeline.execute_repair` per job (no single `Ecto.Multi` wrapping N jobs), and honest per-job success/failure reporting.
- **Operator Elixir API (API-01, API-02):** `ObanPowertools.Operator` typed single + bulk retry/cancel/discard requiring a non-nil actor, routed through the same Lifeline pipeline as the UI, emitting `source: "api"` telemetry within the frozen low-cardinality `@contract`.

### Notes

- Phases 44 and 45 had completed SUMMARY files but their `JobsLive` UI implementation was never committed during execution; it was recovered from the working tree and committed as `0ea569d` during milestone close (full suite: 270 tests, 0 failures). A malformed test-file tail and a corrupted ROADMAP table row were also repaired at close.

---

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
