---
phase: 76
slug: navigation-app-shell
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-11
---

# Phase 76 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix LiveViewTest render/component tests; Playwright 1.61.0 with axe |
| **Config file** | `test/test_helper.exs`, `playwright.config.ts`, `test/browser/support/manifest.ts` |
| **Quick run command** | `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` |
| **Full suite command** | `mix test && npm run visual:a11y` |
| **Estimated runtime** | Quick command target under 15 seconds after Wave 0; full suite depends on browser/a11y container startup |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` once Wave 0 creates the shell test file.
- **After shell browser behavior changes:** Run `npx playwright test test/browser/specs/shell.behavior.spec.ts --project chromium-320`.
- **After every plan wave:** Run `npm run showcase:manifest && npm run visual:a11y`.
- **Before `/gsd:verify-work`:** Run `mix test && npm run visual:a11y`; update VRT baselines only with `npm run vrt:update` when shell pixel changes are intentional.
- **Max feedback latency:** keep unit/render feedback under 15 seconds after Wave 0; browser/a11y feedback is wave-gated.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 76-W0-01 | TBD | 0 | NAV-01, NAV-03, COPY-* | T-76-XSS-01 | Fixed server-side nav labels render through HEEx escaping; no caller-supplied raw HTML labels | unit/render | `mix test test/oban_powertools/web/components/app_shell_test.exs --seed 0` | No - Wave 0 | pending |
| 76-W0-02 | TBD | 0 | NAV-02, NAV-04, A11Y-02 | T-76-UX-01 | Mobile disclosure remains keyboard operable and does not create nested scroll traps | browser | `npx playwright test test/browser/specs/shell.behavior.spec.ts --project chromium-320` | No - Wave 0 | pending |
| 76-W0-03 | TBD | 0 | NAV-01, A11Y-02 | T-76-AUTH-01 | Shell reads existing actor context without creating auth/session decisions | axe + browser | `npm run visual:a11y -- --grep shell` | No - Wave 0 | pending |
| 76-W0-04 | TBD | 0 | NAV-01, NAV-03 | T-76-ROUTE-01 | Manifest/story targets expose active-route and breadcrumb states for regression evidence | source + browser | `npm run showcase:manifest && npm run visual:a11y` | Partial - manifest exists, shell targets missing | pending |

Status values: pending, green, red, flaky.

---

## Wave 0 Requirements

- [ ] `lib/oban_powertools/web/components/app_shell.ex` - shell component API and central nav model.
- [ ] `test/oban_powertools/web/components/app_shell_test.exs` - render/static/copy/active-route contract tests.
- [ ] `test/support/shell_story_catalog.ex` - deterministic shell showcase stories.
- [ ] `test/oban_powertools/shell_story_catalog_test.exs` - catalog/target contract tests.
- [ ] `test/browser/specs/shell.behavior.spec.ts` - skip link, focus order, disclosure collapse, active route, and 320px overflow checks.
- [ ] `scripts/showcase_manifest.exs`, `test/browser/support/manifest.ts`, and `ShowcaseLive` support shell targets.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional Oban Web bridge presence in shell | NAV-01 | Research left this as an open product/scope decision because no Phase 76 CONTEXT.md exists | Confirm whether the final shell should show an Oban Web bridge link; if deferred, document the deferral in the relevant PLAN.md |
| Actor/context label specificity | NAV-01, COPY-* | Research found the source actor assign but not a locked copy policy for label detail | Review the shell showcase story and confirm the actor/context label is acceptable or explicitly defer copy polish to later phases |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing test files and browser shell evidence.
- [ ] No watch-mode flags in verification commands.
- [ ] Feedback latency target documented for unit/render checks.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 exists and plans map concrete task IDs.

**Approval:** pending
