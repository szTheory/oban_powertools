---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 12
subsystem: ui-testing
tags: [css, playwright, visual-regression, accessibility, jobs, forensics]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 09
    provides: Exact 49-story schema-8 manifest and artifact validators
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 10
    provides: Settled isolated showcase launcher and Phase 80 fixture seam
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 11
    provides: Connected Jobs and Forensics production-route acceptance proof
provides:
  - Root-scoped responsive Jobs and Forensics page composition
  - Complete tracked 147-ARIA and 588-PNG page evidence matrix
  - Native mixed-selection and scrollable-confirmation accessibility semantics
  - Fresh compare-only acceptance, axe, ARIA, and VRT closure
affects: [80-13, page-quality, jobs, forensics, operator-patterns]

tech-stack:
  added: []
  patterns:
    - Keep dense Jobs tables conventional and horizontally bounded at intermediate widths
    - Synchronize mixed checkbox state through the native indeterminate DOM property
    - Make every scrollable confirmation surface keyboard focusable with a visible token-owned ring
    - Freeze pre-existing evidence with path-derived SHA-256 inventories before snapshot generation

key-files:
  created:
    - test/browser/__aria_snapshots__/chromium-*/page-{jobs,forensics}-*-aria.yml
    - test/browser/__screenshots__/chromium-*/showcase/page-{jobs,forensics}-*/*.png
  modified:
    - assets/oban_powertools/tokens.css
    - assets/oban_powertools/theme.js
    - priv/static/oban_powertools/oban_powertools.css
    - priv/static/oban_powertools/oban_powertools.js
    - lib/oban_powertools/web/components/operator_patterns.ex

key-decisions:
  - "At tablet widths, preserve the Jobs table's conventional row/column scan model inside one labelled scroll region instead of cardifying rows."
  - "Treat aria-checked as the accessibility contract and the native indeterminate property as the corresponding browser-rendered control state."
  - "Correct production and shared-component semantics at their owning boundaries when locked axe/VRT evidence exposes a defect; never suppress the rule or mask it in a baseline."
  - "Regenerate only page-jobs-explicit-selection after the semantic fix and prove all other 144 ARIA plus 576 PNG artifacts remain byte-identical."

patterns-established:
  - "Evidence bounce-back: stop snapshot adoption when original-resolution review or axe reveals a product defect, fix the owning layer, and restart exact evidence verification."
  - "Artifact isolation: manifest-derived cardinalities plus before/after SHA inventories protect every out-of-scope page artifact."
  - "Locked closure: the final browser aggregate runs compare-only after every accepted evidence update."

requirements-completed: ["PAGE-02", "PAGE-09", "DATA-*", "PAGE-10", "A11Y-*"]

duration: 3h
completed: 2026-07-28
status: complete
---

# Phase 80 Plan 12: Jobs and Forensics Page Evidence Summary

**Jobs and Forensics now have deterministic token-owned composition and a reviewed, tracked 147-ARIA/588-PNG evidence matrix that passes the complete locked page gate**

## Performance

- **Duration:** 3h
- **Started:** 2026-07-28T19:14:53Z
- **Completed:** 2026-07-28T22:12:30Z
- **Tasks:** 3
- **Evidence added:** 90 ARIA YAMLs and 360 PNGs

## Accomplishments

- Added root-scoped Jobs/Forensics page composition with wide master/detail behavior, narrow one-tree reflow, bounded machine regions, minimum action targets, focus scroll margins, high-contrast ownership, and reduced-motion coverage.
- Adopted the existing 57 Wave 1 ARIA snapshots byte-for-byte, then generated exactly 90 Jobs/Forensics ARIA snapshots and 360 Jobs/Forensics screenshots.
- Reviewed every Jobs and Forensics state family at original resolution across 320, tablet, wide, light, dark, and high-contrast representatives, including dense tables, bounded timelines, Unicode/RTL, redaction, progress/results, and review modes.
- Corrected the Jobs results name, tablet table scan density, native mixed checkbox state, and confirmation-dialog scroll focus semantics revealed by the locked evidence run.
- Closed with 147/147 ARIA files, 588/588 PNGs, zero serious/critical page axe findings, 69/69 connected Wave 1+2 cases, and 1,323/1,323 fresh compare-only page tests.

## Task Commits

Plan 80-12 and its evidence-driven owner corrections landed in these atomic commits:

1. **Compose Jobs and Forensics pages** - `7c201d5`
2. **Adopt the 57 Wave 1 ARIA baselines unchanged** - `b4c62fb`
3. **Correct the page acceptance harness** - `62b799c`
4. **Correct page-story contracts** - `c1b19b4`, `0a117b5`
5. **Name the Jobs results region** - `7169c6c`
6. **Preserve Jobs table scan density** - `9fd66c8`
7. **Synchronize native Jobs page tri-state** - `851b04d`
8. **Focus scrollable confirmation dialogs** - `156d8a9`
9. **Add the 90 ARIA and 360 PNG Phase 80 artifacts** - `963808d`

## Files Created/Modified

- `assets/oban_powertools/tokens.css` and packaged CSS - Root-scoped Jobs/Forensics layout, bounded dense-table behavior, and confirmation-dialog focus treatment.
- `assets/oban_powertools/theme.js` and packaged JavaScript - Native mixed-checkbox synchronization on initial apply and LiveView attribute changes.
- `lib/oban_powertools/web/jobs_live.ex` - Labelled Jobs results region.
- `lib/oban_powertools/web/components/operator_patterns.ex` - Keyboard-focusable scrollable confirmation surface.
- `test/support/page_story_catalog.ex` and page story tests - Correct drifted/full-detail evidence contracts.
- `test/browser/specs/page.acceptance.spec.ts` - Accessible Jobs table matching and always-present bounded Forensics timeline contract.
- `test/browser/specs/page-migration-wave-2.spec.ts` - Connected native indeterminate-state regression.
- `test/browser/__aria_snapshots__` - Complete 147-file tracked page ARIA set.
- `test/browser/__screenshots__` - Complete 588-file tracked page PNG set.

## Decisions Made

- Kept tablet Jobs results as one conventional table with a labelled horizontal owner. This retains header-to-cell relationships and row scan density while avoiding page-level overflow.
- Set `HTMLInputElement.indeterminate` from `data-obpt-page-selection="mixed"` because ARIA state alone did not produce the native browser state axe validates or the correct visual affordance.
- Added `tabindex="0"` and a visible focus treatment to the scrollable confirmation container. Accepted/disconnected states can otherwise contain no enabled focusable descendant.
- Refreshed only the three ARIA and twelve PNG `page-jobs-explicit-selection` artifacts after the semantic fix. All other 144 ARIA and 576 PNG files remained byte-identical.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected stale harness and story contracts before generating evidence**

- **Found during:** ARIA missing-only generation and page acceptance.
- **Issue:** The acceptance harness required an exact table name that excluded the accessible caption suffix, treated unavailable Forensics as having no timeline tree, and two story contracts disagreed with rendered drifted/full-detail semantics.
- **Fix:** Matched the Jobs table's accessible-name prefix, required the bounded timeline tree with zero items for history-unavailable, and aligned the drifted/full-detail story copy and activation.
- **Committed in:** `62b799c`, `c1b19b4`, `0a117b5`

**2. [Rule 1/3 - Blocking] Returned visual defects to their owning page layers**

- **Found during:** Original-resolution Jobs evidence review.
- **Issue:** The results table lacked a named region and tablet layouts cardified a dense operational table, while wide no-detail layouts did not use the available results width.
- **Fix:** Labelled the results region and introduced a page-scoped scroll owner/minimum table width while preserving stacked 320px reflow and full-width wide results.
- **Committed in:** `7169c6c`, `9fd66c8`

**3. [Rule 1 - Blocking] Fixed two real axe violations instead of suppressing them**

- **Found during:** First complete locked 1,323-test aggregate.
- **Issue:** Explicit selection exposed `aria-conditional-attr` because `aria-checked="mixed"` was not mirrored to the native property; accepted confirmation states exposed `scrollable-region-focusable`.
- **Fix:** Added deterministic native tri-state synchronization with a connected regression, and made the shared scrollable confirmation surface focusable with a visible ring.
- **Committed in:** `851b04d`, `156d8a9`

**4. [Rule 3 - Blocking] Refreshed the exact evidence changed by the semantic fix**

- **Found during:** Post-fix compare-only aggregate.
- **Issue:** The correct native mixed mark changed exactly three ARIA snapshots and twelve PNGs for `page-jobs-explicit-selection`.
- **Fix:** Updated only that story, reviewed all twelve images at original resolution, and proved every other page artifact byte-identical before the final clean aggregate.
- **Committed in:** `963808d`

---

**Total deviations:** 4 auto-fixed (4 blocking)
**Impact on plan:** The corrections enforce the intended accessibility and dense-table contracts. Scope expanded only to the exact owning page, harness, catalog, JavaScript, and shared confirmation component paths required by locked evidence; no suppression, dependency, schema, migration, or unrelated baseline change was introduced.

## Issues Encountered

- The first complete post-fix compare reported exactly 15 stale `page-jobs-explicit-selection` artifacts and 1,308 passing cases. After the exact refresh, the complete compare-only rerun passed 1,323/1,323.
- Existing locked dependencies reported security advisories during launcher setup. Dependency and lockfile changes remained outside this plan.
- A repository-wide `mix test` diagnostic passed 922/927 tests. The five failures were unrelated dirty/pre-existing contract debt: one CI documentation contract observes the user-edited `page_quality` lane instead of `visual_a11y`, and four example-host contract lanes expose existing generated-host copy/dependency/migration-timeout drift. The Phase 80 focused, connected, and locked browser gates are green.

## User Setup Required

None - the settled launcher creates its isolated databases and browser fixture credentials.

## Verification

- `mix oban_powertools.assets.build` twice - deterministic; source/static CSS and JavaScript are byte-equal after the accessibility correction.
- Focused token/assets/operator tests - 44 passed.
- Jobs Live focused tests - 48 passed.
- CSS/assets/theme ownership tests - 23 passed.
- Corrected axe stories - 36 passed across three projects and four themes.
- `node test/browser/support/verify-page-baselines.mjs --changed-scope` - 360 changed paths, all within 588.
- `node test/browser/support/verify-page-baselines.mjs` - 588 tracked page PNGs.
- `node test/browser/support/verify-page-aria-snapshots.mjs` - 147 tracked page ARIA snapshots.
- Wave 1 integrity - all 57 ARIA and 228 PNG task-entry SHA-256 inventories remained byte-identical.
- Non-explicit integrity after tri-state refresh - all other 144 ARIA and 576 PNG files remained byte-identical.
- Connected Wave 1+2 Docker acceptance - 69 passed.
- Final locked compare-only acceptance/axe/VRT aggregate - 1,323 passed in 14.8 minutes.

## Next Phase Readiness

- Plan 80-13 can execute the complete page aggregate against a clean-clone-visible 147/588 evidence matrix.
- The unrelated CI documentation contract and example-host contract drift remain separate maintenance work; neither blocks the Phase 80 page-quality evidence.
- Existing dependency advisories remain separate dependency-upgrade work.

## Self-Check: PASSED

- All listed product/evidence commits exist and the final evidence commit contains exactly 90 Jobs/Forensics ARIA plus 360 Jobs/Forensics PNG files.
- `git ls-files` exposes exactly 147 page ARIA snapshots and 588 page PNG baselines.
- Wave 1 and all non-explicit-selection post-fix inventories are byte-stable.
- Asset builds, focused ownership suites, connected acceptance, artifact validators, original-resolution review, axe, ARIA, and final compare-only VRT are green.
- The user's unrelated dirty and untracked files remain untouched; `.planning/STATE.md` and `.planning/REQUIREMENTS.md` were not staged.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-28*
