# Phase 32: Forensic Timeline & Evidence Bundle Foundation - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the shared investigative read model, evidence-bundle vocabulary, and
timeline semantics for v1.4 before limiter-history and cron missed-fire
surfaces broaden the native control plane.

This phase owns:
- one shared forensic contract that can assemble durable investigative context
  across workflow, Lifeline, limiter, cron, and audit evidence
- first-class forensic timeline and evidence-bundle entry points on the two
  strongest existing native diagnosis surfaces: workflows and Lifeline
- explicit partial-evidence, unknown-state, and continuity semantics so later
  history-heavy phases do not invent page-local truth
- projection seams and proof posture for chronology, linked-resource continuity,
  and support-truthful degradation

This phase does not:
- turn limiter and cron into fully fledged forensic destinations yet
- front-load Phase 33 missed-fire or limiter-history semantics into Phase 32
- reopen generic queue or job dashboard scope
- invent a second incident language beside the v1.3 control-plane contract

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Keep the repo in research-first, recommendation-first mode. Downstream agents should use repo context, Phoenix/LiveView/Ecto norms, and ecosystem lessons to narrow ordinary choices before asking anything.
- **D-02:** Escalate only if a fork would materially change public semantics, support truth, architecture boundaries, operator trust, or long-term maintainer burden.
- **D-03:** Treat prior v1.3 context decisions as locked defaults unless Phase 32 would otherwise create a real contract conflict.

### Phase 32 Entrypoint Sequencing
- **D-04:** Phase 32 locks **Workflow + Lifeline** as the only first-class forensic timeline and evidence-bundle entry points.
- **D-05:** Limiters and cron contribute **evidence inputs** to the shared forensic contract in Phase 32, but they do **not** become equal first-class forensic destinations until Phase 33 closes their dedicated history semantics.
- **D-06:** Phase 32 copy, plans, and proof must distinguish `evidence source` from `forensic entry surface` explicitly so operators are not misled into thinking limiter/cron history is already complete.
- **D-07:** This sequencing is deliberate, not provisional indecision: first-class forensic drilldowns attach to the strongest durable truth first, then weaker or narrower history sources get promoted later once their retention and semantics are frozen.

### Shared Forensic Contract
- **D-08:** Build one shared forensic read model and assembler seam rather than four page-local timeline builders.
- **D-09:** The forensic contract should reuse the v1.3 operator vocabulary and layer it into a durable investigative shape rather than inventing a parallel incident taxonomy.
- **D-10:** The minimum shared investigative shape is:
  `subject -> current diagnosis summary -> chronology -> related evidence -> linked resources -> legal next paths -> evidence completeness`.
- **D-11:** An evidence bundle must answer:
  what is happening,
  why the current diagnosis exists,
  which durable events support it,
  which related resources matter,
  what the next honest investigative or remediation paths are,
  and whether the bundle is complete, partial, or unknown.
- **D-12:** Keep chronology subordinate to diagnosis. The timeline explains and supports the control-plane story; it does not replace the diagnosis-first product posture with a raw event feed.

### Evidence Provenance and Truthfulness
- **D-13:** Every timeline item and bundle section must retain provenance: source family, resource identity, and whether the fact is durable, inferred, bridge-only, or missing.
- **D-14:** Workflow and Lifeline records are the highest-confidence narrative anchors in Phase 32 because they already own richer native diagnosis, preview/reason, and audit continuity.
- **D-15:** Limiter and cron evidence in Phase 32 should be treated as supporting context only:
  limiter snapshots, saturation/cooldown state, and related audit events;
  cron source/policy/state and related audit events.
- **D-16:** Missing historical rows, retention gaps, or unsupported chronology must render explicit `partial evidence`, `history unavailable`, or `unknown` states rather than implied certainty.
- **D-17:** Do not flatten evidence strength. A current limiter snapshot or paused cron row is not semantically equivalent to a durable workflow or Lifeline investigative trail.

### UX and Navigation Model
- **D-18:** Workflows and Lifeline should open forensic detail from their existing diagnosis-first surfaces instead of introducing a second competing drilldown model.
- **D-19:** The forensic experience should follow one stable operator reading order:
  `diagnosis summary -> timeline -> linked evidence -> related surfaces -> legal next path`.
- **D-20:** URL params own durable continuity selectors only. Keep using stable identifiers and scoped selectors such as `workflow_id`, `step`, `incident_fingerprint`, `view`, `resource_type`, and `resource_id`.
- **D-21:** Preview tokens, mutable reason text, refusal prose, and other transient mutation internals stay off forensic URLs.
- **D-22:** Forensic links may cross from one native surface into another native surface or into the audit destination, but the destination must reconstruct current durable truth from selectors rather than trust serialized source prose.

### Architecture and Query Posture
- **D-23:** Keep data access and forensic assembly out of LiveViews. The shared investigative read model belongs in dedicated query/projection modules, not in per-page `handle_params` trees.
- **D-24:** Build on normalized identity seams already present in audit and surface continuity work: `resource_type`, `resource_id`, stable event keys, and the existing control-plane presenter vocabulary.
- **D-25:** Prefer composable Ecto queries and projection helpers over ad hoc page-local fetch chains. Phase 32 should establish a reusable forensic query layer that Phase 33 can extend.
- **D-26:** Design the shared forensic read model so Phase 33 can promote limiter and cron into first-class forensic destinations additively, without rewriting the Phase 32 contract.

### Proof and Support-Truth Guardrails
- **D-27:** Phase 32 proof should focus on chronology ordering, linked-resource continuity, URL-safe remount behavior, and honest partial-evidence fallback.
- **D-28:** Do not claim all-surface forensic parity in Phase 32 docs, UI copy, or tests.
- **D-29:** If limiter or cron evidence appears in a Phase 32 bundle, it must be labeled as supporting evidence or related context unless Phase 33 semantics have already closed that gap.
- **D-30:** Preserve the v1.3 ownership posture:
  native Powertools surfaces own diagnosis and bounded action truth,
  audit remains the canonical cross-surface read-only evidence destination,
  generic job inspection remains bridge-only where applicable.

### Ecosystem-Learned Lessons To Apply
- **D-31:** Follow the strongest adjacent operator systems by attaching first-class drilldowns to the richest durable truth first, then layering supplemental evidence around them.
- **D-32:** Avoid the common monitoring/dashboard footgun where counters, weak history, or best-effort event streams are presented with the same confidence as durable forensic records.
- **D-33:** Prefer explicit retention and evidence-boundary language over “looks complete” UX that later collapses under missing rows or narrow history windows.

### the agent's Discretion
- Exact module names and projection boundaries for the forensic read model, provided assembly stays centralized and reusable.
- Exact evidence-bundle section labels and component layout, provided provenance, completeness, and legal next-path distinctions stay explicit.
- Exact split of chronology, bundle, and continuity assertions across tests, provided Phase 32 proves support-truthful ordering and fallback behavior without front-loading Phase 33 semantics.

</decisions>

<specifics>
## Specific Ideas

- Preferred sequencing:
  workflows and Lifeline become the first investigative homes because they already carry the repo’s richest diagnosis, continuity, and bounded-action truth.
- Preferred Phase 32 operator feel:
  “I can open one trustworthy forensic story now, see which facts are durable, and understand which related limiter/cron/audit evidence supports it without being tricked into thinking every surface has complete history yet.”
- Preferred evidence-bundle posture:
  one compact current-state summary, a chronology of diagnosis-relevant changes, clearly labeled related evidence cards, and explicit next paths.
- Preferred ecosystem lesson:
  strong operator products treat timelines as evidence-backed drilldowns around a primary subject, not as a generic cross-system raw event river.
- Preferred support-truth posture:
  if limiter or cron evidence is incomplete, say so directly and route the operator to the honest next place rather than fabricating continuity.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 32 scope, plan breakdown, and dependency ordering with Phase 33.
- `.planning/PROJECT.md` — v1.4 milestone posture, repo-level decision posture, and control-plane goals.
- `.planning/REQUIREMENTS.md` — `FRN-01`, `FRN-02`, `FRN-03`, plus the explicit Phase 32 versus Phase 33 traceability split.
- `.planning/STATE.md` — active milestone status and current sequencing.

### Prior locked decisions that constrain this phase
- `.planning/phases/27-control-plane-vocabulary-status-taxonomy-ownership-contract/27-CONTEXT.md` — shared operator vocabulary, ownership boundaries, and event naming contract.
- `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md` — diagnosis-first overview, durable continuity selectors, and bridge-only posture.
- `.planning/phases/29-shared-preview-reason-refusal-audit-contract/29-CONTEXT.md` — preview/reason/refusal/audit trust model and URL guardrails.
- `.planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md` — shared opening-story contract, continuity rules, and limiter/cron/workflow/Lifeline cohesion.
- `.planning/phases/31-docs-example-host-verification-support-truth-closure/31-CONTEXT.md` — support-truth discipline, docs/proof posture, and recommendation-first planning defaults.

### Product posture and research prompts
- `prompts/oban_powertools_context.md` — domain language, personas, clean-room product posture, and research-first narrowing guidance.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — native-shell plus bounded-bridge strategy and why Powertools-owned semantics should not be diluted by generic dashboard parity work.
- `prompts/oban-powertools-deep-research-original-prompt.md` — DX, operator trust, ecosystem lessons, and “one coherent recommendation set” posture.

### Current implementation surfaces and reusable seams
- `lib/oban_powertools/web/workflows_live.ex` — strongest existing workflow diagnosis surface and Lifeline handoff pattern.
- `lib/oban_powertools/web/lifeline_live.ex` — native review/preview/execute venue, continuity selectors, and inline audit/evidence posture.
- `lib/oban_powertools/web/cron_live.ex` — current cron state, preview, and audit surface that should feed forensic evidence without claiming full history yet.
- `lib/oban_powertools/web/limiters_live.ex` — current limiter live-now versus snapshot posture and bridge handoff seam.
- `lib/oban_powertools/web/overview_read_model.ex` — existing projection pattern, bucket semantics, and linked follow-up conventions to extend rather than bypass.
- `lib/oban_powertools/web/control_plane_presenter.ex` — shared status, ownership, and venue wording seam.
- `lib/oban_powertools/audit.ex` — normalized audit identity and durable event envelope to reuse for linked forensic evidence.
- `lib/oban_powertools/control_plane.ex` — shared operator-status taxonomy that the forensic contract must preserve.
- `lib/oban_powertools/web/audit_live.ex` — canonical read-only audit destination and scoped filter follow-up model.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WorkflowsLive` already provides the strongest diagnosis-first drilldown and bounded-action handoff shape; it is the natural first forensic entrypoint.
- `LifelineLive` already owns preview, reason, execution, resolved continuity, and inline audit evidence; it is the second natural first-class forensic entrypoint.
- `OverviewReadModel` already demonstrates a repo-preferred projection seam that centralizes operator story construction outside the LiveView.
- `Audit` already normalizes `resource_type`, `resource_id`, `event_type`, and `command_key`, which is the right identity backbone for cross-surface evidence linking.
- `ControlPlanePresenter` and `ControlPlane` already freeze shared vocabulary that forensic UI should extend instead of replacing.

### Established Patterns
- Thin LiveViews with centralized presenter/read-model wording are preferred over scattered page-local prose and query logic.
- Durable continuity comes from URL-backed stable selectors, not serialized mutation internals.
- Native Powertools pages own diagnosis and bounded-action truth; bridge surfaces remain explicitly narrower.
- The repo favors additive semantic expansion: freeze vocabulary and continuity first, then widen surface-specific history and proof.

### Integration Points
- Phase 32 should introduce a shared forensic projection/query layer that Workflows and Lifeline can consume first and Phase 33 can extend for limiter/cron promotion.
- Bundle assembly should connect workflow rows, Lifeline incidents, audit events, limiter snapshots, and cron state/audit evidence through normalized resource identity rather than ad hoc page-local joins.
- Proof updates should likely concentrate in high-signal LiveView tests plus projection-layer tests for chronology, provenance, completeness labeling, and remount continuity.

</code_context>

<deferred>
## Deferred Ideas

- Making limiter and cron equal first-class forensic destinations before their dedicated history semantics and retention boundaries are closed in Phase 33.
- A generic cross-system raw event console or unrestricted event feed.
- Reopening native generic queue/job dashboard parity work.
- Serializing rendered forensic prose, preview state, or mutable operator intent into URLs.
- Claiming all-surface forensic parity in docs or UI before history semantics and proof actually support it.

</deferred>

---

*Phase: 32-forensic-timeline-evidence-bundle-foundation*
*Context gathered: 2026-05-26*
