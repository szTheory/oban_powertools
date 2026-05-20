---
phase: 3
plan: 02
type: execute
wave: 2
depends_on: ["Phase 3 Plan 01"]
files_modified: ["lib/oban_powertools/workflow.ex", "lib/oban_powertools/workflow/workflow.ex", "lib/oban_powertools/workflow/step.ex", "lib/oban_powertools/workflow/edge.ex", "test/oban_powertools/workflow_test.exs", "test/support/workflow_fixtures.ex"]
autonomous: true
requirements: ["WF-01"]
must_haves:
  truths:
    - "Developers can author workflows through an explicit builder pipeline instead of macro sugar or raw maps."
    - "Workflow insertion validates duplicate names, missing dependencies, orphan edges, and cycles before any rows are written."
    - "Raw workflow structs and builder-authored workflows converge through one normalization path."
  artifacts:
    - path: "lib/oban_powertools/workflow.ex"
      provides: "Public builder and insert API"
      contains: "def insert"
    - path: "test/oban_powertools/workflow_test.exs"
      provides: "Builder normalization and insertion tests"
      contains: "rejects cycles"
    - path: "test/support/workflow_fixtures.ex"
      provides: "Canonical DAG fixtures for later runtime and UI tests"
      contains: "workflow_fixture"
  key_links:
    - from: "Workflow.new/add/connect/insert"
      to: "workflow tables"
      via: "single normalization and insert path"
      pattern: "builder facade over persisted graph"
---

<objective>
Expose the Phase 3 authoring surface and insertion path. This plan turns the durable workflow tables into a public, validation-first API that matches the locked builder posture and gives later runtime work a stable contract.
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
@lib/oban_powertools/idempotency.ex
@lib/oban_powertools/cron.ex
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Build the Explicit Workflow Builder and Normalization Path</name>
  <files>lib/oban_powertools/workflow.ex, test/oban_powertools/workflow_test.exs, test/support/workflow_fixtures.ex</files>
  <behavior>
    - `Workflow.new/1 |> add/3 |> add_many/3 |> connect/3 |> insert/2` is the primary public authoring surface.
    - Builder-authored graphs and raw structs normalize through one validation path.
    - Stable step names and explicit dependency declarations are enforced before persistence.
  </behavior>
  <action>
    Implement the public builder API in `ObanPowertools.Workflow` per D-03, D-04, D-06, D-07, and D-36, following the explicit validation posture already used by `ObanPowertools.Worker`.
    Add shared workflow fixtures and test-first coverage for duplicate step names, missing dependencies, orphan edges, self-loops, cycle rejection, and the prohibition on macro DSL or raw map headline APIs per D-02, D-05, D-07, D-35, and D-45.
    Keep workflow steps as normal Powertools/Oban workers with serializable args and metadata snapshots; do not invent a separate workflow-only worker abstraction per D-08 and D-37.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/workflow_test.exs -x</automated>
  </verify>
  <done>The builder API is the paved-road authoring surface and rejects invalid graph definitions before persistence.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Persist Normalized Workflow Graphs Through One Insert Transaction</name>
  <files>lib/oban_powertools/workflow.ex, lib/oban_powertools/workflow/workflow.ex, lib/oban_powertools/workflow/step.ex, lib/oban_powertools/workflow/edge.ex, test/oban_powertools/workflow_test.exs</files>
  <behavior>
    - Insert writes normalized workflow, step, and edge rows in one transactional path.
    - Runtime state fields initialize explicitly without mutating the logical graph definition contract.
    - Nested workflow linkage and workflow-context metadata remain serializable, immutable, and operator-visible.
  </behavior>
  <action>
    Add the insert transaction and normalization helpers so builder and raw-struct inputs persist through one path per D-05, D-06, D-16, D-17, D-34, and D-38.
    Snapshot stable worker/input metadata and immutable workflow context at insert time, but keep result passing explicit by step-name references rather than recursive payload composition per D-14, D-15, D-16, D-17, and D-36.
    Extend tests to assert inserted rows, initial runtime summary values, stable ordering keys for later UI layout, and the absence of public signal-wait or repair semantics per D-11, D-12, D-13, D-42, and D-43.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/workflow_test.exs -x</automated>
  </verify>
  <done>Workflow definitions persist as normalized rows through one explicit insert contract that later runtime code can trust.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Developer API -> Workflow persistence | Untrusted workflow definitions must be normalized and validated before durable insert. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-3-04 | Tampering | builder insert path | mitigate | Validate duplicate names, dependency existence, cycles, and serializable worker/input metadata before any insert transaction runs. |
| T-3-05 | Repudiation | workflow contract semantics | mitigate | Make stable step names and explicit dependency declarations durable so later explain/audit flows can refer to fixed identifiers. |
| T-3-06 | Elevation of Privilege | workflow authoring surface | accept | This phase only exposes library APIs, not operator mutations; risk stays limited to application code paths using explicit builder contracts. |
</threat_model>

<verification>
mix test test/oban_powertools/workflow_test.exs -x
</verification>

<success_criteria>
Developers can author persisted DAG workflows through one explicit, test-backed builder and insert path that matches the locked public API direction.
</success_criteria>

<output>
After completion, create `.planning/phases/3-02-SUMMARY.md`
</output>
