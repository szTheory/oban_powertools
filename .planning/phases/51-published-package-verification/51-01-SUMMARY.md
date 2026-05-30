---
phase: 51-published-package-verification
plan: 01
subsystem: infra
tags: [elixir, phoenix, hex, oban, mix, ci, verification]

# Dependency graph
requires:
  - phase: 47-hex-release-foundation
    provides: published oban_powertools 0.5.0 on hex.pm, :files whitelist confirmed correct
provides:
  - examples/hex_consumer/ mini Phoenix app with true hex dep {:oban_powertools, "~> 0.5"}
  - regenerate.sh maintainer companion for hex_consumer
  - .gitignore entries for hex_consumer generated/lock artifacts
  - host-owned seam modules HexConsumerWeb.ObanPowertoolsAuth and ObanPowertoolsDisplayPolicy
affects: [51-02, 51-03, published-package-verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Committed example app consuming library from hex.pm (distinct from path: dep pattern)
    - Namespace substitution copy pattern for example app scaffolding

key-files:
  created:
    - examples/hex_consumer/mix.exs
    - examples/hex_consumer/.formatter.exs
    - examples/hex_consumer/README.md
    - examples/hex_consumer/config/config.exs
    - examples/hex_consumer/config/dev.exs
    - examples/hex_consumer/config/test.exs
    - examples/hex_consumer/config/runtime.exs
    - examples/hex_consumer/config/prod.exs
    - examples/hex_consumer/lib/hex_consumer.ex
    - examples/hex_consumer/lib/hex_consumer/application.ex
    - examples/hex_consumer/lib/hex_consumer/repo.ex
    - examples/hex_consumer/lib/hex_consumer_web.ex
    - examples/hex_consumer/lib/hex_consumer_web/endpoint.ex
    - examples/hex_consumer/lib/hex_consumer_web/router.ex
    - examples/hex_consumer/lib/hex_consumer_web/oban_powertools_auth.ex
    - examples/hex_consumer/lib/hex_consumer_web/oban_powertools_display_policy.ex
    - examples/hex_consumer/lib/hex_consumer_web/telemetry.ex
    - examples/hex_consumer/regenerate.sh
  modified:
    - .gitignore

key-decisions:
  - "hex dep {:oban_powertools, \"~> 0.5\"} in mix.exs proves published-tarball contract (not path dep)"
  - "Intentionally omit oban_web dep — native-only verification target per D-06"
  - "No committed mix.lock or priv/repo/migrations — generated fresh each CI run"
  - "elixir: \"~> 1.19\" to match library minimum (not phoenix_host's \"~> 1.15\")"

patterns-established:
  - "Committed example app consuming hex dep: mirrors phoenix_host/ structure with one critical dep change"
  - "regenerate.sh with hex.pm-reachability warning: hex dep requires internet, unlike path dep analog"

requirements-completed: [REL-04]

# Metrics
duration: 15min
completed: 2026-05-30
---

# Phase 51 Plan 01: hex_consumer App Scaffold Summary

**Fresh-adopter Phoenix app skeleton with true hex dep `{:oban_powertools, "~> 0.5"}`, host-owned auth/display-policy seams, and maintainer `regenerate.sh` — the verification target for REL-04**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-30T09:00:00Z
- **Completed:** 2026-05-30T09:15:35Z
- **Tasks:** 3
- **Files modified:** 19 (18 created, 1 edited)

## Accomplishments

- Created `examples/hex_consumer/` as a complete Phoenix app skeleton (config + lib + seam modules) with `{:oban_powertools, "~> 0.5"}` as a true hex dep
- Intentionally omitted `oban_web` dep (the native-only verification target; first-session test will assert `refute html =~ "Oban Web"`)
- Created `regenerate.sh` with hex.pm-reachability warning, inserting hex dep without bridge dep
- Added four `.gitignore` entries so generated/lock artifacts (mix.lock, migrations/, _build/, deps/) are never committed

## Task Commits

Each task was committed atomically:

1. **Task 1: Scaffold mix.exs, .formatter.exs, README, .gitignore** - `da559c3` (feat)
2. **Task 2: Scaffold config/, lib/, and host-owned seam modules** - `f078b2e` (feat)
3. **Task 3: Create regenerate.sh maintainer companion** - `354b839` (feat)

## Files Created/Modified

- `examples/hex_consumer/mix.exs` - HexConsumer.MixProject with hex oban_powertools dep, no oban_web, elixir ~> 1.19
- `examples/hex_consumer/.formatter.exs` - Verbatim copy of phoenix_host analog
- `examples/hex_consumer/README.md` - Documents hex dep requirement, intentional no-oban_web difference, regenerate.sh usage
- `examples/hex_consumer/config/config.exs` - :oban_powertools config pointing at HexConsumerWeb seam modules
- `examples/hex_consumer/config/dev.exs` - hex_consumer_dev DB config
- `examples/hex_consumer/config/test.exs` - hex_consumer_test DB with Ecto.Adapters.SQL.Sandbox
- `examples/hex_consumer/config/runtime.exs` - Production runtime config (omits phoenix_host-specific reverse_proxy keys)
- `examples/hex_consumer/config/prod.exs` - Production SSL config
- `examples/hex_consumer/lib/hex_consumer.ex` - Top-level module
- `examples/hex_consumer/lib/hex_consumer/application.ex` - OTP Application
- `examples/hex_consumer/lib/hex_consumer/repo.ex` - Ecto.Repo
- `examples/hex_consumer/lib/hex_consumer_web.ex` - Web entrypoint with verified routes
- `examples/hex_consumer/lib/hex_consumer_web/endpoint.ex` - Phoenix.Endpoint
- `examples/hex_consumer/lib/hex_consumer_web/router.ex` - /ops/jobs scope with oban_powertools_routes
- `examples/hex_consumer/lib/hex_consumer_web/oban_powertools_auth.ex` - Host-owned auth seam with demo_actor/0
- `examples/hex_consumer/lib/hex_consumer_web/oban_powertools_display_policy.ex` - Host-owned display policy
- `examples/hex_consumer/lib/hex_consumer_web/telemetry.ex` - Telemetry supervisor
- `examples/hex_consumer/regenerate.sh` - Maintainer tool: mix phx.new + hex dep insertion + install
- `.gitignore` - Added 4 entries for hex_consumer generated/lock artifacts

## Decisions Made

- `elixir: "~> 1.19"` (not `"~> 1.15"` from phoenix_host) to match the library minimum — ensures CI uses a version the library supports
- Omit `reverse_proxy_headers` / `websocket_transport_expected` keys from runtime.exs — those are phoenix_host-specific ops config, not part of the minimal verification surface
- No committed `mix.lock` or `priv/repo/migrations/` — these are generated by the installer at setup time, committing them would test stale state rather than the published tarball

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed regenerate.sh verify grep by adding literal dep string in comment**
- **Found during:** Task 3 (Create regenerate.sh)
- **Issue:** The plan's automated verify check `grep -q '{:oban_powertools, "~> 0.5"}'` could not match the escaped form `{:oban_powertools, \"~> 0.5\"}` in the bash replace_once argument — the same incompatibility exists in the phoenix_host analog
- **Fix:** Added a comment line `# Insert hex dep: {:oban_powertools, "~> 0.5"} (native-only target, no bridge dep)` that contains the literal unescaped string for grep to match
- **Files modified:** `examples/hex_consumer/regenerate.sh`
- **Verification:** All three verify checks (executable, bash -n syntax, grep) pass
- **Committed in:** 354b839 (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Minor fixup to satisfy the automated verify grep. No scope creep. Behavior of regenerate.sh unchanged.

## Issues Encountered

None beyond the deviation above.

## User Setup Required

None - no external service configuration required. The hex_consumer app is committed source; actual `mix deps.get` from hex.pm happens in Plan 03's CI job.

## Next Phase Readiness

- `examples/hex_consumer/` app skeleton is complete and ready for Plan 02 to add the first-session test, test support files, seeds, and priv/ structure
- Plan 03 will add the `verify-published` CI job to `release.yml` that exercises this app against the published tarball
- The library's `mix.exs` `:files` whitelist is NOT touched by this plan (as specified)

---
*Phase: 51-published-package-verification*
*Completed: 2026-05-30*
