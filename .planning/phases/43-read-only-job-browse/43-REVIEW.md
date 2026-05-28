---
phase: 43-read-only-job-browse
reviewed: 2026-05-28T02:15:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - lib/oban_powertools/jobs.ex
  - lib/oban_powertools/runtime_config.ex
  - lib/oban_powertools/web/jobs_live.ex
  - lib/oban_powertools/web/live_auth.ex
  - lib/oban_powertools/web/router.ex
  - lib/oban_powertools/web/selectors.ex
  - test/oban_powertools/jobs_test.exs
  - test/oban_powertools/web/live/jobs_live_test.exs
findings:
  critical: 3
  warning: 5
  info: 3
  total: 11
status: issues_found
---

# Phase 43: Code Review Report

**Reviewed:** 2026-05-28T02:15:00Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

This phase delivers a read-only job browse surface: a `Jobs` query context, a `JobsLive` LiveView with list and detail actions, wiring into the router, and selector/URL helpers. The overall architecture is sound — the query module is clean and index-aware, authorization is routed through the existing `LiveAuth` layer, and the display policy contract is exercised correctly.

Three blockers are present. Two involve unguarded external input (`String.to_existing_atom` and `String.to_integer`) that crashes the LiveView process when crafted WebSocket events or URL params supply invalid values. One is an incorrect hardcoded URL in the jobs list table that bypasses the canonical `Selectors` path and will silently break if the mount prefix changes. Five warnings cover a logic error in `timestamp_copy` for future timestamps, missing empty-string normalization for queue/worker before they enter the filter struct (currently masked by the push_patch flow but fragile), a missing `setup_error/1` clause in `RuntimeConfig`, a dead socket assign, and duplicated `read_only?` computation logic. Three info items cover a stale doc string, a magic number duplication, and an unused private function in the test file.

---

## Critical Issues

### CR-01: `String.to_existing_atom/1` on untrusted user input crashes the LiveView process

**File:** `lib/oban_powertools/web/jobs_live.ex:55`

**Issue:** `handle_event("select_state", ...)` converts the user-supplied `state` string via `String.to_existing_atom(state)`. Any WebSocket client (a browser extension, a crafted phx-click payload, or a penetration test) can send `%{"state" => "not_a_valid_state"}` and trigger an `ArgumentError` that is not caught, terminating the LiveView process. The same exposure exists at line 248 in the render template (used for comparison) and at line 441 in `filter_from_params` (via URL params).

`String.to_existing_atom` does not create new atoms, but it raises when the atom is absent — which happens with any unrecognized string. All three callsites need a guard.

**Fix:**
```elixir
@valid_states ~w(available scheduled executing retryable cancelled discarded completed)

# In handle_event("select_state", ...):
def handle_event("select_state", %{"state" => state}, socket) do
  if state in @valid_states do
    filter = socket.assigns.filter
    new_filter = %{filter | state: String.to_existing_atom(state), page: 1}
    {:noreply, push_patch(socket, to: Selectors.jobs_path(filter_path(new_filter)))}
  else
    {:noreply, socket}
  end
end

# In filter_from_params/1:
state_str = Map.get(params, "state", "available")
state =
  if state_str in @valid_states do
    String.to_existing_atom(state_str)
  else
    :available
  end
```

---

### CR-02: `String.to_integer/1` on untrusted `page` input crashes the LiveView process

**File:** `lib/oban_powertools/web/jobs_live.ex:76`

**Issue:** `handle_event("paginate", %{"page" => page_str}, socket)` calls `String.to_integer(page_str)` directly. A crafted WebSocket event with `%{"page" => "evil"}` raises `ArgumentError`. A crafted event or URL param with `?page=0` or `?page=-1` produces a negative Ecto offset (`(0-1)*20 = -20`) which Postgres rejects with `ERROR: OFFSET must not be negative`, again crashing the process. The same applies to `filter_from_params` at line 445.

**Fix:**
```elixir
# In handle_event("paginate", ...):
def handle_event("paginate", %{"page" => page_str}, socket) do
  case Integer.parse(page_str) do
    {page, ""} when page >= 1 ->
      filter = socket.assigns.filter
      new_filter = %{filter | page: page}
      {:noreply, push_patch(socket, to: Selectors.jobs_path(filter_path(new_filter)))}
    _ ->
      {:noreply, socket}
  end
end

# In filter_from_params/1:
page =
  case Integer.parse(Map.get(params, "page", "1")) do
    {p, ""} when p >= 1 -> p
    _ -> 1
  end
```

---

### CR-03: Job detail link hardcodes mount path, bypassing canonical `Selectors`

**File:** `lib/oban_powertools/web/jobs_live.ex:318`

**Issue:** The worker cell in the jobs list table navigates to the detail page via:
```elixir
<.link navigate={"/ops/jobs/jobs/#{job.id}"} ...>
```
This hardcodes `/ops/jobs/jobs` — the same path that all other navigation in this module derives from `Selectors.jobs_path/1` (which reads from `@canonical_paths`). If the mount path is changed in the router, all other navigation updates automatically while this link silently points at the wrong path. Every other navigation site in this file correctly uses `Selectors.jobs_path/1`.

**Fix:** Add a `job_detail_path/1` helper to `Selectors`, or inline via the existing base:
```elixir
# In Selectors:
def job_detail_path(id), do: "#{@canonical_paths.jobs}/#{id}"

# In jobs_live.ex line 318:
<.link navigate={Selectors.job_detail_path(job.id)} class="text-indigo-700 underline">
```

---

## Warnings

### WR-01: `timestamp_copy/1` produces nonsensical output for future timestamps

**File:** `lib/oban_powertools/web/jobs_live.ex:489-497`

**Issue:** `timestamp_copy` computes `seconds = DateTime.diff(DateTime.utc_now(), timestamp, :second)`. For future timestamps — which is the normal case for `:scheduled` and `:available` jobs whose `scheduled_at` is in the future — `seconds` is negative. The `cond` does not guard for negative values, so a job scheduled 5 minutes from now renders as `"-300s ago (2026-05-28 02:20:00 UTC)"`. The `-300s ago` label is semantically incorrect and will confuse operators.

**Fix:**
```elixir
defp timestamp_copy(%DateTime{} = timestamp) do
  seconds = DateTime.diff(DateTime.utc_now(), timestamp, :second)

  relative =
    if seconds < 0 do
      abs_s = abs(seconds)
      cond do
        abs_s < 60 -> "in #{abs_s}s"
        abs_s < 3_600 -> "in #{div(abs_s, 60)}m"
        abs_s < 86_400 -> "in #{div(abs_s, 3_600)}h"
        true -> "in #{div(abs_s, 86_400)}d"
      end
    else
      cond do
        seconds < 60 -> "#{seconds}s ago"
        seconds < 3_600 -> "#{div(seconds, 60)}m ago"
        seconds < 86_400 -> "#{div(seconds, 3_600)}h ago"
        true -> "#{div(seconds, 86_400)}d ago"
      end
    end

  exact = Calendar.strftime(timestamp, "%Y-%m-%d %H:%M:%S UTC")
  "#{relative} (#{exact})"
end
```

---

### WR-02: Empty-string queue/worker values stored in filter struct without normalization

**File:** `lib/oban_powertools/web/jobs_live.ex:70`

**Issue:** `handle_event("filter", %{"filter" => %{"queue" => q, "worker" => w, ...}}, socket)` at line 60 stores `q` and `w` directly into the filter struct: `%{filter | queue: q, worker: w, ...}`. When the user clears the queue or worker field, the browser sends `q = ""` and `w = ""`. These empty strings enter the filter struct, and `maybe_filter_queue/2` / `maybe_filter_worker/2` in `Jobs` only pass through on `nil`, not `""` — so a query with `WHERE queue = ''` would be issued.

Currently this bug is masked: `handle_event` immediately calls `push_patch`, and `handle_params` rebuilds the filter from URL params via `filter_from_params`, where `Map.get(params, "queue")` returns `nil` (since `Selectors.encode/2` correctly drops empty strings from the URL). The in-socket filter struct never drives a DB query. However, this latent inconsistency means any future code path that calls `load_jobs(socket, socket.assigns.filter)` directly (e.g., a real-time subscription update) will silently issue wrong queries.

**Fix:** Normalize empty strings to `nil` in the event handler:
```elixir
def handle_event("filter", %{"filter" => %{"queue" => q, "worker" => w, "tags" => tags_str}}, socket) do
  filter = socket.assigns.filter
  queue = if q == "", do: nil, else: q
  worker = if w == "", do: nil, else: w
  tags = ...
  new_filter = %{filter | queue: queue, worker: worker, tags: tags, page: 1}
  ...
end
```

---

### WR-03: Missing `setup_error/1` clause for `:host_escalation_handler` in `RuntimeConfig`

**File:** `lib/oban_powertools/runtime_config.ex:40-51`

**Issue:** `host_escalation_handler/1` delegates to `configured(:host_escalation_handler, opts)`. The `configured/2` function can call `raise setup_error(key)` when `required: true` is in opts. `setup_error/1` defines clauses for `:repo`, `:auth_module`, `:display_policy`, and `:workflow_callback_handler`, but has no clause for `:host_escalation_handler`. If `configured(:host_escalation_handler, required: true)` is ever called, the result is a `FunctionClauseError` — a confusing, undocumented crash — instead of the informative configuration error messages provided for all other keys.

**Fix:**
```elixir
defp setup_error(:host_escalation_handler) do
  "Oban Powertools requires :host_escalation_handler in config :oban_powertools, " <>
    "host_escalation_handler: MyApp.ObanPowertoolsEscalationHandler before dispatching " <>
    "host escalation callbacks."
end
```

---

### WR-04: `read_only?` is not updated in `load_job_detail/2`

**File:** `lib/oban_powertools/web/jobs_live.ex:362-383`

**Issue:** For the `:show` action, `mount` calls `assign_defaults/1` which sets `read_only?` using resource `%{type: :page, id: "jobs"}`. Then `handle_params` calls `load_job_detail/2`, which does not reassign `read_only?`. For the list page `load_jobs/2` does reassign `read_only?` (with the same resource). The detail render at line 100-101 shows the read-only banner conditioned on `@read_only?`. While the `:retry_job` permission atom is correct for both, the resource object checked for the detail page is `%{type: :page, id: "jobs"}` (the list page's resource), not something job-specific. If a host auth module ever makes fine-grained decisions based on the resource, the detail page receives an incorrect authorization check.

**Fix:** In `load_job_detail/2`, also reassign `read_only?`:
```elixir
socket
|> assign(:job, job)
|> assign(:job_not_found?, false)
|> assign(:args_display, args_display)
|> assign(:meta_display, meta_display)
|> assign(:back_path, back_path_from_session(socket))
|> assign(:read_only?, not LiveAuth.authorized?(
     Map.get(socket.assigns, :current_actor),
     :retry_job,
     %{type: :job, id: to_string(job.id)}
   ))
```

---

### WR-05: `read_only?` computation is duplicated between `assign_defaults/1` and `load_jobs/2`

**File:** `lib/oban_powertools/web/jobs_live.ex:410-414`, `425-430`

**Issue:** The identical four-line `assign(:read_only?, not LiveAuth.authorized?(...))` block appears in both `assign_defaults/1` and `load_jobs/2`. If the permission atom, resource, or actor lookup changes, it must be updated in two places. This is a violation of the DRY principle and introduces divergence risk.

**Fix:** Extract to a private helper:
```elixir
defp assign_read_only(socket) do
  assign(socket, :read_only?,
    not LiveAuth.authorized?(
      Map.get(socket.assigns, :current_actor),
      :retry_job,
      %{type: :page, id: "jobs"}
    )
  )
end
```
Then call `assign_read_only(socket)` in both `assign_defaults/1` and `load_jobs/2`.

---

## Info

### IN-01: `Selectors.encode/2` docstring omits `:jobs` destination

**File:** `lib/oban_powertools/web/selectors.ex:49`

**Issue:** The `@doc` for `encode/2` lists valid destination atoms as `:lifeline`, `:forensics`, `:audit`, `:limiters`, `:cron` — but `:jobs` was added to `@canonical_paths` and `jobs_path/1` was added to the public API. The docstring is stale.

**Fix:** Add `:jobs` to the list on line 49:
```
`destination` must be one of `:lifeline`, `:forensics`, `:audit`, `:limiters`, `:cron`, `:jobs`.
```

---

### IN-02: `page_size: 20` magic number duplicated in two modules

**File:** `lib/oban_powertools/jobs.ex:73`, `lib/oban_powertools/web/jobs_live.ex:446`

**Issue:** The default page size `20` is defined in the `Jobs` struct default and also hardcoded again in `filter_from_params/1`. They agree today, but a future change to one without the other would produce inconsistent behavior across the dead render (URL param) path vs. the struct default path.

**Fix:** In `filter_from_params/1`, derive from the struct default rather than repeating the literal:
```elixir
page_size: %Jobs{}.page_size
```

---

### IN-03: Unused `defp repo/0` in `jobs_test.exs`

**File:** `test/oban_powertools/jobs_test.exs:165`

**Issue:** `defp repo, do: TestRepo` is defined but never called anywhere in the test file. All `Jobs.list/3`, `Jobs.get/2`, and `Jobs.count_by_state/2` calls pass `TestRepo` directly.

**Fix:** Remove the unused private function.

---

_Reviewed: 2026-05-28T02:15:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
