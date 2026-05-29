---
phase: 48
slug: doctor-health-check-task
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
validated: 2026-05-29
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
| 48-01-01 | 01 | 1 | OPS-05 | — | exit_code_for/1 maps findings to 0/1/2 by max severity; cannot-run never returns clean | unit | `mix test test/oban_powertools/doctor_test.exs` | ✅ | ✅ green |
| 48-01-02 | 01 | 1 | OPS-03, OPS-04 | T-48-01 / T-48-02 / T-48-03 | prefix bound as $1; catalog reads scoped to namespace; query error → cannot-run error finding | integration (DB) + unit (rows helper) | `mix test test/oban_powertools/doctor/checks_test.exs` | ✅ | ✅ green |
| 48-01-03 | 01 | 1 | OPS-04, OPS-05 | T-48-01 / T-48-04 | uniqueness risk = warning default / error under --strict; SELECT-only count; no Oban start | integration (DB) + unit | `mix test test/oban_powertools/doctor_test.exs test/oban_powertools/doctor/checks_test.exs` | ✅ | ✅ green |
| 48-02-01 | 02 | 2 | OPS-05 | T-48-08 | JSON carries schema_version: 1; ANSI auto-degrades; output exposes no PII/job args | unit (pure) | `mix test test/oban_powertools/doctor/formatter_test.exs` | ✅ | ✅ green |
| 48-02-02 | 02 | 2 | OPS-03, OPS-04, OPS-05 | T-48-05 / T-48-06 / T-48-07 / T-48-SC | safe atom resolution; repo-only with_repo boot (no Oban); honest System.halt after callback | unit (CLI, no DB, no halt) | `mix test test/mix/tasks/oban_powertools.doctor_test.exs` | ✅ | ✅ green |
| 48-02-03 | 02 | 2 | OPS-03, OPS-04, OPS-05 | T-48-06 / T-48-07 | end-to-end CLI exits 0/1/2 honestly; no Oban start logs; remediation hints visible | **automated** integration (CI subprocess e2e) — was manual, automated during execution | `mix test test/oban_powertools/example_host_contract_test.exs --only doctor` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

All doctor test files are new and are created as the first step of the plan tasks that depend on them (Nyquist-compliant — each code-producing task ships its automated verify):

- [x] `test/oban_powertools/doctor_test.exs` — created by 48-01-01 (orchestrator + exit_code_for, OPS-05); extended by 48-01-03 (run/2 integration)
- [x] `test/oban_powertools/doctor/checks_test.exs` — scaffolded by 48-01-01 (DataCase, async: false, five named describe blocks), filled by 48-01-02 / 48-01-03 (OPS-03, OPS-04)
- [x] `test/oban_powertools/doctor/formatter_test.exs` — created by 48-02-01 (OPS-05 output rendering)
- [x] `test/mix/tasks/oban_powertools.doctor_test.exs` — created by 48-02-02 (CLI flag/contract, OPS-03/04/05 wiring)

No framework install needed — ExUnit + `ObanPowertools.DataCase` + `ObanPowertools.TestRepo` already exist.

---

## Manual-Only Verifications

**None.** The phase has zero remaining manual verifications.

The end-to-end CLI gate originally planned as manual (48-02-03) was **automated during execution** at the user's request. The `System.halt`-terminating, "no Oban started" end-to-end invocation that cannot run in-process within ExUnit is now exercised out-of-process by `ExampleHostContract.doctor!/0`, which runs the **real** `mix oban_powertools.doctor` as a subprocess against a freshly migrated example host and asserts: healthy → exit 0 + sectioned report; `--format json` → valid JSON with `schema_version: 1` and an `exit_code` matching the honest process exit status; `--prefix <absent>` → exit 2 + remediation hint. It is wired as a required `doctor` lane in `.github/workflows/host-contract-proof.yml` (gate-enforced via the `ci-gate` aggregator), so the operator smoke-test is now CI-enforced with zero human UAT.

The CLI's pure logic (flag parsing, repo/prefix resolution, severity/exit-code mapping, formatting) is automated by unit tests; the halting end-to-end invocation and the "no Oban start" runtime observation are automated by the subprocess host-contract lane.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are explicit human-verify checkpoints (48-02-03)
- [x] Sampling continuity: no 3 consecutive code tasks without automated verify
- [x] Wave 0 covered: all new test files created by the task that needs them (first-step scaffolds)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-29

---

## Validation Audit 2026-05-29

Retroactive Nyquist audit (`/gsd-validate-phase 48`) against the executed codebase. The planning-time VALIDATION.md showed all tasks `⬜ pending`; this audit reconciled it with what was actually shipped.

| Metric | Count |
|--------|-------|
| Requirements audited | 6 task rows (OPS-03, OPS-04, OPS-05) |
| COVERED (green automated) | 6 |
| PARTIAL | 0 |
| MISSING | 0 |
| Gaps found | 0 |
| Resolved | 0 (none needed) |
| Escalated to manual | 0 |

**Evidence:**
- `mix test` over the four doctor test files (`doctor_test.exs`, `doctor/checks_test.exs`, `doctor/formatter_test.exs`, `mix/tasks/oban_powertools.doctor_test.exs`) → **45 tests, 0 failures**.
- Threat-model source greps all clean: no prefix interpolation in `checks.ex` (T-48-01/02); no `@requirements`/`Oban.start_link`/write-path in core (T-48-04); no `use Igniter.Mix.Task`/`String.to_atom`/`Oban.start_link` in the Mix task (T-48-05/06/07); `Ecto.Migrator.with_repo` and `schema_version` present.
- Former manual gate 48-02-03 reclassified COVERED: automated as the `doctor` host-contract lane (`example_host_contract_test.exs --only doctor`), wired into the `ci-gate` aggregator in `host-contract-proof.yml`.

**Result:** Phase 48 is Nyquist-compliant — every requirement has automated verification and no manual-only items remain. No test generation required.
