# Phase 4: Lifeline & Repair Center - Validation

This document maps the Phase 4 lifeline requirements to targeted rerunnable commands so the proof chain does not depend on summary prose alone.

## Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test --cover` |

## Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| LIF-01 | Heartbeats are persisted, classified, and projected into durable incidents. | integration | `mix test test/oban_powertools/lifeline_test.exs` |
| LIF-02 | Repair preview and execute flows are durable, preview-first, and incident-driven. | integration/LiveView | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` |
| LIF-03 | Manual repair actions are written to immutable audit evidence and surfaced in native UI. | integration/LiveView | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/audit_live_test.exs` |
| LIF-04 | Archive/prune retention archives manual repair evidence before deletion. | integration | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` |
| N/A | Lifeline routes remain auth-gated inside the Powertools shell. | LiveView | `mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` |

## Execution Requirements
- Per task verification: run the narrowest command listed above.
- Phase gate: run `mix compile --warnings-as-errors` and the Phase 4 command set before archival.

## Deferred Gap
- `LIF-02` remains an open implementation gap because successful repairs do not yet retire the acted-on incident from active projection state; that closure is tracked in Phase 7.
