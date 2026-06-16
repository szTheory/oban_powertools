# Phase 63: Close gap: runtime callback and chain progression consumers - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/plugin/callback_dispatcher.ex` | service | event-driven | `lib/oban_powertools/plugin/callback_dispatcher.ex` | exact |
| `test/oban_powertools/plugin/callback_dispatcher_test.exs` | test | event-driven | `test/oban_powertools/chain_progression_test.exs` | role-match |

## Pattern Assignments

### `lib/oban_powertools/plugin/callback_dispatcher.ex` (service, event-driven)

**Analog:** `lib/oban_powertools/plugin/callback_dispatcher.ex` (Current Prototype)

**Imports pattern** (lines 14-24):
```elixir
  import Ecto.Query

  alias ObanPowertools.Callback
  alias ObanPowertools.RuntimeConfig

  @type option ::
          {:interval, pos_integer()}
          | {:limit, pos_integer()}
          | {:lease_seconds, pos_integer()}
          | {:dispatcher_id, String.t()}
```

**Anti-Pattern to Fix (Repo Lookup)** (line 65):
Change:
```elixir
      repo = RuntimeConfig.repo!(state.conf.name) || state.conf.repo
```
To:
```elixir
      repo = state.conf.repo
```

**Anti-Pattern to Fix (Missing Try/Rescue)** (lines 70-76):
Change:
```elixir
      stats =
        Enum.reduce(rows, %{delivered: 0, failed: 0}, fn row, acc ->
          case dispatch_row(repo, row, now, state.conf.name) do
            :ok -> %{acc | delivered: acc.delivered + 1}
            {:error, _reason} -> %{acc | failed: acc.failed + 1}
          end
        end)
```
To include safe exception handling per `RESEARCH.md` Code Example:
```elixir
  Enum.each(rows, fn row ->
    try do
      dispatch_row(repo, row, now, state.conf.name)
    rescue
      error ->
        mark_failed(repo, row, now, error)
    end
  end)
```
*(Note: Ensure the actual return value `stats` is still computed if needed, but errors must be caught so the polling loop does not crash.)*

**Core Polling Pattern** (lines 41-58, 86-89):
```elixir
  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)

    state = %{
      conf: opts[:conf],
      # ... initialization
    }

    {:ok, schedule_poll(state)}
  end

  defp schedule_poll(state) do
    timer = Process.send_after(self(), :poll, state.interval)
    %{state | timer: timer}
  end
```

---

### `test/oban_powertools/plugin/callback_dispatcher_test.exs` (test, event-driven)

**Analog:** `test/oban_powertools/chain_progression_test.exs`

**Imports and Setup pattern** (lines 1-10):
```elixir
defmodule ObanPowertools.Plugin.CallbackDispatcherTest do
  use ObanPowertools.DataCase, async: false

  import Ecto.Query

  alias ObanPowertools.Callback
  alias ObanPowertools.Plugin.CallbackDispatcher
  # Add other aliases as needed
```

**Test Pattern (Simulating Plugin execution)**:
Since the tests use `config :oban, testing: :manual`, the test will need to either start the Plugin directly under supervision using `start_supervised/1` or call its handler directly.
```elixir
  setup do
    # Pause or manually trigger the poller
    # Insert mock pending Callbacks using `TestRepo`
  end
  
  test "polls and delegates chain.step_succeeded" do
    # ...
  end
```

## Shared Patterns

### Configuration Access
**Source:** `lib/oban_powertools/plugin/callback_dispatcher.ex`
**Apply to:** Oban plugins
Plugins must access repo and prefix strictly through `%Oban.Config{}` (e.g., `state.conf.repo`) and NOT via `Application.get_env` or `RuntimeConfig.repo!`.

### Safe Delegation
**Source:** `63-RESEARCH.md`
**Apply to:** Polling loops calling external dispatchers
Always wrap dynamically loaded function calls or domain dispatcher calls inside `try/rescue` to prevent the overarching polling `GenServer` from crashing and dropping poll events.

## Metadata

**Analog search scope:** `lib/**/*.ex`, `test/**/*.exs`
**Files scanned:** ~150
**Pattern extraction date:** 2024-05-18