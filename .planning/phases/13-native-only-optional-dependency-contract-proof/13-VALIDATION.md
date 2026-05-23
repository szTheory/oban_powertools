---
phase: 13
slug: native-only-optional-dependency-contract-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix test |
| **Config file** | none dedicated; test support loads via `elixirc_paths(:test)` and `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/docs_contract_test.exs test/oban_powertools/web/router_test.exs` |
| **Full suite command** | `bash -lc 'cd examples/phoenix_host && mix precommit && cd ../.. && mix test test/oban_powertools/example_host_contract_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/fresh_host_contract_test.exs'` |
| **Estimated runtime** | ~75 seconds task-level, ~120 seconds wave-end/full-suite |

---

## Sampling Rate

- **After every task commit:** Run the task-specific automated command from the verification map; if the task has not yet created its proof file, also run the quick run command above.
- **After every plan wave:** Run the full suite command above so any wave touching `examples/phoenix_host` still ends with `mix precommit`.
- **Before `$gsd-verify-work`:** The full suite command must be green.
- **Max feedback latency:** 75 seconds at task level, 120 seconds at wave-end/full-suite

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | `PKG-03` / `DOC-03` | `T-13-01` | Native-only temp host removes `oban_web` before dependency resolution, runs the chosen `mix deps.unlock --unused` cleanup, and still compiles/resets cleanly with the supplemental `--no-optional-deps` guard. | integration | `mix test test/oban_powertools/example_host_contract_test.exs --only native-only` | ✅ | ✅ green |
| 13-01-02 | 01 | 1 | `PKG-03` / `DOC-03` | `T-13-02` / `T-13-03` | Bridge-enabled proof runs one real `/ops/jobs/oban` render under the shared actor/session path without expanding into broad Oban Web parity assertions. | integration | `mix test test/oban_powertools/example_host_contract_test.exs --only bridge-enabled` | ✅ | ✅ green |
| 13-02-01 | 02 | 1 | `PKG-03` / `DOC-03` | `T-13-04` | README, installation, and first-session guides lead with the native `/ops/jobs` shell and keep `ops-demo` / `nightly_sync` / `pause_cron_entry` as the canonical proof threshold. | docs + grep | `rg -n 'native, host-owned operator shell at `/ops/jobs`|Native Powertools pages are the supported mutation surface\\.|The host owns router scope, browser pipeline, auth, display policy, and runtime config\\.|`oban_web` is optional|ops-demo|nightly_sync|pause_cron_entry' README.md guides/installation.md guides/first-operator-session.md` | ✅ | ✅ green |
| 13-02-02 | 02 | 1 | `PKG-03` / `DOC-03` | `T-13-05` | Bridge and compatibility guides describe an additive read-only inspection annex and name the tested native-first versus optional-bridge lanes honestly. | docs + grep | `rg -n 'additive read-only inspection annex|Native Powertools pages own audited mutations\\.|tested native-first lane|tested optional bridge lane|examples/phoenix_host' guides/optional-oban-web-bridge.md guides/upgrade-and-compatibility.md` | ✅ | ✅ green |
| 13-03-01 | 03 | 2 | `DOC-03` / `PKG-03` | `T-13-06` | Docs-contract assertions enforce the exact native-first support-truth sentences and keep the canonical first-session markers locked. | unit | `mix test test/oban_powertools/docs_contract_test.exs` | ✅ | ✅ green |
| 13-03-02 | 03 | 2 | `DOC-03` / `PKG-03` | `T-13-06` / `T-13-07` | Workflow job labels, router assertions, and this validation contract stay aligned on `native-first`, `optional-bridge`, and the preserved `fresh-host` lane. | docs + integration | `mix test test/oban_powertools/docs_contract_test.exs test/oban_powertools/web/router_test.exs && rg -n 'native-first:|optional-bridge:|fresh-host:|13-01-01|13-01-02|13-02-01|13-02-02|13-03-01|13-03-02|wave_0_complete: true|nyquist_compliant: true' .github/workflows/host-contract-proof.yml .planning/phases/13-native-only-optional-dependency-contract-proof/13-VALIDATION.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `examples/phoenix_host/test/phoenix_host_web/oban_web_bridge_smoke_test.exs` exists for the bridge-enabled render-smoke sampling.
- [x] `test/support/example_host_contract.ex` performs the native-only dependency rewrite plus `mix deps.unlock --unused` before the `13-01-01` proof.
- [x] `README.md`, `guides/installation.md`, `guides/first-operator-session.md`, `guides/optional-oban-web-bridge.md`, and `guides/upgrade-and-compatibility.md` contain the native-first contract markers.
- [x] `.github/workflows/host-contract-proof.yml` exposes `native-first`, `optional-bridge`, and `fresh-host` job labels.

---

## Manual-Only Verifications

- Read `README.md` and `guides/optional-oban-web-bridge.md` together after Plan 13-02 to confirm the native shell is clearly primary and the bridge still reads as a narrower inspection annex.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Task-level feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
