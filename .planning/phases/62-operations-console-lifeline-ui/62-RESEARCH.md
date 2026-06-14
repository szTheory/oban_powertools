# Phase 62: Operations Console & Lifeline UI - Research

**Researched:** 2026-06-14  
**Domain:** Phoenix LiveView operations UI, Ecto read models, Lifeline repair flows  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Page Shape and Navigation
- **D-01:** Use a URL-addressable batch detail route as the canonical detail pattern: `/ops/jobs/batches/:id`. Inline expansion may be used for compact previews, but it must not be the only way to inspect a batch. This matches `JobsLive`, supports shareable URLs, and gives forensics/audit/runbook handoffs a stable target.
- **D-02:** Add native router and selector support for batches. Extend `ObanPowertools.Web.Router` with `/batches` and `/batches/:id`, and extend `ObanPowertools.Web.Selectors` with `batches_path/1` and `batch_detail_path/1`.
- **D-03:** Keep the index table-first and operator-dense: metrics, status tabs, URL-backed filters, page-local selection, selected banner, table panel, empty/read-only/error states. Do not add realtime counts or cross-page select-all in this phase; those remain future requirements.

### Read Model and Query Boundary
- **D-04:** Add a dedicated read/query context for batches, analogous to `ObanPowertools.Jobs`. The LiveView should not own ad hoc cross-table queries. The read model should own list/detail queries, counts, filters, pagination, and the joins needed to inspect batch members, callbacks, chain metadata, and associated Oban jobs.
- **D-05:** Use the existing offset pagination style from `JobsLive` unless planning finds a concrete performance blocker. Preserve a single-function upgrade path to keyset pagination rather than designing a broader pagination abstraction now.
- **D-06:** Detail data should gather identity, progress counters, failed/discarded members, callback rows, chain step metadata, output dependency status, and manual intervention/audit evidence. Use display/redaction policy seams for job args/meta/error-like payloads instead of leaking raw internals by default.

### Recovery and Mutation Boundaries
- **D-07:** Failed batch member retry must route through the existing Lifeline job repair pipeline. Bulk retry runs independent per-job preview/execute attempts and reports successes, skips, and failures honestly. Do not call `Oban.retry_job` directly from the batches UI, and do not wrap N jobs in one all-or-nothing `Ecto.Multi`.
- **D-08:** Callback retry must become an explicit Lifeline repair target/action for callback outbox rows if the current Lifeline surface does not already support it. Preview must show event, dedupe key, attempts, last error, batch/chain context, before/after state, audit consequence, preview status, and preview token. Execute requires an acceptable reason and a ready preview, and must handle drift, expired previews, consumed previews, unauthorized actors, and per-row failure.
- **D-09:** Only offer callback recovery for visibly blocked or failed callback states, such as failed rows or claimed rows whose lease has expired. Do not offer retry for delivered callbacks or healthy pending callbacks. The UI must show the callback state before it offers execution.
- **D-10:** Native Powertools pages own audited mutations. Generic Oban job internals continue to deep-link to the optional `/ops/jobs/oban` bridge for inspection only.

### Blocked State Semantics
- **D-11:** Show blocked states in specific support-truth language, not as generic "running" or "attention" states. At minimum: `insert_failed`, `callback_failed`, unavailable or expired upstream output, executing-but-not-complete, exhausted with failed/discarded members, and completed.
- **D-12:** For `insert_failed`, surface failed chunk, inserted count, total count, stored failure kind/message, and failed timestamp from the batch insertion fields.
- **D-13:** For `callback_failed`, surface the failed callback event, dedupe key, attempts, last error, availability/claim/delivery timestamps, and whether retry is available.
- **D-14:** For output-unavailable or output-expired chain states, derive the explanation from chain metadata and callback failure evidence. Show upstream job id, step name/index/count, and the locked copy that the upstream output contract must be corrected before retry.

### Chain Presentation
- **D-15:** Chains appear as batch-backed rows with a `Chain` badge. Do not create a separate chain route, chain table, or chain-specific operator surface in this phase.
- **D-16:** Batch detail must show chain context when chain metadata is present: chain id/name when available, current or last known step, step index/count, upstream job id, next-step/output dependency state, and explicit output-unavailable copy.

### Auth, Read-Only, and Audit
- **D-17:** Add batch page/detail permissions and read-only copy to `ObanPowertools.Web.LiveAuth`. Use the same posture as existing native pages: pages remain inspectable when authorized for viewing, while preview/execute controls are disabled with adjacent helper copy when mutation permissions are missing.
- **D-18:** The read-only banner should use the copy locked in `62-UI-SPEC.md` once permission naming exists. Until then, keep copy consistent with the existing `LiveAuth.page_read_only_banner/1` style.
- **D-19:** Show manual intervention history by reusing existing Lifeline/Audit presentation or deep-link patterns where evidence exists. Do not invent audit rows or imply evidence that has not been written.

### Agent's Discretion
- The user approved creating context from the locked UI spec, prior phase decisions, and advisor-mode recommendations. Planning may resolve ordinary implementation details such as exact module names, helper function boundaries, query shapes, component extraction, and test file organization, as long as the decisions above and `62-UI-SPEC.md` remain intact.

### the agent's Discretion

- The user approved creating context from the locked UI spec, prior phase decisions, and advisor-mode recommendations. Planning may resolve ordinary implementation details such as exact module names, helper function boundaries, query shapes, component extraction, and test file organization, as long as the decisions above and `62-UI-SPEC.md` remain intact.

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- Realtime/live counts (`QRY-06`) remain deferred.
- Cross-page select-all (`QRY-08`) remains deferred.
- Args/meta filtering (`QRY-05`), Lifeline-to-job deep-link polish (`QRY-07`), and programmatic job query API (`API-03`) remain future work.
- Dynamic/growable batches, nested batches, chunking, arbitrary DAGs, and external dependencies remain out of scope for this milestone.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BUI-01 | Native `/ops/jobs/batches` LiveView page showing batch progress, statuses, and failed member inspection. [VERIFIED: .planning/REQUIREMENTS.md] | Use `ObanPowertools.Web.JobsLive` route/filter/detail patterns and add `ObanPowertools.Batches` as read context. [VERIFIED: codebase grep] |
| BUI-02 | Operator visibility into explainable blocked states. [VERIFIED: .planning/REQUIREMENTS.md] | Derive explanations from `Batch` insertion fields, `Callback` rows, and chain metadata written by Phase 61. [VERIFIED: codebase grep] |
| BUI-03 | Lifeline-routed bulk recovery action to safely "Retry failed in batch". [VERIFIED: .planning/REQUIREMENTS.md] | Reuse `Lifeline.preview_repair/4` and `execute_repair/5` with independent per-job attempts; do not call Oban mutation APIs directly. [VERIFIED: codebase grep] |
| BUI-04 | Operator visibility and recovery actions for stuck/dead callbacks. [VERIFIED: .planning/REQUIREMENTS.md] | Extend Lifeline to support callback target/action before wiring LiveView retry controls. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 62 should be planned as a native Phoenix LiveView extension under the existing host-owned `/ops/jobs` shell, not as a new dashboard stack or an Oban Web replacement. [VERIFIED: `.planning/phases/62-operations-console-lifeline-ui/62-CONTEXT.md`; VERIFIED: `lib/oban_powertools/web/router.ex`] The correct shape is `BatchesLive` plus a dedicated `ObanPowertools.Batches` read/query context, mirroring the existing separation where `JobsLive` owns interactions and `ObanPowertools.Jobs` owns `oban_jobs` reads. [VERIFIED: `lib/oban_powertools/web/jobs_live.ex`; VERIFIED: `lib/oban_powertools/jobs.ex`]

The largest planning gap is callback retry. [VERIFIED: codebase grep] Current Lifeline supports job and workflow repair targets only through a closed action set and `TargetType` dispatcher; callback rows are visible in schemas but are not yet a Lifeline target. [VERIFIED: `lib/oban_powertools/lifeline.ex`; VERIFIED: `lib/oban_powertools/lifeline/target_type.ex`; VERIFIED: `lib/oban_powertools/callback.ex`] Plan callback recovery as a service-layer Lifeline extension first, then build UI controls against that explicit preview/execute contract. [VERIFIED: `.planning/phases/62-operations-console-lifeline-ui/62-CONTEXT.md`]

**Primary recommendation:** Implement Phase 62 in four layers: routes/selectors/auth, `ObanPowertools.Batches` read model, Lifeline callback repair target, then `BatchesLive` index/detail with focused LiveView and service tests. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| `/ops/jobs/batches` index/detail rendering | Browser / Client via Phoenix LiveView process | API / Backend read context | LiveView owns event handling and HEEx rendering; the read context owns DB queries. [VERIFIED: Phoenix LiveView docs; VERIFIED: `JobsLive`/`Jobs` pattern] |
| Batch list/detail query assembly | API / Backend | Database / Storage | Ecto query modules own joins, counts, filters, pagination, and shape normalization. [VERIFIED: `lib/oban_powertools/jobs.ex`; CITED: https://ecto.hexdocs.pm/Ecto.Query.html] |
| Failed-member retry | API / Backend | Browser / Client | Lifeline owns audited preview/execute mutation; LiveView only invokes it after auth and reason gating. [VERIFIED: `lib/oban_powertools/lifeline.ex`; VERIFIED: `lib/oban_powertools/web/lifeline_live.ex`] |
| Callback retry | API / Backend | Database / Storage | Lifeline must add callback target/action because current target set excludes callbacks. [VERIFIED: `lib/oban_powertools/lifeline.ex`; VERIFIED: `lib/oban_powertools/lifeline/target_type.ex`] |
| Blocked-state explanation | API / Backend | Browser / Client | Explanation should be derived from stored batch/callback/chain evidence, then rendered in the UI. [VERIFIED: `Batch`, `Callback`, `Chain.Progression`] |
| Oban Web deep links | Frontend Server / SSR route boundary | Browser / Client | Existing bridge is nested under the host-owned shell and remains inspection-only. [VERIFIED: `lib/oban_powertools/web/router.ex`; VERIFIED: `lib/oban_powertools/web/oban_web_bridge.ex`] |

## Project Constraints (from AGENTS.md)

No `AGENTS.md` file exists in the project root, so there are no additional project-specific directives from that file. [VERIFIED: `test -f AGENTS.md`]

No `.codex/skills/` or `.agents/skills/` project skill directories exist, so there are no project-local skill rules to apply. [VERIFIED: `find .codex/skills .agents/skills -maxdepth 2 -name SKILL.md`]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / OTP | Elixir 1.19.5 / OTP 28 | Runtime and test execution | Project requires Elixir `~> 1.19`; local toolchain matches. [VERIFIED: `mix.exs`; VERIFIED: `elixir --version`] |
| Phoenix LiveView | locked 1.1.31; latest 1.2.1 available | Native operator UI | Existing pages use `use Phoenix.LiveView`, HEEx, `handle_params/3`, `push_patch/2`, and LiveView tests. [VERIFIED: `mix.lock`; CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html] |
| Ecto / Ecto SQL | locked 3.14.0 | Query context, joins, transactions, migrations | Existing schemas and read models use Ecto; docs support joins, preloads, and `Ecto.Multi`. [VERIFIED: `mix.lock`; CITED: https://ecto.hexdocs.pm/Ecto.Query.html; CITED: https://ecto.hexdocs.pm/Ecto.Multi.html] |
| Oban | locked 2.23.0 | Job storage and existing job repair targets | Phase 61 batch and chain data is stored through Oban jobs plus Powertools tables. [VERIFIED: `mix.lock`; VERIFIED: Phase 61 verification; CITED: https://oban.hexdocs.pm/Oban.html] |
| Tailwind utility classes through host Phoenix app | existing project convention | Dense console styling | Existing native LiveViews use utility classes directly; UI-SPEC forbids third-party UI registries. [VERIFIED: `JobsLive`; VERIFIED: `62-UI-SPEC.md`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | locked 1.4.5 | JSON encode/decode for display snapshots and plan hashes | Use through existing display and Lifeline code paths. [VERIFIED: `mix.lock`; VERIFIED: `lib/oban_powertools/lifeline.ex`] |
| Postgrex | locked 0.22.2 | Postgres adapter | Required by Ecto-backed tests and runtime. [VERIFIED: `mix.lock`; VERIFIED: local `psql --version`] |
| Phoenix.LiveViewTest | from Phoenix LiveView 1.1.31 | LiveView interaction tests | Use `live/2`, `render_click/1`, form events, and `assert_patch/2` like existing tests. [VERIFIED: `test/oban_powertools/web/live/jobs_live_test.exs`; CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native HEEx/Tailwind | shadcn or third-party component registry | Rejected by locked UI contract and project stack; this is not a React app. [VERIFIED: `62-UI-SPEC.md`; VERIFIED: `mix.exs`] |
| Offset pagination | Keyset pagination | Offset matches `JobsLive`; preserve single-function keyset upgrade path if batch volume proves problematic. [VERIFIED: `62-CONTEXT.md`; VERIFIED: `lib/oban_powertools/jobs.ex`] |
| Lifeline callback target | Direct callback row updates from LiveView | Rejected because native pages own audited mutations through Lifeline. [VERIFIED: `62-CONTEXT.md`; VERIFIED: `lib/oban_powertools/lifeline.ex`] |
| Separate chain route | Chain-specific LiveView/table | Rejected because chains are batch-backed rows with a badge. [VERIFIED: `62-CONTEXT.md`; VERIFIED: Phase 61 context] |

**Installation:** No new package installation is recommended for this phase. [VERIFIED: `mix.exs`; VERIFIED: `62-UI-SPEC.md`]

## Package Legitimacy Audit

No external packages should be installed in Phase 62, so the Package Legitimacy Gate is not applicable. [VERIFIED: `62-UI-SPEC.md`; VERIFIED: `mix.exs`]

## Architecture Patterns

### System Architecture Diagram

```text
Operator
  |
  v
/ops/jobs/batches or /ops/jobs/batches/:id
  |
  v
ObanPowertools.Web.Router + LiveAuth
  |-- unauthorized --> redirect "/"
  |-- authorized read-only --> render evidence, disable mutations
  v
ObanPowertools.Web.BatchesLive
  |
  |-- filter/status/page events --> Selectors.batches_path/1 + push_patch
  |-- detail navigation ---------> Selectors.batch_detail_path/1
  v
ObanPowertools.Batches read model
  |
  |-- batches/progress ----------> oban_powertools_batches
  |-- failed members ------------> oban_powertools_batch_jobs + oban_jobs
  |-- callbacks -----------------> oban_powertools_callbacks
  |-- chain context -------------> oban_jobs.meta + callback payload + job_records
  v
Rendered operator evidence
  |
  |-- failed job retry ----------> Lifeline preview_repair(job_retry/job)
  |                                  -> execute_repair(preview_token, reason)
  |                                  -> Audit lifeline.repair_executed
  |
  |-- callback retry ------------> Lifeline preview_repair(callback_retry/callback)
                                     -> validate callback eligibility/drift
                                     -> reset failed/expired-lease callback state
                                     -> Audit lifeline.repair_executed
```

### Recommended Project Structure

```text
lib/oban_powertools/
├── batches.ex                     # read/query context for batch UI
├── lifeline.ex                    # add callback target/action preview + execute
├── lifeline/target_type.ex         # add closed "callback" target
└── web/
    ├── batches_live.ex            # index/detail LiveView
    ├── live_auth.ex               # batch permissions and read-only copy
    ├── router.ex                  # /batches and /batches/:id routes
    └── selectors.ex               # batches_path/1 and batch_detail_path/1

test/oban_powertools/
├── batches_test.exs               # read model and blocked-state derivation
├── lifeline_callback_test.exs      # callback retry preview/execute/drift
└── web/live/batches_live_test.exs  # LiveView index/detail/retry states
```

### Pattern 1: URL-Backed LiveView State

**What:** Use `handle_params/3` to load list/detail state, and use `push_patch/2` with selector helpers for filter/status/page changes. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html; VERIFIED: `JobsLive`]

**When to use:** Use for status tabs, filters, pagination, and shareable detail paths. [VERIFIED: `62-UI-SPEC.md`]

**Example:**

```elixir
# Source: lib/oban_powertools/web/jobs_live.ex + Phoenix.LiveView docs
def handle_event("select_status", %{"status" => status}, socket) do
  if status in @valid_statuses do
    filter = %{socket.assigns.filter | status: status, page: 1}

    {:noreply,
     socket
     |> assign(:selected_jobs, MapSet.new())
     |> push_patch(to: Selectors.batches_path(filter_path(filter)))}
  else
    {:noreply, socket}
  end
end
```

### Pattern 2: Read Context Owns Cross-Table Queries

**What:** Keep joins and query shaping in `ObanPowertools.Batches`, not inside `BatchesLive`. [VERIFIED: `62-CONTEXT.md`; VERIFIED: `lib/oban_powertools/jobs.ex`]

**When to use:** Use for list rows, metrics, batch detail, failed members, callback summaries, and chain context. [VERIFIED: `62-CONTEXT.md`]

**Example:**

```elixir
# Source: lib/oban_powertools/jobs.ex + Ecto.Query docs
def list(repo, %__MODULE__.Filter{} = filter) do
  Batch
  |> where([b], b.status == ^filter.status)
  |> maybe_filter_name_or_id(filter.query)
  |> order_by([b], desc: b.updated_at, desc: b.id)
  |> limit(^filter.page_size)
  |> offset(^offset(filter))
  |> repo.all()
end
```

### Pattern 3: Lifeline Preview Before Mutation

**What:** Preview writes or reuses a durable `RepairPreview`; execution checks auth, preview availability, reason validity, drift, mutation, preview consumption, audit, and host follow-up. [VERIFIED: `lib/oban_powertools/lifeline.ex`; VERIFIED: `lib/oban_powertools/lifeline/repair_preview.ex`]

**When to use:** Use for failed batch member retry and callback retry. [VERIFIED: `62-CONTEXT.md`]

**Example:**

```elixir
# Source: lib/oban_powertools/web/lifeline_live.ex
with :ok <- LiveAuth.authorize_action(socket, :preview_repair, resource),
     {:ok, preview} <-
       Lifeline.preview_repair(repo(), socket.assigns.current_actor, %{
         incident_id: nil,
         action: "callback_retry",
         target_type: "callback",
         target_id: callback_id
       }) do
  {:noreply, assign(socket, preview: preview, reason: "", error_message: nil)}
end
```

### Pattern 4: Explicit Blocked-State Derivation

**What:** Build a pure read-model function that maps stored evidence into copy-ready states such as `insert_failed`, `callback_failed`, `output_unavailable`, `executing`, `exhausted`, and `completed`. [VERIFIED: `62-CONTEXT.md`; VERIFIED: `Batch`; VERIFIED: `Callback`; VERIFIED: `Chain.Progression`]

**When to use:** Use for index hints and the detail section headed "Why this batch is blocked." [VERIFIED: `62-UI-SPEC.md`]

### Anti-Patterns to Avoid

- **LiveView-owned SQL:** LiveView query code would violate D-04 and make tests harder to isolate; put reads in `ObanPowertools.Batches`. [VERIFIED: `62-CONTEXT.md`]
- **Direct `Oban.retry_job` calls:** BUI-03 requires Lifeline-routed recovery and the codebase already has audited preview/execute infrastructure. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `lib/oban_powertools/lifeline.ex`]
- **All-or-nothing bulk retry:** Locked decision D-07 requires independent per-job preview/execute attempts with honest success/skip/failure reporting. [VERIFIED: `62-CONTEXT.md`]
- **Retry controls for healthy callbacks:** D-09 allows callback recovery only for visibly blocked/failed rows such as `failed` or expired-lease `claimed`. [VERIFIED: `62-CONTEXT.md`; VERIFIED: `lib/oban_powertools/callback.ex`]
- **Raw payload leakage:** Use `DisplayPolicy` seams for args/meta/error-like payloads because the project requires host redaction before policy-sensitive operator pages mount. [VERIFIED: `lib/oban_powertools/runtime_config.ex`; VERIFIED: `JobsLive`]
- **Separate chain UI:** Chains are batch-backed and must remain rows with a `Chain` badge. [VERIFIED: `62-CONTEXT.md`; VERIFIED: Phase 61 context]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LiveView routing/session/auth shell | Custom Plug/router shell | Existing `ObanPowertools.Web.Router` live session and `LiveAuth` | Existing native pages already share auth and host-owned route boundaries. [VERIFIED: `router.ex`; VERIFIED: `live_auth.ex`] |
| URL encoding | Inline query-string concatenation | `ObanPowertools.Web.Selectors.encode/2` and new selector helpers | Existing helper drops nil/empty values and preserves keyword-list order for tests. [VERIFIED: `selectors.ex`; VERIFIED: `selectors_test.exs`] |
| Job retry mutation | Direct job state changes in UI | `Lifeline.preview_repair` and `Lifeline.execute_repair` | Provides preview tokens, drift checks, reason validation, audit, and host follow-up. [VERIFIED: `lifeline.ex`] |
| Callback retry semantics | Ad hoc callback row update in LiveView | New Lifeline callback target/action | Keeps BUI-04 recovery audited and consistent with other native mutations. [VERIFIED: `62-CONTEXT.md`] |
| JSON/redaction rendering | Raw `inspect/1` or `Jason.encode!` in UI for sensitive payloads | `DisplayPolicy.render_job_field/3`, `actor_label/2`, `reason/2` patterns | Host policy can redact or replace sensitive data. [VERIFIED: `runtime_config.ex`; VERIFIED: `jobs_live_test.exs`] |
| Query pagination abstraction | New generic pagination framework | Offset pagination in one read-model function | Matches `Jobs.list/3` and D-05. [VERIFIED: `jobs.ex`; VERIFIED: `62-CONTEXT.md`] |

**Key insight:** The hard part is not rendering a table; it is preserving support-truth and audited mutation boundaries while combining batch, callback, chain, Oban job, recorded-output, and audit evidence. [VERIFIED: `62-CONTEXT.md`; VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Treating Callback Retry as Just Another Job Retry

**What goes wrong:** The UI previews a job retry but leaves the failed callback row unchanged, so the batch still appears blocked. [VERIFIED: `Callback`; VERIFIED: `Batch.Tracker`]

**Why it happens:** Current Lifeline supports `job`, `workflow`, and `workflow_step` targets, not `callback`. [VERIFIED: `Lifeline.TargetType`; VERIFIED: `Lifeline.@supported_actions`]

**How to avoid:** Add `callback_retry` / `callback` support in Lifeline before building callback UI controls. [VERIFIED: `62-CONTEXT.md`]

**Warning signs:** UI contains "Preview Callback Retry" but `Lifeline.TargetType.to_atom/1` has no `"callback"` clause. [VERIFIED: `target_type.ex`]

### Pitfall 2: Joining Batch Members Without Preserving Retry Eligibility

**What goes wrong:** Operators can select non-failed or non-retryable jobs. [VERIFIED: `62-UI-SPEC.md`]

**Why it happens:** `BatchJob.state` stores progress states (`success`, `discard`) while Oban job retry eligibility depends on current `oban_jobs.state`. [VERIFIED: `BatchJob`; VERIFIED: `Oban.Job` usage in `JobsLive`]

**How to avoid:** Read model should expose explicit `retry_eligible?` using both batch member state and Oban job state. [VERIFIED: `62-CONTEXT.md`]

**Warning signs:** Selection handlers accept any visible row id without checking eligibility. [VERIFIED: `JobsLive` selection pattern to adapt carefully]

### Pitfall 3: Mislabeling Output Failures as Generic Callback Failure

**What goes wrong:** Chain batches appear generically `callback_failed` without explaining missing or expired upstream output. [VERIFIED: Phase 61 context]

**Why it happens:** Chain progression stores output failures in callback failure evidence; the UI must interpret chain metadata and `last_error`. [VERIFIED: `Chain.Progression`; VERIFIED: `Chain.fetch_upstream_result/1` verification]

**How to avoid:** Blocked-state derivation must inspect callback event, payload, last error, upstream job id, and step metadata. [VERIFIED: `62-CONTEXT.md`]

**Warning signs:** The detail page lacks upstream job id, step index/count, or output-unavailable copy. [VERIFIED: `62-UI-SPEC.md`]

### Pitfall 4: Letting Event Payloads Drive Mutations Without Revalidation

**What goes wrong:** A crafted LiveView event retries a callback/job outside the visible eligible set. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html]

**Why it happens:** LiveView event payloads are client-controlled and must be authorized and validated before fetching or modifying resources. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html]

**How to avoid:** Re-fetch target rows in Lifeline preview/execute and authorize via `LiveAuth.authorize_action/4`. [VERIFIED: `lifeline_live.ex`; VERIFIED: `lifeline.ex`]

**Warning signs:** `handle_event/3` trusts selected ids without service-layer eligibility checks. [VERIFIED: codebase review]

### Pitfall 5: Losing Shareable State

**What goes wrong:** Filters or detail state exist only in assigns, so support handoffs cannot link to the exact view. [VERIFIED: `62-CONTEXT.md`]

**Why it happens:** Inline expansion feels simpler than URL-addressable detail routes. [VERIFIED: `62-CONTEXT.md`]

**How to avoid:** Use `/ops/jobs/batches/:id` for canonical detail and encode filters through selectors. [VERIFIED: `62-CONTEXT.md`; VERIFIED: `selectors.ex`]

**Warning signs:** No `batch_detail_path/1` or route-info test for `/ops/jobs/batches/:id`. [VERIFIED: existing router/selectors tests]

## Code Examples

### Selector Helper Extension

```elixir
# Source: lib/oban_powertools/web/selectors.ex
@canonical_paths %{
  lifeline: "/ops/jobs/lifeline",
  forensics: "/ops/jobs/forensics",
  audit: "/ops/jobs/audit",
  limiters: "/ops/jobs/limiters",
  cron: "/ops/jobs/cron",
  jobs: "/ops/jobs/jobs",
  batches: "/ops/jobs/batches"
}

def batches_path(params \\ []), do: encode(:batches, params)
def batch_detail_path(id), do: "#{@canonical_paths.batches}/#{id}"
```

### Callback Retry Eligibility

```elixir
# Source: lib/oban_powertools/callback.ex + Phase 62 D-09
def callback_retry_eligible?(callback, now \\ DateTime.utc_now())

def callback_retry_eligible?(%Callback{status: "failed"}, _now), do: true

def callback_retry_eligible?(%Callback{status: "claimed", lease_expires_at: %DateTime{} = lease}, now) do
  DateTime.compare(lease, now) in [:lt, :eq]
end

def callback_retry_eligible?(_callback, _now), do: false
```

### Independent Bulk Job Retry

```elixir
# Source: lib/oban_powertools/web/jobs_live.ex + Phase 62 D-07
Enum.reduce(selected_job_ids, %{successes: 0, failures: 0, skipped: 0}, fn job_id, acc ->
  case Lifeline.preview_repair(repo, actor, %{action: "job_retry", target_type: "job", target_id: job_id}) do
    {:ok, preview} ->
      case Lifeline.execute_repair(repo, actor, preview.preview_token, reason) do
        {:ok, _} -> %{acc | successes: acc.successes + 1}
        {:error, _} -> %{acc | failures: acc.failures + 1}
      end

    {:error, _} ->
      %{acc | skipped: acc.skipped + 1}
  end
end)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic Oban Web as primary UI | Native Powertools pages own audited mutations; Oban Web bridge is inspection-only | Existing project architecture before Phase 62 [VERIFIED: `router.ex`] | Batch recovery must be native, not bridge-driven. [VERIFIED: `62-CONTEXT.md`] |
| Workflow-specific callback outbox | Generalized `oban_powertools_callbacks` outbox | Phase 59 [VERIFIED: `59-CONTEXT.md`; VERIFIED: migration] | Batch and chain callbacks share one recovery visibility surface. [VERIFIED: `Callback`] |
| Hidden or implicit chain output failure | Explicit output-unavailable/expired errors through `JobRecord` | Phase 61 [VERIFIED: `61-VERIFICATION.md`] | UI must explain output contract failure, not hide it as running. [VERIFIED: `62-CONTEXT.md`] |
| Direct mutation controls | Lifeline preview/reason/execute with audit evidence | Existing Lifeline implementation [VERIFIED: `lifeline.ex`] | All recovery actions in this phase need preview tokens and reason gating. [VERIFIED: `62-CONTEXT.md`] |

**Deprecated/outdated:**
- Direct Oban mutation from this UI: rejected for BUI-03 and native mutation boundaries. [VERIFIED: `62-CONTEXT.md`]
- Separate chain route/table: rejected by D-15 and Phase 59/61 chain representation. [VERIFIED: `62-CONTEXT.md`; VERIFIED: `59-CONTEXT.md`]
- Realtime counts and cross-page select-all: deferred. [VERIFIED: `62-CONTEXT.md`; VERIFIED: `.planning/REQUIREMENTS.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact final module name `ObanPowertools.Web.BatchesLive` is recommended, not locked by existing code. [ASSUMED] | Recommended Project Structure | Planner can choose a different module name if it updates routes/tests consistently. |
| A2 | Callback retry should reset eligible callback rows to `pending`, clear claim/delivery failure fields as appropriate, and preserve attempts/audit evidence. [ASSUMED] | Architecture Patterns | Lifeline design may choose a narrower mutation shape after implementation tests. |

## Open Questions

1. **What exact callback retry mutation should Lifeline perform?**
   - What we know: callback rows have `status`, `attempts`, `available_at`, claim/lease fields, `delivered_at`, and `last_error`. [VERIFIED: `callback.ex`]
   - What's unclear: whether retry should increment attempts during preview, reset attempts, or only reset status/lease/error on execute. [ASSUMED]
   - Recommendation: planner should add a first task to design and test callback Lifeline semantics before UI wiring. [VERIFIED: `62-CONTEXT.md`]

2. **How much audit history should batch detail show in Phase 62?**
   - What we know: Lifeline writes `lifeline.repair_executed` audit events with resource type/id and metadata. [VERIFIED: `lifeline.ex`]
   - What's unclear: whether batch detail should aggregate job-level retry audit events by batch or only show directly linked callback/job evidence. [ASSUMED]
   - Recommendation: show audit evidence where directly findable by resource id; do not invent synthetic audit rows. [VERIFIED: `62-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/test implementation | yes | 1.19.5 | none needed. [VERIFIED: `elixir --version`] |
| Erlang/OTP | Runtime | yes | OTP 28 | none needed. [VERIFIED: `elixir --version`] |
| Mix | Test runner and dependency metadata | yes | 1.19.5 | none needed. [VERIFIED: `mix --version`] |
| PostgreSQL server | Ecto sandbox tests | yes | server accepting on `/tmp:5432`; client 14.17 | none needed. [VERIFIED: `pg_isready`; VERIFIED: `psql --version`] |
| Node/npm | Potential asset tooling | yes | Node 22.14.0 / npm 11.1.0 | Not expected for this phase because UI uses existing HEEx/Tailwind classes. [VERIFIED: `node --version`; VERIFIED: `62-UI-SPEC.md`] |
| Context7 CLI | Documentation lookup | no | — | Used official HexDocs pages directly. [VERIFIED: `ctx7 not found`; CITED: HexDocs URLs in Sources] |

**Missing dependencies with no fallback:** None found. [VERIFIED: environment audit]

**Missing dependencies with fallback:** Context7 CLI is missing; official HexDocs were used instead. [VERIFIED: `ctx7 not found`; CITED: HexDocs URLs]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest. [VERIFIED: `test/support/live_case.ex`] |
| Config file | `test/test_helper.exs`, `config/test.exs`. [VERIFIED: file scan] |
| Quick run command | `mix test test/oban_powertools/batches_test.exs test/oban_powertools/lifeline_callback_test.exs test/oban_powertools/web/live/batches_live_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/selectors_test.exs` [VERIFIED: existing test layout] |
| Full suite command | `mix test` [VERIFIED: Mix test task available] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| BUI-01 | Batch index/detail show progress, statuses, and failed members | LiveView + read-model unit | `mix test test/oban_powertools/batches_test.exs test/oban_powertools/web/live/batches_live_test.exs` | no - Wave 0 |
| BUI-02 | Blocked states explain insert failure, callback failure, output unavailable/expired, executing, exhausted, completed | read-model unit + LiveView render | `mix test test/oban_powertools/batches_test.exs test/oban_powertools/web/live/batches_live_test.exs` | no - Wave 0 |
| BUI-03 | Bulk retry selected failed batch members through Lifeline with per-job success/failure reporting | service + LiveView interaction | `mix test test/oban_powertools/web/live/batches_live_test.exs test/oban_powertools/lifeline_test.exs` | partial - existing Lifeline job tests; batch UI tests missing |
| BUI-04 | Stuck/dead callback visibility and retry through Lifeline | service + LiveView interaction | `mix test test/oban_powertools/lifeline_callback_test.exs test/oban_powertools/web/live/batches_live_test.exs` | no - Wave 0 |

### Sampling Rate

- **Per task commit:** Run the focused files touched by the task, usually one of `batches_test.exs`, `lifeline_callback_test.exs`, or `batches_live_test.exs`. [VERIFIED: existing test conventions]
- **Per wave merge:** Run the quick command above. [VERIFIED: existing ExUnit setup]
- **Phase gate:** Run `mix test` before `$gsd-verify-work`. [VERIFIED: GSD validation enabled because `.planning/config.json` does not set `workflow.nyquist_validation` to false]

### Wave 0 Gaps

- [ ] `test/oban_powertools/batches_test.exs` - covers list/detail filters, metrics, blocked-state derivation, retry eligibility, chain context. [VERIFIED: file absent]
- [ ] `test/oban_powertools/lifeline_callback_test.exs` - covers callback preview/execute/drift/expired/consumed/unauthorized/reason errors. [VERIFIED: file absent]
- [ ] `test/oban_powertools/web/live/batches_live_test.exs` - covers route rendering, URL filters, read-only state, selection reset, bulk retry modal, callback retry modal, empty/error states. [VERIFIED: file absent]
- [ ] Router/selectors tests need batch path assertions. [VERIFIED: existing `router_test.exs`; VERIFIED: existing `selectors_test.exs`]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not explicitly set `security_enforcement: false`. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Existing host `Auth.current_actor/1` and `LiveAuth.on_mount/4` derive actor from session. [VERIFIED: `auth.ex`; VERIFIED: `live_auth.ex`] |
| V3 Session Management | yes | Host Phoenix browser pipeline owns session; Powertools live session consumes session data. [VERIFIED: `test/support/test_router.ex`; VERIFIED: `router.ex`] |
| V4 Access Control | yes | `LiveAuth.authorize_page/3` and `authorize_action/4` for page and mutation checks. [VERIFIED: `live_auth.ex`] |
| V5 Input Validation | yes | Validate all LiveView params/events; use closed status/action sets and service-layer re-fetch before mutation. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html; VERIFIED: `JobsLive` pattern] |
| V6 Cryptography | no direct new crypto | Lifeline preview tokens are UUIDs and plan hashes already exist; do not add custom crypto. [VERIFIED: `RepairPreview`; VERIFIED: `Lifeline.plan_hash/5`] |
| V7 Error Handling | yes | Render load/preview/drift/expired/consumed errors without crashing LiveView. [VERIFIED: `lifeline_live.ex`; VERIFIED: `62-UI-SPEC.md`] |
| V10 Malicious Code | yes | Do not atomize untrusted strings; use allowlists before `String.to_existing_atom` patterns. [VERIFIED: `JobsLive`; VERIFIED: `Chain.Progression`] |
| V14 Configuration | yes | Require configured repo, auth module, and display policy before sensitive pages. [VERIFIED: `runtime_config.ex`; VERIFIED: `JobsLive`] |

### Known Threat Patterns for Phoenix LiveView / Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged LiveView event retries unauthorized target | Elevation of Privilege | Authorize action and re-fetch/validate target in Lifeline before mutation. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html; VERIFIED: `lifeline.ex`] |
| Raw job args/meta leaks sensitive data | Information Disclosure | Use `DisplayPolicy` for payload rendering and host redaction. [VERIFIED: `runtime_config.ex`; VERIFIED: `JobsLive`] |
| Query param atom exhaustion | Denial of Service | Only convert allowlisted status strings to existing atoms; reject unknown values. [VERIFIED: `JobsLive`] |
| SQL injection through filters | Tampering | Use Ecto query parameters, not string SQL interpolation. [CITED: https://ecto.hexdocs.pm/Ecto.Query.html; VERIFIED: `Jobs` read model] |
| Race between preview and execute | Tampering | Recompute plan hash and mark previews drifted/expired/consumed. [VERIFIED: `lifeline.ex`; VERIFIED: `RepairPreview`] |
| Bulk retry partial failure hidden from operator | Repudiation | Report per-job success/failure/skip counts and rely on audit rows per executed repair. [VERIFIED: `62-CONTEXT.md`; VERIFIED: `lifeline.ex`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/62-operations-console-lifeline-ui/62-CONTEXT.md` - locked implementation decisions, deferred scope, canonical refs. [VERIFIED: file read]
- `.planning/phases/62-operations-console-lifeline-ui/62-UI-SPEC.md` - locked UI, copy, accessibility, and interaction contract. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - BUI-01 through BUI-04 and deferred requirements. [VERIFIED: file read]
- `.planning/STATE.md` - current focus and prior architectural decisions. [VERIFIED: file read]
- `lib/oban_powertools/web/jobs_live.ex` - existing URL filters, selection, detail, and Lifeline job repair pattern. [VERIFIED: codebase grep]
- `lib/oban_powertools/web/lifeline_live.ex` - preview/reason/execute UI behavior. [VERIFIED: codebase grep]
- `lib/oban_powertools/lifeline.ex` - current Lifeline action/target support, preview/execute, audit. [VERIFIED: codebase grep]
- `lib/oban_powertools/batch.ex`, `batch_job.ex`, `callback.ex`, `batch/tracker.ex`, `chain/progression.ex` - batch/callback/chain data sources. [VERIFIED: codebase grep]
- Phoenix LiveView docs - lifecycle, `handle_params/3`, `push_patch/2`, untrusted event payloads. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html]
- Phoenix LiveView Router docs - `live/4`, `live_session/3`. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.Router.html]
- Phoenix LiveViewTest docs - `assert_patch` testing pattern. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html]
- Ecto Query and Multi docs - query/preload and transaction composition references. [CITED: https://ecto.hexdocs.pm/Ecto.Query.html; CITED: https://ecto.hexdocs.pm/Ecto.Multi.html]
- Oban docs - `insert_all` and job API baseline. [CITED: https://oban.hexdocs.pm/Oban.html]

### Secondary (MEDIUM confidence)

- `mix hex.info phoenix_live_view`, `mix hex.info ecto_sql`, `mix hex.info oban` - current Hex package metadata and release recency. [VERIFIED: Hex CLI]

### Tertiary (LOW confidence)

- None. [VERIFIED: sources audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions verified through `mix.lock`, Hex CLI, and official docs. [VERIFIED: `mix.lock`; VERIFIED: Hex CLI]
- Architecture: HIGH - locked context plus existing code patterns are consistent. [VERIFIED: `62-CONTEXT.md`; VERIFIED: codebase grep]
- Pitfalls: HIGH - derived from concrete gaps in current Lifeline target support and locked UI decisions. [VERIFIED: `lifeline.ex`; VERIFIED: `62-CONTEXT.md`]

**Research date:** 2026-06-14  
**Valid until:** 2026-07-14 for project-specific findings; 2026-06-21 for dependency-version claims because Phoenix LiveView is actively releasing. [VERIFIED: Hex CLI]
