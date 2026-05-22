# Installation

This is the exact day-0 path for a Phoenix host app. The library owns internal pages and runtime
helpers. Your host owns auth, display policy, the outer router scope, and the database commands it
runs.

## 0. Start From A Fresh Phoenix Host

The paved road starts from a real Phoenix app:

```bash
mix phx.new my_app --database postgres
```

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

The installer adds starter host wiring for `repo`, `auth_module`, and `display_policy`, creates
Powertools migrations, and mounts the library route tree under a host-owned `/ops/jobs` scope.
The generated `MyAppWeb.ObanPowertoolsAuth` and `MyAppWeb.ObanPowertoolsDisplayPolicy` modules are
thin starter seams owned by the host app.

## 3. Add the Required Host Runtime Config

Keep the generated `repo`, `auth_module`, and `display_policy` wiring in place:

```elixir
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

`auth_module: MyAppWeb.ObanPowertoolsAuth` is host-owned. `display_policy:
MyAppWeb.ObanPowertoolsDisplayPolicy` is also host-owned and required before native pages render
policy-sensitive values. Neither starter seam should be treated as a finished production policy.

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

## 5. Compile The Generated Host Once

Before calling installation successful, compile the generated host:

```bash
mix compile
```

## 6. Run The Required Database Path

`mix oban_powertools.install` generates migrations for audit, idempotency, limiters, cron,
workflow, and lifeline tables. Run them in your host app:

```bash
mix ecto.migrate
```

Use `mix ecto.reset` instead when you want a clean local reset plus seeds. The day-0 contract is
not complete until one of those database paths succeeds.

## 7. Boot The Host Once

Run one bounded boot check before the first operator action:

```bash
mix phx.server
```

If the host boots and `/ops/jobs` renders through your browser pipeline, auth seam, and display
policy seam, the paved road is ready for the first native session.

## 8. Optional `oban_web` Dependency

`oban_web` is optional. If you install it, Powertools mounts the nested bridge at
`/ops/jobs/oban`. That bridge remains read-only and narrower than the native Powertools pages.

## 9. Continue To The First Operator Session

Move on to [First Operator Session](first-operator-session.md) once the host can compile, migrate,
and boot with the config and router contract above.
