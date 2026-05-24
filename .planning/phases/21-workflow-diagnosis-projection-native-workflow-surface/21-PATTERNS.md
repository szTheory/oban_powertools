# Phase 21: Workflow Diagnosis Projection & Native Workflow Surface - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/workflow/runtime.ex` | service | event-driven | `lib/oban_powertools/workflow/runtime.ex` | exact |
| `lib/oban_powertools/explain.ex` | utility | request-response | `lib/oban_powertools/explain.ex` | exact |
| `lib/oban_powertools/web/workflows_live.ex` | liveview | server-rendered | `lib/oban_powertools/web/workflows_live.ex` | exact |
| `lib/oban_powertools/lifeline.ex` | service | projection | `lib/oban_powertools/lifeline.ex` | exact |
| `test/oban_powertools/workflow_runtime_test.exs` | test | event-driven | `test/oban_powertools/workflow_runtime_test.exs` | exact |
| `test/oban_powertools/explain_test.exs` | test | integration | `test/oban_powertools/explain_test.exs` | exact |
| `test/oban_powertools/lifeline_test.exs` | test | projection | `test/oban_powertools/lifeline_test.exs` | exact |
| `test/oban_powertools/web/live/workflows_live_test.exs` | test | liveview | `test/oban_powertools/web/live/workflows_live_test.exs` | exact |

## Pattern Assignments

### `lib/oban_powertools/workflow/runtime.ex` (service, event-driven)

**Analog:** `lib/oban_powertools/workflow/runtime.ex`

**Diagnosis ordering is runtime-owned today and therefore the correct seam to harden before UI work** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:777))
```elixir
def workflow_diagnosis(%Workflow{} = workflow, steps) do
  cond do
    workflow.state == "cancel_requested" or not is_nil(workflow.cancel_requested_at) ->
      "cancel_requested"
    workflow.state == "expired" ->
      "expired_wait"
    workflow.terminal_cause ->
      workflow.terminal_cause
```

**Step diagnosis is already a bounded vocabulary reducer over durable facts** ([runtime.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/runtime.ex:796))
```elixir
def step_diagnosis(%Step{} = step) do
  cond do
    step.state == "awaiting_signal" ->
      "waiting_on_signal"
    "waiting_on_retryable_dependency" in step.blocker_codes ->
      "waiting_on_retryable_dependency"
```

**Pattern takeaway for Phase 21:** keep diagnosis precedence and unsupported-state handling in `Runtime` or a shared projector seam, not in HEEx conditionals.

### `lib/oban_powertools/explain.ex` (utility, request-response)

**Analog:** `lib/oban_powertools/explain.ex`

**Workflow story is the existing shared seam for workflow-level read models** ([explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:121))
```elixir
%{
  diagnosis: Runtime.workflow_diagnosis(workflow, steps),
  semantics: Runtime.semantics_profile(workflow),
  latest_rejection: latest_rejection,
  rejection_summary: rejection_summary(latest_rejection),
  callback_posture: callback_posture(repo, workflow.id),
  latest_recovery_session: latest_recovery_session(repo, workflow.id)
}
```

**Step story already bundles diagnosis plus refusal context for downstream surfaces** ([explain.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/explain.ex:134))
```elixir
%{
  diagnosis: Runtime.step_diagnosis(step),
  blocker_codes: step.blocker_codes,
  blocker_summaries: Enum.map(step.blocker_codes, &blocker_summary/1),
  latest_rejection: latest_rejection,
  rejection_summary: rejection_summary(latest_rejection)
}
```

**Pattern takeaway for Phase 21:** expand `workflow_story/3` and `step_story/2` into the stable diagnosis projector rather than adding a second presenter layer.

### `lib/oban_powertools/web/workflows_live.ex` (liveview, server-rendered)

**Analog:** `lib/oban_powertools/web/workflows_live.ex`

**The page already uses patch-addressable step detail and server-chosen defaults** ([workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:242))
```elixir
selected_step =
  Enum.find(steps, &(&1.step_name == selected_step_name)) ||
    List.first(Enum.filter(steps, &(&1.blocker_codes != []))) ||
    List.first(steps)
```

**Current rendering is state-first and row-detail-heavy, which is exactly what Phase 21 is supposed to replace** ([workflows_live.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/workflows_live.ex:70))
```heex
<p class="mt-2 text-sm text-zinc-600">State: <%= @workflow.state %></p>
<p class="mt-1 text-sm text-zinc-600">Diagnosis: <%= @workflow_story.diagnosis %></p>
<p class="mt-1 text-sm text-zinc-600">Runnable now: <%= @workflow.runnable_step_count %></p>
```

**Pattern takeaway for Phase 21:** preserve `handle_params/3` plus `patch` navigation, but move the default selection logic and all narrative framing behind the projector.

### `lib/oban_powertools/lifeline.ex` (service, projection)

**Analog:** `lib/oban_powertools/lifeline.ex`

**Workflow-stuck incidents already consume `Explain.step_story/2` rather than forking diagnosis logic** ([lifeline.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/lifeline.ex:388))
```elixir
story = Explain.step_story(step, repo: repo)
diagnosis = story.diagnosis || "blocked"
...
"diagnosis" => diagnosis,
"blocker_summaries" => story.blocker_summaries,
```

**Pattern takeaway for Phase 21:** if workflow and Lifeline need parity, tighten the shared `Explain` payloads and let both surfaces inherit the same bounded vocabulary.

### Test surfaces

**Workflow story tests already prove callback posture and latest recovery session seams** ([explain_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/explain_test.exs:62))

**Workflows LiveView tests already prove patch-driven step selection and shared display-policy rendering** ([workflows_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/workflows_live_test.exs:35))

**Lifeline tests already prove workflow-stuck incident diagnosis and blocker summaries flow from shared explanation helpers** ([lifeline_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/lifeline_test.exs:98))

**Pattern takeaway for Phase 21:** extend the existing focused `Explain`, `Runtime`, `Lifeline`, and `WorkflowsLive` tests instead of introducing a new test harness.

## Implementation Notes

- Keep all meaning-bearing diagnosis choices in `Runtime` and `Explain`; `WorkflowsLive` should compose, not reinterpret.
- Preserve URL-addressable `?step=` routing and LiveView patch behavior while replacing the fallback selection heuristic with a deterministic primary-step policy.
- Use bounded maps and strings for narrative/evidence payloads so Phase 22 can reuse them for Lifeline and workflow actions without semantic drift.
- Prefer expanding existing tests over adding snapshot-heavy or HTML-fragile coverage.
