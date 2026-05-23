---
phase: 15-upgrade-lane-support-truth-public-docs-integrity
verified: 2026-05-23T13:46:56Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
---

# Phase 15: Upgrade Lane, Support Truth & Public Docs Integrity Verification Report

**Phase Goal:** Replace the synthetic upgrade proof with a real supported-host lane and align public support-truth docs with what the fixture, guides, and regression suite actually prove.
**Verified:** 2026-05-23T13:46:56Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The repo contains one frozen historical host fixture that represents the singular supported upgrade source lane before the explicit `display_policy` contract. | ✓ VERIFIED | [examples/phoenix_host_upgrade_source/README.md](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/README.md:3) defines the archived fixture as the one supported upgrade source lane and [config/config.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/config/config.exs:19) omits `display_policy`. |
| 2 | Maintainers can tell exactly which historical commit the archived source fixture came from and how to regenerate it off the hot CI path. | ✓ VERIFIED | [examples/phoenix_host_upgrade_source/README.md](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/README.md:8) and [regenerate.sh](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/regenerate.sh:4) pin commit `a1fed86`; the README and script mark regeneration as maintainer-only and outside CI. |
| 3 | The archived source fixture keeps the native `/ops/jobs` shell, `repo`, `auth_module`, and Powertools migrations while intentionally omitting the current `display_policy` contract. | ✓ VERIFIED | [config/config.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/config/config.exs:19), [router.ex](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/lib/phoenix_host_web/router.ex:25), and the checked-in migrations under `examples/phoenix_host_upgrade_source/priv/repo/migrations/` preserve the supported lane prerequisites. |
| 4 | The upgrade-proof lane starts from the archived historical fixture rather than mutating the current fixture in place. | ✓ VERIFIED | [test/support/example_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/example_host_contract.ex:13) selects `@upgrade_source_fixture_dir` for the `upgrade` lane and copies that tree into a temp host. |
| 5 | The only upgrade actions performed in proof are the same host actions described in the public upgrade guide. | ✓ VERIFIED | [test/support/example_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/example_host_contract.ex:149) adds `display_policy`, restores the display policy file, and materializes proof files; [guides/upgrade-and-compatibility.md](/Users/jon/projects/oban_powertools/guides/upgrade-and-compatibility.md:21) documents the same steps. |
| 6 | After upgrade, the host proves one meaningful native operator behavior rather than only config restoration and migration success. | ✓ VERIFIED | [test/oban_powertools/example_host_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/example_host_contract_test.exs:38) asserts `ops-demo`, `nightly_sync`, and `pause_cron_entry`; `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` passed locally. |
| 7 | Public docs use one repeated five-bucket support-truth vocabulary: supported, tested, best-effort, host-owned, and intentionally unsupported. | ✓ VERIFIED | [README.md](/Users/jon/projects/oban_powertools/README.md:74), [guides/support-truth-and-ownership-boundaries.md](/Users/jon/projects/oban_powertools/guides/support-truth-and-ownership-boundaries.md:3), and [test/oban_powertools/docs_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/docs_contract_test.exs:42) repeat and enforce the same five buckets. |
| 8 | README, guide surfaces, and fixture docs all say the native `/ops/jobs` shell is primary and the optional `/ops/jobs/oban` bridge is a narrower read-only annex. | ✓ VERIFIED | [README.md](/Users/jon/projects/oban_powertools/README.md:76), [guides/support-truth-and-ownership-boundaries.md](/Users/jon/projects/oban_powertools/guides/support-truth-and-ownership-boundaries.md:9), [guides/upgrade-and-compatibility.md](/Users/jon/projects/oban_powertools/guides/upgrade-and-compatibility.md:44), and [examples/phoenix_host_upgrade_source/priv/repo/seeds.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/priv/repo/seeds.exs:52) all preserve that boundary. |
| 9 | Production-hardening and troubleshooting guidance points to real host-owned seams and real fail-fast runtime errors without turning narrative guidance into a brittle prose snapshot. | ✓ VERIFIED | [guides/production-hardening.md](/Users/jon/projects/oban_powertools/guides/production-hardening.md:7) covers auth, display policy, `/ops/jobs`, reverse-proxy, WebSocket, and telemetry; [guides/troubleshooting.md](/Users/jon/projects/oban_powertools/guides/troubleshooting.md:7) reuses the exact runtime errors from [lib/oban_powertools/runtime_config.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex:44); [docs_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/docs_contract_test.exs:73) locks only stable markers. |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/phoenix_host_upgrade_source/README.md` | provenance and support-truth notes | ✓ VERIFIED | Commit `a1fed86`, supported lane definition, best-effort exclusions, and maintainer-only replay are documented. |
| `examples/phoenix_host_upgrade_source/regenerate.sh` | commit-pinned regeneration helper | ✓ VERIFIED | Rebuilds from `a1fed86`, labels itself maintainer-only, and is not referenced by CI. |
| `examples/phoenix_host_upgrade_source/config/config.exs` | pre-`display_policy` host config | ✓ VERIFIED | Keeps `repo` and `auth_module`; omits `display_policy`. |
| `examples/phoenix_host_upgrade_source/lib/phoenix_host_web/router.ex` | archived `/ops/jobs` mount shape | ✓ VERIFIED | Preserves the host-owned `/ops/jobs` scope and nested `/oban` mount. |
| `test/support/example_host_contract.ex` | archived-fixture upgrade harness | ✓ VERIFIED | Copies the archived fixture, rewrites the local path, applies upgrade actions, and runs proof commands. |
| `test/oban_powertools/example_host_contract_test.exs` | executable upgrade-proof assertions | ✓ VERIFIED | Covers `native-only`, `bridge-enabled`, `upgrade-proof`, and `first_session`; the upgrade lane asserts native post-upgrade behavior. |
| `guides/upgrade-and-compatibility.md` | public supported upgrade lane | ✓ VERIFIED | Documents one supported source host shape, exact upgrade actions, and support buckets without phase-number history. |
| `.github/workflows/host-contract-proof.yml` | dedicated CI lane | ✓ VERIFIED | Contains explicit `upgrade-proof:` job running `mix test ... --only upgrade-proof`. |
| `README.md` | front-door support-truth summary | ✓ VERIFIED | Names the native-first shell, read-only bridge, supported upgrade lane, and five buckets. |
| `guides/support-truth-and-ownership-boundaries.md` | long-form support boundary guide | ✓ VERIFIED | Organizes the public contract around the five support-truth buckets. |
| `guides/production-hardening.md` | host-owned hardening checklist | ✓ VERIFIED | Covers auth, actor/session lookup, display policy, repo wiring, bridge exposure, reverse-proxy/WebSocket, and telemetry. |
| `guides/troubleshooting.md` | runtime errors and operator-host troubleshooting | ✓ VERIFIED | Reuses exact fail-fast setup strings and maps them to real operator-host failure modes. |
| `test/oban_powertools/docs_contract_test.exs` | narrow claim-based docs assertions | ✓ VERIFIED | Includes the hardening and troubleshooting guides and asserts stable markers instead of prose snapshots. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `examples/phoenix_host_upgrade_source/README.md` | `examples/phoenix_host_upgrade_source/regenerate.sh` | documented source commit and regeneration path | ✓ WIRED | Both point to commit `a1fed86` and the README names the script as the maintainer-only replay path. |
| `examples/phoenix_host_upgrade_source/config/config.exs` | `examples/phoenix_host_upgrade_source/lib/phoenix_host_web/router.ex` | same supported source host shape with config and route ownership both present | ✓ WIRED | The archived fixture keeps `auth_module` plus the host-owned `/ops/jobs` scope together. |
| `test/support/example_host_contract.ex` | `examples/phoenix_host_upgrade_source/config/config.exs` | fixture copy and documented upgrade actions | ✓ WIRED | The helper copies the archived fixture, then rewrites config by appending `display_policy`. |
| `guides/upgrade-and-compatibility.md` | `test/oban_powertools/example_host_contract_test.exs` | same upgrade steps and same canonical post-upgrade proof target | ✓ WIRED | Both describe and assert `ops-demo` -> `pause_cron_entry` on `nightly_sync`. |
| `README.md` | `guides/support-truth-and-ownership-boundaries.md` | shared five-bucket vocabulary | ✓ WIRED | Both repeat `supported`, `tested`, `best-effort`, `host-owned`, and `intentionally unsupported`. |
| `guides/troubleshooting.md` | `lib/oban_powertools/runtime_config.ex` | exact fail-fast setup error strings | ✓ WIRED | The guide quotes the same `:repo`, `:auth_module`, and `:display_policy` runtime messages. |
| `test/oban_powertools/docs_contract_test.exs` | `README.md` | claim-based markers for support-truth and tested lanes | ✓ WIRED | The test loads the README and asserts stable support-truth markers, lane names, and read-only wording. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `test/support/example_host_contract.ex` | `fixture_dir` / copied host tree | `@upgrade_source_fixture_dir` selected for `"upgrade"` in `prepare_host!/1`, copied with `File.cp_r!`, then upgraded via `add_display_policy_config!/1` and `restore_display_policy_file!/1` | Yes | ✓ FLOWING |
| `test/support/example_host_contract.ex` | `proof_output` | `maybe_run_upgrade_proof/2` runs `mix test --trace test/phoenix_host_web/oban_powertools_first_session_test.exs` inside the copied host | Yes | ✓ FLOWING |
| `test/oban_powertools/example_host_contract_test.exs` | `result.proof_output` | `ExampleHostContract.proof!("upgrade")` returns actual command output, which the test asserts against for `ops-demo`, `nightly_sync`, and `pause_cron_entry` | Yes | ✓ FLOWING |
| `test/oban_powertools/docs_contract_test.exs` | `source` | `@docs_files |> Enum.map(&File.read!/1) |> Enum.join("\\n")` plus workflow file read | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Docs contract stays aligned to public support markers and fail-fast errors | `mix test test/oban_powertools/docs_contract_test.exs` | `5 tests, 0 failures` | ✓ PASS |
| Archived-host upgrade proof reaches the native post-upgrade threshold | `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` | `1 test, 0 failures (3 excluded)` in 79.4s | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `PKG-02` | `15-01`, `15-02`, `15-03` | A maintainer can upgrade an existing host app between supported milestone versions using an explicit migration and compatibility guide without guessing hidden contract changes. | ✓ SATISFIED | Archived source lane with provenance in [examples/phoenix_host_upgrade_source/README.md](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/README.md:16), executable harness in [test/support/example_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/example_host_contract.ex:13), guide in [guides/upgrade-and-compatibility.md](/Users/jon/projects/oban_powertools/guides/upgrade-and-compatibility.md:7), and passing `upgrade-proof` test. |
| `HST-03` | `15-03` | A host app can understand support-truth boundaries for what Powertools guarantees versus what remains host-owned or intentionally unsupported. | ✓ SATISFIED | [README.md](/Users/jon/projects/oban_powertools/README.md:74) and [guides/support-truth-and-ownership-boundaries.md](/Users/jon/projects/oban_powertools/guides/support-truth-and-ownership-boundaries.md:7) use the same five buckets and native-vs-bridge boundary. |
| `DOC-02` | `15-03` | A developer can apply a production-hardening checklist for auth, telemetry, optional dependencies, and troubleshooting without reading internal implementation code. | ✓ SATISFIED | [guides/production-hardening.md](/Users/jon/projects/oban_powertools/guides/production-hardening.md:5), [guides/troubleshooting.md](/Users/jon/projects/oban_powertools/guides/troubleshooting.md:3), and [test/oban_powertools/docs_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/docs_contract_test.exs:73) cover and enforce those public-facing markers. |

Phase 15 requirement traceability in [.planning/REQUIREMENTS.md](/Users/jon/projects/oban_powertools/.planning/REQUIREMENTS.md:51) maps exactly to `PKG-02`, `HST-03`, and `DOC-02`. No additional Phase 15 requirement IDs were orphaned from plan frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `examples/phoenix_host/README.md` | 77 | prose mentions `TODO markers` | ℹ️ Info | Descriptive provenance note only; not a placeholder implementation and not phase-blocking. |

### Gaps Summary

No implementation or wiring gaps were found. The archived upgrade source fixture is real and provenance-pinned, the upgrade harness uses that archived source and passes the native post-upgrade proof, and the support-truth, hardening, and troubleshooting docs are aligned with the enforced docs-contract markers and runtime errors.

---

_Verified: 2026-05-23T13:46:56Z_  
_Verifier: Claude (gsd-verifier)_
