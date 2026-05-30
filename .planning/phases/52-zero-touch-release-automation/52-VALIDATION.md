---
phase: 52
slug: zero-touch-release-automation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (existing) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test --exclude host_contract` |
| **Full suite command** | `mix test --exclude host_contract` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test --exclude host_contract`
- **After every plan wave:** Run `mix test --exclude host_contract`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | (process automation) | — | Inspection checklist passes | manual | N/A — manual-only; workflow YAML cannot be tested with mix test | N/A | ⬜ pending |
| 52-01-02 | 01 | 1 | (process automation) | — | actionlint job exists in ci.yml wired into ci-gate | structural | Verified when PR is opened (workflow_run triggers actionlint) | CI — not file | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test files needed — the existing test suite is unchanged. Workflow YAML files cannot be tested with `mix test`; actionlint itself is the automated validator that runs on the PR that adds the actionlint job.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Inspection checklist (6 items) | Process automation (no REQ-ID) | CI YAML files cannot be unit-tested with ExUnit | Verify: branch name in automerge matches config derivation, ci-gate job name matches ci.yml, permissions sufficient, stale-SHA guard present, Bootstrap CI step present, Trigger release.yml step present — all pre-verified during research (all PASS) |
| actionlint job wired into ci-gate | Process automation (no REQ-ID) | Structural check confirmed by opening PR and observing CI | After adding actionlint job to ci.yml, open a PR and verify actionlint appears in required checks and ci-gate only passes when actionlint passes |
| End-to-end zero-touch pipeline | Process automation (no REQ-ID) | No open release PR exists to dry-run against | Deferred to "next actual release cycle" per D-02 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
