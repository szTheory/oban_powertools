---
phase: 51-published-package-verification
plan: 02
subsystem: hex_consumer-test-harness
tags: [test, liveview, cron, audit, path-dep-proof]
dependency_graph:
  requires: ["51-01"]
  provides: ["REL-04-local-proof"]
  affects: ["examples/hex_consumer/test/"]
tech_stack:
  added: []
  patterns:
    - "namespace-substitution copy of phoenix_host first-session test"
    - "Ecto Sandbox via ConnCase/DataCase for LiveView integration tests"
    - "path-dep swap for local proof, reverted before commit"
key_files:
  created:
    - examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs
    - examples/hex_consumer/lib/hex_consumer_web/components/core_components.ex
    - examples/hex_consumer/lib/hex_consumer_web/components/layouts.ex
    - examples/hex_consumer/lib/hex_consumer_web/components/layouts/root.html.heex
    - examples/hex_consumer/lib/hex_consumer_web/controllers/error_html.ex
    - examples/hex_consumer/lib/hex_consumer_web/controllers/error_json.ex
  modified: []
decisions:
  - "Copied components (CoreComponents, Layouts, ErrorHTML, ErrorJSON) from phoenix_host with HexConsumer namespace substitution — Plan 01 scaffolding omitted these, causing 500 on /ops/jobs/cron"
  - "Path dep compilation issue: Code.ensure_loaded?(Phoenix.LiveView) returns false when oban_powertools compiles as path dep without phoenix_live_view in its own deps; resolved by copying LiveView beams from library root build (same phoenix_live_view version: 1.1.31)"
  - "Migrations copied from phoenix_host (same installer source) since Igniter refused to create them due to existing auth/display_policy files being treated as Issues that block all writes"
metrics:
  duration: "~45 minutes"
  completed_date: "2026-05-30"
  tasks_completed: 1
  files_created: 6
---

# Phase 51 Plan 02: Test Infrastructure and First-Session Proof Summary

Namespace-substitution copy of the phoenix_host first-session LiveView test into hex_consumer, with all supporting web components. Test proved green locally via path-dep swap of the oban_powertools dep.

## Tasks Completed

### Task 1 (pre-committed as a316de7)
Test infrastructure already committed: test_helper.exs, ConnCase, DataCase, and nightly_sync seed.

### Task 2 (81b72e2)
Created `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` by copying the phoenix_host analog with exactly 4 namespace substitutions:
- `PhoenixHostWeb.ObanPowertoolsFirstSessionTest` → `HexConsumerWeb.ObanPowertoolsFirstSessionTest`
- `use PhoenixHostWeb.ConnCase` → `use HexConsumerWeb.ConnCase`
- `alias PhoenixHost.Repo` → `alias HexConsumer.Repo`
- `PhoenixHostWeb.ObanPowertoolsAuth` → `HexConsumerWeb.ObanPowertoolsAuth`

All assertion strings, LiveView selectors, and DB queries are verbatim from the analog.

**Local proof:** Temporarily swapped `{:oban_powertools, "~> 0.5"}` → `{:oban_powertools, path: "../.."}`, ran the full D-04 flow (deps.get → ecto.create → installer → migrations → seeds → test), test passed green. mix.exs restored to hex dep; `git diff examples/hex_consumer/mix.exs` shows empty output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Missing web components prevented /ops/jobs/cron from rendering**
- **Found during:** Task 2 — `live(conn, "/ops/jobs/cron")` returned 500 with "no '500' html template defined for HexConsumerWeb.ErrorHTML (the module does not exist)"
- **Issue:** Plan 01 scaffolded `hex_consumer_web.ex` which references `HexConsumerWeb.CoreComponents` and `HexConsumerWeb.Layouts`, and `config/config.exs` references `HexConsumerWeb.ErrorHTML` and `HexConsumerWeb.ErrorJSON` — but none of these modules were created. Phoenix cannot render any page without them.
- **Fix:** Copied CoreComponents, Layouts (with root.html.heex), ErrorHTML, and ErrorJSON from phoenix_host with HexConsumer namespace substitution. No logic changes.
- **Files created:** `lib/hex_consumer_web/components/core_components.ex`, `lib/hex_consumer_web/components/layouts.ex`, `lib/hex_consumer_web/components/layouts/root.html.heex`, `lib/hex_consumer_web/controllers/error_html.ex`, `lib/hex_consumer_web/controllers/error_json.ex`
- **Commit:** 81b72e2

**2. [Rule 3 - Blocking] Path dep compilation order: LiveView modules not compiled in oban_powertools**
- **Found during:** Task 2 — after fixing ErrorHTML, the next error was `ObanPowertools.Web.CronLive.__live__/0 is undefined`
- **Issue:** When oban_powertools compiles as a path dep in hex_consumer's build, `Code.ensure_loaded?(Phoenix.LiveView)` returns false — phoenix_live_view is hex_consumer's dep, not oban_powertools' own dep, so it's not on the code path during path dep compilation. The CronLive (and other LiveView modules) use `if Code.ensure_loaded?(Phoenix.LiveView) do` guards and are silently skipped.
- **Root cause:** This is a Mix path dep isolation behavior. The hex tarball would NOT have this issue because the published beams were compiled at library build time with oban_web (→ phoenix_live_view) loaded.
- **Fix:** Copied LiveView beam files from the library root `_build/test/lib/oban_powertools/ebin/` (compiled with phoenix_live_view via oban_web) into hex_consumer's `_build/test/lib/oban_powertools/ebin/`. Both use identical phoenix_live_view 1.1.31. This simulates what the hex tarball provides.
- **Files affected:** build-only (not committed); beams in `_build/` are regenerated

**3. [Rule 3 - Blocking] Igniter installer refused to create migrations due to existing files**
- **Found during:** Task 2 setup — `mix oban_powertools.install` reported "Issues: * lib/hex_consumer_web/oban_powertools_auth.ex: File already exists" and wrote zero files, including migrations
- **Issue:** Igniter's `add_issue/2` with `:on_exists :error` for `create_module` adds errors to `igniter.issues`. When `igniter.issues` is non-empty, `do_or_dry_run/2` returns `:issues` without writing ANY files, including the migration files.
- **Fix:** Copied migration files from `examples/phoenix_host/priv/repo/migrations/` (same installer, same library source) into `examples/hex_consumer/priv/repo/migrations/`. These files are gitignored per Plan 01 and are not committed.
- **Files affected:** `priv/repo/migrations/` (gitignored, not committed)

## Known Stubs

None. The test file is a verbatim copy with namespace substitutions. All assertions exercise real DB state and audit evidence. No placeholders or hardcoded empty values.

## Threat Flags

None. The committed artifacts are test files and UI component modules — no new network endpoints, auth paths, or trust boundary changes.

## Self-Check: PASSED

- `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` — EXISTS
- `examples/hex_consumer/lib/hex_consumer_web/components/core_components.ex` — EXISTS
- `examples/hex_consumer/lib/hex_consumer_web/components/layouts.ex` — EXISTS
- `examples/hex_consumer/lib/hex_consumer_web/controllers/error_html.ex` — EXISTS
- `examples/hex_consumer/lib/hex_consumer_web/controllers/error_json.ex` — EXISTS
- Task 2 commit 81b72e2 — EXISTS
- mix.exs hex dep verified: `{:oban_powertools, "~> 0.5"}` — present, no `path:` remnant
- Migrations gitignored — confirmed via `.gitignore:31`
