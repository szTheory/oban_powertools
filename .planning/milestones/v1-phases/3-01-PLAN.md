---
phase: 3
plan: 01
type: execute
wave: 1
depends_on: ["Phase 2"]
files_modified: ["lib/mix/tasks/oban_powertools.install.ex", "test/mix/tasks/oban_powertools.install_test.exs", "test/support/migrations/2_phase_3_tables.exs", "lib/oban_powertools/workflow/workflow.ex", "lib/oban_powertools/workflow/step.ex", "lib/oban_powertools/workflow/edge.ex", "lib/oban_powertools/workflow/result.ex"]
autonomous: true
requirements: ["WF-01"]
must_haves:
  truths:
    - "Phase 3 has durable Postgres-backed workflow, step, edge, and result tables before any coordinator or UI logic exists."
    - "Logical graph definition stays separate from mutable runtime state and persisted result evidence."
    - "Stable step names, edge policies, dependency snapshots, and bounded result metadata are part of the stored contract."
  artifacts:
    - path: "lib/oban_powertools/workflow/workflow.ex"
      provides: "Top-level workflow schema"
      contains: "schema"
    - path: "lib/oban_powertools/workflow/edge.ex"
      provides: "Durable dependency-edge schema with terminal policy"
      contains: "policy"
    - path: "test/support/migrations/2_phase_3_tables.exs"
      provides: "Workflow persistence contract in the test harness"
      contains: "oban_powertools_workflows"
  key_links:
    - from: "Installer migrations"
      to: "Repo-backed workflow tests"
      via: "test/support/migrations/2_phase_3_tables.exs"
      pattern: "shared workflow persistence contract"
---

<objective>
Create the durable persistence contracts for Phase 3 workflows. This plan establishes the normalized graph and result storage boundary first so later builder, runtime, signaling, and UI plans can rely on one explicit Postgres source of truth.
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
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add Phase 3 Workflow Tables to Installer and Test Harness</name>
  <files>lib/mix/tasks/oban_powertools.install.ex, test/mix/tasks/oban_powertools.install_test.exs, test/support/migrations/2_phase_3_tables.exs</files>
  <behavior>
    - Installer emits additive workflow tables for definitions, steps, edges, and results.
    - Test support mirrors the same tables and indexes so repo-backed workflow services can be exercised locally.
    - The persisted contract encodes Postgres truth, stable step names, and no hidden in-memory execution state.
  </behavior>
  <action>
    Extend the installer and its source-contract test with Phase 3 workflow tables and indexes per D-01, D-02, D-05, D-10, D-34, D-35, D-36, and D-38.
    Add `test/support/migrations/2_phase_3_tables.exs` for `oban_powertools_workflows`, `oban_powertools_workflow_steps`, `oban_powertools_workflow_edges`, and `oban_powertools_workflow_results`, including unique indexes for workflow-local step names and edge identity.
    Persist only serializable worker/input/context metadata and bounded result evidence; do not introduce closures, opaque in-memory DAG blobs, or mutable shared context per D-16, D-17, D-18, D-37, D-45, and D-46.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs</automated>
  </verify>
  <done>The installer and test harness agree on the Phase 3 durable workflow schema contract.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Create Workflow, Step, Edge, and Result Schemas</name>
  <files>lib/oban_powertools/workflow/workflow.ex, lib/oban_powertools/workflow/step.ex, lib/oban_powertools/workflow/edge.ex, lib/oban_powertools/workflow/result.ex</files>
  <behavior>
    - Workflow rows hold logical definition plus runtime summary without collapsing the two concerns together.
    - Step rows carry stable step names, worker references, serializable input snapshots, workflow context metadata, and explicit runtime status fields.
    - Edge and result rows encode dependency policy, dependency snapshots, bounded result payload metadata, and operator-readable retention flags.
  </behavior>
  <action>
    Add Ecto schemas and changesets for workflow, step, edge, and result records following the Phase 2 persistence style per D-05, D-14, D-15, D-16, D-18, D-19, D-21, D-22, D-25, D-34, D-36, D-37, and D-38.
    Make terminal dependency policy explicit on edges with only `cancel` and `continue`, and include fields needed for later blocker snapshots and nested workflow links without adding public wait nodes or repair actions per D-12, D-13, D-21, D-22, D-42, and D-43.
    Keep names and fields operator-readable and compatible with later `Explain`, `Audit`, and LiveView consumption rather than packing semantics into `meta`-style catchalls.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs</automated>
    <manual>Schema behavior beyond compile-safe definition is intentionally exercised in Plan 3-02 via `test/oban_powertools/workflow_test.exs` once the public builder and insert path exist.</manual>
  </verify>
  <done>Phase 3 persistence models exist and encode the locked durable graph, result, and dependency-policy boundaries.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Application -> Database | Workflow durability and causality depend on explicit tables, constraints, and indexes in Postgres. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-3-01 | Tampering | workflow graph tables | mitigate | Constrain graph writes through explicit schemas, unique indexes, and later transactional APIs so duplicate names, orphan edges, and invalid policies cannot persist. |
| T-3-02 | Denial of Service | workflow results storage | mitigate | Store bounded result payload metadata with explicit retention/redaction fields instead of unbounded JSON blobs. |
| T-3-03 | Information Disclosure | workflow context and result rows | mitigate | Separate immutable workflow context from step outputs and keep sensitive/high-cardinality evidence in durable rows for auth-gated reads only. |
</threat_model>

<verification>
mix test test/mix/tasks/oban_powertools.install_test.exs
</verification>

<success_criteria>
The repo has test-backed persistence contracts for Phase 3 workflow graphs and results, and later plans can build on them without inventing storage structure ad hoc.
</success_criteria>

<output>
After completion, create `.planning/phases/3-01-SUMMARY.md`
</output>
