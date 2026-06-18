---
phase: 70
slug: brand-book-identity-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 70 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a documentation + dev-route phase: most validation is grep/content assertions
> plus one LiveView render test and a prod-exclusion compile check. No DB required.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + shell/grep assertions |
| **Config file** | `mix.exs` (existing); dev route gated via `config/dev.exs` |
| **Quick run command** | `bash .planning/phases/70-brand-book-identity-foundation/checks.sh` (grep assertions) |
| **Full suite command** | `mix test test/oban_powertools/web/live/brand_book_live_test.exs && MIX_ENV=prod mix compile --force` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run the grep content assertions (§Per-Task map)
- **After every plan wave:** Run `mix test` for the brand-book LiveView test
- **Before `/gsd-verify-work`:** Full suite (render test + prod-exclusion compile) must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 70-01-xx | 01 | 1 | BRAND-01 | — | N/A | grep | `grep -q "explain, then act" guides/brand-book.md` | ❌ W0 | ⬜ pending |
| 70-01-xx | 01 | 1 | BRAND-02 | — | N/A | grep | `grep -q "D-07\|D-12" guides/brand-book.md` | ❌ W0 | ⬜ pending |
| 70-01-xx | 01 | 1 | BRAND-03 | — | N/A | grep | `grep -q "D-13\|D-15" guides/brand-book.md` | ❌ W0 | ⬜ pending |
| 70-01-xx | 01 | 1 | BRAND-04 | — | N/A | grep | `grep -q "D-16\|D-21" guides/brand-book.md` | ❌ W0 | ⬜ pending |
| 70-01-xx | 01 | 1 | BRAND-05 | — | N/A | grep | `grep -qi "Traceability" guides/brand-book.md` | ❌ W0 | ⬜ pending |
| 70-02-xx | 02 | 2 | DOC-03 | — | dev-only route, absent in prod | unit | `mix test ...brand_book_live_test.exs` + `MIX_ENV=prod` compile check | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Exact task IDs assigned by the planner.*

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/web/live/brand_book_live_test.exs` — render test, gated by `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)`
- [ ] `checks.sh` (or inline grep block) — content assertions for D-01..D-22 + traceability table + canonical confirm template
- [ ] `config :oban_powertools, dev_routes: true` in `config/dev.exs`

*Existing ExUnit + LiveView test harness (`test/support/live_case.ex`) covers the render test; no new framework needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Brand book reads coherently and renders legibly at the dev route | BRAND-01..05 | Prose quality / visual legibility is not machine-checkable | Start the dev host, visit `/ops/jobs/_brand_book`, confirm essence line, color story, type/voice exemplars, and traceability table all render |

*All structural/presence behaviors have automated verification; only prose quality is manual.*

---

## Validation Sign-Off

- [ ] All tasks have automated verify (grep/content or ExUnit) or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (render test + grep harness)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter once plans satisfy the above

**Approval:** pending
