---
phase: 71
slug: token-layer-isolated-theming-engine
status: complete
nyquist_compliant: true
wave_0_complete: true
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
| 71-01-01 | 01 | 0 | TOKEN-01, TOKEN-02, TOKEN-04, TOKEN-05, MOTION-01, A11Y-03 | T-71-01 / T-71-02 | Static token/theme/contrast/motion/forbidden-scope contract | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs` | ✅ | ✅ green |
| 71-01-02 | 01 | 0 | TOKEN-03, TOKEN-05 | T-71-03 | MD5 asset routing, packaging, and byte-stability contract | unit/static | `mix test test/oban_powertools/web/assets_test.exs` | ✅ | ✅ green |
| 71-01-03 | 01 | 0 | TOKEN-02, TOKEN-04 | T-71-04 | Jobs proof seam and host isolation contract | integration | focused JobsLive suite plus example-host isolation suite | ✅ | ✅ green |
| 71-02-01 | 02 | 1 | TOKEN-01, TOKEN-02, MOTION-01, A11Y-03 | T-71-01 | Scoped two-tier token CSS and contrast-safe roles | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs` | ✅ | ✅ green |
| 71-02-02 | 02 | 1 | TOKEN-04, TOKEN-05 | T-71-02 | Root-scoped controller and bounded persistence | unit/static | `mix test test/oban_powertools/web/theme_tokens_test.exs` | ✅ | ✅ green |
| 71-02-03 | 02 | 1 | TOKEN-03, TOKEN-05 | T-71-03 | Deterministic compiled CSS/JS outputs | build/static | repeated asset builds plus SHA-256 comparison | ✅ | ✅ green |
| 71-03-01 | 03 | 2 | TOKEN-03, TOKEN-05 | T-71-03 | Content-MD5 routes and immutable responses | unit/integration | `mix test test/oban_powertools/web/assets_test.exs` | ✅ | ✅ green |
| 71-03-02 | 03 | 2 | TOKEN-03 | T-71-10 | Hex package includes compiled assets and excludes dev artifacts | package | `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` | ✅ | ✅ green |
| 71-04-01 | 04 | 3 | TOKEN-02, TOKEN-04, TOKEN-05 | T-71-04 | One scoped root owns hashed asset tags | live/integration | focused JobsLive and assets suites | ✅ | ✅ green |
| 71-04-02 | 04 | 3 | TOKEN-02, TOKEN-04, TOKEN-05 | T-71-04 | Native session wiring preserves host layout | live/integration | focused JobsLive plus example-host isolation suites | ✅ | ✅ green |
| 71-05-01 | 05 | 4 | TOKEN-01, TOKEN-02, A11Y-03 | T-71-05 | State badges/tabs use token-backed proof-seam classes | live/static | focused JobsLive and theme-token suites | ✅ | ✅ green |
| 71-05-02 | 05 | 4 | TOKEN-01, TOKEN-02, TOKEN-04 | T-71-05 | Preview modal behavior survives token-class migration | live/integration | `mix test test/oban_powertools/web/live/jobs_live_test.exs` | ✅ | ✅ green |
| 71-05-03 | 05 | 4 | TOKEN-01..05, MOTION-01, A11Y-03 | T-71-03 / T-71-04 | Phase gates close isolation, packaging, and byte stability | integration/build | focused root, package, host, and repeated-build commands | ✅ | ✅ green |

*Status reflects the fresh 2026-07-29 validation audit.*

---

## Wave 0 Requirements

- [x] `test/oban_powertools/web/theme_tokens_test.exs` — token categories, forbidden selectors, raw-value policy, media queries, controller strings, and contrast pairs.
- [x] `test/oban_powertools/web/assets_test.exs` — MD5 routes, immutable headers, content types, invalid hashes, and deterministic outputs.
- [x] `test/oban_powertools/web/live/jobs_live_test.exs` additions — proof-seam classes and behavior regressions.
- [x] `examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` — host-root isolation.
- [x] Asset build byte-stability proof — repeated builds produce identical SHA-256 inventories.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual taste of exact token palette on the proof seam | TOKEN-01, A11Y-03 | Automated contrast checks prove ratios, not brand taste | Open the example host jobs page in light, dark, and high-contrast themes and confirm the seam reads calm, precise, and not decorative. |
| First-paint FOUC perception | TOKEN-04, TOKEN-05 | Browser timing is environment-sensitive and Phase 73 owns the full browser/VRT matrix | Load `/ops/jobs/jobs` with an explicit persisted dark theme and visually confirm there is no obvious light-to-dark flash before LiveView connects. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s for quick checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete — fresh audit evidence recorded 2026-07-29

## Validation Audit 2026-07-29

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Fresh evidence: the combined theme-token, asset, and JobsLive suite passed 75 tests with 0 failures; the Hex package suite passed 38 tests with 0 failures; example-host theme isolation passed 2 tests with 0 failures; two asset builds produced identical SHA-256 inventories. All seven phase requirements are covered by executable static, package, LiveView, or host-integration proof. The two visual-taste/FOUC rows remain explicitly manual polish and do not replace automated requirement coverage.
