# First Operator Session

This walkthrough takes a new host from dependency install to a first successful operator session
at `/ops/jobs`. Success is not compile, reset, or seed output alone. Success is one real native
audited mutation with durable evidence. The native `/ops/jobs` shell is the default paved road,
and `/ops/jobs/oban` is only an additional read-only inspection stop when `oban_web` is installed.

## 1. Finish the Day-0 Setup

Start from [Installation](installation.md) and confirm these host-owned steps are complete:

- `mix oban_powertools.install`
- `config :oban_powertools` includes `repo`, `auth_module: MyAppWeb.ObanPowertoolsAuth`, and
  `display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy`
- the host router mounts the library routes inside `/ops/jobs`
- `mix compile` succeeds
- `mix ecto.migrate` or `mix ecto.reset` succeeds
- one bounded boot check via `mix phx.server` succeeds

## 2. Seed an Operator Actor

Seed at least one operator account or session fixture in your host app. The goal is a real actor
that your `auth_module` can read and authorize for native operator actions.

The canonical proof actor is `ops-demo`. The canonical proof target is the native cron entry
`nightly_sync`.

For a first session, give the seeded actor enough access to:

- open `/ops/jobs`
- inspect the native pages
- perform at least one audited mutation on a native Powertools page

## 3. Start the Host and Open `/ops/jobs`

Boot the Phoenix host:

```bash
mix phx.server
```

Visit `/ops/jobs`. This is the native Powertools shell. It should render through your host-owned
browser pipeline, your host-owned auth module, and your host-owned display policy.

## 4. Complete One Native Audited Mutation

Use one native Powertools page to perform an audited mutation. The canonical proof is
`pause_cron_entry` on `nightly_sync` as operator `ops-demo`.

This matters because the native pages are the supported mutation surface:

- every audited mutation goes through the host-owned auth seam
- display and redaction still flow through your `display_policy`
- audit evidence stays with the native Powertools operator flow

## 5. Check the Optional Bridge Boundary

If `oban_web` is installed, open `/ops/jobs/oban` after the native `ops-demo` ->
`pause_cron_entry` on `nightly_sync` proof succeeds.

That route is an additional read-only inspection stop. It shares the same host-owned actor and
display seams, but it is not a mutation equivalent. Use it for bounded inspection. Keep audited
mutation work on the native Powertools pages.

## 6. What Success Looks Like

Your first operator session is successful when:

- `/ops/jobs` renders for the seeded operator
- operator `ops-demo` completes native action `pause_cron_entry` on `nightly_sync`
- durable audit evidence records that native mutation
- `/ops/jobs/oban` is available only when `oban_web` is installed
- `/ops/jobs/oban` remains read-only

## 7. Compare Against the Canonical Host

If your host differs from the paved road, compare it against the generated fixture walkthrough in
[Example App Walkthrough](example-app-walkthrough.md).
