---
phase: 56
slug: redact-at-rest
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-13
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/oban_powertools/worker_redact_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~existing suite runtime |

---

## Sampling Rate

- **After every task commit:** Run the relevant focused test file
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** < 60 seconds (focused file)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-T0 | 56-01 | 1 | REDACT-01,02 | T-56-01..07 | RED scaffold: key-absent, string-key, exemption, sorted meta, typo/partition guards | integration+unit | `mix test test/oban_powertools/worker_redact_test.exs` | ❌ W0 → created | ⬜ pending |
| 01-T1 | 56-01 | 1 | REDACT-01,02 | T-56-01,02,03,04,07 | new/2 override drops key-absent + injects sorted-string meta; guards raise; required exemption | integration+unit | `mix test test/oban_powertools/worker_redact_test.exs` | ✅ (T0) | ⬜ pending |
| 01-T2 | 56-01 | 1 | REDACT-01,02 | T-56-05,06 | fingerprint-before-drop; single non-clobbering meta injection | integration | `mix test test/oban_powertools/idempotency_test.exs` | ✅ existing | ⬜ pending |
| 02-T0 | 56-02 | 2 | REDACT-01,02 | T-56-08 | RED: cron-scheduled redact job leaks ssn pre-fix; plain-worker control | integration | `mix test test/oban_powertools/cron_test.exs` | ✅ existing | ⬜ pending |
| 02-T1 | 56-02 | 2 | REDACT-01,02 | T-56-08,09,10 | cron routes Powertools workers through new/2; plain unchanged; unloaded degrades | integration | `mix test test/oban_powertools/cron_test.exs` | ✅ (T0) | ⬜ pending |
| 03-T0 | 56-03 | 2 | REDACT-03,04 | T-56-11,12 | RED: disclosure + per-field overlay + empty state + host passthrough + fallback | liveview+unit | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ✅ existing | ⬜ pending |
| 03-T1 | 56-03 | 2 | REDACT-04 | T-56-12,13 | render_job_field(:job_args) overlays "Redacted at enqueue"; [redacted] fallback; host custom passthrough | unit | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ✅ (T0) | ⬜ pending |
| 03-T2 | 56-03 | 2 | REDACT-03 | T-56-11 | disclosure card near Meta; hidden when empty; neutral/read-only | liveview | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ✅ (T0) | ⬜ pending |
| 04-T0 | 56-04 | 2 | REDACT-01 | T-56-14 | RED: docs-contract lock test for redact: support truth | unit | `mix test test/oban_powertools/docs_contract_test.exs` | ✅ existing | ⬜ pending |
| 04-T1 | 56-04 | 2 | REDACT-01 | T-56-14 | guide section with D-11 verbatim boundary; no false payload-scrub assurance | unit | `mix test test/oban_powertools/docs_contract_test.exs` | ✅ (T0) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Redaction Invariant → Proof Map (from 56-RESEARCH.md)

| Invariant | Proof | Plan/Task |
|-----------|-------|-----------|
| Fingerprint-before-drop | two same-user_id/different-ssn jobs → distinct fingerprints | 56-01 T2 |
| Key-absent-not-nil | `refute Map.has_key?(job.args, "ssn")` on real row | 56-01 T0/T1 |
| Single meta injection | `__redacted_fields__` flat List(String), coexists with fingerprint meta | 56-01 T2 |
| Cron coverage | scheduled redact job has field absent + meta present | 56-02 T0/T1 |
| Required-field exemption | typed+redacted worker validates/perform :ok on stored args | 56-01 T0/T1 |
| Partition-key guard | redact ∩ partition_by raises at compile time | 56-01 T0/T1 |
| Display fallback | host policy raise → `{:fallback, "[redacted]"}` | 56-03 T0/T1 |

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/worker_redact_test.exs` — created in 56-01 T0 (override, guards, exemption, normalization, sorted meta)
- [ ] Redaction tests in `test/oban_powertools/idempotency_test.exs` — 56-01 T2 (fingerprint ordering, single non-clobber meta)
- [ ] Cron redaction tests in `test/oban_powertools/cron_test.exs` — 56-02 T0
- [ ] LiveView + render_job_field redaction tests in `test/oban_powertools/web/live/jobs_live_test.exs` — 56-03 T0
- [ ] Docs-contract lock test in `test/oban_powertools/docs_contract_test.exs` — 56-04 T0
- [ ] Existing ExUnit + DataCase + sandbox infrastructure covers framework needs (no install required)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `/ops/jobs` job detail visual rendering of "Fields redacted at enqueue" | REDACT-03, REDACT-04 | LiveView visual disclosure (color/placement nuance) | Enqueue a redact-worker job, open job detail, confirm args panel "Redacted at enqueue" + meta-card "Fields redacted at enqueue: [:ssn, :token]" per 56-UI-SPEC.md (neutral colors, no red, read-only) |

*Automated where possible; LiveView render assertions cover REDACT-03/04 copy presence; manual check confirms color/placement fidelity only.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
