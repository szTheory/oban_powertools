# ObanPowertools

Oban Powertools is a host-owned operations layer for Oban-backed Phoenix applications. The
library owns the internal runtime helpers, pages, and telemetry wrappers; the host app owns
installation, config, router scope, browser pipeline, and policy implementation.

## Installation

Add Oban Powertools to your host app. `oban_web` stays optional and only enables the nested
bridge route at `/ops/jobs/oban`.

```elixir
def deps do
  [
    {:oban_powertools, "~> 0.1.0"},
    {:oban_web, "~> 2.10", optional: true}
  ]
end
```

Run the installer:

```bash
mix oban_powertools.install
```

`mix oban_powertools.install` generates the Powertools Ecto migrations the host must run for
audit, idempotency, smart-engine, workflow, and lifeline tables. The generator creates the
migration wiring; the host is responsible for running those migrations as part of installation.

Configure the host-owned runtime contract:

```elixir
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth
```

## Router Mount Contract

The host app owns the outer `/ops/jobs` scope and the browser pipeline that protects it. The
library owns the route tree mounted inside that scope.

```elixir
scope "/ops/jobs" do
  pipe_through(:browser)

  require ObanPowertools.Web.Router
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

This contract gives the host native Powertools routes at `/ops/jobs` and nested pages such as
`/ops/jobs/cron`, `/ops/jobs/limiters`, `/ops/jobs/workflows`, and `/ops/jobs/lifeline`.

If `oban_web` is installed, the library also mounts the optional bridge at `/ops/jobs/oban`.
Phase 8 freezes only that path and the shared `ObanPowertools.Web.LiveAuth` mount hook. Resolver,
redaction, and policy seams are deferred to Phase 9.

## Supervision Ownership

`ObanPowertools.Application` owns the library’s internal supervision tree. The host does not
start Powertools children directly through its own supervisor.

`ObanPowertools.Lifeline.HeartbeatWriter` starts only when the host has provided
`config :oban_powertools, repo: MyApp.Repo`. Missing repo wiring no longer crashes library boot,
but direct startup of persistence-backed services still fails fast with the shared runtime-config
setup error.

## Telemetry Contract

All public events use the `[:oban_powertools, family, event_suffix]` shape. The public
measurement key is `:count`.

| Family | Allowed metadata keys |
|--------|------------------------|
| `operator_action` | `action`, `source` |
| `limiter` | `action`, `blocker_code`, `resource`, `scope` |
| `cron` | `action`, `source`, `overlap_policy`, `catch_up_policy` |
| `workflow` | `status`, `state` |
| `lifeline` | `action`, `incident_class`, `target_type`, `outcome`, `archived_count`, `pruned_count` |

IDs, job args, preview tokens, and free-form reasons are intentionally outside the public
telemetry API. High-cardinality evidence belongs in durable tables rather than telemetry payloads.
