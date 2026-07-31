---
phase: 75
slug: form-components
status: passed_with_warnings
audited_at: 2026-07-11T19:38:29Z
baseline: 75-UI-SPEC.md
screenshots: not_captured_no_dev_server
scores:
  copywriting: 3
  visuals: 4
  color: 4
  typography: 4
  spacing: 4
  experience_design: 4
overall_score: 23
max_score: 24
blockers: 0
warnings: 2
---

# Phase 75 - UI Review

**Audited:** 2026-07-11  
**Baseline:** `.planning/phases/75-form-components/75-UI-SPEC.md` approved design contract and locked Phase 75 decisions  
**Screenshots:** not captured. No `200` dev server response on `localhost:3000`, `5173`, or `8080` (`8080` returned `301`). Code audit used verifier evidence instead.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Field and empty-state copy mostly matches the contract, but the declared primary CTA and load-error copy are not rendered. |
| 2. Visuals | 4/4 | Form stacks render visible label/legend, control, hint, and error hierarchy with verified VRT coverage. |
| 3. Color | 4/4 | Component source uses token classes only; form CSS reserves accent for focus/checked/switch-on and danger for validation. |
| 4. Typography | 4/4 | Form selectors use the specified 12/13/14px token roles and 400/600 weights. |
| 5. Spacing | 4/4 | Form layout uses the declared token scale, full-width controls, token focus geometry, and 44px choice hit targets. |
| 6. Experience Design | 4/4 | Native semantics, error timing, described-by merging, keyboard behavior, focus, reduced motion, and 320px overflow are verified. |

**Overall: 23/24**

---

## Top 3 Priority Fixes

1. **Render the declared `Apply filters` CTA in the filter-ready story** - the copy contract names a primary CTA but `form-filter-ready` only renders search/select controls - add a token-backed or primitive button in the showcase story, or explicitly remove the CTA from the Phase 75 contract if submit actions are out of scope.
2. **Distinguish form catalog load failure from an empty catalog** - unavailable form stories currently fall through to the empty-state copy - return a load-error state from `load_form_catalog/0` and render `Form stories did not load. Regenerate the showcase manifest and check the form story catalog.`
3. **Resolve the non-form scenario VRT drift in its owning phase** - Phase 75 form evidence is green, but the aggregate `npm run visual:a11y` command remains non-zero due to scenario-only baselines - reconcile those scenario screenshots outside Phase 75 so future UI reviews can rely on the full command.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

**WARNING:** The UI-SPEC declares primary CTA copy `Apply filters`, and the catalog records that string in `test/support/form_story_catalog.ex:122`, but the rendered `form-filter-ready` story in `lib/oban_powertools/web/dev/showcase_live.ex:582` through `lib/oban_powertools/web/dev/showcase_live.ex:584` renders only the search input and select. The VRT baseline therefore does not prove the required CTA copy.

**WARNING:** The UI-SPEC declares a load-error state copy, but `load_form_catalog/0` collapses unavailable catalog cases to `%{available?: false, stories: []}` in `lib/oban_powertools/web/dev/showcase_live.ex:384` through `lib/oban_powertools/web/dev/showcase_live.ex:390`, and the Forms branch renders only the empty-state copy in `lib/oban_powertools/web/dev/showcase_live.ex:242` through `lib/oban_powertools/web/dev/showcase_live.ex:243`. Empty state copy itself matches the contract.

**Evidence:** Required field copy is present in `test/support/form_story_catalog.ex:21` through `test/support/form_story_catalog.ex:25`, `test/support/form_story_catalog.ex:66`, `test/support/form_story_catalog.ex:78`, and `test/support/form_story_catalog.ex:108` through `test/support/form_story_catalog.ex:109`. The visible error component prefixes messages with `Error:` in `lib/oban_powertools/web/components/forms.ex:250` through `lib/oban_powertools/web/components/forms.ex:252`.

### Pillar 2: Visuals (4/4)

No blocker or warning found for the component-scoped visual contract. `Forms.input/1`, `textarea/1`, `select/1`, checkbox, radio, switch, field group, hint, and error render the required visible hierarchy and native controls in `lib/oban_powertools/web/components/forms.ex:33` through `lib/oban_powertools/web/components/forms.ex:252`.

**Evidence:** The showcase renders nine deterministic form stories with realistic field stacks in `lib/oban_powertools/web/dev/showcase_live.ex:561` through `lib/oban_powertools/web/dev/showcase_live.ex:587`. Verifier evidence reports targeted form behavior 13/13 on `chromium-320` and 13/13 on `chromium-wide`, form axe pass, Docker form VRT 108/108, and a clean Phase 75 code review.

### Pillar 3: Color (4/4)

No blocker or warning found. Component source does not hardcode hex or `rgb(` values. Raw color literals are confined to the token layer, which the UI-SPEC permits.

**Evidence:** Default controls use surface/text/border tokens in `assets/oban_powertools/tokens.css:425` through `assets/oban_powertools/tokens.css:438`; invalid controls use danger tokens in `assets/oban_powertools/tokens.css:464` through `assets/oban_powertools/tokens.css:470`; focus uses `--obpt-color-focus` in `assets/oban_powertools/tokens.css:454` through `assets/oban_powertools/tokens.css:461`; checkbox/radio checked color and switch-on styling use accent tokens in `assets/oban_powertools/tokens.css:510` through `assets/oban_powertools/tokens.css:554`. `priv/static/oban_powertools/oban_powertools.css` is byte-identical to the source token CSS.

### Pillar 4: Typography (4/4)

No blocker or warning found for Phase 75 form typography. The form selectors use the locked token progression: root/control text inherits `--obpt-font-size-md`, labels use `--obpt-font-size-sm` with semibold, hints use `--obpt-font-size-xs` with regular/relaxed line height, and errors use `--obpt-font-size-sm` with semibold.

**Evidence:** Token definitions are in `assets/oban_powertools/tokens.css:69` through `assets/oban_powertools/tokens.css:79`; root control text is set in `assets/oban_powertools/tokens.css:141` through `assets/oban_powertools/tokens.css:145`; label, hint, and error typography is set in `assets/oban_powertools/tokens.css:391` through `assets/oban_powertools/tokens.css:422`.

### Pillar 5: Spacing (4/4)

No blocker or warning found. Form layout uses the declared token scale and preserves the 320px contract with full-width controls, `min-width: 0`, wrapping text, and token-backed choice targets.

**Evidence:** Field stack gaps use `--obpt-space-2`, groups use `--obpt-space-4` and `--obpt-space-5`, and controls use `--obpt-space-2`/`--obpt-space-4` padding in `assets/oban_powertools/tokens.css:365` through `assets/oban_powertools/tokens.css:436`. Choice rows and switches use `min-height: calc(var(--obpt-space-7) - var(--obpt-space-1))`, which resolves to the required 44px target, in `assets/oban_powertools/tokens.css:498` through `assets/oban_powertools/tokens.css:504`. The behavior spec checks no horizontal overflow at 320px in `test/browser/specs/forms.behavior.spec.ts:309` through `test/browser/specs/forms.behavior.spec.ts:321`.

### Pillar 6: Experience Design (4/4)

No blocker or warning found for the component-scoped experience contract. The implementation preserves native controls, deterministic labels/descriptions/errors, truthful invalid state, disabled/read-only distinction, safe rest filtering, no fake combobox ARIA, and reduced-motion behavior.

**Evidence:** Identity, error visibility, `aria-invalid`, and caller-first `aria-describedby` merging live in `lib/oban_powertools/web/components/forms.ex:268` through `lib/oban_powertools/web/components/forms.ex:307`; multi-error ids are unique in `lib/oban_powertools/web/components/forms.ex:297` through `lib/oban_powertools/web/components/forms.ex:304`; unsafe visual and popup attrs are filtered in `lib/oban_powertools/web/components/forms.ex:321` through `lib/oban_powertools/web/components/forms.ex:329`. Browser behavior tests cover label activation, radio keyboard, descriptions/errors, boolean hidden inputs, switch Space/click, disabled/read-only, native filter semantics, focus in every theme, reduced motion, and 320px overflow in `test/browser/specs/forms.behavior.spec.ts:49` through `test/browser/specs/forms.behavior.spec.ts:323`.

**Verifier evidence included:** `75-VERIFICATION.md` reports 18/18 must-haves verified, form axe pass, Docker form VRT 108/108, and clean code review. `75-VALIDATION.md` records that the full aggregate visual command remains blocked only by existing non-form scenario VRT drift, not by Phase 75 form targets.

---

## Files Audited

- `.planning/phases/75-form-components/75-01-PLAN.md`
- `.planning/phases/75-form-components/75-02-PLAN.md`
- `.planning/phases/75-form-components/75-03-PLAN.md`
- `.planning/phases/75-form-components/75-04-PLAN.md`
- `.planning/phases/75-form-components/75-05-PLAN.md`
- `.planning/phases/75-form-components/75-06-PLAN.md`
- `.planning/phases/75-form-components/75-01-SUMMARY.md`
- `.planning/phases/75-form-components/75-02-SUMMARY.md`
- `.planning/phases/75-form-components/75-03-SUMMARY.md`
- `.planning/phases/75-form-components/75-04-SUMMARY.md`
- `.planning/phases/75-form-components/75-05-SUMMARY.md`
- `.planning/phases/75-form-components/75-06-SUMMARY.md`
- `.planning/phases/75-form-components/75-CONTEXT.md`
- `.planning/phases/75-form-components/75-UI-SPEC.md`
- `.planning/phases/75-form-components/75-VALIDATION.md`
- `.planning/phases/75-form-components/75-VERIFICATION.md`
- `.planning/phases/75-form-components/75-REVIEW.md`
- `lib/oban_powertools/web/components/forms.ex`
- `lib/oban_powertools/web/dev/showcase_live.ex`
- `test/support/form_story_catalog.ex`
- `test/browser/specs/forms.behavior.spec.ts`
- `assets/oban_powertools/tokens.css`
- `priv/static/oban_powertools/oban_powertools.css`
