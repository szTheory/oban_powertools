---
phase: 62
slug: operations-console-lifeline-ui
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 62 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test test/oban_powertools/batches_test.exs test/oban_powertools/lifeline_callback_test.exs test/oban_powertools/web/live/batches_live_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/selectors_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~90 seconds focused, full suite project-dependent |

---

## Sampling Rate

- **After every task commit:** Run the focused test file for the modified surface: `batches_test.exs`, `lifeline_callback_test.exs`, `batches_live_test.exs`, `router_test.exs`, or `selectors_test.exs`.
- **After every plan wave:** Run `mix test test/oban_powertools/batches_test.exs test/oban_powertools/lifeline_callback_test.exs test/oban_powertools/web/live/batches_live_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/selectors_test.exs`.
- **Before `$gsd-verify-work`:** Run `mix test`.
- **Max feedback latency:** 90 seconds for focused feedback.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 62-W0-01 | TBD | 0 | BUI-01/BUI-02 | T-62-01 / T-62-02 | Read model validates server-side filters and exposes copy-ready evidence without trusting LiveView payloads | unit | `mix test test/oban_powertools/batches_test.exs` | missing W0 | pending |
| 62-W0-02 | TBD | 0 | BUI-03/BUI-04 | T-62-03 / T-62-04 | Lifeline preview/execute re-fetches targets, enforces actor authorization, reason gating, and drift checks | unit/service | `mix test test/oban_powertools/lifeline_callback_test.exs` | missing W0 | pending |
| 62-W0-03 | TBD | 0 | BUI-01/BUI-02/BUI-03/BUI-04 | T-62-05 / T-62-06 | LiveView keeps evidence visible in read-only mode and disables unauthorized mutation controls | LiveView | `mix test test/oban_powertools/web/live/batches_live_test.exs` | missing W0 | pending |
| 62-W0-04 | TBD | 0 | BUI-01 | T-62-01 | Router and selector tests prove canonical URL paths and query encoding | unit/router | `mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/selectors_test.exs` | partial existing | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/batches_test.exs` - covers list/detail filters, metrics, blocked-state derivation, retry eligibility, and chain context.
- [ ] `test/oban_powertools/lifeline_callback_test.exs` - covers callback preview, execute, drift, expired/consumed preview handling, unauthorized actors, and reason errors.
- [ ] `test/oban_powertools/web/live/batches_live_test.exs` - covers route rendering, URL filters, read-only state, selection reset, bulk retry modal, callback retry modal, empty state, and load error state.
- [ ] `test/oban_powertools/web/router_test.exs` - add `/ops/jobs/batches` and `/ops/jobs/batches/:id` route assertions.
- [ ] `test/oban_powertools/web/selectors_test.exs` - add `batches_path/1` and `batch_detail_path/1` assertions.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual density and table-first console polish | BUI-01/BUI-02 | Automated LiveView tests can assert copy and state, but not final operator-console visual quality | Inspect `/ops/jobs/batches` and `/ops/jobs/batches/:id` in browser after implementation; verify UI matches `62-UI-SPEC.md` spacing, typography, color, modal, and accessibility contract |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90 seconds for focused tests
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 is implemented and all mapped tests exist

**Approval:** pending
