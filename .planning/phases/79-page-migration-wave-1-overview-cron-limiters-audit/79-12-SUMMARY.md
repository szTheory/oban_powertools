---
phase: 79-page-migration-wave-1-overview-cron-limiters-audit
plan: 12
subsystem: testing
tags: [showcase, schema-7, playwright, page-stories, accessibility]

requires:
  - phase: 79-page-migration-wave-1-overview-cron-limiters-audit
    plan: 09
    provides: Exact RED contract for schema-7 page discovery and manifest-derived browser evidence
  - phase: 79-page-migration-wave-1-overview-cron-limiters-audit
    plan: 11
    provides: Exact 19-story Elixir catalog and production-composed ShowcaseLive activation seam
provides:
  - Schema-7 manifest with 19 generated page stories and 83 total ordered targets
  - Independent strict TypeScript and Node validators derived from the Elixir-owned page registry
  - Generic page activation, overlay bounds, and visual target discovery for shared Playwright suites
affects: [79-08, page-accessibility, page-visual-regression, showcase-manifest]

tech-stack:
  added: []
  patterns:
    - Elixir owns the only literal page-story registry while downstream validators derive order from generated data
    - Page activation closes any prior group overlay before mounting one production-composed page stage
    - Schema evolution appends page targets without changing the preceding 64 schema-6 targets

key-files:
  created: []
  modified:
    - scripts/showcase_manifest.exs
    - test/browser/.generated/showcase-manifest.json
    - test/browser/support/manifest.ts
    - test/browser/support/manifest-smoke.mjs
    - test/browser/support/showcase.ts

key-decisions:
  - "Keep the exact 19 page-story IDs in Elixir only; TypeScript and Node validate page target sequence against generated page_stories."
  - "Append page stories after the unchanged 64-target schema-6 prefix so existing scenario and component discovery remains byte-for-byte stable."
  - "Close any active group overlay before page activation, then enforce one active page story and at most one dialog or modal."

patterns-established:
  - "Closed schema validation: reject unknown or missing manifest/page fields, unsupported page names, activation modes, kinds, and reordered targets with precise diagnostics."
  - "Shared browser activation: structure, axe, and VRT consumers activate page stories through the same validated LiveView event and production stage."

requirements-completed:
  - PAGE-01
  - PAGE-05
  - PAGE-06
  - PAGE-08
  - PAGE-10
  - COPY-01
  - A11Y-*
  - MOTION-*

duration: 13m
completed: 2026-07-19
status: complete
---

# Phase 79 Plan 12: Schema-7 Page Showcase Targets Summary

**The generated showcase manifest now discovers exactly 19 Elixir-owned page stories as schema-7 targets, with strict independent validation and one shared connected activation path for structure, accessibility, and visual evidence.**

## Performance

- **Duration:** 13m
- **Started:** 2026-07-19T23:32:42Z
- **Completed:** 2026-07-19T23:45:49Z
- **Tasks:** 1
- **Files modified:** 5 (4 tracked sources plus the ignored generated manifest)

## Accomplishments

- Generated `page_stories` directly from `ObanPowertools.PageStoryCatalog`, asserted the binding count of 19, advanced the manifest to schema 7, and appended them to reach exactly 83 targets.
- Preserved the serialized SHA-256 identity of the first 64 targets while making the page-story tail exactly equal to the generated `page_stories` collection.
- Added closed TypeScript and standalone Node validation for exact fields, page/activation/kind domains, derived IDs and selectors, uniqueness, missing/extra stories, and target order without copying the 19-ID registry.
- Extended the shared browser helper to activate every page story through the validated LiveView event, close a lingering group overlay, locate detail/confirmation overlays, and enforce one active page tree with bounded dialog/modal state.
- Proved all 83 targets through the connected structure suite across four themes at the narrow viewport and registered 2,043 structure, a11y, VRT, and page-migration cases across the four browser specs.

## Task Commits

1. **Task 79-12-01: Generate and validate schema-7 page browser targets**
   - `a12ead3` — schema-7 generator, strict validators, and generic page activation

## Files Created/Modified

- `scripts/showcase_manifest.exs` — Derives 19 page stories from the catalog, asserts 83 total targets, and emits schema 7.
- `test/browser/.generated/showcase-manifest.json` — Ignored deterministic output regenerated from the Elixir source.
- `test/browser/support/manifest.ts` — Exports typed page stories and fails closed on schema, domain, field, and ordering drift.
- `test/browser/support/manifest-smoke.mjs` — Independently validates schema 7, exact page target shape, count, and derived sequence.
- `test/browser/support/showcase.ts` — Activates page stories generically and enforces one-tree/one-overlay structure bounds.

## Decisions Made

- The Elixir catalog remains the sole literal registry. Both validators compare the target tail against `page_stories` rather than maintaining a second expected-ID list.
- Page stories are appended after the established schema-6 target prefix so previous discovery order and content remain unchanged.
- Page activation first closes any active group overlay because the shared structure loop visits group targets before page targets; the active page stage then owns the sole allowed dialog/modal.

## Deviations from Plan

None — the plan was implemented as specified.

## Issues Encountered

- An additional non-required run through `with-showcase-server.sh` used the example host's `MIX_ENV=test` path-dependency build, where all optional showcase support catalogs were absent; it failed before activation with zero primitive, form, shell, data, group, and page stories. The planned list gate was unaffected, and a connected `MIX_ENV=dev` host run exercised all 83 targets successfully in all four themes at 320px (4/4).

## User Setup Required

None.

## Next Phase Readiness

- Plan 79-08 can consume the exact 19 manifest-derived page targets for the full connected axe and visual baseline matrix.
- Schema-7 discovery is deterministic, strict, catalog-derived, and preserves all 64 earlier targets unchanged.

## Self-Check: PASSED

- Implementation commit `a12ead3` exists and contains only the four intended tracked source files.
- Manifest generation and independent smoke validation pass with 19 page stories, 83 targets, four themes, and three viewports.
- The first 64 target JSON values retain SHA-256 `09d8d4047f13be71c263ff420dc1f6055ae62deea79491428ac9757fb6e1f034`; repeated full generation retains SHA-256 `709f2ec9c5150b17704f6769778cc7022507e21a1ae5b9f318a247887d0c7d05`.
- Playwright list discovery passes with 2,043 tests in four files, and the connected structure suite passes 4/4 across themes at 320px.
- Elixir formatting, Node syntax, and Git whitespace checks pass; no dependency, lockfile, baseline, route, screenshot, or packaged-asset changes were introduced.
- Pre-existing unrelated planning deletions and untracked workspace files remain untouched.

---
*Phase: 79-page-migration-wave-1-overview-cron-limiters-audit*
*Completed: 2026-07-19*
