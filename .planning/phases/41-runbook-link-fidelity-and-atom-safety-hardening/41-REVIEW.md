---
phase: 41-runbook-link-fidelity-and-atom-safety-hardening
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - lib/oban_powertools/web/selectors.ex
  - lib/oban_powertools/lifeline/target_type.ex
  - lib/oban_powertools/forensics/evidence_bundle.ex
  - lib/oban_powertools/forensics/runbook_entry.ex
  - lib/oban_powertools/web/control_plane_presenter.ex
  - lib/oban_powertools/lifeline.ex
  - lib/oban_powertools/web/lifeline_live.ex
  - lib/oban_powertools/web/overview_read_model.ex
  - lib/oban_powertools/forensics.ex
  - lib/oban_powertools/web/workflows_live.ex
  - test/oban_powertools/web/selectors_test.exs
  - test/oban_powertools/lifeline/target_type_test.exs
  - test/oban_powertools/forensics/evidence_bundle_test.exs
  - test/oban_powertools/web/live/engine_overview_live_test.exs
  - test/oban_powertools/web/live/forensics_live_test.exs
  - test/oban_powertools/web/live/lifeline_live_test.exs
findings:
  critical: 5
  warning: 5
  info: 3
  total: 13
status: issues_found
---

# Phase 41: Code Review Report

**Reviewed:** 2026-05-27T00:00:00Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

This phase introduces URL selector encoding hardening (`Selectors`), a closed-enum `TargetType` dispatcher, atom-safe related-evidence normalization in `EvidenceBundle`, and updated runbook-link fidelity across `RunbookEntry`, `LifelineLive`, `WorkflowsLive`, `ControlPlanePresenter`, `Forensics`, and `OverviewReadModel`.

The core atom-safety work in `EvidenceBundle` is correct and well-tested. `Selectors` is correct. `TargetType` intentionally raises on unknown values and is properly documented. However, several bugs were found across the surface area:

- Two distinct URL-construction defects produce malformed paths (trailing `?` and unencoded step names).
- `LifelineLive.forensic_path/2` bypasses `Selectors` and replicates the empty-query bug.
- The archive prune transaction contains a logical correctness problem: batched fetch + unbounded delete with a mismatch guard cannot prevent data loss when more records exist than the batch size.
- `load_target_detail/1` crashes on non-integer `target_id` values passed from URL params.
- `incident_rows/2` is missing a catch-all clause, causing a `FunctionClauseError` for any `incident_class` other than `"dead_executor"` or `"workflow_stuck"`.

---

## Critical Issues

### CR-01: `ControlPlanePresenter.audit_follow_up_path/1` always emits a trailing `?` on empty params

**File:** `lib/oban_powertools/web/control_plane_presenter.ex:188-190`

**Issue:** The function unconditionally appends `?` to the audit base path, regardless of whether any query params survive the `nil`/`""` filter. When `identity.type`, `identity.id`, and `event.event_type` are all nil or empty, `URI.encode_query/1` returns `""`, and the result is `/ops/jobs/audit?` — an invalid URL sent to the browser and used in `<.link navigate={...}>` tags throughout `LifelineLive`.

```elixir
# current (buggy)
|> URI.encode_query()
|> then(&"/ops/jobs/audit?#{&1}")
```

This is the same defect pattern that `Selectors.encode/2` was written to fix, but `audit_follow_up_path/1` never adopted it.

**Fix:** Delegate to `Selectors.audit_path/1` which already handles the empty-query case correctly:

```elixir
def audit_follow_up_path(event) do
  identity = Audit.event_resource_identity(event)

  Selectors.audit_path([
    {"resource_type", identity.type},
    {"resource_id", identity.id},
    {"event_type", Audit.event_label(event)}
  ])
end
```

---

### CR-02: `LifelineLive.forensic_path/2` bypasses `Selectors` and emits a trailing `?` on empty params

**File:** `lib/oban_powertools/web/lifeline_live.ex:1264-1274`

**Issue:** The private `forensic_path/2` function manually constructs the forensics URL using `URI.encode_query/1` then unconditionally appends `?`, identical to the CR-01 pattern. When `row.target_type` and `row.target_id` are both `nil` (possible for the `dead_executor` summary row where `target_id: nil`) and `row.incident.incident_fingerprint` is empty, this produces `/ops/jobs/forensics?`. It also duplicates the encoding logic instead of using the canonical `Selectors.forensic_path/1`.

```elixir
# current (buggy)
|> URI.encode_query()
|> then(&"/ops/jobs/forensics?#{&1}")
```

**Fix:**

```elixir
defp forensic_path(row, current_view) do
  Selectors.forensic_path([
    {"incident_fingerprint", row.incident.incident_fingerprint},
    {"view", current_view},
    {"resource_type", row.target_type},
    {"resource_id", row.target_id}
  ])
end
```

---

### CR-03: `WorkflowsLive.selected_step_path/2` and `Forensics.workflow_path/2` embed step names in URLs without encoding

**File:** `lib/oban_powertools/web/workflows_live.ex:403-404`; `lib/oban_powertools/forensics.ex:461-462`

**Issue:** Both functions interpolate `step_name` directly into query strings without URI-encoding:

```elixir
# workflows_live.ex:403-404
defp selected_step_path(workflow_id, step_name),
  do: "/ops/jobs/workflows/#{workflow_id}?step=#{step_name}"

# forensics.ex:461-462
defp workflow_path(workflow, step),
  do: "/ops/jobs/workflows/#{workflow.id}?step=#{step.step_name}"
```

Step names containing `&`, `=`, `#`, `?`, or `%` (all valid in application-defined step names) will produce malformed URLs, incorrect query-param parsing on the receiving end, and broken navigation. The `selected_step_path` output is used in `<.link patch={...}>` inside the template (line 164), so the router receives the raw unencoded value.

**Fix:** Encode step names via `URI.encode_www_form/1`:

```elixir
defp selected_step_path(workflow_id, step_name),
  do: "/ops/jobs/workflows/#{workflow_id}?step=#{URI.encode_www_form(step_name)}"

defp workflow_path(workflow, step),
  do: "/ops/jobs/workflows/#{workflow.id}?step=#{URI.encode_www_form(step.step_name)}"
```

---

### CR-04: Archive prune transaction deletes more records than it archived, with no overflow guard

**File:** `lib/oban_powertools/lifeline.ex:220-244`

**Issue:** `archive_due_repair_audits/5` fetches at most `batch_size` rows and inserts them into the archive table (`archive_count`). Immediately afterwards the outer transaction runs an unbounded `repo.delete_all/1` on every matching audit event older than the cutoff — not just the batch that was archived. If there are more qualifying rows than `batch_size`, `deleted_audits > archive_count`, the mismatch guard fires and the transaction rolls back, which means the archived rows are also rolled back. On the next attempt the same condition repeats. In practice this means no records can ever be pruned when there are more candidates than `batch_size`.

More dangerously: if `archive_due_repair_audits` succeeds (returns `archive_count == batch_size`) but the `delete_all` deletes a different number (because new records were inserted concurrently between the two statements), the mismatch guard triggers a rollback — again wasting the archive work.

**Fix:** The delete must be scoped to the exact IDs that were archived, not to the unbounded cutoff predicate:

```elixir
# In archive_due_repair_audits, collect event IDs:
event_ids = Enum.map(rows, & &1.audit_event_id_raw)  # keep the original integer id

# In the transaction, delete only those IDs:
{deleted_audits, _} =
  repo.delete_all(from(event in Audit, where: event.id in ^event_ids))

# The mismatch guard then correctly compares counts for the same set.
```

---

### CR-05: `LifelineLive.load_target_detail/1` calls `String.to_integer/1` on an untrusted URL param

**File:** `lib/oban_powertools/web/lifeline_live.ex:815-816`

**Issue:** The `"job"` clause of `load_target_detail/1` unconditionally calls `String.to_integer(target_id)`, where `target_id` is ultimately derived from the URL-provided `row-id` param (via `find_row!` → row map) or from `incident.evidence["job_ids"]`. When `target_id` is a non-integer string (e.g., `"missing"`, set at line 682 in the summary dead-executor row), this raises `ArgumentError`, crashing the LiveView process and rendering a blank page for the operator.

The summary row (`previewable?: false`) sets `target_id: nil` (line 679), but the non-previewable summary row at line 682 sets `resource: %{type: :job, id: "missing"}`, and while `target_id` is `nil` for that row, `select_incident` can still be clicked on it (line 289), which calls `load_target_detail/1`. More critically, any future caller that passes a job row with a string `target_id` containing non-digits will crash.

**Fix:**

```elixir
defp load_target_detail(%{target_type: "job", target_id: target_id})
    when is_binary(target_id) do
  case Integer.parse(target_id) do
    {job_id, ""} -> %{job_id: job_id}
    _ -> %{job_id: nil}
  end
end

defp load_target_detail(%{target_type: "job"}), do: %{job_id: nil}
```

---

## Warnings

### WR-01: `incident_rows/2` has no catch-all clause — new incident classes will crash `LifelineLive`

**File:** `lib/oban_powertools/web/lifeline_live.ex:668-729`

**Issue:** `incident_rows/2` only handles `"dead_executor"` and `"workflow_stuck"`. The codebase already contains a third incident class, `"workflow_action"` (used in `build_workflow_handoff_row/4` and `infer_incident_class/1`). Any `Incident` with `incident_class: "workflow_action"` fetched through `list_incidents` will raise `FunctionClauseError` in `expand_rows`, crashing `load_data` and making the Lifeline page unrenderable.

**Fix:** Add a fallback clause:

```elixir
defp incident_rows(_repo, %Incident{} = incident) do
  [
    %{
      id: "#{incident.id}:summary",
      incident: incident,
      action: "job_rescue",
      target_type: "job",
      target_id: nil,
      target_summary: incident.summary || incident.incident_class,
      previewable?: false,
      resource: %{type: :job, id: "missing"}
    }
  ]
end
```

---

### WR-02: `execute` handler accesses `row.workflow_id` and `row.step_name` that are absent on `dead_executor` rows

**File:** `lib/oban_powertools/web/lifeline_live.ex:149-158`

**Issue:** After a successful `execute`, the handler builds `next_selection` from `row.workflow_id` and `row.step_name` when `row.incident.id` is nil (the `else` branch). Dead-executor rows do not include `workflow_id` or `step_name` keys. Elixir map access with `.` on a map that lacks the key raises `KeyError`. This path is reached only when `row.incident.id` is nil, which is the case for handoff-only (workflow_action) rows, but the struct definition check should be explicit.

**Fix:** Guard against missing keys:

```elixir
next_selection =
  if row.incident.id do
    %{view: "resolved", incident_fingerprint: preview.incident_fingerprint}
  else
    %{
      view: "active",
      workflow_id: Map.get(row, :workflow_id),
      step_name: Map.get(row, :step_name),
      action: row.action
    }
  end
```

---

### WR-03: `Forensics.audit_path/1` has no catch-all clause — FunctionClauseError when resource_type or resource_id is nil

**File:** `lib/oban_powertools/forensics.ex:480-486`

**Issue:** `lifeline_resource/2` can return `%{resource_type: "job", resource_id: ""}` when `job_ids` is empty and `List.first([]) |> to_string()` produces `""`. This value is then passed to `audit_path/1` at line 235. The clause at line 480 has a guard `when not is_nil(type) and not is_nil(id)` that rejects the empty-string case. The clause at line 485 matches `%{type: _, id: _}` but that key shape is not what `lifeline_resource` returns. No clause matches, causing a `FunctionClauseError`.

**Fix:** Add a fallback clause and handle the empty resource_id case in `lifeline_resource/2`:

```elixir
defp audit_path(_resource), do: Selectors.audit_path([])
```

---

### WR-04: `list_executor_health/2` performs database writes inside a function documented as a read

**File:** `lib/oban_powertools/lifeline.ex:57-79`

**Issue:** `list_executor_health/2` calls `repo.update()` for every heartbeat whose `health_state` differs from the freshly classified state. This means a "list" operation silently mutates persistent state. The function is called twice per page load from `LifelineLive.load_data/2` — once through `Lifeline.project_incidents/2` (line 101) and once directly (line 655). Each call recomputes and writes health states, doubling the write load. Because the function name implies a read-only query, callers may introduce additional call sites without expecting write side-effects. The write is also unchecked (the `{:ok, _}` bind will raise a `MatchError` on `{:error, _}`).

**Fix:** Extract the classification+write into `project_incidents` where side-effecting work already belongs, or rename the function to `classify_and_persist_executor_health/2` to signal its write behavior. The `{:ok, _}` pattern match should at minimum log on error rather than raise.

---

### WR-05: `OverviewReadModel` accesses `event.resource_type`, `event.resource_id`, and `event.event_type` directly rather than via `Audit` helpers

**File:** `lib/oban_powertools/web/overview_read_model.ex:270-292`, `lib/oban_powertools/web/overview_read_model.ex:415-421`

**Issue:** `resolved_exemplars/2` and `resolved_next_step_path/2` access `event.resource_type`, `event.resource_id`, and `event.event_type` directly on the `Audit` struct. The canonical read path for these is `Audit.event_resource_identity/1` and `Audit.event_label/1` (which normalise legacy `resource` encoding). For older audit events where `resource_type` and `resource_id` were not populated separately (stored in the composite `resource` field), these direct accesses will return `nil`, producing empty path segments like `/ops/jobs/audit?resource_type=&resource_id=`. `ControlPlanePresenter.audit_follow_up_path/1` already uses the correct helper.

**Fix:** Replace direct field access with the helpers:

```elixir
identity = Audit.event_resource_identity(event)
Selectors.audit_path([
  {"resource_type", identity.type},
  {"resource_id", identity.id},
  {"event_type", Audit.event_label(event)}
])
```

---

## Info

### IN-01: Typos in user-facing diagnosis strings — "entrie(s)" should be "entries"

**File:** `lib/oban_powertools/web/overview_read_model.ex:174`, `lib/oban_powertools/web/overview_read_model.ex:181`

**Issue:** Two diagnosis strings contain the malformed word `entrie(s)`:

- Line 174: `"paused cron entrie(s) are waiting on native follow-up."`
- Line 181: `"cron entrie(s) are currently runnable."`

The parenthetical pluralization pattern `entrie(s)` is inconsistent with the rest of the file, which uses `(s)` appended to correctly-spelled words (`cooldown(s)`, `resource(s)`, `incident(s)`). `entrie(s)` is not a word; it should be `entries` or `entry(entries)`.

**Fix:** Change both occurrences to `"entries"` (since the count is already displayed as an integer in the same string).

---

### IN-02: Dead code — `project_incidents/2` return value is discarded in `LifelineLive.load_data/2`

**File:** `lib/oban_powertools/web/lifeline_live.ex:602`

**Issue:** `Lifeline.project_incidents(repo)` is called for its side effects (upserting incidents), but the returned list is ignored. The active incidents are then fetched separately via `Lifeline.list_incidents(repo, status: "active")`. This is intentional but the call site should carry a comment to that effect; a future reader may flag it as dead code and remove it, breaking incident projection.

**Fix:** Add a comment or bind to `_`:

```elixir
# Project incidents (side-effectful upsert); result is fetched below via list_incidents.
_projected = Lifeline.project_incidents(repo)
```

---

### IN-03: `EvidenceBundle.normalize_completeness/1` does not forward through unknown map keys

**File:** `lib/oban_powertools/forensics/evidence_bundle.ex:79-86`

**Issue:** The binary-key branch of `normalize_completeness/1` (lines 79-86) explicitly normalises only `"state"` and `"details"` keys. Any additional keys in the raw completeness map (e.g., `"selectors"` which is explicitly present in the `unknown_bundle/1` at `forensics.ex:279`) are dropped silently. The `unknown_bundle` passes `%{state: :unknown, details: "...", selectors: selectors}` which goes through `EvidenceBundle.build/1`'s atom-key branch (`%{state: state} = item` at line 75), so `selectors` is preserved there. But if a host app passes a binary-key completeness map with extra fields, those fields vanish. This is low severity since the `selectors` key in the unknown bundle uses atom keys, but the discrepancy between the two completeness normalisation branches is fragile.

**Fix:** Add a passthrough for unknown keys in the binary-key branch:

```elixir
defp normalize_completeness(%{"state" => _state} = item) do
  item
  |> Map.new(fn
    {"state", value} -> {:state, Provenance.normalize_completeness(value)}
    {"details", value} -> {:details, value}
    {key, value} -> {key, value}  # preserve unknown keys
  end)
end
```

---

_Reviewed: 2026-05-27T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
