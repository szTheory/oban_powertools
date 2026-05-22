---
phase: 9
plan: 03
type: execute
wave: 3
depends_on: ["9-01", "9-02"]
files_modified: ["lib/oban_powertools/web/router.ex", "lib/oban_powertools/web/oban_web_bridge.ex", "test/oban_powertools/web/router_test.exs", "README.md", ".planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md"]
autonomous: true
requirements: ["PKG-03", "POL-01", "POL-02"]
must_haves:
  truths:
    - "The optional `/ops/jobs/oban` bridge adapts the same Powertools auth and display seams as native pages."
    - "The bridge contract stays thin and limited to documented `oban_web` hooks on the existing nested mount."
    - "README and verification artifacts describe the supported optional-path behavior without overstating bridge scope."
  artifacts:
    - path: "lib/oban_powertools/web/router.ex"
      provides: "Bounded route-level bridge contract"
      contains: "oban_dashboard"
    - path: "lib/oban_powertools/web/oban_web_bridge.ex"
      provides: "Powertools-owned adapter for Oban Web auth/display hooks"
      contains: "resolver"
    - path: "test/oban_powertools/web/router_test.exs"
      provides: "Optional-path proof for nested bridge policy hooks"
      contains: "/ops/jobs/oban"
  key_links:
    - from: "native Powertools auth/display seams"
      to: "optional `oban_web` bridge"
      via: "thin bridge adapter over documented hooks"
      pattern: "shared policy -> nested bridge -> no contract widening"
    - from: "README support truth"
      to: "router and verification artifacts"
      via: "same optional dependency guarantees"
      pattern: "docs surface == route surface == tests"
---

<objective>
Freeze the supported optional `oban_web` bridge contract so hosts can adopt the nested bridge with the same Powertools auth/display semantics as native pages, using documented hooks only and verifiable support-truth docs.
</objective>

<execution_context>
@$HOME/.codex/get-shit-done/workflows/execute-plan.md
@$HOME/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/STATE.md
@.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md
@.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-RESEARCH.md
@.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-PATTERNS.md
@.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VALIDATION.md
@.planning/phases/8-host-contract-install-surface/8-RESEARCH.md
@.planning/phases/8-host-contract-install-surface/8-VERIFICATION.md
@README.md
@lib/oban_powertools/web/router.ex
@test/oban_powertools/web/router_test.exs

<interfaces>
Current optional bridge shape:
```elixir
if Code.ensure_loaded?(Oban.Web.Router) do
  import Oban.Web.Router, only: [oban_dashboard: 2]
  oban_dashboard(path, on_mount: [ObanPowertools.Web.LiveAuth])
end
```
</interfaces>
</context>

<tasks>

<task type="execute" tdd="true">
  <name>Task 1: Add the thin Powertools-owned Oban Web bridge adapter</name>
  <files>lib/oban_powertools/web/router.ex, lib/oban_powertools/web/oban_web_bridge.ex, test/oban_powertools/web/router_test.exs</files>
  <read_first>
    - lib/oban_powertools/web/router.ex
    - test/oban_powertools/web/router_test.exs
    - .planning/phases/8-host-contract-install-surface/8-RESEARCH.md
    - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md
    - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-PATTERNS.md
  </read_first>
  <action>
    Add a Powertools-owned bridge adapter module that maps the Phase 9 auth/display seams into the documented Oban Web extension points used at the nested `/ops/jobs/oban` mount. Keep the bridge localized to the existing route macro and do not widen it into a shadow dashboard or generic plugin layer.
    Update `router.ex` so the optional bridge still mounts only under the host-owned `/ops/jobs` scope, still shares `ObanPowertools.Web.LiveAuth`, and now passes only the bounded Phase 9 adapter hooks needed for access mapping and display formatting.
    Replace the Phase 8 negative `resolver:` assertion in `router_test.exs` with positive assertions for the allowed bridge options and shared nested mount invariants.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/web/router.ex` still mounts the bridge only at `/ops/jobs/oban`
    - `lib/oban_powertools/web/oban_web_bridge.ex` exists and acts as the library-owned adapter for documented bridge hooks
    - `test/oban_powertools/web/router_test.exs` positively asserts the supported bridge hook contract instead of only asserting `resolver:` absence
    - `test/oban_powertools/web/router_test.exs` still proves `/oban` does not resolve at the router root
    - `mix test test/oban_powertools/web/router_test.exs` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/web/router_test.exs</automated>
  </verify>
  <done>The optional bridge has one bounded Powertools-owned adapter contract over documented Oban Web hooks without widening the Phase 8 route boundary.</done>
</task>

<task type="execute">
  <name>Task 2: Publish the optional-path support truth and verification proof</name>
  <files>README.md, .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md</files>
  <read_first>
    - README.md
    - .planning/phases/8-host-contract-install-surface/8-VERIFICATION.md
    - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-RESEARCH.md
    - lib/oban_powertools/web/router.ex
    - test/oban_powertools/web/router_test.exs
  </read_first>
  <action>
    Update the README so the supported optional `oban_web` path is explicit: the host still owns dependency choice and outer `/ops/jobs` shell, Powertools owns the nested `/ops/jobs/oban` mount and its adapter plumbing, and the supported bridge contract stops at actor handoff, access mapping, shared display/redaction, and bounded audit/telemetry integration.
    Create `9-VERIFICATION.md` with the exact automated proof command set for the Phase 9 contract: auth contract tests, native display-policy tests, and router bridge tests. Keep the doc explicit that bridge support truth is parity of policy seams, not a full generic Oban Web UX replacement.
    Do not promise nav injection, wrapped generic mutations, or undocumented hook usage anywhere in docs or verification artifacts.
  </action>
  <acceptance_criteria>
    - `README.md` explicitly describes `/ops/jobs/oban` as optional and bounded by documented hooks
    - `README.md` references the shared Powertools auth/display policy story rather than a bridge-specific host seam
    - `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md` exists and contains the exact Phase 9 proof command set
    - grep over README and `9-VERIFICATION.md` shows no support-truth language that implies a full shadow dashboard or plugin surface
  </acceptance_criteria>
  <verify>
    <automated>rg -n "/ops/jobs/oban|optional `oban_web`|documented hooks|auth_module|display_policy|shadow dashboard|plugin" README.md .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md && mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs</automated>
  </verify>
  <done>The optional-path support truth is documented and backed by a concrete proof artifact without overstating the bridge contract.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Host-owned outer shell -> nested optional bridge | The bridge must remain a narrow Powertools-owned adapter under the Phase 8 route boundary. |
| Shared native policy seams -> Oban Web hooks | The bridge must reuse the same auth/display semantics as native pages without inventing a separate host contract. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-9-06 | Elevation of Privilege | optional bridge access mapping | mitigate | Adapt the same explicit Powertools auth seam through documented Oban Web hooks rather than inheriting implicit full access. |
| T-9-07 | Tampering / support-truth confusion | bridge contract docs and route surface | mitigate | Keep the bridge bounded to nested mount plus documented hooks and prove that shape in router tests and README. |
| T-9-08 | Information Disclosure | bridge formatter/redaction path | mitigate | Reuse the shared display-policy seam so `/ops/jobs/oban` cannot reveal values that native pages hide. |
</threat_model>

<verification>
mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs
</verification>

<success_criteria>
Hosts can opt into `/ops/jobs/oban` with one explicit support story: the bridge is optional, nested, policy-consistent with native Powertools pages, and limited to documented hooks that the repo can continuously verify.
</success_criteria>

<output>
After completion, create `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-03-SUMMARY.md`
</output>
