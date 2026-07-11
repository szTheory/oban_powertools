---
phase: 75-form-components
plan: 01
subsystem: ui-testing
tags: [phoenix-component, forms, accessibility, tdd, security]
requires:
  - phase: 74-primitives-library
    provides: Phoenix component render-contract patterns and visual-safe caller attribute policy
  - phase: 71-token-layer-isolated-theming-engine
    provides: Scoped token and host-isolation constraints for form components
provides:
  - RED ExUnit contract for all ten Phase 75 form component exports
  - Executable field identity, validation, native-choice, escaping, and rest-attribute requirements
  - Source guards against visual literals, host theme mutation, raw HTML, and fake widget behavior
affects: [75-02-form-implementation, 75-03-form-stories, phase-78-groups, phase-80-pages]
tech-stack:
  added: []
  patterns:
    - Field-first component tests using Phoenix.Component.to_form and Phoenix.LiveViewTest rendering
    - RED contracts covering semantic output and source-level safety invariants
key-files:
  created:
    - test/oban_powertools/web/components/forms_test.exs
  modified: []
key-decisions:
  - "The RED contract uses real map-backed `to_form/2` fields so implementation must derive native identity and values through Phoenix.HTML.FormField."
  - "Named booleans and event-driven row selection are separate checkbox modes, with hidden unchecked inputs forbidden for event-driven selection."
  - "Caller descriptions precede generated hint/error ids and are deduplicated; invalid state exists only while visible errors render."
patterns-established:
  - "Component contracts render through Phoenix.LiveViewTest and fail cleanly on the missing production module."
  - "Hostile strings exercise every text trust boundary while source assertions reject raw HTML and invented JavaScript/ARIA widget behavior."
requirements-completed: [FORM-01, FORM-02, COMP-01, COMP-02, COMP-03, A11Y-02]
duration: 4 min
completed: 2026-07-11
status: complete
---

# Phase 75 Plan 01: Form Component Contract Summary

**A focused RED ExUnit suite specifies field-derived form identity, truthful validation wiring, native choice semantics, and hostile caller-content safeguards**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-11T17:17:30Z
- **Completed:** 2026-07-11T17:21:44Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Defined all ten public form exports and exercised each high-level field through a real `Phoenix.HTML.FormField` from `to_form/2`.
- Fixed exact contracts for caller-overridden identity, visible labels, deterministic hint/error ids, caller-first description merging, quiet unused errors, explicit errors, native disabled/read-only states, and filter-ready search semantics.
- Added high-severity trust-boundary coverage for escaped labels, hints, errors, values, and options; filtered visual attrs; named/event checkbox separation; and forbidden raw HTML or custom widget behavior.

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | Write the RED form API and semantic contract | `13a61e2` | test RED |

## Files Created/Modified

- `test/oban_powertools/web/components/forms_test.exs` - Fifteen named RED render, API, accessibility, native-state, hostile-input, and source-policy contracts.

## Decisions Made

- Used runtime module/export assertions before component rendering, allowing the suite to compile fully and fail for the intended missing `Forms` implementation.
- Used map-backed `to_form/2` errors and `_unused_` metadata to make the `used_input?/1` timing contract objective without introducing a test-only schema.
- Kept grouped controls native: fieldsets/legends for radio and field groups, checkbox inputs for checkboxes and switches, and no fake combobox or switch roles.

## TDD Gate Compliance

- **RED:** `13a61e2` added the failing contract suite. Focused verification produced `15 tests, 15 failures`, all caused by the absent `ObanPowertools.Web.Components.Forms` module/source.
- **GREEN:** Deferred to plan `75-02`, which implements the production form component module against this contract.
- **REFACTOR:** Not applicable to this RED-only plan.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None. This plan intentionally creates only the RED contract; production implementation is owned by `75-02`.

## Threat Flags

None. T-75-01 through T-75-05 are represented by escaping, rest-filtering, described-by/invalid-state, hidden unchecked-value, and fake-combobox assertions.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix format test/oban_powertools/web/components/forms_test.exs` - PASSED.
- `mix test test/oban_powertools/web/components/forms_test.exs` - RED as required: 15 tests, 15 failures for missing production module/source only.
- `git diff --check -- test/oban_powertools/web/components/forms_test.exs` - PASSED.

## Self-Check: PASSED

- Found `test/oban_powertools/web/components/forms_test.exs`.
- Found task commit `13a61e2` in git history.
- Confirmed no production source file was modified by the task commit.
- Summary file created at `.planning/phases/75-form-components/75-01-SUMMARY.md`.

## Next Phase Readiness

Ready for `75-02`: implement `ObanPowertools.Web.Components.Forms` and make the RED contract green.

---
*Phase: 75-form-components*
*Completed: 2026-07-11*
