# Phase 1: Worker Ergonomics & Idempotency - Validation

This document maps the Phase 1 worker requirements to rerunnable commands that prove the behavior without relying on narrative-only summaries.

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
| WRK-01 | Worker `args:` declarations fail fast when malformed and expose a generated validation contract when valid. | unit | `mix test test/oban_powertools/worker_test.exs` |
| WRK-02 | Enqueue operations synchronously validate params and return changesets on invalid input. | unit/integration | `mix test test/oban_powertools/worker_test.exs` |
| WRK-03 | Idempotency receipts use canonicalized payload fingerprints and return conflicts deterministically. | integration | `mix test test/oban_powertools/idempotency_test.exs` |
| N/A | Installer/test harness still provide the Phase 1 persistence contract. | integration | `mix test test/mix/tasks/oban_powertools.install_test.exs` |

## Execution Requirements
- Per task verification: run the narrowest command listed above.
- Phase gate: run `mix compile --warnings-as-errors` plus the Phase 1 command set before archival.

## Gap Coverage
- `test/oban_powertools/worker_test.exs`
- `test/oban_powertools/idempotency_test.exs`
- `test/mix/tasks/oban_powertools.install_test.exs`
