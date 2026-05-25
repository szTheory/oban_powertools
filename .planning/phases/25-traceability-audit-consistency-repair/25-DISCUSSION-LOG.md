# Phase 25: Traceability & Audit Consistency Repair - Discussion Log

**Date:** 2026-05-25  
**Mode:** `gsd-discuss-phase 25` with all gray areas discussed and subagent-backed research  
**Discussion posture:** shift recommendations left unless a choice would materially affect provenance, support truth, or maintainer burden

## Boundary Confirmed

Phase 25 is a planning/evidence-repair phase. It aligns traceability and milestone bookkeeping with the verification chain created by Phase 24. It does not change workflow runtime semantics and does not broadly normalize historical artifacts for style.

## Repo Reality Captured Before Discussion

- Phase 24 had already created:
  - `17-VERIFICATION.md`
  - `19-VERIFICATION.md`
  - `20-VERIFICATION.md`
  - `21-VERIFICATION.md`
  - `22-VERIFICATION.md`
  - `23-VERIFICATION.md`
- `.planning/REQUIREMENTS.md` still routed `WFS-02`, `REC-03`, `SIG-01`, `SIG-02`, `SIG-03`, `DIA-01`, `DIA-02`, and `VER-01` to Phase 24 as `Pending`.
- `.planning/v1.2-MILESTONE-AUDIT.md` still described the pre-backfill failed state.
- `.planning/PROJECT.md` and `.planning/STATE.md` still contained stale milestone-progress wording that contradicted the newer top-level project state.

## Area 1: Traceability Model

### Options presented

1. Keep implementation-phase ownership only and mark rows complete.
2. Keep implementation-phase ownership plus explicit proof/closure pointer metadata.
3. Reassign ownership to the repair phase.
4. Use a heavier dual-axis `owner` plus `closed by` model.

### Research considerations surfaced

- Strong OSS and architecture patterns preserve original ownership and add later closure links rather than moving historical ownership.
- Reassigning ownership to the repair phase corrupts provenance and creates support confusion.
- A bare ownership-only table is too implicit for future maintainers and recreates the exact “which artifact closes this?” confusion that triggered Phase 25.

### Selected default

**Locked choice:** Option 2.

Keep original implementation ownership and add one small explicit proof/closure pointer in `REQUIREMENTS.md`.

### Why this was selected

- Matches Phase 5 and Phase 24 locked posture.
- Preserves historical truth.
- Makes current closure discoverable without turning the table into a mini database.
- Best fit for future AI-maintainer ergonomics.

## Area 2: Milestone Audit Refresh Posture

### Options presented

1. Rewrite `.planning/v1.2-MILESTONE-AUDIT.md` in place.
2. Keep the failed audit and append a rerun section to the same file.
3. Keep the failed audit unchanged and create a successor audit artifact.
4. Hybrid: keep the failed audit body intact, create a successor audit artifact, and add a superseded/rerun pointer in the old file.

### Research considerations surfaced

- In-place rewrite is the highest-provenance-loss option.
- One-file append keeps continuity but creates canonical-status ambiguity.
- Additive chronology with explicit supersession is the cleanest fit for evidence-first governance.

### Selected default

**Locked choice:** Option 4.

Preserve the failed 2026-05-25 audit, create a successor rerun audit artifact for the repaired state, and add a clear superseded/rerun pointer to the old file.

### Why this was selected

- Preserves what failed and what was repaired.
- Keeps the current canonical audit easy to identify.
- Mirrors the repo’s additive repair posture and v1.1-style closure discipline.

## Area 3: Scope Of Consistency Repair

### Options presented

1. Sync only `ROADMAP.md`, `REQUIREMENTS.md`, and the milestone audit.
2. Sync all top-level canonical docs wholesale, including `PROJECT.md` and `STATE.md`.
3. Sync only the minimum docs needed for the audit and defer the rest.
4. Hybrid: fully sync the audit trio, then make targeted role-clarifying edits in `PROJECT.md` and `STATE.md`.

### Research considerations surfaced

- Audit-only repair leaves obvious contradictions in the first files future maintainers and agents are likely to open.
- Wholesale harmonization risks turning the phase into a broad planning-doc rewrite.
- Narrow role-clarifying edits preserve file boundaries while removing the most misleading volatile claims.

### Selected default

**Locked choice:** Option 4.

Sync the audit trio completely and make targeted role-clarifying edits in `PROJECT.md` and `STATE.md`, without reauthoring them wholesale.

### Why this was selected

- Best balance of least surprise and scope discipline.
- Removes contradictory current-state language.
- Preserves clean ownership boundaries among top-level planning artifacts.

## Area 4: Summary / History Cleanup Boundary

### Options presented

1. Do not touch summaries at all.
2. Add narrow correction metadata/notes only where summaries are materially misleading.
3. Broadly normalize summaries to match the new closure posture.
4. Hybrid: preserve summary bodies by default, add standard correction notes plus an exception-oriented convention for the few files that truly need it.

### Research considerations surfaced

- Broad summary normalization is explicitly discouraged by earlier phases and would blur history.
- Leaving every summary untouched can preserve reader traps where older closure language conflicts with repaired canonical truth.
- The repo already has a good precedent for visible retrospective notes without pretending the original text was current-state truth.

### Selected default

**Locked choice:** Option 4, implemented conservatively.

Leave summaries untouched by default. If a summary is objectively misleading after Phase 25, add one narrow standardized retrospective correction note rather than rewriting the body.

### Why this was selected

- Preserves execution history.
- Fixes only real traps.
- Reuses an existing local precedent instead of inventing a broader archive-migration obligation.

## Final Locked Recommendation Set

1. `REQUIREMENTS.md` keeps original implementation ownership and gains a small explicit proof pointer.
2. The failed v1.2 milestone audit remains as a preserved snapshot and is superseded by a rerun audit artifact.
3. `ROADMAP.md`, `REQUIREMENTS.md`, and the milestone audit artifacts are fully synced; `PROJECT.md` and `STATE.md` receive targeted role-clarifying edits only.
4. Historical summaries remain execution-history artifacts unless a specific file is objectively misleading, in which case it gets one standardized retrospective correction note.

## Inputs Consulted

- Local repo artifacts:
  - `.planning/ROADMAP.md`
  - `.planning/PROJECT.md`
  - `.planning/REQUIREMENTS.md`
  - `.planning/STATE.md`
  - `.planning/v1.2-MILESTONE-AUDIT.md`
  - `.planning/milestones/v1.1-MILESTONE-AUDIT.md`
  - `.planning/phases/24-verification-artifact-backfill/24-CONTEXT.md`
  - `.planning/phases/24-verification-artifact-backfill/24-RESEARCH.md`
  - `.planning/phases/17-db-first-transition-engine-command-pipeline/17-VERIFICATION.md`
  - `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md`
  - `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-VERIFICATION.md`
  - `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-VERIFICATION.md`
  - `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-VERIFICATION.md`
  - `.planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-VERIFICATION.md`
  - `.planning/phases/5-CONTEXT.md`
  - `.planning/phases/5-PATTERNS.md`
  - `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md`
  - `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-VERIFICATION.md`
  - `.planning/phases/0-01-SUMMARY.md`
- Prompt guidance:
  - `prompts/oban_powertools_context.md`
  - `prompts/oban_powertools_ultimate_ui_strategy_brief.md`
  - `prompts/oban-powertools-deep-research-original-prompt.md`
- Subagent-backed research was used for all four gray areas and synthesized into the locked defaults above.

## Deferred Ideas

- Broad historical artifact normalization.
- Any runtime or UI semantics changes.
- Phase 26 historical closeout work unrelated to the v1.2 verification chain.
