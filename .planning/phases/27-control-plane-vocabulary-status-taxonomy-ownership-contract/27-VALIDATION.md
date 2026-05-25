---
phase: 27
slug: control-plane-vocabulary-status-taxonomy-ownership-contract
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 27 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveView tests + docs-contract assertions + targeted `rg` checks |
| **Config file** | existing `mix.exs`, test support repo/migrations, no extra config required |
| **Quick run command** | `mix test test/oban_powertools/control_plane_test.exs test/oban_powertools/audit_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/web/router_test.exs` |
| **Full suite command** | `mix test && rg -n "Powertools-native|Oban Web bridge|needs_review|bridge_only|event_type|command_key|resource_type|resource_id" README.md guides lib test` |
| **Estimated runtime** | ~20-90 seconds depending on DB setup |

---

## Sampling Rate

- **After every task commit:** run the task-level command in the table below.
- **After every plan wave:** rerun the shared LiveView/doc-contract slice for the affected surfaces.
- **Before `$gsd-verify-work`:** the control-plane contract module, audit helpers, native pages, and docs must all agree on the same vocabulary.
- **Max feedback latency:** 90 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Concern | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|---------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-01 | 01 | 1 | shared status/ownership contract | `T-27-01` / `T-27-02` | One pure module exposes the approved operator statuses, ownership labels, and mapping helpers without page-local drift. | unit | `bash -lc 'test -f lib/oban_powertools/control_plane.ex && mix test test/oban_powertools/control_plane_test.exs'` | ✅ | ⬜ pending |
| 27-01-02 | 01 | 1 | additive audit event normalization | `T-27-03` / `T-27-04` | `Audit` and installer/test migrations expose `event_type`, `command_key`, `resource_type`, and `resource_id` additively while preserving native mutation auditing. | unit + source grep | `bash -lc 'mix test test/oban_powertools/audit_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/cron_test.exs && rg -n "event_type|command_key|resource_type|resource_id" lib/oban_powertools/audit.ex lib/mix/tasks/oban_powertools.install.ex test/support/migrations/0_create_tables.exs'` | ✅ | ⬜ pending |
| 27-02-01 | 02 | 2 | shared native presenter seam | `T-27-05` | Overview, limiters, workflows, audit, cron, and Lifeline render shared status/ownership labels from one presenter seam instead of page-local copy. | live-view slice | `bash -lc 'test -f lib/oban_powertools/web/control_plane_presenter.ex && mix test test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/audit_live_test.exs'` | ✅ | ⬜ pending |
| 27-02-02 | 02 | 2 | native mutation and bridge wording coherence | `T-27-05` / `T-27-06` | `LiveAuth`, cron, Lifeline, and the bridge use the same ownership/venue language and keep bridge-only flows explicit. | live-view + router | `bash -lc 'mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/router_test.exs && rg -n "Powertools-native|Oban Web bridge|Inspection only|Audited action" lib/oban_powertools/web'` | ✅ | ⬜ pending |
| 27-03-01 | 03 | 3 | docs/support-truth vocabulary lock | `T-27-07` | README and guides describe the unified native control plane and bounded bridge using the same vocabulary as the pages. | docs-contract | `bash -lc 'mix test test/oban_powertools/docs_contract_test.exs && rg -n "Powertools-native|Oban Web bridge|bridge-only|native `/ops/jobs` shell|supported mutation surface" README.md guides/optional-oban-web-bridge.md guides/support-truth-and-ownership-boundaries.md'` | ✅ | ⬜ pending |
| 27-03-02 | 03 | 3 | end-to-end proof of Phase 27 contract | `T-27-08` | LiveView, router, and docs proof agree on control-plane vocabulary and do not imply a native generic queue dashboard. | mixed verification | `bash -lc 'mix test test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/web/router_test.exs && ! rg -n "shadow dashboard|native generic queue dashboard" README.md guides lib test'` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/27-control-plane-vocabulary-status-taxonomy-ownership-contract/27-CONTEXT.md` exists.
- [x] `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md` define the v1.3 control-plane scope.
- [x] Native surface modules exist for overview, limiters, cron, workflows, Lifeline, audit, bridge, and LiveAuth.
- [x] LiveView proof files already exist under `test/oban_powertools/web/live/`.
- [x] Installer migration source and test-support migrations both still show the pre-Phase-27 audit schema shape.
- [x] Docs-contract and router tests already enforce support-truth and bridge boundaries.

---

## Manual-Only Verifications

- Read the overview, limiter, workflow, Lifeline, and audit pages after execution and confirm the top-level labels now use one status/ownership vocabulary instead of page-local drift.
- Read the updated audit table and confirm operator-facing labels are presenter-derived while raw durable fields remain queryable underneath.
- Read README plus the bridge/support-truth guides and confirm they explain one native control plane with a bounded Oban Web bridge, not a native generic queue dashboard.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification lanes.
- [x] Sampling continuity: no 3 consecutive tasks rely on manual checks only.
- [x] Wave 0 names the exact code/test seams Phase 27 must converge.
- [x] No watch-mode flags.
- [x] Task-level feedback latency < 90s.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending

