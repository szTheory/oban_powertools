---
phase: 4
plan: 05
type: execute
wave: 5
depends_on: ["Phase 4 Plan 02", "Phase 4 Plan 03", "Phase 4 Plan 04"]
files_modified: ["lib/oban_powertools/web/router.ex", "lib/oban_powertools/web/engine_overview_live.ex", "lib/oban_powertools/web/lifeline_live.ex", "lib/oban_powertools/web/audit_live.ex", "test/oban_powertools/web/router_test.exs", "test/oban_powertools/web/live/lifeline_live_test.exs", "test/oban_powertools/web/live/audit_live_test.exs"]
autonomous: true
requirements: ["LIF-02", "LIF-03", "LIF-04"]
must_haves:
  truths:
    - "The native UI is incident-first, evidence-first, and preview-first inside the existing `/ops/jobs` shell."
    - "No direct execute control is available from incident rows; execution stays disabled until a durable preview exists, a reason is provided, and drift has not invalidated the preview."
    - "Archive activity is visible in the same operator surface, but retention policy editing remains out of scope."
  artifacts:
    - path: "lib/oban_powertools/web/lifeline_live.ex"
      provides: "Native Lifeline incident and repair LiveView"
      contains: "Preview Repair Plan"
    - path: "lib/oban_powertools/web/router.ex"
      provides: "Lifeline route mounted inside the native ops shell"
      contains: "/lifeline"
    - path: "test/oban_powertools/web/live/lifeline_live_test.exs"
      provides: "Preview-first, drift, reason, and auth LiveView tests"
      contains: "Preview Drifted"
---

<objective>
Expose Phase 4 through the native Powertools shell. This plan adds the Lifeline LiveView, overview metrics, route wiring, and audit/archive visibility so operators can diagnose and repair incidents without leaving the existing `/ops/jobs` surface.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/STATE.md
@.planning/phases/4-CONTEXT.md
@.planning/phases/4-RESEARCH.md
@.planning/phases/4-PATTERNS.md
@.planning/phases/4-UI-SPEC.md
@lib/oban_powertools/web/router.ex
@lib/oban_powertools/web/engine_overview_live.ex
@lib/oban_powertools/web/cron_live.ex
@lib/oban_powertools/web/workflows_live.ex
@lib/oban_powertools/web/audit_live.ex
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Mount the Lifeline Route and Build the Incident-First LiveView</name>
  <files>lib/oban_powertools/web/router.ex, lib/oban_powertools/web/engine_overview_live.ex, lib/oban_powertools/web/lifeline_live.ex, test/oban_powertools/web/router_test.exs, test/oban_powertools/web/live/lifeline_live_test.exs</files>
  <behavior>
    - `/ops/jobs/lifeline` mounts inside the existing native shell and appears in overview next-step links and metrics.
    - The page defaults to active incidents and uses a master/detail layout that shows detection evidence before preview or execute controls.
    - Generic job details stay behind Oban Web deep links instead of being rebuilt natively.
  </behavior>
  <action>
    Extend the router and overview page with a native Lifeline route, overview metrics, and entry points that follow the Phase 4 UI contract and preserve the hybrid shell posture.
    Implement `LifelineLive` as an incident-first master/detail LiveView with the locked operator sections: `Detection Summary`, `Proposed State Changes`, `Affected Records`, and `Audit Record to be Written`.
    Add route and LiveView auth tests proving unauthorized viewers are redirected, incident rows expose `Preview Repair Plan` as the only primary action, and archive activity remains read-only in the incident flow.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/lifeline_live_test.exs</automated>
  </verify>
  <done>The native shell exposes the Phase 4 Lifeline surface with incident-first routing and overview integration.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Wire Preview Drift, Reason Capture, and Audit Visibility into the UI</name>
  <files>lib/oban_powertools/web/lifeline_live.ex, lib/oban_powertools/web/audit_live.ex, test/oban_powertools/web/live/lifeline_live_test.exs, test/oban_powertools/web/live/audit_live_test.exs</files>
  <behavior>
    - The UI shows durable preview state, reason capture, and `Preview Drifted` gating before execution can proceed.
    - Audit history for manual interventions renders inline for the selected incident and remains visible in the shared audit page.
    - Archive activity and last archive/prune run are visible without turning the page into a policy editor.
  </behavior>
  <action>
    Wire the backend preview and execute APIs into the LiveView so the page requires a preview first, validates reason capture, disables execution when the preview drifts, and shows operator-readable before/after summaries and affected counts before raw ids.
    Extend audit rendering where needed so manual repair history highlights actor, action, resource, reason, and immutable event time, matching the locked Phase 4 copy contract.
    Add LiveView tests for preview creation, reason-required execute enablement, drift invalidation, successful audited execution, archive activity visibility, and deep-linking generic job inspection to Oban Web.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs</automated>
  </verify>
  <done>Operators can diagnose, preview, and safely execute Phase 4 repairs from the native shell with visible drift and audit evidence.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Browser -> LiveView | Operators must never be able to bypass preview, reason, or drift gates from the client. |
| Lifeline UI -> Oban Web | Powertools-native repair concepts stay in the native shell while generic job details deep-link into the guarded dashboard. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-4-13 | Elevation of Privilege | Lifeline LiveView | mitigate | Reuse `LiveAuth` page and action authorization for page entry, preview generation, and execution separately. |
| T-4-14 | Integrity | execute button state | mitigate | Keep execute disabled until preview exists, reason is valid, and the backend confirms the preview is not drifted. |
| T-4-15 | Information Disclosure | incident/audit detail | mitigate | Keep high-cardinality evidence in auth-gated detail panels and deep-link generic job internals to Oban Web. |
</threat_model>

<verification>
mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs
</verification>

<success_criteria>
Operators can use the native `/ops/jobs/lifeline` surface to inspect incidents, preview repair safely, execute only drift-valid repairs with a reason, and review archive/audit evidence without leaving the Powertools shell.
</success_criteria>

<output>
After completion, create `.planning/phases/4-05-SUMMARY.md`
</output>
