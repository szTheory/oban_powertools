---
phase: 73-visual-regression-a11y-harness
verified: 2026-07-29T06:02:38Z
status: passed
score: "4/4 requirements satisfied"
requirements_total: 4
requirements_satisfied: 4
requirements_partial: 0
requirements_blocked: 0
---

# Phase 73 Verification Report

**Phase Goal:** Establish deterministic visual-regression and automated
accessibility gates before page migrations.

**Result:** Passed. The pinned Playwright harness, committed baselines,
deterministic capture controls, axe threshold, and required CI fan-in are present.
The later page-quality split no longer narrows Phase 73's merge gate: pull requests
must pass both the focused page lane and the unfiltered current-showcase lane.

## Goal Achievement

| Goal | Status | Evidence |
|---|---|---|
| External pinned Playwright harness captures every current target across themes and viewports | VERIFIED | Playwright 1.61.0 Noble wrapper; manifest has 113 targets, 4 themes, and 3 viewports; discovery finds 1,356 VRT cases |
| Committed baselines and compare-only CI block unintended diffs | VERIFIED | 1,356 committed PNGs exactly match the generated matrix; `visual_a11y` runs without snapshot-update flags and is required by `ci-gate` |
| Axe critical/serious findings block merges for every current target | VERIFIED | 1,356 unfiltered axe cases discovered; helper uses WCAG 2.2 AA tags and blocks `critical`/`serious`; `visual_a11y` is required by `ci-gate` |
| Capture is deterministic and fixture-backed | VERIFIED | fixed projects, locale, UTC, reduced motion, disabled animations, hidden caret, ready fonts, generated manifest, pinned Docker image |

## Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|---|---|---|---|
| VRT-01 | 73-01, 73-02, 73-04 | SATISFIED | External Node Playwright harness uses pinned `mcr.microsoft.com/playwright:v1.61.0-noble`; generated manifest and three fixed Chromium projects enumerate all 113 current targets across 4 themes |
| VRT-02 | 73-04, 73-05 | SATISFIED | 1,356 component/group/page-scoped PNGs are committed; required CI runs compare mode; update mode exists only in explicit `vrt:update`; docs require reviewed rationale |
| VRT-03 | 73-01, 73-02, 73-04, 73-05 | SATISFIED | Generated fixture manifest, fixed viewport/locale/timezone/media, disabled animations, hidden caret, screenshot CSS, and `document.fonts.ready` stabilize pixels |
| A11Y-01 | 73-01, 73-03, 73-05 | SATISFIED | Axe targets all generated showcase kinds, includes `wcag22aa`, records full JSON, blocks critical/serious findings, and the unfiltered lane is merge-blocking through `ci-gate` |

All five Phase 73 summaries list these requirements in
`requirements-completed`, independently matching the implementation and this
verification.

## Current Evidence

| Check | Result |
|---|---|
| Exact npm dependency/script smoke | PASS |
| `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` | PASS — 113 targets, 4 themes, 3 viewports |
| Deterministic Playwright-config smoke | PASS |
| Wrapper syntax and executable checks | PASS |
| Axe helper contract smoke | PASS |
| Structure Playwright discovery | PASS — 12 tests |
| Unfiltered axe + VRT Playwright discovery | PASS — 2,712 tests |
| Committed PNG cardinality | PASS — 1,356/1,356 |
| `actionlint .github/workflows/ci.yml .github/workflows/page-quality-nightly.yml` | PASS |
| CI fan-in/static contract | PASS — `page_quality` and unfiltered `visual_a11y` are both required |
| `mix test test/oban_powertools/docs_contract_test.exs` | PASS — 19 tests |
| `git diff --check` on Phase 73 closure files | PASS |

The long 2,712-case browser matrix was discovery-checked rather than rerun during
this narrow CI restoration. Historical Phase 73 evidence covers the original
non-page matrix, later page-phase evidence covers the expanded page matrix, and
the restored required job now executes their unfiltered union on every pull
request.

## Residual Boundary

- Moderate, minor, and incomplete axe findings remain diagnostic artifacts rather
  than merge blockers; A11Y-01 specifically requires zero critical/serious.
- Intentional baseline changes still require human review of the PNG diff and PR
  rationale. CI never updates snapshots.
- The scheduled full-showcase workflow remains useful additional evidence, but
  milestone satisfaction does not depend on a nightly-only gate.

No Phase 73 requirement gap remains.
