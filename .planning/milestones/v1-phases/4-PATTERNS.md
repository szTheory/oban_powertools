# Phase 4: Lifeline & Repair Center - Pattern Map

**Mapped:** 2026-05-19  
**Files analyzed:** 14  
**Analogs found:** 12 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/lifeline.ex` | service | CRUD | `lib/oban_powertools/cron.ex` + `lib/oban_powertools/explain.ex` | role-match |
| `lib/oban_powertools/lifeline/heartbeat.ex` | model | event-driven | `lib/oban_powertools/cron/slot.ex` | partial |
| `lib/oban_powertools/lifeline/incident.ex` | model | CRUD | `lib/oban_powertools/explain.ex` | partial |
| `lib/oban_powertools/lifeline/repair_preview.ex` | model | CRUD | `lib/oban_powertools/audit.ex` | partial |
| `lib/oban_powertools/lifeline/archive_run.ex` | model | CRUD | `lib/oban_powertools/cron/entry.ex` | partial |
| `lib/oban_powertools/application.ex` | config | event-driven | `lib/oban_powertools/application.ex` | exact |
| `lib/oban_powertools/audit.ex` | utility | CRUD | `lib/oban_powertools/audit.ex` | exact |
| `lib/oban_powertools/telemetry.ex` | utility | event-driven | `lib/oban_powertools/telemetry.ex` | exact |
| `lib/oban_powertools/web/router.ex` | route | request-response | `lib/oban_powertools/web/router.ex` | exact |
| `lib/oban_powertools/web/engine_overview_live.ex` | component | request-response | `lib/oban_powertools/web/engine_overview_live.ex` | exact |
| `lib/oban_powertools/web/lifeline_live.ex` | component | request-response | `lib/oban_powertools/web/cron_live.ex` + `lib/oban_powertools/web/workflows_live.ex` | role-match |
| `lib/oban_powertools/web/audit_live.ex` | component | request-response | `lib/oban_powertools/web/audit_live.ex` | exact |
| `test/support/migrations/3_phase_4_tables.exs` | migration | CRUD | `test/support/migrations/2_phase_3_tables.exs` | exact |
| `test/oban_powertools/lifeline_test.exs` | test | CRUD | `test/oban_powertools/cron_test.exs` + `test/oban_powertools/workflow_runtime_test.exs` | role-match |
| `test/oban_powertools/web/live/lifeline_live_test.exs` | test | request-response | `test/oban_powertools/web/live/cron_live_test.exs` + `test/oban_powertools/web/live/workflows_live_test.exs` | role-match |

## Existing Modules Most Likely To Change

- `lib/mix/tasks/oban_powertools.install.ex` for Phase 4 tables in the installer contract.
- `lib/oban_powertools/application.ex` for supervised heartbeat/lifeline processes.
- `lib/oban_powertools/audit.ex` for richer repair/archive metadata reads if needed.
- `lib/oban_powertools/telemetry.ex` for `lifeline`, `repair`, and `archive` event wrappers.
- `lib/oban_powertools/web/router.ex` for `/ops/jobs/lifeline`.
- `lib/oban_powertools/web/engine_overview_live.ex` for lifeline metrics and operator entry points.
- `lib/oban_powertools/web/audit_live.ex` for richer action/resource/reason rendering if Phase 4 exposes intervention history inline.

## Pattern Assignments

### `lib/oban_powertools/lifeline.ex` for preview-first mutation orchestration

**Analogs:** `lib/oban_powertools/cron.ex`, `lib/oban_powertools/explain.ex`

- Use the `Cron` shape for explicit public functions and `Ecto.Multi` transactions.
- Use the `Explain` posture for snapshot-aware evidence that can compare “what was seen then” versus “what is true now”.
- Return tagged tuples such as `{:ok, preview}`, `{:error, :preview_drifted}`, `{:error, :heartbeat_late}`, or `{:error, :unauthorized}` rather than exceptions.

### `heartbeat`, `incident`, `repair_preview`, and `archive_run` schemas for durable operational evidence

**Analogs:** `lib/oban_powertools/cron/entry.ex`, `lib/oban_powertools/cron/slot.ex`, `lib/oban_powertools/audit.ex`, `lib/oban_powertools/explain.ex`

- Use `binary_id` primary keys and explicit timestamps like the cron/workflow tables.
- Prefer explicit fields for incident class, health state, plan hash, affected counts, and retention status over vague catch-all metadata.
- Keep high-cardinality details in DB rows, not telemetry labels.

### `application.ex` for opt-in supervised liveness services

**Analog:** `lib/oban_powertools/application.ex`

- Add small lifecycle children the same way PubSub and the workflow coordinator were introduced.
- Keep supervision conditional on module availability and avoid making the app fail just because LiveView or optional runtime pieces are absent.

### `telemetry.ex` for low-cardinality event wrappers

**Analog:** `lib/oban_powertools/telemetry.ex`

- Add narrow wrappers like `execute_lifeline_event/3` and `execute_repair_event/3`.
- Keep metadata coarse: action, incident class, queue, health state, archive outcome.

### `lifeline_live.ex` for evidence-first native operator UX

**Analogs:** `lib/oban_powertools/web/cron_live.ex`, `lib/oban_powertools/web/workflows_live.ex`

- Use `CronLive` for preview-first controls, auth gating, and reason capture.
- Use `WorkflowsLive` for master/detail layout, selection stability, and detail drill-down.
- Keep generic job inspection as an Oban Web deep link rather than duplicating job internals.

### `lifeline_test.exs` and `lifeline_live_test.exs` for repo-style verification

**Analogs:** `test/oban_powertools/cron_test.exs`, `test/oban_powertools/workflow_runtime_test.exs`, `test/oban_powertools/web/live/cron_live_test.exs`, `test/oban_powertools/web/live/workflows_live_test.exs`

- Use repo-backed tests to validate persisted previews, drift rejection, audit writes, and archive-before-delete guarantees.
- Use LiveView tests to validate authorization, incident rendering, preview gating, reason-required execution, and drifted-preview UX.
