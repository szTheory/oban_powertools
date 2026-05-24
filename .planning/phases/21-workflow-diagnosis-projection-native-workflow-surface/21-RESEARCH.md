# Phase 21: Workflow Diagnosis Projection & Native Workflow Surface - Research

**Researched:** 2026-05-24  
**Domain:** Durable workflow diagnosis projection and Phoenix LiveView operator presentation  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md`. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]

### Locked Decisions
- **D-01:** Treat the recommendations in this context as locked defaults for downstream GSD planning and implementation. Do not reopen them unless a later choice would materially change operator trust, support truth, public semantics, or maintainer burden.
- **D-02:** Shift recommendation defaults left for this project and within GSD where possible. Prefer decisive best-practice recommendations over re-asking, except for unusually high-impact public-semantic choices the user is likely to care about directly.
- **D-03:** Keep Postgres-backed rows as the only correctness-bearing truth source. LiveView, PubSub, and coordinator updates remain projections over durable facts rather than independent sources of meaning.
- **D-04:** Preserve the repo's host-owned Phoenix/Ecto posture: explicit read models, thin LiveViews over domain services, bounded vocabulary, support-truthful copy, and least-surprise operator UX.
- **D-05:** Make the native workflow screen diagnosis-first at the top level rather than state/details-first.
- **D-06:** The first question the page should answer is "what is happening and why?" rather than "what fields are on this workflow row?"
- **D-07:** Raw state, counts, steps, and row-derived details remain available, but they are secondary to the projected diagnosis summary.
- **D-08:** The workflow-level diagnosis summary should render three things prominently: cause, concise evidence, and allowed next action.
- **D-09:** Unsupported or ambiguous states must be rendered explicitly as unsupported/unknown rather than guessed or smoothed over with optimistic copy.
- **D-10:** Use a narrative-plus-evidence presentation model:
  one short operator-facing headline,
  one compact evidence section,
  and exact durable facts underneath or behind an expandable section.
- **D-11:** Do not make operators assemble the story manually from blocker codes, state fields, timestamps, and rejection rows spread across the page.
- **D-12:** Do not make the narrative a freehand HEEx concern. The narrative must be derived from one shared read-model projector so workflow UI and Lifeline can speak the same language.
- **D-13:** The evidence section should prioritize durable facts that explain the diagnosis, such as:
  active await/deadline,
  matching or late signal facts,
  terminal cause,
  cancel request timing,
  callback posture,
  latest refusal,
  and latest recovery session where relevant.
- **D-14:** Raw codes and exact row-derived fields should still be available for support/debug depth, but they are not the default operator-facing surface.
- **D-15:** Narrative wording must never outrun durable truth. If the facts do not support a confident sentence, fall back to explicit unknown/unsupported phrasing.
- **D-16:** Use one primary diagnosis step as the focal detail view, while still showing the rest of the workflow graph/list as supporting context.
- **D-17:** Do not keep all steps visually and semantically equal by default; that turns the screen into a prettier database browser and slows diagnosis.
- **D-18:** The primary diagnosis step should be chosen from durable evidence priority rather than display order or first-match convenience.
- **D-19:** Default priority order for the primary diagnosis step is:
  final or terminal cause with actionable evidence,
  then expired wait / waiting on signal,
  then waiting on retryable dependency,
  then missing dependency result,
  then cancel-requested branch state.
- **D-20:** Operators may manually inspect another step, but the UI should still indicate which step is the current primary diagnosis anchor and why.
- **D-21:** The primary step pane should include the diagnosis, concise evidence, dependency chain or downstream impact where relevant, and the allowed next action guidance for that step/workflow situation.
- **D-22:** In Phase 21, allowed next action is informational guidance only.
- **D-23:** Do not add clickable workflow mutation controls in this phase, even for a small subset of actions.
- **D-24:** Allowed next action should mean "what the system would legally accept from durable truth," not "what this screen can execute today."
- **D-25:** The workflow screen should reuse existing durable refusal and `legal_next_steps` evidence where available so the guidance is grounded in the command core rather than invented in the UI.
- **D-26:** Phase 22 owns bounded, audited, preview/reason-backed workflow actions. Phase 21 should prepare that future surface by making the guidance legible, not by partially implementing a second mutation UX early.
- **D-27:** Add or expand one shared workflow diagnosis projector behind `ObanPowertools.Explain` rather than letting `WorkflowsLive` build stories ad hoc from raw assigns.
- **D-28:** The projector should produce a stable read model for both workflow-level and step-level presentation, including at least:
  `headline`,
  `diagnosis`,
  `primary_step`,
  `allowed_next_action`,
  `evidence_items`,
  `raw_facts`,
  and refusal/recovery/callback summaries where relevant.
- **D-29:** Workflow UI and Lifeline should consume the same diagnosis vocabulary and evidence posture so the operator does not have to learn two explanation systems.
- **D-30:** Final truth must outrank lingering request evidence in the projected diagnosis. For example, once a workflow is terminal, the surface must not keep presenting generic `cancel_requested` when a more specific final outcome such as `completed_after_cancel_request` or `expired_wait` is known.
- **D-31:** Use layered operator UX:
  diagnosis summary first,
  evidence second,
  full internals third.
- **D-32:** Keep the current native workflow screen readable for both solo operators and maintainers:
  fast answer on top,
  exact facts one click lower,
  raw internals still reachable.
- **D-33:** Do not hide the rest of the DAG; show it as context around the primary diagnosis rather than as the only way to infer what is happening.
- **D-34:** Keep the screen support-truthful and explicit about unavailable features.
  If an action is guidance-only in Phase 21, say so plainly.
- **D-35:** Stay coherent with the existing Phase 10 operator contract:
  explain first,
  keep mutation trust high,
  and avoid introducing a weaker second action path than Lifeline's preview/reason/audit model.

### Claude's Discretion
- Exact naming of the new projector structs/maps and helper functions, provided they stay thin, shared, and driven from durable facts.
- Exact layout, component decomposition, and visual emphasis in the LiveView, provided the diagnosis-first, evidence-second, raw-facts-third posture holds.
- Exact evidence-item field list per diagnosis class, provided the defaults remain compact, support-truthful, and reusable by future Lifeline/workflow surfaces.
- Exact primary-step prioritization helper implementation, provided it is deterministic, durable-fact-driven, and not just first-by-position.

### Deferred Ideas (OUT OF SCOPE)
- Clickable workflow actions inside the native workflow screen — Phase 22 ownership.
- A broader mutation control surface that duplicates or bypasses Lifeline's preview/reason/audit semantics — out of scope for Phase 21.
- Full DAG graph redesign or a generic workflow-debugging console beyond the diagnosis-first native surface needed for this milestone.
- Optional `oban_web` bridge expansion or plugin-like workflow pages inside the bridge — explicitly outside this phase's boundary.
</user_constraints>

## Summary

Phase 21 should be planned as a read-model and presentation phase, not as a workflow-engine phase. The runtime already owns the bounded diagnosis vocabulary through `Runtime.workflow_diagnosis/2` and `Runtime.step_diagnosis/1`, and `Explain.workflow_story/3` plus `Explain.step_story/2` already exist as the seam where workflow truth, refusal evidence, callback posture, and recovery posture are assembled for UI consumers. The current gap is that those read models are too thin and `WorkflowsLive` still behaves like a row/step browser instead of a diagnosis-first operator surface. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/explain.ex; lib/oban_powertools/web/workflows_live.ex]

The planning posture should therefore be: extend one shared projector behind `ObanPowertools.Explain`, make primary-step selection deterministic from durable evidence priority, and keep `WorkflowsLive` responsible only for routing, patch-driven step focus, and layered rendering. This fits the repo’s existing v1.2 contract that Postgres rows remain the only correctness-bearing truth, workflow mutations stay DB-first, and native operator surfaces explain first while Phase 22 owns actual bounded recovery controls. [VERIFIED: .planning/PROJECT.md; .planning/ROADMAP.md; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]

The existing proof stack is a good base but not yet sufficient for Phase 21’s new responsibilities. Current tests already prove workflow read-only LiveView rendering, selected-step patch behavior, rejection vocabulary display, Lifeline incident projection, and workflow runtime race semantics, but there is no proof yet for workflow-level headline/evidence projection, explicit primary-step priority ordering, final-truth-over-request precedence in the UI, or explicit unsupported/unknown-state rendering. Those should be treated as Wave 0 gaps in planning, not polish. [VERIFIED: test/oban_powertools/web/live/workflows_live_test.exs; test/oban_powertools/explain_test.exs; test/oban_powertools/lifeline_test.exs; test/oban_powertools/workflow_runtime_test.exs]

**Primary recommendation:** Implement Phase 21 as a shared diagnosis projector expansion in `ObanPowertools.Explain`, then reshape `WorkflowsLive` into a diagnosis-first, patch-addressable surface that consumes that projector without inventing new semantics in HEEx. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/explain.ex; lib/oban_powertools/web/workflows_live.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Durable diagnosis classification | API / Backend | Database / Storage | `Runtime.workflow_diagnosis/2` and `Runtime.step_diagnosis/1` already reduce durable workflow and step rows into bounded vocabulary; UI should consume, not infer. [VERIFIED: lib/oban_powertools/workflow/runtime.ex] |
| Workflow diagnosis projection read model | API / Backend | Database / Storage | `Explain.workflow_story/3` and `Explain.step_story/2` already assemble read models from workflow rows, `CommandAttempt`, callback outbox, and recovery sessions. [VERIFIED: lib/oban_powertools/explain.ex] |
| Allowed-next-action guidance | API / Backend | Database / Storage | Durable legal-next-step evidence already lives on rejected `CommandAttempt.metadata["legal_next_steps"]`, so guidance belongs in the projector. [VERIFIED: lib/oban_powertools/explain.ex; lib/oban_powertools/workflow/runtime.ex] |
| Primary diagnosis step selection | API / Backend | Frontend Server (SSR) | Priority is semantic, not visual; the server should choose the default anchor from durable evidence, while LiveView only reflects or overrides that selection through params. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/web/workflows_live.ex] |
| Diagnosis-first page layout | Frontend Server (SSR) | Browser / Client | `WorkflowsLive` already owns mount, `handle_params/3`, and patch-driven selected-step detail; it should render the projector output in layers. [VERIFIED: lib/oban_powertools/web/workflows_live.ex] |
| Step detail switching | Browser / Client | Frontend Server (SSR) | LiveView patch navigation is the standard same-view navigation mechanism; the client triggers patches and `handle_params/3` reloads the selected detail state. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Exact fact drill-down | Frontend Server (SSR) | Database / Storage | Raw row values, blocker details, dependency snapshots, callback posture, and refusal facts should be exposed one layer down without changing truth ownership. [VERIFIED: lib/oban_powertools/explain.ex; lib/oban_powertools/web/workflows_live.ex] |

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Phoenix | 1.8.7 | Host web framework and LiveView routing shell for native operator pages. [VERIFIED: mix.lock] | The repo already resolves Phoenix 1.8.7 and its current Hex package page shows 1.8.7 as the latest stable release updated May 6, 2026. [VERIFIED: mix.lock; CITED: https://hex.pm/packages/phoenix/dependencies] |
| Phoenix LiveView | 1.1.30 | Same-view patch navigation, `handle_params/3`, and server-rendered operator UI. [VERIFIED: mix.lock] | `WorkflowsLive` already uses the standard LiveView mount plus patch flow, and official docs explicitly position `patch`/`push_patch` plus `handle_params/3` as the minimal-diff navigation path for the current LiveView. [VERIFIED: lib/oban_powertools/web/workflows_live.ex; CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Ecto SQL | 3.13.5 | Query layer over durable workflow truth, command evidence, callback outbox, and recovery rows. [VERIFIED: mix.lock] | The repo is already built around explicit Ecto queries and schemas, and no phase decision suggests introducing another read-model store. Hex shows 3.14.0 exists upstream, but Phase 21 should plan against the locked repo version 3.13.5 unless a separate upgrade phase is opened. [VERIFIED: mix.lock; CITED: https://hex.pm/packages/ecto_sql] |
| Postgrex | 0.22.2 | Postgres adapter backing the only correctness-bearing truth source. [VERIFIED: mix.lock] | Phase 21 decisions explicitly keep Postgres rows as the only truth source and the repo resolves Postgrex 0.22.2. [VERIFIED: mix.lock; VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; CITED: https://hex.pm/packages/postgrex] |
| Oban | 2.22.1 | Underlying job/workflow substrate and native operator ecosystem boundary. [VERIFIED: mix.lock] | The library remains Oban-native and current lockfile resolution matches the latest 2.22.1 release listed on Hex, updated April 30, 2026 in the changelog. [VERIFIED: mix.lock; CITED: https://hex.pm/packages/oban; CITED: https://hexdocs.pm/oban/changelog.html] |
| `ObanPowertools.Workflow.Runtime` + `ObanPowertools.Explain` | repo-local | Canonical diagnosis vocabulary plus shared diagnosis projector seam. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/explain.ex] | These modules already centralize workflow diagnosis and story assembly, which makes them the standard phase-local stack instead of new service objects or UI-only helpers. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/explain.ex] |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `ObanPowertools.Web.WorkflowsLive` | repo-local | Native workflow page routing, assigns, and layered rendering. [VERIFIED: lib/oban_powertools/web/workflows_live.ex] | Use for page composition only after the projector has already decided the vocabulary and evidence. [VERIFIED: lib/oban_powertools/web/workflows_live.ex] |
| `ObanPowertools.Lifeline` | repo-local | Neighboring consumer of shared step diagnosis vocabulary and incident evidence. [VERIFIED: lib/oban_powertools/lifeline.ex] | Use as the consistency check for shared projector outputs and wording drift. [VERIFIED: lib/oban_powertools/lifeline.ex] |
| Phoenix.LiveViewTest | 1.1.30 | Primary proof lane for routable LiveViews, patches, and rendered state assertions. [VERIFIED: mix.lock] | Use for page-level workflow UI verification because official docs recommend routable LiveView tests whenever navigation behavior matters. [VERIFIED: mix.lock; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared projector in `Explain` | Ad hoc HEEx conditionals inside `WorkflowsLive` | Faster to spike, but it would fork semantics from Lifeline and violate the locked “not a freehand HEEx concern” decision. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/web/workflows_live.ex] |
| Informational allowed-next-action text | Early clickable workflow controls | Tempting for UX, but explicitly out of scope for Phase 21 and would create a weaker second mutation path before Phase 22’s preview/reason/audit contract. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md] |
| Native Powertools workflow screen | Wider `oban_web` bridge ownership | The repo roadmap and phase context keep workflow-semantic explanation in Powertools-owned native surfaces, not a widened bridge. [VERIFIED: .planning/ROADMAP.md; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md] |

**Installation:** No new dependencies are recommended for Phase 21; stay on the existing repo stack and add repo-local projector/presentation code only. [VERIFIED: mix.exs; mix.lock]

**Version verification:** The repo currently resolves Phoenix `1.8.7`, Phoenix LiveView `1.1.30`, Oban `2.22.1`, Ecto SQL `3.13.5`, and Postgrex `0.22.2` in `mix.lock`. Hex currently lists Phoenix `1.8.7`, Phoenix LiveView `1.1.30`, Oban `2.22.1`, and Postgrex `0.22.2` as current stable versions, while Ecto SQL has moved to `3.14.0`, which is newer than the repo lock and should not be folded into Phase 21 scope. [VERIFIED: mix.lock; CITED: https://hex.pm/packages/phoenix/dependencies; CITED: https://hex.pm/packages/phoenix_live_view; CITED: https://hex.pm/packages/oban; CITED: https://hex.pm/packages/postgrex; CITED: https://hex.pm/packages/ecto_sql]

## Architecture Patterns

### System Architecture Diagram

```text
Workflow rows / step rows / await rows / signal rows / command attempts / callback outbox / recovery sessions
        |
        v
ObanPowertools.Workflow.Runtime
  - canonical workflow_diagnosis/2
  - canonical step_diagnosis/1
  - final-truth precedence
        |
        v
ObanPowertools.Explain projector
  - workflow summary headline
  - evidence items
  - primary_step selection
  - allowed_next_action guidance
  - raw_facts bundle
        |
        +-----------------------> ObanPowertools.Lifeline incident projection
        |
        v
ObanPowertools.Web.WorkflowsLive
  - load_workflow_detail/3
  - patch-driven selected step
  - diagnosis-first render
        |
        v
Operator
  - sees cause
  - sees evidence
  - sees legal next action guidance
  - expands raw facts if needed
```

The key planning rule is that only the top two layers own meaning. `WorkflowsLive` should not re-reduce workflow semantics from raw step fields because that would duplicate `Runtime` and drift from Lifeline. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/explain.ex; lib/oban_powertools/web/workflows_live.ex; lib/oban_powertools/lifeline.ex]

### Recommended Project Structure

```text
lib/oban_powertools/
├── workflow/runtime.ex          # Canonical diagnosis vocabulary and precedence helpers
├── explain.ex                   # Shared workflow + step projector read model
├── lifeline.ex                  # Incident projection consumer of shared vocabulary
└── web/workflows_live.ex        # Thin diagnosis-first page composition

test/oban_powertools/
├── explain_test.exs             # Projector behavior and primary-step selection
├── workflow_runtime_test.exs    # Precedence and durable-fact semantics
├── lifeline_test.exs            # Shared diagnosis vocabulary in incidents
└── web/live/workflows_live_test.exs # UI rendering and patch behavior
```

This structure already exists in the repo; planning should add focused helpers and tests inside these seams before introducing new files. A split from `Explain` into a dedicated `Explain.WorkflowDiagnosis` module is acceptable only if it keeps the same shared seam and does not create a second vocabulary surface. [VERIFIED: lib/oban_powertools/explain.ex; lib/oban_powertools/web/workflows_live.ex; test/oban_powertools/explain_test.exs; test/oban_powertools/web/live/workflows_live_test.exs]

### Pattern 1: Shared Workflow Diagnosis Projector

**What:** Expand `Explain.workflow_story/3` from a thin metadata bundle into the stable workflow read model the phase context asks for: `headline`, `diagnosis`, `primary_step`, `allowed_next_action`, `evidence_items`, `raw_facts`, and relevant refusal/callback/recovery summaries. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/explain.ex]

**When to use:** Use whenever any Powertools-owned surface needs to explain workflow state or step state from durable rows. [VERIFIED: .planning/REQUIREMENTS.md; lib/oban_powertools/lifeline.ex]

**Example:**

```elixir
# Source: local pattern from the current repo seam
def workflow_story(%Workflow{} = workflow, steps, opts \\ []) when is_list(steps) do
  repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
  latest_rejection = latest_rejection(repo, workflow.id)

  %{
    diagnosis: Runtime.workflow_diagnosis(workflow, steps),
    semantics: Runtime.semantics_profile(workflow),
    latest_rejection: latest_rejection,
    rejection_summary: rejection_summary(latest_rejection),
    callback_posture: callback_posture(repo, workflow.id),
    latest_recovery_session: latest_recovery_session(repo, workflow.id)
  }
end
```

The planner should treat this existing function as the expansion point rather than adding a second “presenter” layer in `WorkflowsLive`. [VERIFIED: lib/oban_powertools/explain.ex]

### Pattern 2: Patch-Addressable Primary Step Detail

**What:** Keep one canonical primary step chosen by the server, but keep the detail pane URL-addressable through LiveView patch params so operators can inspect another step without remounting. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/web/workflows_live.ex]

**When to use:** Use for same-page detail changes inside the workflow page. [VERIFIED: lib/oban_powertools/web/workflows_live.ex]

**Example:**

```heex
<!-- Source: https://hexdocs.pm/phoenix_live_view/live-navigation.html -->
<.link patch={~p"/pages/#{@page + 1}"}>Next</.link>
```

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
{:noreply, push_patch(socket, to: "/")}
```

Official LiveView guidance is explicit that `patch`/`push_patch` is the right mechanism for navigating within the current LiveView and that `handle_params/3` is immediately invoked to update the URL state. Phase 21 should keep that model and replace only the default step-selection heuristic. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Pattern 3: Test the Workflow Surface as a Routable LiveView

**What:** Verify the native page through connected LiveView tests and patch assertions instead of HTML-string-only checks. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

**When to use:** Use for workflow page navigation, read-only framing, selected-step continuity, and diagnosis rendering behavior. [VERIFIED: test/oban_powertools/web/live/workflows_live_test.exs]

**Example:**

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
{:ok, view, html} = live(conn, "/my-path")
assert html =~ "<h1>My Connected View</h1>"
```

The repo already follows this pattern in `workflows_live_test.exs`, so Wave 0 work should extend that file rather than introduce a parallel browser-only test lane. [VERIFIED: test/oban_powertools/web/live/workflows_live_test.exs]

### Anti-Patterns to Avoid

- **Ad hoc narrative in HEEx:** `WorkflowsLive` currently renders `workflow_story` and `step_story`; planning should deepen those stories, not scatter `cond` trees through the template. [VERIFIED: lib/oban_powertools/web/workflows_live.ex; lib/oban_powertools/explain.ex]
- **First blocked step wins:** The current default selection is `selected_step_name` or the first blocked step or the first step in display order, which violates the locked durable-priority ordering for the primary diagnosis step. [VERIFIED: lib/oban_powertools/web/workflows_live.ex; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]
- **Request evidence outranks final truth:** `Runtime.workflow_diagnosis/2` currently returns `"cancel_requested"` before checking `workflow.terminal_cause`, which conflicts with the locked Phase 21 rule that final truth must outrank lingering request evidence once terminal meaning is known. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]
- **Second mutation path:** Showing legal next steps as buttons in Phase 21 would contradict the locked split between explanation now and bounded audited actions in Phase 22. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Workflow narrative wording | One-off string assembly inside LiveView render blocks | Shared projector behind `ObanPowertools.Explain` | Keeps vocabulary aligned across workflow UI and Lifeline and avoids HEEx-only semantics drift. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/explain.ex; lib/oban_powertools/lifeline.ex] |
| Same-view detail navigation | Custom JS state or local-only client tabs | LiveView patch params plus `handle_params/3` | Official LiveView docs already define patch navigation for same-view URL state changes. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Allowed-next-action inference | Invented UI heuristics from workflow state strings alone | Existing `CommandAttempt` rejection evidence and durable legal-next-step vocabulary | The repo already persists refusal reasons and `legal_next_steps`; reuse that before adding new guidance rules. [VERIFIED: lib/oban_powertools/explain.ex; lib/oban_powertools/workflow/runtime.ex] |
| Shared diagnosis reuse | Copy-pasted step diagnosis logic in Lifeline and workflow UI | `Runtime.step_diagnosis/1` plus `Explain.step_story/2` | Lifeline already depends on `Explain.step_story/2`; Phase 21 should keep one shared explanation stack. [VERIFIED: lib/oban_powertools/lifeline.ex; lib/oban_powertools/explain.ex] |

**Key insight:** The hard part of this phase is semantic projection, not HTML layout. If the projector is right, the LiveView work is straightforward; if the projector is wrong, the UI will look coherent while lying. [VERIFIED: lib/oban_powertools/explain.ex; lib/oban_powertools/web/workflows_live.ex; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Terminal truth is hidden behind `cancel_requested`

**What goes wrong:** Operators see generic cancel-request wording even when the workflow has already reached a more specific terminal truth such as `completed_after_cancel_request` or `expired_wait`. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]

**Why it happens:** `Runtime.workflow_diagnosis/2` currently checks `workflow.state == "cancel_requested" or not is_nil(workflow.cancel_requested_at)` before `workflow.terminal_cause`. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]

**How to avoid:** Move precedence rules into one canonical diagnosis projector path where terminal cause wins once terminal truth exists, and prove it with runtime plus LiveView tests. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; test/oban_powertools/workflow_runtime_test.exs]

**Warning signs:** Workflow row is terminal, but the top-of-page summary still reads `cancel_requested` and hides the late outcome story. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]

### Pitfall 2: The default primary step is chosen by position, not evidence

**What goes wrong:** The page focuses the first blocked step or first step in the list instead of the step that best explains the workflow’s current state. [VERIFIED: lib/oban_powertools/web/workflows_live.ex]

**Why it happens:** `load_workflow_detail/3` currently falls back to `List.first(Enum.filter(steps, &(&1.blocker_codes != []))) || List.first(steps)`. [VERIFIED: lib/oban_powertools/web/workflows_live.ex]

**How to avoid:** Add a deterministic projector helper that ranks steps by the locked evidence priority and emits both the chosen `primary_step` and the reason it was chosen. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]

**Warning signs:** A workflow waiting on a signal still opens on an unrelated pending step because that step appears first in DAG order. [VERIFIED: lib/oban_powertools/web/workflows_live.ex; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]

### Pitfall 3: Workflow and Lifeline drift into different explanation systems

**What goes wrong:** Operators see one diagnosis word on the workflow page and another in Lifeline incident evidence for the same durable situation. [VERIFIED: .planning/REQUIREMENTS.md; lib/oban_powertools/lifeline.ex]

**Why it happens:** The repo already has two consumers, and divergence becomes easy if one page adds presentation-only semantic helpers. [VERIFIED: lib/oban_powertools/lifeline.ex; lib/oban_powertools/web/workflows_live.ex]

**How to avoid:** Keep shared projector outputs and bounded vocabulary in `Runtime`/`Explain`, then make both surfaces consume them. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/explain.ex]

**Warning signs:** Incident evidence or workflow page copy mentions a diagnosis string not returned by `Runtime.step_diagnosis/1` or `Runtime.workflow_diagnosis/2`. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/lifeline.ex]

### Pitfall 4: “Allowed next action” is presented as capability instead of legality

**What goes wrong:** The page implies the UI can execute the action now, even though Phase 21 only provides guidance. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]

**Why it happens:** The wording is close to mutation UX and the repo already has actionable Lifeline flows elsewhere. [VERIFIED: lib/oban_powertools/web/lifeline_live.ex; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]

**How to avoid:** Phrase the field as legal next action guidance, source it from durable refusal/core evidence, and pair it with explicit Phase 21 read-only copy. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/explain.ex]

**Warning signs:** Buttons appear, or copy says “retry now” instead of “legal next action: retry” before Phase 22 exists. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]

## Code Examples

Verified patterns from official sources:

### Same-LiveView Step Selection via Patch

```heex
<!-- Source: https://hexdocs.pm/phoenix_live_view/live-navigation.html -->
<.link patch={~p"/pages/#{@page + 1}"}>Next</.link>
```

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
{:noreply, push_patch(socket, to: "/")}
```

Use this pattern for `?step=...` workflow detail selection so the URL remains shareable and `handle_params/3` remains the one place that recalculates selected detail state. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Routable LiveView Test

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
{:ok, view, html} = live(conn, "/my-path")
assert html =~ "<h1>My Connected View</h1>"
```

Phase 21 should keep using routable LiveView tests because official docs recommend them when live navigation matters. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| State/details-first workflow inspector | Diagnosis-first workflow projection with cause, evidence, and legal next action guidance | Locked for Phase 21 on 2026-05-24 in the discuss-phase context | Planning should center on read-model design, not generic DAG browsing. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md] |
| UI-level interpretation from blocker fields | Shared runtime plus explainability vocabulary reused by multiple native surfaces | Established by Phases 17-20 and called out again in Phase 21 | Reduces support drift and keeps final semantics in one place. [VERIFIED: .planning/PROJECT.md; lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/explain.ex; lib/oban_powertools/lifeline.ex] |
| Freeform navigation state | Patch-driven same-view navigation with `handle_params/3` | Standard Phoenix LiveView practice in 1.1.x | Keeps detail state shareable, testable, and minimal-diff. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |

**Deprecated/outdated:**

- Treating the workflow screen as a prettier database browser is now explicitly out of contract for this phase. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]
- Relying on `cancel_requested_at` as the primary diagnosis once a terminal cause exists is incompatible with the locked final-truth precedence rule. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]

## Assumptions Log

All material claims in this research were verified from repo files or cited from official Phoenix/Hex/Oban sources in this session. No user confirmation is required for hidden assumptions at the planning boundary. [VERIFIED: mix.lock; lib/oban_powertools/explain.ex; lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/web/workflows_live.ex]

## Open Questions

1. **Should the expanded projector stay inside `Explain` or split into a dedicated submodule?**
   - What we know: The phase context locks the seam “behind `ObanPowertools.Explain`” but leaves naming and helper decomposition to agent discretion. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]
   - What's unclear: Whether planner tasking should preserve a single file or introduce a focused module such as `ObanPowertools.Explain.WorkflowDiagnosis`. [VERIFIED: lib/oban_powertools/explain.ex]
   - Recommendation: Keep the planner neutral on file count and lock only the semantic seam: one shared projector consumed by both workflow UI and Lifeline. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/lifeline.ex]

2. **Where should allowed-next-action guidance come from when there is no recent refusal row?**
   - What we know: Current durable `legal_next_steps` evidence is available on rejected `CommandAttempt` rows, but the workflow page often needs proactive guidance before any refusal occurs. [VERIFIED: lib/oban_powertools/explain.ex; lib/oban_powertools/workflow/runtime.ex]
   - What's unclear: Whether the projector should derive positive guidance purely from diagnosis class, or whether planning should first add a reusable “legal next actions for current truth” helper in `Runtime`. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
   - Recommendation: Plan a small runtime-owned helper for positive guidance so the UI does not invent legality and refusal rows remain an augmenting evidence source. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]

3. **How much raw fact depth should render inline versus behind disclosure UI?**
   - What we know: The locked posture is diagnosis first, evidence second, full internals third, with raw fields still reachable. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]
   - What's unclear: The exact field list and disclosure component shape are left to agent discretion. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]
   - Recommendation: Planner should reserve one task for shared evidence-item schema and one task for HEEx composition so field-volume decisions do not block semantic projection work. [VERIFIED: lib/oban_powertools/web/workflows_live.ex; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile and run phase code plus ExUnit suite | ✓ | 1.19.5 | — [VERIFIED: local shell `elixir --version`] |
| Mix | Test and compile commands | ✓ | 1.19.5 | — [VERIFIED: local shell `mix --version`] |
| PostgreSQL CLI/runtime | Repo test environment and durable-row semantics | ✓ | 14.17 | none for current repo test lane [VERIFIED: local shell `psql --version`; VERIFIED: local shell `postgres --version`] |
| Node.js | Optional asset/tooling support; not required by current workflow proof lane | ✓ | 22.14.0 | not needed for this phase’s core tests [VERIFIED: local shell `node --version`] |
| npm | Optional documentation/tooling support; not required by current workflow proof lane | ✓ | 11.1.0 | not needed for this phase’s core tests [VERIFIED: local shell `npm --version`] |
| Docker | Optional local environment support | ✓ | 29.4.1 | not needed for current repo tests [VERIFIED: local shell `docker --version`] |

**Missing dependencies with no fallback:** None discovered during the environment audit. [VERIFIED: local shell command audit on 2026-05-24]

**Missing dependencies with fallback:** None discovered during the environment audit. [VERIFIED: local shell command audit on 2026-05-24]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with `Phoenix.LiveViewTest` and repo-backed `DataCase` / `LiveCase`. [VERIFIED: test/test_helper.exs; test/support/data_case.ex; test/oban_powertools/web/live/workflows_live_test.exs] |
| Config file | `test/test_helper.exs`; no separate `config/test.exs`-style repo-local test framework config file in the root library. [VERIFIED: test/test_helper.exs; rg --files test] |
| Quick run command | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/workflows_live_test.exs` [VERIFIED: local repo test structure] |
| Full suite command | `mix test` [VERIFIED: local Elixir project conventions; test tree present in repo] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| P21-01 | Workflow-level projector renders diagnosis, headline, evidence, and raw-fact bundles from durable rows. [VERIFIED: .planning/ROADMAP.md; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md] | unit + integration | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/workflow_runtime_test.exs` | ❌ Wave 0 |
| P21-02 | Primary-step default selection follows locked durable evidence priority instead of first blocked step order. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/web/workflows_live.ex] | unit + LiveView | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ❌ Wave 0 |
| P21-03 | Workflow UI renders diagnosis-first summary plus evidence and guidance, with raw internals one level lower. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md] | LiveView | `mix test test/oban_powertools/web/live/workflows_live_test.exs` | PARTIAL |
| P21-04 | Unsupported or unknown states render explicitly instead of guessed copy. [VERIFIED: .planning/ROADMAP.md; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md] | unit + LiveView | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ❌ Wave 0 |
| P21-05 | Lifeline and workflow surfaces keep the same diagnosis vocabulary and evidence posture. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md] | integration + LiveView | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | PARTIAL |
| P21-06 | Final truth outranks lingering request evidence in workflow explanation. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex] | runtime + projector + LiveView | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/workflows_live_test.exs`
- **Per wave merge:** `mix test test/oban_powertools/explain_test.exs test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs`
- **Phase gate:** `mix test`

### Wave 0 Gaps

- [ ] Add projector-focused tests in `test/oban_powertools/explain_test.exs` for workflow headline, evidence items, raw facts, and allowed-next-action guidance. [VERIFIED: test/oban_powertools/explain_test.exs]
- [ ] Add deterministic primary-step priority tests covering terminal truth, expired wait, waiting on signal, retryable dependency, missing dependency result, and cancel-request fallback. [VERIFIED: .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md; test/oban_powertools/explain_test.exs]
- [ ] Add runtime/projector tests proving terminal truth outranks `cancel_requested` once terminal cause is present. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- [ ] Add LiveView tests for diagnosis-first layout, evidence visibility, explicit unknown/unsupported copy, and “guidance only” wording for allowed next action. [VERIFIED: test/oban_powertools/web/live/workflows_live_test.exs; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]
- [ ] Add cross-surface parity assertions so Lifeline incident evidence and workflow page diagnosis strings stay aligned for the same durable step states. [VERIFIED: test/oban_powertools/lifeline_test.exs; test/oban_powertools/web/live/workflows_live_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | This phase consumes existing session/actor state rather than introducing new authentication mechanisms. [VERIFIED: lib/oban_powertools/web/workflows_live.ex] |
| V3 Session Management | no | No new session lifecycle rules are introduced here. [VERIFIED: lib/oban_powertools/web/workflows_live.ex] |
| V4 Access Control | yes | Reuse `LiveAuth.authorize_page/3` and existing read-only page posture. [VERIFIED: lib/oban_powertools/web/workflows_live.ex] |
| V5 Input Validation | yes | Keep `workflow_id` and `step` param handling server-side and explicit; do not trust client-provided diagnosis state. [VERIFIED: lib/oban_powertools/web/workflows_live.ex] |
| V6 Cryptography | no | Phase 21 does not introduce cryptographic behavior. [VERIFIED: phase scope in .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized workflow inspection | Information Disclosure | Keep `LiveAuth.authorize_page/3` gate and existing unauthorized redirect behavior covered by LiveView tests. [VERIFIED: lib/oban_powertools/web/workflows_live.ex; test/oban_powertools/web/live/workflows_live_test.exs] |
| Misleading operator guidance | Tampering | Source diagnosis and legal-next-action guidance from durable rows and runtime-owned helpers, not client-side state or optimistic UI copy. [VERIFIED: lib/oban_powertools/explain.ex; lib/oban_powertools/workflow/runtime.ex; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md] |
| Sensitive result leakage in raw evidence sections | Information Disclosure | Reuse existing `DisplayPolicy.workflow_result/2` seam when rendering result payloads and keep exact facts one layer down, not dumped unredacted by default. [VERIFIED: lib/oban_powertools/web/workflows_live.ex; test/oban_powertools/web/live/workflows_live_test.exs] |
| UI-only semantics drift | Repudiation / Integrity | Keep one projector path so the same durable facts can be defended across support, Lifeline, and workflow UI. [VERIFIED: lib/oban_powertools/explain.ex; lib/oban_powertools/lifeline.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md` - locked scope, UX posture, projector requirements, primary-step priority, and Phase 21/22 split.
- `.planning/ROADMAP.md` - Phase 21 goal and dependency on Phase 20.
- `.planning/milestones/v1.2-ROADMAP.md` - milestone sequence and Phase 21 versus Phase 22 framing.
- `.planning/PROJECT.md` - v1.2 milestone posture and already-landed workflow semantics status.
- `.planning/REQUIREMENTS.md` - `DIA-01`, `DIA-02`, and operator-surface proof expectations.
- `lib/oban_powertools/explain.ex` - current workflow and step explanation seam.
- `lib/oban_powertools/workflow/runtime.ex` - diagnosis vocabulary, transition semantics, and rejection evidence source.
- `lib/oban_powertools/web/workflows_live.ex` - current native workflow page behavior and selected-step heuristic.
- `lib/oban_powertools/lifeline.ex` - existing shared diagnosis consumer.
- `test/oban_powertools/explain_test.exs` - current projector proof coverage.
- `test/oban_powertools/web/live/workflows_live_test.exs` - current workflow UI proof coverage.
- `test/oban_powertools/lifeline_test.exs` and `test/oban_powertools/web/live/lifeline_live_test.exs` - current shared incident and workflow vocabulary proof coverage.
- `mix.lock` - resolved dependency versions in the repo.
- `mix test ...` run on 2026-05-24 - relevant phase-adjacent suites passed: 50 tests, 0 failures.

### Secondary (MEDIUM confidence)

- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html - official `handle_params/3` and `push_patch/2` semantics.
- https://hexdocs.pm/phoenix_live_view/live-navigation.html - official `patch` versus `navigate` behavior.
- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html - official routable LiveView testing guidance.
- https://hexdocs.pm/oban/changelog.html - current Oban `2.22.1` release date.
- https://hex.pm/packages/phoenix/dependencies - current Phoenix `1.8.7` package metadata and update date.
- https://hex.pm/packages/phoenix_live_view - current Phoenix LiveView `1.1.30` package metadata.
- https://hex.pm/packages/oban - current Oban `2.22.1` package metadata.
- https://hex.pm/packages/oban_web - current Oban Web `2.12.4` package metadata.
- https://hex.pm/packages/postgrex - current Postgrex `0.22.2` package metadata.
- https://hex.pm/packages/ecto_sql - current Ecto SQL package metadata showing `3.14.0` upstream and `3.13.5` in-repo lock.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo lockfile, local environment audit, and official Hex pages all agree on the stack, with the only notable delta being upstream Ecto SQL moving past the repo lock. [VERIFIED: mix.lock; CITED: https://hex.pm/packages/ecto_sql]
- Architecture: HIGH - the relevant seams are explicit in the repo and the phase context is unusually prescriptive about them. [VERIFIED: lib/oban_powertools/explain.ex; lib/oban_powertools/web/workflows_live.ex; .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md]
- Pitfalls: HIGH - the most important risks are directly visible in current code, especially the selected-step heuristic and current `cancel_requested` precedence. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/web/workflows_live.ex]

**Research date:** 2026-05-24  
**Valid until:** 2026-06-23 for repo-local architecture; 2026-05-31 for external package-version checks
