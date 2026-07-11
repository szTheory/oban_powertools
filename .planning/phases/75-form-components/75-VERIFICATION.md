---
phase: 75-form-components
verified: 2026-07-11T18:15:00Z
status: gaps_found
score: "15/18 must-haves verified"
behavior_unverified: 0
overrides_applied: 0
next_action: "Create and execute Phase 75 gap-closure plans for WR-01 through WR-03, then re-run verification."
next_command: "/gsd-plan-phase 75 --gaps"
---

# Phase 75: Form Components Verification Report

**Phase Goal:** Accessible, token-driven Phoenix form primitives built on `to_form`, with deterministic showcase and browser evidence.
**Verified:** 2026-07-11
**Status:** gaps_found
**Re-verification:** No - initial verification

## Goal Achievement

Phase 75 is substantially implemented, but the goal is not yet fully achieved. The component library, token CSS, form story catalog, generated manifest integration, browser behavior suite, and committed VRT baselines are present and exercised. Three review findings remain reproducible in the current production source and violate explicit Phase 75 native-submission, unique-association, and non-color switch-state contracts.

The 96 scenario-only VRT failures are not Phase 75 defects: all 108 form VRT cases and all targeted form behavior/axe cases passed. Optional Phoenix host-contract compilation failures/timeouts are also outside this phase when caused by the external host fixture/toolchain; the core non-host-contract suite and warnings-as-errors compile passed. Neither external gate excuses WR-01..03, which are local Phase 75 defects visible directly in `forms.ex`.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Ten stateless `Phoenix.Component` form exports exist in a separate `Forms` module. | VERIFIED | `lib/oban_powertools/web/components/forms.ex`; focused component tests pass. |
| 2 | High-level controls derive id/name/value/errors from `Phoenix.HTML.FormField`/`to_form` while permitting explicit identity overrides. | VERIFIED | `prepare_field/2` and render contracts in `forms_test.exs`. |
| 3 | Input, textarea, select, checkbox, radio group, and switch use native semantics; filter input does not claim combobox behavior. | VERIFIED | Native elements in `forms.ex`; component and browser behavior tests. |
| 4 | Visible labels/legends, deterministic hint ids, truthful single-error invalid state, and caller-first description merging exist. | VERIFIED | Component tests and targeted Playwright evidence. |
| 5 | Caller content is HEEx-escaped and caller `class`/`style` visual escape hatches are filtered. | VERIFIED | Hostile-content/static contracts in `forms_test.exs`. |
| 6 | Form CSS is `.obpt-root` scoped, token-backed, responsive, theme-aware, focus-visible, and reduced-motion aware. | VERIFIED | `assets/oban_powertools/tokens.css`; compiled asset matches source; form VRT matrix passed. |
| 7 | Disabled and readonly text controls are semantically and visually distinct. | VERIFIED | Native attributes, token styles, and targeted browser checks. |
| 8 | Choice controls provide native keyboard and label-click behavior. | VERIFIED | Targeted form behavior suite passed at 320 and wide viewports. |
| 9 | Named booleans emit hidden unchecked values while event-driven selection checkboxes do not. | VERIFIED | Render tests cover normal modes; disabled mode is the separate gap below. |
| 10 | Radio groups use `fieldset`/`legend` without invented ARIA widget semantics. | VERIFIED | `radio_group/1` markup and render/browser tests. |
| 11 | A separate dev/test-only catalog contains nine deterministic form stories. | VERIFIED | `test/support/form_story_catalog.ex`; manifest smoke reports 9 form stories. |
| 12 | The showcase renders real `to_form`-backed controls at generated stable targets. | VERIFIED | Showcase tests pass; manifest smoke reports 25 total targets. |
| 13 | Form browser evidence covers behavior, axe, themes, viewports, and committed VRT baselines. | VERIFIED | 13 tests per targeted viewport and 108/108 form VRT cases documented in `75-VALIDATION.md`. |
| 14 | No new runtime dependency, page migration, form DSL, popup combobox, or page-owned persistence behavior was added. | VERIFIED | Scope/source inspection and plan summaries. |
| 15 | FORM-01 and the implemented component-level portion of A11Y-02 are substantively covered. | VERIFIED | ExUnit, browser, axe, and VRT evidence; Phase 82 retains full page/manual accessibility closure. |
| 16 | Switch visible On/Off text remains synchronized immediately after native interaction. | GAP | WR-01 remains at `forms.ex`: state text is server-rendered from `@checked`, so native Space/click changes `:checked` but not the text until rerender. Existing browser test asserts checked state only. |
| 17 | Disabled named checkbox/switch fields do not submit a hidden false value. | GAP | WR-02 remains: hidden unchecked inputs omit `disabled={@disabled}` in both `checkbox/1` and `switch/1`, allowing disabled true values to be overwritten on unrelated submission. |
| 18 | Multiple visible validation messages have unique, complete accessible-description wiring. | GAP | WR-03 remains: every error is rendered with the same `${id}-error` id while `aria-describedby` lists it once, producing duplicate DOM ids for multiple errors. |

**Score:** 15/18 must-haves verified.

## Requirements Coverage

| Requirement | Status | Evidence / Blocking Issue |
|---|---|---|
| FORM-01 | SATISFIED | All scoped form primitives exist, are field-first, native, and token-only. |
| FORM-02 | BLOCKED | WR-01 and WR-03 violate non-color state accuracy and deterministic/complete error association; WR-02 violates disabled native submission behavior. |
| COMP-01..04 (form set) | SATISFIED WITH GAPS ABOVE | Documented attrs/components, token styling, story matrix, themes, 320px, axe, and VRT exist; the three behavioral edge cases prevent phase completion. |
| A11Y-02 (component scope) | BLOCKED | Keyboard operation/focus are proven, but switch text and duplicate error ids fail the component-level accessibility contract. Full page/dialog/manual scope remains Phase 82. |

Note: `.planning/REQUIREMENTS.md` checkboxes mark FORM-01/02 complete, but its traceability table still says Phase 75 `Pending`. That bookkeeping inconsistency should be corrected when the gap closure is completed; it is not the cause of the implementation failure.

## Verification Evidence

| Check | Result |
|---|---|
| `mix test test/oban_powertools/web/components/forms_test.exs test/oban_powertools/form_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs` | PASS - 27 tests, 0 failures |
| `mix compile --warnings-as-errors` | PASS |
| `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` | PASS - 9 scenarios, 7 primitive stories, 9 form stories, 25 targets |
| Targeted form Playwright at chromium-320 and chromium-wide | PASS - 13 tests each, recorded in `75-VALIDATION.md` |
| Form VRT matrix | PASS - 108/108 form cases, recorded in `75-VALIDATION.md` |
| Full `npm run visual:a11y` | EXTERNAL/PRE-EXISTING FAILURE - 579/675 pass; exactly 96 scenario-only VRT baseline failures, no form-target failure |
| Optional host-contract gate | NON-BLOCKING EXTERNAL - host fixture Phoenix compile failure/timeouts are not attributable to Phase 75 form code |

## Gaps Summary

1. **WR-01:** Synchronize visible switch On/Off text with native checked state and test both toggle directions.
2. **WR-02:** Disable hidden unchecked inputs whenever the named checkbox/switch is disabled; add submission-markup coverage.
3. **WR-03:** Render one uniquely identified error container or indexed unique error ids, with complete `aria-describedby` coverage; test multiple errors and global id uniqueness.

## Next Action

Create gap-closure plans for WR-01..03, execute them, and re-run Phase 75 verification.

`/gsd-plan-phase 75 --gaps`

