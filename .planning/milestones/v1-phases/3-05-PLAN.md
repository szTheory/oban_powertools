---
phase: 3
plan: 05
type: execute
wave: 5
depends_on: ["Phase 3 Plan 04"]
files_modified: ["lib/oban_powertools/web/router.ex", "lib/oban_powertools/web/engine_overview_live.ex", "lib/oban_powertools/web/workflows_live.ex", "test/oban_powertools/web/router_test.exs", "test/oban_powertools/web/live/workflows_live_test.exs"]
autonomous: true
requirements: ["WF-03"]
must_haves:
  truths:
    - "Operators can inspect workflows from the existing `/ops/jobs` shell without rebuilding the generic jobs dashboard."
    - "Workflow detail renders blocked nodes and dependency edges clearly, preserves stable selection/layout across live updates, and deep-links to Oban Web for generic job inspection."
    - "The workflow UI stays read-only in Phase 3 while still explaining what is blocked, why, what could run next, and where nested workflow drill-down continues."
  artifacts:
    - path: "lib/oban_powertools/web/workflows_live.ex"
      provides: "Native workflow index/detail LiveView"
      contains: "Open generic job inspection in Oban Web"
    - path: "lib/oban_powertools/web/router.ex"
      provides: "Workflow routes inside the existing ops shell"
      contains: "/workflows"
    - path: "test/oban_powertools/web/live/workflows_live_test.exs"
      provides: "Read-only DAG detail, auth, and live-update stability tests"
      contains: "blocked"
  key_links:
    - from: "workflow LiveView"
      to: "Oban Web"
      via: "job deep links from selected node detail"
      pattern: "diagnose in Powertools, inspect generics in Oban Web"
---

<objective>
Expose workflow state through the native Powertools shell. This plan adds the read-only workflow index/detail surface and overview links that satisfy WF-03 without crossing into repair-center or generic job-admin territory.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/STATE.md
@.planning/phases/3-CONTEXT.md
@.planning/phases/3-RESEARCH.md
@.planning/phases/3-PATTERNS.md
@lib/oban_powertools/web/router.ex
@lib/oban_powertools/web/engine_overview_live.ex
@lib/oban_powertools/web/limiters_live.ex
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Mount Workflow Routes and Add Overview Workflow Entry Points</name>
  <files>lib/oban_powertools/web/router.ex, lib/oban_powertools/web/engine_overview_live.ex, test/oban_powertools/web/router_test.exs, test/oban_powertools/web/live/workflows_live_test.exs</files>
  <behavior>
    - `/ops/jobs/workflows` and workflow-detail routing mount inside the existing native shell.
    - The overview page gains workflow-specific metrics and next-step links without replacing the hybrid shell direction.
    - Unauthorized viewers are redirected before any workflow content renders.
  </behavior>
  <action>
    Extend the existing router macro and overview page with workflow routes, metrics, and next-step links per D-27, D-28, D-30, D-31, and D-39.
    Keep the shell hybrid: native workflow pages own Powertools workflow concepts, while generic job details continue to live behind Oban Web deep links per D-27, D-30, and D-44.
    Add route and LiveView auth tests proving the workflow surface stays read-only and auth-gated, with no retry/skip/cancel/repair controls introduced per D-29, D-32, D-43, and D-44.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/workflows_live_test.exs -x</automated>
  </verify>
  <done>The native shell exposes workflow routes and overview entry points that align with the existing auth-gated operator surface.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Build the Read-Only Workflow Index and Detail LiveView</name>
  <files>lib/oban_powertools/web/workflows_live.ex, test/oban_powertools/web/live/workflows_live_test.exs</files>
  <behavior>
    - The workflow page shows index and detail states through one stable, explanation-first LiveView.
    - Detail rendering highlights blocked nodes and dependency edges, preserves selected node state across live updates, and supports nested/subworkflow drill-down one path at a time.
    - Selected-node detail explains blockers, dependency reasons, result availability, what could run next, and provides Oban Web job deep links.
  </behavior>
  <action>
    Implement a master/detail `WorkflowsLive` that follows the `LimitersLive` read-only inspection pattern rather than the preview-action pattern, using router actions or params to keep selection/layout stable per D-28, D-29, D-31, and D-33.
    Render DAG state from persisted workflow/step/edge/result rows and workflow blocker snapshots, including blocked-node badges, dependency reason copy, result availability markers, nested child workflow links, and Oban Web deep links per D-15, D-19, D-25, D-29, D-30, and D-31.
    Add LiveView tests for blocked-node highlighting, selected-node detail, preserved selection across PubSub/live refreshes, nested drill-down, unauthorized redirects, and the absence of mutation controls per D-29, D-32, D-33, D-43, and D-44.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/web/live/workflows_live_test.exs -x</automated>
  </verify>
  <done>Operators can diagnose workflow state natively in Powertools with stable, read-only DAG views and generic job deep-links into Oban Web.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Browser -> LiveView | Workflow state is operator-visible and must remain auth-gated, read-only, and stable under live updates. |
| Workflow UI -> Oban Web | Deep links cross from Powertools-native concepts to generic job inspection while sharing the same protected ops area. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-3-13 | Elevation of Privilege | workflow LiveViews | mitigate | Reuse `LiveAuth` page authorization and assert unauthorized redirects for index and detail routes. |
| T-3-14 | Information Disclosure | workflow detail page | mitigate | Show workflow/result evidence only in auth-gated views, keep the page read-only, and deep-link generic job internals to existing guarded Oban Web pages. |
| T-3-15 | Denial of Service | live DAG updates | mitigate | Preserve stable layout and selection state across updates so PubSub churn does not cause repeated expensive recomputation or operator disorientation. |
</threat_model>

<verification>
mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/workflows_live_test.exs -x
</verification>

<success_criteria>
Operators can inspect blocked workflows and nested workflow state from the native `/ops/jobs` shell, understand exact dependency causes, and jump into Oban Web for generic job detail without any Phase 4 mutation surface leaking into Phase 3.
</success_criteria>

<output>
After completion, create `.planning/phases/3-05-SUMMARY.md`
</output>
