---
phase: 81-page-migration-wave-3-batches-workflows-lifeline
plan: 07
subsystem: testing
tags: [phoenix, playwright, postgres, fixtures, authorization]
requires:
  - phase: 80-page-migration-wave-2-jobs-forensics
    provides: test-only secret-gated connected fixture pattern
provides:
  - deterministic connected Batches, Workflows, and Lifeline fixtures
  - closed typed Phase 81 browser fixture client
  - native-host and Docker fixture contract evidence
affects: [phase-81-page-migrations, connected-browser-evidence, page-quality]
tech-stack:
  added: []
  patterns:
    - compile-time test-only fixture route with explicit opt-in and ephemeral credential
    - deterministic per-project public handles with closed response validation
key-files:
  created:
    - examples/phoenix_host/test/support/phase81_browser_fixtures.ex
    - examples/phoenix_host/test/phase81_browser_fixtures_test.exs
    - test/browser/support/phase81-fixtures.ts
    - test/browser/specs/phase81-fixtures.spec.ts
  modified:
    - examples/phoenix_host/config/test.exs
    - examples/phoenix_host/lib/phoenix_host_web/router.ex
    - scripts/with-showcase-server.sh
    - scripts/playwright-docker.sh
key-decisions:
  - "Keep Wave 3 fixture authority in a distinct compile-gated endpoint so accepted Phase 79/80 contracts remain unchanged."
  - "Return only deterministic public handles and finite state names; keep credentials, preview identities, snapshots, and domain authority server-side."
patterns-established:
  - "Fixture isolation: test environment plus explicit flag plus nonblank credential are all required."
  - "Bound evidence: seed every Wave 3 list at its render limit plus one."
requirements-completed: [PAGE-03, PAGE-04, PAGE-07, PAGE-10, A11Y-01, A11Y-02, A11Y-04]
duration: 35min
completed: 2026-07-29
status: complete
---

# Phase 81 Plan 07: Connected Wave 3 Fixture Bridge Summary

**Secret-gated deterministic Batches, Workflows, and Lifeline fixtures now run through both native-host and Docker Playwright paths.**

## Performance

- **Duration:** 35 min
- **Started:** 2026-07-29T02:36:00Z
- **Completed:** 2026-07-29T03:11:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added a POST-only Phase 81 test route with exact request schemas, constant-time credential checks, deterministic project/run isolation, actor setup, and explicit revoke/drift/duplicate/disconnect/interruption controls.
- Seeded all twelve Wave 3 bounded evidence families at their exact limit-plus-one cardinalities.
- Added a fail-closed TypeScript client that validates exact response keys and rejects missing credentials, malformed payloads, sensitive fields, and failed requests.
- Proved the six-test connected fixture contract through both the native showcase launcher and the authoritative Docker launcher.

## Task Commits

1. **Task 81-07-01: Add a test-only closed Wave 3 host fixture seam** - `4ca9aea`
2. **Task 81-07-02: Wire launcher credentials and a fail-closed browser client** - `6199d32`

## Files Created/Modified

- `examples/phoenix_host/test/support/phase81_browser_fixtures.ex` - compile-gated fixture authority, deterministic database seeds, and controllers.
- `examples/phoenix_host/test/phase81_browser_fixtures_test.exs` - enabled/off route, schema, cardinality, race, and confidentiality tests.
- `examples/phoenix_host/config/test.exs` - includes the Phase 81 opt-in in disposable browser-server configuration.
- `examples/phoenix_host/lib/phoenix_host_web/router.ex` - adds three POST-only fixture actions behind the test/flag gate.
- `scripts/with-showcase-server.sh` - generates and passes a distinct ephemeral Phase 81 credential.
- `scripts/playwright-docker.sh` - passes only the named Phase 81 credential into the browser container.
- `test/browser/support/phase81-fixtures.ts` - typed closed-schema fixture client.
- `test/browser/specs/phase81-fixtures.spec.ts` - runtime isolation, controls, denial, and confidentiality contract.

## Decisions Made

- Preserved Phase 79/80 endpoints and clients unchanged by implementing a sibling Phase 81 authority.
- Used deterministic UUIDs and fixed-size insert sets per project/run so repeated resets are identical and cross-project handles cannot collide.
- Kept fixture responses public-only; private reasons, raw evidence, preview capabilities, and credentials never cross the endpoint.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added current batch evidence columns to disposable test databases**

- **Found during:** Task 81-07-01
- **Issue:** The example host's original batch migration predates package fields used by the current Batches page, so a fresh connected fixture database lacked those columns.
- **Fix:** The explicitly enabled test-only reset seam adds the current columns with idempotent `ADD COLUMN IF NOT EXISTS` statements before seeding. Production and packaged migrations are unchanged.
- **Files modified:** `examples/phoenix_host/test/support/phase81_browser_fixtures.ex`
- **Verification:** Enabled host ExUnit and both connected browser launch paths pass.
- **Committed in:** `4ca9aea`

**2. [Rule 3 - Verification] Ran host ExUnit from the example-host application**

- **Found during:** Task 81-07-01 verification
- **Issue:** The plan's root-level `mix test examples/phoenix_host/...` invocation uses the root application and cannot load `PhoenixHostWeb.Endpoint`.
- **Fix:** Ran the same focused test from `examples/phoenix_host` with the host-relative test path, both with Phase 81 enabled and disabled.
- **Verification:** Enabled 4/4 and disabled 2/2 passed.

**Total deviations:** 2 auto-fixed (2 blocking/verification)
**Impact on plan:** Both changes were limited to disposable test infrastructure and preserved the production/package boundary.

## Issues Encountered

- Dependency resolution emitted pre-existing upstream advisory notices. They are recorded in `deferred-items.md`; no dependency changes were made in this plan.

## Verification Evidence

- `PHASE81_BROWSER_FIXTURES=1 mix test test/phase81_browser_fixtures_test.exs --seed 0` — 4 tests, 0 failures.
- `mix test test/phase81_browser_fixtures_test.exs --seed 0` — 2 tests, 0 failures with route/modules absent.
- `npx playwright test test/browser/specs/phase81-fixtures.spec.ts --project=chromium-wide --list` — 6 tests discovered.
- `npm run showcase:manifest` — passed.
- Native host runtime — 6 tests passed.
- Docker runtime — 6 tests passed.

## User Setup Required

None - both launchers generate the ephemeral credential automatically.

## Next Phase Readiness

- Production Batches migration work can consume the deterministic batch/member/callback handles.
- Workflows and Lifeline plans can exercise saturated lists and explicit authorization/execution race states without ambient seeds.
- No Plan 81-07 blocker remains.

## Self-Check: PASSED

- All four created fixture/client/spec files exist.
- Task commits `4ca9aea` and `6199d32` exist.
- Enabled, disabled, native-host, and Docker verification evidence is green.

---
*Phase: 81-page-migration-wave-3-batches-workflows-lifeline*
*Completed: 2026-07-29*
