# 1.0 Upgrade & Compatibility

This guide documents the supported upgrade lane for transitioning from **0.5.x to 1.0.0**. It starts from a real Phoenix host shape that
already runs Oban Powertools 0.5.x natively at `/ops/jobs`, then upgrades that host to the 1.0.0 public contract without guessing at hidden seam changes.
That contract is the unified native `/ops/jobs` control plane, with `/ops/jobs/oban` kept as a narrower read-only bridge.

## Supported Source Lane (0.5.x)

The supported source lane is a Phoenix host generated from `mix phx.new` with:

- Postgres and Ecto already in place
- Oban Powertools 0.5.x already installed
- `repo: MyApp.Repo` already configured
- `auth_module: MyAppWeb.ObanPowertoolsAuth` already configured
- the host-owned `/ops/jobs` scope already mounted
- Powertools migrations already present in the host app
- `display_policy` still missing

This is the only source host shape that the upgrade proof and this guide claim directly.

## Exact Upgrade Actions to 1.0.0

To cross the 1.0 threshold, the following host actions are required:

1. Add the host-owned display policy module:

```elixir
defmodule MyAppWeb.ObanPowertoolsDisplayPolicy do
  @behaviour ObanPowertools.DisplayPolicy

  def display(_kind, _value, _context), do: nil
end
```

2. Wire that module into `config :oban_powertools`:

```elixir
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

3. Re-check that the host still mounts the library inside the host-owned `/ops/jobs` scope and
   browser pipeline.
4. Choose whether to keep the optional `oban_web` dependency enabled for the read-only
   `/ops/jobs/oban` annex.
5. Run the current Powertools migrations.
6. Prove one native post-upgrade operator action: operator `ops-demo` reaches the native cron
   surface and uses `pause_cron_entry` on `nightly_sync`.

The executable `upgrade-proof` lane performs those same host updates, then proves the native
`ops-demo` -> `pause_cron_entry` on `nightly_sync` threshold.

## Repo-Local Historical Compatibility Proof

The singular supported host upgrade lane stays narrow on purpose. Broader continuity checks for
legacy waiting, retrying, cancelling, and recovery evidence run as repo-local library proof only.

Those checks verify stored workflow meaning remains explainable on the compatibility path without
promoting additional host shapes or upgrade histories into the supported lane.

## Support Truth

| Bucket | Meaning |
|--------|---------|
| supported | The native `/ops/jobs` shell, the host-owned integration contract, and this singular upgrade lane are supported. |
| tested | CI proves the fresh-host install lane, the native-first lane, the first-session lane, the optional read-only bridge lane, docs markers, this upgrade-proof lane, and repo-local historical workflow compatibility proof. |
| best-effort | Bridge-enabled source hosts, diverged hosts, partially adopted hosts, and hosts missing `repo`, `auth_module`, or `/ops/jobs` are best-effort. |
| host-owned | Auth, session lookup, router scope, browser pipeline, reverse proxy behavior, actor seeding, and whether `/ops/jobs/oban` is exposed stay host-owned. |
| intentionally unsupported | Bridge write parity, hidden fallback behavior when required config is missing, and broader compatibility claims outside tested lanes are intentionally unsupported. |

## Compatibility Boundary

This guide does not describe a broad semver matrix. It documents one tested source host shape and
one deterministic upgrade threshold.

Treat these hosts as `best-effort` instead of `supported`:

- hosts that already diverged from the documented `/ops/jobs` mount shape
- hosts that enabled bridge behavior beyond the bounded read-only `/ops/jobs/oban` contract
- hosts that partially adopted Powertools without all required seams in place
- hosts missing `repo`, `auth_module`, migrations, or the host-owned `/ops/jobs` route

Treat these choices as `host-owned`:

- auth and session lookup rules
- router scope and browser pipeline composition
- reverse proxy, WebSocket, and cookie/session deployment behavior
- actor provisioning for `ops-demo`-style operator access
- whether the optional read-only bridge is exposed in production

Treat these claims as `intentionally unsupported`:

- bridge write parity with the native Powertools pages
- compatibility promises beyond the tested lane above
- fallback behavior that tries to hide missing `display_policy` or other required config

## Canonical Proof Target

After the upgrade actions complete, the proof target is still native-first:

- operator: `ops-demo`
- resource: `nightly_sync`
- action: `pause_cron_entry`

If your upgraded host cannot reach that threshold through the native `/ops/jobs` surface, it has
not yet reached the supported current contract described here.
