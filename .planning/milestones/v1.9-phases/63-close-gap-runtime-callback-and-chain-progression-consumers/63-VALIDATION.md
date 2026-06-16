# Phase 63 Validation: Runtime Callback and Chain Progression Consumers

This file defines the goal-backward verification steps for ensuring Phase 63 has successfully closed the gaps for `BAT-04` (Batch callbacks), `CHN-01`, and `CHN-02` (Chain progression).

## Phase Goal
The system autonomously processes and delegates batch and chain callback events at runtime without blocking or crashing the application, enabling chains and batches to progress automatically when steps complete.

## Observable Truths

### 1. The Plugin is Configurable
- **Truth:** A developer can configure `ObanPowertools.Plugin.CallbackDispatcher` as an active Oban plugin.
- **Verification:** Confirm the module implements the `Oban.Plugin` behavior and starts successfully when added to the Oban plugins list.

### 2. Autonomous Polling Mechanism Works
- **Truth:** The plugin continuously polls for available `pending` or `claimed` callbacks.
- **Verification:** Insert a `pending` callback manually into the database and verify that within the configured interval, the callback is picked up and attempted by the polling loop.

### 3. Gap Closure: Chain and Batch Delegation
- **Truth:** Chain step and batch completion events are processed and delegated to their appropriate domain handlers.
- **Verification:** 
  - For **BAT-04**: A `batch.completed` callback correctly calls `ObanPowertools.Batch.CallbackDispatcher.dispatch_callback/3`.
  - For **CHN-01 / CHN-02**: A `chain.step_succeeded` callback correctly calls `ObanPowertools.Chain.Progression.dispatch_callback/3`.

### 4. Resilience Against Poison Pills
- **Truth:** Poison pills (crashing callbacks) do not take down the polling loop.
- **Verification:** Insert a malformed callback that causes `dispatch_callback` to raise an exception. The plugin must catch this error, mark the callback as `failed`, record the exception in `last_error`, release the lease, and continue processing other valid callbacks without the GenServer crashing.

## Required Artifacts
- `lib/oban_powertools/plugin/callback_dispatcher.ex` (The Oban plugin for callback polling)
- `test/oban_powertools/plugin/callback_dispatcher_test.exs` (Integration test suite for resilience and proper delegation)

## Key Links to Validate
- The dispatcher plugin successfully delegates to `ObanPowertools.Batch.CallbackDispatcher.dispatch_callback/3`.
- The dispatcher plugin successfully delegates to `ObanPowertools.Chain.Progression.dispatch_callback/3`.
