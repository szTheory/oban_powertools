---
phase: 12-fresh-host-install-path-example-fixture-repair
plan: 01
subsystem: testing
tags: [igniter, phoenix, ecto, oban, installer]
requires:
  - phase: 11-docs-example-app-compatibility-contract-proof
    provides: canonical host seam examples and layered host-contract proof patterns
provides:
  - structural installer regression coverage for generated host contract markers
  - fresh-host execution proof from `mix phx.new` through install, compile, reset, and boot
  - native-only router and migration hardening required by the repaired installer path
affects: [phase-12, docs, installer, host-contract, native-only]
tech-stack:
  added: []
  patterns: [split structural-vs-execution proof lanes, macro-expansion optional dependency gating, deterministic migration timestamping]
key-files:
  created: [test/support/fresh_host_contract.ex, test/oban_powertools/fresh_host_contract_test.exs]
  modified: [lib/mix/tasks/oban_powertools.install.ex, lib/oban_powertools/web/router.ex, test/mix/tasks/oban_powertools.install_test.exs]
key-decisions:
  - "Keep the fast structural installer regression source-based, and move real fresh-host execution into a separate helper-backed lane."
  - "Bypass Igniter root-path config helpers in fresh hosts by writing the Powertools keys through nested config insertion while preserving the grouped public contract."
  - "Resolve the optional `oban_web` bridge at macro expansion time so native-only hosts never compile against `Oban.Web.Router`."
patterns-established:
  - "Structural installer assertions should lock exact generated markers without taking on compile or boot proof."
  - "Fresh-host contract tests should generate a real Phoenix host, patch only true host-owned seams, and exercise install-to-boot end to end."
requirements-completed: [PKG-01]
duration: 18min
completed: 2026-05-22
---

# Phase 12 Plan 01: Fresh Host Installer Repair Summary

**Fresh Phoenix hosts now install Oban Powertools through deterministic config, seam, route, and migration generation with separate structural and end-to-end proof lanes**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-22T13:38:00Z
- **Completed:** 2026-05-22T13:56:40Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Replaced the old broad installer source test with a focused structural contract that asserts config keys, seam modules, host-owned routing, migrations, and the absence of a hard `oban_web` dependency.
- Repaired the installer so fresh hosts get auth and display-policy starter seams, explicit repo wiring for every generated migration, and deterministic migration timestamps.
- Added a real `mix phx.new` proof lane that installs the library into a temp host, fills only the host-owned seams, runs `mix ecto.reset`, and proves one successful application boot without `oban_web`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Keep the installer structural regression focused on generated contract markers** - `6086f94` (test), `a1fed86` (fix)
2. **Task 2: Repair the Igniter install pipeline to emit the full thin host contract** - `a1fed86` (fix)
3. **Task 3: Add a separate fresh-host execution proof lane for compile, migrate, and boot** - `75d0597` (test), `a575ba6` (fix)

## Files Created/Modified
- `lib/mix/tasks/oban_powertools.install.ex` - Generates both starter seams, uses fresh-host-safe config insertion, passes an explicit repo to every migration, and assigns distinct migration timestamps.
- `lib/oban_powertools/web/router.ex` - Gates the optional `oban_web` bridge at macro expansion time so native-only hosts compile cleanly.
- `test/mix/tasks/oban_powertools.install_test.exs` - Fast structural regression for generated contract markers and optional dependency posture.
- `test/support/fresh_host_contract.ex` - Temp-host harness for `mix phx.new`, local dependency wiring, install, seam fill-in, reset, and boot proof.
- `test/oban_powertools/fresh_host_contract_test.exs` - End-to-end assertion lane for config, router, seam modules, compile, reset, and boot evidence.

## Decisions Made
- Kept the grouped `config :oban_powertools` contract as the public target, but relied on nested Igniter key insertion internally because the root-path helper crashes on fresh Phoenix apps.
- Treated native-only compilation without `oban_web` as a correctness requirement, so the router macro now emits zero `Oban.Web.Router` references unless that module is already loaded in the host compile environment.
- Used deterministic timestamp offsets across the Powertools migration set so one installer run can emit many migrations without duplicate Ecto versions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed the crashing Igniter root-path config flow**
- **Found during:** Task 3 (Add a separate fresh-host execution proof lane for compile, migrate, and boot)
- **Issue:** Both `configure_group/6` and root-path `configure_new/6` crashed on a brand-new Phoenix host before any config was written.
- **Fix:** Switched the installer to nested Powertools key insertion while preserving the grouped host contract markers in the structural regression.
- **Files modified:** `lib/mix/tasks/oban_powertools.install.ex`
- **Verification:** `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/fresh_host_contract_test.exs`
- **Committed in:** `a575ba6`

**2. [Rule 3 - Blocking] Passed the fresh host repo explicitly into every generated migration**
- **Found during:** Task 3 (Add a separate fresh-host execution proof lane for compile, migrate, and boot)
- **Issue:** `Igniter.Libs.Ecto.gen_migration/4` received `nil` and failed to determine the host repo in a generated Phoenix app.
- **Fix:** Added a shared `repo_module/1` helper and threaded it through the full migration pipeline.
- **Files modified:** `lib/mix/tasks/oban_powertools.install.ex`
- **Verification:** `mix test test/oban_powertools/fresh_host_contract_test.exs`
- **Committed in:** `a575ba6`

**3. [Rule 2 - Missing Critical] Removed native-only compile coupling to `Oban.Web.Router`**
- **Found during:** Task 3 (Add a separate fresh-host execution proof lane for compile, migrate, and boot)
- **Issue:** A fresh host without `oban_web` still failed to compile because the router macro expanded a bridge reference into host code.
- **Fix:** Moved optional bridge resolution into macro expansion time and only emit bridge AST when `Oban.Web.Router` is present.
- **Files modified:** `lib/oban_powertools/web/router.ex`
- **Verification:** `mix test test/oban_powertools/fresh_host_contract_test.exs`
- **Committed in:** `a575ba6`

**4. [Rule 1 - Bug] Made the generated migration set unique and rerunnable in proof**
- **Found during:** Task 3 (Add a separate fresh-host execution proof lane for compile, migrate, and boot)
- **Issue:** Multiple Powertools migrations were generated in the same second, then repeated proof runs collided with existing fresh-host tables.
- **Fix:** Assigned deterministic timestamp offsets per migration and switched the proof lane to `mix ecto.reset`.
- **Files modified:** `lib/mix/tasks/oban_powertools.install.ex`, `test/support/fresh_host_contract.ex`
- **Verification:** `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/fresh_host_contract_test.exs`
- **Committed in:** `a575ba6`

---

**Total deviations:** 4 auto-fixed (2 bug, 1 missing critical, 1 blocking)
**Impact on plan:** All deviations were required to make the documented fresh-host path executable and native-only safe. No scope creep beyond installer correctness.

## Issues Encountered
- Fresh-host execution surfaced multiple latent installer defects that the prior source-only regression could not see: crashing config insertion, missing repo selection for migrations, native-only router compile breakage, and duplicate migration versions.

## User Setup Required

None - no external service configuration required.

## Known Stubs

- `lib/mix/tasks/oban_powertools.install.ex:54` - Generated auth seam still contains a TODO for current-actor lookup because session/auth policy remains host-owned by design.
- `lib/mix/tasks/oban_powertools.install.ex:62` - Generated auth seam still contains a TODO for authorization logic because production operator policy cannot be synthesized safely by the installer.
- `lib/mix/tasks/oban_powertools.install.ex:68` - Generated auth seam still contains a TODO for audit principal shaping because durable attribution fields are host-owned.
- `lib/mix/tasks/oban_powertools.install.ex:88` - Generated display-policy seam still contains a TODO for redaction/formatting because visible data policy is intentionally host-owned.

## Next Phase Readiness
- The public `mix phx.new` install path now has both a fast structural regression and a real execution proof lane, so Phase 12 can move on to fixture provenance and first-session evidence.
- No blockers remain for `12-02`, but its fixture/docs work should reuse the same generated seam and migration truths this plan established.

## Self-Check: PASSED

- Verified `.planning/phases/12-fresh-host-install-path-example-fixture-repair/12-01-SUMMARY.md` exists.
- Verified task commits `6086f94`, `a1fed86`, `75d0597`, and `a575ba6` exist in git history.
