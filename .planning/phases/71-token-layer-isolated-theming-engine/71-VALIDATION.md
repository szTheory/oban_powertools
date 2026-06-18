---
phase: 71
slug: token-layer-isolated-theming-engine
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 71 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest + lazy_html |
| **Config file** | `config/test.exs` |
| **Quick run command** | `mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs` |
| **Full suite command** | `mix test --exclude host_contract` plus `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` and targeted example-host smoke/page tests |
| **Estimated runtime** | ~60-180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs`
- **After every proof-seam commit:** Run `mix test test/oban_powertools/web/live/jobs_live_test.exs`
- **After every plan wave:** Run `mix test --exclude host_contract`
- **Before `/gsd:verify-work`:** Full suite, Hex release package test, example-host isolation tests, byte-stability rerun, and forbidden-selector/storage grep checks must be green
- **Max feedback latency:** 180 seconds for quick checks; full suite at wave boundaries

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 71-W0-01 | TBD | 0 | TOKEN-01, TOKEN-02, TOKEN-04, TOKEN-05, MOTION-01, A11Y-03 | T-71-01 / T-71-02 | Token/static tests exist before token and theme implementation proceeds | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs` | ❌ W0 | ⬜ pending |
| 71-W0-02 | TBD | 0 | TOKEN-03, TOKEN-05 | T-71-03 | Asset route tests prove md5 paths, immutable cache headers, and deterministic outputs | unit/static | `mix test test/oban_powertools/web/assets_test.exs` | ❌ W0 | ⬜ pending |
| 71-W0-03 | TBD | 0 | TOKEN-02, TOKEN-04 | T-71-04 | Example host isolation test proves host root and `<html>` are untouched | integration | `cd examples/phoenix_host && mix test test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` | ❌ W0 | ⬜ pending |
| 71-01-01 | TBD | 1 | TOKEN-01, MOTION-01, A11Y-03 | T-71-01 | `assets/oban_powertools/tokens.css` declares two-tier scoped tokens and contrast-safe semantic roles | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs` | ❌ W0 | ⬜ pending |
| 71-01-02 | TBD | 1 | TOKEN-04, TOKEN-05 | T-71-02 | `assets/oban_powertools/theme.js` uses only `.obpt-root`, `data-obpt-theme`, and `localStorage["oban_powertools:theme"]` | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs` | ❌ W0 | ⬜ pending |
| 71-02-01 | TBD | 1 | TOKEN-03, TOKEN-05 | T-71-03 | Compiled CSS/JS are served by Powertools with content md5 and immutable caching | unit/static | `mix test test/oban_powertools/web/assets_test.exs` | ❌ W0 | ⬜ pending |
| 71-02-02 | TBD | 2 | TOKEN-03 | T-71-10 | Hex release package contract requires Phase 71 `priv/static/oban_powertools` assets while still excluding `test` and `.planning` | package | `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` | ✅ existing | ⬜ pending |
| 71-03-01 | TBD | 2 | TOKEN-02, TOKEN-04 | T-71-04 | LiveView shell renders asset tags and a single `.obpt-root` without mutating host root markup | live/integration | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ✅ partial | ⬜ pending |
| 71-04-01 | TBD | 2 | TOKEN-01, TOKEN-02, A11Y-03 | T-71-05 | `jobs_live.ex` badge/tab/modal proof seam uses `.obpt-*` classes and preserves existing behavior | live/integration | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ✅ partial | ⬜ pending |
| 71-GATE-01 | TBD | 3 | TOKEN-05 | T-71-03 | Re-running the asset build leaves `priv/static/oban_powertools/*` byte-identical | static/build | `mix oban_powertools.assets.build && shasum priv/static/oban_powertools/*` repeated | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/web/theme_tokens_test.exs` — parse `assets/oban_powertools/tokens.css` and check token categories, forbidden selectors, raw values outside token declarations, media queries, theme controller strings, and contrast pairs.
- [ ] `test/oban_powertools/web/assets_test.exs` — assert md5 route paths, immutable cache headers, content types, and invalid/mismatched md5 behavior if implemented.
- [ ] `test/oban_powertools/web/live/jobs_live_test.exs` additions — assert `obpt-badge`, `obpt-tab`, and `obpt-modal` proof-seam classes while preserving existing behavior.
- [ ] `examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` — prove host `/` is unchanged, `/ops/jobs/jobs` includes assets/root, and rendered static HTML has no host-root theme mutation.
- [ ] Asset build byte-stability helper — run the build twice and compare SHA256 for `priv/static/oban_powertools/*`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual taste of exact token palette on the proof seam | TOKEN-01, A11Y-03 | Automated contrast checks prove ratios, not brand taste | Open the example host jobs page in light, dark, and high-contrast themes and confirm the seam reads calm, precise, and not decorative. |
| First-paint FOUC perception | TOKEN-04, TOKEN-05 | Browser timing is environment-sensitive and Phase 73 owns the full browser/VRT matrix | Load `/ops/jobs/jobs` with an explicit persisted dark theme and visually confirm there is no obvious light-to-dark flash before LiveView connects. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s for quick checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
