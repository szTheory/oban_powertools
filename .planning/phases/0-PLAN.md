---
phase: 0
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: ["mix.exs", "lib/oban_powertools.ex", "lib/oban_powertools/auth.ex", "lib/oban_powertools/telemetry.ex", "lib/oban_powertools/web/router.ex", "lib/mix/tasks/oban_powertools.install.ex", "test/oban_powertools/auth_test.exs", "test/oban_powertools/telemetry_test.exs", "test/oban_powertools/web/router_test.exs", "test/mix/tasks/oban_powertools.install_test.exs"]
autonomous: true
requirements: ["FND-01", "FND-02", "FND-03"]
must_haves:
  truths:
    - "Developer can run `mix oban_powertools.install` to set up the host app."
    - "Installer injects `oban_powertools_audit_events` migration, Auth module, and router scope."
    - "Oban Powertools provides a strict Auth behaviour."
    - "Telemetry baseline events are strictly low-cardinality."
    - "Hybrid web strategy dynamically detects Oban.Web.Router."
  artifacts:
    - path: "mix.exs"
      provides: "Project configuration and dependencies"
      contains: "igniter"
    - path: "lib/oban_powertools/auth.ex"
      provides: "Strict Auth behaviour definition"
      contains: "@callback current_actor"
    - path: "lib/oban_powertools/telemetry.ex"
      provides: "Telemetry wrapper"
      contains: "telemetry.execute"
    - path: "lib/oban_powertools/web/router.ex"
      provides: "Dynamic routing bridge"
      contains: "Code.ensure_loaded?"
    - path: "lib/mix/tasks/oban_powertools.install.ex"
      provides: "Igniter installer task"
      contains: "Igniter.Libs.Phoenix.add_scope"
  key_links:
    - from: "lib/mix/tasks/oban_powertools.install.ex"
      to: "host application router"
      via: "Igniter AST injection"
      pattern: "add_scope"
---

<objective>
Initialize the Oban Powertools project and establish the "Host-Owned, Ecto-Native, and Operator-First" infrastructure. This involves setting up the core package, defining the Auth behaviour, Telemetry wrapper, Hybrid Web Router logic, and building the Igniter installer.

Purpose: Provide a clean installation path into an existing Phoenix application using Igniter.
Output: Core behaviour definitions, Telemetry helper, Router bridge, and the `oban_powertools.install` mix task.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/0-CONTEXT.md
@.planning/ROADMAP.md
@.planning/phases/0-RESEARCH.md
@.planning/phases/0-PATTERNS.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Project Initialization</name>
  <files>mix.exs, lib/oban_powertools.ex</files>
  <action>
    Since this is a greenfield project, run `mix new oban_powertools --sup` in a temporary directory and move the contents to the current root, or manually create `mix.exs` and standard lib directories. Add `igniter`, `telemetry`, and `jason` as dependencies to `mix.exs`. Add `oban_web` as an optional dependency (if possible, or just document it). Run `mix deps.get`.
  </action>
  <verify>
    <automated>mix deps.get</automated>
  </verify>
  <done>The mix.exs file exists with required dependencies and compiles successfully.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Core Contracts (Auth, Telemetry, Router)</name>
  <files>lib/oban_powertools/auth.ex, lib/oban_powertools/telemetry.ex, lib/oban_powertools/web/router.ex, test/oban_powertools/auth_test.exs, test/oban_powertools/telemetry_test.exs, test/oban_powertools/web/router_test.exs</files>
  <behavior>
    - ObanPowertools.Auth must define `current_actor/1` and `can_perform_action?/3` callbacks.
    - ObanPowertools.Telemetry must emit [:oban_powertools, :operator_action, :complete] safely.
    - ObanPowertools.Web.Router must provide a macro or helper that checks Code.ensure_loaded?(Oban.Web.Router) and conditionally mounts routes.
  </behavior>
  <action>
    Create the `ObanPowertools.Auth` behaviour with standard docs.
    Create `ObanPowertools.Telemetry` to wrap `:telemetry.execute` for low-cardinality operator actions (no IDs in tags).
    Create `ObanPowertools.Web.Router` with an `oban_powertools_routes(path)` macro that injects a `live_session` and mounts the Oban web bridge if available.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/auth_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/web/router_test.exs</automated>
  </verify>
  <done>Modules are created, well-documented, and compile cleanly with passing tests.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Igniter Installer</name>
  <files>lib/mix/tasks/oban_powertools.install.ex, test/mix/tasks/oban_powertools.install_test.exs</files>
  <behavior>
    - Installer correctly handles Igniter project creation and Ecto migration generation.
    - Installer properly injects the router scope.
    - Installer sets up Auth behaviour correctly.
  </behavior>
  <action>
    Implement `Mix.Tasks.ObanPowertools.Install` using `Igniter.Mix.Task`.
    Use `Igniter.Libs.Ecto.gen_migration` to scaffold `oban_powertools_audit_events` (actor_id, action, resource, metadata) following the patterns established in `0-RESEARCH.md`.
    Use `Igniter.Project.Module.create_module` to generate `MyAppWeb.ObanPowertoolsAuth` in the host app implementing `ObanPowertools.Auth` as detailed in Pattern 2 of `0-RESEARCH.md`.
    Use `Igniter.Libs.Phoenix.add_scope` to inject `/ops/jobs` calling the router macro from Task 2 (Pattern 1 of `0-RESEARCH.md`), explicitly using `Igniter.Project.Web.web_module_name` to avoid Pitfall 1 from `0-RESEARCH.md`.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs</automated>
  </verify>
  <done>The install task is successfully defined, provides Igniter dependencies properly, and integration tests pass.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Admin -> Powertools Shell | Operators accessing the internal system tools. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-0-01 | Elevation of Privilege | ObanPowertools.Auth | mitigate | Provide clear documentation and defaults for users to secure `current_actor/1` with the strict `ObanPowertools.Auth` behaviour to deny default access. |
| T-0-02 | Information Disclosure | ObanPowertools.Telemetry | mitigate | Strictly enforce low-cardinality in telemetry tags. Do not log PII or UUIDs to telemetry metrics. |
</threat_model>

<verification>
mix format --check-formatted
mix compile --warnings-as-errors
mix test
</verification>

<success_criteria>
Core modules and `mix oban_powertools.install` task successfully compiled and fully tested. Code logic enforces the "Host-Owned, Ecto-Native" pattern.
</success_criteria>

<output>
After completion, create `.planning/phases/0-01-SUMMARY.md`
</output>