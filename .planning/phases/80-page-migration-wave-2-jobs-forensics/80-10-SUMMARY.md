---
phase: 80-page-migration-wave-2-jobs-forensics
plan: 10
subsystem: testing
tags: [phoenix, playwright, fixtures, postgres, docker, security]

requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    plan: 08
    provides: Production Jobs and Forensics routes plus deterministic page-story contracts
  - phase: 79-page-migration-wave-1-overview-cron-limiters-audit
    plan: 10
    provides: Opt-in authenticated browser fixture pattern and disposable Playwright launcher
provides:
  - Test-only authenticated Phase 80 reset, actor, batch barrier, and evidence endpoints
  - Deterministic isolated Jobs and Forensics fixture data for all Plan 80 acceptance classes
  - Strict fail-closed TypeScript client for exact Phase 80 fixture schemas
  - One disposable browser server lifecycle carrying Phase 79 and Phase 80 concurrently
affects: [80-11, 80-12, playwright, jobs, forensics, page-quality]

tech-stack:
  added: []
  patterns:
    - Compile fixture routes only under MIX_ENV=test plus an explicit feature flag
    - Forward ephemeral browser credentials by environment name at the Docker boundary
    - Validate every fixture response against exact public keys and closed allowlists

key-files:
  created:
    - examples/phoenix_host/test/support/phase80_browser_fixtures.ex
    - examples/phoenix_host/test/phase80_browser_fixtures_test.exs
    - test/browser/support/phase80-fixtures.ts
    - test/browser/specs/phase80-fixtures.spec.ts
  modified:
    - examples/phoenix_host/config/test.exs
    - examples/phoenix_host/lib/phoenix_host_web/router.ex
    - scripts/with-showcase-server.sh
    - scripts/playwright-docker.sh

key-decisions:
  - "Keep Phase 80 as a sibling fixture seam so Phase 79 routes, schemas, and callers remain unchanged."
  - "Use one project/run-tagged database population and a DB/message barrier; the seam controls deterministic state but never executes operator actions."
  - "Expose only IDs, counts, states, and audit completion, rejecting unknown or sensitive response fields in the browser client."
  - "Reuse the existing validated Phase 79 disposable database/build lifecycle while enabling both fixture generations and independently generated secrets."

patterns-established:
  - "Fixture denial parity: missing, wrong, and disabled fixture access all return an empty 404."
  - "Call-time credential gate: browser helpers validate the process credential before any request or state lookup."
  - "Protected dirty boundary: compare dependency/package files against task-entry checksums rather than HEAD."

requirements-completed: ["PAGE-02", "PAGE-09", "FORM-03", "PAGE-10", "A11Y-*"]

duration: 28m
completed: 2026-07-28
status: complete
---

# Phase 80 Plan 10: Isolated Browser Fixture Bridge Summary

**A secret-protected, deterministic Jobs/Forensics fixture seam now runs beside Phase 79 through one disposable Phoenix/Postgres/Playwright lifecycle with strict closed-schema clients**

## Performance

- **Duration:** 28m
- **Started:** 2026-07-28T17:54:45Z
- **Completed:** 2026-07-28T18:22:45Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added exactly four opt-in test-only POST endpoints for deterministic Phase 80 reset, actor, batch-barrier, and closed public evidence control; production and Hex builds contain none of the fixture modules or routes.
- Seeded 2,500 project/run-isolated jobs across seven states, exact page and batch boundaries, every adversarial repair class, four forensic families, 55-event windows, Unicode/RTL content, and sensitive sentinels that never enter public responses.
- Preserved Phase 79 unchanged while one validated disposable database, build, and Phoenix server enables both fixture generations with independent cryptographically random credentials.
- Added a fail-closed TypeScript client and six-test browser proof covering idempotency, isolation, both actors, connected production-route availability, barrier status/hold/release, bounded evidence polling, and denial parity.

## Task Commits

Task 80-10-01 used an atomic TDD red-green pair; Task 80-10-02 used one implementation commit:

1. **RED: Define the Phase 80 fixture seam contract** - `fc25e0c`
2. **GREEN: Add the isolated Phase 80 fixture seam** - `cc93a15`
3. **Task 2: Bridge Phase 80 browser fixtures through the shared launcher** - `d729608`

## Files Created/Modified

- `examples/phoenix_host/test/support/phase80_browser_fixtures.ex` - Deterministic tagged data, actor sessions, DB/message barrier, public evidence, constant-time authentication, and empty-404 controller.
- `examples/phoenix_host/test/phase80_browser_fixtures_test.exs` - Complete route-on/off, schema, security, isolation, barrier, coexistence, and package contract.
- `examples/phoenix_host/config/test.exs` - Shared fixture-server lifecycle and empty disabled-route 404 renderer.
- `examples/phoenix_host/lib/phoenix_host_web/router.ex` - Four exact POST routes behind the test-plus-flag compile gate.
- `scripts/with-showcase-server.sh` - Second independent secret and both fixture flags on the existing disposable lifecycle.
- `scripts/playwright-docker.sh` - Conditional Phase 80 secret forwarding by environment name only.
- `test/browser/support/phase80-fixtures.ts` - Call-time secret checks, allowlists, exact schema validation, and sensitive-field rejection.
- `test/browser/specs/phase80-fixtures.spec.ts` - Concurrent Phase 79/80 browser fixture proof.

## Decisions Made

- Retained the existing Phase 79 database/build names and cleanup validation because one lifecycle already provides the required isolation; Phase 80 adds flags and credentials without weakening that contract.
- Kept seeded sensitive values only in tagged database rows. Reset and evidence responses expose the minimum closed set of public identifiers, counts, and states.
- Used exact-text actor assertions on the shared showcase because its component examples intentionally contain longer demo actor labels.
- Kept existing PostgreSQL configurability and `PAGE_QUALITY_ONLY` launcher changes unstaged; only Phase 80 hunks entered these commits.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first integrated browser run found a strict-locator ambiguity between `Actor: ops` and longer showcase demo labels. Exact-text assertions resolved it, and the full shared-server command then passed 12/12.
- `mix deps.get` reported advisories for existing locked dependencies. Dependency and lockfile changes were explicitly outside this plan; the task-entry checksum proves those protected files remained byte-identical.

## User Setup Required

None - the launcher creates and transports both ephemeral credentials automatically.

## Verification

- TDD RED: the combined host contract ran 12 tests with six expected failures while all Phase 80 routes were absent.
- `PHASE79_BROWSER_FIXTURES=1 PHASE80_BROWSER_FIXTURES=1 MIX_TEST_PARTITION=_phase80_fixture_contract mix test test/phase79_browser_fixtures_test.exs test/phase80_browser_fixtures_test.exs --seed 0` - 13 tests, 0 failures.
- `PHASE80_BROWSER_FIXTURES=0 MIX_TEST_PARTITION=_phase80_fixture_route_off mix test test/phase80_browser_fixtures_test.exs --seed 0` - two real tests, 0 failures, with no tag filters.
- `mix test test/oban_powertools/hex_release_test.exs --seed 0` - 38 tests, 0 failures.
- Test and production `mix compile --warnings-as-errors` passed; a production runtime probe confirmed Phase 80 fixture modules and routes are absent.
- `bash -n` passed for both launcher scripts.
- Playwright discovery registered 36 tests across three projects.
- The one-server Docker command ran both Phase 79 and Phase 80 specs concurrently on `chromium-wide` - 12 tests, 0 failures.
- The exact task-entry checksum for `package-lock.json`, `mix.exs`, `mix.lock`, and packaged JavaScript remained unchanged.
- Source/artifact scans found no literal fixture credential, secret-header material, or Phase 80 sensitive sentinel in browser outputs.
- Scoped `git diff --check` and all four-file Elixir formatting checks passed.

## Next Phase Readiness

- Plan 80-11 can consume the stable reset/actor/batch/evidence client against connected production Jobs and Forensics routes.
- Plan 80-12 can generate and adopt the manifest-owned ARIA and PNG evidence after production-route acceptance is green.
- Existing dependency advisories remain a separate maintenance concern; they do not block the fixture bridge and were not altered here.

## Self-Check: PASSED

- All four created files exist, and all three task commits contain only the eight declared task paths.
- Route-on, route-off, Hex exclusion, dual-generation Docker execution, denial parity, protected-file checksum, production absence, and artifact confidentiality checks are green.
- The user's unrelated dirty and untracked files remain untouched; `.planning/STATE.md` and `.planning/REQUIREMENTS.md` were not staged.

---
*Phase: 80-page-migration-wave-2-jobs-forensics*
*Completed: 2026-07-28*
