---
phase: 2
plan: 03
type: execute
wave: 3
depends_on: ["Phase 2 Plan 02"]
files_modified: ["lib/oban_powertools/explain.ex", "lib/oban_powertools/limits.ex", "lib/oban_powertools/telemetry.ex", "lib/oban_powertools/audit.ex", "test/oban_powertools/explain_test.exs", "test/oban_powertools/telemetry_test.exs"]
autonomous: true
requirements: ["ENG-02"]
must_haves:
  truths:
    - "`explain/1` returns structured runnable or blocked payloads with stable blocker codes."
    - "Blocked-job evidence distinguishes live state from persisted snapshots."
    - "Limiter and explain state transitions emit low-cardinality telemetry and normalized audit records."
  artifacts:
    - path: "lib/oban_powertools/explain.ex"
      provides: "Structured explain contract"
      contains: "def explain"
    - path: "lib/oban_powertools/audit.ex"
      provides: "Normalized audit writer/read helper"
      contains: "def record"
  key_links:
    - from: "ObanPowertools.Explain.explain/1"
      to: "audit and telemetry events"
      via: "blocker snapshots and low-cardinality metadata"
      pattern: "live recompute + persisted evidence"
---

<objective>
Implement the structured explain contract plus the supporting audit and telemetry surfaces. This plan isolates ENG-02 so the contract can be locked and tested before the UI depends on it.
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
@.planning/phases/2-PATTERNS.md
@.planning/phases/2-VALIDATION.md
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Structured Explain Contract</name>
  <files>lib/oban_powertools/explain.ex, lib/oban_powertools/limits.ex, test/oban_powertools/explain_test.exs</files>
  <behavior>
    - `explain/1` distinguishes runnable vs blocked and orders blockers deterministically.
    - Blocker snapshots are persisted when blocked state begins or materially changes.
    - Live-now and snapshot evidence remain distinct in the contract.
  </behavior>
  <action>
    Add `ObanPowertools.Explain` for live recompute and snapshot-aware evidence assembly.
    Integrate with the limiter service only through explicit tagged outcomes and persisted evidence rows.
    Write contract tests that pin blocker codes, ordering, and the live-vs-snapshot split.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/explain_test.exs</automated>
  </verify>
  <done>The explain contract is durable, structured, and safe for later UI consumption.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Telemetry and Audit Normalization</name>
  <files>lib/oban_powertools/telemetry.ex, lib/oban_powertools/audit.ex, test/oban_powertools/telemetry_test.exs</files>
  <behavior>
    - Telemetry remains low-cardinality and operator-oriented.
    - Audit records normalize limiter actions and blocker evidence changes.
    - Explain-related writes have an explicit read/write path rather than hidden side effects.
  </behavior>
  <action>
    Extend telemetry helpers for blocked, released, and cooled-down outcomes while keeping metadata coarse.
    Add a dedicated audit helper so limiter actions and blocker-state changes have an explicit persistence boundary.
    Strengthen tests around telemetry metadata shape and normalized audit payloads.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/telemetry_test.exs</automated>
  </verify>
  <done>Explain-related state transitions are observable through stable telemetry and audit contracts.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Application -> Database | Blocker snapshots and audit rows are persisted in Postgres. |
| Internal events -> Telemetry | Only low-cardinality metadata should leave the smart-engine boundary. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-2-05 | Information Disclosure | explain payloads and telemetry | mitigate | Keep telemetry low-cardinality and expose detailed evidence only through auth-gated reads. |
| T-2-06 | Repudiation | limiter and explain actions | mitigate | Normalize audit writes for cooldown, unblock, and blocker snapshot changes. |
</threat_model>

<verification>
mix test test/oban_powertools/explain_test.exs test/oban_powertools/telemetry_test.exs
</verification>

<success_criteria>
Blocked jobs can be explained with structured evidence, and explain-related state transitions are visible through normalized audit and low-cardinality telemetry contracts.
</success_criteria>

<output>
After completion, create `.planning/phases/2-03-SUMMARY.md`
</output>
