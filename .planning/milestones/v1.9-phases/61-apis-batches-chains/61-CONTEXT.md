# Phase 61: APIs (Batches & Chains) - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose developer-facing APIs for fixed-size massive batch enqueueing, linear chain composition, and durable upstream-output access. This phase clarifies the public contracts for `Batch.insert_stream/2`, `ObanPowertools.Chain`, and chain output handoff; it does not add dynamic/growable batches, nested batches, arbitrary DAG workflows, or the Phase 62 operator UI.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope & Decisions
- `.planning/ROADMAP.md` — Phase 61 scope, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — BAT-02, CHN-01, and CHN-02 definitions plus out-of-scope constraints.
- `.planning/phases/59-schemas-foundation/59-CONTEXT.md` — Dedicated batch tables, generalized callback outbox, and no separate chains table.
- `.planning/phases/60-execution-engine-tracker-hooks/60-CONTEXT.md` — Exactly-once batch progress tracking and callback failure recovery posture.

### Project Research & Product Posture
- `prompts/oban_powertools_context.md` — Clean-room product vision, composition vocabulary, batch/chain/workflow boundaries, support-truth posture, and SRE/operator concerns.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — Future `/ops/jobs/batches` operator visibility, bridge/native UI posture, and design-system constraints for Phase 62.

### Implementation Surfaces
- `lib/oban_powertools/batch.ex` — Current batch schema and status/counter fields.
- `lib/oban_powertools/batch_job.ex` — Current batch member uniqueness and job tracking.
- `lib/oban_powertools/batch/tracker.ex` — Existing progress tracking, completion status, and callback insertion logic.
- `lib/oban_powertools/callback.ex` — Generalized callback outbox schema and current allowed event vocabulary.
- `lib/oban_powertools/job_record.ex` — Durable recorded-output boundary used by chain output handoff.
- `lib/oban_powertools/worker.ex` — Worker macro, `record_output: true`, and generated `new/2` / `perform/1` behavior.
- `lib/oban_powertools/worker/hooks.ex` — Hook dispatch order and observe-only hook semantics.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Batch` / `BatchJob`: Existing schemas anchor batch rows, member uniqueness, and progress counters.
- `ObanPowertools.Batch.Tracker`: Existing hook-driven tracking already consumes `batch_id` from job meta and inserts callbacks when counts reach `total_count`.
- `ObanPowertools.Callback`: Existing outbox should be extended for chain progression metadata/events rather than replaced.
- `ObanPowertools.JobRecord`: Existing recorded-output retention, size-limit, normalization, and fetch behavior should be the durable output handoff foundation.
- `ObanPowertools.Worker`: Existing `record_output: true` worker option can be validated for output-dependent chain steps.

### Established Patterns
- Ecto/Postgres-native persistence with no Redis/libgraph dependency.
- Explicit support truth over hidden magic: failed callbacks, insert failures, and unavailable outputs must be visible and repairable.
- Worker hooks are observe-only and crash-caught; they must not become the public orchestration surface for chains.
- Public APIs should mirror idiomatic Oban/Elixir shapes: job changesets, pipeable builders, explicit repo/Oban instance options, tagged tuples, and small result structs.

### Integration Points
- `Batch.insert_stream/2` connects batch row creation, chunked `Oban.insert_all`-style insertion, member meta injection, callback configuration, telemetry, and failure status.
- `ObanPowertools.Chain.insert/2` connects explicit chain specs to first-job insertion and callback rows for next-step progression.
- `Chain.fetch_upstream_result/1` connects downstream workers to `JobRecord.fetch_result/2` using upstream references stored in job meta.
- Phase 62 `/ops/jobs/batches` UI must be able to show `insert_failed`, `callback_failed`, and output-unavailable blocked states without guessing.

</code_context>

<specifics>
## Specific Ideas

### External Ecosystem Research Consulted
- Oban core docs: job changesets, `insert_all`, transactional control, and reliability/observability posture — https://oban.hexdocs.pm/Oban.html
- Oban Worker docs: existing `Worker.new/2 |> Oban.insert()` mental model — https://hexdocs.pm/oban/Oban.Worker.html
- Oban Pro Batch docs: batch id metadata and explicit batch callbacks — https://oban.pro/docs/pro/Oban.Pro.Batch.html
- Oban Pro Composition docs: separate concepts for chains, batches, chunks, and workflows — https://oban.pro/docs/pro/composition.html
- Oban Pro Worker docs: recorded output retrieval pattern — https://oban.pro/docs/pro/Oban.Pro.Worker.html
- Sidekiq batches: loader-job/growable-batch precedent and callback footguns — https://github.com/sidekiq/sidekiq/wiki/Batches
- Celery canvas: chain/chord ergonomics and result-backend footguns — https://docs.celeryq.dev/en/stable/userguide/canvas.html
- Rails Active Job bulk enqueue: bulk enqueue as fewer datastore round trips and backend-specific support — https://guides.rubyonrails.org/active_job_basics.html
- Hangfire batches: nested batch/continuation complexity to avoid in this milestone — https://docs.hangfire.io/en/latest/background-methods/using-batches.html
- GoodJob batches: Rails/Postgres batch callback ergonomics and batch access patterns — https://github.com/bensheldon/good_job

### Research Synthesis
- What to copy: simple pipeable APIs, explicit batch/chain/workflow boundaries, durable callback state, compact result objects, and recorded-output fetch APIs.
- What to avoid: growable batch membership, callback ambiguity, payloads copied through job args, anonymous function persistence, all-or-nothing transactions for massive inserts, and hidden result-backend dependencies.
- UI/UX implication for Phase 62: show blocked/failure states in the operator console using plain status language; do not present a hanging batch as merely "running" when insertion or output handoff failed.

</specifics>

<deferred>
## Deferred Ideas

- Growable/dynamic batches and loader-job patterns remain deferred until a future milestone explicitly reopens the fixed-size batch decision.
- Nested batches, chunks, arbitrary DAG composition, and chain fan-in/fan-out remain out of Phase 61 and belong to dedicated future work if adopter demand appears.
- Full operator UI design for batch/chain blocked states belongs to Phase 62.

</deferred>

---

*Phase: 61-APIs (Batches & Chains)*
*Context gathered: 2026-06-14*
