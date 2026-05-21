# Phase 6 Validation

**Phase:** 6
**Name:** Runtime Config & Authorization Hardening
**Prepared:** 2026-05-20

## Test Framework

- ExUnit for source-contract and runtime-helper tests
- Phoenix LiveView test helpers for cron UI authorization behavior

## Phase Requirements -> Test Map

| Requirement | Coverage | Commands |
|-------------|----------|----------|
| FND-01 | Installer writes explicit runtime wiring and runtime helper enforces repo contract | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/auth_test.exs` |
| FND-02 | Auth-module wiring is explicit and web surfaces fail closed before preview exposure | `mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/live/cron_live_test.exs` |
| ENG-03 | Cron UI preserves durable behavior while preventing unauthorized preview entry | `mix test test/oban_powertools/cron_test.exs test/oban_powertools/web/live/cron_live_test.exs` |

## Execution Requirements

- Tests that override application env must restore prior values in `on_exit`.
- LiveView assertions must prove both UI state and side-effect absence for unauthorized preview attempts.
- Verification must include at least one assertion on exact setup-error copy for missing `:repo` or `:auth_module`.

## Gap Coverage

- Closes the milestone-audit integration gaps for installer/runtime wiring (`FND-01`, `FND-02`).
- Closes the cron preview authorization-ordering gap for `ENG-03`.
- Does not cover the Phase 7 incident-retirement defect (`LIF-02`), which remains intentionally out of scope.

