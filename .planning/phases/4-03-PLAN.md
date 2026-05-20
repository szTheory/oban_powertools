---
phase: 4
plan: 03
type: execute
wave: 3
depends_on: ["Phase 4 Plan 01", "Phase 4 Plan 02"]
files_modified: ["lib/oban_powertools/lifeline.ex", "lib/oban_powertools/audit.ex", "lib/oban_powertools/telemetry.ex", "lib/oban_powertools/workflow.ex", "test/oban_powertools/lifeline_test.exs", "test/oban_powertools/workflow_runtime_test.exs"]
autonomous: true
requirements: ["LIF-02", "LIF-03"]
must_haves:
  truths:
    - "All Phase 4 repair actions follow preview -> reason -> execute, with no direct mutation from incident rows."
    - "Preview rows are durable, single-use, drift-aware, and separately authorized from execution."
    - "Manual retry/cancel/rescue actions write immutable audit evidence in the same transaction as the state change."
  artifacts:
    - path: "lib/oban_powertools/lifeline.ex"
      provides: "Repair preview and execute API"
      contains: "Preview Drifted"
    - path: "lib/oban_powertools/audit.ex"
      provides: "Immutable manual-repair audit sink"
      contains: "reason"
    - path: "test/oban_powertools/lifeline_test.exs"
      provides: "Preview drift, reason, and audit transaction tests"
      contains: "plan_hash"
---

<objective>
Implement the repair backend for Phase 4. This plan adds durable preview generation, drift-aware execution, narrow job/workflow-step repair actions, and immutable audit writes with reason capture.
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
@lib/oban_powertools/audit.ex
@lib/oban_powertools/cron.ex
@lib/oban_powertools/explain.ex
@lib/oban_powertools/workflow.ex
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Build Durable Repair Preview Generation</name>
  <files>lib/oban_powertools/lifeline.ex, lib/oban_powertools/telemetry.ex, test/oban_powertools/lifeline_test.exs</files>
  <behavior>
    - Preview generation produces durable rows keyed by incident class, fingerprint, plan hash, and concrete repair targets.
    - Allowed actions remain narrow: orphaned job rescue, single-job retry/cancel, and single workflow-step retry/cancel.
    - Preview payloads show before/after state and affected counts before raw ids or low-level payload detail.
  </behavior>
  <action>
    Add explicit preview-generation APIs that accept a concrete incident or target, compute the affected record set, persist `incident_fingerprint` and `plan_hash`, and return operator-readable before/after summaries.
    Reject unsupported Phase 4 mutation scope such as branch-wide retry, force-complete, skip-edge, or generic repair-all actions.
    Add tests proving preview generation is durable, idempotent under duplicate preview requests when inputs match, and blocked for `Heartbeat Late` incidents or unsupported target classes.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/lifeline_test.exs</automated>
  </verify>
  <done>Repair previews are durable, scoped, and safe enough for operators to inspect before any mutation happens.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Execute Repair Plans with Drift Checks, Auth, and Immutable Audit</name>
  <files>lib/oban_powertools/lifeline.ex, lib/oban_powertools/audit.ex, lib/oban_powertools/workflow.ex, test/oban_powertools/lifeline_test.exs, test/oban_powertools/workflow_runtime_test.exs</files>
  <behavior>
    - Execute recomputes incident-defining fields and rejects stale preview rows as `Preview Drifted`.
    - Authorization and reason capture are enforced at execute time even if preview was already allowed.
    - State mutation, preview consumption, and audit write succeed or fail together in one transaction.
  </behavior>
  <action>
    Implement execute paths for the locked Phase 4 repair actions using `Ecto.Multi`, consuming the preview row once, rechecking drift, applying the state change to the targeted job or workflow step, and writing immutable audit evidence with actor, reason, preview token, fingerprint, hash, and affected counts.
    Extend workflow/job runtime helpers only where needed to support the narrow retry/cancel/rescue actions without introducing broad mutation semantics.
    Add tests for blank/trivial reason rejection, preview single-use behavior, drift rejection after state changes, and successful audit evidence writes for both job and workflow-step repair actions.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/workflow_runtime_test.exs</automated>
  </verify>
  <done>Repair execution is drift-aware, idempotent, auth-gated, and immutably audited.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Operator preview -> Execute mutation | A stale or replayed preview must never be enough to mutate job or workflow state. |
| Repair service -> Audit trail | Manual interventions must be non-repudiable and linked to exactly what the operator approved. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-4-07 | Elevation of Privilege | repair execution | mitigate | Re-authorize execute separately from preview and keep action names narrow and explicit. |
| T-4-08 | Replay | preview token | mitigate | Make preview rows single-use and reject execution when hash/fingerprint drift is detected. |
| T-4-09 | Repudiation | manual repair | mitigate | Write actor, reason, preview token, fingerprint, hash, and affected counts in the same transaction as the state change. |
</threat_model>

<verification>
mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/workflow_runtime_test.exs
</verification>

<success_criteria>
Operators can safely preview and execute only the locked Phase 4 repair actions, and every manual mutation leaves durable, trustworthy audit evidence.
</success_criteria>

<output>
After completion, create `.planning/phases/4-03-SUMMARY.md`
</output>
