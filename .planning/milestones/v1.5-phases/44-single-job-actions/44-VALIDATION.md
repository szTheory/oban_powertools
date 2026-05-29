# Phase 44: Single-Job Actions - Validation

This document maps the Phase 44 closure requirements to the plan slices and repo-local verification commands that must be rerun before the milestone audit is regenerated.

## Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test --cover` |

## Phase Requirements -> Plan / Evidence Map
| Req ID | Closure Behavior | Plan | Automated Command |
|--------|------------------|------|-------------------|
| QRY-03 | Operator can execute retry, cancel, and discard on single jobs | `44-01`, `44-02` | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/jobs_live_test.exs` |

## Execution Requirements
- Per plan completion: run the narrowest requirement-specific commands named above before any broader suite.
- Supporting signal: run `mix compile --warnings-as-errors` and `mix test` before declaring the phase complete.

## Gap Coverage
The following artifacts are expected to exist by the end of Phase 44 execution:
- `.planning/phases/44-single-job-actions/44-01-SUMMARY.md`
- `.planning/phases/44-single-job-actions/44-02-SUMMARY.md`
- `.planning/phases/44-single-job-actions/44-VERIFICATION.md`
