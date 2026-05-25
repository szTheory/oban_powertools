# Phase 27: Control Plane Vocabulary, Status Taxonomy & Ownership Contract - Research

**Researched:** 2026-05-25
**Domain:** shared operator vocabulary, native-versus-bridge ownership seams, cross-surface presenter extraction, and audit event contract normalization
**Confidence:** HIGH [VERIFIED: repo-local source review, live-view test inventory, installer/test migration inspection]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-04 to D-14:** Freeze one small shared operator-status layer (`needs_review`, `blocked`, `waiting`, `runnable`, `resolved`, `bridge_only`) above raw engine/domain states, and make that layer durable enough for later overview and drill-down work.
- **D-15 to D-21:** Keep the native-versus-bridge ownership contract explicit. Powertools-native pages own diagnosis, preview, reason, refusal, and audited mutations; `/ops/jobs/oban` remains a bounded Oban Web bridge.
- **D-22 to D-33:** Use diagnosis-first wording and venue-aware next-action copy. Do not let generic action-first copy or raw engine-state labels keep driving the UI.
- **D-34 to D-41:** Separate operator command vocabulary from durable audit event vocabulary. Move toward explicit `event_type`, typed principal/resource identity, and presenter-generated operator labels.
- **D-42 to D-44:** Centralize cross-surface copy/presentation and prove the new language through tests and docs, not ad hoc HEEx strings.

### Out of Scope
- Rebuilding the full generic Oban Web queue/job dashboard in native Powertools pages.
- Adding new machine-facing API or CLI control-plane contracts.
- Broadening mutation surface area beyond the bounded native actions already shipped.
</user_constraints>

## Summary

Phase 27 is a contract-and-seam phase, not a broad UI rewrite. The current repo already has the right architectural shape for a shared control plane: LiveAuth centralizes permission/refusal copy, ObanWebBridge already freezes the bridge as a read-only adapter, Explain already produces diagnosis-rich workflow/limiter stories, and the native LiveViews already express the strongest patterns in workflows and Lifeline. The problem is vocabulary drift and data-shape drift across those seams, not missing primitives. [CITED: lib/oban_powertools/web/live_auth.ex] [CITED: lib/oban_powertools/web/oban_web_bridge.ex] [CITED: lib/oban_powertools/explain.ex]

Today each native surface still invents its own primary labels:
- overview is count-first and still says `Smart Engine Overview`
- limiters render `Cooling Down`, `Blocked`, and `Runnable` as page-local state labels
- cron leads with raw paused/runnable state plus page-specific mutation wording
- workflows still surface raw workflow `state` as the main row label
- Lifeline already uses `Needs Review` and `Resolved`, but its wording is local to incidents
- audit still stores `action` and a single overloaded `resource` string, so the UI can only echo event rows instead of rendering one control-plane story

[CITED: lib/oban_powertools/web/engine_overview_live.ex] [CITED: lib/oban_powertools/web/limiters_live.ex] [CITED: lib/oban_powertools/web/cron_live.ex] [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: lib/oban_powertools/web/lifeline_live.ex] [CITED: lib/oban_powertools/web/audit_live.ex] [CITED: lib/oban_powertools/audit.ex]

The safest execution split is:
1. Freeze the shared machine-facing contract first: one status/ownership/venue vocabulary module plus an additive audit schema/read-model contract.
2. Extract shared presenters/helpers and rewire the existing native LiveViews to use them without widening page scope.
3. Update docs, docs-contract markers, and LiveView proof so the new control-plane language becomes a supported public promise before Phase 28 starts.

**Primary recommendation:** introduce one shared control-plane contract module and one shared presenter seam, normalize audit storage additively toward `event_type` plus structured resource identity, then re-render the existing pages through those seams before touching milestone-wide docs/proof.

## Repo Reality

### The current drift is concrete and surface-local

- `EngineOverviewLive` still leads with metric cards such as `Limiter Resources`, `Blocked Jobs`, and `Paused Cron Entries`, plus a `Smart Engine Overview` heading. This is incompatible with the Phase 27 goal of durable operator buckets and diagnosis-first handoffs. [CITED: lib/oban_powertools/web/engine_overview_live.ex]
- `LimitersLive` already has a useful diagnostic split between `Live Now` and `Snapshot at Block Start`, but its row state is still local-state wording (`Cooling Down`, `Blocked`, `Runnable`) instead of the shared status layer. [CITED: lib/oban_powertools/web/limiters_live.ex]
- `CronLive` and `LifelineLive` already share preview/reason/audit posture conceptually, but the copy is still embedded in page-local helpers and HEEx. [CITED: lib/oban_powertools/web/cron_live.ex] [CITED: lib/oban_powertools/web/lifeline_live.ex]
- `WorkflowsLive` already uses `Explain.workflow_story/3` and `Explain.step_story/2`, so it is the best proving ground for separating `operator_status`, `diagnosis`, and raw semantics cleanly. [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: lib/oban_powertools/explain.ex]

### The bridge contract is already honest and should be preserved

The router and bridge modules already say the right thing:
- host apps own the outer `/ops/jobs` scope
- native Powertools pages own audited mutations
- `/ops/jobs/oban` is a read-only Oban Web bridge

That means Phase 27 does not need a routing redesign. It needs the ownership labels and page copy to become reusable and explicit so downstream overview and drill-down work can point to the bridge without semantic drift. [CITED: lib/oban_powertools/web/router.ex] [CITED: lib/oban_powertools/web/oban_web_bridge.ex] [CITED: test/oban_powertools/web/router_test.exs]

### The audit contract is the main machine-facing gap

`ObanPowertools.Audit` still persists:
- `actor_id`
- `action`
- `resource`
- `metadata`

This is enough for current mutation evidence, but not enough for the Phase 27 contract. The context explicitly wants command vocabulary, durable event vocabulary, and operator-facing labels separated. The current schema overloads `action` and `resource`, while `AuditLive` can only render raw values back to the operator. An additive migration is justified here. [CITED: lib/oban_powertools/audit.ex] [CITED: lib/mix/tasks/oban_powertools.install.ex] [CITED: test/support/migrations/0_create_tables.exs]

## Architectural Responsibility Map

| Concern | Primary Artifact | Secondary Artifact | Rationale |
|---------|------------------|--------------------|-----------|
| Shared status / ownership / venue taxonomy | `lib/oban_powertools/control_plane.ex` | `test/oban_powertools/control_plane_test.exs` | A non-LiveView contract module keeps machine-facing vocabulary stable and reusable across overview, native pages, docs, and future drill-down work. |
| Shared native presentation and copy | `lib/oban_powertools/web/control_plane_presenter.ex` | `lib/oban_powertools/web/live_auth.ex` | Presenter and permission seams should own repeated labels/badges/copy instead of each LiveView embedding text directly. |
| Overview / native-surface rendering | `lib/oban_powertools/web/engine_overview_live.ex`, `limiters_live.ex`, `cron_live.ex`, `workflows_live.ex`, `lifeline_live.ex`, `audit_live.ex` | live-view tests under `test/oban_powertools/web/live/` | The existing native pages are the right surfaces to converge; no new page family is required in Phase 27. |
| Durable audit event contract | `lib/oban_powertools/audit.ex` | installer migration source + `test/support/migrations/*.exs` | The audit read model needs additive schema support for `event_type`, structured resource identity, and command/event separation. |
| Public support truth and docs contract | `README.md`, bridge/support-truth guides, `test/oban_powertools/docs_contract_test.exs` | `test/oban_powertools/web/router_test.exs` | Phase 27 changes product vocabulary; the docs and contract tests must freeze the new promise before Phase 28 uses it. |

## Standard Stack

No new external dependency is required. The repo already has the primitives needed for this phase.

### Core

| Tool / Artifact | Version | Purpose | Why Standard |
|-----------------|---------|---------|--------------|
| `ObanPowertools.Explain` | repo-local | diagnosis and blocker storytelling substrate | Already powers the strongest diagnosis-first surfaces and can feed a shared operator-status layer. |
| `ObanPowertools.Web.LiveAuth` | repo-local | shared permission, read-only, and audit-consequence copy seam | Already centralizes the native mutation posture and should be extended rather than bypassed. |
| LiveView tests under `test/oban_powertools/web/live/` | repo-local | cross-surface vocabulary proof | The repo already proves UI behavior here; Phase 27 should extend those tests instead of inventing separate snapshot tooling. |
| installer and test-support migrations | repo-local | additive audit-schema evolution | The repo’s host contract depends on keeping real installer migrations and test fixtures aligned. |

### Supporting

| Tool / Artifact | Purpose | When to Use |
|-----------------|---------|-------------|
| `README.md`, `guides/optional-oban-web-bridge.md`, `guides/support-truth-and-ownership-boundaries.md` | public ownership/support-truth markers | Update once the machine-facing and presentation contract is settled. |
| `test/oban_powertools/docs_contract_test.exs` | docs vocabulary enforcement | Use to freeze exact control-plane language and bridge posture markers. |
| `test/oban_powertools/web/router_test.exs` | bridge truth assertions | Use to keep native-versus-bridge routing semantics explicit after wording changes. |

## Recommended Execution Split

### Wave 1

- Create one shared `ObanPowertools.ControlPlane` contract module.
- Define the canonical statuses, ownerships, venue labels, and mapping helpers from existing domain rows/stories.
- Additive-normalize `ObanPowertools.Audit` toward `command_key`, `event_type`, `resource_type`, `resource_id`, and typed principal/resource helpers.
- Update installer and test-support migrations plus audit unit tests.

Reason: Phase 28 and the page rewires need a stable machine-facing contract first.

### Wave 2

- Create one shared presenter seam for operator badges, diagnosis/next-action copy, ownership copy, and audit row labels.
- Rewire overview, limiters, cron, workflows, Lifeline, audit, and LiveAuth to consume the shared contract.
- Keep raw engine/domain state visible as secondary proof, not primary row posture.

Reason: once the contract exists, the page rewires become focused view work rather than semantic invention.

### Wave 3

- Update README and bridge/support-truth guides to use the new vocabulary.
- Expand docs-contract and LiveView tests to prove the shared terms, bridge labels, read-only behavior, and audit metadata rendering.

Reason: public support truth must freeze before the milestone starts advertising the new overview and handoff model.

## Architecture Patterns

### Pattern 1: small shared operator layer over richer raw truth

**What:** expose one tiny durable status taxonomy while preserving raw state and diagnosis beneath it.

**Use here:** map limiter, cron, workflow, Lifeline, and audit surfaces onto the six approved operator statuses while keeping raw blocker codes, workflow semantics, and cron pause state visible as supporting truth.

### Pattern 2: additive audit normalization instead of destructive rewrite

**What:** keep current event writing viable while adding better fields and read helpers.

**Use here:** add `event_type` and structured resource identity to the audit schema, keep compatibility shims for existing `action`/`resource` callers during the phase, and make operator labels presenter-derived.

### Pattern 3: presenter registry over HEEx string drift

**What:** centralize labels, badges, and venue/ownership copy in one seam consumed by every LiveView.

**Use here:** extract ownership badges (`Powertools-native`, `Oban Web bridge`), operator status badge labels, audit event labels, and venue-aware next-action copy from the existing page-local text fragments.

## Anti-Patterns To Avoid

- Replacing raw engine/domain truth with only friendly labels.
- Treating `bridge_only` like an error/severity state instead of an ownership/venue state.
- Rebuilding the bridge or generic job UI instead of labeling it honestly.
- Letting each LiveView keep local text helpers after introducing a shared presenter seam.
- Reusing `action` as the only durable audit truth once `event_type` and `command_key` exist.
- Updating docs before the code/test contract is stable.

## Validation Architecture

### Verification style

- Pure-module tests for the new control-plane contract and audit helpers.
- LiveView tests proving shared labels and venue/ownership wording across overview, cron, workflows, Lifeline, audit, and limiters.
- Docs-contract assertions for the new native-control-plane and bridge markers.
- Router proof to keep the bounded bridge posture honest.

### Approval criteria

- One shared control-plane module owns the approved status taxonomy and ownership vocabulary.
- Native pages render shared operator status and ownership copy through one presenter seam.
- Audit events expose additive structured identity and durable `event_type` semantics.
- Public docs and tests use the same native-versus-bridge vocabulary as the pages.
- No plan widens scope into a native generic queue/job dashboard rebuild.

