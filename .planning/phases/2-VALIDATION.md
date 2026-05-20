# Phase 2: Smart Engine Limits & Cron - Validation

This document maps the phase success criteria to the automated tests that prove their completion.

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
| ENG-01 | Durable global and partitioned limiters enforce explicit worker bindings and cooldown semantics | integration | `mix test test/oban_powertools/limits_test.exs test/oban_powertools/worker_test.exs` |
| ENG-02 | `explain/1` returns structured blocker evidence and the native UI renders explanation-first states safely | integration | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/limiters_live_test.exs` |
| ENG-03 | Dynamic cron honors durable slot claims plus overlap/catch-up policies | integration | `mix test test/oban_powertools/cron_test.exs test/oban_powertools/web/live/cron_live_test.exs` |
| N/A | Installer generates the smart-engine tables and test harness mirrors them | unit/integration | `mix test test/mix/tasks/oban_powertools.install_test.exs` |
| N/A | Operator actions remain auth-gated, preview-first, audited, and low-cardinality in telemetry | integration | `mix test test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/telemetry_test.exs` |

## Execution Requirements
- Per task commit: run the narrowest targeted test command named in the plan task.
- Per plan completion: run `mix test`.
- Phase gate: run `mix format --check-formatted`, `mix compile --warnings-as-errors`, and `mix test --cover` before `/gsd-verify-work`.

## Gap Coverage
The following test files are expected to prove the phase must-haves and success criteria:
- `test/mix/tasks/oban_powertools.install_test.exs`
- `test/oban_powertools/limits_test.exs`
- `test/oban_powertools/worker_test.exs`
- `test/oban_powertools/explain_test.exs`
- `test/oban_powertools/cron_test.exs`
- `test/oban_powertools/web/live/limiters_live_test.exs`
- `test/oban_powertools/web/live/cron_live_test.exs`
- `test/oban_powertools/web/live/audit_live_test.exs`
- `test/oban_powertools/telemetry_test.exs`
