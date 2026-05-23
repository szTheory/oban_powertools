# PhoenixHost

`examples/phoenix_host` is the canonical curated current-state fixture for the public host
contract.
It is not a polished showcase app. It exists to prove one honest install-to-first-session
lane and to keep the host/library ownership boundary reviewable.

`examples/phoenix_host_upgrade_source` is a separate frozen historical fixture. It exists only
for the singular supported upgrade lane and should not replace this current-state fixture when
you want to inspect the live public host contract.

## What this fixture proves

- a canonical host-owned `/ops/jobs` shell around Powertools routes
- a migration-complete fixture that resets into base Oban plus Powertools tables
- explicit `auth_module: PhoenixHostWeb.ObanPowertoolsAuth`
- explicit `display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy`
- one narrow first-session seed lane: operator `ops-demo` and cron entry `nightly_sync`
- the optional read-only `/ops/jobs/oban` bridge when `oban_web` is present

Native Powertools pages own audited mutations. The optional bridge is read-only inspection,
not mutation parity.

## Local run

```bash
mix deps.get
MIX_ENV=test mix ecto.reset
mix phx.server
```

Open `http://localhost:4000/ops/jobs`.

## Seeded first-session state

The fixture seeds only the operator-visible state required for one honest first session:

- actor id: `ops-demo`
- actor label: `ops-demo`
- actor role: `ops`
- native cron resource: `nightly_sync`

That seed set is intentionally narrow. It supports opening `/ops/jobs`, previewing a native
cron action, executing it, and inspecting durable audit evidence without implying broader
demo coverage.

## Provenance Buckets

This checked-in fixture is support-truth aligned today, but it is still a curated fixture.
Use the three buckets below when explaining where each part came from.

### 1. `mix phx.new`

Phoenix generated the baseline host tree:

- project scaffolding, endpoint, repo, and tests
- host application supervision shape
- default browser pipeline and Phoenix file layout

### 2. `mix oban_powertools.install`

The installer-generated bucket is the Powertools-owned starting point:

- `config :oban_powertools` wiring for `repo`, `auth_module`, and `display_policy`
- the nested Powertools route mount inside the host-owned `/ops/jobs` scope
- the checked-in Powertools migration set represented in `priv/repo/migrations`

### 3. Manual Host-Owned Follow-Up

These pieces remain deliberate manual follow-up owned by the host app:

- the real `auth/session` lookup and authorization policy
- the real `display_policy` and redaction posture
- any host login UX or operator-role assignment
- the exact seed data and support-truth wording for this curated fixture

`regenerate.sh` rebuilds the first two buckets and leaves explicit TODO markers for this
manual host-owned follow-up. Stricter end-to-end generation is a later tightening step;
this fixture is intentionally honest about that gap today.

## Operational Caveats

Mounted operator pages only behave as documented when the host has already wired its own
runtime and browser seams correctly:

- reverse-proxy forwarding must preserve the request shape Phoenix and LiveView expect
- WebSocket transport must be available for LiveView pages
- host auth/session wiring must already be correct before Powertools pages or the bridge mount

If reverse-proxy forwarding is wrong, WebSocket transport is blocked, or auth/session wiring
is incomplete, the native pages and the read-only bridge will not behave as documented.
