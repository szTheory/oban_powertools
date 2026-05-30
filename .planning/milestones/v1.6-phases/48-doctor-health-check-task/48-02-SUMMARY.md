---
phase: 48-doctor-health-check-task
plan: "02"
subsystem: doctor
tags: [doctor, mix-task, formatter, json, exit-codes, cli, e2e, host-contract]
dependency_graph:
  requires:
    - ObanPowertools.Doctor.run/2 orchestrator
    - ObanPowertools.Doctor.exit_code_for/1
    - ObanPowertools.Doctor.Finding struct
  provides:
    - ObanPowertools.Doctor.Formatter (human + JSON renderers, print/2)
    - Mix.Tasks.ObanPowertools.Doctor (CLI entry point)
    - schema_version:1 JSON stability contract
    - ExampleHostContract.doctor!/0 (automated e2e harness)
  affects:
    - lib/oban_powertools/doctor/formatter.ex
    - lib/mix/tasks/oban_powertools.doctor.ex
tech_stack:
  added: []
  patterns:
    - Pure formatter module (no Ecto/DB) with IO.ANSI.enabled? auto-degrade
    - Jason.encode! with a fixed top-level schema_version contract (D-03)
    - Plain `use Mix.Task` (NOT Igniter) with inline `Mix.Task.run("app.config")` load
    - Ecto.Migrator.with_repo/2 repo-only boot; System.halt AFTER the callback returns
    - Module.safe_concat repo resolution (never String.to_atom on CLI input — T-48-05)
    - Explicit --format string->atom mapping (no String.to_existing_atom at runtime)
    - host_contract System.cmd subprocess e2e (honest System.halt exit codes observed)
key_files:
  created:
    - lib/oban_powertools/doctor/formatter.ex
    - lib/mix/tasks/oban_powertools.doctor.ex
    - test/oban_powertools/doctor/formatter_test.exs
    - test/mix/tasks/oban_powertools.doctor_test.exs
  modified:
    - test/support/example_host_contract.ex
    - test/oban_powertools/example_host_contract_test.exs
    - .github/workflows/host-contract-proof.yml
decisions:
  - "Human-verify gate (Task 3) was AUTOMATED rather than performed manually, at the user's request: the operator smoke-test is now a CI-enforced host_contract `doctor` lane that runs the real CLI against the example host. Zero human UAT required."
  - "Loaded `Mix.Task.run(\"app.config\")` at the top of run/1 to make the host app's repo module + Oban app env available without starting any app (D-09/D-10) — avoids @requirements (forbidden by the plan) and app.start (would start Oban)."
  - "Replaced String.to_existing_atom(format) with an explicit case mapping (\"json\" -> :json, _ -> :human): the target atom is not guaranteed registered in a standalone CLI process, and explicit mapping is also a stronger T-48-05 mitigation (no atom creation from CLI input)."
metrics:
  completed: "2026-05-29T17:30:00Z"
  tasks_completed: 3
  files_created: 4
  files_modified: 3
---

# Phase 48 Plan 02: Doctor Formatter + CLI Task Summary

The operator-facing layer of `mix oban_powertools.doctor`: a pure `Doctor.Formatter` (sectioned human report with ANSI auto-degrade + `--format json` carrying a `schema_version: 1` stability contract) and the plain `Mix.Tasks.ObanPowertools.Doctor` entry point (OptionParser flags, layered repo/prefix resolution, repo-only `Ecto.Migrator.with_repo/2` boot, honest `System.halt/1` exit codes). The former manual human-verify gate is now an automated, CI-enforced end-to-end contract.

## What Was Built

### `lib/oban_powertools/doctor/formatter.ex`

Pure module (no Ecto, no DB) over `[%Finding{}]`:
- `format(findings, opts)` dispatches on `:format` (`:human` default, `:json`)
- Human renderer: sectioned report grouping findings by severity, each line showing a `[ERROR]`/`[WARNING]` label, the message, and the remediation hint; a private `colorize/2` gated on `IO.ANSI.enabled?()` (red/yellow) that returns plain text in CI/non-TTY/`NO_COLOR` (D-01)
- JSON renderer: `Jason.encode!` of a map with top-level `schema_version: 1` (D-03 stability contract, documented as CHANGELOG-tracked in the `@moduledoc`), plus `prefix`, `oban_version_installed`, `oban_version_db`, `exit_code`, and `findings` (list of check/severity/message/remediation maps)
- `print(findings, opts)` IO.puts the formatted string

### `lib/mix/tasks/oban_powertools.doctor.ex`

`use Mix.Task` (NOT Igniter) entry point:
- `@moduledoc` documents flags, the 0/1/2 exit codes, the severity table, `--strict` scope, and the `--prefix` production guidance
- `@switches [repo: :string, prefix: :string, oban_name: :string, format: :string, strict: :boolean]`, parsed with `OptionParser.parse(argv, strict: @switches)`
- Loads `Mix.Task.run("app.config")` first so the repo module + Oban app env are available **without starting any application**
- `resolve_repo/1`: `--repo` via `Module.safe_concat` (never `String.to_atom` — T-48-05) > `RuntimeConfig.repo!()` with an actionable `config :oban_powertools, repo: MyApp.Repo` error (D-08)
- `resolve_prefix/1`: `--prefix` > host Oban app env > `"public"` (D-07/D-10), reading app env without starting Oban
- Boots via `Ecto.Migrator.with_repo/2`, runs `Doctor.run` + `Formatter.print`, returns the exit code; `System.halt/1` is called in the `case` arms **after** `with_repo` returns (Pitfall 3), never inside the callback; `{:error, reason}` prints the no-repo contract message and halts 2

### Test Files

- `test/oban_powertools/doctor/formatter_test.exs` — pure `ExUnit.Case`: all-clear report, severity label + remediation presence, JSON `schema_version == 1`, finding-field round-trip, top-level `prefix`/`exit_code`
- `test/mix/tasks/oban_powertools.doctor_test.exs` — pure source-contract tests: plain `Mix.Task`, not Igniter; all five switches declared; no `@requirements`/`Oban.start_link`; `with_repo` present; no `String.to_atom(` on the repo flag; `System.halt` outside the callback

### Automated end-to-end gate (replaces manual UAT)

- `ExampleHostContract.doctor!/0` (test/support) prepares a fresh example-host copy, runs `deps.get`/`compile`/`ecto.reset`, then runs the **real** `mix oban_powertools.doctor` as a subprocess in three modes, returning raw `{output, status}` pairs
- `:doctor` lane test asserts: healthy host → exit 0 + sectioned report; `--format json` → valid JSON with `schema_version: 1` and an `exit_code` matching the process exit status (honesty); `--prefix <absent>` → exit 2 + remediation hint
- `host-contract-proof.yml` gains a required `doctor` CI lane (gate-enforced, mirroring `native-first`)

## Deviations from Plan

### Auto-fixed Issues (surfaced by the Task 3 verification, then fixed)

**1. [Rule 3 - Blocking] CLI crashed: host repo module not available**

- **Found during:** Task 3 smoke-verification against `examples/phoenix_host`
- **Issue:** `Ecto.Migrator.with_repo/2` was called without first loading the host app's config/code paths, so the resolved repo module raised `UndefinedFunctionError: PhoenixHost.Repo.config/0`. Pure unit tests could not catch this (all modules preloaded in test env).
- **Fix:** Load `Mix.Task.run("app.config")` at the start of `run/1` — loads config + code paths without starting any application (Oban stays down; D-09/D-10), and without adding the plan-forbidden `@requirements`.
- **Files modified:** `lib/mix/tasks/oban_powertools.doctor.ex`
- **Commit:** 2c1ec3e

**2. [Rule 3 - Blocking] CLI crashed: `String.to_existing_atom("human")`**

- **Found during:** Task 3 smoke-verification (after fix #1)
- **Issue:** The format flag was converted via `String.to_existing_atom`, which raised at runtime because `:human` was not guaranteed registered in the standalone CLI process (it only passed in tests where modules were preloaded).
- **Fix:** Explicit `case` mapping `"json" -> :json`, `_ -> :human`. Also a stronger T-48-05 mitigation (no atom creation from CLI input).
- **Files modified:** `lib/mix/tasks/oban_powertools.doctor.ex`
- **Commit:** 2c1ec3e

### Scope enhancement (user-directed): manual gate → automated CI contract

- **Trigger:** At the human-verify checkpoint the user asked why a human gate is needed and directed automating it / shifting left into CI so zero human UAT is required.
- **Change:** Converted the manual operator smoke-test into `ExampleHostContract.doctor!/0` + a `:doctor` host_contract lane, wired as a required lane in `host-contract-proof.yml`. The lane runs the real CLI (honest `System.halt` exit codes via subprocess) against a freshly migrated example host.
- **Files modified:** `test/support/example_host_contract.ex`, `test/oban_powertools/example_host_contract_test.exs`, `.github/workflows/host-contract-proof.yml`
- **Commit:** 3fbd323
- **Verified locally:** `mix test ... --only doctor` → 1 test, 0 failures (53s).

## Known Stubs

None.

## Threat Flags

None. Threat-model mitigations applied:
- T-48-05: `--repo`/`--oban-name` resolved via `Module.safe_concat`; no `String.to_atom` on CLI input; `--format` mapped explicitly (no dynamic atom creation)
- T-48-06: repo-only `with_repo/2` boot; no `@requirements`, no `Oban.start_link`; `app.config` loads but never starts apps — verified by the e2e lane (no Oban boot) and the source-contract unit test
- T-48-07: `System.halt/1` with `exit_code_for/1`; no-repo/db-unreachable halts 2, never 0 — verified honest by the `--prefix <absent>` e2e assertion
- T-48-08: output carries only schema/index/version metadata + authored remediation strings

## Self-Check: PASSED

Source files verified present:
- FOUND: lib/oban_powertools/doctor/formatter.ex
- FOUND: lib/mix/tasks/oban_powertools.doctor.ex
- FOUND: test/oban_powertools/doctor/formatter_test.exs
- FOUND: test/mix/tasks/oban_powertools.doctor_test.exs
- FOUND: test/support/example_host_contract.ex (doctor!/0)
- FOUND: .github/workflows/host-contract-proof.yml (doctor lane + gate)

Commits verified present:
- FOUND: 36f605e (Task 1 RED), 1c03bc1 (Formatter), e4b11a4 (Mix task)
- FOUND: 2c1ec3e (CLI runtime fixes from smoke-verify)
- FOUND: 3fbd323 (automated doctor host-contract lane)
