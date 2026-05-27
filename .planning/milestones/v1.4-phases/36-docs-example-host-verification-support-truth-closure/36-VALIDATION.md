---
phase: 36
slug: docs-example-host-verification-support-truth-closure
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 36 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/oban_powertools/docs_contract_test.exs --seed 0` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60-180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/docs_contract_test.exs --seed 0`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 1 | DOC-05 | T-36-01 / T-36-02 | Docs preserve support-truth boundaries and ownership labels without over-claims | unit + contract | `mix test test/oban_powertools/docs_contract_test.exs --seed 0` | ✅ | ✅ green |
| 36-02-01 | 02 | 1 | VER-04 | T-36-03 / T-36-04 | Workflow check names and claim mappings stay deterministic and merge-blocking | static + contract | `rg -n "continuity-ver04-c1|continuity-ver04-c2|continuity-ver04-c3|continuity-ver04-c4|continuity-proof-status" .github/workflows/host-contract-proof.yml` | ✅ | ✅ green |
| 36-03-01 | 03 | 2 | DOC-05, VER-04 | T-36-05 | Reconciliation docs point to canonical closure artifacts without reopening runtime scope | integration | `rg -n "Phase 38|Phase 39|DOC-05|VER-04" .planning/phases/36-docs-example-host-verification-support-truth-closure/*.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit test framework and docs-contract suite available
- [x] Existing CI workflow contract and proof manifest files available

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reconciliation prose remains additive (no history rewrite semantics) | DOC-05, VER-04 | Requires human judgment on wording and chronology framing | Read `36-CONTEXT.md`, `36-RESEARCH.md`, and `36-03-PLAN.md`; confirm wording references Phase 38/39 as canonical closure owners and introduces no new runtime commitments. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
