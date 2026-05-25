# Phase 26: Historical Closeout Hygiene - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-UAT.md` | canonical closeout artifact normalization | historical closeout truth -> current UAT schema -> milestone audit gate | `/Users/jon/.codex/get-shit-done/templates/UAT.md` | strong |
| `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-VERIFICATION.md` | adjacent provenance clarification | verification report -> canonical UAT note | existing `12-VERIFICATION.md` human-verification section | strong |
| `/Users/jon/.codex/get-shit-done/bin/lib/audit.cjs` | archival gate hardening | UAT scan -> open-artifact gate -> milestone close | existing `scanUatGaps()` logic | strong |
| `/Users/jon/.codex/get-shit-done/bin/lib/uat.cjs` | checkpoint/parser hardening | current-test parsing -> checkpoint render / UAT audit | existing `parseCurrentTest()` logic | medium |
| `.planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md` | current-state milestone verdict cleanup | normalized UAT truth -> rerun audit narrative | `.planning/milestones/v1.1-MILESTONE-AUDIT.md` | strong |
| `.planning/ROADMAP.md` | active phase inventory closeout | executed Phase 26 plans -> milestone plan count | Phase 25 roadmap repair pattern | strong |
| `.planning/STATE.md` | session continuity after closeout hygiene | current focus -> milestone closeout next action | Phase 25 state narrowing pattern | strong |

## Pattern Assignments

### Canonical UAT schema normalization

**Pattern:** Use the current UAT template literally enough that both tooling and humans see the file as complete without interpretation.

**Planning takeaway:** Convert `status`, `## Current Test`, and per-test `result` tokens to the current contract. Keep the original `started` timestamp, update `updated`, and add one short explicit retrospective note.

### Retrospective note instead of alternate ledger

**Pattern:** Preserve the original verdict/date and explain the later schema normalization in a short grep-friendly note.

**Planning takeaway:** Put the note directly in `12-UAT.md`; optionally mirror it once in `12-VERIFICATION.md`. Do not create a new `12-CLOSEOUT.md` or other sidecar file.

### Legacy-closed compatibility must be diagnostic and narrow

**Pattern:** Read-only tooling may recognize a legacy closed alias, but only if there are zero open scenarios and the status is unmistakably closed.

**Planning takeaway:** If `audit.cjs` or `uat.cjs` is patched, scope it to `passed`-style legacy success markers only. Never relax `testing`, `partial`, `diagnosed`, skipped, blocked, or pending states.

### Additive chronology across milestone audits

**Pattern:** The failed snapshot remains the failed snapshot; the current rerun audit is the only present-tense milestone verdict.

**Planning takeaway:** Update `.planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md` after execution, but leave `.planning/v1.2-MILESTONE-AUDIT.md` untouched.

### Active roadmap/state are current-tense only

**Pattern:** `ROADMAP.md` and `STATE.md` should describe the live plan inventory and next action, not preserve stale historical blockers that the rerun audit has already narrowed.

**Planning takeaway:** Once Phase 26 executes, those files should point to milestone closeout rather than continuing to frame the Phase 12 UAT as unresolved.

## Implementation Notes

- Reuse the exact `status: complete` UAT frontmatter value from the current template.
- Prefer exact canonical markers such as `[testing complete]` and `result: pass`.
- Keep chronology-bearing dates explicit: the successful human closeout is 2026-05-23; the schema normalization is 2026-05-25.
- If tooling hardening is added, verify it with the repo-local `audit-open --json` command rather than synthetic prose-only checks.
