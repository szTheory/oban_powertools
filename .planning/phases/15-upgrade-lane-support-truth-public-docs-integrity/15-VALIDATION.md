---
phase: 15
slug: upgrade-lane-support-truth-public-docs-integrity
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix plus grep-based docs artifact checks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/docs_contract_test.exs` |
| **Full suite command** | `mix test test/oban_powertools/example_host_contract_test.exs test/oban_powertools/fresh_host_contract_test.exs test/oban_powertools/docs_contract_test.exs` |
| **Estimated runtime** | ~15 seconds task-level smoke, ~45-60 seconds wave-end targeted proof set |

---

## Sampling Rate

- **After every task commit:** Run the task-specific command from the verification map below.
- **After every plan wave:** Run the full suite command above so upgrade, fresh-host, and docs-contract surfaces stay aligned.
- **Before `$gsd-verify-work`:** The targeted proof set and artifact integrity checks must be green.
- **Max feedback latency:** 60 seconds at wave end, shorter for single-file docs-contract or upgrade-lane reruns.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | `PKG-02` | `T-15-01` / `T-15-02` | The upgrade harness starts from one archived historical host instead of synthetic `display_policy` removal and restoration. | integration + grep | `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` | ✅ | ⬜ pending |
| 15-01-02 | 01 | 1 | `PKG-02` | `T-15-01` / `T-15-03` | The supported upgrade lane proves one real native post-upgrade operator action after compile and `ecto.reset`. | integration | `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` | ✅ | ⬜ pending |
| 15-02-01 | 02 | 1 | `HST-03` / `DOC-02` | `T-15-04` / `T-15-05` | README and guides expose the five support-truth buckets and singular supported upgrade lane without broad compatibility claims. | integration + grep | `mix test test/oban_powertools/docs_contract_test.exs` | ✅ | ⬜ pending |
| 15-02-02 | 02 | 1 | `DOC-02` | `T-15-04` / `T-15-06` | Production-hardening and troubleshooting guidance point at verified host-owned seams and fail-fast runtime boundaries without prose snapshot coupling. | integration + grep | `mix test test/oban_powertools/docs_contract_test.exs` | ✅ | ⬜ pending |
| 15-03-01 | 03 | 2 | `PKG-02` / `HST-03` / `DOC-02` | `T-15-07` / `T-15-08` | CI lane names, harness wiring, and docs-contract guards all describe the same supported upgrade story and support-truth vocabulary. | integration + grep | `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof && mix test test/oban_powertools/docs_contract_test.exs` | ✅ | ⬜ pending |
| 15-03-02 | 03 | 2 | `PKG-02` / `DOC-02` | `T-15-07` / `T-15-09` | The combined host-contract proof workflow still covers fresh-host, upgrade, and docs-contract regressions after the lane rewrite. | integration | `mix test test/oban_powertools/example_host_contract_test.exs test/oban_powertools/fresh_host_contract_test.exs test/oban_powertools/docs_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md` exists.
- [x] `.planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-RESEARCH.md` exists.
- [ ] `.planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-PATTERNS.md` must exist before final planning.
- [x] `test/support/example_host_contract.ex`, `test/oban_powertools/example_host_contract_test.exs`, and `test/oban_powertools/docs_contract_test.exs` already exist as the main proof surfaces.
- [x] `.github/workflows/host-contract-proof.yml` already provides the named CI lane that Phase 15 will realign.

---

## Manual-Only Verifications

- Read the archived historical fixture README or provenance note after execution to confirm it names the exact source commit and does not silently drift into a second current-state fixture.
- Read `guides/upgrade-and-compatibility.md`, `guides/support-truth-and-ownership-boundaries.md`, `guides/production-hardening.md`, and `guides/troubleshooting.md` together to confirm they use the same five-bucket vocabulary and keep narrative advice outside the exact-string contract boundary.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all required input artifacts
- [x] No watch-mode flags
- [x] Task-level feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
