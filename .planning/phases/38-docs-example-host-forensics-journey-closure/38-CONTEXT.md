# Phase 38: docs-example-host-forensics-journey-closure - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Close `DOC-05` for v1.4 by aligning public docs and example-host guidance with the already-shipped forensic and runbook operator flows.

This phase owns:
- README and guide coverage for `/ops/jobs/forensics` investigative flow
- explicit evidence-boundary and support-truth language for forensic and runbook handoffs
- example-host walkthrough alignment for supported operator journeys and host-owned escalation boundaries
- docs-contract and milestone evidence references that make closure auditable

This phase does not:
- add new runtime forensics/remediation capabilities
- reopen ownership boundaries locked in phases 31, 34, 35, and 37
- claim first-party ownership of downstream alert delivery or external runbook truth

</domain>

<decisions>
## Implementation Decisions

### Forensics Docs Surface Map
- **D-01:** Add one canonical guide, `guides/forensics-and-runbook-handoffs.md`, as the source of truth for the phase-38 operator journey.
- **D-02:** Use a hub-and-spoke docs architecture: canonical deep narrative in the new guide, with concise cross-links from `README.md`, `guides/first-operator-session.md`, `guides/example-app-walkthrough.md`, `guides/support-truth-and-ownership-boundaries.md`, and `examples/phoenix_host/README.md`.
- **D-03:** Standardize the published investigative path as: `overview (/ops/jobs)` -> `forensics (/ops/jobs/forensics)` -> `legal next path` (ownership/venue explicit) -> `audit follow-up (/ops/jobs/audit)`.
- **D-04:** Require explicit evidence-boundary labels in docs wherever causal certainty could be overstated: `partial evidence`, `history unavailable`, and `unknown`.

### Support-Truth Wording Depth
- **D-05:** Adopt layered wording: canonical deep contract + concise "support-truth snapshot" blocks in high-traffic docs + point-of-choice ownership labels at runbook decision points.
- **D-06:** Keep ownership triad wording locked and consistent: `Powertools-native` (`Audited action`), `Oban Web bridge` (`Inspection only`), and `host-owned follow-up`.
- **D-07:** For escalation seams, claim only statuses Powertools can prove (`unconfigured`, `invoked`, `failed`) and never imply provider-level delivery truth.
- **D-08:** Keep support buckets (`supported`, `tested`, `best-effort`, `host-owned`, `intentionally unsupported`) visible for major forensics/runbook claims, not only in a single reference doc.

### Example-Host Journey Shape
- **D-09:** Use a layered journey shape: fast quickstart plus deeper runbook/forensics guidance, anchored by one canonical operator workflow spine.
- **D-10:** Extend first-session and example-host walkthrough docs with an explicit post-mutation forensic continuity step (`ops-demo` -> `pause_cron_entry nightly_sync` -> forensic confirmation -> audit confirmation).
- **D-11:** Keep scenario coverage bounded (3-5 high-value scenario appendices) to avoid runbook-doc sprawl and drift.
- **D-12:** Keep example-host prose tied to concrete fixture paths and route-level behavior to preserve least surprise for Phoenix adopters.

### DOC-05 Closure Evidence Format
- **D-13:** Use a hybrid closure model: executable docs-contract checks + phase-level verification artifact + requirements traceability references.
- **D-14:** Evolve `test/oban_powertools/docs_contract_test.exs` with file-scoped DOC-05 assertions for forensics/runbook claims; do not rely only on globally joined marker checks.
- **D-15:** Introduce claim IDs (for example `DOC05-C1...`) in docs-contract assertions so phase verification can map each closure claim to a concrete test.
- **D-16:** Add guard assertions that prevent over-claiming first-party alert delivery or external runbook ownership.

### Claude's Discretion
- Exact marker strings and test naming in docs-contract coverage, as long as claim-to-evidence mapping stays explicit.
- Exact section titles and ordering within the new canonical forensics guide, as long as the workflow spine and ownership/evidence boundaries remain unchanged.
- Exact split between walkthrough narrative and scenario appendix material, as long as onboarding stays fast and day-2 guidance remains support-truthful.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` - Phase 38 scope, plan breakdown, and closure criteria.
- `.planning/PROJECT.md` - v1.4 posture, recommendation-first decision policy, and support-truth constraints.
- `.planning/REQUIREMENTS.md` - `DOC-05` requirement text, support-truth gate, and proof posture constraints.
- `.planning/STATE.md` - active sequencing and current milestone context.

### Prior locked context that constrains Phase 38
- `.planning/phases/31-docs-example-host-verification-support-truth-closure/31-CONTEXT.md` - docs/example-host/support-truth closure posture and claim-based docs contract approach.
- `.planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-CONTEXT.md` - runbook entry advisory model and ownership triad contract.
- `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-CONTEXT.md` - runbook continuity plus host-owned escalation seam boundaries.
- `.planning/phases/37-verification-backfill-forensic-ops-baseline/37-CONTEXT.md` - verification report/evidence discipline and additive traceability posture.

### Public docs and fixture surfaces in scope
- `README.md` - top-level install/support-truth and operator-surface promises.
- `guides/first-operator-session.md` - canonical first successful operator journey.
- `guides/example-app-walkthrough.md` - canonical fixture walkthrough and operator journey framing.
- `guides/support-truth-and-ownership-boundaries.md` - shared ownership/support bucket contract.
- `examples/phoenix_host/README.md` - fixture-level host contract and operator caveats.
- `test/oban_powertools/docs_contract_test.exs` - executable docs-contract proof lane.

### Product posture and research context prompts
- `prompts/oban_powertools_context.md` - domain language, support-truth posture, and recommendation-first planning guidance.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` - native shell and bounded bridge strategy, ownership clarity, and least-surprise operator UX.
- `prompts/oban-powertools-deep-research-original-prompt.md` - one-shot recommendation posture, ecosystem lessons, and DX/SRE quality bar.

### Current forensics/runbook implementation anchors
- `lib/oban_powertools/web/forensics_live.ex` - canonical forensics surface wording and diagnosis-first posture.
- `lib/oban_powertools/forensics/runbook_entry.ex` - runbook entry ownership and legal-next-path shape.
- `lib/oban_powertools/web/control_plane_presenter.ex` - shared ownership/status wording seam used across surfaces.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/oban_powertools/docs_contract_test.exs` already enforces claim markers and is the natural place to add DOC-05 closure checks.
- `guides/support-truth-and-ownership-boundaries.md` already freezes the support bucket vocabulary and ownership split.
- `guides/first-operator-session.md` already provides a concrete paved-road operator flow (`ops-demo`, `nightly_sync`, `pause_cron_entry`) that can be extended with forensic continuity.
- `examples/phoenix_host/README.md` already captures curated fixture provenance and host-owned caveats, making it a strong anchor for journey alignment.

### Established Patterns
- Claim-based docs contracts over full prose snapshots.
- Host-owned seams and explicit ownership boundaries at surface entrypoints.
- Diagnosis-first operator posture with read-only bridge boundaries clearly named.
- Additive phase closure artifacts (verification and traceability) rather than broad historical rewrites.

### Integration Points
- Add canonical forensics/runbook guide and connect all public entry docs to it.
- Extend docs-contract tests from broad joined markers toward file-scoped DOC-05 claim checks.
- Publish phase closure references so ROADMAP/REQUIREMENTS/phase artifacts tell one consistent closure story.

</code_context>

<specifics>
## Specific Ideas

- The recommendation set is intentionally one-shot and coherent: one canonical journey guide, one layered wording model, one workflow spine, one hybrid evidence model.
- Prioritize least surprise for Phoenix adopters by documenting route-level operator flow explicitly (`/ops/jobs`, `/ops/jobs/forensics`, `/ops/jobs/audit`) instead of abstract prose.
- Keep docs honest at the decision point: operators should know whether the next step is native, bridge-only, or host-owned before they act.
- Preserve DX by avoiding both extremes: no giant README monolith and no scattered disconnected caveat fragments.

</specifics>

<deferred>
## Deferred Ideas

- Full semantic/NLP-style docs assertions for prose meaning (deferred unless marker+file-scoped checks prove insufficient).
- Broad scenario library beyond high-value forensics/runbook operator journeys (deferred to avoid doc sprawl in this phase).
- Any runtime behavior expansion for forensics/remediation beyond docs and closure evidence alignment.

</deferred>

---

*Phase: 38-docs-example-host-forensics-journey-closure*
*Context gathered: 2026-05-27*
