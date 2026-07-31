---
phase: 74
slug: primitives-library
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-10
---

# Phase 74 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5; Playwright Test 1.61.0; axe-core 4.11.4 |
| Config file | `mix.exs`, `playwright.config.ts`, `test/browser/support/axe.ts` |
| Quick run command | `mix test test/oban_powertools/web/components/primitives_test.exs test/oban_powertools/web/live/showcase_live_test.exs` |
| Full suite command | `npm run visual:a11y && mix test --exclude host_contract` |
| Estimated runtime | Quick: local ExUnit subset; Full: browser VRT/a11y plus full non-host-contract ExUnit suite |

## Sampling Rate

- After every task commit: run `mix test test/oban_powertools/web/components/primitives_test.exs test/oban_powertools/web/live/showcase_live_test.exs`
- After every plan wave: run `npm run visual:a11y`
- Before `/gsd:verify-work`: run `npm run visual:a11y && mix test --exclude host_contract && mix compile --warnings-as-errors`
- Max feedback latency: one task commit between automated checks

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 74-01-01 | 01 | 1 | COMP-01, COMP-02, COMP-03, A11Y-02 | T-74-01 | Closed component API and hostile-rest-attr contract | unit/static | `mix test test/oban_powertools/web/components/primitives_test.exs` | Yes | green |
| 74-01-02 | 01 | 1 | COMP-01, COMP-02, COMP-03, A11Y-02 | T-74-01 | Stateless Phoenix.Component implementation matches contract | unit/compile | primitive component suite plus warnings-as-errors compile | Yes | green |
| 74-02-01 | 02 | 2 | COMP-02..04, MOTION-02, A11Y-02 | T-74-01 | Primitive CSS is root-scoped and token-backed | unit/static | primitive and theme-token suites | Yes | green |
| 74-02-02 | 02 | 2 | COMP-03, COMP-04, MOTION-02, A11Y-02 | T-74-02 | Tooltip behavior is scoped and compiled assets deterministic | unit/build | component, token, asset, and repeated-build suites | Yes | green |
| 74-03-01 | 03 | 3 | COMP-01, COMP-04, A11Y-02, SHOW-01 | - | Primitive catalog is deterministic and separate | unit/static | `mix test test/oban_powertools/primitive_story_catalog_test.exs` | Yes | green |
| 74-03-02 | 03 | 3 | COMP-01, COMP-04, A11Y-02, SHOW-01 | - | Showcase renders real primitive stories | unit/LiveView | catalog, component, and showcase suites | Yes | green |
| 74-04-01 | 04 | 4 | COMP-04, A11Y-02, SHOW-01 | - | Manifest derives primitive targets from Elixir catalogs | static/integration | `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` | Yes | green |
| 74-04-02 | 04 | 4 | COMP-04, A11Y-02, SHOW-01 | - | Structure, VRT, and axe consume unified targets | browser/static | current manifest validation plus tracked baseline inventory | Yes | green |
| 74-05-01 | 05 | 5 | COMP-03, COMP-04, MOTION-02, A11Y-02, SHOW-01 | T-74-02 | Labels, focus, tooltip Escape, 320px overflow, and reduced motion | browser | `npm run visual:a11y -- test/browser/specs/primitives.behavior.spec.ts` | Yes | green |
| 74-05-02 | 05 | 5 | COMP-04, MOTION-02, A11Y-02, SHOW-01 | - | All primitive theme/viewport baselines are tracked | VRT/static | tracked primitive baseline inventory plus unified VRT harness | Yes | green |

## Wave 0 Requirements

- [x] `test/oban_powertools/web/components/primitives_test.exs` - render/API/no-raw/no-escape contracts for COMP-01, COMP-02, COMP-03.
- [x] `test/support/primitive_story_catalog.ex` - primitive story metadata and helper contracts for SHOW-01 and COMP-04.
- [x] `test/oban_powertools/primitive_story_catalog_test.exs` - deterministic story ids, snapshots, and a11y selectors.
- [x] `test/browser/specs/primitives.behavior.spec.ts` - focus, accessible-name, tooltip, overflow, and reduced-motion checks.
- [x] Manifest schema coverage in `test/browser/support/manifest.ts` - unified stress scenario plus primitive story target validation.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Screen-reader announcement quality across all pages | A11Y-02 | Phase 74 only proves primitive-level API and automated behavior; full manual SR pass is deferred to Phase 82 | Do not block Phase 74; record any primitive-level SR concern as follow-up for Phase 82 |
| Full domain status taxonomy correctness | COMP-03 | Phase 74 deliberately defers cross-domain state mapping to Phase 77 | Verify only representative `StatusPill` examples such as retryable, executing, completed, discarded |

## Threat References

| Threat Ref | Threat | Mitigation Verified By |
|------------|--------|------------------------|
| T-74-01 | Visual policy bypass through caller `class` or `style` rest attrs | Render tests with hostile attrs plus source grep for raw values |
| T-74-02 | Unlabeled or keyboard-inoperable icon/tooltip controls | Required component attrs plus Playwright accessible-name and keyboard checks |

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency stays within one task commit.
- [x] `nyquist_compliant: true` set in frontmatter after Wave 0 and plan coverage are complete.

**Approval:** complete — fresh audit evidence recorded 2026-07-29

## Validation Audit 2026-07-29

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Fresh evidence: the focused primitive/component/catalog/showcase/token suite passed 65 tests with 0 failures; the generated manifest validated 7 primitive stories within the current 113-target, 4-theme, 3-viewport matrix; all 84 Phase 74 primitive PNG baselines are tracked; compilation passed with warnings-as-errors; and all 24 primitive browser behavior tests passed across 320, tablet, and wide projects. Full system-wide screen-reader and domain-taxonomy review remain correctly assigned to later phases, while every Phase 74 requirement has automated phase-scoped proof.
