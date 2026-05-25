# Phase 26: Historical Closeout Hygiene - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Remove the remaining stale historical closeout signal that still blocks milestone archiving even though the underlying Phase 12 human closeout passed on 2026-05-23.

This phase is repo hygiene and closeout-contract repair for already-shipped work. It does not reopen Phase 12 product behavior, does not broaden into repo-wide historical normalization, and does not turn into a general redesign of GSD verification semantics.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Shift recommendations left for this phase and downstream GSD work. Treat the defaults below as locked unless a later choice would materially change historical honesty, support truth, or maintainer burden.
- **D-02:** Optimize for least surprise, one canonical source of truth, future AI-maintainer clarity, and additive chronology over byte-for-byte preservation of malformed historical metadata.

### Resolution Shape For The Phase 12 UAT Artifact
- **D-03:** The primary fix should normalize the repo-owned `12-UAT.md` artifact to the current canonical UAT schema rather than leaving the stale shape in place and teaching future readers/tooling to special-case it forever.
- **D-04:** Normalization must preserve the underlying historical verdict and timing. The closeout remains a successful human review completed on 2026-05-23; Phase 26 is only repairing stale schema/metadata shape, not changing outcome.
- **D-05:** Normalize the whole stale success shape, not just one frontmatter field. At minimum, bring `status`, `Current Test`, and success result tokens into the current UAT contract so `audit-open`, checkpoint rendering, and human readers all agree.
- **D-06:** Add one short explicit retrospective note in the UAT artifact stating that Phase 26 performed schema normalization for archival hygiene and that the original closeout verdict/date remain unchanged.
- **D-07:** Do not create a second sidecar closeout ledger or alternate metadata file just to explain that `12-UAT.md` passed. The UAT artifact itself should become canonical again.

### Cleanup Breadth
- **D-08:** Use targeted related cleanup, not minimum-only and not broad historical normalization.
- **D-09:** Fix the direct archival blocker plus the small ring of adjacent stale metadata/references that would still mislead a maintainer after the artifact is normalized.
- **D-10:** Keep the cleanup boundary objective and narrow: only touch files that still imply the Phase 12 closeout is unresolved or that still cause milestone-close tooling to treat the artifact as open.
- **D-11:** Do not rewrite old summaries, audits, or planning bodies for cosmetic consistency. If any adjacent artifact needs clarification, prefer a small grep-able retrospective note or a tight metadata update over narrative replacement.
- **D-12:** If the rerun/current audit artifacts already describe the Phase 12 item as archival hygiene rather than an implementation gap, preserve that chronology and only tighten wording where it still creates a real reader trap.

### Tooling Scope
- **D-13:** The repo-local artifact normalization is the primary responsibility of Phase 26. Do not rely on mutable machine-local tooling state as the only fix.
- **D-14:** A narrowly scoped GSD tooling patch is acceptable only as a secondary hardening step if it stays tightly limited to legacy closed UAT aliases and does not relax genuinely open states.
- **D-15:** Any tooling compatibility must be explicit and diagnostic rather than magical. If GSD accepts legacy successful UAT shapes, it should do so narrowly and without masking `testing`, `partial`, `diagnosed`, `blocked`, deferred-human, or pending-scenario states.
- **D-16:** Do not broaden this phase into a formal migration framework or a large cross-repo compatibility project. If future repos need wider legacy-UAT support, that can become separate GSD work after this repo is clean.

### Ecosystem / DX Posture
- **D-17:** Follow the same idiomatic posture used by Phoenix/Oban/Ecto upgrades: converge repo-owned artifacts onto one canonical shape, keep compatibility narrow, and make stale state explicit instead of silently tolerated.
- **D-18:** Preserve support truth the same way earlier repair phases did:
  one canonical source per truth type,
  additive chronology instead of hidden rewrites,
  and no permanent dual-format ambiguity for maintainer-facing artifacts the repo fully owns.
- **D-19:** Future maintainers and AI agents should be able to inspect one UAT artifact and one milestone audit chain and immediately understand that Phase 12 is closed, why the stale signal existed, and why Phase 26 touched it.

### the agent's Discretion
- Exact wording of the retrospective normalization note, provided it clearly distinguishes schema repair from verdict change.
- Exact list of adjacent files to touch, provided each one has a concrete archival-hygiene reason and the phase does not drift into broad history cleanup.
- Whether to include a tiny GSD compatibility patch, provided the repo artifact is still normalized first and the tooling change stays legacy-closed-only.

</decisions>

<specifics>
## Specific Ideas

- Preferred Phase 26 outcome:
  `12-UAT.md` becomes canonical under today’s UAT contract,
  milestone-close tooling stops flagging it as open,
  and future readers no longer have to reverse-engineer whether `passed` meant “closed enough.”
- Preferred cleanup posture:
  “fix the artifact at the source, then remove only the nearby stale traps that still contradict it.”
- Preferred tooling posture:
  repo truth first, optional narrow GSD hardening second.
- Preferred support-truth posture:
  “historical success preserved; stale schema normalized explicitly.”
- Preferred carry-forward GSD rule:
  when the repo fully owns an old metadata artifact, normalize it in place before inventing permanent compatibility layers.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Current Milestone Truth
- `.planning/ROADMAP.md` — Phase 26 scope and the explicit requirement to resolve the lingering Phase 12 UAT closeout signal.
- `.planning/PROJECT.md` — top-level product/support-truth posture and the repo’s explicit preference for inspectable, least-surprise behavior.
- `.planning/REQUIREMENTS.md` — current milestone requirement closure state and evidence posture.
- `.planning/STATE.md` — current session continuity, phase focus, and canonical next-step context.
- `.planning/v1.2-MILESTONE-AUDIT.md` — failed 2026-05-25 audit snapshot that still records the Phase 12 UAT closeout item as open archival hygiene.
- `.planning/milestones/v1.2-rerun-MILESTONE-AUDIT.md` — current canonical milestone verdict showing the Phase 12 item as archival hygiene rather than a blocking implementation gap.
- `.planning/milestones/v1.1-MILESTONE-AUDIT.md` — canonical proof that the Phase 12 human closeout passed on 2026-05-23 and remained a closeout-only concern rather than an implementation gap.

### Primary Historical Artifact
- `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-UAT.md` — stale UAT artifact whose legacy success schema is still being treated as open by archival tooling.
- `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-VERIFICATION.md` — canonical Phase 12 verification report, including the human verification items that the UAT artifact closes out.

### Prior Repair-Phase Guardrails
- `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md` — additive repair, historical-summary preservation, and no-broad-normalization precedent.
- `.planning/phases/24-verification-artifact-backfill/24-CONTEXT.md` — fresh-proof and canonical-artifact posture for evidence repair.
- `.planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md` — locked rules for preserving chronology, keeping one canonical source per truth type, and using only narrow retrospective corrections.

### Tooling Contract References
- `/Users/jon/.codex/get-shit-done/templates/UAT.md` — current canonical UAT schema and success-state shape.
- `/Users/jon/.codex/get-shit-done/workflows/verify-work.md` — workflow expectations for how completed UAT artifacts should look.
- `/Users/jon/.codex/get-shit-done/workflows/complete-milestone.md` — artifact-audit behavior at milestone close.
- `/Users/jon/.codex/get-shit-done/bin/lib/audit.cjs` — current `audit-open` logic that treats any UAT status other than `complete` as open.
- `/Users/jon/.codex/get-shit-done/bin/lib/uat.cjs` — current UAT parsing/checkpoint behavior that expects canonical current-test and result tokens.

### Product / DX Guidance
- `prompts/oban_powertools_context.md` — host-owned, explicit, support-truth-first product posture for maintainer/operator tooling.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — least-surprise operator-surface guidance and shared policy posture.
- `prompts/oban-powertools-deep-research-original-prompt.md` — “ultimate library” DX, ergonomics, and ecosystem-lessons posture to preserve even in planning hygiene work.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `12-VERIFICATION.md` already contains the canonical human-review truth; the UAT artifact only needs schema/closeout normalization, not a new verdict.
- `v1.1-MILESTONE-AUDIT.md` already proves the Phase 12 editorial closeout passed on 2026-05-23.
- `v1.2-rerun-MILESTONE-AUDIT.md` already narrows the remaining issue correctly to archival hygiene rather than reopened implementation uncertainty.
- The current UAT template and workflow docs provide an explicit target shape for normalization; no new schema needs to be invented.

### Established Patterns
- This repo prefers additive chronology, explicit supersession, and narrow retrospective notes over hidden historical rewrites.
- Repo-owned planning artifacts are expected to be canonical and machine-readable under the current workflow contracts once a repair phase touches them.
- Support truth in this repo is strict: stale or contradictory metadata should be made explicit or repaired, not silently tolerated.
- Prior repair phases repeatedly chose “preserve ownership, repair the artifact chain” instead of creating alternate closure ledgers.

### Integration Points
- Phase 26 must connect the stale Phase 12 UAT artifact to the current UAT template/workflow contract so `audit-open` and milestone close interpret it correctly.
- Any adjacent audit/state wording touched by Phase 26 should align the archival story across the failed v1.2 snapshot, the rerun audit, and current phase state without collapsing chronology.
- If a tiny GSD patch is included, it should integrate with the existing UAT/audit parsers narrowly enough that future repos gain better legacy-closed handling without weakening open-gap detection.

</code_context>

<deferred>
## Deferred Ideas

- Broad historical normalization across older UAT, summary, audit, or planning artifacts outside the narrow Phase 12 archival blocker.
- A formal GSD-wide legacy-artifact migration framework or generalized compatibility layer for many old repos.
- Any reopening of Phase 12 implementation behavior, docs content, or verification scope beyond the stale closeout metadata contract.

</deferred>

---

*Phase: 26-historical-closeout-hygiene*
*Context gathered: 2026-05-25*
