---
phase: 5
plan: 05
type: execute
wave: 5
depends_on: ["Phase 5 Plan 01", "Phase 5 Plan 02", "Phase 5 Plan 03", "Phase 5 Plan 04"]
files_modified: [".planning/phases/4-VALIDATION.md", ".planning/phases/4-VERIFICATION.md", ".planning/REQUIREMENTS.md", ".planning/v1-v1-MILESTONE-AUDIT.md"]
autonomous: true
requirements: ["LIF-01", "LIF-03", "LIF-04"]
---

<objective>
Close the Phase 4 evidence gaps, synchronize the final Phase 5-owned requirement rows, and rerun the milestone audit so the repo records both the closed evidence chain and the remaining deferred Phase 6/7 defects honestly.
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
@.planning/phases/4-01-SUMMARY.md
@.planning/phases/4-02-SUMMARY.md
@.planning/phases/4-03-SUMMARY.md
@.planning/phases/4-04-SUMMARY.md
@.planning/phases/4-05-SUMMARY.md
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Add Phase 4 validation and verification while keeping incident-closure defects open</name>
  <files>.planning/phases/4-VALIDATION.md, .planning/phases/4-VERIFICATION.md, .planning/REQUIREMENTS.md</files>
  <behavior>
    - Phase 4 gains the missing validation and verification artifacts using the same evidence-first posture as earlier repaired phases.
    - `LIF-01`, `LIF-03`, and `LIF-04` are evidence-closed with fresh commands.
    - `LIF-02` remains explicitly open for Phase 7 because the incident-retirement bug is real and unresolved.
  </behavior>
  <action>
    Create `.planning/phases/4-VALIDATION.md` and `.planning/phases/4-VERIFICATION.md`, using the existing Phase 4 summaries and current test surface to map and record proof for the covered requirements.
    Update `.planning/REQUIREMENTS.md` so the Phase 4 requirement rows distinguish the closed evidence-backed requirements from the still-open `LIF-02` flow defect.
    Follow `.planning/phases/2-VALIDATION.md` and `.planning/phases/3-VALIDATION.md` as validation analogs, plus `.planning/phases/4-PLAN-CHECK.md` as the closest local verification-report analog, as mapped in `.planning/phases/5-PATTERNS.md`.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/router_test.exs</automated>
  </verify>
  <done>Phase 4 has auditable proof for `LIF-01`, `LIF-03`, and `LIF-04` without masking the `LIF-02` repair-closure gap.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Re-run the milestone audit and record the remaining deferred gaps explicitly</name>
  <files>.planning/v1-v1-MILESTONE-AUDIT.md, .planning/REQUIREMENTS.md</files>
  <behavior>
    - The milestone audit is regenerated or updated from the current repo state after all Phase 5 evidence artifacts exist.
    - Orphaned requirements for the Phase 5-owned set no longer appear in the final audit.
    - The final audit still reports the real deferred implementation gaps for Phase 6 and Phase 7 rather than pretending milestone perfection.
  </behavior>
  <action>
    Re-run the milestone audit as an explicit repo-local procedure:
    1. run `mix compile --warnings-as-errors`,
    2. run `mix test`,
    3. read `.planning/REQUIREMENTS.md`,
    4. read summary frontmatter from `.planning/phases/*-SUMMARY.md` via `requirements-completed`,
    5. read `.planning/phases/0-VERIFICATION.md` through `.planning/phases/4-VERIFICATION.md`,
    6. then rewrite `.planning/v1-v1-MILESTONE-AUDIT.md` from that fresh evidence chain.
    Ensure the final artifact refreshes the `audited:` timestamp from the current baseline, removes `orphaned` status for the Phase 5-owned requirements from both the YAML `gaps.requirements` entries and the markdown coverage table, preserves `FND-01`, `FND-02`, `ENG-03`, and `LIF-02` as deferred or open implementation gaps, and leaves `REQUIREMENTS.md` synchronized with the post-audit state.
  </action>
  <verify>
    <automated>rg -n '^audited:' .planning/v1-v1-MILESTONE-AUDIT.md && ! rg -n '^audited: 2026-05-20T18:58:00\\+02:00$' .planning/v1-v1-MILESTONE-AUDIT.md && ! rg -U -n 'id: "(FND-03|WRK-01|WRK-02|WRK-03|ENG-01|ENG-02|WF-01|WF-02|WF-03|LIF-01|LIF-03|LIF-04)"\n\\s+status: "orphaned"' .planning/v1-v1-MILESTONE-AUDIT.md && ! rg -n '^\| (FND-03|WRK-01|WRK-02|WRK-03|ENG-01|ENG-02|WF-01|WF-02|WF-03|LIF-01|LIF-03|LIF-04) .* orphaned \|$' .planning/v1-v1-MILESTONE-AUDIT.md && rg -n "FND-01|FND-02|ENG-03|LIF-02" .planning/v1-v1-MILESTONE-AUDIT.md .planning/REQUIREMENTS.md</automated>
  </verify>
  <done>The milestone audit reflects successful evidence closure for the Phase 5 scope and preserves the explicit backlog of real deferred defects.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Phase 4 evidence closure -> live defect backlog | Closing proof for repaired requirements must not erase the still-open incident-retirement defect. |
| Audit rerun -> final milestone posture | The final audit must remain a truthful snapshot of current repo state, including remaining deferred gaps. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-5-10 | Integrity | Phase 4 closure status | mitigate | Close only `LIF-01`, `LIF-03`, and `LIF-04`; keep `LIF-02` explicitly assigned to Phase 7 in verification and requirements. |
| T-5-11 | Repudiation | milestone audit rerun | mitigate | Re-run the audit after all evidence files exist and preserve unresolved Phase 6/7 defects in the final report. |
</threat_model>

<verification>
mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/router_test.exs
rg -n '^audited:' .planning/v1-v1-MILESTONE-AUDIT.md
! rg -n '^audited: 2026-05-20T18:58:00\\+02:00$' .planning/v1-v1-MILESTONE-AUDIT.md
! rg -U -n 'id: "(FND-03|WRK-01|WRK-02|WRK-03|ENG-01|ENG-02|WF-01|WF-02|WF-03|LIF-01|LIF-03|LIF-04)"\n\\s+status: "orphaned"' .planning/v1-v1-MILESTONE-AUDIT.md
! rg -n '^\| (FND-03|WRK-01|WRK-02|WRK-03|ENG-01|ENG-02|WF-01|WF-02|WF-03|LIF-01|LIF-03|LIF-04) .* orphaned \|$' .planning/v1-v1-MILESTONE-AUDIT.md
rg -n "FND-01|FND-02|ENG-03|LIF-02" .planning/v1-v1-MILESTONE-AUDIT.md .planning/REQUIREMENTS.md
</verification>

<success_criteria>
Phase 4 has complete evidence artifacts for `LIF-01`, `LIF-03`, and `LIF-04`, the final milestone audit no longer shows orphaned requirements for the Phase 5-owned set, and the remaining Phase 6/7 defects stay explicitly open.
</success_criteria>

<output>
After completion, create `.planning/phases/5-05-SUMMARY.md`
</output>
