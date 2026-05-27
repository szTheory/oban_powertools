# Requirements: Oban Powertools

**Defined:** 2026-05-26
**Milestone:** v1.4 Operator Forensics & SRE Runbooks
**Status:** Drafted and approved by default candidate selection
**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

## v1.4 Goal

Make the stable v1.3 control plane materially better for real incident investigation and remediation by adding durable forensic context, clearer operational history, and runbook-guided follow-up without widening scope into a generic queue dashboard or premature automation contract.

## v1.4 Requirements

### Forensic Timelines & Evidence Bundles

- [x] **FRN-01**: Operators can inspect a durable cross-surface forensic timeline for a Powertools-managed resource that shows diagnosis-relevant state changes, manual actions, and related audit events in chronological order.
- [x] **FRN-02**: Operators can open an evidence bundle from a diagnosis state and see the current summary, recent causal events, related resources, and the next supported investigative or remediation paths.
- [x] **FRN-03**: Forensic views preserve the shared control-plane vocabulary from v1.3 so concepts like blocked, waiting, needs review, resolved, bridge-only, and host-owned remain consistent across overview and drill-down surfaces.

### Operational History & Missed-Fire Diagnostics

- [x] **OPS-01**: Operators can inspect limiter history that explains when capacity was exhausted, restored, or reconfigured, with enough context to distinguish transient pressure from policy-caused blocking.
- [x] **OPS-02**: Operators can inspect cron missed-fire, delayed-fire, and overlap-relevant history so they can diagnose why a scheduled task did not run when expected.
- [x] **OPS-03**: The native overview can project attention-worthy historical issues from limiters, cron, workflows, and Lifeline without degrading into a generic raw-event feed.

### Runbook-Guided Remediation

- [x] **RNB-01**: Operators can see runbook-guided next steps for supported diagnosis states, including preconditions, cautions, and the recommended order of operations before any bounded native action.
- [x] **RNB-02**: Runbook guidance distinguishes Powertools-native actions, bridge-only follow-up, and host-owned or external-system steps so the product stays honest about its ownership boundaries.
- [x] **RNB-03**: When operators launch or complete a supported remediation flow, the resulting audit and evidence views retain the runbook context needed to explain what was attempted and why.

### Support Truth, Proof & Host Integration

- [x] **DOC-05**: README, operator guides, and example-host material explain the new forensics and runbook surfaces honestly, including what is advisory, what is merge-blocking proof, and what remains host-owned.
- [x] **VER-04**: Automated proof covers forensic timeline projection, limiter and cron history behavior, runbook guidance rendering, and continuity between diagnosis, action, and audit surfaces.
- [x] **HST-05**: Host apps can integrate alert or escalation hooks around the new investigative surfaces without losing explicit boundaries about where entitlement, delivery, or downstream runbook truth lives.

## Capability Selection Rubric

| Capability Family | Route Owner Expectation | Bridge Frequency | Permission / Policy Sensitivity | Support-Matrix Impact | Proof Required | Package Classification |
|-------------------|-------------------------|------------------|---------------------------------|-----------------------|----------------|------------------------|
| Forensic timelines and evidence bundles | Native Powertools shell | Low-frequency semantic | Medium | High | Hermetic projection and LiveView proof | `core` |
| Limiter history and cron missed-fire diagnostics | Native Powertools shell | Native screen | Medium | High | Hermetic history and projection proof | `core` |
| Runbook-guided remediation flows | Native Powertools shell with explicit external follow-up seams | Mixed native + host-owned | High | High | Hermetic guidance and audit continuity proof | `core` |
| Alert or escalation hooks | Host-owned integration seam | Defer | High | Medium | Advisory integration proof plus docs | `companion` |
| Generic queue or job event explorer | Generic dashboard surface | Native screen | Medium | High | Out of milestone | `defer` |
| CLI/API automation contracts | External integration | Defer | High | High | Out of milestone | `defer` |

## Packaging Ledger

| Surface | Classification | Scope Rule |
|---------|----------------|------------|
| Forensic projections, timelines, and evidence bundles inside `/ops/jobs` | `core` | Must build on existing native control-plane vocabulary and stay diagnosis-first. |
| Limiter history and cron missed-fire diagnostics | `core` | Must answer specific operational questions instead of exposing an unrestricted raw-event console. |
| Runbook guidance, cautions, and bounded native remediation follow-up | `core` | Guidance may point to native, bridge-only, or host-owned next steps but must not pretend to own external systems. |
| Alert and escalation integration seams | `companion` | Keep hooks explicit and narrow; the host owns destination wiring and delivery truth. |
| Generic queue dashboard replacement | `defer` | Do not reopen the v1.3 decision to avoid a native generic queue rewrite. |
| CLI/API automation surfaces | `defer` | Reserve until the investigative vocabulary and support truth settle. |

## Future Requirements

### Deferred From v1.4

- **API-02**: Control-plane diagnosis and bounded actions are available through explicit CLI or API contracts for automation use cases.
- **QRY-01**: Native queue and generic job inspection reach parity with the bounded bridge for the primary adopter flows that still require Oban Web today.
- **ALR-01**: Powertools ships first-party delivery adapters for Slack, PagerDuty, or similar escalation targets instead of host-owned hooks.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Rebuilding the full generic Oban Web job or queue dashboard in native Powertools pages | The milestone should deepen investigative leverage, not broaden into commodity dashboard parity work. |
| Machine-facing CLI or API automation contracts | Prematurely freezes contracts before the operator forensics vocabulary has been proven in the native UI. |
| First-party ownership of external alert delivery, paging, or ticketing workflows | Alert and runbook truth should stay explicit and host-owned unless a later milestone deliberately broadens that contract. |
| Non-Postgres forensic storage or a separate control plane | Conflicts with the product's Ecto-native and inspectable-operational-state posture. |

## Proof Posture Gate

| Claim Area | Merge-Blocking Hermetic Proof | Advisory Proof | Support Obligation |
|------------|-------------------------------|----------------|--------------------|
| Forensic timeline projection | Projection and LiveView tests for chronology, resource linkage, and diagnosis labeling | Maintainer smoke review for readability | Public docs must not imply hidden or best-effort timelines where proof is narrower. |
| Limiter history and cron missed-fire diagnosis | History generation and rendering tests covering representative block, restore, and schedule-slip cases | Example-host walkthrough notes | Operators must get explicit “unknown” or “insufficient evidence” states rather than inferred certainty. |
| Runbook-guided remediation | LiveView and audit continuity tests covering guidance rendering, cautions, and follow-up state | Manual review of wording and guardrails | Guidance must stay honest about native versus host-owned or bridge-only steps. |
| Alert/escalation integration seams | Contract tests for hook wiring and fallback behavior | Host-example integration notes | Docs must state that delivery and downstream runbook truth live outside core Powertools. |
| Docs and example-host alignment | Docs-contract plus example-host proof for the supported operator journey | Maintainer review of support-truth language | README and guides must describe forensics as investigative support, not universal observability. |

## Support Truth Gate

| Surface | Denial / Fallback Behavior | Missing Prerequisite Behavior | Native Rebuild Required | Rough-Edge Docs To Publish |
|---------|----------------------------|-------------------------------|-------------------------|----------------------------|
| Forensic timelines and evidence bundles | Show explicit “not enough evidence”, “history unavailable”, or “bridge-only” states instead of invented chronology | Missing audit or historical rows must degrade to visible partial evidence rather than blank certainty | No | Forensics scope and evidence limitations |
| Limiter and cron history views | Show absence or retention limits explicitly when history is incomplete | Missing scheduler or limiter history must remain visible as a support-truth boundary | No | Missed-fire and limiter-history interpretation guide |
| Runbook guidance | Refuse unsupported actions with shared v1.3 wording and point to the next honest path | Missing auth, reason, or host-owned integration seams must remain explicit before action | No | Runbook guidance and ownership boundaries |
| Alert or escalation hooks | Fall back to no-op or explicit unavailable states without implying that Powertools delivered an alert | Missing host wiring or credentials must stay host-owned and clearly surfaced | No | Alert hook setup and host-owned delivery truth |
| Example host and public docs | Keep the canonical host focused on supported operator journeys only | Missing optional integrations must stay documented as optional and external | No | Example-host forensics and runbook walkthrough |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FRN-01 | Phase 37 | Complete |
| FRN-02 | Phase 37 | Complete |
| FRN-03 | Phase 37 | Complete |
| OPS-01 | Phase 37 | Complete |
| OPS-02 | Phase 37 | Complete |
| OPS-03 | Phase 34 | Complete |
| RNB-01 | Phase 34 | Complete |
| RNB-02 | Phase 34 | Complete |
| RNB-03 | Phase 35 | Complete |
| DOC-05 | Phase 38 | Complete |
| VER-04 | Phase 39 | Complete |
| HST-05 | Phase 35 | Complete |
| API-02 | Deferred (v1.5+) | Deferred |
| QRY-01 | Deferred (v1.5+) | Deferred |
| ALR-01 | Deferred (v1.5+) | Deferred |

Reconciliation note: **Phase 36 is a reconciliation umbrella** with additive chronology only.
`DOC-05` closure ownership stays in Phase 38 (`38-VERIFICATION.md`, including `DOC05-C1` contract lineage),
and `VER-04` closure ownership stays in Phase 39 (`39-VERIFICATION.md` and `39-PROOF-MANIFEST.json`,
including `VER04-C1` and aggregate `continuity-proof-status`).

### Phase 37 Verification Backfill References

- `FRN-01` -> `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VERIFICATION.md`
- `FRN-02` -> `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VERIFICATION.md`
- `FRN-03` -> `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VERIFICATION.md`
- `OPS-01` -> `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-VERIFICATION.md`
- `OPS-02` -> `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-VERIFICATION.md`

### Phase 38 Verification References

- `DOC-05` -> `.planning/phases/38-docs-example-host-forensics-journey-closure/38-VERIFICATION.md`

### Phase 39 Verification References

- `VER-04` -> `.planning/phases/39-ci-continuity-proof-lane-closure/39-VERIFICATION.md`
- `VER-04` -> `.planning/phases/39-ci-continuity-proof-lane-closure/39-PROOF-MANIFEST.json`

**Coverage:**

- v1.4 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0
- Complete: 12
- Pending: 0

---
*Requirements defined: 2026-05-26*
*Last updated: 2026-05-27 after phase 36 reconciliation closure*
