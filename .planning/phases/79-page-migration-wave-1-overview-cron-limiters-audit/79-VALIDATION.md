---
phase: 79
slug: page-migration-wave-1-overview-cron-limiters-audit
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-07-19
---

# Phase 79 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Playwright/browser VRT and axe harness |
| **Config file** | `mix.exs`, root `package.json`, and `playwright.config.ts` |
| **Quick run command** | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/audit_live_test.exs --seed 0` |
| **Full suite command** | `mix format --check-formatted && mix test --exclude host_contract && mix credo --strict && mix dialyzer && npm run visual:a11y` |
| **Estimated runtime** | Targeted checks in seconds to a few minutes; integrated gate below 20 minutes |

---

## Sampling Rate

- **After every task commit:** Run the narrowest affected ExUnit/component/browser command from the verification map in the task's PLAN.md.
- **After every plan wave:** Run the four connected LiveView test files plus affected component, asset, manifest, and browser specs.
- **Before `/gsd:verify-work`:** The integrated full suite and compare-only VRT must be green.
- **Max feedback latency:** Keep normal automated feedback below 20 minutes; do not allow three consecutive implementation tasks without an automated proof.

---

## Per-Task Verification Map

The planner must replace the rows below with concrete task IDs and exact commands. Every substantive task must have an automated proof immediately after the change.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | PAGE-01, COPY-01 | Phase 79 threat model | Shared shell/components preserve authorization and redaction boundaries | component + connected LiveView | `mix test test/oban_powertools/web/components/operator_patterns_test.exs test/oban_powertools/web/live/operator_patterns_harness_test.exs --seed 0` | ✅ | ⬜ pending |
| TBD | TBD | TBD | PAGE-05 | Phase 79 threat model | Overview remains bounded, truthful, read-only, and free of secret/internal values | unit + LiveView | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs --seed 0` | ✅ | ⬜ pending |
| TBD | TBD | TBD | PAGE-06 | Phase 79 threat model | Cron preserves double authorization, preview identity, reason validation, single-use execution, and durable audit behavior | unit + LiveView | `mix test test/oban_powertools/web/live/cron_live_test.exs --seed 0` | ✅ | ⬜ pending |
| TBD | TBD | TBD | PAGE-08 | Phase 79 threat model | Limiters distinguish current, snapshot, and retained evidence without inventing authority or causality | unit + LiveView | `mix test test/oban_powertools/web/live/limiters_live_test.exs --seed 0` | ✅ | ⬜ pending |
| TBD | TBD | TBD | PAGE-10 | Phase 79 threat model | Audit is bounded, stable, structurally redacted, filter-compatible, and read-only | query + LiveView | `mix test test/oban_powertools/web/live/audit_live_test.exs --seed 0` | ✅ | ⬜ pending |
| TBD | TBD | TBD | A11Y-*, MOTION-* | Phase 79 threat model | One semantic DOM tree, accessible focus/dialog behavior, reduced motion, and no sensitive DOM payloads | browser + axe + VRT | `npm run visual:a11y -- test/browser/specs/page-migration-wave-1.spec.ts` | ❌ planner creates | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing ExUnit, connected LiveView, component harness, asset, showcase-manifest, Playwright, axe, and VRT infrastructure covers the phase. The plan must add the Phase 79 deterministic page stories/spec and lock its expected story × theme × viewport matrix before baseline generation.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Screen-reader heading, landmark, table, and control-name experience | A11Y-* | Assistive-technology usability needs human observation beyond axe | Review each migrated page and selected-detail state with a screen reader; confirm logical order, native table navigation, and resource-specific names. |
| Cron confirmation focus and recovery | A11Y-*, PAGE-06 | Focus containment/restoration across modal and responsive state changes benefits from direct observation | Open selected detail, enter each confirmation, traverse with keyboard, test permitted Escape, failure recovery, success close, resize, and logical focus restoration. |
| Responsive reflow, high contrast, and reduced motion | A11Y-*, MOTION-* | Visual/focus quality and color-independent meaning require reviewed evidence | Inspect 320px, tablet, and wide at 200% zoom across light, dark, system, and high-contrast themes; enable reduced motion and confirm instant nonessential transitions. |
| Copy, evidence truth, and ownership review | COPY-01, PAGE-05, PAGE-06, PAGE-08, PAGE-10 | Semantic truth and support-boundary wording require operator review | Review quiet, nonzero, unavailable, permission-denied, stale, partial, expired/drifted, empty, long/Unicode, selected-detail, and dialog fixtures for exact action/absence/ownership/freshness/completeness/receipt copy. |
| Visual baseline scope | PAGE-01, A11Y-* | Generated pixels are evidence only after human review | Confirm expected page image count equals locked story count × 12, inspect changed PNG families, reject unrelated changes, then run compare-only VRT. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or explicit infrastructure dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Existing infrastructure covers the phase; no framework-install Wave 0 is required.
- [ ] Phase 79 page browser spec and deterministic story matrix exist.
- [ ] No watch-mode flags appear in plan verification commands.
- [ ] Normal feedback latency remains below 20 minutes.
- [ ] Targeted connected LiveView and component gates are green.
- [ ] Axe has zero critical/serious violations and compare-only VRT is green.
- [ ] `nyquist_compliant: true` is set in frontmatter after all plan task rows are concrete and verified.

**Approval:** pending
