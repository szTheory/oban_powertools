---
phase: 75
slug: form-components
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-11
---

# Phase 75 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix; Phoenix LiveView component render helpers; Playwright Test 1.61.0; axe-core 4.11.x |
| Config file | `mix.exs`, `playwright.config.ts`, `test/browser/support/axe.ts` |
| Quick run command | `mix test test/oban_powertools/web/components/forms_test.exs test/oban_powertools/form_story_catalog_test.exs` |
| Full suite command | `npm run visual:a11y && mix test --exclude host_contract && mix compile --warnings-as-errors` |
| Estimated runtime | Quick: local ExUnit subset; Full: browser VRT/a11y plus full non-host-contract ExUnit suite |

## Sampling Rate

- After every task commit: run the relevant ExUnit file for changed form components/catalog code.
- After every story or manifest change: run `npm run showcase:manifest`.
- After every plan wave: run `npm run visual:a11y:host -- test/browser/specs/forms.behavior.spec.ts` plus the relevant ExUnit subset.
- Before `/gsd:verify-work`: run `npm run visual:a11y && mix test --exclude host_contract && mix compile --warnings-as-errors`.
- Max feedback latency: one task commit between automated checks.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 75-W0-01 | TBD | 0 | FORM-01, FORM-02 | T-75-01, T-75-04 | Form components derive id/name/value/errors from `Phoenix.HTML.FormField`, filter caller visual escape hatches, and escape user-facing text | unit/static | `mix test test/oban_powertools/web/components/forms_test.exs` | No - Wave 0 | pending |
| 75-W0-02 | TBD | 0 | FORM-01, COMP-01..04 | - | Form story metadata is deterministic, separate from domain stress fixtures, and generated into the showcase manifest | unit/static | `mix test test/oban_powertools/form_story_catalog_test.exs && npm run showcase:manifest` | No - Wave 0 | pending |
| 75-W0-03 | TBD | 0 | FORM-02, A11Y-02 | T-75-02, T-75-03 | Labels, hints, errors, `aria-describedby`, `aria-invalid`, native choice keyboard behavior, disabled/read-only states, and 320px reflow are browser-proven | browser | `npm run visual:a11y:host -- test/browser/specs/forms.behavior.spec.ts` | No - Wave 0 | pending |
| 75-W0-04 | TBD | 0 | COMP-02, COMP-04 | T-75-04 | Token-only source stays clean; form stories join the existing VRT/axe matrix across system/light/dark/high-contrast and 320/tablet/wide | browser/VRT/static | `npm run visual:a11y` | Existing harness; form targets missing | pending |

## Wave 0 Requirements

- [ ] `test/oban_powertools/web/components/forms_test.exs` - render/API/no-raw/no-escape/a11y wiring contracts for FORM-01, FORM-02, COMP-01..03.
- [ ] `test/support/form_story_catalog.ex` - dev/test-only form story metadata for valid, invalid, required, optional, disabled, read-only, loading, filter-ready, long-label, and long-value states.
- [ ] `test/oban_powertools/form_story_catalog_test.exs` - deterministic story ids, stable selectors, target metadata, and accessibility labels.
- [ ] `test/browser/specs/forms.behavior.spec.ts` - label association, hint/error `aria-describedby` merge, `aria-invalid`, keyboard choice behavior, label click behavior, focus, disabled/read-only contrast, reduced motion, and 320px overflow checks.
- [ ] `scripts/showcase_manifest.exs` and `test/browser/support/manifest.ts` updates - include generated form targets without hardcoded TypeScript story lists.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Screen-reader announcement quality across migrated production pages | A11Y-02 | Phase 75 proves component-level semantics; full page-level manual SR traversal is deferred to Phase 82 | Do not block Phase 75; record page-level SR concerns as Phase 82 follow-ups |
| Jobs/Forensics URL filter behavior | FORM-03 | Phase 75 deliberately ships filter-ready fields only; URL-preserving page migration is Phase 80 | Verify only that filter-ready controls remain semantic text/select controls and do not emit fake combobox roles |
| Destructive reason/confirm flows | FORM-04 | Phase 78 owns the danger-form meta-pattern; Phase 75 only supplies reusable fields | Verify reason-field examples render through shared label/hint/error semantics without changing mutation flow |

## Threat References

| Threat Ref | Threat | Mitigation Verified By |
|------------|--------|------------------------|
| T-75-01 | XSS through label, hint, error, or option text | HEEx-rendered component tests with hostile text and no raw-HTML label/error API |
| T-75-02 | Hidden unchecked values corrupt row-selection events | Source/render tests proving hidden unchecked values are emitted only for named boolean fields, not event-driven row selection checkboxes |
| T-75-03 | Misleading unavailable controls or visually disabled actions | Browser/source checks for native `disabled`, distinct read-only rendering, explanation text, and parent-owned action suppression |
| T-75-04 | Host style or caller visual policy bypass through `class` or `style` rest attrs | Static/source tests and hostile render tests mirroring Phase 74 primitive safeguards |
| T-75-05 | Fake combobox semantics on plain filters | Source/render/browser tests proving filter-ready fields remain native text/search/select controls unless a real popup exists |

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency stays within one task commit.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 and plan coverage are complete.

**Approval:** pending
