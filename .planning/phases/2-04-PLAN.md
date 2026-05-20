---
phase: 2
plan: 04
type: execute
wave: 4
depends_on: ["Phase 2 Plan 01", "Phase 2 Plan 03"]
files_modified: ["lib/oban_powertools/cron.ex", "lib/oban_powertools/cron/entry.ex", "lib/oban_powertools/cron/slot.ex", "lib/oban_powertools/telemetry.ex", "lib/oban_powertools/audit.ex", "test/oban_powertools/cron_test.exs"]
autonomous: true
requirements: ["ENG-03"]
must_haves:
  truths:
    - "Dynamic cron uses durable slot claims keyed by entry and slot time."
    - "Overlap and catch-up policies are explicit first-class semantics."
    - "Pause, resume, and run-now flows are policy-aware, auditable, and telemetry-visible."
  artifacts:
    - path: "lib/oban_powertools/cron.ex"
      provides: "Cron orchestration and slot claim logic"
      contains: "Ecto.Multi"
    - path: "test/oban_powertools/cron_test.exs"
      provides: "Policy matrix coverage for overlap and catch-up"
      contains: "queue_one"
  key_links:
    - from: "due slot"
      to: "ObanPowertools.Cron"
      via: "entry_id + slot_at ledger"
      pattern: "transactional claim and policy enforcement"
---

<objective>
Implement the dynamic cron engine on top of the Phase 2 persistence foundation. This plan turns durable entries and slot rows into explicit overlap/catch-up behavior that is cluster-safe and operator-visible.
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
  <name>Task 1: Entry Sync and Slot Claim Orchestration</name>
  <files>lib/oban_powertools/cron.ex, lib/oban_powertools/cron/entry.ex, lib/oban_powertools/cron/slot.ex, test/oban_powertools/cron_test.exs</files>
  <behavior>
    - Code-managed and runtime-managed cron entries share one durable execution path.
    - Every due occurrence is claimed through a durable slot row.
    - Duplicate firings resolve through tagged outcomes rather than hidden retries.
  </behavior>
  <action>
    Build the `ObanPowertools.Cron` entry-sync and slot-claim flow using `Ecto.Multi`.
    Ensure code-managed entries preserve read-only schedule semantics while runtime-managed entries remain mutable.
    Cover duplicate slot claims and guarantee-window resets in repo-backed tests.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/cron_test.exs</automated>
  </verify>
  <done>Due slots are claimed durably and cron entries share one explicit execution model.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Policy Enforcement, Manual Actions, and Observability</name>
  <files>lib/oban_powertools/cron.ex, lib/oban_powertools/telemetry.ex, lib/oban_powertools/audit.ex, test/oban_powertools/cron_test.exs</files>
  <behavior>
    - Overlap policies `queue_one`, `skip`, `allow`, and `cancel_previous` are explicit and tested.
    - Catch-up defaults to `latest` and bounded replay stays opt-in.
    - Pause, resume, and run-now operations are auditable and telemetry-visible.
  </behavior>
  <action>
    Implement policy application inside the cron orchestration layer.
    Add explicit helpers for pause, resume, and run-now actions that write normalized audit rows and emit low-cardinality telemetry.
    Test the overlap/catch-up matrix and manual-action side effects in one repo-backed cron suite.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/cron_test.exs</automated>
  </verify>
  <done>Dynamic cron honors the locked overlap and catch-up semantics and exposes safe operator controls.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Scheduler -> Database | Cron correctness depends on transactional slot claiming in Postgres. |
| Operator actions -> Cron state | Manual pause/resume/run-now actions must be authorized, auditable, and policy-aware. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-2-07 | Denial of Service | catch-up replay | mitigate | Default to `latest`, require bounded replay opt-in, and test the policy matrix. |
| T-2-08 | Tampering | manual cron controls | mitigate | Write audit rows and emit telemetry for pause/resume/run-now transitions. |
| T-2-09 | Reliability | duplicate slot claims | mitigate | Use durable uniqueness and transactional claim logic for each due slot. |
</threat_model>

<verification>
mix test test/oban_powertools/cron_test.exs
</verification>

<success_criteria>
Dynamic cron is durable, policy-driven, and cluster-safe, with explicit operator controls that respect audit and telemetry rules.
</success_criteria>

<output>
After completion, create `.planning/phases/2-04-SUMMARY.md`
</output>
