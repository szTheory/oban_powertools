---
phase: 25
slug: traceability-audit-consistency-repair
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-25
---

# Phase 25 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Repo-local shell audit with `rg` plus optional ExUnit spot-checks through `mix test` |
| **Config file** | `test/test_helper.exs` for optional ExUnit verification; no dedicated markdown-lint config detected |
| **Quick run command** | `rg -n "WFS-02|REC-03|SIG-01|SIG-02|SIG-03|DIA-01|DIA-02|VER-01|17-VERIFICATION|19-VERIFICATION|20-VERIFICATION|21-VERIFICATION|22-VERIFICATION|23-VERIFICATION" .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/PROJECT.md .planning/STATE.md .planning/v1.2-MILESTONE-AUDIT.md .planning/milestones/*.md` |
| **Full suite command** | `rg -n "superseded|rerun|canonical|Phase 25|Pending|Complete|gaps_found|passed" .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/PROJECT.md .planning/STATE.md .planning/v1.2-MILESTONE-AUDIT.md .planning/milestones/*.md && mix test test/oban_powertools/workflow_runtime_transitions_test.exs test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` |
| **Estimated runtime** | ~5-15 seconds for doc-only grep checks, ~90-180 seconds if the optional workflow proof spot-check bundle is included |

---

## Sampling Rate

- **After every task commit:** Run the task-specific `rg` command from the verification map below.
- **After every plan wave:** Run the full planning-doc consistency command and manually inspect the failed-audit supersession link plus the rerun-audit verdict.
- **Before `$gsd-verify-work`:** All eight requirement rows, both v1.2 audit artifacts, and the targeted role-clarifying edits in `ROADMAP.md`, `PROJECT.md`, and `STATE.md` must agree on the current closure story.
- **Max feedback latency:** 180 seconds when the optional ExUnit proof spot-check bundle is included.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 25-01-01 | 01 | 1 | `WFS-02` / `REC-03` / `SIG-01` / `SIG-02` / `SIG-03` / `DIA-01` / `DIA-02` / `VER-01` | `T-25-01` | `REQUIREMENTS.md` keeps original owner phases, adds the rigid `Closure Proof` column, and marks the eight reopened v1.2 checklist bullets complete so the checklist and traceability table agree. | doc consistency | `bash -lc 'rg -n "^\\| Requirement \\| Owner Phase \\| Closure Proof \\| Status \\|$|^\\| WFS-02 \\| 17 \\| 17-VERIFICATION\\.md \\| Complete \\|$|^\\| REC-03 \\| 20 \\| 20-VERIFICATION\\.md \\| Complete \\|$|^\\| SIG-01 \\| 19 \\| 19-VERIFICATION\\.md \\| Complete \\|$|^\\| SIG-02 \\| 19 \\| 19-VERIFICATION\\.md \\| Complete \\|$|^\\| SIG-03 \\| 19 \\| 19-VERIFICATION\\.md \\| Complete \\|$|^\\| DIA-01 \\| 21 \\| 21-VERIFICATION\\.md \\| Complete \\|$|^\\| DIA-02 \\| 22 \\| 22-VERIFICATION\\.md \\| Complete \\|$|^\\| VER-01 \\| 23 \\| 23-VERIFICATION\\.md \\| Complete \\|$" .planning/REQUIREMENTS.md && rg -n "^- \\[x\\] \\*\\*(WFS-02|REC-03|SIG-01|SIG-02|SIG-03|DIA-01|DIA-02|VER-01)\\*\\*:" .planning/REQUIREMENTS.md && ! rg -n "^\\| (WFS-02|REC-03|SIG-01|SIG-02|SIG-03|DIA-01|DIA-02|VER-01) \\| (24|25) \\|" .planning/REQUIREMENTS.md'` | ✅ | ⬜ pending |
| 25-01-02 | 01 | 1 | roadmap inventory / progress bookkeeping | `T-25-02` / `T-25-03` | `ROADMAP.md` advertises the real Phase 24 and Phase 25 plan inventories, rewrites the stale Phase 25 details sentence to the repaired owner-phase plus closure-proof story, and records the exact recomputed v1.2 progress row without implying either repair phase owns workflow semantics. | doc consistency | `rg -n "\\*\\*Plans:\\*\\* 3 plans|24-01-PLAN\\.md|24-02-PLAN\\.md|24-03-PLAN\\.md|25-01-PLAN\\.md|25-02-PLAN\\.md|25-03-PLAN\\.md" .planning/ROADMAP.md && rg -n "Repair the v1\\.2 traceability table so original owner phases, canonical closure proof, and additive milestone-audit chronology all tell the same present-tense story\\." .planning/ROADMAP.md && rg -n "^\\| v1\\.2 \\| 16-26 \\| 25/28 \\| Gap Closure Active \\| - \\|$" .planning/ROADMAP.md` | ✅ | ⬜ pending |
| 25-02-01 | 02 | 1 | failed-audit supersession note | `T-25-04` | `.planning/v1.2-MILESTONE-AUDIT.md` stays a `gaps_found` historical snapshot and gains only the rerun pointer needed to route readers to the current canonical verdict. | doc consistency | `bash -lc 'rg -n "^status: gaps_found$" .planning/v1.2-MILESTONE-AUDIT.md && rg -n "v1\\.2-rerun-MILESTONE-AUDIT\\.md" .planning/v1.2-MILESTONE-AUDIT.md && rg -n "failed 2026-05-25 snapshot" .planning/v1.2-MILESTONE-AUDIT.md && rg -Fn '"'"'\"'\"'**Status:** `gaps_found`'\"'\"' .planning/v1.2-MILESTONE-AUDIT.md'` | ✅ | ⬜ pending |
| 25-02-02 | 02 | 1 | canonical rerun audit | `T-25-05` / `T-25-06` | `.planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md` becomes the passed current-state audit and closes the eight repaired requirements against the canonical phase-local verification files. | doc consistency | `bash -lc 'rg -n "status: passed|## Requirement Status|WFS-02|REC-03|SIG-01|SIG-02|SIG-03|DIA-01|DIA-02|VER-01|17-VERIFICATION\\.md|19-VERIFICATION\\.md|20-VERIFICATION\\.md|21-VERIFICATION\\.md|22-VERIFICATION\\.md|23-VERIFICATION\\.md|current canonical" .planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md && ! rg -n "unsatisfied|orphaned" .planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md'` | ✅ | ⬜ pending |
| 25-03-01 | 03 | 2 | stable product posture | `T-25-07` | `PROJECT.md` returns to stable product posture, removes stale Phase 17-19 status blocks, and routes volatile v1.2 truth to `REQUIREMENTS.md`, `ROADMAP.md`, and the rerun milestone audit. | doc consistency | `bash -lc 'rg -n "## What This Is|## Core Value|## Current Milestone: v1\\.2 Workflow Semantics & Recovery|REQUIREMENTS\\.md|ROADMAP\\.md|v1\\.2-rerun-MILESTONE-AUDIT\\.md" .planning/PROJECT.md && ! rg -n "Phase 17 status:|Phase 18 status:|Phase 19 status:" .planning/PROJECT.md'` | ✅ | ⬜ pending |
| 25-03-02 | 03 | 2 | session continuity / summary-scope guardrail | `T-25-08` / `T-25-09` | `STATE.md` reflects Phase 25 as the active target, distinguishes failed snapshot versus current canonical rerun audit, and leaves pre-existing summaries untouched in this plan. | doc consistency + scope audit | `bash -lc 'rg -n "^## Current Position$" .planning/STATE.md && rg -n "^- \\*\\*Phase:\\*\\* 25$" .planning/STATE.md && rg -n "v1\\.2-MILESTONE-AUDIT\\.md" .planning/STATE.md && rg -n "v1\\.2-rerun-MILESTONE-AUDIT\\.md" .planning/STATE.md && rg -n "^- \\*\\*Next Action:\\*\\*" .planning/STATE.md && ! rg -n "^Phase: 24 \\(verification-artifact-backfill\\) — EXECUTING$" .planning/STATE.md' && rg -n "^files_modified:$|^  - \\.planning/PROJECT\\.md$|^  - \\.planning/STATE\\.md$" .planning/phases/25-traceability-audit-consistency-repair/25-03-PLAN.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md` exists.
- [x] `.planning/phases/25-traceability-audit-consistency-repair/25-RESEARCH.md` exists.
- [x] Canonical proof files exist in Phases 17, 19, 20, 21, 22, and 23.
- [x] `.planning/v1.2-MILESTONE-AUDIT.md` exists as the failed snapshot to preserve.
- [x] `.planning/milestones/v1.1-MILESTONE-AUDIT.md` exists as the local passed-rerun audit analog.
- [ ] The target v1.2 rerun audit artifact does not exist yet.
- [ ] No reusable doc-audit helper script exists; verification relies on explicit inline `rg` commands.
- [ ] `STATE.md` still contains stale “Phase 24 executing” text and must be normalized during execution.

---

## Manual-Only Verifications

- Read the failed v1.2 audit header to confirm the supersession note preserves the 2026-05-25 failure context instead of rewriting history.
- Read the new rerun audit verdict and requirement table to confirm it mirrors the repaired proof chain rather than inventing a second proof store.
- Read `PROJECT.md` and `STATE.md` after edits to confirm they are narrower entrypoints, not duplicate mini-audits.
- Confirm the failed-audit note and rerun-audit verdict describe distinct historical versus current roles.

---

## Validation Sign-Off

- [x] All planned task classes have an automated verification lane or an explicit manual review.
- [x] Sampling continuity: no three consecutive task classes rely on manual checks only.
- [x] Wave 0 names the missing rerun-audit artifact and stale-state contradiction explicitly.
- [x] No watch-mode flags
- [x] Task-level feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
