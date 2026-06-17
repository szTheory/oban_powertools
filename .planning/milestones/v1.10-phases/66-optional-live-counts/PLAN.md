# Phase 66: Optional Live Counts

## Objective
Provide optional live counts using `oban_met` if it's available, gracefully falling back to database polling if it's not.

## Implementation Steps
1. **Fallback Strategy**: Create a polling mechanism in `jobs_live.ex` that periodically calls `Jobs.count_by_state/2`.
2. **`oban_met` Integration**: If `oban_met` is configured, subscribe to its telemetry or pubsub events instead of polling.
3. **UI Updates**: Ensure the counts badge next to the state tabs update seamlessly via LiveView's `handle_info`.

## Verification
- Test without `oban_met` to ensure polling works.
- Test with `oban_met` mocked/enabled to verify pubsub updates.