# Support Truth And Ownership Boundaries

This project is intentionally explicit about which side owns which behavior. The public contract
uses five support-truth buckets everywhere: `supported`, `tested`, `best-effort`, `host-owned`,
and `intentionally unsupported`.

## supported

- the native `/ops/jobs` shell is the supported operator surface
- native Powertools pages are the supported mutation surface
- the optional `/ops/jobs/oban` bridge is supported only as a read-only inspection annex
- the host-owned integration contract is supported when the documented seams are explicit
- the singular upgrade lane from `examples/phoenix_host_upgrade_source` to the current contract
  is supported

## tested

- the fresh-host install path
- the canonical current-state fixture at `examples/phoenix_host`
- the first-session proof for `ops-demo`, `nightly_sync`, and `pause_cron_entry`
- the optional bridge render lane at `/ops/jobs/oban`
- the docs-contract lane
- the singular `upgrade-proof` lane backed by `examples/phoenix_host_upgrade_source`

## best-effort

- semver-allowed combinations outside tested lanes
- bridge-enabled or otherwise diverged source hosts
- bespoke host shells beyond the documented `/ops/jobs` mount shape
- unusual reverse-proxy, session, or WebSocket setups
- bridge behavior beyond the bounded read-only contract

## host-owned

- router scope in front of `/ops/jobs`
- browser pipeline in front of `/ops/jobs`
- auth implementation and authorization policy
- actor and session lookup
- runtime config
- display policy and redaction posture
- reverse-proxy, WebSocket, and auth/session behavior ahead of the mount
- seeded operator data and whether the optional bridge is exposed in production

## intentionally unsupported

- using the bridge as a mutation surface alongside native Powertools pages
- hidden fallback behavior when required config is missing
- non-Postgres support
- broad compatibility promises outside verified lanes

## library-owned implementation

- nested Powertools routes
- native pages
- runtime helpers and adapters
- bounded bridge plumbing

The library keeps those internals explicit, but they do not change the host-owned ownership
split above. The host contract stays explicit instead of relying on hidden defaults.
