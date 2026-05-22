# Installation

This is the exact day-0 path for a Phoenix host app. The library owns internal pages and runtime
helpers. Your host owns auth, display policy, the outer router scope, and the database migrations
it runs.

## 1. Add Dependencies

Add Oban Powertools to your host app. Add `oban_web` only if you want the nested read-only bridge
at `/ops/jobs/oban`.

```elixir
def deps do
  [
    {:oban_powertools, "~> 0.1.0"},
    {:oban_web, "~> 2.10", optional: true}
  ]
end
```

## 2. Run the Installer

Run the generator-backed installer:

```bash
mix oban_powertools.install
```

The installer adds starter host wiring for `repo` and `auth_module`, creates Powertools
migrations, and mounts the library route tree under a host-owned `/ops/jobs` scope. It does not
scaffold a display policy for you.

## 3. Add the Required Host Runtime Config

Keep the generated `repo` and `auth_module`, then add the explicit display policy step before
mounting policy-sensitive native pages:

```elixir
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

`auth_module` is host-owned. `display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy` is also
host-owned and required before native pages render policy-sensitive values.

## 4. Confirm the Router Mount

Your host owns the outer browser scope. The library owns only the nested routes mounted inside it:

```elixir
scope "/ops/jobs" do
  pipe_through(:browser)

  require ObanPowertools.Web.Router
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

That mount gives you native Powertools pages at `/ops/jobs` and the optional read-only bridge at
`/ops/jobs/oban`.

## 5. Run the Generated Migrations

`mix oban_powertools.install` generates migrations for audit, idempotency, limiters, cron,
workflow, and lifeline tables. Run them in your host app:

```bash
mix ecto.migrate
```

## 6. Optional `oban_web` Dependency

`oban_web` is optional. If you install it, Powertools mounts the nested bridge at
`/ops/jobs/oban`. That bridge remains read-only and narrower than the native Powertools pages.

## 7. Continue to the First Operator Session

Move on to [First Operator Session](first-operator-session.md) once the host can compile, migrate,
and boot with the config and router contract above.
