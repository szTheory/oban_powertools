# Stack Research

**Domain:** Native job browse surface and operator actions Elixir API (v1.5 additions)
**Researched:** 2026-05-27
**Confidence:** HIGH — all findings verified directly against locked deps in mix.lock and lib/

---

## What Is Already In Place (Do Not Re-add)

Oban 2.22.1, Phoenix LiveView 1.1.30, Phoenix 1.8.7, Ecto SQL 3.13.5, Postgrex 0.22.2,
Telemetry 1.4, Jason 1.4. No new dependencies are needed for v1.5.

---

## New Capabilities and Their Stack Primitives

### QRY-01: Native Job Listing with Filter/Search

**Use `Oban.Job.query/1` directly — no new library.**

`Oban.Job` (the schema at `"oban_jobs"`) is an `Ecto.Schema` the codebase already imports via
`import Ecto.Query`. The locked Oban 2.22.1 ships `Oban.Job.query/1` (available since 2.22.0)
that builds a composable `Ecto.Query` from a keyword list:

```elixir
[state: ~w(available retryable), queue: "default", worker: MyApp.MyWorker]
|> Oban.Job.query()
|> order_by([j], desc: j.inserted_at)
|> limit(50)
|> repo.all()
```

Supported filter fields confirmed from `@query_fields` in `deps/oban/lib/oban/job.ex`:
`id`, `state`, `queue`, `worker`, `priority`, `attempt`, `max_attempts`, `tags`, `args`,
`meta`, `attempted_at`, `cancelled_at`, `completed_at`, `discarded_at`, `inserted_at`,
`scheduled_at`.

- Scalar values → equality match
- List values → `IN` match (except `:tags` which requires full array equality)
- Map values for `:args`/`:meta` → JSONB containment (`@>`) — Postgres-only, already the stack

**Job states** from `Oban.Job.states/0`:
`suspended`, `scheduled`, `available`, `executing`, `retryable`, `completed`, `discarded`,
`cancelled`.

**Filtering approach for the UI:** encode active filters in URL params via `handle_params/3` +
`push_patch/2` (already the pattern in `LifelineLive`, `WorkflowsLive`). Build the query with
`Oban.Job.query/1` then compose additional `Ecto.Query` clauses (`order_by`, `limit`, `offset`
or keyset cursor). No extra library.

**Tags filter caveat:** `Oban.Job.query(tags: ["tag1"])` does full-array equality, not
containment. For a "job has this tag" filter compose a manual JSONB array-contains clause:
`where(query, [j], fragment("? @> ?::jsonb", j.tags, ^Jason.encode!(["tag1"])))` — or use
`fragment("? \\? ?", j.tags, ^"tag1")` for the text `?` operator on `jsonb`. Both work on the
existing Postgrex stack.

### QRY-01: Pagination

**Cursor-based pagination via manual Ecto query, no new library.**

The job table will have large cardinality. Use `id`-keyset pagination (insert `where j.id < ^last_id` + `limit N`) for forward-only page navigation, or `limit`/`offset` for
small bounded ranges. This matches what every operator dashboard in the Oban Web bridge does
and requires zero new deps. Avoid bringing in Scrivener or similar — they require schema
macros that conflict with the host-owned Ecto pattern. A read-model module (parallel to
`OverviewReadModel`) handles query construction and pagination state.

Encode page cursor or offset in URL params via `push_patch/2` — consistent with existing
navigation in `LifelineLive`.

### QRY-01: LiveView Component Pattern

**`Phoenix.LiveView.stream/4` for the job list table.**

LiveView 1.1.30 ships `stream/4`, `stream_insert/4`, `stream_delete/3`, `stream_delete_by_dom_id/3`
in `Phoenix.LiveView`. Use `stream(socket, :jobs, jobs)` on `handle_params/3` and
`stream(socket, :jobs, new_jobs, reset: true)` when filters change. This gives server-driven
DOM diffing without holding the full collection in socket assigns. Template: `<tr :for={{dom_id, job} <- @streams.jobs}`.

This is the right choice over `assign(:jobs, jobs)` for any list that can grow to hundreds of
rows. The codebase does not yet use streams (existing LiveViews hold small, bounded collections
in assigns) — v1.5 is the first surface large enough to need them.

**Filter form:** `phx-change="filter"` on a `<form>` with no submit (immediate filter on
change), `handle_event("filter", params, socket)` rebuilds the stream. Already the pattern
established with `phx-change="reason"` in `LifelineLive`.

**Bulk checkbox selection:** use `JS.push("toggle_job", value: %{id: id})` on each row
checkbox to accumulate selected IDs into a `MapSet` in socket assigns. No client-side
JavaScript hook needed — `JS.push/3` with `:value` option is available in LiveView 1.1.30.

### QRY-02: Native Job Detail View

**New route + separate LiveView, `Oban.Job` schema direct.**

Add `live("/jobs/:id", ObanPowertools.Web.JobDetailLive, :show)` inside the existing
`live_session :oban_powertools_native` block in `Router`. `JobDetailLive` mounts with
`repo.get!(Oban.Job, id)`, loads the job's `errors` field (already `{:array, :map}` on the
schema with `attempt`, `at`, `error` keys), and reads `meta` and `args` via `Jason.encode!/2`
for formatted display.

No new schema — `Oban.Job` has all required fields: `args`, `meta`, `errors`, `attempt`,
`state`, `queue`, `worker`, `tags`, `inserted_at`, `attempted_at`, `completed_at`,
`discarded_at`, `cancelled_at`.

Add `/ops/jobs/jobs` to `Selectors` — same pattern as `lifeline_path/1`, `forensic_path/1`.

### QRY-03: Native Job Actions (retry, cancel, discard)

**Reuse the preview → reason → audit pipeline already in Lifeline. No new pattern.**

The existing `Lifeline` module already mutates `Oban.Job` via direct Ecto updates:

```elixir
# retry / rescue:
repo.update!(Ecto.Changeset.change(job, state: "available", scheduled_at: now))

# cancel:
repo.update!(Ecto.Changeset.change(job, state: "cancelled", cancelled_at: now))
```

**Discard** follows the same pattern (no public `Oban.discard_job/2` in the Oban public API —
verified by searching `deps/oban/lib/oban.ex`; `Engine.discard_job` is internal):

```elixir
repo.update!(Ecto.Changeset.change(job, state: "discarded", discarded_at: now))
```

Wrap these three mutations in a new `ObanPowertools.Jobs` module (see API-01 below) and call
it from both the LiveView and the Elixir API. Record `Audit.record/3` after each success.
Emit `Telemetry.execute_operator_action(:complete, ...)` with `action: "job_retry"` /
`"job_cancel"` / `"job_discard"`, `source: "ui"` or `"api"`.

**No new `RepairPreview` rows needed for basic job actions** — the Lifeline preview system was
designed for incident-scoped dry-run with plan-hash drift detection. Job browse actions (retry,
cancel, discard) are direct single-job mutations that follow the simpler cron pattern:
preview state lives in socket assigns (`:preview_state`, `:preview_job`), reason is captured
in a form field, execute event commits. Saves DB write overhead of preview tokens for common
operations.

### QRY-04: Bulk Job Operations

**`Oban.cancel_all_jobs/2`, `Oban.retry_all_jobs/2`, and manual `update_all` for discard.**

Locked Oban 2.22.1 provides:
- `Oban.retry_all_jobs(queryable)` → `{:ok, count}` (since 2.9.0)
- `Oban.cancel_all_jobs(queryable)` → `{:ok, count}` (since prior to 2.22)
- `Oban.delete_all_jobs(queryable)` → `{:ok, count}` — this is **delete**, not discard
- No `discard_all_jobs` public API exists; use `repo.update_all` with Ecto to set
  `state: "discarded"` and `discarded_at: now()` for bulk discard.

Pattern for bulk operations from UI: accumulate selected `job_ids` in a `MapSet` assign,
confirm via preview panel, call `Oban.Job.query(id: MapSet.to_list(ids))` then pass to the
appropriate bulk API or update_all.

Require reason input before bulk mutations — consistent with existing audit posture.
Record one `Audit.record/4` entry per bulk action with `metadata: %{count: n, ids: ids}` for
durable evidence.

### API-01: Operator Actions Elixir API

**New `ObanPowertools.Jobs` module — no new primitives, compose existing patterns.**

Introduce one new public module: `ObanPowertools.Jobs`. It is the programmatic API surface
mirroring what the UI does, typed with `@spec`. Design pattern follows `ObanPowertools.Cron`
and `ObanPowertools.Lifeline` — accepts `repo` + `actor` keyword args, calls `Auth.authorize/3`,
writes `Audit.record/3`, emits telemetry.

```elixir
# Single-job mutations
ObanPowertools.Jobs.retry_job(job_id, actor: actor, repo: repo)
ObanPowertools.Jobs.cancel_job(job_id, actor: actor, repo: repo)
ObanPowertools.Jobs.discard_job(job_id, actor: actor, repo: repo)

# Bulk mutations (queryable-based)
ObanPowertools.Jobs.retry_jobs(queryable, actor: actor, repo: repo)
ObanPowertools.Jobs.cancel_jobs(queryable, actor: actor, repo: repo)

# Query (read-only)
ObanPowertools.Jobs.list(filters, opts)
ObanPowertools.Jobs.get(id, opts)
```

Each mutation returns `{:ok, result}` or `{:error, reason}` — no exceptions for normal
authorization failures.

**Auth integration:** call `Auth.authorization_outcome(actor, :retry_job, %{id: job_id})`
before mutating. Return `{:error, :unauthorized}` on refusal. This reuses the behaviour
already established in `ObanPowertools.Auth`.

**Telemetry:** emit `Telemetry.execute_operator_action(:complete, %{count: 1}, %{action:
"job_retry", source: "api"})` — uses existing `[:oban_powertools, :operator_action, :complete]`
event family. The `:source` key distinguishes API calls from UI calls. No new event families
needed.

**No new behaviour or callback.** The API is a plain module with public functions, not a
behaviour the host implements. The host calls it imperatively. A behaviour would only add
friction here.

**Oban instance name:** the `Jobs` module should accept `oban_name: Oban` (default `Oban`) for
hosts running multiple Oban instances, consistent with how `Oban.retry_all_jobs/2` and
`Oban.cancel_all_jobs/2` accept a name as first arg. Pass through to `Oban.retry_all_jobs(name,
queryable)` for bulk operations. Single-job mutations use direct Ecto (not the Oban API) so
they do not need the name.

---

## Core Technologies (Unchanged — Confirmed Versions)

| Technology | Locked Version | Role in v1.5 |
|------------|---------------|--------------|
| Oban | 2.22.1 | `Oban.Job.query/1`, `retry_all_jobs/2`, `cancel_all_jobs/2` |
| Phoenix LiveView | 1.1.30 | `stream/4`, `push_patch/2`, `JS.push/3` |
| Ecto SQL | 3.13.5 | composable queries, `update_all` for discard |
| Postgrex | 0.22.2 | JSONB operators for tags/args/meta filtering |
| Telemetry | 1.4 | existing `:operator_action` family extended with `source: "api"` |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Scrivener / Paginator | Schema macros that conflict with Ecto-native pattern; overkill for a single operator surface | Manual `limit`/`offset` or keyset cursor in the read-model module |
| PubSub / live job-state subscriptions | Oban does not publish per-job state change events on PubSub; polling-on-demand is correct for an operator surface | Reload on operator action, or manual poll interval via `Process.send_after` if needed |
| `Oban.Web` internals beyond the existing bridge | Not a public API; fragile across oban_web versions | `Oban.Job.query/1` + direct Ecto |
| New audit schema | Existing `oban_powertools_audit_events` is correct and covers job actions | `Audit.record/3` with `resource: %{type: :job, id: job_id}` |
| LiveView hooks / JS for checkbox state | Not needed; `JS.push/3` with `:value` handles toggle events without client hooks | `JS.push("toggle_job", value: %{id: id})` |

---

## Integration Points Summary

| New Surface | Builds On | Pattern Source |
|-------------|-----------|----------------|
| Job list query | `Oban.Job.query/1` + `Ecto.Query` | Confirmed in `deps/oban/lib/oban/job.ex` |
| Tags filter | Manual JSONB fragment | Required because `Job.query(tags:)` requires exact array equality |
| Job list LiveView | `Phoenix.LiveView.stream/4` | First use of streams in this codebase |
| Job detail route | `live("/jobs/:id", ...)` added to existing `live_session` | `lib/oban_powertools/web/router.ex` |
| Single-job mutations | Direct Ecto `repo.update!` on `Oban.Job` | Already proven in `Lifeline.mutate_target/5` |
| Bulk retry/cancel | `Oban.retry_all_jobs/2`, `Oban.cancel_all_jobs/2` | Public API, confirmed present in 2.22.1 |
| Bulk discard | `repo.update_all` with Ecto | No `Oban.discard_all_jobs` in public API |
| Operator API module | `ObanPowertools.Jobs` | Mirrors `ObanPowertools.Cron` pattern |
| Selectors | Add `:jobs` path to `Selectors.encode/2` | `lib/oban_powertools/web/selectors.ex` |
| Telemetry | Existing `:operator_action` family, add `source: "api"` metadata | `lib/oban_powertools/telemetry.ex` |

---

## Sources

- `deps/oban/lib/oban/job.ex` — `@query_fields`, `query/1`, `states/0`, schema fields (verified in locked 2.22.1)
- `deps/oban/lib/oban.ex` — `retry_all_jobs/2`, `cancel_all_jobs/2`, `delete_all_jobs/2`; absence of `discard_job` confirmed by search (verified in locked 2.22.1)
- `deps/oban/lib/oban/engine.ex` — `discard_job` is engine-internal only (verified)
- `deps/phoenix_live_view/lib/phoenix_live_view.ex` — `stream/4`, `stream_insert/4`, `stream_delete/3` (verified in locked 1.1.30)
- `deps/phoenix_live_view/lib/phoenix_live_view/js.ex` — `JS.push/3` with `:value` (verified)
- `mix.lock` — exact locked versions of all dependencies (verified)
- `lib/oban_powertools/lifeline.ex` — existing `mutate_target/5` Ecto update pattern for retry/cancel (verified)
- `lib/oban_powertools/auth.ex` — `Auth.authorization_outcome/3` pattern (verified)
- `lib/oban_powertools/telemetry.ex` — existing `:operator_action` event family (verified)
- `lib/oban_powertools/web/router.ex` — `live_session` block for new route addition (verified)
- `lib/oban_powertools/web/selectors.ex` — selector pattern to extend (verified)

---
*Stack research for: Oban Powertools v1.5 — Native Job Surface & Operator API*
*Researched: 2026-05-27*
