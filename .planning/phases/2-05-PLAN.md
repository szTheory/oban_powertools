---
phase: 2
plan: 05
type: execute
wave: 5
depends_on: ["Phase 2 Plan 03", "Phase 2 Plan 04"]
files_modified: ["lib/oban_powertools/web/router.ex", "lib/oban_powertools/web/live/engine_overview_live.ex", "lib/oban_powertools/web/live/limiters_live.ex", "lib/oban_powertools/web/live/cron_live.ex", "lib/oban_powertools/web/live/audit_live.ex", "test/oban_powertools/web/live/limiters_live_test.exs", "test/oban_powertools/web/live/cron_live_test.exs", "test/oban_powertools/web/live/audit_live_test.exs"]
autonomous: true
requirements: ["ENG-02", "ENG-03"]
must_haves:
  truths:
    - "Native Phase 2 pages stay narrow, explanation-first, and inside the existing `/ops/jobs` shell."
    - "Blocked-job views distinguish `Live Now` from `Snapshot at Block Start`."
    - "Cron pages distinguish `Code` from `Runtime` entries and require preview-before-mutate flows."
    - "Every mutating UI action is action-level auth-gated and verified through audit plus telemetry assertions."
  artifacts:
    - path: "lib/oban_powertools/web/live/limiters_live.ex"
      provides: "Explanation-first limiter UI"
      contains: "Live Now"
    - path: "lib/oban_powertools/web/live/cron_live.ex"
      provides: "Cron UI with source badges and preview-first actions"
      contains: "Runtime"
    - path: "test/oban_powertools/web/live/limiters_live_test.exs"
      provides: "Auth and explanation contract tests"
      contains: "Snapshot at Block Start"
  key_links:
    - from: "UI action"
      to: "ObanPowertools.Auth"
      via: "page-level and action-level authorization"
      pattern: "explain, then act"
    - from: "preview confirmation"
      to: "ObanPowertools.Audit and ObanPowertools.Telemetry"
      via: "mutating operator action flow"
      pattern: "preview -> authorize -> write"
---

<objective>
Expose the Phase 2 smart-engine concepts through narrow native operator pages. This plan stays isolated because `2-PATTERNS.md` and `2-RESEARCH.md` both flag LiveView interaction and testing as new surfaces in this repo, so the execution and verification burden needs to stay focused.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/phases/2-CONTEXT.md
@.planning/phases/2-UI-SPEC.md
@.planning/phases/2-RESEARCH.md
@.planning/phases/2-PATTERNS.md
@.planning/phases/2-VALIDATION.md
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Native Overview and Explanation-First Limiters UI</name>
  <files>lib/oban_powertools/web/router.ex, lib/oban_powertools/web/live/engine_overview_live.ex, lib/oban_powertools/web/live/limiters_live.ex, test/oban_powertools/web/live/limiters_live_test.exs</files>
  <behavior>
    - The existing `/ops/jobs` shell gains narrow native overview and limiter surfaces.
    - Blocked-job detail renders `Live Now` and `Snapshot at Block Start` distinctly.
    - Generic job inspection deep-links to Oban Web instead of reimplementing a full jobs console.
  </behavior>
  <action>
    Extend the router and add LiveViews for the overview and limiters pages.
    Follow the no-analog guidance from `2-PATTERNS.md` and `2-RESEARCH.md`: keep modules small, server-driven, and backed by direct LiveView interaction tests rather than relying only on route tests.
    Test rendering and interaction around blocker ordering, explanation tabs, and deep links to generic job inspection.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/web/live/limiters_live_test.exs</automated>
  </verify>
  <done>Operators can inspect live limiter state and blocker evidence through an explanation-first native surface.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Cron and Audit UI with Preview-First Actions</name>
  <files>lib/oban_powertools/web/live/cron_live.ex, lib/oban_powertools/web/live/audit_live.ex, test/oban_powertools/web/live/cron_live_test.exs, test/oban_powertools/web/live/audit_live_test.exs</files>
  <behavior>
    - Cron rows visibly distinguish `Code` and `Runtime` entries.
    - Pause, resume, and run-now flows show preview-first confirmations before mutation.
    - Audit and telemetry side effects are asserted from the UI-triggered action path.
  </behavior>
  <action>
    Add cron and audit LiveViews that consume the Phase 2 services and render the locked source badges, action labels, and safe next steps from the UI spec.
    Keep mutating action flow explicit: preview -> auth check -> write action -> audit row -> telemetry event.
    Write LiveView tests that prove source badges, preview-first action flow, action-level authorization failures, and audit-history rendering.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/audit_live_test.exs</automated>
  </verify>
  <done>The native operator UI proves the locked interaction, auth, audit, and telemetry contract under direct LiveView tests.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Browser -> LiveView actions | Operator mutations must remain server-authorized and preview-first. |
| UI -> Audit/Telemetry | Every mutating action must produce durable audit evidence and low-cardinality telemetry. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-2-10 | Elevation of Privilege | native operator actions | mitigate | Enforce page-level and action-level checks through `ObanPowertools.Auth` and assert failures in LiveView tests. |
| T-2-11 | Repudiation | operator action history | mitigate | Verify each mutating flow writes normalized audit rows that the audit page can render. |
| T-2-12 | Information Disclosure | blocked-job evidence | mitigate | Keep detailed evidence in auth-gated views and expose only low-cardinality telemetry externally. |
</threat_model>

<verification>
mix test test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/audit_live_test.exs
</verification>

<success_criteria>
Operators can safely inspect and act on smart-engine state through narrow native pages that prove the locked UI, auth, audit, and preview-first contracts in direct LiveView tests.
</success_criteria>

<output>
After completion, create `.planning/phases/2-05-SUMMARY.md`
</output>
