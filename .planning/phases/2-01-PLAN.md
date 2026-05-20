---
phase: 2
plan: 01
type: execute
wave: 1
depends_on: ["Phase 1"]
files_modified: ["lib/mix/tasks/oban_powertools.install.ex", "test/mix/tasks/oban_powertools.install_test.exs", "test/support/migrations/0_create_tables.exs", "lib/oban_powertools/limits/resource.ex", "lib/oban_powertools/limits/state.ex", "lib/oban_powertools/cron/entry.ex", "lib/oban_powertools/cron/slot.ex"]
autonomous: true
requirements: ["ENG-01", "ENG-03"]
must_haves:
  truths:
    - "Phase 2 has durable Postgres-backed tables for limiter resources, limiter state, cron entries, cron slots, and blocker snapshots."
    - "Stable resource definitions remain separate from mutable runtime state."
    - "Cron slot uniqueness is expressed through durable entry/slot keys rather than implicit in-memory checks."
  artifacts:
    - path: "lib/oban_powertools/limits/resource.ex"
      provides: "Named limiter resource schema"
      contains: "schema"
    - path: "lib/oban_powertools/cron/slot.ex"
      provides: "Durable cron slot ledger schema"
      contains: "schema"
  key_links:
    - from: "Installer migrations"
      to: "Repo-backed tests"
      via: "test/support/migrations/0_create_tables.exs"
      pattern: "shared persistence contract"
---

<objective>
Create the durable persistence contracts required by the smart-engine subsystem. This plan establishes the schema foundation for limiter resources/state, cron entries/slots, and blocker evidence without yet implementing the higher-level orchestration logic.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/2-CONTEXT.md
@.planning/phases/2-RESEARCH.md
@.planning/phases/2-VALIDATION.md
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Installer Migrations and Test-Harness Tables</name>
  <files>lib/mix/tasks/oban_powertools.install.ex, test/mix/tasks/oban_powertools.install_test.exs, test/support/migrations/0_create_tables.exs</files>
  <behavior>
    - Installer generates additive Phase 2 smart-engine tables.
    - Test support mirrors those tables so repo-backed services can be exercised locally.
    - Table names and indexes make the resource/state split explicit.
  </behavior>
  <action>
    Extend the installer with migration bodies for limiter resources, limiter state, cron entries, cron slots, and blocker snapshots.
    Mirror those tables in the test support migration file.
    Strengthen installer source-contract tests so future changes cannot silently alter the persistence contract.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs</automated>
  </verify>
  <done>The installer and test harness agree on the Phase 2 database contract.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Ecto Schemas for Resources, State, Entries, and Slots</name>
  <files>lib/oban_powertools/limits/resource.ex, lib/oban_powertools/limits/state.ex, lib/oban_powertools/cron/entry.ex, lib/oban_powertools/cron/slot.ex</files>
  <behavior>
    - Named limiter resources and mutable limiter state are distinct schemas.
    - Cron entries carry source ownership, overlap policy, catch-up policy, timezone, and pause state.
    - Cron slots model durable claim state by entry and slot timestamp.
  </behavior>
  <action>
    Add schema modules and changesets for limiter resources, limiter state, cron entries, and cron slots.
    Keep field names explicit, operator-readable, and ready for later audit/explain reuse.
    Follow the `Receipt` schema conventions already used in `ObanPowertools.Idempotency`.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs</automated>
  </verify>
  <done>Phase 2 persistence models exist and align with the locked durable resource/state split.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Application -> Database | Smart-engine durability depends on correct schema design and indexing in Postgres. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-2-01 | Tampering | smart-engine tables | mitigate | Use explicit schemas, indexes, and later transactional writers to constrain how state changes occur. |
| T-2-02 | Denial of Service | cron slot ledger | mitigate | Enforce durable uniqueness and indexes on entry/slot keys so replay and duplicate scheduling remain bounded. |
</threat_model>

<verification>
mix test test/mix/tasks/oban_powertools.install_test.exs
</verification>

<success_criteria>
The repo has durable, test-backed persistence contracts for Phase 2 smart-engine state, and later plans can build on them without inventing table structure ad hoc.
</success_criteria>

<output>
After completion, create `.planning/phases/2-01-SUMMARY.md`
</output>
