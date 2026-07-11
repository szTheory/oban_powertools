---
phase: 75-form-components
plan: 04
subsystem: ui
tags: [playwright, manifest, forms, accessibility, visual-regression]
requires:
  - phase: 75-03
    provides: Nine rendered form stories and the deterministic Elixir form story catalog
provides:
  - Schema version 3 showcase manifest with nine first-class form stories
  - Strict TypeScript and smoke validation for ordered form target metadata
  - Unified structure, VRT, and axe iteration across all 25 showcase targets
affects: [75-05, visual-regression, accessibility, showcase-manifest]
tech-stack:
  added: []
  patterns: [Elixir-owned browser target generation, discriminated target union, derived selector validation]
key-files:
  created: []
  modified: [scripts/showcase_manifest.exs, test/browser/support/manifest.ts, test/browser/support/manifest-smoke.mjs, test/browser/support/showcase.ts]
key-decisions:
  - "D-23: Form target ids, selectors, and snapshots derive only from the Elixir story catalog and join the generated target union after primitives."
  - "Bumped the manifest schema to version 3 because form_stories is a new required top-level collection and target kind."
patterns-established:
  - "Every component-story collection is validated against its kind-specific slug and mechanically derived story, snapshot, and axe selector."
  - "Browser suites consume the unified targets export; target-kind narrowing adds metadata assertions without separate story lists."
requirements-completed: [FORM-01, FORM-02, COMP-02, COMP-03, COMP-04, A11Y-02]
duration: 10 min
completed: 2026-07-11
status: complete
---

# Phase 75 Plan 04: Generated Form Target Contract Summary

**Nine Elixir-owned form stories are now first-class, strictly validated showcase targets consumed automatically by structure, VRT, and axe coverage.**

## Performance

- **Duration:** 10 min
- **Completed:** 2026-07-11
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Extended the generated showcase manifest to schema version 3 with exactly nine `form_stories`, ordered after scenarios and primitive stories in the 25-member target union.
- Added strict TypeScript and standalone smoke validation for form kind, `form-*` ids, metadata, counts, ordering, selectors, snapshots, and exact collection/target equality.
- Proved every generated form target resolves exactly once in the showcase and participates in all four themes of the existing axe loop without form-specific lists, masks, or skips.

## Task Commits

1. **Task 1: Generate and strictly validate form manifest targets** - `9cd581e`
2. **Task 2: Teach showcase structure support about form targets** - `b393402`

## Files Created/Modified

- `scripts/showcase_manifest.exs` - Serializes the form catalog and appends its targets to the generated manifest.
- `test/browser/support/manifest.ts` - Defines `ShowcaseFormStory`, validates the schema, and exports `formStories` plus unified targets.
- `test/browser/support/manifest-smoke.mjs` - Independently checks form counts, metadata, derived paths/selectors, and target ordering.
- `test/browser/support/showcase.ts` - Narrows form targets and asserts exact rendered form-story metadata.

## Decisions Made

- Bumped the schema version from 2 to 3 so consumers fail closed when the new required collection or target kind is absent.
- Kept form identifiers entirely Elixir-owned; TypeScript validates generated values but contains no form story id array.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A direct `npx tsc` check was unavailable because TypeScript is not a direct project dependency; Playwright loaded and compiled the TypeScript support contract during the required browser suites.
- Dependency resolution reported existing upstream security advisories. This plan introduced no dependencies and its catalog-to-locator boundaries pass the strict traversal and selector checks.

## Verification

- `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` — passed: 9 scenarios, 7 primitive stories, 9 form stories, 25 targets.
- Structure suite on `chromium-320` — 4 themes, 4 passed.
- Form axe suite on `chromium-320` — 9 form targets × 4 themes, 36 passed.
- `rg 'form-input-states|form-textarea-select' test/browser --glob '*.ts' --glob '*.mjs'` — no hardcoded form story entries.

## Self-Check: PASSED

## User Setup Required

None.

## Next Phase Readiness

Ready for 75-05 targeted browser behavior and baseline completion. No blockers.

---
*Phase: 75-form-components*
*Completed: 2026-07-11*
