# Phase 2: Smart Engine Limits & Cron - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 18
**Analogs found:** 10 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/worker.ex` | macro | transform | `lib/oban_powertools/worker.ex` | exact |
| `lib/oban_powertools/idempotency.ex` | service | CRUD | `lib/oban_powertools/idempotency.ex` | exact |
| `lib/oban_powertools/telemetry.ex` | utility | event-driven | `lib/oban_powertools/telemetry.ex` | exact |
| `lib/oban_powertools/auth.ex` | interface | request-response | `lib/oban_powertools/auth.ex` | exact |
| `lib/oban_powertools/web/router.ex` | route | request-response | `lib/oban_powertools/web/router.ex` | exact |
| `lib/mix/tasks/oban_powertools.install.ex` | utility | file-I/O | `lib/mix/tasks/oban_powertools.install.ex` | exact |
| `test/support/migrations/0_create_tables.exs` | migration | CRUD | `test/support/migrations/0_create_tables.exs` | exact |
| `test/support/data_case.ex` | test | CRUD | `test/support/data_case.ex` | exact |
| `lib/oban_powertools/limits/resource.ex` | model | CRUD | `lib/oban_powertools/idempotency.ex` (`Receipt`) | partial |
| `lib/oban_powertools/limits/state.ex` | model | CRUD | `lib/oban_powertools/idempotency.ex` (`Receipt`) | partial |
| `lib/oban_powertools/limits.ex` | service | CRUD | `lib/oban_powertools/idempotency.ex` | role-match |
| `lib/oban_powertools/explain.ex` | service | request-response | `lib/oban_powertools/telemetry.ex` + `lib/oban_powertools/idempotency.ex` | partial |
| `lib/oban_powertools/cron/entry.ex` | model | CRUD | `lib/oban_powertools/idempotency.ex` (`Receipt`) | partial |
| `lib/oban_powertools/cron/slot.ex` | model | CRUD | `lib/oban_powertools/idempotency.ex` (`Receipt`) | partial |
| `lib/oban_powertools/cron.ex` | service | CRUD | `lib/oban_powertools/idempotency.ex` | role-match |
| `lib/oban_powertools/web/live/*.ex` | component | request-response | none | none |
| `test/oban_powertools/limits_test.exs` / `cron_test.exs` / `explain_test.exs` | test | CRUD | `test/oban_powertools/idempotency_test.exs` | role-match |
| `test/mix/tasks/oban_powertools.install_test.exs` | test | file-I/O | `test/mix/tasks/oban_powertools.install_test.exs` | exact |

## Existing Modules Most Likely To Change

- `lib/oban_powertools/worker.ex` for `limits: [...]` declarations and callback extension points.
- `lib/oban_powertools/idempotency.ex` as the clearest in-repo `Ecto.Multi` pattern for atomic limiter reservations, cron slot claims, and snapshot writes.
- `lib/oban_powertools/telemetry.ex` for Phase 2 event-name helpers and low-cardinality metadata shaping.
- `lib/oban_powertools/web/router.ex` for native shell routes plus Oban Web bridge coexistence under `/ops/jobs`.
- `lib/mix/tasks/oban_powertools.install.ex` for new Phase 2 tables and any host wiring needed by native pages.
- `test/support/migrations/0_create_tables.exs` to mirror installer-added tables in the repo test harness.
- `test/mix/tasks/oban_powertools.install_test.exs` to pin migration contract strings for new tables.
- `lib/oban_powertools/auth.ex` only if the page/action contract needs to become more explicit; otherwise keep the behaviour stable and add consuming modules around it.

## Pattern Assignments

### `lib/oban_powertools/worker.ex` for worker macro extension points

**Analog:** [lib/oban_powertools/worker.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/worker.ex:6)

**Imports and macro setup** (lines 6-21):
```elixir
defmacro __using__(opts) do
  args_config = Keyword.get(opts, :args, [])
  oban_opts = Keyword.delete(opts, :args)
  validate_args_config!(args_config)

  fields =
    for {name, type} <- args_config do
      quote do
        field(unquote(name), unquote(type))
      end
    end

  quote do
    use Oban.Worker, unquote(oban_opts)
    @behaviour __MODULE__
    import Ecto.Changeset
```

**Core extension pattern** (lines 31-81):
```elixir
defmodule Args do
  use Ecto.Schema
  @primary_key false

  embedded_schema do
    unquote(fields)
  end
end

def validate(params) do
  %Args{}
  |> Args.changeset(params)
  |> case do
    %{valid?: true} = changeset -> {:ok, apply_changes(changeset)}
    changeset -> {:error, changeset}
  end
end

def enqueue(args, opts \\ []) do
  ObanPowertools.Idempotency.transaction(__MODULE__, args, opts)
end
```

**What to copy for Phase 2**
- Keep the `use ObanPowertools.Worker, ...` options explicit and grep-able. Add `limits:` handling beside `args:`, not in a separate DSL.
- Follow the same pattern of compile-time option extraction before `quote`; add `limits_config = Keyword.get(opts, :limits, [])` and validate it outside the quoted block.
- Keep worker-facing callbacks pure and structural. If weight/partition callbacks are introduced, define them as explicit behaviour callbacks on the generated worker module.

### `lib/oban_powertools/idempotency.ex` for Ecto schemas and `Ecto.Multi` transactions

**Analog:** [lib/oban_powertools/idempotency.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/idempotency.ex:8)

**Schema pattern** (lines 8-27):
```elixir
defmodule Receipt do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "oban_powertools_idempotency_receipts" do
    field(:worker, :string)
    field(:fingerprint, :string)
    field(:job_id, :integer)
    field(:state, :string, default: "available")
    field(:expires_at, :utc_datetime)

    timestamps()
  end
end
```

**Transactional flow pattern** (lines 52-92):
```elixir
Multi.new()
|> Multi.insert(
  :receipt,
  Receipt.changeset(%Receipt{}, %{worker: worker_name, fingerprint: fingerprint, state: "available"}),
  on_conflict: [set: [state: "available"]],
  conflict_target: [:worker, :fingerprint],
  returning: true
)
|> Multi.run(:job, fn repo, %{receipt: receipt} ->
  if is_nil(receipt.job_id) do
    job_changeset = worker_mod.new(args_map, opts)
    repo.insert(job_changeset)
  else
    {:error, :conflict}
  end
end)
|> Multi.run(:update_receipt, fn repo, %{job: job, receipt: receipt} ->
  repo.update(Receipt.changeset(receipt, %{job_id: job.id}))
end)
|> repo.transaction()
```

**Conflict and error return pattern** (lines 81-92):
```elixir
|> case do
  {:ok, %{job: job}} -> {:ok, job}
  {:error, :job, :conflict, _} -> {:conflict, existing_job}
  {:error, _name, reason, _} -> {:error, reason}
end
```

**What to copy for Phase 2**
- Use nested schema modules only if the schema is tightly scoped to a service module. If limiter/cron schemas will be public or numerous, move them into dedicated files but keep the same `use Ecto.Schema` + `changeset/2` shape.
- Model limiter reservations, cooldown changes, cron slot claims, and audit writes as one `Multi` chain per action.
- Preserve tagged-tuple flow. Do not raise for expected blocking states; return structured `{:blocked, blockers}` or `{:error, reason}` values.
- Reuse `on_conflict`, `conflict_target`, and `returning: true` as the starting point for durable slot ledgers and named limiter resources.

### New Ecto schemas for limiters and cron

**Best analog:** [lib/oban_powertools/idempotency.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/idempotency.ex:8)

**Why this is the closest match**
- It is the only real schema + changeset pattern in the repo.
- It already uses durable identifiers, string state fields, and timestamps.
- It already pairs schema validation with transactional writes.

**What to copy**
- `use Ecto.Schema` and `import Ecto.Changeset` setup from lines 8-10.
- `@primary_key {:id, :binary_id, autogenerate: true}` from line 12 for durable resources like limiter resources and cron entries.
- `changeset/2` with `cast` + `validate_required` from lines 23-27 as the baseline.

**Planner note**
- There is no in-repo analog yet for associations, embeds, enum fields, or snapshot schemas. Phase 2 will be the first place these shapes appear if used.

### `lib/mix/tasks/oban_powertools.install.ex` for installer and migration generation

**Analog:** [lib/mix/tasks/oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex:13)

**Igniter pipeline pattern** (lines 13-18):
```elixir
def igniter(igniter) do
  igniter
  |> setup_auth_module()
  |> setup_router_scope()
  |> setup_migration()
end
```

**Migration generation pattern** (lines 59-100):
```elixir
igniter
|> Igniter.Libs.Ecto.gen_migration(
  nil,
  "oban_powertools_audit_events",
  body: """
    def change do
      create table(:oban_powertools_audit_events) do
        add :actor_id, :string
        ...
      end
    end
  """
)
|> Igniter.Libs.Ecto.gen_migration(
  nil,
  "oban_powertools_idempotency_receipts",
  body: """
    def change do
      create table(:oban_powertools_idempotency_receipts, primary_key: false) do
        ...
      end
    end
  """
)
```

**Router injection pattern** (lines 45-56):
```elixir
router_contents = """
  require ObanPowertools.Web.Router
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
"""

Igniter.Libs.Phoenix.add_scope(igniter, "/ops/jobs", router_contents, [])
```

**What to copy for Phase 2**
- Keep installer growth additive through the same pipeline; add new migration generators rather than inventing a second installation path.
- Extend the router injection string instead of creating a second `/ops/jobs` scope.
- Use the same string-bodied migration pattern for limiter tables, cron tables, and blocker snapshot tables.

### `lib/oban_powertools/telemetry.ex` for naming and low-cardinality boundaries

**Analog:** [lib/oban_powertools/telemetry.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/telemetry.ex:6)

**Current event wrapper** (lines 6-14):
```elixir
def execute_operator_action(event_suffix, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute(
    [:oban_powertools, :operator_action, event_suffix],
    measurements,
    metadata
  )
end
```

**What to copy for Phase 2**
- Keep one Powertools-owned wrapper module as the only place building event names.
- Follow the same prefix style for smart-engine events, e.g. `[:oban_powertools, :limiter, :blocked]`, `[:oban_powertools, :cron, :slot_claimed]`, `[:oban_powertools, :operator_action, :previewed]`.
- Keep metadata coarse: limiter kind, blocker code, overlap policy, catch_up policy, action, source. Do not attach job ids, partition values, or raw args.

### `lib/oban_powertools/auth.ex` for auth-gated page and action checks

**Analog:** [lib/oban_powertools/auth.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/auth.ex:6)

**Behaviour contract** (lines 6-14):
```elixir
@callback current_actor(Plug.Conn.t() | map()) :: any()
@callback can_perform_action?(actor :: any(), action :: atom(), resource :: any()) :: boolean()
```

**What to copy for Phase 2**
- Keep the host-owned behaviour as the single authorization authority.
- Gate both page access and mutating actions through `current_actor/1` plus `can_perform_action?/3`.
- Pass coarse resource descriptors such as `%{type: :limiter, id: limiter_name}` or `%{type: :cron_entry, id: entry_name}` rather than raw DB structs if you want a stable auth contract.

**Missing analog**
- There is no existing `on_mount`, plug, or LiveView action helper in the repo yet. Phase 2 introduces that surface.

### `lib/oban_powertools/web/router.ex` for router and live shell integration

**Analog:** [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex:9)

**Current bridge pattern** (lines 9-23):
```elixir
defmacro oban_powertools_routes(path) do
  if Code.ensure_loaded?(Oban.Web.Router) do
    quote do
      import Phoenix.LiveView.Router, only: [live_session: 3]
      import Oban.Web.Router, only: [oban_dashboard: 1]

      live_session :oban_powertools, on_mount: [] do
        oban_dashboard(unquote(path))
      end
    end
  else
    quote do
      # Oban Web is not available, provide fallback or skip
    end
  end
end
```

**What to copy for Phase 2**
- Preserve the single macro entrypoint and the `/ops/jobs` shell concept.
- Extend this macro to mount native Powertools pages and the Oban Web bridge side by side in the same `live_session`.
- Keep dependency detection around Oban Web. Native shell routes should still compile when Oban Web is absent.

**Missing analog**
- There is no native LiveView shell/page module yet, so route-to-page wiring is a new surface.

### Test patterns

**Worker macro tests:** [test/oban_powertools/worker_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/worker_test.exs:4)
```elixir
defmodule BasicWorker do
  use ObanPowertools.Worker,
    queue: :default,
    args: [user_id: :integer, email: :string]
end

test "invalid args definitions fail at compile time" do
  assert_raise ArgumentError, ~r/expected :args/, fn ->
    Code.compile_string(...)
  end
end
```

**Transactional DB tests:** [test/oban_powertools/idempotency_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/idempotency_test.exs:11)
```elixir
assert {:ok, job} = MockWorker.enqueue(%{id: 123})
assert repo().get_by(Idempotency.Receipt, worker: inspect(MockWorker), job_id: job.id)

assert {:ok, job1} = MockWorker.enqueue(%{id: 456})
assert {:conflict, job2} = MockWorker.enqueue(%{id: 456})
```

**Installer contract tests:** [test/mix/tasks/oban_powertools.install_test.exs](/Users/jon/projects/oban_powertools/test/mix/tasks/oban_powertools.install_test.exs:9)
```elixir
source = "lib/mix/tasks/oban_powertools.install.ex" |> File.read!()
assert source =~ "create table(:oban_powertools_idempotency_receipts, primary_key: false)"
assert source =~ "create unique_index(:oban_powertools_idempotency_receipts, [:worker, :fingerprint])"
```

**Telemetry tests:** [test/oban_powertools/telemetry_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/telemetry_test.exs:5)
```elixir
:telemetry.attach("test-handler", [:oban_powertools, :operator_action, :complete], fn name, measurements, metadata, _ ->
  send(self(), {:telemetry_event, name, measurements, metadata})
end, nil)
```

**Test DB harness:** [test/support/data_case.ex](/Users/jon/projects/oban_powertools/test/support/data_case.ex:13) and [test/support/migrations/0_create_tables.exs](/Users/jon/projects/oban_powertools/test/support/migrations/0_create_tables.exs:4)
```elixir
:ok = Ecto.Adapters.SQL.Sandbox.checkout(ObanPowertools.TestRepo)
...
create table(:oban_powertools_idempotency_receipts, primary_key: false) do
```

**What to copy for Phase 2**
- For worker macro additions, add compile-time tests using `Code.compile_string/1`.
- For limiter/cron transactions, follow the existing DataCase style and assert both tuple results and durable row state.
- For installer changes, continue source-contract assertions unless a heavier Igniter integration harness is introduced.
- For telemetry, keep one test per emitted event family with attach/assert/detach.

## Shared Patterns

### Explicit worker API surface
**Source:** [lib/oban_powertools/worker.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/worker.ex:6)
**Apply to:** `limits:` declarations, weight callbacks, partition extractors
```elixir
args_config = Keyword.get(opts, :args, [])
oban_opts = Keyword.delete(opts, :args)
validate_args_config!(args_config)
```

### `Ecto.Multi` as the unit of safety
**Source:** [lib/oban_powertools/idempotency.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/idempotency.ex:55)
**Apply to:** limiter reservations, cooldown actions, cron slot claims, audit writes
```elixir
Multi.new()
|> Multi.insert(...)
|> Multi.run(...)
|> repo.transaction()
```

### Low-cardinality telemetry wrapper
**Source:** [lib/oban_powertools/telemetry.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/telemetry.ex:9)
**Apply to:** limiter, blocker, cron, and operator action events
```elixir
:telemetry.execute(
  [:oban_powertools, :operator_action, event_suffix],
  measurements,
  metadata
)
```

### Host-owned auth contract
**Source:** [lib/oban_powertools/auth.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/auth.ex:9)
**Apply to:** page guards and mutating web actions
```elixir
@callback current_actor(Plug.Conn.t() | map()) :: any()
@callback can_perform_action?(actor :: any(), action :: atom(), resource :: any()) :: boolean()
```

### Hybrid shell routing
**Source:** [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex:10)
**Apply to:** native pages plus Oban Web bridge under one shell
```elixir
if Code.ensure_loaded?(Oban.Web.Router) do
  quote do
    live_session :oban_powertools, on_mount: [] do
      oban_dashboard(unquote(path))
    end
  end
end
```

## No Analog Found

| File / Surface | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/oban_powertools/web/live/*.ex` native shell pages | component | request-response | No LiveView modules exist yet. |
| Auth `on_mount` / page guard helper | middleware | request-response | Behaviour exists, but no concrete mount or action wrapper exists yet. |
| `lib/oban_powertools/explain.ex` blocker contract and snapshot recomputation | service | request-response | No existing structured explanation API in repo. |
| Cron overlap and catch-up policy engine | service | CRUD | No scheduler or slot-ledger implementation exists yet. |
| Partitioned limiter state rows and cooldown semantics | model/service | CRUD | No limiter tables or reservation engine exist yet. |
| Unified audit writer module | service | event-driven | Audit table exists in migration only; there is no runtime schema/service module yet. |

## Metadata

**Analog search scope:** `lib/**/*.ex`, `test/**/*.exs`, `.planning/**/*.md`
**Files scanned:** 33
**Pattern extraction date:** 2026-05-19
