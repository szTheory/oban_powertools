---
phase: 4
plan: 02
type: execute
wave: 2
depends_on: ["Phase 4 Plan 01"]
files_modified: ["lib/oban_powertools/application.ex", "lib/oban_powertools/telemetry.ex", "lib/oban_powertools/lifeline.ex", "lib/oban_powertools/lifeline/heartbeat_writer.ex", "test/oban_powertools/lifeline_test.exs"]
autonomous: true
requirements: ["LIF-01"]
must_haves:
  truths:
    - "Executor liveness is derived from persisted heartbeat evidence, not job runtime heuristics."
    - "Late executors are warning-only, while missing executors can produce orphan-candidate incidents."
    - "Heartbeat writes and incident projection are supervised, low-cardinality, and conservative under retries or duplicate polls."
  artifacts:
    - path: "lib/oban_powertools/lifeline.ex"
      provides: "Public heartbeat refresh, health classification, and incident listing API"
      contains: "Executor Missing"
    - path: "lib/oban_powertools/application.ex"
      provides: "Supervision for Phase 4 heartbeat/lifeline processes"
      contains: "heartbeat"
    - path: "test/oban_powertools/lifeline_test.exs"
      provides: "Heartbeat and orphan-detection tests"
      contains: "dead_executor"
---

<objective>
Implement durable executor heartbeat writes and conservative incident detection. This plan delivers the backend liveness layer that feeds the later repair center without allowing any mutation yet.
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
@lib/oban_powertools/cron.ex
@lib/oban_powertools/explain.ex
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add the Heartbeat Writer and Liveness Classification Service</name>
  <files>lib/oban_powertools/application.ex, lib/oban_powertools/telemetry.ex, lib/oban_powertools/lifeline.ex, lib/oban_powertools/lifeline/heartbeat_writer.ex, test/oban_powertools/lifeline_test.exs</files>
  <behavior>
    - A supervised writer periodically bulk-upserts heartbeat rows for stable executor identities.
    - Liveness classifies rows into `Healthy`, `Heartbeat Late`, and `Executor Missing` using the locked default thresholds.
    - Telemetry remains low-cardinality and never uses executor ids or job ids as metric labels.
  </behavior>
  <action>
    Add a Phase 4 lifeline service and supervised heartbeat writer under `ObanPowertools.Application`, following the small-child pattern used for PubSub and the workflow coordinator.
    Implement explicit APIs for refreshing heartbeats, listing executor health, and classifying heartbeat age using the locked defaults of 15s cadence, 45s warning, and 120s missing.
    Add `execute_lifeline_event/3` style telemetry wrappers and repo-backed tests proving heartbeat rows are durable, repeated writes upsert the same executor identity, and `late` never escalates to a mutable orphan incident on its own.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/lifeline_test.exs</automated>
  </verify>
  <done>Heartbeat writers and liveness classification exist with conservative, test-backed semantics.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Project Dead-Executor and Workflow-Stuck Incidents</name>
  <files>lib/oban_powertools/lifeline.ex, test/oban_powertools/lifeline_test.exs</files>
  <behavior>
    - The lifeline service projects only the Phase 4 incident classes: `dead_executor` and `workflow_stuck`.
    - Dead-executor incidents are based on persisted heartbeat evidence plus affected running work, never raw runtime age alone.
    - Incident read models expose affected counts and operator-readable evidence that later preview flows can reuse.
  </behavior>
  <action>
    Extend the lifeline backend to emit and list incidents from durable heartbeat and workflow-step data, mapping only the locked Phase 4 classes and preserving explicit affected job/workflow-step scope.
    Snapshot the executor identity on running jobs or workflow steps where needed so orphan evidence points back to the exact owner that held the work.
    Add tests for `healthy`, `late`, and `missing` state transitions, for dead-executor orphan-candidate detection, and for workflow-stuck evidence that stays read-only until the later repair preview plan lands.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/lifeline_test.exs</automated>
  </verify>
  <done>The backend can show actionable incidents with conservative evidence and no mutation leakage.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Runtime processes -> Heartbeat tables | Liveness writes must be durable and restart-safe even when nodes crash or duplicate refreshes occur. |
| Lifeline detection -> Incident read model | Detection must remain conservative so missing-vs-late state does not unlock unsafe repair. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-4-04 | Tampering | executor identity | mitigate | Use stable executor ids rather than raw pids so restarts and reconnects do not falsify ownership evidence. |
| T-4-05 | Denial of Service | heartbeat polling loop | mitigate | Use bulk upserts and bounded polling cadence rather than per-job write amplification. |
| T-4-06 | Integrity | orphan detection | mitigate | Require persisted missing-heartbeat evidence before projecting dead-executor incidents. |
</threat_model>

<verification>
mix test test/oban_powertools/lifeline_test.exs
</verification>

<success_criteria>
The repo can persist executor heartbeats, classify health conservatively, and surface Phase 4 incidents without relying on naive time-based rescue.
</success_criteria>

<output>
After completion, create `.planning/phases/4-02-SUMMARY.md`
</output>
