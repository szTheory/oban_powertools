---
phase: 6
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: ["lib/mix/tasks/oban_powertools.install.ex", "lib/oban_powertools/auth.ex", "lib/oban_powertools/runtime_config.ex", "lib/oban_powertools/application.ex", "test/mix/tasks/oban_powertools.install_test.exs", "test/oban_powertools/auth_test.exs"]
autonomous: true
requirements: ["FND-01", "FND-02"]
must_haves:
  truths:
    - "Host apps get an explicit `config :oban_powertools, repo: ..., auth_module: ...` integration contract from the installer."
    - "Repo and auth-module lookups route through one centralized setup contract instead of mixed direct `Application.get_env` and `fetch_env!` calls."
    - "Missing required config fails with explicit setup errors rather than silent nil/false behavior."
  artifacts:
    - path: "lib/mix/tasks/oban_powertools.install.ex"
      provides: "Explicit installer-generated runtime wiring"
      contains: "config :oban_powertools"
    - path: "lib/oban_powertools/runtime_config.ex"
      provides: "Centralized repo/auth-module contract"
      contains: "def repo!"
    - path: "test/mix/tasks/oban_powertools.install_test.exs"
      provides: "Installer source assertions"
      contains: "config :oban_powertools"
  key_links:
    - from: "installer-generated config"
      to: "runtime config helper"
      via: "explicit host-owned keys"
      pattern: "generate -> resolve -> fail fast"
---

<objective>
Establish the explicit runtime wiring contract for Powertools and make missing `:repo` / `:auth_module` failures consistent, precise, and host-visible.
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
@.planning/phases/6-runtime-config-authorization-hardening/6-PATTERNS.md
@.planning/phases/6-runtime-config-authorization-hardening/6-VALIDATION.md
</context>

<tasks>

<task type="execute" tdd="true">
  <name>Task 1: Add a centralized runtime config contract for repo and auth-module lookups</name>
  <files>lib/oban_powertools/runtime_config.ex, lib/oban_powertools/auth.ex, lib/oban_powertools/application.ex, test/oban_powertools/auth_test.exs</files>
  <read_first>
    - lib/oban_powertools/auth.ex
    - lib/oban_powertools/application.ex
    - lib/oban_powertools/audit.ex
    - lib/oban_powertools/web/live_auth.ex
    - .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
    - .planning/phases/6-runtime-config-authorization-hardening/6-RESEARCH.md
  </read_first>
  <action>
    Create `lib/oban_powertools/runtime_config.ex` with one explicit contract for resolving `:repo` and `:auth_module`.
    Implement concrete helpers such as `repo!/0`, `repo(opts)`, `auth_module!/0`, and setup-error helpers that raise explicit messages matching the Phase 6 context, including wording like `Oban Powertools requires :repo` and `Oban Powertools requires :auth_module`.
    Update `lib/oban_powertools/auth.ex` so `current_actor/1` and authorization-facing lookups no longer silently degrade when the auth module is required on web surfaces; route resolution through the new helper and preserve a narrow opt-in path only where absence is intentionally recoverable.
    Update any application boot wiring only if needed to avoid introducing an eager app-start crash for optional surfaces; the fail-fast behavior belongs at required runtime usage boundaries, not unconditional application startup.
    Extend `test/oban_powertools/auth_test.exs` with explicit env override coverage that proves the helper returns configured modules when present and raises the new setup errors when required config is missing.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/runtime_config.ex` exists and contains `def repo!` plus `def auth_module!`
    - `lib/oban_powertools/auth.ex` no longer contains `Application.get_env(:oban_powertools, :auth_module)`
    - `test/oban_powertools/auth_test.exs` contains assertions for missing-config error messages
    - `mix test test/oban_powertools/auth_test.exs` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/auth_test.exs</automated>
  </verify>
  <done>Runtime lookup behavior is centralized and produces one explicit setup story for repo/auth-module requirements.</done>
</task>

<task type="execute" tdd="true">
  <name>Task 2: Make the installer emit the explicit host runtime wiring contract</name>
  <files>lib/mix/tasks/oban_powertools.install.ex, test/mix/tasks/oban_powertools.install_test.exs</files>
  <read_first>
    - lib/mix/tasks/oban_powertools.install.ex
    - test/mix/tasks/oban_powertools.install_test.exs
    - .planning/phases/0-CONTEXT.md
    - .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
    - .planning/phases/6-runtime-config-authorization-hardening/6-PATTERNS.md
  </read_first>
  <action>
    Extend `Mix.Tasks.ObanPowertools.Install` so the generated host-app setup includes explicit `config :oban_powertools, repo: MyApp.Repo, auth_module: MyAppWeb.ObanPowertoolsAuth` guidance or injection in the same paved-road install flow that already creates the auth module and router scope.
    Keep the contract host-owned and grep-able; do not add inference from `ecto_repos`, Oban config, or runtime discovery.
    Update installer tests so they assert on the concrete `config :oban_powertools` lines and the explicit `repo:` / `auth_module:` keys in the installer source or generated template path.
  </action>
  <acceptance_criteria>
    - `lib/mix/tasks/oban_powertools.install.ex` contains `config :oban_powertools`
    - `lib/mix/tasks/oban_powertools.install.ex` contains `repo:` and `auth_module:`
    - `test/mix/tasks/oban_powertools.install_test.exs` contains an assertion for `config :oban_powertools`
    - `mix test test/mix/tasks/oban_powertools.install_test.exs` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs</automated>
  </verify>
  <done>The installer tells host applications exactly how to wire Powertools without relying on test-only config.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Host application config -> Powertools runtime | Missing or ambiguous repo/auth wiring must fail with explicit setup errors rather than hidden fallback behavior. |
| Installer output -> operator surfaces | Generated host config becomes the source of truth for later runtime and web behavior. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-6-01 | Tampering | runtime config resolution | mitigate | Centralize all repo/auth-module lookup through one helper with explicit required keys. |
| T-6-02 | Elevation of Privilege | auth-module fallback | mitigate | Replace silent falsey fallback with explicit missing-config failure on required auth-gated surfaces. |
| T-6-03 | Repudiation | installer contract | mitigate | Make host wiring grep-able and testable through explicit installer assertions. |
</threat_model>

<verification>
mix test test/oban_powertools/auth_test.exs test/mix/tasks/oban_powertools.install_test.exs
</verification>

<success_criteria>
Powertools has one explicit runtime config contract, the installer exposes it directly to host apps, and missing repo/auth wiring fails with precise setup errors instead of implicit behavior.
</success_criteria>

<output>
After completion, create `.planning/phases/6-runtime-config-authorization-hardening/6-01-SUMMARY.md`
</output>

