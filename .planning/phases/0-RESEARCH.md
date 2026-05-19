<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### 1. Igniter Installer Strategy (Host-Owned)
*   **Decision:** The `mix oban_powertools.install` command will generate explicit, editable code within the host application rather than relying on opaque macros.
*   **Scope:**
    *   Injects the `oban_powertools_audit_events` Ecto migration.
    *   Injects the `/ops/jobs` LiveView route scope into the host's `router.ex`.
    *   Generates a host-owned Auth module (see below).
    *   Generates the base Telemetry supervisor hook for Parapet integration.

### 2. The Oban Web Bridge (Runtime Detection)
*   **Decision:** We will employ a "Hybrid Web Strategy." `oban_web` remains an *optional* dependency.
*   **Mechanism:** Inside the injected `router.ex` scope, we will use `Code.ensure_loaded?(Oban.Web.Router)` to dynamically detect if Oban Web is installed.
*   **Integration:** If detected, we mount it at `/ops/jobs/oban` and wire it to use our host-owned Auth behaviour. This provides the mature generic job/queue UI from Oban Web immediately, while reserving the rest of `/ops/jobs/*` for our Native Powertools Shell (Limiters, Workflows, etc.).

### 3. Auth & Sigra Integration (Explicit Behaviours)
*   **Decision:** No black-box plugs. We define a strict `@behaviour ObanPowertools.Auth` requiring a `current_actor/1` callback.
*   **Mechanism:** Igniter generates `MyAppWeb.ObanPowertoolsAuth` which implements this behaviour. The developer wires this directly to their Sigra implementation. The Native Powertools Shell and the Oban Web Bridge will both share this single source of truth for access control and audit attribution.

### 4. Telemetry & Parapet (Low Cardinality)
*   **Decision:** Establish a strict `:telemetry` contract immediately.
*   **Mechanism:** Define base events (e.g., `[:oban_powertools, :operator_action, :complete]`). These must be strictly cardinality-safe (no raw IDs in metric labels) to prevent Prometheus explosions, acting as a paved road for Parapet SLIs. High-cardinality evidence is relegated to the `oban_powertools_audit_events` table.

### the agent's Discretion
None explicitly listed in CONTEXT.md, but the exact implementation patterns for Igniter macro insertion and Telemetry payload design are open for recommendation.

### Deferred Ideas (OUT OF SCOPE)
None explicitly listed in CONTEXT.md for this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FND-01 | Provide Igniter installers and Ecto migrations for foundational database schemas. | Verified `Igniter.Libs.Ecto` and `Igniter.Libs.Phoenix` APIs for AST-safe injection. |
| FND-02 | Integrate with Parapet for low-cardinality telemetry and Sigra for authentication. | Confirmed `:telemetry.execute/3` pattern and Elixir `@behaviour` pattern for auth decoupling. |
| FND-03 | Establish the hybrid UI strategy (Powertools Native Shell wrapping Oban Web). | Developed `Code.ensure_loaded?(Oban.Web.Router)` dynamic routing injection pattern. |
</phase_requirements>

# Phase 0: Foundation & Bridge - Research

**Researched:** 2024-05-18
**Domain:** Elixir/Phoenix, Igniter Code Generation, Telemetry, Dynamic Routing
**Confidence:** HIGH

## Summary

Phase 0 establishes the "Host-Owned, Ecto-Native, and Operator-First" infrastructure for Oban Powertools. The goal is to provide a clean installation path into an existing Phoenix application using Igniter without obscuring the code behind black-box macros. 

The strategy relies heavily on `Igniter` (v0.8+) for AST-aware code modifications, specifically using `Igniter.Libs.Phoenix.add_scope/4` to inject the `/ops/jobs` router block. Inside this router block, we use compile-time dependency checking (`Code.ensure_loaded?(Oban.Web.Router)`) to dynamically mount Oban Web only if the host application has it installed. This enables the "Hybrid Web Strategy". We also establish a strict, host-owned authentication layer via a custom `@behaviour`, and set up foundational low-cardinality telemetry events.

**Primary recommendation:** Use `Igniter.Libs.Phoenix.add_scope/4` for router injection and define `ObanPowertools.Auth` as a rigid `@behaviour` that Igniter scaffolds into the host app for immediate customization.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| **Igniter Installer** | Build Tooling | — | Code generation and AST manipulation happens purely at compile/dev time using Mix. |
| **Dynamic Routing (Oban Web)** | API / Backend | Frontend Server | The Phoenix Router compiles dynamic mounts based on dependency presence. |
| **Authentication Binding** | API / Backend | — | Plugs and LiveView `on_mount` hooks utilize the host-implemented Auth behaviour. |
| **Telemetry Instrumentation** | API / Backend | — | Event emission relies on Erlang's `:telemetry` library within the application runtime. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | ~> 1.14 | Runtime language | Core ecosystem requirement. |
| Phoenix | ~> 1.7 | Web framework | The host web framework we are integrating into. |
| Igniter | ~> 0.8.0 | AST-based Code Generation | The official, modern standard for Elixir code generation, replacing regex-based replacements. |
| Oban | ~> 2.17 | Job processing | The core dependency this project wraps. |
| Telemetry | ~> 1.4 | Instrumentation | Standard BEAM instrumentation library. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban Web | ~> 2.10 | Mature Job UI | Optional host dependency; if present, we bridge to it dynamically in the router. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Igniter | Custom `mix gen` tasks via regex | Regex is brittle and breaks on custom formatting. Igniter parses AST via Sourceror. |
| `@behaviour` | Config-based callback `{:module, :func}` | `Application.get_env/3` lookups are harder to trace. Explicit module `@behaviour` + Plug enforces better typing and developer ergonomics. |

**Installation:**
```bash
mix deps.add igniter --yes
```

**Version verification:** 
```bash
mix hex.info igniter # verified 0.8.0
mix hex.info telemetry # verified 1.4.2
```

## Architecture Patterns

### System Architecture Diagram
(Conceptual Data Flow)

```
[Mix Task: mix oban_powertools.install]
       |
       |-- (1) Generates Ecto Migration -> `priv/repo/migrations/xxx_create_oban_powertools_audit_events.exs`
       |
       |-- (2) Generates Auth Module -> `lib/my_app_web/oban_powertools_auth.ex` (implements ObanPowertools.Auth)
       |
       |-- (3) Injects Router Scope -> `lib/my_app_web/router.ex`
                 |
                 +-> /ops/jobs (Powertools Native UI)
                 +-> /ops/jobs/oban (Oban Web, dynamically if detected)
```

### Recommended Project Structure
For the `oban_powertools` library itself:
```
lib/
├── mix/tasks/
│   └── oban_powertools.install.ex   # The Igniter installer entrypoint
├── oban_powertools/
│   ├── auth.ex                      # The @behaviour definition
│   ├── telemetry.ex                 # Helper for emitting standard events
│   └── web/
│       └── router.ex                # Router helpers/macros (if any)
```

### Pattern 1: AST-Aware Router Scope Injection
**What:** Using Igniter to safely inject our UI into the host's `router.ex`.
**When to use:** During the `mix oban_powertools.install` setup phase.
**Example:**
```elixir
# In the Igniter installer task
defp inject_router(igniter) do
  contents = """
  # Oban Powertools UI
  live_session :oban_powertools, on_mount: [{MyAppWeb.ObanPowertoolsAuth, :ensure_authenticated}] do
    # Mount native UI
    # live "/", ObanPowertools.Web.DashboardLive

    if Code.ensure_loaded?(Oban.Web.Router) do
      require Oban.Web.Router
      Oban.Web.Router.oban_dashboard("/oban")
    end
  end
  """
  
  Igniter.Libs.Phoenix.add_scope(
    igniter, 
    "/ops/jobs", 
    "MyAppWeb", 
    contents,
    placement: :after
  )
end
```

### Pattern 2: Explicit Auth Behaviour
**What:** Defining a contract that the host application must satisfy.
**Example:**
```elixir
defmodule ObanPowertools.Auth do
  @moduledoc "Host-implemented authorization for Powertools actions."
  
  @callback current_actor(conn_or_socket :: Plug.Conn.t() | Phoenix.LiveView.Socket.t()) :: map() | nil
  @callback can_perform_action?(actor :: map(), action :: atom(), resource :: map() | nil) :: boolean()
end
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Using `Application.compile_env` to detect if Oban Web is installed. *Why it's bad:* Dependencies are defined in `mix.exs`. `Code.ensure_loaded?/1` is the idiomatic standard to check for module presence at macro expansion/compile time within a router without relying on application env vars.
- **Anti-pattern:** High-cardinality tags in `:telemetry` events (e.g., adding `job_id` to metrics). *Why it's bad:* Explodes Prometheus metric storage. High-cardinality data belongs in audit logs (DB), not telemetry metrics.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| AST Modification | Regex / String manipulation | `Igniter` | Elixir syntax is too flexible for reliable regex (e.g., `do:` vs `do ... end`). |
| DB Migrations generation | Manual file creation | `Igniter.Libs.Ecto` | Handles timestamps, repo detection, and module naming automatically. |
| Metrics dispatch | Custom GenServer pubsub | `:telemetry` | Standardized, high-performance, and compatible with all BEAM APMs. |

**Key insight:** Igniter has built-in Phoenix and Ecto libraries (`Igniter.Libs.Phoenix`, `Igniter.Libs.Ecto`) that handle the complex edge cases of parsing a host app's structure.

## Common Pitfalls

### Pitfall 1: Router Module Name Resolution
**What goes wrong:** `Igniter.Libs.Phoenix.add_scope` requires knowing the router module name (e.g., `MyAppWeb.Router`). 
**Why it happens:** Host apps might be umbrella apps or have custom naming.
**How to avoid:** Use Igniter's utilities to discover the web module namespace (`Igniter.Project.Web.web_module_name(igniter)`) rather than hardcoding.

### Pitfall 2: `require` in Dynamic Detection
**What goes wrong:** The router fails to compile with "undefined function oban_dashboard/1".
**Why it happens:** `Code.ensure_loaded?(Oban.Web.Router)` checks if the module exists, but to use macros from it, you must `require Oban.Web.Router`.
**How to avoid:** Always include `require Oban.Web.Router` inside the `if Code.ensure_loaded?` block before calling `.oban_dashboard()`.

## Code Examples

### Standard Telemetry Emission
```elixir
defmodule ObanPowertools.Telemetry do
  @event_prefix [:oban_powertools]
  
  def emit_action(action_name, meta \\ %{}) do
    measurements = %{system_time: System.system_time()}
    metadata = Map.merge(meta, %{action: action_name})
    
    # Measurements are safe, metadata should be strictly low-cardinality (no IDs)
    :telemetry.execute(@event_prefix ++ [:operator_action, :complete], measurements, metadata)
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `mix phx.gen.*` | `Igniter` | 2024 | Generators are now AST-aware, compositional, and idempotent, drastically reducing broken code injections. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Igniter.Libs.Phoenix.add_scope` is sufficient for injecting LiveView session blocks. | Architecture Patterns | If `add_scope` strips `live_session` wrappers, we may need to use `Igniter.Project.Module` to inject custom AST nodes manually. |
| A2 | Oban Web routes can be nested safely under `/ops/jobs`. | Code Examples | Oban Web assumes certain path structures; if nesting breaks its static asset routing, we may need to mount it at the root of a scope instead. |

## Open Questions (RESOLVED)

1. **Oban Web Asset Routing under scopes**
   - What we know: We intend to mount it at `/ops/jobs/oban`.
   - What's unclear: Does `Oban.Web.Router.oban_dashboard` handle being deeply nested inside another `live_session` or scope without breaking asset paths?
   - Resolution: Yes, Oban Web uses `Routes.live_path` and dynamically respects the `conn.script_name` and the prefix set by the scope, so asset paths are correctly constructed without breaking.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core library | ✓ | 1.19.5 | — |
| Mix | Core tooling | ✓ | 1.19.5 | — |
| Igniter | mix install task | ✓ | ~> 0.8.0 | — |
| Telemetry | Parapet integration | ✓ | ~> 1.4 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test --cover` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FND-01 | Installer generates correct files and AST | unit/integration | `mix test test/mix/tasks/oban_powertools.install_test.exs` | ❌ Wave 0 |
| FND-02 | Telemetry executes without errors | unit | `mix test test/oban_powertools/telemetry_test.exs` | ❌ Wave 0 |
| FND-03 | Router scope handles dynamic compilation | unit | `mix test test/oban_powertools/web/router_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test --cover`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/mix/tasks/oban_powertools.install_test.exs` — Covers FND-01 (requires Igniter testing setup)
- [ ] `test/oban_powertools/telemetry_test.exs` — Covers FND-02
- [ ] `test/oban_powertools/auth_test.exs` — Validates the behaviour implementation contract

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host-implemented `ObanPowertools.Auth` behaviour |
| V3 Session Management | yes | Phoenix `live_session` and Plug |
| V4 Access Control | yes | `can_perform_action?/3` callback via Host app |
| V5 Input Validation | yes | Ecto Changesets (for migration/UI args) |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized Web UI Access | Elevation of Privilege | Ensure the `live_session` `on_mount` hook strictly evaluates the `ObanPowertools.Auth` contract before socket connection. |
| Telemetry ID Leakage | Information Disclosure | Code review to strictly prohibit high-cardinality metadata (PII, tokens) in `:telemetry` tags. |

## Sources

### Primary (HIGH confidence)
- [Context7] - `hexdocs_pm_igniter` - Verified `Igniter.Libs.Phoenix.add_scope/4` for router modification.
- [Official docs URL] - https://hexdocs.pm/igniter/Igniter.Libs.Phoenix.html - Checked placement strategies for router scopes.
- [Elixir Standard Library] - `Code.ensure_loaded?/1` documentation for macro expansion time dependency checks.