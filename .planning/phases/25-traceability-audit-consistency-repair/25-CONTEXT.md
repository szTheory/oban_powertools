# Phase 25: Traceability & Audit Consistency Repair - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Align the v1.2 requirement traceability table, milestone audit bookkeeping, and top-level planning story with the verification chain that now exists after Phase 24.

This phase repairs canonical planning and audit artifacts for already-shipped workflow-semantics work. It does not add or change workflow runtime behavior, does not reassign implementation ownership to the repair phase, and does not perform broad historical wording cleanup across old summaries.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<specifics>
## Specific Ideas

- Preferred traceability shape:
  “owner phase stays historical; proof pointer shows which verification artifact closes it now.”
- Preferred audit shape:
  “failed audit remains as historical evidence; rerun audit becomes current canonical milestone verdict.”
- Preferred top-level doc posture:
  “remove contradictory volatile status text from top-level entrypoints instead of making every file restate milestone progress.”
- Preferred summary posture:
  “execution history is preserved; only objectively misleading files get a standardized retrospective correction note.”
- Preferred maintainer DX:
  a future agent should be able to answer “which file closes this requirement today?” and “what was the failed audit versus the repaired audit?” without spelunking git history.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Current Contradictions
- `.planning/ROADMAP.md` — Phase 25 scope and the explicit requirement to align roadmap, requirements, and milestone audit present-tense truth.
- `.planning/PROJECT.md` — top-level product posture plus the current stale v1.2 status wording that should be role-clarified rather than broadly rewritten.
- `.planning/REQUIREMENTS.md` — current v1.2 requirement table, proof posture gate, and the stale traceability rows that still point reopened requirements at Phase 24.
- `.planning/STATE.md` — current session-continuity artifact and the stale “Phase 24 executing” wording that no longer matches the project’s present position.
- `.planning/v1.2-MILESTONE-AUDIT.md` — the 2026-05-25 failed snapshot that Phase 25 must preserve while superseding with a rerun.

### Upstream Repair Context And Canonical Proof
- `.planning/phases/24-verification-artifact-backfill/24-CONTEXT.md` — locked backfill rules: fresh reruns, additive repair, phase-local verification as canonical closure.
- `.planning/phases/24-verification-artifact-backfill/24-RESEARCH.md` — requirement closure map and proof-topology split that created the current repaired chain.
- `.planning/phases/17-db-first-transition-engine-command-pipeline/17-VERIFICATION.md` — canonical closure for `WFS-02` with adjacent support for `REC-03` and `VER-01`.
- `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md` — canonical closure for `SIG-01`, `SIG-02`, `SIG-03`, and the await/signal/expiry slice of `VER-01`.
- `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-VERIFICATION.md` — canonical closure for `REC-03` and supporting race-path proof posture.
- `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-VERIFICATION.md` — canonical closure for `DIA-01`.
- `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-VERIFICATION.md` — canonical closure for `DIA-02` and bounded workflow/Lifeline action parity.
- `.planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-VERIFICATION.md` — canonical closure for `VER-01` and milestone-level proof topology.

### Prior Evidence-Repair Precedent
- `.planning/phases/5-CONTEXT.md` — original implementation ownership must stay put while repair phases restore proof and traceability.
- `.planning/phases/5-PATTERNS.md` — anti-pattern guardrail against repo-wide wording cleanup and precedent for explicit retrospective normalization.
- `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md` — additive repair, canonical phase-local proof, and summary-history preservation posture.
- `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-VERIFICATION.md` — closure-index pattern showing how a repair phase can point at canonical proof without re-owning it.
- `.planning/phases/0-01-SUMMARY.md` — local precedent for a standardized retrospective traceability note in a summary.

### Audit And Supersession Precedent
- `.planning/milestones/v1.1-MILESTONE-AUDIT.md` — local example of a clean passed audit artifact after prior evidence-chain repair work.
- `.planning/milestones/v1.2-ROADMAP.md` — shipped v1.2 scope, used as the historical milestone baseline beneath the current gap-closure phases.

### Product Posture And DX Guidance
- `prompts/oban_powertools_context.md` — host-owned, explicit, audit-friendly product posture and maintainer/operator personas.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — least-surprise operator-surface and support-truth posture relevant to planning artifact clarity.
- `prompts/oban-powertools-deep-research-original-prompt.md` — shift-left DX posture, ecosystem lessons, and “ultimate lib” framing that should inform maintainer-facing artifact quality.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The six new phase-local verification files from Phases 17 and 19-23 already provide the canonical closure targets Phase 25 must point at; this phase should not invent a second proof store.
- `.planning/v1.2-MILESTONE-AUDIT.md` already captures the exact failed-state inventory that must remain historically visible.
- `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-VERIFICATION.md` provides the closest local pattern for a repair-phase artifact that indexes canonical proof without taking ownership.
- `.planning/phases/0-01-SUMMARY.md` provides the strongest local example of a retrospective note that preserves historical honesty rather than silently rewriting history.

### Established Patterns
- This repo treats phase-local `VERIFICATION.md` files as the canonical present-tense closure layer once they exist.
- Summary frontmatter and body are execution-history evidence, not the primary proof store.
- Support truth in this repo is explicit, semver-sensitive, and intolerant of contradictory top-level claims.
- Earlier repair phases favored additive chronology and narrow normalization over broad archive cleanup.

### Integration Points
- Phase 25 should connect `REQUIREMENTS.md` directly to the repaired Phase 17/19/20/21/22/23 verification files.
- Phase 25 should define the current canonical milestone audit posture clearly enough that future milestone closeout tools do not need to guess whether the failed or rerun audit is authoritative.
- Phase 25 should make `PROJECT.md` and `STATE.md` safer entrypoints for future AI agents by removing or narrowing stale volatile state claims and pointing them to the correct live files.

</code_context>

<deferred>
## Deferred Ideas

- Repo-wide summary/frontmatter modernization beyond files that are objectively misleading after the repaired traceability chain lands.
- Any new runtime, UI, telemetry, or support-truth semantics not already implemented in Phases 17-23.
- Historical closeout cleanup unrelated to v1.2 traceability and audit bookkeeping; that belongs in Phase 26.

</deferred>

---

*Phase: 25-traceability-audit-consistency-repair*
*Context gathered: 2026-05-25*
