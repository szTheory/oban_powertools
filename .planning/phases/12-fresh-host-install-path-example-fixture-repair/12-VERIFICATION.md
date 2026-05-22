---
phase: 12-fresh-host-install-path-example-fixture-repair
verified: 2026-05-22T22:45:34Z
status: human_needed
score: 12/12 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Read the public install and first-session docs together"
    expected: "README.md, guides/installation.md, guides/first-operator-session.md, and guides/example-app-walkthrough.md describe one consistent paved road and clearly mark host-owned follow-up."
    why_human: "Support-truth clarity and editorial honesty are partly semantic judgments; the docs contract test only proves marker presence."
  - test: "Review curated-fixture provenance wording"
    expected: "examples/phoenix_host/README.md and examples/phoenix_host/regenerate.sh read as a curated contract host, not a fully generated showcase app."
    why_human: "The repo can assert provenance markers automatically, but whether the wording overclaims generator provenance still needs human judgment."
---

# Phase 12: Fresh Host Install Path & Example Fixture Repair Verification Report

**Phase Goal:** Restore the documented day-0 install path so a fresh Phoenix host and the canonical example fixture both prove the public host-owned setup contract end to end.
**Verified:** 2026-05-22T22:45:34Z
**Status:** human_needed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A fresh Phoenix host can run `mix oban_powertools.install` without crashing. | ✓ VERIFIED | `test/support/fresh_host_contract.ex:8-42` runs `mix oban_powertools.install`; `test/oban_powertools/fresh_host_contract_test.exs:7-13` passed locally. |
| 2 | The installer emits deterministic host-owned wiring for config, route scope, migrations, and thin starter seam modules. | ✓ VERIFIED | `lib/mix/tasks/oban_powertools.install.ex:27-136` generates auth/display seams, config, scope, and migrations; `test/mix/tasks/oban_powertools.install_test.exs` passed locally. |
| 3 | A generated fresh host can compile, migrate, and boot once only the true host-owned seams are filled. | ✓ VERIFIED | `test/support/fresh_host_contract.ex:15-34` fills only auth/display seams, then runs compile, `ecto.reset`, and boot; `test/oban_powertools/fresh_host_contract_test.exs:10-35` asserts success. |
| 4 | The canonical example fixture can reset into a database that includes Powertools tables, not only base Oban tables. | ✓ VERIFIED | Checked-in migrations exist in `examples/phoenix_host/priv/repo/migrations`; serial `cd examples/phoenix_host && MIX_ENV=test mix ecto.reset` succeeded locally. |
| 5 | The fixture seeds exactly the operator-visible state needed for one honest first-session proof. | ✓ VERIFIED | `examples/phoenix_host/priv/repo/seeds.exs:4-55` seeds `ops-demo` and `nightly_sync` only; serial seed run succeeded locally. |
| 6 | Maintainers can tell which parts of the fixture came from `mix phx.new`, which came from `mix oban_powertools.install`, and which remain manual host-owned follow-up. | ✓ VERIFIED | `examples/phoenix_host/README.md:42-74` and `examples/phoenix_host/regenerate.sh:23-65` split provenance into generated vs manual buckets. |
| 7 | The repaired fixture can complete one real native operator flow after reset and seed. | ✓ VERIFIED | `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs:12-88` drives `/ops/jobs/cron` and executes `pause_cron_entry`; fixture-local test passed locally. |
| 8 | That flow writes durable audit evidence tied to the seeded operator principal. | ✓ VERIFIED | `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs:74-85` asserts persisted audit event with actor `ops-demo`; `lib/oban_powertools/audit.ex:35-91` reads real DB-backed audit rows. |
| 9 | The root proof harness can rerun the first-session lane deterministically in CI. | ✓ VERIFIED | `test/support/example_host_contract.ex:58-76` shells the fixture-local test; `test/oban_powertools/example_host_contract_test.exs:32-41` and `--only first_session` passed locally. |
| 10 | Public docs describe the repaired day-0 path exactly as the code now proves it, including compile, migrate/reset, and boot before the first native operator action. | ✓ VERIFIED | `README.md:25-68` and `guides/installation.md:29-112` document install, compile, migrate/reset, and boot; `test/oban_powertools/docs_contract_test.exs:15-30` enforces the markers. |
| 11 | The first successful operator session is defined as one real native audited mutation, not compile/reset/seed alone. | ✓ VERIFIED | `guides/first-operator-session.md:3-71` defines success as `ops-demo` pausing `nightly_sync`; `test/oban_powertools/docs_contract_test.exs:32-38` and `test/oban_powertools/example_host_contract_test.exs:32-41` enforce the same path. |
| 12 | Docs drift and proof-lane drift are both caught automatically in CI. | ✓ VERIFIED | `.github/workflows/host-contract-proof.yml:8-162` has explicit `structural`, `fresh-host`, `docs-contract`, `native-only`, `first-session`, `bridge-enabled`, and `upgrade-proof` jobs; docs contract test checks workflow wiring at `test/oban_powertools/docs_contract_test.exs:48-60`. |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mix/tasks/oban_powertools.install.ex` | Fresh-host install pipeline | ✓ VERIFIED | Config, route scope, starter seams, and migration pipeline present at `:27-136`. |
| `test/mix/tasks/oban_powertools.install_test.exs` | Structural installer regression proof | ✓ VERIFIED | Structural assertions passed locally. |
| `test/support/fresh_host_contract.ex` | Fresh-host end-to-end helper | ✓ VERIFIED | Runs `phx.new`, `deps.get`, installer, compile, reset, and boot. |
| `test/oban_powertools/fresh_host_contract_test.exs` | Root fresh-host execution proof | ✓ VERIFIED | Passed locally; asserts generated config/router/seams. |
| `examples/phoenix_host/priv/repo/migrations` | Canonical fixture Powertools migration set | ✓ VERIFIED | Contains full Powertools migrations through `20260522000034_*`. |
| `examples/phoenix_host/priv/repo/seeds.exs` | Deterministic first-session seed data | ✓ VERIFIED | Seeds `ops-demo` and `nightly_sync`; serial run succeeded locally. |
| `examples/phoenix_host/regenerate.sh` | Repeatable provenance path | ✓ VERIFIED | Rebuilds `phx.new` + installer baseline and leaves explicit manual follow-up markers. |
| `examples/phoenix_host/README.md` | Honest curated-fixture support truth | ✓ VERIFIED | Describes curated fixture and provenance buckets explicitly. |
| `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` | Fixture-local native proof | ✓ VERIFIED | Drives native cron page and asserts durable audit evidence. |
| `test/support/example_host_contract.ex` | Root fixture proof helper | ✓ VERIFIED | Wires fixture lanes and first-session shell execution. |
| `test/oban_powertools/example_host_contract_test.exs` | Root contract proof runner | ✓ VERIFIED | Full suite passed locally in 263.8s. |
| `README.md` | Concise public install contract | ✓ VERIFIED | Matches repaired install path and support boundary. |
| `guides/first-operator-session.md` | Canonical first-session definition | ✓ VERIFIED | Names `ops-demo`, `nightly_sync`, `pause_cron_entry`, and durable audit threshold. |
| `test/oban_powertools/docs_contract_test.exs` | Docs contract enforcement | ✓ VERIFIED | Passed locally. |
| `.github/workflows/host-contract-proof.yml` | CI proof lanes | ✓ VERIFIED | Explicit jobs target repaired proof files. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `test/mix/tasks/oban_powertools.install_test.exs` | `lib/mix/tasks/oban_powertools.install.ex` | structural contract assertions | ✓ WIRED | Tests assert config, seam, route, and migration markers from installer source. |
| `test/oban_powertools/fresh_host_contract_test.exs` | `test/support/fresh_host_contract.ex` | fresh-host execution helper | ✓ WIRED | Test calls `FreshHostContract.proof!/0` and asserts install/compile/migrate/boot outputs. |
| `lib/mix/tasks/oban_powertools.install.ex` | host config and router files | Igniter config and scope insertion | ✓ WIRED | `configure_new/5` at `:105-123` and `add_scope/4` at `:126-140`. |
| `examples/phoenix_host/priv/repo/migrations` | `examples/phoenix_host/priv/repo/seeds.exs` | fixture reset before seed data | ✓ WIRED | Serial `ecto.reset` then seeds succeeded locally against Powertools tables. |
| `examples/phoenix_host/regenerate.sh` | `examples/phoenix_host/README.md` | documented provenance story | ✓ WIRED | Both describe `phx.new` + installer baseline plus manual follow-up. |
| `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` | `examples/phoenix_host/priv/repo/seeds.exs` | seeded actor and cron resource | ✓ WIRED | Test consumes `ops-demo` and `nightly_sync` seeded in `seeds.exs`. |
| `test/oban_powertools/example_host_contract_test.exs` | `test/support/example_host_contract.ex` | fixture shell proof | ✓ WIRED | Root test calls both `proof!/1` and `first_session!/0`. |
| `README.md` | `guides/installation.md` | same paved-road install sequence | ✓ WIRED | Both document `mix oban_powertools.install`, compile, migrate/reset, and boot. |
| `guides/first-operator-session.md` | `test/oban_powertools/example_host_contract_test.exs` | same canonical native mutation flow | ✓ WIRED | Both use `ops-demo`, `nightly_sync`, and `pause_cron_entry`. |
| `guides/installation.md` | `test/oban_powertools/fresh_host_contract_test.exs` | same fresh-host compile/migrate/boot proof lane | ✓ WIRED | Docs steps match helper/test command sequence. |
| `test/oban_powertools/docs_contract_test.exs` | `.github/workflows/host-contract-proof.yml` | docs drift enforced in CI | ✓ WIRED | Test asserts workflow job names and proof commands directly. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` | `preview`, `event`, `entry` | `RepairPreview`, `Audit.list/2`, `Repo.get_by!/2` | Yes - reads persisted DB state after UI mutation | ✓ FLOWING |
| `examples/phoenix_host/priv/repo/seeds.exs` | `nightly_sync_attrs`, `ops_actor` | `PhoenixHostWeb.ObanPowertoolsAuth.demo_actor/0` + `Repo.insert!/2` | Yes - inserts canonical cron entry into DB | ✓ FLOWING |
| `test/support/fresh_host_contract.ex` | `install_output`, `compile_output`, `migrate_output`, `boot_output` | real `System.cmd/3` calls in temp host | Yes - captures actual command output, not static stubs | ✓ FLOWING |
| `test/support/example_host_contract.ex` | `output` for `first_session!` | real fixture `mix test --trace` invocation | Yes - output comes from fixture-local test execution | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Structural installer contract | `mix test test/mix/tasks/oban_powertools.install_test.exs` | `4 tests, 0 failures` | ✓ PASS |
| Fresh-host install/compile/migrate/boot lane | `mix test test/oban_powertools/fresh_host_contract_test.exs` | `1 test, 0 failures` | ✓ PASS |
| Canonical fixture reset and seed | `cd examples/phoenix_host && MIX_ENV=test mix ecto.reset && MIX_ENV=test mix run priv/repo/seeds.exs` | Powertools migrations ran; `ops-demo` / `nightly_sync` seeded | ✓ PASS |
| Fixture-local first-session proof | `cd examples/phoenix_host && MIX_ENV=test mix test test/phoenix_host_web/oban_powertools_first_session_test.exs` | `1 test, 0 failures` | ✓ PASS |
| Root first-session harness | `mix test test/oban_powertools/example_host_contract_test.exs --only first_session` | `1 test, 0 failures (3 excluded)` | ✓ PASS |
| Full root fixture contract suite | `mix test test/oban_powertools/example_host_contract_test.exs` | `4 tests, 0 failures` | ✓ PASS |
| Docs contract enforcement | `mix test test/oban_powertools/docs_contract_test.exs` | `4 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `PKG-01` | `12-01`, `12-02`, `12-04` | A Phoenix host app can install Oban Powertools through a documented, host-owned generator path that produces deterministic wiring for config, supervision, routes, and migrations. | ✓ SATISFIED | Fresh-host proof passed; installer emits repo/auth/display-policy config, host-owned `/ops/jobs` scope, and migration set; docs and CI enforce the same path. |
| `DOC-01` | `12-02`, `12-03`, `12-04` | A developer can complete a day-0 install and first successful operator session by following a concise documented path and example app. | ✓ SATISFIED | Fixture reset/seed passed; fixture-local native mutation writes audit evidence; root first-session lane and docs contract both pass locally. |

No orphaned Phase 12 requirements were found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/mix/tasks/oban_powertools.install.ex` | 54, 62, 68, 88 | `TODO` starter seams | ℹ️ Info | Intentional host-owned scaffolding; structural tests verify these remain thin placeholders rather than fake business logic. |
| `examples/phoenix_host/regenerate.sh` | 59-62 | explicit `TODO` manual follow-up markers | ℹ️ Info | Intentional provenance honesty; script correctly avoids claiming full generator provenance. |

### Human Verification Required

### 1. Public Docs Consistency

**Test:** Read `README.md`, `guides/installation.md`, `guides/first-operator-session.md`, and `guides/example-app-walkthrough.md` together.
**Expected:** They describe the same paved road: `mix phx.new`, add dependency, `mix oban_powertools.install`, fill host-owned seams, compile, migrate/reset, boot, then complete `pause_cron_entry` on `nightly_sync` as `ops-demo`.
**Why human:** Marker-based tests cannot judge whether the prose is actually clear, non-misleading, and proportioned correctly for a new adopter.

### 2. Curated Fixture Provenance Honesty

**Test:** Read `examples/phoenix_host/README.md` alongside `examples/phoenix_host/regenerate.sh`.
**Expected:** A maintainer would reasonably conclude the fixture is curated, partially regenerated, and still requires explicit manual host-owned follow-up.
**Why human:** This is an editorial support-truth judgment, not a binary code-path property.

### Gaps Summary

No implementation gaps were found. The phase goal is achieved in code and automated proof. Remaining work is limited to human editorial verification of support-truth wording and provenance clarity.

---

_Verified: 2026-05-22T22:45:34Z_
_Verifier: Claude (gsd-verifier)_
