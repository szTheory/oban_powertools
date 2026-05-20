---
phase: 3
plan: 03
type: execute
wave: 3
depends_on: ["Phase 3 Plan 02"]
files_modified: ["lib/oban_powertools/workflow.ex", "lib/oban_powertools/workflow/runtime.ex", "lib/oban_powertools/workflow/result.ex", "lib/oban_powertools/explain.ex", "test/oban_powertools/workflow_runtime_test.exs", "test/oban_powertools/explain_test.exs"]
autonomous: true
requirements: ["WF-01", "WF-02"]
must_haves:
  truths:
    - "Completing a workflow step records explicit result evidence and re-evaluates dependent steps through durable state transitions."
    - "Retryable upstream work keeps dependents blocked, while terminal non-success outcomes cascade to queued descendants by default."
    - "Blocked or cancelled child steps carry preserved dependency snapshots that explain exact causality."
  artifacts:
    - path: "lib/oban_powertools/workflow/runtime.ex"
      provides: "DB-backed step completion and dependency release engine"
      contains: "complete_step"
    - path: "lib/oban_powertools/explain.ex"
      provides: "Workflow blocker and snapshot explanation contract"
      contains: "snapshot_at_block_start"
    - path: "test/oban_powertools/workflow_runtime_test.exs"
      provides: "Runtime progression and cascade-policy tests"
      contains: "cascade"
  key_links:
    - from: "step completion"
      to: "child release and blocker snapshots"
      via: "single runtime transaction"
      pattern: "persist first, then signal later"
---

<objective>
Implement the durable runtime semantics for workflows. This plan makes step completion, result persistence, blocker explanations, and terminal dependency propagation explicit in Postgres before any PubSub acceleration is added.
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
@lib/oban_powertools/explain.ex
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add Runtime Completion, Result Persistence, and Dependency Policies</name>
  <files>lib/oban_powertools/workflow.ex, lib/oban_powertools/workflow/runtime.ex, lib/oban_powertools/workflow/result.ex, test/oban_powertools/workflow_runtime_test.exs</files>
  <behavior>
    - Completing a step persists an explicit result row and updates step/workflow runtime state in one transaction.
    - Downstream steps unblock only when all required dependencies are successful and have resolvable results.
    - Terminal dependency outcomes default to cascade-cancel for queued or available descendants, with per-edge `cancel` or `continue` overrides.
  </behavior>
  <action>
    Implement runtime completion and release functions using `Ecto.Multi` per D-09, D-10, D-14, D-15, D-18, D-19, D-20, D-21, D-22, D-23, D-24, D-25, D-26, and D-34.
    Persist explicit result rows keyed by stable step name, including redaction/overflow metadata and operator-visible status markers, and resolve downstream references through those persisted results rather than mutable workflow context per D-14, D-15, D-17, D-18, and D-46.
    Write runtime tests for successful fan-out/fan-in release, blocked-on-retryable parents, default cascade-cancel on terminal failure, narrow per-edge `continue` handling for cleanup/finalizer steps, and nested child workflow linkage without flattening graphs per D-22, D-23, D-26, and D-36.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/workflow_runtime_test.exs -x</automated>
  </verify>
  <done>Workflow runtime transitions and dependency policies are durable, explicit, and proven under integration tests.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Extend Explainability for Workflow Blockers and Dependency Snapshots</name>
  <files>lib/oban_powertools/explain.ex, lib/oban_powertools/workflow/runtime.ex, test/oban_powertools/workflow_runtime_test.exs, test/oban_powertools/explain_test.exs</files>
  <behavior>
    - Workflow blocker payloads reuse the existing `status`, `blockers`, `live_now`, and `snapshot_at_block_start` contract.
    - Missing results, retryable upstream work, cascade-cancel decisions, and unresolved edge policy become explicit blocker codes.
    - Child-step snapshots preserve exact dependency names, outcomes, and policies for later UI and audit rendering.
  </behavior>
  <action>
    Extend `ObanPowertools.Explain` with workflow-specific blocker normalization and snapshot readers per D-19, D-25, D-31, D-34, and D-41.
    Persist dependency snapshots on affected child steps during runtime transitions so the explain contract can show what is blocked, why it is blocked, and which dependency/result caused it even after live state changes per D-25 and D-31.
    Add test coverage proving workflow explanations do not collapse missing dependency results to `nil`, do not treat retryable parents as terminal, and keep running descendants untouched during initial terminal propagation per D-19, D-20, and D-26.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/explain_test.exs -x</automated>
  </verify>
  <done>Workflow runtime state produces durable, operator-readable blocker explanations and dependency snapshots.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Workflow runtime -> Database | Step completion and child release must stay idempotent and durable across concurrent transitions. |
| Result persistence -> Explain/UI | Stored results and snapshots feed operator-visible diagnostics and must remain bounded and explicit. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-3-07 | Tampering | child release transition | mitigate | Use one transactional completion/release path with durable step/result rows and conflict-aware release queries. |
| T-3-08 | Information Disclosure | workflow results and snapshots | mitigate | Enforce bounded result storage plus redaction/overflow markers and surface summaries instead of arbitrary raw payloads. |
| T-3-09 | Denial of Service | dependency resolution | mitigate | Treat missing/unresolved dependency results as explicit blockers instead of retry loops or recursive payload lookups. |
</threat_model>

<verification>
mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/explain_test.exs -x
</verification>

<success_criteria>
Workflow runtime transitions now persist explicit results, apply the locked dependency semantics, and surface exact blocker evidence without relying on PubSub or mutable in-memory state.
</success_criteria>

<output>
After completion, create `.planning/phases/3-03-SUMMARY.md`
</output>
