# ObanPowertools

Oban Powertools is a host-owned operations layer for Oban-backed Phoenix applications. The
library owns internal runtime helpers, native pages, and bridge adapters. The host app owns
router scope, browser pipeline, auth, display policy, runtime config, and seeded operator data.

## 60-Second Install

Start from a fresh Phoenix host, then add Oban Powertools. `oban_web` stays optional and only
enables the nested read-only bridge at `/ops/jobs/oban`.

```bash
mix phx.new my_app --database postgres
```

```elixir
def deps do
  [
    {:oban_powertools, "~> 0.1.0"},
    {:oban_web, "~> 2.10", optional: true}
  ]
end
```

Run the installer after adding the dependency:

```bash
mix oban_powertools.install
```

The installer generates migrations, a host auth seam, and a host display-policy seam:
`MyAppWeb.ObanPowertoolsAuth` and `MyAppWeb.ObanPowertoolsDisplayPolicy`.

```elixir
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

The host owns those modules. They are starter seams, not production-ready policy implementations.

Run the generated migrations, then mount the Powertools route tree inside a host-owned browser
scope:

```elixir
scope "/ops/jobs" do
  pipe_through(:browser)

  require ObanPowertools.Web.Router
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

Native Powertools pages then mount at `/ops/jobs`, and the optional `oban_web` bridge mounts at
`/ops/jobs/oban` when `oban_web` is installed.

Before calling day-0 setup complete, make the generated host pass the bounded proof threshold:

```bash
mix compile
mix ecto.migrate
mix phx.server
```

`mix ecto.reset` is the equivalent reset path when you want a clean local proof run. The first
successful operator session starts only after that compile, migrate or reset, and boot check has
passed and a real native mutation succeeds.

## Support Truth

- The host owns the outer `/ops/jobs` shell, browser pipeline, auth module, display policy, and
  runtime config.
- The optional `/ops/jobs/oban` bridge is read-only.
- Native Powertools pages own audited mutations.
- `oban_web` is optional and narrower than the native Powertools surface.

## Guides

- [Installation](guides/installation.md) covers the exact host-owned setup path, including
  `ObanPowertoolsAuth`, `ObanPowertoolsDisplayPolicy`, and the compile/migrate/boot threshold.
- [First Operator Session](guides/first-operator-session.md) walks from install to the canonical
  `ops-demo` -> `pause_cron_entry` on `nightly_sync` proof and the read-only bridge.
- [Example App Walkthrough](guides/example-app-walkthrough.md) points to the canonical fixture at
  `examples/phoenix_host`.

## Canonical Example Host

The canonical curated host fixture lives at `examples/phoenix_host`. It is the public reference
path for `mix phx.new` plus `mix oban_powertools.install`, not a fully generated demo app.
