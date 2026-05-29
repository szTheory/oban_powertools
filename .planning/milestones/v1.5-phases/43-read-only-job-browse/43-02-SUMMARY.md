---
phase: 43-read-only-job-browse
plan: "02"
subsystem: web-liveview
tags:
  - phoenix-liveview
  - routing
  - auth
  - oban
  - filter-state

dependency_graph:
  requires:
    - 43-01  # ObanPowertools.Jobs context, Selectors.jobs_path/1
  provides:
    - ObanPowertools.Web.JobsLive (:index and :show routes)
    - LiveAuth :view_jobs, :view_job_detail, :retry_job, :cancel_job, :discard_job atoms
    - LiveAuth :jobs and :job_detail page_read_only_banner entries
  affects:
    - lib/oban_powertools/web/live_auth.ex
    - lib/oban_powertools/web/router.ex
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools/web/live/jobs_live_test.exs

tech_stack:
  added: []
  patterns:
    - connected?(socket) guard for push_patch during handle_params
    - if/2 for nil-returning conditional expressions in filter_path (avoids &&-returns-false bug)
    - %Plug.Conn.Unfetched{} awareness — dead render params are always empty; live phase owns URL-driven state

key_files:
  created:
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools/web/live/jobs_live_test.exs
  modified:
    - lib/oban_powertools/web/live_auth.ex
    - lib/oban_powertools/web/router.ex

decisions:
  - "connected?(socket) guard wraps push_patch in handle_params — dead render phase receives %Plug.Conn.Unfetched{} for params regardless of URL, so Map.get always returns nil; without the guard every test URL causes a redirect loop"
  - "if/2 over && in filter_path — Elixir's && returns the left-hand falsy value (false, not nil) when the condition is false; Selectors.encode does not drop false; using if/2 returns nil which Selectors.encode correctly drops"
  - "Test 2 uses HTML assertions instead of assert_patch — mount-time push_patch fires inside handle_params during mount; ClientProxy does not send a :patch message to the test mailbox for mount-reply live_patch keys"
  - "assert_patch requires binary string not regex — changed filter/tab test assertions from ~r/.../ to exact URL strings"

metrics:
  duration: "~2 hours (including diagnosis of three LiveView internals issues)"
  completed: "2026-05-27"
  tasks_total: 3
  tasks_completed: 3
  files_created: 2
  files_modified: 2
---

# Phase 43 Plan 02: JobsLive Route, LiveAuth Atoms, and Integration Tests Summary

Read-only job browse LiveView: routes, LiveAuth atoms, JobsLive `:index` action, and 10 integration tests. The `/ops/jobs/jobs` URL lists jobs by state with 7-tab navigation, queue/worker/tags filters, and URL-serialized filter state. Unauthorized actors redirect to `/`. The `:show` action compiles as a Wave 3 stub.

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| 7a03ef9 | feat | Extend LiveAuth with job permission atoms and add JobsLive routes |
| 3e30909 | feat | Implement ObanPowertools.Web.JobsLive :index action |
| 6d73ada | fix | Use connected?/1 guard for push_patch and fix filter_path nil encoding |
| 816ceb5 | test | Add LiveView integration tests for JobsLive :index action |

## Files Changed

### `lib/oban_powertools/web/live_auth.ex` (modified — additive)

**@permission_messages** — 5 new entries:
- `:view_jobs` → "Permission: read-only. You can inspect the Powertools-native job list, but mutation controls stay disabled until you receive broader permission."
- `:view_job_detail` → "Permission: read-only. You can inspect this Powertools-native job detail, but mutation controls stay disabled until you receive broader permission."
- `:retry_job` → "Permission: read-only. You can inspect this Powertools-native job, but you do not have permission to retry it."
- `:cancel_job` → "Permission: read-only. You can inspect this Powertools-native job, but you do not have permission to cancel it."
- `:discard_job` → "Permission: read-only. You can inspect this Powertools-native job, but you do not have permission to discard it."

**@page_read_only_banners** — 2 new entries:
- `:jobs` → "Permission: read-only. Job list stays visible, but mutation controls stay disabled until you receive broader permission."
- `:job_detail` → "Permission: read-only. Job detail stays visible, but retry, cancel, and discard controls stay disabled until you receive broader permission."

All existing entries preserved verbatim.

### `lib/oban_powertools/web/router.ex` (modified — additive)

Two routes added inside existing `live_session :oban_powertools_native`:

```elixir
live("/jobs", ObanPowertools.Web.JobsLive, :index)
live("/jobs/:id", ObanPowertools.Web.JobsLive, :show)
```

### `lib/oban_powertools/web/jobs_live.ex` (created)

Full `ObanPowertools.Web.JobsLive` implementation:

- Wrapped in `if Code.ensure_loaded?(Phoenix.LiveView) do ... end`
- `mount/3` branches on `socket.assigns.live_action` — `:show` uses `:view_job_detail`, else `:view_jobs` (D-17/D-18)
- `handle_params/3` dispatches: `:show` action → stub (Wave 3); list action → `connected?(socket)` guard controls push_patch vs data load
- Three handle_event handlers: `select_state`, `filter`, `paginate` — all push URL patches via `Selectors.jobs_path/1`
- Render: 7-tab state bar with counts, queue/worker/tags filter form, job table with state badges, empty state block, Previous/Next pagination
- UI-SPEC typography: `font-semibold` throughout (verified: `grep -c 'font-medium' lib/oban_powertools/web/jobs_live.ex` = 0)
- State badge colors: 7 states mapped to UI-SPEC §Color tokens
- Private helpers: `filter_path/1`, `filter_from_params/1`, `assign_defaults/1`, `load_jobs/2`, `state_tab_class/1`, `state_badge_class/1`, `short_worker_name/1`, `timestamp_copy/1` (nil/NaiveDateTime/DateTime/binary clauses), `repo/0`

### `test/oban_powertools/web/live/jobs_live_test.exs` (created)

10 integration tests — all passing (`10 tests, 0 failures`):

1. redirects unauthorized viewers
2. redirects when no state param then loads default state
3. renders list page with state tabs and headings
4. filters by queue via push_patch
5. filters by worker
6. filters by tags
7. navigates state via tab click
8. read-only banner renders when actor lacks mutation permissions
9. hides read-only banner when actor has retry_job permission
10. renders empty state when no jobs match the filter

## Design Decision Implementation Status

| Decision | Status | Location |
|----------|--------|----------|
| D-02: pre-declare Phase 44 permission atoms | Done | live_auth.ex @permission_messages |
| D-06: routes inside existing live_session | Done | router.ex live_session :oban_powertools_native |
| D-07: queue/worker/tags filter via URL params | Done | handle_event("filter"...) + filter_from_params/1 |
| D-09: 7-tab state bar | Done | render/1 state tabs nav |
| D-12: job table column order (State, Worker, Queue, ID, Scheduled, Attempts) | Done | render/1 table thead |
| D-13: short_worker_name/1 (last segment) | Done | defp short_worker_name/1 |
| D-15: Phase 43 is read-only (no mutation controls) | Done | no Oban runtime calls anywhere |
| D-17: mount branches on live_action for auth | Done | mount/3 case on socket.assigns.live_action |
| D-18: :show action uses :view_job_detail permission | Done | mount/3 :show branch |
| D-19: :jobs and :job_detail banner entries | Done | live_auth.ex @page_read_only_banners |
| D-20: 5 permission atoms pre-declared | Done | live_auth.ex @permission_messages |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] connected?(socket) guard for push_patch in handle_params**
- **Found during:** Task 2 / Task 3 test run
- **Issue:** During the dead render phase, `conn.params` is `%Plug.Conn.Unfetched{aspect: :params}` — a struct with only atom keys. `Map.get(%Plug.Conn.Unfetched{}, "state")` returns `nil` (the default) rather than the URL query string value, because the test router pipeline lacks `fetch_query_params` and the Unfetched struct has no `"state"` string key. The plan's original code `case Map.get(params, "state") do nil -> push_patch(...)` fired unconditionally in the dead render, even for URLs like `/ops/jobs/jobs?state=available`. This caused every `live(conn, "...?state=available")` call to return `{:error, {:live_redirect, ...}}` instead of `{:ok, view, html}`, failing all 9 of the non-redirect tests.
- **Fix:** Wrapped the push_patch branch in `{true, nil}` pattern: `case {connected?(socket), Map.get(params, "state")} do {true, nil} -> push_patch(...); _ -> load_jobs(...)`. The dead render always falls through to the `_` branch and loads normally.
- **Files modified:** `lib/oban_powertools/web/jobs_live.ex`
- **Commit:** 6d73ada

**2. [Rule 1 - Bug] filter_path/1 used && which returns false (not nil) for dropped params**
- **Found during:** Task 3 test run (Test 4 filter_by_queue)
- **Issue:** The plan spec for `filter_path` used `filter.tags && Enum.join(...)` and `filter.page > 1 && to_string(filter.page)`. Elixir's `&&` returns the left-hand falsy value when the condition is false — `false`, not `nil`. `Selectors.encode/2` does not drop `false` values, so URLs got `?page=false`. Then `filter_from_params/1` called `String.to_integer("false")` which raised `ArgumentError`.
- **Fix:** Changed to `if/2`: `if(filter.tags, do: Enum.join(filter.tags, ","))` and `if(filter.page > 1, do: to_string(filter.page))`. `if/2` returns `nil` when the condition is false, which Selectors drops correctly.
- **Files modified:** `lib/oban_powertools/web/jobs_live.ex`
- **Commit:** 6d73ada

**3. [Rule 1 - Bug] assert_patch timeout for mount-time push_patch**
- **Found during:** Task 3 — Test 2 ("redirects when no state param")
- **Issue:** When `push_patch` fires inside `handle_params` during the mount cycle, Phoenix LiveView 1.1.30's channel processes it in `mount_handle_params_result` and includes the result as `live_patch: opts` in the initial mount reply. The ClientProxy's `init` function ignores the `live_patch` key in the mount response — it does NOT call `send_patch`. No `{:patch, ...}` message reaches the test process mailbox. `assert_patch/2` times out with 100ms.
- **Fix:** Test 2 changed from `assert_patch(view, ...)` to HTML assertions: `{:ok, _view, html} = live(conn, "/ops/jobs/jobs")` followed by `assert html =~ "Jobs"` and `assert html =~ "border-indigo-300 bg-indigo-50"` (the active state tab class, proving the view resolved to `?state=available`).
- **Files modified:** `test/oban_powertools/web/live/jobs_live_test.exs`
- **Commit:** 816ceb5

**4. [Rule 1 - Bug] assert_patch does not accept regex — requires binary string**
- **Found during:** Task 3 — Tests 4 and 7 initial drafts
- **Issue:** `assert_patch(view, ~r/queue=alpha/)` raises because `assert_patch/2` requires a binary string, not a Regex.
- **Fix:** Changed to exact URL strings: `assert_patch(view, "/ops/jobs/jobs?state=available&queue=alpha")` and `assert_patch(view, "/ops/jobs/jobs?state=executing")`.
- **Files modified:** `test/oban_powertools/web/live/jobs_live_test.exs`
- **Commit:** 816ceb5

## Known Stubs

- `lib/oban_powertools/web/jobs_live.ex` — `:show` action `handle_params` returns `{:noreply, assign(socket, :job, nil) |> assign(:job_id, id)}`. The render for `:show` displays "Job detail loading — Wave 3 owns this view." Wave 3 (Plan 43-03) will replace this with the real detail loader and redacted args/meta display.

## Threat Surface Scan

All threat mitigations in the plan's `<threat_model>` are implemented:
- T-43-02-01: `LiveAuth.authorize_page/3` called before any data load in `mount/3`
- T-43-02-02: `:show` action uses `:view_job_detail` permission (auth fires before Wave 3 render)
- T-43-02-03: `String.to_existing_atom/1` for state param; Ecto binding for queue/worker/tags
- T-43-02-04: `String.to_existing_atom/1` raises on unknown atom strings
- T-43-02-05: `page_size: 20` hardcoded; `String.to_integer/1` raises on non-numeric page
- T-43-02-06: read-only phase — no mutations, no audit needed
- T-43-02-07: no package installs

No new security-relevant surface introduced beyond what the threat model covers.

## Pre-existing Warning (not introduced by this plan)

`function continuity_action/1 is unused` in `lib/oban_powertools/web/forensics_live.ex:362` — noted in 43-01-SUMMARY.md, unchanged.

## Self-Check: PASSED

- [x] `lib/oban_powertools/web/jobs_live.ex` exists
- [x] `test/oban_powertools/web/live/jobs_live_test.exs` exists
- [x] Commit 7a03ef9 exists (Task 1)
- [x] Commit 3e30909 exists (Task 2)
- [x] Commit 6d73ada exists (Task 2 fixes)
- [x] Commit 816ceb5 exists (Task 3)
- [x] `10 tests, 0 failures`
