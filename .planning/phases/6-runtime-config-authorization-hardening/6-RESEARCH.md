# Phase 6: Runtime Config & Authorization Hardening - Research

**Researched:** 2026-05-20 [VERIFIED: current session date]
**Domain:** Explicit runtime wiring, centralized setup validation, and cron preview authorization hardening. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]
**Confidence:** HIGH [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs]

<user_constraints>
## Locked Decisions

- **D-03 to D-07:** Runtime dependencies stay host-owned and explicit; no repo inference, no `ecto_repos` fallback, and no first-repo-wins heuristics. [VERIFIED: .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md]
- **D-08 to D-12:** Missing `:repo` and `:auth_module` should fail immediately and consistently on required surfaces through one centralized validation contract. [VERIFIED: .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md]
- **D-13 to D-16:** Cron preview is privileged. Unauthorized users must not trigger preview telemetry, preview assigns, or preview-side state. [VERIFIED: .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md]
- **D-17 to D-20:** Cron actions remain visible but disabled-with-explanation for viewers lacking mutation permissions. [VERIFIED: .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md]
- **D-21 to D-23:** Keep the existing "explain, then act" posture, but make authorization a prerequisite to entering preview flows and use explicit setup-error copy for missing runtime config. [VERIFIED: .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md]

## Discretion

- Exact module placement for config helpers and error helpers, provided every repo/auth lookup routes through the same contract.
- Exact disabled-action rendering in `CronLive`, provided the explanation is inline, persistent, and testable.
- Exact verification harness shape, provided it proves host-app-like runtime behavior instead of only leaning on `config/test.exs`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FND-01 | Provide Igniter installers and Ecto migrations for foundational database schemas. [VERIFIED: .planning/REQUIREMENTS.md] | The schema portion is already implemented; the remaining gap is installer-emitted runtime wiring for repo ownership so persistence-backed surfaces do not depend on test-only config. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] |
| FND-02 | Integrate with Parapet for low-cardinality telemetry and Sigra for authentication. [VERIFIED: .planning/REQUIREMENTS.md] | Telemetry/auth primitives exist, but runtime auth-module wiring and auth-before-preview enforcement remain open. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] |
| ENG-03 | Support dynamic cron with explicit overlap and catch-up policies. [VERIFIED: .planning/REQUIREMENTS.md] | Durable cron behavior exists; the remaining requirement gap is the mutation authorization ordering on the native cron surface. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: lib/oban_powertools/cron.ex] [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs] |
</phase_requirements>

## Summary

Phase 6 is a gap-closure implementation phase, not a redesign. The durable cron engine, auth behavior, and installer entrypoint already exist; the remaining work is to remove runtime ambiguity and close one authorization loophole that lets unauthorized users enter preview state before the action is checked. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex]

The most important planning consequence is that runtime config and authorization should be treated as one integration contract rather than as scattered one-off fixes. The repo currently reads `:repo` and `:auth_module` ad hoc from multiple modules, mixing `Application.get_env/3` soft fallbacks with `Application.fetch_env!/2` hard crashes. That produces inconsistent setup failures and makes host integration invisible outside `config/test.exs`. [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/live_auth.ex] [VERIFIED: lib/oban_powertools/lifeline/heartbeat_writer.ex] [VERIFIED: config/test.exs]

**Primary recommendation:** split implementation into three slices:
1. establish a centralized runtime config contract plus installer-generated host config,
2. harden `CronLive` so authorization precedes preview state and the UI exposes disabled-with-explanation actions,
3. add host-like verification that proves missing config and unauthorized preview attempts fail in the intended way. [VERIFIED: .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md] [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Runtime dependency contract (`:repo`, `:auth_module`) | New shared config helper module in `lib/oban_powertools/` | Existing callers in web/services | The repo currently has inconsistent direct `Application.get_env` and `fetch_env!` calls; one shared helper is the simplest way to centralize explicit failures. [VERIFIED: repo grep for `Application.get_env(:oban_powertools, :repo)`] |
| Host-app integration story | `Mix.Tasks.ObanPowertools.Install` | Installer tests | The audit explicitly says the installer fails to inject required runtime config today. [VERIFIED: .planning/v1-v1-MILESTONE-AUDIT.md] [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] |
| Page/action auth boundary | `ObanPowertools.Web.LiveAuth` + `ObanPowertools.Web.CronLive` | `ObanPowertools.Auth` | `LiveAuth` already owns page/action authorization, but `CronLive` bypasses action auth on preview. [VERIFIED: lib/oban_powertools/web/live_auth.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] |
| Verification of host-like behavior | focused ExUnit/LiveView tests | verification artifact | The success criteria require proof under host-app-like conditions, not only green code paths with test-only wiring. [VERIFIED: .planning/ROADMAP.md] |

## Standard Stack

### Core

| Library / Artifact | Purpose | Why Standard |
|--------------------|---------|--------------|
| `Igniter.Mix.Task` + `Igniter.Project.Module` | Generate or inject host-facing installation output | Already used for installer scaffolding and auth-module creation. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] |
| `Application.compile_env` / `Application.get_env` helpers wrapped centrally | Runtime config lookup | Needed to replace scattered direct calls with one explicit contract. [VERIFIED: lib/oban_powertools/auth.ex] |
| Phoenix LiveView event handling | Preview gating and disabled-action rendering | `CronLive` already isolates preview/confirm events, so the fix is localized rather than architectural. [VERIFIED: lib/oban_powertools/web/cron_live.ex] |
| ExUnit + LiveView tests | Verification | Existing test suite already exercises installer source contracts and cron UI flow. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs] |

### Supporting

| Artifact | Purpose | When to Use |
|----------|---------|-------------|
| `lib/oban_powertools/auth.ex` | Behavior and runtime auth-module lookup | Extend with explicit setup validation/error helpers instead of silent `nil` or `false` fallback. |
| `lib/oban_powertools/web/live_auth.ex` | Page/action gatekeeper | Reuse for authorization checks and error-copy normalization where possible. |
| `config/test.exs` | Current test-only runtime config baseline | Keep for test support, but Phase 6 verification must prove the library contract without pretending this file is the installer outcome. |

## Concrete Repo Findings

### Runtime config findings

- The installer creates the auth behavior module and router scope but never writes explicit `config :oban_powertools, repo: ..., auth_module: ...`. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex]
- `Auth.auth_module/0` returns `Application.get_env(:oban_powertools, :auth_module)` and downstream calls silently return `nil` or `false` when it is missing. [VERIFIED: lib/oban_powertools/auth.ex]
- Web LiveViews and some services use `Application.fetch_env!(:oban_powertools, :repo)`, while others use `Application.get_env(:oban_powertools, :repo)` or `Keyword.get(opts, :repo, Application.get_env(...))`. This creates divergent failure modes and makes setup errors hard to reason about. [VERIFIED: repo grep for repo lookups]
- `config/test.exs` currently provides `repo` and `auth_module`, which is why the test environment does not expose the host-installation gap by default. [VERIFIED: config/test.exs]

### Authorization findings

- `CronLive.handle_event(\"preview\", ...)` finds the entry, emits preview telemetry, and assigns `@preview` before any auth check runs. [VERIFIED: lib/oban_powertools/web/cron_live.ex]
- Current unauthorized coverage only proves confirm-time denial after preview state was already entered. [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs]
- `LifelineLive` already uses the desired pattern: authorize before preview/execute side effects and return explicit unauthorized messages in-state. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]

## Recommended Plan Split

| Plan | Scope | Why This Seam Fits |
|------|-------|--------------------|
| `6-01` | Runtime config contract and installer output | Touches shared library contract and installation story without mixing UI behavior changes. |
| `6-02` | Cron authorization ordering and disabled-action UX | Focused LiveView/auth slice, with a strong local analog in `LifelineLive`. |
| `6-03` | Host-like verification, requirements closure, and final phase verification | Keeps proof and closure work separate and ensures the phase ends with explicit evidence. |

## Validation Architecture

### Requirement -> Verification Map

| Requirement | Primary Commands | Why |
|-------------|------------------|-----|
| FND-01 | `mix test test/mix/tasks/oban_powertools.install_test.exs` plus new runtime-config helper tests | Proves installer output and centralized setup contract exist. |
| FND-02 | `mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/live/cron_live_test.exs` | Proves explicit auth-module behavior and auth-before-preview enforcement. |
| ENG-03 | `mix test test/oban_powertools/cron_test.exs test/oban_powertools/web/live/cron_live_test.exs` | Proves cron behavior stays green while the UI mutation flow is hardened. |

### Host-App-Like Proof Expectations

- Add tests that read installer source for explicit `config :oban_powertools` injection or equivalent helper usage.
- Add tests for missing-config setup errors that do not rely on the default `config/test.exs` path.
- Add a LiveView test asserting unauthorized preview clicks do not render preview state and do not emit preview telemetry.
- Add a LiveView test or rendered-state assertion for disabled cron actions with inline permission explanations.

## Architecture Patterns

### Pattern 1: Centralized setup contract

Use one library module to resolve required runtime config and raise purpose-built setup errors. Callers should either pass `repo:` explicitly or use the shared helper, never direct `Application.get_env` / `fetch_env!` scattered throughout the codebase.

### Pattern 2: Authorize before preview side effects

Follow the `LifelineLive` posture for cron actions: decide capability first, then allocate preview state, then allow confirm to execute. No telemetry or audit rows should happen before the preview authorization decision.

### Pattern 3: Disabled-with-explanation operator UX

For visible-but-forbidden actions, compute capability alongside the row data and render disabled controls with inline explanatory copy rather than hiding the action or allowing click-then-deny behavior.

## Anti-Patterns To Avoid

- Adding repo inference from Oban config, `ecto_repos`, or the first loaded Ecto repo. [VERIFIED: .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md]
- Preserving `Auth.authorize/3` silent false fallback for missing `:auth_module` on required web surfaces. [VERIFIED: lib/oban_powertools/auth.ex]
- Emitting preview telemetry for unauthorized users. [VERIFIED: lib/oban_powertools/web/cron_live.ex]
- Treating `config/test.exs` as sufficient evidence that the host-installation contract is fixed. [VERIFIED: .planning/ROADMAP.md]

