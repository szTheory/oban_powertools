---
phase: 28
slug: diagnosis-first-overview-context-preserving-drilldowns
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 28 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveView tests + router proof + targeted `rg` checks |
| **Config file** | existing `mix.exs`, `test/support/live_case.ex`, and repo-local test fixtures |
| **Quick run command** | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/router_test.exs` |
| **Full suite command** | `mix test && rg -n "Needs Review|Blocked|Waiting|Runnable|Resolved Recently|Bridge-only Follow-up|Oban Web bridge|Inspection only|resource=|row-id|workflow_id|event_type" lib test .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns` |
| **Estimated runtime** | ~30-120 seconds depending on DB setup |

---

## Sampling Rate

- **After every task commit:** run the task-level command in the table below.
- **After every plan wave:** rerun the shared LiveView slice for overview plus the affected destinations.
- **Before `$gsd-verify-work`:** overview buckets, native handoffs, bridge labels, and read-only continuity must all agree on the same control-plane story.
- **Max feedback latency:** 120 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Concern | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|---------|------------|-----------------|-----------|-------------------|-------------|--------|
| 28-01-01 | 01 | 1 | bounded overview read model | `T-28-01` / `T-28-02` | One read-model seam emits deterministic bucket counts, diagnosis, venue labels, and exemplars without HEEx-local drift. | source + focused test | `bash -lc 'test -f lib/oban_powertools/web/overview_read_model.ex && rg -n "Needs Review|Blocked|Waiting|Runnable|Resolved Recently|Bridge-only Follow-up|Oban Web bridge|Inspection only" lib/oban_powertools/web/overview_read_model.ex lib/oban_powertools/web/control_plane_presenter.ex'` | ⬜ pending | ⬜ pending |
| 28-01-02 | 01 | 1 | diagnosis-first overview rendering | `T-28-02` / `T-28-03` | `/ops/jobs` renders triage-first cards with diagnosis, exemplars, and venue-aware CTAs instead of a metric wall. | LiveView | `bash -lc 'test -f test/oban_powertools/web/live/engine_overview_live_test.exs && mix test test/oban_powertools/web/live/engine_overview_live_test.exs'` | ⬜ pending | ⬜ pending |
| 28-02-01 | 02 | 2 | native URL-owned selection continuity | `T-28-03` / `T-28-04` | Limiters, Lifeline, and workflows restore the same focused diagnosis context after patch, refresh, and remount without leaking preview state into params. | LiveView | `bash -lc 'mix test test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs && rg -n "handle_params|push_patch|patch=|resource=|row-id|workflow_id|step=" lib/oban_powertools/web/limiters_live.ex lib/oban_powertools/web/lifeline_live.ex lib/oban_powertools/web/workflows_live.ex'` | ✅ | ⬜ pending |
| 28-02-02 | 02 | 2 | honest bridge and scoped destination handoffs | `T-28-04` | Overview and destination links preserve durable context where native surfaces own it and keep bridge-only follow-up explicitly inspection-only. | LiveView + source | `bash -lc 'mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/audit_live_test.exs && rg -n "Oban Web bridge|Inspection only|resource_type|resource_id|event_type" lib/oban_powertools/web/engine_overview_live.ex lib/oban_powertools/web/cron_live.ex lib/oban_powertools/web/audit_live.ex'` | ✅ | ⬜ pending |
| 28-03-01 | 03 | 3 | read-only continuity | `T-28-05` | Read-only sessions preserve selected diagnosis context while action controls remain disabled and support-truthful. | LiveView | `bash -lc 'mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/cron_live_test.exs'` | ⬜ pending | ⬜ pending |
| 28-03-02 | 03 | 3 | bridge-enabled and route ownership proof | `T-28-06` | Native and bridge routes keep their bounded ownership story and the overview does not imply a native generic jobs dashboard. | router + mixed slice | `bash -lc 'mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/audit_live_test.exs && ! rg -n "native generic jobs dashboard|shadow dashboard" lib test README.md guides'` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md` exists.
- [x] `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-RESEARCH.md` exists.
- [x] `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-PATTERNS.md` exists.
- [x] `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-UI-SPEC.md` exists.
- [x] `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md` define the v1.3 overview scope.
- [x] Current native surfaces exist for overview, limiters, cron, workflows, Lifeline, audit, and the bounded bridge.
- [x] Existing LiveView proof files already exist for workflows, Lifeline, limiters, cron, and audit.
- [x] Phase 28 still needs a new `engine_overview_live_test.exs` proof lane.

---

## Manual-Only Verifications

- Read `/ops/jobs` after execution and confirm the first screen answers what needs attention, why, and where to go next without collapsing into a metric wall.
- Click at least one native and one bridge-only handoff from the overview and confirm the destination posture is honest before and after navigation.
- Refresh a selected limiter, workflow, and Lifeline drilldown state and confirm the same diagnosis context remains selected without restoring preview tokens or draft reason text.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification lanes.
- [x] Sampling continuity: no 3 consecutive tasks rely on manual checks only.
- [x] Wave 0 names the exact code/test seams Phase 28 must converge.
- [x] No watch-mode flags.
- [x] Task-level feedback latency < 120s.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
