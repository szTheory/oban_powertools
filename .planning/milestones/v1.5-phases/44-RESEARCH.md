# Phase 44: Single-Job Actions - Research

**Researched:** 2026-05-28
**Domain:** Elixir/Phoenix LiveView UI and Backend Data Integrity
**Confidence:** HIGH

## Summary

This phase introduces mutation controls (Retry, Cancel, Discard) to the single-job detail view (`JobsLive`). To ensure safety, auditing, and conflict resolution, these mutations are executed via the `Lifeline` subsystem rather than direct Oban calls. We implement a non-CoreComponents inline modal for previews, enforced reasoning, and display of concurrent state drifts. `Lifeline` itself must be augmented to natively support `"job_discard"` alongside its existing job repair actions.

**Primary recommendation:** Integrate `"job_discard"` into `Lifeline`, and drive the `JobsLive` modal state directly from `Lifeline.preview_repair/4` and `Lifeline.execute_repair/4` returns, using the existing `current_actor` for authorization.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** The action preview modal must be implemented using inline HTML and Tailwind classes directly in `jobs_live.ex` (or a local private UI module) rather than relying on Phoenix `CoreComponents`. `oban_powertools` is a library and cannot assume the host application's `CoreComponents` will be unmodified or present.
- **D-02:** The reason string must be enforced via client-side UI validation (e.g. disabling the submit button when the reason input is blank) in addition to the strict backend validation in `Lifeline`.
- **D-03:** Explicit backend support for the `"job_discard"` action must be added to `Lifeline.ex`. This includes adding it to `@supported_actions`, supporting it in `build_job_preview/5`, determining the `next_job_state`, handling the mutation in `mutate_target/5`, and adding a `repair_summary`.
- **D-04:** Both `"job_cancel"` and `"job_discard"` are destructive actions that transition jobs to a terminal state (`"cancelled"` and `"discarded"` respectively).
- **D-05:** Rely entirely on the native concurrent modification guard built into `Lifeline.execute_repair/4` via the `plan_hash` drift check. Do not implement a redundant optimistic locking or `updated_at` check in the LiveView layer. If the job state changes between preview and execution, `Lifeline` will return a natural error.

### the agent's Discretion
*(None explicitly listed, strictly following decisions.)*

### Deferred Ideas (OUT OF SCOPE)
*(None listed.)*
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Job Action Preview | API / Backend | Browser / Client | `Lifeline.preview_repair/4` securely determines if the action is valid for the job's current state and calculates the plan drift hash. |
| Reason Enforcement | Browser / Client | API / Backend | Disabled submit button until reason is provided, minimizing roundtrips; backend validates via `Lifeline`. |
| Job Mutation | API / Backend | — | `Lifeline.execute_repair/4` modifies the target and ensures proper audit trails and drift detection. |
| State Guard | API / Backend | Browser / Client | Handled by `Lifeline` via `plan_hash` check (`{:error, :preview_drifted}`). Client displays error message. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | current | UI Layer | The existing interactive stack for `oban_powertools`. |
| Tailwind CSS | current | Styling | Driven entirely by class attributes without external dependencies. |

## Architecture Patterns

### Pattern 1: Inline Modal State Management
**What:** Creating a custom modal without relying on `Phoenix.Component.modal/1` (D-01).
**When to use:** In a standalone library context where host application dependencies (`CoreComponents`) cannot be trusted to be present or un-modified.
**Example:**
```elixir
# jobs_live.ex state:
# socket |> assign(action_preview: nil, action_reason: "", action_error: nil)

# jobs_live.ex render:
<div :if={@action_preview} class="fixed inset-0 z-50 flex items-center justify-center bg-zinc-900/50 backdrop-blur-sm">
  <div class="relative w-full max-w-lg rounded-lg bg-white p-6 shadow-xl">
    <h2 class="text-base font-semibold"><%= String.capitalize(String.replace(@action_preview.action, "job_", "")) %> Job #<%= @job.id %></h2>
    <!-- Modal body -->
    <form phx-submit="execute_action" phx-change="validate_action">
       <!-- input & buttons -->
    </form>
  </div>
</div>
```

### Pattern 2: Integrating Lifeline job mutations safely
**What:** Calling `Lifeline` without an explicitly detected `incident`.
**When to use:** When human operators manually interact with a specific job via the detail UI, they effectively become the incident discoverer. `Lifeline.build_job_preview/5` naturally handles `nil` incidents by using `incident_fingerprint_for_job/2`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UI Modal logic | `CoreComponents` (`<.modal>`) | Raw HTML + Tailwind classes | Library isolation requirements (D-01) restrict relying on host assets. |
| State drift checking | LiveView optimistic lock (`@job.updated_at`) | `Lifeline.execute_repair/4` drift guard | Keeps drift prevention logic at the mutation layer. |

## Common Pitfalls

### Pitfall 1: Failing to clear preview state on refresh
**What goes wrong:** User successfully executes an action, but the modal stays open with stale data.
**Why it happens:** Missing reset of modal assignments after `Lifeline.execute_repair/4` returns `{:ok, _}`.
**How to avoid:** Explicitly clear `@action_preview`, `@action_reason`, and `@action_error` when mutation is successful, right before reloading the job details.

### Pitfall 2: Overlooking nil incidents in Lifeline
**What goes wrong:** Calling `Lifeline.preview_repair/4` throws because it expects an active incident ID.
**Why it happens:** Manual actions don't have tracked incidents.
**How to avoid:** Ensure the `attrs` payload only sends `action`, `target_type`, and `target_id`. `Lifeline.resolve_incident/2` gracefully returns `nil` when neither ID nor fingerprint is supplied, which is supported by `build_job_preview/5`.

## Code Examples

### Augmenting Lifeline for "job_discard"
```elixir
# lib/oban_powertools/lifeline.ex

# 1. Update supported_actions
@supported_actions ~w(job_rescue job_retry job_cancel job_discard workflow_step_retry workflow_step_cancel workflow_request_cancel)

# 2. Add next_job_state
defp next_job_state("job_discard"), do: "discarded"

# 3. Add mutate_target handler
{"job", "job_discard"} ->
  job = repo.get!(Oban.Job, preview.target_id)
  {:ok, repo.update!(Ecto.Changeset.change(job, state: "discarded", discarded_at: now))}

# 4. Add repair_summary
defp repair_summary("job_discard", "job", target_id),
  do: "Discard job #{target_id} from the native repair flow."
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/oban_powertools/web/jobs_live_test.exs test/oban_powertools/lifeline_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | JobsLive shows action bar for correct states | integration | `mix test test/oban_powertools/web/jobs_live_test.exs` | ✅ Wave 0 |
| REQ-02 | JobsLive previews action, handles reason/submit | integration | `mix test test/oban_powertools/web/jobs_live_test.exs` | ✅ Wave 0 |
| REQ-03 | JobsLive drift check returns visual alert | integration | `mix test test/oban_powertools/web/jobs_live_test.exs` | ✅ Wave 0 |
| REQ-04 | Lifeline correctly processes `job_discard` action | unit | `mix test test/oban_powertools/lifeline_test.exs` | ✅ Wave 0 |

## Sources

### Primary (HIGH confidence)
- `lib/oban_powertools/lifeline.ex` - Checked existing logic for nil incident compatibility.
- `lib/oban_powertools/web/jobs_live.ex` - Checked context/assigns setup and missing `Lifeline` aliases.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows the project constraints.
- Architecture: HIGH - Verified the path for manual job actions seamlessly fits into existing `Lifeline` flows via nil incidents.
- Pitfalls: HIGH - Addressed state-clearing mechanics for the custom modal.

**Research date:** 2026-05-28
**Valid until:** 2026-06-28
