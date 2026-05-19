# Phase 0: Foundation & Bridge - Validation

This document maps the phase success criteria to the automated tests that prove their completion.

## Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test --cover` |

## Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| FND-01 | Installer generates correct files and AST | unit/integration | `mix test test/mix/tasks/oban_powertools.install_test.exs` |
| FND-02 | Telemetry executes without errors | unit | `mix test test/oban_powertools/telemetry_test.exs` |
| FND-03 | Router scope handles dynamic compilation | unit | `mix test test/oban_powertools/web/router_test.exs` |
| N/A    | Auth behaviour contract is strict and correct | unit | `mix test test/oban_powertools/auth_test.exs` |

## Execution Requirements
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test --cover`
- **Phase gate:** Full suite green before `/gsd-verify-work`

## Gap Coverage
The following test files provide complete coverage for the defined must-haves and success criteria in this phase:
- `test/mix/tasks/oban_powertools.install_test.exs`
- `test/oban_powertools/telemetry_test.exs`
- `test/oban_powertools/auth_test.exs`
- `test/oban_powertools/web/router_test.exs`
