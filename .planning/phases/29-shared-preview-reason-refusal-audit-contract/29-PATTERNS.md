# Phase 29: Shared Preview, Reason, Refusal & Audit Contract - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/cron.ex` | cron preview/reason policy normalization | action request -> shared preview metadata -> audit event | existing cron preview/execute pipeline | strong |
| `lib/oban_powertools/lifeline.ex` | repair preview/reason policy normalization | intervention request -> shared preview metadata -> audit event | existing Lifeline preview/execute pipeline | strong |
| `lib/oban_powertools/workflow/runtime.ex` | workflow refusal/reason evidence normalization | workflow legality -> structured refusal/reason facts | existing workflow rejection/runtime helpers | strong |
| `lib/oban_powertools/web/control_plane_presenter.ex` | shared preview/refusal/audit wording seam | machine truth -> operator copy -> venue-aware next step | existing presenter seam | strong |
| `lib/oban_powertools/web/live_auth.ex` | permission and mutation error normalization | auth/error key -> human-first refusal contract | existing `LiveAuth` maps | strong |
| `lib/oban_powertools/web/cron_live.ex` | concise native mutation surface | preview metadata -> shared copy -> recent audit continuity | current cron preview card | strong |
| `lib/oban_powertools/web/lifeline_live.ex` | rich native execution venue | preview metadata + incident context -> shared copy + local audit continuity | current Lifeline review panel | strong |
| `lib/oban_powertools/web/workflows_live.ex` | workflow-directed handoff surface | rejection/handoff facts -> human-first guidance -> Lifeline path | existing workflow story + Lifeline handoff | strong |
| `lib/oban_powertools/audit.ex` | canonical event/resource identity | event write -> normalized labels + follow-up metadata | existing audit schema/reader helpers | strong |
| `lib/oban_powertools/web/audit_live.ex` | query-backed global audit destination | URL filters -> scoped event list -> follow-up links | current audit table/filter UI | medium |
| `test/oban_powertools/cron_test.exs` | cron domain proof | optional reason + preview/audit semantics | existing cron execution tests | strong |
| `test/oban_powertools/lifeline_test.exs` | Lifeline domain proof | required reason + preview/audit semantics | existing Lifeline execution tests | strong |
| `test/oban_powertools/web/live/cron_live_test.exs` | cron surface proof | rendered preview/refusal copy -> consistent contract | existing cron LiveView test | strong |
| `test/oban_powertools/web/live/lifeline_live_test.exs` | Lifeline surface proof | preview/refusal/audit continuity -> consistent contract | existing Lifeline LiveView test | strong |
| `test/oban_powertools/web/live/workflows_live_test.exs` / `audit_live_test.exs` | workflow handoff and audit destination proof | rendered refusal/handoff/filter links -> consistent contract | existing workflow/audit LiveView tests | strong |

## Pattern Assignments

### One durable preview primitive should stay shared

**Pattern:** cron and Lifeline already use the same preview substrate (`RepairPreview`, token, expiry, drift, consume, audit coupling).

**Planning takeaway:** Phase 29 should converge naming, policy metadata, and copy around that shared primitive instead of branching by surface family.

### `LiveAuth` plus presenter is the right normalization seam

**Pattern:** permission/read-only and mutation error categories already centralize in `LiveAuth`, while native-versus-bridge vocabulary and audit labels already centralize in `ControlPlanePresenter`.

**Planning takeaway:** put refusal formatting and venue-aware next-step wording into those seams rather than duplicating more HEEx-specific copy helpers in cron, Lifeline, or workflows.

### Workflow pages already prove the bounded handoff model

**Pattern:** `WorkflowsLive` already diagnoses workflow causality and links into Lifeline for bounded intervention.

**Planning takeaway:** normalize the wording and refusal story there, but keep execution in Lifeline; do not create a second native execution venue.

### Audit identity fields are already present; query ownership is the missing seam

**Pattern:** audit events already persist `event_type`, `command_key`, `resource_type`, and `resource_id`, and `AuditLive` already parses URL filters.

**Planning takeaway:** move filtering and follow-up-link generation toward one query-backed/read-model path rather than relying on in-memory filtering and page-local link assembly.

### Local audit continuity is already the right UI shape

**Pattern:** cron and Lifeline already keep recent event evidence close to the acted-on resource or incident.

**Planning takeaway:** preserve that bounded recent slice, but make its labels and “go deeper” links consume the same event/resource contract as `/ops/jobs/audit`.

## Implementation Notes

- Prefer one explicit action-policy helper over a new host-facing DSL.
- Keep reason field visibility universal across native previews even when requiredness differs.
- Keep preview tokens and draft reason state off URLs.
- Use resource identity first and incident/workflow correlation second when generating audit follow-up links.
- Prefer Powertools-native destinations for follow-up when Powertools owns the diagnosis surface; only use the Oban Web bridge for true `bridge_only` inspection.
