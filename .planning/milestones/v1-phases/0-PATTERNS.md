# Phase 0: Foundation & Bridge - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 5
**Analogs found:** 0 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/oban_powertools.install.ex` | utility | file-I/O | none | none |
| `priv/repo/migrations/[timestamp]_create_oban_powertools_audit_events.exs` | migration | CRUD | none | none |
| `lib/oban_powertools/auth.ex` | interface | request-response | none | none |
| `lib/oban_powertools/web/router.ex` | route | request-response | none | none |
| `lib/oban_powertools/telemetry.ex` | utility | event-driven | none | none |

## Pattern Assignments

Since the project is entirely greenfield, no direct analogs exist in the codebase yet. Patterns below follow standard Elixir/Phoenix ecosystem conventions and the szTheory SaaS-in-a-Box DNA outlined in `0-CONTEXT.md` and `ARCHITECTURE.md`.

### `lib/mix/tasks/oban_powertools.install.ex` (utility, file-I/O)

**Analog:** Standard Igniter Task Pattern

**Core Pattern:**
```elixir
defmodule Mix.Tasks.ObanPowertools.Install do
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :oban_powertools,
      dependencies: ["ecto.sql", "telemetry"],
      positional: [],
      schema: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter, _argv) do
    igniter
    # |> Igniter.Project.Deps.add_dep({:oban_powertools, "~> 0.1"}) # (If acting as a generator from outside)
    |> inject_migration()
    |> inject_router_scope()
    |> generate_auth_module()
  end
  
  # ... helper functions for injection
end
```

### `priv/repo/migrations/..._create_oban_powertools_audit_events.exs` (migration, CRUD)

**Analog:** Standard Ecto Migration Pattern

**Core Pattern:**
```elixir
defmodule Repo.Migrations.CreateObanPowertoolsAuditEvents do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_audit_events) do
      add :actor_id, :string, null: false
      add :action, :string, null: false
      add :resource, :string
      add :metadata, :map, default: %{}

      timestamps()
    end
    
    create index(:oban_powertools_audit_events, [:actor_id])
    create index(:oban_powertools_audit_events, [:action])
  end
end
```

### `lib/oban_powertools/auth.ex` (interface, request-response)

**Analog:** Elixir Behaviour Pattern

**Core Pattern:**
```elixir
defmodule ObanPowertools.Auth do
  @moduledoc """
  Behaviour for resolving the current actor for audit logging and access control.
  """
  
  @doc "Returns the current actor map or nil from the Plug.Conn"
  @callback current_actor(Plug.Conn.t()) :: map() | nil
  
  @doc "Checks if the actor has permission to perform an action"
  @callback can?(map() | nil, atom(), map()) :: boolean()
end
```

### `lib/oban_powertools/web/router.ex` (route, request-response)

**Analog:** Phoenix Router Macro Pattern

**Core Pattern:**
```elixir
defmodule ObanPowertools.Web.Router do
  defmacro oban_powertools_routes(path) do
    quote do
      scope unquote(path), ObanPowertools.Web do
        # Detect Oban.Web.Router dynamically
        if Code.ensure_loaded?(Oban.Web.Router) do
          # Mount Oban.Web routes under /ops/jobs/oban
          # For example: Oban.Web.Router.oban_routes("/oban") 
        end
        
        # Mount native Powertools Shell routes here
      end
    end
  end
end
```

### `lib/oban_powertools/telemetry.ex` (utility, event-driven)

**Analog:** Standard `:telemetry` Emit Wrapper

**Core Pattern:**
```elixir
defmodule ObanPowertools.Telemetry do
  @moduledoc "Handles emitting telemetry events safely."

  def emit_audit_event(actor_id, action, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :operator_action, :complete],
      %{count: 1},
      %{action: action, actor_id: actor_id}
    )
  end
end
```

## Shared Patterns

### Error Handling
**Source:** Standard Ecto / Elixir
**Apply to:** All database and logic operations.
Pattern: Use tagged tuples `{:ok, result}` and `{:error, reason}` or valid `Ecto.Changeset` returns. Do not raise exceptions for control flow.

### Telemetry Naming
**Source:** Standard OTP Conventions `[:app_name, :domain, :action]`
**Apply to:** `ObanPowertools.Telemetry` and core instrumented functions.

## No Analog Found

Files with no close match in the codebase (project is greenfield):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/mix/tasks/oban_powertools.install.ex` | utility | file-I/O | No existing Elixir codebase. |
| `priv/repo/migrations/..._create_oban_powertools_audit_events.exs` | migration | CRUD | No existing migrations. |
| `lib/oban_powertools/auth.ex` | interface | request-response | No existing files. |
| `lib/oban_powertools/web/router.ex` | route | request-response | No existing web layer. |
| `lib/oban_powertools/telemetry.ex` | utility | event-driven | No existing utility layer. |

## Metadata

**Analog search scope:** `/Users/jon/projects/oban_powertools/**/*.ex`
**Files scanned:** 0
**Pattern extraction date:** 2024-05-18
