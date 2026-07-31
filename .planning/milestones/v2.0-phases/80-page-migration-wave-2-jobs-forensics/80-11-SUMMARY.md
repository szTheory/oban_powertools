---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 11
subsystem: testing
tags: [playwright, phoenix-liveview, jobs, forensics, accessibility, security]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 09
    provides: Schema-8 manifest with 49 ordered page stories
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 10
    provides: Isolated Phase 80 reset, actor, batch, evidence, and disposable-server fixture bridge
  - phase: 79-page-migration-wave-1-overview-cron-limiters-audit
    plan: 10
    provides: Connected Wave 1 acceptance contract
provides:
  - Exact ordered 19-story Wave 1 compatibility contract over the expanded 49-story manifest
  - Connected three-project Jobs and Forensics production-route acceptance proof
  - Host and Docker page gates ordered Wave 1 then Wave 2 before generic axe and VRT
affects: [80-12, 80-13, playwright, jobs, forensics, page-quality]

tech-stack:
  added: []
  patterns:
    - Filter compatibility subsets by typed page family and assert exact ordered IDs
    - Scope broad fixture-backed Jobs queries by public project/run metadata
    - Compare authorization and disconnect effects against measured public evidence baselines
    - Scan browser, DOM, fixture-response, and available server-log channels for sentinels

key-files:
  created:
    - test/browser/specs/page-migration-wave-2.spec.ts
  modified:
    - test/browser/specs/page-migration-wave-1.spec.ts
    - package.json

key-decisions:
  - "Keep Wave 1 compatibility independent of manifest position by filtering the four established families and comparing the exact ordered 19 IDs."
  - "Scope broad Jobs queries with the fixture's public project/run key so concurrent Playwright projects cannot observe one another's rows."
  - "Prove renewed denial adds no audited effect and disconnect adds exactly one effect relative to the measured baseline, rather than assuming a globally empty Audit table."
  - "Filter the existing Wave 1 Audit interaction to its own fixture resource so Wave 1 and Wave 2 remain valid when executed together."

patterns-established:
  - "Connected acceptance isolation: every stateful case resets and authenticates through the test-only seam, then exercises only production routes."
  - "Effect evidence: authorization and socket-lifecycle assertions use public database evidence deltas, never disabled DOM state or sleep-based timing."
  - "Compatibility split: expanded manifests retain prior-wave contracts through typed family filtering and exact ordered identifiers."

requirements-completed: ["PAGE-02", "PAGE-09", "FORM-03", "PAGE-10", "A11Y-*"]

duration: 35m
completed: 2026-07-28
status: complete
---

# Phase 80 Plan 11: Connected Jobs and Forensics Acceptance Summary

**Real Jobs and Forensics routes now have isolated three-viewport acceptance coverage for canonical navigation, bulk effects, typed evidence, authorization, confidentiality, and accessible reflow**

## Performance

- **Duration:** 35m
- **Started:** 2026-07-28T18:26:14Z
- **Completed:** 2026-07-28T19:01:29Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Preserved Phase 79 against the schema-8 49-story manifest by filtering exactly `overview|cron|limiters|audit`, asserting the exact ordered 19 IDs, and retaining counts 3/8/4/4.
- Added eight connected Jobs/Forensics scenarios per project across Chromium 320, tablet, and wide, with real history/filter/selection/bulk/auth/disconnect/evidence behavior and no skips, static-story fallbacks, or sleeps.
- Proved one-tree responsive behavior, 320px and 200% reflow, visible focus, modal/nonmodal behavior, 44px targets, reduced motion, sparse announcements, and cross-channel confidentiality.
- Added Wave 2 after Wave 1 and before generic axe/VRT in both host and Docker page gates.

## Task Commits

Task 80-11-01 used an atomic TDD red-green pair:

1. **RED: Define the expanded Wave 1 compatibility contract** - `94d71a0`
2. **GREEN: Prove connected Jobs and Forensics pages** - `099ff7d`

## Files Created/Modified

- `test/browser/specs/page-migration-wave-1.spec.ts` - Typed four-family compatibility filter, exact ordered Wave 1 IDs, and fixture-scoped Audit filtering for concurrent execution.
- `test/browser/specs/page-migration-wave-2.spec.ts` - Connected production-route Jobs and Forensics behavior, accessibility, authorization, effect, and confidentiality evidence.
- `package.json` - Wave 1 then Wave 2 ordering in `verify:pages:host` and `verify:pages:docker`.

## Decisions Made

- Used a public `phase80_key` metadata filter for broad Jobs searches; exact ID and unique boundary queries remain direct production queries.
- Used evidence deltas for denial and disconnect because the public contract guarantees project/run effect evidence, not a globally empty Audit table.
- Dispatched the second quick-review activation as a DOM click in narrow modal mode because the first modal correctly blocks pointer interaction with its inert background row.
- Kept the connected spec serial within each project while allowing the three isolated projects to run concurrently.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Isolated the existing Wave 1 Audit scenario from concurrent Wave 2 evidence**

- **Found during:** Task 80-11-01 combined Wave 1 and Wave 2 verification.
- **Issue:** Wave 1 submitted empty Audit filters, so newer Wave 2 fixture rows occupied page 1 and hid Wave 1's selected fixture records.
- **Fix:** Filled the existing resource-type and resource-ID fields with the Wave 1 fixture's `cron_entry` identity before applying filters.
- **Files modified:** `test/browser/specs/page-migration-wave-1.spec.ts`
- **Verification:** The exact combined Docker command passed 69/69 across all three projects.
- **Committed in:** `099ff7d`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix makes the stated Wave 1 filter contract deterministic under the required combined execution; no fixture or production behavior changed.

## Issues Encountered

- A full Wave 2 run revealed that reset does not promise a globally empty Audit table. Comparing the renewed-denial and disconnect outcomes to measured public baselines removed that invalid assumption while retaining exact effect proof.
- Narrow quick review correctly made its background inert, so a pointer click could not activate the next row while the modal was open; the scenario uses a DOM click to exercise the server-side stale replacement path.
- `mix deps.get` reported advisories for existing locked dependencies. Dependency and lockfile changes were outside this plan and remained unstaged.

## User Setup Required

None - the settled launcher creates the isolated database and transports both fixture credentials.

## Verification

- TDD RED: Wave 1 module initialization rejected the unfiltered expanded manifest with six-family counts instead of the locked four-family counts.
- `npx playwright test --list test/browser/specs/page-migration-wave-1.spec.ts test/browser/specs/page-migration-wave-2.spec.ts` - 69 tests in two files.
- `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/page-migration-wave-2.spec.ts` - 24 passed.
- `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/page-migration-wave-1.spec.ts test/browser/specs/page-migration-wave-2.spec.ts` - 69 passed.
- Exact Node package-order proof passed for both host and Docker scripts: Wave 1 before Wave 2 before `showcase.a11y.spec.ts`.
- `git diff --cached --check` passed before the source commit.

## Next Phase Readiness

- Plan 80-12 can adopt exact ARIA and VRT evidence now that connected Jobs/Forensics behavior is green.
- Plan 80-13 can run the complete page aggregate after the baseline artifacts land.
- Existing dependency advisories remain a separate maintenance concern and were not altered here.

## Self-Check: PASSED

- The new spec exists and both TDD commits contain only declared task paths.
- Discovery, direct Wave 2, combined Wave 1/Wave 2, package ordering, effect evidence, and confidentiality checks are green.
- No fixture, launcher, manifest generator, production route, dependency, lockfile, schema, migration, PNG, or generated evidence was changed.
- The user's unrelated dirty and untracked files remain untouched; `.planning/STATE.md` and `.planning/REQUIREMENTS.md` were not staged.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-28*
