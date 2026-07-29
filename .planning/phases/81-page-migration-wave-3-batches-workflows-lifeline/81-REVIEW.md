---
phase: 81-page-migration-wave-3-batches-workflows-lifeline
reviewed: 2026-07-29T15:14:36Z
depth: standard
files_reviewed: 41
files_reviewed_list:
  - .github/workflows/ci.yml
  - assets/oban_powertools/tokens.css
  - examples/phoenix_host/config/test.exs
  - examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex
  - examples/phoenix_host/lib/phoenix_host_web/router.ex
  - examples/phoenix_host/test/phase81_browser_fixtures_test.exs
  - examples/phoenix_host/test/support/phase81_browser_fixtures.ex
  - lib/oban_powertools/batches.ex
  - lib/oban_powertools/web/batches_live.ex
  - lib/oban_powertools/web/control_plane_presenter.ex
  - lib/oban_powertools/web/dev/showcase_live.ex
  - lib/oban_powertools/web/lifeline_live.ex
  - lib/oban_powertools/web/selectors.ex
  - lib/oban_powertools/web/workflows_live.ex
  - mix.exs
  - package.json
  - priv/static/oban_powertools/oban_powertools.css
  - scripts/playwright-docker.sh
  - scripts/showcase_manifest.exs
  - scripts/with-showcase-server.sh
  - test/browser/specs/page-migration-wave-1.spec.ts
  - test/browser/specs/page-migration-wave-3.spec.ts
  - test/browser/specs/phase81-fixtures.spec.ts
  - test/browser/support/manifest-smoke.mjs
  - test/browser/support/manifest.ts
  - test/browser/support/phase81-fixtures.ts
  - test/browser/support/verify-page-aria-snapshots.mjs
  - test/browser/support/verify-page-baselines.mjs
  - test/browser/support/verify-page-script-order.mjs
  - test/browser/voiceover/page.voiceover.spec.ts
  - test/oban_powertools/page_story_catalog_test.exs
  - test/oban_powertools/showcase_catalog_test.exs
  - test/oban_powertools/web/assets_test.exs
  - test/oban_powertools/web/live/batches_live_test.exs
  - test/oban_powertools/web/live/lifeline_live_test.exs
  - test/oban_powertools/web/live/showcase_live_test.exs
  - test/oban_powertools/web/live/workflows_live_test.exs
  - test/oban_powertools/web/operator_pattern_presenter_test.exs
  - test/oban_powertools/web/selectors_test.exs
  - test/oban_powertools/web/theme_tokens_test.exs
  - test/support/page_story_catalog.ex
findings:
  critical: 5
  warning: 3
  info: 0
  total: 8
status: issues_found
---

# Phase 81: Code Review Report

**Reviewed:** 2026-07-29T15:14:36Z
**Depth:** standard
**Files Reviewed:** 41
**Status:** issues_found

## Summary

The Phase 81 migration has five shipping blockers in its bounded production reads and mutation confirmation copy. The new test suite passes (`89 tests, 0 failures` across the scoped Batches, Workflows, Lifeline, presenter, and selector suites), but three test-quality gaps explain why these defects are not detected: the connected race test does not exercise production outcomes, several fixture cardinalities are asserted only from a hard-coded response, and the archive bound is dead code.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: The “Failed Members” window includes successful jobs

**File:** `lib/oban_powertools/batches.ex:320-333`
**Issue:** `detail_members/4` replaced the prior `failed_members/3` read, but it only sorts failed/discarded members first; it never filters out completed members. `BatchesLive` renders the returned collection under “Failed Members” and labels every checkbox “Select failed job.” With the Phase 81 fixture, the 50-row window contains all 26 discarded members plus 24 completed members. Operators therefore see successful jobs represented as failures, and a batch with no failures but at least one completed member no longer renders the “No failed members” state.
**Fix:**
```elixir
BatchJob
|> join(:left, [member], job in Oban.Job, on: job.id == member.job_id)
|> where(
  [member, job],
  member.state in ^@failed_member_states or job.state in ^@failed_member_states
)
|> order_by([member], asc: member.inserted_at, asc: member.job_id)
|> limit(^limit)
```
Preserve the existing `failed_member?/2` semantics exactly if the database predicate needs to distinguish missing jobs or additional states.

### CR-02: Workflows displays the oldest retained attempt as the current result

**File:** `lib/oban_powertools/web/workflows_live.ex:387-405`
**Issue:** Results are queried newest-first and then converted with `Map.new(&{&1.step_id, &1})`. When a step has multiple attempts, later enumeration overwrites the newest row with the oldest row in the bounded window. The Phase 81 fixture creates 51 attempts for one step specifically in this shape: attempt 1 is newest, while attempt 51 is oldest and has a different status. The UI consequently diagnoses the selected step from stale result evidence. The global 51-row cap can also omit a selected step’s latest result when other steps have newer attempts.
**Fix:**
```elixir
results_by_step =
  results
  |> Enum.reduce(%{}, fn result, acc ->
    Map.put_new(acc, result.step_id, result)
  end)
```
Better, query one latest result per rendered step using `DISTINCT ON (step_id)` ordered by `step_id, recorded_at DESC, id DESC`, and separately probe `LIMIT + 1` for truthful completeness.

### CR-03: Lifeline’s bounded incident window selects old, class-sorted incidents before ranking

**File:** `lib/oban_powertools/web/lifeline_live.ex:990-1012`
**Issue:** `Lifeline.list_incidents/2` returns incidents ordered by `incident_class ASC, inserted_at ASC`. `load_data/2` takes the first 51 from that ordering and only then expands and sorts the retained subset by severity and recency. Newer or more severe incidents outside the alphabetically earliest/oldest 51 are invisible, deep links to them silently fall back to another row, and the UI’s “Showing the newest 50 incidents” statement is false.
**Fix:** Build a database-bounded query ordered by the actual presentation priority (severity and `last_detected_at DESC`, with a stable ID tie-breaker), fetch `LIMIT 51`, then expand/render the first 50. If severity cannot be expressed safely in SQL, sort the authorized incident set before applying the cap and add a dedicated bounded query API afterward.

### CR-04: Lifeline drops relevant audit history by limiting before filtering

**File:** `lib/oban_powertools/web/lifeline_live.ex:1254-1261`
**Issue:** `audit_events_for_row/1` takes the newest 51 audit events globally and only then filters for the selected incident or resource. A relevant event disappears as soon as 51 unrelated events are newer, causing the page to claim that no remediation attempts were recorded even though durable evidence exists.
**Fix:** Apply the resource/fingerprint predicate in the query before ordering and `LIMIT 51`. At minimum, move the `Enum.filter/2` before `Enum.take/2`; the preferred fix is an `Audit` query that performs the OR predicate, `inserted_at DESC, id DESC`, and `LIMIT + 1` in the database.

### CR-05: Callback confirmation describes the target as a failed job

**File:** `lib/oban_powertools/web/control_plane_presenter.ex:304-320`
**Issue:** `present_batch_retry_preview/2` always produces a scope such as “1 currently eligible failed job.” `BatchesLive` calls this same projector for `callback_retry`, so the callback mutation dialog tells the operator that a job is being retried even though the held capability targets a callback. This is materially misleading confirmation copy immediately before a state-changing action.
**Fix:**
```elixir
noun = presentation_text(presentation_value(context, :object_noun), "job")
scope = "#{count} currently eligible #{noun}#{if(count == 1, do: "", else: "s")}"
```
Pass `object_noun: "callback"` from the callback flow and `object_noun: "failed job"` from the bulk-job flow, with focused assertions for both rendered dialogs.

## Warnings

### WR-01: The connected race test never drives the advertised production outcomes

**File:** `test/browser/specs/page-migration-wave-3.spec.ts:362-390`
**Issue:** The test named “Lifeline distinguishes drifted, duplicate, disconnected, interrupted, partial, skipped, and failed outcomes” only calls the fixture control endpoint and verifies that it echoes four different strings. It does not preview or execute a repair, does not cause production Lifeline code to consume those states, and does not assert any corresponding UI result. `partial`, `skipped`, and `failed` are not driven at all.
**Fix:** Make each fixture command alter the real preview/target/execution seam, perform the connected preview/execute flow for every state, and assert the rendered status, recovery guidance, fresh-preview requirement, and Audit link behavior.

### WR-02: Saturated fixture cardinalities are hard-coded rather than proven

**File:** `examples/phoenix_host/test/support/phase81_browser_fixtures.ex:32-44`
**Issue:** The public response claims `workflowEvidence: 26` and `batchResults: 51`, but the fixture does not insert workflow `Edge` rows and no production batch-result source is populated. The fixture test verifies those values only by comparing the returned `@counts` map; unlike workflows, steps, callbacks, incidents, and audits, it never queries storage to prove these families exist. This lets the connected suite report saturated coverage without exercising the relevant `LIMIT + 1` branches.
**Fix:** Seed the actual `Edge` and batch-result sources consumed by production, derive counts from inserted records, and assert storage plus rendered completeness guidance. Remove any family count that has no real production source.

### WR-03: The archive limit is dead code

**File:** `lib/oban_powertools/web/lifeline_live.ex:1033-1036`
**Issue:** `_bounded_archive_window` computes an archive window and immediately discards it. The page still projects only `retention.last_run`, while the source-contract test passes merely because `@archive_limit + 1` appears in the file. This is misleading maintenance evidence and does not validate a 25-row archive boundary.
**Fix:** Either remove `@archive_limit` and the claimed archive-window contract because the page intentionally shows only the latest run, or load, assign, render, and test an actual `LIMIT 26` archive collection.

---

_Reviewed: 2026-07-29T15:14:36Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
