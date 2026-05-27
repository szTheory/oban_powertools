# Phase 38: docs-example-host-forensics-journey-closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `38-CONTEXT.md` - this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 38-docs-example-host-forensics-journey-closure
**Areas discussed:** Forensics docs surface map, Support-truth wording depth, Example-host journey shape, DOC-05 closure evidence format

---

## Forensics Docs Surface Map

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical guide + lightweight cross-links (hub-and-spoke) | One authoritative journey doc for `/ops/jobs/forensics`, evidence boundaries, and runbook handoffs; short pointers elsewhere | ✓ |
| Distributed-only updates | Spread details across existing docs with no canonical guide | |
| README-centric canonical | Put complete forensics journey primarily in README | |
| Matrix-first canonical | Use support-truth matrix as primary with minimal narrative | |

**User's choice:** Use subagent-backed one-shot recommendation; no manual option-by-option selection required.  
**Locked decision:** Canonical guide + cross-linked docs architecture.
**Notes:** Best balance for least surprise, discoverability, and drift control in this repo's docs-contract posture.

---

## Support-Truth Wording Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Centralized contract-only | Keep nuanced wording only in one deep contract doc | |
| Repeat full depth everywhere | Duplicate full boundary language in all docs | |
| Layered model | Canonical deep contract + concise snapshots + point-of-choice labels | ✓ |
| Evidence-coupled everywhere | Tag every claim heavily as advisory/proven in each doc | |

**User's choice:** Subagent-driven one-shot recommendation set; optimize for coherence and no extra cognitive load.  
**Locked decision:** Layered wording model with evidence-coupled discipline where claims are high-risk.
**Notes:** Preserve explicit ownership triad and avoid over-claiming downstream alert delivery truth.

---

## Example-Host Journey Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal fixture tour | Keep walkthrough mostly structural/provenance-focused | |
| Prescriptive single workflow | One strict operator flow for all readers | |
| Layered quickstart + deep dive | Fast start with canonical spine plus deeper operational detail | ✓ |
| Scenario/runbook-heavy | Large scenario catalog as primary docs mode | |

**User's choice:** One-shot recommendation with strong DX and day-2 operator confidence.  
**Locked decision:** Layered quickstart/deep-dive anchored by one canonical operator workflow spine.
**Notes:** Add explicit forensic continuity step after first native mutation and keep scenario appendix bounded.

---

## DOC-05 Closure Evidence Format

| Option | Description | Selected |
|--------|-------------|----------|
| Marker-only docs contract | Fast string marker checks only | |
| Semantic assertion only | Rich structure/meaning parser checks only | |
| Traceability matrix only | Artifact references without executable docs checks | |
| Hybrid evidence model | File-scoped docs-contract + verification artifact + requirements refs | ✓ |

**User's choice:** Subagent-backed one-shot recommendation set aligned with existing verification discipline.  
**Locked decision:** Hybrid evidence model.
**Notes:** Keep ExUnit-first workflow, add file-scoped DOC-05 claims, and maintain auditable mapping in phase verification artifacts.

---

## Claude's Discretion

- Exact marker wording and claim IDs in docs-contract tests.
- Exact section layout for the new canonical forensics/runbook guide.
- Exact split between quickstart narrative and scenario appendix depth.

## Deferred Ideas

- Full semantic/NLP docs assertion framework.
- Large scenario catalog beyond high-value forensic/runbook journeys.
- Runtime capability expansion (out of Phase 38 scope).
