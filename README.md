# ObanPowertools

Oban Powertools is a host-owned operations layer for Oban-backed Phoenix applications. The
library owns internal runtime helpers, native pages, and bridge adapters. The host app owns
router scope, browser pipeline, auth, display policy, runtime config, and seeded operator data.

Oban Powertools ships a native, host-owned operator shell at `/ops/jobs`.
`oban_web` is optional; when installed, Powertools mounts a nested read-only Oban Web bridge at `/ops/jobs/oban` for additional inspection.

## 60-Second Install

Start from a fresh Phoenix host, then add Oban Powertools. The default paved road is the native
shell at `/ops/jobs`, and `oban_web` stays optional for the nested read-only bridge at
`/ops/jobs/oban`.

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

- `supported`: the native `/ops/jobs` shell is the supported operator surface, and native
  Powertools pages are the supported mutation surface.
- `supported`: the optional `/ops/jobs/oban` bridge is supported only as a narrower read-only
  inspection annex.
- `supported`: one singular upgrade lane is supported for hosts that already have Postgres/Ecto,
  `repo`, `auth_module`, `/ops/jobs`, and Powertools migrations in place and still need to add
  `display_policy`.
- `tested`: the repo proves the fresh-host install lane, the native-first fixture lane, the
  first-session lane, the optional bridge render lane, the docs-contract lane, and the supported
  upgrade lane.
- `best-effort`: best-effort outside tested lanes applies to semver-allowed combinations,
  bridge-enabled or diverged source hosts, bespoke shells, and unusual proxy or session setups.
- `host-owned`: the host owns router scope, browser pipeline, auth, actor/session lookup,
  display policy, runtime config, reverse-proxy and WebSocket behavior, seeded operator data,
  and whether the bridge is exposed in production.
- `intentionally unsupported`: using the bridge as a mutation surface, hidden fallback behavior
  when required config is missing, non-Postgres support, and broader compatibility claims
  outside verified lanes.

## Guides

- [Installation](guides/installation.md) covers the exact host-owned setup path, including
  `ObanPowertoolsAuth`, `ObanPowertoolsDisplayPolicy`, and the compile/migrate/boot threshold.
- [First Operator Session](guides/first-operator-session.md) walks from install to the canonical
  `ops-demo` -> `pause_cron_entry` on `nightly_sync` proof and the read-only bridge.
- [Support Truth And Ownership Boundaries](guides/support-truth-and-ownership-boundaries.md)
  expands the shared supported/tested/best-effort/host-owned/intentionally unsupported
  vocabulary.
- [Example App Walkthrough](guides/example-app-walkthrough.md) points to the canonical fixture at
  `examples/phoenix_host`.

## Canonical Example Host

The canonical curated host fixture lives at `examples/phoenix_host`. It is the public reference
path for `mix phx.new` plus `mix oban_powertools.install`, not a fully generated demo app.
`examples/phoenix_host_upgrade_source` exists separately only as the frozen source fixture for
the supported upgrade lane.
