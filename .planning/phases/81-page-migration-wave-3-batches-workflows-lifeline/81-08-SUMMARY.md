---
phase: 81-page-migration-wave-3-batches-workflows-lifeline
plan: 08
subsystem: browser-acceptance
tags: [playwright, accessibility, confidentiality, docker, ci]
requires:
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 07
    provides: secret-gated deterministic connected fixtures
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 10
    provides: responsive Wave 3 token CSS
provides:
  - connected Batches, Workflows, and Lifeline production-route acceptance
  - browser, WebSocket, response, DOM, URL, console, page-error, and server-log confidentiality scans
  - required host and Docker page-quality sequencing for Phase 81
affects: [81-09, 81-11, 81-12, 81-13, 81-14, page-quality]
tech-stack:
  added: []
  patterns:
    - fixture-targeted connected selectors remain isolated under concurrent Playwright workers
    - required page-quality order is parsed and rejected on drift
key-files:
  created:
    - test/browser/support/verify-page-script-order.mjs
  modified:
    - test/browser/specs/page-migration-wave-3.spec.ts
    - package.json
    - lib/oban_powertools/web/lifeline_live.ex
    - assets/oban_powertools/tokens.css
    - priv/static/oban_powertools/oban_powertools.css
key-decisions:
  - "Scope connected Lifeline actions to the fixture executor identity so concurrent fixture inventories cannot cause strict-selector ambiguity."
  - "Capture dynamic browser channels while checking prohibited product copy only in the visible Lifeline surface, excluding inert static-asset source text."
  - "Register Phase 81 fixtures and Wave 3 immediately after Wave 2 and before generic page, axe, and VRT checks."
requirements-completed: [PAGE-03, PAGE-04, PAGE-07, GROUP-01, GROUP-02, PAGE-10, A11Y-01, A11Y-02, A11Y-03, A11Y-04, MOTION-01, MOTION-02]
duration: 1h20min
completed: 2026-07-29
status: complete
---

# Phase 81 Plan 08: Connected Wave 3 Acceptance Summary

**Batches, Workflows, and Lifeline now have required secret-aware host and authoritative Docker acceptance, including accessibility, authority, boundedness, and confidentiality evidence.**

## Performance

- **Duration:** 1h20min
- **Completed:** 2026-07-29T09:20:13Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Completed ten connected production-route contracts for Batches, Workflows, Lifeline, focus, responsive behavior, reduced motion, and browser-channel confidentiality.
- Added dynamic capture for requests, responses, WebSocket frames, console output, page errors, DOM/form/attribute state, URLs, performance resources, and the server log.
- Added exact package-script and launcher assertions for page-only mode, 79→80→81 credentials, host/Docker ownership, immutable test flags, and the required Wave 3 position.
- Fixed two production accessibility defects found by connected evidence: Lifeline focus restoration and a sub-44px Wave 3 target.
- Made Lifeline selectors deterministic when fixture and connected specs execute concurrently.

## Task Commits

1. **Tasks 81-08-01/02: Complete connected acceptance and product accessibility fixes** — `2128c94`
2. **Task 81-08-03: Register Wave 3 in required quality flows** — `f898603`
3. **Docker concurrency hardening** — `723fbc9`
4. **Visible-copy confidentiality scope correction** — `9febd6e`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored focus to the exact Lifeline preview invoker**

- Connected Escape evidence showed the dialog trigger did not declare its controlled dialog.
- Added `aria-controls="lifeline-repair-dialog"` at the production trigger.
- Verified native focus restoration after dialog removal.

**2. [Rule 1 - Bug] Enforced Wave 3's 44px interactive target**

- Connected 320px evidence measured the Batches select-all control at 33.39px.
- Added token-derived minimum block size for visible controls across all three Wave 3 roots and regenerated the packaged stylesheet.
- Focused asset/theme/Lifeline tests pass and connected target evidence is green.

**3. [Rule 3 - Blocking] Isolated the selected Lifeline fixture under concurrent specs**

- Running Phase 81 fixture and migration specs together seeded multiple active incidents.
- Scoped the preview action to the fixture executor identity instead of a global accessible name.
- Native and Docker combined runs now pass with two workers.

## Verification Evidence

- `node test/browser/support/verify-page-script-order.mjs` — passed.
- Five-file Playwright list inventory — 4,257 tests discovered.
- `mix test test/oban_powertools/web/assets_test.exs test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0` — 40 tests, 0 failures.
- Native combined Phase 81 fixture + connected acceptance — 16 tests, 0 failures.
- Authoritative Docker combined Phase 81 fixture + connected acceptance — 16 tests, 0 failures.
- `npm run showcase:manifest` — passed.
- `git diff --cached --check` — passed for every commit.

## User Setup Required

None. The launchers generate and forward all three ephemeral credentials without printing them.

## Next Phase Readiness

- The required page-quality graph now includes connected Wave 3 before generic acceptance, axe, ARIA, and VRT evidence.
- Artifact-generation plans can rely on a green connected production contract.
- No blocker remains.

## Self-Check: PASSED

- All four implementation commits exist.
- Native and Docker combined suites are green.
- Pre-existing package, lockfile, script, browser, workflow, and planning changes remain unstaged.

---
*Phase: 81-page-migration-wave-3-batches-workflows-lifeline*
*Completed: 2026-07-29*
