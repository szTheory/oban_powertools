# Phase 5: Milestone Evidence & Traceability Closure - Validation

This document maps the Phase 5 closure requirements to the plan slices and repo-local verification commands that must be rerun before the milestone audit is regenerated.

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
| FND-03 | Hybrid shell/router evidence is restored and traceable without closing deferred installer gaps | `5-01` | `mix test test/oban_powertools/web/router_test.exs` |
| WRK-01 | Compile-time worker args validation has fresh verification evidence | `5-02` | `mix test test/oban_powertools/worker_test.exs` |
| WRK-02 | Synchronous enqueue validation has fresh verification evidence | `5-02` | `mix test test/oban_powertools/worker_test.exs` |
| WRK-03 | Durable idempotency receipts have fresh verification evidence | `5-02` | `mix test test/oban_powertools/idempotency_test.exs` |
| ENG-01 | Limiter behavior is tied to restored summaries and fresh verification results | `5-03` | `mix test test/oban_powertools/limits_test.exs test/oban_powertools/worker_test.exs` |
| ENG-02 | `explain/1` and explanation-first UI behavior are tied to restored summaries and fresh verification results | `5-03` | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/limiters_live_test.exs` |
| WF-01 | Workflow persistence evidence is restored and linked to fresh verification | `5-04` | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/workflow_test.exs` |
| WF-02 | Workflow runtime and coordinator signaling evidence is restored and linked to fresh verification | `5-04` | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/telemetry_test.exs` |
| WF-03 | Workflow UI blocked-step evidence is restored and linked to fresh verification | `5-04` | `mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/workflows_live_test.exs` |
| LIF-01 | Heartbeat and incident projection proof is restored without closing the deferred repair-closure defect | `5-05` | `mix test test/oban_powertools/lifeline_test.exs` |
| LIF-03 | Manual repair audit evidence is restored with fresh verification | `5-05` | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` |
| LIF-04 | Archive-before-delete evidence is restored with fresh verification | `5-05` | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` |

## Execution Requirements
- Per plan completion: run the narrowest requirement-specific commands named above before any broader suite.
- Supporting signal: run `mix compile --warnings-as-errors` and `mix test` before regenerating the milestone audit.
- Final phase gate: update `.planning/v1-v1-MILESTONE-AUDIT.md` from the fresh 3-source evidence chain (`REQUIREMENTS.md`, summary frontmatter, per-phase verification docs) and verify that Phase 5-owned requirements no longer appear as `orphaned`.

## Gap Coverage
The following artifacts are expected to exist by the end of Phase 5 execution:
- `.planning/phases/0-VERIFICATION.md`
- `.planning/phases/1-VALIDATION.md`
- `.planning/phases/1-VERIFICATION.md`
- `.planning/phases/2-01-SUMMARY.md`
- `.planning/phases/2-02-SUMMARY.md`
- `.planning/phases/2-03-SUMMARY.md`
- `.planning/phases/2-VERIFICATION.md`
- `.planning/phases/3-VERIFICATION.md`
- `.planning/phases/4-VALIDATION.md`
- `.planning/phases/4-VERIFICATION.md`
- `.planning/v1-v1-MILESTONE-AUDIT.md`
