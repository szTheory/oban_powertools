# Support Truth And Ownership Boundaries

This project is intentionally explicit about which side owns which behavior.

## Host owns

- host owns router scope
- browser pipeline in front of `/ops/jobs`
- auth implementation
- runtime config
- display policy
- reverse-proxy, WebSocket, and auth/session behavior ahead of the mount

## Library owns

- nested Powertools routes
- native pages
- runtime helpers and adapters
- bounded bridge plumbing

## Support truth

- native pages own audited mutations
- the optional `/ops/jobs/oban` bridge is read-only
- the host contract stays explicit instead of relying on hidden defaults
