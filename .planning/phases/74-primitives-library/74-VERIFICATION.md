---
phase: 74-primitives-library
verified: 2026-07-11T15:13:39Z
status: passed
score: "18/18 must-haves verified"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 74: Primitives Library Verification Report

**Phase Goal:** Build the token-driven primitive components and register them as showcase stories under VRT/a11y.
**Verified:** 2026-07-11T15:13:39Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

Phase 74 is achieved. The codebase contains a substantive Phoenix primitive component module, token-backed primitive CSS and tooltip JS, real primitive showcase stories, generated manifest integration, tracked primitive VRT baselines, and browser/ExUnit gates covering the primitive story targets.

Phase 74 proves the primitive-level automated accessibility and motion contract. The full system-wide manual screen-reader/page traversal/a11y sweep remains explicitly owned by Phase 82, not a Phase 74 gap.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Roadmap SC1: Button, Icon button, Link, Badge/Tag/StatusPill, Card/Surface, Divider, Spinner/Skeleton, Tooltip, Kbd, and Stat ship as Phoenix.Component primitives, tokens-only, with documented attrs/slots. | VERIFIED | `lib/oban_powertools/web/components/primitives.ex:10` uses `Phoenix.Component`; public functions span `button/1` through `stat/1`; docs/attrs/slots are present before each component. CSS classes resolve in `assets/oban_powertools/tokens.css:506-903`. |
| 2 | Roadmap SC2: Each primitive is keyboard-operable, screen-reader-correct at the primitive automated scope, renders in all themes and at 320px, has showcase stories, and passes VRT/a11y gates. | VERIFIED | `test/browser/specs/primitives.behavior.spec.ts` covers accessible names, focus, tooltip Escape, 320px overflow, and reduced motion. `npm run visual:a11y:host -- --list` enumerated 420 browser tests with 192 primitive-target tests and 24 primitive behavior tests. Orchestrator final gate evidence: `npm run visual:a11y` passed 420 browser tests. |
| 3 | Roadmap SC3: No raw hex/px in primitive source. | VERIFIED | `test/oban_powertools/web/components/primitives_test.exs:327-345` rejects raw color/px in `primitives.ex`; independent `rg` found no raw hex/px in primitive module/showcase/manifest/browser source. Token CSS has palette tokens and allowed `1px solid var(--obpt-...)` border literals guarded by `theme_tokens_test.exs:168-203` and `:362-364`. |
| 4 | Primitives exist as stateless Phoenix.Component function components per D-01/D-02. | VERIFIED | `primitives.ex:1-10` module is stateless component module; no LiveComponent/state ownership added. `mix test ...primitives_test.exs...` passed. |
| 5 | Primitive attrs, slots, defaults, and closed variants are documented in source per COMP-01/COMP-02. | VERIFIED | `@doc`, `attr`, `slot`, closed value lists (`@button_variants`, `@tones`, `@surface_variants`) are in `primitives.ex:13-32`, `:85-98`, `:190-254`, and later component declarations. |
| 6 | Rest attrs preserve caller identity/ARIA/data/native behavior while blocking visual escape hatches and suppressing disabled-with-reason actions. | VERIFIED | `visual_safe_rest/2` drops `class`/`style` and action attrs when requested at `primitives.ex:499-518`; render tests at `primitives_test.exs:75-140` verify preservation and suppression. |
| 7 | Primitive classes resolve under `.obpt-root` using only token variables and token-backed classes. | VERIFIED | `assets/oban_powertools/tokens.css:506-903` defines primitive classes under `.obpt-root`; static guard `theme_tokens_test.exs:168-203` checks scoping, raw color rejection, and token-backed visual declarations. |
| 8 | Tooltip Escape behavior is dependency-free and scoped to Powertools roots. | VERIFIED | `assets/oban_powertools/theme.js:6-15` defines scoped tooltip attrs/selectors; behavior remains in existing asset IIFE and is tested by `primitives.behavior.spec.ts:120-149`. |
| 9 | Compiled CSS/JS assets stay byte-stable after primitive styling and behavior are added. | VERIFIED | `priv/static/oban_powertools/oban_powertools.css` and `.js` include primitive CSS/tooltip JS; `assets_test.exs:50-95` defines repeated-build byte-stability and compiled-content checks. Orchestrator evidence: `mix test --exclude host_contract && mix compile --warnings-as-errors` passed. |
| 10 | Primitive stories are registered separately from domain stress scenarios. | VERIFIED | `test/support/primitive_story_catalog.ex` defines `ObanPowertools.PrimitiveStoryCatalog`; `primitive_story_catalog_test.exs:67-73` asserts separation from `ShowcaseCatalog.scenarios/0`. |
| 11 | The dev-only showcase renders real primitive story cells in the existing `primitives` section. | VERIFIED | `showcase_live.ex:178-210` renders `data-obpt-primitive-story` cells; `showcase_live.ex:404-490` renders real primitive components for each story. |
| 12 | Every primitive named in COMP-01 appears in at least one primitive story target. | VERIFIED | `primitive_story_catalog_test.exs:140-151` checks primitive coverage metadata; seven story ids are present in `primitive_story_catalog.ex:12-184`. |
| 13 | Playwright manifest is generated from both stress scenarios and primitive stories. | VERIFIED | `scripts/showcase_manifest.exs:19-68` loads `ShowcaseCatalog` and `PrimitiveStoryCatalog`, emits schema v2 `scenarios`, `primitive_stories`, and `targets`; current generated manifest has 9 scenarios, 7 primitive stories, and 16 targets. |
| 14 | VRT and axe specs iterate unified targets instead of hardcoded primitive arrays. | VERIFIED | `showcase.vrt.spec.ts:6-15` and `showcase.a11y.spec.ts:7-19` loop over `targets`; `showcase.ts:77-124` validates both scenario and primitive target DOM. |
| 15 | Scenario manifest compatibility is preserved while primitives join the same theme and viewport matrix. | VERIFIED | `manifest.ts:90-116` preserves 9 scenarios; `manifest.ts:118-183` validates 7 primitives; `manifest.ts:185-235` validates unified `targets`. Manifest smoke passed with 4 themes and 3 viewports. |
| 16 | Primitive behavior checks prove labels, focus, tooltip Escape, 320px overflow, and reduced-motion behavior beyond axe. | VERIFIED | `primitives.behavior.spec.ts:66-199` directly exercises these behaviors; Playwright enumeration includes 24 primitive behavior tests. Orchestrator targeted browser checks passed on chromium-320 and chromium-wide. |
| 17 | Committed primitive PNG baselines exist for every primitive target across all existing themes and viewports. | VERIFIED | `git ls-files test/browser/__screenshots__ | rg '/showcase/primitive-.+\\.png$'` counted 84 tracked primitive PNGs: 7 stories x 3 viewports x 4 themes. |
| 18 | The full `npm run visual:a11y` gate passes with primitive stories included. | VERIFIED | Orchestrator final evidence: `npm run visual:a11y` passed 420 browser tests. Independent enumeration confirmed the gate includes primitive story VRT/a11y/behavior coverage. |

**Score:** 18/18 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/oban_powertools/web/components/primitives.ex` | Phoenix primitive component module | VERIFIED | Exists, 640 lines, exports all COMP-01 functions, substantive render logic and source guards. |
| `test/oban_powertools/web/components/primitives_test.exs` | Render/API/static primitive contract tests | VERIFIED | Exists, 397 lines; focused ExUnit run passed with primitive/static coverage. |
| `assets/oban_powertools/tokens.css` | Primitive token CSS classes | VERIFIED | Exists, 1277 lines; primitive classes root-scoped and token-backed. |
| `assets/oban_powertools/theme.js` | Tooltip Escape/focus behavior | VERIFIED | Exists, 207 lines; scoped tooltip behavior uses `data-obpt-tooltip-*`. |
| `priv/static/oban_powertools/oban_powertools.css` | Compiled primitive CSS asset | VERIFIED | Exists and includes primitive selectors matching source CSS. |
| `priv/static/oban_powertools/oban_powertools.js` | Compiled primitive JS asset | VERIFIED | Exists and includes tooltip selectors/state attrs. |
| `test/support/primitive_story_catalog.ex` | Primitive story registry | VERIFIED | Exists, 211 lines; seven deterministic primitive story ids. |
| `test/oban_powertools/primitive_story_catalog_test.exs` | Primitive story metadata tests | VERIFIED | Exists; included in passing focused ExUnit run. |
| `lib/oban_powertools/web/dev/showcase_live.ex` | Showcase primitive story rendering | VERIFIED | Loads primitive catalog and renders real primitive component story bodies. |
| `scripts/showcase_manifest.exs` | Schema v2 generated manifest | VERIFIED | Emits `scenarios`, `primitive_stories`, and unified `targets`. |
| `test/browser/support/manifest.ts` | Typed manifest validation and exports | VERIFIED | Validates schema v2 and exports `scenarios`, `primitiveStories`, `targets`, `themes`, `viewports`. |
| `test/browser/support/showcase.ts` | Target locator and structure assertions | VERIFIED | `targetLocator` and `assertShowcaseStructure` cover scenario and primitive targets. |
| `test/browser/specs/showcase.vrt.spec.ts` | Unified target VRT loop | VERIFIED | Loops over `targets` and uses target snapshot metadata. |
| `test/browser/specs/showcase.a11y.spec.ts` | Unified target axe loop | VERIFIED | Loops over `targets` and writes target-kind result names. |
| `test/browser/specs/primitives.behavior.spec.ts` | Targeted primitive browser behavior checks | VERIFIED | Exists, 200 lines; covers names/focus/tooltip/overflow/reduced motion. |
| `test/browser/__screenshots__/chromium-*/showcase/primitive-*/*.png` | Primitive VRT baselines | VERIFIED | 84 tracked PNGs across seven stories, three viewports, four themes. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `primitives_test.exs` | `primitives.ex` | Phoenix component render tests | WIRED | Tests import/capture `ObanPowertools.Web.Components.Primitives` and render each primitive. |
| `primitives.ex` | `tokens.css` | Owned `.obpt-*` classes and `data-obpt-*` attrs | WIRED | Component classes (`obpt-button`, `obpt-icon-button`, etc.) have matching root-scoped CSS. |
| `theme.js` | `tokens.css` | `data-obpt-tooltip-*` attributes | WIRED | JS toggles tooltip state attrs consumed by CSS selectors at `tokens.css:824-826`. |
| `PrimitiveStoryCatalog` | `ShowcaseLive` | Runtime dev/test catalog load | WIRED | `showcase_live.ex:21-73` loads primitive catalog; `:178-210` renders story cells. |
| `ShowcaseLive` | `Primitives` | Phoenix component alias and story bodies | WIRED | `showcase_live.ex:17` aliases primitives; `:404-490` renders each primitive story. |
| `PrimitiveStoryCatalog` | `showcase_manifest.exs` | Elixir manifest generation | WIRED | `showcase_manifest.exs:36-55` maps primitive stories into manifest rows. |
| `showcase_manifest.exs` | `manifest.ts` | `test/browser/.generated/showcase-manifest.json` | WIRED | Existing generated manifest validates via `manifest-smoke.mjs`. |
| `manifest.ts` | VRT/a11y/structure specs | Exported `targets` | WIRED | Specs import `targets` and loop over unified scenario/primitive target list. |
| `showcase.vrt.spec.ts` | PNG baselines | `toHaveScreenshot([target.snapshot, theme.png])` | WIRED | Tracked PNG count matches target matrix: 84 primitive screenshots. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `ShowcaseLive` | `@primitive_stories` | `load_primitive_catalog()` -> `PrimitiveStoryCatalog.stories/0` | Yes, seven story maps | FLOWING |
| `PrimitiveStoryCatalog` | `stories/0` | Static dev/test registry with coverage/test target metadata | Yes, seven real primitive stories | FLOWING |
| `showcase_manifest.exs` | `primitive_stories`, `targets` | `PrimitiveStoryCatalog.stories/0` plus `ShowcaseCatalog.scenarios/0` | Yes, 7 primitives + 9 scenarios | FLOWING |
| `manifest.ts` | `primitiveStories`, `targets` | Generated JSON at `test/browser/.generated/showcase-manifest.json` | Yes, runtime-validated schema v2 | FLOWING |
| Browser specs | `targets` | `manifest.ts` exports | Yes, structure/VRT/axe loop over generated targets | FLOWING |
| VRT baselines | `target.snapshot` | Manifest target snapshot metadata | Yes, 84 tracked primitive PNGs | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Manifest validates primitive stories and unified targets | `node test/browser/support/manifest-smoke.mjs` | `showcase manifest ok: 9 scenarios, 7 primitive stories, 16 targets, 4 themes, 3 viewports` | PASS |
| Primitive component, story catalog, showcase, and token static guards pass | `mix test test/oban_powertools/web/components/primitives_test.exs test/oban_powertools/primitive_story_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/theme_tokens_test.exs` | 32 tests, 0 failures | PASS |
| Browser gate includes primitive targets without starting the server | `npm run visual:a11y:host -- --list` summarized by Node | 420 tests listed; 192 primitive-target tests; 24 primitive behavior tests | PASS |
| Code compiles warning-free | `mix compile --warnings-as-errors` | exit 0 | PASS |
| Full visual/a11y gate after final fixes | Orchestrator evidence: `npm run visual:a11y` | 420 browser tests passed | PASS |
| Full ExUnit + compile gate after final fixes | Orchestrator evidence: `mix test --exclude host_contract && mix compile --warnings-as-errors` | 638 tests, 0 failures, 7 excluded; compile warnings-as-errors passed | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| None discovered | `find scripts -path '*/tests/probe-*.sh' -type f` | No phase-declared or conventional probe scripts found | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| COMP-01 | 74-01, 74-03 | Documented Phoenix.Component primitives exist. | SATISFIED | `primitives.ex` exports all COMP-01 primitives; story catalog covers all primitive names. |
| COMP-02 | 74-01, 74-02 | Documented attrs/slots/defaults and token-only rendering. | SATISFIED | Source docs/attrs/slots present; `theme_tokens_test.exs` verifies root-scoped token-backed primitive CSS. |
| COMP-03 | 74-01, 74-02, 74-05 | Keyboard-operable and screen-reader-correct primitive semantics. | SATISFIED | Required labels/loading context/ARIA in components; Playwright behavior spec covers focus, names, tooltip, disabled and reduced-motion behaviors. |
| COMP-04 | 74-02, 74-03, 74-04, 74-05 | Themes, 320px, and showcase stories per state. | SATISFIED | Manifest has 4 themes, 3 viewports, 7 primitive stories; 84 tracked primitive baselines. |
| MOTION-02 | 74-02, 74-05 | Reduced-motion-safe primitive transitions/loading. | SATISFIED | CSS reduced-motion rules at `tokens.css:940-956`; browser behavior test verifies spinner/skeleton remain visible with no animation. |
| A11Y-02 | 74-01..74-05 | Keyboard reachability/operability, visible focus, non-color status channels at primitive scope. | SATISFIED | API semantics, focus CSS, behavior spec, axe/VRT gate coverage. System-wide manual sweep remains Phase 82. |
| SHOW-01 (primitive stories) | 74-03, 74-04, 74-05 | Dev-only showcase renders primitive stories under VRT/a11y. | SATISFIED | `_showcase` guarded by `compile_env`; primitive stories render in `data-obpt-section="primitives"` and join manifest targets. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `lib/oban_powertools/web/dev/showcase_live.ex` | 213 | Primitive catalog unavailable fallback placeholder | INFO | Defensive fallback only; tests assert the primitive section does not render placeholder when catalog is available. |
| `lib/oban_powertools/web/dev/showcase_live.ex` | 218 | Reserved placeholder for future non-primitive sections | INFO | Existing showcase scaffold for later phases; not part of primitive story targets. |
| `lib/oban_powertools/web/dev/showcase_live.ex` | 276 | Stress fixture catalog unavailable fallback | INFO | Defensive existing fallback; unrelated to primitive implementation. |
| Phase files scanned | - | `TBD`/`FIXME`/`XXX` debt markers | NONE | No blocker debt markers found in modified implementation/test files. |

### Human Verification Required

None. Behavior-dependent Phase 74 truths are covered by automated behavioral tests and the final browser gate. Full manual SR/page traversal and system-wide a11y/motion hardening are explicitly deferred to Phase 82 by roadmap and Phase 74 context.

### Gaps Summary

No blocking gaps found. All roadmap success criteria and plan must-haves are verified against code, tests, generated manifest data, tracked baselines, and gate evidence.

---

_Verified: 2026-07-11T15:13:39Z_
_Verifier: the agent (gsd-verifier)_
