---
phase: 5
plan: 02
type: execute
wave: 2
depends_on: ["Phase 5 Plan 01"]
files_modified: [".planning/phases/1-VALIDATION.md", ".planning/phases/1-VERIFICATION.md", ".planning/REQUIREMENTS.md"]
autonomous: true
requirements: ["WRK-01", "WRK-02", "WRK-03"]
---

<objective>
Restore the Phase 1 worker evidence chain so the typed worker and idempotency requirements are backed by fresh verification artifacts and synchronized traceability status.
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
@.planning/phases/1-01-SUMMARY.md
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Backfill the missing Phase 1 validation map</name>
  <files>.planning/phases/1-VALIDATION.md</files>
  <behavior>
    - Phase 1 has a requirement-to-command validation artifact matching the repo's existing validation document shape.
    - Each of `WRK-01`, `WRK-02`, and `WRK-03` maps to targeted rerunnable commands rather than broad prose claims.
    - The validation doc stays narrow and evidence-oriented.
  </behavior>
  <action>
    Create `.planning/phases/1-VALIDATION.md` using the established local structure: test framework, requirement-to-command map, execution requirements, and gap coverage.
    Seed the command map from the Phase 1 summary and current Phase 1 tests so later verification can record fresh evidence without inventing a new proof model.
    Follow the validation analogs in `.planning/phases/0-VALIDATION.md`, `.planning/phases/2-VALIDATION.md`, and `.planning/phases/3-VALIDATION.md` as mapped in `.planning/phases/5-PATTERNS.md`.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/worker_test.exs test/oban_powertools/idempotency_test.exs test/mix/tasks/oban_powertools.install_test.exs</automated>
  </verify>
  <done>Phase 1 has an explicit validation map for all worker ergonomics requirements.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Create Phase 1 verification and sync worker requirement status</name>
  <files>.planning/phases/1-VERIFICATION.md, .planning/REQUIREMENTS.md</files>
  <behavior>
    - Verification records fresh outcomes for the Phase 1 requirement command set.
    - `REQUIREMENTS.md` reflects that `WRK-01`, `WRK-02`, and `WRK-03` are evidence-closed without changing Phase 1 implementation ownership.
    - The artifact chain is complete: requirements table, summary frontmatter, and verification doc all agree.
  </behavior>
  <action>
    Write `.planning/phases/1-VERIFICATION.md` capturing current repo-state results for the Phase 1 validation commands and any prerequisite compile/test context needed for audit trust.
    Update `.planning/REQUIREMENTS.md` so the worker requirements show explicit closure proof linked to Phase 1 ownership and Phase 5 evidence restoration.
    Use `.planning/phases/4-PLAN-CHECK.md` as the closest local verification-result analog and keep the requirement-link structure aligned with `.planning/phases/5-PATTERNS.md`.
  </action>
  <verify>
    <automated>mix compile --warnings-as-errors && mix test test/oban_powertools/worker_test.exs test/oban_powertools/idempotency_test.exs test/mix/tasks/oban_powertools.install_test.exs</automated>
  </verify>
  <done>The worker requirements are traceable from requirement row to summary metadata to fresh verification results.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Existing summary -> new verification | Phase 1 summary claims must be corroborated by current test commands. |
| Requirement row -> closure status | Status changes must reflect fresh evidence, not convenience. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-5-04 | Integrity | Phase 1 closure proof | mitigate | Require targeted worker/idempotency commands and record current outcomes in verification. |
| T-5-05 | Repudiation | requirements status sync | mitigate | Preserve Phase 1 as implementation owner while adding explicit Phase 5 proof metadata. |
</threat_model>

<verification>
mix compile --warnings-as-errors
mix test test/oban_powertools/worker_test.exs test/oban_powertools/idempotency_test.exs test/mix/tasks/oban_powertools.install_test.exs
</verification>

<success_criteria>
`WRK-01`, `WRK-02`, and `WRK-03` each have an explicit validation map, a fresh verification record, and synchronized traceability status in `REQUIREMENTS.md`.
</success_criteria>

<output>
After completion, create `.planning/phases/5-02-SUMMARY.md`
</output>
