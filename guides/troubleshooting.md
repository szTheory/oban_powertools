# Troubleshooting

## Fail-fast config errors

These setup errors are real runtime contract checks:

- `Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo before using persistence-backed features.`
- `Oban Powertools requires :auth_module in config :oban_powertools, auth_module: MyAppWeb.ObanPowertoolsAuth before mounting native operator pages.`
- `Oban Powertools requires :display_policy in config :oban_powertools, display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy before mounting policy-sensitive native operator pages.`

## Common operator-host issues

- Missing `repo`, `auth_module`, or `display_policy` will fail fast before the relevant native
  pages can work. Fix the config first; there is no hidden fallback path.
- `/ops/jobs` is mounted, but the host browser pipeline is wrong for the intended session/auth
  boundary. The pages may render a login loop, authorize the wrong actor, or fail to mount.
- LiveView reaches `/ops/jobs`, but reverse-proxy or ingress settings break WebSocket transport.
  The browser may load the shell and then fail on reconnects or interactive updates.
- Session/auth propagation works for normal requests but not for the mounted operator route. That
  usually means the host pipeline, plugs, or current-actor assignment differ at the `/ops/jobs`
  scope.
- Repo wiring or supervision is incomplete in the environment where operators run. Persistence-
  backed views need the host repo and the relevant application processes available.

## First places to check

- `config :oban_powertools` for `repo`, `auth_module`, and `display_policy`
- the host `/ops/jobs` router scope and its browser pipeline
- session/auth propagation into LiveView and the current-actor lookup path
- WebSocket forwarding through any reverse-proxy or ingress layer
- the environment-specific supervision tree and repo startup
