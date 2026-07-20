---
phase: 79-page-migration-wave-1-overview-cron-limiters-audit
plan: 08
subsystem: testing
tags: [playwright, axe, vrt, phoenix-liveview, accessibility, docker, validation]

requires:
  - phase: 79-07
    provides: Token-owned page composition CSS and deterministic packaged assets
  - phase: 79-10
    provides: Authenticated isolated browser fixture/reset/recovery seam
  - phase: 79-11
    provides: Exact 19-story production-composed page catalog
  - phase: 79-12
    provides: Schema-7 manifest and shared page target pipeline
provides:
  - Connected production-page behavior, authorization, recovery, focus, reflow, motion, and confidentiality proof
  - Exact 228-image page visual matrix with page-only scope and fresh compare-only evidence
  - Reconciled 25-task validation and threat ledger with explicit automated residuals and pending human review
affects: [phase-79-uat, page-vrt, accessibility-review, repository-quality-debt]

tech-stack:
  added: []
  patterns:
    - Test-only connected fixture catalogs remain flag-gated and fail closed
    - Page VRT activation restores the requested true theme after LiveView patches
    - Visual evidence is accepted only after exact-set, changed-scope, and compare-only gates

key-files:
  created:
    - test/browser/__screenshots__/chromium-320/showcase/page-*/*.png
    - test/browser/__screenshots__/chromium-tablet/showcase/page-*/*.png
    - test/browser/__screenshots__/chromium-wide/showcase/page-*/*.png
  modified:
    - test/browser/specs/page-migration-wave-1.spec.ts
    - test/browser/specs/showcase.structure.spec.ts
    - test/browser/specs/showcase.a11y.spec.ts
    - test/browser/specs/showcase.vrt.spec.ts
    - test/browser/support/showcase.ts
    - assets/oban_powertools/tokens.css
    - priv/static/oban_powertools/oban_powertools.css
    - .planning/phases/79-page-migration-wave-1-overview-cron-limiters-audit/79-VALIDATION.md

key-decisions:
  - "Keep Phase 79 validation draft and Nyquist false until the five human review rows have recorded observations."
  - "Record the measured 423 non-page VRT residual instead of repeating the planning-time estimate of 108."
  - "Treat current Credo, Dialyzer, dependency advisories, and non-page baselines as explicit repository debt because Phase 79 changed no dependency, lockfile, packaged JS, or non-page screenshot."

patterns-established:
  - "Page evidence matrix: 19 Elixir-owned stories × 4 themes × 3 viewports = exactly 228 targets and files."
  - "Aggregate reconciliation: classify raw failures, correct stale behavior contracts, and rerun those contracts focused before attributing the residual."

requirements-completed:
  - PAGE-01
  - PAGE-05
  - PAGE-06
  - PAGE-08
  - PAGE-10
  - COPY-01
  - A11Y-*
  - MOTION-*

duration: 2h 57m
completed: 2026-07-20
status: complete
---

# Phase 79 Plan 08: Connected Page Evidence and Validation Summary

**Connected production behavior, zero-serious page axe coverage, and an exact 228-image page matrix now lock Overview, Cron, Limiters, and Audit while preserving authority and package boundaries.**

## Performance

- **Duration:** 2h 57m
- **Started:** 2026-07-20T00:41:20Z
- **Completed:** 2026-07-20T03:38:15Z
- **Tasks:** 3
- **Files modified:** 246

## Accomplishments

- Proved connected URL/history, authorization, read-only behavior, Cron confirmation/recovery/receipt semantics, responsive one-tree behavior, keyboard focus, 200% zoom, reduced motion, and confidentiality on real LiveViews.
- Ran the page structure, axe, and VRT matrix across 19 stories, four true themes, and three viewports; generated exactly 228 page PNGs and finished with a 228/228 compare-only pass.
- Reconciled every task from Plans 79-01 through 79-12, all seven high-severity Phase 79 threats, Docker fixture guarantees, package boundaries, inherited static-analysis debt, aggregate browser debt, and five pending human review rows.
- Corrected stale integrated and aggregate test contracts; the focused reconciliation matrix passed 27/27 and the selected integrated browser gate passed 507/507.

## Task Commits

Each task was committed atomically:

1. **Task 79-08-01: Connected page behavior, structure, axe, reflow, and motion** — `a421462` (test)
2. **Task 79-08-02: Exact page visual evidence** — `dfe78fc` (test)
3. **Task 79-08-03: Integrated gates and validation reconciliation** — `3fd3341`, `045e7a0`, `47a0d2a` (test/docs)

## Files Created/Modified

- `test/browser/specs/page-migration-wave-1.spec.ts` — Connected production routes, fixture reset, history, authorization, recovery, focus, reflow, zoom, motion, and confidentiality.
- `test/browser/support/showcase.ts` — Shared schema-7 page activation, one-overlay bounds, and requested-theme restoration.
- `test/browser/specs/showcase.structure.spec.ts` — Exact page metadata, one-tree, heading, and table structure proof.
- `test/browser/specs/showcase.a11y.spec.ts` — Manifest-driven axe coverage over all page states.
- `test/browser/specs/showcase.vrt.spec.ts` — Deterministic page activation and stabilized compare-only matcher timing.
- `test/browser/specs/operator-patterns.behavior.spec.ts` — Finite blocker presentation contract excludes internal machine codes.
- `test/browser/specs/primitives.behavior.spec.ts` — Keyboard reachability budget scales with the complete focusable catalog.
- `assets/oban_powertools/tokens.css` — Full-width page showcase layout, target-size, status-pill, timestamp, and page composition corrections.
- `priv/static/oban_powertools/oban_powertools.css` — Byte-equal packaged CSS.
- `test/browser/__screenshots__/chromium-{320,tablet,wide}/showcase/page-*/*.png` — Exact 228-image Phase 79 evidence set.
- `.planning/phases/79-page-migration-wave-1-overview-cron-limiters-audit/79-VALIDATION.md` — Concrete 25-task evidence, threat, residual, scope, and pending-human ledger.

## Decisions Made

- Preserved `status: draft`, `nyquist_compliant: false`, and Approval pending in the validation ledger. Automated proof cannot substitute for the required screen-reader, keyboard-observation, responsive/theme/motion, copy, and visual reviews.
- Accepted only true-theme screenshots. Page activation now restores the requested theme after the LiveView patch, preventing a dark/high-contrast filename from silently capturing system theme pixels.
- Kept screenshot scope exact. No scenario, primitive, form, shell, data, or group baseline was updated even though the aggregate runner reported stale non-page comparisons.
- Replaced the planning-time aggregate estimate with measured evidence: the complete stable run had 2,238 tests, 1,779 passes, 431 failures, and 28 skips; after focused correction, the remaining classified debt is 423 non-page VRT comparisons.

## Verification

- Targeted Phase 79 ExUnit: 151 tests, 0 failures.
- Full ExUnit excluding `host_contract`: 848 tests, 0 failures, 7 excluded.
- Exact Docker fixture: 6/6, including reset isolation, actor switching, real recovery state, omission fail-closed behavior, and empty 404 parity.
- Page generation: 228/228; exact verifier: 228; generation changed scope: 228 page paths; distinct-theme hash groups: 57/57.
- Fresh page compare-only VRT: 228/228.
- Integrated page browser selection: 507/507 in 6.6 minutes.
- Aggregate non-VRT focused reconciliation: 27/27.
- Source/static CSS parity, repeated manifest SHA-256, protected-path diff, and cumulative whitespace gates: green.
- Repository-wide inherited gates remain red and are not hidden: Credo reports 260 findings, Dialyzer reports 62 errors, and 423 non-page VRT comparisons remain stale.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved true requested themes through page activation**
- **Found during:** Task 79-08-02 visual inspection
- **Issue:** Activating a LiveView page story patched the root theme back to system after deterministic preparation.
- **Fix:** Captured and restored the requested theme through the scoped theme controller before screenshot assertions.
- **Files modified:** `test/browser/support/showcase.ts`
- **Verification:** Page axe 228/228; all 57 story/viewport groups have distinct light, dark, and high-contrast hashes; compare-only 228/228.
- **Committed in:** `dfe78fc`

**2. [Rule 1 - Bug] Removed page-story squeeze and Audit status overlap**
- **Found during:** Task 79-08-02 executor-side image review
- **Issue:** Generic showcase auto-fit columns squeezed wide page trees; Audit missing-field pills could wrap into neighboring content and timestamps competed for the same row.
- **Fix:** Made the Pages showcase section one column, kept status labels atomic, and gave Audit timestamps their own grid row. Also repaired Limiter link target size and Cron control association discovered by axe/reflow checks.
- **Files modified:** `assets/oban_powertools/tokens.css`, `priv/static/oban_powertools/oban_powertools.css`, `lib/oban_powertools/web/cron_live.ex`, `lib/oban_powertools/web/limiters_live.ex`
- **Verification:** Representative originals reviewed across all page families/themes/viewports; page axe and compare-only matrices green; CSS byte-equal.
- **Committed in:** `a421462`, `dfe78fc`

**3. [Rule 3 - Blocking] Forwarded exact Playwright arguments through the npm wrapper**
- **Found during:** Task 79-08-01 targeted browser execution
- **Issue:** `npm run visual:a11y -- ...` did not forward its trailing selection into the nested Docker npm script.
- **Fix:** Added the npm `--` forwarding boundary without changing dependencies.
- **Files modified:** `package.json`
- **Verification:** Exact selected integrated gate ran 507 tests and passed all 507.
- **Committed in:** `a421462`

**4. [Rule 1 - Bug] Aligned stale integrated test contracts with migrated pages**
- **Found during:** Task 79-08-03 full ExUnit run
- **Issue:** Tests assumed eager module loading, the retired Overview heading, raw Cron row actions, and raw Audit event labels.
- **Fix:** Ensured the presenter module is loaded and asserted current Overview, selected-detail confirmation, form submission, and finite Audit labels.
- **Files modified:** `test/oban_powertools/web/operator_pattern_presenter_test.exs`, `test/oban_powertools/web/live/app_shell_layout_test.exs`, `test/oban_powertools/web/live/control_plane_copy_coherence_test.exs`
- **Verification:** Focused 21/21 and full ExUnit 848/848.
- **Committed in:** `3fd3341`

**5. [Rule 1 - Bug] Reconciled expanded-catalog behavior contracts**
- **Found during:** Task 79-08-03 aggregate run
- **Issue:** The blocker test required internal machine codes that finite presentation intentionally omits; wide keyboard focus used a fixed 80-Tab budget that no longer covered the expanded catalog.
- **Fix:** Asserted machine-code absence and derived the Tab budget from the page's focusable elements.
- **Files modified:** `test/browser/specs/operator-patterns.behavior.spec.ts`, `test/browser/specs/primitives.behavior.spec.ts`
- **Verification:** Focused operator-pattern, primitive-focus, and page-axe matrix passed 27/27.
- **Committed in:** `045e7a0`

---

**Total deviations:** 5 auto-fixed (4 correctness bugs, 1 blocking test-runner issue).
**Impact on plan:** Each correction was required to make the intended Phase 79 evidence truthful. No dependency, lockfile, migration/schema, production route, policy/provider, public Cron API, packaged JS, or non-page screenshot scope was added.

## Issues Encountered

- The first aggregate run stopped at test 702 when Docker Desktop exited with `unexpected EOF`. Docker was restarted and the full retry completed; only the complete retry supplies aggregate counts.
- The plan expected 108 scenario-only VRT failures, but the stable repository measurement found 423 non-page comparison failures across scenario, primitive, form, data, and group targets. Phase 79 page comparisons all passed, and no non-page image was changed.
- `mix credo --strict` and `mix dialyzer` expose inherited repository-wide debt. Docker dependency resolution also reported advisories in locked Hex packages. This plan changed no dependency or lockfile, so those items remain explicit follow-up work rather than unreviewed scope expansion.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 79-08 automated implementation and evidence work is complete.
- Phase 79 remains intentionally unapproved until the five manual rows in `79-VALIDATION.md` are performed and recorded.
- Repository follow-up should triage Credo/Dialyzer findings, dependency advisories, and 423 non-page VRT mismatches independently of the page migration.

## Self-Check: PASSED

- All five Plan 79-08 commits exist in order.
- Exactly 228 page PNGs exist and the fresh compare-only page matrix is green.
- All 25 phase tasks and seven high-severity threats have concrete ledger rows.
- Validation remains draft/false/pending because human evidence has not been invented.

---
*Phase: 79-page-migration-wave-1-overview-cron-limiters-audit*
*Completed: 2026-07-20*
