# Phase 63: Close gap: runtime callback and chain progression consumers - Research

**Researched:** 2024-05-18
**Domain:** Oban Plugins, Background Process Lifecycle, Job Dispatching
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BAT-04 Gap | Tracker creates outbox rows but end-to-end execution stops because no runtime consumer invokes the dispatcher. | Covered by Plugin architecture. The central `ObanPowertools.Plugin.CallbackDispatcher` will poll and call `ObanPowertools.Batch.CallbackDispatcher.dispatch_callback`. |
| CHN-01/02 Gap | Chain DSL logic exists but no runtime caller for `Chain.Progression.dispatch_callbacks`. | Covered by Plugin architecture. The central plugin will poll and call `ObanPowertools.Chain.Progression.dispatch_callback` to progress chains automatically. |
</phase_requirements>

## Summary

The `oban_powertools` library has existing core modules to handle batch events (`ObanPowertools.Batch.CallbackDispatcher`), chain progressions (`ObanPowertools.Chain.Progression`), and workflow state transitions (`ObanPowertools.Workflow.Runtime`). These modules know how to claim events from `oban_powertools_callbacks` using `FOR UPDATE SKIP LOCKED` and process them. However, they lack a dedicated runtime process that continuously polls the database and delegates to these modules automatically. 

**Primary recommendation:** Implement the missing runtime consumer as an **Oban Plugin** (`ObanPowertools.Plugin.CallbackDispatcher`) using standard OTP GenServer behavior. This plugin will poll the `oban_powertools_callbacks` table and natively integrate with the host's Oban supervision tree for automatic start/stop and testing sandbox support.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Event Polling & Claiming | Backend / Oban Worker | — | Requires direct database transaction logic (`FOR UPDATE SKIP LOCKED`) and should scale horizontally across all nodes running the Oban queue. |
| Callback Delegation | Backend / Oban Worker | — | Needs to map the `event` column to the right internal Powertools domain module, returning successes or failing rows locally. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Oban.Plugin` | >= 2.15 | Process Lifecycle | This is the official behaviour provided by Oban for long-running custom GenServers that need to sit alongside an Oban instance. It securely passes down Oban Configuration (`%Oban.Config{}`) like repo and prefix, handles test sandboxes, and coordinates pause/resume with Oban. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Oban.Plugin` | Standalone `GenServer` | We lose the `conf` scoping (which means multi-tenant Oban instances break), and developers have to manually add it to their application tree instead of just putting it in the `plugins: [...]` list of their Oban config. |
| `Oban.Plugin` | Scheduled Job (`Oban.Plugins.Cron`) | Cron only goes down to a 1-minute granularity. Callbacks drive flow-control logic, so progressions would stall for up to a minute between steps. Unacceptable latency. |
| Database Polling | `LISTEN/NOTIFY` (PubSub) | Oban explicitly shifted away from `LISTEN/NOTIFY` in version 3 for performance/scalability reasons because it exhausted connection pools at scale. `FOR UPDATE SKIP LOCKED` is the proven high-scale alternative. |

## Architecture Patterns

### System Architecture Diagram

```
[Host Elixir Application]
   │
   └── [Oban Supervision Tree]
          │
          └──> ObanPowertools.Plugin.CallbackDispatcher (GenServer)
                      │
                      ├── Timer (1000ms loop via Process.send_after)
                      │
                      ├── Query: SELECT ... FOR UPDATE SKIP LOCKED
                      │
                      └── Event Routing
                             ├── "chain.step_succeeded"
                             │      └──> ObanPowertools.Chain.Progression
                             ├── "batch.completed" / "batch.exhausted"
                             │      └──> ObanPowertools.Batch.CallbackDispatcher
                             └── "workflow.terminal" / "workflow.recovery_completed"
                                    └──> ObanPowertools.Workflow.Runtime
```

### Pattern 1: Oban Plugin GenServer
**What:** Writing a module that `use GenServer` and `@behaviour Oban.Plugin`, overriding `start_link/1`, `validate/1`, and implementing `init/1` and `handle_info(:poll, state)`.
**When to use:** Whenever `oban_powertools` needs an active runtime listener that queries the database constantly, acting exactly like `Oban.Plugins.Stager`.
**Example:**
```elixir
defmodule ObanPowertools.Plugin.CallbackDispatcher do
  @behaviour Oban.Plugin
  use GenServer

  @impl Oban.Plugin
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: opts[:name])

  @impl Oban.Plugin
  def validate(opts), do: Oban.Validation.validate(opts, fn _ -> :ok end)

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)
    state = %{conf: opts[:conf], interval: 1000}
    {:ok, schedule_poll(state)}
  end

  defp schedule_poll(state) do
    timer = Process.send_after(self(), :poll, state.interval)
    %{state | timer: timer}
  end
end
```

### Anti-Patterns to Avoid
- **Crashing the Plugin:** Oban plugins shouldn't crash on logical errors. If `Chain.Progression.dispatch_callback/4` raises an exception due to a malformed payload, the GenServer will crash, restarting via supervisor. This drops poll events. The plugin needs a clean `case` or `try/rescue` to mark the specific callback as `failed` without stopping the `handle_info(:poll, state)` cycle.
- **Looking up Repo via Application Environment:** Using `ObanPowertools.RuntimeConfig.repo!` inside a plugin is an anti-pattern. The plugin starts with `opts[:conf]` (which is `%Oban.Config{}`). It should fetch the repo via `state.conf.repo` directly so that multi-instance setups (which use different Repos) work properly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Process Initialization | Adding directly to Host's `application.ex` | `plugins: [{ObanPowertools.Plugin.CallbackDispatcher, []}]` | Keeps Powertools isolated within Oban's boundary. |
| Time Tracking | `:timer.send_interval/2` | `Process.send_after/3` | `send_interval` fires blindly. If the DB query takes 2 seconds, it sends 2 messages to the mailbox. `send_after` guarantees pacing between operations. |

## Common Pitfalls

### Pitfall 1: Conflicting Poller IDs in Tests
**What goes wrong:** `FOR UPDATE SKIP LOCKED` claims rows, updating `claimed_by`. If tests fail randomly, it's often because the plugin in test mode claimed the rows before the test logic did.
**Why it happens:** In ExUnit, if the Plugin starts natively in the sandbox, it steals the callbacks.
**How to avoid:** Usually plugins are paused in `testing: :disabled` or `testing: :manual` mode unless explicitly enabled. Ensure tests that assert on manual callback progression temporarily pause the `CallbackDispatcher` plugin if it starts by default.

### Pitfall 2: Orphaned `claimed` Rows
**What goes wrong:** A node claims callbacks, sets `status: "claimed"`, sets `lease_expires_at`, but crashes before completing the delegation.
**Why it happens:** The `ObanPowertools.Plugin.CallbackDispatcher` crashes.
**How to avoid:** The polling query must claim rows that are `status == "claimed"` AND `lease_expires_at <= ^now`.

## Code Examples

Verified patterns from Oban ecosystem and existing Powertools prototypes:

### [Safe Polling Loop Routing]
```elixir
def handle_info(:poll, state) do
  repo = state.conf.repo
  now = DateTime.utc_now()
  limit = state.limit

  rows = claim_callbacks(repo, now, state.dispatcher_id, state.lease_seconds, limit)

  Enum.each(rows, fn row ->
    try do
      dispatch_row(repo, row, now, state.conf.name)
    rescue
      error ->
        mark_failed(repo, row, now, error)
    end
  end)

  {:noreply, schedule_poll(state)}
end
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Untracked prototype files in `lib/oban_powertools/plugin/` should be the foundation. | All | If they were intentionally abandoned, we might implement a rejected design. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` | Host | ✓ | System | — |

**Missing dependencies with no fallback:**
- None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | none — see Wave 0 |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BAT-04 | Batch callbacks are polled and delegated | integration | `mix test test/oban_powertools/plugin/callback_dispatcher_test.exs` | ❌ Wave 0 |
| CHN-01 | Chain steps trigger progression automatically | integration | `mix test test/oban_powertools/plugin/callback_dispatcher_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/oban_powertools/plugin/callback_dispatcher_test.exs` — covers both Req IDs by simulating an Oban instance with the plugin attached and inserting mock pending callbacks.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Callback payloads must be strictly validated during delegation to avoid untrusted code execution. |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/OTP

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Poison Pill DoS | Denial of Service | Wrap `dispatch_callback` dynamically loaded functions inside a safe `try/rescue` to prevent the overarching polling `GenServer` from crashing permanently. |
| Remote Code Execution | Tampering | Never execute `String.to_atom/1` on arbitrary callback payload `module` or `function` names; always use `String.to_existing_atom/1` when dynamically calling host logic. |

## Sources

### Primary (HIGH confidence)
- Oban.Plugin source (verified locally) - Evaluated the %Oban.Config{} struct to verify configuration mapping context.
- Local untracked prototype: `lib/oban_powertools/plugin/callback_dispatcher.ex` (perfectly implements the correct architecture pattern but needs minor fixes regarding configuration lookup).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `Oban.Plugin` is practically mandatory for standard background looping within Oban architectures.
- Architecture: HIGH - Pessimistic row locking on a centralized poller maps directly to how the Oban `Stager` works.
- Pitfalls: HIGH - Common multi-tenant repo configuration mistakes verified locally.

**Research date:** 2024-05-18
**Valid until:** 30 days
