# Phase 61: APIs (Batches & Chains) - Research

**Researched:** 2026-06-14
**Domain:** Elixir/Oban/Ecto batch enqueue APIs, callback-outbox chain composition, durable job output handoff
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### `Batch.insert_stream/2` Public Contract
- **D-01:** Implement `Batch.insert_stream/2` as a fixed-size, chunked streaming insert API. The caller must provide `total_count:` up front; do not infer totals by consuming an arbitrary stream.
- **D-02:** Insert in bounded chunks with a default `chunk_size` chosen for Postgres safety. The default transaction mode should be per chunk for massive batches, not one giant all-or-nothing transaction.
- **D-03:** Return compact result structs, not all inserted jobs: `{:ok, %Batch.InsertResult{batch_id, total_count, inserted_count, chunk_count}}` or `{:error, %Batch.InsertError{batch_id, total_count, inserted_count, failed_chunk, reason}}`.
- **D-04:** Partial insert failure must be honest and durable. If some chunks were inserted and a later chunk fails, return the error with counts and mark the batch as visibly failed for insertion (`insert_failed` or equivalent), rather than leaving a permanently hanging batch.
- **D-05:** Do not support `on_conflict: :skip` for batch members. Skipped jobs corrupt the fixed `total_count` invariant and make completion callbacks untrustworthy.
- **D-06:** Allow caller-supplied deterministic `batch_id` only as a creation id. Never silently append to an existing batch id; an existing id is an error unless a future explicitly designed idempotent insert contract is added.
- **D-07:** Callback configuration remains explicit. Do not overload worker lifecycle hooks as whole-batch callbacks; callbacks continue through the generalized `oban_powertools_callbacks` outbox with `batch.completed` / `batch.exhausted` events.

### Linear Chain API
- **D-08:** Create `ObanPowertools.Chain` as the public chain API. The canonical docs path should be pipeable and familiar to Oban users, while the support-truth representation is an explicit `%ObanPowertools.Chain{}` spec.
- **D-09:** Provide a list/spec constructor for generated chains, e.g. `Chain.from_list/2`, but keep the pipeable facade as the primary developer experience.
- **D-10:** Compile chains to existing primitives: a batch grouping plus callback-outbox links that enqueue the next step. Do not introduce a separate `chains` table in this phase.
- **D-11:** Keep chains strictly linear. Reject branching, fan-in, nested batches, arbitrary workflow dependencies, and chain-of-workflow magic. If users need a DAG, they should use the existing Workflow surface.
- **D-12:** Do not use worker `on_success/2` or `on_discard/2` as the public chain authoring contract. Worker hooks remain observe-only lifecycle hooks; chain progression is Powertools-owned callback/outbox behavior.
- **D-13:** Persist output-dependent arg builders as durable references, not anonymous functions. Static next steps may be job changesets; dynamic next-step args must use an MFA/builder behavior such as `{Module, :function, extra_args}` so the callback dispatcher can rebuild args after BEAM restarts.

### Upstream Output Handoff
- **D-14:** Use `ObanPowertools.JobRecord` as the durable output boundary for chain state propagation. Chain metadata/callback payloads carry references such as upstream job id, chain id, and step name; they do not carry full business payloads.
- **D-15:** Expose `ObanPowertools.Chain.fetch_upstream_result/1` (and repo-explicit variants if needed) as the normal CHN-02 API for downstream workers that need the upstream payload.
- **D-16:** Require upstream workers that feed output-dependent chain steps to use `record_output: true`. Validate this at chain build/insert time when the upstream worker module is known.
- **D-17:** Missing, expired, oversized, or unrecorded upstream output must be surfaced as an explicit error, not `nil`. The callback/chain path should fail visibly and recoverably (`output_unavailable`, callback failed/blocked state, or equivalent), preserving Phase 62 operator repair visibility.
- **D-18:** Do not auto-copy upstream payloads into downstream job args by default. If a future escape hatch allows payload snapshots, it must be explicit, documented as small/non-sensitive only, and must not bypass redaction/display-policy support truth.

### Cohesive API Shape
- **D-19:** Recommended batch example:

  ```elixir
  rows
  |> Stream.map(&ImportRowWorker.new(%{import_id: import.id, row: &1}))
  |> ObanPowertools.Batch.insert_stream(
    repo: MyApp.Repo,
    total_count: row_count,
    chunk_size: 1_000,
    name: "import:#{import.id}"
  )
  ```

- **D-20:** Recommended chain example:

  ```elixir
  import ObanPowertools.Chain

  FetchFile.new(%{import_id: import.id})
  |> chain(:parse, ParseFile, args: {ImportChainArgs, :parse, [import.id]})
  |> chain(:write, WriteRows.new(%{import_id: import.id}))
  |> chain(:notify, NotifyImport.new(%{import_id: import.id}))
  |> ObanPowertools.Chain.insert(MyApp.Repo, name: "import:#{import.id}")
  ```

- **D-21:** Recommended downstream output example:

  ```elixir
  def process(job) do
    with {:ok, upstream} <- ObanPowertools.Chain.fetch_upstream_result(job) do
      transform(upstream["rows_ref"])
    end
  end
  ```

### the agent's Discretion
- The user explicitly delegated the three selected gray areas to subagent-backed research and asked for one coherent recommendation set. The planner should treat the decisions above as locked unless implementation discovers a concrete contradiction with existing code or Oban/Ecto constraints.

### Deferred Ideas (OUT OF SCOPE)
- Growable/dynamic batches and loader-job patterns remain deferred until a future milestone explicitly reopens the fixed-size batch decision.
- Nested batches, chunks, arbitrary DAG composition, and chain fan-in/fan-out remain out of Phase 61 and belong to dedicated future work if adopter demand appears.
- Full operator UI design for batch/chain blocked states belongs to Phase 62.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BAT-02 | `Batch.insert_stream/2` API for safely enqueuing massive batches via chunked inserts to prevent DB lock starvation. [VERIFIED: .planning/REQUIREMENTS.md] | Use bounded `Stream.chunk_every/2` plus per-chunk `Oban.insert_all/2`, inject `batch_id` into job meta, and return compact counters. [VERIFIED: codebase grep] [CITED: https://oban.hexdocs.pm/Oban.html] |
| CHN-01 | Ergonomic DSL for linear Chains mapping sequentially to the Callback Outbox. [VERIFIED: .planning/REQUIREMENTS.md] | Add `%ObanPowertools.Chain{}` and a `chain/3` macro/function facade; persist next-step progression as callback rows, not a `chains` table. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md] |
| CHN-02 | State propagation support allowing a sequential job to access durable output of its upstream predecessor. [VERIFIED: .planning/REQUIREMENTS.md] | Use `ObanPowertools.JobRecord.fetch_result/2` behind `Chain.fetch_upstream_result/1`; require `record_output: true` for output-dependent upstream steps. [VERIFIED: lib/oban_powertools/job_record.ex] |
</phase_requirements>

## Summary

Phase 61 should stay entirely on the existing Elixir/Oban/Ecto stack; no new external package is required. [VERIFIED: mix.exs] `Batch.insert_stream/2` should be a public API added to `ObanPowertools.Batch` that creates a fixed-size batch row, streams job changesets in bounded chunks, injects `batch_id` metadata, inserts each chunk with `Oban.insert_all/2`, and marks insertion failures durably with a visible status. [VERIFIED: lib/oban_powertools/batch.ex] [VERIFIED: lib/oban_powertools/batch/tracker.ex] [CITED: https://oban.hexdocs.pm/Oban.html]

Chains should be implemented as an API/spec layer plus callback-outbox progression, not as a new persistence model. [VERIFIED: .planning/phases/59-schemas-foundation/59-CONTEXT.md] Existing callback dispatch is workflow-handler oriented, so Phase 61 must add a Powertools-owned chain progression path or dispatcher branch for chain callback events instead of routing chain progression through `workflow_callback_handler`. [VERIFIED: lib/oban_powertools/workflow/runtime.ex] [VERIFIED: lib/oban_powertools/callback.ex]

**Primary recommendation:** Plan three implementation slices: `Batch.insert_stream/2`, `ObanPowertools.Chain` spec/insert/progression, and `Chain.fetch_upstream_result/1` with explicit output-unavailable failure states. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]

## Project Constraints

- No root `AGENTS.md` exists in `/Users/jon/projects/oban_powertools`; the only discovered `AGENTS.md` is under `examples/phoenix_host_upgrade_source/`. [VERIFIED: `find . -maxdepth 3 -name AGENTS.md`]
- No project-local `.codex/skills/` or `.agents/skills/` directory exists, so no additional project skill rules apply. [VERIFIED: `find . -maxdepth 3 -path './.codex/skills/*/SKILL.md' -o -path './.agents/skills/*/SKILL.md'`]
- Graphify is disabled, so semantic graph context is unavailable for this phase. [VERIFIED: `gsd-tools graphify status`]
- The project preference is `vendor_philosophy: thorough-evaluator`; research should prefer explicit evaluation and support-truth behavior over hidden magic. [VERIFIED: .planning/config.json]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Massive batch enqueue | API / Backend | Database / Storage | The public Elixir API builds job changesets, creates batch rows, and performs bounded DB inserts. [VERIFIED: lib/oban_powertools/batch.ex] |
| Batch progress tracking | API / Backend | Database / Storage | Phase 60 hooks already update counters transactionally from worker lifecycle results. [VERIFIED: lib/oban_powertools/batch/tracker.ex] |
| Chain authoring DSL | API / Backend | — | Chain construction is developer-facing Elixir API surface, not browser/UI behavior. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md] |
| Chain progression | API / Backend | Database / Storage | Progression should enqueue next jobs from durable callback rows and Oban job metadata. [VERIFIED: lib/oban_powertools/callback.ex] |
| Upstream output handoff | API / Backend | Database / Storage | `JobRecord` stores output rows and exposes fetch APIs by Oban job id. [VERIFIED: lib/oban_powertools/job_record.ex] |
| Operator visibility | Browser / Client | API / Backend | Phase 62 owns UI; Phase 61 must create explicit statuses and payloads the UI can inspect. [VERIFIED: .planning/ROADMAP.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Runtime, build, test runner | Project `mix.exs` targets `~> 1.19`, and local environment matches. [VERIFIED: mix.exs] [VERIFIED: `elixir --version`] |
| Oban | 2.23.0 | Job changesets, `insert_all`, job metadata, queue persistence | Oban provides `Worker.new/2`, `Oban.Job.new/2`, metadata, transactional insertion, and bulk insertion. [VERIFIED: `mix deps`] [CITED: https://oban.hexdocs.pm/Oban.html] [CITED: https://oban.hexdocs.pm/Oban.Job.html] |
| Ecto / Ecto SQL | 3.14.0 | Schemas, changesets, `Ecto.Multi`, transactions, `Repo.insert_all` | Existing schemas and migrations are Ecto-native; Ecto provides transaction and insert primitives. [VERIFIED: `mix deps`] [CITED: https://ecto.hexdocs.pm/Ecto.Repo.html] |
| Postgrex / PostgreSQL | Postgrex 0.22.2, PostgreSQL 14.17 local | Database adapter and target RDBMS for tests | Oban 2.23 requires PostgreSQL 14+ when using Postgres, and local Postgres is accepting connections. [VERIFIED: `mix deps`] [VERIFIED: `pg_isready`] [CITED: https://oban.hexdocs.pm/Oban.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | 1.4.5 | JSON payload encoding and output-size checks | Already used by `JobRecord` to normalize and size recorded outputs. [VERIFIED: lib/oban_powertools/job_record.ex] [VERIFIED: `mix deps`] |
| Telemetry | 1.4.2 | Event emission | Use only if adding batch/chain API telemetry; existing project already centralizes telemetry contracts. [VERIFIED: lib/oban_powertools/telemetry.ex] |
| ExUnit / SQL Sandbox | Elixir 1.19.5 built-in, Ecto SQL sandbox | Tests | Existing `DataCase` uses `Ecto.Adapters.SQL.Sandbox`; keep Phase 61 tests in the same style. [VERIFIED: test/support/data_case.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Chunked `Oban.insert_all/2` | Raw `Repo.insert_all(Oban.Job, ...)` | Raw inserts would bypass Oban changeset handling and are unnecessary because Oban exposes bulk insert for changesets. [CITED: https://oban.hexdocs.pm/Oban.html] |
| Callback-outbox chain progression | New `chains` table | Explicitly rejected by Phase 59 and Phase 61 decisions. [VERIFIED: .planning/phases/59-schemas-foundation/59-CONTEXT.md] [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md] |
| `JobRecord` output fetch | Copy upstream payload into downstream args | Explicitly rejected because payload copies can bypass redaction/display boundaries and bloat job args. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md] |

**Installation:**

```bash
# No new packages for Phase 61.
```

**Version verification:**

```bash
mix deps
mix hex.info oban
mix hex.info ecto_sql
```

## Package Legitimacy Audit

No external packages are recommended or installed in Phase 61. [VERIFIED: mix.exs] `slopcheck` is available locally, but there are no package names to audit. [VERIFIED: `slopcheck --version`]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | — | — | — | — | — | No install |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Batch.insert_stream/2 caller
  -> validates total_count/chunk_size/batch_id/name/callback opts
  -> inserts oban_powertools_batches row with status="inserting"
  -> stream chunks of Oban.Job changesets
  -> inject meta: %{"batch_id" => batch_id, "batch_name" => name?}
  -> Oban.insert_all(chunk)
       -> success: increment inserted_count and continue
       -> failure: update batch status="insert_failed" + failure payload, return InsertError
  -> when inserted_count == total_count: update status="executing", return InsertResult

Worker execution
  -> ObanPowertools.Worker.Hooks.after_result/3
  -> Batch.Tracker.record_progress/3
  -> oban_powertools_batch_jobs uniqueness guard
  -> atomic batch counter increment
  -> batch.completed / batch.exhausted callback row

Chain.insert/2 caller
  -> builds %ObanPowertools.Chain{} linear spec
  -> creates batch grouping row with total_count = step_count
  -> inserts first job with chain metadata
  -> stores next-step spec in callback row payload
  -> chain callback dispatcher claims row
       -> optional fetch upstream JobRecord
       -> optional MFA args builder
       -> insert next job with upstream job id in meta
       -> mark callback delivered or failed/blocked
```

### Recommended Project Structure

```text
lib/oban_powertools/
├── batch.ex                 # Add InsertResult, InsertError, insert_stream/2
├── batch/tracker.ex         # Keep progress callback behavior; extend statuses only as needed
├── chain.ex                 # Public Chain struct, chain/3 DSL, from_list/2, insert/2, fetch_upstream_result/1
├── chain/progression.ex     # Internal callback-row to next-job insertion logic
├── callback.ex              # Extend allowed event vocabulary for chain progression
└── job_record.ex            # Reuse fetch_result; avoid payload copy into args
```

### Pattern 1: Chunked Batch Insertion

**What:** Create the batch once, stream changesets in fixed chunks, insert each chunk independently, and return counters instead of inserted jobs. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]

**When to use:** BAT-02 massive batch enqueueing where a single transaction over the entire stream would hold locks too long. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: Oban insert_all supports changeset lists and streams; Phase 61 locks total_count/chunking.
def insert_stream(stream, opts) do
  total_count = Keyword.fetch!(opts, :total_count)
  chunk_size = Keyword.get(opts, :chunk_size, 1_000)

  with {:ok, batch} <- create_batch(opts, total_count) do
    stream
    |> Stream.chunk_every(chunk_size)
    |> Enum.reduce_while(%InsertResult{batch_id: batch.id, total_count: total_count}, fn chunk, acc ->
      case insert_chunk(chunk, batch.id, opts) do
        {:ok, inserted} -> {:cont, %{acc | inserted_count: acc.inserted_count + inserted}}
        {:error, reason} -> {:halt, fail_insert(batch, acc, reason)}
      end
    end)
  end
end
```

### Pattern 2: Changeset Metadata Injection

**What:** Rewrite each `Oban.Job` changeset to merge Powertools metadata before calling `Oban.insert_all/2`. [VERIFIED: lib/oban_powertools/batch/tracker.ex] [CITED: https://oban.hexdocs.pm/Oban.Job.html]

**When to use:** Every batch member and chain step needs durable metadata for progress tracking or upstream output lookup. [VERIFIED: lib/oban_powertools/worker/hooks.ex]

**Example:**

```elixir
# Source: Oban.Job.new/2 supports :meta; Oban.Worker.new/2 returns a job changeset.
defp put_powertools_meta(%Ecto.Changeset{} = changeset, meta) do
  existing = Ecto.Changeset.get_field(changeset, :meta) || %{}
  Ecto.Changeset.put_change(changeset, :meta, Map.merge(existing, meta))
end
```

### Pattern 3: Linear Chain Spec

**What:** Represent a chain as a list of ordered step specs and reject any API input that implies branching or fan-in. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]

**When to use:** CHN-01 sequential jobs where each step may depend on the prior step’s durable output. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: Phase 61 CONTEXT D-20.
FetchFile.new(%{"import_id" => import.id})
|> ObanPowertools.Chain.chain(:parse, ParseFile, args: {ImportChainArgs, :parse, [import.id]})
|> ObanPowertools.Chain.chain(:write, WriteRows.new(%{"import_id" => import.id}))
|> ObanPowertools.Chain.insert(MyApp.Repo, name: "import:#{import.id}")
```

### Anti-Patterns to Avoid

- **One giant transaction for massive streams:** It contradicts the locked per-chunk default and can hold locks for too long. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]
- **`on_conflict: :skip` for batch jobs:** It corrupts the fixed `total_count` invariant. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]
- **Anonymous functions in persisted chain specs:** They cannot be reconstructed after restart; persist MFA/builder references instead. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]
- **Routing chain progression through user worker hooks:** Worker hooks are observe-only in current project semantics. [VERIFIED: lib/oban_powertools/worker/hooks.ex]
- **Copying upstream output into downstream args by default:** This can leak or duplicate payloads and conflicts with the locked output boundary. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bulk job persistence | Raw SQL into `oban_jobs` | `Oban.insert_all/2` | Oban already accepts changeset lists/streams and preserves job semantics. [CITED: https://oban.hexdocs.pm/Oban.html] |
| Output storage | A chain-specific result table | `ObanPowertools.JobRecord` | Existing output records already normalize payloads, enforce size limits, and expose fetch APIs. [VERIFIED: lib/oban_powertools/job_record.ex] |
| Idempotent progress | Manual count queries over `batch_jobs` | Existing `Batch.Tracker` uniqueness plus counter increments | Phase 60 already implemented exactly-once progress tracking. [VERIFIED: lib/oban_powertools/batch/tracker.ex] |
| DAG execution | Branch/fan-in chain semantics | Existing `ObanPowertools.Workflow` | Workflow already validates DAGs and dependencies; chains must stay linear. [VERIFIED: lib/oban_powertools/workflow.ex] |

**Key insight:** Phase 61 is an API-composition phase over existing primitives; plans should add thin, explicit orchestration surfaces and avoid new engines or tables unless implementation discovers an unavoidable schema gap. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Batch Hangs After Partial Insert Failure

**What goes wrong:** A batch row with `total_count` larger than inserted jobs never reaches completion. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]
**Why it happens:** A later chunk fails after earlier chunks were committed. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]
**How to avoid:** Update batch status to `insert_failed` with enough failure details before returning `InsertError`. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]
**Warning signs:** `inserted_count < total_count` and status still reads `executing`. [VERIFIED: lib/oban_powertools/batch.ex]

### Pitfall 2: Callback Dispatcher Claims Chain Rows as Host Workflow Callbacks

**What goes wrong:** `Workflow.dispatch_callbacks/2` claims all pending callback rows and calls `handler.handle_workflow_callback(row.payload)`. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
**Why it happens:** Current `claim_callbacks/5` does not filter by event prefix. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
**How to avoid:** Add event-scoped claim filters or a separate chain progression dispatcher that only claims chain events. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
**Warning signs:** Chain callback events require `workflow_callback_handler` or fail with handler errors. [VERIFIED: lib/oban_powertools/runtime_config.ex]

### Pitfall 3: Upstream Result Is Unavailable

**What goes wrong:** A downstream worker calls `fetch_upstream_result/1` and no `JobRecord` exists. [VERIFIED: lib/oban_powertools/job_record.ex]
**Why it happens:** Upstream worker did not set `record_output: true`, returned non-`{:ok, payload}`, payload was oversized, or retention expired. [VERIFIED: lib/oban_powertools/worker.ex] [VERIFIED: lib/oban_powertools/job_record.ex]
**How to avoid:** Validate output-dependent upstream modules at chain build/insert time when the worker module is known, and return explicit errors such as `{:error, :output_unavailable}`. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md]
**Warning signs:** `JobRecord.fetch_result/2` returns `{:error, :not_found}`. [VERIFIED: lib/oban_powertools/job_record.ex]

### Pitfall 4: Bulk Insert Uses Unique Jobs

**What goes wrong:** Bulk unique jobs are not supported by Oban basic engine. [CITED: https://oban.hexdocs.pm/Oban.html]
**Why it happens:** Oban documents that only Smart Engine supports bulk unique jobs, automatic insert batching, and minimized parameters. [CITED: https://oban.hexdocs.pm/Oban.html]
**How to avoid:** Reject or document unsupported unique changesets in `Batch.insert_stream/2`, or fall back to per-job insertion only if explicitly planned. [CITED: https://oban.hexdocs.pm/Oban.html]
**Warning signs:** A batch stream contains changesets with `unique` options. [CITED: https://oban.hexdocs.pm/Oban.Job.html]

## Code Examples

### Fetch Upstream Result

```elixir
# Source: lib/oban_powertools/job_record.ex
def fetch_upstream_result(%Oban.Job{meta: meta}) do
  with upstream_id when is_integer(upstream_id) <- meta["upstream_job_id"] || meta[:upstream_job_id],
       {:ok, payload} <- ObanPowertools.JobRecord.fetch_result(upstream_id) do
    {:ok, payload}
  else
    nil -> {:error, :missing_upstream_job_id}
    {:error, :not_found} -> {:error, :output_unavailable}
  end
end
```

### Chain Callback Payload Shape

```elixir
# Source: lib/oban_powertools/callback.ex plus Phase 61 CONTEXT D-13/D-14.
%{
  "event" => "chain.step_succeeded",
  "chain_id" => batch.id,
  "step_name" => "parse",
  "upstream_job_id" => job.id,
  "next_step" => %{
    "step" => %{
      "name" => "write",
      "index" => 2,
      "worker" => "MyApp.WriteRows",
      "args" => %{},
      "queue" => "default",
      "meta" => %{},
      "args_builder" => ["MyApp.ImportChainArgs", "write", [import_id]],
      "requires_output" => true
    },
    "remaining" => [
      %{
        "name" => "notify",
        "index" => 3,
        "worker" => "MyApp.NotifyImport",
        "args" => %{"import_id" => import_id},
        "queue" => "default",
        "meta" => %{},
        "requires_output" => false
      }
    ]
  }
}
```

### Chain Insert Validation

```elixir
# Source: lib/oban_powertools/worker.ex exposes __powertools_output_recording__/0.
defp validate_recorded_upstream!(worker_mod) do
  if function_exported?(worker_mod, :__powertools_output_recording__, 0) do
    %{record_output: true} = worker_mod.__powertools_output_recording__()
    :ok
  else
    {:error, {:record_output_required, worker_mod}}
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Oban Pro batch worker module | `Oban.Pro.Batch` with explicit batch callbacks | Oban Pro v1.5 upgrade docs | Supports separate batch abstraction and callback behavior. [CITED: https://oban.pro/docs/pro/v1-5.html] |
| Conflating chains/workflows/batches | Separate composition primitives: Batch, Chain, Chunk, Workflow | Oban Pro composition docs current page | Phase 61 should preserve clear boundaries and avoid chain DAG semantics. [CITED: https://oban.pro/docs/pro/composition.html] |
| Recomputing progress from many jobs | Dedicated tracking tables/counters in modern Oban Pro workflows | Oban Pro v1.7 changelog | Supports Phase 59/60 direction of explicit rows and counters. [CITED: https://oban.pro/docs/pro/changelog.html] |

**Deprecated/outdated:**
- `Oban.Pro.Workers.Batch` is deprecated in favor of `Oban.Pro.Batch`; do not mirror the old worker-injected batch API shape. [CITED: https://oban.pro/docs/pro/v1-5.html]
- Arbitrary DAG workflow semantics belong to `ObanPowertools.Workflow`, not the chain DSL. [VERIFIED: lib/oban_powertools/workflow.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Default `chunk_size: 1_000` is a safe starting point for Postgres inserts in this project. [ASSUMED] | Summary / Architecture Patterns | Planner should include measurement tests and allow tuning if local DB timeout/parameter behavior says otherwise. |
| A2 | Chain progression can be implemented without schema changes beyond callback event/status/payload support. [ASSUMED] | Architecture Patterns | Planner may need a small migration if explicit `insert_failed` details or chain status fields cannot fit existing schemas. |

## Open Questions (RESOLVED)

1. **Where should durable insertion failure details live? RESOLVED by Plan 61-01.**
   - What we know: `Batch` currently has `status`, counters, and `completed_at` only. [VERIFIED: lib/oban_powertools/batch.ex]
   - Resolution: Plan 61-01 adds explicit batch fields `name`, `inserted_count`, `insert_chunk_count`, `insert_failed_chunk`, `insert_failure`, and `insert_failed_at` to the schema, test migration, and host installer migration. This directly supports Phase 62 display and D-04 durable partial failure semantics. [VERIFIED: .planning/phases/61-apis-batches-chains/61-01-PLAN.md]

2. **Should chain progression reuse `Workflow.dispatch_callbacks/2` or get its own API? RESOLVED by Plan 61-04.**
   - What we know: Current dispatcher claims all callback rows matching pending/failed/claimed states. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
   - Resolution: Plan 61-04 keeps host callback dispatch responsible for `"workflow.terminal"`, `"workflow.recovery_completed"`, `"batch.completed"`, and `"batch.exhausted"` while excluding `"chain.step_succeeded"`. Chain events get a separate `ObanPowertools.Chain.Progression.dispatch_callbacks/2` path that claims only chain rows and consumes the durable `%{"step" => immediate, "remaining" => tail}` descriptor so D-20 3+ step chains continue progressing. [VERIFIED: .planning/phases/61-apis-batches-chains/61-04-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Build/test/runtime | yes | 1.19.5 | none needed [VERIFIED: `elixir --version`] |
| Mix | Build/test/deps | yes | 1.19.5 | none needed [VERIFIED: `mix --version`] |
| PostgreSQL | Data tests and Oban storage | yes | 14.17 | none needed [VERIFIED: `psql --version`; `pg_isready`] |
| Oban | Job API | yes | 2.23.0 | none needed [VERIFIED: `mix deps`] |
| Ecto SQL | Schemas/transactions | yes | 3.14.0 | none needed [VERIFIED: `mix deps`] |
| slopcheck | Package audit | yes | 0.6.1 | no package installs [VERIFIED: `slopcheck --version`] |
| Context7 CLI | Docs lookup | no | — | Official HexDocs/Web docs used [VERIFIED: `ctx7 not found`] |

**Missing dependencies with no fallback:** none

**Missing dependencies with fallback:**
- Context7 CLI is absent; official HexDocs and Oban Pro docs were used instead. [VERIFIED: `ctx7 not found`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL Sandbox [VERIFIED: test/support/data_case.ex] |
| Config file | `test/test_helper.exs` boots migrations and `TestRepo`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/oban_powertools/batch_test.exs test/oban_powertools/batch/tracker_test.exs test/oban_powertools/callback_test.exs test/oban_powertools/job_record_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| BAT-02 | `Batch.insert_stream/2` inserts stream in bounded chunks, returns compact result, and marks partial failure as `insert_failed`. | unit/integration | `mix test test/oban_powertools/batch_insert_stream_test.exs` | No - Wave 0 |
| BAT-02 | Large insert does not use one transaction and calls `Oban.insert_all/2` once per chunk. | integration/measurement | `mix test test/oban_powertools/batch_insert_stream_test.exs --only batch_stream` | No - Wave 0 |
| CHN-01 | Pipeable `chain/3`, `from_list/2`, and `Chain.insert/2` reject branching and create first job plus callback metadata. | unit/integration | `mix test test/oban_powertools/chain_test.exs` | No - Wave 0 |
| CHN-01 | Chain callback progression inserts the next job after upstream success and does not invoke host workflow callback handler. | integration | `mix test test/oban_powertools/chain_progression_test.exs` | No - Wave 0 |
| CHN-02 | Downstream worker can call `Chain.fetch_upstream_result/1` and receive `JobRecord` payload. | unit/integration | `mix test test/oban_powertools/chain_output_test.exs` | No - Wave 0 |
| CHN-02 | Missing/unrecorded/oversized upstream output returns explicit error and leaves repairable state. | integration | `mix test test/oban_powertools/chain_output_test.exs` | No - Wave 0 |

### Sampling Rate

- **Per task commit:** targeted file command for the edited module.
- **Per wave merge:** `mix test test/oban_powertools/batch_insert_stream_test.exs test/oban_powertools/chain_test.exs test/oban_powertools/chain_progression_test.exs test/oban_powertools/chain_output_test.exs`
- **Phase gate:** `mix test`

### Wave 0 Gaps

- [ ] `test/oban_powertools/batch_insert_stream_test.exs` - covers BAT-02.
- [ ] `test/oban_powertools/chain_test.exs` - covers CHN-01 DSL/spec validation.
- [ ] `test/oban_powertools/chain_progression_test.exs` - covers CHN-01 callback-outbox progression.
- [ ] `test/oban_powertools/chain_output_test.exs` - covers CHN-02 durable output handoff.
- [ ] Optional migration test if batch failure metadata requires schema changes. [ASSUMED]

**Current verification run:** `mix test test/oban_powertools/batch/tracker_test.exs test/oban_powertools/job_record_test.exs test/oban_powertools/callback_test.exs` passed with 17 tests and 0 failures. [VERIFIED: command output]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No user authentication changes in Phase 61. [VERIFIED: .planning/ROADMAP.md] |
| V3 Session Management | no | No browser/session changes in Phase 61. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | no | Operator UI access control belongs to Phase 62. [VERIFIED: .planning/ROADMAP.md] |
| V5 Input Validation | yes | Validate public API options, job changesets, JSON/MFA builder specs, total count, chunk size, and linear step names with explicit errors. [VERIFIED: lib/oban_powertools/workflow.ex] |
| V6 Cryptography | no | No cryptographic primitive changes in Phase 61. [VERIFIED: .planning/ROADMAP.md] |
| V8 Data Protection | yes | Do not copy upstream payloads into job args by default; use `JobRecord` and existing redaction/display-policy boundaries. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md] |
| V10 Malicious Code | yes | Do not persist anonymous functions; only allow validated MFA/builder references for dynamic args. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md] |

### Known Threat Patterns for Elixir/Oban/Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Payload leakage through downstream args | Information Disclosure | Keep only upstream job references in metadata and fetch via `JobRecord`. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md] |
| Unsafe dynamic MFA execution | Elevation of Privilege | Require explicit builder behavior or allowlisted MFA shape; reject anonymous functions and invalid modules. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md] |
| Duplicate deterministic batch id appends | Tampering | Treat existing `batch_id` as error; never append silently. [VERIFIED: .planning/phases/61-apis-batches-chains/61-CONTEXT.md] |
| Callback row hijacking across event types | Tampering / Repudiation | Event-scoped callback claiming and dedupe keys. [VERIFIED: lib/oban_powertools/workflow/runtime.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/61-apis-batches-chains/61-CONTEXT.md` - locked API decisions, examples, boundaries.
- `.planning/REQUIREMENTS.md` - BAT-02, CHN-01, CHN-02 requirements.
- `.planning/ROADMAP.md` - Phase 60 dependency context and Phase 62 UI boundary.
- `lib/oban_powertools/batch.ex` - current batch schema.
- `lib/oban_powertools/batch/tracker.ex` - existing progress and batch callback insertion logic.
- `lib/oban_powertools/callback.ex` - callback outbox schema and event validation.
- `lib/oban_powertools/job_record.ex` - durable output recording/fetching.
- `lib/oban_powertools/worker.ex` and `lib/oban_powertools/worker/hooks.ex` - `record_output` and hook semantics.
- Oban HexDocs v2.23.0 - `Oban`, `Oban.Job`, `Oban.Worker`.
- Ecto HexDocs v3.14.0 - `Ecto.Repo`, `Ecto.Multi`.

### Secondary (MEDIUM confidence)

- Oban Pro docs - Batch/composition/workflow output patterns used as ecosystem reference, not as binding implementation. [CITED: https://oban.pro/docs/pro/composition.html]
- Oban Pro v1.5 upgrade docs - current batch API direction and deprecated worker batch API. [CITED: https://oban.pro/docs/pro/v1-5.html]
- Oban Pro changelog - modern tracking/index posture. [CITED: https://oban.pro/docs/pro/changelog.html]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from `mix.deps`, HexDocs, and local environment.
- Architecture: HIGH - locked by Phase 59/60/61 context and verified against current code.
- Pitfalls: HIGH - tied to current callback dispatcher, schema fields, and Oban docs.
- Defaults/tuning: MEDIUM - `chunk_size: 1_000` should be measured under project tests before locking as permanent.

**Research date:** 2026-06-14
**Valid until:** 2026-07-14 for local architecture; re-check Oban/Ecto docs before dependency-sensitive implementation.
