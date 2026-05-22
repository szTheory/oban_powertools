---
phase: 9
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: ["lib/oban_powertools/auth.ex", "lib/oban_powertools/runtime_config.ex", "lib/oban_powertools/web/live_auth.ex", "lib/oban_powertools/web/cron_live.ex", "lib/oban_powertools/web/lifeline_live.ex", "test/oban_powertools/auth_test.exs", "test/oban_powertools/web/live/cron_live_test.exs", "test/oban_powertools/web/live/lifeline_live_test.exs", "test/support/test_auth.ex"]
autonomous: true
requirements: ["POL-01"]
must_haves:
  truths:
    - "Host apps implement one explicit Powertools auth contract for actor resolution, authorization outcome, and durable audit-principal derivation."
    - "Native mutation flows fail explicitly when authorization passes but no valid audit principal can be derived."
    - "Permissive attribution fallbacks like `inspect/1`, `nil`, or session heuristics no longer power durable mutation writes."
  artifacts:
    - path: "lib/oban_powertools/auth.ex"
      provides: "Explicit public auth and audit-principal contract"
      contains: "audit_principal"
    - path: "lib/oban_powertools/web/live_auth.ex"
      provides: "Native LiveView adapter for explicit authorization outcomes"
      contains: "authorize_action"
    - path: "test/oban_powertools/auth_test.exs"
      provides: "Contract proof for missing-config, denial, and missing-principal behavior"
      contains: "audit_principal"
  key_links:
    - from: "host `auth_module`"
      to: "native LiveView mount and mutation flows"
      via: "explicit `current_actor` and authorization outcome contract"
      pattern: "resolve actor -> authorize -> derive principal -> mutate"
    - from: "mutation service inputs"
      to: "durable audit writes"
      via: "explicit principal envelope"
      pattern: "authorized actor without principal fails before write"
---

<objective>
Freeze the Phase 9 auth and actor-attribution contract so host apps configure one explicit Powertools auth seam that native pages and mutation paths can trust without permissive fallback behavior.
</objective>

<execution_context>
@$HOME/.codex/get-shit-done/workflows/execute-plan.md
@$HOME/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/STATE.md
@.planning/MILESTONE-ARC.md
@.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md
@.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-RESEARCH.md
@.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-PATTERNS.md
@.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VALIDATION.md
@.planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
@lib/oban_powertools/auth.ex
@lib/oban_powertools/runtime_config.ex
@lib/oban_powertools/web/live_auth.ex
@lib/oban_powertools/web/cron_live.ex
@lib/oban_powertools/web/lifeline_live.ex
@test/oban_powertools/auth_test.exs
@test/support/test_auth.ex

<interfaces>
Current public auth surface:
```elixir
@callback current_actor(Plug.Conn.t() | map()) :: any()
@callback can_perform_action?(actor :: any(), action :: atom(), resource :: any()) :: boolean()
def current_actor(conn_or_socket_or_session)
def authorize(actor, action, resource)
def actor_id(actor)
```

Current native auth adapter:
```elixir
def on_mount(:default, _params, session, socket)
def authorize_page(socket, action, resource)
def authorize_action(socket, action, resource, opts \\ [])
```
</interfaces>
</context>

<tasks>

<task type="execute" tdd="true">
  <name>Task 1: Freeze the host auth and audit-principal behaviour in `ObanPowertools.Auth`</name>
  <files>lib/oban_powertools/auth.ex, lib/oban_powertools/runtime_config.ex, test/oban_powertools/auth_test.exs, test/support/test_auth.ex</files>
  <read_first>
    - lib/oban_powertools/auth.ex
    - lib/oban_powertools/runtime_config.ex
    - test/oban_powertools/auth_test.exs
    - test/support/test_auth.ex
    - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md
    - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-RESEARCH.md
  </read_first>
  <action>
    Evolve `ObanPowertools.Auth` in place instead of introducing a second host seam. Keep `current_actor/1` as the actor-resolution entrypoint, but replace the boolean-only callback with an explicit authorization contract and add an explicit `audit_principal/1` callback that returns the stable public principal envelope for durable writes.
    The Phase 9 contract should support explicit `:ok` or `{:error, reason}` authorization outcomes and should remove permissive `actor_id/1` fallback behavior as a public write path. If a compatibility shim is needed temporarily, keep it library-owned and make the strict path the only one used by native mutation and audit writes.
    Extend `test/oban_powertools/auth_test.exs` and `test/support/test_auth.ex` first so the public contract is locked before touching call sites. Cover authorization outcomes, missing runtime config, and the case where an actor is authorized but `audit_principal/1` returns an invalid or missing principal.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/auth.ex` defines explicit authorization and principal callbacks in `behaviour_info(:callbacks)`
    - `lib/oban_powertools/auth.ex` no longer relies on `inspect/1` as the durable audit-principal fallback path
    - `test/support/test_auth.ex` implements the new callback shape used by the public contract
    - `test/oban_powertools/auth_test.exs` contains assertions for missing-principal failure and explicit authorization outcomes
    - `mix test test/oban_powertools/auth_test.exs` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/auth_test.exs</automated>
  </verify>
  <done>The repo has one explicit host auth contract for resolution, authorization, and durable principal derivation, with no permissive audit fallback story left in active use.</done>
</task>

<task type="execute" tdd="true">
  <name>Task 2: Thread the explicit auth/principal contract through native LiveView mutation flows</name>
  <files>lib/oban_powertools/web/live_auth.ex, lib/oban_powertools/web/cron_live.ex, lib/oban_powertools/web/lifeline_live.ex, test/oban_powertools/web/live/cron_live_test.exs, test/oban_powertools/web/live/lifeline_live_test.exs</files>
  <read_first>
    - lib/oban_powertools/web/live_auth.ex
    - lib/oban_powertools/web/cron_live.ex
    - lib/oban_powertools/web/lifeline_live.ex
    - test/oban_powertools/web/live/cron_live_test.exs
    - test/oban_powertools/web/live/lifeline_live_test.exs
    - .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
    - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-PATTERNS.md
  </read_first>
  <action>
    Update `ObanPowertools.Web.LiveAuth` so page- and event-level authorization consume the explicit Phase 9 outcome contract rather than booleans, while preserving the existing mount-time and mutation-time defense-in-depth posture.
    Refactor cron and lifeline mutation paths so they derive an explicit principal before durable preview/execute writes and fail with operator-readable errors when the host actor is authorized but unattributable. Remove direct `Auth.actor_id(actor)` mutation plumbing in favor of the explicit principal seam from Task 1.
    Extend the existing LiveView tests to prove the new failure mode: authorized viewers with missing or invalid principals never produce durable mutation or audit writes, while authorized-and-attributable flows remain green.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/web/live_auth.ex` consumes explicit `:ok` or `{:error, reason}` authorization outcomes
    - `lib/oban_powertools/web/cron_live.ex` and `lib/oban_powertools/web/lifeline_live.ex` no longer call `Auth.actor_id(`
    - `test/oban_powertools/web/live/cron_live_test.exs` contains a case for authorized-but-unattributable cron mutation failure
    - `test/oban_powertools/web/live/lifeline_live_test.exs` contains a case for authorized-but-unattributable execute failure
    - `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs</automated>
  </verify>
  <done>Native Powertools pages use the strict Phase 9 auth/principal contract end-to-end and fail explicitly before durable writes when attribution is invalid.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Host actor/auth module -> Powertools native surfaces | Authorization and audit attribution must use one explicit host-owned contract rather than boolean ambiguity or fallback stringification. |
| Authorized operator -> durable mutation/audit write | Authorized actors without valid principals must not generate durable writes or misleading audit evidence. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-9-01 | Elevation of Privilege | auth contract | mitigate | Replace boolean authorization with explicit outcomes and preserve authorize-on-mount plus authorize-on-mutation behavior. |
| T-9-02 | Repudiation | audit attribution | mitigate | Require explicit audit principals for durable writes and remove permissive `inspect/1` / `nil` fallback behavior from active use. |
| T-9-03 | Tampering | native mutation plumbing | mitigate | Thread the same strict auth/principal seam through cron and lifeline so no mutation path bypasses the contract. |
</threat_model>

<verification>
mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs
</verification>

<success_criteria>
Phase 9 establishes one explicit host auth contract and proves that native Powertools mutations authorize and attribute operator actions without permissive fallback behavior.
</success_criteria>

<output>
After completion, create `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-01-SUMMARY.md`
</output>
