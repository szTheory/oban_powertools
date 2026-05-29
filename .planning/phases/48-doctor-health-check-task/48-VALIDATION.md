---
phase: 48
slug: doctor-health-check-task
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-29
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir, `mix test`) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/doctor_test.exs test/oban_powertools/doctor/ test/mix/tasks/oban_powertools.doctor_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15-30 seconds (doctor subset); full suite ~60s |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/doctor_test.exs test/oban_powertools/doctor/ test/mix/tasks/oban_powertools.doctor_test.exs --max-failures 3`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green + operator smoke-verify (48-02 Task 3) approved
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | OPS-05 | — | exit_code_for/1 maps findings to 0/1/2 by max severity; cannot-run never returns clean | unit | `mix test test/oban_powertools/doctor_test.exs` | ❌ W0 (this task creates it) | ⬜ pending |
| 48-01-02 | 01 | 1 | OPS-03, OPS-04 | T-48-01 / T-48-02 / T-48-03 | prefix bound as $1; catalog reads scoped to namespace; query error → cannot-run error finding | integration (DB) + unit (rows helper) | `mix test test/oban_powertools/doctor/checks_test.exs` | ❌ W0 (48-01-01 stub) | ⬜ pending |
| 48-01-03 | 01 | 1 | OPS-04, OPS-05 | T-48-01 / T-48-04 | uniqueness risk = warning default / error under --strict; SELECT-only count; no Oban start | integration (DB) + unit | `mix test test/oban_powertools/doctor_test.exs test/oban_powertools/doctor/checks_test.exs` | ✅ (extends 48-01 files) | ⬜ pending |
| 48-02-01 | 02 | 2 | OPS-05 | T-48-08 | JSON carries schema_version: 1; ANSI auto-degrades; output exposes no PII/job args | unit (pure) | `mix test test/oban_powertools/doctor/formatter_test.exs` | ❌ W0 (this task creates it) | ⬜ pending |
| 48-02-02 | 02 | 2 | OPS-03, OPS-04, OPS-05 | T-48-05 / T-48-06 / T-48-07 / T-48-SC | safe atom resolution; repo-only with_repo boot (no Oban); honest System.halt after callback | unit (CLI, no DB, no halt) | `mix test test/mix/tasks/oban_powertools.doctor_test.exs` | ❌ W0 (this task creates it) | ⬜ pending |
| 48-02-03 | 02 | 2 | OPS-03, OPS-04, OPS-05 | T-48-06 / T-48-07 | end-to-end CLI exits 0/1/2 honestly; no Oban start logs; remediation hints visible | manual (human-verify) | `cd examples/phoenix_host && mix oban_powertools.doctor` (+ `--format json`, `echo $?`) | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

All doctor test files are new and are created as the first step of the plan tasks that depend on them (Nyquist-compliant — each code-producing task ships its automated verify):

- [ ] `test/oban_powertools/doctor_test.exs` — created by 48-01-01 (orchestrator + exit_code_for, OPS-05); extended by 48-01-03 (run/2 integration)
- [ ] `test/oban_powertools/doctor/checks_test.exs` — scaffolded by 48-01-01 (DataCase, async: false, five named describe blocks), filled by 48-01-02 / 48-01-03 (OPS-03, OPS-04)
- [ ] `test/oban_powertools/doctor/formatter_test.exs` — created by 48-02-01 (OPS-05 output rendering)
- [ ] `test/mix/tasks/oban_powertools.doctor_test.exs` — created by 48-02-02 (CLI flag/contract, OPS-03/04/05 wiring)

No framework install needed — ExUnit + `ObanPowertools.DataCase` + `ObanPowertools.TestRepo` already exist.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| End-to-end `mix oban_powertools.doctor` exit code + read-only boot (no Oban start) | OPS-03, OPS-04, OPS-05 | A Mix task calling `System.halt/1` cannot be invoked in-process within ExUnit without terminating the BEAM; "no Oban started" is observed via runtime logs | 48-02 Task 3: run the task against the example host, confirm exit 0 on healthy DB, valid JSON with `schema_version`, no Oban/queue log lines, and a `REINDEX` hint + exit 2 after dropping an expected index |

The CLI's pure logic (flag parsing, repo/prefix resolution, severity/exit-code mapping, formatting) IS automated; only the halting end-to-end invocation and the "no Oban start" runtime observation are manual.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are explicit human-verify checkpoints (48-02-03)
- [x] Sampling continuity: no 3 consecutive code tasks without automated verify
- [x] Wave 0 covered: all new test files created by the task that needs them (first-step scaffolds)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-29
