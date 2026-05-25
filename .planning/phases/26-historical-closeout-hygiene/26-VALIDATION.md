---
phase: 26
slug: historical-closeout-hygiene
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 26 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Repo-local shell audit using `node` + `rg`; optional parser smoke via Node CLI |
| **Config file** | none required beyond the existing GSD tooling sources |
| **Quick run command** | `node "$HOME/.codex/get-shit-done/bin/gsd-tools.cjs" audit-open --json && rg -n "^status: complete$|^\\[testing complete\\]$|^result: pass$|Phase 26 normalized this file to the current UAT schema on 2026-05-25" .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-UAT.md` |
| **Full suite command** | `node "$HOME/.codex/get-shit-done/bin/gsd-tools.cjs" audit-open --json && rg -n "^status: complete$|^\\[testing complete\\]$|^result: pass$|^status: passed$|current canonical|archival hygiene|gsd-complete-milestone|25/28|28/28" .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-UAT.md .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-VERIFICATION.md .planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md .planning/ROADMAP.md .planning/STATE.md /Users/jon/.codex/get-shit-done/bin/lib/audit.cjs /Users/jon/.codex/get-shit-done/bin/lib/uat.cjs` |
| **Estimated runtime** | ~2-10 seconds; no repo build required |

---

## Sampling Rate

- **After every task commit:** Run the task-specific command from the verification map below.
- **After every plan wave:** Re-run `audit-open --json` and inspect the exact affected artifact text.
- **Before `$gsd-verify-work`:** The UAT artifact, any tooling hardening, the rerun audit wording, and the roadmap/state next-step story must all agree that the Phase 12 closeout is complete and historical.
- **Max feedback latency:** 10 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Concern | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|---------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 1 | canonical UAT schema | `T-26-01` / `T-26-02` | `12-UAT.md` uses `status: complete`, canonical completion marker, canonical `result: pass` tokens, and one retrospective note preserving the 2026-05-23 verdict. | doc schema + gate smoke | `bash -lc 'rg -n "^status: complete$|^\\[testing complete\\]$|^result: pass$|Phase 26 normalized this file to the current UAT schema on 2026-05-25" .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-UAT.md && node "$HOME/.codex/get-shit-done/bin/gsd-tools.cjs" audit-open --json | rg -n "\"uat_gaps\": 0|\"has_open_items\": false"'` | ✅ | ⬜ pending |
| 26-01-02 | 01 | 1 | adjacent provenance note | `T-26-02` | `12-VERIFICATION.md` explicitly says the UAT artifact was normalized later for archival hygiene without changing the original human closeout verdict. | doc consistency | `rg -n "Phase 26 normalized `12-UAT\\.md` to the current canonical UAT schema on 2026-05-25|2026-05-23" .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-VERIFICATION.md` | ✅ | ⬜ pending |
| 26-02-01 | 02 | 2 | narrow legacy-closed audit handling | `T-26-03` | `audit.cjs` recognizes legacy `passed` only as a closed alias when no open scenarios remain, and still reports incomplete UAT states as open. | CLI smoke + source grep | `bash -lc 'rg -n "status === .passed.|legacy.*closed|open_scenario_count" /Users/jon/.codex/get-shit-done/bin/lib/audit.cjs && node "$HOME/.codex/get-shit-done/bin/gsd-tools.cjs" audit-open --json | rg -n "\"uat_gaps\": 0|\"has_open_items\": false"'` | ✅ | ⬜ pending |
| 26-02-02 | 02 | 2 | narrow completion-marker parser handling | `T-26-03` | `uat.cjs` accepts a legacy completion marker only for already-complete sessions and does not relax pending-path parsing. | source grep | `rg -n "testing complete|completed" /Users/jon/.codex/get-shit-done/bin/lib/uat.cjs` | ✅ | ⬜ pending |
| 26-03-01 | 03 | 3 | current-state milestone verdict cleanup | `T-26-04` | `v1.2-rerun-MILESTONE-AUDIT.md` stops listing the Phase 12 item as unresolved tech debt and explicitly states that archival hygiene is complete. | doc consistency | `bash -lc 'rg -n "Phase 12 UAT closeout|archival hygiene|current canonical" .planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md && ! rg -n "remains archival hygiene" .planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md'` | ✅ | ⬜ pending |
| 26-03-02 | 03 | 3 | active closeout inventory and next action | `T-26-04` / `T-26-05` | `ROADMAP.md` marks all three Phase 26 plans complete and `STATE.md` points to milestone closeout rather than stale UAT ambiguity. | doc consistency | `bash -lc 'rg -n "26-01-PLAN\\.md|26-02-PLAN\\.md|26-03-PLAN\\.md|\\| v1\\.2 \\| 16-26 \\| 28/28 \\| Gap Closure Active \\| - \\|" .planning/ROADMAP.md && rg -n "gsd-complete-milestone|Phase 26 complete|v1\\.2-rerun-MILESTONE-AUDIT\\.md" .planning/STATE.md'` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/26-historical-closeout-hygiene/26-CONTEXT.md` exists.
- [x] `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-UAT.md` exists and is the direct archival blocker.
- [x] `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-VERIFICATION.md` exists as the canonical provenance report.
- [x] `.planning/milestones/v1.1-MILESTONE-AUDIT.md` exists as canonical proof that the human closeout passed on 2026-05-23.
- [x] `.planning/v1.2-MILESTONE-AUDIT.md` exists as the failed snapshot that must remain untouched.
- [x] `.planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md` exists as the current canonical milestone verdict to tighten after execution.
- [x] `node "$HOME/.codex/get-shit-done/bin/gsd-tools.cjs" audit-open --json` currently reproduces the open Phase 12 UAT signal.

---

## Manual-Only Verifications

- Read the retrospective note in `12-UAT.md` and confirm it clearly separates schema normalization from verdict change.
- Read the rerun audit conclusion after execution and confirm it presents archival hygiene as resolved current state without rewriting the failed historical snapshot.
- Read `STATE.md` after execution and confirm it is session continuity only, not a duplicate milestone audit.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification lanes.
- [x] Sampling continuity: no 3 consecutive tasks rely on manual checks only.
- [x] Wave 0 names the exact reproduced blocker.
- [x] No watch-mode flags.
- [x] Task-level feedback latency < 10s.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
