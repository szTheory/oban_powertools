# Milestone v1.1 Requirements

**Milestone:** v1.1 Host Contract & Adoption Hardening
**Status:** Reopened by milestone audit 2026-05-22
**Coverage:** 7/12 requirements are currently marked complete after the Phase 12-14 repairs; the remaining unchecked items are the outstanding milestone gaps.

## v1.1 Requirements

### Packaging & Install

- [x] **PKG-01**: A Phoenix host app can install Oban Powertools through a documented, host-owned generator path that produces deterministic wiring for config, supervision, routes, and migrations.
- [ ] **PKG-02**: A maintainer can upgrade an existing host app between supported milestone versions using an explicit migration and compatibility guide without guessing hidden contract changes.
- [ ] **PKG-03**: A host app can run Oban Powertools with or without `oban_web` installed, with the optional-path behavior documented and continuously verifiable.

### Policy Surfaces

- [x] **POL-01**: A host app can provide stable auth and actor-attribution hooks that apply consistently across plugs, LiveView mounts, and mutation events.
- [x] **POL-02**: A host app can provide shared redaction and formatter policies that apply consistently across Powertools-native screens and the Oban Web bridge.
- [x] **POL-03**: Operators and integrators can rely on a documented low-cardinality telemetry contract whose event names, measurements, and metadata boundaries are treated as public API.

### Host Topology & UX

- [x] **HST-01**: A host app can mount the Powertools shell and bridge routes with clear, documented ownership boundaries between library code and host router/supervision/config.
- [x] **HST-02**: An operator sees consistent permission, read-only, preview, reason, and audit behavior across the Powertools shell and any bridged operator flows.
- [ ] **HST-03**: A host app can understand support-truth boundaries for what Powertools guarantees versus what remains host-owned or intentionally unsupported.

### Docs & Example-Proof

- [x] **DOC-01**: A developer can complete a day-0 install and first successful operator session by following a concise documented path and example app.
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
| PKG-01 | Phase 12 | Restore the fresh-host generator path and example-fixture proof |
| PKG-02 | Phase 15 | Replace synthetic upgrade proof with a supported-host migration lane |
| PKG-03 | Phase 13 | Verify the native-only path without `oban_web` and keep the bridge bounded |
| POL-01 | Phase 14 | Close auth and actor-attribution evidence gaps across Phase 9 artifacts |
| POL-02 | Phase 14 | Close redaction and formatter evidence gaps across Phase 9 artifacts |
| POL-03 | Phase 14 | Repair telemetry closure metadata and verification traceability |
| HST-01 | Phase 8 | Route/supervision/config ownership contract |
| HST-02 | Phase 14 | Add missing phase-level verification for operator UX coherence |
| HST-03 | Phase 15 | Align support-truth claims with verified fixture and guide behavior |
| DOC-01 | Phase 12 | Rebuild the day-0 install and first-session paved path |
| DOC-02 | Phase 15 | Close production-hardening and troubleshooting evidence with verification |
| DOC-03 | Phase 13 | Re-prove optional dependency, route, and support-truth regressions honestly |
