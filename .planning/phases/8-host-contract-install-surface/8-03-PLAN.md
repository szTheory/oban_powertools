---
phase: 8
plan: 03
type: execute
wave: 2
depends_on: ["8-01", "8-02"]
files_modified: ["lib/oban_powertools/telemetry.ex", "test/oban_powertools/telemetry_test.exs", "README.md", ".planning/phases/8-host-contract-install-surface/8-VALIDATION.md"]
autonomous: true
requirements: ["POL-03", "PKG-01", "HST-01"]
must_haves:
  truths:
    - "Operators and host integrators can read one public telemetry contract covering event families, measurements, and low-cardinality metadata boundaries."
    - "The host install README describes the exact generator path, supervision ownership, route mount boundary, and optional bridge shape that Phase 8 freezes."
    - "Phase 8 validation artifacts point at the exact proof commands and contract tests that guard the public host surface."
  artifacts:
    - path: "lib/oban_powertools/telemetry.ex"
      provides: "Public telemetry contract surface"
      contains: "operator_action"
    - path: "test/oban_powertools/telemetry_test.exs"
      provides: "Telemetry family and metadata-boundary proof"
      contains: "count"
    - path: "README.md"
      provides: "Host install, supervision, route, optional-bridge, and telemetry contract guidance"
      contains: "mix oban_powertools.install"
  key_links:
    - from: "Telemetry wrapper"
      to: "README telemetry contract"
      via: "same event families and metadata-key boundaries"
      pattern: "code surface == docs surface == tests"
    - from: "README install steps"
      to: "Phase 8 plan proofs"
      via: "installer config, application supervision, router mount"
      pattern: "host follows README -> tests prove same contract"
---

<objective>
Lock Phase 8’s public docs and telemetry API so the host contract becomes visible outside the source tree: the README names the install/mount/supervision contract, the telemetry wrapper exposes the documented schema, and validation artifacts point at the exact proof commands.

Purpose: close POL-03 and turn the code-level contract from Plans 01-02 into documented public API without adding Phase 9 policy scope.
Output: public telemetry contract in code/tests, README sections for install and mount ownership, and updated Phase 8 validation steps.
</objective>

<execution_context>
@/Users/jon/.codex/get-shit-done/workflows/execute-plan.md
@/Users/jon/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/MILESTONE-ARC.md
@.planning/phases/8-host-contract-install-surface/8-RESEARCH.md
@.planning/phases/8-host-contract-install-surface/8-PATTERNS.md
@.planning/phases/8-host-contract-install-surface/8-VALIDATION.md
@README.md
@lib/oban_powertools/telemetry.ex
@test/oban_powertools/telemetry_test.exs
@.planning/phases/8-host-contract-install-surface/8-01-PLAN.md
@.planning/phases/8-host-contract-install-surface/8-02-PLAN.md

<interfaces>
From `lib/oban_powertools/telemetry.ex`:
```elixir
def execute_operator_action(event_suffix, measurements \\ %{}, metadata \\ %{})
def execute_limiter_event(event_suffix, measurements \\ %{}, metadata \\ %{})
def execute_cron_event(event_suffix, measurements \\ %{}, metadata \\ %{})
def execute_workflow_event(event_suffix, measurements \\ %{}, metadata \\ %{})
def execute_lifeline_event(event_suffix, measurements \\ %{}, metadata \\ %{})
```

Current emitted metadata unions from repo grep:
```text
operator_action -> action, source
limiter -> action, blocker_code, resource, scope
cron -> action, source, overlap_policy, catch_up_policy
workflow -> status, state
lifeline -> action, incident_class, target_type, outcome, archived_count, pruned_count
```
</interfaces>
</context>

<tasks>

<task type="execute" tdd="true">
  <name>Task 1: Freeze the telemetry public API in code and tests</name>
  <files>lib/oban_powertools/telemetry.ex, test/oban_powertools/telemetry_test.exs</files>
  <read_first>
    - lib/oban_powertools/telemetry.ex
    - test/oban_powertools/telemetry_test.exs
    - lib/oban_powertools/cron.ex
    - lib/oban_powertools/lifeline.ex
    - lib/oban_powertools/limits.ex
    - lib/oban_powertools/workflow/runtime.ex
    - .planning/phases/8-host-contract-install-surface/8-RESEARCH.md
    - .planning/phases/8-host-contract-install-surface/8-PATTERNS.md
  </read_first>
  <acceptance_criteria>
    - `lib/oban_powertools/telemetry.ex` documents all five public event families: `operator_action`, `limiter`, `cron`, `workflow`, and `lifeline`
    - `lib/oban_powertools/telemetry.ex` documents `count` as the public measurement and lists the allowed metadata keys per family
    - `test/oban_powertools/telemetry_test.exs` asserts the documented families or contract map exactly matches the public API
    - `test/oban_powertools/telemetry_test.exs` includes coverage for cron and lifeline metadata boundaries in addition to the existing operator/limiter/workflow examples
  </acceptance_criteria>
  <action>
    Extend `lib/oban_powertools/telemetry.ex` so Phase 8 exposes one public contract surface for telemetry. Use concrete values from the current emitters: families `[:operator_action, :limiter, :cron, :workflow, :lifeline]`, measurement key `:count`, and these low-cardinality metadata unions only:
    `operator_action -> [:action, :source]`
    `limiter -> [:action, :blocker_code, :resource, :scope]`
    `cron -> [:action, :source, :overlap_policy, :catch_up_policy]`
    `workflow -> [:status, :state]`
    `lifeline -> [:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]`
    Expose the contract in a stable, testable way such as a `contract/0` function, module attribute rendered in docs, or equivalent public surface. Do not widen the public API to IDs, job args, preview tokens, or free-form reasons.
    Expand `test/oban_powertools/telemetry_test.exs` so it locks the contract surface and adds emit/receive coverage for at least one `execute_cron_event/3` and one `execute_lifeline_event/3` case using only the documented metadata keys.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/telemetry_test.exs -x</automated>
  </verify>
  <done>Telemetry is now a documented and tested public API rather than an implicit wrapper convention.</done>
</task>

<task type="execute">
  <name>Task 2: Publish the Phase 8 host contract in README and validation artifacts</name>
  <files>README.md, .planning/phases/8-host-contract-install-surface/8-VALIDATION.md</files>
  <read_first>
    - README.md
    - .planning/phases/8-host-contract-install-surface/8-VALIDATION.md
    - .planning/phases/8-host-contract-install-surface/8-RESEARCH.md
    - .planning/phases/8-host-contract-install-surface/8-01-PLAN.md
    - .planning/phases/8-host-contract-install-surface/8-02-PLAN.md
    - lib/mix/tasks/oban_powertools.install.ex
    - lib/oban_powertools/application.ex
    - lib/oban_powertools/web/router.ex
    - lib/oban_powertools/telemetry.ex
  </read_first>
  <acceptance_criteria>
    - `README.md` contains `mix oban_powertools.install`
    - `README.md` contains `config :oban_powertools`
    - `README.md` contains `/ops/jobs` and `/ops/jobs/oban`
    - `README.md` explicitly documents that `mix oban_powertools.install` generates the Powertools Ecto migrations the host must run
    - `README.md` names `ObanPowertools.Application` and `ObanPowertools.Lifeline.HeartbeatWriter`
    - `.planning/phases/8-host-contract-install-surface/8-VALIDATION.md` references `test/oban_powertools/application_test.exs`, `test/oban_powertools/web/router_test.exs`, and `test/oban_powertools/telemetry_test.exs`
    - `.planning/phases/8-host-contract-install-surface/8-VALIDATION.md` sets `nyquist_compliant: true`
    - `.planning/phases/8-host-contract-install-surface/8-VALIDATION.md` sets `wave_0_complete: true`
    - `.planning/phases/8-host-contract-install-surface/8-VALIDATION.md` updates `Approval:` from `pending`
  </acceptance_criteria>
  <action>
    Replace the placeholder README installation section with the Phase 8 public contract, using exact host-facing steps and values:
    1. add `{:oban_powertools, "~> 0.1.0"}` and optional `{:oban_web, "~> 2.10", optional: true}` deps;
    2. run `mix oban_powertools.install`;
    3. explicitly say that the generator creates the Powertools migrations for audit, idempotency, smart-engine, workflow, and lifeline tables and that the host must run those migrations as part of installation;
    4. show the required `config :oban_powertools, repo: MyApp.Repo, auth_module: MyAppWeb.ObanPowertoolsAuth`;
    5. show the host-owned router scope snippet mounting `ObanPowertools.Web.Router.oban_powertools_routes("/oban")` under `/ops/jobs`;
    6. state that `ObanPowertools.Application` owns internal supervision and only starts `ObanPowertools.Lifeline.HeartbeatWriter` when repo wiring exists;
    7. state that `/ops/jobs/oban` appears only when `oban_web` is installed, and resolver/policy seams are deferred to Phase 9;
    8. include the telemetry family table from Task 1.
    Update `8-VALIDATION.md` so the task map and Wave 0 section reflect the actual Phase 8 proof set after implementation: `test/oban_powertools/application_test.exs`, `test/oban_powertools/web/router_test.exs`, `test/oban_powertools/telemetry_test.exs`, and the combined quick-run command.
    After the proof set is aligned, explicitly flip the validation artifact into its completed Phase 8 state by setting `nyquist_compliant: true`, `wave_0_complete: true`, and replacing `Approval: pending` with a dated approval line. Remove stale pending/W0 markers once the file references the implemented tests and commands.
  </action>
  <verify>
    <automated>rg -n "mix oban_powertools.install|config :oban_powertools|/ops/jobs|/ops/jobs/oban|ObanPowertools.Application|ObanPowertools.Lifeline.HeartbeatWriter|migrations|audit|idempotency|workflow|lifeline" README.md && rg -n "test/oban_powertools/application_test.exs|test/oban_powertools/web/router_test.exs|test/oban_powertools/telemetry_test.exs|test/mix/tasks/oban_powertools.install_test.exs|nyquist_compliant: true|wave_0_complete: true|Approval: approved" .planning/phases/8-host-contract-install-surface/8-VALIDATION.md && mix test test/oban_powertools/application_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/telemetry_test.exs test/mix/tasks/oban_powertools.install_test.exs</automated>
  </verify>
  <done>The host contract is visible in README and the phase validation artifact points at the exact automated proof that guards it.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Library telemetry -> host observers | Public events must stay low-cardinality and must not leak sensitive or unbounded metadata. |
| README/public docs -> host adoption | Public docs must describe the exact install, supervision, and mount contract that the code and tests prove. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-8-07 | Information Disclosure | telemetry metadata contract | mitigate | Freeze the allowed metadata keys per family and explicitly exclude IDs, args, tokens, and free-form reasons from the public API. |
| T-8-08 | Denial of Service | telemetry schema drift | mitigate | Treat event families and measurement keys as public API in code/tests so breaking schema changes fail quickly. |
| T-8-09 | Spoofing / support-truth confusion | README host contract | mitigate | Keep README install/mount/supervision instructions aligned with the code and validation artifact so adopters are not misled by placeholder docs. |
</threat_model>

<verification>
mix test test/oban_powertools/application_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/telemetry_test.exs test/mix/tasks/oban_powertools.install_test.exs
</verification>

<success_criteria>
Phase 8 ends with one public host contract: README, telemetry code, tests, and validation artifacts all describe the same install, mount, supervision, and telemetry surface.
</success_criteria>

<output>
After completion, create `.planning/phases/8-host-contract-install-surface/8-03-SUMMARY.md`
</output>
