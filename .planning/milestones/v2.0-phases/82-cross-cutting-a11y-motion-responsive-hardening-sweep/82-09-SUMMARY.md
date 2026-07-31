---
phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
plan: "09"
subsystem: testing
tags: [playwright, accessibility, production-routes, keyboard, themes, reflow]

requires:
  - phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
    provides: "Shared strict system-quality auditors, copy policy, connected fixtures, and repaired route semantics from Plans 03-07 and 12-16"
  - phase: 79-page-migration-wave-1-overview-cron-limiters-audit
    provides: "Authenticated Overview, Cron, Limiters, and Audit production journeys"
  - phase: 80-page-migration-wave-2-jobs-forensics
    provides: "Authenticated Jobs and Forensics production journeys"
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    provides: "Authenticated Batches, Workflows, and Lifeline production journeys"
provides:
  - "Exact manifest-checked nine-family connected production route matrix expanding to 27 Playwright cases"
  - "Four-theme whole-AppShell axe, keyboard, geometry, motion, copy, system-theme, and restored 200% zoom evidence"
  - "Wave 1-3 connected regression journeys upgraded from weak local geometry checks to shared strict auditors"
affects: [milestone-quality, connected-production-acceptance, release-proof]

tech-stack:
  added: []
  patterns:
    - "Connected route definitions are a typed manifest-equal record containing fixture setup and safe traversal only"
    - "Production quality audits retain one outer test per route/project while themes and media matrices execute inside each case"
    - "Migration-specific authority journeys delegate mechanical focus, target, reflow, one-tree, and zoom evidence to shared helpers"

key-files:
  created:
    - test/browser/support/connected-pages.ts
    - test/browser/specs/system-quality.spec.ts
  modified:
    - test/browser/specs/page-migration-wave-1.spec.ts
    - test/browser/specs/page-migration-wave-2.spec.ts
    - test/browser/specs/page-migration-wave-3.spec.ts

key-decisions:
  - "Use base Jobs and Batches routes for connected quality so every family starts from stable production composition before safe traversal."
  - "Keep the exact 27-case outer cardinality by running all four themes and the finite system-media equivalence matrix within each route/project case."
  - "Use temporary deterministic selectors for id-less focused controls and remove them in finally blocks so strict focus diagnostics do not weaken existing journeys."

patterns-established:
  - "Manifest-equal route matrix: module initialization rejects missing, extra, or reordered connected page families."
  - "Bounded production evidence: axe violations attach compact route/theme/project diagnostics without oversized raw reports."

requirements-completed:
  - A11Y-01
  - A11Y-02
  - A11Y-03
  - A11Y-04
  - MOTION-02
  - NAV-02
  - DATA-03
  - COPY-01
  - COPY-02

duration: 30min
completed: 2026-07-29
status: complete
---

# Phase 82 Plan 09: Connected Production Quality Summary

**Exactly nine authenticated production routes now expand to 27 manifest-checked acceptance cases, with four-theme whole-shell quality evidence and the existing Wave 1-3 authority journeys using the same strict auditors**

## Performance

- **Duration:** 30 min
- **Started:** 2026-07-29T18:12:00-04:00
- **Completed:** 2026-07-29T18:42:00-04:00
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added a typed, ordered, manifest-equal connected route contract for Overview, Cron, Limiters, Audit, Jobs, Forensics, Batches, Workflows, and Lifeline using the existing Phase 79-81 fixture and authentication clients.
- Added exactly 27 project-expanded production-quality cases covering real connected AppShell composition, four themes, strict whole-root axe, native keyboard traversal, focus/target/reflow/motion/copy policy, finite system-theme equivalence, and restored wide 200% zoom.
- Replaced weak local focus, overflow, one-tree, target-size, and zoom mechanics in the Wave 1-3 connected suites with shared strict helpers while retaining their route-specific mutation, authority, recovery, history, and confidentiality assertions.
- Preserved the reviewed ARIA boundary: no snapshot was regenerated or modified.

## Task Commits

Each task was committed atomically:

1. **Task 1: Define exact connected family routes and safe journeys** - `b29197d` (test)
2. **Task 2: Prove whole-route shell, axe, keyboard, geometry, motion, and copy** - `6ab51e3` (test)
3. **Task 3: Replace weak Wave 1-3 local helpers with shared strict helpers** - `c3ce5fa` (test)

## Files Created/Modified

- `test/browser/support/connected-pages.ts` - Defines the exact family-to-route fixture and safe-traversal matrix and rejects manifest drift.
- `test/browser/specs/system-quality.spec.ts` - Runs the exact connected 27-case quality lane across production AppShell composition.
- `test/browser/specs/page-migration-wave-1.spec.ts` - Delegates connected Wave 1 focus, reflow, one-tree, and zoom evidence to strict shared helpers.
- `test/browser/specs/page-migration-wave-2.spec.ts` - Delegates connected Wave 2 focus, target, reflow, and restored zoom evidence to strict shared helpers.
- `test/browser/specs/page-migration-wave-3.spec.ts` - Delegates connected Wave 3 target, reflow, one-tree, and restored zoom evidence to strict shared helpers.

## Decisions Made

- Route contracts contain fixture/authentication setup and safe keyboard destinations only; browser helpers never gain endpoint, credential, or mutation authority.
- Jobs and Batches begin at their stable base routes, leaving detail and mutation coverage in the existing authority-sensitive migration suites.
- Focus audits use strict active-element, indicator-thickness, contrast, viewport, and occlusion evidence. Id-less controls receive a temporary test selector that is always removed.
- The host-backed migration verification runs with one Playwright worker because the production fixture reset contract has serial ownership.

## Deviations from Plan

None - the route matrix, 27-case outer cardinality, connected quality sweep, and strict Wave 1-3 helper reuse were implemented as specified.

## Issues Encountered

- The three-file migration command intermittently returned `409 Conflict` from the Phase 81 fixture reset when Playwright used three parallel workers. Running the same 33 cases with `CI=1` enforced the fixture contract's intended single-owner execution and passed 33/33 without retries or ignored failures.
- Host bootstrap reported pre-existing dependency advisories. No dependency, lockfile, workflow, or server configuration was changed by this plan.

## User Setup Required

None - no external service configuration required.

## Verification Evidence

- `npm run showcase:manifest && npx playwright test test/browser/specs/system-quality.spec.ts --list` — exactly 27 tests in one file.
- Connected system-quality Chromium-wide host lane — 9/9 passed.
- Wave 1-3 connected Chromium-wide host lane with serial fixture ownership — 33/33 passed.
- `node test/browser/support/verify-phase82-quality.mjs` — schema 8, 163 targets, 99 pages, nine routes, three roots, 31 files, 18 declarations, zero exceptions.
- Prettier and scoped `git diff --check` — pass.
- `git status --short test/browser/__aria_snapshots__` — clean.

## Next Phase Readiness

- The exact connected-production lane is ready for release proof and can detect route-family drift directly from the generated manifest.
- Plans 82-10 and 82-11 can consume the completed mechanical and connected-route evidence without changing the reviewed ARIA snapshot set.

## Self-Check: PASSED

- All three task commits exist and contain only Plan 82-09 implementation paths/hunks.
- Exact discovery, the nine-route wide lane, and all 33 migration regression cases passed.
- Existing authority-sensitive and confidentiality journeys remain present.
- No retry, sleep, ignored failure, extra worker, fixture endpoint, or ARIA update mode was introduced.

---
*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Completed: 2026-07-29*
