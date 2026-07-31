---
phase: 79-page-migration-wave-1-overview-cron-limiters-audit
plan: 10
subsystem: testing
tags: [playwright, phoenix, postgres, browser-fixtures, security]

requires:
  - phase: 79-page-migration-wave-1-overview-cron-limiters-audit
    provides: Overview, Cron, Limiter, Audit, and connected-browser contracts from Plans 79-03 through 79-09
provides:
  - Test-only authenticated Phoenix reset, actor, and recovery fixture seam
  - Disposable per-run PostgreSQL launcher with exact database cleanup
  - Fail-closed Playwright helpers and concurrent Docker-connected lifecycle proof
affects: [79-11, 79-12, connected-page-evidence, browser-a11y]

tech-stack:
  added: []
  patterns:
    - Compile-time opt-in fixture modules with Mix recompile hooks and runtime secret authentication
    - Name-only Docker environment forwarding for ephemeral credentials
    - Project-and-run keyed deterministic browser fixture resets

key-files:
  created:
    - examples/phoenix_host/test/support/phase79_browser_fixtures.ex
    - examples/phoenix_host/test/phase79_browser_fixtures_test.exs
    - test/browser/support/phase79-fixtures.ts
    - test/browser/specs/phase79-fixtures.spec.ts
  modified:
    - examples/phoenix_host/config/test.exs
    - examples/phoenix_host/lib/phoenix_host_web/router.ex
    - scripts/with-showcase-server.sh
    - scripts/playwright-docker.sh

key-decisions:
  - "Use a unique launcher build path plus Mix recompile hooks so fixture routes and modules follow the explicit opt-in flag across back-to-back runs."
  - "Keep fixture responses closed and public-only while carrying the ephemeral credential exclusively in a request header and Docker environment name."
  - "Open the real Cron preview before applying recovery perturbations; use a future scheduled active job for deterministic skipped and partial evidence."

patterns-established:
  - "Fixture isolation: every reset is keyed by a closed Playwright project and run tag, and deletes only rows bearing that identity."
  - "Fail closed: missing local credentials stop before network I/O, while missing and invalid HTTP credentials share the same empty 404."

requirements-completed:
  - PAGE-01
  - PAGE-05
  - PAGE-06
  - PAGE-08
  - PAGE-10
  - A11Y-*

duration: 1h 19m
completed: 2026-07-19
status: complete
---

# Phase 79 Plan 10: Connected Browser Fixture Harness Summary

**A deterministic test-only Phoenix seam now drives disposable-database Playwright runs without ambient seeds, production exposure, or fixture-credential disclosure.**

## Performance

- **Duration:** 1h 19m
- **Started:** 2026-07-19T21:47:23Z
- **Completed:** 2026-07-19T23:05:57Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added exactly three opt-in fixture POST routes with constant-time secret verification, deterministic project/run resets, actor sessions, and five real-preview recovery perturbations.
- Reworked the connected launcher around one validated `phoenix_host_test_phase79_*` database, an isolated build cache, exact cleanup, and name-only Docker secret forwarding.
- Added closed-schema TypeScript helpers and Docker lifecycle coverage; the pinned Chromium run passed 6/6 and the npm wrapper's stronger concurrent three-project run passed 18/18.

## Task Commits

Each task was committed atomically, including explicit TDD gates:

1. **Task 79-10-01: Opt-in host fixture seam**
   - `1e05040` — RED fixture seam contract
   - `02a020c` — deterministic host fixture implementation
   - `3bd6af2` — fixture browser WebSocket origin
   - `5958c50` — active Cron preview perturbations
   - `d12c3f7` — back-to-back opt-in gate recompilation
2. **Task 79-10-02: Disposable database and Docker secret bridge**
   - `cabf436` — isolated launcher and name-only Docker forwarding
   - `e2031e3` — isolated fixture server build cache
   - `3ac956e` — reliable isolated build cleanup
   - `e5cb1bd` — quiet cleanup retry
3. **Task 79-10-03: Fail-closed browser proof**
   - `67c5053` — RED connected fixture contract
   - `8558b1b` — validated TypeScript helpers and connected proof
   - `acda8db` — collision-free concurrent project isolation

## Files Created/Modified

- `examples/phoenix_host/config/test.exs` — Enables only opted-in test-server routes, normal pooling, and browser WebSocket origin handling.
- `examples/phoenix_host/lib/phoenix_host_web/router.ex` — Adds the three exact test-only fixture mappings and environment-gate recompilation.
- `examples/phoenix_host/test/support/phase79_browser_fixtures.ex` — Implements deterministic reset/auth/recovery domain behavior and the concrete controller.
- `examples/phoenix_host/test/phase79_browser_fixtures_test.exs` — Proves idempotency, isolation, closed responses, auth denial, recovery scope, and route absence.
- `scripts/with-showcase-server.sh` — Owns the validated disposable database, isolated build, server, secret, and cleanup lifecycle.
- `scripts/playwright-docker.sh` — Conditionally forwards only the fixture environment variable name.
- `test/browser/support/phase79-fixtures.ts` — Validates credentials, projects, response schemas, identities, and exact fixture counts.
- `test/browser/specs/phase79-fixtures.spec.ts` — Exercises reset, actor, recovery, availability, and denial contracts through Docker.

## Decisions Made

- A unique `MIX_BUILD_PATH` isolates the connected test server from ordinary host-test artifacts; Mix recompile hooks reevaluate the flag when route-on and route-off tests share the ordinary test build.
- The fixture HTTP contract exposes only stable names, counts, and states. Preview tokens, plan hashes, metadata, raw errors, and the ephemeral credential remain server-side.
- Recovery tests wait for the real confirmation dialog before perturbing its persisted preview. The recovery Cron entry uses `skip`, and a future scheduled job prevents Oban from consuming overlap evidence before submission.
- Read-only session switching is proven on the unrestricted showcase surface because the current host auth policy redirects read-only actors away from Cron; dedicated page authorization evidence remains owned by the final connected page plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Isolated fixture-server compilation from stale test build state**
- **Found during:** Task 79-10-03 connected verification
- **Issue:** A prior route-off test build could fail Phoenix compile-environment validation when the launcher reused it.
- **Fix:** Added a validated per-run build path, then replaced the database-partition sentinel with Mix recompile hooks for ordinary back-to-back route tests.
- **Files modified:** `scripts/with-showcase-server.sh`, `examples/phoenix_host/config/test.exs`, `examples/phoenix_host/lib/phoenix_host_web/router.ex`, `examples/phoenix_host/test/support/phase79_browser_fixtures.ex`
- **Verification:** Exact route-on then route-off tests pass; the disposable server passes its full connected run.
- **Commits:** `e2031e3`, `d12c3f7`

**2. [Rule 1 - Bug] Allowed the Docker browser's LiveView WebSocket origin**
- **Found during:** Task 79-10-03 connected verification
- **Issue:** Static HTML loaded through Docker, but the test endpoint rejected the non-local browser origin and never reached `phx-connected`.
- **Fix:** Disabled origin checking only for the explicitly opted-in fixture test server.
- **Files modified:** `examples/phoenix_host/config/test.exs`
- **Verification:** Connected showcase and Cron LiveViews reach `phx-connected` in Docker.
- **Commit:** `3bd6af2`

**3. [Rule 1 - Bug] Applied recovery perturbations to the page-owned real preview**
- **Found during:** Task 79-10-03 recovery proof
- **Issue:** Preparing drift before opening the dialog let the page create a fresh matching preview; unscheduled overlap jobs could also be consumed before execution.
- **Fix:** Wait for the real preview, perturb that ready record, drift an included plan-hash field, and schedule overlap evidence in the future.
- **Files modified:** `examples/phoenix_host/test/support/phase79_browser_fixtures.ex`, `test/browser/specs/phase79-fixtures.spec.ts`
- **Verification:** Expired, out-of-date, consumed, skipped, and partial states all retain recovery UI with no success receipt.
- **Commit:** `5958c50`

**4. [Rule 1 - Bug] Removed cross-project isolation-tag collisions**
- **Found during:** Exact npm Docker wrapper verification
- **Issue:** The wrapper ran all three Playwright projects concurrently, and two workers chose the same cross-project run identity.
- **Fix:** Included the source project in every isolation-proof run tag.
- **Files modified:** `test/browser/specs/phase79-fixtures.spec.ts`
- **Verification:** Concurrent wrapper run passes 18/18.
- **Commit:** `acda8db`

**5. [Rule 1 - Bug] Retried asynchronous build-directory cleanup**
- **Found during:** Repeated disposable-server verification
- **Issue:** A just-terminated BEAM process could briefly race removal of its unique build directory.
- **Fix:** Retry the already validated exact path after one second without widening the deletion target.
- **Files modified:** `scripts/with-showcase-server.sh`
- **Verification:** Connected commands return success after dropping the database and cleaning the build.
- **Commits:** `3ac956e`, `e5cb1bd`

---

**Total deviations:** 5 auto-fixed (4 bugs, 1 blocking issue)
**Impact on plan:** All fixes were necessary to make the specified isolated and concurrent lifecycle deterministic; the cumulative implementation remains limited to the eight planned files.

## Issues Encountered

- Hex reported an expired user session and advisories for existing pinned dependencies while resolving the example host. All required public dependencies were already available; the plan intentionally made no dependency or lockfile changes.
- The `visual:a11y` npm wrapper did not forward its trailing project filter into its nested npm script, so the exact command exercised all three configured projects. The resulting 18-test concurrent run passed and is stronger than the requested six-test project proof.

## User Setup Required

None - the launcher generates its credential and disposable database identity for every run.

## Next Phase Readiness

- Plans 79-11 and 79-12 can consume the reset, actor, and recovery helpers without ambient seeds or optional skips.
- No dependency, lockfile, production route, migration, packaged JavaScript, or screenshot baseline changed.

## Self-Check: PASSED

- All four created files and four modified files exist.
- All twelve task and corrective commits are present in Git history.
- Cumulative plan diff contains exactly the eight paths listed in `79-10-PLAN.md`.
- Host route-on (5/5), route-off (1/1), release regression (37/37), pinned Docker (6/6), and concurrent wrapper (18/18) verification passed.
- Generated Playwright artifacts contain neither fixture credential headers nor environment-variable content.

---
*Phase: 79-page-migration-wave-1-overview-cron-limiters-audit*
*Completed: 2026-07-19*
