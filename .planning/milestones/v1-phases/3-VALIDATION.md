# Phase 3: Workflows (DAGs) & Signaling - Validation

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
| WF-01 | Workflow insertion rejects invalid DAGs and persists normalized workflow, step, edge, and result contracts. | integration | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/workflow_test.exs` |
| WF-02 | Completing a step persists result evidence, applies dependency policy correctly, and uses PubSub only as a DB-safe accelerator. | integration | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/telemetry_test.exs` |
| WF-03 | Native workflow pages highlight blocked steps, preserve stable selection during live updates, and deep-link to Oban Web without mutation controls. | LiveView | `mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/workflows_live_test.exs` |
| N/A | Installer generates workflow tables and the repo test harness mirrors the same contract. | unit/integration | `mix test test/mix/tasks/oban_powertools.install_test.exs` |
| N/A | Workflow blocker explanations remain explicit, operator-readable, and backed by durable snapshots. | integration | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/explain_test.exs` |

## Execution Requirements
- Per task commit: run the narrowest targeted test command named in the plan task.
- Per plan completion: run `mix test`.
- Phase gate: run `mix format --check-formatted`, `mix compile --warnings-as-errors`, and `mix test --cover` before `/gsd-verify-work`.

## Gap Coverage
The following test files are expected to prove the phase must-haves and success criteria:
- `test/mix/tasks/oban_powertools.install_test.exs`
- `test/oban_powertools/workflow_test.exs`
- `test/oban_powertools/workflow_runtime_test.exs`
- `test/oban_powertools/workflow_coordinator_test.exs`
- `test/oban_powertools/explain_test.exs`
- `test/oban_powertools/telemetry_test.exs`
- `test/oban_powertools/web/router_test.exs`
- `test/oban_powertools/web/live/workflows_live_test.exs`
