---
phase: 4
plan: 04
type: execute
wave: 4
depends_on: ["Phase 4 Plan 01", "Phase 4 Plan 03"]
files_modified: ["lib/oban_powertools/lifeline.ex", "lib/oban_powertools/telemetry.ex", "lib/oban_powertools/application.ex", "test/oban_powertools/lifeline_test.exs", "test/oban_powertools/telemetry_test.exs"]
autonomous: true
requirements: ["LIF-03", "LIF-04"]
must_haves:
  truths:
    - "Archive-before-delete applies only to evidence-bearing records, not raw heartbeat spam."
    - "Archive/prune operations are explicit public APIs with telemetry and audit visibility, not ad hoc SQL."
    - "Deletion of archive-required source rows happens only after archive writes succeed."
  artifacts:
    - path: "lib/oban_powertools/lifeline.ex"
      provides: "Archive/prune orchestration API"
      contains: "Run Archive + Prune Now"
    - path: "test/oban_powertools/lifeline_test.exs"
      provides: "Archive-before-delete and retention tests"
      contains: "archived_at"
    - path: "test/oban_powertools/telemetry_test.exs"
      provides: "Low-cardinality archive telemetry coverage"
      contains: "archive"
---

<objective>
Implement Phase 4 retention and evidence cleanup. This plan adds archive-before-delete behavior, explicit archive/prune runs, and low-cardinality visibility for keeping operational tables lean without losing intervention evidence.
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
@lib/oban_powertools/application.ex
@lib/oban_powertools/telemetry.ex
@lib/oban_powertools/audit.ex
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add Archive-Before-Delete Retention Services</name>
  <files>lib/oban_powertools/lifeline.ex, lib/oban_powertools/application.ex, test/oban_powertools/lifeline_test.exs</files>
  <behavior>
    - Archive/prune runs explicitly classify source rows by retention class before deciding whether to archive or delete.
    - Raw heartbeat samples remain short-lived hot data and are pruned without durable archival in Phase 4.
    - Repair-touched or manually intervened workflow/job evidence is archived before any source-row deletion occurs.
  </behavior>
  <action>
    Implement explicit retention APIs and any supervised scheduler hook needed for archive/prune runs, using small batches and persisted run records rather than one-off SQL.
    Encode the locked Phase 4 retention posture: short heartbeat retention, disposable preview drafts, hot audit history, and longer-lived archived manual-intervention evidence.
    Add repo-backed tests proving archive-required rows are written to durable archive storage before deletion, failed archive writes block deletion, and heartbeat rows are pruned as ephemeral operational samples instead of being archived.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/lifeline_test.exs</automated>
  </verify>
  <done>Archive-before-delete behavior exists and protects evidence-bearing records while keeping hot tables lean.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Emit Retention Telemetry and Read Models for Operator Visibility</name>
  <files>lib/oban_powertools/lifeline.ex, lib/oban_powertools/telemetry.ex, test/oban_powertools/lifeline_test.exs, test/oban_powertools/telemetry_test.exs</files>
  <behavior>
    - Archive/prune runs emit low-cardinality telemetry about action, class, and outcome.
    - The backend exposes read models for last run time, counts, and archive/prune freshness that the UI can display without editing policies.
    - Manual archive/prune previews can later reuse the same evidence-first contract as repair actions.
  </behavior>
  <action>
    Add telemetry wrappers and backend read functions for archive/prune freshness, affected counts, and recent outcomes, keeping metadata coarse and excluding executor ids, job ids, and workflow ids from labels.
    Extend tests to assert telemetry event names and metadata shape for successful archive, blocked deletion, and prune-only heartbeat cleanup paths.
    Keep UI-facing read models read-only in this plan; policy editing remains out of scope for Phase 4.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/telemetry_test.exs</automated>
  </verify>
  <done>The retention engine is measurable and exposes the read models the native lifeline page needs.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Retention engine -> Source rows | Deletion decisions must depend on successful archive writes for evidence-bearing classes. |
| Retention telemetry -> Operators | Visibility must stay low-cardinality and trustworthy without leaking high-cardinality evidence into metrics. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-4-10 | Data Loss | archive/prune run | mitigate | Block source-row deletion unless durable archive writes succeed for archive-required classes. |
| T-4-11 | Denial of Service | retention jobs | mitigate | Use small batches and explicit run records instead of giant delete sweeps. |
| T-4-12 | Information Disclosure | telemetry labels | mitigate | Emit only coarse retention metadata such as class, action, and outcome. |
</threat_model>

<verification>
mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/telemetry_test.exs
</verification>

<success_criteria>
The repo can archive and prune Phase 4 evidence safely, with test-backed guarantees that durable evidence is preserved before deletion and operators can see retention freshness.
</success_criteria>

<output>
After completion, create `.planning/phases/4-04-SUMMARY.md`
</output>
