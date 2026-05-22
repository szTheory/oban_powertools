---
phase: 11
plan: 02
subsystem: example-host
tags: [phoenix, host-contract, auth, display-policy, seeds]
requires: [DOC-01, HST-03]
provides: [canonical-example-host, rerunnable-fixture, thin-host-seams]
key_files:
  created:
    - examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex
    - examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex
    - examples/phoenix_host/regenerate.sh
    - examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs
  modified:
    - examples/phoenix_host/mix.exs
    - examples/phoenix_host/config/config.exs
    - examples/phoenix_host/config/runtime.exs
    - examples/phoenix_host/lib/phoenix_host/application.ex
    - examples/phoenix_host/lib/phoenix_host_web/router.ex
    - examples/phoenix_host/priv/repo/seeds.exs
    - examples/phoenix_host/README.md
completed_at: 2026-05-22
---

# Phase 11 Plan 02 Summary

`examples/phoenix_host` now exists as the canonical Phase 11 fixture: a generated Phoenix host with explicit Powertools config, host-owned `/ops/jobs` routing, thin auth and display-policy seams, rerunnable seed assumptions, and a regeneration script anchored to `mix phx.new` plus `mix oban_powertools.install`.

## Verification

- `cd examples/phoenix_host && mix compile`
  Result: passed
- `cd examples/phoenix_host && rg -n "auth_module: PhoenixHostWeb.ObanPowertoolsAuth|display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy|scope \"/ops/jobs\"|oban_powertools_routes\\(\"/oban\"\\)|oban_web" mix.exs config/config.exs lib/phoenix_host_web/router.ex`
  Result: passed
- `cd examples/phoenix_host && MIX_ENV=test mix ecto.reset && MIX_ENV=test mix run priv/repo/seeds.exs`
  Result: passed
- `cd examples/phoenix_host && rg -n "@behaviour ObanPowertools.Auth|def display\\(|ops|display_policy|read-only|mix phx.new|reverse-proxy|WebSocket|auth/session|mix oban_powertools.install" lib/phoenix_host_web/oban_powertools_auth.ex lib/phoenix_host_web/oban_powertools_display_policy.ex priv/repo/seeds.exs README.md regenerate.sh`
  Result: passed

## Deviations from Plan

- `mix oban_powertools.install` currently fails in the generated host with `Igniter.Libs.Ecto.gen_migration/4` receiving a `nil` module. The fixture keeps the documented provenance path but finishes the thin host seams manually.
- Added a minimal Oban migration so the rerunnable `ecto.reset` lane can boot and seed without missing `oban_peers`.

## Self-Check: PASSED
