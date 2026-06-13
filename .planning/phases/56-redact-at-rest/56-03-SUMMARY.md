---
phase: 56-redact-at-rest
plan: "03"
subsystem: display-policy
tags: [redaction, display-policy, liveview, runtime-config, security, ui]
dependency_graph:
  requires: [56-01]
  provides: [redact-display-overlay, redact-disclosure-block, redacted-fields-assign]
  affects:
    - lib/oban_powertools/runtime_config.ex
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools/web/live/jobs_live_test.exs
tech_stack:
  added: []
  patterns: [tagged-return-shape, render-job-field-clause-dispatch, assign-defaults-coverage, heex-conditional-block]
key_files:
  created: []
  modified:
    - lib/oban_powertools/runtime_config.ex
    - lib/oban_powertools/web/jobs_live.ex
    - test/oban_powertools/web/live/jobs_live_test.exs
decisions:
  - "OQ3-resolved: host policy returning custom map/string for :job_args is passed through unchanged — Powertools overlay only on nil/default path"
  - "Disclosure block uses conditional <% if @redacted_fields != [] %> near Meta card, no new top-level card (D-13)"
  - "Comma-joined atom-presentation form ':ssn, :token' via Enum.map(&':#{&1}') |> Enum.join(', ') (D-17)"
  - "rescue _ -> {:fallback, '[redacted]'} preserved on :job_args clause (D-14)"
metrics:
  duration: "8 minutes"
  completed: "2026-06-13"
  tasks: 3
  files: 3
requirements: [REDACT-03, REDACT-04]
---

# Phase 56 Plan 03: Redaction Display & Disclosure Summary

Redaction surface: `render_job_field(:job_args)` overlays "Redacted at enqueue" per field on the default DisplayPolicy path, and the `/ops/jobs` detail view renders "Fields redacted at enqueue: :ssn, :token" near the Meta card from `meta["__redacted_fields__"]`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 0 | Wave 0 — failing REDACT-03/04 tests | 04e6641 | test/oban_powertools/web/live/jobs_live_test.exs |
| 1 | render_job_field(:job_args) overlay in runtime_config.ex | 43504fd | lib/oban_powertools/runtime_config.ex |
| 2 | Redaction disclosure block + assigns in jobs_live.ex | c5fd038 | lib/oban_powertools/web/jobs_live.ex |

## What Was Built

### `runtime_config.ex` — `:job_args` render clause

Added a new `def render_job_field(:job_args, value, context)` clause BEFORE the generic `render_job_field(kind, value, context)` clause (mirroring the existing `:job_recorded` dispatch pattern).

Logic:
- Calls `get_redacted_fields/1` to extract `meta["__redacted_fields__"]` from the `%{job: %Oban.Job{}}` context shape, falling back to `[]` for unknown context shapes.
- When `redacted_fields == []`: delegates to the same case-on-`apply_policy` logic as the generic clause.
- When `redacted_fields` is non-empty AND `apply_policy` returns `nil` (default path): builds `build_redacted_args_map/2` — a merged map with `%{field => "Redacted at enqueue"}` overlaid over args (string keys, D-17/D-14), then `{:raw_json, Jason.encode!(annotated, pretty: true)}`.
- When `apply_policy` returns a custom binary or custom map: passes through unchanged (OQ3 RESOLVED — host owns custom returns).
- `rescue _ -> {:fallback, "[redacted]"}` preserved on the new clause (D-14, load-bearing per PATTERNS.md).

Private helpers added:
- `get_redacted_fields/1` — extracts `__redacted_fields__` from `%{job: %Oban.Job{meta: meta}}`, `[]` fallback for other shapes.
- `build_redacted_args_map/2` — `Map.new(redacted_fields, &{&1, "Redacted at enqueue"}) |> Map.merge(args, overlay)`.

### `jobs_live.ex` — `:redacted_fields` assigns + disclosure block

Assigns:
- `load_job_detail/2` job branch: `redacted_fields = get_in(job.meta || %{}, ["__redacted_fields__"]) || []` → `|> assign(:redacted_fields, redacted_fields)`.
- `load_job_detail/2` nil/not-found branch: `|> assign(:redacted_fields, [])`.
- `assign_defaults/1`: `|> assign(:redacted_fields, [])` (PATTERNS: every new assign must appear in assign_defaults).

Template (between Meta card `</div>` and `<%!-- Recorded output panel --%>`):
```heex
<%= if @redacted_fields != [] do %>
  <div class="rounded-lg border bg-white p-4">
    <p class="text-xs font-semibold text-zinc-500">
      Fields redacted at enqueue:
      <%= Enum.map(@redacted_fields, &":#{&1}") |> Enum.join(", ") %>
    </p>
  </div>
<% end %>
```

Colors: `text-zinc-500` (`#71717A`) — neutral per UI-SPEC. No red. Read-only: no actions.

### Test coverage

5 new tests in `jobs_live_test.exs`:

**REDACT-03 describe block:**
1. Disclosure present: job with `meta: %{"__redacted_fields__" => ["ssn", "token"]}` → `html =~ "Fields redacted at enqueue"` AND `html =~ ":ssn, :token"` (comma-joined form, D-13/D-17).
2. Empty state: job with no `__redacted_fields__` → `refute html =~ "Fields redacted at enqueue"`.

**REDACT-04 describe block:**
3. Per-field overlay: nil policy + `__redacted_fields__` → `html =~ "Redacted at enqueue"` in args panel.
4. Host passthrough: `ObanPowertools.Web.JobsLiveDetailCustomArgsPolicy` returning `%{"custom" => "host_redacted"}` → `assert html =~ "host_redacted"`, `refute html =~ "Redacted at enqueue"` (OQ3 RESOLVED).
5. Fallback preserved: raising policy → `assert html =~ "[redacted]"`.

New policy module: `ObanPowertools.Web.JobsLiveDetailCustomArgsPolicy` — returns a custom map for `:job_args` to guard the host passthrough invariant.

## Verification Results

```
mix test test/oban_powertools/web/live/jobs_live_test.exs
35 tests, 0 failures

mix compile --warnings-as-errors
# Clean, no warnings
```

### Acceptance Criteria Met

- `grep -n "Fields redacted at enqueue" lib/oban_powertools/web/jobs_live.ex` → line 395
- `grep -n "Redacted at enqueue" lib/oban_powertools/runtime_config.ex` → line 293
- `grep -c "redacted_fields" lib/oban_powertools/web/jobs_live.ex` → 7 (load_job_detail both branches, assign_defaults, template)
- No red color classes on the disclosure block (`text-zinc-500` only)
- `[redacted]` fallback intact on `:job_args` clause at line 239
- Host custom policy not overridden (REDACT-04 passthrough test green)
- Disclosure assertion pins the comma-joined ":ssn, :token" form — NOT separate substring assertions

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] Worktree deps/build symlinks required to run tests**
- **Found during:** Task 0 verification
- **Issue:** The git worktree did not have `deps/` or `_build/` directories, so `mix test` from inside the worktree reported unchecked dependencies. The main repo has built deps at `/Users/jon/projects/oban_powertools/deps` and `_build`.
- **Fix:** Created symlinks `deps -> /Users/jon/projects/oban_powertools/deps` and `_build -> /Users/jon/projects/oban_powertools/_build` inside the worktree. Tests ran successfully after this.
- **Files modified:** worktree symlinks only (not tracked in git)
- **Commit:** n/a

## Known Stubs

None. All implementation is wired end-to-end: `__redacted_fields__` from stored job meta → LiveView assigns → template disclosure + render_job_field overlay. Real DB integration tests (insert_job! with meta) prove the full path.

## Threat Flags

No new threat surfaces introduced. Changes are display-only: field names are shown, never field values. The `__redacted_fields__` list contains only string field names (keys absent from stored args by Plan 56-01). The `[redacted]` fallback on the `:job_args` clause preserves the T-56-12 mitigation.

## Self-Check: PASSED
