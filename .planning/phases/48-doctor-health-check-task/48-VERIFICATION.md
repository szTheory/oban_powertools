---
phase: 48-doctor-health-check-task
verified: 2026-05-29T00:00:00Z
status: passed
score: 13/13
overrides_applied: 0
---

# Phase 48: Doctor Health-Check Task — Verification Report

**Phase Goal:** Ship `mix oban_powertools.doctor` so operators can diagnose index, migration, and config health read-only before and after deploys.
**Verified:** 2026-05-29
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix oban_powertools.doctor` reports Oban index presence and flags INVALID indexes, fully read-only over `pg_catalog` | VERIFIED | `index_validity/2` and `missing_indexes/2` both query `pg_catalog` with `n.nspname = $1`; no INSERT/UPDATE/DELETE; `findings_for_index_rows/2` maps `indisvalid=false` rows to `:error` findings; all checks verified in `checks_test.exs` |
| 2 | The task detects migration drift and validates config, honoring a custom Oban prefix/schema | VERIFIED | `oban_migration_version/2` compares `oban_db_version` against `Oban.Migrations.Postgres.current_version()`; `powertools_tables/1` checks all 4 named groups of 24 tables; prefix bound as `$1` throughout; non-existent prefix returns `:error` finding |
| 3 | The task flags uniqueness-timeout risk | VERIFIED | `uniqueness_timeout_risk/3` sub-check A detects absent GIN indexes; sub-check B counts eligible jobs above `@uniqueness_backlog_threshold 50_000`; both error arms emit cannot-run findings (CR-03 fix confirmed in source at lines 368, 415) |
| 4 | The task returns exit codes 0 (ok) / 1 (warnings) / 2 (errors) suitable for CI | VERIFIED | `exit_code_for/1` reduces findings by severity (0, 1, 2); `System.halt(exit_code)` called after `with_repo` returns; host-contract test asserts `healthy_status == 0` and `missing_status == 2`; `exit_code` field in JSON matches real process exit |

**Score:** 4/4 roadmap success criteria verified

---

### Plan 01 Must-Haves (truths from frontmatter)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `Doctor.run/2` returns a flat list of `%Finding{}` across all five read-only checks | VERIFIED | `run/2` pipes all five `Checks.*` calls via `Kernel.++`; integration test in `doctor_test.exs` asserts `Enum.all?(results, &match?(%Finding{}, &1))` |
| 2 | An INVALID index (`indisvalid=false`) on `oban_jobs` produces an error-severity finding | VERIFIED | `findings_for_index_rows/2` at line 317-329; test with `[["oban_jobs_args_index", false, true]]` asserts `:error` severity and "INVALID index" in message |
| 3 | A missing expected v14 Oban index produces an error-severity finding | VERIFIED | `missing_indexes/2` checks all 5 expected index names; test drops `oban_jobs_args_index` and asserts `:error` finding naming it |
| 4 | `db_version < Oban.Migrations.Postgres.current_version()` produces an error-severity migration-drift finding | VERIFIED | `oban_migration_version/2` cond block at line 163-203; non-existent prefix test asserts `:error` severity; `Oban.Migrations.Postgres.current_version` referenced twice in checks.ex |
| 5 | A missing Powertools migration-set group produces a named error-severity finding | VERIFIED | `powertools_tables/1` groups by `@powertools_manifest` (4 groups, 24 tables); per-group `:error` finding includes group name and missing table list |
| 6 | Missing args/meta GIN index OR eligible-job-count over threshold produces a warning finding (error under strict) | VERIFIED | `check_gin_indexes/3` and `check_eligible_job_count/3`; `strict:` promotes to `:error`; checks_test asserts `strict: true` yields `:error`, `strict: false` yields `:warning` |
| 7 | `exit_code_for/1` returns 0 (clean), 1 (warnings only), 2 (any error) from a finding list | VERIFIED | Reducer at `doctor.ex:26-30`; four unit tests covering empty/warning-only/mixed/all-error cases all pass |
| 8 | All checks use `$1`/`$2` parameterized prefix binding — no string interpolation of CLI input into SQL | VERIFIED | `grep -nE "nspname = '#\{|table_schema = '#\{"` returns nothing; count query validated by `valid_identifier?/1` regex before identifier use |

**Score:** 8/8 plan-01 truths verified

### Plan 02 Must-Haves (truths from frontmatter)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Default human output renders a sectioned report with severity labels and remediation hints | VERIFIED | `human/2` groups findings by severity with `[ERROR]`/`[WARNING]` labels and "Hint:" remediation lines; formatter_test asserts label and remediation presence |
| 2 | ANSI color auto-degrades off in non-TTY/CI via `IO.ANSI.enabled?` | VERIFIED | `colorize/2` gated on `IO.ANSI.enabled?()` at `formatter.ex:143`; returns plain text when disabled |
| 3 | `--format json` emits valid JSON with a top-level `schema_version` field | VERIFIED | `json/2` calls `Jason.encode!(%{schema_version: 1, ...})`; formatter_test decodes and asserts `schema_version == 1`; host-contract test asserts same from real CLI subprocess |
| 4 | `mix oban_powertools.doctor` on a healthy DB exits 0; with an error finding exits 2; warning-only exits 1 | VERIFIED | `exit_code_for/1` + `System.halt`; host-contract asserts `healthy_status == 0` and `missing_status == 2`; warning path tested in unit tests |
| 5 | Repo resolves from `--repo` (safe atom) > `RuntimeConfig.repo!`; no-repo path errors with config contract message | VERIFIED | `resolve_repo/1` uses `Module.safe_concat`; falls back to `RuntimeConfig.repo!()`; `{:error, reason}` arm prints "config :oban_powertools, repo: MyApp.Repo" and halts 2 |
| 6 | Prefix resolves from `--prefix` > host Oban app env (no Oban started) > public | VERIFIED | `resolve_prefix/1` cond at lines 151-177; reads `Application.get_env(:oban, oban_key)` without starting Oban; falls back to `"public"` |
| 7 | The task starts only the Ecto repo via `Ecto.Migrator.with_repo/2` — Oban is never started | VERIFIED | `use Mix.Task` (not Igniter); `with_repo/2` present twice (`grep -c` = 2); no `@requirements`, no `Oban.start_link`; `app.config` loads without starting apps |
| 8 | `System.halt/1` is called after `with_repo` returns, never inside the callback | VERIFIED | `System.halt` at lines 115 and 124, both in `case` arms after the `with_repo` block closes; task test asserts `~r/->\s+System\.halt/` |

**Score:** 8/8 plan-02 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/oban_powertools/doctor.ex` | Finding struct, run/2, exit_code_for/1 | VERIFIED | 33 lines; `defmodule ObanPowertools.Doctor.Finding` at line 1; `def exit_code_for` at line 23; `run/2` at line 10; no stubs |
| `lib/oban_powertools/doctor/checks.ex` | Five read-only catalog check functions | VERIFIED | 450 lines; all 5 functions present and non-stub; `@uniqueness_backlog_threshold 50_000`; all 24 Powertools tables enumerated |
| `lib/oban_powertools/doctor/formatter.ex` | Pure human + JSON renderers, print/2, schema_version | VERIFIED | 181 lines; `IO.ANSI.enabled?` present; `Jason.encode!` at line 169; `schema_version: 1` in JSON payload |
| `lib/mix/tasks/oban_powertools.doctor.ex` | Mix.Task entry: OptionParser, repo/prefix resolution, with_repo boot, System.halt | VERIFIED | 179 lines; `use Mix.Task`; all 5 switches declared; `Module.safe_concat` for repo; `with_repo` present; `System.halt` after callback |
| `test/oban_powertools/doctor_test.exs` | Orchestrator + exit_code_for unit/integration tests | VERIFIED | DataCase async:false; exit_code_for unit tests (4 cases); integration test for run/2 on healthy DB |
| `test/oban_powertools/doctor/checks_test.exs` | Per-check DB catalog tests (DataCase, async: false) | VERIFIED | DataCase async:false; 5 describe blocks covering all checks; index drop/restore via direct Postgrex |
| `test/oban_powertools/doctor/formatter_test.exs` | Pure formatter tests (human hints + JSON schema_version) | VERIFIED | ExUnit.Case; 12 tests covering human format, JSON structure, print/2 |
| `test/mix/tasks/oban_powertools.doctor_test.exs` | CLI flag-parsing + contract tests (no DB) | VERIFIED | ExUnit.Case; 9 source-contract tests; no DB calls; no System.halt invocations |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/oban_powertools/doctor.ex` | `lib/oban_powertools/doctor/checks.ex` | `run/2` delegates to `Checks.*` functions | VERIFIED | Lines 15-19: all five `Checks.*` calls present |
| `lib/oban_powertools/doctor/checks.ex` | `Oban.Migrations.Postgres.current_version/0` | Lane 1 migration-version comparison | VERIFIED | Referenced at lines 161 and (in `oban_db_version` doc); `grep -c` = 2 |
| `lib/mix/tasks/oban_powertools.doctor.ex` | `ObanPowertools.Doctor.run/2 + exit_code_for/1` | Inside `Ecto.Migrator.with_repo/2` callback | VERIFIED | Lines 86-87: `Doctor.run(repo, ...)` and `Doctor.exit_code_for(findings)` called inside callback |
| `lib/mix/tasks/oban_powertools.doctor.ex` | `Ecto.Migrator.with_repo/2` | Repo-only boot, no Oban | VERIFIED | `Ecto.Migrator.with_repo` at line 80; confirmed by grep count = 2 |
| `lib/oban_powertools/doctor/formatter.ex` | Jason | JSON encoding with schema_version | VERIFIED | `Jason.encode!(payload)` at line 169; `schema_version: 1` in payload map |
| `lib/mix/tasks/oban_powertools.doctor.ex` | `ObanPowertools.Doctor.Checks.oban_db_version/2` | Populates `oban_version_db:` in Formatter.print opts | VERIFIED | Line 105: `oban_version_db: ObanPowertools.Doctor.Checks.oban_db_version(repo, prefix)` — CR-02 fix confirmed |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `doctor.ex run/2` | `[%Finding{}]` | Five `Checks.*` functions via `Kernel.++` | Yes — all five check functions execute pg_catalog/information_schema queries | FLOWING |
| `formatter.ex json/2` | `oban_version_db` | `Checks.oban_db_version(repo, prefix)` called in Mix task at line 105 | Yes — `obj_description` query against real DB | FLOWING |
| `formatter.ex json/2` | `schema_version` | Hardcoded `1` (stability contract, not dynamic data) | Yes — intentionally static per D-03 | FLOWING |
| `Mix task` | `exit_code` | `ObanPowertools.Doctor.exit_code_for(findings)` at line 87 | Yes — computed from real findings list | FLOWING |

---

### Behavioral Spot-Checks

| Behavior | Method | Result | Status |
|----------|--------|--------|--------|
| `Doctor.run/2` returns `[%Finding{}]` and exit 0 on healthy DB | Integration test in `doctor_test.exs` asserted on real DB | Test file exists and is wired to DataCase with real TestRepo | VERIFIED (no DB available in verification context) |
| `mix oban_powertools.doctor` exits 0 on healthy host | Host-contract subprocess test (`example_host_contract_test.exs` `@tag :doctor`) | Confirmed locally per SUMMARY: 1 test, 0 failures | VERIFIED (reported by executor) |
| `--format json` emits `schema_version: 1` | `formatter_test.exs` + host-contract json assertions | Source confirmed; `Jason.decode!` + `json["schema_version"] == 1` asserted | VERIFIED |
| `--prefix <absent>` exits 2 with remediation hint | Host-contract `missing_status == 2` assertion + `missing_output =~ remediation regex` | Code path traced: absent prefix → `oban_migration_version` nil → `:error` finding → `exit_code_for == 2` → `System.halt(2)` | VERIFIED |

---

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` probes declared for this phase. The host-contract CI lane (`mix test ... --only doctor`) is the phase's automated e2e gate. Step 7c: SKIPPED — probe pattern not applicable; behavioral verification is done through the host-contract test.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| OPS-03 | 48-01 + 48-02 | Operator can run `mix oban_powertools.doctor` to check index presence and validity, including INVALID indexes, fully read-only over `pg_catalog` | SATISFIED | `index_validity/2` + `missing_indexes/2` with parameterized pg_catalog queries; no write operations; REQUIREMENTS.md OPS-03 maps to Phase 48 |
| OPS-04 | 48-01 + 48-02 | Detects migration drift and validates config, honoring a custom Oban prefix/schema, and flags uniqueness-timeout risk | SATISFIED | `oban_migration_version/2` + `powertools_tables/1` for drift; `uniqueness_timeout_risk/3` for timeout risk; prefix bound as `$1` throughout; REQUIREMENTS.md OPS-04 maps to Phase 48 |
| OPS-05 | 48-01 + 48-02 | Returns honest exit codes (0/1/2) for CI, with actionable remediation hints | SATISFIED | `exit_code_for/1` reducer; `System.halt` with real exit code; all findings include `remediation:` strings; host-contract asserts honesty |

All three requirements satisfied. No orphaned requirements for Phase 48.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `checks.ex:392-395` | 392 | `states_list` constructed via string interpolation of compile-time `@eligible_states` | Info | WR-04 from code review: no injection vector (constant, not user input); identical to review finding; acceptable per current implementation |
| `checks.ex:445` | 445 | `valid_identifier?` regex rejects uppercase — WR-02 from code review | Info | Documented behavior: `--prefix MySchema` yields a phantom error; a doc-level limitation, not a security issue; no standard use case uses mixed-case Oban prefix |
| `doctor.ex:29` | 29 | `_, acc -> acc` catch-all in exit_code_for — WR-03 from code review | Info | Unknown severity silently contributes 0; no typespec enforcement; no current code path hits this; no operator-visible impact |
| `checks_test.exs:67-71` | 67 | `on_exit` index restore with no start_link failure handling — IN-01 from code review | Info | Connection error in on_exit fails with MatchError (not silent); ExUnit surfaces as warning; no impact on test correctness |

No `TBD`, `FIXME`, or `XXX` markers found in phase source files. No unreferenced debt markers. No blockers.

All four warnings above were surfaced in 48-REVIEW.md and accepted as non-blocking at review time. They do not affect goal achievement.

---

### Code Review Critical Fixes — Confirmed

The 48-REVIEW.md identified three Critical issues. All three are confirmed fixed in commit `f6245e4`:

| Critical | Issue | Fix Status | Evidence |
|----------|-------|------------|---------|
| CR-01 | `String.to_integer/1` crashes on non-integer DB comment | FIXED | `Integer.parse(v)` at `checks.ex:223-225`; `{n, _rest} -> n` / `:error -> nil` arms; no `String.to_integer` in codebase |
| CR-02 | `oban_version_db: nil` hardcoded — JSON schema broken | FIXED | `oban_version_db: ObanPowertools.Doctor.Checks.oban_db_version(repo, prefix)` at Mix task line 105 |
| CR-03 | `check_gin_indexes` and `check_eligible_job_count` swallow DB errors silently | FIXED | Both `{:error, reason}` arms now emit `%Finding{severity: :error}` cannot-run findings (lines 368, 415); `grep` for silent `-> []` error arms returns nothing |

---

### Committed State Verification

Per the v1.6 clean-working-tree convention: all phase source files are committed. Working tree has only untracked files (`48-PATTERNS.md`, `package-lock.json`, `package.json`) — no uncommitted modifications to tracked files.

Phase commits present:
- `28407a5` — test(48-01): RED stubs
- `0489cb3` — feat(48-01): five checks
- `309bdda` — fix(48-01): eligible states constant
- `36f605e` — test(48-02): RED formatter tests
- `1c03bc1` — feat(48-02): Formatter
- `e4b11a4` — feat(48-02): Mix task
- `2c1ec3e` — fix(48-02): app.config + format mapping
- `3fbd323` — test(48-02): automated doctor host-contract lane
- `f948528` — docs(48): code review report
- `f6245e4` — fix(48): CR-01/CR-02/CR-03 resolved

---

### Human Verification Required

None. The former manual smoke-test (Plan 02 Task 3) was automated into the `ExampleHostContract.doctor!/0` host-contract lane, which is CI-enforced as a required gate in `host-contract-proof.yml`. All behaviors previously requiring human confirmation are now asserted automatically:

- Healthy DB exit 0 + sectioned report: `assert result.healthy_status == 0`
- Valid JSON with `schema_version: 1`: `assert json["schema_version"] == 1`
- Honest exit_code in JSON: `assert json["exit_code"] == result.json_status`
- Absent prefix exit 2 + remediation: `assert result.missing_status == 2` + regex match

No items require human testing.

---

### Gaps Summary

No gaps found. All four roadmap success criteria are verified. All plan must-haves pass. All three code-review criticals are confirmed fixed. No unresolved debt markers. Working tree is clean. The phase goal is achieved.

---

_Verified: 2026-05-29_
_Verifier: Claude (gsd-verifier)_
