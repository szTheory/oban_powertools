# Phase 9: Policy Boundaries & Optional Bridge Contracts - Research

**Researched:** 2026-05-21 [VERIFIED: current session date]
**Domain:** Host-owned auth, audit-principal attribution, display/redaction policy, and optional `oban_web` bridge contract for Oban Powertools. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: repository code/tests and prior phase artifacts]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Keep one host-owned `auth_module` and one host-owned `display_policy`; Powertools owns adapters over both seams. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md]
- Preserve `config :oban_powertools, auth_module: MyAppWeb.ObanPowertoolsAuth` as the public auth config key for compatibility with Phase 8. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md] [VERIFIED: README.md]
- Replace boolean-only authorization and permissive `actor_id/1` fallback with explicit authorization and audit-principal contracts. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md] [VERIFIED: lib/oban_powertools/auth.ex]
- Keep the optional `oban_web` bridge thin and limited to documented hooks on the nested `/ops/jobs/oban` mount. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md] [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: test/oban_powertools/web/router_test.exs]
- Keep telemetry low-cardinality; actor ids, labels, reasons, and rendered payloads do not become telemetry metadata. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md] [VERIFIED: .planning/phases/8-host-contract-install-surface/8-VERIFICATION.md]

### Claude's Discretion
- Exact module and helper names beyond the frozen seam names. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md]
- Exact action/resource tuples, as long as they are explicit, stable, and shared by native pages and the bridge. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md]
- Exact storage location for principal `type` and `label`, provided the public contract is explicit and no permissive fallback remains. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Full UX parity across native pages and the bridge belongs to Phase 10. [VERIFIED: .planning/ROADMAP.md]
- Upgrade/migration guides and full public proof belong to Phase 11. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- A general plugin system, nav injection, or wrapped generic Oban Web mutations are explicitly unsupported bridge directions. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POL-01 | A host app can provide stable auth and actor-attribution hooks that apply consistently across plugs, LiveView mounts, and mutation events. [VERIFIED: .planning/REQUIREMENTS.md] | Current code has a host-owned auth seam, but it is split across `current_actor/1`, boolean `can_perform_action?/3`, and permissive `actor_id/1`; Phase 9 must freeze an explicit contract for actor resolution, authorization outcome, and durable audit principal derivation. [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: lib/oban_powertools/web/live_auth.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex] |
| POL-02 | A host app can provide shared redaction and formatter policies that apply consistently across Powertools-native screens and the Oban Web bridge. [VERIFIED: .planning/REQUIREMENTS.md] | Current rendering is page-local: audit shows raw `actor_id` and `reason`, workflows render raw result state, and cron/lifeline use local labels and copy. Phase 9 must freeze one display-policy seam and route both native pages and the bridge through shared helpers rather than bespoke strings. [VERIFIED: lib/oban_powertools/web/audit_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/workflow/result.ex] |
| PKG-03 | A host app can run Oban Powertools with or without `oban_web` installed, with the optional-path behavior documented and continuously verifiable. [VERIFIED: .planning/REQUIREMENTS.md] | Phase 8 froze the nested route and optional dependency shape; Phase 9 must add the supported bridge policy surface without widening the contract beyond documented Oban Web hooks. [VERIFIED: .planning/phases/8-host-contract-install-surface/8-RESEARCH.md] [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: test/oban_powertools/web/router_test.exs] |
</phase_requirements>

## Summary

Phase 9 is another contract-freezing phase. The repo already has the correct ownership posture from earlier phases: host apps own runtime config, router scope, and policy modules; Powertools owns runtime readers, LiveView adapters, route macros, audit persistence, and the optional nested bridge mount. The gap is not missing infrastructure; it is missing explicit policy semantics for who the actor is, how authorization outcomes are expressed, how audit attribution becomes durable, and how policy-sensitive values render consistently across pages and the optional bridge. [VERIFIED: .planning/MILESTONE-ARC.md] [VERIFIED: lib/oban_powertools/runtime_config.ex] [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: .planning/phases/8-host-contract-install-surface/8-PATTERNS.md]

The current auth behaviour is the sharpest Phase 9 gap. `ObanPowertools.Auth` still exposes `can_perform_action?/3 :: boolean()` and `actor_id/1` falls back to `inspect/1`. That is acceptable for internal bootstrapping, but it is not acceptable as a public host contract because it blurs authorization failure with attribution failure and allows durable audit writes to accept permissive stringification. Native mutation flows already thread actors explicitly into cron and lifeline operations, which means the repo is ready for a stricter principal contract without inventing ambient-process magic. [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]

The second major gap is display-policy drift. Audit, workflow, and operator pages each render policy-sensitive values directly. `AuditLive` shows `event.actor_id || "system"` and raw reason strings, `WorkflowsLive` exposes step state and result presence without a shared result-formatting seam, and native pages rely on page-local labels or copy for values that the context now treats as policy-owned. Phase 9 should not mutate durable evidence into pre-rendered presentation strings; it should leave audit/result rows raw and add a host-owned display-policy seam plus shared library render helpers. [VERIFIED: lib/oban_powertools/web/audit_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex] [VERIFIED: lib/oban_powertools/workflow/result.ex] [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md]

The bridge work stays intentionally narrow. The current route macro already proves the nested `/ops/jobs/oban` mount and shared `on_mount: [ObanPowertools.Web.LiveAuth]` hook, while tests explicitly assert that Phase 8 did not add `resolver:`. Phase 9 should replace that negative assertion with a positive, bounded resolver/formatter contract that adapts the same Powertools auth/display seams into Oban Web, but it should not promise a shadow dashboard or wrapped generic actions. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: test/oban_powertools/web/router_test.exs] [VERIFIED: .planning/phases/8-host-contract-install-surface/8-VERIFICATION.md]

**Primary recommendation:** plan Phase 9 as three deliverables: first freeze the auth and audit-principal contract in `Auth`, `RuntimeConfig`, `LiveAuth`, and tests; second thread that contract through native mutation/audit/display helpers so native surfaces stop drifting; third add the thin `oban_web` bridge adapter plus proof and docs for the supported optional-path behavior. [VERIFIED: current repo structure] [VERIFIED: phase requirements and context]

## Current Gaps That Matter For Planning

### Gap 1: Boolean auth contract is too weak for a public policy seam
- `@callback can_perform_action?/3 :: boolean()` cannot distinguish denial from configuration error, unsupported action, or missing principal derivation. [VERIFIED: lib/oban_powertools/auth.ex]
- `LiveAuth.authorize_page/3` and `authorize_action/4` consume booleans and invent user-facing messages themselves, which means the host contract cannot return explicit policy reasons yet. [VERIFIED: lib/oban_powertools/web/live_auth.ex]
- `test/support/test_auth.ex` also encodes the boolean contract, so any Phase 9 auth tightening must update tests and fixtures together. [VERIFIED: test/support/test_auth.ex]

### Gap 2: Durable audit attribution still permits fallback stringification
- `Auth.actor_id/1` accepts `nil`, strings, atoms, integers, maps, and finally `inspect/1`, which is specifically contrary to the context’s “no permissive late normalization” decision. [VERIFIED: lib/oban_powertools/auth.ex]
- `Audit.record/4` only persists `actor_id` plus free-form metadata, so principal `type` and `label` need an explicit storage choice during planning. [VERIFIED: lib/oban_powertools/audit.ex]
- Cron and lifeline mutation flows already pass actors explicitly, which means Phase 9 can fail early on missing principal derivation instead of introducing session heuristics. [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/lifeline_live.ex]

### Gap 3: Policy-sensitive rendering is page-local
- `AuditLive` renders actor and reason directly from durable rows. [VERIFIED: lib/oban_powertools/web/audit_live.ex]
- `WorkflowsLive` has no shared formatter for result payloads or summaries and currently builds detail state directly from raw rows. [VERIFIED: lib/oban_powertools/web/workflows_live.ex]
- The repo has no `display_policy` config seam yet, so Phase 9 needs to introduce it through the same centralized runtime-config pattern used for `auth_module`. [VERIFIED: lib/oban_powertools/runtime_config.ex]

### Gap 4: Optional bridge contract is still Phase 8-negative rather than Phase 9-positive
- `router_test.exs` currently proves the absence of `resolver:` rather than a supported policy adapter contract. [VERIFIED: test/oban_powertools/web/router_test.exs]
- `router.ex` only mounts `oban_dashboard(path, on_mount: [ObanPowertools.Web.LiveAuth])`, so the bridge does not yet share explicit access mapping or formatter hooks. [VERIFIED: lib/oban_powertools/web/router.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Actor resolution | Host `auth_module` | `ObanPowertools.Auth` delegate | The host knows who the operator is; the library should only normalize and consume that seam. [VERIFIED: lib/oban_powertools/auth.ex] |
| Authorization outcome | Host `auth_module` | `ObanPowertools.Web.LiveAuth` and bridge adapter | Native pages and the bridge need one explicit policy story, but the host still owns the decision logic. [VERIFIED: lib/oban_powertools/web/live_auth.ex] |
| Audit principal derivation | Host `auth_module` | Mutation services and `Audit` writer | Durable writes must use a typed, explicit principal derived from the host actor rather than permissive fallbacks. [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: lib/oban_powertools/audit.ex] |
| Display/redaction decisions | Host `display_policy` | Shared Powertools helpers and bridge formatter hooks | The host owns sensitivity rules; the library owns rendering and adapter plumbing so surfaces do not drift. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md] |
| Optional `oban_web` bridge shape | Host dependency choice and outer scope | Powertools route macro and resolver/formatter adapter | The bridge remains optional and nested under the Phase 8 route contract. [VERIFIED: lib/oban_powertools/web/router.ex] |
| Telemetry metadata boundary | Powertools telemetry wrapper | Host observers | Public telemetry remains low-cardinality even while audit and display contracts get richer. [VERIFIED: .planning/phases/8-host-contract-install-surface/8-VERIFICATION.md] |

## Recommended Plan Slices

### Slice 1: Freeze the host auth and audit-principal contract
**Why first:** POL-01 is the prerequisite for every native mutation path and for any bridge adapter. [VERIFIED: requirements/context]
**Likely files:** `lib/oban_powertools/auth.ex`, `lib/oban_powertools/runtime_config.ex`, `lib/oban_powertools/web/live_auth.ex`, `test/oban_powertools/auth_test.exs`, `test/support/test_auth.ex`, selected LiveView tests.
**Expected outcome:** one explicit contract for `current_actor/1`, authorization, `audit_principal/1`, and a fail-fast missing-principal posture.

### Slice 2: Thread policy through native audit/display surfaces
**Why second:** POL-02 needs the new principal/auth contract available before page-level policy rendering can be made consistent. [VERIFIED: repo flows]
**Likely files:** `lib/oban_powertools/audit.ex`, `lib/oban_powertools/web/cron_live.ex`, `lib/oban_powertools/web/lifeline_live.ex`, `lib/oban_powertools/web/audit_live.ex`, `lib/oban_powertools/web/workflows_live.ex`, `lib/oban_powertools/workflow/result.ex`, `lib/oban_powertools/workflow/runtime.ex`, LiveView tests.
**Expected outcome:** native pages and workflow/audit views render through shared display-policy helpers and mutation services persist explicit principals.

### Slice 3: Add the bounded optional bridge policy adapter and publish proof
**Why third:** PKG-03 depends on the auth/display seams already being explicit and reusable. [VERIFIED: route/test posture]
**Likely files:** `lib/oban_powertools/web/router.ex`, a new bridge adapter module or resolver helper, `test/oban_powertools/web/router_test.exs`, README, and verification docs.
**Expected outcome:** `/ops/jobs/oban` uses the same policy story as native pages through documented hooks only, while the optional dependency contract stays narrow and testable.

## Validation Architecture

The phase can stay on focused ExUnit and LiveView proof rather than browser automation. The smallest effective feedback loop is:

- auth/runtime contract tests in `test/oban_powertools/auth_test.exs`
- native mutation contract tests in `test/oban_powertools/web/live/cron_live_test.exs` and `test/oban_powertools/web/live/lifeline_live_test.exs`
- bridge contract tests in `test/oban_powertools/web/router_test.exs`
- a combined quick-run command that covers auth, native surfaces, and bridge contract drift

Recommended quick-run command:
`mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs`

## Anti-Patterns To Avoid

- Do not add a second bridge-only or native-only policy module; evolve the existing host-owned auth seam and add one display-policy seam. [VERIFIED: context/patterns]
- Do not keep `inspect/1`, `nil`, or session heuristics as durable audit-principal fallback behavior. [VERIFIED: lib/oban_powertools/auth.ex]
- Do not push redaction or formatter logic into page-local helpers on `CronLive`, `LifelineLive`, `AuditLive`, or `WorkflowsLive`. [VERIFIED: repo code]
- Do not widen telemetry metadata while adding richer audit or display policy. [VERIFIED: Phase 8 contract]
- Do not widen the `oban_web` bridge past documented hooks on the existing nested route mount. [VERIFIED: context/router test]

## Research Conclusion

Phase 9 should be planned as contract-hardening, not feature sprawl. The repo already has the right ownership model and explicit operator flows; the missing work is to freeze one explicit auth/principal contract, one explicit display-policy seam, and one narrow bridge adapter contract, then prove those seams with focused tests and docs. [VERIFIED: roadmap, context, repo-local code/tests]

## RESEARCH COMPLETE
