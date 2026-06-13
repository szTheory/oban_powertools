---
phase: 56
slug: redact-at-rest
status: draft
nyquist_compliant: false
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
| TBD | TBD | TBD | REDACT-01..04 | TBD | TBD | unit/integration | `mix test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Filled by gsd-planner during planning — see 56-RESEARCH.md "Validation Architecture" for the per-invariant proof map (fingerprint-before-drop, key-absent-not-nil, single meta injection, cron coverage, required-field exemption, partition-key guard).*

---

## Wave 0 Requirements

- [ ] Test files for the `new/2` redaction override (worker.ex)
- [ ] Integration test asserting a real Postgres `oban_jobs` row has redacted keys absent + `__redacted_fields__` in meta
- [ ] Existing ExUnit infrastructure covers framework needs (no install required)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `/ops/jobs` job detail visual rendering of "Fields redacted at enqueue" | REDACT-03, REDACT-04 | LiveView visual disclosure | Enqueue a redact-worker job, open job detail, confirm args panel + meta-card copy per 56-UI-SPEC.md |

*Automated where possible; LiveView render assertions should cover most of REDACT-03/04.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
