# Phase 8: Host Contract & Install Surface - Research

**Researched:** 2026-05-21 [VERIFIED: current session date]
**Domain:** Phoenix host integration contract for install wiring, runtime config, supervision ownership, route mounting, optional Oban Web bridge shape, and public telemetry surface. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: lib/oban_powertools/telemetry.ex]
**Confidence:** HIGH [VERIFIED: repository code/tests] [CITED: https://hexdocs.pm/igniter/Igniter.Project.Config.html] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html] [CITED: https://hexdocs.pm/telemetry/telemetry.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
No phase-local `CONTEXT.md` exists yet. Research scope was inferred from milestone requirements, roadmap language, prior phases, and current code. [VERIFIED: /Users/jon/projects/oban_powertools/.planning/phases/8-host-contract-install-surface directory state] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]

### Claude's Discretion
Infer the host contract boundaries from the existing installer, runtime config, supervision, router, tests, and milestone arc without reopening already-shipped v1 product posture. [VERIFIED: user brief] [VERIFIED: .planning/MILESTONE-ARC.md] [VERIFIED: .planning/STATE.md]

### Deferred Ideas (OUT OF SCOPE)
Alternative UI strategies, broader auth/redaction formatter design, upgrade guides, and full optional-dependency proof beyond install/routing shape remain in later phases by roadmap/traceability. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKG-01 | A Phoenix host app can install Oban Powertools through a documented, host-owned generator path that produces deterministic wiring for config, supervision, routes, and migrations. [VERIFIED: .planning/REQUIREMENTS.md] | The installer already owns auth-module generation, config injection, router scope insertion, and migration generation; Phase 8 should freeze those as the public install contract and add proof for supervision/boot posture. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: lib/oban_powertools/application.ex] |
| POL-03 | Operators and integrators can rely on a documented low-cardinality telemetry contract whose event names, measurements, and metadata boundaries are treated as public API. [VERIFIED: .planning/REQUIREMENTS.md] | The repo already centralizes telemetry emission into five prefixes with suffix-based event names; Phase 8 should document allowed measurements/metadata fields and add contract tests for the public surface. [VERIFIED: lib/oban_powertools/telemetry.ex] [VERIFIED: test/oban_powertools/telemetry_test.exs] [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| HST-01 | A host app can mount the Powertools shell and bridge routes with clear, documented ownership boundaries between library code and host router/supervision/config. [VERIFIED: .planning/REQUIREMENTS.md] | The route macro already mounts native LiveViews plus an optional `oban_dashboard/2` bridge behind `Code.ensure_loaded?`; Phase 8 should make host-owned route scope and library-owned macro internals explicit and verifiable. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: test/oban_powertools/web/router_test.exs] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html] |
</phase_requirements>

## Summary

Phase 8 is a contract-freezing phase, not a capability-building phase. The repo already contains the install generator, centralized runtime config module, library application supervisor, native route macro, optional Oban Web bridge hook, and a telemetry wrapper; the missing work is to define exactly which parts are host-owned, which parts are library-owned, and which behaviors are public API that must not drift silently. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: lib/oban_powertools/runtime_config.ex] [VERIFIED: lib/oban_powertools/application.ex] [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: lib/oban_powertools/telemetry.ex]

The most important planning consequence is that supervision belongs in this phase as much as install and routing. In a plain `mix run`, the library application currently fails to boot without `config :oban_powertools, repo: ...` because `ObanPowertools.Lifeline.HeartbeatWriter` initializes with `Application.fetch_env!(:oban_powertools, :repo)` and is supervised by default. That means the phase cannot stop at documenting generator output; it must either formalize that boot-time requirement as part of the host contract or change the supervised-child seam so missing config is an explicit, intentional posture. [VERIFIED: lib/oban_powertools/application.ex] [VERIFIED: lib/oban_powertools/lifeline/heartbeat_writer.ex] [VERIFIED: `mix run` failure in current session]

The optional Oban Web bridge should be treated narrowly in this phase. Official Oban Web docs confirm `oban_dashboard/2` supports `resolver:` and `on_mount:` hooks, while `Oban.Web.Resolver` supplies shared user/access/formatting/query-limit callbacks. Phase 8 should lock the mount path and ownership seam now, but deeper policy unification through resolver callbacks belongs to Phase 9 per roadmap scope. [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html] [VERIFIED: .planning/ROADMAP.md]

**Primary recommendation:** plan Phase 8 around three deliverables: define the host contract documentably in code/tests, make the supervision/boot prerequisite explicit and deterministic, and add contract-proof coverage for installer output, route shape, optional bridge presence, and telemetry schema. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: current repo gaps from tests/code inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency install and code generation | Host app `mix` task invocation | Library installer internals | The host chooses to run `mix oban_powertools.install`; the library owns AST-safe file generation through Igniter. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [CITED: https://hexdocs.pm/igniter/Igniter.Project.Config.html] |
| Runtime config (`:repo`, `:auth_module`) | Host app config files | Library runtime readers | The installer writes explicit host config and runtime access routes through `RuntimeConfig`. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: lib/oban_powertools/runtime_config.ex] |
| Internal background children | Library OTP application | Host-provided config inputs | `ObanPowertools.Application` starts internal children automatically, but those children depend on host-owned runtime config. [VERIFIED: lib/oban_powertools/application.ex] [VERIFIED: lib/oban_powertools/lifeline/heartbeat_writer.ex] |
| Native Powertools route tree | Host router scope/pipeline | Library route macro | The host owns where `/ops/jobs` is mounted and which browser pipeline protects it; the macro owns the LiveView route set beneath that scope. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: lib/oban_powertools/web/router.ex] |
| Optional Oban Web bridge route | Host dependency choice and router scope | Library conditional macro branch | The bridge is only mounted when `Oban.Web.Router` is available. [VERIFIED: lib/oban_powertools/web/router.ex] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html] |
| Actor resolution and action authorization | Host auth module implementation | Library mount/action helpers | `ObanPowertools.Auth` is a host-implemented behaviour and `LiveAuth` consumes it. [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: lib/oban_powertools/web/live_auth.ex] |
| Public telemetry emission surface | Library telemetry wrapper | Host-attached handlers/loggers | The library emits fixed-prefix events through `:telemetry.execute/3`; hosts decide how to observe them. [VERIFIED: lib/oban_powertools/telemetry.ex] [CITED: https://hexdocs.pm/telemetry/telemetry.html] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `igniter` | `0.8.0` released 2026-05-09 [VERIFIED: mix hex.info igniter] | AST-safe installer generation and config/router edits | The repo already uses `Igniter.Mix.Task`, `Project.Config.configure_group/6`, and Phoenix/Ecto helpers; continuing with Igniter avoids brittle string-based generators. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [CITED: https://hexdocs.pm/igniter/Igniter.Project.Config.html] |
| `phoenix_live_view` | `1.1.30` released 2026-05-05; `1.2.0-rc.2` exists but is not the stable locked version. [VERIFIED: mix hex.info phoenix_live_view] | Native Powertools shell routes and mount hooks | Current route macro and tests are built around LiveView sessions and `on_mount`. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: test/oban_powertools/web/router_test.exs] |
| `oban_web` | `2.12.4` released 2026-05-11 [VERIFIED: mix hex.info oban_web] | Optional generic jobs dashboard bridge | Official docs confirm `oban_dashboard/2`, `on_mount`, and `resolver` are the supported bridge seams. [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html] |
| `telemetry` | `1.4.2` released 2026-05-11 [VERIFIED: mix hex.info telemetry] | Public event emission API | The repo already wraps `:telemetry.execute/3` and the library should keep measurements vs metadata aligned with Telemetry conventions. [VERIFIED: lib/oban_powertools/telemetry.ex] [CITED: https://hexdocs.pm/telemetry/telemetry.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `oban` | `2.22.1` released 2026-04-30 [VERIFIED: mix hex.info oban] | Runtime engine and host-owned Oban instance behind Powertools surfaces | Use as the upstream runtime that Powertools augments; do not make Phase 8 responsible for Oban instance definition itself. [VERIFIED: mix.exs] |
| `ecto_sql` | `3.13.5` locked; `3.14.0` current on Hex as of 2026-05-19. [VERIFIED: mix hex.info ecto_sql] | Migration generation and persistence-backed host features | Use existing Ecto migration path; Phase 8 should prove generated migrations remain deterministic. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Igniter config/router editing | Manual string templates or README-only steps | Faster initially, but loses AST-safe idempotence and determinism. [VERIFIED: current installer architecture] [CITED: https://hexdocs.pm/igniter/Igniter.Project.Config.html] |
| Optional Oban Web bridge | Full native generic jobs dashboard now | Violates milestone focus and duplicates a mature OSS dashboard before policy seams stabilize. [VERIFIED: .planning/MILESTONE-ARC.md] [CITED: https://hexdocs.pm/oban_web/overview.html] |
| `:telemetry` public contract | Bespoke pubsub/logging API | Loses ecosystem-standard handler model and complicates host observability integration. [VERIFIED: lib/oban_powertools/telemetry.ex] [CITED: https://hexdocs.pm/telemetry/telemetry.html] |

**Installation:**
```elixir
defp deps do
  [
    {:oban_powertools, "~> 0.1.0"},
    {:oban_web, "~> 2.12", optional: true}
  ]
end
```
[VERIFIED: mix.exs] [VERIFIED: README.md]

**Version verification:** `mix hex.info` verified `igniter 0.8.0 (2026-05-09)`, `oban 2.22.1 (2026-04-30)`, `oban_web 2.12.4 (2026-05-11)`, `phoenix_live_view 1.1.30 (2026-05-05)`, and `telemetry 1.4.2 (2026-05-11)`. [VERIFIED: local Hex registry in current session]

## Architecture Patterns

### System Architecture Diagram

```text
Host developer
  -> adds deps in mix.exs
  -> runs `mix oban_powertools.install`
      -> installer creates host auth module
      -> installer injects `config :oban_powertools, repo/auth_module`
      -> installer injects `/ops/jobs` router scope
      -> installer generates Powertools migrations

Browser request
  -> host router `/ops/jobs` scope + browser pipeline
      -> `ObanPowertools.Web.Router.oban_powertools_routes/1`
          -> native LiveView session (`LiveAuth` on_mount)
              -> host auth module resolves actor
              -> Powertools pages read host config + repo
          -> optional `oban_dashboard/2` bridge if `oban_web` loaded
              -> shared `on_mount`
              -> later resolver/policy seam in Phase 9

OTP boot
  -> host app starts dependency applications
      -> `ObanPowertools.Application`
          -> internal children start
          -> HeartbeatWriter currently requires configured repo at init

Operator action
  -> Powertools page/service
      -> durable DB/audit write
      -> `ObanPowertools.Telemetry` emits fixed-prefix event
      -> host handlers/loggers consume event
```
[VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: lib/oban_powertools/web/live_auth.ex] [VERIFIED: lib/oban_powertools/application.ex] [VERIFIED: lib/oban_powertools/telemetry.ex] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html]

### Recommended Project Structure

```text
lib/
├── mix/tasks/oban_powertools.install.ex   # Host-facing installer contract
├── oban_powertools/runtime_config.ex      # Central runtime contract for host wiring
├── oban_powertools/application.ex         # Library-owned internal supervision
├── oban_powertools/telemetry.ex           # Public telemetry API surface
└── oban_powertools/web/
    ├── router.ex                          # Mount macro and optional bridge seam
    └── live_auth.ex                       # Host-auth consumption point
```
[VERIFIED: repository tree]

### Pattern 1: Installer as the paved road
**What:** The install task should remain the single public way to wire config, routes, and migrations into a host Phoenix app. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex]
**When to use:** Use for all day-0 installs and as the baseline contract for example-app/docs/proof. [VERIFIED: PKG-01 scope in .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: lib/mix/tasks/oban_powertools.install.ex
Igniter.Project.Config.configure_group(
  igniter,
  "config.exs",
  :oban_powertools,
  [],
  [
    {[:repo], {:code, Macro.escape(Module.concat(app_module, "Repo"))}},
    {[:auth_module], {:code, Macro.escape(auth_module_name)}}
  ]
)
```
[VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [CITED: https://hexdocs.pm/igniter/Igniter.Project.Config.html]

### Pattern 2: Host-owned outer scope, library-owned inner routes
**What:** The host owns the `/ops/jobs` scope and browser pipeline; the library macro owns the pages and optional bridge beneath it. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: lib/oban_powertools/web/router.ex]
**When to use:** Use whenever documenting or testing route ownership. [VERIFIED: HST-01 scope]
**Example:**
```elixir
# Source: lib/oban_powertools/web/router.ex
live_session :oban_powertools_native,
  on_mount: [ObanPowertools.Web.LiveAuth],
  session: %{"oban_dashboard_path" => path} do
  live("/", ObanPowertools.Web.EngineOverviewLive, :index)
  live("/cron", ObanPowertools.Web.CronLive, :index)
end

if Code.ensure_loaded?(Oban.Web.Router) do
  oban_dashboard(path, on_mount: [ObanPowertools.Web.LiveAuth])
end
```
[VERIFIED: lib/oban_powertools/web/router.ex] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html]

### Pattern 3: Telemetry wrapper as the public API
**What:** Emit all Powertools public telemetry through the wrapper module, not ad hoc `:telemetry.execute/3` calls scattered across features. [VERIFIED: lib/oban_powertools/telemetry.ex]
**When to use:** Use for any event intended to be documented as part of POL-03. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: lib/oban_powertools/telemetry.ex
def execute_cron_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute([:oban_powertools, :cron, event_suffix], measurements, metadata)
end
```
[VERIFIED: lib/oban_powertools/telemetry.ex] [CITED: https://hexdocs.pm/telemetry/telemetry.html]

### Anti-Patterns to Avoid
- **Hidden install path:** Do not split the public setup story across README snippets, hand edits, and implicit defaults. [VERIFIED: PKG-01 wording]
- **Undocumented supervision magic:** Do not leave boot-time `:repo` failure as an accidental side effect if it is meant to be contractually required. [VERIFIED: lib/oban_powertools/lifeline/heartbeat_writer.ex] [VERIFIED: `mix run` failure in current session]
- **Route ownership blur:** Do not make the host responsible for individual internal LiveViews or library internal children. [VERIFIED: current application/router structure]
- **Unbounded telemetry metadata:** Do not let feature modules treat high-cardinality metadata as public event schema. [VERIFIED: milestone principle in .planning/MILESTONE-ARC.md] [CITED: https://hexdocs.pm/telemetry/telemetry.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Host file mutation | Regex/string-edit installer | Igniter config/router helpers | Official Igniter APIs already support grouped config insertion and Phoenix scope updates. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [CITED: https://hexdocs.pm/igniter/Igniter.Project.Config.html] |
| Oban Web policy shim | Forked dashboard or custom patch layer | `resolver:` and `on_mount:` seams | Official Oban Web exposes these hooks as supported extension points. [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html] |
| Event bus | Custom process/mailbox logger API | `:telemetry` handlers | Telemetry already formalizes event name, measurements, and metadata semantics. [CITED: https://hexdocs.pm/telemetry/telemetry.html] |

**Key insight:** Phase 8 should standardize existing seams, not invent new abstraction layers around them. [VERIFIED: current repo code structure]

## Common Pitfalls

### Pitfall 1: Treating config generation as sufficient proof
**What goes wrong:** The installer writes config and routes, but no contract test proves the exact route/bridge/supervision shape the host is expected to rely on. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: test/oban_powertools/web/router_test.exs]
**Why it happens:** Current tests only assert source fragments and native routes, not the optional bridge route or application boot posture. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: test/oban_powertools/web/router_test.exs]
**How to avoid:** Add proof for installer output, bridge route presence when `oban_web` is installed, and explicit behavior when required runtime config is absent. [VERIFIED: current gaps from repo inspection]
**Warning signs:** Planning language says “documented” without adding tests that lock route names, config keys, and startup behavior. [VERIFIED: Phase 8 requirement wording]

### Pitfall 2: Leaving supervision ownership ambiguous
**What goes wrong:** Host adopters assume they only need routes and config, but the dependency can fail at application boot if internal children require missing config. [VERIFIED: lib/oban_powertools/application.ex] [VERIFIED: lib/oban_powertools/lifeline/heartbeat_writer.ex] [VERIFIED: `mix run` failure in current session]
**Why it happens:** The library owns internal children, but that ownership boundary is not yet documented as public contract. [VERIFIED: lib/oban_powertools/application.ex]
**How to avoid:** Decide explicitly whether boot without `:repo` is unsupported or whether the internal child should be conditional, then lock that behavior in docs/tests. [VERIFIED: current repo ambiguity]
**Warning signs:** `mix run` or example-app boot fails before any operator route is hit. [VERIFIED: current session]

### Pitfall 3: Mixing telemetry schema with per-feature implementation details
**What goes wrong:** Event prefixes remain stable, but metadata keys drift feature-by-feature and become accidental breaking changes for host observers. [VERIFIED: lib/oban_powertools/telemetry.ex] [VERIFIED: event emitters found by `rg`]
**Why it happens:** The wrapper fixes only the event prefix shape today; metadata discipline is social rather than contract-tested. [VERIFIED: lib/oban_powertools/telemetry.ex] [VERIFIED: test/oban_powertools/telemetry_test.exs]
**How to avoid:** Publish allowed event names, required measurements, and permitted low-cardinality metadata keys per prefix, then assert them in tests. [VERIFIED: POL-03 wording] [CITED: https://hexdocs.pm/telemetry/telemetry.html]
**Warning signs:** New events add IDs, raw args, or unbounded reason strings into metadata. [VERIFIED: milestone principle in .planning/MILESTONE-ARC.md]

### Pitfall 4: Pulling Phase 9 bridge policy work into Phase 8
**What goes wrong:** Planning balloons into resolver/redaction/access-control design instead of stabilizing mount shape and ownership boundaries first. [VERIFIED: .planning/ROADMAP.md]
**Why it happens:** Oban Web exposes many callbacks, and it is tempting to solve all bridge policy at once. [CITED: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html]
**How to avoid:** In Phase 8, lock only route path, optionality, and shared ownership seam; defer resolver/redaction policy contract to Phase 9. [VERIFIED: Phase 9 scope in .planning/ROADMAP.md]
**Warning signs:** The plan starts introducing formatter/redaction/access modules as Phase 8 must-haves. [VERIFIED: roadmap traceability]

## Code Examples

Verified patterns from official/current sources:

### Mounting the optional Oban Web bridge with official hooks
```elixir
# Source: https://hexdocs.pm/oban_web/Oban.Web.Router.html
scope "/" do
  pipe_through :browser

  oban_dashboard "/oban",
    resolver: MyApp.Resolver,
    on_mount: [MyApp.UserHook]
end
```
[CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html]

### Defining a resolver seam for shared policy
```elixir
# Source: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html
defmodule MyApp.Resolver do
  @behaviour Oban.Web.Resolver

  def resolve_user(conn), do: conn.assigns.current_user
  def resolve_access(%{admin?: true}), do: :all
  def resolve_access(_user), do: :read_only
end
```
[CITED: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html]

### Emitting a documented telemetry event
```elixir
# Source: https://hexdocs.pm/telemetry/telemetry.html
:telemetry.execute(
  [:oban_powertools, :cron, :paused],
  %{count: 1},
  %{action: "pause", resource: "cron"}
)
```
[CITED: https://hexdocs.pm/telemetry/telemetry.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hidden or README-only host wiring | Generator-emitted host wiring with explicit config keys | Already present by Phase 6/8 codebase state. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] | Makes install deterministic and grep-able, but now needs public proof. [VERIFIED: current repo gap] |
| Ad hoc route additions per feature | One route macro mounting native shell plus optional bridge | Established before Phase 8 and still current. [VERIFIED: lib/oban_powertools/web/router.ex] | Gives one host-owned mount seam to stabilize. [VERIFIED: HST-01 scope] |
| Logging-only or feature-local observability | Telemetry-first event emission with fixed prefixes | Established in shipped v1 foundation. [VERIFIED: .planning/STATE.md] [VERIFIED: lib/oban_powertools/telemetry.ex] | Allows POL-03 to define a public observer contract instead of a private implementation detail. [VERIFIED: .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**
- Treating the README placeholder as the install story is outdated; the real install path is the generator and current README does not describe it yet. [VERIFIED: README.md] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | No unverified assumptions were required for the primary recommendations in this research. [VERIFIED: all claims trace to repo state, local commands, or official docs] | — | — |

## Open Questions (RESOLVED)

1. **Boot without `:repo` should omit the internal heartbeat child rather than crash library startup.** [RESOLVED by Phase 8 Plan 01]
   - What we knew: the current application could fail on startup because `HeartbeatWriter` fetched `:repo` during init. [VERIFIED: lib/oban_powertools/lifeline/heartbeat_writer.ex] [VERIFIED: `mix run` failure in current session]
   - Resolution: Phase 8 freezes the support-truth boundary as “host-owned config enables persistence-backed children.” `ObanPowertools.Application` remains library-owned, but `ObanPowertools.Lifeline.HeartbeatWriter` is only included when `ObanPowertools.RuntimeConfig.repo()` is present. Direct child startup still fails fast through `RuntimeConfig.repo!` so the repo requirement stays explicit at the point of persistence-backed use. [RESOLVED by `8-01-PLAN.md`]

2. **Phase 8 should add bridge-route proof only, not a resolver stub.** [RESOLVED by Phase 8 Plan 02]
   - What we knew: `oban_dashboard/2` officially supports `resolver:` and `on_mount:`; the current macro only uses `on_mount:`. [VERIFIED: lib/oban_powertools/web/router.ex] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html]
   - Resolution: Phase 8 freezes only the mount shape and ownership boundary for the optional bridge. The plan keeps shared `on_mount: [ObanPowertools.Web.LiveAuth]` proof, explicitly avoids adding `resolver:` / redaction / formatter seams here, and defers those policy contracts to Phase 9 per the roadmap split. [RESOLVED by `8-02-PLAN.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix task, app boot, tests | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Installer/tests | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL | Repo-backed tests and runtime boot validation | ✓ [VERIFIED: `pg_isready`] | `14.17` client; local server accepting on `/tmp:5432`. [VERIFIED: `psql --version`] [VERIFIED: `pg_isready`] | — |
| Hex registry access | Version verification | ✓ [VERIFIED: `mix hex.info ...`] | Current during session [VERIFIED: local command output] | — |

**Missing dependencies with no fallback:**
- None found for planning/research. [VERIFIED: current environment probes]

**Missing dependencies with fallback:**
- None found for planning/research. [VERIFIED: current environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with `Phoenix.LiveViewTest` support. [VERIFIED: test/support/live_case.ex] [VERIFIED: test/test_helper.exs] |
| Config file | none; bootstrapped through `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/auth_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/web/router_test.exs` [VERIFIED: current session test run] |
| Full suite command | `mix test` [VERIFIED: standard project test entrypoint] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PKG-01 | Installer emits deterministic config/router/migration/supervision contract | unit + integration | `mix test test/mix/tasks/oban_powertools.install_test.exs` | ✅ [VERIFIED: file exists] |
| POL-03 | Public telemetry prefixes, event names, measurements, and metadata boundaries stay stable | unit | `mix test test/oban_powertools/telemetry_test.exs` | ✅ partial [VERIFIED: file exists] |
| HST-01 | Native shell and optional bridge routes mount with explicit ownership boundaries | unit + router integration | `mix test test/oban_powertools/web/router_test.exs` | ✅ partial [VERIFIED: file exists] |

### Sampling Rate
- **Per task commit:** `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/auth_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/web/router_test.exs` [VERIFIED: current session]
- **Per wave merge:** `mix test` [VERIFIED: standard project practice]
- **Phase gate:** full suite green plus explicit host-contract proof for bridge route and startup posture. [VERIFIED: phase research recommendation]

### Wave 0 Gaps
- [ ] `test/oban_powertools/web/router_test.exs` should add explicit proof for `/ops/jobs/oban` when `oban_web` is available. [VERIFIED: current file only checks native routes]
- [ ] Add an application-boot or child-init contract test proving the chosen missing-`:repo` supervision posture. [VERIFIED: current gap from `mix run` failure]
- [ ] `test/oban_powertools/telemetry_test.exs` should assert documented metadata boundaries per public event family, not just that events emit. [VERIFIED: current file scope]
- [ ] Add host-installation proof that route/config output remains deterministic across reruns or pre-existing config cases if Phase 8 promises idempotence explicitly. [VERIFIED: install task uses Igniter group config; current tests do not cover rerun behavior]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: host auth module + LiveView mount] | Host-implemented `ObanPowertools.Auth` behaviour and shared `LiveAuth` on-mount gate. [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: lib/oban_powertools/web/live_auth.ex] |
| V3 Session Management | host-owned/indirect [VERIFIED: LiveAuth consumes session map] | Host browser/session pipeline; Powertools should document that it does not own session issuance. [VERIFIED: lib/oban_powertools/web/live_auth.ex] |
| V4 Access Control | yes [VERIFIED: native page/action auth and future bridge resolver seam] | `LiveAuth.authorize_page/3`, `authorize_action/4`, and later `Oban.Web.Resolver.resolve_access/1`. [VERIFIED: lib/oban_powertools/web/live_auth.ex] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html] |
| V5 Input Validation | yes [VERIFIED: install/config contract and route contract are operator-controlled inputs] | Explicit runtime config validation through `RuntimeConfig` plus deterministic installer generation. [VERIFIED: lib/oban_powertools/runtime_config.ex] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] |
| V6 Cryptography | no direct phase ownership [VERIFIED: phase scope] | No new crypto surface should be introduced in Phase 8. [VERIFIED: .planning/ROADMAP.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Mounting ops routes outside the intended browser/auth pipeline | Elevation of Privilege | Keep host-owned mount instructions explicit and test route shape rather than relying on implicit safe defaults. [VERIFIED: installer adds scope only; host owns pipeline] |
| Policy drift between native pages and Oban Web bridge | Elevation of Privilege / Tampering | Freeze route seam in Phase 8 and centralize bridge policy through official resolver/on_mount hooks in Phase 9. [VERIFIED: roadmap split] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Router.html] [CITED: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html] |
| Telemetry metadata leaking high-cardinality or sensitive values | Information Disclosure / DoS | Treat measurements/metadata boundaries as public API and keep durable evidence in tables rather than event payloads. [VERIFIED: .planning/MILESTONE-ARC.md] [CITED: https://hexdocs.pm/telemetry/telemetry.html] |
| Hidden boot-time config dependency | Denial of Service | Make required startup config explicit in install docs/tests or gate the child deliberately. [VERIFIED: lib/oban_powertools/lifeline/heartbeat_writer.ex] [VERIFIED: `mix run` failure in current session] |

## Sources

### Primary (HIGH confidence)
- `lib/mix/tasks/oban_powertools.install.ex` - current installer contract, config injection, route scope, migration generation. [VERIFIED: repo source]
- `lib/oban_powertools/runtime_config.ex` - centralized runtime config semantics. [VERIFIED: repo source]
- `lib/oban_powertools/application.ex` and `lib/oban_powertools/lifeline/heartbeat_writer.ex` - supervision ownership and boot-time repo dependency. [VERIFIED: repo source]
- `lib/oban_powertools/web/router.ex` and `lib/oban_powertools/web/live_auth.ex` - native route contract and shared auth mount seam. [VERIFIED: repo source]
- `lib/oban_powertools/telemetry.ex` plus emitters located by `rg` - public telemetry wrapper shape. [VERIFIED: repo source]
- `test/mix/tasks/oban_powertools.install_test.exs`, `test/oban_powertools/web/router_test.exs`, `test/oban_powertools/auth_test.exs`, `test/oban_powertools/telemetry_test.exs` - existing proof coverage and gaps. [VERIFIED: repo tests]
- `mix hex.info igniter`, `mix hex.info oban`, `mix hex.info oban_web`, `mix hex.info phoenix_live_view`, `mix hex.info telemetry`, `mix hex.info ecto_sql` - current versions and release dates. [VERIFIED: local commands]
- `mix test test/mix/tasks/oban_powertools.install_test.exs` and `mix test test/oban_powertools/auth_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/web/router_test.exs` - current baseline green. [VERIFIED: current session]

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/igniter/Igniter.Project.Config.html - `configure_group/6` semantics and grouped config insertion behavior. [CITED: official docs]
- https://hexdocs.pm/oban_web/Oban.Web.Router.html - `oban_dashboard/2`, `resolver:`, `on_mount:`, and mount options. [CITED: official docs]
- https://hexdocs.pm/oban_web/Oban.Web.Resolver.html - shared bridge policy callbacks and limits/formatting hooks. [CITED: official docs]
- https://hexdocs.pm/oban_web/Oban.Web.Telemetry.html - Oban Web action-event schema and logger surface. [CITED: official docs]
- https://hexdocs.pm/telemetry/telemetry.html - `execute/3` event, measurements, metadata, and handler conventions. [CITED: official docs]
- https://hexdocs.pm/oban_web/overview.html - current embedded dashboard posture and why bridge-first remains the milestone fit. [CITED: official docs]

### Tertiary (LOW confidence)
- None. [VERIFIED: all substantive claims tied to repo or official documentation]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were verified live against Hex and the libraries are already present in the repo. [VERIFIED: mix hex.info outputs]  
- Architecture: HIGH - ownership boundaries are directly visible in installer, router, runtime config, app supervisor, and current tests. [VERIFIED: repo code/tests]  
- Pitfalls: HIGH - the largest risks were reproduced from current behavior, including app boot failure without `:repo` and proof gaps in current tests. [VERIFIED: current session + repo inspection]

**Research date:** 2026-05-21 [VERIFIED: current session date]
**Valid until:** 2026-06-20 for planning structure; recheck Hex package versions and Oban Web docs if Phase 8 planning slips beyond 30 days. [VERIFIED: package/doc recency in current session]
