---
phase: 12
slug: fresh-host-install-path-example-fixture-repair
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-22
---

# Phase 12 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Phoenix integration tests, docs contract tests, and fixture-host proof helpers |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/oban_powertools.install_test.exs` |
| **Full suite command** | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/example_host_contract_test.exs` |
| **Estimated runtime** | ~25 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick-run command above, plus the task-specific command from the verification map once the touched proof file exists.
- **After every plan wave:** Run `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/example_host_contract_test.exs`.
- **Before `$gsd-verify-work`:** The full-suite command must be green.
- **Max feedback latency:** 25 seconds for task-level smoke checks, with the slower combined lane reserved for wave-level verification.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | PKG-01 | T-12-01 / T-12-02 | Installer patches config, router, seam modules, and Powertools migrations without crashing, and keeps `oban_web` optional. | unit + integration | `mix test test/mix/tasks/oban_powertools.install_test.exs && rg -n "oban_powertools.install|CaseClauseError|oban_web" test/mix/tasks/oban_powertools.install_test.exs lib/mix/tasks/oban_powertools.install.ex` | ✅ | ⬜ pending |
| 12-02-01 | 02 | 1 | PKG-01 / DOC-01 | T-12-03 / T-12-04 | Canonical fixture includes the Powertools migration set and README/regeneration files describe exact generated vs manual seams honestly. | compile + docs | `cd examples/phoenix_host && MIX_ENV=test mix ecto.reset && rg -n "ObanPowertools|mix phx.new|mix oban_powertools.install|manual" README.md regenerate.sh priv/repo/migrations` | ✅ | ⬜ pending |
| 12-03-01 | 03 | 2 | DOC-01 | T-12-05 / T-12-06 | First-session proof completes one native audited mutation and asserts durable audit evidence through the fixture/proof helper. | integration | `mix test test/oban_powertools/example_host_contract_test.exs` | ✅ | ⬜ pending |
| 12-04-01 | 04 | 2 | PKG-01 / DOC-01 | T-12-07 / T-12-08 | README, guides, fixture walkthrough, and CI lane names all match the repaired day-0 path and first-session proof truthfully. | docs + workflow | `mix test test/oban_powertools/docs_contract_test.exs test/oban_powertools/example_host_contract_test.exs && rg -n "fresh host|mix oban_powertools.install|first operator session|native-only|bridge-enabled|structural|docs-contract" README.md guides examples/phoenix_host/README.md .github/workflows/host-contract-proof.yml` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/oban_powertools.install_test.exs` must exist before installer regression sampling can pass.
- [ ] `test/oban_powertools/docs_contract_test.exs` must exist before docs/support-truth checks can pass.
- [ ] `test/oban_powertools/example_host_contract_test.exs` and `test/support/example_host_contract.ex` must exist before first-session proof sampling can pass.
- [ ] `examples/phoenix_host/priv/repo/migrations/` must contain the Powertools migration set before fixture reset proof can pass.
- [ ] `.github/workflows/host-contract-proof.yml` must exist before workflow-lane verification can pass.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fresh-host README and guide wording feel support-truthful to a new adopter | DOC-01 | Prose honesty and ambiguity still need a human read after contract tests pass | Run `mix docs`, then read `README.md`, `guides/installation.md`, `guides/first-operator-session.md`, and `guides/example-app-walkthrough.md` together to confirm they describe the same paved road and clearly mark host-owned follow-up. |
| Fixture provenance remains thin and non-showcase | PKG-01 / DOC-01 | The canonical-fixture posture is partly editorial, not just structural | Review `examples/phoenix_host/README.md` and `examples/phoenix_host/regenerate.sh` to confirm they describe the fixture as a curated contract host rather than a polished demo app. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all known pending validation dependencies
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
