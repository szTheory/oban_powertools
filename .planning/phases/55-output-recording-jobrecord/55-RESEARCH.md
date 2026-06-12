# Phase 55: Output Recording (JobRecord) - Research

**Researched:** 2026-06-12
**Domain:** Elixir/Ecto/Phoenix LiveView output recording for Oban workers
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- None listed in `.planning/phases/55-output-recording-jobrecord/55-CONTEXT.md`; the phase boundary explicitly excludes modifying `Workflow.Result`, arbitrary Elixir term serialization, public manual `record_output/2`, `{:ok, payload, record_opts}`, archiving output records before deletion, new runtime dependencies, and Phase 56 at-rest args redaction.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REC-01 | Worker can declare `record_output: true` in `use ObanPowertools.Worker` opts to opt in to persisting `{:ok, payload}` return values from `process/1`. | Worker macro and wrapper insertion points identified; Oban official return semantics confirm `{:ok, value}` is successful and value is otherwise ignored by Oban. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| REC-02 | `ObanPowertools.JobRecord` Ecto schema with `oban_powertools_job_records` table independent of `Workflow.Result`. | Existing `Workflow.Result` schema and installer migration provide the field pattern to mirror, while Context D-01/D-02 lock a separate table with no hard FK. [VERIFIED: codebase grep] |
| REC-03 | Host can retrieve latest recorded output for a job via `fetch_result/1` returning `{:ok, result}` or `{:error, :not_found}`. | Ecto schema/query APIs and `Jobs.get/2` read pattern support explicit repo-backed lookup; latest should order by `recorded_at DESC, id DESC` for deterministic retrieval. [VERIFIED: codebase grep] [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html] |
| REC-04 | Recorded output is visible in `/ops/jobs` job detail view via a new `:job_recorded` DisplayPolicy kind. | Existing `JobsLive.load_job_detail/2` assigns args/meta display through `DisplayPolicy.render_job_field/3`; add a recorded-output assign and card in the locked UI position. [VERIFIED: codebase grep] |
| REC-05 | Worker can declare `output_limit: bytes` and `output_retention: :standard | :extended | :ephemeral`. | Worker option normalization already validates `timeout:`/`deadline:` at compile time; Lifeline prune transaction and archive telemetry already centralize retention pruning. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 55 should be planned as four coordinated vertical changes: a new `ObanPowertools.JobRecord` schema/migration, a best-effort recorder inserted into the existing `ObanPowertools.Worker.perform/1` wrapper, a `/ops/jobs` detail-card integration through `DisplayPolicy`, and a Lifeline prune extension. The user has locked the public contract tightly: only `record_output: true` workers record only `{:ok, payload}`, and every recorder failure path must warn and preserve the original Oban result. [VERIFIED: codebase grep] [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]

The existing project already has the major patterns needed: `Workflow.Result` defines the durable result field set; `Worker` owns generated compile-time option validation and the only `process/1` wrapper; `JobsLive` owns job detail rendering; and `Lifeline.run_archive_prune/3` owns archive/prune accounting and telemetry. No new runtime dependency is needed; use existing Ecto, Jason, Oban, Phoenix LiveView, and Igniter surfaces. [VERIFIED: codebase grep] [VERIFIED: Hex registry]

**Primary recommendation:** Plan the phase in this order: schema/test migration + `JobRecord` API, worker recording insertion before `Hooks.after_result/3`, UI/display-policy card, Lifeline pruning and docs. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Worker opt-in option validation | API / Backend | — | `ObanPowertools.Worker.__using__/1` already validates and strips Powertools-only compile-time options before `use Oban.Worker`. [VERIFIED: codebase grep] |
| Output normalization and persistence | API / Backend | Database / Storage | The job process owns the return value; Ecto/Postgres owns durable JSONB-compatible storage. [VERIFIED: codebase grep] [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html] |
| `fetch_result/1` lookup | API / Backend | Database / Storage | Public Elixir API should query `oban_powertools_job_records` by `oban_job_id`; no browser responsibility. [VERIFIED: codebase grep] |
| `/ops/jobs` recorded-output display | Frontend Server (LiveView) | API / Backend | `JobsLive` loads job detail from `Jobs`; it should load one optional record and render policy-normalized output. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Retention pruning | API / Backend | Database / Storage | Existing Lifeline prune cycle already runs a repo transaction, updates `ArchiveRun`, and emits prune telemetry. [VERIFIED: codebase grep] |
| Installer/test migrations | Database / Storage | API / Backend | Igniter generates host migrations; test support migrations mirror shipped tables. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] |

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists at the project root, so there are no additional AGENTS.md directives to enforce. [VERIFIED: shell]

Project-local `.codex/skills/` and `.agents/skills/` directories are absent, so no project-local skill rules apply. [VERIFIED: shell]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Compile macros, run tests, build library. | Local toolchain used by the repo and required for generated worker modules. [VERIFIED: shell] |
| Oban | 2.23.0 | Worker return semantics and job schema. | Current lockfile version; official docs define `:ok`/`{:ok, value}` success and failure/cancel/snooze branches. [VERIFIED: Hex registry] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Ecto / Ecto SQL | 3.14.0 | Schema, changesets, migrations, repo operations. | Existing persistence layer; official docs cover schema mapping and migration helpers. [VERIFIED: Hex registry] [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] |
| Postgrex / PostgreSQL | Postgrex 0.22.2 / local PostgreSQL 14.17 | Postgres JSONB-compatible map storage and test database. | Project is Postgres/Ecto-native; local service is accepting connections. [VERIFIED: Hex registry] [VERIFIED: shell] |
| Jason | 1.4.5 | JSON encode and byte-count normalized payloads. | Existing dependency; official docs define `encode/2`, `encode!/2`, and error behavior for invalid input. [VERIFIED: Hex registry] [CITED: https://hexdocs.pm/jason/Jason.html] |
| Phoenix LiveView | locked 1.1.31 | Native `/ops/jobs` detail rendering. | Existing optional UI stack; `JobsLive` uses `use Phoenix.LiveView` and inline `~H` templates. [VERIFIED: Hex registry] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Igniter | locked 0.8.0 | Installer migration generation. | Existing `mix oban_powertools.install` uses `Igniter.Mix.Task` and `Igniter.Libs.Ecto.gen_migration`. [VERIFIED: Hex registry] [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | bundled with Elixir 1.19.5 | Unit/integration tests. | Add focused tests in worker, JobRecord, Lifeline, LiveView, installer, docs-contract areas. [VERIFIED: shell] |
| Telemetry | 1.4.x constraint; existing dependency | Existing Lifeline prune telemetry metadata. | Do not add a new event family; only update existing `:archive_prune_completed` `pruned_count` value through Lifeline. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `JobRecord` table | Mutate `Workflow.Result` | Rejected by Context D-01 because workflow step uniqueness/FK semantics differ from standalone job output. [VERIFIED: codebase grep] |
| JSONB-compatible map payload | `:erlang.term_to_binary`, `bytea`, Base64 envelope | Rejected by Context D-15 because operators need queryable/inspectable JSON-compatible output, not opaque term storage. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md] |
| `DisplayPolicy.workflow_result/2` | New `:job_recorded` display kind | Context D-29 locks the new kind to avoid conflating workflow step result display with standalone job output. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md] |
| New prune worker/scheduler | Existing Lifeline prune cycle | Context D-25 locks Lifeline pruning; a new scheduler would duplicate retention accounting. [VERIFIED: codebase grep] |

**Installation:**

```bash
# No new runtime packages. Use existing mix.lock dependencies.
mix deps.get
```

**Version verification:** Versions above were checked with `mix hex.info`, `mix.lock`, and local tool commands on 2026-06-12. [VERIFIED: Hex registry] [VERIFIED: shell]

## Package Legitimacy Audit

This phase installs no new external package. Existing dependencies are already locked in `mix.lock`; slopcheck was present but its current CLI does not support the requested `--json` flag, and no package install is recommended. [VERIFIED: shell]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | Hex | — | — | — | not applicable | No new package install |

**Packages removed due to slopcheck [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Worker module compile
  -> ObanPowertools.Worker.__using__/1
  -> validate record_output/output_limit/output_retention
  -> strip Powertools-only opts before use Oban.Worker
  -> expose __powertools_output_recording__/0

Oban executes job
  -> generated perform/1 validates args
  -> deadline pre-check
  -> Hooks.on_start/2
  -> process/1
     -> if {:ok, payload} and record_output true
        -> JobRecord.record(repo, worker, job, payload, settings)
           -> normalize JSON-compatible payload
           -> Jason compact encode byte count
           -> reject oversized/non-encodable with warning
           -> insert oban_powertools_job_records best-effort
     -> Hooks.after_result/3
  -> return original result to Oban

/ops/jobs detail
  -> JobsLive.load_job_detail/2
  -> Jobs.get(repo, id)
  -> JobRecord.fetch_for_job(repo, job.id)
  -> DisplayPolicy.job_recorded_display or render_job_field(:job_recorded, ...)
  -> Recorded Output card

Lifeline archive prune
  -> run_archive_prune/3 transaction
  -> archive old repair audits
  -> prune consumed previews + old heartbeats + expired JobRecords
  -> ArchiveRun.pruned_count includes JobRecords
  -> telemetry :archive_prune_completed pruned_count includes JobRecords
```

### Recommended Project Structure

```text
lib/
├── oban_powertools/
│   ├── job_record.ex             # Ecto schema, record/fetch API, payload normalization
│   ├── worker.ex                 # compile-time options and wrapper insertion
│   ├── worker/
│   │   └── output_recording.ex   # optional helper if macro code gets large
│   ├── runtime_config.ex         # DisplayPolicy :job_recorded normalization/fallback
│   ├── jobs.ex                   # optional read coordination for job detail
│   ├── lifeline.ex               # prune expired JobRecords in existing transaction
│   └── web/jobs_live.ex          # Recorded Output card
test/
├── oban_powertools/job_record_test.exs
├── oban_powertools/worker_test.exs
├── oban_powertools/lifeline_test.exs
├── oban_powertools/web/live/jobs_live_test.exs
└── support/migrations/*          # add test table
```

### Pattern 1: Best-Effort Recorder Before Success Hook

**What:** Insert recording after `process/1` returns and before `Hooks.after_result/3`. [VERIFIED: codebase grep]  
**When to use:** Only for `{:ok, payload}` and only when compile-time recording config says enabled. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]

```elixir
# Source: local worker wrapper + Oban official return semantics
result = process(job)
ObanPowertools.Worker.OutputRecording.after_result(__MODULE__, job, result)
ObanPowertools.Worker.Hooks.after_result(__MODULE__, job, result)
result
```

### Pattern 2: Schema Mirroring `Workflow.Result` Without FKs

**What:** Create `JobRecord` with binary UUID primary key, `oban_job_id` integer soft reference, result metadata fields, `timestamps(updated_at: false)`, and uniqueness on `[:oban_job_id, :attempt]`. [VERIFIED: codebase grep]  
**When to use:** Standalone job output persistence; do not associate to `Workflow.Step`. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]

```elixir
# Source: lib/oban_powertools/workflow/result.ex pattern
@primary_key {:id, :binary_id, autogenerate: true}

schema "oban_powertools_job_records" do
  field :oban_job_id, :integer
  field :worker, :string
  field :attempt, :integer, default: 1
  field :status, :string, default: "ok"
  field :payload, :map, default: %{}
  field :payload_bytes, :integer, default: 0
  field :retention, :string, default: "standard"
  field :redacted, :boolean, default: false
  field :summary, :string
  field :recorded_at, :utc_datetime_usec
  field :expires_at, :utc_datetime_usec

  timestamps(updated_at: false)
end
```

### Pattern 3: JSON-Compatible Payload Normalization

**What:** Recursively stringify map keys and preserve JSON scalar/list/map structure before encoding and insertion. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]  
**When to use:** Every payload before byte counting and `:map` storage. [CITED: https://hexdocs.pm/jason/Jason.html]

```elixir
# Source: Context D-16/D-17 + Jason official encode docs
defp normalize_payload(%{} = map) do
  Map.new(map, fn {key, value} -> {to_string(key), normalize_payload(value)} end)
end

defp normalize_payload(list) when is_list(list), do: Enum.map(list, &normalize_payload/1)
defp normalize_payload(value) when is_binary(value) or is_number(value) or is_boolean(value) or is_nil(value), do: value
defp normalize_payload(other), do: raise ArgumentError, "payload is not JSON-compatible: #{inspect(other)}"
```

### Pattern 4: DisplayPolicy Fallback Must Not Crash Page

**What:** Convert `display(:job_recorded, ...)` into a bounded map/string/default display, rescuing policy errors to a safe fallback. [VERIFIED: codebase grep]  
**When to use:** `JobsLive` recorded-output card. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]

```elixir
# Source: existing DisplayPolicy.render_job_field/3 fallback pattern
def job_recorded(record_input, context) do
  default = default_job_recorded(record_input)

  case apply_policy(:job_recorded, record_input, context) do
    nil -> default
    text when is_binary(text) -> %{default | payload: text}
    %{} = rendered -> merge_known_job_record_fields(default, rendered)
    other -> raise ArgumentError, invalid_return_message(:job_recorded, other)
  end
rescue
  _ -> %{available?: true, payload: "Recorded output hidden by display policy fallback."}
end
```

### Anti-Patterns to Avoid

- **Recording after `on_success/2`:** Success hooks may enqueue consumers that immediately call `fetch_result/1`; record first to avoid a race. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]
- **Failing the job because recording fails:** Context D-12 locks warning-only behavior for insert, conflict, encoding, and size failures. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]
- **Creating metadata-only rejection rows:** Context D-34 says oversized/non-encodable outputs normally appear as missing output in the UI; warnings/docs are the source of truth. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]
- **Joining `oban_jobs` during prune:** JobRecord retention is independent and must not wait for or block Oban pruning. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]
- **Atomizing user-controlled JSON keys:** Jason docs warn atom decoding can create atoms at runtime and pose a DoS vector; keep stored payload keys as strings. [CITED: https://hexdocs.pm/jason/Jason.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Worker execution lifecycle | New executor/supervisor/telemetry listener | Existing generated `perform/1` wrapper | The wrapper already owns args validation, deadline check, hooks, and return preservation. [VERIFIED: codebase grep] |
| JSON encoding and byte count | Custom JSON serializer | `Jason.encode!/1` or `Jason.encode/1` | Jason is existing dependency and official API reports encode errors. [VERIFIED: Hex registry] [CITED: https://hexdocs.pm/jason/Jason.html] |
| Database schema/migration | Raw SQL table creation | Ecto schema + Igniter Ecto migration pattern | Project uses Ecto-native schemas and generated migrations. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] |
| Duplicate detection | Manual pre-check-only query | Unique index + changeset `unique_constraint`/insert conflict handling | Ecto docs describe unique constraints as race-safe around insert. [CITED: https://hexdocs.pm/ecto/constraints-and-upserts.html] |
| UI policy rendering | Hard-coded payload formatting only | `DisplayPolicy` new `:job_recorded` kind with fallback | Existing args/meta and workflow-result surfaces centralize host display policy. [VERIFIED: codebase grep] |
| Retention scheduler | New cron/process | `Lifeline.run_archive_prune/3` | Existing transaction updates `ArchiveRun` and telemetry. [VERIFIED: codebase grep] |

**Key insight:** The risky work is coordination, not algorithms. Use existing Ecto/LiveView/Lifeline/Worker seams and keep all recorder failures non-fatal. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Recording Too Late
**What goes wrong:** `on_success/2` fires before output exists, so hook-triggered consumers see `{:error, :not_found}`. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]  
**Why it happens:** The current wrapper calls `Hooks.after_result/3` immediately after `process/1`; adding recording after that is the easiest edit but violates Context D-11. [VERIFIED: codebase grep]  
**How to avoid:** Insert recorder before `Hooks.after_result/3` or make `Hooks.after_result/3` call a pre-success recorder only for `{:ok, payload}`. [VERIFIED: codebase grep]  
**Warning signs:** Worker tests observe `on_success` message before `JobRecord.fetch_result/1` succeeds. [VERIFIED: codebase grep]

### Pitfall 2: Letting Recorder Errors Affect Oban Outcome
**What goes wrong:** Size/encoding/DB errors cause retry, discard, or crash despite successful work. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]  
**Why it happens:** Using `repo.insert!` or `Jason.encode!` without rescue in the wrapper. [CITED: https://hexdocs.pm/jason/Jason.html]  
**How to avoid:** Contain all recorder errors in the recorder module, log warning, return `:ok` to wrapper. [VERIFIED: codebase grep]  
**Warning signs:** A test with non-encodable payload raises or changes `perform/1` return. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]

### Pitfall 3: Ambiguous Payload Shape
**What goes wrong:** Payload retrieval returns structs, atom-keyed maps, tuples, or terms that cannot round-trip through JSONB. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]  
**Why it happens:** Storing arbitrary Elixir terms instead of normalized JSON-compatible data. [CITED: https://hexdocs.pm/jason/Jason.html]  
**How to avoid:** Normalize recursively, stringify keys, reject unsupported values, and document that `fetch_result/1` returns stored JSON-compatible payload. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]  
**Warning signs:** Tests require atom keys or struct reconstruction from `fetch_result/1`. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]

### Pitfall 4: Incorrect Prune Accounting
**What goes wrong:** Expired records are deleted but `ArchiveRun.pruned_count` and telemetry omit them, making retention runs look incomplete. [VERIFIED: codebase grep]  
**Why it happens:** Current prune count only sums previews and heartbeats. [VERIFIED: codebase grep]  
**How to avoid:** Add `pruned_job_records` to the transaction tuple and to both `ArchiveRun.pruned_count` and telemetry metadata. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]  
**Warning signs:** Lifeline test deletes JobRecords but `run.pruned_count` does not increase. [VERIFIED: codebase grep]

### Pitfall 5: DisplayPolicy Kind Confusion
**What goes wrong:** Host policy receives `:workflow_result` for standalone jobs or raising policy crashes job detail. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]  
**Why it happens:** Reusing `DisplayPolicy.workflow_result/2` directly because the shape is similar. [VERIFIED: codebase grep]  
**How to avoid:** Add explicit `:job_recorded` handling and bounded fallback copy. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]  
**Warning signs:** UI tests pass `display(:workflow_result, ...)` for jobs, or raising `display(:job_recorded, ...)` fails the LiveView. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official and local sources:

### Compile-Time Option Normalization

```elixir
# Source: lib/oban_powertools/worker.ex timeout/deadline pattern
record_output_config = Keyword.get(opts, :record_output, false)
output_limit_config = Keyword.get(opts, :output_limit, 65_536)
output_retention_config = Keyword.get(opts, :output_retention, :standard)

oban_opts =
  opts
  |> Keyword.delete(:record_output)
  |> Keyword.delete(:output_limit)
  |> Keyword.delete(:output_retention)
```

### Race-Safe Unique Attempt Handling

```elixir
# Source: Ecto constraints docs + Workflow.Result changeset pattern
%JobRecord{}
|> JobRecord.changeset(attrs)
|> repo.insert()
|> case do
  {:ok, record} -> {:ok, record}
  {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
end
```

### Lifeline Prune Extension

```elixir
# Source: lib/oban_powertools/lifeline.ex run_archive_prune/3 pattern
{pruned_job_records, _} =
  repo.delete_all(
    from(record in ObanPowertools.JobRecord,
      where: record.expires_at <= ^now,
      order_by: [asc: record.expires_at, asc: record.id],
      limit: ^batch_size
    )
  )
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Oban OSS ignores `{:ok, value}` beyond marking success | Powertools records `{:ok, payload}` only when worker opts in | Phase 55 | Adds operational output visibility while preserving Oban return semantics. [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Workflow-only durable result table | Separate standalone `JobRecord` table | Phase 55 locked context | Avoids nullable workflow FK ambiguity and incompatible unique constraints. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md] |
| Existing job detail shows Args/Meta then Errors | Insert Recorded Output card between Args/Meta and Errors | Phase 55 locked context | Operators can inspect output near inputs without burying failure evidence. [VERIFIED: codebase grep] |
| Lifeline prunes previews/heartbeats only | Lifeline also prunes expired JobRecords | Phase 55 locked context | Output retention follows the existing archive/prune operational rhythm. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Earlier milestone research mentioned `record_output/2` and `{:ok, result, record_opts}`; Phase 55 Context D-08/D-09 explicitly defers both. [VERIFIED: codebase grep] [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]
- Earlier milestone research suggested routing workflow-step records through workflow results; Phase 55 Context narrows scope to standalone `JobRecord` and says not to mutate `Workflow.Result`. [VERIFIED: codebase grep] [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `fetch_result/1` should choose the latest row by `recorded_at DESC, id DESC` if more than one row exists for a job. [ASSUMED] | Phase Requirements / Architecture Patterns | If product expects a specific attempt or only unique latest by job, planner may choose wrong query semantics; unique `(oban_job_id, attempt)` still allows multiple attempts. |
| A2 | `summary` can default to `"Result available"` or equivalent when not supplied. [ASSUMED] | Architecture Patterns / UI | If exact copy is product-sensitive, UI tests may need a different default string. |

## Open Questions

1. **Should `fetch_result/1` accept only job id or also `%Oban.Job{}`?**
   - What we know: Requirement says `fetch_result/1`; job detail has `%Oban.Job{}` and host callers likely have job ids. [CITED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep]
   - What's unclear: Exact public input type is not specified in Context. [ASSUMED]
   - Recommendation: Support both integer job id and `%Oban.Job{id: id}` in one arity if small; document both. [ASSUMED]

2. **Should `JobRecord.record/5` be public or internal?**
   - What we know: Context D-09 forbids public manual `record_output/2`, not necessarily an internal schema function. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md]
   - What's unclear: Whether HexDocs should expose low-level `record/…` or keep it `@doc false`. [ASSUMED]
   - Recommendation: Expose `fetch_result/1`; keep record insertion helper internal/undocumented for Phase 55. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | Compile and test | ✓ | Elixir 1.19.5 / Mix 1.19.5 | None needed |
| Erlang/OTP | Runtime | ✓ | OTP 28 | None needed |
| PostgreSQL server | Ecto tests | ✓ | 14.17, `pg_isready` accepting connections | None needed |
| `psql` | DB inspection/debugging | ✓ | 14.17 | Use Ecto queries if unavailable |
| `mix hex.info` | Registry/version checks | ✓ | Hex task available | Lockfile only |
| `rg` | Codebase research | ✓ | 15.1.0 | `grep` |
| `ctx7` | Context7 docs fallback | ✗ | — | Official HexDocs via web search |
| `slopcheck` | Package legitimacy | ✓ | CLI present, no `--json` support | Not needed because no new packages |

**Missing dependencies with no fallback:** none  
**Missing dependencies with fallback:** `ctx7` missing; official HexDocs were used directly. [VERIFIED: shell]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL sandbox-style repo support. [VERIFIED: codebase grep] |
| Config file | `test/test_helper.exs`, `test/support/data_case.ex`, `test/support/live_case.ex`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/oban_powertools/job_record_test.exs test/oban_powertools/worker_test.exs -x` |
| Full suite command | `mix test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| REC-01 | `record_output: true` records `{:ok, payload}` before `on_success/2`; `:ok` and non-success outcomes do not record. | unit/integration | `mix test test/oban_powertools/worker_test.exs -x` | ✅ extend existing |
| REC-02 | `JobRecord` schema, changeset, migration shape, unique attempt guard. | unit/db | `mix test test/oban_powertools/job_record_test.exs -x` | ❌ Wave 0 |
| REC-03 | `fetch_result/1` returns `{:ok, result}` or `{:error, :not_found}`. | unit/db | `mix test test/oban_powertools/job_record_test.exs -x` | ❌ Wave 0 |
| REC-04 | `/ops/jobs` detail renders available/missing recorded output and policy fallback cases. | LiveView integration | `mix test test/oban_powertools/web/live/jobs_live_test.exs -x` | ✅ extend existing |
| REC-05 | `output_limit` rejects oversize; `output_retention` computes expiry and Lifeline prunes expired records. | unit/db/integration | `mix test test/oban_powertools/job_record_test.exs test/oban_powertools/lifeline_test.exs -x` | ❌ JobRecord test, ✅ extend Lifeline |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/job_record_test.exs test/oban_powertools/worker_test.exs -x`
- **Per wave merge:** `mix test test/oban_powertools/job_record_test.exs test/oban_powertools/worker_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/jobs_live_test.exs -x`
- **Phase gate:** `mix test`

### Wave 0 Gaps

- [ ] `test/oban_powertools/job_record_test.exs` — covers REC-02, REC-03, REC-05.
- [ ] Test support migration update — add `oban_powertools_job_records` to `test/support/migrations`.
- [ ] Installer assertions — extend `test/mix/tasks/oban_powertools.install_test.exs` and host-contract tests if they assert generated migration table lists.

**Verification already run during research:** `mix test test/oban_powertools/worker_test.exs test/oban_powertools/web/live/jobs_live_test.exs test/oban_powertools/lifeline_test.exs --trace` passed with 71 tests, 0 failures. [VERIFIED: shell]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new auth | Existing LiveAuth gate already protects `/ops/jobs`; do not add new routes. [VERIFIED: codebase grep] |
| V3 Session Management | no new session behavior | Existing LiveView session/auth path remains unchanged. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Job detail remains behind `:view_job_detail`; recorded output must not bypass `DisplayPolicy`. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Compile-time option validation plus JSON-compatible payload normalization and byte cap. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md] |
| V6 Cryptography | no | No encryption or term serialization; Phase 56 redaction and encryption are out of scope/deferred. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md] |
| V8 Data Protection | yes | Best-effort operational evidence only; docs must warn against storing sensitive/large business payloads. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md] |
| V10 Malicious Code | yes | Do not decode user-controlled keys to atoms; keep JSON keys as strings. [CITED: https://hexdocs.pm/jason/Jason.html] |

### Known Threat Patterns for Elixir/Ecto/Phoenix Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sensitive data stored in recorded payload | Information Disclosure | Opt-in only, byte cap, display policy, docs warning that output recording is not redaction. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md] |
| Runtime atom exhaustion from user keys | Denial of Service | Stringify keys; never convert payload keys with `String.to_atom/1`. [CITED: https://hexdocs.pm/jason/Jason.html] |
| Oversized payload storage/TOAST bloat | Denial of Service | Enforce `output_limit` before insert; reject rather than truncate. [CITED: .planning/phases/55-output-recording-jobrecord/55-CONTEXT.md] |
| Display policy crash exposes error page | Denial of Service / Information Disclosure | Rescue policy errors and render bounded fallback copy. [VERIFIED: codebase grep] |
| SQL injection in pruning/query | Tampering | Use Ecto query bindings, not string-concatenated SQL. [CITED: https://ecto.hexdocs.pm/Ecto.Repo.html] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/55-output-recording-jobrecord/55-CONTEXT.md` — locked storage, worker, retention, UI, test, and documentation decisions.
- `.planning/REQUIREMENTS.md` — REC-01 through REC-05 requirement text.
- `.planning/ROADMAP.md` — Phase 55 goal, success criteria, dependency context.
- `.planning/STATE.md` and `.planning/PROJECT.md` — v1.7 build order, zero-new-runtime-dependency posture, support-truth constraints.
- Local code: `lib/oban_powertools/worker.ex`, `lib/oban_powertools/worker/hooks.ex`, `lib/oban_powertools/workflow/result.ex`, `lib/oban_powertools/runtime_config.ex`, `lib/oban_powertools/web/jobs_live.ex`, `lib/oban_powertools/jobs.ex`, `lib/oban_powertools/lifeline.ex`, `lib/mix/tasks/oban_powertools.install.ex`.
- Local tests: `test/oban_powertools/worker_test.exs`, `test/oban_powertools/web/live/jobs_live_test.exs`, `test/oban_powertools/lifeline_test.exs`, `test/support/migrations/2_phase_3_tables.exs`.
- Hex registry via `mix hex.info` — Oban 2.23.0, Ecto SQL 3.14.0, Jason 1.4.5, Phoenix LiveView lock/release data, Igniter 0.8.0.
- Official Oban Worker docs — `https://hexdocs.pm/oban/Oban.Worker.html`.
- Official Ecto Schema docs — `https://ecto.hexdocs.pm/Ecto.Schema.html`.
- Official Ecto Repo docs — `https://ecto.hexdocs.pm/Ecto.Repo.html`.
- Official Ecto Migration docs — `https://hexdocs.pm/ecto_sql/Ecto.Migration.html`.
- Official Jason docs — `https://hexdocs.pm/jason/Jason.html`.
- Official Phoenix LiveView docs — `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html`.

### Secondary (MEDIUM confidence)

- Official Oban Pro Worker docs — `https://oban.pro/docs/pro/Oban.Pro.Worker.html` for ecosystem comparison around recorded jobs; used only as product-pattern background because Phase 55 context locks Powertools behavior.
- `.planning/research/SUMMARY.md`, `.planning/research/FEATURES.md`, `.planning/research/ARCHITECTURE.md`, `.planning/research/PITFALLS.md`, `.planning/research/STACK.md` — prior v1.7 research, superseded where Phase 55 Context differs.

### Tertiary (LOW confidence)

- None used for recommendations.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all recommended libraries already exist in `mix.lock` and were checked through Hex/local tooling.
- Architecture: HIGH — phase context is locked and local integration points are direct.
- Pitfalls: HIGH — failure modes are explicitly called out in context and backed by local wrapper/UI/prune patterns.
- UI details: MEDIUM — placement and fields are locked, but exact display copy beyond the missing-output sentence may be refined during implementation tests.

**Research date:** 2026-06-12  
**Valid until:** 2026-07-12 for local architecture; dependency version facts should be rechecked after 2026-06-19 because Oban/Phoenix/LiveView are currently moving quickly.
