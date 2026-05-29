---
phase: 43-read-only-job-browse
plan: "03"
subsystem: ui
tags: [phoenix-liveview, oban, display-policy, redaction, integration-tests]

# Dependency graph
requires:
  - phase: 43-read-only-job-browse
    plan: "01"
    provides: Jobs.get/2, DisplayPolicy.render_job_field/3, Selectors.jobs_path/1
  - phase: 43-read-only-job-browse
    plan: "02"
    provides: JobsLive mount/3 auth + display-policy gate, :show stub, list-page render
provides:
  - "JobsLive :show action — real handle_params loading job via Jobs.get/2 with DisplayPolicy redaction for args and meta"
  - "Full detail view with identity card, args/meta panels, errors panel, attempt history panel, timing fields"
  - "Job-not-found branch rendering UI-SPEC copy without crashing"
  - "Back link preserving filter state via back_path_from_session/1"
  - "11 detail-page integration tests covering all 4 DisplayPolicy.render_job_field/3 return arms"
affects: [phase-43-verify-work, any-phase-using-JobsLive-detail]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DisplayPolicy tagged-tuple rendering: {:raw_json, _} | {:string, _} | {:fallback, _} matched via case in HEEx template"
    - "Detail view loaded in handle_params/3 via private load_job_detail/2; mount/3 only handles auth"
    - "back_path_from_session/1 falls back to bare path when filter assign is nil (direct URL hit)"
    - "Test DisplayPolicy modules defined as bare defmodule at top of test file; swapped per-test via Application.put_env + on_exit restore"

key-files:
  created: []
  modified:
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools/web/live/jobs_live_test.exs

key-decisions:
  - "Replace Wave 2 stub handle_params/3 with load_job_detail/2 that calls Jobs.get/2 and both DisplayPolicy.render_job_field/3 calls"
  - "Inline case matching on tagged display tuple in HEEx template rather than a function component — avoids HEEx function-component complexity for a trivial three-branch match"
  - "Fixed insert_job!/1 test helper to pop :args from opts and pass as positional arg to Oban.Job.new/2 — Oban.Job.new ignores :args in the opts keyword list"

patterns-established:
  - "Detail render: load_job_detail/2 assigns :job, :args_display, :meta_display, :job_not_found?, :back_path atomically"
  - "DisplayPolicy rescue arm: any exception from render_job_field/3 results in {:fallback, '[redacted]'} — never crashes render"
  - "Nil timing fields hidden via :if={value} on each <div> wrapper — no conditional in helpers needed"

requirements-completed: [QRY-02]

# Metrics
duration: 45min
completed: 2026-05-27
---

# Phase 43 Plan 03: Job Detail View Summary

**JobsLive :show action replaces Wave 2 stub — loads job via Jobs.get/2, redacts args/meta through DisplayPolicy.render_job_field/3, renders full D-14 detail layout with 11 passing integration tests covering all 4 DisplayPolicy arms**

## Performance

- **Duration:** ~45 min (continuation agent)
- **Started:** 2026-05-27T21:50:00Z
- **Completed:** 2026-05-27T22:02:00Z
- **Tasks:** 2 (Task 1 committed by prior agent; Task 2 committed by this agent)
- **Files modified:** 2

## Accomplishments

- Wave 2 `:show` stub replaced with real `load_job_detail/2` calling `Jobs.get/2` and `DisplayPolicy.render_job_field/3` for both `:job_args` and `:job_meta`
- Full detail page renders: identity card (worker, queue, state badge, id, attempt, non-nil timing fields), args panel, meta panel, errors panel (with empty-state copy), attempt history panel (with empty-state copy), back link
- All 4 `DisplayPolicy.render_job_field/3` return arms exercised by passing tests: nil→{:raw_json,_}, String→{:string,_}, Map→{:raw_json,_}, raise→{:fallback,"[redacted]"}
- Job-not-found branch renders UI-SPEC copy ("Job not found. It may have been pruned or the ID is invalid.") without crashing
- `font-medium` zero constraint maintained (UI-SPEC 2-weight rule); `font-semibold` used throughout
- 256 total tests, 0 failures (full suite)

## Task Commits

1. **Task 1: Replace Wave 2 :show stub — implement handle_params + render** - `2120fbf` (feat — committed by prior agent)
2. **Task 2: Extend jobs_live_test.exs with detail-page integration tests** - `f8c4118` (test — committed by this agent)

**Plan metadata:** (this commit)

## Files Created/Modified

- `lib/oban_powertools/web/jobs_live.ex` — handle_params/3 :show clause replaced; load_job_detail/2 and back_path_from_session/1 private helpers added; :show render branch replaced with full D-14 detail layout
- `test/oban_powertools/web/live/jobs_live_test.exs` — four DisplayPolicy test modules added (NilPolicy, StringPolicy, MapPolicy, RaisingPolicy); describe "Detail page" block with 11 tests added; insert_job!/1 helper fixed to pass args as positional arg

## Decisions Made

- Inline `case` pattern matching on the tagged display tuple inside the HEEx template was chosen over a Phoenix function component helper — three-branch match is concise and reviewable inline without the boilerplate of a separate `defp render_display_field(assigns)` component
- `back_path_from_session/1` uses `socket.assigns[:filter]` (safe access) — falls back to `Selectors.jobs_path([])` when filter is nil on a direct `:show` URL hit; this is documented as best-effort per RESEARCH.md Open Question 2
- Test policy modules scoped per-test via `Application.put_env` + `on_exit` restore rather than extending the shared `setup` block — simpler and eliminates risk of leaking policy state across unrelated tests

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed insert_job!/1 helper — args not passed to Oban.Job.new correctly**
- **Found during:** Task 2 (detail-page integration tests)
- **Issue:** `Oban.Job.new(args, opts)` takes args as first positional argument. The helper was calling `Oban.Job.new(%{}, opts)` ignoring any `args:` key in opts. This caused the nil-policy raw-JSON test to fail because the job was inserted with `%{}` instead of `%{"id" => 42, "action" => "ingest"}`.
- **Fix:** Added `{args, opts} = Keyword.pop(opts, :args, %{})` before `Oban.Job.new(args, opts)` in the helper
- **Files modified:** test/oban_powertools/web/live/jobs_live_test.exs
- **Verification:** `mix test test/.../jobs_live_test.exs` — 21 tests, 0 failures
- **Committed in:** f8c4118 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in test helper)
**Impact on plan:** Fix was necessary for test correctness; no scope creep.

## Issues Encountered

None beyond the insert_job!/1 bug documented above.

## User Setup Required

None - no external service configuration required.

## Phase 43 Success Criteria Status

1. [x] Operator can navigate to `/ops/jobs/jobs` and see a filterable job list by state — Wave 2
2. [x] Filter controls (state tab, queue, worker, tags) narrow the job list live — Wave 2
3. [x] Operator can click any job row and see its full detail — args, meta, errors, attempt history, and timing — with `DisplayPolicy` redaction applied to args and meta — **this plan**
4. [x] Unauthorized actors are redirected to `/` on both the list page and the detail page — Wave 2 (list) + this plan (detail)
5. [x] `DisplayPolicy` is configured check fires on mount for both actions — Wave 2

Phase 43 is ready for `/gsd:verify-work 43`.

## Next Phase Readiness

- Phase 43 read-only job browse is feature-complete across all three waves
- All three QRY-0x requirements are covered: Jobs.get/2 (QRY-01), detail render + redaction (QRY-02), list + filter (QRY-03 via Wave 2)
- `/gsd:verify-work 43` can be run to exercise the acceptance criteria

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced by this plan. The `:show` action was already behind `LiveAuth.authorize_page(socket, :view_job_detail, ...)` from Wave 2.

---
*Phase: 43-read-only-job-browse*
*Completed: 2026-05-27*
