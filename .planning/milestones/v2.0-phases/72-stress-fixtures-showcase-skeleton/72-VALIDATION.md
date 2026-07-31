---
phase: 72
slug: stress-fixtures-showcase-skeleton
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-18
last_audited: 2026-07-29
---

# Phase 72 - Validation Strategy

> Post-execution Nyquist audit for the deterministic fixture catalog and dev-only showcase skeleton.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest + static source checks + Hex package unpack checks |
| **Config file** | `config/test.exs`; example host uses `examples/phoenix_host/config/test.exs` |
| **Quick run command** | `mix test test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/router_test.exs` |
| **Phase suite command** | `mix test test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/theme_tokens_test.exs test/oban_powertools/web/assets_test.exs` |
| **Package command** | `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` |
| **Example-host command** | `cd examples/phoenix_host && mix test test/phoenix_host_web/oban_powertools_theme_isolation_test.exs test/phoenix_host_web/controllers/page_controller_test.exs` |
| **Full suite command** | `mix test --exclude host_contract` |
| **Observed runtime** | ~8 seconds for the phase suite; under 1 second for package and example-host suites after compilation |

---

## Sampling Rate

- **After every task commit:** Run the targeted test command for the touched area.
- **After every plan wave:** Run the phase suite and the package or example-host checks affected by that wave.
- **Before phase sign-off:** Run phase tests, package exclusion, catalog static scans, and dev/prod route proofs.
- **Max feedback latency:** Targeted task checks stay under 2 minutes; the full suite is reserved for wave and phase boundaries.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Test File | Status |
|---------|------|------|-------------|-----------|-------------------|-----------|--------|
| 72-01-01 | 01 | 1 | FIX-01, FIX-02, FIX-03 | unit/static | `mix test test/oban_powertools/showcase_catalog_test.exs` | `test/oban_powertools/showcase_catalog_test.exs` | green |
| 72-01-02 | 01 | 1 | FIX-03, SHOW-03 | package | `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` | `test/oban_powertools/hex_release_test.exs` | green |
| 72-02-01 | 02 | 1 | SHOW-01, SHOW-02 | LiveView integration | `mix test test/oban_powertools/web/live/showcase_live_test.exs` | `test/oban_powertools/web/live/showcase_live_test.exs` | green |
| 72-02-02 | 02 | 1 | SHOW-01 | router integration | `mix test test/oban_powertools/web/router_test.exs` | `test/oban_powertools/web/router_test.exs` | green |
| 72-02-03 | 02 | 1 | SHOW-03 | host integration | `cd examples/phoenix_host && mix test test/phoenix_host_web/oban_powertools_theme_isolation_test.exs test/phoenix_host_web/controllers/page_controller_test.exs` | `examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` | green |
| 72-03-01 | 03 | 2 | FIX-01, FIX-02 | unit | `mix test test/oban_powertools/showcase_catalog_test.exs` | `test/oban_powertools/showcase_catalog_test.exs` | green |
| 72-03-02 | 03 | 2 | FIX-01, FIX-02, FIX-03 | unit/static | `mix test test/oban_powertools/showcase_catalog_test.exs` plus deterministic-source scan | `test/oban_powertools/showcase_catalog_test.exs` | green |
| 72-04-01 | 04 | 3 | FIX-02, SHOW-01, SHOW-02 | LiveView/static | `mix test test/oban_powertools/web/live/showcase_live_test.exs` | `test/oban_powertools/web/live/showcase_live_test.exs` | green |
| 72-04-02 | 04 | 3 | SHOW-01, SHOW-03 | router/LiveView | `mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/showcase_live_test.exs` | `test/oban_powertools/web/router_test.exs` | green |
| 72-04-03 | 04 | 3 | FIX-02, SHOW-02, SHOW-03 | asset/package/environment | Phase suite, Hex unpack, and example-host dev/prod route proofs | `test/oban_powertools/web/theme_tokens_test.exs`, `test/oban_powertools/web/assets_test.exs`, `test/oban_powertools/hex_release_test.exs` | green |

*Status: pending / green / red / flaky*

---

## Requirement Coverage

| Requirement | Automated Evidence | Status |
|-------------|--------------------|--------|
| FIX-01 | Catalog contract asserts stable domains, scenario IDs, required adversarial states, personas/JTBDs, and deterministic repeated output. | COVERED |
| FIX-02 | Catalog target helpers and ShowcaseLive tests assert stable snapshot/a11y/story targets and catalog-backed rendering. | COVERED |
| FIX-03 | Catalog source scan rejects runtime/random/DB generation; Hex tests and unpack proof exclude test support and planning artifacts. | COVERED |
| SHOW-01 (skeleton) | Router and LiveView tests verify `/ops/jobs/_showcase`, ThemeShell ownership, stable sections, and reserved open-state targets; prod proof returns `{false, :error}`. | COVERED |
| SHOW-02 | LiveView tests verify exact theme choices, viewport choices, selected state, and stable `data-obpt-*` controls. | COVERED |
| SHOW-03 | Example-host tests verify host-root isolation and scoped Powertools ownership; dev proof exposes the route while prod and Hex proofs exclude it and its fixtures. | COVERED |

---

## Wave 0 Completion

- [x] `test/oban_powertools/showcase_catalog_test.exs` covers FIX-01, FIX-02, and FIX-03.
- [x] `test/oban_powertools/web/live/showcase_live_test.exs` covers SHOW-01 skeleton rendering and SHOW-02 controls/selectors.
- [x] `test/oban_powertools/web/router_test.exs` covers `_showcase` route info.
- [x] `test/oban_powertools/hex_release_test.exs` rejects the canonical fixture catalog while retaining runtime assets.
- [x] `examples/phoenix_host/test/phoenix_host_web/oban_powertools_theme_isolation_test.exs` covers host isolation without host router/layout changes.

---

## Manual-Only Verifications

None. Manual browser inspection remains useful exploratory evidence but is not required for Phase 72 sign-off.

---

## Audit Evidence

### Phase Tests

- Phase suite: **68 tests, 0 failures**.
- Package suite: **38 tests, 0 failures**.
- Example-host suite after gap repair: **3 tests, 0 failures**.

### Deterministic Catalog

The static scan of `test/support/showcase_catalog.ex` found no wall-clock, UUID, random, Faker, Repo, insert, Oban insert, or Ecto.Multi calls.

### Route Boundary

- Example host in `MIX_ENV=dev`: `ShowcaseLive` loaded and route info returned `/ops/jobs/_showcase`.
- Example host in `MIX_ENV=prod`: `{false, :error}`.

### Package Boundary

The unpacked Hex package contains:

- `priv/static/oban_powertools/oban_powertools.css`
- `priv/static/oban_powertools/oban_powertools.js`

It does not contain `test/support/showcase_catalog.ex`, `test`, or `.planning` artifacts.

---

## Validation Audit 2026-07-29

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

The audit found one partial SHOW-03 check: the example-host isolation test still asserted legacy Phase 71 presentation classes that the current Jobs page no longer renders. The Nyquist repair replaced those brittle assertions with stable app-shell, navigation, filter, result-state, and inserted-row contracts while preserving all Phase 72 host-isolation assertions.

---

## Validation Sign-Off

- [x] All 10 executed tasks have automated verification.
- [x] Every Phase 72 requirement maps to a green automated contract.
- [x] Sampling continuity has no three-task gap.
- [x] Wave 0 references exist and are green.
- [x] No watch-mode flags are used.
- [x] Feedback latency targets are documented.
- [x] Manual-only list is empty.
- [x] `nyquist_compliant: true` and `wave_0_complete: true`.

**Approval:** complete — audited 2026-07-29
