---
phase: 72
slug: stress-fixtures-showcase-skeleton
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-18
---

# Phase 72 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest + package unpack checks |
| **Config file** | `config/test.exs`; example host uses `examples/phoenix_host/config/test.exs` |
| **Quick run command** | `mix test test/oban_powertools/showcase_catalog_test.exs test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/router_test.exs` |
| **Full suite command** | `mix test --exclude host_contract`; plus `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs`; plus the targeted example-host proof for `_showcase` |
| **Estimated runtime** | ~120 seconds targeted, ~10 minutes full suite based on recent phase timings |

---

## Sampling Rate

- **After every task commit:** Run the targeted test command for the touched area.
- **After every plan wave:** Run `mix test --exclude host_contract` and any targeted example-host checks introduced by that wave.
- **Before `/gsd:verify-work`:** Full suite, Hex unpack proof, prod route absence proof, and example-host no-host-change proof must be green.
- **Max feedback latency:** 10 minutes for full wave feedback; targeted task checks should stay under 2 minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 72-01-01 | 01 | 1 | FIX-01, FIX-02, FIX-03 | T-72-01 | Catalog data is deterministic, constant-only, and stable-selector ready | unit/static | `mix test test/oban_powertools/showcase_catalog_test.exs` | No - W0 | pending |
| 72-01-02 | 01 | 1 | SHOW-01, SHOW-02 | T-72-02 | Showcase route renders through Powertools shell with stable controls/selectors | LiveView integration | `mix test test/oban_powertools/web/live/showcase_live_test.exs test/oban_powertools/web/router_test.exs` | No - W0 | pending |
| 72-01-03 | 01 | 1 | SHOW-03, FIX-03 | T-72-03 | Dev/test artifacts do not leak into prod route table or Hex package | package/prod proof | `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` | Partial | pending |
| 72-01-04 | 01 | 1 | SHOW-03 | T-72-04 | Example host renders showcase from the existing router macro without host router/layout changes | integration | `cd examples/phoenix_host && mix test test/phoenix_host_web/oban_powertools_theme_isolation_test.exs test/phoenix_host_web/controllers/page_controller_test.exs` | Partial | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `test/oban_powertools/showcase_catalog_test.exs` - stubs and failing assertions for FIX-01, FIX-02, and FIX-03.
- [ ] `test/oban_powertools/web/live/showcase_live_test.exs` - stubs and failing assertions for SHOW-01 skeleton render and SHOW-02 controls/selectors.
- [ ] `test/oban_powertools/web/router_test.exs` - route-info contract for `_showcase` in dev/test and prod absence proof.
- [ ] `test/oban_powertools/hex_release_test.exs` - package assertions rejecting `test/support/showcase_catalog.ex` and showcase support artifacts while keeping `priv/static/oban_powertools` assets.
- [ ] Example-host proof extension only after the route/module availability strategy is chosen; no host router/layout edits.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Manual browser inspection of `/ops/jobs/_showcase` is useful but not sufficient for sign-off.

---

## Required Commands And Evidence

### Deterministic Fixtures

```bash
mix test test/oban_powertools/showcase_catalog_test.exs
rg 'DateTime\.utc_now|NaiveDateTime\.utc_now|System\.system_time|Ecto\.UUID\.generate|Enum\.random|:rand|Faker' test/support/showcase_catalog.ex
```

Expected evidence:
- Tests assert unique slug IDs.
- Tests assert all required domains: `overview`, `jobs`, `batches`, `workflows`, `cron`, `limiters`, `lifeline`, `audit`, and `forensics`.
- Tests assert required adversarial state tags: `empty`, `one`, `many`, `long_id`, `long_module`, `long_url`, `non_ascii`, `emoji`, `rtl`, `high_count`, `mixed_severity`, `permission_denied`, `stale`, `disconnected`, and `boundary_pagination`.
- Tests assert triage, incident response, repair, and audit review persona/JTBD coverage.
- The grep command returns no matches.

### Showcase Render And Controls

```bash
mix test test/oban_powertools/web/live/showcase_live_test.exs
```

Expected evidence:
- `live(conn, "/ops/jobs/_showcase")` renders through `ObanPowertools.Web.ThemeShell`.
- Rendered HTML has exactly one `.obpt-root`.
- Rendered HTML includes md5 Powertools CSS/JS asset paths.
- Theme controls expose `data-obpt-theme-choice="system"`, `"light"`, `"dark"`, and `"high-contrast"`.
- Viewport controls expose stable values for `320`, `tablet`, and `wide` through `data-obpt-viewport`.
- Story cells expose `data-obpt-story`, `data-obpt-domain`, `data-obpt-persona`, and `data-obpt-state`.

### Production Route Absence

```bash
MIX_ENV=prod mix compile --warnings-as-errors
cd examples/phoenix_host && MIX_ENV=prod mix run --no-start -e 'IO.inspect(Phoenix.Router.route_info(PhoenixHostWeb.Router, "GET", "/ops/jobs/_showcase", "localhost"))'
```

Expected evidence:
- Prod compile succeeds.
- Route info prints `:error`.
- No `_showcase` route is mounted in production.

### Hex Tarball Exclusion

```bash
rm -rf /tmp/obpt_phase72_pkg
OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix hex.build --unpack -o /tmp/obpt_phase72_pkg
test -f /tmp/obpt_phase72_pkg/priv/static/oban_powertools/oban_powertools.css
test -f /tmp/obpt_phase72_pkg/priv/static/oban_powertools/oban_powertools.js
test ! -e /tmp/obpt_phase72_pkg/test/support/showcase_catalog.ex
! find /tmp/obpt_phase72_pkg -type f | rg '(^|/)showcase_catalog\.ex$|^\.planning/|^test/'
```

Expected evidence:
- Runtime Phase 71 assets remain packaged.
- `test`, `.planning`, and showcase catalog/support files are absent.

### Example Host Behavior

```bash
cd examples/phoenix_host
MIX_ENV=dev mix compile --warnings-as-errors
MIX_ENV=dev mix run --no-start -e 'IO.inspect({Code.ensure_loaded?(ObanPowertools.Web.Dev.ShowcaseLive), Phoenix.Router.route_info(PhoenixHostWeb.Router, "GET", "/ops/jobs/_showcase", "localhost")})'
mix test test/phoenix_host_web/oban_powertools_theme_isolation_test.exs test/phoenix_host_web/controllers/page_controller_test.exs
```

Expected evidence:
- Dev compile has no undefined LiveView warning.
- `Code.ensure_loaded?(ObanPowertools.Web.Dev.ShowcaseLive)` is `true`.
- Route info returns a LiveView route for `/ops/jobs/_showcase`.
- Host `/` remains free of `.obpt-root`, `/ops/jobs/_assets/`, and `oban_powertools:theme`.

---

## Validation Sign-Off

- [x] All tasks have automated verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
