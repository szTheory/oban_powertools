---
phase: 81-page-migration-wave-3-batches-workflows-lifeline
plan: 02
subsystem: web
tags: [elixir, phoenix-liveview, batches, security, accessibility]
requires:
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 01
    provides: RED finite presenter, selector, and page-composition contracts
  - phase: 81-page-migration-wave-3-batches-workflows-lifeline
    plan: 07
    provides: isolated secret-gated Wave 3 connected fixtures
provides:
  - closed bounded Batches row, detail, and retry-preview presentation maps
  - pure Batches index and detail composition with shared production components
  - repository-side member and callback LIMIT-plus-one reads
  - connected mixed-selection and authorization-race acceptance evidence
affects: [81-03, 81-04, 81-05, 81-06, 81-08]
tech-stack:
  added: []
  patterns:
    - project authorized domain values into exact finite presenter maps before rendering
    - retain preview and mutation authority only in parent-owned LiveView state
    - read bounded collections with LIMIT plus one and render explicit completeness guidance
key-files:
  created: []
  modified:
    - lib/oban_powertools/web/control_plane_presenter.ex
    - lib/oban_powertools/web/batches_live.ex
    - lib/oban_powertools/batches.ex
    - test/oban_powertools/web/operator_pattern_presenter_test.exs
    - test/oban_powertools/web/live/batches_live_test.exs
    - examples/phoenix_host/test/support/phase81_browser_fixtures.ex
    - examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex
key-decisions:
  - "Batches.get/3 owns member and callback LIMIT-plus-one reads so the repository boundary, not only presentation, is finite."
  - "Eligible failed members sort before the finite cap while mixed member history remains visible and selection stays page-local."
  - "Callback retry presentation exposes consequence-only projections while raw preview authority remains socket-owned for execution."
  - "The Phase 81 example fixture uses the host's ops_actor session contract and a test-only dynamic authorization bridge for deterministic revoke races."
requirements-completed: [PAGE-03]
duration: 34min
completed: 2026-07-29
status: complete
---

# Phase 81 Plan 02: Batches Migration Summary

**Batches now renders through closed, bounded presentation maps and pure shared composition while preserving server-owned retry authorization, preview, execution, and Audit behavior.**

## Performance

- **Duration:** 34 min
- **Completed:** 2026-07-29
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added exact Batches row, detail, and retry-preview projections with 50/25/50/25 render caps, LIMIT-plus-one completeness detection, structural allowlisting, and no preview token, plan hash, snapshot, payload, or raw error authority in rendered maps.
- Rebuilt the Batches list/detail UI around public `page_content/1` and `detail_page_content/1` seams, shared status/progress presentation, stable roots, one semantic responsive tree, bounded history, and accessible confirmation dialogs.
- Preserved page-local eligible selection, Lifeline-owned callback and failed-job recovery, server-side reauthorization, stale-state handling, canonical URLs, Oban Web bridge links, and durable Audit evidence.
- Proved the connected production route with 50 rendered members, 25 callbacks, mixed selection, reason-required retry preview, uniform revoke-race failure, and no URL mutation authority.

## Task Commits

1. **Task 81-02-01: Implement exact closed Batches presentation maps** — `ec83e5a`
2. **Task 81-02-02: Rebuild Batches on pure shared composition** — `778d46f`

## Evidence

- Focused presenter and Batches LiveView test command — **42/42 green**
- Warnings-as-errors production compile — passed
- Secret-gated example-host Phase 81 fixture test command — **4/4 green**
- Connected Playwright Batches detail contract on `chromium-wide` — passed
- Connected Playwright Batches authorization-race contract on `chromium-wide` — passed
- Scoped `git diff --check` — passed

## Deviations from Plan

### Auto-fixed

**1. Added repository-side bounds in `Batches.get/3`**

- **Found during:** Task 81-02-02
- **Issue:** A presentation-only cap would still materialize unbounded member and callback collections before rendering.
- **Fix:** Added optional finite member/callback reads and SQL `LIMIT + 1` queries, with eligible failed members ordered first.
- **Files:** `lib/oban_powertools/batches.ex`
- **Verification:** Focused tests and connected saturated fixture passed.

**2. Completed the Phase 81 fixture's deterministic Batch member bridge**

- **Found during:** Connected Batches acceptance
- **Issue:** Seeded `BatchJob` rows referenced absent `oban_jobs`, making every visible failed member ineligible and preventing honest mixed-selection proof.
- **Fix:** Seeded deterministic matching Oban jobs and cleaned them with the scoped fixture.
- **Files:** `examples/phoenix_host/test/support/phase81_browser_fixtures.ex`
- **Verification:** Fixture contract and connected mixed-selection case passed.

**3. Wired the fixture's authorization race through the example host boundary**

- **Found during:** Connected authorization-race acceptance
- **Issue:** The fixture stored revoke state but used a session key the host auth seam did not read, so the browser remained `ops-demo`.
- **Fix:** Used the existing `ops_actor` session contract, attached the scoped fixture key, and dynamically consulted the test-only fixture state from the example host authorization callback.
- **Files:** `examples/phoenix_host/test/support/phase81_browser_fixtures.ex`, `examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex`
- **Verification:** The connected revoke case now reports permission change and leaves action and preview authority out of the URL.

## Issues Encountered

- The first combined browser rerun used a nonexistent `chromium` project; the configured desktop project is `chromium-wide`. Re-running against the configured project reached the application contract.
- Dependency resolution printed pre-existing advisory notices for locked packages. No dependency or lockfile change was made.
- A pre-existing optional-default warning remains in the focused Batches test helper; it does not fail the warnings-as-errors production compile gate.

## Security and Threat Review

- Selected retry targets remain finite, page-local, eligible-only, and revalidated at the existing server authorization and Lifeline boundaries.
- Presenter output excludes raw payloads, provider errors, snapshots, reasons, preview tokens, and plan hashes.
- Repository reads and rendered collections are bounded independently.
- Authorization changes fail with uniform operator-facing copy and no action or preview token in URL state.

## Known Stubs

The non-Batches Wave 3 presenter seams remain closed unavailable placeholders for their owning Workflows and Lifeline plans. No Batches behavior is stubbed.

## TDD Gate Compliance

Plan 81-01 supplied the RED contracts. This plan made the Batches-specific contracts GREEN without weakening them; focused tests, fixture tests, compile, and the two connected Batches cases all pass.

## Next Phase Readiness

- Batches is ready for catalog/showcase integration and aggregate Phase 81 validation.
- Workflows and Lifeline can reuse the finite presenter constants and closed-seam structure established here.
- The corrected Phase 81 actor/race fixture contract is available to later connected acceptance cases.

## Self-Check: PASSED

- Both task commits exist.
- All seven plan-scoped implementation and test files are committed.
- Focused, compile, fixture, and connected Batches verification is green.
- No unrelated dirty worktree files were staged or committed.

---
*Phase: 81-page-migration-wave-3-batches-workflows-lifeline*
*Completed: 2026-07-29*
