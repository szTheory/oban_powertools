# Phase 32: forensic-timeline-evidence-bundle-foundation - Research

**Researched:** 2026-05-26
**Domain:** Phoenix LiveView forensic timelines and evidence-bundle composition for the native `/ops/jobs` control plane
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-04:** Workflow and Lifeline are the only first-class forensic entry surfaces in Phase 32.
- **D-05:** Limiters and cron contribute evidence inputs in Phase 32, but do not become equal first-class forensic destinations until Phase 33.
- **D-08:** Build one shared forensic read model and assembler seam rather than page-local timeline builders.
- **D-10:** The minimum shared investigative shape is `subject -> current diagnosis summary -> chronology -> related evidence -> linked resources -> legal next paths -> evidence completeness`.
- **D-12:** Chronology stays subordinate to diagnosis; Phase 32 must not devolve into a raw event feed.
- **D-13:** Every timeline item and bundle section must retain provenance, resource identity, and source-strength labeling.
- **D-16:** Missing history or unsupported chronology must surface as explicit `partial evidence`, `history unavailable`, or `unknown` states.
- **D-18:** Workflows and Lifeline should open forensic detail from their existing diagnosis-first surfaces rather than through a competing drilldown model.
- **D-20:** URLs may carry only durable continuity selectors such as `workflow_id`, `step`, `incident_fingerprint`, `view`, `resource_type`, and `resource_id`.
- **D-21:** Preview tokens, mutable reason text, refusal prose, and other transient mutation internals stay off forensic URLs.
- **D-23:** Data access and forensic assembly belong in dedicated query/projection modules, not in LiveViews.
- **D-25:** Prefer composable Ecto queries and projection helpers over ad hoc fetch chains.
- **D-27:** Proof must focus on chronology ordering, linked-resource continuity, remount-safe selectors, and honest partial-evidence fallback.
- **D-28:** Do not claim all-surface forensic parity in Phase 32 copy, UI, or tests.

### Deferred Ideas (OUT OF SCOPE)
- Promoting limiter or cron into first-class standalone forensic destinations.
- Building a generic raw event console.
- Serializing rendered forensic prose or preview state into URLs.
- Claiming historical completeness where only current-state or narrow evidence exists.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FRN-01 | Operators can inspect a durable cross-surface forensic timeline for a Powertools-managed resource showing diagnosis-relevant state changes, manual actions, and related audit events in chronological order. | Compose chronology from durable workflow/Lifeline facts plus audit evidence, and treat limiter/cron inputs as supporting context with explicit provenance rather than equal narrative anchors. |
| FRN-02 | Operators can open an evidence bundle from a diagnosis state and see the current summary, causal events, related resources, and next honest paths. | Add one shared bundle assembler and one native forensic destination wired from workflows and Lifeline. |
| FRN-03 | Forensic views preserve the v1.3 control-plane vocabulary across overview and drilldown surfaces. | Reuse `ControlPlanePresenter`, `ControlPlane`, and the existing native-versus-bridge wording seams rather than inventing new incident taxonomy or event labels. |
</phase_requirements>

## Summary

Phase 32 should be planned as one additive forensic read-model layer plus one bounded native forensic destination. The codebase already has the stable building blocks needed for this: normalized audit identity in `ObanPowertools.Audit`, shared control-plane wording in `ObanPowertools.Web.ControlPlanePresenter`, diagnosis-first workflow and Lifeline entry surfaces, and router-backed continuity selectors across native pages. The missing piece is a dedicated forensic composition seam that can assemble those facts into one trustworthy operator story without implying that every contributing source has equal historical depth.

The highest-risk failure mode is false confidence. Workflow and Lifeline already have durable diagnosis and action context, but limiter and cron currently skew toward live state and narrow audit context. If the plan lets those facts render as if they were equivalent to durable investigative history, Phase 32 will violate its own support-truth posture before Phase 33 even begins. The plan therefore needs explicit provenance and completeness labeling in the read model itself, not only in UI copy.

The safest execution path is:
1. Introduce a dedicated forensic domain/query layer that returns a normalized evidence bundle and chronology items with provenance and completeness metadata.
2. Add one native forensic LiveView destination plus continuity-safe links from the existing workflow and Lifeline pages.
3. Prove ordering, provenance labeling, cross-link continuity, remount-safe URL behavior, and partial-evidence states through focused unit and LiveView tests.

**Primary recommendation:** implement Phase 32 around a new shared `ObanPowertools.Forensics` seam and a bounded `/ops/jobs/forensics` native destination, while keeping workflows and Lifeline as the only first-class entry points and labeling limiter/cron facts as supporting evidence only.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Forensic evidence bundle assembly | API / Backend | Frontend Server (SSR) | Bundle shape and chronology truth should come from dedicated query/projection modules, not template-local branching. |
| Forensic destination rendering | Frontend Server (SSR) | API / Backend | LiveView should render one diagnosis-first page from assembled facts while preserving router-owned continuity. |
| Workflow and Lifeline entry links | Frontend Server (SSR) | Browser / Client | Existing native pages remain entry points; links should carry only durable selectors into the forensic destination. |
| Provenance and completeness labeling | API / Backend | Frontend Server (SSR) | Source-strength and evidence-boundary decisions belong in the assembled read model so every consumer stays honest. |
| Cross-surface audit follow-up | Frontend Server (SSR) | Database / Storage | Existing `/ops/jobs/audit` filters remain canonical for read-only evidence drilldown. |

## Standard Stack

### Core
| Library | Purpose | Why Standard |
|---------|---------|--------------|
| Phoenix LiveView | Native forensic destination, URL-backed continuity, server-rendered drilldown | The repo already uses LiveView for every operator surface, and the continuity model is already URL-first. |
| Ecto | Timeline and evidence queries | Existing read-model seams and audit filtering already rely on composable Ecto queries. |
| Existing Powertools audit + control-plane modules | Provenance, identity, vocabulary, and venue labels | Phase 32 should extend these seams rather than fork them. |

### No New Dependencies
- No need for external event-stream tooling, JS timeline libraries, or new persistence stores in Phase 32.
- No need for a new browser-E2E harness; hermetic LiveView and projection tests are aligned with repo practice.

## Recommended Project Structure

```text
lib/oban_powertools/
├── audit.ex
├── control_plane.ex
├── forensics.ex
└── forensics/
    ├── evidence_bundle.ex
    ├── chronology.ex
    └── provenance.ex

lib/oban_powertools/web/
├── control_plane_presenter.ex
├── forensics_live.ex
├── lifeline_live.ex
├── router.ex
└── workflows_live.ex

test/oban_powertools/
├── forensics_test.exs
└── web/live/
    ├── forensics_live_test.exs
    ├── lifeline_live_test.exs
    ├── workflows_live_test.exs
    └── control_plane_copy_coherence_test.exs
```

## Architecture Patterns

### Pattern 1: Shared Bundle Assembler With Typed Provenance
**What:** Create one forensic assembler that emits a subject summary, chronology items, supporting evidence cards, linked resources, next paths, and an explicit completeness state.  
**When to use:** Any workflow or Lifeline forensic drilldown, and later as the extension seam for Phase 33 limiter/cron promotion.  
**Why:** It keeps provenance and completeness honest in one place instead of letting UI code improvise confidence levels.

### Pattern 2: Strong Anchors First, Supporting Evidence Second
**What:** Treat workflow and Lifeline records as the primary narrative anchors; treat limiter and cron facts as supporting context only in Phase 32.  
**When to use:** Timeline ordering, evidence-card labeling, and next-path copy.  
**Why:** This matches the locked context and prevents false parity between current-state snapshots and durable investigative records.

### Pattern 3: Router-Owned Forensic Continuity
**What:** Keep forensic continuity in stable selectors such as `resource_type`, `resource_id`, `workflow_id`, `step`, `incident_fingerprint`, and `view`.  
**When to use:** Linking from workflow/Lifeline into the forensic destination and reopening the same bundle after refresh/remount.  
**Why:** It matches the existing control-plane continuity model and keeps transient preview/refusal state off the URL.

### Pattern 4: Audit As Canonical Read-Only Evidence Destination
**What:** Preserve `/ops/jobs/audit` as the canonical read-only follow-up surface for scoped event evidence.  
**When to use:** Timeline item links or related-evidence cards that need deeper historical inspection.  
**Why:** Audit already owns structured resource identity and scoped filters; Phase 32 should build on that instead of inventing a second history filter model.

## Validation Architecture

Phase 32 needs two proof layers:

1. **Projection/unit proof**
   - chronology sorts by durable event time
   - items carry provenance and completeness metadata
   - limiter/cron evidence is labeled as supporting context, not equal anchor history
   - missing rows produce `partial evidence`, `history unavailable`, or `unknown`

2. **LiveView continuity proof**
   - workflows and Lifeline expose native forensic entry links
   - forensic destination restores the same scoped bundle after refresh/remount
   - URLs contain only stable selectors
   - copy preserves v1.3 control-plane vocabulary and venue honesty

## Anti-Patterns To Avoid

- Building four page-local forensic assemblers in LiveViews.
- Rendering current limiter or cron state as if it were a durable historical trail.
- Introducing a second ad hoc history filter surface instead of reusing `/ops/jobs/audit`.
- Putting preview tokens, reason text, refusal prose, or rendered diagnosis in forensic URLs.
- Treating Phase 32 as permission to claim all-surface forensic parity before Phase 33 closes limiter-history and cron-history semantics.

## Planning Implications

- `32-01` should freeze the forensic bundle contract, provenance vocabulary, and shared query layer.
- `32-02` should add the native forensic destination and wire workflows/Lifeline into it.
- `32-03` should focus on chronology proof, linked-resource continuity, partial-evidence fallback, and copy-coherence closure.

---
*Research complete: 2026-05-26*
