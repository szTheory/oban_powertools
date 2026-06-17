# Phase 66: Optional Live Counts Context

## Goal
Operators have real-time visibility into queue and state counts when supported

## Requirements
- **QRY-06**: Display real-time job counts in the native UI using `oban_met` as an optional read source (never a hard dependency).

## Success Criteria
1. User sees real-time job counts in the UI when `oban_met` is configured.
2. The system functions normally without `oban_met` (no hard dependency is introduced).
3. Counts automatically update without requiring a full page reload.

## Known Context
- `oban_met` is an optional plugin for Oban that provides efficient metrics.
- The powertools project cannot depend on it being installed. We must gracefully fall back to our existing `Jobs.count_by_state/2` when it's absent.
- The UI should leverage Phoenix LiveView's `handle_info` to receive updates if we subscribe to pubsub events, or we could poll. Given `oban_met` usually pushes telemetry or provides an efficient API, we need to investigate the best integration path.