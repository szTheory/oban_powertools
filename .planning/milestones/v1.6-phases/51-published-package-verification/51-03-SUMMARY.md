---
phase: 51-published-package-verification
plan: 03
subsystem: ci-release-pipeline
tags: [ci, yaml, release, hex, verification, postgres, liveview]

# Dependency graph
requires:
  - plan: 51-01
    provides: examples/hex_consumer/ app scaffold with hex dep
  - plan: 51-02
    provides: first-session test and test infrastructure for hex_consumer
provides:
  - .github/workflows/release.yml verify-published job (REL-04 closure)
  - Phase drift check D-06 verified: :files whitelist unchanged, intentional no-oban_web documented
  - Phase clean-tree assertion D-05: git status --porcelain empty for phase paths
affects: [REL-04, release-pipeline, published-package-verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - verify-published CI job: needs [release-please, publish-hex] + exact-version sed pin + postgres:16 service + full Mix step sequence
    - Exact version forcing: sed patches mix.exs dep to == <version> from release-please.outputs.version before mix deps.get

key-files:
  created: []
  modified:
    - .github/workflows/release.yml

key-decisions:
  - "needs: [release-please, publish-hex] — publish-hex already polls until hex.pm indexes the tarball (D-01a), so no race; verify-published needs release-please explicitly to access outputs.version"
  - "Exact == <version> pin via sed (not mix deps.update): guarantees the just-published version is tested, not whatever ~> 0.5 floats to (D-02b recommendation from RESEARCH.md)"
  - "POSTGRES_DB: hex_consumer_test (not phoenix_host_test) to avoid potential collision with host-contract-proof.yml jobs on the same runner (Pitfall F)"
  - "No HEX_API_KEY in verify-published: job reads from hex.pm only, permissions: contents: read (T-51-06 mitigated)"
  - "D-05 clean-tree assertion: git status --porcelain for examples/hex_consumer and release.yml paths is empty"
  - "D-06 drift check: :files whitelist unchanged at ~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]; intentional no-oban_web difference documented in examples/hex_consumer/README.md"

requirements-completed: [REL-04]

# Metrics
duration: 3min
completed: 2026-05-30
---

# Phase 51 Plan 03: Wire verify-published into release.yml Summary

`verify-published` CI job added to `.github/workflows/release.yml`, chained `needs: [release-please, publish-hex]`, that pins the hex consumer to the exact just-published version via `sed` and runs the full installer→migrate→seed→first-session-test sequence against the published tarball — closing REL-04.

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-30T11:03:53Z
- **Completed:** 2026-05-30T11:05:56Z
- **Tasks:** 2 (1 code, 1 verification-only)
- **Files modified:** 1 (`.github/workflows/release.yml`)

## Accomplishments

- Added `verify-published` job to `.github/workflows/release.yml` as a new terminal job after `publish-hex`
- Job correctly uses `needs: [release-please, publish-hex]` — inheriting the tarball-indexed guarantee from publish-hex's existing polling step (no race, per D-01a)
- `POSTGRES_DB: hex_consumer_test` service block mirrors `host-contract-proof.yml` pattern with a distinct DB name (Pitfall F)
- Exact version pin: `sed -i "s|{:oban_powertools, \"~> 0.5\"}|{:oban_powertools, \"== ${VERSION}\"}|"` using `needs.release-please.outputs.version` (D-02b)
- All 11 Mix steps carry `working-directory: examples/hex_consumer` (Pitfall C)
- No secrets referenced — `permissions: contents: read` only (T-51-06)
- Ran phase gate checks: D-05 clean-tree assertion passed, D-06 drift check passed

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the verify-published job to release.yml** - `a7a5e99` (feat)
2. **Task 2: Phase drift check and clean-tree assertion** - verification-only, no code change (all checks passed, documented in Summary)

## Files Created/Modified

- `.github/workflows/release.yml` — added 80 lines: the complete `verify-published` job

## Phase Gate Results

### D-06 Drift Check (Task 2)

| Item | Status | Detail |
|------|--------|--------|
| `:files` whitelist unchanged | PASS | `~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]` — verified unchanged, confirmed correct against 0.5.0 tarball (RESEARCH.md Focus Q5) |
| Intentional no-`oban_web` difference | DOCUMENTED | `examples/hex_consumer/README.md` line 20: "No `oban_web` dep: This consumer exercises the native-only operator..." |
| Real packaging drift in 0.5.0 tarball | NONE | All `lib/` files (including `lib/mix/tasks/oban_powertools.install.ex`), `guides/`, and root files confirmed present; no `priv/` directory exists in the library (correct — migrations are embedded in `lib/`). RESEARCH.md Focus Q5 verified directly against the built tarball. |

No packaging bugs found. No `:files` widening needed or applied.

### D-05 Clean-Tree Assertion (Task 2)

`git status --porcelain examples/hex_consumer .github/workflows/release.yml` outputs empty. All phase artifacts are either committed or gitignored (per Plan 01: `mix.lock`, `priv/repo/migrations/`, `_build/`, `deps/`). Phase is clean.

## Decisions Made

- Exact `== <version>` pin (not `mix deps.update`) per RESEARCH.md Focus Q1 recommendation — most robust mechanism for forcing the exact just-published version
- No aggregate gate job for `verify-published` — it is a leaf job; a red run is visible on the release commit (RESEARCH.md Open Question 2 answer)
- `working-directory` on every Mix step — mitigates Pitfall C (mix commands run in wrong project)

## Deviations from Plan

None — plan executed exactly as written. The exact version pin sed pattern was confirmed present with the correct backslash-escaped quote form as expected by the plan's automated verify check.

## Known Stubs

None. The CI job definition is complete with all required steps. No hardcoded empty values or placeholders.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| T-51-06 mitigated | `.github/workflows/release.yml` | `verify-published` job declares `permissions: contents: read` and references no secrets — `HEX_API_KEY` stays scoped to `publish-hex` only |

## Self-Check: PASSED

- `.github/workflows/release.yml` — EXISTS and parses as valid YAML
- `verify-published:` job present — CONFIRMED
- `needs: [release-please, publish-hex]` — CONFIRMED
- `POSTGRES_DB: hex_consumer_test` — CONFIRMED
- Exact version pin sed command — CONFIRMED (backslash-escaped form `\"== `)
- `oban_powertools_first_session_test` referenced — CONFIRMED
- `mix.exs` `:files` whitelist unchanged — CONFIRMED
- `examples/hex_consumer/README.md` documents `oban_web` difference — CONFIRMED
- `git status --porcelain` empty for phase paths — CONFIRMED
- Task 1 commit `a7a5e99` — EXISTS

---
*Phase: 51-published-package-verification*
*Completed: 2026-05-30*
