---
phase: 51-published-package-verification
verified: 2026-05-30T14:00:00Z
status: human_needed
score: 12/12 must-haves verified
overrides_applied: 0
re_verification: false
human_verification:
  - test: "Trigger a release and observe the verify-published CI job run to completion"
    expected: "The verify-published job runs after publish-hex completes, pins the consumer to the exact published version via sed, runs mix oban_powertools.install, migrates, seeds, and the first-session test passes green"
    why_human: "The CI job only runs when release_created == 'true' — it cannot be exercised programmatically from the repo. The local path-dep proof (Plan 02) demonstrates the test assertions are correct, but the full published-tarball path (hex.pm resolution, :files whitelist exercise) requires an actual release run."
---

# Phase 51: Published-Package Verification — Verification Report

**Phase Goal:** Prove the published Hex package installs and works end-to-end for a new adopter
**Verified:** 2026-05-30T14:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `examples/hex_consumer/` is a compilable mini Phoenix app whose own mix.exs declares `{:oban_powertools, "~> 0.5"}` as a hex dep | VERIFIED | `mix.exs` confirmed: `{:oban_powertools, "~> 0.5"}` present; no `path:` dep; `elixir: "~> 1.19"` |
| 2 | The consumer app has no oban_web dependency (native-only path) | VERIFIED | `grep -q 'oban_web' examples/hex_consumer/mix.exs` returns 0 matches |
| 3 | mix.exs declares elixir: "~> 1.19" to match the library minimum | VERIFIED | Confirmed present in mix.exs |
| 4 | A regenerate.sh companion exists, is executable, inserts the hex dep without oban_web | VERIFIED | `test -x regenerate.sh` passes; `bash -n` syntax check passes; hex dep string present in comment; no oban_web |
| 5 | examples/hex_consumer/mix.lock, deps/, _build/, and priv/repo/migrations/ are gitignored | VERIFIED | `.gitignore:30-33` entries confirmed; `git ls-files --error-unmatch` confirms none are tracked |
| 6 | examples/hex_consumer/ has a first-session test that drives /ops/jobs/cron, pauses nightly_sync, asserts DB state + audit evidence | VERIFIED | Test exercises `pause_cron_entry`, `cron.paused` action, `Audit.list`, `paused_at` DB state, and `refute html =~ "Oban Web"` |
| 7 | The nightly_sync Cron.Entry seed matches the field values the test asserts (source: fixture, overlap_policy: queue_one, catch_up_policy: latest) | VERIFIED | seeds.exs: `overlap_policy: "queue_one"`, `catch_up_policy: "latest"`, `source: "fixture"` — all match test assertions |
| 8 | test/support fixtures (ConnCase, DataCase) use Ecto Sandbox against HexConsumer.Repo | VERIFIED | `HexConsumerWeb.ConnCase` and `HexConsumer.Repo` confirmed; `Ecto.Adapters.SQL.Sandbox` in test.exs |
| 9 | release.yml has a verify-published job with needs: [release-please, publish-hex] that runs only when release_created == 'true' | VERIFIED | Lines 215-293 of release.yml; all conditions confirmed; YAML parses valid |
| 10 | The job pins the consumer to the exact just-published version via sed of mix.exs to == <version> before mix deps.get | VERIFIED | `sed -i "s|{:oban_powertools, \"~> 0.5\"}|{:oban_powertools, \"== ${VERSION}\"}|"` confirmed at release.yml:262-263 |
| 11 | The :files whitelist in the library root mix.exs is NOT loosened | VERIFIED | `~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]` — unchanged |
| 12 | Phase verification asserts git status --porcelain is empty (D-05) and documents in-repo-vs-published drift (D-06) | VERIFIED | `git status --porcelain examples/hex_consumer .github/workflows/release.yml` is empty; no-oban_web difference documented in README.md |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/hex_consumer/mix.exs` | HexConsumer.MixProject with hex oban_powertools dep, no oban_web, elixir ~> 1.19 | VERIFIED | All three conditions confirmed |
| `examples/hex_consumer/config/test.exs` | hex_consumer_test database + Ecto Sandbox pool config | VERIFIED | Both strings confirmed present |
| `examples/hex_consumer/lib/hex_consumer_web/oban_powertools_auth.ex` | HexConsumerWeb.ObanPowertoolsAuth with demo_actor/0 | VERIFIED | Full implementation, not a stub; `demo_actor/0` returns `%{id: "ops-demo", label: "ops-demo", role: :ops}` |
| `examples/hex_consumer/regenerate.sh` | Maintainer regeneration script with hex dep insertion | VERIFIED | Executable, syntax-valid, inserts hex dep, references hex_consumer dirs |
| `.gitignore` | Ignore rules for hex_consumer generated/lock artifacts | VERIFIED | Lines 30-33 cover mix.lock, priv/repo/migrations/, _build/, deps/ |
| `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` | REL-04 operator-session proof: cron pause + audit evidence | VERIFIED | Full 4-namespace-substitution copy; all D-04 assertions present |
| `examples/hex_consumer/priv/repo/seeds.exs` | nightly_sync Cron.Entry fixture the test depends on | VERIFIED | All required field values present and matching test assertions |
| `examples/hex_consumer/test/support/conn_case.ex` | HexConsumerWeb.ConnCase with sandbox + verified_routes | VERIFIED | Module confirmed |
| `examples/hex_consumer/test/test_helper.exs` | ExUnit start + sandbox manual mode for HexConsumer.Repo | VERIFIED | HexConsumer.Repo confirmed |
| `.github/workflows/release.yml` | verify-published job chained after publish-hex (REL-04) | VERIFIED | Job at L215; all required structure confirmed; YAML valid |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `examples/hex_consumer/config/config.exs` | `HexConsumerWeb.ObanPowertoolsAuth` | `:oban_powertools auth_module config` | WIRED | `auth_module: HexConsumerWeb.ObanPowertoolsAuth` confirmed |
| `examples/hex_consumer/mix.exs` | oban_powertools on hex.pm | hex dep declaration | WIRED | `{:oban_powertools, "~> 0.5"}` confirmed; no path: remnant |
| `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` | `examples/hex_consumer/priv/repo/seeds.exs` | nightly_sync fixture the test asserts is present | WIRED | `nightly_sync` asserted in test; `nightly_sync` seeded with exact matching field values |
| `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` | `HexConsumerWeb.ObanPowertoolsAuth.demo_actor/0` | actor injected into LiveView session | WIRED | `HexConsumerWeb.ObanPowertoolsAuth.demo_actor()` called in test; `demo_actor/0` implemented in auth module |
| `.github/workflows/release.yml verify-published` | `needs.release-please.outputs.version` | exact-version sed pin of examples/hex_consumer/mix.exs | WIRED | `VERSION="${{ needs.release-please.outputs.version }}"` feeds the sed command |
| `.github/workflows/release.yml verify-published` | `examples/hex_consumer first-session test` | mix test against the published tarball | WIRED | `mix test test/hex_consumer_web/oban_powertools_first_session_test.exs` at L292 |

### Data-Flow Trace (Level 4)

Not applicable. This phase produces a CI job definition, committed example app scaffold, and test files — not a component that renders dynamic data from a database in the traditional sense. The test itself asserts real DB state (not static/hardcoded values) and the seeds provide the real fixture data. Data flow is correct by construction: seeds.exs inserts a real DB row; test asserts the DB row's state after the LiveView action.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| mix.exs declares hex dep, no path: | `grep '{:oban_powertools, "~> 0.5"}' examples/hex_consumer/mix.exs` | Match found | PASS |
| No oban_web dep in mix.exs | `grep -q 'oban_web' examples/hex_consumer/mix.exs` | No match | PASS |
| regenerate.sh syntax valid | `bash -n examples/hex_consumer/regenerate.sh` | Exit 0 | PASS |
| YAML validity of release.yml | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release.yml'))"` | No error | PASS |
| No PhoenixHost residue in config/lib | `grep -rq 'PhoenixHost' examples/hex_consumer/config examples/hex_consumer/lib` | No match | PASS |
| No PhoenixHost residue in test | `grep -rq 'PhoenixHost' examples/hex_consumer/test` | No match | PASS |
| :files whitelist unchanged | `grep 'files: ~w\[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE\]' mix.exs` | Match found | PASS |
| D-05 clean-tree | `git status --porcelain examples/hex_consumer .github/workflows/release.yml` | Empty output | PASS |

Note: The local test proof (Plan 02 Task 2 — path-dep swap, test run, revert) is not independently re-runnable by this verifier because it requires a running Postgres instance and hex.pm reachability. The commit evidence (all 6 phase commits present in git log), the mix.exs hex-dep state (no path: remnant), and the test file content substantively support the SUMMARY.md claim that the test passed locally.

### Probe Execution

No probe scripts are defined for this phase. The verification proof relies on the CI job (`verify-published`) which requires an actual release trigger — this is the human verification item below.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| REL-04 | 51-01, 51-02, 51-03 | The getting-started quickstart is verified working from the published package — a fresh host installs from hex and reaches a first successful operator session | SATISFIED (pending CI run) | examples/hex_consumer/ app with hex dep; first-session test with full D-04 operator flow; verify-published CI job wired into release.yml; local proof via path-dep swap documented in SUMMARY |

Only REL-04 is mapped to Phase 51 in REQUIREMENTS.md. No orphaned requirements found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `examples/hex_consumer/priv/repo/migrations/*.exs` | L1 each | `PhoenixHost.Repo.Migrations.*` module names | INFO | Gitignored files — not committed, not tracked. Migrations were copied from phoenix_host during the path-dep proof run (Plan 02 deviation #3). Since these are gitignored and regenerated each CI run from the published tarball's installer, the stale module names in the local working-tree copies have no impact on the published-package verification. Not a blocker. |

No TBD, FIXME, or XXX markers found in any committed file modified by this phase.

### Human Verification Required

### 1. CI verify-published job execution against real release

**Test:** Create a new release of oban_powertools (or manually trigger the release pipeline) and observe the `verify-published` job in `.github/workflows/release.yml` run to completion.

**Expected:** The job:
1. Checks out the release tag
2. Pins mix.exs to `{:oban_powertools, "== <version>"}` via sed
3. Runs `mix deps.get` resolving the published tarball from hex.pm (exercises the `:files` whitelist)
4. Runs `mix oban_powertools.install` from the published tarball
5. Creates and migrates the `hex_consumer_test` Postgres database
6. Seeds the `nightly_sync` cron entry
7. Runs `oban_powertools_first_session_test.exs` — the test passes green, asserting `cron.paused` DB state + audit evidence

**Why human:** The `verify-published` job is gated on `release_created == 'true'` and requires hex.pm to have the published tarball indexed. This cannot be exercised programmatically from the local repo. The local proof (Plan 02) used a path dep swap to confirm the test assertions are correct, but the actual `:files` whitelist exercise — which is the core REL-04 failure class — requires the real published tarball to be fetched by `mix deps.get`.

### Gaps Summary

No gaps found. All 12 must-have truths are verified in the codebase. The sole remaining item is human verification of the CI job against a real release — an inherent constraint of a post-publish CI gate, not a flaw in the implementation.

---

_Verified: 2026-05-30T14:00:00Z_
_Verifier: Claude (gsd-verifier)_
