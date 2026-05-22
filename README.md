# ObanPowertools

Oban Powertools is a host-owned operations layer for Oban-backed Phoenix applications. The
library owns internal runtime helpers, native pages, and bridge adapters. The host app owns
router scope, browser pipeline, auth, display policy, runtime config, and seeded operator data.

## 60-Second Install

Add Oban Powertools to your host. `oban_web` stays optional and only enables the nested
read-only bridge at `/ops/jobs/oban`.

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

The installer generates migrations and starter host wiring for `repo` and `auth_module`. The
host must still add `display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy` before mounting
policy-sensitive native pages.

```elixir
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

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

## Support Truth

- The host owns the outer `/ops/jobs` shell, browser pipeline, auth module, display policy, and
  runtime config.
- The optional `/ops/jobs/oban` bridge is read-only.
- native Powertools pages own audited mutations.
- `oban_web` is optional and narrower than the native Powertools surface.

## Guides

- [Installation](guides/installation.md) covers the exact host-owned setup path, including
  `display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy`.
- [First Operator Session](guides/first-operator-session.md) walks from install to a first
  successful `/ops/jobs` session and the read-only bridge.
- [Example App Walkthrough](guides/example-app-walkthrough.md) points to the canonical fixture at
  `examples/phoenix_host`.

## Canonical Example Host

The canonical generated host fixture lives at `examples/phoenix_host`. It is the public reference
path for `mix phx.new` plus `mix oban_powertools.install`, not a hand-built demo app.
