# ObanPowertools

Oban Powertools is a host-owned operations layer for Oban-backed Phoenix applications. The
library owns internal runtime helpers, native pages, and bridge adapters. The host app owns
router scope, browser pipeline, auth, display policy, runtime config, and seeded operator data.

Oban Powertools ships a unified native `/ops/jobs` control plane at `/ops/jobs`.
`oban_web` is optional; when installed, Powertools mounts a nested read-only Oban Web bridge at `/ops/jobs/oban` for additional inspection.
The native pages are `Powertools-native` surfaces for `Audited action`, while the bridge remains `Inspection only`.
The diagnosis-first overview, cross-surface audit follow-up, and bounded native actions all belong to that same native control plane story.

> **0.x stability window:** This library is published at `0.x` on Hex. There is no API freeze yet
> — public surfaces may change before `1.0`. The internal `v1.x` planning milestone numbers
> (v1.5, v1.6, etc.) track shipped tranches of work and do **not** map to published Hex versions.
> Oban Powertools is stable. Adopt `~> 1.0`.

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
    {:oban_powertools, "~> 1.0"},
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
- `supported`: `Powertools-native` surfaces own diagnosis-first wording, legal next action, venue, and durable audit evidence.
- `supported`: the canonical forensics handoff path is `/ops/jobs` -> `/ops/jobs/forensics` -> ownership-labeled next path -> `/ops/jobs/audit`.
- `supported`: the optional `/ops/jobs/oban` bridge is supported only as a narrower read-only
  inspection annex and stays explicitly `Inspection only`.
- `supported`: forensics labels are explicit support-truth boundaries; `partial evidence`,
  `history unavailable`, and `unknown` mean operators should treat certainty as bounded.
- `host-owned`: downstream escalation and provider delivery outcomes remain host-owned follow-up.
- `supported`: one singular upgrade lane is supported for hosts that already have Postgres/Ecto,
  `repo`, `auth_module`, `/ops/jobs`, and Powertools migrations in place and still need to add
  `display_policy`.
- `tested`: the repo proves the fresh-host install lane, the native-first fixture lane, the
  first-session lane, the optional bridge render lane, the docs-contract lane, and the supported
  upgrade lane. Broader legacy workflow compatibility for waiting, retrying, cancelling, and
  recovery evidence is repo-local `tested` proof, not an expansion of the supported host lane.
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
  `ops-demo` -> `pause_cron_entry` on `nightly_sync` proof, forensic confirmation, audit follow-up,
  and the read-only bridge.
- [Forensics And Runbook Handoffs](guides/forensics-and-runbook-handoffs.md) is the canonical
  v1.4 journey and ownership contract for `/ops/jobs/forensics` and `/ops/jobs/audit`.
- [Example App Walkthrough](guides/example-app-walkthrough.md) points to the canonical fixture at
  `examples/phoenix_host`.
- [Workers And Idempotency](guides/workers-and-idempotency.md) shows how to build typed workers
  and what `enqueue/2` guarantees.
- [Limits And Explain](guides/limits-and-explain.md) covers limiter declarations, blocked
  outcomes, and blocker inspection.
- [Workflows](guides/workflows.md) explains the durable DAG builder, dependency release, and
  current runtime semantics.
- [Lifeline And Repairs](guides/lifeline-and-repairs.md) covers heartbeat projection, incident
  diagnosis, repair preview, and audited execution.
- [Policy Integration Patterns](guides/policy-integration-patterns.md) shows how the host auth
  and display seams should be shaped in a real Phoenix app.
- [Optional Oban Web Bridge](guides/optional-oban-web-bridge.md) defines the bounded
  `/ops/jobs/oban` read-only annex for generic inspection only.
- [Support Truth And Ownership Boundaries](guides/support-truth-and-ownership-boundaries.md)
  expands the shared supported/tested/best-effort/host-owned/intentionally unsupported
  vocabulary.
- [Powertools vs. Oban Pro](guides/powertools-vs-oban-pro.md) provides a definitive feature
  comparison, including Batches, Chains, Dynamic Cron, Limiters, Lifeline, and the Native UI.

## Canonical Example Host

The canonical curated host fixture lives at `examples/phoenix_host`. It is the public reference
path for `mix phx.new` plus `mix oban_powertools.install`, not a fully generated demo app. The
tracked source tree is the config, lib, migrations, seeds, static assets, and focused tests that
keep the documented host contract reviewable. Local build artifacts and vendored dependencies are
not part of that public contract.
`examples/phoenix_host_upgrade_source` exists separately only as the frozen source fixture for
the supported upgrade lane.
