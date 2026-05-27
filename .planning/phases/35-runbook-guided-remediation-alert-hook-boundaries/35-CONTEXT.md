# Phase 35: Runbook-Guided Remediation & Alert Hook Boundaries - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Connect supported remediation flows to durable runbook context and explicit host-owned escalation seams. This phase makes native remediation attempts explainable after the fact and prepares narrow alert/escalation integration boundaries, but it does not ship a first-party paging, ticketing, or runbook automation product.

</domain>

<decisions>
## Implementation Decisions

### Recommendation-First Scope
- **D-01:** Treat Phase 35 as a continuity and boundary phase, not a new capability family. The planner should extend the existing advisory runbook, Lifeline remediation, audit, and forensic bundle seams.
- **D-02:** Do not reopen Phase 34's runbook shape. `RunbookEntry` remains evidence-grounded guidance assembled from forensic bundles; Phase 35 adds durable attempted-step context only where a supported native action is previewed or executed.
- **D-03:** No broad user-choice gray area remains after repo-local research. Escalation would only be needed if planning proposes first-party provider delivery, a persisted generic checklist/session product, or a new public automation API.

### Native Remediation Continuity
- **D-04:** Supported Powertools-native remediation flows must carry runbook context from guidance into preview, execute, audit, and forensic evidence. The resulting audit/evidence view should answer: which runbook entry or legal next path led here, what was attempted, why it was allowed, and what result was recorded.
- **D-05:** Store durable runbook context as structured metadata attached to existing native mutation evidence, not as rendered prose. Prefer stable selectors and facts: runbook entry subject, diagnosis state, evidence completeness, selected legal-next-path intent/ownership/venue, preview token, incident fingerprint, target resource, action, reason, and plan hash.
- **D-06:** Keep rendered runbook copy, refusal prose, reason text in URLs, preview internals in URLs, and destination-specific UI wording out of continuity selectors. Destinations must reconstruct current truth from durable identifiers and stored facts.
- **D-07:** Lifeline remains the native execution venue for currently supported remediation. Workflow, cron, limiter, and forensic surfaces can route toward Lifeline or evidence follow-up, but should not become second mutation venues unless a later phase deliberately changes that contract.
- **D-08:** Completion evidence must distinguish previewed, attempted, succeeded, refused, drifted, expired, consumed, bridge-only, and host-owned follow-up states. Do not imply a remediation completed when the operator only opened guidance or followed an external path.

### Alert and Escalation Hook Boundaries
- **D-09:** Add only a narrow host-owned alert/escalation integration seam. Powertools may expose structured event facts or callback points around evidence/runbook/remediation state, but the host owns destinations, credentials, delivery guarantees, retry policy, escalation routing, and downstream runbook truth.
- **D-10:** Fallback behavior must be explicit and non-magical: if no host hook is configured, render and record "host-owned follow-up unavailable/not configured" style guidance rather than pretending Powertools delivered an alert.
- **D-11:** Avoid provider-specific adapters in core. Slack, PagerDuty, ticketing, webhooks, and incident-management products remain future companion or host code unless a later milestone changes the packaging ledger.
- **D-12:** Hook payloads, if introduced, should use low-cardinality event names and bounded structured metadata. They must not leak high-cardinality identifiers into telemetry labels or freeze a broad machine automation contract.

### Ownership and UX Boundaries
- **D-13:** Preserve the ownership triad at the point of choice: `Powertools-native`, `Oban Web bridge`, and `host-owned follow-up`.
- **D-14:** Powertools-native paths may render as actionable controls only when they stay inside the existing preview -> reason -> execute -> audit trust model.
- **D-15:** Oban Web bridge paths remain inspection-only, even when they appear as part of a remediation runbook.
- **D-16:** Host-owned escalation paths render as guidance or configured host follow-up, not as filled native action controls owned by Powertools.
- **D-17:** Continue the shared operator reading order: diagnosis -> runbook guidance -> legal next path -> venue/ownership -> evidence -> audit follow-up.

### Proof and Support Truth
- **D-18:** Merge-blocking proof should cover runbook context preserved through at least one supported native remediation path into audit and forensic evidence.
- **D-19:** Proof should cover host-owned escalation hook fallback and configured-hook behavior without requiring a real external provider.
- **D-20:** Proof should assert native, bridge-only, and host-owned follow-up paths remain visually and semantically distinct across remediation and escalation surfaces.
- **D-21:** Public docs and example-host changes belong mostly to Phase 36, but Phase 35 implementation and tests must avoid claims that Phase 36 docs cannot support.

### the agent's Discretion
- Exact schema, struct, or metadata names for runbook attempt context, provided selectors remain stable and rendered prose stays out of durable selectors.
- Whether the host-owned hook seam is a behaviour, callback module, config option, or small event dispatcher, provided ownership and fallback semantics stay explicit.
- Exact UI layout for remediation context in audit/forensics, provided it stays close to the acted-on evidence and does not become a generic incident-management console.
- Exact test file split, provided the proof directly covers RNB-03 and the alert/escalation boundary portion of HST-05.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 35 scope, plan breakdown, dependency on Phase 34, and Phase 36 closure boundary.
- `.planning/PROJECT.md` — v1.4 posture, recommendation-first decision policy, and host-owned support-truth constraints.
- `.planning/REQUIREMENTS.md` — `RNB-03`, `HST-05`, proof posture gate, support-truth gate, and packaging ledger for alert/escalation seams.
- `.planning/STATE.md` — current milestone sequencing and accumulated locked decisions.

### Prior locked decisions that constrain this phase
- `.planning/phases/27-control-plane-vocabulary-status-taxonomy-ownership-contract/27-CONTEXT.md` — shared operator vocabulary and ownership contract.
- `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md` — diagnosis-first overview and URL-owned continuity posture.
- `.planning/phases/29-shared-preview-reason-refusal-audit-contract/29-CONTEXT.md` — preview/reason/refusal/audit trust model, shared audit follow-up, and URL guardrails.
- `.planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-CONTEXT.md` — shared opening-story contract and venue-honest follow-up rules.
- `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-CONTEXT.md` — forensic bundle contract, provenance, completeness, linked resources, and legal next paths.
- `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-CONTEXT.md` — limiter/cron history semantics and partial-evidence handling.
- `.planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-CONTEXT.md` — advisory runbook entry shape, ownership triad, and explicit Phase 35 boundary for persisted attempted-step context.

### Product posture and research prompts
- `prompts/oban_powertools_context.md` — domain language, personas, and support-truth expectations.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — native-shell plus bounded-bridge strategy.
- `prompts/oban-powertools-deep-research-original-prompt.md` — ecosystem lessons, operator trust, DX, and one-shot recommendation posture.

### Current implementation surfaces and reusable seams
- `lib/oban_powertools/forensics/runbook_entry.ex` — current advisory runbook entry structure, ownership labels, legal next path normalization, and Phase 34 advisory boundary text.
- `lib/oban_powertools/forensics.ex` — shared forensic bundle assembly, Lifeline/workflow legal next paths, completeness, and runbook enrichment.
- `lib/oban_powertools/forensics/evidence_bundle.ex` — reusable evidence-bundle data shape.
- `lib/oban_powertools/lifeline.ex` — supported native remediation preview/execute path, reason validation, `Ecto.Multi` mutation, preview consumption, and repair audit write.
- `lib/oban_powertools/audit.ex` — normalized audit event writer/reader and query-backed scoped filters.
- `lib/oban_powertools/web/control_plane_presenter.ex` — shared ownership, runbook boundary, forensic completeness, audit follow-up, and refusal wording helpers.
- `lib/oban_powertools/control_plane.ex` — machine-facing status and ownership taxonomy.
- `lib/oban_powertools/web/forensics_live.ex` — canonical deep runbook/evidence rendering surface.
- `lib/oban_powertools/web/lifeline_live.ex` — native Lifeline remediation venue and local audit/evidence continuity surface.
- `lib/oban_powertools/web/workflows_live.ex` — workflow diagnosis and runbook/Lifeline handoff surface.
- `lib/oban_powertools/web/cron_live.ex` — cron runbook and audit follow-up surface.
- `lib/oban_powertools/web/limiters_live.ex` — limiter runbook and host-owned follow-up surface.
- `test/oban_powertools/forensics_test.exs` — current runbook ownership, advisory boundary, completeness, and legal-next-path proof.
- `test/oban_powertools/web/live/forensics_live_test.exs` — current deep runbook rendering and non-native path proof.
- `test/oban_powertools/lifeline_test.exs` and `test/oban_powertools/web/live/lifeline_live_test.exs` — existing supported remediation and continuity proof to extend.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Forensics.RunbookEntry`: already normalizes prerequisites, cautions, ownership, legal next paths, and evidence paths. Phase 35 should extend or wrap this shape rather than hand-building attempt context elsewhere.
- `ObanPowertools.Forensics.EvidenceBundle`: already centralizes subject, diagnosis, chronology, related evidence, linked resources, legal next paths, and completeness.
- `ObanPowertools.Lifeline.execute_repair/5`: already has the transaction boundary for target mutation, incident resolution, preview consumption, and audit write.
- `ObanPowertools.Audit.record/4`: already accepts structured metadata and normalized resource identity, making it the natural place to retain runbook attempt context.
- `ControlPlanePresenter.runbook_ownership_label/1`, `runbook_boundary_note/1`, and `runbook_path_posture/1`: already encode the ownership triad and should remain the shared wording seam.

### Established Patterns
- Durable truth belongs in context functions and `Ecto.Multi`; LiveViews render read models and should stay thin.
- URL selectors carry stable identifiers only. Rendered copy, preview tokens, reason text, and transient mutation state stay off URLs.
- Native actions are preview-first, reason-aware, permission-checked, and audit-backed.
- Forensic/audit views reconstruct current durable truth from resource identity and scoped selectors.
- Host-owned and bridge-only follow-up paths render as bounded guidance rather than native action controls.

### Integration Points
- Extend runbook context into Lifeline preview/execute metadata and repair audit rows.
- Project remediation attempts back into forensic bundles and audit follow-up views.
- Add a host-owned alert/escalation hook seam near durable remediation/runbook state transitions, with explicit no-op/unconfigured fallback.
- Reuse existing LiveView surfaces for rendering continuity rather than adding a new remediation dashboard.

</code_context>

<specifics>
## Specific Ideas

- Preferred operator feel: "I can see the runbook that led to this action, the evidence it relied on, what the operator attempted, and whether Powertools or the host owned the next step."
- Preferred implementation feel: add narrow structured context to existing preview/audit/evidence paths instead of creating a generic runbook session engine.
- External SRE/incident-management research supports this posture: actionable alerts, current playbooks, clear escalation ownership, and audit trails matter; provider-specific delivery and broad runbook automation should not be implied unless explicitly owned and proven.
- The most important anti-claim: Phase 35 may prove a hook seam and fallback behavior, but it must not claim that Powertools delivered a page, opened a ticket, or ran an external runbook.

</specifics>

<deferred>
## Deferred Ideas

- First-party Slack, PagerDuty, ticketing, or incident-management delivery adapters — future companion package or later milestone.
- Generic persisted runbook checklist/session product — out of v1.4 scope unless a later milestone deliberately broadens the product.
- Machine-facing CLI/API automation contracts for runbook remediation — deferred until the investigative vocabulary and support truth settle.
- Native generic queue/job dashboard parity — still deferred and bridge-only per earlier milestone decisions.

</deferred>

---

*Phase: 35-runbook-guided-remediation-alert-hook-boundaries*
*Context gathered: 2026-05-27*
