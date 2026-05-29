# Phase 5: Milestone Evidence & Traceability Closure - Research

**Researched:** 2026-05-20 [VERIFIED: current session date]
**Domain:** Milestone audit closure, verification artifacts, and requirement traceability repair for Phases 0 through 4. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/5-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/5-CONTEXT.md]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Downstream GSD agents should treat the recommendations in this context as locked defaults and avoid re-asking unless a later choice would materially affect correctness, audit trust, or the project’s historical truthfulness.
- **D-02:** Shift defaults left for this project: prefer decisive best-practice recommendations over interactive re-litigation, except for unusually high-impact choices that would materially change product semantics or roadmap scope.
- **D-03:** Phase 5 stays artifact-first and evidence-first. Its primary deliverables are missing verification artifacts, restored traceability metadata, repaired summary completeness, and synchronized requirement status.
- **D-04:** Phase 5 must not absorb runtime or behavioral fixes that belong to already-identified implementation gap phases. In particular, Phase 6 remains responsible for the runtime config and authorization defects, and Phase 7 remains responsible for the lifeline incident-closure defect.
- **D-05:** If evidence restoration uncovers an additional real implementation bug, record it as deferred follow-on work rather than silently folding it into Phase 5.
- **D-06:** Only artifact-local edits are in scope by default: planning docs, summary files, validation files, verification files, traceability tables, and other evidence-bearing repository artifacts.
- **D-07:** Completion proof for Phase 5-covered requirements must be based on fresh, rerunnable verification evidence tied to concrete commands or targeted tests, not retrospective narrative alone.
- **D-08:** Retrospective documentation is allowed only as supporting traceability metadata: restoring missing summary files, frontmatter, and requirement links around fresh verification proof.
- **D-09:** Every requirement closed by Phase 5 must map to at least one concrete verification command, and the verification artifact must record pass/fail outcomes in the current repository state.
- **D-10:** Broad commands such as `mix test` are acceptable only when narrower requirement-relevant commands are also listed or clearly subsumed by the broader command.
- **D-11:** The final Phase 5 gate must include rerunning the milestone audit itself, because removing orphaned requirements from the audit is an explicit success criterion.
- **D-12:** Normalize only the artifacts the audit identifies as broken, missing, or required for traceability closure.
- **D-13:** Do not rewrite prior phase prose for stylistic uniformity alone. Preserve historical wording unless a change is required to restore machine-readable traceability or correct an objective inconsistency.
- **D-14:** Missing or incomplete legacy artifacts should be backfilled to the minimum extent necessary to satisfy the audit’s 3-source cross-check:
  phase summaries,
  phase verification artifacts,
  validation frontmatter where needed,
  and `REQUIREMENTS.md` synchronization.
- **D-15:** When a legacy artifact is normalized in Phase 5, the normalization should be clearly attributable to traceability closure rather than presented as if it were original contemporaneous authorship.
- **D-16:** Use Phase 5 as the forward standard for evidence quality, but do not convert the entire historical archive into a full-template migration unless a later automation need explicitly justifies that work.
- **D-17:** Requirements remain owned by their original implementation phases. Phase 5 provides closure evidence; it does not become the historical implementation owner for already-built functionality.
- **D-18:** Traceability must distinguish implementation ownership from verification closure. A requirement can be implemented in Phase N and verified/closed in Phase 5 without rewriting its original phase ownership.
- **D-19:** `REQUIREMENTS.md` should preserve the implementation phase as the canonical owner and add explicit proof/closure information rather than reassigning already-built requirements to Phase 5.
- **D-20:** Status semantics should be derived from evidence rather than reassigned for convenience:
  implemented,
  verified,
  complete,
  pending,
  or orphaned/gap.
- **D-21:** Requirements attached to true unfinished implementation work stay with their future implementation phases, even if the audit surfaced them during milestone closure.
- **D-22:** Favor command-level, grep-able, low-ambiguity verification over prose-heavy “trust me” closure language.
- **D-23:** Keep artifact changes narrowly scoped and reviewable so the diff tells a clear story: what proof was missing, what was restored, and how the orphaned requirement was closed.
- **D-24:** The least surprising operator/developer experience for this repo is explicit provenance: what was built when, what was proven when, and which artifact provides that proof.
- **D-25:** The planning and verification surface should remain friendly to future AI-assisted maintenance by using stable requirement ids, stable file naming, explicit command maps, and minimal implicit interpretation.

### Claude's Discretion
- Exact frontmatter schema for summary/validation/verification files, provided it preserves explicit requirement linkage and proof provenance.
- Exact wording of traceability tables and verification sections, provided they remain objective, auditable, and easy to diff.
- Exact grouping of verification commands by phase or requirement, provided the mapping from requirement id to fresh proof stays explicit.

### Deferred Ideas (OUT OF SCOPE)
- Full repository-wide historical artifact standardization beyond what the audit requires.
- Folding runtime defect fixes into Phase 5 for convenience.
- Reassigning already-implemented requirements to Phase 5 as if it were their implementation owner.
- Any broad re-baselining of roadmap or milestone history that weakens causality between implementation phase and proof phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FND-03 | Establish the hybrid UI strategy (Powertools Native Shell wrapping Oban Web). [VERIFIED: .planning/REQUIREMENTS.md] | Close with fresh router/UI proof only; do not bundle Phase 6 auth/runtime-config defects into this requirement’s closure evidence. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/5-CONTEXT.md] |
| WRK-01 | Provide `use ObanPowertools.Worker` macro supporting compile-time Ecto schema `args`. [VERIFIED: .planning/REQUIREMENTS.md] | Existing Phase 1 summary already marks completion; missing piece is a phase verification artifact with fresh rerunnable commands. [VERIFIED: .planning/phases/1-01-SUMMARY.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| WRK-02 | Enqueue operations must synchronously validate args and return `{:error, changeset}` on failure. [VERIFIED: .planning/REQUIREMENTS.md] | Same closure model as WRK-01: retain historical ownership in Phase 1 and add fresh proof in Phase 5 artifacts. [VERIFIED: .planning/phases/1-01-SUMMARY.md] [VERIFIED: .planning/phases/5-CONTEXT.md] |
| WRK-03 | Implement Postgres-backed Idempotency Receipts to guarantee exactly-once business logic execution. [VERIFIED: .planning/REQUIREMENTS.md] | Same closure model as WRK-01/02. [VERIFIED: .planning/phases/1-01-SUMMARY.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| ENG-01 | Implement Ecto-native global and partitioned rate limiters (token buckets). [VERIFIED: .planning/REQUIREMENTS.md] | Requires backfilled Phase 2 summaries plus a Phase 2 verification artifact. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| ENG-02 | Provide `explain/1` capability to explicitly surface why any job is blocked. [VERIFIED: .planning/REQUIREMENTS.md] | Requires the same Phase 2 summary repair plus fresh proof. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/2-VALIDATION.md] |
| WF-01 | Model explicit DAG workflows using `oban_powertools_workflows` and `edges` tables. [VERIFIED: .planning/REQUIREMENTS.md] | Requires Phase 3 summary frontmatter normalization and a Phase 3 verification artifact. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/3-01-SUMMARY.md] |
| WF-02 | Build GenServer coordinators and Phoenix PubSub signaling for rapid step progression. [VERIFIED: .planning/REQUIREMENTS.md] | Same closure model as WF-01. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/3-VALIDATION.md] |
| WF-03 | Create a visual UI representation for DAG states, highlighting blocked steps. [VERIFIED: .planning/REQUIREMENTS.md] | Same closure model as WF-01. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/3-VALIDATION.md] |
| LIF-01 | Implement executor heartbeats tracking into `oban_powertools_heartbeats`. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 4 summaries already provide machine-readable completion markers; missing closure pieces are REQUIREMENTS sync and phase verification. [VERIFIED: .planning/phases/4-02-SUMMARY.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| LIF-03 | Audit all manual UI operations (retries, cancels) to `oban_powertools_audit_events`. [VERIFIED: .planning/REQUIREMENTS.md] | Same closure model as LIF-01, with extra care to avoid relying on deferred incident-closure behavior. [VERIFIED: .planning/phases/4-03-SUMMARY.md] [VERIFIED: .planning/phases/4-05-SUMMARY.md] [VERIFIED: .planning/phases/5-CONTEXT.md] |
| LIF-04 | Implement a dynamic pruner with an archive-before-delete compliance feature. [VERIFIED: .planning/REQUIREMENTS.md] | Same closure model as LIF-01. [VERIFIED: .planning/phases/4-04-SUMMARY.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
</phase_requirements>

## Summary

Phase 5 is a proof-recovery phase, not an implementation phase. The roadmap assigns it to restoring verification artifacts, summary completeness, and traceability for already-built work, while the phase context explicitly forbids absorbing the runtime config, authorization, and incident-closure defects already split into Phases 6 and 7. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/5-CONTEXT.md]

The authoritative audit gap list is still the best inventory of missing evidence, but it is not a perfect snapshot of today’s `REQUIREMENTS.md`: the audit was written at `2026-05-20T18:58:00+02:00`, while `REQUIREMENTS.md` was modified later in the same session and now routes requirements to Phases 5, 6, and 7 explicitly. Phase 5 should therefore use current roadmap/requirements files to define ownership boundaries and use the milestone audit as the artifact-gap checklist. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md]

The minimum closure model is strict and small: for each Phase 5-owned requirement, keep the original implementation phase, restore or normalize summary evidence, record fresh rerunnable commands in a phase `*-VERIFICATION.md`, and sync `REQUIREMENTS.md` so the three sources agree. Validation artifacts matter for phase completeness, but they are supporting evidence; the audit’s orphaned-requirement logic is driven by `REQUIREMENTS.md`, summary frontmatter, and `VERIFICATION.md`. [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]

**Primary recommendation:** Close Phase 5 by repairing only the evidence chain `REQUIREMENTS.md -> summary frontmatter -> phase VERIFICATION.md -> fresh command results -> rerun audit`, while explicitly leaving `FND-01`, `FND-02`, `ENG-03`, and `LIF-02` deferred to Phases 6 and 7. [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Requirement ownership and status truth | Repository planning artifacts | Milestone audit artifact | Current phase ownership is defined in `ROADMAP.md`, `REQUIREMENTS.md`, and Phase 5 context, not in code modules. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/5-CONTEXT.md] |
| Fresh proof capture | Mix/ExUnit CLI runtime | Phase `*-VERIFICATION.md` files | Phase 5 context requires rerunnable commands and pass/fail recording in current repo state. [VERIFIED: .planning/phases/5-CONTEXT.md] |
| Machine-readable completion markers | Phase summary frontmatter | `REQUIREMENTS.md` traceability rows | The audit treats missing summary frontmatter as one of the three broken proof sources. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| Milestone closure gate | Milestone audit rerun | Verification artifacts | The roadmap and context both require rerunning the audit as the explicit gate. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/5-CONTEXT.md] |

## Standard Stack

### Core
| Library / Artifact | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `mix` / ExUnit | Mix 1.19.5, Elixir 1.19.5 | Execute fresh targeted verification commands. | These tools are present locally and already underpin every existing validation document. [VERIFIED: `mix --version`] [VERIFIED: `elixir --version`] [VERIFIED: .planning/phases/0-VALIDATION.md] [VERIFIED: .planning/phases/2-VALIDATION.md] [VERIFIED: .planning/phases/3-VALIDATION.md] |
| `REQUIREMENTS.md` traceability table | repo-local | Canonical requirement ownership/status surface. | The roadmap and Phase 5 context treat this file as the canonical ownership ledger that must be synchronized, not replaced. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/5-CONTEXT.md] |
| Summary YAML frontmatter | repo-local | Machine-readable requirement completion markers. | Existing local pattern already uses `requirements-completed` in Phase 1 and Phase 4, and the audit checks for it. [VERIFIED: .planning/phases/1-01-SUMMARY.md] [VERIFIED: repo grep requirements-completed] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| Phase `*-VERIFICATION.md` | missing and required | Fresh proof artifact per implementation phase. | The audit says every requirement is orphaned because these files do not exist yet. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: absence of `.planning/phases/*-VERIFICATION.md`] |

### Supporting
| Library / Artifact | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Existing `*-VALIDATION.md` files | repo-local | Seed requirement-to-command mappings. | Reuse for Phases 0, 2, and 3 instead of inventing new command maps. [VERIFIED: .planning/phases/0-VALIDATION.md] [VERIFIED: .planning/phases/2-VALIDATION.md] [VERIFIED: .planning/phases/3-VALIDATION.md] |
| Missing `1-VALIDATION.md` and `4-VALIDATION.md` | missing and audit-relevant | Phase completeness normalization outside the strict 3-source check. | Add if the planner wants the milestone audit’s “required verification and validation artifacts” language fully satisfied. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| `v1-v1-MILESTONE-AUDIT.md` | repo-local | Closure checklist and final gate target. | Use as the authoritative defect inventory, then rerun it at the end. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/5-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-phase `VERIFICATION.md` files | Retrospective prose inside summaries only | Rejected because Phase 5 context requires fresh rerunnable command evidence and the audit’s 3-source check explicitly expects `VERIFICATION.md`. [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| Syncing current ownership in `REQUIREMENTS.md` | Reassigning implemented requirements to Phase 5 | Rejected because Phase 5 preserves original implementation ownership and only adds closure proof. [VERIFIED: .planning/phases/5-CONTEXT.md] |

**Installation:** No new packages are required for this phase; the repo-local stack is existing Markdown artifacts plus `mix`/ExUnit. [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: `mix --version`]

**Version verification:** `mix --version` reports Mix 1.19.5 and `elixir --version` reports Elixir 1.19.5 in the current environment. [VERIFIED: `mix --version`] [VERIFIED: `elixir --version`]

## Scope Boundaries

### Requirement Routing
| Requirement | Phase 5 Action | Must Stay Deferred? | Why |
|-------------|----------------|---------------------|-----|
| FND-03 | Close with restored summary/verification/traceability evidence. | No | Current `REQUIREMENTS.md` assigns `FND-03` to Phase 5 and the roadmap names it in Phase 5 requirements. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] |
| WRK-01, WRK-02, WRK-03 | Close with evidence only. | No | Current `REQUIREMENTS.md` and roadmap assign them to Phase 5. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] |
| ENG-01, ENG-02 | Close with evidence only. | No | Current `REQUIREMENTS.md` and roadmap assign them to Phase 5. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] |
| WF-01, WF-02, WF-03 | Close with evidence only. | No | Current `REQUIREMENTS.md` and roadmap assign them to Phase 5. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] |
| LIF-01, LIF-03, LIF-04 | Close with evidence only. | No | Current `REQUIREMENTS.md` and roadmap assign them to Phase 5. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] |
| FND-01, FND-02 | Preserve as deferred implementation work in Phase 6, even if historical Phase 0 evidence is restored. | Yes, Phase 6 | The roadmap and current `REQUIREMENTS.md` assign them to Phase 6 because installer/runtime wiring remains broken. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| ENG-03 | Preserve as deferred implementation work in Phase 6. | Yes, Phase 6 | The roadmap and current `REQUIREMENTS.md` assign it to Phase 6 because cron preview authorization is still weaker than the execute path. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| LIF-02 | Preserve as deferred implementation work in Phase 7. | Yes, Phase 7 | The roadmap and current `REQUIREMENTS.md` assign it to Phase 7 because successful repair does not retire the active incident yet. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |

### Authoritative Scope Boundary
- Phase 5 may restore historical evidence around Phase 0 and Phase 4 work, but it must not claim to have fixed the runtime config, preview authorization, or incident-closure defects themselves. [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
- Phase 5 should treat current `ROADMAP.md` and current `REQUIREMENTS.md` as the ownership authority and treat the milestone audit as the missing-artifact inventory. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]

## Minimum Artifact Set for the Audit 3-Source Check

### Strict Minimum for Orphaned-Requirement Closure
| Artifact | Required Work | Why It Is Minimum |
|---------|---------------|-------------------|
| `0-01-SUMMARY.md` | Add machine-readable completion markers for `FND-03` only if they can be stated truthfully for current ownership boundaries. [VERIFIED: .planning/phases/0-01-SUMMARY.md] [VERIFIED: .planning/REQUIREMENTS.md] | The audit flags Phase 0 summary frontmatter as missing. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| `2-01-SUMMARY.md`, `2-02-SUMMARY.md`, `2-03-SUMMARY.md` | Backfill missing plan summaries. [VERIFIED: `.planning/phases/2-01-SUMMARY.md` missing] [VERIFIED: `.planning/phases/2-02-SUMMARY.md` missing] [VERIFIED: `.planning/phases/2-03-SUMMARY.md` missing] | The audit explicitly calls these files out as missing. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| `3-01-SUMMARY.md` through `3-05-SUMMARY.md` | Add YAML frontmatter with requirement linkage. [VERIFIED: .planning/phases/3-01-SUMMARY.md] [VERIFIED: .planning/phases/3-02-SUMMARY.md] | The audit says Phase 3 summaries exist but lack completion markers. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| `0-VERIFICATION.md` through `4-VERIFICATION.md` | Create one phase verification artifact per already-implemented phase. [VERIFIED: absence of `.planning/phases/*-VERIFICATION.md`] | The audit says every requirement is orphaned because no verification files exist. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| `REQUIREMENTS.md` | Sync requirement status/proof fields without changing deferred ownership. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/5-CONTEXT.md] | The current traceability table is stale relative to summary evidence for Phase 4 and lacks explicit closure proof fields. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/5-CONTEXT.md] |

### Additional Artifacts Needed for Full Audit Closure Beyond the 3-Source Rule
| Artifact | Required Work | Why It Matters |
|---------|---------------|----------------|
| `1-VALIDATION.md` and `4-VALIDATION.md` | Create missing validation docs. [VERIFIED: `.planning/phases/1-VALIDATION.md` missing] [VERIFIED: `.planning/phases/4-VALIDATION.md` missing] | The audit records missing validation artifacts for Phases 1 and 4. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| `0-VALIDATION.md`, `2-VALIDATION.md`, `3-VALIDATION.md` | Add frontmatter if the planner wants Nyquist normalization, but do not over-migrate structure beyond what the audit needs. [VERIFIED: .planning/phases/0-VALIDATION.md] [VERIFIED: .planning/phases/2-VALIDATION.md] [VERIFIED: .planning/phases/3-VALIDATION.md] | The audit calls out missing Nyquist frontmatter on these files. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |

## Architecture Patterns

### System Architecture Diagram
```text
Current ownership docs
ROADMAP.md + REQUIREMENTS.md + 5-CONTEXT.md
        |
        v
Requirement routing decision
        |
        +--> Phase 5-owned requirement
        |         |
        |         v
        |   restore/normalize summary evidence
        |         |
        |         v
        |   run targeted mix commands
        |         |
        |         v
        |   write phase VERIFICATION.md with pass/fail results
        |         |
        |         v
        |   sync REQUIREMENTS.md proof/status fields
        |
        +--> Deferred requirement (Phase 6/7)
                  |
                  v
            keep ownership pending
            do not mark complete in Phase 5
                  |
                  v
            note historical evidence only

All updated artifacts
        |
        v
rerun milestone audit
        |
        v
orphaned requirements cleared without rewriting implementation history
```

### Recommended Project Structure
```text
.planning/
├── REQUIREMENTS.md          # canonical requirement ownership + closure status
├── v1-v1-MILESTONE-AUDIT.md # rerun gate artifact
└── phases/
    ├── N-xx-SUMMARY.md      # plan-local completion metadata
    ├── N-VALIDATION.md      # requirement -> command map
    └── N-VERIFICATION.md    # fresh current-state proof
```

### Pattern 1: Three-Source Traceability Chain
**What:** Use one machine-readable chain per requirement: `REQUIREMENTS.md`, summary frontmatter, and phase `VERIFICATION.md`. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/5-CONTEXT.md]
**When to use:** For every Phase 5-owned requirement and for every historical implementation phase whose evidence is being restored. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```yaml
# Source pattern: .planning/phases/1-01-SUMMARY.md
requirements-completed: [WRK-01, WRK-02, WRK-03]
```

### Pattern 2: Phase-Level Verification Is the Current Truth Surface
**What:** Keep plan summaries historical and use one phase verification artifact to record fresh commands and current pass/fail results. [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
**When to use:** When multiple plan summaries contribute to one requirement or when summary frontmatter risks overstating completion timing. [VERIFIED: repo grep requirements-completed] [VERIFIED: .planning/phases/4-01-SUMMARY.md] [VERIFIED: .planning/phases/4-03-SUMMARY.md] [VERIFIED: .planning/phases/4-05-SUMMARY.md]
**Example:**
```markdown
## Verification Results
| Requirement | Command | Result | Notes |
|-------------|---------|--------|-------|
| WF-02 | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/telemetry_test.exs` | pass | Fresh run in current repo state |
```

### Pattern 3: Retrospective Normalization With Provenance
**What:** If Phase 5 backfills or normalizes an old artifact, make the normalization explicit instead of pretending it was original contemporaneous authoring. [VERIFIED: .planning/phases/5-CONTEXT.md]
**When to use:** Missing Phase 2 summaries, missing Phase 3 frontmatter, missing verification docs, and stale traceability rows. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
**Example:**
```markdown
## Provenance Note
This frontmatter was added in Phase 5 to restore machine-readable traceability for a summary originally created during Phase 3.
```

### Anti-Patterns to Avoid
- **Retrospective prose-only proof:** Rejected because Phase 5 requires fresh rerunnable commands tied to current results. [VERIFIED: .planning/phases/5-CONTEXT.md]
- **Using current Phase 5 to “fix” deferred runtime defects on paper:** Rejected because `FND-01`, `FND-02`, `ENG-03`, and `LIF-02` are explicitly routed to Phases 6 and 7. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- **Treating any single plan summary as definitive proof:** Risky because Phase 4 summaries currently overlap and can overstate when a requirement became fully complete. [VERIFIED: .planning/phases/4-01-SUMMARY.md] [VERIFIED: .planning/phases/4-02-SUMMARY.md] [VERIFIED: .planning/phases/4-03-SUMMARY.md] [VERIFIED: .planning/phases/4-04-SUMMARY.md] [VERIFIED: .planning/phases/4-05-SUMMARY.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Requirement ownership truth | A new parallel ledger outside existing planning artifacts | `ROADMAP.md` + `REQUIREMENTS.md` + Phase 5 context | Current docs already define scope and ownership; duplicating them creates drift. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/5-CONTEXT.md] |
| Verification proof | Human summary prose only | Fresh `mix test` / `mix compile` commands recorded in `*-VERIFICATION.md` | Phase 5 requires rerunnable evidence with current-state outcomes. [VERIFIED: .planning/phases/5-CONTEXT.md] |
| Phase 2/3 evidence reconstruction | New acceptance criteria | Existing validation docs and existing summary patterns | The repo already contains command maps and metadata patterns; missing pieces are consistency and execution, not invention. [VERIFIED: .planning/phases/0-VALIDATION.md] [VERIFIED: .planning/phases/2-VALIDATION.md] [VERIFIED: .planning/phases/3-VALIDATION.md] [VERIFIED: .planning/phases/1-01-SUMMARY.md] |

**Key insight:** Phase 5 succeeds by making existing truth explicit and rerunnable, not by introducing a new proof system. [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]

## Common Pitfalls

### Pitfall 1: Historically Misleading Completion Markers
**What goes wrong:** A summary frontmatter field claims a requirement was “completed” in a plan that only laid groundwork for later plans. [VERIFIED: .planning/phases/4-01-SUMMARY.md] [VERIFIED: .planning/phases/4-03-SUMMARY.md] [VERIFIED: .planning/phases/4-05-SUMMARY.md]
**Why it happens:** Existing local frontmatter appears to mix “requirement touched by this plan” with “requirement fully closed by this plan.” [VERIFIED: repo grep requirements-completed]
**How to avoid:** Use phase `VERIFICATION.md` as the final closure authority and normalize summary frontmatter only where the current metadata is objectively inconsistent. [VERIFIED: .planning/phases/5-CONTEXT.md]
**Warning signs:** Multiple summaries in one phase each list the same requirement as completed. [VERIFIED: repo grep requirements-completed]

### Pitfall 2: Letting the Audit Override Current Ownership
**What goes wrong:** Phase 5 closes `FND-01`, `FND-02`, `ENG-03`, or `LIF-02` because the audit surfaced them, even though current roadmap ownership moved them to Phases 6 and 7. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
**Why it happens:** The audit is an artifact-gap inventory, but some ownership/status assumptions in it predate later roadmap rewrites. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/REQUIREMENTS.md]
**How to avoid:** Use the current roadmap and current requirements table as ownership authority, and use the audit only as the closure checklist. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
**Warning signs:** A requirement appears under a future phase in `REQUIREMENTS.md` but is about to be marked complete in Phase 5. [VERIFIED: .planning/REQUIREMENTS.md]

### Pitfall 3: Broad Test Runs With No Requirement Mapping
**What goes wrong:** A verification file records only `mix test`, which proves general health but not which requirement it closes. [VERIFIED: .planning/phases/5-CONTEXT.md]
**Why it happens:** Broad green runs are easier to write down than per-requirement command maps. [ASSUMED]
**How to avoid:** Keep one narrow command per requirement, then optionally add `mix test` as a supporting umbrella run. [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: .planning/phases/0-VALIDATION.md] [VERIFIED: .planning/phases/2-VALIDATION.md] [VERIFIED: .planning/phases/3-VALIDATION.md]
**Warning signs:** A verification artifact cannot answer “which command closed `ENG-02`?” immediately. [VERIFIED: .planning/phases/5-CONTEXT.md]

### Pitfall 4: Treating Validation Gaps as Equal to Runtime Defects
**What goes wrong:** Phase 5 planning mixes missing docs with code fixes and loses the clean closure story. [VERIFIED: .planning/phases/5-CONTEXT.md]
**Why it happens:** The milestone audit lists artifact gaps and real integration defects in one file. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
**How to avoid:** Sequence artifact repair first, then stop at clear deferred issue handoff for Phases 6 and 7. [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]
**Warning signs:** Planned edits leave `.planning/` and start changing runtime modules outside evidence artifacts. [VERIFIED: .planning/phases/5-CONTEXT.md]

## Code Examples

Verified local patterns from existing artifacts:

### Summary Frontmatter Pattern
```yaml
# Source pattern: .planning/phases/1-01-SUMMARY.md
phase: 1
plan: 01
requirements-completed: [WRK-01, WRK-02, WRK-03]
completed: 2026-05-19
```

### Validation Command Map Pattern
```markdown
# Source pattern: .planning/phases/2-VALIDATION.md
| ENG-02 | `explain/1` returns structured blocker evidence and the native UI renders explanation-first states safely | integration | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/limiters_live_test.exs` |
```

### Recommended Verification Result Pattern
```markdown
## Verification Results
| Requirement | Command | Result | Evidence Source |
|-------------|---------|--------|-----------------|
| WRK-03 | `mix test test/oban_powertools/idempotency_test.exs` | pass | fresh Phase 5 rerun |
```

## Concrete Verification Evidence Posture

### Requirement -> Fresh Command Map
| Requirement | Fresh command posture |
|-------------|-----------------------|
| FND-03 | `mix test test/oban_powertools/web/router_test.exs` [VERIFIED: .planning/phases/0-VALIDATION.md] |
| WRK-01 | `mix test test/oban_powertools/worker_test.exs` [VERIFIED: .planning/phases/1-01-SUMMARY.md] |
| WRK-02 | `mix test test/oban_powertools/worker_test.exs` [VERIFIED: .planning/phases/1-01-SUMMARY.md] |
| WRK-03 | `mix test test/oban_powertools/idempotency_test.exs` [VERIFIED: .planning/phases/1-01-SUMMARY.md] |
| ENG-01 | `mix test test/oban_powertools/limits_test.exs test/oban_powertools/worker_test.exs` [VERIFIED: .planning/phases/2-VALIDATION.md] |
| ENG-02 | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/limiters_live_test.exs` [VERIFIED: .planning/phases/2-VALIDATION.md] |
| WF-01 | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/workflow_test.exs` [VERIFIED: .planning/phases/3-VALIDATION.md] |
| WF-02 | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/telemetry_test.exs` [VERIFIED: .planning/phases/3-VALIDATION.md] |
| WF-03 | `mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/workflows_live_test.exs` [VERIFIED: .planning/phases/3-VALIDATION.md] |
| LIF-01 | `mix test test/oban_powertools/lifeline_test.exs` [VERIFIED: .planning/phases/4-02-SUMMARY.md] |
| LIF-03 | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` [VERIFIED: .planning/phases/4-03-SUMMARY.md] [VERIFIED: .planning/phases/4-05-SUMMARY.md] |
| LIF-04 | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` [VERIFIED: .planning/phases/4-04-SUMMARY.md] [VERIFIED: .planning/phases/4-05-SUMMARY.md] |

### Required Evidence Shape
- Record the exact command, execution date, result, and requirement ids in each `*-VERIFICATION.md`. [VERIFIED: .planning/phases/5-CONTEXT.md]
- Use narrow commands first and optionally add `mix test` as an umbrella confidence signal. [VERIFIED: .planning/phases/5-CONTEXT.md]
- Record `mix compile --warnings-as-errors` separately if the planner wants a current compile health signal, but do not let compile/format status silently replace requirement-specific proof. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/5-CONTEXT.md]
- Do not claim audit closure until the milestone audit has been regenerated after artifact updates. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/5-CONTEXT.md]

## Risks That Could Make Traceability Historically Misleading

| Risk | Why It Misleads | Mitigation |
|------|------------------|------------|
| Overlapping Phase 4 `requirements-completed` markers | It can imply `LIF-02`, `LIF-03`, or `LIF-04` were fully complete earlier than the surrounding prose supports. [VERIFIED: .planning/phases/4-01-SUMMARY.md] [VERIFIED: .planning/phases/4-03-SUMMARY.md] [VERIFIED: .planning/phases/4-04-SUMMARY.md] [VERIFIED: .planning/phases/4-05-SUMMARY.md] | Make phase verification the final authority and trim only objectively false summary claims if necessary. [VERIFIED: .planning/phases/5-CONTEXT.md] |
| Using the audit’s older status snapshot as current truth | The audit and current `REQUIREMENTS.md` no longer express the same routing for some requirements. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/REQUIREMENTS.md] | Treat `REQUIREMENTS.md` and `ROADMAP.md` as current ownership truth. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] |
| Closing deferred requirements with historical test evidence only | It would blur “implemented before” with “still behaviorally broken today.” [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] | Keep `FND-01`, `FND-02`, `ENG-03`, and `LIF-02` pending for their deferred implementation phases. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] |
| Restoring missing summaries without a provenance note | It can make a Phase 5 backfill look like original contemporaneous evidence. [VERIFIED: .planning/phases/5-CONTEXT.md] | Add an explicit provenance note when backfilling. [VERIFIED: .planning/phases/5-CONTEXT.md] |
| Claiming milestone closure without a documented audit rerun command | It weakens the “fresh rerunnable evidence” standard. [VERIFIED: .planning/phases/5-CONTEXT.md] | Capture the actual local audit regeneration command or manual reproduction step in the final verification artifact. [VERIFIED: repo grep found no local audit command reference] |

## Recommended Sequencing for Closure Work

1. Lock ownership boundaries first: confirm that Phase 5 closes only `FND-03`, `WRK-01..03`, `ENG-01..02`, `WF-01..03`, `LIF-01`, `LIF-03`, and `LIF-04`, while `FND-01`, `FND-02`, `ENG-03`, and `LIF-02` stay deferred. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md]
2. Normalize missing summary evidence next: backfill `2-01` through `2-03` summaries, add Phase 3 frontmatter, and add any objectively missing completion markers in Phase 0. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/0-01-SUMMARY.md] [VERIFIED: .planning/phases/3-01-SUMMARY.md]
3. Build phase-level verification docs after summary normalization so each verification artifact can cite stable summary evidence and targeted commands. [VERIFIED: .planning/phases/5-CONTEXT.md]
4. Sync `REQUIREMENTS.md` after verification docs exist, because status should be derived from evidence rather than guessed in advance. [VERIFIED: .planning/phases/5-CONTEXT.md]
5. Normalize validation artifacts last among docs, because they support audit completeness but do not unblock the strict orphaned-requirement 3-source rule by themselves. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
6. Rerun the milestone audit only after all artifact links are in place; otherwise the result will still reflect transient partial closure. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/5-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Narrative-only summaries or partial plan outputs | Machine-readable summary metadata plus fresh phase verification artifacts | Required by the 2026-05-20 milestone audit and locked by Phase 5 context. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/5-CONTEXT.md] | Closure becomes auditable and rerunnable instead of interpretive. |
| Treating requirement completion as implied by green code/tests | Treating requirement closure as a 3-source artifact chain | Explicit in the current milestone audit. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] | Prevents orphaned requirements even when code confidence is high. |

**Deprecated/outdated:**
- Summary-only closure claims without `VERIFICATION.md` support are now insufficient for this milestone. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Broad green runs are easier to record than requirement-specific commands. [ASSUMED] | Common Pitfalls | Low; this does not change artifact scope, only the explanation of why the pitfall happens. |

## Open Questions (RESOLVED)

1. **What exact repo-local command regenerates the milestone audit?**
   - What we know: Phase 5 must end with a fresh audit rerun, but no repo-local Markdown or shell reference to the generating command was found in this pass. [VERIFIED: .planning/phases/5-CONTEXT.md] [VERIFIED: repo grep found no local audit command reference]
   - Resolution: Treat audit regeneration as an explicit repo-local manual procedure in the plan, not as an implicit hidden command. The execution path should:
     1. rerun the recorded compile and test commands,
     2. read `REQUIREMENTS.md`,
     3. read summary frontmatter via `requirements-completed`,
     4. read `.planning/phases/{0,1,2,3,4}-VERIFICATION.md`,
     5. then rewrite `.planning/v1-v1-MILESTONE-AUDIT.md` from that fresh evidence chain.
   - Decision: Phase 5 planning should name that procedure directly and verify that Phase 5-owned requirements no longer appear as `orphaned` in the audit.

2. **Should Phase 4 summary frontmatter be reduced or only disambiguated by phase verification?**
   - What we know: Several Phase 4 summaries overlap in `requirements-completed`, and at least `4-01-SUMMARY.md` reads broader than its accomplishment text. [VERIFIED: .planning/phases/4-01-SUMMARY.md] [VERIFIED: .planning/phases/4-03-SUMMARY.md] [VERIFIED: .planning/phases/4-04-SUMMARY.md] [VERIFIED: .planning/phases/4-05-SUMMARY.md]
   - Resolution: Prefer minimal normalization. Summary frontmatter may remain overlapping as long as Phase 4 verification becomes the authority for final requirement closure and the milestone audit no longer reports Phase 5-owned requirements as orphaned.
   - Decision: Phase 5 should avoid broad rewrites of Phase 4 summary prose/frontmatter unless the rerun audit proves stricter cleanup is necessary.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | Fresh verification commands | ✓ | 1.19.5 | — |
| `elixir` | Mix test/compile execution | ✓ | 1.19.5 | — |

**Missing dependencies with no fallback:**
- None found in this repo-local research pass. [VERIFIED: `mix --version`] [VERIFIED: `elixir --version`]

**Missing dependencies with fallback:**
- Milestone audit regeneration command is not documented locally; fallback is to treat it as an explicit planning item rather than assuming it. [VERIFIED: repo grep found no local audit command reference]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5 [VERIFIED: `mix --version`] |
| Config file | `test/test_helper.exs` [VERIFIED: .planning/phases/0-VALIDATION.md] [VERIFIED: .planning/phases/2-VALIDATION.md] [VERIFIED: .planning/phases/3-VALIDATION.md] |
| Quick run command | `mix test` [VERIFIED: .planning/phases/0-VALIDATION.md] |
| Full suite command | `mix test --cover` [VERIFIED: .planning/phases/0-VALIDATION.md] [VERIFIED: .planning/phases/2-VALIDATION.md] [VERIFIED: .planning/phases/3-VALIDATION.md] |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FND-03 | Router scope and native shell bridge behavior | unit | `mix test test/oban_powertools/web/router_test.exs` | ✅ [VERIFIED: .planning/phases/0-VALIDATION.md] |
| WRK-01 | Compile-time worker args validation | unit | `mix test test/oban_powertools/worker_test.exs` | ✅ [VERIFIED: .planning/phases/1-01-SUMMARY.md] |
| WRK-02 | Synchronous enqueue validation | unit | `mix test test/oban_powertools/worker_test.exs` | ✅ [VERIFIED: .planning/phases/1-01-SUMMARY.md] |
| WRK-03 | Durable idempotency receipts | integration | `mix test test/oban_powertools/idempotency_test.exs` | ✅ [VERIFIED: .planning/phases/1-01-SUMMARY.md] |
| ENG-01 | Global and partitioned limiters | integration | `mix test test/oban_powertools/limits_test.exs test/oban_powertools/worker_test.exs` | ✅ [VERIFIED: .planning/phases/2-VALIDATION.md] |
| ENG-02 | `explain/1` plus UI explanation-first behavior | integration | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/limiters_live_test.exs` | ✅ [VERIFIED: .planning/phases/2-VALIDATION.md] |
| WF-01 | Workflow insert and normalized persistence | integration | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/workflow_test.exs` | ✅ [VERIFIED: .planning/phases/3-VALIDATION.md] |
| WF-02 | Workflow progression and PubSub acceleration | integration | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/telemetry_test.exs` | ✅ [VERIFIED: .planning/phases/3-VALIDATION.md] |
| WF-03 | Workflow UI blocked-step visibility | LiveView | `mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ✅ [VERIFIED: .planning/phases/3-VALIDATION.md] |
| LIF-01 | Heartbeat refresh and incident projection | integration | `mix test test/oban_powertools/lifeline_test.exs` | ✅ [VERIFIED: .planning/phases/4-02-SUMMARY.md] |
| LIF-03 | Manual repair audit evidence and UI visibility | integration/LiveView | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ [VERIFIED: .planning/phases/4-03-SUMMARY.md] [VERIFIED: .planning/phases/4-05-SUMMARY.md] |
| LIF-04 | Archive-before-delete retention | integration/LiveView | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ [VERIFIED: .planning/phases/4-04-SUMMARY.md] [VERIFIED: .planning/phases/4-05-SUMMARY.md] |

### Sampling Rate
- **Per task commit:** Run the narrowest requirement-specific command first. [VERIFIED: .planning/phases/5-CONTEXT.md]
- **Per wave merge:** Run `mix test` as a supporting signal, not as the only proof source. [VERIFIED: .planning/phases/5-CONTEXT.md]
- **Phase gate:** Targeted requirement commands recorded in `*-VERIFICATION.md`, then rerun the milestone audit. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/5-CONTEXT.md]

### Wave 0 Gaps
- [ ] `0-VERIFICATION.md` through `4-VERIFICATION.md` — missing current-state proof artifacts. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
- [ ] `1-VALIDATION.md` and `4-VALIDATION.md` — missing validation artifacts. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
- [ ] `2-01-SUMMARY.md`, `2-02-SUMMARY.md`, `2-03-SUMMARY.md` — missing summary outputs. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
- [ ] Phase 3 summary frontmatter normalization — missing machine-readable completion markers. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
- [ ] Audit regeneration command capture — no local reference found. [VERIFIED: repo grep found no local audit command reference]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 5 should document but not repair auth defects; `FND-02` stays in Phase 6. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| V3 Session Management | no | No session-behavior changes are in scope; this is artifact closure only. [VERIFIED: .planning/phases/5-CONTEXT.md] |
| V4 Access Control | yes | Preserve deferred ownership for preview authorization defects instead of papering them over in traceability docs. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |
| V5 Input Validation | yes | Verification artifacts should use explicit requirement ids and explicit command strings to avoid ambiguous proof mapping. [VERIFIED: .planning/phases/5-CONTEXT.md] |
| V6 Cryptography | no | No cryptographic implementation work is part of this phase. [VERIFIED: .planning/phases/5-CONTEXT.md] |

### Known Threat Patterns for this phase
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False completion claim | Repudiation | Require fresh command evidence in `VERIFICATION.md` before marking a requirement complete. [VERIFIED: .planning/phases/5-CONTEXT.md] |
| Ownership drift across phases | Tampering | Preserve implementation ownership in `REQUIREMENTS.md` and add closure proof separately. [VERIFIED: .planning/phases/5-CONTEXT.md] |
| Deferred defect hidden by documentation | Information disclosure | Keep Phase 6/7 requirements pending even when older implementation evidence exists. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/ROADMAP.md` - Phase 5 scope, success criteria, and deferred Phase 6/7 boundaries.
- `.planning/REQUIREMENTS.md` - current requirement routing and pending statuses.
- `.planning/v1-v1-MILESTONE-AUDIT.md` - authoritative gap inventory, 3-source rule, and integration defects.
- `.planning/phases/5-CONTEXT.md` - locked decisions for artifact-first, evidence-first closure.
- `.planning/phases/0-01-SUMMARY.md`, `.planning/phases/1-01-SUMMARY.md`, `.planning/phases/2-04-SUMMARY.md`, `.planning/phases/2-05-SUMMARY.md`, `.planning/phases/3-01-SUMMARY.md`, `.planning/phases/4-01-SUMMARY.md`, `.planning/phases/4-02-SUMMARY.md`, `.planning/phases/4-03-SUMMARY.md`, `.planning/phases/4-04-SUMMARY.md`, `.planning/phases/4-05-SUMMARY.md` - local artifact pattern and inconsistency checks.
- `.planning/phases/0-VALIDATION.md`, `.planning/phases/2-VALIDATION.md`, `.planning/phases/3-VALIDATION.md` - existing requirement-to-command mappings.
- `mix --version`, `elixir --version` - environment availability.
- `rg -n "requirements-completed:" .planning/phases/*-SUMMARY.md` - summary frontmatter presence and overlap.

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new tooling decisions are needed; the stack is existing repo artifacts plus verified local Mix/ExUnit tooling. [VERIFIED: `mix --version`] [VERIFIED: .planning/phases/5-CONTEXT.md]
- Architecture: HIGH - Phase 5 boundaries and the 3-source closure model are explicit in roadmap, requirements, audit, and context docs. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/5-CONTEXT.md]
- Pitfalls: HIGH - the main pitfalls are directly observable in the current artifact set, especially missing verification docs, missing Phase 2 summaries, missing Phase 3 frontmatter, and overlapping Phase 4 completion markers. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: repo grep requirements-completed]

**Research date:** 2026-05-20 [VERIFIED: current session date]
**Valid until:** 2026-06-19 for artifact scope and routing, unless roadmap/requirements ownership changes again. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
