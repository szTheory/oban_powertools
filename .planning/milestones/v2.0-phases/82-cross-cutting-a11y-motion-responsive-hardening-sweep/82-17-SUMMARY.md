---
phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
plan: "17"
subsystem: ui
tags: [copy-policy, schema-8, manifest, accessibility, typescript]

requires:
  - phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep
    provides: RED finite copy-policy contracts from Plan 02
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    provides: schema-8 inventory with 163 targets and 99 page stories
provides:
  - Deterministic production-owned operator copy policy
  - Schema-8 non-inventory copy policy projection
  - Independent typed and static fail-closed manifest validation
affects: [82-14, page-acceptance, showcase-a11y, milestone-quality-gate]

tech-stack:
  added: []
  patterns:
    - Production Elixir owns finite browser-readable policy
    - Browser validators consume generated policy without a second target registry

key-files:
  created:
    - lib/oban_powertools/web/copy.ex
  modified:
    - test/oban_powertools/web/copy_contract_test.exs
    - scripts/showcase_manifest.exs
    - test/browser/support/manifest.ts
    - test/browser/support/manifest-smoke.mjs

key-decisions:
  - "Keep page-specific consequence and support prose outside Copy.contract/0."
  - "Retain schema 8 and project copy_contract beside, never inside, catalog inventory."
  - "Validate policy structure and invariants in TypeScript without duplicating Elixir-owned phrase or target registries."

patterns-established:
  - "Finite policy projection: compile-time Elixir maps serialize once into non-inventory manifest metadata."
  - "Fail-closed policy validation: exact fields, finite identifiers, non-empty unique values, and target-ID rejection."

requirements-completed:
  - COPY-01
  - COPY-02
  - A11Y-01
  - A11Y-04

duration: 5min
completed: 2026-07-29
status: complete
---

# Phase 82 Plan 17: Finite Copy Policy and Manifest Projection Summary

**One production-owned copy contract now drives ExUnit and schema-8 browser validation while the 163-target/99-page inventory remains unchanged**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-29T20:29:00Z
- **Completed:** 2026-07-29T20:33:48Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a deterministic `ObanPowertools.Web.Copy` contract for canonical terms, forbidden phrases, state/recovery requirements, confirmation order, honest receipt verbs, scan roots, and exact exclusions.
- Projected that contract as schema-8 `copy_contract` metadata without adding or reordering showcase targets.
- Added typed and independent static policy validators, including malformed fixtures for missing fields, extra inventory, malformed canonical policy, and embedded target IDs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement the finite Copy contract and source scanner policy** - `bd44ec5` (feat)
2. **Task 2: Project and validate copy policy in schema 8** - `71635f7` (feat)

## Files Created/Modified

- `lib/oban_powertools/web/copy.ex` - Finite production-owned copy policy.
- `test/oban_powertools/web/copy_contract_test.exs` - Corrected exclusion-usage fixture and verifies the production policy.
- `scripts/showcase_manifest.exs` - Projects `Copy.contract/0` beside unchanged inventory.
- `test/browser/support/manifest.ts` - Typed runtime validation of generated copy policy.
- `test/browser/support/manifest-smoke.mjs` - Independent static policy validation and malformed-policy self-tests.

## Decisions Made

- Kept contract content finite and public-safe: no preview identity, runtime reason, provider payload, exception detail, or page-specific consequence prose crosses into generated JSON.
- Validated policy structure and cross-field invariants rather than copying phrase literals into TypeScript.
- Preserved the schema version and exact inventory reconstruction so copy metadata cannot become a second showcase registry.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected inverted stale-exclusion fixture logic**
- **Found during:** Task 1
- **Issue:** The RED helper marked a matching exclusion as unused and ignored an unmatched stale exclusion.
- **Fix:** Negated the source-match predicate so only unmatched exact exclusions fail.
- **Files modified:** `test/oban_powertools/web/copy_contract_test.exs`
- **Verification:** All 8 focused copy-contract tests pass.
- **Committed in:** `bd44ec5`

---

**Total deviations:** 1 auto-fixed bug.
**Impact on plan:** The correction makes the intended stale/used exclusion contract executable; no product scope changed.

## Issues Encountered

- The repository does not include TypeScript as a standalone compiler dependency. Playwright `--list` was used for the repository-native TypeScript load/compile check; no package was installed.

## User Setup Required

None - no external service configuration required.

## Verification Evidence

- `mix test test/oban_powertools/web/copy_contract_test.exs --seed 0` — 8 tests, 0 failures.
- `npm run showcase:manifest` — schema 8 generated successfully.
- `node test/browser/support/manifest-smoke.mjs` — 9 scenarios, 99 page stories, 163 targets.
- `npx playwright test test/browser/specs/page.acceptance.spec.ts --list` — 297 generated cases discovered across three viewports.
- `git diff --check` — plan-owned files pass.

## Next Phase Readiness

- Browser rendered-copy and connected-route scans can consume `manifest.copy_contract` without adding a second phrase or target registry.
- No blockers; the next dependency-ready Phase 82 plan may proceed.

---
*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Completed: 2026-07-29*
