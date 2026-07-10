---
phase: 74
slug: primitives-library
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 74-W0-01 | TBD | 0 | COMP-01, COMP-02 | T-74-01 | Component APIs expose closed attrs/slots and no caller `class` or `style` escape hatch | unit/static | `mix test test/oban_powertools/web/components/primitives_test.exs` | No - Wave 0 | pending |
| 74-W0-02 | TBD | 0 | SHOW-01, COMP-04 | - | Primitive story metadata is deterministic and separate from stress scenarios | unit/static | `mix test test/oban_powertools/primitive_story_catalog_test.exs` | No - Wave 0 | pending |
| 74-W0-03 | TBD | 0 | SHOW-01 | - | Showcase route renders primitive stories without polluting `ShowcaseCatalog.scenarios/0` | unit/integration | `mix test test/oban_powertools/web/live/showcase_live_test.exs` | Existing file; primitive assertions missing | pending |
| 74-W0-04 | TBD | 0 | COMP-03, A11Y-02 | T-74-02 | Icon buttons have accessible names; focus remains visible; tooltip Escape works | browser | `npm run visual:a11y:host -- test/browser/specs/primitives.behavior.spec.ts` | No - Wave 0 | pending |
| 74-W0-05 | TBD | 0 | COMP-04, MOTION-02 | - | Primitive stories render at 320px and respect reduced motion | browser/VRT | `npm run visual:a11y` | Existing harness; primitive targets missing | pending |

## Wave 0 Requirements

- [ ] `test/oban_powertools/web/components/primitives_test.exs` - render/API/no-raw/no-escape contracts for COMP-01, COMP-02, COMP-03.
- [ ] `test/support/primitive_story_catalog.ex` - primitive story metadata and helper contracts for SHOW-01 and COMP-04.
- [ ] `test/oban_powertools/primitive_story_catalog_test.exs` - deterministic story ids, snapshots, and a11y selectors.
- [ ] `test/browser/specs/primitives.behavior.spec.ts` - focus, accessible-name, tooltip, overflow, and reduced-motion checks.
- [ ] Manifest schema coverage in `test/browser/support/manifest.ts` - unified stress scenario plus primitive story target validation.

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

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency stays within one task commit.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 and plan coverage are complete.

**Approval:** pending
