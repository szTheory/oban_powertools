# Phase 25: Traceability & Audit Consistency Repair - Research

**Researched:** 2026-05-25
**Domain:** planning-doc traceability, milestone audit chronology, and verification ownership repair [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: codebase grep]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Decision-Making Default
- **D-01:** Shift recommendations left for this phase and downstream GSD work. Treat the decisions below as locked defaults unless a later choice would materially change provenance, support truth, or maintainer burden.
- **D-02:** Optimize for least surprise, explicit provenance, audit-closeable evidence, and future AI-maintainer clarity over cleaner retrospective storytelling.

### Traceability Model In `REQUIREMENTS.md`
- **D-03:** Preserve original implementation ownership for repaired requirements. `WFS-02`, `REC-03`, `SIG-01`, `SIG-02`, `SIG-03`, `DIA-01`, `DIA-02`, and `VER-01` should route back to the phases that implemented the behavior, not remain assigned to Phase 24 or Phase 25.
- **D-04:** Extend the v1.2 traceability table with one small explicit proof/closure pointer so an auditor can tell which current verification artifact closes the claim today without mistaking the repair phase for the implementation owner.
- **D-05:** Keep the proof pointer format rigid and grep-able rather than turning `REQUIREMENTS.md` into a mini database. A small additive column or equivalent explicit metadata is preferred over multi-axis over-modeling.
- **D-06:** Do not use “latest evidence writer” semantics for ownership. Repair phases add closure evidence; they do not become the semantic owners of workflow behavior.

### Milestone Audit Refresh Posture
- **D-07:** Preserve `.planning/v1.2-MILESTONE-AUDIT.md` as the 2026-05-25 failed snapshot rather than rewriting it in place to look like the gaps never existed.
- **D-08:** Create a successor rerun audit artifact that reflects the post-Phase-24 present-tense state and aggregates the new phase-local verification files.
- **D-09:** Add a short superseded/rerun pointer at the top of the failed audit so readers who land there can immediately find the current canonical audit result.
- **D-10:** Keep milestone audits as additive chronology-bearing artifacts: the failed audit proves what was broken, and the rerun audit proves what is now closed.

### Top-Level Canonical Doc Scope
- **D-11:** Fully sync the active audit trio for this phase: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and the milestone audit artifacts.
- **D-12:** Also make targeted role-clarifying edits in `.planning/PROJECT.md` and `.planning/STATE.md` so those top-level entrypoints stop contradicting the current milestone story.
- **D-13:** Do not broadly rewrite `PROJECT.md` or `STATE.md` into duplicate mini-roadmaps. Narrow them toward their intended roles and point volatile milestone-progress truth back to the live canonical files.
- **D-14:** Prefer one clear canonical source per type of truth:
  requirements closure in `REQUIREMENTS.md`,
  active phase ordering in `ROADMAP.md`,
  milestone pass/fail aggregation in milestone audit artifacts,
  stable product posture in `PROJECT.md`,
  session continuity in `STATE.md`.

### Summary / History Cleanup Boundary
- **D-15:** Preserve summary bodies as execution-history artifacts by default.
- **D-16:** Do not perform repo-wide summary normalization just to make old phases read like today’s repaired closure posture.
- **D-17:** If a summary is objectively misleading after Phase 25, add one narrow standardized retrospective correction note rather than rewriting the body wholesale.
- **D-18:** Only summaries that create a real reader trap should receive that note; otherwise leave them untouched and rely on the canonical traceability and audit artifacts.
- **D-19:** If any summary is corrected, keep the note visibly retrospective and grep-able, following the established Phase 5-style historical honesty posture.

### Carry-Forward Governance Rule
- **D-20:** For future evidence-repair phases, use the same stable model:
  original implementation ownership stays put,
  canonical closure lives in phase-local `VERIFICATION.md`,
  top-level traceability points at that proof explicitly,
  milestone audits are additive and may be superseded by reruns,
  summary normalization stays narrow and exception-based.

### the agent's Discretion
- Exact wording of the proof-pointer field names and audit supersession note, provided the ownership-versus-closure distinction stays explicit.
- Exact name of the successor v1.2 audit artifact, provided it is obviously the rerun/current canonical audit and cross-links cleanly from the failed snapshot.
- Exact threshold language for “materially misleading” summaries, provided it remains narrow, objective, and auditable.

### Deferred Ideas (OUT OF SCOPE)
- Repo-wide summary/frontmatter modernization beyond files that are objectively misleading after the repaired traceability chain lands.
- Any new runtime, UI, telemetry, or support-truth semantics not already implemented in Phases 17-23.
- Historical closeout cleanup unrelated to v1.2 traceability and audit bookkeeping; that belongs in Phase 26.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WFS-02 | Runtime and operator mutations can only move workflows through documented legal transitions that are recomputed from Postgres-backed truth rather than transient PubSub state. | Keep ownership on Phase 17 and point closure to `17-VERIFICATION.md`; use the rerun audit to mark present-tense closure without reassigning the requirement. [CITED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-VERIFICATION.md] |
| REC-03 | Workflow cancellation is cooperative and explicit: operators can see request versus final outcome, and late step completion after a cancel request is preserved as durable evidence instead of hidden. | Keep ownership on Phase 20 and point closure to `20-VERIFICATION.md`; use supporting references only where operator handoff context matters. [CITED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-VERIFICATION.md] |
| SIG-01 | A workflow step can durably register an await contract with signal name, correlation identity, dedupe behavior, and deadline so waiting survives restarts and cross-node execution. | Keep ownership on Phase 19 and point closure to `19-VERIFICATION.md`. [CITED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md] |
| SIG-02 | Incoming workflow signals are stored as durable facts and reconciled idempotently whether they arrive before, during, or after a matching wait registration. | Keep ownership on Phase 19 and point closure to `19-VERIFICATION.md`. [CITED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md] |
| SIG-03 | Expiry and late-arrival policy is explicit: a maintainer can tell whether an overdue wait failed, cancelled downstream work, remained recoverable, or ignored late signals by contract. | Keep ownership on Phase 19 and point closure to `19-VERIFICATION.md`, with optional support note to Phase 20 only where race-ordering context is useful. [CITED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md] |
| DIA-01 | A workflow screen can explain durable cause classes without requiring direct database inspection. | Keep ownership on Phase 21 and point closure to `21-VERIFICATION.md`; do not leave ownership on Phase 17 or Phase 24. [CITED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-VERIFICATION.md] |
| DIA-02 | Lifeline and workflow inspection surfaces consume the same workflow diagnosis vocabulary and expose only bounded, audited recovery actions that re-enter the workflow command pipeline. | Keep ownership on Phase 22 and point closure to `22-VERIFICATION.md`. [CITED: .planning/phases/22-lifeline-integration-bounded-recovery-actions/22-VERIFICATION.md] |
| VER-01 | The repo proves duplicate, late, dropped, and race-path workflow events with automated fixtures covering signal replay, cancel-versus-complete races, expiry, and lost wakeup reconciliation. | Keep ownership on Phase 23 and point closure to `23-VERIFICATION.md`, while allowing supporting proof links from earlier semantics phases. [CITED: .planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-VERIFICATION.md] |
</phase_requirements>

## Summary

Phase 25 is a documentation-governance repair phase, not a runtime phase. The repo already has canonical phase-local closure artifacts for all eight reopened v1.2 requirements because Phase 24 added `17/19/20/21/22/23-VERIFICATION.md`; the remaining problem is that the top-level planning story still reflects the failed 2026-05-25 audit snapshot instead of the repaired proof chain. [CITED: .planning/phases/24-verification-artifact-backfill/24-RESEARCH.md] [CITED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-VERIFICATION.md] [CITED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md] [CITED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-VERIFICATION.md] [CITED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-VERIFICATION.md] [CITED: .planning/phases/22-lifeline-integration-bounded-recovery-actions/22-VERIFICATION.md] [CITED: .planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-VERIFICATION.md]

The planner should treat this as a five-file synchronization task across `REQUIREMENTS.md`, `ROADMAP.md`, `PROJECT.md`, `STATE.md`, and the v1.2 milestone audit set, with one additive new audit artifact. The key invariant is that requirement ownership stays with the implementation phases, present-tense closure points at the current `VERIFICATION.md`, and the original failed audit remains preserved as historical evidence with a pointer to the rerun result. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] [CITED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]

The smallest safe design is to expand the `REQUIREMENTS.md` traceability table from `Requirement | Phase | Status` to a rigid ownership-plus-proof shape, then generate a new passed v1.2 rerun audit that mirrors the v1.1 passed-audit style while explicitly distinguishing historical failure from current closure. `PROJECT.md` and `STATE.md` should be narrowed so they stop restating stale phase-by-phase progress in places that are supposed to be stable posture and session continuity documents. [CITED: .planning/REQUIREMENTS.md] [CITED: .planning/PROJECT.md] [CITED: .planning/STATE.md] [CITED: .planning/v1.2-MILESTONE-AUDIT.md]

**Primary recommendation:** Keep original owner phases in `REQUIREMENTS.md`, add one grep-able proof-pointer column to the traceability table, preserve `.planning/v1.2-MILESTONE-AUDIT.md` as the failed 2026-05-25 snapshot, and create a new passed rerun audit as the canonical present-tense milestone verdict. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Requirement ownership repair | `REQUIREMENTS.md` | phase-local `VERIFICATION.md` files | The traceability table is the canonical ownership ledger, while the verification files are the canonical proof targets. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| Present-tense milestone verdict | rerun milestone audit artifact | `.planning/v1.2-MILESTONE-AUDIT.md` | The rerun audit should become the current verdict, while the existing file remains the failed historical snapshot. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| Historical failure record | `.planning/v1.2-MILESTONE-AUDIT.md` | rerun milestone audit artifact | The failed audit must be preserved and cross-linked rather than rewritten away. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| Active phase ordering | `ROADMAP.md` | milestone audit artifacts | `ROADMAP.md` owns current gap-closure sequencing, but should stop contradicting the repaired audit story. [CITED: .planning/ROADMAP.md] |
| Stable product posture | `PROJECT.md` | `ROADMAP.md` | `PROJECT.md` should describe stable shipped posture and current milestone framing, not stale per-phase execution state. [CITED: .planning/PROJECT.md] |
| Session continuity | `STATE.md` | `ROADMAP.md`, rerun milestone audit artifact | `STATE.md` should point future agents to the live phase and current audit truth without preserving obsolete “Phase 24 executing” text. [CITED: .planning/STATE.md] |

## Standard Stack

No new package or library dependency is required for Phase 25 because the phase scope is limited to `.planning/` artifact repair and consistency checks. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Existing `.planning/` markdown artifacts | n/a | Canonical source-of-truth layer for requirements, roadmap, milestone audit, state, and project posture. | Phase 25 is explicitly scoped to these files and not to runtime code changes. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| `ripgrep` | 15.1.0 | Fast consistency checks over requirement IDs, proof pointers, and cross-links. | The repo instructions prefer `rg`, and it is available locally. [VERIFIED: local CLI] |
| Elixir `mix` / ExUnit | 1.19.5 | Existing repo test harness for optional confidence checks against the cited workflow proof seams. | The repo already uses `mix test` for milestone proof capture, though this phase is primarily doc-only. [VERIFIED: local CLI] [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| phase-local `VERIFICATION.md` artifacts | n/a | Canonical proof targets for the repaired requirements. | Use these as closure pointers from traceability and the rerun audit. [CITED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-VERIFICATION.md] [CITED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md] [CITED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-VERIFICATION.md] [CITED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-VERIFICATION.md] [CITED: .planning/phases/22-lifeline-integration-bounded-recovery-actions/22-VERIFICATION.md] [CITED: .planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-VERIFICATION.md] |
| passed milestone audit pattern | v1.1 local precedent | Shape for a canonical post-repair milestone verdict. | Use when drafting the successor v1.2 rerun audit so the result matches local precedent. [CITED: .planning/milestones/v1.1-MILESTONE-AUDIT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Owner phase + proof pointer in `REQUIREMENTS.md` | Move reopened requirements to Phase 24 or Phase 25 | Violates the locked ownership model and obscures which implementation phase actually owns the behavior. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| Additive rerun audit artifact | Rewrite `.planning/v1.2-MILESTONE-AUDIT.md` in place | Erases the failed 2026-05-25 evidence snapshot that this phase is required to preserve. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| Narrow role-clarifying edits in `PROJECT.md` and `STATE.md` | Full historical wording normalization | Creates avoidable churn and duplicates milestone truth across too many top-level entrypoints. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |

**Installation:**
```bash
# No new package installation required for Phase 25.
```

**Version verification:** No new npm packages are recommended in this research, so npm registry verification is not applicable. The local execution tools available for validation are `mix 1.19.5`, `elixir 1.19.5`, and `rg 15.1.0`. [VERIFIED: local CLI]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 24 verification backfills
        |
        v
17/19/20/21/22/23-VERIFICATION.md
        |
        +------------------------------+
        |                              |
        v                              v
REQUIREMENTS.md traceability      v1.2 rerun milestone audit
(owner phase + proof pointer)     (current canonical verdict)
        |                              ^
        |                              |
        +-----------> ROADMAP.md ------+
        |
        +-----------> PROJECT.md (stable posture only)
        |
        +-----------> STATE.md (session continuity only)

Historical path preserved:
.planning/v1.2-MILESTONE-AUDIT.md (failed 2026-05-25 snapshot)
        |
        v
superseded/rerun pointer to current canonical audit
```

The primary data flow is “phase-local proof exists” -> “traceability points at it” -> “rerun audit aggregates it” -> “top-level entrypoints stop contradicting it.” [CITED: .planning/phases/24-verification-artifact-backfill/24-RESEARCH.md] [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]

### Recommended Project Structure
```text
.planning/
├── REQUIREMENTS.md                         # Canonical ownership + closure-pointer ledger
├── ROADMAP.md                              # Active phase ordering and gap-closure sequencing
├── PROJECT.md                              # Stable product posture and milestone framing
├── STATE.md                                # Current session continuity and next-step pointer
├── v1.2-MILESTONE-AUDIT.md                 # Preserved failed 2026-05-25 snapshot
├── milestones/
│   └── v1.2-<rerun-name>-MILESTONE-AUDIT.md  # New current canonical rerun verdict
└── phases/17|19|20|21|22|23-.../XX-VERIFICATION.md  # Canonical proof artifacts
```

### Pattern 1: Owner Phase + Proof Pointer Split
**What:** Keep a single owner-phase column in `REQUIREMENTS.md`, then add one explicit proof-pointer column that names the present-tense closing artifact. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
**When to use:** Use for every reopened requirement that now has a canonical `VERIFICATION.md` but must not be reassigned to the repair phase. [CITED: .planning/REQUIREMENTS.md] [CITED: .planning/phases/24-verification-artifact-backfill/24-RESEARCH.md]
**Example:**
```markdown
<!-- Source: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md -->
| Requirement | Owner Phase | Proof Pointer | Status |
|-------------|-------------|---------------|--------|
| WFS-02 | 17 | 17-VERIFICATION.md | Complete |
| REC-03 | 20 | 20-VERIFICATION.md | Complete |
| SIG-01 | 19 | 19-VERIFICATION.md | Complete |
```

### Pattern 2: Additive Audit Chronology
**What:** Preserve the original failed audit, add a top-of-file pointer to the rerun artifact, and author a separate passed audit that becomes the current canonical milestone verdict. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
**When to use:** Use when a milestone audit failure was real at the time and later repair work closes it. [CITED: .planning/v1.2-MILESTONE-AUDIT.md] [CITED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]
**Example:**
```markdown
<!-- Source: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md -->
> Superseded for current milestone status by `.planning/milestones/v1.2-<rerun-name>-MILESTONE-AUDIT.md`.
> This file remains the failed 2026-05-25 snapshot.
```

### Pattern 3: Narrow Top-Level Role Clarification
**What:** Remove volatile or contradictory phase-status prose from `PROJECT.md` and `STATE.md`, then replace it with references to the live roadmap and current audit artifact. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
**When to use:** Use where top-level files currently restate stale milestone progress or obsolete active-phase status. [CITED: .planning/PROJECT.md] [CITED: .planning/STATE.md]
**Example:**
```markdown
<!-- Source: .planning/STATE.md -->
## Current Position

- Phase 25 is the active planning target.
- Canonical milestone verdict: `.planning/milestones/v1.2-<rerun-name>-MILESTONE-AUDIT.md`
- Historical failed snapshot: `.planning/v1.2-MILESTONE-AUDIT.md`
```

### Anti-Patterns to Avoid
- **Reassigning ownership to the repair phase:** This breaks the locked rule that implementation ownership stays with the original semantic phase. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
- **Rewriting the failed audit into a passed audit:** This destroys chronology and removes the evidence of what Phase 25 is repairing. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
- **Using Phase 14-style closure index as the proof owner:** Phase 14 is explicitly a memo/index precedent, not a proof-store reassignment pattern. [CITED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-VERIFICATION.md]
- **Broad summary cleanup:** The phase scope excludes repo-wide summary normalization unless a file is objectively misleading after repair. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Requirement closure topology | A new mini database inside `REQUIREMENTS.md` | One additive proof-pointer column | The context explicitly prefers a rigid small field over multi-axis over-modeling. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| Cross-phase proof storage | A second closure index that competes with `VERIFICATION.md` | Existing phase-local `VERIFICATION.md` files | Phase 24 established these files as the canonical present-tense closure layer. [CITED: .planning/phases/24-verification-artifact-backfill/24-CONTEXT.md] |
| Milestone history repair | In-place audit rewrite | Additive rerun audit artifact | The failed snapshot is required historical evidence. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| Top-level consistency | Repo-wide prose normalization | Narrow edits in `ROADMAP.md`, `PROJECT.md`, and `STATE.md` | The locked scope is the active audit trio plus targeted role clarification only. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |

**Key insight:** The repo already has the proof; this phase should repair the routing and chronology of that proof, not invent a new evidence system. [CITED: .planning/phases/24-verification-artifact-backfill/24-RESEARCH.md]

## Common Pitfalls

### Pitfall 1: Ownership Drift
**What goes wrong:** Reopened requirements stay mapped to Phase 24 or get moved to Phase 25 even though the implementation lives in Phases 17/19/20/21/22/23. [CITED: .planning/REQUIREMENTS.md] [CITED: .planning/phases/24-verification-artifact-backfill/24-RESEARCH.md]
**Why it happens:** The current traceability table only has `Requirement | Phase | Status`, which encourages “latest repair phase owns closure” shortcuts. [CITED: .planning/REQUIREMENTS.md]
**How to avoid:** Add a proof-pointer field while restoring the owner phase to the original implementation phase. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
**Warning signs:** `WFS-02`, `REC-03`, `SIG-01`, `SIG-02`, `SIG-03`, `DIA-01`, `DIA-02`, or `VER-01` still show `24` after the repair. [VERIFIED: codebase grep]

### Pitfall 2: Audit History Erasure
**What goes wrong:** The failed v1.2 audit is edited until it reads like the gaps never existed. [CITED: .planning/v1.2-MILESTONE-AUDIT.md]
**Why it happens:** It is tempting to “fix” the audit by rewriting the file that surfaced the failure. [ASSUMED]
**How to avoid:** Leave `.planning/v1.2-MILESTONE-AUDIT.md` as the failed 2026-05-25 snapshot and create a separate rerun artifact. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
**Warning signs:** The original file’s frontmatter `status: gaps_found` disappears instead of being preserved with a supersession pointer. [CITED: .planning/v1.2-MILESTONE-AUDIT.md]

### Pitfall 3: Top-Level Story Duplication
**What goes wrong:** `PROJECT.md`, `STATE.md`, and `ROADMAP.md` all try to restate the entire v1.2 milestone verdict in different words. [CITED: .planning/PROJECT.md] [CITED: .planning/STATE.md] [CITED: .planning/ROADMAP.md]
**Why it happens:** These files currently contain stale milestone progress text, so a naive repair may overcompensate by duplicating more status language everywhere. [CITED: .planning/PROJECT.md] [CITED: .planning/STATE.md]
**How to avoid:** Give each file one role and point volatile milestone truth back to the live canonical artifact. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
**Warning signs:** The same requirement-closure prose appears in more than one top-level file after the edit. [ASSUMED]

### Pitfall 4: Summary Overreach
**What goes wrong:** Historical summaries get broadly rewritten just to match the new present-tense closure posture. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
**Why it happens:** Summary bodies are the most visible historical artifacts, so they are easy to target during cleanup. [ASSUMED]
**How to avoid:** Touch summaries only if a file is objectively misleading, and use a standardized retrospective note instead of rewriting the body. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] [CITED: .planning/phases/0-01-SUMMARY.md]
**Warning signs:** Multiple old `SUMMARY.md` files change even though the phase scope is traceability and audit consistency only. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from local project sources:

### Traceability Table With Explicit Closure Pointer
```markdown
<!-- Source: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md -->
## Traceability

| Requirement | Owner Phase | Closure Proof | Status |
|-------------|-------------|---------------|--------|
| WFS-02 | 17 | 17-VERIFICATION.md | Complete |
| REC-03 | 20 | 20-VERIFICATION.md | Complete |
| SIG-01 | 19 | 19-VERIFICATION.md | Complete |
| SIG-02 | 19 | 19-VERIFICATION.md | Complete |
| SIG-03 | 19 | 19-VERIFICATION.md | Complete |
| DIA-01 | 21 | 21-VERIFICATION.md | Complete |
| DIA-02 | 22 | 22-VERIFICATION.md | Complete |
| VER-01 | 23 | 23-VERIFICATION.md | Complete |
```

### Closure Memo / Index Pattern Without Re-Owning Proof
```markdown
<!-- Source: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-VERIFICATION.md -->
## Closure Memo

This file is a closure memo and index. Present-tense closure truth lives in the owning
phase verification files. This artifact helps auditors find the right proof quickly.
```

### Historical Summary Correction Note Pattern
```markdown
<!-- Source: .planning/phases/0-01-SUMMARY.md -->
## Retrospective Traceability Note

Phase 25 corrected top-level traceability so this summary remains historical execution evidence
and does not act as the canonical closure record.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Summary/frontmatter-only closure for Phases 17, 19, 20, 21, 22, and 23 | Canonical phase-local `VERIFICATION.md` closure for those phases | Phase 24 backfill on 2026-05-25 | Phase 25 can point top-level traceability directly at canonical proof instead of guessing from summaries. [CITED: .planning/phases/24-verification-artifact-backfill/24-RESEARCH.md] |
| Single failed v1.2 audit snapshot as the only milestone audit file | Failed snapshot preserved plus separate rerun audit as current canonical verdict | Locked by Phase 25 context on 2026-05-25 | Restores chronology without making current status ambiguous. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| `REQUIREMENTS.md` traceability with only `Requirement | Phase | Status` | Traceability with original owner plus explicit closure pointer | Required in Phase 25 planning | Prevents repair phases from looking like implementation owners. [CITED: .planning/REQUIREMENTS.md] [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |

**Deprecated/outdated:**
- `Requirement | Phase | Status` as the only v1.2 traceability model: it currently leaves eight repaired requirements mapped to Phase 24 `Pending`, even though canonical closure docs now exist. [CITED: .planning/REQUIREMENTS.md] [CITED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-VERIFICATION.md] [CITED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md] [CITED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-VERIFICATION.md] [CITED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-VERIFICATION.md] [CITED: .planning/phases/22-lifeline-integration-bounded-recovery-actions/22-VERIFICATION.md] [CITED: .planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-VERIFICATION.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Readers may be tempted to rewrite the failed audit in place because it is the most visible milestone artifact. | Common Pitfalls / Pitfall 2 | Low; the locked context still forbids this, but the planner might underweight the guardrail. |
| A2 | Duplicate milestone verdict prose across top-level files will create maintainability churn after the repair. | Common Pitfalls / Pitfall 3 | Low; the repo already prefers one canonical source per truth, so the main impact would be unnecessary plan breadth. |
| A3 | Summary files are likely to be over-edited unless the plan sets an explicit “only if objectively misleading” threshold. | Common Pitfalls / Pitfall 4 | Medium; uncontrolled summary edits would expand scope into historical normalization. |

## Open Questions

1. **What should the rerun audit filename be?**
   - What we know: The context locks “separate successor artifact” but leaves the exact name to agent discretion. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]
   - What's unclear: Whether the project prefers `v1.2-RERUN-MILESTONE-AUDIT.md`, a dated form, or `v1.2-current-MILESTONE-AUDIT.md`. [ASSUMED]
   - Recommendation: Pick the shortest name that is obviously “current canonical rerun” and easy to grep from the failed snapshot.

2. **Should any old summary receive a retrospective correction note in Phase 25?**
   - What we know: The context allows notes only for objectively misleading summaries and cites `.planning/phases/0-01-SUMMARY.md` as the local pattern. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] [CITED: .planning/phases/0-01-SUMMARY.md]
   - What's unclear: Which, if any, current summary actually traps readers after the top-level repairs land. [ASSUMED]
   - Recommendation: Treat summary edits as optional Wave 2 work only if a concrete misleading file is identified during the top-level consistency pass.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `rg` | fast traceability and cross-link audits | ✓ | 15.1.0 | `grep` if needed, but slower. [VERIFIED: local CLI] |
| `mix` | optional repo proof spot-checks and existing validation workflow alignment | ✓ | 1.19.5 | none; skip runtime checks if planner keeps phase doc-only. [VERIFIED: local CLI] |
| `elixir` | `mix` runtime for optional spot-checks | ✓ | 1.19.5 | none. [VERIFIED: local CLI] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local CLI]

**Missing dependencies with fallback:**
- None. [VERIFIED: local CLI]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Repo-local shell audit with `rg 15.1.0`; optional ExUnit harness available through `mix 1.19.5`. [VERIFIED: local CLI] |
| Config file | `test/test_helper.exs` for ExUnit; no dedicated markdown-lint config detected. [VERIFIED: codebase grep] |
| Quick run command | `rg -n "WFS-02|REC-03|SIG-01|SIG-02|SIG-03|DIA-01|DIA-02|VER-01|17-VERIFICATION|19-VERIFICATION|20-VERIFICATION|21-VERIFICATION|22-VERIFICATION|23-VERIFICATION" .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/PROJECT.md .planning/STATE.md .planning/v1.2-MILESTONE-AUDIT.md .planning/milestones/*.md` |
| Full suite command | `rg -n "superseded|rerun|canonical|Phase 25|Pending|Complete|gaps_found|passed" .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/PROJECT.md .planning/STATE.md .planning/v1.2-MILESTONE-AUDIT.md .planning/milestones/*.md && mix test test/oban_powertools/workflow_runtime_transitions_test.exs test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WFS-02 | `REQUIREMENTS.md` owner phase is 17 and closure pointer targets `17-VERIFICATION.md`. | doc consistency | `rg -n "^\\| WFS-02 \\| 17 \\| .*17-VERIFICATION\\.md \\| Complete \\|$" .planning/REQUIREMENTS.md` | ✅ |
| REC-03 | `REQUIREMENTS.md` owner phase is 20 and closure pointer targets `20-VERIFICATION.md`. | doc consistency | `rg -n "^\\| REC-03 \\| 20 \\| .*20-VERIFICATION\\.md \\| Complete \\|$" .planning/REQUIREMENTS.md` | ✅ |
| SIG-01 | `REQUIREMENTS.md` owner phase is 19 and closure pointer targets `19-VERIFICATION.md`. | doc consistency | `rg -n "^\\| SIG-01 \\| 19 \\| .*19-VERIFICATION\\.md \\| Complete \\|$" .planning/REQUIREMENTS.md` | ✅ |
| SIG-02 | `REQUIREMENTS.md` owner phase is 19 and closure pointer targets `19-VERIFICATION.md`. | doc consistency | `rg -n "^\\| SIG-02 \\| 19 \\| .*19-VERIFICATION\\.md \\| Complete \\|$" .planning/REQUIREMENTS.md` | ✅ |
| SIG-03 | `REQUIREMENTS.md` owner phase is 19 and closure pointer targets `19-VERIFICATION.md`. | doc consistency | `rg -n "^\\| SIG-03 \\| 19 \\| .*19-VERIFICATION\\.md \\| Complete \\|$" .planning/REQUIREMENTS.md` | ✅ |
| DIA-01 | `REQUIREMENTS.md` owner phase is 21 and closure pointer targets `21-VERIFICATION.md`. | doc consistency | `rg -n "^\\| DIA-01 \\| 21 \\| .*21-VERIFICATION\\.md \\| Complete \\|$" .planning/REQUIREMENTS.md` | ✅ |
| DIA-02 | `REQUIREMENTS.md` owner phase is 22 and closure pointer targets `22-VERIFICATION.md`. | doc consistency | `rg -n "^\\| DIA-02 \\| 22 \\| .*22-VERIFICATION\\.md \\| Complete \\|$" .planning/REQUIREMENTS.md` | ✅ |
| VER-01 | `REQUIREMENTS.md` owner phase is 23 and closure pointer targets `23-VERIFICATION.md`; rerun audit marks requirement satisfied. | doc consistency | `rg -n "^\\| VER-01 \\| 23 \\| .*23-VERIFICATION\\.md \\| Complete \\|$" .planning/REQUIREMENTS.md && rg -n "`VER-01`.*satisfied" .planning/milestones/*.md` | ✅ |

### Sampling Rate
- **Per task commit:** run the quick `rg` consistency command. [VERIFIED: local CLI]
- **Per wave merge:** rerun the full planning-doc consistency command and review the new milestone audit links manually. [ASSUMED]
- **Phase gate:** all eight requirement rows, both audit artifacts, and the top-level role clarifications must agree before `/gsd-verify-work`. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md]

### Wave 0 Gaps
- [ ] No reusable doc-audit script exists; Phase 25 will likely use inline `rg` commands in summaries or verification notes. [VERIFIED: codebase grep]
- [ ] The target rerun audit file does not exist yet. [VERIFIED: codebase grep]
- [ ] `STATE.md` still contains stale “Phase 24 executing” text that must be normalized before the phase can be considered consistent. [CITED: .planning/STATE.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 25 does not change auth behavior; it only repairs planning artifacts. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| V3 Session Management | no | No session semantics are in scope for this doc-only phase. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| V4 Access Control | no | No runtime access-control logic changes are planned. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| V5 Input Validation | yes | Use rigid, grep-able table formats and exact requirement IDs to avoid traceability drift. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| V6 Cryptography | no | No cryptographic behavior is in scope. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |

### Known Threat Patterns for planning-doc consistency

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Requirement ownership drift | Tampering | Keep original owner phases in `REQUIREMENTS.md` and add separate proof pointers instead of reassigning rows. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| Historical audit erasure | Repudiation | Preserve the failed 2026-05-25 audit and add a superseded/rerun pointer to a new passed audit artifact. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| Contradictory support truth across top-level docs | Information disclosure | Narrow `PROJECT.md` and `STATE.md` to their intended roles and point volatile truth to canonical files. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |
| Summary over-normalization | Tampering | Only add retrospective notes when a concrete summary is objectively misleading after the top-level repair. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md` - locked scope, ownership model, audit chronology rules, and top-level doc boundaries.
- `.planning/REQUIREMENTS.md` - current v1.2 requirement list, proof posture gate, and stale traceability-table shape.
- `.planning/ROADMAP.md` - active phase ordering and explicit Phase 25 goal statement.
- `.planning/PROJECT.md` - current top-level posture and stale v1.2 status text.
- `.planning/STATE.md` - current session-continuity text and stale “Phase 24 executing” contradiction.
- `.planning/v1.2-MILESTONE-AUDIT.md` - failed 2026-05-25 snapshot and exact reopened-requirement inventory.
- `.planning/milestones/v1.1-MILESTONE-AUDIT.md` - local precedent for a passed additive milestone audit after repair work.
- `.planning/phases/24-verification-artifact-backfill/24-CONTEXT.md` and `24-RESEARCH.md` - Phase 24 boundary and the proof-topology model that Phase 25 must route explicitly.
- `.planning/phases/17-db-first-transition-engine-command-pipeline/17-VERIFICATION.md`
- `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md`
- `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-VERIFICATION.md`
- `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-VERIFICATION.md`
- `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-VERIFICATION.md`
- `.planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-VERIFICATION.md`
- `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-VERIFICATION.md` - local closure-index precedent.
- `.planning/phases/0-01-SUMMARY.md` - local retrospective correction-note precedent.
- Local CLI checks: `mix --version`, `elixir --version`, `rg --version`. [VERIFIED: local CLI]

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- The behavioral assumptions listed in the Assumptions Log.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no external dependency choice is needed; local tools and artifact boundaries were verified directly in the repo. [VERIFIED: local CLI] [VERIFIED: codebase grep]
- Architecture: HIGH - the ownership/proof split and additive audit model are locked in Phase 25 context and reinforced by Phase 14 and Phase 24 precedents. [CITED: .planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md] [CITED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-VERIFICATION.md] [CITED: .planning/phases/24-verification-artifact-backfill/24-RESEARCH.md]
- Pitfalls: MEDIUM - the concrete contradictions are verified, but some maintainability risks are predictive and therefore logged as assumptions. [CITED: .planning/PROJECT.md] [CITED: .planning/STATE.md] [CITED: .planning/v1.2-MILESTONE-AUDIT.md]

**Research date:** 2026-05-25
**Valid until:** 2026-06-24
