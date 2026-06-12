# Phase 55: Output Recording (JobRecord) - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 55 adds opt-in output recording for `ObanPowertools.Worker`.
Workers declaring `record_output: true` persist successful `{:ok, payload}`
returns into a dedicated `ObanPowertools.JobRecord` schema backed by the
`oban_powertools_job_records` table. Host code can retrieve the latest record
with `ObanPowertools.JobRecord.fetch_result/1`, and operators can inspect
recorded output on the native `/ops/jobs` job detail view through a dedicated
`:job_recorded` display-policy kind.

This phase delivers REC-01 through REC-05 only. It does not modify
`Workflow.Result`, add arbitrary Elixir term serialization, add a public
manual `record_output/2` API, add `{:ok, payload, record_opts}` worker return
semantics, archive output records before deletion, introduce new runtime
dependencies, or implement Phase 56 at-rest args redaction.

</domain>

<decisions>
## Implementation Decisions

### Storage Model
- **D-01:** Add a dedicated `ObanPowertools.JobRecord` Ecto schema and
  `oban_powertools_job_records` table. Do not generalize or mutate
  `ObanPowertools.Workflow.Result`; workflow step result uniqueness and FK
  semantics differ from standalone job output recording.
- **D-02:** Do not add a hard foreign key from `oban_powertools_job_records` to
  `oban_jobs`. Oban prunes its own table, and a hard FK would block or distort
  host pruning behavior.
- **D-03:** Use `oban_job_id` as a soft integer reference, plus `worker`,
  `attempt`, `status`, `payload`, `payload_bytes`, `retention`, `redacted`,
  `summary`, `recorded_at`, `expires_at`, and insert timestamp fields mirroring
  the useful parts of `Workflow.Result`.
- **D-04:** Add a uniqueness guard on `(oban_job_id, attempt)` so a single
  attempt cannot double-record output. If a conflict occurs, logging a warning
  and preserving the successful job result is preferable to failing the job.
- **D-05:** Add indexes for `oban_job_id`, `worker`, `status`, and
  `expires_at`. Retention pruning depends on the `expires_at` index.

### Public Worker Contract
- **D-06:** `record_output: true` is the opt-in switch. Workers that do not
  declare it never persist successful return values.
- **D-07:** In Phase 55, only `{:ok, payload}` is recorded. Plain `:ok` remains
  a successful no-output result and must not create a `JobRecord` row with
  `nil` or `%{}`.
- **D-08:** Do not add `{:ok, payload, record_opts}` in Phase 55. It is a
  Powertools-specific return shape, not an Oban worker return shape, and would
  expand the public API before there is adopter evidence for per-result
  metadata.
- **D-09:** Do not add public `record_output/2` in Phase 55. Manual recording
  introduces double-recording, transaction-truth, and ordering questions that
  should wait for v1.8 batch or adopter feedback.
- **D-10:** Validate `record_output`, `output_limit`, and `output_retention` at
  compile time in `ObanPowertools.Worker`. Strip these Powertools-only options
  before `use Oban.Worker`.

### Wrapper Ordering and Failure Semantics
- **D-11:** Recording happens after `process/1` returns `{:ok, payload}` and
  before `on_success/2` hook dispatch. This lets success hooks assume a
  successful record already exists if recording was enabled and accepted.
- **D-12:** Recording failure, insert conflict, payload encoding failure, or
  payload size rejection logs a warning and never changes the return value that
  Oban sees. No recording failure may cause retry, discard, or cancellation.
- **D-13:** `{:error, reason}`, raises/throws/exits, `:discard`,
  `{:discard, reason}`, `{:cancel, reason}`, `{:snooze, seconds}`, and unknown
  successful return shapes are not recorded in Phase 55. Failure evidence
  belongs to Oban job errors and Phase 53 hooks, not the output table.
- **D-14:** Keep the recorder internally structured so later phases can add
  record options or manual recording without replacing storage: normalize
  payload, apply compile-time output settings, insert best-effort, return the
  original Oban-compatible result.

### Payload Encoding and Limits
- **D-15:** `JobRecord.payload` stores only normalized JSONB-compatible data in
  an Ecto `:map` / Postgres JSONB column. Do not preserve arbitrary Elixir
  terms with `:erlang.term_to_binary`, `bytea`, Base64, or an opaque envelope.
- **D-16:** Normalize payloads recursively for JSONB storage: stringify map
  keys, recurse lists and maps, and pass JSON scalars through.
- **D-17:** Measure `payload_bytes` as `byte_size(Jason.encode!(normalized_payload))`
  using compact Jason output before insert.
- **D-18:** Default `output_limit` is `65_536` bytes, documented as 64 KiB.
  A worker may declare `output_limit: bytes` as a positive integer byte cap.
- **D-19:** If the normalized payload cannot be JSON-encoded, or if encoded
  bytes exceed `output_limit`, reject the recording with a warning. Do not
  truncate silently and do not insert opaque fallback payloads.
- **D-20:** `fetch_result/1` returns the stored JSON-compatible payload shape,
  not decoded Elixir structs or arbitrary terms.
- **D-21:** Document the large-output pattern explicitly: write large artifacts
  or rich domain data to host-owned storage and return a small JSON reference
  such as a domain row id, object key, or URL-safe identifier.

### Retention and Pruning
- **D-22:** `output_retention` accepts exactly `:standard`, `:extended`, or
  `:ephemeral` at compile time. Persist them as `"standard"`, `"extended"`,
  and `"ephemeral"`.
- **D-23:** Use fixed library-owned retention TTLs: `:ephemeral` = 6 hours,
  `:standard` = 7 days, `:extended` = 30 days.
- **D-24:** Compute `recorded_at = DateTime.utc_now()` at successful record
  time, and compute `expires_at` from `recorded_at` plus the selected policy
  TTL. Store both as UTC microsecond timestamps. `expires_at` should be
  non-null for `JobRecord`.
- **D-25:** Extend `Lifeline.run_archive_prune/3` to delete due JobRecords
  where `expires_at <= now`, ordered by `expires_at, id`, limited by the
  existing `batch_size`, inside the existing prune transaction.
- **D-26:** Add deleted JobRecord rows to `ArchiveRun.pruned_count` and the
  existing `:archive_prune_completed` telemetry `pruned_count`; do not add them
  to `archived_count`.
- **D-27:** Do not archive JobRecords before deletion in Phase 55. JobRecord is
  operational output visibility, not immutable audit evidence. Hosts needing
  durable business history should store it in domain tables and record a
  reference.
- **D-28:** Do not join `oban_jobs` during JobRecord pruning and do not wait for
  Oban job pruning. JobRecord retention is independent by design.

### Operator Display and DisplayPolicy
- **D-29:** Add a dedicated `:job_recorded` DisplayPolicy kind for standalone
  job recorded output. Do not call `display(:workflow_result, ...)` for job
  detail records.
- **D-30:** Reuse the useful structured display shape from workflow results
  internally, but keep the public kind and context separate. Context should
  include `%{surface: :jobs, field: :recorded, job: job}` or equivalent.
- **D-31:** Add a "Recorded Output" card on `/ops/jobs` job detail after the
  Args/Meta panels and before Errors.
- **D-32:** Available output should show result availability, summary, status,
  attempt, payload bytes, recorded timestamp, retention policy, expiry
  timestamp, and policy-rendered payload.
- **D-33:** Missing output should show honest neutral copy:
  "No recorded output found for this job." Do not say recording was disabled
  unless the system has explicit evidence.
- **D-34:** Because Phase 55 rejects oversized and non-encodable payloads
  without inserting a row, the job detail page will normally show the missing
  output state for those cases. Do not invent a metadata-only rejection row in
  Phase 55 unless planning proves it is necessary to satisfy tests; warnings
  and documentation are the source of truth for rejected recordings.
- **D-35:** Policy `nil` means safe default rendering; policy string means
  payload text with default metadata; policy map means merge known display
  fields; policy raise or invalid return must not crash the page and should
  show a bounded fallback such as "Recorded output hidden by display policy
  fallback."
- **D-36:** Redaction-specific display copy is prepared for Phase 56 but not
  implemented as at-rest output redaction in Phase 55. If a `redacted` flag is
  present, display it honestly as stored metadata, not as proof that args were
  redacted.

### Tests and Documentation
- **D-37:** Worker tests must prove `record_output: true` records `{:ok,
  payload}` before `on_success/2`, while `:ok` and non-success outcomes do not
  create records.
- **D-38:** JobRecord tests must cover `fetch_result/1`, JSONB normalization,
  payload byte counting, non-encodable rejection, oversized rejection, unique
  attempt protection, retention validation, and `expires_at` calculation.
- **D-39:** Lifeline tests must cover pruning expired JobRecords, respecting
  `batch_size`, updating `ArchiveRun.pruned_count`, and leaving
  non-expired records untouched.
- **D-40:** Job detail tests must cover available output, missing output,
  policy nil/string/map returns, invalid/raising policy fallback, and retention
  metadata rendering.
- **D-41:** Installer and test migrations must add `oban_powertools_job_records`
  consistently with existing generated migration style.
- **D-42:** Documentation must state the support-truth boundary: output
  recording is best-effort operational evidence, not business storage, not a
  transaction guarantee, and not a replacement for host-owned artifact storage.

### the agent's Discretion
- The user asked for all gray areas to be researched with subagents and for the
  agent to synthesize one coherent recommendation set. Downstream agents should
  implement the locked decisions above rather than reopening ordinary
  implementation choices.
- The agent resolved a cross-cutting ambiguity in favor of no metadata-only row
  for oversized or non-encodable outputs in Phase 55. This keeps
  `fetch_result/1` semantics simple (`{:error, :not_found}` when nothing was
  stored) and aligns with the roadmap requirement that oversized payloads are
  rejected rather than stored or truncated.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Locked Prior Decisions
- `.planning/ROADMAP.md` — Phase 55 goal, REC mapping, UI hint, and success
  criteria.
- `.planning/REQUIREMENTS.md` — REC-01 through REC-05.
- `.planning/PROJECT.md` — v1.7 milestone posture, zero-new-dependency
  constraint, native operator support-truth posture, and research-first
  decision posture.
- `.planning/STATE.md` — current milestone state and v1.7 locked decisions:
  separate `oban_powertools_job_records`, no FK to `oban_jobs`, redaction after
  fingerprint, and build order.
- `.planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md` — authoritative
  hook dispatch semantics, wrapper ordering, `on_success/2` envelope, and
  timeout/cancel support truth.
- `.planning/phases/54-deadline-timeout-pass-through/54-CONTEXT.md` —
  deadline check position before hooks/process and current worker wrapper
  integration.

### v1.7 Research
- `.planning/research/SUMMARY.md` — milestone architecture, JobRecord table,
  output recording pitfalls, no-FK decision, 64 KiB cap, and zero-new-dep
  posture.
- `.planning/research/FEATURES.md` — output recording ecosystem comparison,
  opt-in requirement, byte cap, output retention policy, and anti-features.
- `.planning/research/ARCHITECTURE.md` — JobRecord schema shape, no-FK
  rationale, display-policy extension, and migration notes.
- `.planning/research/PITFALLS.md` — output schema, unbounded payload, hook
  ordering, and retention footguns.
- `.planning/research/STACK.md` — locked dependency versions, Jason byte-count
  strategy, and no-new-library conclusion.
- `.planning/threads/2026-05-28-post-v1.5-next-milestone.md` — worker
  lifecycle milestone ordering, small byte-cap direction, and defer-encrypt
  context.

### Prompt Corpus
- `prompts/oban_powertools_context.md` — product vocabulary for recorded jobs,
  typed workers, retention/pruning, operator UX, clean-room commercial-feature
  parity, and support-truth boundaries.
- `prompts/oban-powertools-deep-research-original-prompt.md` — original
  architecture/SRE/DX lens for commercial-grade OSS job tooling.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — operator-first,
  host-owned UI strategy and display-policy/redaction cohesion.

### Code and Existing Patterns
- `lib/oban_powertools/worker.ex` — generated `perform/1`, option stripping,
  args validation, deadline guard, hook dispatch insertion point, and compile
  time validation helpers.
- `lib/oban_powertools/worker/hooks.ex` — `after_result/3` routing and
  `on_success/2` envelope that recording must precede.
- `lib/oban_powertools/worker/deadlines.ex` — existing helper-module pattern
  for keeping macro quoted code small.
- `lib/oban_powertools/workflow/result.ex` — existing durable result schema to
  mirror but not modify.
- `lib/oban_powertools/runtime_config.ex` — `DisplayPolicy.workflow_result/2`
  and `render_job_field/3` normalization/fallback patterns.
- `lib/oban_powertools/web/jobs_live.ex` — native job detail surface where the
  Recorded Output card will be loaded and rendered.
- `lib/oban_powertools/web/workflows_live.ex` — existing workflow result card
  pattern and `DisplayPolicy.workflow_result/2` usage.
- `lib/oban_powertools/jobs.ex` — read-only job query owner; likely place to
  add or coordinate recorded-output loading for job detail.
- `lib/oban_powertools/lifeline.ex` — `run_archive_prune/3`, retention status,
  archive/prune transaction, and telemetry update point.
- `lib/oban_powertools/lifeline/archive_run.ex` — `pruned_count` ledger fields
  that JobRecord pruning should update.
- `lib/mix/tasks/oban_powertools.install.ex` — Igniter migration generation
  style to extend for `oban_powertools_job_records`.
- `guides/workers-and-idempotency.md` — worker DX docs that need
  `record_output`, `output_limit`, and `output_retention` support truth.
- `guides/lifeline-and-repairs.md` — retention/prune docs that need JobRecord
  prune scope added.
- `test/oban_powertools/worker_test.exs` — worker macro, hook ordering, and
  compile-time validation tests to extend.
- `test/oban_powertools/web/live/jobs_live_test.exs` — job detail display
  policy tests to extend.
- `test/oban_powertools/lifeline_test.exs` — archive/prune tests to extend.
- `test/support/migrations/2_phase_3_tables.exs` and
  `test/support/migrations/3_phase_4_tables.exs` — existing workflow result
  and archive-run migration patterns for test schema updates.

### External and Vendored References
- `deps/oban/lib/oban/worker.ex` — Oban worker return semantics; confirms
  `{:ok, value}` is a standard success return shape.
- `deps/oban/lib/oban/queue/executor.ex` — Oban executor result normalization
  and job stop telemetry result behavior.
- `deps/oban/lib/oban/telemetry.ex` — Oban job stop metadata includes result
  ephemerally but does not persist it.
- `https://hexdocs.pm/oban/Oban.Worker.html` — official Oban worker result
  semantics.
- `https://hexdocs.pm/oban/Oban.Plugins.Pruner.html` — Oban pruning posture and
  bounded job-history expectations.
- `https://oban.pro/docs/pro/Oban.Pro.Worker.html` — clean-room public
  comparison for recorded worker output, hooks, and deadlines.
- `https://oban.pro/docs/pro/Oban.Pro.Plugins.DynamicPruner.html` — clean-room
  comparison for age-based retention policies.
- `https://github.com/sidekiq/sidekiq/wiki/Best-Practices` — JSON-simple job
  argument and durable-storage lessons.
- `https://docs.celeryq.dev/en/stable/userguide/configuration.html` — result
  backend expiry and JSON serializer support-truth comparison.
- `https://github.com/bensheldon/good_job` — Postgres-backed job table cleanup
  and operator-dashboard retention comparison.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Worker.__using__/1`: already owns Powertools option
  stripping, compile-time normalization, generated `perform/1`, and hook
  insertion. This is the correct integration point for `record_output`,
  `output_limit`, and `output_retention`.
- `ObanPowertools.Worker.Hooks.after_result/3`: centralizes success/failure
  routing. Recording should happen before this call for `{:ok, payload}`.
- `ObanPowertools.Worker.Deadlines`: good model for a small internal helper
  module. A similar `ObanPowertools.Worker.Recorder` or
  `ObanPowertools.JobRecord` helper can keep macro code readable.
- `ObanPowertools.Workflow.Result`: provides a proven field set for durable
  payload evidence and `display_input/1`, but should remain workflow-specific.
- `ObanPowertools.DisplayPolicy`: already provides host-owned policy
  extension and safe fallbacks for job args/meta and workflow results.
- `Lifeline.run_archive_prune/3`: existing transaction, ledger, and telemetry
  surface for pruning Powertools-owned operational data.

### Established Patterns
- Public telemetry remains low-cardinality; durable details live in Ecto rows
  or operator surfaces. Phase 55 does not need a new telemetry family.
- Native operator pages use compact bordered cards and honest empty states.
  The Recorded Output card should follow the existing job-detail visual system.
- Powertools-owned metadata and records are explicit and inspectable. JSONB
  payload storage fits this pattern better than opaque BEAM term storage.
- Existing docs emphasize support-truth boundaries. Output recording docs
  should be explicit that recording is best-effort operational evidence, not
  business persistence.
- Existing migration/install support is generated through Igniter and mirrored
  in test migrations. Phase 55 must update both.

### Integration Points
- `lib/oban_powertools/worker.ex`: strip and validate `record_output`,
  `output_limit`, and `output_retention`; expose internal module attributes;
  insert recording before hook dispatch for `{:ok, payload}`.
- New `lib/oban_powertools/job_record.ex`: schema, changeset, `record/3` or
  internal insert helper, payload normalization/byte counting, retention TTL,
  and `fetch_result/1`.
- `lib/oban_powertools/runtime_config.ex`: add `DisplayPolicy.job_recorded/2`
  or an equivalent normalizer around `display(:job_recorded, input, context)`.
- `lib/oban_powertools/web/jobs_live.ex`: load latest record for the job and
  render the Recorded Output card.
- `lib/oban_powertools/jobs.ex`: likely owner for read-only latest-record
  lookup used by job detail, unless `JobRecord.fetch_result/1` is used
  directly from LiveView with explicit repo.
- `lib/oban_powertools/lifeline.ex`: include due JobRecords in prune and update
  `pruned_count`.
- `lib/mix/tasks/oban_powertools.install.ex`: generate the JobRecord table
  migration for host apps.
- `guides/workers-and-idempotency.md` and `guides/lifeline-and-repairs.md`:
  document recording, limits, retention, and prune support truth.

</code_context>

<specifics>
## Specific Ideas

- Prefer a small internal recorder helper instead of growing quoted macro code.
- Use string metadata/status values in persisted rows: `"ok"`, `"standard"`,
  `"extended"`, `"ephemeral"`.
- Use `DateTime.utc_now()` and `DateTime.add/3` for retention timestamps, as in
  existing Lifeline code.
- Keep `fetch_result/1` focused on the latest successful stored payload:
  `{:ok, result}` or `{:error, :not_found}` as required.
- Use warning logs for rejected recordings with enough support context to debug
  worker, job id, attempt, byte count, configured limit, and rejection reason,
  without logging the payload itself.
- Treat the current prompt corpus as product guidance, not source material to
  copy from commercial implementations.

</specifics>

<deferred>
## Deferred Ideas

- `{:ok, payload, record_opts}` return convention — defer until real
  per-result metadata needs justify a public Powertools-specific return shape.
- Public `record_output/2` callable from inside `process/1` — defer until v1.8
  batches or adopter feedback proves manual recording semantics are needed.
- Arbitrary Elixir term serialization — defer indefinitely unless a strong
  internal-consumer use case outweighs operator inspectability and support
  safety.
- Metadata-only rows for rejected oversized or non-encodable output — defer
  unless future support requirements need durable rejection evidence.
- Archive-before-delete for JobRecord — defer unless recorded output becomes a
  formal audit/compliance artifact.
- UI retention editing — out of scope; retention policy remains library-owned
  in this phase.
- Phase 56 at-rest args redaction and output redaction propagation — separate
  next phase.

</deferred>

---

*Phase: 55-Output Recording (JobRecord)*
*Context gathered: 2026-06-12*
