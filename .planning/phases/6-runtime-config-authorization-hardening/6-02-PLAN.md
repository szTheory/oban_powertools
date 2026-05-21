---
phase: 6
plan: 02
type: execute
wave: 2
depends_on: ["Phase 6 Plan 01"]
files_modified: ["lib/oban_powertools/web/cron_live.ex", "lib/oban_powertools/web/live_auth.ex", "test/oban_powertools/web/live/cron_live_test.exs"]
autonomous: true
requirements: ["FND-02", "ENG-03"]
must_haves:
  truths:
    - "Unauthorized users never enter cron preview state."
    - "Cron actions remain visible to viewers but disabled with inline explanation when mutation permission is missing."
    - "No preview telemetry or preview-side state is generated for unauthorized attempts."
  artifacts:
    - path: "lib/oban_powertools/web/cron_live.ex"
      provides: "auth-before-preview cron UI"
      contains: "authorize_action"
    - path: "test/oban_powertools/web/live/cron_live_test.exs"
      provides: "unauthorized preview side-effect coverage"
      contains: "Preview Action"
  key_links:
    - from: "preview click"
      to: "LiveAuth"
      via: "action-level authorization"
      pattern: "authorize -> preview -> confirm"
---

<objective>
Close the cron preview authorization loophole while preserving the existing preview-first operator model and exposing permission boundaries before click.
</objective>

<execution_context>
@$HOME/.codex/get-shit-done/workflows/execute-plan.md
@$HOME/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/2-CONTEXT.md
@.planning/phases/4-CONTEXT.md
@.planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
@.planning/phases/6-runtime-config-authorization-hardening/6-RESEARCH.md
@.planning/phases/6-runtime-config-authorization-hardening/6-PATTERNS.md
@.planning/phases/6-runtime-config-authorization-hardening/6-VALIDATION.md
</context>

<tasks>

<task type="execute" tdd="true">
  <name>Task 1: Reorder cron preview flow so authorization happens before preview side effects</name>
  <files>lib/oban_powertools/web/cron_live.ex, lib/oban_powertools/web/live_auth.ex, test/oban_powertools/web/live/cron_live_test.exs</files>
  <read_first>
    - lib/oban_powertools/web/cron_live.ex
    - lib/oban_powertools/web/live_auth.ex
    - lib/oban_powertools/web/lifeline_live.ex
    - test/oban_powertools/web/live/cron_live_test.exs
    - test/oban_powertools/web/live/lifeline_live_test.exs
    - .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
  </read_first>
  <action>
    Update `CronLive.handle_event("preview", ...)` so it resolves the cron entry, builds the action resource, and calls authorization before any preview telemetry execution or `assign(:preview, ...)`.
    Preserve confirm-time authorization as defense in depth, but make the preview event the first enforcement point.
    Ensure unauthorized preview attempts leave `@preview` unset, render explicit permission copy, and produce no `[:oban_powertools, :operator_action, :previewed]` telemetry event.
    If `LiveAuth.authorize_action/3` currently only returns a generic message, extend it only as needed to support explicit in-page unauthorized preview feedback without weakening other action guards.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/web/cron_live.ex` contains authorization logic inside `handle_event("preview",`
    - `lib/oban_powertools/web/cron_live.ex` no longer executes preview telemetry before authorization
    - `test/oban_powertools/web/live/cron_live_test.exs` contains a test asserting unauthorized preview does not render `Preview Action`
    - `mix test test/oban_powertools/web/live/cron_live_test.exs` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/web/live/cron_live_test.exs</automated>
  </verify>
  <done>Unauthorized users cannot trigger preview state or preview telemetry in the cron LiveView.</done>
</task>

<task type="execute" tdd="true">
  <name>Task 2: Render disabled cron actions with inline permission explanations</name>
  <files>lib/oban_powertools/web/cron_live.ex, test/oban_powertools/web/live/cron_live_test.exs</files>
  <read_first>
    - lib/oban_powertools/web/cron_live.ex
    - test/oban_powertools/web/live/cron_live_test.exs
    - .planning/phases/2-05-PLAN.md
    - .planning/phases/6-runtime-config-authorization-hardening/6-CONTEXT.md
    - .planning/phases/6-runtime-config-authorization-hardening/6-PATTERNS.md
  </read_first>
  <action>
    Refactor cron row rendering so each action is computed with an enabled/disabled state derived from the current actor permissions and the mapped mutation action (`:pause_cron_entry`, `:resume_cron_entry`, `:run_cron_entry`).
    Keep actions visible for users who can view the cron page but cannot mutate entries. Render the button disabled and add inline explanatory copy such as `You do not have permission to pause cron entries.` rather than hiding the control or relying on a tooltip-only affordance.
    Ensure the disabled state respects the paused/unpaused entry variants and does not break the existing source badge, policy label, preview copy, or confirm flow for authorized users.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/web/cron_live.ex` renders disabled buttons or disabled-state markup for unauthorized actions
    - `test/oban_powertools/web/live/cron_live_test.exs` contains assertions for disabled action copy
    - the authorized preview-first flow test still asserts `Preview Action`
    - `mix test test/oban_powertools/web/live/cron_live_test.exs` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/web/live/cron_live_test.exs</automated>
  </verify>
  <done>The cron page communicates permission boundaries before click while preserving the preview-first mutation model for authorized operators.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Viewer -> mutation preview | Authorization must gate entry into preview state, not only final confirmation. |
| LiveView UI -> telemetry/audit side effects | Unauthorized clicks must not generate preview telemetry or any preview-side evidence. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-6-04 | Elevation of Privilege | cron preview flow | mitigate | Enforce action auth in the preview event path before state assignment. |
| T-6-05 | Information Disclosure | preview state | mitigate | Keep preview copy, reason field, and confirm affordance inaccessible to unauthorized viewers. |
| T-6-06 | Repudiation | preview telemetry | mitigate | Suppress preview telemetry for unauthorized clicks and verify absence in tests. |
</threat_model>

<verification>
mix test test/oban_powertools/web/live/cron_live_test.exs
</verification>

<success_criteria>
The cron UI stays preview-first for authorized operators, but unauthorized viewers never enter preview state and receive clear disabled-state explanations before they click.
</success_criteria>

<output>
After completion, create `.planning/phases/6-runtime-config-authorization-hardening/6-02-SUMMARY.md`
</output>
