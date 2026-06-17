# Phase 66 Research

## Overview
Phase 66 focuses on integrating optional live counts into the native UI using `oban_met`.

## Ecosystem Information
- `oban_met` provides efficient, low-overhead counts for jobs in various states.
- It typically relies on telemetry or direct ETS access for fast reads without hitting the database.

## Technical Approach
1.  **Detection**: At startup or runtime, detect if `Oban.Met` (or the equivalent module) is loaded and configured.
2.  **Fallback**: If `oban_met` is not present, use the existing `Jobs.count_by_state/2` logic which hits the database.
3.  **Live Updates**:
    *   If using polling (simplest), we need a `timer:send_interval` in the LiveView mount.
    *   If `oban_met` provides a pubsub broadcast mechanism, we can subscribe to it.
4.  **UI Updates**: Ensure the counts badge next to the state tabs in `JobsLive` update dynamically.