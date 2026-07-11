---
phase: 75-form-components
reviewed: 2026-07-11T18:05:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - assets/oban_powertools/tokens.css
  - lib/oban_powertools/web/components/forms.ex
  - lib/oban_powertools/web/dev/showcase_live.ex
  - priv/static/oban_powertools/oban_powertools.css
  - scripts/showcase_manifest.exs
  - test/browser/specs/forms.behavior.spec.ts
  - test/browser/support/manifest-smoke.mjs
  - test/browser/support/manifest.ts
  - test/browser/support/showcase.ts
  - test/oban_powertools/form_story_catalog_test.exs
  - test/oban_powertools/web/components/forms_test.exs
  - test/oban_powertools/web/live/showcase_live_test.exs
  - test/support/form_story_catalog.ex
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 75: Code Review Report

**Reviewed:** 2026-07-11T18:05:00Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

The form implementation is well scoped, escapes caller content, preserves native control semantics, strictly validates generated manifest targets, and keeps the source and compiled CSS assets identical. Three component edge cases violate the Phase 75 accessibility or native-submission contracts. No critical security or performance issue was found.

## Findings

### WR-01: Switch state text becomes false after native interaction

- **Severity:** Warning
- **File:** `lib/oban_powertools/web/components/forms.ex:197`
- **Related test gap:** `test/browser/specs/forms.behavior.spec.ts:144`
- **Contract:** The UI-SPEC requires a visible, non-color-only on/off signal and the browser plan requires state to remain visible after native Space interaction.

The visible `On`/`Off` text is computed only during server rendering (`if @checked`). A user can toggle the checkbox natively with Space or a label click, which updates `:checked` and the CSS track but leaves the rendered text unchanged until a parent LiveView happens to rerender. The existing browser test toggles the control and asserts only `toBeChecked()`, so it does not catch that the same switch simultaneously continues to say `Off`.

Use CSS tied to `:checked` to expose mutually exclusive on/off labels, or otherwise ensure native change immediately keeps the textual state synchronized. Extend the behavior test to assert the visible state text after both directions of native toggling.

### WR-02: Disabled named booleans still submit an enabled hidden `false` value

- **Severity:** Warning
- **File:** `lib/oban_powertools/web/components/forms.ex:127`
- **Also applies to:** `lib/oban_powertools/web/components/forms.ex:190`
- **Contract:** Disabled native controls need not be submitted and must not imply a state change.

For named checkboxes and switches, the hidden unchecked input is always enabled even when the visible checkbox is disabled. Browser form submission therefore sends `false` for a disabled true-valued field, despite the native checkbox itself being omitted. A disabled control can consequently overwrite persisted state merely because the form was submitted for another reason.

Propagate `disabled={@disabled}` to the hidden unchecked input (matching the visible control), and add component coverage for disabled named checkbox and switch submission markup.

### WR-03: Multiple validation messages render duplicate DOM ids

- **Severity:** Warning
- **File:** `lib/oban_powertools/web/components/forms.ex:49`
- **Also applies to:** `lib/oban_powertools/web/components/forms.ex:75`, `lib/oban_powertools/web/components/forms.ex:105`, `lib/oban_powertools/web/components/forms.ex:135`, `lib/oban_powertools/web/components/forms.ex:169`, `lib/oban_powertools/web/components/forms.ex:200`
- **Contract:** Generated hint/error ids must be deterministic and unique, and `aria-describedby` must truthfully associate all rendered guidance.

Every entry in `@visible_errors` is rendered with the same `${id}-error` id, while `aria-describedby` contains that id only once. Any field with two validation messages therefore creates invalid duplicate ids and an ambiguous accessible-description target.

Prefer one `${id}-error` container containing all messages, or assign indexed ids and merge all of them into `aria-describedby`. Add a render test with at least two errors and assert document-wide id uniqueness and complete description wiring.

## Verification

- `mix test test/oban_powertools/web/components/forms_test.exs test/oban_powertools/form_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs` passed: 27 tests, 0 failures.
- `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` passed: 9 scenarios, 7 primitive stories, 9 form stories, 25 targets.
- `assets/oban_powertools/tokens.css` and `priv/static/oban_powertools/oban_powertools.css` are byte-identical.

---

_Reviewed: 2026-07-11T18:05:00Z_
_Reviewer: gsd-code-reviewer_
_Depth: standard_
