---
phase: 75
phase_name: form-components
audited_at: 2026-07-11T19:39:11Z
status: secured
threats_total: 32
threats_open: 0
accepted_risks: 1
register_authored_at_plan_time: true
asvs_level: 1
---

# Phase 75 - Security

Threat-model-driven audit for Phase 75 form components. The register was authored at plan time across `75-01-PLAN.md` through `75-06-PLAN.md`; no implementation files were modified during this audit.

## Scope

### Trust Boundaries

| Boundary | Data crossing | Evidence surface |
|---|---|---|
| Caller assigns/rest attrs -> HEEx/DOM | Labels, hints, errors, values, ids, options, global attrs | `forms.ex`, component tests |
| Native browser state -> visible UI | Checkbox/switch checked state before server rerender | `forms.ex`, `tokens.css`, Playwright behavior spec |
| Hidden form inputs -> submitted params | Hidden unchecked false values and selected checkbox values | `forms.ex`, component tests, native `FormData` browser test |
| Generated DOM ids -> assistive tech | Hint/error ids and `aria-describedby` tokens | `forms.ex`, component tests, browser duplicate-id test |
| Catalog JSON -> browser locators/snapshots | Form story ids, selectors, snapshot paths, target metadata | catalog, manifest generator, TS/smoke validators |
| CSS package -> host page | Scoped selectors and published static CSS | `tokens.css`, `priv/static/.../oban_powertools.css` |
| Baselines/evidence -> reviewer trust | VRT screenshots, axe targets, automated accessibility claims | package scripts, VRT/axe specs, screenshot counts |

## Threat Verification

| Threat ID | Origin | Category | Disposition | Status | Evidence |
|---|---|---|---|---|---|
| T-75-01-01 | 75-01 XSS via labels/hints/errors/values/options | XSS | mitigate | closed | HEEx interpolation for controls and errors in `lib/oban_powertools/web/components/forms.ex:34`, `:49`, `:102`, `:248`, `:252`; hostile escaping contract in `test/oban_powertools/web/components/forms_test.exs:408`. |
| T-75-01-02 | 75-01 visual-policy injection through `class`/`style` | Tampering | mitigate | closed | `visual_safe_rest/1` drops `class` and `style` in `lib/oban_powertools/web/components/forms.ex:321`; attr-filter contract in `test/oban_powertools/web/components/forms_test.exs:184`. |
| T-75-01-03 | 75-01 ARIA spoofing or broken associations | Spoofing | mitigate | closed | Final ids, caller descriptions, generated hint/error ids, and `aria-invalid` are built in `lib/oban_powertools/web/components/forms.ex:271`; tests cover ordered associations in `test/oban_powertools/web/components/forms_test.exs:72` and multi-error associations in `:89`. |
| T-75-01-04 | 75-01 hidden unchecked value mutates row selection | Tampering | mitigate | closed | `prepare_choice/2` strips implicit names for nonblank `phx-click` event selection and suppresses hidden fallback in `lib/oban_powertools/web/components/forms.ex:254`; ExUnit mode tests at `test/oban_powertools/web/components/forms_test.exs:239`, `:260`, `:289`; native `FormData` proof in `test/browser/specs/forms.behavior.spec.ts:137`. |
| T-75-01-05 | 75-01 fake combobox communicates nonexistent behavior | Spoofing | mitigate | closed | Popup ARIA and `role` are filtered in `lib/oban_powertools/web/components/forms.ex:321`; filter source/render tests at `test/oban_powertools/web/components/forms_test.exs:216`; browser absence checks at `test/browser/specs/forms.behavior.spec.ts:251`. |
| T-75-02-01 | 75-02 XSS in rendered field content | XSS | mitigate | closed | Component text uses HEEx interpolation in `lib/oban_powertools/web/components/forms.ex:34`, `:48`, `:49`, `:102`, `:248`, `:252`; hostile component tests reject raw HTML in `test/oban_powertools/web/components/forms_test.exs:408`. |
| T-75-02-02 | 75-02 attribute/style injection | Tampering | mitigate | closed | Central rest filtering in `lib/oban_powertools/web/components/forms.ex:321`; allowed semantic attrs and rejected visual attrs tested in `test/oban_powertools/web/components/forms_test.exs:184`. |
| T-75-02-03 | 75-02 hidden input causes unintended selection/mutation | Tampering | mitigate | closed | Named boolean/event-selection split in `lib/oban_powertools/web/components/forms.ex:254`; exact DOM and blank/nil event tests in `test/oban_powertools/web/components/forms_test.exs:239`, `:260`, `:289`; browser `FormData` assertion in `test/browser/specs/forms.behavior.spec.ts:157`. |
| T-75-02-04 | 75-02 disabled control appears actionable | Spoofing | mitigate | closed | Native `disabled` attrs render on controls and hidden fallbacks in `lib/oban_powertools/web/components/forms.ex:41`, `:72`, `:99`, `:127`, `:190`; CSS disabled/read-only distinctions in `assets/oban_powertools/tokens.css:472`; browser disabled/read-only test in `test/browser/specs/forms.behavior.spec.ts:223`. |
| T-75-02-05 | 75-02 CSS leaks into host or host overrides policy | Tampering | mitigate | closed | Form selectors are scoped below `.obpt-root` in `assets/oban_powertools/tokens.css:365`; published CSS has same selectors in `priv/static/oban_powertools/oban_powertools.css:365`; `cmp` returned `0`; source guard rejects host/theme mutation in `test/oban_powertools/web/components/forms_test.exs:423`. |
| T-75-02-06 | 75-02 misleading ARIA combobox | Spoofing | mitigate | closed | `role`, `aria-expanded`, `aria-controls`, and `aria-activedescendant` are filtered in `lib/oban_powertools/web/components/forms.ex:321`; render/browser checks at `test/oban_powertools/web/components/forms_test.exs:216` and `test/browser/specs/forms.behavior.spec.ts:251`. |
| T-75-03-01 | 75-03 story input XSS | XSS | mitigate | closed | Long-content story carries hostile text as data in `test/support/form_story_catalog.ex:126`; showcase renders it through `Forms.textarea` in `lib/oban_powertools/web/dev/showcase_live.ex:585`; component escaping test at `test/oban_powertools/web/components/forms_test.exs:408`. |
| T-75-03-02 | 75-03 production exposure of dev catalog | Information Disclosure | mitigate | closed | Showcase module is guarded by `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)` in `lib/oban_powertools/web/dev/showcase_live.ex:1`; form catalog loading is runtime-gated in `:384`. |
| T-75-03-03 | 75-03 selector/metadata injection | Tampering | mitigate | closed | Catalog derives stable `story`, `snapshot`, and `a11y` targets in `test/support/form_story_catalog.ex:146`; tests enforce slug ids and derived targets in `test/oban_powertools/form_story_catalog_test.exs:15` and `:26`. |
| T-75-03-04 | 75-03 story implies unsupported action | Spoofing | mitigate | closed | Catalog tests define forbidden deferred behavior terms in `test/oban_powertools/form_story_catalog_test.exs:13` and reject them from components/metadata in `:40`. |
| T-75-03-05 | 75-03 misleading disabled/pending UI | Spoofing | mitigate | closed | Story renders disabled switch/select and readonly input with explanations in `lib/oban_powertools/web/dev/showcase_live.ex:573`; CSS distinguishes disabled/read-only in `assets/oban_powertools/tokens.css:472`; browser checks pending and disabled/read-only behavior in `test/browser/specs/forms.behavior.spec.ts:184` and `:223`. |
| T-75-04-01 | 75-04 manifest tampering/path traversal | Tampering | mitigate | closed | Form stories are serialized from `FormStoryCatalog` in `scripts/showcase_manifest.exs:58`; TS validator enforces `form-*` slugs and derived `story`/`snapshot`/`a11y` in `test/browser/support/manifest.ts:297`; smoke validator repeats those checks in `test/browser/support/manifest-smoke.mjs:136`. |
| T-75-04-02 | 75-04 omitted form targets overstate coverage | Repudiation | mitigate | closed | Generator appends `form_stories` to unified `targets` in `scripts/showcase_manifest.exs:79`; TS validator enforces nine form stories, expected target length, ordering, and equality in `test/browser/support/manifest.ts:191`; smoke validator mirrors exact target equality in `test/browser/support/manifest-smoke.mjs:163`. |
| T-75-04-03 | 75-04 selector injection scans wrong DOM | Tampering | mitigate | closed | Derived a11y selectors are checked in `test/browser/support/manifest.ts:322`; runtime structure asserts each generated target resolves exactly once and form metadata matches in `test/browser/support/showcase.ts:108`. |
| T-75-04-04 | 75-04 hardcoded browser list drifts | Repudiation | mitigate | closed | Structure, VRT, and axe specs import and iterate generated `targets` in `test/browser/specs/showcase.structure.spec.ts:1`, `test/browser/specs/showcase.vrt.spec.ts:1`, and `test/browser/specs/showcase.a11y.spec.ts:1`; manifest exports `formStories`/`targets` in `test/browser/support/manifest.ts:386`. |
| T-75-04-05 | 75-04 crafted ARIA metadata masks semantics | Spoofing | mitigate | closed | Axe runs against each generated `target.a11y` in `test/browser/specs/showcase.a11y.spec.ts:7`; independent component behavior tests use generated `formStories` and direct control locators in `test/browser/specs/forms.behavior.spec.ts:2` and `:94`. |
| T-75-05-01 | 75-05 keyboard trap or inaccessible control | Denial of Service | mitigate | closed | Browser tests cover label activation, radio arrow movement, switch Space/click, and focus visibility in `test/browser/specs/forms.behavior.spec.ts:50`, `:74`, `:184`, `:270`; focus CSS exists in `assets/oban_powertools/tokens.css:454`. |
| T-75-05-02 | 75-05 hidden checkbox value corrupts selection | Tampering | mitigate | closed | Native `FormData` browser proof starts at `test/browser/specs/forms.behavior.spec.ts:137`; ExUnit contracts distinguish named boolean/event/blank/nil modes in `test/oban_powertools/web/components/forms_test.exs:239`, `:260`, `:289`. |
| T-75-05-03 | 75-05 misleading disabled/read-only/pending state | Spoofing | mitigate | closed | Browser tests cover pending switch and disabled/readonly behavior in `test/browser/specs/forms.behavior.spec.ts:184` and `:223`; CSS distinguishes state treatments in `assets/oban_powertools/tokens.css:472`. |
| T-75-05-04 | 75-05 fake combobox spoofing | Spoofing | mitigate | closed | Filter-ready browser test rejects popup ARIA on native search/select controls in `test/browser/specs/forms.behavior.spec.ts:251`; component rest filtering drops popup ARIA in `lib/oban_powertools/web/components/forms.ex:321`. |
| T-75-05-05 | 75-05 baseline tampering/broad masking | Tampering | mitigate | closed | `vrt:update` and `visual:a11y` use Docker-pinned Playwright in `package.json:6`; VRT spec screenshots each generated target without masks in `test/browser/specs/showcase.vrt.spec.ts:6`; filesystem audit found 108 form PNGs under 27 form target directories. |
| T-75-05-06 | 75-05 overclaimed accessibility | Repudiation | mitigate | closed | Browser evidence is scoped to generated showcase/form targets in `test/browser/specs/forms.behavior.spec.ts:2`; axe spec runs automated critical/serious checks per target in `test/browser/specs/showcase.a11y.spec.ts:7`; page/manual claims remain outside code evidence and are not asserted by these specs. |
| T-75-06-01 | 75-06 switch visible state | Spoofing | mitigate | closed | `switch/1` renders both Off/On labels in `lib/oban_powertools/web/components/forms.ex:197`; CSS toggles visibility from native `:checked` state in `assets/oban_powertools/tokens.css:563` and published CSS at `priv/static/oban_powertools/oban_powertools.css:563`; browser toggles both directions in `test/browser/specs/forms.behavior.spec.ts:184`. |
| T-75-06-02 | 75-06 disabled hidden unchecked inputs | Tampering | mitigate | closed | Checkbox and switch hidden false inputs include `disabled={@disabled}` in `lib/oban_powertools/web/components/forms.ex:127` and `:190`; render tests at `test/oban_powertools/web/components/forms_test.exs:327`; browser markup assertion in `test/browser/specs/forms.behavior.spec.ts:184`. |
| T-75-06-03 | 75-06 duplicate error ids/incomplete descriptions | Information Disclosure | mitigate | closed | Multi-error ids are indexed in `lib/oban_powertools/web/components/forms.ex:297`; all generated ids merge into `aria-describedby` in `:291`; ExUnit coverage at `test/oban_powertools/web/components/forms_test.exs:89`; browser duplicate-id and association test at `test/browser/specs/forms.behavior.spec.ts:94`. |
| T-75-06-04 | 75-06 caller attrs and form text | Tampering | mitigate | closed | `visual_safe_rest/1` preserves filtering in `lib/oban_powertools/web/components/forms.ex:321`; HEEx-only label/hint/error rendering at `:241`, `:248`, `:252`; post-review event-selection logic is present in `prepare_choice/2` at `:254`; commits `c18e659` and `bf26f1d` are present and touched the expected files. |
| T-75-06-05 | 75-06 aggregate visual gate residuals | Denial of Service | accept | closed | Accepted risk documented below. Residual is scenario-only: `75-06-SUMMARY.md:114` states all form behavior, form axe, and form VRT targets passed after scoped refresh. |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---|---|---|---|---|
| AR-75-01 | T-75-06-05 | The aggregate `npm run visual:a11y` gate still fails on non-form scenario VRT drift outside the Phase 75 form surface. The Phase 75 form targets have scoped behavior, axe, and Docker VRT evidence, and unrelated scenario baselines were intentionally not changed in this phase. | Plan-time disposition in `75-06-PLAN.md`; verified/documented by this security audit | 2026-07-11 |

## Unregistered Flags

None. `75-01-SUMMARY.md:90` and `75-06-SUMMARY.md:124` explicitly report no threat flags. The scenario-only VRT residual is mapped to accepted risk `T-75-06-05`, not treated as unregistered Phase 75 form attack surface.

## Post-Review Native FormData Leakage Check

| Check | Evidence | Status |
|---|---|---|
| Commit `c18e659` present | `git show --stat --oneline c18e659` reports `fix(75-06): isolate event selection form data`, touching `forms.ex`, `forms.behavior.spec.ts`, and `forms_test.exs`. | closed |
| Commit `bf26f1d` present | `git show --stat --oneline bf26f1d` reports `fix(75-06): guard blank choice event wiring`, touching `forms.ex` and `forms_test.exs`. | closed |
| Native `FormData` cannot leak event selection | Browser test constructs real `FormData` from rendered story in `test/browser/specs/forms.behavior.spec.ts:137` and asserts the event-selection checkbox has no `name`/hidden fallback. | closed |
| Blank/nil `phx-click` does not disable named boolean submission | Current code uses `present_text(Map.get(assigns.rest, "phx-click"))` in `lib/oban_powertools/web/components/forms.ex:258`; tests cover nil, blank, and blank explicit name in `test/oban_powertools/web/components/forms_test.exs:289`. | closed |

## Audit Trail

| Audit Date | Threats Total | Closed | Open | Accepted | Run By |
|---|---:|---:|---:|---:|---|
| 2026-07-11T19:39:11Z | 32 | 32 | 0 | 1 | Codex security audit |

## Sign-Off

- [x] All plan-time threats have a disposition.
- [x] All `mitigate` threats have implementation/test/CSS evidence.
- [x] Accepted risk `T-75-06-05` is documented.
- [x] Summary threat flags incorporated; no unregistered flags remain.
- [x] `threats_open: 0` confirmed.

**Approval:** secured 2026-07-11
