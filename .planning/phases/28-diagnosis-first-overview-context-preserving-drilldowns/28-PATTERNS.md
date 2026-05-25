# Phase 28: Diagnosis-First Overview & Context-Preserving Drilldowns - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 14
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/web/overview_read_model.ex` | shared overview bucket/query seam | durable truth -> triage buckets -> venue-aware cards | `lib/oban_powertools/explain.ex` | medium |
| `lib/oban_powertools/web/engine_overview_live.ex` | overview surface rewrite | overview buckets -> diagnosis cards -> destination CTAs | existing `EngineOverviewLive` | medium |
| `lib/oban_powertools/web/control_plane_presenter.ex` | shared venue/ownership/CTA wording | status + ownership -> visible labels and posture copy | existing presenter module | strong |
| `test/oban_powertools/web/live/engine_overview_live_test.exs` | new overview proof lane | rendered HTML -> bucket, diagnosis, venue, CTA assertions | `test/oban_powertools/web/live/workflows_live_test.exs` | medium |
| `lib/oban_powertools/web/limiters_live.ex` | native param-backed detail selection | query param -> selected limiter -> remount-safe detail panel | `lib/oban_powertools/web/workflows_live.ex` | strong |
| `test/oban_powertools/web/live/limiters_live_test.exs` | limiter continuity proof | URL param -> rendered selected resource | existing limiter live test | strong |
| `lib/oban_powertools/web/lifeline_live.ex` | patch-friendly row/view continuity | click/toggle -> URL patch -> durable row/view selection | existing `LifelineLive` workflow handoff path | strong |
| `test/oban_powertools/web/live/lifeline_live_test.exs` | Lifeline remount/read-only proof | URL param -> selected row survives preview/read-only/remount | existing Lifeline live test | strong |
| `lib/oban_powertools/web/cron_live.ex` | optional selected-entry drilldown contract | query param -> selected cron row without preview state | `WorkflowsLive` selection + current cron preview flow | medium |
| `test/oban_powertools/web/live/cron_live_test.exs` | cron handoff proof | selected entry param -> same previewable row rendered after remount | existing cron live test | medium |
| `lib/oban_powertools/web/audit_live.ex` | filtered audit destination | query param -> scoped event/resource filter | current audit table + workflows detail posture | medium |
| `test/oban_powertools/web/live/audit_live_test.exs` | scoped audit proof | URL filter -> matching resource/event remains visible | existing audit live test | strong |
| `lib/oban_powertools/web/router.ex` | route ownership contract | native routes + bounded bridge remain explicit | existing router module | strong |
| `test/oban_powertools/web/router_test.exs` | bridge ownership proof | route exposure -> native vs bridge truth | existing router test | strong |

## Pattern Assignments

### Workflows is the canonical URL-owned detail pattern

**Pattern:** router-owned `navigate` across LiveViews, `handle_params/3` for detail restoration, and `patch` for in-page selection changes.

**Planning takeaway:** reuse the `WorkflowsLive` model for every native Phase 28 destination that promises exact focused context, especially limiters and Lifeline.

### Lifeline already has the right selectors but not consistent URL patching

**Pattern:** `LifelineLive` can already rebuild state from `view`, `row-id`, `incident_fingerprint`, `workflow_id`, `step`, and `action` params.

**Planning takeaway:** Phase 28 should patch those params on selection and view toggles instead of only mutating assigns, so refresh/remount/read-only sessions preserve context.

### Overview needs a read model, not more template logic

**Pattern:** current overview cards are direct metrics with hard-coded labels and static links.

**Planning takeaway:** introduce one bounded read-model seam that returns status, diagnosis, exemplars, venue, ownership, and destination metadata in one contract before rewriting HEEx.

### Bridge follow-up must stay explicit and filtered, not fake-native

**Pattern:** the bridge is already mounted as a separate bounded inspection venue under `/ops/jobs/oban`.

**Planning takeaway:** overview and exemplar handoffs may link to bridge pages or filtered generic-job destinations, but plans must never promise unsupported native detail restoration for bridge-owned follow-up.

### LiveView tests are the canonical proof seam

**Pattern:** current repo web proof uses `ObanPowertools.LiveCase` plus rendered HTML assertions for auth, read-only posture, preview flows, and route continuity.

**Planning takeaway:** add a new overview test file and extend existing LiveView tests rather than introducing browser automation or snapshot tooling.

## Implementation Notes

- Prefer `?resource=<name>` for limiter selection because it is durable, human-readable, and already matches the resource identity shown in the UI.
- Preserve the existing workflow route shape `/ops/jobs/workflows/:id?step=...`; do not replace it with a flatter query-only contract.
- Keep preview tokens, reason text, and execute-state out of query params on cron and Lifeline.
- Scope audit filters to durable identifiers such as `resource_type`, `resource_id`, `event_type`, or `view=resolved`; avoid fuzzy search or non-deterministic "recent" filters in Phase 28.
