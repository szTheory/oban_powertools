---
phase: 7
plan: 02
type: execute
wave: 2
depends_on: ["Phase 7 Plan 01"]
files_modified: ["lib/oban_powertools/web/lifeline_live.ex", "test/oban_powertools/web/live/lifeline_live_test.exs"]
autonomous: true
requirements: ["LIF-02"]
must_haves:
  truths:
    - "The Lifeline page still lands on active incidents by default."
    - "After a successful repair, the acted-on incident leaves the active list and remains visible in a resolved destination with inline audit evidence."
    - "A fresh Lifeline mount no longer shows the repaired incident in `Needs Review` but still preserves closure evidence in the resolved view."
  artifacts:
    - path: "lib/oban_powertools/web/lifeline_live.ex"
      provides: "Active/resolved Lifeline continuity and post-execute selection logic"
      contains: "load_data"
    - path: "test/oban_powertools/web/live/lifeline_live_test.exs"
      provides: "LiveView refresh and remount regression coverage"
      contains: "resolved"
  key_links:
    - from: "successful execute event"
      to: "resolved incident selection"
      via: "selected fingerprint/status reload"
      pattern: "execute -> resolved destination"
    - from: "fresh live mount"
      to: "active incident list"
      via: "default Needs Review filter"
      pattern: "mount -> active default -> resolved evidence preserved elsewhere"
---

<objective>
Bring the native Lifeline LiveView into alignment with the repaired backend lifecycle so the UI remains incident-first, active-by-default, and evidence-first per D-16 through D-23 without inventing a new product surface.
</objective>

<execution_context>
@$HOME/.codex/get-shit-done/workflows/execute-plan.md
@$HOME/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/phases/4-UI-SPEC.md
@.planning/phases/4-CONTEXT.md
@.planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md
@.planning/phases/7-lifeline-incident-closure-integrity/7-RESEARCH.md
@.planning/phases/7-lifeline-incident-closure-integrity/7-PATTERNS.md

<interfaces>
From `lib/oban_powertools/web/lifeline_live.ex`:
```elixir
def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket)
def handle_event("select_incident", %{"row-id" => row_id}, socket)
def handle_event("preview", %{"row-id" => row_id}, socket)
def handle_event("execute", _params, socket)
defp load_data(socket, selected_row_id)
```

Current active-only load path:
```elixir
Lifeline.project_incidents(repo)
incidents = Lifeline.list_incidents(repo, status: "active")
incident_rows = expand_rows(repo, incidents)
selected_row = pick_selected_row(incident_rows, selected_row_id)
```
</interfaces>
</context>

<tasks>

<task type="execute" tdd="true">
  <name>Task 1: Split Lifeline active and resolved views while preserving post-execute selection continuity</name>
  <files>lib/oban_powertools/web/lifeline_live.ex</files>
  <read_first>
    - lib/oban_powertools/web/lifeline_live.ex
    - lib/oban_powertools/lifeline.ex
    - .planning/phases/4-UI-SPEC.md
    - .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md
    - .planning/phases/7-lifeline-incident-closure-integrity/7-PATTERNS.md
  </read_first>
  <action>
    Refactor `LifelineLive` so `load_data/2` loads both `status: "active"` and `status: "resolved"` incidents, while keeping `Needs Review` as the default landing posture per D-17 and the Phase 4 UI contract.
    Introduce an explicit active/resolved view state and selection model keyed by incident fingerprint or a status-plus-row selector instead of reselecting by active-row id only; after a successful execute, reload into the resolved destination for `preview.incident_fingerprint` per D-18 through D-21.
    Preserve the existing visual language from Phase 4 and do not invent a new design system. The change here is behavioral and structural: active incidents answer what still needs action, resolved incidents answer what just happened and what proof was written.
    Keep the inline manual intervention history and success copy attached to the acted-on incident after execute, and ensure the active table no longer mixes resolved rows into `Needs Review` per D-20.
  </action>
  <acceptance_criteria>
    - `lib/oban_powertools/web/lifeline_live.ex` loads both active and resolved incident collections
    - `lib/oban_powertools/web/lifeline_live.ex` contains explicit active/resolved view state or handler logic
    - `lib/oban_powertools/web/lifeline_live.ex` no longer calls `load_data(row.id)` on successful execute
    - `lib/oban_powertools/web/lifeline_live.ex` still renders `Needs Review` as the default active heading
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/web/live/lifeline_live_test.exs -x</automated>
  </verify>
  <done>The LiveView has a durable resolved destination for repaired incidents and no longer relies on active-row-only reselection.</done>
</task>

<task type="execute" tdd="true">
  <name>Task 2: Prove refresh and remount behavior for resolved incidents with Phoenix.LiveViewTest</name>
  <files>test/oban_powertools/web/live/lifeline_live_test.exs, lib/oban_powertools/web/lifeline_live.ex</files>
  <read_first>
    - test/oban_powertools/web/live/lifeline_live_test.exs
    - lib/oban_powertools/web/lifeline_live.ex
    - test/oban_powertools/lifeline_test.exs
    - .planning/phases/7-lifeline-incident-closure-integrity/7-CONTEXT.md
    - .planning/phases/4-UI-SPEC.md
  </read_first>
  <action>
    Extend `test/oban_powertools/web/live/lifeline_live_test.exs` with the exact D-23 UI proof points:
    1. after preview + execute, the repaired incident is absent from the active `Needs Review` list and visible in the resolved destination with the success copy and audit reason still attached;
    2. after a fresh `live(conn, "/ops/jobs/lifeline")` mount, the page defaults to active incidents and still does not show the repaired incident in the active list;
    3. switching to the resolved view after remount reveals the repaired incident plus manual intervention history;
    4. drifted or unauthorized flows do not move the incident into resolved state.
    Adjust `LifelineLive` markup only as needed to make those assertions deterministic with `has_element?/2` and `render_click/2`; prefer stable labels and buttons over fragile raw HTML matching.
  </action>
  <acceptance_criteria>
    - `test/oban_powertools/web/live/lifeline_live_test.exs` contains a remount regression that calls `live(conn, "/ops/jobs/lifeline")` after execute
    - `test/oban_powertools/web/live/lifeline_live_test.exs` asserts the repaired incident is absent from `Needs Review`
    - `test/oban_powertools/web/live/lifeline_live_test.exs` asserts the resolved view shows the repaired incident and manual intervention history
    - `mix test test/oban_powertools/web/live/lifeline_live_test.exs -x` exits 0
  </acceptance_criteria>
  <verify>
    <automated>mix test test/oban_powertools/web/live/lifeline_live_test.exs -x</automated>
  </verify>
  <done>LiveView coverage proves both immediate refresh and fresh mount behavior for repaired incidents, matching the Phase 7 verification bar.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Backend incident lifecycle -> LiveView selection state | The UI must not reselect an unrelated active row or hide closure evidence after execute. |
| Fresh mount -> operator action queue | Default active views must not replay repaired incidents into `Needs Review`. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-7-05 | Information Disclosure / operator confusion | `LifelineLive` post-execute flow | mitigate | Switch selection to a resolved destination keyed to the acted-on fingerprint instead of falling back to another active row. |
| T-7-06 | Tampering | active/resolved list rendering | mitigate | Load active and resolved incidents separately so resolved rows do not remain mixed into the active queue. |
| T-7-07 | Repudiation | resolved incident evidence | mitigate | Keep success copy and manual intervention history inline with the resolved incident so closure proof stays visible after execute and remount. |
</threat_model>

<verification>
mix test test/oban_powertools/web/live/lifeline_live_test.exs -x
</verification>

<success_criteria>
The Lifeline UI remains active-by-default, but repaired incidents move cleanly into a resolved destination that survives refreshes and fresh mounts without losing audit evidence.
</success_criteria>

<output>
After completion, create `.planning/phases/7-lifeline-incident-closure-integrity/7-02-SUMMARY.md`
</output>
