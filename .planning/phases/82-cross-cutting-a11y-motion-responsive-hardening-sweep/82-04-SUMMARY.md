---
phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
plan: "04"
subsystem: testing
tags: [playwright, accessibility, wcag, axe, responsive, motion, themes]

requires:
  - phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
    provides: "Plan 01's 33 RED browser contracts for system quality and axe policy"
provides:
  - "Bounded shared browser auditors for contrast, targets, focus, reflow, zoom, motion, and computed system-theme roles"
  - "Fail-closed axe policy with exact expiring exceptions, compensating assertions, and bounded redacted diagnostics"
affects: [82-08, 82-09, 82-10, connected-quality, showcase-a11y]

tech-stack:
  added: []
  patterns:
    - "Pure geometry and color evaluators feed bounded Playwright wrappers"
    - "Browser media, root attributes, focus, and CDP metrics restore in finally blocks"
    - "Axe exceptions are exact, expiring, executable, and accounted as used or unused"

key-files:
  created:
    - test/browser/support/system-quality.ts
  modified:
    - test/browser/support/axe.ts
    - test/browser/specs/system-quality-contract.spec.ts

key-decisions:
  - "Keep normative 24px target geometry separate from the named 44px operator comfort policy."
  - "Treat critical and serious axe findings as unwaivable, and moderate findings as blocking unless every affected selector has one exact valid compensating exception."
  - "Compare system theme computed-role vectors against explicit light, dark, and high-contrast vectors under the full OS scheme/contrast matrix."

patterns-established:
  - "Bounded diagnostics: selectors and measurements are retained without DOM dumps or fixture/browser-channel payloads."
  - "Observational auditor: shared quality checks inspect rendered state without activating arbitrary controls."

requirements-completed:
  - A11Y-01
  - A11Y-02
  - A11Y-03
  - A11Y-04
  - MOTION-02
  - NAV-02
  - DATA-03

duration: 14min
completed: 2026-07-29
status: complete
---

# Phase 82 Plan 04: Shared Browser Auditors and Axe Policy Summary

**Exact bounded system-quality auditors and a closed axe waiver policy now make all 33 Wave 0 browser contracts green**

## Performance

- **Duration:** 14 min
- **Started:** 2026-07-29T20:13:00Z
- **Completed:** 2026-07-29T20:27:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Implemented unrounded sRGB/alpha contrast, 24px spacing geometry, separate 44px comfort checks, focus visibility/occlusion, one-tree reflow, bounded machine scrollers, and restored 200% zoom.
- Implemented independent OS/root reduced-motion checks and a four-case system-theme matrix covering OS light, OS dark, and contrast-more under both schemes.
- Replaced the two-impact axe assertion with a fail-closed policy that blocks moderate findings by default and rejects broad, expired, duplicate, unmatched, failed, and unused exceptions.
- Redacted axe artifacts to selector-level evidence and bounded findings, DOM walks, strings, and artifact size.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement exact geometry, color, reflow, and motion auditors** - `40dced1` (feat)
2. **Task 2: Make axe findings and exceptions fail closed** - `86e59a4` (feat)

## Files Created/Modified

- `test/browser/support/system-quality.ts` - Pure evaluators and reusable Playwright wrappers for every shared mechanical quality check.
- `test/browser/support/axe.ts` - WCAG-tagged runner, redacted artifact writer, strict policy evaluator, and route-capable assertion.
- `test/browser/specs/system-quality-contract.spec.ts` - Static implementation imports that run all 33 algorithm and policy cases through Playwright.

## Decisions Made

- Kept the normative WCAG 2.5.8 result independent from the product's 44px comfort result so neither can weaken the other.
- Required exact selector-level accounting for moderate exceptions; critical, serious, unknown-impact, and selectorless findings always block.
- Snapshotted and restored theme, motion, media, viewport, and CDP state so serial browser runs cannot contaminate later cases.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced dynamic RED seam imports with static Playwright imports**

- **Found during:** Task 1 verification
- **Issue:** Node's CommonJS dynamic import path loaded the new TypeScript modules without Playwright transformation, producing `Unexpected token 'export'` for all 33 cases.
- **Fix:** Preserved the test helpers while resolving their implementations through static imports, allowing Playwright's TypeScript transform to own module loading.
- **Files modified:** `test/browser/specs/system-quality-contract.spec.ts`
- **Verification:** All 33 Chromium-wide cases pass.
- **Committed in:** `40dced1`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The change only closes the intended RED-to-GREEN module seam; it does not alter contract coverage or production behavior.

## Issues Encountered

None beyond the resolved TypeScript dynamic-import seam.

## User Setup Required

None - no external service configuration required.

## Verification Evidence

- `npx playwright test test/browser/specs/system-quality-contract.spec.ts --project=chromium-wide` — 33 passed.
- `npx prettier --check test/browser/support/system-quality.ts test/browser/support/axe.ts test/browser/specs/system-quality-contract.spec.ts` — pass.
- `git diff --check` — pass.

## Next Phase Readiness

- Plans 82-08 through 82-10 can import `auditSystemQuality`, the focused/reflow/motion helpers, and `assertAxePolicy` without page-local substitutes.
- Exact future-consumer wiring remains intentionally deferred to its owning plans.
- No blockers.

## Self-Check: PASSED

- All key files exist.
- Both task commits exist.
- All 33 Wave 0 browser contracts pass without retries or sleeps.

---
*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Completed: 2026-07-29*
