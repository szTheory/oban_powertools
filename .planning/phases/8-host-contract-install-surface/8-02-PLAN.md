---
phase: 8
plan: 02
type: execute
wave: 1
depends_on: []
files_modified: ["lib/oban_powertools/web/router.ex", "test/oban_powertools/web/router_test.exs"]
autonomous: true
requirements: ["HST-01"]
must_haves:
  truths:
    - "A host router mounts Powertools by owning the outer `/ops/jobs` scope and browser pipeline."
    - "The library macro owns the native route tree under that scope plus the optional `/ops/jobs/oban` bridge when `oban_web` is available."
    - "Phase 8 proves only mount shape and ownership boundary for the bridge; resolver/policy seams remain out of scope until Phase 9."
  artifacts:
    - path: "lib/oban_powertools/web/router.ex"
      provides: "Explicit route-contract docs and limited optional bridge shape"
      contains: "oban_powertools_routes"
    - path: "test/oban_powertools/web/router_test.exs"
      provides: "Proof for native route paths and optional bridge mount path"
      contains: "/ops/jobs/oban"
  key_links:
    - from: "host router scope `/ops/jobs`"
      to: "ObanPowertools.Web.Router.oban_powertools_routes(\"/oban\")"
      via: "host-owned outer shell"
      pattern: "outer scope + inner macro"
    - from: "native LiveView session"
      to: "optional `oban_dashboard/2` bridge"
      via: "shared `on_mount: [ObanPowertools.Web.LiveAuth]`"
      pattern: "same mount auth hook, no resolver work in Phase 8"
---

<objective>
Freeze the Phase 8 route and optional-bridge contract so host apps have one verifiable mount shape: the host owns the outer router scope, the library owns the inner native pages, and `oban_web` only adds an optional bridge at the documented nested path.

Purpose: close HST-01 without drifting into Phase 9 resolver/policy work.
Output: route-contract docs in `ObanPowertools.Web.Router` and ExUnit proof for native pages plus the optional `/ops/jobs/oban` bridge path.
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
@lib/oban_powertools/web/router.ex
@lib/oban_powertools/web/live_auth.ex
@test/oban_powertools/web/router_test.exs
@test/support/test_router.ex

<interfaces>
From `lib/oban_powertools/web/router.ex`:
```elixir
defmacro oban_powertools_routes(path)
```

Current host fixture from `test/support/test_router.ex`:
```elixir
scope "/ops/jobs" do
  pipe_through(:browser)
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```
</interfaces>
</context>

<tasks>

<task type="execute">
  <name>Task 1: Document the host-owned mount boundary directly in `ObanPowertools.Web.Router`</name>
  <files>lib/oban_powertools/web/router.ex</files>
  <read_first>
    - lib/oban_powertools/web/router.ex
    - lib/oban_powertools/web/live_auth.ex
    - test/support/test_router.ex
    - .planning/phases/8-host-contract-install-surface/8-RESEARCH.md
    - .planning/phases/8-host-contract-install-surface/8-PATTERNS.md
  </read_first>
  <acceptance_criteria>
    - `lib/oban_powertools/web/router.ex` moduledoc or `@doc` text explicitly states the host owns the outer `/ops/jobs` scope and browser pipeline
    - `lib/oban_powertools/web/router.ex` explicitly states the optional bridge path is `"/oban"` beneath the host-owned outer scope
    - `lib/oban_powertools/web/router.ex` explicitly states resolver/redaction/policy work is not introduced here
  </acceptance_criteria>
  <action>
    Expand the module or function docs in `lib/oban_powertools/web/router.ex` so the public contract names the exact ownership split: host router owns the outer `/ops/jobs` scope and `pipe_through(:browser)`, `oban_powertools_routes("/oban")` owns the inner native route tree, and if `Oban.Web.Router` is loaded the library mounts `oban_dashboard("/oban", on_mount: [ObanPowertools.Web.LiveAuth])` beneath that same scope.
    Keep the bridge language narrow per Phase 8 research: mention shared `on_mount` only, and explicitly avoid adding `resolver:` hooks, formatter modules, or redaction seams because those are Phase 9 work.
  </action>
  <verify>
    <automated>rg -n 'host owns the outer .*/ops/jobs.*scope|optional bridge path is .*/oban.|resolver.*not introduced|Phase 9' lib/oban_powertools/web/router.ex && mix test test/oban_powertools/web/router_test.exs -x</automated>
  </verify>
  <done>The route macro itself documents the exact host/library ownership boundary and Phase 8’s intentionally limited optional-bridge scope.</done>
</task>

<task type="execute" tdd="true">
  <name>Task 2: Prove native and optional bridge mount shape with router tests</name>
  <files>test/oban_powertools/web/router_test.exs</files>
  <read_first>
    - test/oban_powertools/web/router_test.exs
    - test/support/test_router.ex
    - lib/oban_powertools/web/router.ex
    - .planning/phases/8-host-contract-install-surface/8-RESEARCH.md
    - .planning/phases/8-host-contract-install-surface/8-VALIDATION.md
  </read_first>
  <acceptance_criteria>
    - `test/oban_powertools/web/router_test.exs` asserts native routes resolve under `/ops/jobs`
    - `test/oban_powertools/web/router_test.exs` asserts `/ops/jobs/oban` resolves when `Oban.Web.Router` is available
    - `test/oban_powertools/web/router_test.exs` asserts `/oban` does not resolve at the root router level, proving the library macro does not own the outer scope
    - `test/oban_powertools/web/router_test.exs` contains an assertion tying the bridge to `ObanPowertools.Web.LiveAuth` rather than a new Phase 8 resolver seam
  </acceptance_criteria>
  <action>
    Extend `test/oban_powertools/web/router_test.exs` with explicit Phase 8 proof cases:
    1. keep the existing native `/ops/jobs`, `/ops/jobs/lifeline`, `/ops/jobs/limiters`, `/ops/jobs/cron`, `/ops/jobs/audit`, and `/ops/jobs/workflows` assertions;
    2. add a conditional assertion that `/ops/jobs/oban` resolves when `Code.ensure_loaded?(Oban.Web.Router)` is true;
    3. assert `/oban` at the application root does not resolve, proving the host must supply the outer `/ops/jobs` scope;
    4. verify the bridge contract stays limited to `on_mount: [ObanPowertools.Web.LiveAuth]` and does not introduce `resolver:` in Phase 8.
  </action>
  <verify>
    <automated>rg -n "/ops/jobs/oban|/oban|ObanPowertools.Web.LiveAuth|resolver:" test/oban_powertools/web/router_test.exs && mix test test/oban_powertools/web/router_test.exs -x</automated>
  </verify>
  <done>The route shape is now executable proof: native pages and the optional bridge mount where the contract says they do, and the host-owned outer scope remains explicit.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Host router scope -> library macro | The host must remain the owner of the outer browser scope so route/auth responsibility is not blurred. |
| Native shell -> optional `oban_web` bridge | The bridge must share only the documented mount/auth seam in Phase 8 and not silently gain broader policy hooks. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-8-04 | Elevation of Privilege | router mount boundary | mitigate | Document and test that the host owns the outer `/ops/jobs` scope and browser pipeline while the library owns only the inner routes. |
| T-8-05 | Tampering | optional bridge seam | mitigate | Freeze the bridge to path + `on_mount` only and assert no `resolver:` surface is added in Phase 8. |
| T-8-06 | Repudiation | route contract | mitigate | Add route-info assertions for `/ops/jobs/oban` and `/oban` so ownership drift becomes a test failure. |
</threat_model>

<verification>
mix test test/oban_powertools/web/router_test.exs
</verification>

<success_criteria>
Hosts can rely on one exact mount shape: outer `/ops/jobs` scope is host-owned, inner pages are library-owned, and `oban_web` adds only the documented nested bridge path and auth hook in this phase.
</success_criteria>

<output>
After completion, create `.planning/phases/8-host-contract-install-surface/8-02-SUMMARY.md`
</output>
