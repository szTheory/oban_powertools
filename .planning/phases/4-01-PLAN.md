---
phase: 4
plan: 01
type: execute
wave: 1
depends_on: ["Phase 3"]
files_modified: ["lib/mix/tasks/oban_powertools.install.ex", "test/mix/tasks/oban_powertools.install_test.exs", "test/support/migrations/3_phase_4_tables.exs", "lib/oban_powertools/lifeline/heartbeat.ex", "lib/oban_powertools/lifeline/incident.ex", "lib/oban_powertools/lifeline/repair_preview.ex", "lib/oban_powertools/lifeline/archive_run.ex"]
autonomous: true
requirements: ["LIF-01", "LIF-02", "LIF-03", "LIF-04"]
must_haves:
  truths:
    - "Phase 4 introduces durable Postgres-backed contracts for executor heartbeats, incident evidence, repair previews, and archive/prune evidence before any runtime or UI logic relies on them."
    - "The installer and test harness share one explicit schema contract so later lifeline, repair, and retention code do not invent storage ad hoc."
    - "Preview drift, operator auditability, and archive-before-delete all have first-class persisted fields rather than being inferred from LiveView state or opaque metadata."
  artifacts:
    - path: "test/support/migrations/3_phase_4_tables.exs"
      provides: "Phase 4 persistence contract for repo-backed tests"
      contains: "oban_powertools_heartbeats"
    - path: "lib/mix/tasks/oban_powertools.install.ex"
      provides: "Host installer support for all new Phase 4 tables"
      contains: "oban_powertools_repair_previews"
    - path: "lib/oban_powertools/lifeline/repair_preview.ex"
      provides: "Durable preview schema with fingerprint/hash fields"
      contains: "plan_hash"
  key_links:
    - from: "Installer migrations"
      to: "Repo-backed test migrations"
      via: "test/support/migrations/3_phase_4_tables.exs"
      pattern: "shared Phase 4 persistence contract"
---

<objective>
Create the durable Phase 4 persistence boundary first. This plan adds the heartbeat, incident, repair preview, and archive evidence tables plus their Ecto schemas so every later repair or retention action has one explicit source of truth.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/STATE.md
@.planning/phases/4-CONTEXT.md
@.planning/phases/4-RESEARCH.md
@.planning/phases/4-PATTERNS.md
@lib/mix/tasks/oban_powertools.install.ex
@test/support/migrations/2_phase_3_tables.exs
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add Phase 4 Tables to Installer and Test Harness</name>
  <files>lib/mix/tasks/oban_powertools.install.ex, test/mix/tasks/oban_powertools.install_test.exs, test/support/migrations/3_phase_4_tables.exs</files>
  <behavior>
    - Installer emits additive Phase 4 tables for heartbeats, incidents, repair previews, archive runs, and archived repair evidence.
    - Repo-backed tests can migrate the same schema locally without depending on a generated host app.
    - The schema encodes executor identity, drift fingerprints, actor/audit linkage, and archive-before-delete state explicitly.
  </behavior>
  <action>
    Extend the installer and its source-contract tests with Phase 4 tables per D-04 through D-09, D-15 through D-18, D-25 through D-32, and D-34 through D-45.
    Add `test/support/migrations/3_phase_4_tables.exs` with explicit tables for `oban_powertools_heartbeats`, `oban_powertools_lifeline_incidents`, `oban_powertools_repair_previews`, `oban_powertools_archive_runs`, and `oban_powertools_repair_archives`, including indexes on health state, incident class, preview drift fields, and prune/archive timestamps.
    Keep the contract evidence-first: heartbeat rows store stable `executor_id` and liveness timestamps, preview rows store `incident_fingerprint` and `plan_hash`, and archive rows store enough immutable summary data to prove archive-before-delete occurred.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs</automated>
  </verify>
  <done>The installer and test harness agree on the full Phase 4 persistence contract.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Create Phase 4 Heartbeat, Incident, Preview, and Archive Schemas</name>
  <files>lib/oban_powertools/lifeline/heartbeat.ex, lib/oban_powertools/lifeline/incident.ex, lib/oban_powertools/lifeline/repair_preview.ex, lib/oban_powertools/lifeline/archive_run.ex</files>
  <behavior>
    - Heartbeat rows model durable executor liveness with coarse health classification inputs.
    - Incident rows distinguish `dead_executor` and `workflow_stuck` evidence from the repair targets they may later produce.
    - Repair preview and archive rows encode drift, reason/audit linkage, and evidence retention without relying on generic `%{}` blobs alone.
  </behavior>
  <action>
    Add Ecto schemas and changesets for the new Phase 4 records following the explicit contract style used by cron and workflow persistence.
    Make preview/audit/archive fields operator-readable and drift-friendly: include `incident_class`, `incident_fingerprint`, `plan_hash`, `health_state`, `affected_counts`, `executed_at`, and `archived_at` instead of burying those semantics in one opaque metadata map.
    Preserve room for later approval workflows without implementing them now, and do not add broad workflow-graph mutation or per-worker retention editing semantics in this phase.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs</automated>
    <manual>Runtime behavior is intentionally exercised in Plans 4-02 through 4-04 once services exist.</manual>
  </verify>
  <done>Phase 4 persistence models exist and encode the locked liveness, preview, and archive evidence boundaries.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Application -> Database | Phase 4 safety depends on explicit durable evidence for liveness, repair previews, and archive-before-delete. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-4-01 | Tampering | repair preview rows | mitigate | Persist fingerprint and plan-hash fields so later execute paths can reject drift instead of trusting stale client state. |
| T-4-02 | Repudiation | archive/repair evidence | mitigate | Encode actor, timestamps, and immutable evidence linkage in Phase 4 tables before mutation services exist. |
| T-4-03 | Information Disclosure | archived evidence | mitigate | Keep high-cardinality evidence in auth-gated durable rows and avoid pushing ids into telemetry labels. |
</threat_model>

<verification>
mix test test/mix/tasks/oban_powertools.install_test.exs
</verification>

<success_criteria>
The repo has test-backed Phase 4 tables and schemas for lifeline, repair preview, and archive evidence, and later plans can rely on them without inventing storage structure.
</success_criteria>

<output>
After completion, create `.planning/phases/4-01-SUMMARY.md`
</output>
