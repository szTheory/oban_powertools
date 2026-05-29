---
phase: 3
plan: 04
type: execute
wave: 4
depends_on: ["Phase 3 Plan 03"]
files_modified: ["lib/oban_powertools/application.ex", "lib/oban_powertools/workflow/coordinator.ex", "lib/oban_powertools/workflow/signal.ex", "lib/oban_powertools/workflow/runtime.ex", "lib/oban_powertools/audit.ex", "lib/oban_powertools/telemetry.ex", "test/oban_powertools/workflow_coordinator_test.exs", "test/oban_powertools/telemetry_test.exs"]
autonomous: true
requirements: ["WF-02"]
must_haves:
  truths:
    - "Workflow progression converges correctly from durable DB state even if PubSub delivery is delayed or lost."
    - "PubSub accelerates child release and workflow completion notifications without becoming the source of truth."
    - "Workflow lifecycle transitions emit normalized audit rows and low-cardinality telemetry."
  artifacts:
    - path: "lib/oban_powertools/workflow/coordinator.ex"
      provides: "Thin supervised coordinator for workflow event acceleration"
      contains: "GenServer"
    - path: "lib/oban_powertools/workflow/signal.ex"
      provides: "Internal workflow event vocabulary and topic helpers"
      contains: "step_completed"
    - path: "test/oban_powertools/workflow_coordinator_test.exs"
      provides: "DB-first signaling tests"
      contains: "PubSub"
  key_links:
    - from: "runtime transition"
      to: "coordinator fan-out"
      via: "post-commit workflow signal publication"
      pattern: "persist -> audit/telemetry -> broadcast"
---

<objective>
Layer PubSub acceleration, supervision, and lifecycle visibility onto the durable runtime. This plan keeps the coordinator thin and idempotent while wiring the audit and telemetry posture needed for operator trust.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/STATE.md
@.planning/phases/3-CONTEXT.md
@.planning/phases/3-RESEARCH.md
@.planning/phases/3-PATTERNS.md
@lib/oban_powertools/application.ex
@lib/oban_powertools/telemetry.ex
@lib/oban_powertools/audit.ex
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add the Workflow Coordinator, Signal Vocabulary, and Supervisor Wiring</name>
  <files>lib/oban_powertools/application.ex, lib/oban_powertools/workflow/coordinator.ex, lib/oban_powertools/workflow/signal.ex, lib/oban_powertools/workflow/runtime.ex, test/oban_powertools/workflow_coordinator_test.exs</files>
  <behavior>
    - Runtime transitions publish structured internal workflow signals only after durable state changes commit.
    - A supervised coordinator subscribes to workflow topics and re-checks runnable children idempotently.
    - DB reconciliation remains sufficient for correctness even if PubSub messages are dropped or duplicated.
  </behavior>
  <action>
    Add a thin coordinator under `ObanPowertools.Supervisor` and a dedicated internal signal vocabulary covering `step_completed`, `step_unblocked`, and `workflow_completed` per D-09, D-10, D-11, and D-34.
    Publish workflow signals as post-commit hints from the runtime layer, and keep coordinator work limited to idempotent re-checks or fast fan-out instead of owning workflow truth in memory per D-09, D-10, D-11, and D-45.
    Write integration tests that prove duplicate or missing PubSub delivery does not create duplicate child release, that no external signal waits are exposed, and that already-running descendants are not retroactively mutated by initial terminal propagation per D-12, D-13, D-26, and D-42.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/workflow_coordinator_test.exs -x</automated>
  </verify>
  <done>Workflow signaling is PubSub-accelerated, supervised, and still correct when the database is the only reliable source of truth.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Wire Workflow Audit Rows and Low-Cardinality Telemetry</name>
  <files>lib/oban_powertools/audit.ex, lib/oban_powertools/telemetry.ex, lib/oban_powertools/workflow/runtime.ex, lib/oban_powertools/workflow/coordinator.ex, test/oban_powertools/workflow_coordinator_test.exs, test/oban_powertools/telemetry_test.exs</files>
  <behavior>
    - Material workflow lifecycle transitions write normalized audit rows keyed by workflow or workflow-step resource ids.
    - Telemetry events emit coarse labels only and leave high-cardinality evidence in durable tables.
    - Audit and telemetry assertions cover inserted, unblocked, completed, and cascade-cancelled flows.
  </behavior>
  <action>
    Extend `ObanPowertools.Audit` and `ObanPowertools.Telemetry` with workflow lifecycle helpers per D-39, D-40, and D-41, using resource strings such as `workflow:<id>` and `workflow_step:<id>` rather than step names in metric labels.
    Record workflow lifecycle events that materially change operator understanding, including insertion, unblocking, completion, and cascade-cancel decisions, while keeping metadata low-cardinality on telemetry and full-causality in durable rows per D-25, D-39, D-40, and D-41.
    Add tests that attach telemetry handlers and assert audit rows alongside coordinator-driven runtime behavior, preserving the repo’s existing audit-plus-telemetry verification posture.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/telemetry_test.exs -x</automated>
  </verify>
  <done>Workflow transitions now produce normalized audit evidence and low-cardinality telemetry without leaking high-cardinality workflow labels.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Database -> PubSub -> Coordinator | PubSub can accelerate progression, but it cannot be trusted as the authoritative workflow state boundary. |
| Runtime -> Audit/Telemetry | Lifecycle visibility must preserve operator evidence while keeping metrics safe and bounded. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-3-10 | Tampering | PubSub-driven child release | mitigate | Broadcast only after commit and have the coordinator re-read durable state before acting so duplicate or lost messages cannot corrupt workflow progression. |
| T-3-11 | Repudiation | workflow lifecycle evidence | mitigate | Record normalized audit rows for material workflow transitions and assert them in runtime/coordinator tests. |
| T-3-12 | Information Disclosure | workflow telemetry | mitigate | Emit low-cardinality telemetry labels only and store high-cardinality workflow evidence in workflow/result/audit tables. |
</threat_model>

<verification>
mix test test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/telemetry_test.exs -x
</verification>

<success_criteria>
Workflow signaling is accelerated by a thin coordinator, remains DB-correct without PubSub guarantees, and surfaces audit plus telemetry evidence that matches the project’s existing operational posture.
</success_criteria>

<output>
After completion, create `.planning/phases/3-04-SUMMARY.md`
</output>
