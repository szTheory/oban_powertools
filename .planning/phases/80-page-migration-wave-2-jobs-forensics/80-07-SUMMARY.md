---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 07
subsystem: web
tags: [liveview, forensics, forms, timeline, authorization, accessibility]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 05
    provides: Typed four-family Forensics scope grammar and canonical selector paths
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 06
    provides: Bounded Forensics evidence assembly and closed diagnosis-first presenter map
provides:
  - Submit-only typed Forensics chooser with canonical URL lifecycle and zero-read invalid handling
  - Uniform non-enumerating unavailable state for missing and unauthorized evidence
  - Pure closed-assign diagnosis-first page composition with bounded semantic Timeline
  - Backward-compatible custom FilterBar submit label for page-specific operator language
affects: [page-stories, browser-quality, forensics-live, operator-patterns]

tech-stack:
  added: []
  patterns:
    - Parse and authorize a typed scope before every evidence read
    - Keep draft form validation separate from canonical submitted URL state
    - Delegate LiveView render through a public pure component with a closed assign contract

key-files:
  created: []
  modified:
    - lib/oban_powertools/web/forensics_live.ex
    - lib/oban_powertools/web/components/operator_patterns.ex
    - test/oban_powertools/web/live/forensics_live_test.exs
    - test/oban_powertools/web/components/operator_patterns_test.exs

key-decisions:
  - "Bare Forensics is a genuine four-type chooser; mixed, orphaned, or unsupported URL parameters replace to bare Forensics before any source read."
  - "Draft changes reveal and validate type-specific fields without patching or querying; only a valid Inspect evidence submit writes canonical selector parameters."
  - "Missing and unauthorized valid scopes share byte-equivalent Evidence unavailable output and expose no destination differences."
  - "Ready evidence renders from only the exact page assign contract and uses one bounded shared Timeline with absolute machine-readable timestamps."
  - "FilterBar accepts an optional validated submit_label while preserving Apply filters as its default."

patterns-established:
  - "Typed chooser lifecycle: draft validation is local, submission is canonical, and URL input is reparsed before reads."
  - "Closed page boundary: render/1 passes only named presentation assigns into public page_content/1."
  - "Diagnosis-first order: support truth, chooser, summary, guidance, optional history, event log, then evidence limits."

requirements-completed: ["PAGE-09", "FORM-03", "DATA-*", "PAGE-10", "A11Y-*"]

duration: 30m
completed: 2026-07-28
status: complete
---

# Phase 80 Plan 07: Typed Diagnosis-First Forensics Page Summary

**Forensics now turns one canonical typed evidence scope into a bounded, authorization-safe operator narrative without search, mutation, source leakage, or duplicate page trees**

## Performance

- **Duration:** 30m
- **Started:** 2026-07-28T16:28:48Z
- **Completed:** 2026-07-28T16:59:17Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Replaced legacy tuple/map handling with a typed four-family chooser for Workflow, Incident, Cron, and Limiter evidence.
- Separated draft validation from canonical submitted state: field changes perform no patch or evidence query, while valid submission emits only supported selector keys.
- Reparsed direct URL parameters before reads, replaced invalid/conflicting input to bare Forensics, and rendered missing and unauthorized scopes through one byte-equivalent unavailable state.
- Added public pure `page_content/1` composition with the exact closed assign contract and one semantic page tree rooted at `#forensics-page.obpt-page.obpt-forensics-page`.
- Composed ready evidence in diagnosis-first order with shared FilterBar, DescriptionList, disclosure, Timeline, and coverage patterns; event history is newest-first, capped at 50, and carries absolute machine-readable timestamps.
- Kept the page read-only and authorization-bound: one primary supported destination, deduplicated additional guidance, optional neutral historical remediation, and an exhaustive Audit link only when authorized.
- Added confidentiality, accessibility, empty/unavailable, canonicalization, query-bound, section-order, semantic-tree, source-count, and component compatibility coverage.

## Task Commits

Task 80-07-01 used one atomic red-green pair:

1. **RED: Define typed Forensics scope contract** - `56e4882`
2. **GREEN: Add typed Forensics scope state** - `ca3d992`

Task 80-07-02 used one atomic red-green pair plus one post-GREEN semantic correction:

1. **RED: Define diagnosis-first Forensics page** - `ccc8ead`
2. **GREEN: Render diagnosis-first Forensics page** - `0004e8a`
3. **FIX: Pin exact page root and machine-readable event datetimes** - `55c4c3b`

## Files Created/Modified

- `lib/oban_powertools/web/forensics_live.ex` - Typed chooser state, canonical scope lifecycle, authorization/query orchestration, closed render delegation, and diagnosis-first page composition.
- `test/oban_powertools/web/live/forensics_live_test.exs` - Typed form, zero-read invalid input, canonical URL, unavailable-state equality, authorization, pure composition, order, bounds, accessibility, and confidentiality contracts.
- `lib/oban_powertools/web/components/operator_patterns.ex` - Optional validated `submit_label` attribute with the existing `Apply filters` default.
- `test/oban_powertools/web/components/operator_patterns_test.exs` - Focused custom/default submit-label compatibility proof.

## Decisions Made

- Kept the chooser form present across empty, unavailable, and ready states so operators can change evidence families without adding search or saved client state.
- Used `Scope.parse/1` as the sole URL trust boundary and reauthorized both the page and selected scope before calling `Forensics.bundle/2`.
- Preserved draft identifiers after an invalid submit while using associated hints/errors and focusing the invalid summary/field.
- Passed only `scope_form, scope_state, scope_notice, support, summary, next_steps, latest_remediation, events, coverage, audit_href` into pure page composition.
- Rendered chronology event ISO timestamps directly through the shared Timeline so visible time and `<time datetime>` stay absolute and machine-readable.
- Kept arbitrary event state as safe grammatical detail instead of mapping it to an unsupported visual status taxonomy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Component Contract] Added a backward-compatible FilterBar submit label**

- **Found during:** Task 80-07-02 RED.
- **Issue:** The shared submit-mode FilterBar hardcoded `Apply filters`, preventing the required page-specific `Inspect evidence` operator language.
- **Fix:** Added optional validated `submit_label` with the existing string as its default and added focused compatibility coverage.
- **Files modified:** `lib/oban_powertools/web/components/operator_patterns.ex`, `test/oban_powertools/web/components/operator_patterns_test.exs`
- **Verification:** Both custom `Inspect evidence` and default `Apply filters` render in the shared component suite.
- **Committed in:** `0004e8a`
- **Authorization:** Parent executor explicitly approved this minimal backward-compatible extension.

---

**Total deviations:** 1 auto-fixed blocking component contract.
**Impact on plan:** The extension is additive, preserves every existing caller, and enables the exact locked Forensics vocabulary.

## Issues Encountered

- The legacy LiveView passed typed `Forensics.bundle/2` tuples into map-only rendering paths, producing nine baseline failures. The typed state refactor removed that seam and brought the focused integration suite to green.
- The shared checkout contained substantial unrelated dirty work. None of it was modified or staged by this plan.
- A repository-wide `mix test --seed 0` completed with 921 tests and 8 failures in unrelated documentation/host-contract lanes, including the dirty CI workflow contract, optional-Phoenix host compilation, stale overview smoke copy, and a host migration ownership timeout. All required Plan 80-07 domain, LiveView, and component suites pass independently.

## User Setup Required

None. No migration, dependency, route, configuration, schema, asset, or external service change is required.

## Verification

- `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` - 42 tests, 0 failures.
- `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/forensics/evidence_bundle_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` - 46 tests, 0 failures.
- `mix test test/oban_powertools/web/components/data_display_test.exs test/oban_powertools/web/components/operator_patterns_test.exs --seed 0` - 48 tests, 0 failures.
- Exact four-file `mix format --check-formatted ...` command passed.
- `mix compile --warnings-as-errors` passed for production code.
- Invalid URL and draft-change tests prove zero evidence reads; valid missing and unauthorized scopes prove byte-equivalent unavailable output.
- Pure composition proves one H1, one ordered Timeline, exact section order, 50-event cap, absolute `<time datetime>`, authorized links, and absence of sensitive sentinels or legacy raw bundle fields.
- Baseline-to-GREEN inspection contains exactly the four authorized implementation/test files; no route, dependency, schema, migration, asset, source selector, search, mutation, detail surface, second pane, or seventh URL key was added.
- All five implementation task commits pass `git show --check`.

## Next Phase Readiness

- Forensics is ready for shared page-story, browser-quality, accessibility, and visual-regression coverage without changing its server-owned typed state contract.
- Plan 80-08 and later page migrations can reuse the closed pure-composition and typed submit-only chooser patterns.
- Repository-wide docs/host-contract failures remain outside Plan 80-07 and should be resolved by the owning workstreams before a global green claim.

## Self-Check: PASSED

- All four authorized implementation/test files exist and are committed.
- Both required RED/GREEN pairs exist as `56e4882`/`ca3d992` and `ccc8ead`/`0004e8a`; semantic correction `55c4c3b` is also committed.
- The exact focused suites, shared component suites, formatting gate, production warnings-as-errors compile, query-bound assertions, and confidentiality scans pass.
- `render/1` delegates to public `page_content/1` through only the exact closed page assign contract.
- Ready output has the exact page root, one semantic Timeline, absolute machine-readable timestamps, bounded coverage, and only authorized destinations.
- No `.planning/STATE.md` or `.planning/REQUIREMENTS.md` change was staged or committed.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-28*
