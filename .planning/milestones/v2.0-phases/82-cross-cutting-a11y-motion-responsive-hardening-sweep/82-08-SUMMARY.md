---
phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
plan: "08"
subsystem: testing
tags: [playwright, axe, accessibility, reflow, reduced-motion, copy-policy, aria]

requires:
  - phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
    provides: "Shared system-quality auditor, generated copy contract, repaired page semantics, and reviewed exact ARIA baselines from Plans 03-07 and 12-16"
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    provides: "Schema-8 inventory with 163 targets and 99 page stories"
provides:
  - "Mechanical reflow, motion, target, rendered-copy, contrast, theme-matrix, and strict axe evidence integrated into all 1,956 manifest-derived showcase activations"
  - "Deterministic manifest-first-per-kind host runtime slice without a handwritten target inventory"
  - "Generated copy-policy and confirmation-order evidence across all 99 page stories while preserving 297 exact ARIA snapshots"
affects: [82-09, milestone-quality, showcase-a11y, page-acceptance]

tech-stack:
  added: []
  patterns:
    - "Exhaustive quality checks piggyback on an existing manifest-derived activation loop and scope every DOM audit to the active target"
    - "Rendered copy policy selects semantic channels by rule: actions, receipt/status surfaces, or the complete active root"
    - "Runtime slices derive target IDs only after loading the generated manifest"

key-files:
  created: []
  modified:
    - test/browser/specs/showcase.a11y.spec.ts
    - test/browser/specs/page.acceptance.spec.ts
    - test/browser/support/system-quality.ts
    - assets/oban_powertools/tokens.css
    - priv/static/oban_powertools/oban_powertools.css
    - test/oban_powertools/web/theme_tokens_test.exs

key-decisions:
  - "Derive manifest-first-per-kind at runtime and reject empty, unknown, or duplicate selections so representative runtime evidence cannot become a second inventory."
  - "Keep explicit-root reduced motion independent of the OS media query so the documented root override works under every OS preference."
  - "Scope ambiguous-action policy to action controls and host-outcome policy to status, alert, and receipt channels to avoid treating explanatory prose as an action or claimed outcome."

patterns-established:
  - "Active-root auditing: system-quality helpers accept an audit selector and never scan hidden inactive showcase stories."
  - "Generated confirmation anatomy: page acceptance maps every generated confirmation_order key to one DOM marker and verifies document order."

requirements-completed:
  - A11Y-01
  - A11Y-03
  - A11Y-04
  - MOTION-02
  - NAV-02
  - DATA-03
  - COPY-01
  - COPY-02

duration: 40min
completed: 2026-07-29
status: complete
---

# Phase 82 Plan 08: Exhaustive Mechanical and Page Policy Coverage Summary

**All 1,956 generated showcase activations now carry active-root mechanical quality evidence, while all 99 page stories enforce generated copy and confirmation policy against the unchanged 297-file reviewed ARIA set**

## Performance

- **Duration:** 40 min
- **Started:** 2026-07-29T17:29:00-04:00
- **Completed:** 2026-07-29T18:09:03-04:00
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Integrated strict axe, base reflow, OS and explicit-root reduced motion, 200% zoom, target geometry, rendered copy, selected contrast, and finite system-theme equivalence checks into the existing exhaustive manifest loop.
- Added a host-backed `manifest-first-per-kind` runtime slice derived only from the generated manifest; its 28 Chromium-wide cases passed without introducing another inventory or navigation matrix.
- Extended all 99 Chromium-wide page stories with generated copy-policy and confirmation-anatomy/order assertions while retaining existing text, role, structure, and exact ARIA comparisons.
- Preserved the Plan 82-16 snapshot boundary: all 297 exact ARIA paths validate and no snapshot was changed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Piggyback mechanical system quality on exhaustive axe activation** - `9c00abe` (test)
2. **Task 2: Apply generated copy and confirmation policy to page acceptance** - `fb56f27` (test)

## Files Created/Modified

- `test/browser/specs/showcase.a11y.spec.ts` - Runs shared active-root mechanical audits inside the existing 1,956-case axe matrix and exposes the manifest-derived runtime slice.
- `test/browser/specs/page.acceptance.spec.ts` - Enforces generated copy policy and confirmation order across all page stories.
- `test/browser/support/system-quality.ts` - Supports active-root audit scoping and excludes focus sentinels from pointer-target evidence.
- `assets/oban_powertools/tokens.css` - Makes explicit-root reduced-motion duration tokens independent of OS media preference.
- `priv/static/oban_powertools/oban_powertools.css` - Rebuilt package asset matching the repaired source token behavior.
- `test/oban_powertools/web/theme_tokens_test.exs` - Regresses the explicit-root reduced-motion contract in source and packaged CSS.

## Decisions Made

- Representative host runtime coverage is selected only from manifest order, first target per present kind, with invalid runtime selections rejected.
- System-theme checks compare finite computed semantic role/property vectors and always restore media and root state.
- Copy rules inspect the semantic channel they govern: actionable controls for ambiguous actions, status/alert/receipt surfaces for host outcomes, and the full active root for general policy.
- A submitting confirmation may omit safe dismissal only when the confirmation exposes its submitting state and the submit control is disabled.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Explicit-root reduced motion depended accidentally on OS reduced motion**
- **Found during:** Task 1 (Piggyback mechanical system quality on exhaustive axe activation)
- **Issue:** The explicit `.obpt-root[data-obpt-motion="reduce"]` duration overrides were nested inside the OS `prefers-reduced-motion` media query, so explicit root reduction failed under `no-preference`.
- **Fix:** Separated the root override from the media query, rebuilt the packaged CSS, and added an exact source/package regression.
- **Files modified:** `assets/oban_powertools/tokens.css`, `priv/static/oban_powertools/oban_powertools.css`, `test/oban_powertools/web/theme_tokens_test.exs`
- **Verification:** Theme token tests pass 19/19; source/package comparison and the host runtime slice pass.
- **Committed in:** `9c00abe`

**2. [Rule 3 - Blocking] Shared audit traversed inactive showcase DOM**
- **Found during:** Task 1 (Piggyback mechanical system quality on exhaustive axe activation)
- **Issue:** The shared auditor's document-level traversal could include hidden stories and its broad pointer selector included tabindex-only focus sentinels, violating the active-root evidence boundary.
- **Fix:** Added an explicit audit selector, routed mechanical scans through the active target root, and excluded generic tabindex-only sentinels from pointer-target checks.
- **Files modified:** `test/browser/support/system-quality.ts`, `test/browser/specs/showcase.a11y.spec.ts`
- **Verification:** System-quality contracts pass 33/33 and the 28-case host slice passes.
- **Committed in:** `9c00abe`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking integration issue)
**Impact on plan:** Both repairs were required to make the planned evidence truthful and active-root scoped; neither introduced a new inventory or feature surface.

## Issues Encountered

- Submitting confirmations intentionally remove the safe-dismiss button after acceptance. The ordering assertion now permits that state only with an explicit `submitting` marker and disabled submit control.
- The showcase host bootstrap reported pre-existing dependency advisories. No dependency or lockfile was changed by this plan.

## User Setup Required

None - no external service configuration required.

## Verification Evidence

- `npm run showcase:manifest` — pass; schema 8 regenerated without drift.
- Showcase discovery — exactly 1,956 tests in one file across 163 targets, four themes, and three projects.
- Host-backed manifest-first-per-kind Chromium-wide slice — 28/28 passed.
- Page acceptance discovery — exactly 297 tests in one file.
- Complete Chromium-wide page acceptance runtime — 99/99 passed.
- `node test/browser/support/verify-page-aria-snapshots.mjs` — exactly 297 snapshots; compare-only set passed.
- `node test/browser/support/verify-phase82-quality.mjs` — schema 8, 163 targets, 99 pages, nine routes, three roots, 31 files, 18 declarations, zero exceptions.
- System-quality contracts — 33/33 passed.
- Theme token tests — 19/19 passed.
- Prettier and `git diff --check` — pass.
- `git status --short test/browser/__aria_snapshots__` — clean.

## Next Phase Readiness

- Plan 82-09 can consume the same shared auditor for connected production-page evidence.
- The exhaustive showcase and page-policy gates are ready for milestone closure with no ARIA regeneration required.

## Self-Check: PASSED

- Both task commits exist and contain only Plan 82-08 implementation paths.
- All required discovery/runtime gates passed at the exact 163-target/99-story scope.
- The 297-file ARIA baseline remains unchanged.
- No handwritten TypeScript target inventory, retry, ignored failure, or update mode was introduced.

---
*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Completed: 2026-07-29*
