# Phase 10: Operator UX Coherence & Mutation Safety - Research

**Researched:** 2026-05-21
**Domain:** Native operator mutation coherence, durable preview semantics, read-only posture, and bridge support-truth across Powertools shell surfaces.
**Confidence:** HIGH [VERIFIED: repo-local code, tests, and prior phase artifacts]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Native Powertools pages remain the authoritative mutation surface; the optional `/ops/jobs/oban` bridge stays read-only in this phase. [VERIFIED: 10-CONTEXT.md]
- Mutation controls should stay visible but disabled-with-explanation when a viewer can inspect a resource but cannot mutate it. [VERIFIED: 10-CONTEXT.md] [VERIFIED: lib/oban_powertools/web/cron_live.ex]
- Native mutation flows must converge on one server-authoritative contract: `preview -> reason -> execute`. [VERIFIED: 10-CONTEXT.md]
- Durable preview records, explicit preview status, risk-based reason requirements, and durable audit evidence are all part of the target contract. [VERIFIED: 10-CONTEXT.md] [VERIFIED: lib/oban_powertools/lifeline/repair_preview.ex]
- Bridge coherence means shared auth/display seams and plain support-truth, not parity with native Powertools mutation behavior. [VERIFIED: 10-CONTEXT.md] [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex]

### Claude's Discretion
- Exact helper/module names for shared preview and operator-surface vocabulary, provided the contract stays durable, explicit, and reusable across pages.
- Exact field placement between existing preview rows and bounded metadata, provided the user-visible contract exposes `preview_token`, status, reason policy, before/after state, affected scope, and drift/expiry semantics.
- Exact UI composition, provided page-level read-only framing plus control-level disabled reasons remain the default posture.

### Deferred Ideas (OUT OF SCOPE)
- Full native replacement of Oban Web.
- Broad new mutation surface area or bridge-side writes.
- A new general RBAC framework.
- Phase 11 docs/compatibility proof work beyond the minimum support-truth needed to keep Phase 10 coherent.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HST-02 | An operator sees consistent permission, read-only, preview, reason, and audit behavior across the Powertools shell and any bridged operator flows. [VERIFIED: .planning/REQUIREMENTS.md] | The repo already has explicit auth/display seams from Phase 9, a rich durable preview model in Lifeline, disabled-with-explanation precedent in Cron, and a bounded read-only bridge adapter. Phase 10 should unify those into one operator contract instead of adding new seams. [VERIFIED: lib/oban_powertools/web/live_auth.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex] |
</phase_requirements>

## Summary

Phase 10 is a convergence phase, not an infrastructure phase. Phase 9 already froze the host-owned `auth_module` and `display_policy` seams and the thin read-only bridge adapter. The remaining gap is operator-facing behavior drift: cron still uses an ephemeral LiveView preview with page-local copy, lifeline has the durable preview and richer drift/consumed lifecycle, audit/workflows are read-only but do not yet participate in one shared mutation/read-only vocabulary, and the bridge is technically read-only without enough repo-local support-truth tying it back to native mutation ownership. [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] [VERIFIED: lib/oban_powertools/web/audit_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex]

The highest-value planning move is to treat Lifeline as the correctness pattern library and Cron as the main convergence target. Lifeline already proves durable preview rows, preview drift handling, preview consumption, reason validation, and inline audit continuity. Cron already proves page-level read-only access, disabled controls, and basic preview/confirm UX, but its preview state is not durable and its preview contract is much thinner. Phase 10 should move cron and future native mutation surfaces toward the same durable preview lifecycle and vocabulary, while preserving cron's lower-friction posture for low-risk actions. [VERIFIED: 10-CONTEXT.md] [VERIFIED: lib/oban_powertools/lifeline/repair_preview.ex] [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs] [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs]

The bridge work should stay narrow. `ObanPowertools.Web.ObanWebBridge.resolve_access/1` already returns `:read_only`, which is the correct Phase 10 posture. The missing work is not new bridge mutation plumbing; it is making the bridge's read-only status, shared display policy, and “use native pages for audited mutations” story explicit and testable wherever operators encounter the bridge. [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex] [VERIFIED: README.md] [VERIFIED: test/oban_powertools/web/router_test.exs]

## Current Gaps That Matter For Planning

### Gap 1: Cron preview is still ephemeral and thinner than the locked Phase 10 contract
- `CronLive` stores preview state only in socket assigns and calls `Cron.pause_entry/4`, `resume_entry/4`, and `run_now/4` directly on confirm. [VERIFIED: lib/oban_powertools/web/cron_live.ex]
- Lifeline already persists preview rows with token, status, before/after state, expiry, reason policy, and drift detection. [VERIFIED: lib/oban_powertools/lifeline/repair_preview.ex] [VERIFIED: lib/oban_powertools/lifeline.ex]
- The context explicitly says native operator mutations should use durable preview records rather than ephemeral LiveView assign state. [VERIFIED: 10-CONTEXT.md]

### Gap 2: Mutation vocabulary is still page-local instead of shared
- Cron hardcodes preview copy, unauthorized messages, and disabled-reason text locally. [VERIFIED: lib/oban_powertools/web/cron_live.ex]
- Lifeline hardcodes its own preview/error vocabulary locally. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]
- Audit and Workflows are read-only readers today, but they do not yet expose one shared operator vocabulary around read-only, audit provenance, and support-truth. [VERIFIED: lib/oban_powertools/web/audit_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex]

### Gap 3: Read-only coherence exists in pieces, not as one explicit surface contract
- Cron already renders disabled controls with inline permission explanations. [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs]
- Lifeline distinguishes previewable vs execute-capable states, but its page-level read-only framing and bridge support-truth do not yet define the cross-surface contract for all native pages. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]
- The bridge adapter enforces read-only technically, but repo-local docs and tests still focus more on route shape than on the operator-facing trust story for bridge use. [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex] [VERIFIED: README.md] [VERIFIED: test/oban_powertools/web/router_test.exs]

### Gap 4: Reason policy and preview-status semantics are not yet normalized across native surfaces
- Lifeline already enforces `reason_required`, `reason_too_short`, `preview_drifted`, and `preview_consumed`. [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: test/oban_powertools/web/live/lifeline_live_test.exs]
- Cron accepts an optional reason string but has no durable preview record, no preview expiry/drift lifecycle, and no shared status vocabulary. [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/cron.ex]
- The context locks the target status vocabulary to `ready`, `drifted`, `expired`, and `consumed`. [VERIFIED: 10-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Authorization and principal derivation | Host `auth_module` via `ObanPowertools.Auth` | `ObanPowertools.Web.LiveAuth` and bridge adapter | Phase 9 already froze this seam; Phase 10 should reuse it rather than widening it. [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: lib/oban_powertools/web/live_auth.ex] |
| Preview persistence and execute safety | Library-owned mutation services | Native LiveViews | Durability, drift handling, and atomic audit boundaries belong in services, not socket-only state. [VERIFIED: lib/oban_powertools/lifeline.ex] [VERIFIED: 10-CONTEXT.md] |
| Read-only and mutation vocabulary | Library-owned shared helpers/components | Individual LiveViews | One operator trust story should span cron, lifeline, workflows, audit, and bridge surfaces. [VERIFIED: 10-CONTEXT.md] |
| Display/redaction policy | Host `display_policy` | Shared render helpers plus bridge adapter | Phase 9 already froze this seam; Phase 10 should apply it consistently. [VERIFIED: lib/oban_powertools/runtime_config.ex] [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex] |
| Bridge support-truth | Powertools docs/router/adapter | Native pages linking into bridge | Bridge remains optional and read-only; native pages own audited mutations. [VERIFIED: README.md] [VERIFIED: lib/oban_powertools/web/router.ex] |

## Recommended Plan Slices

### Slice 1: Generalize the durable preview contract for native mutations
**Why first:** It is the main functional gap between cron and lifeline, and it underpins preview/status/reason/audit coherence.  
**Likely files:** `lib/oban_powertools/lifeline/repair_preview.ex`, `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/cron.ex`, `lib/oban_powertools/web/cron_live.ex`, selected tests.  
**Expected outcome:** one durable preview model and one explicit preview lifecycle that native mutation pages can share.

### Slice 2: Apply one operator-surface vocabulary across native pages
**Why second:** Once preview semantics are shared, the UI contract can converge without reintroducing page-local drift.  
**Likely files:** `lib/oban_powertools/web/cron_live.ex`, `lib/oban_powertools/web/lifeline_live.ex`, `lib/oban_powertools/web/audit_live.ex`, `lib/oban_powertools/web/workflows_live.ex`, and LiveView tests.  
**Expected outcome:** page-level read-only framing, control-level disabled reasons, preview/error statuses, and inline audit/provenance copy all follow one explicit vocabulary.

### Slice 3: Tighten bridge support-truth and read-only coherence
**Why third:** The bridge should reuse the converged native policy story instead of forcing Phase 10 to plan bridge work in parallel with core native behavior.  
**Likely files:** `lib/oban_powertools/web/oban_web_bridge.ex`, `README.md`, `test/oban_powertools/web/router_test.exs`, and a phase-local verification artifact after execution.  
**Expected outcome:** `/ops/jobs/oban` remains read-only, display-policy-consistent, and clearly labeled as the inspection surface while native pages retain audited mutation ownership.

## Validation Architecture

Focused ExUnit and LiveView tests remain the right verification posture. No browser E2E is required for this phase.

Recommended quick-run command:
`mix test test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/router_test.exs`

The minimum planning bar should prove:
- durable preview lifecycle works for both cron and lifeline,
- authorized-but-read-only viewers see disabled controls with inline explanations,
- preview/error status vocabulary is consistent across native surfaces,
- inline audit/provenance remains visible near acted-on resources,
- the bridge stays read-only and support-truthful.

## Anti-Patterns To Avoid

- Do not add a second host-owned policy seam for Phase 10; reuse Phase 9 auth/display contracts.
- Do not let cron keep ephemeral preview-only state while lifeline uses durable preview rows.
- Do not widen the bridge into generic writes or pretend it has full native mutation parity.
- Do not hide mutation controls entirely on viewable resources; disabled-with-explanation is the locked default.
- Do not move rich operator evidence into telemetry metadata.
- Do not split read-only, preview, reason, and audit vocabulary into page-specific copy without a shared contract.

## Research Conclusion

Phase 10 should be planned as a three-step convergence pass: first extract or generalize the durable preview contract from Lifeline so cron joins the same mutation-safety model, then unify native operator vocabulary and read-only/audit framing across pages, and only then tighten bridge support-truth around the already-read-only `/ops/jobs/oban` surface. That sequencing satisfies the locked context decisions without reopening Phase 9’s lower-level policy seams.

## RESEARCH COMPLETE
