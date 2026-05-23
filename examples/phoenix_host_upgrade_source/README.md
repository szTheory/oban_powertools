# PhoenixHost Upgrade Source Fixture

`examples/phoenix_host_upgrade_source` is the frozen historical source lane for supported
upgrades into the current public host contract.

## Provenance

- Historical source commit: `a1fed86`
- Source shape: native-first Phoenix host generated from `mix phx.new` with Postgres/Ecto,
  Powertools already installed, `repo` wiring present, `auth_module` wired, the host-owned
  `/ops/jobs` scope mounted, and the Powertools migrations checked in
- Intentional omission: this archived fixture stays pre-`display_policy`, so
  `config/config.exs` does not declare
  `display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy`

## Supported upgrade source lane

This fixture is the one supported upgrade source lane. It represents the singular historical
host posture that current upgrade guidance is allowed to claim:

- `config :oban_powertools` already points at `repo: PhoenixHost.Repo`
- `config :oban_powertools` already points at
  `auth_module: PhoenixHostWeb.ObanPowertoolsAuth`
- the host owns `scope "/ops/jobs"` and mounts
  `ObanPowertools.Web.Router.oban_powertools_routes("/oban")`
- Powertools migrations are already present under `priv/repo/migrations`
- the seed story is intentionally narrow: operator `ops-demo` and cron entry `nightly_sync`

Anything outside that lane is best-effort rather than supported:

- bridge-enabled source hosts with behavior beyond the checked-in `/ops/jobs/oban` mount shape
- manually diverged or partially adopted hosts
- hosts missing `repo`, `auth_module`, or the host-owned `/ops/jobs` scope

## Maintainer regeneration

`./regenerate.sh` is a maintainer-only provenance helper. It rebuilds the installer-owned
baseline from commit `a1fed86`, reapplies the checked-in host-owned follow-up files needed for
this archived fixture, and leaves the result outside the normal PR proof path.

Normal CI and contract proof lanes do not run the historical replay helper. The checked-in
fixture is the auditable source of truth for the supported upgrade source lane.
