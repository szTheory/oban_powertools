---
phase: 77-data-display-operator-patterns
plan: 07
subsystem: ui
tags: [playwright, axe, visual-regression, accessibility, security]
requires:
  - phase: 77-06
    provides: Schema-5 generated data stories and target-driven browser support
  - phase: 76-05
    provides: Canonical Docker Playwright renderer and scoped baseline workflow
provides:
  - Live browser proof for data-display semantics, interaction, responsive reflow, confidentiality, and bounded rendering
  - Exactly 120 canonical data-only PNG baselines across ten stories, four themes, and three projects
  - Independent manifest-derived baseline equality and Git screenshot change-scope gates
  - Nyquist-complete Phase 77 validation with an explicit unrelated aggregate residual boundary
affects: [phase-78, phase-79, phase-80, phase-81, browser-evidence]
tech-stack:
  added: []
  patterns: [LiveView readiness before interaction, manifest-derived baseline matrices, data-only visual evidence]
key-files:
  created:
    - test/browser/support/verify-data-baselines.mjs
    - test/browser/__screenshots__/chromium-*/showcase/data-*/*.png
    - .planning/phases/77-data-display-operator-patterns/77-07-SUMMARY.md
  modified:
    - test/browser/specs/data-display.behavior.spec.ts
    - test/browser/support/showcase.ts
    - examples/phoenix_host/priv/static/assets/js/app.js
    - .planning/phases/77-data-display-operator-patterns/77-VALIDATION.md
key-decisions:
  - "Require the example host and Playwright helper to reach LiveView's connected state before proving parent-owned events."
  - "Derive the exact data screenshot matrix independently from schema-5 manifest stories, themes, viewport dimensions, and project mappings."
  - "Keep Phase 77 completion focused: commit exactly 120 data baselines while preserving the 108 unrelated scenario-only aggregate residual."
patterns-established:
  - "Live browser fixtures wait for phx-connected before dispatching server-owned controls, preventing false interaction evidence and connection races."
  - "Baseline verification separates missing/extra equality from changed-screenshot scope so cardinality and isolation fail independently."
requirements-completed: [DATA-01, DATA-02, DATA-03, DATA-04, A11Y-02]
duration: 31 min
completed: 2026-07-12
status: complete
---

# Phase 77 Plan 07: Live Data Evidence and Baseline Closeout Summary

**Live 320/wide behavior, full structure and axe matrices, canonical Docker VRT, and independent exact-120 gates now close Phase 77 without touching unrelated baselines.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-07-12T23:54:15Z
- **Completed:** 2026-07-13T00:25:15Z
- **Tasks:** 2
- **Files modified:** 129

## Accomplishments

- Completed seven generated-target browser contracts that prove parent-owned click/Enter/Space sorting, one semantic table DOM, 320px labelled selection and 44px targets, all-theme keyboard focus, long-value expansion, bounded internal code scrolling, cross-channel redaction, truthful progress, notification urgency, and bounded 2,500-row evidence.
- Enabled real LiveView events in the Phoenix example host and hardened the shared showcase helper to wait for connection, select the server-owned viewport before applying theme, and eliminate a real browser-readiness race.
- Generated and visually reviewed exactly 120 Docker-rendered data baselines across ten stories, four themes, and three Chromium projects; the subsequent no-update comparison passed all 120.
- Added an independent Node verifier that rejects schema/theme/viewport drift, duplicate-derived paths, missing/extra data PNGs, wrong cardinality, and every changed screenshot outside the expected data matrix, including rename pairs.
- Reconciled every final task from `77-01-01` through `77-07-02` in `77-VALIDATION.md`, set Nyquist and Wave 0 complete only after all required live gates passed, and preserved the documented 108 scenario-only aggregate residual.

## Task Commits

1. **Task 77-07-01: Make focused data behavior green on 320 and wide**
   - d1b5a3c — enable real LiveView browser events in the example host and order viewport/theme preparation correctly
   - 6f1c46b — exercise the progress clamp with an over-max showcase fixture
   - 1031d30 — complete the seven live data-display behavior contracts
2. **Task 77-07-02: Generate data-only baselines and record focused Nyquist evidence**
   - a79714b — wait for LiveView readiness before shared showcase interaction
   - de5a084 — remove a pre-existing formatting defect that blocked the required repository-wide gate
   - 3f47a2d — add the exact baseline verifier, 120 canonical PNGs, and reconciled validation record

## Files Created/Modified

- test/browser/specs/data-display.behavior.spec.ts — Seven live interaction, responsive, focus, confidentiality, and bounded-data contracts.
- test/browser/support/verify-data-baselines.mjs — Independent exact-set/cardinality and changed-screenshot scope verifier.
- test/browser/__screenshots__/chromium-*/showcase/data-*/*.png — Exactly 120 canonical Docker-rendered data baselines.
- test/browser/support/showcase.ts — LiveView connection readiness plus stable viewport-before-theme preparation.
- examples/phoenix_host/lib/phoenix_host_web/endpoint.ex — Static mounts for Phoenix and LiveView browser clients.
- examples/phoenix_host/lib/phoenix_host_web/components/layouts/root.html.heex — Browser client script loading for the example host.
- examples/phoenix_host/priv/static/assets/js/app.js — CSRF-aware LiveSocket bootstrap.
- test/support/data_display_story_catalog.ex — Over-max progress fixture proving clamped rendering.
- test/mix/tasks/oban_powertools.install_test.exs — Minimal formatting-only correction needed by the full gate.
- .planning/phases/77-data-display-operator-patterns/77-VALIDATION.md — Final task/wave map, executed evidence, Nyquist sign-off, and residual boundary.

## Decisions Made

- Treated a rendered-but-disconnected example host as invalid behavior evidence. Browser setup now waits for `.phx-connected` before any parent-owned viewport, sorting, or dismissal event is exercised.
- Kept screenshot truth independent of Playwright discovery by deriving expected paths in a standalone Node process from the generated manifest and recursively comparing the on-disk set.
- Kept baseline change isolation as a separate mode that parses NUL-delimited Git porcelain, including both sides of rename/copy records, so unrelated tracked, deleted, renamed, or untracked screenshots fail explicitly.
- Preserved the Phase 76 aggregate boundary: focused Phase 77 gates are green, while `npm run visual:a11y` is not claimed globally green because 108 scenario-only failures remain outside this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Connected the Phoenix example host to LiveView**
- **Found during:** Task 77-07-01 live sorting RED
- **Issue:** The example host loaded a placeholder application script, so `phx-click` controls rendered but never reached `ShowcaseLive`.
- **Fix:** Served Phoenix/LiveView client assets, loaded them from the root layout, and bootstrapped a CSRF-aware `LiveSocket`.
- **Files modified:** `examples/phoenix_host/lib/phoenix_host_web/endpoint.ex`, `examples/phoenix_host/lib/phoenix_host_web/components/layouts/root.html.heex`, `examples/phoenix_host/priv/static/assets/js/app.js`
- **Verification:** Live behavior passed 14/14 across the required 320 and wide projects.
- **Committed in:** d1b5a3c

**2. [Rule 3 - Blocking] Stabilized server-owned viewport and theme preparation**
- **Found during:** Task 77-07-01 live behavior and Task 77-07-02 focused axe
- **Issue:** Applying theme before the viewport LiveView patch reset theme state, and one axe case clicked before the socket connected.
- **Fix:** Select viewport before applying theme and require `.phx-connected` before shared interactions.
- **Files modified:** `test/browser/support/showcase.ts`
- **Verification:** Behavior 14/14, structure 12/12, axe 120/120, and no-update VRT 120/120 passed after the final change.
- **Committed in:** d1b5a3c, a79714b

**3. [Rule 1 - Bug] Made the progress story actually prove clamping**
- **Found during:** Task 77-07-01 behavior contract completion
- **Issue:** The existing value `62/100` could not prove over-max clamping although the contract required truthful `100/100` output.
- **Fix:** Changed the deterministic fixture to `162/100`; component rendering clamps it to `100/100` and `100%`.
- **Files modified:** `test/support/data_display_story_catalog.ex`
- **Verification:** Catalog tests and the live progress behavior passed.
- **Committed in:** 6f1c46b

**4. [Rule 3 - Blocking] Removed a pre-existing formatter defect**
- **Found during:** Task 77-07-02 focused full gate
- **Issue:** Repository-wide `mix format --check-formatted` was blocked by one extra blank line in an unchanged install-task test.
- **Fix:** Removed only the extra blank line.
- **Files modified:** `test/mix/tasks/oban_powertools.install_test.exs`
- **Verification:** Its seven focused tests passed and the repository-wide format gate became green.
- **Committed in:** de5a084

---

**Total deviations:** 4 auto-fixed (1 bug, 3 blocking)
**Impact on plan:** All fixes were necessary to make the specified live evidence truthful and the mandatory closeout gate executable. No dependency, production page migration, scenario baseline refresh, or scope expansion was introduced.

## Issues Encountered

- The first full focused axe run passed 119 tests and exposed one tablet connection race in shared setup. The failing case passed after the readiness fix, then the complete 120-test matrix was rerun and passed.
- Hex printed existing dependency advisory/authentication warnings during example-host setup. They did not change dependencies or block the focused phase gates.

## Verification

- Focused structure/VRT/axe discovery — 252 tests listed across three Chromium projects.
- Data-display behavior discovery — 21 tests listed; required 320/wide execution passed all 14.
- Complete live structure — all 12 project/theme combinations passed.
- Focused axe — all 120 data story/theme/project cases passed after the connection-race correction.
- Canonical Docker VRT update — all 120 data cases passed and wrote exactly 120 PNGs.
- Canonical no-update Docker VRT compare — all 120 data cases passed against the final harness.
- Independent baseline equality — `data baselines ok: 120`.
- Independent changed scope — 120 changed screenshot paths, all inside the exact manifest-derived data matrix.
- Focused full gate — repository formatting and warnings-as-errors compile passed; 60 ExUnit tests passed; schema-5 manifest smoke reported 10 data stories and 41 total targets.
- Source audit — no dynamic atom conversion, raw HTML, inline style/width, grid role, table hook, or raw/redacted dual-secret assign.
- Representative 320/high-contrast, tablet/dark, and wide/light screenshots were visually inspected; no non-data screenshot changed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 77 is implementation- and Nyquist-complete for DATA-01..04 and A11Y-02 at the shared component/showcase level.
- Phase 78 may compose these primitives into operator meta-components; Phases 79–81 may migrate production pages using the validated taxonomy and data-display contracts.
- The 108 scenario-only VRT residual remains explicitly owned outside this phase and must still prevent an aggregate visual-green claim until its owning work resolves it.

## Self-Check: PASSED

- All plan-owned source, verifier, validation, and summary files exist.
- Exactly 120 expected data PNGs exist and the independent changed-scope gate reports no unrelated screenshot change.
- Every task commit is present in git history and the final validation record is Nyquist compliant.
- All required focused browser, ExUnit, manifest, formatting, compile, and source-audit gates passed against the final harness.

---
*Phase: 77-data-display-operator-patterns*
*Completed: 2026-07-12*
