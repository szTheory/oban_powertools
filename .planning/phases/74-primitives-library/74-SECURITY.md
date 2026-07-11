---
phase: 74
slug: primitives-library
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-11
---

# Phase 74 - Security

Per-phase security contract: plan-time threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| caller LiveView to primitive component | Parent code passes attrs, slots, labels, IDs, and rest attrs into shared primitives. | UI attrs, LiveView attrs, labels, slot content |
| primitive component to browser DOM | HEEx-rendered primitive markup becomes operator-facing controls and metadata. | HTML attributes, accessible names, status text |
| primitive source to token CSS/static assets | Component-owned class names resolve through scoped `.obpt-root` token CSS and packaged static assets. | CSS selectors, token variables, compiled CSS/JS |
| browser events to tooltip behavior | Keyboard, pointer, and focus events affect tooltip open/dismiss state. | DOM events, `data-obpt-tooltip-*` state |
| test support catalog to dev showcase | Dev/test story metadata is loaded into the dev-only showcase LiveView. | Synthetic story metadata and copy |
| dev-only route to host app | `_showcase` and `_brand_book` must remain absent unless dev routes are enabled. | Host router route table |
| Elixir manifest to TypeScript/browser specs | Generated JSON drives Playwright structure, VRT, and axe target selection. | Manifest schema, target IDs, selectors, snapshot paths |
| browser automation to reviewer trust | Browser tests and PNG baselines become regression evidence. | Playwright assertions, axe JSON, screenshot baselines |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status | Evidence |
|-----------|----------|-----------|-------------|------------|--------|----------|
| T-74-01 | Tampering | `attr :rest, :global` passthrough | mitigate | Filter caller visual attrs in `visual_safe_rest/2`; tests prove hostile visual attrs are absent while allowed attrs remain. | closed | `lib/oban_powertools/web/components/primitives.ex:499`; `test/oban_powertools/web/components/primitives_test.exs:75` |
| T-74-02 | Spoofing/Tampering | `link/1` and `button/1` semantics | mitigate | `link/1` requires a navigation target and suppresses action attrs; disabled-with-reason buttons force `type="button"` and suppress actions. | closed | `lib/oban_powertools/web/components/primitives.ex:153`; `lib/oban_powertools/web/components/primitives.ex:556`; `test/oban_powertools/web/components/primitives_test.exs:175` |
| T-74-03 | Information Disclosure | icon/loading/status primitives | mitigate | Required icon labels and named loading/status text are implemented; decorative icon content is hidden. | closed | `lib/oban_powertools/web/components/primitives.ex:85`; `lib/oban_powertools/web/components/primitives.ex:353`; `test/browser/specs/primitives.behavior.spec.ts:67` |
| T-74-04 | Tampering/XSS | slots and story text rendered through primitives | mitigate | Components render with HEEx interpolation/render slots and no raw HTML injection API in primitives/showcase/story catalog. | closed | `lib/oban_powertools/web/components/primitives.ex:66`; `lib/oban_powertools/web/components/primitives.ex:424`; `rg Phoenix.HTML.raw/raw` no matches in primitive/showcase/catalog files |
| T-74-05 | Tampering | primitive CSS source | mitigate | Primitive CSS is `.obpt-root` scoped and token-backed; tests reject host selectors and raw primitive visual values. | closed | `assets/oban_powertools/tokens.css:506`; `test/oban_powertools/web/theme_tokens_test.exs:168` |
| T-74-06 | Denial of Service | tooltip keyboard behavior | mitigate | Escape only mutates scoped tooltip state and returns focus to the trigger; browser behavior test verifies dismissal and focus retention. | closed | `assets/oban_powertools/theme.js:181`; `test/browser/specs/primitives.behavior.spec.ts:120` |
| T-74-07 | Tampering | compiled assets | mitigate | Asset test reruns the build task twice and compares static SHA-256 maps; compiled assets include primitive CSS/tooltip JS. | closed | `test/oban_powertools/web/assets_test.exs:50`; `test/oban_powertools/web/assets_test.exs:63` |
| T-74-08 | Spoofing | focus/hover styling | mitigate | Tokenized disabled/status/focus channels are present; browser tests verify visible focus across themes. | closed | `assets/oban_powertools/tokens.css:566`; `assets/oban_powertools/tokens.css:661`; `test/browser/specs/primitives.behavior.spec.ts:87` |
| T-74-09 | Tampering | primitive story registry | mitigate | Primitive story catalog is deterministic, has unique derived targets, and stays separate from `ShowcaseCatalog.scenarios/0`. | closed | `test/support/primitive_story_catalog.ex:1`; `test/oban_powertools/primitive_story_catalog_test.exs:47` |
| T-74-10 | Information Disclosure/XSS | story copy and slots | mitigate | Synthetic story copy is rendered through HEEx interpolation; no raw HTML story fields or raw rendering exist in showcase/catalog files. | closed | `lib/oban_powertools/web/dev/showcase_live.ex:191`; `test/support/primitive_story_catalog.ex:10`; `rg Phoenix.HTML.raw/raw` no matches in showcase/catalog files |
| T-74-11 | Elevation of Privilege | dev-only showcase route | mitigate | Showcase module and router route are both gated by `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)`. | closed | `lib/oban_powertools/web/dev/showcase_live.ex:1`; `lib/oban_powertools/web/router.ex:73` |
| T-74-12 | Spoofing | inert danger examples | mitigate | Danger examples render through primitives; disabled-with-reason action attrs are suppressed and no `cancel` handler/mutation path exists in the showcase. | closed | `lib/oban_powertools/web/dev/showcase_live.ex:414`; `lib/oban_powertools/web/components/primitives.ex:499`; `lib/oban_powertools/web/dev/showcase_live.ex:77` |
| T-74-13 | Tampering | generated manifest | mitigate | Manifest generator emits schema v2 primitive stories/targets; TypeScript validators assert schema, IDs, selectors, counts, and provenance. | closed | `scripts/showcase_manifest.exs:36`; `test/browser/support/manifest.ts:118`; `test/browser/support/manifest.ts:185` |
| T-74-14 | Repudiation | screenshot and axe target provenance | mitigate | Generated target metadata carries kind/id/snapshot/a11y fields; VRT and axe result names include target provenance. | closed | `test/browser/support/manifest.ts:198`; `test/browser/specs/showcase.vrt.spec.ts:8`; `test/browser/specs/showcase.a11y.spec.ts:10` |
| T-74-15 | Denial of Service | browser matrix growth | accept | Accepted bounded matrix growth: 7 primitive targets joined the existing 4-theme by 3-viewport matrix. | closed | Accepted risk `AR-74-15` |
| T-74-16 | Tampering | hardcoded TS primitive lists | mitigate | Browser structure, VRT, and axe specs consume generated `targets`; no standalone primitive target list exists in those specs. | closed | `test/browser/support/manifest.ts:328`; `test/browser/specs/showcase.structure.spec.ts:13`; `test/browser/specs/showcase.vrt.spec.ts:8`; `test/browser/specs/showcase.a11y.spec.ts:9` |
| T-74-17 | Denial of Service | tooltip/focus behavior | mitigate | Playwright verifies tooltip focus open, Escape dismissal, focus retention, and renewed hover behavior. | closed | `test/browser/specs/primitives.behavior.spec.ts:120` |
| T-74-18 | Information Disclosure/Usability | unlabeled icon/loading controls | mitigate | Playwright verifies icon-button accessible names and named loading status regions. | closed | `test/browser/specs/primitives.behavior.spec.ts:67`; `test/browser/specs/primitives.behavior.spec.ts:169` |
| T-74-19 | Repudiation | baseline changes | mitigate | Existing VRT workflow is wired; primitive baseline set contains 84 PNGs and report/generated artifacts are not present in git status. | closed | `package.json:9`; `test/browser/__screenshots__/chromium-*/showcase/primitive-*/*.png` count: 84; `git status --short test/browser/.generated playwright-report test-results` no output |
| T-74-20 | Tampering | broad visual masks | mitigate | VRT uses unmasked `toHaveScreenshot` for every generated target; grep found no `mask` usage in browser specs/support. | closed | `test/browser/specs/showcase.vrt.spec.ts:15`; `rg mask test/browser/specs test/browser/support` no matches |
| T-74-21 | Spoofing | overclaimed a11y proof | mitigate | Plan and summary state that Phase 74 proves primitive-level automated checks only and Phase 82 owns full manual SR/page traversal. | closed | `74-05-PLAN.md:180`; `74-VALIDATION.md:53`; `74-05-SUMMARY.md:110` |
| T-74-SC | Tampering | package installs across plans 01-05 | accept | Plan-time accepted risk: no Phase 74 package-manager install task was declared; existing browser dependencies are reused. | closed | Accepted risk `AR-74-SC` |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-74-15 | T-74-15 | Seven primitive targets add bounded coverage to the existing 4-theme by 3-viewport browser matrix; no unbounded dynamic target generation is present. | Phase 74 plan-time threat model | 2026-07-11 |
| AR-74-SC | T-74-SC | The package legitimacy checkpoint was accepted because Phase 74 did not declare package-manager install work; existing npm/Hex dependencies are reused. | Phase 74 plan-time threat model | 2026-07-11 |

## Unregistered Flags

None. All five summary `## Threat Flags` sections reported no unmapped threat flags:

- `74-01-SUMMARY.md:94`
- `74-02-SUMMARY.md:97`
- `74-03-SUMMARY.md:102`
- `74-04-SUMMARY.md:105`
- `74-05-SUMMARY.md:106`

## Open Threats

None.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-11 | 22 | 21 | 1 | Codex security auditor |
| 2026-07-11 | 22 | 22 | 0 | Codex security auditor re-run for T-74-21 |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-11
