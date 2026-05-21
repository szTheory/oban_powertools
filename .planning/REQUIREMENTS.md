# Milestone v1.1 Requirements

**Milestone:** v1.1 Host Contract & Adoption Hardening
**Status:** Drafted 2026-05-21

## v1.1 Requirements

### Packaging & Install

- [x] **PKG-01**: A Phoenix host app can install Oban Powertools through a documented, host-owned generator path that produces deterministic wiring for config, supervision, routes, and migrations.
- [ ] **PKG-02**: A maintainer can upgrade an existing host app between supported milestone versions using an explicit migration and compatibility guide without guessing hidden contract changes.
- [ ] **PKG-03**: A host app can run Oban Powertools with or without `oban_web` installed, with the optional-path behavior documented and continuously verifiable.

### Policy Surfaces

- [ ] **POL-01**: A host app can provide stable auth and actor-attribution hooks that apply consistently across plugs, LiveView mounts, and mutation events.
- [ ] **POL-02**: A host app can provide shared redaction and formatter policies that apply consistently across Powertools-native screens and the Oban Web bridge.
- [x] **POL-03**: Operators and integrators can rely on a documented low-cardinality telemetry contract whose event names, measurements, and metadata boundaries are treated as public API.

### Host Topology & UX

- [x] **HST-01**: A host app can mount the Powertools shell and bridge routes with clear, documented ownership boundaries between library code and host router/supervision/config.
- [ ] **HST-02**: An operator sees consistent permission, read-only, preview, reason, and audit behavior across the Powertools shell and any bridged operator flows.
- [ ] **HST-03**: A host app can understand support-truth boundaries for what Powertools guarantees versus what remains host-owned or intentionally unsupported.

### Docs & Example-Proof

- [ ] **DOC-01**: A developer can complete a day-0 install and first successful operator session by following a concise documented path and example app.
- [ ] **DOC-02**: A developer can apply a production-hardening checklist for auth, telemetry, optional dependencies, and troubleshooting without reading internal implementation code.
- [ ] **DOC-03**: Maintainers can verify the public host contract with automated proof that covers optional dependency paths, route/auth integration, and support-truth regressions.

## Future Requirements

- `WF2-01`: Deepen workflow cancellation, recovery, and signal semantics after the host contract milestone closes.
- `CTL-01`: Unify control-plane action vocabulary and blocked-state diagnostics across cron, limits, workflows, queues, and Lifeline.
- `OBS-01`: Expand operator forensics, runbooks, and evidence bundles after runtime/control-plane semantics stabilize.

## Out Of Scope

- New major runtime engines or workflow primitives in v1.1.
- Full native replacement for generic Oban Web tables/charts/search.
- Non-Postgres support.
- Cloud/provider-specific integrations or mobile/operator companion surfaces.

## Traceability

| Requirement | Planned Roadmap Phase | Notes |
|-------------|-----------------------|-------|
| PKG-01 | Phase 8 | Install surface and host-owned wiring contract |
| PKG-02 | Phase 11 | Upgrade/migration/support-truth proof |
| PKG-03 | Phase 9 | Optional dependency contract and verification |
| POL-01 | Phase 9 | Auth and actor attribution seams |
| POL-02 | Phase 9 | Redaction and formatter seams |
| POL-03 | Phase 8 | Telemetry contract baseline |
| HST-01 | Phase 8 | Route/supervision/config ownership contract |
| HST-02 | Phase 10 | UX coherence and mutation safety |
| HST-03 | Phase 11 | Docs/support matrix truth |
| DOC-01 | Phase 11 | Example app and install path |
| DOC-02 | Phase 11 | Production hardening/troubleshooting |
| DOC-03 | Phase 11 | Proof for public host contract |
