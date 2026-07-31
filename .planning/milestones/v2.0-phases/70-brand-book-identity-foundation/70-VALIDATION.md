---
phase: 70
slug: brand-book-identity-foundation
status: complete
nyquist_compliant: true
wave_0_complete: true
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
| 70-01-01 | 01 | 1 | BRAND-01..05 | — | Content harness fails closed on missing decisions and canonical copy | shell/static | `bash .planning/phases/70-brand-book-identity-foundation/checks.sh` | ✅ | ✅ green |
| 70-01-02 | 01 | 1 | BRAND-01..05 | — | All D-01..D-22 decisions and traceability categories are present | shell/static | `bash .planning/phases/70-brand-book-identity-foundation/checks.sh` | ✅ | ✅ green |
| 70-01-03 | 01 | 1 | BRAND-01, BRAND-05 | — | Brand guide is registered for grouped HexDocs output | compile/static | `grep -q 'brand-book.md' mix.exs && grep -q 'Design System' mix.exs && mix compile --warnings-as-errors` | ✅ | ✅ green |
| 70-02-01 | 02 | 2 | DOC-03 | — | Dev routes are enabled only in dev/test config | shell/static | `grep -q 'dev_routes: true' config/dev.exs && grep -q 'dev_routes: true' config/test.exs && ! grep -q 'dev_routes' config/prod.exs` | ✅ | ✅ green |
| 70-02-02 | 02 | 2 | BRAND-01, DOC-03 | — | The dev route renders the real brand-book content | ExUnit/LiveView | `mix test test/oban_powertools/web/live/brand_book_live_test.exs` | ✅ | ✅ green |
| 70-02-03 | 02 | 2 | DOC-03 | — | BrandBookLive and its route are absent from production builds | compile/integration | `MIX_ENV=prod mix compile --force --warnings-as-errors` plus `Code.ensure_loaded?/1` exclusion assertion | ✅ | ✅ green |
| 70-02-04 | 02 | 2 | DOC-03 | — | README links both static and dev-route delivery | shell/static | `grep -q 'guides/brand-book.md' README.md && grep -q '_brand_book' README.md` | ✅ | ✅ green |

*Status reflects the fresh 2026-07-29 validation audit.*

---

## Wave 0 Requirements

- [x] `test/oban_powertools/web/live/brand_book_live_test.exs` — render test, gated by `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)`
- [x] `checks.sh` — content assertions for D-01..D-22 + traceability table + canonical confirm template
- [x] `config :oban_powertools, dev_routes: true` in `config/dev.exs`

*Existing ExUnit + LiveView test harness (`test/support/live_case.ex`) covers the render test; no new framework needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Brand book reads coherently and renders legibly at the dev route | BRAND-01..05 | Prose quality / visual legibility is not machine-checkable | Start the dev host, visit `/ops/jobs/_brand_book`, confirm essence line, color story, type/voice exemplars, and traceability table all render |

*All structural/presence behaviors have automated verification; only prose quality is manual.*

---

## Validation Sign-Off

- [x] All tasks have automated verify (grep/content or ExUnit) or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (render test + grep harness)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter once plans satisfy the above

**Approval:** complete — fresh audit evidence recorded 2026-07-29

## Validation Audit 2026-07-29

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Fresh evidence: the content harness passed all D-01..D-22 and canonical-copy assertions; the LiveView render suite passed 1 test with 0 failures; production compilation passed with warnings-as-errors and `BrandBookLive` was confirmed absent. All six phase requirements have automated structural or behavioral coverage. The prose-quality row remains optional subjective review, not a requirement coverage gap.
