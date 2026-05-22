---
phase: 9
plan: 02
type: execute
wave: 2
depends_on: ["9-01"]
files_modified: ["lib/oban_powertools/runtime_config.ex", "lib/oban_powertools/audit.ex", "lib/oban_powertools/web/cron_live.ex", "lib/oban_powertools/web/lifeline_live.ex", "lib/oban_powertools/web/audit_live.ex", "lib/oban_powertools/web/workflows_live.ex", "lib/oban_powertools/workflow/result.ex", "lib/oban_powertools/workflow/runtime.ex", "test/oban_powertools/web/live/cron_live_test.exs", "test/oban_powertools/web/live/lifeline_live_test.exs", "test/oban_powertools/web/live/audit_live_test.exs", "test/oban_powertools/web/live/workflows_live_test.exs"]
autonomous: true
requirements: ["POL-01", "POL-02"]
must_haves:
  truths:
    - "Hosts configure one explicit `display_policy` seam and Powertools applies it consistently across native operator surfaces."
    - "Audit and workflow persistence remain evidence-first; policy is applied at render time rather than by storing presentation strings."
    - "Audit principal `id`, `type`, and optional `label` become visible through shared helpers instead of page-local string handling."
  artifacts:
    - path: "lib/oban_powertools/runtime_config.ex"
      provides: "Centralized `display_policy` runtime contract"
      contains: "display_policy"
    - path: "lib/oban_powertools/web/audit_live.ex"
      provides: "Shared audit rendering over host-owned display decisions"
      contains: "Reason"
    - path: "lib/oban_powertools/web/workflows_live.ex"
      provides: "Shared workflow result display posture without mutating durable evidence"
      contains: "Result available"
  key_links:
    - from: "host `display_policy`"
      to: "native audit/workflow/operator pages"
      via: "shared library helpers"
      pattern: "raw evidence -> display decision -> rendered output"
    - from: "explicit principal envelope"
      to: "audit and workflow UI"
      via: "shared formatting helpers"
      pattern: "durable principal -> policy-aware render"
---

<objective>
Freeze the Phase 9 display, redaction, and formatter contract for native Powertools pages so policy-sensitive values render through one host-owned seam while durable evidence stays raw and inspectable.
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
@lib/oban_powertools/runtime_config.ex
@lib/oban_powertools/audit.ex
@lib/oban_powertools/web/cron_live.ex
@lib/oban_powertools/web/lifeline_live.ex
@lib/oban_powertools/web/audit_live.ex
@lib/oban_powertools/web/workflows_live.ex
@lib/oban_powertools/workflow/result.ex
@lib/oban_powertools/workflow/runtime.ex

<interfaces>
Current raw evidence surfaces:
```elixir
schema "oban_powertools_audit_events" do
  field(:actor_id, :string)
  field(:metadata, :map, default: %{})
end

schema "oban_powertools_workflow_results" do
  field(:payload, :map, default: %{})
  field(:redacted, :boolean, default: false)
  field(:summary, :string)
end
```
</interfaces>
</context>

<tasks>

<task type="execute" tdd="true">
  <name>Task 1: Add the host-owned display policy seam and shared rendering helpers</name>
  <files>lib/oban_powertools/runtime_config.ex, lib/oban_powertools/audit.ex, lib/oban_powertools/workflow/result.ex, lib/oban_powertools/workflow/runtime.ex</files>
  <read_first>
    - lib/oban_powertools/runtime_config.ex
    - lib/oban_powertools/audit.ex
    - lib/oban_powertools/workflow/result.ex
    - lib/oban_powertools/workflow/runtime.ex
    - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md
    - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-PATTERNS.md
  </read_first>
  <action>
    Introduce the Phase 9 `display_policy` seam through the existing `RuntimeConfig` pattern instead of ad hoc `Application.get_env/2` lookups. Keep the seam host-owned and fail-fast only at public render points where policy-sensitive native pages are mounted.
    Preserve the repo’s evidence-first posture by keeping audit rows and workflow results raw. If additional principal or display metadata is needed, store bounded structured data that supports rendering, but do not replace raw payloads or reasons with presentation strings. The `redacted` flag remains evidence metadata, not the complete UI contract.
    Add shared helpers or a narrow display adapter module that can render actor labels, reasons, payload summaries, and redaction outcomes for native pages without page-local duplication.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/runtime_config.ex` exposes a centralized `display_policy` runtime contract
    - `lib/oban_powertools/audit.ex` and `lib/oban_powertools/workflow/runtime.ex` continue storing raw evidence rather than pre-rendered display strings
    - no schema or service code path relies on page-local formatting helpers as the public policy seam
    - `mix test test/oban_powertools/auth_test.exs` exits 0 after the new runtime seam is added
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/auth_test.exs</automated>
  </verify>
  <done>The repo has one host-owned display-policy seam and shared helper posture without changing durable evidence into presentation-only data.</done>
</task>

<task type="execute" tdd="true">
  <name>Task 2: Apply shared display policy to native audit, workflow, and operator surfaces</name>
  <files>lib/oban_powertools/web/cron_live.ex, lib/oban_powertools/web/lifeline_live.ex, lib/oban_powertools/web/audit_live.ex, lib/oban_powertools/web/workflows_live.ex, test/oban_powertools/web/live/cron_live_test.exs, test/oban_powertools/web/live/lifeline_live_test.exs, test/oban_powertools/web/live/audit_live_test.exs, test/oban_powertools/web/live/workflows_live_test.exs</files>
  <read_first>
    - lib/oban_powertools/web/cron_live.ex
    - lib/oban_powertools/web/lifeline_live.ex
    - lib/oban_powertools/web/audit_live.ex
    - lib/oban_powertools/web/workflows_live.ex
    - test/oban_powertools/web/live/cron_live_test.exs
    - test/oban_powertools/web/live/lifeline_live_test.exs
    - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-RESEARCH.md
  </read_first>
  <action>
    Replace policy-sensitive page-local rendering with shared display helpers across native pages. `AuditLive` should stop rendering `event.actor_id || "system"` and raw reason strings directly; `WorkflowsLive` should stop relying on raw durable result state as its public display contract; cron and lifeline should reuse the same actor/reason/result formatting posture instead of local helper drift.
    Add focused LiveView tests for audit and workflow display behavior, and extend existing cron/lifeline tests where shared display helpers affect operator-visible copy. The test goal is parity: native pages should apply one consistent policy story for actor labels, reasons, result summaries, and redacted values.
    Do not broaden this plan into the Oban Web bridge yet. This plan only makes native surfaces coherent so the bridge can reuse the same contract in Plan 03.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/web/audit_live.ex` no longer directly renders `event.actor_id || "system"` as its policy contract
    - `lib/oban_powertools/web/workflows_live.ex` renders workflow-result information through shared display helpers or policy-aware components
    - `test/oban_powertools/web/live/audit_live_test.exs` exists and proves policy-aware audit rendering
    - `test/oban_powertools/web/live/workflows_live_test.exs` exists and proves workflow display respects the shared policy seam
    - `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs</automated>
  </verify>
  <done>Native Powertools pages share one host-owned display/redaction policy story while keeping durable evidence raw and operator-traceable.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Raw durable evidence -> user-visible operator UI | Policy-sensitive values must render consistently without mutating stored evidence into presentation-only strings. |
| Host display policy -> multiple native pages | One policy seam must govern audit, workflow, and operator rendering so surfaces cannot drift. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-9-04 | Information Disclosure | native UI rendering | mitigate | Introduce one host-owned display policy and route native pages through shared rendering helpers instead of ad hoc string handling. |
| T-9-05 | Tampering / support-truth confusion | audit/workflow display posture | mitigate | Keep audit/result evidence raw and structured while rendering through policy-aware helpers at read time. |
</threat_model>

<verification>
mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs
</verification>

<success_criteria>
Phase 9 gives native Powertools pages one explicit display and redaction contract, with raw evidence preserved underneath and no page-local drift in policy-sensitive rendering.
</success_criteria>

<output>
After completion, create `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-02-SUMMARY.md`
</output>
