# Phase 26: Historical Closeout Hygiene - Research

**Researched:** 2026-05-25
**Domain:** historical UAT schema normalization, closeout metadata repair, and narrow archival-tooling hardening
**Confidence:** HIGH [VERIFIED: repo-local artifact audit, local source review]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-03 / D-04 / D-05:** Normalize the repo-owned Phase 12 UAT artifact to the current canonical UAT schema without changing the underlying successful 2026-05-23 verdict.
- **D-06 / D-07:** Add one explicit retrospective note to the UAT artifact; do not create a second sidecar ledger.
- **D-08 / D-09 / D-10:** Keep cleanup narrow. Fix the archival blocker plus the nearby metadata that would still mislead maintainers afterward.
- **D-13 / D-14 / D-15 / D-16:** Artifact normalization is the primary fix. A tiny tooling patch is allowed only as a secondary hardening step, and only for legacy closed aliases.
- **D-18 / D-19:** Preserve additive chronology and support truth so future maintainers can immediately tell that Phase 12 was already closed and Phase 26 only repaired stale schema.

### Out of Scope
- Reopening Phase 12 implementation, docs behavior, or verification scope.
- Broad historical normalization across unrelated summaries, audits, or UAT files.
- A general migration framework for all legacy GSD repositories.
</user_constraints>

## Summary

Phase 26 is a documentation-and-tooling hygiene phase, not a runtime behavior phase. The current blocker is concrete and reproducible: `node "$HOME/.codex/get-shit-done/bin/gsd-tools.cjs" audit-open --json` still reports one open UAT gap for Phase 12 because `12-UAT.md` uses the legacy frontmatter status `passed`, while `audit.cjs` only exempts status `complete`. [VERIFIED: local CLI] [CITED: /Users/jon/.codex/get-shit-done/bin/lib/audit.cjs]

The Phase 12 closeout itself already succeeded. `12-UAT.md` records two human checks that passed, `12-VERIFICATION.md` includes a full `Human Verification Completed` section, and the canonical v1.1 milestone audit explicitly says those human checks passed on 2026-05-23. The remaining problem is schema shape, not truth. [CITED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-UAT.md] [CITED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-VERIFICATION.md] [CITED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]

The smallest safe plan is three layers:
1. Normalize `12-UAT.md` in place to the current template contract: `status: complete`, canonical `## Current Test` completion marker, `result: pass` tokens, and one retrospective note preserving the 2026-05-23 verdict. [CITED: /Users/jon/.codex/get-shit-done/templates/UAT.md]
2. Add a narrow read-only compatibility hardening in the GSD audit/parser layer so legacy fully-closed aliases such as `passed` are recognized as closed when no pending, skipped, or blocked scenarios remain. This is optional but justified as a secondary guardrail. [CITED: /Users/jon/.codex/get-shit-done/bin/lib/audit.cjs] [CITED: /Users/jon/.codex/get-shit-done/bin/lib/uat.cjs]
3. Remove the last current-state metadata that still implies the closeout is unresolved, specifically the v1.2 rerun audit tech-debt note and the active roadmap/state story after Phase 26 execution. The failed 2026-05-25 snapshot stays untouched. [CITED: .planning/v1.2-MILESTONE-AUDIT.md] [CITED: .planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md] [CITED: .planning/ROADMAP.md] [CITED: .planning/STATE.md]

**Primary recommendation:** normalize the Phase 12 UAT artifact first, then harden audit parsing narrowly for legacy closed aliases, then update only the adjacent current-state artifacts that still describe the issue as unresolved.

## Repo Reality

### The exact archival blocker

- `audit-open --json` currently returns:
  - `counts.uat_gaps: 1`
  - item: `phase: "12"`, `file: "12-UAT.md"`, `status: "passed"`, `open_scenario_count: 0`
- `scanUatGaps()` in `audit.cjs` treats every UAT file whose frontmatter status is not `complete` as open, regardless of whether all scenarios already passed. [VERIFIED: local CLI] [CITED: /Users/jon/.codex/get-shit-done/bin/lib/audit.cjs]

### The Phase 12 artifact is stale relative to the current template

`12-UAT.md` differs from the current template in four user-visible ways:
- frontmatter uses `status: passed` instead of `status: complete`
- `## Current Test` contains `[completed]` instead of the template completion marker `[testing complete]`
- test rows use `result: [passed] ...` prose instead of the canonical `result: pass`
- the closeout explanation lives only in freeform notes rather than one explicit retrospective normalization note

These differences are enough to confuse automated closeout scanning even though the human verdict is already clear. [CITED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-UAT.md] [CITED: /Users/jon/.codex/get-shit-done/templates/UAT.md]

### Current proof and chronology already exist

- `12-VERIFICATION.md` already proves the human closeout checks and records why they were human-only judgments.
- `v1.1-MILESTONE-AUDIT.md` already treats the human checks as passed closeout work from 2026-05-23.
- `v1.2-MILESTONE-AUDIT.md` must remain the failed historical snapshot that still noted the stale Phase 12 UAT signal.
- `v1.2-rerun-MILESTONE-AUDIT.md` already narrows the issue to archival hygiene, so it is the right current-state artifact to update after Phase 26 lands.

No new business proof needs to be invented. [CITED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-VERIFICATION.md] [CITED: .planning/milestones/v1.1-MILESTONE-AUDIT.md] [CITED: .planning/v1.2-MILESTONE-AUDIT.md] [CITED: .planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md]

## Architectural Responsibility Map

| Concern | Primary Artifact | Secondary Artifact | Rationale |
|---------|------------------|--------------------|-----------|
| Canonical closeout truth for Phase 12 | `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-UAT.md` | `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-VERIFICATION.md` | The UAT file is the repo-owned completion artifact that milestone close scans directly. |
| Read-only archival audit behavior | `/Users/jon/.codex/get-shit-done/bin/lib/audit.cjs` | `/Users/jon/.codex/get-shit-done/bin/lib/uat.cjs` | Audit/parser logic should accept only clearly closed legacy aliases and remain strict for open states. |
| Current milestone verdict | `.planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md` | `.planning/ROADMAP.md`, `.planning/STATE.md` | The rerun audit owns current closeout truth; roadmap and state should stop contradicting it after execution. |
| Historical failure record | `.planning/v1.2-MILESTONE-AUDIT.md` | none | The failed 2026-05-25 snapshot is preserved chronology and should not be rewritten. |

## Standard Stack

No new package dependency is required. Phase 26 is satisfied with existing repo-owned markdown artifacts plus the installed GSD tooling sources. [VERIFIED: codebase scan]

### Core

| Tool / Artifact | Version | Purpose | Why Standard |
|-----------------|---------|---------|--------------|
| `12-UAT.md` + `12-VERIFICATION.md` | repo-local | Canonical closeout artifact pair for Phase 12 | They already contain the true verdict; only schema and adjacent wording need repair. |
| `node "$HOME/.codex/get-shit-done/bin/gsd-tools.cjs" audit-open --json` | local CLI | Reproduce the archival blocker and verify closeout clearance | This is the exact milestone-close preflight gate. |
| `rg` | 15.1.0 | Grep-based schema and chronology checks | Preferred by repo instructions and sufficient for this doc/tooling scope. |

### Supporting

| Tool / Artifact | Purpose | When to Use |
|-----------------|---------|-------------|
| `/Users/jon/.codex/get-shit-done/templates/UAT.md` | Canonical target schema for UAT normalization | Use to rewrite `12-UAT.md` into current contract shape. |
| `/Users/jon/.codex/get-shit-done/bin/lib/audit.cjs` | Open-artifact gate logic | Use if narrow legacy-closed compatibility hardening is still warranted after normalization. |
| `/Users/jon/.codex/get-shit-done/bin/lib/uat.cjs` | Current-test parsing/checkpoint rendering rules | Use only for narrow completion-marker compatibility, not broad semantic relaxation. |

## Recommended Execution Split

### Wave 1

- Normalize `12-UAT.md` to the current UAT schema.
- Add one explicit retrospective note preserving the 2026-05-23 closeout truth.
- Optionally add a matching explanatory note in `12-VERIFICATION.md`.

Reason: this is the artifact-level source fix and should land before any tooling or metadata cleanup.

### Wave 2

- Add narrow legacy-closed compatibility in `audit.cjs` and, if needed, `uat.cjs`.
- Re-run `audit-open --json` to prove the gate is now clear and still strict for truly open states.

Reason: tooling hardening is secondary and should be informed by the normalized file shape rather than replacing it.

### Wave 3

- Update current-state metadata (`v1.2-rerun-MILESTONE-AUDIT.md`, `ROADMAP.md`, `STATE.md`) so nothing still frames Phase 12 as an unresolved blocker.
- Preserve the failed v1.2 snapshot unchanged.

Reason: chronology and support truth should be cleaned up only after the underlying artifact and audit gate are correct.

## Architecture Patterns

### Pattern 1: Normalize repo-owned historical artifacts in place

**What:** When the repo fully owns the stale metadata artifact, convert it to the current canonical schema rather than carrying permanent dual-format ambiguity.

**Use here:** `12-UAT.md` is repo-owned and already semantically complete, so in-place normalization is safer than a sidecar ledger. [CITED: .planning/phases/26-historical-closeout-hygiene/26-CONTEXT.md]

### Pattern 2: Preserve chronology with retrospective notes, not rewrites

**What:** Keep the original verdict/date intact and add one explicit note saying a later phase normalized schema or archival metadata.

**Use here:** the note should say Phase 26 normalized the file on 2026-05-25 while preserving the successful 2026-05-23 human closeout. [CITED: .planning/phases/26-historical-closeout-hygiene/26-CONTEXT.md]

### Pattern 3: Narrow closed-alias compatibility only

**What:** If tooling compatibility is added, recognize only clearly closed legacy states and keep all pending, blocked, skipped, partial, diagnosed, or testing paths strict.

**Use here:** `audit.cjs` may accept legacy `passed` only when no open scenarios remain; it must not weaken open-gap detection. [CITED: /Users/jon/.codex/get-shit-done/bin/lib/audit.cjs]

## Anti-Patterns To Avoid

- Reopening Phase 12 implementation or docs scope just because the archival artifact is stale.
- Leaving `12-UAT.md` in legacy shape and teaching every future tool to special-case it forever.
- Rewriting `.planning/v1.2-MILESTONE-AUDIT.md` so the failed 2026-05-25 snapshot disappears.
- Broadening compatibility to treat `testing`, `partial`, `diagnosed`, skipped, or blocked states as effectively closed.
- Inventing a second closeout ledger that competes with `12-UAT.md`.

## Validation Architecture

### Verification style

- Use exact `rg` checks for UAT frontmatter, current-test marker, result tokens, and retrospective note.
- Use `audit-open --json` as the canonical closeout gate verification.
- Use targeted grep checks on rerun-audit and roadmap/state wording so current-state metadata no longer implies Phase 12 is still open.

### Approval criteria

- `audit-open --json` reports `counts.uat_gaps: 0`.
- `12-UAT.md` matches the current schema closely enough that human readers and tooling both read it as closed.
- Any tooling patch remains legacy-closed-only and does not weaken open-state detection.
- The failed v1.2 audit remains intact, while the rerun audit and current roadmap/state story stop carrying the stale open-item framing.
