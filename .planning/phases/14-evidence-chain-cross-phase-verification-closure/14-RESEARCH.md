# Phase 14: Evidence Chain & Cross-Phase Verification Closure - Research

**Researched:** 2026-05-23
**Domain:** Retrospective evidence-chain repair for host-contract requirements across Phases 8-10
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Shift recommendations left by default for this project and within GSD. Downstream agents should treat the recommendations here as locked defaults unless a later choice would materially change public support truth, provenance, or maintainer burden.
- **D-02:** Optimize for least surprise, durable provenance, support-truth honesty, and audit-closeable evidence over aesthetic normalization or cleaner retroactive storytelling.

### Retrospective Repair Posture
- **D-03:** Use conservative, audit-targeted additive repair as the default posture for Phase 14.
- **D-04:** Only repair artifacts explicitly needed to restore `requirements -> verification -> summary` closure for Phases 8-10.
- **D-05:** Do not turn Phase 14 into a broad historical artifact normalization or schema-migration phase.
- **D-06:** Allow narrow normalization only when it is the minimum change required for the audited phase to become machine- and human-closeable.

### Verification Shape
- **D-07:** Canonical proof should live with the original requirement-owning phases, not be silently reassigned to Phase 14.
- **D-08:** Retrofit missing phase-local verification closure for Phases 8, 9, and 10:
  Phase 8 keeps its phase verification as canonical and only repairs missing summary/closure metadata;
  Phase 9 must gain a true phase-level requirements coverage artifact rather than relying on the narrow existing plan-03 verification shape;
  Phase 10 must gain a real `10-VERIFICATION.md` because validation and summaries are not sufficient closure.
- **D-09:** Phase 14 should produce a cross-phase closure/index artifact that explains what was repaired, points to the canonical phase-local proof, and confirms that requirement ownership was not reassigned.
- **D-10:** Phase 14 is an auditor's closure memo and index, not the primary proof store for `POL-01`, `POL-02`, `POL-03`, or `HST-02`.

### Summary Truth Posture
- **D-11:** Preserve historical summaries as execution-history artifacts by default.
- **D-12:** Do not silently rewrite older summaries to make them read as if today's proof posture existed at original plan-close time.
- **D-13:** When a historical summary needs repair, prefer explicit correction metadata and a visible historical note over narrative replacement.
- **D-14:** If an old summary contains materially misleading present-tense closure language, amend it only with an explicit correction posture that preserves the fact of later audit-based reevaluation.
- **D-15:** Summary files touched by Phase 14 should distinguish:
  what the plan concluded at completion time,
  what later audit evidence narrowed or downgraded,
  and which newer artifact now governs present-tense closure truth.

### Proof Strictness
- **D-16:** Re-run targeted proof commands and anchor repaired closure claims to fresh dated results.
- **D-17:** Documentary-only closure is not credible as the primary strategy for this phase because the milestone audit already proved that older green artifacts could coexist with broken end-to-end support truth.
- **D-18:** Use targeted proof strictness, not minimal, broad, or full-suite by default.
- **D-19:** Targeted reruns should mirror the exact commands and proof lanes that map to the repaired closure claim and any immediately adjacent host-contract seam.
- **D-20:** Grep/doc checks may supplement executable proof for wording or support-truth alignment, but must not replace executable proof where the requirement is operational.

### Scope Guardrails
- **D-21:** Do not reopen runtime design decisions from Phases 8-10 unless fresh proof reveals an actual product or contract mismatch.
- **D-22:** Do not use Phase 14 to broaden the public bridge contract, add new host capabilities, or redesign operator UX beyond what is needed to close the evidence chain honestly.
- **D-23:** Treat validation docs as setup/strategy artifacts, not substitutes for verification closure.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `POL-01` | Host auth, actor attribution, and bounded bridge policy seams must be phase-closeable through exact requirement ownership and fresh proof. [VERIFIED: .planning/REQUIREMENTS.md; .planning/milestones/v1.1-MILESTONE-AUDIT.md] | Replace the current plan-scoped `9-VERIFICATION.md` with a phase-level verification report that maps `POL-01` to fresh runs of `test/oban_powertools/auth_test.exs`, `test/oban_powertools/web/live/cron_live_test.exs`, `test/oban_powertools/web/live/lifeline_live_test.exs`, and bridge/router proof as supporting evidence. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md; test/oban_powertools/auth_test.exs; test/oban_powertools/web/live/cron_live_test.exs; test/oban_powertools/web/live/lifeline_live_test.exs] |
| `POL-02` | Shared display-policy, read-only framing, and workflow/audit support truth must be phase-closeable through exact requirement ownership and fresh proof. [VERIFIED: .planning/REQUIREMENTS.md; .planning/milestones/v1.1-MILESTONE-AUDIT.md] | The same Phase 9 verification retrofit should close `POL-02` by REQ-ID using fresh runs of `test/oban_powertools/web/live/audit_live_test.exs`, `test/oban_powertools/web/live/workflows_live_test.exs`, and adjacent route proof where the bridge inherits display-policy and read-only seams. [VERIFIED: test/oban_powertools/web/live/audit_live_test.exs; test/oban_powertools/web/live/workflows_live_test.exs; test/oban_powertools/web/router_test.exs] |
| `POL-03` | The public telemetry contract already verified in Phase 8 must become fully traceable across verification and summary closure metadata. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/8-host-contract-install-surface/8-VERIFICATION.md] | Keep `8-VERIFICATION.md` as canonical proof and narrowly repair only summary metadata on `8-03-SUMMARY.md`, adding explicit closure hooks without reasserting `PKG-01`. [VERIFIED: .planning/phases/8-host-contract-install-surface/8-03-SUMMARY.md; .planning/phases/8-host-contract-install-surface/8-02-SUMMARY.md; .planning/milestones/v1.1-MILESTONE-AUDIT.md] |
| `HST-02` | Shared preview, read-only, audit, and optional-bridge support truth across the operator shell must gain a real phase-level verification artifact. [VERIFIED: .planning/REQUIREMENTS.md; .planning/milestones/v1.1-MILESTONE-AUDIT.md] | Create `10-VERIFICATION.md` modeled on the Phase 8 and Phase 12 verification reports, using fresh targeted reruns of router plus the Phase 10 LiveView proof surfaces already named in `14-CONTEXT.md`. [VERIFIED: .planning/phases/10-operator-ux-coherence-mutation-safety/10-01-SUMMARY.md; .planning/phases/10-operator-ux-coherence-mutation-safety/10-02-SUMMARY.md; .planning/phases/10-operator-ux-coherence-mutation-safety/10-03-SUMMARY.md; test/oban_powertools/web/router_test.exs; test/oban_powertools/web/live/cron_live_test.exs; test/oban_powertools/web/live/lifeline_live_test.exs; test/oban_powertools/web/live/audit_live_test.exs; test/oban_powertools/web/live/workflows_live_test.exs] |
</phase_requirements>

## Summary

Phase 14 is a proof-closure phase, not an implementation phase. The code and tests for the reopened host-contract seams already exist and are already the right proof surfaces; what is broken is the evidence chain between requirement ownership, phase-level verification, and summary closure metadata. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md; .planning/milestones/v1.1-MILESTONE-AUDIT.md]

The audit findings point to three distinct repair classes. First, Phase 8 has canonical verification for `POL-03`, but its summary metadata does not carry `requirements-completed`, so the closure chain is only two-thirds complete. [VERIFIED: .planning/phases/8-host-contract-install-surface/8-VERIFICATION.md; .planning/phases/8-host-contract-install-surface/8-03-SUMMARY.md; .planning/milestones/v1.1-MILESTONE-AUDIT.md] Second, Phase 9 has execution summaries and a narrow plan-scoped verification file, but no phase-level report that closes `POL-01` and `POL-02` by REQ-ID, and two of the three summaries are still missing normalized frontmatter. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-01-SUMMARY.md; .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-02-SUMMARY.md; .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-03-SUMMARY.md; .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md; .planning/milestones/v1.1-MILESTONE-AUDIT.md] Third, Phase 10 has the right summary evidence but no `10-VERIFICATION.md` at all, so `HST-02` is assigned yet unverified. [VERIFIED: .planning/phases/10-operator-ux-coherence-mutation-safety/10-01-SUMMARY.md; .planning/phases/10-operator-ux-coherence-mutation-safety/10-02-SUMMARY.md; .planning/phases/10-operator-ux-coherence-mutation-safety/10-03-SUMMARY.md; .planning/milestones/v1.1-MILESTONE-AUDIT.md]

The minimal credible plan therefore has three slices. Slice 1 repairs the summary side of Phase 8 and Phase 9 while preserving execution history and adding explicit retrospective notes where later audit evidence narrowed older closure claims. Slice 2 rebuilds the verification layer for Phases 9 and 10 using fresh, targeted reruns against the existing auth, router, and native LiveView proof surfaces. Slice 3 adds a Phase 14 closure memo that indexes the repaired chain, explains what changed, and points future auditors back to the canonical phase-local proof files instead of reassigning ownership. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md; .planning/phases/8-host-contract-install-surface/8-VERIFICATION.md; test/oban_powertools/auth_test.exs; test/oban_powertools/web/router_test.exs; test/oban_powertools/web/live/cron_live_test.exs; test/oban_powertools/web/live/lifeline_live_test.exs; test/oban_powertools/web/live/audit_live_test.exs; test/oban_powertools/web/live/workflows_live_test.exs]

**Primary recommendation:** Plan Phase 14 as three execute plans:
1. summary normalization and historical correction notes for `8-03`, `9-01`, `9-02`, and `9-03`;
2. phase-level verification retrofits for Phases 9 and 10 with fresh dated proof results;
3. a new `14-VERIFICATION.md` closure/index artifact that ties the milestone audit back to the repaired phase-local chain. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-PATTERNS.md; .planning/milestones/v1.1-MILESTONE-AUDIT.md]

## Project Constraints

- No runtime feature expansion is allowed in this phase unless targeted reruns expose a real mismatch. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md]
- `8-VERIFICATION.md` is already the local gold standard for phase-level requirements coverage and should be reused as the primary structural model for Phase 9 and Phase 10 closure. [VERIFIED: .planning/phases/8-host-contract-install-surface/8-VERIFICATION.md]
- `9-01-SUMMARY.md` and `9-02-SUMMARY.md` currently have no YAML frontmatter, so downstream closure automation cannot consume them. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-01-SUMMARY.md; .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-02-SUMMARY.md]
- `9-03-SUMMARY.md` already has normalized frontmatter but still reflects a then-current `PKG-03` closure understanding that the audit later invalidated, so it needs an explicit correction posture rather than a silent rewrite. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-03-SUMMARY.md; .planning/milestones/v1.1-MILESTONE-AUDIT.md]
- `10-VALIDATION.md` is strategy evidence, not closure evidence, and must not be treated as a substitute for `10-VERIFICATION.md`. [VERIFIED: .planning/phases/10-operator-ux-coherence-mutation-safety/10-VALIDATION.md; .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Normalize historical summary metadata without falsifying execution history | Docs / planning artifacts | — | The work is additive metadata and correction-note repair in existing summary files, not product behavior changes. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-01-SUMMARY.md; .planning/phases/0-01-SUMMARY.md] |
| Close `POL-01` with fresh auth and mutation-boundary proof | Native operator shell tests | Bridge/router proof | `POL-01` maps primarily to auth behavior, actor attribution, and native mutation gates, with the optional bridge as supporting policy continuity rather than the main proof store. [VERIFIED: test/oban_powertools/auth_test.exs; test/oban_powertools/web/live/cron_live_test.exs; test/oban_powertools/web/live/lifeline_live_test.exs; test/oban_powertools/web/router_test.exs] |
| Close `POL-02` with fresh display-policy and read-only proof | Native operator shell tests | Bridge/router proof | The display-policy seam is exercised directly in audit and workflow LiveViews, while the router proof shows the shared read-only annex stays bounded. [VERIFIED: test/oban_powertools/web/live/audit_live_test.exs; test/oban_powertools/web/live/workflows_live_test.exs; test/oban_powertools/web/router_test.exs] |
| Close `HST-02` with fresh phase-level verification | Native operator shell tests | Bridge/router proof and docs guardrails | `HST-02` spans shared preview, vocabulary, read-only posture, and bridge truth, so it needs one consolidated verification report over all Phase 10 proof surfaces. [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs; test/oban_powertools/web/live/lifeline_live_test.exs; test/oban_powertools/web/live/audit_live_test.exs; test/oban_powertools/web/live/workflows_live_test.exs; test/oban_powertools/web/router_test.exs; test/oban_powertools/docs_contract_test.exs] |
| Publish the final cross-phase closure map | Planning / audit artifacts | — | Phase 14 owns the index and correction memo, not the canonical per-requirement proof. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md] |

## Recommended Proof Set

### Phase 8 closure refresh
- `rg -n "requirements-completed|POL-03|PKG-01" .planning/phases/8-host-contract-install-surface/8-03-SUMMARY.md`
- Reuse dated evidence references already present in `.planning/phases/8-host-contract-install-surface/8-VERIFICATION.md`

### Phase 9 targeted reruns
- `mix test test/oban_powertools/auth_test.exs`
- `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs`
- `mix test test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs`
- `mix test test/oban_powertools/web/router_test.exs`

### Phase 10 targeted reruns
- `mix test test/oban_powertools/web/live/cron_live_test.exs`
- `mix test test/oban_powertools/web/live/lifeline_live_test.exs`
- `mix test test/oban_powertools/web/live/audit_live_test.exs`
- `mix test test/oban_powertools/web/live/workflows_live_test.exs`
- `mix test test/oban_powertools/web/router_test.exs`
- `mix test test/oban_powertools/docs_contract_test.exs`

These commands are intentionally overlapping because the reopened requirements share seams. The phase should prefer grouped reruns where that keeps provenance clear, but the verification report must still map each requirement to the exact command sets that support it. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md]

## Architecture Patterns

### Pattern 1: Retrospective metadata normalization without body rewrite
**What:** Add modern YAML frontmatter and explicit `requirements-completed` keys to old summary files while preserving the existing execution body. [VERIFIED: .planning/phases/10-operator-ux-coherence-mutation-safety/10-03-SUMMARY.md; .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-01-SUMMARY.md]
**When to use:** Use for `9-01-SUMMARY.md` and `9-02-SUMMARY.md`, and for `8-03-SUMMARY.md` if the missing closure metadata can be added without changing the body narrative. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-PATTERNS.md]
**Anti-pattern:** Do not rewrite the accomplishment sections as if the repaired evidence chain existed at original plan-close time. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md]

### Pattern 2: Explicit retrospective correction note for reopened requirement claims
**What:** Preserve the historical execution record, then append a clearly dated note stating that later audit evidence narrowed or reassigned present-tense closure. [VERIFIED: .planning/phases/0-01-SUMMARY.md; .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-03-SUMMARY.md]
**When to use:** Use for `9-03-SUMMARY.md`, where the original summary reflected `PKG-03` closure that the 2026-05-22 audit later reopened and Phase 13 ultimately repaired. [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]
**Anti-pattern:** Do not silently delete `PKG-03` from the historical body or let Phase 14 imply that Phase 9 still owns present-tense `PKG-03` closure. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-PATTERNS.md]

### Pattern 3: Phase-level verification report with requirements coverage
**What:** Use the `8-VERIFICATION.md` and `12-VERIFICATION.md` structure: proof commands, behavioral spot-checks, requirement coverage table, and fresh dated results. [VERIFIED: .planning/phases/8-host-contract-install-surface/8-VERIFICATION.md; .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-VERIFICATION.md]
**When to use:** Replace `9-VERIFICATION.md` and create `10-VERIFICATION.md`. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-PATTERNS.md]
**Anti-pattern:** Do not leave `9-VERIFICATION.md` as a plan-scoped report with `plan: 03` frontmatter or stop at a list of proof commands without REQ-ID closure. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md]

### Pattern 4: Cross-phase closure memo as an index, not as proof ownership
**What:** Create `14-VERIFICATION.md` as a maintainer-facing closure map that points to repaired canonical proof in Phases 8-10 and explains what Phase 14 changed. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md]
**When to use:** Use after the phase-local repairs land and fresh reruns have produced dated results. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md]
**Anti-pattern:** Do not write `14-VERIFICATION.md` as though Phase 14 itself proves `POL-01`, `POL-02`, `POL-03`, or `HST-02`; it should index those requirements back to Phase 8, 9, and 10 artifacts. [VERIFIED: .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md]

## Plan Shape Recommendation

### Plan 14-01: Normalize historical summary closure artifacts
- Touch `8-03-SUMMARY.md`, `9-01-SUMMARY.md`, `9-02-SUMMARY.md`, and `9-03-SUMMARY.md`
- Add only the metadata and correction blocks needed for machine- and human-closeable closure
- Verify with `rg` against exact frontmatter keys and correction-note markers

### Plan 14-02: Retrofit phase-local verification for Phases 9 and 10
- Rewrite `9-VERIFICATION.md` into a phase-level REQ-ID report
- Create `10-VERIFICATION.md` from the existing proof surfaces
- Run the targeted proof commands and capture fresh dated results

### Plan 14-03: Publish the Phase 14 closure/index artifact
- Create `14-VERIFICATION.md` or an equivalent closure memo in the Phase 14 directory
- Map each repaired requirement to its owning phase verification and summary files
- Explain retrospective corrections, proof dates, and the non-reassignment of requirement ownership

## Risks and Guardrails

- The main risk is over-normalization: a planner may try to “clean up” old summaries broadly instead of doing the narrow repair the context demands.
- The second risk is proof duplication: if `14-VERIFICATION.md` becomes the canonical proof store, future audits will lose the original phase ownership chain.
- The third risk is stale evidence: if verification files are rewritten without fresh dated reruns, the repaired chain will still be documentary rather than executable.

**Planner guardrail:** every task should answer one of these questions explicitly:
1. Does this change restore a missing summary closure hook?
2. Does this change restore a missing phase-level verification mapping?
3. Does this change create the final cross-phase map without reassigning ownership?

Anything outside those three questions is probably Phase 14 scope creep.

## RESEARCH COMPLETE
