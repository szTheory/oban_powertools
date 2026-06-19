---
phase: 73
slug: visual-regression-a11y-harness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-19
---

# Phase 73 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit for Elixir showcase/catalog contracts; Playwright Test 1.61.0 plus axe-core for browser VRT/a11y |
| **Config file** | Existing `mix.exs` / `test/test_helper.exs`; new `playwright.config.ts` created in Wave 0 |
| **Quick run command** | `mix test test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs && npm run visual:a11y -- --grep "overview-operational-empty"` |
| **Full suite command** | `mix test --exclude host_contract && npm run visual:a11y && actionlint .github/workflows/ci.yml` |
| **Estimated runtime** | ~10-20 minutes after browser baselines exist |

---

## Sampling Rate

- **After every task commit:** Run the quick command or the narrowest relevant Playwright spec.
- **After every plan wave:** Run `mix test --exclude host_contract && npm run visual:a11y`.
- **Before `/gsd:verify-work`:** Full suite must be green with committed baselines and no snapshot update mode.
- **Max feedback latency:** 20 minutes for the full visual/a11y lane; under 5 minutes for targeted ExUnit or single-spec browser checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 73-01-01 | 01 | 1 | VRT-01, VRT-03 | T-73-01 / T-73-03 | Generated manifest rejects drift and avoids hand-copied selectors | ExUnit + Node smoke | `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` | No W0 | pending |
| 73-01-02 | 01 | 1 | VRT-01, VRT-03 | T-73-02 | Browser execution uses pinned Docker and deterministic media/viewport/font controls | Playwright structure | `npm run visual:a11y -- test/browser/specs/showcase.structure.spec.ts` | No W0 | pending |
| 73-02-01 | 02 | 2 | VRT-01, VRT-02, VRT-03 | T-73-02 / T-73-04 | Committed baselines are generated only through explicit update mode | Playwright VRT | `npm run visual:a11y -- test/browser/specs/showcase.vrt.spec.ts` | No W0 | pending |
| 73-03-01 | 03 | 2 | A11Y-01 | T-73-05 | Axe scans publish full findings but block only serious/critical violations | Playwright axe | `npm run visual:a11y -- test/browser/specs/showcase.a11y.spec.ts` | No W0 | pending |
| 73-04-01 | 04 | 3 | VRT-02, A11Y-01 | T-73-04 / T-73-06 | `visual_a11y` cannot be bypassed outside `ci-gate` fan-in | CI workflow lint | `actionlint .github/workflows/ci.yml` | Existing workflow yes; lane no W0 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `package.json` and `package-lock.json` with exact dev dependencies and scripts.
- [ ] `playwright.config.ts` with Chromium viewport projects, deterministic settings, and stable snapshot path template.
- [ ] `scripts/showcase_manifest.exs` deriving JSON from `ObanPowertools.ShowcaseCatalog`.
- [ ] `scripts/playwright-docker.sh` and `scripts/with-showcase-server.sh` for pinned Docker execution and example-host lifecycle.
- [ ] `test/browser/specs/showcase.structure.spec.ts`.
- [ ] `test/browser/specs/showcase.vrt.spec.ts`.
- [ ] `test/browser/specs/showcase.a11y.spec.ts`.
- [ ] `test/browser/support/*` helpers and `test/browser/styles/screenshot.css`.
- [ ] `test/browser/__screenshots__/` committed baselines for catalog-backed stories.
- [ ] `.github/workflows/ci.yml` `visual_a11y` lane wired into `ci-gate`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Baseline change rationale | VRT-02 | CI can detect PNG churn but cannot judge intended design changes | Review PR diff for `test/browser/__screenshots__/**/*.png`; require explicit explanation for baseline updates |
| Docker networking on macOS | VRT-01 | Local Docker Desktop host networking differs from Linux CI | Run `npm run visual:a11y` locally and confirm the wrapper reaches the example host without changing baselines |
| Accessibility claim boundary | A11Y-01 | Axe cannot prove keyboard traversal, screen-reader announcement quality, focus trap/restore, or reflow | Verify docs and plan text state axe is an automated serious/critical gate, with manual a11y deferred to Phase 82 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing browser harness references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 20 minutes for full phase gate.
- [ ] `nyquist_compliant: true` set in frontmatter after plans assign concrete task IDs and Wave 0 files exist.

**Approval:** pending
