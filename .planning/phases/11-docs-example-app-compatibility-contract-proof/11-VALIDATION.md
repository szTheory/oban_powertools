---
phase: 11
slug: docs-example-app-compatibility-contract-proof
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-21
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Phoenix integration tests, and docs contract tests |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/web/router_test.exs` |
| **Full suite command** | `mix test && mix docs` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick-run command above if the task has not yet created its own targeted proof files; once Phase 11 docs-contract and example-host proof files exist, also run the task-specific automated command from the verification map.
- **After every plan wave:** Run `mix test && mix docs`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 45 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | DOC-01 / HST-03 | T-11-01 / T-11-03 | README and ExDoc wiring expose the honest day-0 contract, including explicit `display_policy` ownership and native-vs-bridge support truth. | docs + grep | `mix docs && rg -n "display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy|examples/phoenix_host|read-only|native Powertools pages own audited mutations" README.md mix.exs` | ✅ | ⬜ pending |
| 11-01-02 | 01 | 1 | DOC-01 / HST-03 | T-11-01 / T-11-02 | Day-0 guides teach the real host path, router mount, optional bridge note, and first operator session without hidden setup. | docs + grep | `mix docs && rg -n "display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy|oban_powertools_routes\\(\"/oban\"\\)|/ops/jobs/oban|audited mutation|mix phx.new|mix oban_powertools.install" guides/installation.md guides/first-operator-session.md guides/example-app-walkthrough.md` | ✅ | ⬜ pending |
| 11-02-01 | 02 | 1 | DOC-01 / HST-03 | T-11-04 / T-11-05 | Canonical host keeps one host-owned `/ops/jobs` shell, explicit auth/display wiring, and a single tree that can exercise native-only and bridge-enabled paths. | compile + grep | `cd examples/phoenix_host && mix deps.get && mix compile && rg -n "auth_module: PhoenixHostWeb.ObanPowertoolsAuth|display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy|scope \"/ops/jobs\"|oban_powertools_routes\\(\"/oban\"\\)|oban_web" mix.exs config/config.exs lib/phoenix_host_web/router.ex` | ✅ | ⬜ pending |
| 11-02-02 | 02 | 1 | DOC-01 / HST-03 | T-11-04 / T-11-06 | Example host seeds and host seams support one native audited mutation path plus read-only bridge inspection with rerunnable verification, and the fixture README states reverse-proxy, WebSocket, and auth/session caveats that materially affect mounted `/ops/jobs` behavior. | integration + docs | `cd examples/phoenix_host && MIX_ENV=test mix ecto.reset && MIX_ENV=test mix run priv/repo/seeds.exs && rg -n "@behaviour ObanPowertools.Auth|def display\\(|ops|display_policy|read-only|mix phx.new|reverse-proxy|WebSocket|auth/session|mix oban_powertools.install" lib/phoenix_host_web/oban_powertools_auth.ex lib/phoenix_host_web/oban_powertools_display_policy.ex priv/repo/seeds.exs README.md regenerate.sh` | ✅ | ⬜ pending |
| 11-03-01 | 03 | 2 | PKG-02 | T-11-07 | Upgrade guide documents one tested Phase 8-10 to Phase 11 lane and distinguishes tested native-only, tested bridge-enabled, and best-effort support. | docs + grep | `mix docs && rg -n "Phase 8|display_policy|tested native-only lane|tested bridge-enabled lane|best-effort" guides/upgrade-and-compatibility.md` | ✅ | ⬜ pending |
| 11-03-02 | 03 | 2 | DOC-02 / HST-03 | T-11-08 / T-11-09 | Hardening, troubleshooting, bridge, and ownership guides include telemetry, read-only bridge truth, host-owned boundaries, and reverse-proxy/WebSocket/auth/session caveats for mounted operator UI behavior. | docs + grep | `mix docs && rg -n "telemetry|read-only|native Powertools pages own audited mutations|requires :display_policy|host owns router scope|reverse-proxy|WebSocket|auth/session" guides/production-hardening.md guides/optional-oban-web-bridge.md guides/troubleshooting.md guides/support-truth-and-ownership-boundaries.md` | ✅ | ⬜ pending |
| 11-04-01 | 04 | 3 | DOC-03 / HST-03 | T-11-10 | Docs contract tests lock canonical snippets and support-truth markers without relying on broad prose matching. | unit | `mix test test/oban_powertools/docs_contract_test.exs` | ✅ | ⬜ pending |
| 11-04-02 | 04 | 3 | DOC-03 / DOC-01 / PKG-02 | T-11-11 / T-11-12 | Example-host proof covers native-only, bridge-enabled, and the documented upgrade lane that explicitly adds `display_policy`, while repo-local CI names and runs the advertised proof lanes: `structural`, `docs-contract`, `native-only`, `bridge-enabled`, and `upgrade-proof`. | integration + workflow | `mix test test/oban_powertools/example_host_contract_test.exs && rg -n "structural|docs-contract|native-only|bridge-enabled|upgrade-proof" .github/workflows/host-contract-proof.yml` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mix.exs` ExDoc wiring must exist before any `mix docs` verification can pass.
- [ ] `guides/installation.md`, `guides/first-operator-session.md`, and `guides/example-app-walkthrough.md` must exist before the day-0 docs checks run.
- [ ] `guides/upgrade-and-compatibility.md`, `guides/production-hardening.md`, `guides/optional-oban-web-bridge.md`, `guides/troubleshooting.md`, and `guides/support-truth-and-ownership-boundaries.md` must exist before the day-2 docs checks run.
- [ ] `test/oban_powertools/docs_contract_test.exs` must exist before docs-contract sampling is added to the per-task loop.
- [ ] `test/oban_powertools/example_host_contract_test.exs` and `test/support/example_host_contract.ex` must exist before example-host proof sampling is added to the per-task loop.
- [ ] `.github/workflows/host-contract-proof.yml` must exist before workflow-lane verification can pass.

---

## Manual-Only Verifications

- Confirm the published docs render the grouped ExDoc sections in the intended day-0/day-2 order after `mix docs`.
- Spot-check that the documented bridge caveats remain support-truthful if upstream `oban_web` route or websocket behavior changes in a future dependency bump.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 documents all pending validation dependencies honestly
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
