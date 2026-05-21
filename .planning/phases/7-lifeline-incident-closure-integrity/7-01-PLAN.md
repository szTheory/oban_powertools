---
phase: 7
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: ["lib/oban_powertools/lifeline.ex", "test/oban_powertools/lifeline_test.exs"]
autonomous: true
requirements: ["LIF-02"]
must_haves:
  truths:
    - "A successful repair retires the acted-on incident row durably in the same transaction as the target mutation, preview consumption, and audit write."
    - "Re-running incident projection does not keep a repaired incident active when no current stranded evidence remains."
    - "Unauthorized, drifted, invalid-reason, or otherwise failed repair paths leave the incident row active."
  artifacts:
    - path: "lib/oban_powertools/lifeline.ex"
      provides: "Atomic incident lifecycle reconciliation for projection and execute paths"
      contains: "def project_incidents"
    - path: "test/oban_powertools/lifeline_test.exs"
      provides: "Regression coverage for retirement, reprojection, and non-retirement failures"
      contains: "resolved"
  key_links:
    - from: "project_incidents/2"
      to: "oban_powertools_lifeline_incidents.status"
      via: "candidate-set reconciliation"
      pattern: "active if currently stranded, resolved otherwise"
    - from: "apply_repair/5"
      to: "Incident.status/resolved_at"
      via: "Ecto.Multi incident step"
      pattern: "target -> incident -> preview -> audit"
---

<objective>
Close the backend correctness gap in Lifeline so repair execution and incident projection share one explicit lifecycle model per D-03 through D-15, without adding new lifecycle storage unless the existing `status` and `resolved_at` fields prove insufficient.
</objective>

<execution_context>
@$HOME/.codex/get-shit-done/workflows/execute-plan.md
@$HOME/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/STATE.md
@.planning/phases/4-VERIFICATION.md
@.planning/phases/4-CONTEXT.md
@.planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md
@.planning/phases/7-lifeline-incident-closure-integrity/7-RESEARCH.md
@.planning/phases/7-lifeline-incident-closure-integrity/7-PATTERNS.md

<interfaces>
From `lib/oban_powertools/lifeline.ex`:
```elixir
def list_incidents(repo, opts \\ [])
def project_incidents(repo, opts \\ [])
def preview_repair(repo, actor, attrs, opts \\ [])
def execute_repair(repo, actor, preview_token, reason, opts \\ [])
```

Current execute transaction ordering to extend:
```elixir
Multi.new()
|> Multi.run(:target, fn repo, _changes -> mutate_target(repo, preview, now) end)
|> Multi.update(:preview, ...)
|> Multi.run(:audit, fn repo, %{preview: preview_record} -> ... end)
```

From `lib/oban_powertools/lifeline/incident.ex`:
```elixir
field(:status, :string, default: "active")
field(:resolved_at, :utc_datetime_usec)
field(:incident_fingerprint, :string)
```
</interfaces>
</context>

<tasks>

<task type="execute" tdd="true">
  <name>Task 1: Reconcile active incidents against current evidence inside projection per D-07 through D-12</name>
  <files>lib/oban_powertools/lifeline.ex, test/oban_powertools/lifeline_test.exs</files>
  <read_first>
    - lib/oban_powertools/lifeline.ex
    - lib/oban_powertools/lifeline/incident.ex
    - test/oban_powertools/lifeline_test.exs
    - .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md
    - .planning/phases/7-lifeline-incident-closure-integrity/7-RESEARCH.md
  </read_first>
  <action>
    Refactor `project_incidents/2` so it computes the full current candidate fingerprint set, upserts those candidates as `active`, and resolves any previously active `Incident` rows whose `incident_fingerprint` is absent from the current candidate set, per D-08.
    In the dead-executor branch, narrow active evidence so rescued jobs no longer count after they move to `available` or `retryable`; use current stranded evidence only, with `Oban.Job.state == "executing"` for dead-executor jobs and current workflow-step state checks instead of historical executor metadata alone, per D-09.
    Keep stable incident identity per D-11 by updating the existing row on reopen instead of inserting successor rows; when a previously resolved row becomes active again, clear `resolved_at`, preserve `first_detected_at`, and refresh `last_detected_at`.
    Do not add a new migration or new lifecycle table in this task; preserve the explicit `status` and `resolved_at` model per D-06 unless the executor can prove the existing row shape cannot express the required behavior.
    Extend `test/oban_powertools/lifeline_test.exs` with failing-then-passing regression coverage that proves:
    1. a repaired dead-executor fingerprint is resolved on reprojection once no executing job still qualifies;
    2. `project_incidents/2` reuses the same row when the same fingerprint becomes active again;
    3. workflow-stuck projection only stays active when the current blocker/state still qualifies per D-10.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/lifeline.ex` contains stale-active reconciliation logic inside `def project_incidents`
    - `lib/oban_powertools/lifeline.ex` no longer queries dead-executor jobs with `job.state in ["executing", "available", "retryable"]`
    - `test/oban_powertools/lifeline_test.exs` contains a regression asserting a resolved incident is not returned as active after reprojection
    - `test/oban_powertools/lifeline_test.exs` contains a regression asserting the same `incident_fingerprint` row is reused on reopen
    - `mix test test/oban_powertools/lifeline_test.exs -x` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/lifeline_test.exs -x</automated>
  </verify>
  <done>Projection is evidence-driven, stale active rows resolve durably, and reopen semantics reuse the same incident row.</done>
</task>

<task type="execute" tdd="true">
  <name>Task 2: Retire incidents atomically inside repair execution per D-03, D-04, D-13, and D-15</name>
  <files>lib/oban_powertools/lifeline.ex, test/oban_powertools/lifeline_test.exs</files>
  <read_first>
    - lib/oban_powertools/lifeline.ex
    - test/oban_powertools/lifeline_test.exs
    - .planning/phases/4-CONTEXT.md
    - .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md
    - .planning/phases/7-lifeline-incident-closure-integrity/7-PATTERNS.md
  </read_first>
  <action>
    Insert an explicit `:incident` step into `apply_repair/5` between `:target` and `:preview` so the same `Ecto.Multi` performs target mutation, incident retirement, preview consumption, and immutable audit write per D-04.
    Implement a concrete helper such as `resolve_incident_after_repair/4` or `incident_still_active?/3` that reloads the repaired target and only sets `Incident.status` to `resolved` plus `resolved_at` when the post-mutation state no longer satisfies the active criteria per D-15; if the target changed but the incident is still active, roll the transaction back with a specific error instead of leaving a mutated target under an active incident.
    Keep failed paths non-retiring per D-13: unauthorized, drifted, invalid-reason, preview-consumed, and heartbeat-late flows must never flip `status` or set `resolved_at`.
    Extend `test/oban_powertools/lifeline_test.exs` so it proves:
    1. successful job rescue resolves the incident row and stamps `resolved_at`;
    2. successful workflow-step repair resolves the workflow-stuck row;
    3. unauthorized execute and drifted execute keep the incident `active`;
    4. late-heartbeat preview rejection leaves the incident lifecycle unchanged.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/lifeline.ex` contains a `Multi.run(:incident` step between `:target` and `:preview`
    - `lib/oban_powertools/lifeline.ex` updates `status: "resolved"` and `resolved_at:` as part of repair execution
    - `test/oban_powertools/lifeline_test.exs` contains assertions for successful retirement and failed-path non-retirement
    - `test/oban_powertools/lifeline_test.exs` contains an assertion that unauthorized execution leaves `status == "active"`
    - `mix test test/oban_powertools/lifeline_test.exs -x` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/lifeline_test.exs -x</automated>
  </verify>
  <done>Repair execution either mutates and retires the incident atomically or fails without changing the incident lifecycle.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Repair execute transaction -> incident lifecycle row | Target mutation must not succeed without the incident row transitioning consistently in the same transaction. |
| Current stranded evidence -> active incident projection | Historical executor metadata must not replay stale incidents as still active. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-7-01 | Tampering | `project_incidents/2` | mitigate | Reconcile the full active set against current candidate fingerprints and resolve stale rows per D-08. |
| T-7-02 | Elevation of Privilege | `execute_repair/5` | mitigate | Keep auth, reason, preview, and drift guards ahead of the transactional retirement step so unauthorized or invalid paths cannot retire incidents. |
| T-7-03 | Repudiation | `apply_repair/5` | mitigate | Make incident retirement part of the same `Ecto.Multi` as preview consumption and audit evidence so operator actions have one durable story. |
| T-7-04 | Information Disclosure / operator confusion | incident evidence model | mitigate | Derive active status from live evidence only so repaired or no-longer-stranded work does not linger in the active queue. |
</threat_model>

<verification>
mix test test/oban_powertools/lifeline_test.exs -x
</verification>

<success_criteria>
The backend no longer allows the Phase 4 gap: successful repairs retire the incident row durably, stale active rows resolve on reprojection, and all failed paths preserve the active incident.
</success_criteria>

<output>
After completion, create `.planning/phases/7-lifeline-incident-closure-integrity/7-01-SUMMARY.md`
</output>
