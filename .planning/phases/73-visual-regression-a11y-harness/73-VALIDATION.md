---
phase: 73
slug: visual-regression-a11y-harness
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-19
---

# Phase 73 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit for Elixir showcase/catalog contracts; Playwright Test 1.61.0 plus axe-core for browser VRT/a11y |
| **Config file** | Existing `mix.exs` / `test/test_helper.exs`; new `playwright.config.ts` created by Plan 73-02 |
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

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Artifact Source | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-----------------|--------|
| 73-01-T1 | 01 | 1 | VRT-01, VRT-03, A11Y-01 | T-73-SC | Exact npm pins and lockfile prevent package drift | Node metadata smoke | `node -e "const fs=require('fs'); const p=JSON.parse(fs.readFileSync('package.json','utf8')); const deps=p.devDependencies||{}; for (const [name, version] of Object.entries({'@playwright/test':'1.61.0','@axe-core/playwright':'4.11.3','axe-core':'4.11.4'})) { if (deps[name] !== version) throw new Error(name + ' must be pinned to ' + version); } for (const script of ['showcase:manifest','visual:a11y','visual:a11y:host','visual:a11y:docker','vrt:update']) { if (!p.scripts || !p.scripts[script]) throw new Error('missing script ' + script); }"` | Created by Plan 73-01 Task 1 | pending |
| 73-01-T2 | 01 | 1 | VRT-01, VRT-03, A11Y-01 | T-73-01 / T-73-02 | Generated manifest rejects drift and avoids hand-copied selectors | Manifest generation smoke | `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` | Created by Plan 73-01 Task 2 | pending |
| 73-02-T1 | 02 | 2 | VRT-01, VRT-03 | T-73-03 / T-73-04 | Playwright config fixes project, media, locale, timezone, and snapshot-path contract | Config smoke | `node -e "const fs=require('fs'); const c=fs.readFileSync('playwright.config.ts','utf8'); for (const token of ['chromium-320','chromium-tablet','chromium-wide','snapshotPathTemplate','timezoneId','UTC','locale','en-US','reducedMotion','reduce']) { if (!c.includes(token)) throw new Error('missing ' + token); }"` | Created by Plan 73-02 Task 1 | pending |
| 73-02-T2 | 02 | 2 | VRT-01, VRT-03 | T-73-03 / T-73-04 | Docker and server wrappers use the real showcase route and preserve caller args | Shell lint | `bash -n scripts/playwright-docker.sh scripts/with-showcase-server.sh && test -x scripts/playwright-docker.sh && test -x scripts/with-showcase-server.sh` | Created by Plan 73-02 Task 2 | pending |
| 73-02-T3 | 02 | 2 | VRT-01, VRT-03 | T-73-03 | Browser smoke proves the real route, shell, assets, controls, anchors, and story targets | Playwright structure | `npm run visual:a11y -- test/browser/specs/showcase.structure.spec.ts` | Created by Plan 73-02 Task 3 | pending |
| 73-03-T1 | 03 | 3 | A11Y-01 | T-73-05 / T-73-06 | Axe threshold helper keeps serious/critical blocking and full results visible | Axe helper smoke | `node -e "const fs=require('fs'); const s=fs.readFileSync('test/browser/support/axe.ts','utf8'); for (const token of ['AxeBuilder','runAxeForTarget','writeAxeResult','assertNoCriticalOrSerious','wcag22aa','target-size','critical','serious','incomplete']) { if (!s.includes(token)) throw new Error('missing ' + token); }"` | Created by Plan 73-03 Task 1 | pending |
| 73-03-T2 | 03 | 3 | A11Y-01 | T-73-05 / T-73-06 | Axe scans publish full findings but block only serious/critical violations | Playwright axe | `npm run visual:a11y -- test/browser/specs/showcase.a11y.spec.ts` | Created by Plan 73-03 Task 2 | pending |
| 73-04-T1 | 04 | 4 | VRT-01, VRT-02, VRT-03 | T-73-07 | VRT matrix enumerates catalog story cells from generated manifest only | Playwright list | `npm run visual:a11y -- test/browser/specs/showcase.vrt.spec.ts --list` | Created by Plan 73-04 Task 1 | pending |
| 73-04-T2 | 04 | 4 | VRT-01, VRT-02, VRT-03 | T-73-07 / T-73-08 | Committed baselines are generated only through explicit Docker update mode | Playwright VRT | `npm run vrt:update && test "$(find test/browser/__screenshots__ -name '*.png' \| wc -l \| tr -d ' ')" = "108" && npm run visual:a11y -- test/browser/specs/showcase.vrt.spec.ts` | Created by Plan 73-04 Task 2 | pending |
| 73-05-T1 | 05 | 5 | VRT-02, VRT-03, A11Y-01 | T-73-09 / T-73-10 | `visual_a11y` cannot be bypassed outside `ci-gate` fan-in | CI workflow lint | `actionlint .github/workflows/ci.yml && ruby -e 's=File.read(".github/workflows/ci.yml"); abort("missing visual_a11y job") unless s.include?("visual_a11y:"); abort("missing ci-gate fan-in") unless s.include?("VISUAL_A11Y") && s.match?(/needs: \\[[^\\]]*visual_a11y[^\\]]*\\]/m); abort("CI must not update snapshots") if s.include?("--update-snapshots")'` | Modified by Plan 73-05 Task 1 | pending |
| 73-05-T2 | 05 | 5 | VRT-02, VRT-03, A11Y-01 | T-73-11 | Docs preserve Docker-only baseline review and narrow axe claims | Docs test | `mix test test/oban_powertools/docs_contract_test.exs && mix docs` | Created/modified by Plan 73-05 Task 2 | pending |

*Status: pending, green, red, flaky*

---

## Planned Artifact Requirements

No separate validation scaffold is required before execution. Each final plan task has an automated verify command, and missing test/support files are created by the task that owns their first verification.

- [ ] `package.json` and `package-lock.json` with exact dev dependencies and scripts, created by Plan 73-01.
- [ ] `scripts/showcase_manifest.exs` and manifest validators deriving JSON from `ObanPowertools.ShowcaseCatalog`, created by Plan 73-01.
- [ ] `playwright.config.ts` with Chromium viewport projects, deterministic settings, and the non-duplicating snapshot path template from Plan 73-02.
- [ ] `scripts/playwright-docker.sh` and `scripts/with-showcase-server.sh` for pinned Docker execution and example-host lifecycle, created by Plan 73-02.
- [ ] `test/browser/specs/showcase.structure.spec.ts`, created by Plan 73-02.
- [ ] `test/browser/specs/showcase.a11y.spec.ts` and `test/browser/support/axe.ts`, created by Plan 73-03.
- [ ] `test/browser/specs/showcase.vrt.spec.ts`, created by Plan 73-04.
- [ ] `test/browser/__screenshots__/` committed baselines for catalog-backed stories, created by Plan 73-04.
- [ ] `.github/workflows/ci.yml` `visual_a11y` lane wired into `ci-gate`, modified by Plan 73-05.
- [ ] `guides/visual-regression-and-a11y.md` and docs contract coverage, created by Plan 73-05.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Baseline change rationale | VRT-02 | CI can detect PNG churn but cannot judge intended design changes | Review PR diff for `test/browser/__screenshots__/**/*.png`; require explicit explanation for baseline updates |
| Docker networking on macOS | VRT-01 | Local Docker Desktop host networking differs from Linux CI | Run `npm run visual:a11y` locally and confirm the wrapper reaches the example host without changing baselines |
| Accessibility claim boundary | A11Y-01 | Axe cannot prove keyboard traversal, screen-reader announcement quality, focus trap/restore, or reflow | Verify docs and plan text state axe is an automated serious/critical gate, with manual a11y deferred to Phase 82 |

---

## Validation Sign-Off

- [x] All 11 final plan tasks have `<automated>` verify commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Missing browser harness files are created by the task that owns their first verification.
- [x] No watch-mode flags.
- [x] Feedback latency < 20 minutes for full phase gate.
- [x] `nyquist_compliant: true` and `wave_0_complete: true` are set in frontmatter for the final plans 73-01 through 73-05.

**Approval:** ready for execution
