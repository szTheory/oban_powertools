# Phase 27: Control Plane Vocabulary, Status Taxonomy & Ownership Contract - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 19
**Analogs found:** 19 / 19

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/control_plane.ex` | shared machine-facing status/ownership contract | domain row/story -> operator status/ownership/venue contract | `lib/oban_powertools/explain.ex` | medium |
| `test/oban_powertools/control_plane_test.exs` | pure contract proof | mapping rules -> stable contract assertions | `test/oban_powertools/explain_test.exs` | strong |
| `lib/oban_powertools/audit.ex` | additive audit schema/read-model normalization | mutation event -> durable event_type/resource identity -> UI reader helpers | existing `Audit` module | strong |
| `lib/mix/tasks/oban_powertools.install.ex` | installer migration truth | host install -> audit schema columns/indexes | existing audit table migration block | strong |
| `test/support/migrations/0_create_tables.exs` | test schema truth | test repo bootstrap -> audit schema parity | existing audit table migration | strong |
| `lib/oban_powertools/web/control_plane_presenter.ex` | shared UI labels/badges/copy | contract -> page labels/badges/next-action strings | `RuntimeConfig` display helpers + page-local copy helpers | medium |
| `lib/oban_powertools/web/live_auth.ex` | shared permission/ownership wording | auth outcome -> native mutation posture copy | existing `LiveAuth` maps | strong |
| `lib/oban_powertools/web/engine_overview_live.ex` | overview bucket rewrite | shared contract -> triage-first cards/links | current overview cards | medium |
| `lib/oban_powertools/web/limiters_live.ex` | limiter status/diagnosis mapping | limiter state + snapshots -> shared status + diagnosis | current Live Now / Snapshot split | strong |
| `lib/oban_powertools/web/cron_live.ex` | cron vocabulary alignment | cron entry + preview state -> shared status/action wording | existing preview flow | strong |
| `lib/oban_powertools/web/workflows_live.ex` | workflow operator-status alignment | workflow/step stories -> shared status + diagnosis | current `Explain.workflow_story/3` integration | strong |
| `lib/oban_powertools/web/lifeline_live.ex` | native mutation venue truth | incident rows + preview state -> shared ownership/audit wording | current `Needs Review` / `Resolved` UI | strong |
| `lib/oban_powertools/web/audit_live.ex` | shared audit rendering | event row -> presenter label + resource link identity | current audit table | strong |
| `lib/oban_powertools/web/oban_web_bridge.ex` | bridge ownership marker | bridge read-only access -> bounded bridge wording | current bridge moduledoc/resolver | strong |
| `test/oban_powertools/web/live/limiters_live_test.exs` | limiter proof | UI render -> shared labels | current limiter LiveView test | strong |
| `test/oban_powertools/web/live/workflows_live_test.exs` | workflow proof | UI render -> shared labels + venue wording | current workflow LiveView test | strong |
| `test/oban_powertools/web/live/cron_live_test.exs` | preview/mutation wording proof | preview flow -> shared audited action language | current cron LiveView test | strong |
| `test/oban_powertools/web/live/lifeline_live_test.exs` | incident/mutation wording proof | incident review -> shared status and audit language | current Lifeline LiveView test | strong |
| `test/oban_powertools/web/live/audit_live_test.exs` | audit destination proof | event render -> shared ownership/audit language | current audit LiveView test | strong |

## Pattern Assignments

### Shared domain contract should stay pure and additive

**Pattern:** keep the status/ownership taxonomy in a non-LiveView module so it is reusable by pages, audit readers, docs, and later roadmap phases.

**Planning takeaway:** create `lib/oban_powertools/control_plane.ex` as a pure contract module with status constants, ownership/venue helpers, and mapping functions from limiter, cron, workflow, Lifeline, and bridge contexts.

### Existing diagnosis seams are better than rewriting underlying domain logic

**Pattern:** reuse `Explain.workflow_story/3`, `Explain.step_story/2`, limiter blocker snapshots, and existing preview metadata rather than inventing a second diagnosis engine.

**Planning takeaway:** Phase 27 should translate existing diagnoses into shared operator status and wording, not replace the underlying workflow/limiter/Lifeline reasoning paths.

### LiveAuth is the right place for shared native mutation posture

**Pattern:** permission/refusal copy already centralizes in `LiveAuth`.

**Planning takeaway:** move shared ownership badges, audited-action wording, and page read-only copy toward `LiveAuth` plus a new presenter seam instead of duplicating strings in cron/Lifeline/audit.

### Audit normalization must update both installer truth and test schema truth

**Pattern:** host contract changes always require real installer migration source plus test-support migration parity.

**Planning takeaway:** any additive `event_type` / structured-resource change must touch `lib/mix/tasks/oban_powertools.install.ex` and `test/support/migrations/0_create_tables.exs`, not only the schema module.

### Docs-contract assertions are the public support-truth lock

**Pattern:** the repo already treats docs markers as merge-blocking contract proof.

**Planning takeaway:** Phase 27 documentation work should add exact vocabulary markers to `README.md`, bridge/support-truth guides, and `test/oban_powertools/docs_contract_test.exs` instead of relying on prose-only review.

## Implementation Notes

- Prefer additive audit evolution: keep compatibility paths for current `action` / `resource` callers while introducing `event_type`, `command_key`, `resource_type`, and `resource_id`.
- Keep `bridge_only` as an ownership/venue outcome; do not use it as a red/failure state on pages.
- Preserve raw workflow semantics, cron pause state, limiter blocker codes, and Lifeline incident evidence underneath the shared operator-status layer.
- Reuse the existing LiveView tests as the canonical proof seam for vocabulary changes rather than creating separate fixture-only assertions.

