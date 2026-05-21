---
phase: 8
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: ["lib/mix/tasks/oban_powertools.install.ex", "lib/oban_powertools/runtime_config.ex", "lib/oban_powertools/application.ex", "lib/oban_powertools/lifeline/heartbeat_writer.ex", "test/mix/tasks/oban_powertools.install_test.exs", "test/oban_powertools/application_test.exs"]
autonomous: true
requirements: ["PKG-01", "HST-01"]
must_haves:
  truths:
    - "A host that runs `mix oban_powertools.install` gets explicit config, supervision, and route wiring instead of hidden library defaults."
    - "Booting a host without `config :oban_powertools, repo: ...` does not crash the library application through an accidental HeartbeatWriter start."
    - "The library still fails fast with one explicit repo setup error when HeartbeatWriter or another persistence-backed runtime service is started directly without host wiring."
  artifacts:
    - path: "lib/oban_powertools/application.ex"
      provides: "Deterministic boot-time child inclusion for `ObanPowertools.Lifeline.HeartbeatWriter`"
      contains: "maybe_add_heartbeat_writer"
    - path: "lib/oban_powertools/lifeline/heartbeat_writer.ex"
      provides: "Shared repo setup contract for the heartbeat child"
      contains: "RuntimeConfig.repo!"
    - path: "test/oban_powertools/application_test.exs"
      provides: "Proof for configured vs unconfigured supervision posture"
      contains: "HeartbeatWriter"
  key_links:
    - from: "Mix.Tasks.ObanPowertools.Install"
      to: "ObanPowertools.RuntimeConfig"
      via: "explicit `config :oban_powertools, repo: ..., auth_module: ...` output"
      pattern: "host wires repo -> runtime contract resolves repo"
    - from: "ObanPowertools.Application"
      to: "ObanPowertools.Lifeline.HeartbeatWriter"
      via: "conditional child inclusion"
      pattern: "configured repo includes child, missing repo omits child"
---

<objective>
Freeze the host-owned install and supervision contract so Phase 8 makes boot-time behavior explicit: installer output stays deterministic, the library supervisor owns child wiring, and `HeartbeatWriter` only participates when the host has configured the required repo.

Purpose: close the hidden boot-time DoS seam called out in Phase 8 research without moving supervision ownership out of `ObanPowertools.Application`.
Output: one deterministic install/supervision contract in code and tests covering `ObanPowertools.Application`, `ObanPowertools.Lifeline.HeartbeatWriter`, and the installer path.
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
@.planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
@.planning/phases/6-runtime-config-authorization-hardening/6-RESEARCH.md
@lib/mix/tasks/oban_powertools.install.ex
@lib/oban_powertools/runtime_config.ex
@lib/oban_powertools/application.ex
@lib/oban_powertools/lifeline/heartbeat_writer.ex
@test/mix/tasks/oban_powertools.install_test.exs

<interfaces>
From `lib/oban_powertools/runtime_config.ex`:
```elixir
def repo(opts \\ [])
def repo!(opts \\ [])
def auth_module(opts \\ [])
def auth_module!(opts \\ [])
```

From `lib/oban_powertools/application.ex`:
```elixir
@impl true
def start(_type, _args)
defp maybe_add_heartbeat_writer(children)
```

From `lib/oban_powertools/lifeline/heartbeat_writer.ex`:
```elixir
def start_link(opts \\ [])
@impl true
def init(opts)
```
</interfaces>
</context>

<tasks>

<task type="execute" tdd="true">
  <name>Task 1: Freeze the boot-time supervision contract around `ObanPowertools.Application` and `ObanPowertools.Lifeline.HeartbeatWriter`</name>
  <files>lib/oban_powertools/application.ex, lib/oban_powertools/lifeline/heartbeat_writer.ex, lib/oban_powertools/runtime_config.ex, test/oban_powertools/application_test.exs</files>
  <read_first>
    - lib/oban_powertools/application.ex
    - lib/oban_powertools/lifeline/heartbeat_writer.ex
    - lib/oban_powertools/runtime_config.ex
    - test/oban_powertools/auth_test.exs
    - .planning/phases/8-host-contract-install-surface/8-RESEARCH.md
    - .planning/phases/8-host-contract-install-surface/8-PATTERNS.md
    - .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
  </read_first>
  <acceptance_criteria>
    - `lib/oban_powertools/application.ex` conditionally appends `ObanPowertools.Lifeline.HeartbeatWriter` only when `ObanPowertools.RuntimeConfig.repo()` returns a repo
    - `lib/oban_powertools/lifeline/heartbeat_writer.ex` uses `RuntimeConfig.repo!(opts)` instead of `Application.fetch_env!(:oban_powertools, :repo)`
    - `test/oban_powertools/application_test.exs` proves missing `:repo` omits the heartbeat child from the supervisor without crashing app start
    - `test/oban_powertools/application_test.exs` proves direct heartbeat startup without a repo still raises the shared runtime-config error
  </acceptance_criteria>
  <action>
    Implement the explicit supervision choice recommended by Phase 8 research and Pattern Map lines about deterministic child omission: keep supervision library-owned, but make `ObanPowertools.Application.maybe_add_heartbeat_writer/1` gate child inclusion on `ObanPowertools.RuntimeConfig.repo()` being present rather than always starting the child and letting `Application.fetch_env!` crash at boot.
    Update `ObanPowertools.Lifeline.HeartbeatWriter.init/1` to resolve the repo through `ObanPowertools.RuntimeConfig.repo!(opts)` so manual or test startup still fails fast with the shared repo setup error from Phase 6 D-08 through D-12.
    Create `test/oban_powertools/application_test.exs` with concrete coverage for three states: configured repo includes the heartbeat child, missing repo lets `ObanPowertools.Application.start(:normal, [])` succeed without the heartbeat child, and `ObanPowertools.Lifeline.HeartbeatWriter.start_link(interval_ms: 5, provider: fn -> [] end)` raises the exact repo setup error when no repo is configured.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/application_test.exs -x</automated>
  </verify>
  <done>The library boot contract is explicit: missing host repo wiring no longer causes an accidental app-start crash, while direct persistence-backed runtime usage still fails with one intentional setup error.</done>
</task>

<task type="execute" tdd="true">
  <name>Task 2: Freeze the installer’s host-owned supervision wiring story</name>
  <files>lib/mix/tasks/oban_powertools.install.ex, test/mix/tasks/oban_powertools.install_test.exs</files>
  <read_first>
    - lib/mix/tasks/oban_powertools.install.ex
    - test/mix/tasks/oban_powertools.install_test.exs
    - lib/oban_powertools/application.ex
    - .planning/phases/8-host-contract-install-surface/8-RESEARCH.md
    - .planning/phases/8-host-contract-install-surface/8-PATTERNS.md
    - .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
  </read_first>
  <acceptance_criteria>
    - `lib/mix/tasks/oban_powertools.install.ex` contains explicit install-path text for `config :oban_powertools`, `repo:`, and `auth_module:`
    - `lib/mix/tasks/oban_powertools.install.ex` contains host-contract copy that names `ObanPowertools.Application` and `ObanPowertools.Lifeline.HeartbeatWriter`
    - `test/mix/tasks/oban_powertools.install_test.exs` asserts the installer source still contains the expected Powertools migration generation calls or migration table contracts for audit, idempotency, smart-engine, workflow, and lifeline tables
    - `test/mix/tasks/oban_powertools.install_test.exs` asserts the install source contains the supervision-contract copy in addition to config keys
    - `mix test test/mix/tasks/oban_powertools.install_test.exs -x` exits 0
  </acceptance_criteria>
  <action>
    Extend the install task’s generated config/comment contract so the paved road explicitly says the host owns `config :oban_powertools, repo: ..., auth_module: ...`, while `ObanPowertools.Application` owns the internal heartbeat child and starts `ObanPowertools.Lifeline.HeartbeatWriter` only after repo wiring exists.
    Keep this contract inside the single `igniter/1` pipeline per PKG-01 and Phase 6 D-03 through D-07; do not add repo inference, fallback discovery, or a second install path.
    Update `test/mix/tasks/oban_powertools.install_test.exs` so it locks the exact public contract strings for config keys plus the supervision statement, and also treats migration generation as part of the public generator contract by asserting the installer still emits the expected Powertools migration wiring for audit, idempotency, smart-engine, workflow, and lifeline persistence.
    If the existing migration tests already cover the concrete tables, tighten them so they clearly function as the PKG-01 deterministic migration proof rather than leaving migration coverage implicit.
  </action>
  <verify>
    <automated>rg -n "setup_migration|setup_smart_engine_migrations|setup_workflow_migrations|setup_phase_4_migrations" lib/mix/tasks/oban_powertools.install.ex && mix test test/mix/tasks/oban_powertools.install_test.exs -x</automated>
  </verify>
  <done>The installer now states the host-owned config and library-owned supervision contract explicitly, and tests prevent silent drift.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Host config -> library OTP boot | Missing `:repo` must not become an accidental boot-time denial of service through unconditional child start. |
| Installer output -> host supervision expectations | The generated install path must say exactly what the host owns and what the library supervises. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-8-01 | Denial of Service | `ObanPowertools.Application` / `ObanPowertools.Lifeline.HeartbeatWriter` | mitigate | Gate heartbeat child inclusion on configured repo presence and keep direct child startup on the shared `RuntimeConfig.repo!` fail-fast path. |
| T-8-02 | Tampering | installer/runtime contract | mitigate | Freeze exact host-owned config keys and supervision copy in installer source tests so hidden defaults cannot drift in. |
| T-8-03 | Repudiation | install/support contract | mitigate | Make the public install contract grep-able in installer source and prove it with ExUnit assertions. |
</threat_model>

<verification>
mix test test/oban_powertools/application_test.exs test/mix/tasks/oban_powertools.install_test.exs
</verification>

<success_criteria>
Phase 8 makes the supervision contract explicit: installed hosts know they own config, the library owns supervision, and missing repo wiring no longer crashes boot through an unintended HeartbeatWriter path.
</success_criteria>

<output>
After completion, create `.planning/phases/8-host-contract-install-surface/8-01-SUMMARY.md`
</output>
