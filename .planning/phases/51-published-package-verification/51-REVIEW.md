---
phase: 51-published-package-verification
reviewed: 2026-05-30T00:00:00Z
depth: standard
files_reviewed: 25
files_reviewed_list:
  - .github/workflows/release.yml
  - examples/hex_consumer/.formatter.exs
  - examples/hex_consumer/README.md
  - examples/hex_consumer/config/config.exs
  - examples/hex_consumer/config/dev.exs
  - examples/hex_consumer/config/prod.exs
  - examples/hex_consumer/config/runtime.exs
  - examples/hex_consumer/config/test.exs
  - examples/hex_consumer/lib/hex_consumer.ex
  - examples/hex_consumer/lib/hex_consumer/application.ex
  - examples/hex_consumer/lib/hex_consumer/repo.ex
  - examples/hex_consumer/lib/hex_consumer_web.ex
  - examples/hex_consumer/lib/hex_consumer_web/components/core_components.ex
  - examples/hex_consumer/lib/hex_consumer_web/components/layouts.ex
  - examples/hex_consumer/lib/hex_consumer_web/components/layouts/root.html.heex
  - examples/hex_consumer/lib/hex_consumer_web/controllers/error_html.ex
  - examples/hex_consumer/lib/hex_consumer_web/controllers/error_json.ex
  - examples/hex_consumer/lib/hex_consumer_web/endpoint.ex
  - examples/hex_consumer/lib/hex_consumer_web/oban_powertools_auth.ex
  - examples/hex_consumer/lib/hex_consumer_web/oban_powertools_display_policy.ex
  - examples/hex_consumer/lib/hex_consumer_web/router.ex
  - examples/hex_consumer/lib/hex_consumer_web/telemetry.ex
  - examples/hex_consumer/mix.exs
  - examples/hex_consumer/regenerate.sh
  - examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs
findings:
  critical: 2
  warning: 4
  info: 2
  total: 8
status: issues_found
---

# Phase 51: Code Review Report

**Reviewed:** 2026-05-30T00:00:00Z
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

This phase ships three deliverables: the `verify-published` CI job added to
`release.yml`, the `hex_consumer` example application (a standalone Phoenix app
that depends on oban_powertools from hex.pm), and the regeneration helper
`regenerate.sh`. The CI plumbing is sound in its overall shape. The majority of
the application files are boilerplate Phoenix scaffolding with no material
defects. However two blockers were found: an unauthenticated-access backdoor in
the canonical auth example that would be copied verbatim by adopters, and a
silently-failing sed substitution in the release workflow that can cause the
verification job to test the wrong package version. Four warnings round out the
findings.

---

## Critical Issues

### CR-01: `current_actor/1` catch-all grants full ops access to every unauthenticated visitor

**File:** `examples/hex_consumer/lib/hex_consumer_web/oban_powertools_auth.ex:13`

**Issue:** The catch-all clause returns `demo_actor()` — a map with `role: :ops`
— for any connection that does not match the four specific session patterns above
it. Combined with the `authorize/3` implementation (lines 18–23), which grants
`:ok` to any map whose `:role` or `"role"` key equals `:ops` or `"ops"`, this
means a completely unauthenticated HTTP request hits `authorize(demo_actor(), …)`
and receives `:ok`. No login, token, or credential is required to gain full
operator access.

The module docstring calls this "the canonical example host." Developers
following the generated installer instructions are encouraged to use this file as
their auth seam template. Nothing in the module, the README, or `regenerate.sh`
warns that this fallback is deliberately open for demo purposes and must not be
used in production.

**Fix:** Add an explicit `@moduledoc` warning and guard the catch-all:

```elixir
@moduledoc """
Thin host-owned Powertools auth seam for the canonical example host.

WARNING: This module is intentionally open for CI/demo purposes.
The `current_actor/1` catch-all returns a privileged demo actor for
any unrecognised connection. Do NOT copy this implementation into a
production application. Replace the catch-all with `nil` and implement
real authentication (tokens, session cookies, etc.).
"""

# Replace line 13 with:
def current_actor(_), do: nil
```

With `nil` returned, `authorize(nil, …)` hits the existing guard on line 16 and
returns `{:error, :unauthorized}` for all unauthenticated visitors, which is the
correct production behaviour.

---

### CR-02: `sed` pin-version substitution in release workflow is silently fragile

**File:** `.github/workflows/release.yml:262-263`

**Issue:** The "Pin consumer to exact published version" step uses a literal
string match:

```bash
sed -i "s|{:oban_powertools, \"~> 0.5\"}|{:oban_powertools, \"== ${VERSION}\"}|" \
  examples/hex_consumer/mix.exs
```

`sed` returns exit code 0 even when no substitution is performed. If the
constraint in `mix.exs` ever drifts from the hardcoded `"~> 0.5"` (e.g., after
a major version bump to `"~> 1.0"`), `sed` silently makes no change. The
subsequent `mix deps.get` then resolves the original version constraint
(`"~> 0.5"`) from hex.pm — possibly a _different_ version than the one just
published — and the `mix test` step passes while verifying the wrong tarball.
The whole purpose of REL-04 (proving the exact published tarball works) is
undermined without any CI signal.

**Fix:** Extract the version constraint from `mix.exs` at runtime and use grep
to verify the substitution succeeded:

```bash
VERSION="${{ needs.release-please.outputs.version }}"
# Rewrite any ~> constraint to the exact pinned version
sed -i "s|{:oban_powertools, \"~> [^\"]*\"}|{:oban_powertools, \"== ${VERSION}\"}|" \
  examples/hex_consumer/mix.exs
# Fail loudly if the pin was not applied
grep -q "oban_powertools, \"== ${VERSION}\"" examples/hex_consumer/mix.exs || \
  { echo "ERROR: failed to pin oban_powertools to ${VERSION}"; exit 1; }
```

The broader regex `~> [^\"]*` is robust against any future constraint value
change.

---

## Warnings

### WR-01: `PageController` referenced in router but module does not exist

**File:** `examples/hex_consumer/lib/hex_consumer_web/router.ex:22`

**Issue:** The route `get "/", PageController, :home` references
`HexConsumerWeb.PageController`, which has no corresponding source file anywhere
under `lib/`. Phoenix does not validate controller module existence at compile
time, so the app compiles cleanly and all tests pass (no test exercises `GET /`).
However any request to `/` at runtime raises an `UndefinedFunctionError` or
`Protocol.UndefinedError`, producing a 500 rather than a meaningful page. The
root route is the first thing a developer following the README's `mix phx.server`
instruction would hit.

**Fix:** Either add a minimal `PageController` (a one-file controller with a
`home` action that renders a redirect or static HTML), or replace the route with
a redirect to the ops dashboard:

```elixir
# Option A — redirect root to ops
scope "/", HexConsumerWeb do
  pipe_through :browser
  get "/", Plug.Conn, :redirect  # or a real redirect plug
end

# Option B — simple controller at lib/hex_consumer_web/controllers/page_controller.ex
defmodule HexConsumerWeb.PageController do
  use HexConsumerWeb, :controller
  def home(conn, _params), do: redirect(conn, to: "/ops/jobs")
end
```

---

### WR-02: `mix oban_powertools.install` and `mix compile` run without `MIX_ENV` in `verify-published`

**File:** `.github/workflows/release.yml:270,274`

**Issue:** The "Run installer from published tarball" step and the "Compile hex
consumer" step have no `env: MIX_ENV:` setting, so they run in `:dev` by
default. The subsequent ecto and test steps explicitly set `MIX_ENV: test`. This
creates a split: deps and generated files land in `_build/dev`, but test
execution uses `_build/test`. Elixir's `Mix.Project` compiles sources separately
per environment. The compile artefacts produced by the `:dev` `mix compile` are
not reused for the `:test` run; the test step re-compiles anyway. This means the
explicit `mix compile --warnings-as-errors` step silently tests a different build
artefact than what the tests actually run against, giving a false green signal if
a warning exists only in test-env code paths.

**Fix:** Set `MIX_ENV: test` on both steps:

```yaml
- name: Run installer from published tarball
  env:
    MIX_ENV: test
  run: mix oban_powertools.install
  working-directory: examples/hex_consumer

- name: Compile hex consumer
  env:
    MIX_ENV: test
  run: mix compile --warnings-as-errors
  working-directory: examples/hex_consumer
```

---

### WR-03: `OBAN_POWERTOOLS_SKIP_DB_BOOT` env var is set at job level but does nothing in `hex_consumer`

**File:** `.github/workflows/release.yml:223-224`

**Issue:** The `verify-published` job sets `OBAN_POWERTOOLS_SKIP_DB_BOOT: "1"`
as a job-level env variable. This env var is consumed only by the _main library's_
`test/test_helper.exs` to skip DB migrations when running unit tests without a
database. The `hex_consumer` application has its own `test/test_helper.exs` which
does not reference this variable at all. The setting has no effect and silently
misleads future maintainers (the planning docs explicitly cite it as "mirroring
host-contract-proof.yml"). Since the `verify-published` job explicitly provisions
a Postgres service and _requires_ a database, setting this flag is actively
contradictory to the job's intent.

**Fix:** Remove the job-level `OBAN_POWERTOOLS_SKIP_DB_BOOT` env from the
`verify-published` job, or add a comment making clear it is a no-op here:

```yaml
# env:
#   OBAN_POWERTOOLS_SKIP_DB_BOOT: "1"  # has no effect in hex_consumer; removed
```

---

### WR-04: Oban runs with real queues during tests — no `:testing` / `inline` mode set

**File:** `examples/hex_consumer/config/test.exs`

**Issue:** `config.exs` (loaded for all envs) configures Oban with
`queues: [default: 5]`. The test config (`config/test.exs`) does not override
this with `testing: :inline` or `testing: :manual`. Oban therefore starts with
live queue pollers during the test run. The `ObanPowertoolsFirstSessionTest`
uses `async: false` and SQL sandbox in manual mode, but live Oban pollers share
the same Repo connection pool and are not SQL-sandbox-aware. This can cause
Oban's internal queries (queue heartbeats, rescuer) to check out bare
connections outside the sandbox, which in rare cases produces unexpected DB
state or test-order-dependent failures.

**Fix:** Override the Oban config in `test.exs` to disable queue polling:

```elixir
# config/test.exs
config :hex_consumer, Oban, testing: :inline
```

Or if inline job execution is not desired for this test:

```elixir
config :hex_consumer, Oban, queues: false, plugins: false
```

---

## Info

### IN-01: `audit_principal/1` catch-all silently re-attributes failed lookups to `demo_actor`

**File:** `examples/hex_consumer/lib/hex_consumer_web/oban_powertools_auth.ex:37`

**Issue:** `def audit_principal(_actor), do: audit_principal(demo_actor())` means
any actor value that doesn't satisfy `is_map(actor)` (line 29) falls through to
produce the `ops-demo` principal. This is invisible in the demo app, but if an
adopter copies this module and passes an integer or struct actor, their audit
events will be silently attributed to `ops-demo` instead of raising or returning
an error. The fallback obscures misconfiguration.

**Fix:** Replace the catch-all with `nil` to propagate the error through
`ObanPowertools.Auth.normalize_audit_principal/1`, which already handles `nil`
cleanly:

```elixir
def audit_principal(_actor), do: nil
```

---

### IN-02: `Repo.one!` in first-session test produces an opaque crash on missing preview record

**File:** `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs:44-51`

**Issue:** `Repo.one!(from(record in RepairPreview, …))` raises
`Ecto.NoResultsError` if the pause action did not insert a `RepairPreview` row.
The failure message ("expected at most one result but got none") does not indicate
which UI interaction failed to create the preview or what the actual DB state is.
A developer diagnosing a CI failure on this test has no actionable signal.

**Fix:** Use `Repo.one/1` with an explicit `assert` for a clearer failure message:

```elixir
preview = Repo.one(from(record in RepairPreview,
  where: record.action == "pause_cron_entry" and
         record.target_type == "cron_entry" and record.status == "ready",
  order_by: [desc: record.inserted_at],
  limit: 1
))

assert preview != nil,
  "Expected a RepairPreview record after clicking pause_cron_entry, but none was found. " <>
  "Check that the LiveView pause button rendered and that phx-click fired correctly."
```

---

_Reviewed: 2026-05-30T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
