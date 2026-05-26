# Optional Oban Web Bridge

`oban_web` is optional. When installed, `/ops/jobs/oban` is an additive read-only inspection annex, not a co-equal operator surface.
It is the explicit `Oban Web bridge`: `Inspection only`, never the native `Audited action` surface.
The supported control plane stays the unified native `/ops/jobs` control plane, including overview and audit follow-up.

## What the bridge is

- mounted at `/ops/jobs/oban`
- read-only
- Inspection only
- powered by the same host-owned actor and display seams
- useful for inspection alongside native pages
- useful after native overview or audit context points at generic follow-up

## What the bridge is not

- not a write surface
- not native-feature parity
- not a replacement for preview-backed native operator flows
- not a replacement for the diagnosis-first overview or cross-surface audit destination

Native Powertools pages are `Powertools-native` and own `Audited action` flows.

## Host caveats that matter

- the host still owns the outer `/ops/jobs` shell
- the bridge reuses the same host-owned auth, display policy, and routing seams
- reverse-proxy forwarding must preserve websocket behavior
- mounted operator routes still depend on correct session/auth propagation
- bridge and LiveView behavior remain sensitive to host-owned browser pipeline choices
