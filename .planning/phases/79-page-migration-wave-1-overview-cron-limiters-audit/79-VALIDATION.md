---
phase: 79
slug: page-migration-wave-1-overview-cron-limiters-audit
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-07-19
---

# Phase 79 — Validation Evidence Ledger

> Automated evidence is reconciled. Human observations remain intentionally pending, so
> `status: draft`, `nyquist_compliant: false`, and Approval pending are authoritative.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus the Playwright Docker runner, axe, and screenshot harness |
| **Configuration** | `mix.exs`, root `package.json`, and `playwright.config.ts` |
| **Targeted ExUnit** | Four connected page suites plus Audit, presenter, component, catalog, showcase, token, and asset suites |
| **Page browser gate** | Manifest smoke + exact baseline verifier + connected/structure/axe/VRT selection |
| **Aggregate gate** | `npm run visual:a11y` (measured separately from the Phase 79 page gate) |
| **Fixture infrastructure** | Test-only example-host routes behind `PHASE79_BROWSER_FIXTURES=1`, isolated disposable database/build, and `PHASE79_BROWSER_FIXTURE_SECRET` forwarded by name only |

## Corrected Requirement Map

| Requirement | Phase 79 surface |
|-------------|------------------|
| `PAGE-01` | Overview |
| `PAGE-05` | Cron |
| `PAGE-06` | Limiters |
| `PAGE-08` | Audit |
| `PAGE-10` | Cross-page shell, ownership, destination, compatibility, and package-boundary behavior |

---

## Per-Task Verification Map

Every actual task from Plans 79-01 through 79-12 is represented. Commands are the
post-implementation gates; Plan 79-01's intentional RED contracts are green in the final
integrated run.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure behavior / artifact | Automated command and result | Status |
|---------|------|------|-------------|------------|----------------------------|------------------------------|--------|
| 79-01-01 | 79-01 | 1 | PAGE-01/05/06/08/10, COPY-01 | T-79-08-DOS/LEAK | Pins bounded query, finite presenter, component, and canonical URL contracts | Targeted Phase 79 ExUnit gate: 151 tests, 0 failures | ✅ |
| 79-01-02 | 79-01 | 1 | PAGE-01/05/06/08, A11Y-* | T-79-08-AUTH/REPLAY/FOCUS | Pins all four connected LiveView behavior contracts | Targeted Phase 79 ExUnit gate: 151 tests, 0 failures | ✅ |
| 79-02-01 | 79-02 | 2 | PAGE-08, PAGE-10 | T-79-08-DOS/AUTH | Stable bounded Audit paging | `mix test test/oban_powertools/audit_test.exs --seed 0`: 4 tests, 0 failures | ✅ |
| 79-02-02 | 79-02 | 2 | PAGE-01/05/06/08, COPY-01 | T-79-08-LEAK/INJECT | Finite cross-page presenters and structural redaction | Presenter + operator-pattern component gate: 36 tests, 0 failures | ✅ |
| 79-02-03 | 79-02 | 2 | PAGE-06/08/10, A11Y-* | T-79-08-FOCUS/LEAK | Compatible blocker and Audit components | Focused shared Phase 79 slice: 10 tests, 0 failures | ✅ |
| 79-03-01 | 79-03 | 3 | PAGE-01, PAGE-10, COPY-01 | T-79-08-DOS/LEAK | Deterministic bounded Overview read model and ordering | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs --seed 0`: 14 tests, 0 failures | ✅ |
| 79-03-02 | 79-03 | 3 | PAGE-01, A11Y-*, MOTION-* | T-79-08-FOCUS/DOS | Stable Overview shared composition | Operator-pattern + data-display component gate: 46 tests, 0 failures | ✅ |
| 79-04-01 | 79-04 | 3 | PAGE-05, PAGE-10 | T-79-08-AUTH | Safe Cron URL selection and selected-detail-only actions | Cron LiveView/domain gate: 29 tests, 0 failures | ✅ |
| 79-04-02 | 79-04 | 3 | PAGE-05, COPY-01 | T-79-08-AUTH/REPLAY/LEAK | Confirm-time authority, single-use preview, reason, recovery, and receipt truth | Cron LiveView gate: 15 tests, 0 failures; full-DOM redaction assertions green | ✅ |
| 79-04-03 | 79-04 | 3 | PAGE-05, A11Y-*, MOTION-* | T-79-08-FOCUS | Cron scan/detail/dialog mutual exclusion and one truthful receipt | Shared component gate: 46 tests, 0 failures; `mix compile --warnings-as-errors` green in Plan 79-04 | ✅ |
| 79-05-01 | 79-05 | 3 | PAGE-06, PAGE-10 | T-79-08-DOS/LEAK | Batched limiter reads and current/snapshot evidence truth | Limiters slice and constant-query instrumentation green | ✅ |
| 79-05-02 | 79-05 | 3 | PAGE-06, COPY-01, A11Y-* | T-79-08-AUTH/LEAK/FOCUS | Read-only Limiters composition and server-gated destinations | Limiters LiveView: 11 tests, 0 failures; shared components: 47 tests, 0 failures | ✅ |
| 79-06-01 | 79-06 | 3 | PAGE-08, PAGE-10 | T-79-08-AUTH/DOS | Filter-scoped selected Audit retrieval and canonical URL state | Audit LiveView: 11 tests, 0 failures | ✅ |
| 79-06-02 | 79-06 | 3 | PAGE-08, COPY-01 | T-79-08-LEAK/INJECT | Bounded normalized row/detail assigns outside render | Audit + presenter: 22 tests, 0 failures; schema/metadata absence gates green | ✅ |
| 79-06-03 | 79-06 | 3 | PAGE-08, A11Y-*, MOTION-* | T-79-08-AUTH/FOCUS | Read-only Audit scan, filters, pagination, and evidence detail | Shared components: 47 tests, 0 failures; `mix compile --warnings-as-errors` green in Plan 79-06 | ✅ |
| 79-07-01 | 79-07 | 4 | PAGE-01/05/06/08/10, A11Y-*, MOTION-* | T-79-08-FOCUS/SUPPLY | Token-owned page CSS and deterministic packaged asset | Asset build + token/assets tests: 23 tests, 0 failures; source/static CSS byte-equal; packaged JS unchanged | ✅ |
| 79-08-01 | 79-08 | 6 | PAGE-01/05/06/08/10, COPY-01, A11Y-*, MOTION-* | T-79-08-AUTH/REPLAY/INJECT/LEAK/DOS/FOCUS | Connected behavior, structure, axe, reflow, zoom, motion, and confidentiality | Integrated browser selection: 507 passed; connected page subset: 39 passed; page axe matrix: 228 passed | ✅ |
| 79-08-02 | 79-08 | 6 | PAGE-01/05/06/08, A11Y-* | T-79-08-FOCUS/SUPPLY | Exact page-only visual evidence | Generation: 228 passed; exact verifier: 228; changed scope at generation: 228 page paths; fresh compare-only: 228 passed | ✅ automated / ⬜ human |
| 79-08-03 | 79-08 | 6 | PAGE-01/05/06/08/10, COPY-01, A11Y-*, MOTION-* | all T-79-08 refs | Integrated regression and evidence reconciliation | ExUnit/page browser gates green; repository Credo/Dialyzer/non-page VRT debt recorded below; manual sign-off pending | ⚠️ draft |
| 79-09-01 | 79-09 | 1 | PAGE-01/05/06/08/10, A11Y-* | T-79-08-SUPPLY/FOCUS | Exact 19-story and browser evidence contracts | Elixir formatting, Node syntax, exact-ID static gate, and whitespace gate green | ✅ |
| 79-10-01 | 79-10 | 4 | PAGE-01/05/06/08 | T-79-08-AUTH/REPLAY/LEAK | Opt-in host reset, actor, and recovery seam | Route-on 5/5, route-off 1/1, release regression 37/37 | ✅ |
| 79-10-02 | 79-10 | 4 | PAGE-01/05/06/08/10 | T-79-08-AUTH/SUPPLY | Isolated database/build and secret-name propagation | Pinned Docker fixture run 6/6; wrapper concurrent run 18/18 in Plan 79-10 | ✅ |
| 79-10-03 | 79-10 | 4 | PAGE-05, A11Y-* | T-79-08-AUTH/REPLAY/LEAK | Fail-closed fixture helpers and real recovery state | Exact final command `... phase79-fixtures.spec.ts --project=chromium-wide`: 6 passed | ✅ |
| 79-11-01 | 79-11 | 4 | PAGE-01/05/06/08/10, COPY-01, A11Y-*, MOTION-* | T-79-08-INJECT/FOCUS/SUPPLY | Exact production-composed page catalog | Catalog/showcase/release gates green; all 19 stories, one matching tree, at most one dialog/modal | ✅ |
| 79-12-01 | 79-12 | 5 | PAGE-01/05/06/08/10, COPY-01, A11Y-*, MOTION-* | T-79-08-INJECT/SUPPLY | Schema-7 manifest and shared browser target pipeline | Manifest smoke: 9/7/9/6/10/23/19 stories and 83 targets; repeated SHA-256 stable | ✅ |

*Status: ✅ green · ⚠️ reconciled residual or pending non-automated closure · ⬜ pending*

---

## Final Automated Evidence

| Gate | Exact command / evidence | Result |
|------|--------------------------|--------|
| Phase 79 ExUnit | `mix test` over the four page LiveViews, Audit, presenter, components, catalog, showcase, tokens, and assets with `--seed 0` | 151 tests, 0 failures |
| Full ExUnit | `mix test --exclude host_contract` | 848 tests, 0 failures, 7 excluded |
| Formatting | `mix format --check-formatted` and cumulative `git diff --check "$PHASE79_BASE" --` | Green |
| Credo | `mix credo --strict` | Inherited repository debt: 9 warnings, 88 refactoring, 54 readability, 109 design findings; not introduced by Phase 79 |
| Dialyzer | `mix dialyzer` | Inherited repository debt: 62 errors, including Mix-task PLT gaps and longstanding opaque/type findings; no Phase 79-specific finding identified |
| Fixture | `scripts/with-showcase-server.sh scripts/playwright-docker.sh npx playwright test test/browser/specs/phase79-fixtures.spec.ts --project=chromium-wide` | 6 passed; reset twice, actor switching, recovery states, omission fails before network, absent/wrong headers return indistinguishable empty 404 |
| Manifest | `npm run showcase:manifest && node test/browser/support/manifest-smoke.mjs` | Schema 7; 19 page stories; 83 total targets; 4 themes; 3 viewports |
| Manifest determinism | Generate/hash twice | SHA-256 `709f2ec9c5150b17704f6769778cc7022507e21a1ae5b9f318a247887d0c7d05` both times |
| Exact page files | `node test/browser/support/verify-page-baselines.mjs` | `page baselines ok: 228` |
| Generation scope | `node test/browser/support/verify-page-baselines.mjs --changed-scope` before screenshot commit | `228 paths, all within 228`; no non-page screenshot changed |
| Theme identity | SHA comparison for every 19-story × 3-viewport group | 57/57 groups had distinct light, dark, and high-contrast bytes |
| Page compare-only | Docker `showcase.vrt.spec.ts --grep "page page-"` without update flags | 228 passed |
| Integrated page gate | Manifest smoke + verifier + connected/structure/axe/VRT grep | 507 passed in 6.6 minutes |
| Aggregate raw measurement | `npm run visual:a11y` | 2,238 total: 1,779 passed, 431 failed, 28 skipped in 19.3 minutes |
| Aggregate classification | Failure inspection + focused rerun | 423 non-page VRT mismatches; 7 stale behavior contracts corrected; 1 transient page-axe connection miss |
| Aggregate non-VRT reconciliation | Focused operator-pattern, primitive-focus, and page-axe matrix | 27 passed; all non-VRT aggregate failures green after correction |

The planning-time expectation of **108 scenario-only VRT failures did not match the measured
repository state**. The stable aggregate exposed **423 non-page VRT comparison failures** across
scenario, primitive, form, data, and group families. Phase 79 did not update any of those images,
and every `page-*` comparison passed. This variance is recorded rather than hidden or relabeled.
The first aggregate attempt was infrastructure-aborted at test 702 when Docker Desktop stopped;
the reported counts come from the complete stable retry.

---

## Fixture, Confidentiality, and Package-Boundary Evidence

- The disposable runner owns an isolated database and build path and cleans them on exit.
- `PHASE79_BROWSER_FIXTURE_SECRET` is forwarded into Docker by environment-variable name only;
  no command or source embeds the value.
- Removing the variable fails locally before network I/O. Missing and wrong fixture headers both
  return an empty 404 response.
- Reset results expose stable project/actor/count/state names only. Tokens, plan hashes,
  credentials, raw metadata, errors, principals, and stacktraces stay server-side.
- Connected confidentiality scans cover text, markup, URLs, form values, hidden nodes, serialized
  story metadata, and every attribute.
- Source and packaged CSS are byte-equal. Repeated manifest generation is byte-stable. Packaged
  JavaScript, `mix.exs`, `mix.lock`, `package-lock.json`, migrations, policies, providers, and the
  public Cron API are unchanged from `79-START-SHA`.
- Root `package.json` changed only to forward trailing Playwright arguments through the existing
  npm wrapper; no dependency changed.
- The only route-file change is the Plan 79-10 test-only example-host fixture route behind the
  explicit flag. The example-host test auth catalog is also flag-gated.
- Docker dependency resolution reported current advisories in inherited Hex packages. Phase 79
  changed no dependency or lockfile; dependency remediation is outside this execution's authority
  and remains separately actionable repository work.

---

## High-Severity Threat Reconciliation

| Threat | Category | Evidence | Phase 79 status |
|--------|----------|----------|-----------------|
| T-79-08-AUTH | Access control | Real connected page/resource/action authorization, read-only actor, scoped selection, and current-principal Cron confirmation | ✅ mitigated |
| T-79-08-REPLAY | Business logic | Expired, drifted, consumed, skipped, partial, duplicate, single-use, and one-receipt tests | ✅ mitigated |
| T-79-08-INJECT | Injection | Hostile Unicode/HTML fixtures plus cross-channel DOM/URL/form/attribute scans and finite presenters | ✅ mitigated |
| T-79-08-LEAK | Data protection | Structural allowlists, package exclusion, filter-scoped Audit detail, fixture 404 parity, and absence sentinels | ✅ mitigated |
| T-79-08-DOS | Availability | Bounded query/DOM/page counts, no polling/N+1/duplicate tree, overflow/reflow checks, exact fixture cleanup | ✅ mitigated |
| T-79-08-FOCUS | Accessibility | One-dialog containment/restore, wide no-trap, resize, 320/200%, visible focus, target size, and reduced motion | ✅ automated; human observation pending |
| T-79-08-SUPPLY | Supply chain | Page-only PNG scope, source/static and manifest stability, unchanged locks/dependencies/JS, cumulative protected-boundary audit | ✅ mitigated for Phase 79 scope |

No unresolved high-severity threat or unplanned protected-boundary change remains in Phase 79's
scope. Repository-wide static-analysis, dependency-advisory, and non-page VRT debt is explicitly
recorded above and is not presented as green.

---

## Manual-Only Verifications

| Behavior | Requirement | Why manual | Test instructions | Status |
|----------|-------------|------------|-------------------|--------|
| Screen-reader heading, landmark, table, and control-name experience | A11Y-* | Assistive-technology usability needs human observation beyond axe | Review each migrated page and selected-detail state with a screen reader; confirm logical order, native table navigation, and resource-specific names. | ⬜ pending |
| Cron confirmation focus and recovery | A11Y-*, PAGE-05 | Direct observation complements mechanical containment/restoration evidence | Open selected detail; traverse each confirmation; test Escape, recovery, success close, resize, and logical focus restoration. | ⬜ pending |
| Responsive reflow, high contrast, and reduced motion | A11Y-*, MOTION-* | Color-independent meaning and perceived motion quality require review | Inspect 320, tablet, and wide at 200% across all themes; enable reduced motion and review action/focus visibility. | ⬜ pending |
| Copy, evidence truth, and ownership | COPY-01, PAGE-01/05/06/08/10 | Operator semantics require human judgment | Review quiet, nonzero, unavailable, denied, stale, partial, expired/drifted, empty, long/Unicode, selected-detail, and receipt copy. | ⬜ pending |
| Visual packet | PAGE-01/05/06/08, A11Y-* | Pixels become approved evidence only after human review | Review all 19 IDs across 3 viewports × 4 themes, including long/Unicode, selected detail, confirmation, and recovery. | ⬜ pending |

Executor-side representative inspection found no squeeze, overlap, clipping, unreadable theme,
duplicate tree, or unrelated screenshot-family change. That mechanical inspection does not replace
the five human rows above.

---

## Validation Sign-Off

- [x] All 25 tasks have concrete automated evidence rows.
- [x] Sampling continuity was maintained; no three implementation tasks lacked an automated gate.
- [x] Existing infrastructure covered the phase; no framework-install Wave 0 was required.
- [x] The schema-7 matrix contains exactly 19 page stories and 228 page/theme/viewport targets.
- [x] No watch-mode flags appear in verification commands.
- [x] Targeted ExUnit, connected behavior, structure, page axe, and compare-only page VRT are green.
- [x] Exact page image count, generation scope, theme identity, and protected-boundary diff are reconciled.
- [x] Docker fixture reset, named-secret propagation, omission failure, 404 parity, and cleanup are evidenced.
- [x] All Phase 79 high-severity threats have automated mitigation evidence.
- [ ] Repository-wide Credo/Dialyzer debt is green.
- [ ] Repository-wide non-page VRT debt is green (423 comparison failures remain).
- [ ] Required human screen-reader, keyboard, responsive/theme/motion, copy, and visual reviews are recorded.
- [ ] `nyquist_compliant: true`, `status: complete`, and Approval approved are set only after all closure rows are satisfied.

**Approval:** pending
