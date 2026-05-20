---
phase: 2
plan: 02
type: execute
wave: 2
depends_on: ["Phase 1", "Phase 2 Plan 01"]
files_modified: ["lib/oban_powertools/worker.ex", "lib/oban_powertools/limits.ex", "lib/oban_powertools/limits/resource.ex", "lib/oban_powertools/limits/state.ex", "test/oban_powertools/limits_test.exs", "test/oban_powertools/worker_test.exs"]
autonomous: true
requirements: ["ENG-01"]
must_haves:
  truths:
    - "Workers declare smart-engine participation explicitly via code-owned `limits:` bindings."
    - "Limiter reservation and cooldown logic uses durable Postgres-backed state and returns tagged results instead of hidden retries."
    - "Queued jobs preserve resolved limiter semantics through explicit binding snapshots."
  artifacts:
    - path: "lib/oban_powertools/limits.ex"
      provides: "Limiter reservation, release, and cooldown service"
      contains: "Ecto.Multi"
    - path: "lib/oban_powertools/worker.ex"
      provides: "Explicit `limits:` worker DSL"
      contains: "limits:"
  key_links:
    - from: "Worker limits metadata"
      to: "ObanPowertools.Limits"
      via: "explicit binding snapshot"
      pattern: "code-owned declarations + durable runtime state"
---

<objective>
Implement the explicit worker limits DSL and the durable limiter reservation engine. This plan covers the core ENG-01 mechanics before explanation, audit, cron, or UI layers consume them.
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
  <name>Task 1: Worker Limits DSL</name>
  <files>lib/oban_powertools/worker.ex, test/oban_powertools/worker_test.exs</files>
  <behavior>
    - `use ObanPowertools.Worker` accepts explicit `limits:` declarations.
    - Limits configuration is validated at compile time and remains grep-able in code.
    - Binding metadata needed by runtime reservation is exposed deterministically.
  </behavior>
  <action>
    Extend the worker macro to parse and validate `limits:` declarations alongside existing `args:`.
    Keep the API explicit and deterministic, with pure partition/weight callback contracts where needed.
    Add focused worker tests for valid and invalid smart-engine declarations.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/worker_test.exs</automated>
  </verify>
  <done>Workers can opt into smart-engine semantics explicitly and safely.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Durable Reservation and Cooldown Logic</name>
  <files>lib/oban_powertools/limits.ex, lib/oban_powertools/limits/resource.ex, lib/oban_powertools/limits/state.ex, test/oban_powertools/limits_test.exs</files>
  <behavior>
    - Reservation logic supports global and partitioned constraints plus manual cooldown.
    - Existing jobs preserve the meaning of resolved bindings through a durable snapshot.
    - Blocked outcomes are tagged, deterministic, and ready for later explain consumers.
  </behavior>
  <action>
    Build `ObanPowertools.Limits` around `Ecto.Multi` transactions for reservation, release, and cooldown behavior.
    Use durable state rows and explicit conflict handling instead of process-local coordination.
    Add repo-backed tests for global limits, partitioned limits, weight handling, and cooldown behavior.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/limits_test.exs</automated>
  </verify>
  <done>The limiter engine enforces durable global and partitioned throttling semantics.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Worker declarations -> Runtime state | Code-owned limit semantics must not drift silently once jobs are queued. |
| Application -> Database | Limiter state and binding snapshots are persisted in Postgres. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-2-03 | Integrity Drift | queued job limiter semantics | mitigate | Snapshot resolved limiter binding metadata onto jobs and validate declarations at compile time. |
| T-2-04 | Availability | limiter reservation path | mitigate | Use transactional reservation and deterministic conflict handling instead of hidden retries. |
</threat_model>

<verification>
mix test test/oban_powertools/limits_test.exs test/oban_powertools/worker_test.exs
</verification>

<success_criteria>
Workers can declare limits explicitly, and the limiter engine enforces durable global and partitioned constraints with deterministic blocked outcomes.
</success_criteria>

<output>
After completion, create `.planning/phases/2-02-SUMMARY.md`
</output>
