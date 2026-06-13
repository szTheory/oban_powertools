---
phase: 57
slug: doctor-manifest-fix
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 57 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built into Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/doctor/checks_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/doctor/checks_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | INT-01 | — | N/A | integration | `mix test test/oban_powertools/doctor/checks_test.exs` | ✅ | ⬜ pending |
| 57-01-02 | 01 | 1 | INT-01 | — | N/A | integration | `mix test test/oban_powertools/doctor/checks_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No Wave 0 setup needed — `checks_test.exs` and ExUnit are already present and working (18 tests, 0 failures confirmed by research).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Error finding names `oban_powertools_job_records` when table is absent | INT-01 | Cannot be automated against the test DB (table is present); requires a DB with the migration NOT applied | Create a test DB without the Phase 55 migration, run `mix oban_powertools.doctor`, confirm error finding names the table and its group |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
