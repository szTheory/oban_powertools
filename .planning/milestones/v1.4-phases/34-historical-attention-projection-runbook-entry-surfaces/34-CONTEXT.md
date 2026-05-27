# Phase 34: Historical Attention Projection & Runbook Entry Surfaces - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Project historically important operational issues back into the native `/ops/jobs`
control plane and expose the first honest runbook entry points for supported
diagnosis states.

This phase owns:
- historically informed attention projection for limiter, cron, workflow, and
  Lifeline evidence inside the existing native overview and relevant drill-down
  surfaces
- advisory runbook entry surfaces that pair diagnosis states with prerequisites,
  cautions, evidence, and the next honest investigative or remediation path
- shared wording for runbook entries, refusal-adjacent next steps, and overview
  handoffs using the existing control-plane and forensic vocabulary
- explicit native, bridge-only, and host-owned follow-up boundaries before an
  operator acts

This phase does not:
- add persisted runbook sessions, checklist execution, or remediation-attempt
  continuity; Phase 35 owns supported remediation continuity
- add first-party alert delivery, escalation integrations, or external SRE
  provider ownership
- create a raw historical event feed, generic queue dashboard, or unrestricted
  audit/history console
- reopen the v1.3 native-shell versus Oban Web bridge boundary

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Keep recommendation-first planning for this repo. Downstream agents
  should read repo-local context and implementation surfaces, narrow choices
  aggressively, and ask only if a fork changes public semantics, support truth,
  architectural boundaries, operator trust, or maintainer burden.
- **D-02:** Preserve the v1.3/v1.4 product posture: native Powertools pages own
  Powertools diagnosis and bounded audited action truth; the Oban Web bridge is
  inspection-only; host apps own external escalation and delivery truth.
- **D-03:** Treat the Phase 28 diagnosis-first overview, Phase 29 shared
  refusal/audit wording, Phase 30 shared opening-story contract, Phase 32
  forensic bundle contract, and Phase 33 limiter/cron history semantics as
  locked inputs.

### Historical Attention Projection
- **D-04:** Extend the existing overview buckets with historical attention
  projection rather than adding a separate raw history feed or generic
  “Historical Attention” dashboard band.
- **D-05:** Historical evidence may influence exemplar priority, attention
  reason, and next-path selection inside the existing diagnosis-first buckets,
  but it must not replace current-state operator status as the primary scan
  model.
- **D-06:** Attention projection should stay bounded and deterministic: one to
  three exemplar items per relevant bucket, each with a concise reason derived
  from durable facts or explicit partial-evidence state.
- **D-07:** Runbook-entry cards may be layered into overview and drill-down
  surfaces only for diagnosis states that have honest guidance. Do not show
  “interesting history” as a call to action when Powertools cannot state a safe
  next path.
- **D-08:** Projection ordering should favor actionable, symptom-oriented
  signals over recency theater. Recent limiter pressure, cron missed-fire or
  unknown-window evidence, workflow blocked steps, and Lifeline incidents should
  rank when they change what an operator should safely do next.
- **D-09:** Missing history, retention gaps, or incomplete provenance must remain
  visible as `partial evidence`, `history unavailable`, or `unknown`; never let
  an attention card imply certainty the forensic bundle cannot support.

### Runbook Entry Surface Shape
- **D-10:** Use a lightweight hybrid runbook surface: overview and selected native
  drilldowns show compact runbook-entry summaries, while `/ops/jobs/forensics`
  owns the deeper evidence-grounded runbook entry.
- **D-11:** The canonical runbook entry belongs in the same shared read-model
  family as forensic bundles, not as page-local HEEx prose. It should be
  assembled from diagnosis, evidence completeness, linked resources, and legal
  next paths.
- **D-12:** A runbook entry should contain, at minimum:
  diagnosis state, why it matters now, prerequisites, cautions, recommended
  order of operations, ownership/venue for each follow-up path, evidence link,
  and unsupported or partial-evidence boundaries.
- **D-13:** Phase 34 runbook entries are advisory and evidence-grounded. They may
  point to a native investigation, a bridge-only inspection, or a host-owned
  follow-up, but they must not create the impression that Powertools has already
  executed or recorded a remediation attempt.
- **D-14:** Do not introduce a persisted checklist/session model in Phase 34.
  Persisted attempted-step context, action continuity, and post-remediation
  evidence belong to Phase 35.
- **D-15:** Host-owned runbook links or external escalation destinations should
  stay optional and explicitly host-owned. Phase 34 may prepare the semantic
  slot for them, but should not make first product value depend on host
  configuration.

### Ownership Boundary and Copy Alignment
- **D-16:** Use a presenter-owned ownership triad for runbook and follow-up
  wording: `Powertools-native`, `Oban Web bridge`, and `host-owned follow-up`.
- **D-17:** Runbook entries and refusal-adjacent copy should share the same
  operator shape already locked in prior phases:
  `outcome -> concise reason -> legal next move -> venue -> evidence`.
- **D-18:** The ownership/venue label must appear at the decision point where an
  operator chooses the next path, not only after navigation.
- **D-19:** Avoid noisy badge repetition. Ownership should be mandatory in
  structured runbook/follow-up data and consistently rendered at decision
  points, but not sprayed across every sentence.
- **D-20:** `Investigate`, `Remediate`, and `Escalate` style verbs may be used as
  action-intent labels only when the ownership/venue remains equally visible.
  Do not let verb-first copy make host-owned escalation or bridge-only
  inspection sound native.
- **D-21:** Unsupported, premature, or host-owned steps should render as honest
  guidance or refusal-adjacent next paths, not disabled mystery controls or
  faux-native action buttons.

### Architecture and Query Posture
- **D-22:** Keep LiveViews thin. Historical attention and runbook-entry assembly
  belong in shared read-model/presenter modules rather than per-surface query
  and copy branches.
- **D-23:** Build on existing Phase 32/33 forensic read models where possible:
  `Forensics.bundle/2`, limiter history summaries, cron history summaries,
  completeness labels, linked resources, and `legal_next_paths`.
- **D-24:** `OverviewReadModel` should remain the overview composition seam, but
  Phase 34 should add shared historical-attention/runbook helpers instead of
  burying new ranking and copy rules directly inside the overview LiveView.
- **D-25:** Stable URL selectors remain the continuity contract:
  `resource_type`, `resource_id`, `workflow_id`, `step`,
  `incident_fingerprint`, and `view` are appropriate; rendered diagnosis,
  reason text, preview tokens, refusal prose, and runbook copy stay off URLs.
- **D-26:** Prefer additive internal structs or maps for runbook entries over a
  broad host-facing DSL. The structure should be testable and reusable by Phase
  35 without freezing a public automation API.

### Proof and Support-Truth Guardrails
- **D-27:** Phase 34 proof should assert that overview attention projection stays
  bounded, diagnosis-first, and not feed-like.
- **D-28:** Proof should assert that overview summaries, drill-down summaries,
  and forensic runbook entries agree because they share read models or presenter
  vocabulary.
- **D-29:** Tests must cover native, bridge-only, and host-owned follow-up labels
  before navigation or action.
- **D-30:** Tests must cover partial-evidence and history-unavailable states so
  attention/runbook guidance does not imply certainty when retained evidence is
  missing.
- **D-31:** Phase 34 should not claim remediation continuity, escalation
  delivery, or runbook execution in docs, UI, tests, or comments. Those claims
  become eligible only after Phase 35 implements and proves them.

### the agent's Discretion
- Exact module and struct names for historical-attention and runbook-entry read
  models, provided the assembly is centralized, testable, and reusable by Phase
  35.
- Exact attention scoring weights and exemplar ordering, provided they remain
  deterministic, bounded, and explanation-backed.
- Exact compact versus deep runbook layout split, provided the overview stays
  scannable and `/ops/jobs/forensics` remains the canonical evidence-grounded
  runbook entry.
- Exact wording polish for prerequisites and cautions, provided ownership,
  venue, evidence completeness, and unsupported boundaries stay explicit.

</decisions>

<specifics>
## Specific Ideas

- Preferred operator feel:
  “The overview tells me what historically deserves attention now, why, and the
  next safe thing to do without making me browse a feed.”
- Preferred attention shape:
  existing diagnosis buckets stay primary; historical facts change the exemplar
  reason and ordering only when they affect the next safe operator path.
- Preferred runbook shape:
  compact summary near the diagnosis, deeper evidence-grounded runbook entry in
  the forensic bundle, and no persisted checklist or execution session yet.
- Preferred ownership wording:
  `Powertools-native`, `Oban Web bridge`, and `host-owned follow-up` are
  structured metadata rendered at the point of choice.
- Research-backed external lesson:
  mature incident systems attach playbooks/runbooks to actionable symptoms,
  keep escalation ownership explicit, and avoid turning historical signals into
  dashboard sprawl or raw event streams.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 34 scope, plan breakdown, dependency on Phase
  33, and Phase 35 boundary.
- `.planning/PROJECT.md` — v1.4 milestone posture, repo-level decision posture,
  and native-shell support-truth goals.
- `.planning/REQUIREMENTS.md` — `OPS-03`, `RNB-01`, `RNB-02`, plus the proof and
  support-truth gates for attention projection and runbook guidance.
- `.planning/STATE.md` — active milestone status and current sequencing.

### Prior locked decisions that constrain this phase
- `.planning/phases/27-control-plane-vocabulary-status-taxonomy-ownership-contract/27-CONTEXT.md` — shared operator vocabulary, ownership model, and layered wording contract.
- `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md` — diagnosis-first overview, bounded exemplar posture, and native/bridge handoff rules.
- `.planning/phases/29-shared-preview-reason-refusal-audit-contract/29-CONTEXT.md` — refusal shape, audit follow-up model, preview/reason URL guardrails, and shared presenter posture.
- `.planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md` — shared opening-story contract, continuity params, and surface-cohesion rules.
- `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-CONTEXT.md` — forensic bundle shape, evidence completeness vocabulary, provenance, linked resources, and legal next paths.
- `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-CONTEXT.md` — limiter and cron first-class forensic destinations, retained history facts, missed-fire semantics, and partial-evidence handling.

### Product posture and research prompts
- `prompts/oban_powertools_context.md` — domain language, personas, product
  posture, and support-truth expectations.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — native-shell plus
  bounded-bridge strategy and why Powertools-owned diagnosis should not become
  generic dashboard parity.
- `prompts/oban-powertools-deep-research-original-prompt.md` — DX, operator
  trust, ecosystem lessons, and one-shot recommendation posture.

### Current implementation surfaces and reusable seams
- `lib/oban_powertools/web/overview_read_model.ex` — existing overview bucket,
  exemplar, diagnosis, and handoff composition seam to extend.
- `lib/oban_powertools/web/engine_overview_live.ex` — current diagnosis-first
  overview rendering.
- `lib/oban_powertools/forensics.ex` — shared bundle assembly, linked resources,
  legal next paths, completeness, and stable selector handling.
- `lib/oban_powertools/web/forensics_live.ex` — canonical forensic destination
  that should own the deeper runbook entry surface.
- `lib/oban_powertools/forensics/cron_history.ex` — cron slot history,
  missed-fire, unknown-window, completeness, and forensic bundle projection.
- `lib/oban_powertools/forensics/limiter_history.ex` — limiter history facts,
  resource-level diagnosis, completeness, and forensic bundle projection.
- `lib/oban_powertools/web/control_plane_presenter.ex` — shared status,
  provenance, completeness, ownership, venue, audit, and refusal wording seam to
  extend.
- `lib/oban_powertools/web/live_auth.ex` — shared read-only and permission
  vocabulary for page/action boundaries.
- `lib/oban_powertools/web/workflows_live.ex` — workflow diagnosis and forensic
  handoff surface.
- `lib/oban_powertools/web/lifeline_live.ex` — Lifeline incident diagnosis,
  native repair venue, forensic handoff, and audit continuity surface.
- `lib/oban_powertools/web/cron_live.ex` — cron history summary and forensic
  handoff surface.
- `lib/oban_powertools/web/limiters_live.ex` — limiter history summary and
  forensic handoff surface.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `OverviewReadModel` already centralizes the overview’s status buckets,
  bounded exemplars, diagnosis sentences, venue labels, and next-step paths.
- `Forensics.bundle/2` already routes stable selectors for workflows, Lifeline,
  cron entries, and limiters into one evidence-bundle contract.
- `CronHistory` and `LimiterHistory` already expose summary and bundle read
  models with completeness states, which are the strongest inputs for Phase 34
  historical attention.
- `ControlPlanePresenter` already owns forensic provenance labels,
  completeness labels, ownership posture, audit follow-up paths, and workflow
  refusal presentation.
- `ForensicsLive` already renders diagnosis summary, chronology, related
  evidence, linked resources, legal next paths, and evidence completeness in one
  canonical destination.

### Established Patterns
- Thin LiveViews with read-model/presenter-owned copy are preferred over
  page-local branching.
- The overview is a diagnosis-first triage surface with representative bounded
  exemplars, not a table-heavy inbox or event feed.
- Forensic URLs preserve durable selectors only and reconstruct current truth on
  the destination.
- Native Powertools surfaces, Oban Web bridge inspection, and host-owned
  follow-up must remain visibly distinct before an operator acts.

### Integration Points
- Phase 34 should likely add a shared internal runbook-entry/read-model seam
  that `OverviewReadModel`, `Forensics.bundle/2`, and selected native drilldowns
  can consume.
- Overview attention projection should connect Phase 33 limiter/cron history
  summaries and existing workflow/Lifeline diagnosis evidence to the existing
  bucket/exemplar model.
- The deeper runbook entry should attach naturally to the forensic bundle near
  `legal_next_paths`, `linked_resources`, and `completeness`.
- Proof should concentrate in `overview_read_model`, `forensics`, LiveView, and
  control-plane copy coherence tests rather than snapshotting broad prose.

</code_context>

<deferred>
## Deferred Ideas

- Persisted runbook sessions, checklists, attempted-step state, and remediation
  continuity — Phase 35.
- First-party alert delivery, PagerDuty/Slack/ticketing adapters, or external
  escalation ownership — later milestone or host-owned companion seam.
- Host-configured external runbook registries as a required first-value path.
- Generic historical event feed, raw audit/history console, or table-first
  operator inbox.
- Machine-facing CLI/API automation contracts for runbook or remediation flows.

</deferred>

---

*Phase: 34-historical-attention-projection-runbook-entry-surfaces*
*Context gathered: 2026-05-27*
