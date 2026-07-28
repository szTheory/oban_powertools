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
- **Before `/gsd:verify-work`:** `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test --seed 0`, `npm run verify:pages`, and `scripts/with-showcase-server.sh npm run verify:voiceover --` must be green. The transcript gate may remain explicitly open only when the server health check succeeded and the residual failure is specifically the supported macOS/VoiceOver/Guidepup capability.
- **Max feedback latency:** 120 seconds for ordinary task sampling. Browser/VRT and real screen-reader gates are reserved for their dedicated plans and the final wave.

---

## Per-Plan Verification Map

| Plan | Wave | Requirements | Secure behavior | Primary automated commands | Status |
|------|------|--------------|-----------------|----------------------------|--------|
| 80-01 Jobs query/URL foundation | 1 | PAGE-02, FORM-03, DATA-*, PAGE-10 | Complete green query, params, and selector suites prove bounded predicates, one grouped count, stable ID windows, and invalid-value rejection before query | `mix test test/oban_powertools/jobs_test.exs test/oban_powertools/web/jobs_params_test.exs test/oban_powertools/web/selectors_test.exs --seed 0` | ⬜ pending |
| 80-02 Jobs browse/quick review | 2 | PAGE-02, FORM-03, DATA-*, PAGE-10, A11Y-* | Invalid URL JSON is replaced before querying; quick review is uniformly unavailable and structurally redacted; no future detail/bulk assertions are present | `mix test test/oban_powertools/web/operator_pattern_presenter_test.exs test/oban_powertools/web/live/jobs_live_test.exs --seed 0` | ⬜ pending |
| 80-03 Jobs detail/single actions | 3 | PAGE-02, DATA-*, PAGE-10, A11Y-* | Deterministic allowlisted return URLs; reauthorization before Lifeline preview/execute; no raw payload/error leakage | `mix test test/oban_powertools/web/operator_pattern_presenter_test.exs test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/lifeline_test.exs --seed 0` | ⬜ pending |
| 80-04 Jobs batch coordinator | 4 | PAGE-02, FORM-03, DATA-*, A11Y-* | Frozen bounded membership; max concurrency four; finite timeouts; safe result messages; no token/error/telemetry leakage | `mix test test/oban_powertools/jobs/batch_coordinator_test.exs test/oban_powertools/auth_test.exs test/oban_powertools/application_test.exs test/oban_powertools/web/live/jobs_live_test.exs --seed 0` | ⬜ pending |
| 80-05 Forensics scope/query foundation | 4 | PAGE-09, DATA-*, PAGE-10, A11Y-* | Exactly one supported scope family is parsed before reads; bounded stable Audit windows and honest has-more metadata prevent enumeration and completeness overclaim | `mix test test/oban_powertools/audit_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/selectors_test.exs --seed 0` | ⬜ pending |
| 80-06 Forensics assembly/presenter | 5 | PAGE-09, DATA-*, PAGE-10, A11Y-* | Typed source dispatch, structural redaction, bounded evidence, independent truth dimensions, and a closed presentation map prevent leakage and causal overclaim | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/forensics/evidence_bundle_test.exs test/oban_powertools/web/operator_pattern_presenter_test.exs --seed 0` | ⬜ pending |
| 80-07 Forensics page | 6 | PAGE-09, FORM-03, DATA-*, PAGE-10, A11Y-* | Conflicting/malformed URLs canonicalize before evidence reads; reauthorization and uniform unavailable output prevent existence/policy leakage | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/forensics/evidence_bundle_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` | ⬜ pending |
| 80-08 page story catalog | 7 | PAGE-02, PAGE-09, DATA-*, PAGE-10, A11Y-* | One ordered Elixir registry calls production `page_content/1`; exact 30-story metadata, closed inputs, redaction sentinels, and package absence are enforced | `mix test test/oban_powertools/page_story_catalog_test.exs test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs --seed 0` | ⬜ pending |
| 80-09 manifest and validators | 8 | PAGE-02, PAGE-09, DATA-*, PAGE-10, A11Y-* | Task-entry compact JSON/SHA-256 capture proves the original first 83 targets remain byte/order-stable without HEAD; schema-8 discovery and exact 113/147/588 future sets are strict | `test -s /tmp/oban-powertools-80-09-first83.before.json && test -s /tmp/oban-powertools-80-09-first83.before.sha256 && npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` | ⬜ pending |
| 80-10 fixtures/launcher/client | 8 | PAGE-02, PAGE-09, FORM-03, PAGE-10, A11Y-* | Compile-time route-on and route-off branches each execute real tests; isolated authenticated fixtures, closed commands, checksums, and one validated launcher lifecycle fail closed | `cd examples/phoenix_host && PHASE80_BROWSER_FIXTURES=0 MIX_TEST_PARTITION=_phase80_fixture_route_off mix test test/phase80_browser_fixtures_test.exs --seed 0` | ⬜ pending |
| 80-11 connected browser/package | 9 | PAGE-02, PAGE-09, FORM-03, PAGE-10, A11Y-* | Wave 1 and Wave 2 run serially through one settled launcher/port; real DB/Lifeline/Audit effects, authorization, redaction, focus, reflow, and package absence are proven | `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/page-migration-wave-1.spec.ts test/browser/specs/page-migration-wave-2.spec.ts` | ⬜ pending |
| 80-12 styles and tracked evidence | 10 | PAGE-02, PAGE-09, DATA-*, PAGE-10, A11Y-* | Root-scoped CSS is deterministic; all 57 Wave 1 ARIA and 228 Wave 1 PNG files are task-boundary SHA-256 protected; `PAGE_QUALITY_ONLY=1` generation yields exact tracked 147/588 sets | `mix oban_powertools.assets.build && node test/browser/support/verify-page-baselines.mjs && node test/browser/support/verify-page-aria-snapshots.mjs` | ⬜ pending |
| 80-13 closure and VoiceOver | 11 | PAGE-02, PAGE-09, FORM-03, DATA-*, PAGE-10, A11Y-* | Full regression and compare-only gates pass; exact production-composed VoiceOver stories require `Back to Jobs`, `Investigation summary`, and `Event log` or retain a narrowly classified supported-environment gap | `mix format --check-formatted && mix compile --warnings-as-errors && mix test --seed 0 && npm run verify:pages && scripts/with-showcase-server.sh npm run verify:voiceover --` | ⬜ pending |

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
| VoiceOver transcript for Jobs and Forensics production composition | A11Y-* | The established transcript gate requires the supported macOS/VoiceOver environment and cannot be replaced by axe | Run `scripts/with-showcase-server.sh npm run verify:voiceover --`; require the guaranteed phrases `Back to Jobs`, `Investigation summary`, and `Event log`; classify an environmental gap only after successful server health and only for the macOS/VoiceOver/Guidepup capability |
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
