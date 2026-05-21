---
phase: 6
plan: 03
type: execute
wave: 3
depends_on: ["Phase 6 Plan 01", "Phase 6 Plan 02"]
files_modified: ["test/oban_powertools/auth_test.exs", "test/oban_powertools/cron_test.exs", "test/oban_powertools/web/live/cron_live_test.exs", ".planning/phases/6-runtime-config-authorization-hardening/6-VERIFICATION.md", ".planning/REQUIREMENTS.md", ".planning/v1-v1-MILESTONE-AUDIT.md"]
autonomous: true
requirements: ["FND-01", "FND-02", "ENG-03"]
must_haves:
  truths:
    - "Phase 6 ends with explicit evidence that the installer/runtime wiring gap and cron preview auth gap are closed."
    - "Verification proves behavior in host-app-like conditions instead of only passing through test-global config."
    - "Phase 6 closure updates requirements and audit artifacts without touching the unrelated Phase 7 incident-retirement gap."
  artifacts:
    - path: ".planning/phases/6-runtime-config-authorization-hardening/6-VERIFICATION.md"
      provides: "fresh phase proof"
      contains: "FND-01"
    - path: ".planning/REQUIREMENTS.md"
      provides: "closure status updates"
      contains: "Phase 6"
    - path: ".planning/v1-v1-MILESTONE-AUDIT.md"
      provides: "reduced deferred gap set"
      contains: "LIF-02"
  key_links:
    - from: "new runtime/auth tests"
      to: "requirements and audit closure"
      via: "fresh verification evidence"
      pattern: "implement -> verify -> close"
---

<objective>
Prove the Phase 6 fixes under host-like conditions and close the remaining Phase 6-owned requirement gaps in the planning artifacts.
</objective>

<execution_context>
@$HOME/.codex/get-shit-done/workflows/execute-plan.md
@$HOME/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/v1-v1-MILESTONE-AUDIT.md
@.planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
@.planning/phases/6-runtime-config-authorization-hardening/6-RESEARCH.md
@.planning/phases/6-runtime-config-authorization-hardening/6-VALIDATION.md
</context>

<tasks>

<task type="execute" tdd="true">
  <name>Task 1: Add host-like verification coverage for runtime wiring and cron authorization closure</name>
  <files>test/oban_powertools/auth_test.exs, test/oban_powertools/cron_test.exs, test/oban_powertools/web/live/cron_live_test.exs</files>
  <read_first>
    - test/oban_powertools/auth_test.exs
    - test/oban_powertools/cron_test.exs
    - test/oban_powertools/web/live/cron_live_test.exs
    - config/test.exs
    - .planning/phases/6-runtime-config-authorization-hardening/6-VALIDATION.md
    - .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
  </read_first>
  <action>
    Extend the test suite so it proves host-like behavior instead of only the happy path created by global test config.
    Add env-override coverage for missing `:repo` or `:auth_module` on required surfaces, restore previous config in `on_exit`, and assert exact setup-error messages.
    Add cron-facing assertions that unauthorized preview attempts produce no preview telemetry and no preview UI state, while authorized preview/confirm flows remain green.
    Add or update cron-domain tests only where needed to prove the hardened UI flow did not break durable cron behaviors such as pause, resume, and run-now side effects.
  </action>
  <acceptance_criteria>
    - `test/oban_powertools/auth_test.exs` contains env override cleanup with `on_exit`
    - `test/oban_powertools/web/live/cron_live_test.exs` asserts no preview telemetry for unauthorized preview attempts
    - `mix test test/oban_powertools/auth_test.exs test/oban_powertools/cron_test.exs test/oban_powertools/web/live/cron_live_test.exs` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/auth_test.exs test/oban_powertools/cron_test.exs test/oban_powertools/web/live/cron_live_test.exs</automated>
  </verify>
  <done>Fresh tests prove the hardened runtime and authorization contract under realistic host-like conditions.</done>
</task>

<task type="execute" tdd="false">
  <name>Task 2: Record Phase 6 verification evidence and close the remaining audit gaps</name>
  <files>.planning/phases/6-runtime-config-authorization-hardening/6-VERIFICATION.md, .planning/REQUIREMENTS.md, .planning/v1-v1-MILESTONE-AUDIT.md</files>
  <read_first>
    - .planning/REQUIREMENTS.md
    - .planning/v1-v1-MILESTONE-AUDIT.md
    - .planning/phases/5-05-SUMMARY.md
    - .planning/phases/6-runtime-config-authorization-hardening/6-VALIDATION.md
    - .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
  </read_first>
  <action>
    Create `.planning/phases/6-runtime-config-authorization-hardening/6-VERIFICATION.md` with explicit command/result tables for `FND-01`, `FND-02`, and `ENG-03`, including the targeted test commands from the validation map and notes on what each command proves.
    Update `.planning/REQUIREMENTS.md` so `FND-01`, `FND-02`, and `ENG-03` no longer remain deferred after the Phase 6 fixes land; preserve implementation ownership and update only closure/evidence status fields in whatever structure the file currently uses at execution time.
    Rewrite `.planning/v1-v1-MILESTONE-AUDIT.md` from the new evidence chain so the only remaining open implementation gap is `LIF-02` for Phase 7.
    Do not erase the historical note that Phase 6 fixed previously deferred Phase 0 / Phase 2 defects; the final audit should still reflect causality accurately.
  </action>
  <acceptance_criteria>
    - `.planning/phases/6-runtime-config-authorization-hardening/6-VERIFICATION.md` exists and contains `FND-01`, `FND-02`, and `ENG-03`
    - `.planning/v1-v1-MILESTONE-AUDIT.md` still contains `LIF-02`
    - `.planning/v1-v1-MILESTONE-AUDIT.md` no longer reports `status: "deferred"` entries for `FND-01`, `FND-02`, or `ENG-03`
    - `.planning/REQUIREMENTS.md` no longer marks `FND-01`, `FND-02`, or `ENG-03` as `deferred`
  </acceptance_criteria>
  <verify>
    <automated>rg -n "FND-01|FND-02|ENG-03" .planning/phases/6-runtime-config-authorization-hardening/6-VERIFICATION.md .planning/REQUIREMENTS.md && rg -n "LIF-02" .planning/v1-v1-MILESTONE-AUDIT.md && ! rg -U -n 'id: "(FND-01|FND-02|ENG-03)"\n\s+status: "deferred"' .planning/v1-v1-MILESTONE-AUDIT.md && ! rg -n '^\| (FND-01|FND-02|ENG-03) .* deferred ' .planning/REQUIREMENTS.md</automated>
  </verify>
  <done>Phase 6 has a fresh verification artifact and the planning/audit surfaces reflect closure of all Phase 6-owned defects.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Test harness -> host-like contract proof | Verification must prove explicit runtime wiring and auth ordering without relying solely on global test config. |
| Fresh evidence -> milestone audit | Closure artifacts must update Phase 6-owned gaps while preserving the still-open Phase 7 defect accurately. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-6-07 | Integrity | verification evidence | mitigate | Use targeted commands with exact requirement-to-proof mapping and update the audit only after tests pass. |
| T-6-08 | Repudiation | requirement closure | mitigate | Record fresh results in `6-VERIFICATION.md` and keep implementation ownership distinct from closure phase. |
| T-6-09 | Information Disclosure | test-only assumptions | mitigate | Override env in tests to prove the contract explicitly rather than silently inheriting `config/test.exs`. |
</threat_model>

<verification>
mix test test/oban_powertools/auth_test.exs test/oban_powertools/cron_test.exs test/oban_powertools/web/live/cron_live_test.exs
rg -n "FND-01|FND-02|ENG-03" .planning/phases/6-runtime-config-authorization-hardening/6-VERIFICATION.md .planning/REQUIREMENTS.md
rg -n "LIF-02" .planning/v1-v1-MILESTONE-AUDIT.md
</verification>

<success_criteria>
Phase 6 ends with rerunnable proof that the runtime-wiring and cron preview authorization gaps are closed, and all planning artifacts reflect that closure while leaving only the unrelated Phase 7 defect open.
</success_criteria>

<output>
After completion, create `.planning/phases/6-runtime-config-authorization-hardening/6-03-SUMMARY.md`
</output>
