---
phase: 79-page-migration-wave-1-overview-cron-limiters-audit
plan: 06
subsystem: ui
tags: [audit, liveview, pagination, structural-redaction, phoenix-components]
requires:
  - phase: 79-page-migration-wave-1-overview-cron-limiters-audit
    provides: bounded Audit.page/2 reads, finite Audit presenters, and Wave 1 RED contracts
  - phase: 78-component-groups-meta-components
    provides: FilterBar, DataTable, DetailSurface, AuditEntry, Forms, and Primitives
provides:
  - Filter-scoped non-enumerating Audit.fetch_in_scope/3 lookup
  - Canonical exact-filter, page, and selected-event URL state
  - Bounded normalized Audit row/detail assigns with structural metadata redaction
  - Public pure AuditLive.page_content/1 composition seam
affects: [79-07, 79-08, 79-10, audit, page-stories, visual-regression]
tech-stack:
  added: []
  patterns: [scoped immutable lookup, normalized render boundary, URL-owned scan detail]
key-files:
  created: []
  modified:
    - lib/oban_powertools/audit.ex
    - lib/oban_powertools/web/audit_live.ex
    - test/oban_powertools/audit_test.exs
    - test/oban_powertools/web/live/audit_live_test.exs
key-decisions:
  - "Combine selected Audit ID and every active exact filter in one query and return the same error for malformed, missing, or mismatched records."
  - "Project metadata through a narrow plain-map allowlist before the shared Audit presenters, then retain only normalized rows, detail, and page metadata in render assigns."
  - "Keep first selection as a history push, selection switches and close as replacements, and every canonical URL ordered resource_type, resource_id, event_type, page, event."
patterns-established:
  - "Audit render boundary: repository schemas exist only inside parameter-loading helpers and are immediately reduced to finite presenter maps."
  - "Audit composition boundary: public page_content/1 renders supplied normalized state only through FilterBar, DataTable, DetailSurface, and AuditEntry."
requirements-completed: [PAGE-08, PAGE-10, COPY-01, A11Y-*, MOTION-*]
duration: 22 min
completed: 2026-07-19
status: complete
---

# Phase 79 Plan 06: Bounded Audit Scan and Immutable Evidence Summary

**Audit now provides a stable 20-row read-only scan plus one filter-scoped, URL-owned immutable evidence detail with structural redaction before render.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-07-19T21:04:37Z
- **Completed:** 2026-07-19T21:26:47Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `Audit.fetch_in_scope/3`, which normalizes positive IDs, combines the ID and all active exact filters in one SQL query, and gives malformed, missing, and mismatched selections the same `:error` result.
- Preserved the exact three Audit filters while composing canonical page and event state in ordered URLs; applying or removing filters resets page/selection, pagination retains filters, and selection/close use the required push/replace history behavior.
- Replaced raw schema/metadata assigns with fixed-size normalized presenter maps, a schemaless filter form, human active filters, exact result summaries, safe pagination paths, and plain repair-retention copy.
- Structurally projected actor, reason, outcome, source, correlation, changes, and evidence before presenter use while excluding command keys, tokens, hashes, credentials, exceptions, stacktraces, provider blobs, and raw errors from render-intended assigns and the complete DOM.
- Rebuilt Audit through the shared FilterBar, DataTable, DetailSurface, AuditEntry, Forms, and Primitives components with one H1, one semantic table tree, exact empty/error copy, distinct target/evidence controls, and no mutation, checkbox, bulk, refresh, live-tail, or causal-timeline affordance.
- Exported pure `AuditLive.page_content/1` for deterministic page stories without repository work, authorization, URL parsing, current-time lookup, or mutation.

## Task Commits

Each implementation task was committed atomically; Task 1 retained its explicit TDD RED contract commit:

1. **Task 79-06-01 RED: Pin scoped Audit lookup and canonical filter links** - `87833ae` (test)
2. **Task 79-06-01 GREEN: Add scoped Audit selection and URL state** - `f50e4b1` (feat)
3. **Task 79-06-02: Build bounded normalized row/detail assigns outside render** - `b29672f` (feat)
4. **Task 79-06-03: Compose reusable Audit scan and immutable detail** - `6b15e1f` (feat)

## Files Created/Modified

- `lib/oban_powertools/audit.ex` - Exact-filter selected-event lookup with one bounded query and indistinguishable failure semantics.
- `lib/oban_powertools/web/audit_live.ex` - Canonical URL orchestration, schema-to-presentation projection, bounded retention copy, and public pure page composition.
- `test/oban_powertools/audit_test.exs` - Exact filter/mismatch/malformed lookup coverage and telemetry proof of the bounded single-query lookup shape.
- `test/oban_powertools/web/live/audit_live_test.exs` - Pagination, URL history, filters, pure composition, normalized assigns, confidentiality, immutable detail, empty/error, authorization, and read-only regressions.

## Decisions Made

- The selected lookup never fetches globally and compares afterward. ID and scope are expressed together in the database query, so out-of-scope existence is not disclosed.
- The metadata projection accepts only finite text facts, a three-field principal projection used transiently by DisplayPolicy, a closed outcome state, and recursively allowlisted `field/before/after/label/value/items` evidence. Evidence collections are capped before rendering.
- Raw `%Audit{}` values are short-lived inside `load_audit_state/1`; only plain row/detail maps and page metadata are assigned for rendering. The selected detail retains the complete policy-safe reason while table reasons abbreviate only after policy.
- Repair archive status is reduced to a separate ledger count/run sentence. It makes no whole-Audit retention guarantee and never says archived repairs appear in the live scan.
- The DataTable keeps its component-owned row identity while each event cell also exposes the required stable `audit-record-{id}` semantic marker. Direct detail URLs outside the current 20-row window restore focus to the table fallback.
- The selected AuditEntry remains immutable past-tense evidence. Missing reason, outcome, source, and correlation use the exact shared copy and are never inferred from row ID, event suffix, or command key.

## Verification

- Consolidated Plan 79-06 suite - PASS, **80 tests, 0 failures** across Audit query, AuditLive, shared presenter, OperatorPatterns, and DataDisplay coverage.
- `mix test test/oban_powertools/web/live/audit_live_test.exs --seed 0` - PASS, 11 tests.
- `mix test test/oban_powertools/audit_test.exs test/oban_powertools/web/operator_pattern_presenter_test.exs --seed 0` - PASS, 22 tests.
- `mix test test/oban_powertools/web/components/operator_patterns_test.exs test/oban_powertools/web/components/data_display_test.exs --seed 0` - PASS, 47 tests.
- `mix compile --warnings-as-errors` - PASS.
- Plan-scoped `mix format --check-formatted` and `git diff --check` - PASS.
- Query/source gates - PASS: fixed 20-row paging, one filter-scoped selected query, no `Audit.list_all`, repository work outside `page_content/1`, and only `apply_filters`, `select_event`, and `close_detail` handlers.
- Full-DOM and assign confidentiality gates - PASS: raw Audit schemas, metadata keys, credentials, preview tokens, plan hashes, command keys, exceptions, stacktraces, and raw errors remain absent while genuine allowlisted evidence renders.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion; changes remain inside the declared Audit query, LiveView, and focused test files.

## Issues Encountered

- The shared presenter intentionally rejects prohibited metadata anywhere in its input. AuditLive therefore constructs a transient allowlisted `%Audit{}` copy before presenter calls rather than passing the raw metadata map and relying on output filtering.
- The shared DataTable owns its `<tr>` ID format. Audit retains that component identity and places the required `audit-record-{id}` semantic marker in the corresponding Event cell without creating a second responsive tree.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 79-07 can style the stable `audit-page`, retention, FilterBar, DataTable, pagination, detail, and AuditEntry hooks across narrow and wide layouts.
- Plan 79-08 can render empty, filtered-boundary, selected-long, and selected-missing-field stories directly through public pure `page_content/1`.
- Plan 79-10 can exercise canonical filter/page/event navigation, adaptive detail focus/history, and confidential DOM absence in the authenticated browser harness.
- No unresolved high-severity authorization, IDOR, injection, confidentiality, availability, evidence-truth, or accessibility threat remains in this plan's scope.

## Self-Check: PASSED

- All four task commits resolve in order and contain only the declared production/test work; unrelated pre-existing planning deletions and untracked files remain untouched and unstaged.
- The required `Audit.fetch_in_scope/3` and public `AuditLive.page_content/1` exports compile and are exercised by focused green tests.
- Exact pagination, canonical URLs, non-enumerating selection, normalized assigns, shared composition, absence copy, retention truth, and confidentiality contracts are green after the final commit.
- This summary records the exact task hashes, requirement IDs, verification evidence, and preserved unrelated worktree state.

---
*Phase: 79-page-migration-wave-1-overview-cron-limiters-audit*
*Completed: 2026-07-19*
