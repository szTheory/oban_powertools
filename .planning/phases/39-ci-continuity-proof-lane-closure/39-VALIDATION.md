---
phase: 39
slug: ci-continuity-proof-lane-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 39 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir test suite) |
| **Config file** | `mix.exs` / `config/test.exs` |
| **Quick run command** | `mix test test/oban_powertools/docs_contract_test.exs --seed 0` |
| **Full suite command** | `mix test test/oban_powertools/docs_contract_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/docs_contract_test.exs --seed 0`
- **After every plan wave:** Run `mix test test/oban_powertools/docs_contract_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | VER-04 | T-39-01-01 | Continuity jobs and aggregate gate are explicit and stable in workflow | contract | `rg -n "continuity-proof|continuity-proof-status|VER04-C1|VER04-C2|VER04-C3|VER04-C4" .github/workflows/host-contract-proof.yml` | ✅ | ⬜ pending |
| 39-01-02 | 01 | 1 | VER-04 | T-39-01-02 | Docs contract locks continuity lane naming to prevent branch-protection drift | test | `mix test test/oban_powertools/docs_contract_test.exs --seed 0` | ✅ | ⬜ pending |
| 39-02-01 | 02 | 2 | VER-04 | T-39-02-01 | Required proof artifacts are generated and uploaded on success/failure | contract | `rg -n "if: always\\(\\)|if-no-files-found: error|ver04-claim-matrix\\.md|ver04-claim-matrix\\.json|run-metadata\\.json|redaction-report\\.json" .github/workflows/host-contract-proof.yml` | ✅ | ⬜ pending |
| 39-02-02 | 02 | 2 | VER-04 | T-39-02-02 | Claim commands remain deterministic and rerunnable with fixed seed | test | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/cron_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0` | ✅ | ⬜ pending |
| 39-03-01 | 03 | 3 | VER-04 | T-39-03-01 | Proof manifest and phase verification map claims to CI evidence deterministically | contract | `rg -n "VER04-C1|VER04-C2|VER04-C3|VER04-C4|VER-04" .planning/phases/39-ci-continuity-proof-lane-closure/39-PROOF-MANIFEST.json .planning/phases/39-ci-continuity-proof-lane-closure/39-VERIFICATION.md` | ❌ W0 | ⬜ pending |
| 39-03-02 | 03 | 3 | VER-04 | T-39-03-02 | Requirement traceability flips only after proof references are published | contract | `rg -n "VER-04 \\| Phase 39 \\| Complete|Phase 39 Verification References|39-VERIFICATION\\.md|39-PROOF-MANIFEST\\.json" .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/39-ci-continuity-proof-lane-closure/39-PROOF-MANIFEST.json` — proof manifest scaffold for claim-to-evidence mapping
- [ ] `.planning/phases/39-ci-continuity-proof-lane-closure/39-VERIFICATION.md` — phase closure verification artifact skeleton

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch protection uses the aggregate continuity gate check name | VER-04 | Repository settings are external to codebase | Confirm branch protection requires `continuity-proof-status` before merge. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
