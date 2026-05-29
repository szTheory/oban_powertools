---
phase: 5
plan: 04
type: execute
wave: 4
depends_on: ["Phase 5 Plan 01", "Phase 5 Plan 03"]
files_modified: [".planning/phases/3-01-SUMMARY.md", ".planning/phases/3-02-SUMMARY.md", ".planning/phases/3-03-SUMMARY.md", ".planning/phases/3-04-SUMMARY.md", ".planning/phases/3-05-SUMMARY.md", ".planning/phases/3-VALIDATION.md", ".planning/phases/3-VERIFICATION.md", ".planning/REQUIREMENTS.md"]
autonomous: true
requirements: ["WF-01", "WF-02", "WF-03"]
---

<objective>
Normalize the Phase 3 workflow evidence set so the existing summary bodies gain machine-readable completion metadata and the workflow requirements are backed by fresh verification artifacts.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/v1-v1-MILESTONE-AUDIT.md
@.planning/phases/5-CONTEXT.md
@.planning/phases/5-RESEARCH.md
@.planning/phases/5-PATTERNS.md
@.planning/phases/3-VALIDATION.md
@.planning/phases/3-01-SUMMARY.md
@.planning/phases/3-02-SUMMARY.md
@.planning/phases/3-03-SUMMARY.md
@.planning/phases/3-04-SUMMARY.md
@.planning/phases/3-05-SUMMARY.md
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Add frontmatter-based completion metadata to the Phase 3 summaries</name>
  <files>.planning/phases/3-01-SUMMARY.md, .planning/phases/3-02-SUMMARY.md, .planning/phases/3-03-SUMMARY.md, .planning/phases/3-04-SUMMARY.md, .planning/phases/3-05-SUMMARY.md</files>
  <behavior>
    - Existing summary bodies remain substantially intact.
    - Each Phase 3 summary gains frontmatter compatible with the repo's current summary contract.
    - `requirements-completed` assignments align to the actual Phase 3 plans and cover `WF-01`, `WF-02`, and `WF-03` without duplication noise or invented scope.
  </behavior>
  <action>
    Normalize the five Phase 3 summary files by prepending YAML frontmatter and visible retrospective provenance while preserving the existing narrative sections wherever possible.
    Use the Phase 3 plans and current repo history to assign requirement completion metadata accurately across the persistence, runtime, coordinator, telemetry, and UI slices.
    Follow `.planning/phases/1-01-SUMMARY.md` as the frontmatter analog and the minimal-normalization rule captured in `.planning/phases/5-PATTERNS.md`.
  </action>
  <verify>
    <automated>rg -n "requirements-completed|WF-01|WF-02|WF-03" .planning/phases/3-0*-SUMMARY.md</automated>
  </verify>
  <done>Phase 3 summary artifacts are machine-readable and traceable without losing their historical narrative content.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Add Phase 3 verification evidence and sync workflow requirement closure</name>
  <files>.planning/phases/3-VALIDATION.md, .planning/phases/3-VERIFICATION.md, .planning/REQUIREMENTS.md</files>
  <behavior>
    - Validation remains command-map oriented and only changes where clarity or frontmatter normalization is needed.
    - Verification captures fresh command results for the workflow requirements and supporting installer/runtime tests.
    - `REQUIREMENTS.md` reflects workflow closure without changing Phase 3 implementation ownership.
  </behavior>
  <action>
    Update `.planning/phases/3-VALIDATION.md` to make its Phase 3 proof map explicit and phase-gate-ready, then create `.planning/phases/3-VERIFICATION.md` with current results for the workflow test commands.
    Synchronize the `WF-01`, `WF-02`, and `WF-03` rows in `.planning/REQUIREMENTS.md` so the audit can follow the full 3-source chain cleanly.
    Use `.planning/phases/3-VALIDATION.md` as the validation analog and `.planning/phases/4-PLAN-CHECK.md` as the closest local verification-report analog.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/workflow_test.exs test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/web/live/workflows_live_test.exs</automated>
  </verify>
  <done>The workflow requirements are fully represented in validation, verification, and requirements traceability artifacts.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Existing summary prose -> new frontmatter | Frontmatter must add machine-readable closure without distorting the original narrative record. |
| Workflow tests -> requirement closure | Verification must stay linked to concrete workflow behaviors, not generic full-suite confidence. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-5-08 | Integrity | Phase 3 frontmatter normalization | mitigate | Preserve existing summary bodies and add only the metadata needed for audit closure. |
| T-5-09 | Repudiation | workflow requirement closure | mitigate | Record targeted workflow verification commands and synchronize requirements rows to the resulting evidence. |
</threat_model>

<verification>
rg -n "requirements-completed|WF-01|WF-02|WF-03" .planning/phases/3-0*-SUMMARY.md
mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/workflow_test.exs test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/web/live/workflows_live_test.exs
</verification>

<success_criteria>
All Phase 3 workflow requirements have machine-readable summary metadata, fresh verification evidence, and synchronized requirement rows in `REQUIREMENTS.md`.
</success_criteria>

<output>
After completion, create `.planning/phases/5-04-SUMMARY.md`
</output>
