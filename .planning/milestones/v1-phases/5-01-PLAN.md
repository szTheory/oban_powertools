---
phase: 5
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [".planning/REQUIREMENTS.md", ".planning/phases/0-01-SUMMARY.md", ".planning/phases/0-VALIDATION.md", ".planning/phases/0-VERIFICATION.md"]
autonomous: true
requirements: ["FND-03"]
---

<objective>
Establish the Phase 5 traceability contract and repair the Phase 0 evidence chain so `FND-03` can be proven complete without falsely closing the Phase 6 installer/runtime gaps for `FND-01` and `FND-02`.
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
@.planning/phases/0-01-SUMMARY.md
@.planning/phases/0-VALIDATION.md
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Define explicit traceability semantics in REQUIREMENTS.md</name>
  <files>.planning/REQUIREMENTS.md</files>
  <behavior>
    - `REQUIREMENTS.md` preserves original implementation phase ownership for all requirements.
    - Requirement status semantics distinguish completed proof from deferred implementation gaps.
    - Deferred requirements assigned to Phase 6 and Phase 7 remain explicitly open instead of being papered over by Phase 5 artifact work.
  </behavior>
  <action>
    Rewrite the traceability table in `.planning/REQUIREMENTS.md` into an explicit evidence-oriented model that separates implementation owner, closure phase, and current proof status.
    Make the repo-local contract grep-able and mechanically useful for later audit reruns, while keeping `FND-01`, `FND-02`, `ENG-03`, and `LIF-02` visibly deferred to their future implementation phases.
    Follow the traceability-chain analogs called out in `.planning/phases/5-PATTERNS.md`, especially the `REQUIREMENTS.md` coverage model from `.planning/v1-v1-MILESTONE-AUDIT.md`.
  </action>
  <verify>
    <automated>rg -n "FND-03|FND-01|FND-02|ENG-03|LIF-02" .planning/REQUIREMENTS.md</automated>
  </verify>
  <done>The requirements traceability contract is explicit, phase-owned, and safe for evidence closure work.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Backfill Phase 0 summary and verification artifacts without overstating deferred gaps</name>
  <files>.planning/phases/0-01-SUMMARY.md, .planning/phases/0-VALIDATION.md, .planning/phases/0-VERIFICATION.md</files>
  <behavior>
    - Phase 0 summary frontmatter exposes machine-readable completion metadata for `FND-03`.
    - Phase 0 validation and verification artifacts clearly map requirement evidence and record that `FND-01` and `FND-02` still have real downstream defects tracked in Phase 6.
    - Fresh verification remains command-backed and does not rely on narrative alone.
  </behavior>
  <action>
    Normalize `.planning/phases/0-01-SUMMARY.md` so it carries the repo's current `requirements-completed` style metadata and visible retrospective provenance.
    Update `.planning/phases/0-VALIDATION.md` only as needed to make the requirement-to-command mapping explicit and current, then create `.planning/phases/0-VERIFICATION.md` capturing fresh results for the Phase 0 command set with `FND-03` closed and `FND-01`/`FND-02` explicitly left open for Phase 6.
    Use `.planning/phases/1-01-SUMMARY.md` as the summary-frontmatter analog and `.planning/phases/0-VALIDATION.md` plus `.planning/phases/4-PLAN-CHECK.md` as the validation and verification analogs documented in `.planning/phases/5-PATTERNS.md`.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/auth_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/web/router_test.exs</automated>
  </verify>
  <done>Phase 0 has a complete, historically honest evidence chain for `FND-03` and explicit deferred treatment for the remaining foundation gaps.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Historical implementation -> retrospective closure | Phase 5 must not rewrite who implemented a requirement or imply that deferred defects are resolved. |
| Validation map -> verification artifact | Verification must record current results and unresolved gaps rather than blindly mirroring validation intent. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-5-01 | Integrity | `REQUIREMENTS.md` traceability model | mitigate | Preserve implementation ownership and add proof status instead of reassigning completed work to Phase 5. |
| T-5-02 | Repudiation | retrospective Phase 0 normalization | mitigate | Make backfilled frontmatter and verification provenance explicit in the repaired artifacts. |
| T-5-03 | Tampering | deferred foundation gaps | mitigate | Keep `FND-01` and `FND-02` visibly open in verification and requirements artifacts. |
</threat_model>

<verification>
rg -n "FND-03|FND-01|FND-02|ENG-03|LIF-02" .planning/REQUIREMENTS.md
mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/auth_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/web/router_test.exs
</verification>

<success_criteria>
The repo has an explicit traceability contract, Phase 0 can prove `FND-03` with fresh evidence, and the still-open foundation defects remain clearly deferred to Phase 6.
</success_criteria>

<output>
After completion, create `.planning/phases/5-01-SUMMARY.md`
</output>
