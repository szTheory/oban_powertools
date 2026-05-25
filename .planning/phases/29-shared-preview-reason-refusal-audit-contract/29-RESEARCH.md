# Phase 29: Shared Preview, Reason, Refusal & Audit Contract - Research

**Researched:** 2026-05-25
**Domain:** shared native mutation policy, preview lifecycle normalization, reason-policy enforcement, workflow handoff wording, and audit follow-up coherence
**Confidence:** HIGH [VERIFIED: repo-local source review, existing test inventory, active Phase 27/28 artifacts]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-04 to D-11:** keep one canonical preview lifecycle across cron, Lifeline, and workflow-directed actions: `ready`, `drifted`, `expired`, `consumed`; keep preview storage, drift checks, consume semantics, and audit coupling shared and server-authoritative; keep preview state off URLs.
- **D-12 to D-19:** reason policy is action-owned, not page-owned; every native preview shows a visible reason field; low-risk cron controls stay optional while Lifeline and workflow-directed interventions stay required with shared server-side validation.
- **D-20 to D-27:** machine refusal keys remain stable but operator copy should normalize around `outcome -> concise reason -> legal next move -> venue`; workflow pages must not lead with raw refusal codes; wording ownership should move toward a shared presenter/read-model seam rather than more `LiveAuth` string drift.
- **D-28 to D-40:** audit stays read-only, recent/local on acted-on pages, and globally explorable through `/ops/jobs/audit`; one normalized audit event/read-model seam should support local continuity and global rendering; follow-up links should prefer Powertools-native destinations and use query-backed filters.
- **D-41 to D-43:** stay boring and explicit: context functions own durable truth, `Ecto.Multi` owns correctness boundaries, LiveViews stay thin, URL state owns durable selection only, and presenter/read-model seams own operator copy.

### Deferred Ideas
- New mutation families or a native queue/job mutation console.
- A broad i18n/copy platform.
- A second audit projection store or analytics/history product.
</user_constraints>

<phase_requirements>
## Phase Requirements

Requirement descriptions are copied from `.planning/REQUIREMENTS.md`.

| ID | Description | Research Support |
|----|-------------|------------------|
| ACT-01 | Preview status, reason requirements, disabled-action/refusal wording, and audit consequence copy are consistent across every bounded native mutation surface. | Reuse the existing preview/audit primitives, but centralize status copy, reason policy metadata, and refusal formatting instead of leaving them embedded in cron and Lifeline. |
| ACT-02 | Workflow-directed actions, Lifeline repairs, and cron mutations all present one shared policy story for what can happen next, why an action is unavailable, and where durable evidence will land. | Keep Lifeline as the execution venue for workflow-directed interventions, but normalize the handoff wording and refusal semantics around one contract. |
| ACT-03 | The audit destination can be read as part of the same control plane, with resource links and event metadata that match the shared operator vocabulary used on native pages. | Push audit filtering and link generation through one shared read-model/presenter seam; avoid page-local string assembly and in-memory filter drift. |
</phase_requirements>

## Summary

Phase 29 is a contract-convergence phase, not a new capability phase. The repo already has the hard primitives: cron and Lifeline both use durable previews with consume/drift/expiry semantics; workflow runtime already records refusal evidence and operator reasons; audit already stores `command_key`, `event_type`, `resource_type`, and `resource_id`; and the Phase 27 presenter/auth seams already define the shared control-plane vocabulary. The remaining gap is that each surface still tells the mutation story differently. [CITED: lib/oban_powertools/cron.ex] [CITED: lib/oban_powertools/lifeline.ex] [CITED: lib/oban_powertools/workflow/runtime.ex] [CITED: lib/oban_powertools/audit.ex] [CITED: lib/oban_powertools/web/control_plane_presenter.ex] [CITED: lib/oban_powertools/web/live_auth.ex]

The safest split is:
1. normalize preview status, reason policy metadata, refusal copy shape, and audit-consequence wording across cron and Lifeline without changing mutation scope;
2. apply the same contract to workflow-directed handoffs and remaining bounded native entrypoints so operators see one policy story before they reach Lifeline;
3. finish on the audit read side by making local continuity panels, audit rows, and follow-up links tell the same resource/event story through query-backed filters and shared labels.

**Primary recommendation:** add one small shared action-policy seam for preview status, reason policy, and refusal normalization; keep domain validation server-side in cron/Lifeline/runtime; extend `ControlPlanePresenter` for operator copy and follow-up links; and move audit filtering/linking toward one shared read-model contract instead of more per-LiveView branching. [CITED: .planning/phases/29-shared-preview-reason-refusal-audit-contract/29-CONTEXT.md] [CITED: lib/oban_powertools/web/cron_live.ex] [CITED: lib/oban_powertools/web/lifeline_live.ex] [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: lib/oban_powertools/web/audit_live.ex]

## Repo Reality

### The preview primitive is already shared, but the presentation contract is not

- `Cron.preview_entry_action/4` and `Lifeline.preview_repair/4` both use `RepairPreview`, `plan_hash`, `preview_token`, `expires_at`, consume semantics, drift detection, and audit writes. That means Phase 29 should unify naming and rendering around the existing primitive instead of inventing a second preview system. [CITED: lib/oban_powertools/cron.ex] [CITED: lib/oban_powertools/lifeline.ex]
- Cron currently renders preview summary, actor, action, resource, intended effect, audit consequence, preview status, preview token, rendered reason, and recent audit in one concise card. Lifeline renders richer before/after diagnosis plus preview status, preview token, reason, and local audit events. The shape is conceptually shared but not contractually shared yet. [CITED: lib/oban_powertools/web/cron_live.ex] [CITED: lib/oban_powertools/web/lifeline_live.ex]

### Reason requiredness is already server-side, but duplicated by surface family

- Cron validates optional reasons for pause/resume/run-now through `validate_reason/2` and stores trimmed reason text in preview metadata/audit rows when present. [CITED: lib/oban_powertools/cron.ex]
- Lifeline validates required reasons with the same basic rules, but the enforcement sits in a separate module with separate UX copy. Workflow-directed interventions also persist reasons in runtime transitions and already carry rejection/hand-off evidence, so the missing piece is a shared action-owned reason policy table and shared presenter wording. [CITED: lib/oban_powertools/lifeline.ex] [CITED: lib/oban_powertools/workflow/runtime.ex]

### Refusal normalization is the biggest operator-copy gap

- `LiveAuth` already centralizes permission/read-only and preview failure categories, but its output is still largely a map of surface-local strings. [CITED: lib/oban_powertools/web/live_auth.ex]
- `WorkflowsLive` still leads with raw `rejection_summary.code` alongside the message, and its Lifeline handoff copy is hard-coded in the page. That conflicts with the Phase 29 rule that operators should see a human summary first and machine codes second. [CITED: lib/oban_powertools/web/workflows_live.ex]
- Cron and Lifeline each interpret preview-state failures (`preview_drifted`, `preview_expired`, `preview_consumed`, invalid reason, unauthorized) locally. A shared refusal formatter should turn those durable keys into one explicit next-step story. [CITED: lib/oban_powertools/web/cron_live.ex] [CITED: lib/oban_powertools/web/lifeline_live.ex] [CITED: lib/oban_powertools/web/live_auth.ex]

### Audit already has the right storage fields, but the read side still drifts

- `ObanPowertools.Audit` now exposes `command_key`, `event_type`, `resource_type`, and `resource_id`, and `ControlPlanePresenter` already delegates event/resource labels there. [CITED: lib/oban_powertools/audit.ex] [CITED: lib/oban_powertools/web/control_plane_presenter.ex]
- `AuditLive` accepts `resource_type`, `resource_id`, and `event_type` params, but the filtering path shown in the current module still checks matches in-process rather than making query-backed filter composition the durable seam. That is exactly the kind of drift the context forbids. [CITED: lib/oban_powertools/web/audit_live.ex]
- Cron and Lifeline already render recent local audit evidence beside the acted-on resource. The missing contract is one normalized event label + destination-link story shared by local panels and `/ops/jobs/audit`. [CITED: lib/oban_powertools/web/cron_live.ex] [CITED: lib/oban_powertools/web/lifeline_live.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Preview lifecycle and reason policy truth | Backend/context layer (`cron.ex`, `lifeline.ex`, `workflow/runtime.ex`) | LiveView only renders derived facts | Requiredness, drift, consume, and audit coupling must stay server-authoritative. |
| Shared refusal wording and venue-aware next steps | Presenter/auth seam (`control_plane_presenter.ex`, `live_auth.ex`) | LiveView displays formatted outcomes | Keeps durable machine keys stable while converging operator language. |
| Workflow-directed action handoff story | `workflows_live.ex` + Lifeline selection contract | Lifeline remains execution venue | Phase 29 should normalize the policy story without moving execution out of Lifeline. |
| Local audit continuity and global audit linking | Audit read model + presenter helpers | Surface-specific panels | One event/read-model contract should drive both the local “what just happened” slice and the global destination. |
| Global audit filtering | Audit query helper / LiveView data loader | URL param ownership | Context requires router-backed filters executed in Ecto, not `Enum.filter` drift. |

## Standard Stack

No new dependency is required. The repo-local Phoenix, LiveView, Ecto, preview, runtime, and audit seams are sufficient.

### Core

| Artifact | Purpose | Why Standard |
|----------|---------|--------------|
| `ObanPowertools.Lifeline.RepairPreview` and preview consumers | shared durable preview substrate | Already provides token, drift, expiry, consume, and audit-coupled semantics for the mutation posture. |
| `ObanPowertools.Web.LiveAuth` | permission and mutation error categories | Already owns stable refusal categories and read-only posture. |
| `ObanPowertools.Web.ControlPlanePresenter` | shared control-plane labels | Already owns native/bridge vocabulary and audit labels; best place to extend operator mutation copy. |
| `ObanPowertools.Audit` | normalized event/resource contract | Already stores durable identity fields Phase 29 needs on the read side. |
| `ObanPowertools.LiveCase` and LiveView tests | hermetic proof lane | Existing tests already cover cron, Lifeline, workflows, and audit surfaces. |

### Supporting

| Artifact | Purpose | When to Use |
|----------|---------|-------------|
| `lib/oban_powertools/web/workflows_live.ex` | workflow handoff/refusal normalization | Use to prove human-first refusal copy and venue-aware next moves. |
| `test/oban_powertools/cron_test.exs`, `lifeline_test.exs` | domain reason/audit contract proof | Use for server-side validation and audit field assertions. |
| `test/oban_powertools/web/live/*.exs` | cross-surface copy and continuity proof | Use to verify the shared policy story under read-only and preview-state transitions. |

## Recommended Execution Split

### Wave 1

- Introduce one shared action-policy seam for preview status labels, reason-policy metadata, and refusal normalization inputs.
- Rewire cron and Lifeline to consume the shared contract for reason field visibility, preview state wording, refusal copy, and audit-consequence text.
- Extend domain tests so cron and Lifeline prove the same durable reason/audit semantics.

Reason: cron and Lifeline are the two native execution surfaces; once their policy story is coherent, downstream workflow handoffs have a stable target.

### Wave 2

- Normalize workflow-directed handoff cards, refusal summaries, and any other bounded native entrypoints around the same contract.
- Keep workflow execution in Lifeline, but make workflow pages explain legality, refusal, next move, and audit venue with the same wording structure as cron/Lifeline.
- Prove this via workflow and Lifeline LiveView tests under read-only and refusal-state cases.

Reason: the workflow surface owns diagnosis and handoff language, not execution. Phase 29 must converge language without widening venue scope.

### Wave 3

- Normalize audit event labels, resource labels, local continuity panels, and global follow-up links around one query-backed filter/link contract.
- Extend `AuditLive` and any local audit slices so they prefer native destinations when Powertools owns the diagnosis surface and fall back to explicit bridge-only posture when it does not.
- Add verification for filter URLs, resource continuity, and acted-on-resource missing cases.

Reason: audit coherence should land after the mutation surfaces and workflow handoffs define the contract the audit surface needs to reflect.

## Architecture Patterns

### Pattern 1: one policy contract, multiple risk-shaped surfaces

**What:** share machine truth and wording shape across surfaces while allowing concise cron cards and richer Lifeline cards.

**Use here:** unify preview lifecycle, reason requiredness, refusal classes, and audit consequence copy without forcing every surface into the same markup density.

### Pattern 2: action-owned reason policy over page-owned form rules

**What:** expose one explicit `reason_policy_for(action)` or equivalent metadata seam close to the domain action boundary.

**Use here:** cron pause/resume/run-now stay optional; Lifeline repair and workflow-directed operator interventions stay required with minimum specificity; LiveViews render from the same metadata but validation remains server-side.

### Pattern 3: durable refusal keys, presenter-owned operator copy

**What:** preserve canonical machine keys (`preview_drifted`, `reason_required`, workflow rejection codes) while rendering human-first outcome summaries and next moves centrally.

**Use here:** use `LiveAuth` and `ControlPlanePresenter` as the formatting seam instead of proliferating HEEx strings or translating keys ad hoc in each LiveView.

### Pattern 4: one audit event/read-model seam for local and global continuity

**What:** local panels and the global audit page consume the same event/resource identity contract and follow-up-link helpers.

**Use here:** use `resource_type`, `resource_id`, `event_type`, and `command_key` to drive both page-local continuity slices and `/ops/jobs/audit` filter URLs.

## Anti-Patterns To Avoid

- Splitting preview lifecycle semantics by surface family.
- Requiring filler reasons for low-risk cron actions.
- Leading workflow UI with raw refusal codes or backend atoms.
- Pushing operator wording down into domain services.
- Reusing in-memory audit filtering once query-backed filters are available.
- Turning local audit continuity panels into full history feeds.
- Expanding Phase 29 into a new generic job/queue mutation venue.

## Validation Architecture

### Verification style

- Domain tests for shared reason-policy enforcement and audit metadata on cron/Lifeline/workflow mutation paths.
- LiveView tests for preview-state copy, refusal wording, workflow handoff messaging, read-only posture, and audit continuity.
- Query/filter verification for audit URLs and acted-on resource follow-up.
- Grepable checks to keep preview internals off URLs and raw refusal-first copy out of workflow/LiveAuth surfaces.

### Approval criteria

- Preview lifecycle wording is coherent across cron, Lifeline, and workflow-directed handoffs.
- Reason visibility and requiredness follow action-owned policy, not page-local drift.
- Refusal copy always tells the operator what happened, why, what legal next move exists, and where it belongs.
- Local and global audit views use the same event/resource identity story and URL-backed follow-up filters.
- No plan widens scope into new mutation families, a new execution venue, or an audit analytics product.
