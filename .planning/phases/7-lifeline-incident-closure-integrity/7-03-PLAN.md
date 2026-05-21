---
phase: 7
plan: 03
type: execute
wave: 3
depends_on: ["Phase 7 Plan 01", "Phase 7 Plan 02"]
files_modified: [".planning/phases/7-lifeline-incident-closure-integrity/7-VERIFICATION.md", ".planning/REQUIREMENTS.md"]
autonomous: true
requirements: ["LIF-02"]
must_haves:
  truths:
    - "Phase 7 leaves a fresh verification artifact that proves all four D-23 closure points."
    - "The `LIF-02` traceability row no longer reports an open gap once the backend and LiveView regressions pass."
  artifacts:
    - path: ".planning/phases/7-lifeline-incident-closure-integrity/7-VERIFICATION.md"
      provides: "Fresh Phase 7 proof for backend and LiveView closure behavior"
      contains: "LIF-02"
    - path: ".planning/REQUIREMENTS.md"
      provides: "Closed traceability status for `LIF-02`"
      contains: "Phase 7"
  key_links:
    - from: "Phase 7 verification command"
      to: "LIF-02 proof row"
      via: "backend + LiveView regression evidence"
      pattern: "repair -> projection -> remount -> proof"
---

<objective>
Convert the implementation fixes into audit-grade closure evidence so `LIF-02` is closed with explicit backend and LiveView proof instead of implicit confidence from passing code alone.
</objective>

<execution_context>
@$HOME/.codex/get-shit-done/workflows/execute-plan.md
@$HOME/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/4-VERIFICATION.md
@.planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md
@.planning/phases/7-lifeline-incident-closure-integrity/7-RESEARCH.md
</context>

<tasks>

<task type="execute">
  <name>Task 1: Write the Phase 7 verification artifact with explicit D-23 proof mapping</name>
  <files>.planning/phases/7-lifeline-incident-closure-integrity/7-VERIFICATION.md</files>
  <read_first>
    - .planning/phases/4-VERIFICATION.md
    - .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md
    - test/oban_powertools/lifeline_test.exs
    - test/oban_powertools/web/live/lifeline_live_test.exs
  </read_first>
  <action>
    Create `7-VERIFICATION.md` after running the Phase 7 regression command. Record one explicit `LIF-02` row with the command output date and notes that directly enumerate the four D-23 proof points:
    successful repair retires the incident durably,
    reprojection does not keep it active without evidence,
    failed/drifted/unauthorized paths do not retire it,
    and a fresh Lifeline mount no longer shows the repaired incident in `Needs Review` while preserving closure evidence.
    Use the concrete automated command `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs`.
    Keep the artifact objective and grep-able; do not describe hypothetical browser testing or out-of-scope E2E work per D-24.
  </action>
  <acceptance_criteria>
    - `.planning/phases/7-lifeline-incident-closure-integrity/7-VERIFICATION.md` exists
    - `.planning/phases/7-lifeline-incident-closure-integrity/7-VERIFICATION.md` contains `LIF-02`
    - `.planning/phases/7-lifeline-incident-closure-integrity/7-VERIFICATION.md` contains the exact command `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs`
    - `.planning/phases/7-lifeline-incident-closure-integrity/7-VERIFICATION.md` explicitly mentions fresh mount or remount proof
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs</automated>
  </verify>
  <done>The Phase 7 verification artifact directly proves the locked closure criteria instead of leaving them implicit.</done>
</task>

<task type="execute">
  <name>Task 2: Close the `LIF-02` traceability row without changing implementation ownership</name>
  <files>.planning/REQUIREMENTS.md</files>
  <read_first>
    - .planning/REQUIREMENTS.md
    - .planning/phases/7-lifeline-incident-closure-integrity/7-VERIFICATION.md
    - .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md
    - .planning/phases/4-VERIFICATION.md
  </read_first>
  <action>
    Update the `LIF-02` row in `.planning/REQUIREMENTS.md` so the implementation owner remains Phase 4, the evidence closure phase remains Phase 7, and `Proof Status` changes from `open_gap` to `closed` after the new verification artifact is written.
    Expand the summary and verification evidence references to include the relevant Phase 7 artifacts created by execution, but do not rewrite ownership semantics or broaden the row into unrelated Phase 4/5/6 requirements.
    Keep the note concrete about what Phase 7 fixed: active incident retirement, stale reprojection prevention, and LiveView closure continuity.
  </action>
  <acceptance_criteria>
    - `.planning/REQUIREMENTS.md` contains `| LIF-02 | Phase 4 | Phase 7 | closed |`
    - `.planning/REQUIREMENTS.md` references `7-VERIFICATION.md` in the `LIF-02` row
    - `.planning/REQUIREMENTS.md` still lists `Phase 4` as the `Implementation Owner` for `LIF-02`
  </acceptance_criteria>
  <verify>
    <automated>rg -n "LIF-02|7-VERIFICATION.md|open_gap|closed" .planning/REQUIREMENTS.md .planning/phases/7-lifeline-incident-closure-integrity/7-VERIFICATION.md</automated>
  </verify>
  <done>`LIF-02` is traceably closed with Phase 7 proof while preserving historical implementation ownership.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Test evidence -> planning artifacts | Passing code must be reflected accurately in verification and requirements records. |
| Traceability table -> future audits | Requirement status must close only when the new proof artifact exists and matches the implemented behavior. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-7-08 | Repudiation | `7-VERIFICATION.md` | mitigate | Record the exact automated command and each D-23 proof point explicitly. |
| T-7-09 | Tampering | `REQUIREMENTS.md` | mitigate | Update only the `LIF-02` row and preserve Phase 4 implementation ownership while closing proof status. |
| T-7-10 | Information Disclosure / operator confusion | closure notes | mitigate | State clearly that Phase 7 closes repair retirement, reprojection, and remount integrity rather than implying a broader redesign. |
</threat_model>

<verification>
mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs
</verification>

<success_criteria>
Phase 7 ends with a fresh verification artifact and a closed `LIF-02` traceability row that both point to the exact backend and LiveView evidence.
</success_criteria>

<output>
After completion, create `.planning/phases/7-lifeline-incident-closure-integrity/7-03-SUMMARY.md`
</output>
