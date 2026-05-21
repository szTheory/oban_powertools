---
phase: 8
slug: host-contract-install-surface
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with `Phoenix.LiveViewTest` support |
| **Config file** | `test/test_helper.exs` bootstrap; no dedicated framework config file |
| **Quick run command** | `mix test test/oban_powertools/application_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/telemetry_test.exs test/mix/tasks/oban_powertools.install_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/application_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/telemetry_test.exs test/mix/tasks/oban_powertools.install_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 8-01-01 | 01 | 1 | PKG-01 | T-8-01 / T-8-02 | Installer emits deterministic host config, route scope, and support-truth contract without hidden defaults | unit | `mix test test/mix/tasks/oban_powertools.install_test.exs` | ✅ | ✅ green |
| 8-02-01 | 02 | 2 | PKG-01, HST-01 | T-8-03 | Boot/supervision posture for missing `:repo` is explicit and verified | unit | `mix test test/oban_powertools/application_test.exs` | ✅ | ✅ green |
| 8-02-02 | 02 | 2 | HST-01 | T-8-04 / T-8-05 | Native and optional bridge routes mount with clear host-owned outer scope and library-owned inner route contract | integration | `mix test test/oban_powertools/web/router_test.exs` | ✅ | ✅ green |
| 8-03-01 | 03 | 3 | POL-03 | T-8-06 | Public telemetry event families expose only documented low-cardinality measurements and metadata keys | unit | `mix test test/oban_powertools/telemetry_test.exs` | ✅ | ✅ green |
| 8-03-02 | 03 | 3 | PKG-01, POL-03, HST-01 | T-8-01 / T-8-06 | Verification artifact and contract docs reflect the exact supported host seams and proof commands | doc + grep | `rg -n "mix oban_powertools.install|config :oban_powertools|/ops/jobs|/ops/jobs/oban|ObanPowertools.Application|ObanPowertools.Lifeline.HeartbeatWriter|migrations|audit|idempotency|workflow|lifeline" README.md && rg -n "test/oban_powertools/application_test.exs|test/oban_powertools/web/router_test.exs|test/oban_powertools/telemetry_test.exs|test/mix/tasks/oban_powertools.install_test.exs|nyquist_compliant: true|wave_0_complete: true|Approval: approved" .planning/phases/8-host-contract-install-surface/8-VALIDATION.md && mix test test/oban_powertools/application_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/telemetry_test.exs test/mix/tasks/oban_powertools.install_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/oban_powertools/application_test.exs` — boot/supervision contract test for missing `:repo`
- [x] `test/oban_powertools/web/router_test.exs` — explicit `/ops/jobs/oban` bridge assertion when `oban_web` is available
- [x] `test/oban_powertools/telemetry_test.exs` — metadata-boundary assertions per public event family
- [x] Combined quick-run proof covers installer, supervision, routing, and telemetry contract drift

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host-owned install/support-truth documentation reads clearly for a fresh adopter | PKG-01, HST-01 | Clarity of contract language is easier to judge in rendered docs than raw grep alone | Read the updated contract docs and confirm they explicitly separate host-owned config/router/supervision from library-owned pages/children/telemetry helpers |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-21
