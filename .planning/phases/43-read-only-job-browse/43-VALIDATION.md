---
phase: 43
slug: read-only-job-browse
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/jobs_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/jobs_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-01 | 01 | 0 | QRY-01 | — | N/A | Unit | `mix test test/oban_powertools/jobs_test.exs` | ❌ W0 | ⬜ pending |
| 43-01-02 | 01 | 0 | QRY-02 | — | N/A | LiveView integration | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ❌ W0 | ⬜ pending |
| 43-02-01 | 02 | 1 | QRY-01 | — | `authorize_page(:view_jobs)` gates list mount | LiveView integration | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ❌ W0 | ⬜ pending |
| 43-02-02 | 02 | 1 | QRY-01 | T-InfoDisc | State leads WHERE; no sequential scan | Unit | `mix test test/oban_powertools/jobs_test.exs` | ❌ W0 | ⬜ pending |
| 43-02-03 | 02 | 1 | QRY-01 | T-InfoDisc | URL params preserved on filter change | LiveView integration | same | ❌ W0 | ⬜ pending |
| 43-02-04 | 02 | 1 | QRY-01 | T-InfoDisc | Unauthorized redirect | LiveView integration | same | ❌ W0 | ⬜ pending |
| 43-02-05 | 02 | 1 | QRY-01 | — | Read-only banner renders for restricted actor | LiveView integration | same | ❌ W0 | ⬜ pending |
| 43-03-01 | 03 | 2 | QRY-02 | T-InfoDisc | `authorize_page(:view_job_detail)` gates detail mount | LiveView integration | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ❌ W0 | ⬜ pending |
| 43-03-02 | 03 | 2 | QRY-02 | T-InfoDisc | DisplayPolicy redaction applied to args | LiveView integration | same | ❌ W0 | ⬜ pending |
| 43-03-03 | 03 | 2 | QRY-02 | T-InfoDisc | DisplayPolicy redaction applied to meta | LiveView integration | same | ❌ W0 | ⬜ pending |
| 43-03-04 | 03 | 2 | QRY-02 | — | Detail page renders all job fields (errors, attempts, timing) | LiveView integration | same | ❌ W0 | ⬜ pending |
| 43-04-01 | 04 | 1 | D-06 | — | Routes `/jobs` and `/jobs/:id` registered | Router test | `mix test test/oban_powertools/web/router_test.exs` | ✅ (extend) | ⬜ pending |
| 43-04-02 | 04 | 1 | D-20 | — | Permission atoms added to LiveAuth | Unit/compile | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/jobs_test.exs` — unit tests for `ObanPowertools.Jobs`: `list/3` state-leading WHERE, pagination, optional filters, `count_by_state/2`, `get/2`
- [ ] `test/oban_powertools/web/live/jobs_live_test.exs` — LiveView integration tests following `lifeline_live_test.exs` / `workflows_live_test.exs` pattern; needs a test display policy module at the top
- [ ] `test/oban_powertools/web/router_test.exs` — extend with assertions for `/ops/jobs/jobs` and `/ops/jobs/jobs/:id` route registration (file exists, add cases)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tags filter does not silently table-scan without GIN index | QRY-01 | Requires real Postgres EXPLAIN output; ExUnit runs in sandbox | Run `EXPLAIN ANALYZE SELECT ... WHERE state='available' AND $1 = ANY(tags)` in psql; verify Index Scan |

---

## Security Threat Model

| Pattern | STRIDE | Mitigation |
|---------|--------|-----------|
| Unauthorized job detail access | Information Disclosure | `LiveAuth.authorize_page(socket, :view_job_detail, %{type: :job, id: job_id})` in mount |
| Sensitive args/meta exposure | Information Disclosure | `DisplayPolicy.render_job_field/3` — host controls redaction via `display/3` callback |
| SQL injection via filter params | Tampering | Ecto parameterized queries — all `%JobFilter{}` values bound as params |
| Large table scan via unindexed tags filter | Denial of Service | State MUST lead WHERE (D-05); GIN index caveat documented |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
