# Phase 80 Research: Page Migration Wave 2 — Jobs + Forensics

**Phase:** 80
**Researched:** 2026-07-27
**Status:** Ready for planning
**Primary requirements:** PAGE-02, PAGE-09, FORM-03, DATA-*, PAGE-10, A11Y-*
**Authority:** `80-CONTEXT.md` is the binding phase contract. This research explains how to implement it in the current repository.

## Research Question

How should the existing Jobs and Forensics LiveViews be migrated onto the Phase 77–79 design system without weakening their current behavior, while adding the URL, selection, bulk-operation, bounded-evidence, redaction, accessibility, deterministic-fixture, and browser-quality guarantees locked by Phase 80?

## Executive Summary

Phase 80 is not primarily a markup replacement. The existing pages render useful data, but their state and data-access shapes do not satisfy the phase contract:

- Jobs currently applies filters on every `phx-change`, performs seven state-count queries, uses unbounded ID enumeration for “all matching,” executes bulk work synchronously and sequentially in the LiveView, exposes raw error material, and renders bespoke tables/modals rather than shared components.
- Forensics currently chooses a scope by hidden precedence, has no typed chooser, loads all audit events and filters them in memory for workflow and incident scopes, exposes overly broad event maps, and renders a flat card wall rather than a diagnosis-first evidence page.
- The shared components needed by both pages already exist. Phase 79 established the correct pattern: LiveViews own URL/authentication/orchestration, presenters produce closed safe display maps, and public pure `page_content/1` components are rendered by both production and deterministic page stories.
- The existing page-quality pipeline is deliberately cardinality-locked to 19 Wave 1 stories, four themes, and three viewports. Phase 80 must extend the same catalog, manifest, ARIA, axe, and VRT pipeline; it must not create a parallel screenshot system.

The safest implementation is a dependency-ordered set of plans rather than one Jobs plan and one Forensics plan. Jobs bulk coordination is independently high-risk and should not be mixed with ordinary page composition. Forensics scoped data access should be implemented and tested before its LiveView is rearranged. Deterministic stories and connected browser fixtures should follow the production composition seams, then the final plan should run the complete page-quality matrix and focused behavioral suites.

No new runtime dependency, database migration, public route, or router shape is required. A named library-owned `Task.Supervisor` is required for bulk execution. The incident audit predicate is currently a JSONB metadata predicate without a supporting index; because Phase 80 forbids a surprise migration, the plan must measure and document that bounded query rather than quietly introduce schema work.

## Binding Inputs and Precedence

Use this precedence whenever implementation details conflict:

1. `guides/brand-book.md`
2. Current `PROJECT.md`, `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md`
3. Shipped Phase 77–79 production components and validated patterns
4. Phase 80 `80-CONTEXT.md`
5. Older research or historical implementation choices

Within Phase 80, the decisions in `80-CONTEXT.md` are locked. `80-DISCUSSION-LOG.md` is an audit trail and is not an independent source of planning decisions.

Important interpretation notes:

- The requirements file is internally inconsistent for accessibility: the requirement definitions check A11Y-01 through A11Y-04, while the traceability table marks A11Y-02 through A11Y-04 pending for Phase 82. DATA-01 through DATA-04 and PAGE-10 are checked as shared contracts. Regardless of ledger status, all of those shared contracts remain Phase 80 acceptance obligations: the two migrated pages must consume them correctly and must not regress their guarantees.
- `MOTION-*` is not a named primary requirement in the Phase 80 roadmap row, but D83 and D88 explicitly require reduced-motion verification. Treat that as an acceptance condition.
- PAGE-02 means Jobs becomes a first-class migrated page with safe batch operations, not merely a restyled table.
- PAGE-09 means Forensics becomes a diagnosis-first read-only evidence page, not merely the existing bundle cards inside new surfaces.
- PAGE-10 means deterministic rendering and browser verification of the actual production composition seams.

## Current Baseline

The focused current regression suite passes:

```bash
mix test \
  test/oban_powertools/jobs_test.exs \
  test/oban_powertools/web/live/jobs_live_test.exs \
  test/oban_powertools/forensics_test.exs \
  test/oban_powertools/forensics/evidence_bundle_test.exs \
  test/oban_powertools/web/live/forensics_live_test.exs \
  test/oban_powertools/web/components/operator_patterns_test.exs \
  test/oban_powertools/web/components/data_display_test.exs \
  --seed 0
```

Observed result on 2026-07-27: **134 tests, 0 failures**.

Existing warnings in `jobs_live_test.exs`:

- unused `job2` near line 1054
- unused `job1` and `job2` near lines 1089–1090

Those warnings predate this research. They are worth cleaning when those tests are edited, but they are not Phase 80 failures.

The current test output also makes the seven independent state-count queries visible. That is useful evidence for the Jobs query change; the phase should replace them with one grouped query rather than merely hiding the output.

## Repository Map and Existing Seams

### Jobs

| File | Existing responsibility | Phase 80 consequence |
|---|---|---|
| `lib/oban_powertools/web/jobs_live.ex` | List and detail rendering, URL parsing, polling, selection, preview, execution | Must become orchestration-only around canonical params, presenters, shared components, and an async coordinator |
| `lib/oban_powertools/jobs.ex` | Oban job filters, list, get, unbounded IDs, state counts | Must provide composable queries, exact counts, grouped state counts, and bounded ordered ID enumeration |
| `lib/oban_powertools/operator.ex` | Existing public sequential bulk APIs | Preserve compatibility; do not use these as the page coordinator if they cannot meet the frozen/supervised/progress contract |
| `lib/oban_powertools/lifeline.ex` | Authoritative preview and one-target execution with audit, drift, expiry, and authorization | Reuse for every single and bulk target; do not bypass with direct Oban calls |
| `lib/oban_powertools/runtime_config.ex` | Validated runtime accessors | Add the batch target limit contract here |
| `lib/oban_powertools/application.ex` | Library supervision tree | Add the named library `Task.Supervisor` |

Current `JobsLive` symbols that the implementation will replace or substantially reshape include:

- `mount/3`
- both `handle_params/3` clauses
- events `select_state`, `filter`, `toggle_job`, `toggle_all`, `select_all_global`, `clear_selection`, `paginate`, `preview`, `preview_bulk`, `close_preview`, `reason`, `execute`, and `execute_bulk`
- both `render/1` clauses
- `load_job_detail/2`
- recorded-output helpers
- `back_path_from_session/1`
- default/filter parsing and URL construction helpers

Do not preserve those event names merely for familiarity. Preserve externally observable behavior and tests where useful, but prefer events that reflect the locked state machine: draft validation, filter submission, explicit scope selection, preview, confirmation, execution, result dismissal, and quick-review open/switch/close.

### Forensics

| File | Existing responsibility | Phase 80 consequence |
|---|---|---|
| `lib/oban_powertools/web/forensics_live.ex` | Page authorization, parameter normalization, bundle rendering | Must own typed selector form, canonical URL transitions, uniform unavailable state, and diagnosis-first composition |
| `lib/oban_powertools/forensics.ex` | Scope precedence, evidence loading, chronology inputs, completeness helpers | Must validate exactly one supported scope and use bounded scoped audit queries |
| `lib/oban_powertools/forensics/chronology.ex` | Newest-first ordering | Reuse ordering, but feed it closed, normalized event maps |
| `lib/oban_powertools/forensics/evidence_bundle.ex` | Bundle normalization | Retain useful normalization while preventing unknown/raw fields from reaching rendering |
| `lib/oban_powertools/audit.ex` | Audit query/page/fetch APIs | Add a bounded scoped window API rather than calling `list_all/1` and filtering in memory |
| `lib/oban_powertools/cron_history.ex` | Bounded cron fact history | Reuse with explicit coverage/provenance presentation |
| `lib/oban_powertools/limiter_history.ex` | Bounded limiter fact history | Reuse with explicit coverage/provenance presentation |

Current `Forensics.bundle/2` silently applies this precedence:

1. workflow
2. Lifeline incident
3. Cron pair
4. Limiter pair
5. unknown

That behavior conflicts with the locked selector contract. Conflicting or malformed scope families must canonicalize to the empty chooser with an explanation; they must never be interpreted by precedence.

### Shared UI and presentation

| File | Reusable capability |
|---|---|
| `lib/oban_powertools/web/components/operator_patterns.ex` | `filter_bar/1`, `detail_surface/1`, `confirm_action_dialog/1` |
| `lib/oban_powertools/web/components/data_display.ex` | `data_table/1`, `timeline/1`, `description_list/1`, `args_viewer/1`, `code_block/1`, explicit empty/error/loading/progress patterns |
| `lib/oban_powertools/web/control_plane_presenter.ex` | Pure display-safe presentation seam established in prior phases |
| `lib/oban_powertools/web/selectors.ex` | Central route/selector URL construction |
| `assets/oban_powertools/tokens.css` | Source token and page-composition styles |
| `priv/static/oban_powertools/oban_powertools.css` | Built asset; regenerate from source rather than hand-editing |

The shared components already cover nearly all Phase 80 interaction shapes. The pages should compose them, not fork them:

- Jobs filters: `filter_bar/1` in `:submit` mode
- Jobs list: `data_table/1`
- Jobs quick review: `detail_surface/1`
- single and bulk actions: `confirm_action_dialog/1`
- argument/metadata/output rendering: `args_viewer/1` and `code_block/1`
- Forensics event stream: `timeline/1`
- identity, scope, and coverage facts: `description_list/1`

`data_table/1` preserves one semantic native table and supplies responsive labels; do not replace it with an ARIA grid or a duplicate mobile DOM. `detail_surface/1` supplies the adaptive dialog/surface mechanics, but the parent must continue to own the URL, selected resource, authorization, and close behavior.

### Deterministic page-quality infrastructure

Wave 1 deliberately hard-codes its acceptance contract in several places:

- `test/support/page_story_catalog.ex`: 19 page stories for Overview, Cron, Limiters, and Audit
- `lib/oban_powertools/web/dev/showcase_live.ex`: `@page_story_count 19`, the four allowed pages, story activation types, and direct calls to public `page_content/1`
- `scripts/showcase_manifest.exs`: exactly 19 page stories and 83 total showcase targets
- `test/browser/support/verify-page-baselines.mjs`: exactly 19 stories, a four-page ID regex, and 228 images (`19 × 4 themes × 3 viewports`)
- `test/browser/support/verify-page-aria-snapshots.mjs`: the page ARIA contract
- `test/browser/specs/page.acceptance.spec.ts`: per-story structural assertions
- `test/browser/specs/page-migration-wave-1.spec.ts`: connected Wave 1 behavior
- `test/browser/specs/showcase.a11y.spec.ts`: axe matrix
- `test/browser/specs/showcase.vrt.spec.ts`: screenshot matrix
- `test/browser/specs/phase79-fixtures.spec.ts` and `test/browser/support/phase79-fixtures.ts`: opt-in connected fixtures
- `examples/phoenix_host_upgrade_source`: isolated test host used by the fixture route

`npm run verify:pages` is the umbrella gate. Phase 80 should extend it to include the new connected spec and the new page-story totals.

## Recommended Architecture

The architectural boundary should be:

```text
untrusted URL/event
        |
        v
LiveView canonical parser + authorization
        |
        +----> context query API (bounded, stable, exact where promised)
        |
        +----> Lifeline preview/execute (all mutations)
        |
        v
ControlPlanePresenter (closed, redacted display maps)
        |
        v
public pure page_content/1
        |
        v
shared design-system components
```

The same `page_content/1` must be called by:

- the production `render/1`
- the deterministic page-story showcase

No repository lookup, authentication call, clock read, task spawn, or mutation belongs inside `page_content/1`. This is the Phase 79 composition seam and is the key to PAGE-10.

Use separate context modules for data and lifecycle concerns:

- `Jobs` owns job query construction and bounded ID selection.
- A focused Jobs batch coordinator module owns frozen scope and supervised execution. It may be nested under `ObanPowertools.Jobs` or `ObanPowertools.Web.JobsLive`, but the reusable state machine should not be embedded as private render/event code.
- `Forensics` owns selector validation and evidence retrieval.
- `Audit` owns Ecto construction for audit windows.
- `ControlPlanePresenter` owns display-safe, finite maps and labels.
- `Selectors` owns URL allowlisting and canonical ordering.

## Jobs Implementation Research

### 1. Canonical URL and form model

The required list URL state is:

- `state`: always present logically; one of the seven supported Oban states
- `queue`
- `worker`
- `tags`
- `args`
- `meta`
- `page`
- `job`: optional quick-review ID

The required state must not become a removable chip. Optional filters become removable applied chips.

Recommended parsing contract:

```elixir
%{
  query: %Jobs{
    state: "available",
    queue: nil,
    worker: nil,
    tags: [],
    args: %{},
    meta: %{},
    page: 1,
    page_size: 20
  },
  canonical_params: [...],
  explanations: [...],
  quick_review_id: nil | integer
}
```

Keep separate objects for:

- **applied URL state**, which drives queries and chips
- **draft form state**, which may be invalid and remains visible until corrected or resubmitted

`filter_bar/1` should use `mode={:submit}`. The change event only validates draft fields and reveals the advanced section; it must not patch or query. The submit event validates all draft fields and then patches the canonical URL.

Required validation semantics:

- `args` and `meta` are JSON object containment filters, not arbitrary JSON values.
- `tags` means all listed tags are required.
- queue and worker are plain bounded strings using existing project conventions.
- no qualifier DSL is introduced.
- an invalid draft remains in the form with field errors.
- invalid direct URL JSON is replaced with safe defaults and a visible explanation.

The field microcopy is locked and should be asserted verbatim:

- tags: “Separate tags with commas. Jobs must contain every listed tag.”
- JSON fields: “Enter a JSON object. Filter values are stored in the URL; do not enter secrets.”
- invalid JSON: “Enter a valid JSON object.”

Recommended canonicalization flow:

1. Parse all URL params as untrusted input.
2. Record whether canonicalization is required.
3. Build the safe applied query and form.
4. If direct URL input was invalid, `push_patch(..., replace: true)` to the safe canonical URL.
5. Render the explanation after the replacement.
6. Never query with the invalid value.

Changing state or optional filters must reset:

- page to 1
- quick review
- explicit selection
- frozen all-matching scope
- preview
- progress/results

Removing a chip or clearing optional filters has the same reset behavior while preserving required state.

Pagination preserves explicit selected IDs but not quick review. This gives operators a stable cross-page selection without carrying a contextually stale review surface.

### 2. Central URL construction

Extend `ObanPowertools.Web.Selectors` rather than constructing paths ad hoc in `JobsLive`.

Recommended additions:

```elixir
jobs_path(params)
job_detail_path(id, list_params \\ [])
```

`job_detail_path/2` should allow only the list-return keys:

```elixir
~w(state queue worker tags args meta page)
```

It must:

- drop unknown keys
- use deterministic ordering
- normalize/default values consistently with the list parser
- never accept `return_to`
- never propagate `job`

The full detail page builds its back link from these explicit allowlisted params, not `back_path_from_session/1`. This makes bookmarks, refreshes, and copied URLs deterministic.

Quick-review transitions:

- first open: `push_patch`, creating a history entry
- switch from one reviewed job to another: `push_patch(..., replace: true)`
- close: `push_patch(..., replace: true)` with `job` removed
- browser Back after the first open: closes review naturally
- stale, malformed, missing, or unauthorized `job`: same unavailable result and safe replacement with `job` removed

The trigger is an explicit “Review job” control. Do not make the entire row interactive. The selected row needs a non-color visual treatment plus a programmatically determinable current/selected state.

### 3. Query API

`lib/oban_powertools/jobs.ex` currently has the correct filter semantics and stable list order, but its API shapes are insufficient:

- `list/3` orders by `scheduled_at DESC, id DESC`
- `list_ids/2` is unbounded and lacks explicit order
- `count_by_state/2` performs seven queries
- there is no exact filtered count for pagination/range copy

Refactor query construction so state is optional and the non-state predicates are reusable. A useful internal split is:

```elixir
defp filtered_query(query, opts)
defp apply_non_state_filters(query, %Jobs{})
defp apply_state_filter(query, %Jobs{})
```

Recommended public context APIs:

```elixir
list(repo, filters, opts)
count(repo, filters, opts)
count_by_state(repo, filters, opts)
ordered_ids_window(repo, filters, limit, opts)
get(repo, id, opts)
```

Exact names are discretionary, but the capabilities are not.

`count_by_state/3` must use one grouped query over the same non-state filters:

```sql
SELECT state, count(*)
FROM oban_jobs
WHERE <queue/worker/tags/args/meta predicates>
GROUP BY state
```

Merge its result into a seven-key zero map. Do not make a follow-up query for missing states.

The current list state uses 20 rows per page. Query:

- the current 20-row page
- the exact count for the active state and optional filters
- the seven grouped counts over the same optional filters

Use the exact count for:

- “Showing X–Y of Z”
- previous/next availability
- an exact final page when `Z` is a multiple of 20

Do not infer `Next` from `length(rows) == 20`; that is wrong at an exact full last page.

`ordered_ids_window/4` supports all-matching scope with `limit + 1`, using the same stable `scheduled_at DESC, id DESC` ordering and the same applied filter identity. The extra row only detects overflow. It must never be included in the frozen scope.

Retain the existing module documentation that recommends host-owned GIN indexes for `tags`, `args`, and `meta`. Phase 80 does not own host schema migrations.

### 4. Table and quick-review presentation

Create closed presenter functions in `ControlPlanePresenter`. Names may vary, but the output responsibilities should be distinct:

```elixir
present_job_row(job, policy)
present_job_quick_review(job, policy)
present_job_detail(job, policy)
```

The row map should contain only:

- ID and accessible ID label
- full worker module
- state label/tone
- queue
- scheduled absolute time
- attempts/max attempts
- selection label/state
- review label/state

Do not shorten the worker to only its final module segment. Visual truncation may be CSS-only, but the full worker must remain in the DOM and accessible.

Use `data_table/1` with these exact conceptual columns:

1. Selection
2. Worker
3. State
4. Queue
5. Scheduled
6. Attempts
7. Job ID
8. Review job

At 320px the shared component should produce the locked stacked semantic table without duplicating rows or creating horizontal page scroll. Selection controls require:

- at least a 44×44 CSS-pixel target
- accessible name such as `Select job 123`
- visible focus indication
- non-color checked/selected state

The quick-review presenter is deliberately bounded and read-only. It may expose only:

- full job ID
- state
- worker
- queue
- attempts/max attempts
- contextual timestamp
- structurally redacted latest error
- whether recorded output is available
- enqueue redaction disclosure
- link to full details

It must not assign or render:

- args or meta
- output payload
- full stack trace
- full attempt history
- audit history
- mutations

This is an assign-time contract, not just a template condition. Sensitive material excluded from the presenter cannot leak through comments, hidden DOM, debug attributes, or LiveView diffs.

### 5. Full job detail

The full detail route remains `/jobs/:id`. It is the only location for job mutation controls.

Render in this order:

1. current/support state
2. legal actions
3. identity and timing
4. error and attempts
5. args, meta, recorded output, and redaction disclosure
6. related authorized destinations

Use existing shared data-display components for all structured payloads. The current page renders raw cards and `<pre>` blocks; replace them with the closed presenter maps plus `args_viewer/1`, `code_block/1`, and `description_list/1`.

Current errors and stack traces need a new semantics-aware presenter. `DisplayPolicy` already covers args, meta, and recorded output; do not assume it safely normalizes Oban error arrays. The error presenter must:

- retain useful attempt/timestamp/class/message structure only when allowed
- redact token, secret, credential, URL/query, header, and payload-like values
- bound entries and text lengths
- never expose an arbitrary struct or exception via `inspect/1`
- produce the same safe meaning across HTML, logs, telemetry, and test diagnostics

Missing and unauthorized jobs render the same “Job unavailable” state. Do not retain the current distinct “Job not found” copy.

Legal actions are contextual:

- retry: warning treatment and primary within its confirmation
- cancel/discard: danger treatment
- unavailable actions are explained, not rendered as dead unexplained buttons

Every action must use Lifeline preview and the shared `confirm_action_dialog/1`; do not call direct Oban mutation functions from the LiveView.

### 6. Selection state

Represent explicit and all-matching scopes as different states, not a `global_select` boolean.

Suggested state shapes:

```elixir
%{mode: :explicit, ids: MapSet.t(integer)}

%{
  mode: :all_matching,
  ids: [integer],
  filter_identity: binary,
  selected_count: non_neg_integer,
  observed_at: DateTime.t()
}
```

The LiveView may hold a richer struct, but it should have these properties:

- explicit selected IDs persist across pages
- page selection affects exactly the 20 visible row IDs
- when every eligible row on the current page is selected, offer an explicit “Select all N matching jobs” control
- all-matching freezes ordered IDs immediately
- all-matching does not rerun the query at preview or execution time
- any filter/state change clears the frozen scope
- pagination does not alter the frozen IDs

Do not encode all-matching as “run this filter later.” That would make the confirmation scope non-deterministic.

Use a canonical filter identity produced from applied params, not a raw map hash whose order or representation could vary.

### 7. Batch limit configuration

Add a runtime configuration accessor in `RuntimeConfig`:

```elixir
bulk_job_target_limit()
```

Contract:

- default: 100
- maximum allowed override: 1000
- positive integer only
- malformed, zero, negative, or greater-than-1000 configuration fails clearly

Use the repository’s centralized runtime config error style. Prefer validating it during application startup so an invalid setting fails deterministically rather than when an operator first tries a batch. If the project’s current config-loading pattern makes startup validation inappropriate, the accessor must still fail with an actionable library error and tests must cover the exact message.

The exact config key name is still a planner-level naming choice. It should live under the existing Oban Powertools application configuration and must be documented in the phase’s host-facing notes.

### 8. Preview and confirmation

Preview is both an authorization boundary and the source of confirmation truth.

For every frozen target:

1. authorize page access
2. authorize the requested action
3. authorize the specific target
4. call real `Lifeline.preview_repair/4`
5. classify it as ready or excluded using a finite safe reason taxonomy

Never create a fake bulk preview by inferring state in the UI. Lifeline preview supplies the authoritative token, drift protection, and action legality.

The preview model should contain server-only and display-safe layers:

```elixir
%{
  scope: %{...},
  ready: [%{job_id: id, token: opaque, safe_row: %{...}}],
  excluded: [%{job_id: id, reason: :not_eligible, safe_row: %{...}}],
  created_at: DateTime.t(),
  display: %{...}
}
```

Tokens and internal errors never enter the display map.

Confirmation copy/data must include:

- selected count
- ready count
- excluded count
- off-page count
- frozen filter identity in human terms
- observed/frozen time
- consequence
- reversibility/support statement
- explicit non-atomic statement

Submission requires both:

- trimmed reason of at least 8 characters
- exact typed ready count

Zero-ready preview renders as unavailable and cannot submit.

If any ready target drifts or its preview expires before execution, do not silently re-preview it. Mark the stale target safely and require a fresh preview for another attempt.

### 9. Supervised execution

Add a named library-owned `Task.Supervisor` under `ObanPowertools.Application`. Do not use an unlinked raw task owned by the LiveView process.

Recommended lifecycle:

```text
confirmed preview
  -> start nonlinked coordinator task
  -> execute ready targets with max concurrency 4
  -> each target has a finite timeout
  -> send low-cardinality progress messages to LiveView
  -> emit stable ordered final result
```

Use `Task.Supervisor.async_stream_nolink/6` or equivalent library-supervised nonlinked work, with:

- `max_concurrency: 4`
- ordered result reconstruction by the frozen target order
- a per-target timeout
- `on_timeout: :kill_task`
- no one-big `Ecto.Multi`

The exact timeout is not locked in context. Choose and document a conservative finite default in the plan; keep it internal unless there is a demonstrated host need for configuration.

Every target executes independently through `Lifeline.execute_repair/5`. This preserves:

- target-level authorization
- preview token validation
- drift/expiry/consumed behavior
- Lifeline audit receipts
- non-atomic recovery

The existing `Operator.bulk_retry/…`, `bulk_cancel/…`, and `bulk_discard/…` APIs are sequential. Preserve their public behavior unless the implementation deliberately and separately upgrades them with compatibility tests. They are not a substitute for the page coordinator as currently written.

The LiveView should receive messages containing only:

- run reference
- processed count
- total count
- success/skipped/failed aggregate counts
- final bounded display results when complete

Do not send job payloads, tokens, raw exceptions, reasons, or high-cardinality IDs through telemetry or logs.

Disconnect semantics are intentionally limited:

- browser disconnect does not cancel the supervised coordinator
- node restart may interrupt it
- there is no durable aggregate run ledger in Phase 80
- the individual Lifeline audit records are recovery authority

Do not imply that the UI can reconstruct exact aggregate progress after reconnection. Copy and tests should state that limitation honestly.

### 10. Result model

Results use the frozen target order and one of three display outcomes:

- success
- skipped
- failed

Map internal error atoms/tuples to finite safe operator copy. Never render `inspect(error)`.
Attach job and Audit destinations only after reauthorization, using the existing deterministic selector helpers.

Result behavior:

- all-success may close only when the exact receipt is presented
- partial/skipped/failed stays open
- rows are bounded or paged
- successful resolved rows may be cleared
- unresolved rows remain for review/retry
- any retry begins with a fresh preview

The shared `confirm_action_dialog/1` already supports pending, submitting, partial, failed, expired, drifted, consumed, progress, typed count, reason, result rows, and audit links. Extend its inputs only if a missing Phase 80 concept cannot be represented generically; do not build a Jobs-only modal.

### 11. Authentication, redaction, and telemetry

Authentication boundaries:

- authorize page load
- reauthorize before preview
- reauthorize action and every target during preview
- Lifeline reauthorizes execution
- authorize every outbound related link/destination

Missing and unauthorized resources must remain indistinguishable in both quick review and detail.

Redaction must happen before:

- LiveView assigns
- component arguments
- DOM/diffs
- logs
- telemetry metadata
- task/coordinator messages

Suggested telemetry events are low-cardinality lifecycle observations:

- batch preview start/stop with action plus bucketed selected/ready/excluded sizes
- batch execution start/progress/stop with action plus bucketed aggregate outcomes and duration
- query timing with filter presence booleans, never values

No exact target counts, worker names, queue names, job IDs, filters, reasons, preview tokens, actor IDs, stack traces, or payloads belong in telemetry metadata. Exact counts remain appropriate in the authorized current socket’s presentation state; telemetry receives only stable buckets.

Receipts must state that targets are independently committed and operations may be at-least-once. Never claim batch atomicity or exactly-once execution.

## Forensics Implementation Research

### 1. Typed scope grammar

The six preserved URL keys are:

- `resource_type`
- `resource_id`
- `workflow_id`
- `step`
- `incident_fingerprint`
- `view`

Treat them as a grammar, not six independent optional filters.

Recommended valid families:

| Human type | Required keys | Optional contextual keys | Rejected examples |
|---|---|---|---|
| Workflow | `workflow_id` | `step`; workflow/workflow-step `resource_type` + `resource_id` when consistent | incident keys, Cron/Limiter pair, orphan `step`, mismatched resource identity |
| Lifeline incident | `incident_fingerprint` | supported `view`; a consistent incident resource pair | workflow keys, Cron/Limiter pair, orphan `view`, unsupported view |
| Cron entry | Cron `resource_type` + `resource_id` | none unless current canonical links require a documented supported view | workflow or incident keys, missing half of pair |
| Limiter | Limiter `resource_type` + `resource_id` | none unless current canonical links require a documented supported view | workflow or incident keys, missing half of pair |

The exact accepted `resource_type` literals should be taken from existing link producers and schema fixtures, then centralized in the parser. Do not accept an arbitrary resource pair merely because both strings are present.

Rules:

- no keys: empty chooser
- exactly one valid family: inspect it
- malformed or orphan keys: empty chooser plus explanation
- keys from multiple families: empty chooser plus explanation
- unknown resource type: empty chooser plus explanation
- arbitrary job ID or job resource pair: not a forensic bundle
- missing and unauthorized valid target: uniform “Evidence unavailable”

`Forensics.selectors/1` currently normalizes strings but does not enforce this grammar. Introduce a typed parser result such as:

```elixir
{:empty, canonical_params, explanation}
{:ok, %Forensics.Scope{kind: ..., ...}, canonical_params}
{:invalid, canonical_params, explanation}
```

Invalid direct URLs should be replaced with the empty canonical chooser URL using `replace: true`. Do not preserve conflicting keys after explaining them.

### 2. Selector form and URL behavior

Use `filter_bar/1` in submit mode.

Primary chooser fields change by human evidence type:

- Workflow: workflow ID, optional step
- Lifeline incident: fingerprint, optional supported view
- Cron entry: canonical Cron identity fields
- Limiter: canonical Limiter identity fields

The form change event reveals and validates the selected type’s fields. “Inspect evidence” patches only after valid submission.

The exact empty copy is:

> Choose evidence to inspect.

Do not add:

- global search
- typeahead
- saved searches
- inferred scope
- an extra page URL key for evidence-window paging

### 3. Scoped bounded queries

The most important Forensics data correction is removing these shapes:

```elixir
Audit.list_all(repo: repo) |> Enum.filter(...)
```

They currently exist for workflow and Lifeline incident evidence. They violate the bounded-query and separation-of-concerns contract.

Add an Audit context API for a stable bounded window:

```elixir
Audit.window(repo,
  resource_type: ...,
  resource_id: ...,
  event_types: ...,
  metadata: ...,
  limit: ...
)
```

The exact API can use a scope struct instead of keyword options. It must support:

- stable newest-first ordering with an ID tie-breaker
- a finite limit
- exact total count when reasonably available, or a `limit + 1` `has_more?` contract
- source/provenance metadata
- no `list_all/1`

The existing Audit schema has indexes for:

- actor ID
- action
- event type
- `(resource_type, resource_id)`

It does not have an index for `metadata->>'incident_fingerprint'`.

Therefore:

- workflow evidence should use authoritative relational/resource identity predicates wherever existing records permit
- incident evidence may require the JSONB fingerprint predicate
- the incident query must be bounded
- run `EXPLAIN (ANALYZE, BUFFERS)` against a representative local/test data volume if available, or at minimum `EXPLAIN` on the generated SQL
- record that this predicate is unindexed and host-data-volume-sensitive
- do not add a migration in Phase 80

If representative production-like volume is not available, explicitly label the measurement limitation in the phase summary and documentation.

Cron and Limiter fact histories are already bounded to eight in their contexts. Preserve that bound and augment the presentation with coverage copy rather than fetching more to make the page feel complete.

### 4. Evidence bundle model

`Forensics.bundle/2` should accept a validated typed scope, not a loose selector map whose family is chosen by precedence.

A normalized internal evidence result should distinguish:

```elixir
{:ok, evidence}
{:unavailable, safe_reason}
{:error, safe_reason}
```

The display presenter should then produce a closed map with:

```elixir
%{
  support: %{state: ..., copy: ...},
  scope: %{type: ..., identity: [...], copy: ...},
  summary: %{headline: ..., facts: [...]},
  next_steps: [%{label: ..., href: ..., support: ...}],
  latest_remediation: nil | %{...},
  events: [%{...}],
  coverage: %{showing: ..., total: ..., bounded?: ..., retention: ..., sources: [...]},
  audit_href: nil | binary
}
```

No unknown keys or source structs should survive into this map.

`EvidenceBundle` can remain an internal normalizer, but it must not be treated as proof that arbitrary event fields are safe for the DOM.

### 5. Diagnosis-first page composition

Render the full page in this order:

1. title and support state
2. typed scope filter
3. Investigation summary
4. What to do next
5. optional neutral Latest remediation evidence
6. Event log
7. combined Evidence limits and sources

This is intentionally one page:

- no detail surface
- no tabs
- no two-pane explorer
- no event card wall

The first “What to do next” destination is the one primary native legal route when supported and authorized. Put additional destinations behind “Review all guidance.”
State that primary route’s prerequisite or caution next to it; do not force the operator to infer whether the route is currently useful or safe.

Deduplicate destinations by canonical URL and meaning. A workflow, incident, and audit event may all point to the same native page; it should appear once.

Only render noun actions:

- “Open workflow”
- “Review incident in Lifeline”
- “Open cron entry”
- “Review limiter blockers”
- “View matching audit evidence”

Do not label non-actions as buttons, and do not emit links whose destination is unsupported or unauthorized.

“Latest remediation evidence” appears only when an actual historical Lifeline repair record exists. It must be visually neutral; a past repair is evidence, not a current success state.

### 6. Timeline normalization

Use the shared `timeline/1`.

Each event must include:

- newest-first stable ordering
- absolute timestamp
- grammatical sentence/title
- source/provenance
- human status
- domain
- redacted notes
- authorized follow-ups

Keep these dimensions separate:

- operational status
- severity
- provenance/source
- completeness/coverage

Normalize provenance into the finite support vocabulary established by the context—durable, supporting, bridge-only, or missing—when those meanings apply. Do not expose source atoms.

Do not encode “Audit” or “partial evidence” as a warning status color. Conversely, do not allow a neutral source badge to conceal an error/blocked status.

`Forensics.Chronology.sort/1` already provides newest-first ordering with tie handling. Preserve or tighten it, but feed it presenter-normalized records.

Current chronology items do not all carry a finite human status. Add source-specific mappings in `ControlPlanePresenter`, for example:

- workflow step state → human workflow status
- Lifeline audit outcome → succeeded/skipped/failed/unknown
- Cron fact state → current/superseded/unavailable as supported by source data
- limiter fact state → active/cleared/unavailable as supported by source data

Do not invent certainty where the source lacks it. Use an explicit “Status unavailable” mapping rather than deriving success from the presence of an event.

### 7. Redaction contract

Current audit item construction includes:

- reason
- action
- attempt state
- selected path
- full runbook context

Those cannot flow directly to page assigns.

The Forensics presenter must redact or omit:

- operator reasons unless an explicitly approved safe presentation exists
- continuity/runbook secrets
- raw errors
- stack traces
- payload metadata
- tokens and credentials
- sensitive URLs/query strings
- arbitrary audit metadata

Safe notes should be source-specific and structurally selected, not “the original map with several keys deleted.”

Apply redaction before assigns, logs, telemetry, and timeline construction. Tests need sentinel values across each possible channel.

### 8. Evidence coverage

Every evidence source needs a bounded coverage statement:

- “Showing N of M” when an exact total is known
- “Showing the newest N; more evidence exists” when using `limit + 1`
- “Showing all N available in this source window” when the source is complete
- an explicit retention/source limitation when history cannot prove completeness

The combined Evidence limits and sources section should name:

- source(s)
- window/bound
- completeness
- retention limitations
- the authorized Audit route, when available

No seventh URL selector key is needed. The Forensics page is a curated evidence window; deeper browsing belongs in Audit or a native destination.

As part of the composition rewrite, remove obsolete phase-number copy, raw selector-key summaries, raw action/source atoms, duplicated completeness cards, and repeated paths. Browser Back plus deterministic `Open…` destinations provide navigation; do not manufacture `return_to` values.

## Shared Design and Accessibility Requirements

Both pages must follow the shipped control-plane visual language:

- calm, neutral surfaces
- semantic color only for actual status/severity/action consequence
- no gradient decoration
- no shadow-heavy card stacks
- no decorative icon noise
- usable light, dark, system, and high-contrast themes
- no page-level horizontal scrolling at 320px
- 44×44 minimum pointer targets
- visible focus
- programmatic names, roles, values, errors, and selected/current state
- restrained `aria-live` announcements
- reduced-motion support

Use one live region per meaningful process, not per row. For Jobs bulk work, announce start and final outcome once. Keep real processed/total progress visible as text without making every intermediate target completion a live-region announcement.

For the quick-review dialog/surface, verify:

- focus moves to the surface on open according to the shared component contract
- Escape/close behavior updates the URL
- focus returns to the explicit Review control when practical
- switching reviews does not add repeated history entries
- the full-detail link is keyboard reachable

For form errors:

- associate error text with the field
- set invalid state programmatically
- keep invalid draft text visible
- put a concise summary or focus target at the first invalid field after submit

## Deterministic Fixture and Browser Strategy

### 1. Production composition stories

Add Jobs and Forensics stories to the existing `PageStoryCatalog`. Do not create a second catalog.

Add public pure composition functions:

```elixir
JobsLive.page_content(assigns)
ForensicsLive.page_content(assigns)
```

The showcase must call those exact functions.

The final story count must be locked in the first story-contract plan and then updated consistently in:

- `test/support/page_story_catalog.ex`
- `lib/oban_powertools/web/dev/showcase_live.ex`
- `scripts/showcase_manifest.exs`
- `test/browser/support/verify-page-baselines.mjs`
- ARIA baseline verifier/snapshots
- showcase catalog tests

Keep manifest schema version 8 if the existing story object fields remain sufficient. Bump it only if the contract shape changes; do not bump merely because story count changes.

The current baseline formula is:

```text
19 stories × 4 themes × 3 viewports = 228 PNG files
```

After Phase 80:

```text
(19 + new_jobs_stories + new_forensics_stories) × 4 × 3
```

The verifier must derive the final exact matrix from the locked count while retaining an explicit expected total. Extend the ID regex to `jobs|forensics`; do not loosen it to arbitrary page names.

### 2. Minimum story coverage

Several locked conditions can coexist in one deterministic story. Avoid multiplying screenshots when a single fixture proves multiple independent visual states, but do not combine states whose layout or interaction differs materially.

Recommended minimum Jobs story matrix:

| Story concept | Required conditions |
|---|---|
| empty browse | zero rows, seven state counts, exact 0 range, filters |
| one row + review | one job, selected review, long worker/ID, bounded review |
| many filtered rows | multiple pages, tags/JSON chips, exact count and ordinary pagination |
| thousands projected | thousands in dataset/count, only one 20-row page in DOM, bounded query/render proof |
| exact full final page | 20 rows on final page, Next disabled by exact total |
| invalid draft | invalid args/meta JSON retained with accessible errors |
| long/Unicode/RTL/redacted | long worker/queue, Unicode, RTL, secret sentinels, mobile pressure |
| explicit cross-page selection | selected count includes off-page IDs, page selection mixed state |
| all-matching frozen | frozen count/time/filter identity and off-page count |
| oversized scope | `limit + 1` overflow, no truncation |
| zero-ready confirmation | all targets excluded, submit unavailable |
| submitting progress | coarse real progress visual state |
| all-success receipt | exact receipt and close behavior |
| partial result | mixed success and unresolved outcomes, bounded rows |
| skipped result | skipped remains distinct from success and is retained |
| failed result | safe mapped failure, no raw inspected error |
| drifted result | fresh-preview requirement |
| disconnected run | work continues without socket ownership |
| interrupted run | honest node/application interruption and Audit recovery copy |
| full detail | legal actions, redacted error/args/meta/output, deterministic back link |

Recommended minimum Forensics story matrix:

| Story concept | Required conditions |
|---|---|
| empty chooser | exact empty copy and all four typed choices |
| complete workflow | workflow + step, full coverage, native next step |
| partial Lifeline incident | actual remediation evidence, partial coverage, Audit route |
| Cron evidence | bounded history and coverage/source copy |
| Limiter evidence | bounded history and coverage/source copy |
| unavailable | missing/unauthorized indistinguishable |
| conflicting selector | explanation plus canonical empty chooser |
| unknown coverage | evidence exists but completeness cannot be established |
| history unavailable | source history unavailable without implying an empty complete history |
| deep bounded timeline | long history, `N of M`/has-more, stable newest-first |
| adversarial content | Unicode/RTL/very long values and redaction sentinels |
| restricted guidance | unsupported/unauthorized links omitted and duplicates removed |

The planner may combine concepts and choose the exact IDs. It must publish an exact final list before baseline generation. The non-negotiable acceptance condition is coverage of every D86/D87 state, not a specific new story count.

“Thousands of jobs” means a fixture database/query count in the thousands with a bounded 20-row rendered page. Rendering thousands of table rows would contradict the bounded-read decision and test the wrong behavior.

### 3. Connected fixtures

Static stories prove pure composition and visual states. They do not prove:

- URL history
- direct invalid URL canonicalization
- filtering query semantics
- auth parity
- frozen ID behavior
- Lifeline preview/drift/execute
- background execution after disconnect
- scoped Ecto evidence

Extend the existing opt-in isolated host fixture system. Its current names are Phase 79-specific:

- `/__phase79_browser_fixtures__/reset`
- `/__phase79_browser_fixtures__/actor`
- `/__phase79_browser_fixtures__/recovery`
- `phase79-fixtures.ts`

Preferred approach: generalize the route/helper names to a version-neutral page-browser fixture contract while retaining compatibility aliases for Phase 79 tests. If that would create unnecessary churn, add a Phase 80 sibling fixture endpoint and helper, but keep one shared isolated host/database/server process.

Requirements:

- opt-in only in test fixture mode
- secret header
- closed request schemas
- deterministic reset
- no production router exposure
- isolated database/build path
- deterministic clock/IDs where the current harness permits
- explicit actor capabilities

The current read-only example actor grants only Cron and Audit view permissions. Connected Jobs/Forensics cases should use the operator actor for the main path and add a narrowly defined restricted actor or host policy branch for permission-equality and missing-follow-up tests. Do not weaken the production authorization module.

Seed fixtures for:

- all seven job states
- exact pagination boundary
- cross-page selected IDs
- all-matching under/over limit
- eligible, excluded, drifted, expired, skipped, failed, and successful Lifeline targets
- sensitive sentinels in args/meta/output/errors/reasons/runbook metadata
- all four forensic evidence types
- missing and unauthorized targets with the same visible result
- conflicting selector URLs
- exact and has-more evidence windows
- long, Unicode, and RTL values

For disconnect continuation, the connected test should start a deliberately gated/slow supervised run, disconnect or navigate the LiveView away, release the targets through a test-only control, and assert individual Lifeline audits complete. Avoid wall-clock sleeps; use fixture barriers or polling with a bounded timeout.

### 4. Browser assertions

Add a connected `page-migration-wave-2.spec.ts` and include it in `verify:pages:host` and `verify:pages:docker`.

Required Jobs connected assertions:

- first review pushes history, switching and closing replace
- browser Back closes first review
- stale `job` canonicalizes safely
- invalid draft does not query/patch
- valid submit canonicalizes filters
- invalid direct JSON canonicalizes with explanation
- state/filter changes reset required state
- pagination preserves explicit IDs
- exact full final page disables Next
- page selection and all-matching are distinct
- overflow is rejected without truncation
- confirmation requires reason and exact ready count
- execution uses actual progress
- partial results stay open
- disconnect does not cancel target operations
- full detail retains allowlisted back params only
- missing and unauthorized job output is identical
- no redaction sentinel appears in HTML, LiveView payload-visible DOM, logs captured by fixture, or telemetry test process

Required Forensics connected assertions:

- empty chooser and typed field switching
- valid submit patches the six-key grammar
- mixed/orphan params replace to empty chooser with explanation
- missing and unauthorized output is identical
- each of four evidence types loads its authoritative source
- event ordering is stable newest-first
- deep history is bounded and coverage copy is correct
- restricted/duplicate destinations are omitted/deduplicated
- raw audit reason/runbook/error/stack/payload sentinels never appear

Required page-quality assertions at 320, 768, and 1440:

- no page-level horizontal overflow
- 44×44 targets
- visible/programmatic dialog, form, selection, table, status, progress, and error states
- no serious/critical axe violations
- expected ARIA snapshots
- all four themes
- reduced motion where animation exists

## Plan Decomposition and Dependencies

The phase should be split by risk and dependency, not just by page.

### Plan 80-01 — Contract tests and canonical foundations

Create failing/contract tests for:

- Jobs filter draft vs applied URL state
- selector allowlisting and detail return params
- grouped counts and exact pagination
- bounded ordered ID window
- RuntimeConfig batch limit
- Forensics typed selector grammar
- Audit bounded window behavior
- presenter redaction/closed maps

This plan establishes executable contracts before page markup moves. It may implement the minimal context/parser/presenter foundations needed to turn the tests green, but should not yet attempt the full pages.

### Plan 80-02 — Jobs browse, filters, counts, and quick review

Dependencies: 80-01.

Implement:

- submit-mode `filter_bar/1`
- canonical URL handling
- grouped state counts
- exact count/range/pagination
- `data_table/1`
- explicit selection across pages
- bounded redacted quick review with URL history
- public pure Jobs page composition

Keep full job mutations out of this plan.

### Plan 80-03 — Jobs full detail and single-target confirmations

Dependencies: 80-01; may run alongside late 80-02 work if files do not overlap, but both touch `JobsLive`, so sequential execution is safer.

Implement:

- allowlisted deterministic back URL
- structured/redacted full detail
- uniform unavailable state
- authorized destinations
- Lifeline preview/confirmation/execute for retry/cancel/discard

### Plan 80-04 — Jobs frozen batch coordinator

Dependencies: 80-01 and the selection model from 80-02.

Implement:

- target-limit config
- named `Task.Supervisor`
- explicit/all-matching frozen scopes
- `limit + 1` overflow
- per-target preview classification
- exact confirmation
- supervised max-concurrency-four execution
- progress messages
- stable bounded results
- disconnect/interruption semantics

This deserves its own plan because it combines concurrency, authorization, mutation, audit, and recovery risk.

### Plan 80-05 — Forensics typed bounded evidence model

Dependencies: 80-01.

Implement:

- strict scope parser
- bounded Audit query API
- authoritative workflow/incident/Cron/Limiter queries
- coverage/completeness metadata
- closed redacted presenter maps
- query-plan measurement for incident JSONB predicate

This can run in parallel with Jobs page plans if the workspace workflow permits because its main source files are distinct.

### Plan 80-06 — Forensics diagnosis-first page

Dependencies: 80-05.

Implement:

- typed submit-mode chooser
- canonical invalid URL handling
- diagnosis-first order
- legal/deduplicated guidance
- actual remediation evidence
- shared timeline
- combined limits/sources
- public pure Forensics page composition

### Plan 80-07 — Page stories, showcase, and styles

Dependencies: 80-02, 80-03, 80-04, and 80-06.

Implement:

- exact locked story matrix
- `PageStoryCatalog` additions
- ShowcaseLive direct composition calls
- manifest/validator cardinalities
- Jobs/Forensics page-level source CSS
- generated built CSS
- ARIA snapshot contract updates

Do not update baselines before all story IDs and compositions are final.

### Plan 80-08 — Connected fixtures and Wave 2 browser behavior

Dependencies: production behavior from 80-02 through 80-06. It may overlap with the latter part of 80-07 if story catalog files are not touched concurrently.

Implement:

- version-neutral or sibling Phase 80 isolated fixtures
- deterministic data/actors/barriers
- connected Wave 2 Playwright spec
- `verify:pages` inclusion
- URL, auth, selection, mutation, disconnect, and scoped-query cases

### Plan 80-09 — Full page-quality gate and closure

Dependencies: all prior plans.

Run:

- focused unit/LiveView suites
- full `mix test`
- format/compile warnings gate
- component contracts
- page catalog/manifest validation
- ARIA
- axe
- VRT at 320/768/1440 and four themes
- reduced-motion checks
- changed-baseline scope validation

Record exact story, ARIA snapshot, and PNG counts in the phase summary.

This decomposition is intentionally more granular than the context’s suggestion that Jobs and Forensics each receive their own plan. The Jobs batch state machine should not share a commit/review unit with ordinary Jobs page composition or with Forensics.

## Validation Architecture

Phase 80 has multiple failure domains. Nyquist validation means every domain gets the cheapest deterministic test that can observe it, plus a smaller number of connected/browser tests for behaviors that cannot be proven below that layer.

### Layer 1 — Pure parser and presenter tests

Targets:

- Jobs URL/default/canonical param parsing
- draft JSON object validation
- selector allowlisting/order
- Forensics scope grammar
- finite status/reason mappings
- closed presenter maps
- structural redaction
- coverage copy

These tests should enumerate table-driven adversarial inputs:

- unknown keys
- repeated/mixed scope keys
- orphan step/view
- integer overflow/negative page
- JSON scalar/array instead of object
- Unicode/RTL
- token/secret/password/header/URL/query sentinels
- exception structs and unexpected error tuples

Assertions must verify both expected visible values and forbidden key/value absence.

Suggested files:

- `test/oban_powertools/web/selectors_test.exs`
- `test/oban_powertools/web/control_plane_presenter_test.exs`
- `test/oban_powertools/web/jobs_params_test.exs` or focused JobsLive parser tests
- `test/oban_powertools/forensics_test.exs`

### Layer 2 — Context/query tests

Targets:

- all optional Jobs filters are ANDed
- tags use all-required containment
- args/meta use JSON object containment
- stable order is `scheduled_at DESC, id DESC`
- grouped state count uses one query and returns seven keys including zeros
- exact page count and exact-full-last-page
- bounded ordered IDs use `limit + 1` without truncation
- Audit workflow and incident windows are bounded and stable
- exact/has-more coverage is correct
- no workflow/incident path calls `Audit.list_all/1`

Query-count verification can use repository telemetry/query capture already available in tests. Avoid brittle SQL string equality except where validating index/query-plan characteristics.

Suggested files:

- `test/oban_powertools/jobs_test.exs`
- `test/oban_powertools/audit_test.exs`
- `test/oban_powertools/forensics_test.exs`

### Layer 3 — Batch coordinator tests

Use deterministic fakes/barriers around Lifeline calls and the library Task Supervisor.

Targets:

- explicit scope order
- all-matching freeze
- overflow
- per-target auth/preview
- authorization revocation or resource disappearance between page load, preview, and execution
- zero-ready
- typed count and reason gates
- max concurrency never exceeds four
- target timeout becomes safe failed/skipped result
- target crash does not crash LiveView/coordinator
- stable frozen order despite out-of-order completion
- drift/expired/consumed mappings
- success/skipped/failed aggregates
- disconnect leaves task running
- node/interruption copy and individual Audit authority
- no tokens/raw errors in messages or telemetry

Do not depend on arbitrary sleeps. Gate target completion with messages or a test adapter, and assert active concurrency explicitly.

Suggested new focused files:

- `test/oban_powertools/jobs/batch_coordinator_test.exs`
- `test/oban_powertools/application_test.exs`
- RuntimeConfig tests in the existing config suite

### Layer 4 — LiveView tests

Targets:

- production renders shared components
- page content pure seam accepts deterministic assigns
- submit vs change behavior
- patches use push/replace correctly
- stale review canonicalizes
- filter/reset/selection transitions
- missing/unauthorized equality
- confirmation form and state transitions
- Forensics chooser/canonicalization/page order
- no sensitive sentinel in rendered HTML

Continue and expand:

- `test/oban_powertools/web/live/jobs_live_test.exs`
- `test/oban_powertools/web/live/forensics_live_test.exs`
- component harness tests when a generic component contract changes

### Layer 5 — Story/catalog contracts

Targets:

- exact story count and unique IDs
- allowed page and activation values
- direct production `page_content/1` composition
- deterministic fixture maps
- expected target selectors
- manifest schema/cardinality
- every locked adversarial state represented

Commands:

```bash
mix test \
  test/oban_powertools/page_story_catalog_test.exs \
  test/oban_powertools/showcase_catalog_test.exs \
  test/oban_powertools/web/live/showcase_live_test.exs \
  --seed 0

npm run showcase:manifest
node test/browser/support/verify-page-baselines.mjs
node test/browser/support/verify-page-aria-snapshots.mjs
```

### Layer 6 — Connected browser tests

Use the isolated host for URL history, auth, real database queries, Lifeline execution, and disconnect semantics.

Run the Wave 2 spec directly during development, then through the umbrella gate:

```bash
npm run showcase:manifest
scripts/with-showcase-server.sh \
  scripts/playwright-docker.sh \
  npx playwright test test/browser/specs/page-migration-wave-2.spec.ts
```

The exact wrapper may change if the fixture host requires its existing dedicated start command. The plan should preserve the repository’s Docker-first browser convention.

### Layer 7 — Visual, ARIA, accessibility, motion

The required final command is:

```bash
npm run verify:pages
```

It must include:

- page acceptance
- Wave 1 connected behavior
- Wave 2 connected behavior
- page-only axe
- page-only VRT
- ARIA baseline verification

Run the repository’s real screen-reader transcript contract on the supported macOS/VoiceOver environment as well:

```bash
npm run verify:voiceover
```

If that environment is unavailable to an implementation agent, record the missing environmental proof explicitly and leave the established transcript gate for the supported runner; do not substitute an axe pass for a real screen-reader transcript.

Update baselines only after behavior and accessibility pass:

```bash
npm run vrt:update
npm run verify:pages
```

Use the changed-scope baseline verifier to ensure screenshot edits are confined to the locked page matrix. Record whether shared CSS legitimately changed Wave 1 screenshots; do not blindly accept unrelated churn.

### Layer 8 — Full repository regression

Before completion:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test --seed 0
npm run verify:pages
```

If the repository has an established aggregate verification alias at implementation time, use it in addition to these explicit gates.

### Requirement-to-test mapping

| Requirement | Primary proof |
|---|---|
| PAGE-02 | Jobs LiveView/context/coordinator tests + connected Wave 2 + page stories |
| PAGE-09 | Forensics parser/query/LiveView tests + connected Wave 2 + page stories |
| FORM-03 | filter-bar component contract + Jobs/Forensics change/submit LiveView tests + axe |
| DATA-* | shared component tests + page composition stories + ARIA/VRT |
| PAGE-10 | direct `page_content/1` showcase contract + manifest + connected fixtures |
| A11Y-* | semantic component tests + ARIA snapshots + axe + viewport/target assertions |
| reduced motion | Playwright reduced-motion assertion and stable VRT |

## Likely Files to Modify

### Production

- `lib/oban_powertools/application.ex`
- `lib/oban_powertools/runtime_config.ex`
- `lib/oban_powertools/jobs.ex`
- new focused Jobs batch coordinator module
- `lib/oban_powertools/forensics.ex`
- `lib/oban_powertools/audit.ex`
- possibly focused Forensics scope/query modules if extraction improves clarity
- `lib/oban_powertools/web/jobs_live.ex`
- `lib/oban_powertools/web/forensics_live.ex`
- `lib/oban_powertools/web/control_plane_presenter.ex`
- `lib/oban_powertools/web/selectors.ex`
- `lib/oban_powertools/web/dev/showcase_live.ex`
- `assets/oban_powertools/tokens.css`
- regenerated `priv/static/oban_powertools/oban_powertools.css`

### Unit/LiveView tests

- `test/oban_powertools/jobs_test.exs`
- `test/oban_powertools/forensics_test.exs`
- `test/oban_powertools/forensics/evidence_bundle_test.exs`
- Audit tests
- RuntimeConfig/application tests
- new batch coordinator tests
- `test/oban_powertools/web/live/jobs_live_test.exs`
- `test/oban_powertools/web/live/forensics_live_test.exs`
- `test/oban_powertools/web/selectors_test.exs`
- presenter tests

### Deterministic/browser

- `test/support/page_story_catalog.ex`
- `test/oban_powertools/page_story_catalog_test.exs`
- `test/oban_powertools/showcase_catalog_test.exs`
- `test/oban_powertools/web/live/showcase_live_test.exs`
- `scripts/showcase_manifest.exs`
- `test/browser/support/verify-page-baselines.mjs`
- `test/browser/support/verify-page-aria-snapshots.mjs`
- page ARIA snapshot fixtures
- new `test/browser/specs/page-migration-wave-2.spec.ts`
- fixture host/helper files
- `package.json`
- new/updated VRT PNGs under the existing page-story matrix

### Files that should not need change

- production router route shapes
- host database migrations
- Oban schemas
- public Jobs or Forensics route paths
- design-system component internals unless a genuinely generic missing state is discovered
- dependency manifests

## Risks and Mitigations

### Risk: URL state and draft form state collapse into one object

**Failure:** invalid JSON disappears, queries run on every keystroke, or the URL claims filters that were not applied.

**Mitigation:** separate applied canonical params from draft form params and test change vs submit explicitly.

### Risk: “All matching” remains a deferred filter

**Failure:** execution mutates jobs that were not in the confirmation or misses jobs that were.

**Mitigation:** freeze stable ordered IDs, filter identity, exact count, and timestamp before preview; never rerun scope at execute time.

### Risk: apparent concurrency without lifecycle ownership

**Failure:** LiveView crash cancels work, linked task crashes the page, or node interruption is presented as durable completion.

**Mitigation:** library-owned `Task.Supervisor`, nonlinked tasks, max concurrency four, finite timeouts, honest interruption copy, individual Lifeline audits as recovery authority.

### Risk: preview tokens or raw failures leak

**Failure:** tokens/errors reach DOM, LiveView diffs, logs, telemetry, or result rows.

**Mitigation:** keep execution and display models separate; only finite safe result maps cross the coordinator-to-LiveView boundary.

### Risk: Forensics continues using hidden precedence

**Failure:** mixed URLs inspect the wrong resource and conceal operator mistakes.

**Mitigation:** typed one-family parser with canonical invalid replacement before any evidence query.

### Risk: bounded display backed by unbounded reads

**Failure:** page looks small but workflow/incident audit loading scales with the full audit table.

**Mitigation:** Ecto-scoped stable Audit window and query-count/query-plan tests; ban `list_all |> Enum.filter`.

### Risk: incident fingerprint scan at host scale

**Failure:** unindexed JSONB predicate becomes slow.

**Mitigation:** finite bound, stable query, `EXPLAIN` measurement/documentation, and explicit follow-up recommendation if host scale warrants an index. No surprise Phase 80 migration.

### Risk: structural redaction covers args but not error/audit shapes

**Failure:** stack traces, reasons, runbook context, or URLs leak through new polished components.

**Mitigation:** source-specific closed presenters and cross-channel sentinel tests; never pass source maps through generically.

### Risk: page stories fork production markup

**Failure:** screenshots pass while production regresses.

**Mitigation:** public pure `page_content/1` called directly from production and showcase, with catalog tests enforcing that seam.

### Risk: baseline cardinality is loosened to make additions easier

**Failure:** missing or stale screenshots no longer fail deterministically.

**Mitigation:** lock exact story IDs/count first, update every hard-coded contract together, retain exact formula and strict page-name regex.

### Risk: VRT fixture renders thousands of DOM rows

**Failure:** browser gate becomes slow and contradicts bounded reads.

**Mitigation:** seed/project a count in the thousands while rendering only the current 20-row page.

### Risk: Phase 79 fixture generalization breaks Wave 1

**Failure:** existing accepted connected tests stop running.

**Mitigation:** compatibility aliases or a sibling Phase 80 endpoint; run Wave 1 and Wave 2 through the same final gate.

### Risk: shared CSS changes cause broad baseline churn

**Failure:** valid Phase 80 review becomes obscured by unrelated screenshot changes.

**Mitigation:** keep page-composition CSS narrowly scoped, use component classes already shipped, run changed-scope verification, and inspect any Wave 1 changes individually.

## Explicit Non-Goals

Phase 80 should not:

- add a database migration
- add dependencies
- change public route shapes
- add a job mutation outside Lifeline
- add a durable bulk-run database ledger
- promise aggregate resume after node restart
- add global Forensics search/typeahead/saved searches
- add a seventh Forensics URL key
- turn the Jobs table into an ARIA grid
- create a second screenshot or story system
- remove or silently alter public `Operator.bulk_*` APIs
- redesign Phase 77 shared primitives without a demonstrated generic defect

## Unresolved Information the Planner Must Make Explicit

These are bounded implementation choices, not blockers:

1. **Exact Phase 80 page-story list and count.** The minimum matrix above covers the locked conditions, but the planner must decide which compatible conditions share a story and then lock IDs/count before implementation.
2. **Runtime config key name.** Default 100 and maximum 1000 are locked; the key name is not.
3. **Per-target execution timeout.** It must be finite and tested; no exact duration is locked.
4. **Fixture naming strategy.** Prefer a version-neutral generalization with Phase 79 compatibility; a sibling Phase 80 endpoint is acceptable if lower risk.
5. **Exact Forensics resource-type literals.** Derive and enumerate them from current native link producers before implementing the typed grammar.
6. **Incident query performance at representative host scale.** The schema has no fingerprint index and Phase 80 cannot add one. If no representative dataset is available, record that the local `EXPLAIN` cannot predict production scale.
7. **Non-Lifeline source status wording.** The presenter must use finite human labels grounded in the actual Cron/Limiter/workflow source fields; do not invent status semantics during template work.
8. **Full error presentation bounds.** The context requires structural redaction and bounded data but does not specify the exact attempt count/text limit. Lock conservative constants in the presenter plan and test them.

None of these choices require reopening the phase’s product decisions.

## Concrete Recommendations

1. Start with executable parser/query/presenter contracts. The two current pages mix these responsibilities, and changing markup first would make behavioral regressions harder to isolate.
2. Extract one reusable non-state Jobs query and derive list, exact count, grouped counts, and bounded IDs from it. Filter drift between those queries is the primary data-correctness hazard.
3. Treat Jobs bulk execution as its own state machine and plan. Freeze IDs before preview; use Lifeline per target; supervise nonlinked work; expose only aggregate safe progress.
4. Treat Forensics selector parsing as a sum type: empty, workflow, incident, Cron, or limiter. Remove hidden precedence entirely.
5. Add a bounded Audit window in the Audit context. Never conceal an unbounded query behind a bounded timeline component.
6. Put all source-specific sensitive shaping in `ControlPlanePresenter` before LiveView assigns.
7. Reuse `filter_bar/1`, `data_table/1`, `detail_surface/1`, `confirm_action_dialog/1`, and `timeline/1` directly. Page code should contain composition and orchestration, not replacement primitives.
8. Expose pure Jobs and Forensics `page_content/1` seams and use them directly in the existing Page Story Catalog/Showcase.
9. Lock the exact story matrix before screenshot generation and retain strict cardinality validation.
10. Make `npm run verify:pages` the final cross-page gate, including both Wave 1 and Wave 2 connected behavior.

## Planning Readiness

The phase is ready to plan. The implementation does not require external research or a new dependency. The largest risks are internal and well-bounded:

- correct canonical URL state
- query consistency and boundedness
- frozen batch scope
- supervised non-atomic execution
- closed redacted presentation
- strict Forensics scope grammar
- extension of the existing exact page-quality matrix

The recommended nine-plan sequence keeps those risks independently testable while still permitting the Forensics data-model work to proceed in parallel with Jobs page work when the execution workflow allows it.
