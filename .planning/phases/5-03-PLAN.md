---
phase: 5
plan: 03
type: execute
wave: 3
depends_on: ["Phase 5 Plan 01", "Phase 5 Plan 02"]
files_modified: [".planning/phases/2-01-SUMMARY.md", ".planning/phases/2-02-SUMMARY.md", ".planning/phases/2-03-SUMMARY.md", ".planning/phases/2-04-SUMMARY.md", ".planning/phases/2-05-SUMMARY.md", ".planning/phases/2-VALIDATION.md", ".planning/phases/2-VERIFICATION.md", ".planning/REQUIREMENTS.md"]
autonomous: true
requirements: ["ENG-01", "ENG-02"]
---

<objective>
Recover the incomplete Phase 2 artifact set by backfilling missing summaries, normalizing legacy summary metadata, and creating verification evidence for the Phase 5-owned smart-engine requirements.
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
@.planning/phases/2-VALIDATION.md
@.planning/phases/2-04-SUMMARY.md
@.planning/phases/2-05-SUMMARY.md
@.planning/phases/2-01-PLAN.md
@.planning/phases/2-02-PLAN.md
@.planning/phases/2-03-PLAN.md
@.planning/phases/2-04-PLAN.md
@.planning/phases/2-05-PLAN.md
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Restore the missing and incomplete Phase 2 summary artifacts</name>
  <files>.planning/phases/2-01-SUMMARY.md, .planning/phases/2-02-SUMMARY.md, .planning/phases/2-03-SUMMARY.md, .planning/phases/2-04-SUMMARY.md, .planning/phases/2-05-SUMMARY.md</files>
  <behavior>
    - Missing summaries for plans `2-01`, `2-02`, and `2-03` are backfilled from actual completed scope, not invented scope.
    - Existing summaries for `2-04` and `2-05` gain machine-readable frontmatter compatible with the repo's current summary pattern.
    - `requirements-completed` metadata closes only `ENG-01` and `ENG-02`; `ENG-03` remains visibly deferred to Phase 6 because of the live auth-ordering defect.
  </behavior>
  <action>
    Reconstruct `.planning/phases/2-01-SUMMARY.md`, `.planning/phases/2-02-SUMMARY.md`, and `.planning/phases/2-03-SUMMARY.md` from the Phase 2 plans and completed code/test posture.
    Normalize `.planning/phases/2-04-SUMMARY.md` and `.planning/phases/2-05-SUMMARY.md` with explicit frontmatter and provenance notes without rewriting their historical body prose beyond what traceability needs.
    Follow the summary analogs identified in `.planning/phases/5-PATTERNS.md`: `.planning/phases/1-01-SUMMARY.md` for modern frontmatter shape and the existing Phase 2 summary bodies for minimal prose preservation.
  </action>
  <verify>
    <automated>rg -n "requirements-completed|ENG-01|ENG-02|ENG-03" .planning/phases/2-0*-SUMMARY.md</automated>
  </verify>
  <done>Phase 2 has a complete summary set with machine-readable metadata that matches the audit closure boundary.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Add Phase 2 verification evidence and synchronize smart-engine traceability</name>
  <files>.planning/phases/2-VALIDATION.md, .planning/phases/2-VERIFICATION.md, .planning/REQUIREMENTS.md</files>
  <behavior>
    - Validation and verification explicitly cover `ENG-01` and `ENG-02` with fresh targeted commands.
    - `ENG-03` remains visible as an open implementation gap for Phase 6.
    - `REQUIREMENTS.md`, summary frontmatter, and verification results all agree on the final status.
  </behavior>
  <action>
    Update `.planning/phases/2-VALIDATION.md` only where needed to strengthen requirement-to-command clarity and to document the deferred treatment of `ENG-03`.
    Create `.planning/phases/2-VERIFICATION.md` with current Phase 2 command results, then sync the `ENG-01` and `ENG-02` rows in `.planning/REQUIREMENTS.md` without overstating closure for the deferred cron authorization issue.
    Use `.planning/phases/2-VALIDATION.md` as the command-map analog and `.planning/phases/4-PLAN-CHECK.md` as the closest repo-local verification-report analog.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/limits_test.exs test/oban_powertools/worker_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/web/live/limiters_live_test.exs</automated>
  </verify>
  <done>Phase 2 evidence closure is complete for `ENG-01` and `ENG-02`, while `ENG-03` remains accurately deferred.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Plan history -> reconstructed summaries | Missing summaries must be backfilled from actual completed scope, not guessed or broadened. |
| Phase 2 closure -> deferred cron defect | Phase 5 must not make `ENG-03` look resolved when the audit found a live defect. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-5-06 | Integrity | Phase 2 summary reconstruction | mitigate | Derive summaries from existing plans and current repo evidence, then note retrospective provenance. |
| T-5-07 | Tampering | `ENG-03` status | mitigate | Keep `ENG-03` out of `requirements-completed` closure and explicitly defer it in requirements and verification. |
</threat_model>

<verification>
rg -n "requirements-completed|ENG-01|ENG-02|ENG-03" .planning/phases/2-0*-SUMMARY.md
mix test test/oban_powertools/limits_test.exs test/oban_powertools/worker_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/web/live/limiters_live_test.exs
</verification>

<success_criteria>
Phase 2 has the missing summary artifacts restored, `ENG-01` and `ENG-02` are fully traceable through validation and verification, and `ENG-03` remains explicitly deferred to Phase 6.
</success_criteria>

<output>
After completion, create `.planning/phases/5-03-SUMMARY.md`
</output>
