---
phase: 80
slug: page-migration-wave-2-jobs-forensics
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-27
---

# Phase 80 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest; Playwright + axe-core for connected browser, ARIA, accessibility, and VRT proof |
| **Config files** | `mix.exs`, `playwright.config.ts`, `package.json`, `voiceover.config.ts` |
| **Quick run command** | `mix test test/oban_powertools/jobs_test.exs test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/forensics/evidence_bundle_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` |
| **Full suite command** | `mix format --check-formatted && mix compile --warnings-as-errors && mix test --seed 0 && npm run verify:pages` |
| **Focused baseline** | 134 tests, 0 failures on 2026-07-27 |
| **Estimated runtime** | Focused ExUnit: under 120 seconds; browser/full suite: environment-dependent |

---

## Sampling Rate

- **After every task commit:** Run the narrowest non-watch ExUnit or Node command that exercises the changed contract; use the quick run command after any cross-cutting Jobs/Forensics change.
- **After every plan wave:** Run all plan-level commands for the completed wave, then the quick run command.
- **Before `/gsd:verify-work`:** `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test --seed 0`, `npm run verify:pages`, and the supported `npm run verify:voiceover` transcript gate must be green or explicitly recorded as environmentally unavailable.
- **Max feedback latency:** 120 seconds for ordinary task sampling. Browser/VRT and real screen-reader gates are reserved for their dedicated plans and the final wave.

---

## Per-Plan Verification Map

| Plan | Wave | Requirements | Secure behavior | Primary automated commands | Status |
|------|------|--------------|-----------------|----------------------------|--------|
| 80-01 canonical contracts | 1 | PAGE-02, PAGE-09, FORM-03, DATA-*, PAGE-10, A11Y-* | URL parsers reject mixed/invalid scopes; presenters expose closed redacted maps; context reads remain bounded | `mix test test/oban_powertools/jobs_test.exs test/oban_powertools/audit_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/selectors_test.exs test/oban_powertools/web/control_plane_presenter_test.exs --seed 0` | ⬜ pending |
| 80-02 Jobs browse | 2 | PAGE-02, FORM-03, DATA-*, PAGE-10, A11Y-* | Invalid URL JSON is replaced before querying; quick review is uniformly unavailable and structurally redacted | `mix test test/oban_powertools/jobs_test.exs test/oban_powertools/web/live/jobs_live_test.exs --seed 0` | ⬜ pending |
| 80-03 Jobs detail | 3 | PAGE-02, DATA-*, A11Y-* | Deterministic allowlisted return URLs; reauthorization before Lifeline preview/execute; no raw payload/error leakage | `mix test test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/lifeline_test.exs --seed 0` | ⬜ pending |
| 80-04 Jobs batch coordinator | 3 | PAGE-02, FORM-03, DATA-*, A11Y-* | Frozen bounded membership; max concurrency four; finite timeouts; safe result messages; no token/error/telemetry leakage | `mix test test/oban_powertools/jobs/batch_coordinator_test.exs test/oban_powertools/runtime_config_test.exs test/oban_powertools/application_test.exs test/oban_powertools/web/live/jobs_live_test.exs --seed 0` | ⬜ pending |
| 80-05 Forensics evidence model | 2 | PAGE-09, DATA-*, PAGE-10, A11Y-* | Exactly one supported scope family; bounded stable Audit windows; closed redacted evidence; honest coverage metadata | `mix test test/oban_powertools/audit_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/forensics/evidence_bundle_test.exs test/oban_powertools/web/control_plane_presenter_test.exs --seed 0` | ⬜ pending |
| 80-06 Forensics page | 3 | PAGE-09, FORM-03, DATA-*, PAGE-10, A11Y-* | Conflicting/malformed URLs canonicalize before evidence reads; unavailable states do not leak existence or policy detail | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` | ⬜ pending |
| 80-07 stories and styles | 4 | PAGE-02, PAGE-09, DATA-*, PAGE-10, A11Y-* | Deterministic fixtures contain redacted bounded presentation data and call the production `page_content/1` seams | `mix test test/oban_powertools/page_story_catalog_test.exs test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0 && npm run showcase:manifest && node test/browser/support/verify-page-baselines.mjs && node test/browser/support/verify-page-aria-snapshots.mjs` | ⬜ pending |
| 80-08 connected browser proof | 4 | PAGE-02, PAGE-09, FORM-03, PAGE-10, A11Y-* | Connected fixtures preserve authorization, bounded queries, frozen selection, redaction, and disconnect truth | `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/page-migration-wave-2.spec.ts` | ⬜ pending |
| 80-09 closure | 5 | PAGE-02, PAGE-09, FORM-03, DATA-*, PAGE-10, A11Y-* | Full regression, accessibility, reduced-motion, ARIA, VRT, and changed-baseline scope gates pass together | `mix format --check-formatted && mix compile --warnings-as-errors && mix test --seed 0 && npm run verify:pages` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

The planner may adjust wave numbers or split task IDs, but every task must retain an automated verification command from the corresponding row. No three consecutive implementation tasks may defer automated proof.

---

## Wave 0 Requirements

Existing infrastructure covers the phase:

- ExUnit, Phoenix.LiveViewTest, repository/query instrumentation, and component/story tests are already installed.
- Playwright, axe, Docker-first browser wrappers, strict page manifest/baseline validators, ARIA snapshots, VRT, and the VoiceOver transcript harness already exist.
- New focused test files may be created by their owning implementation plans, but Phase 80 requires no dependency installation or separate test-framework setup.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| VoiceOver transcript for Jobs and Forensics production composition | A11Y-* | The established transcript gate requires the supported macOS/VoiceOver environment and cannot be replaced by axe | Run `npm run verify:voiceover`; compare output to the repository transcript contract; record an explicit environmental gap if the supported runner is unavailable |
| Incident JSONB predicate at representative host scale | PAGE-09 | Local `EXPLAIN` cannot predict an unknown host’s production cardinality/index distribution | Capture the bounded query and local `EXPLAIN`; document that hosts with representative scale should evaluate the fingerprint predicate and add a host-owned index if warranted |

---

## Validation Sign-Off

- [x] Every recommended plan has a primary automated verification command.
- [x] Sampling continuity forbids three consecutive tasks without automated proof.
- [x] Existing infrastructure covers all required test layers; no Wave 0 dependency setup is required.
- [x] Commands are non-watch and bounded at the task level.
- [x] Ordinary feedback latency target is under 120 seconds; expensive browser/assistive-technology checks are isolated to dedicated plans and final closure.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** ready for planning on 2026-07-27
