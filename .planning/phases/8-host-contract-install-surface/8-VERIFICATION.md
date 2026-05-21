---
phase: 8-host-contract-install-surface
verified: 2026-05-21T16:25:01Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
---

# Phase 8: Host Contract & Install Surface Verification Report

**Phase Goal:** Make the public host-owned install/config/supervision/route contract explicit and verifiable.
**Verified:** 2026-05-21T16:25:01Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A host can follow one explicit generator-backed install/config contract for Powertools wiring. | ✓ VERIFIED | Installer config comment makes host ownership explicit for `repo` and `auth_module`, and installer code owns router scope plus migration pipeline in [lib/mix/tasks/oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:49), [lib/mix/tasks/oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:78), and [lib/mix/tasks/oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:92). Installer tests lock those contracts in [test/mix/tasks/oban_powertools.install_test.exs](/Users/jon/projects/oban_powertools/test/mix/tasks/oban_powertools.install_test.exs:9). README publishes the same path in [README.md](/Users/jon/projects/oban_powertools/README.md:21). |
| 2 | The library owns supervision, and missing host repo wiring no longer crashes boot through unconditional `HeartbeatWriter` startup. | ✓ VERIFIED | `ObanPowertools.Application` only appends `HeartbeatWriter` when `RuntimeConfig.repo()` is present in [lib/oban_powertools/application.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/application.ex:40). Test coverage proves configured inclusion and unconfigured omission in [test/oban_powertools/application_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/application_test.exs:8). |
| 3 | Persistence-backed runtime services still fail fast with one explicit shared repo-setup error when started directly without host wiring. | ✓ VERIFIED | `HeartbeatWriter.init/1` resolves its repo through `RuntimeConfig.repo!(opts)` in [lib/oban_powertools/lifeline/heartbeat_writer.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline/heartbeat_writer.ex:18), and the direct-start failure path is asserted in [test/oban_powertools/application_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/application_test.exs:45). |
| 4 | The host owns the outer `/ops/jobs` shell while the library owns the inner native route tree and optional nested bridge shape. | ✓ VERIFIED | Router docs state the ownership boundary and Phase 9 deferral in [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex:10). The fixture router mounts the macro under host scope in [test/support/test_router.ex](/Users/jon/projects/oban_powertools/test/support/test_router.ex:20), and route tests prove native pages under `/ops/jobs`, no root `/oban`, and conditional nested bridge resolution at `/ops/jobs/oban` in [test/oban_powertools/web/router_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/router_test.exs:11). |
| 5 | The optional `oban_web` bridge remains narrowly scoped to nested path plus shared `LiveAuth`, without Phase 9 resolver/policy seams. | ✓ VERIFIED | The macro mounts `oban_dashboard(path, on_mount: [ObanPowertools.Web.LiveAuth])` only when `Oban.Web.Router` is loaded in [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex:45). Tests assert the `LiveAuth` hook and refute `resolver:` in [test/oban_powertools/web/router_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/router_test.exs:53). |
| 6 | Operators and integrators can rely on one documented public telemetry contract for event families, measurement key, and low-cardinality metadata boundaries. | ✓ VERIFIED | `ObanPowertools.Telemetry.contract/0` publishes the five families plus `:count` and allowed metadata keys in [lib/oban_powertools/telemetry.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/telemetry.ex:1). Tests lock the contract and event emission examples in [test/oban_powertools/telemetry_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/telemetry_test.exs:15), and README mirrors the same schema in [README.md](/Users/jon/projects/oban_powertools/README.md:70). |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mix/tasks/oban_powertools.install.ex` | Deterministic host-owned install/config/router/migration contract | ✓ VERIFIED | Substantive installer pipeline plus explicit host contract comment and router scope insertion. |
| `lib/oban_powertools/application.ex` | Conditional internal child inclusion for `HeartbeatWriter` | ✓ VERIFIED | `maybe_add_heartbeat_writer/1` gates on `RuntimeConfig.repo()`. |
| `lib/oban_powertools/lifeline/heartbeat_writer.ex` | Shared fail-fast repo setup contract | ✓ VERIFIED | Uses `RuntimeConfig.repo!(opts)` before starting periodic refresh state. |
| `lib/oban_powertools/web/router.ex` | Explicit host/library route boundary and optional bridge shape | ✓ VERIFIED | Docs and macro implementation align on `/ops/jobs` outer scope and `"/oban"` nested path. |
| `lib/oban_powertools/telemetry.ex` | Public telemetry contract surface | ✓ VERIFIED | Contract map plus public wrapper functions present and used. |
| `README.md` | Public install/mount/supervision/telemetry contract docs | ✓ VERIFIED | Contains install command, config, route contract, supervision note, bridge note, and telemetry table. |
| `.planning/phases/8-host-contract-install-surface/8-VALIDATION.md` | Exact proof commands and completed validation metadata | ✓ VERIFIED | Quick-run command, test references, `nyquist_compliant: true`, and approval marker all present. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Mix.Tasks.ObanPowertools.Install` | Host runtime config | `config :oban_powertools, repo: ..., auth_module: ...` | ✓ WIRED | Installer comment and config insertion at [lib/mix/tasks/oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:54) match README contract at [README.md](/Users/jon/projects/oban_powertools/README.md:31). |
| `ObanPowertools.Application` | `ObanPowertools.Lifeline.HeartbeatWriter` | Conditional child inclusion | ✓ WIRED | `RuntimeConfig.repo()` gate in [lib/oban_powertools/application.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/application.ex:40) is exercised by [test/oban_powertools/application_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/application_test.exs:17). |
| Host router scope `/ops/jobs` | `oban_powertools_routes("/oban")` | Host-owned outer shell | ✓ WIRED | Fixture router uses the macro exactly this way in [test/support/test_router.ex](/Users/jon/projects/oban_powertools/test/support/test_router.ex:20), and route tests confirm the resulting paths. |
| Native LiveView session | Optional `oban_dashboard/2` bridge | Shared `on_mount: [ObanPowertools.Web.LiveAuth]` | ✓ WIRED | Macro implementation and route metadata test align in [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex:33) and [test/oban_powertools/web/router_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/router_test.exs:62). |
| Telemetry wrapper | README telemetry contract | Same families and metadata-key boundaries | ✓ WIRED | Code contract in [lib/oban_powertools/telemetry.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/telemetry.ex:28), tests in [test/oban_powertools/telemetry_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/telemetry_test.exs:4), and README table in [README.md](/Users/jon/projects/oban_powertools/README.md:75) match. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/oban_powertools/application.ex` | `children` | `RuntimeConfig.repo()` reads host env through [lib/oban_powertools/runtime_config.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex:6) | Yes | ✓ FLOWING |
| `lib/oban_powertools/lifeline/heartbeat_writer.ex` | `state.repo` | `RuntimeConfig.repo!(opts)` | Yes | ✓ FLOWING |
| `lib/oban_powertools/web/router.ex` | `path` / `on_mount` | Host macro call in [test/support/test_router.ex](/Users/jon/projects/oban_powertools/test/support/test_router.ex:20) | Yes | ✓ FLOWING |
| `lib/oban_powertools/telemetry.ex` | `measurements` and `metadata` | Real feature emitters in [lib/oban_powertools/cron.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/cron.ex:122), [lib/oban_powertools/limits.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/limits.ex:40), [lib/oban_powertools/workflow/runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:57), and [lib/oban_powertools/lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:44) | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Combined Phase 8 proof set | `mix test test/oban_powertools/application_test.exs test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/telemetry_test.exs` | `20 tests, 0 failures` | ✓ PASS |
| Supervision contract | `mix test test/oban_powertools/application_test.exs` | `3 tests, 0 failures` | ✓ PASS |
| Route and optional bridge shape | `mix test test/oban_powertools/web/router_test.exs` | `4 tests, 0 failures` | ✓ PASS |
| Telemetry contract | `mix test test/oban_powertools/telemetry_test.exs` | `6 tests, 0 failures` | ✓ PASS |
| Installer contract | `mix test test/mix/tasks/oban_powertools.install_test.exs` | `7 tests, 0 failures` | ✓ PASS |
| README public contract markers | `rg -n "mix oban_powertools.install|config :oban_powertools|/ops/jobs|/ops/jobs/oban|ObanPowertools.Application|ObanPowertools.Lifeline.HeartbeatWriter|migrations|audit|idempotency|workflow|lifeline" README.md` | Matched install, route, supervision, and telemetry lines | ✓ PASS |
| Validation artifact proof markers | `rg -n "test/oban_powertools/application_test.exs|test/oban_powertools/web/router_test.exs|test/oban_powertools/telemetry_test.exs|test/mix/tasks/oban_powertools.install_test.exs|nyquist_compliant: true|wave_0_complete: true|Approval: approved" .planning/phases/8-host-contract-install-surface/8-VALIDATION.md` | Matched quick-run, phase proof files, metadata flags, and approval | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `PKG-01` | `8-01`, `8-03` | Host-owned generator path produces deterministic config, supervision, routes, and migrations | ✓ SATISFIED | Installer pipeline and contract comment in [lib/mix/tasks/oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:13), migration/source assertions in [test/mix/tasks/oban_powertools.install_test.exs](/Users/jon/projects/oban_powertools/test/mix/tasks/oban_powertools.install_test.exs:9), published install path in [README.md](/Users/jon/projects/oban_powertools/README.md:21). |
| `HST-01` | `8-01`, `8-02`, `8-03` | Host can mount shell and bridge with clear ownership boundaries | ✓ SATISFIED | Supervision ownership in [README.md](/Users/jon/projects/oban_powertools/README.md:60), route docs and macro in [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex:10), route proof in [test/oban_powertools/web/router_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/router_test.exs:11). |
| `POL-03` | `8-03` | Documented low-cardinality telemetry contract treated as public API | ✓ SATISFIED | Contract map in [lib/oban_powertools/telemetry.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/telemetry.ex:28), emitter call sites in cron/limits/workflow/lifeline modules, tests in [test/oban_powertools/telemetry_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/telemetry_test.exs:15), README table in [README.md](/Users/jon/projects/oban_powertools/README.md:75). |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/mix/tasks/oban_powertools.install.ex` | 35 | `TODO` in generated host auth scaffold | ℹ️ Info | Intentional host-owned stub, not a library contract gap. The phase makes this ownership explicit rather than hiding it. |
| `lib/mix/tasks/oban_powertools.install.ex` | 41 | `TODO` in generated host auth scaffold | ℹ️ Info | Same as above. |

### Gaps Summary

No blocking gaps found. Phase 8 achieved the stated goal: the host-owned install/config/router contract is explicit, supervision remains library-owned with deterministic repo-gated child startup, the optional `oban_web` bridge is frozen to the nested shape and shared mount hook, and the telemetry contract is documented and test-backed as public API.

Residual verification note: installer proof is source-level rather than a generated host-app integration run, so Phase 8 proves the public contract and deterministic wiring surfaces structurally, not through an end-to-end scaffold replay.

---

_Verified: 2026-05-21T16:25:01Z_
_Verifier: Claude (gsd-verifier)_
