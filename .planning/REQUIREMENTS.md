# Requirements: Oban Powertools — v1.6 Release & Operability

**Defined:** 2026-05-28
**Core Value:** Ecto-native operational safety with explicit, inspectable behavior for developers and operators, delivered through a native `/ops/jobs` shell with honest host-ownership and support-truth boundaries.

**Milestone goal:** Make Oban Powertools real for adopters — publish it to hex and ship the two named operability footguns — before adding any more capability. The release IS the milestone; the tooling ships adopter trust, not raw capability. Zero new runtime dependencies.

## v1.6 Requirements

### Release & Packaging

- [x] **REL-01**: Library publishes to hex.pm at `0.5.0` with a strict `:files` whitelist that ships `priv/` migration generators and excludes `.planning/`, tests, and dev cruft.
- [x] **REL-02**: ExDoc API documentation builds with `source_ref` pinned to the release tag and renders correctly on hexdocs (guides included as `extras`).
- [x] **REL-03**: `CHANGELOG.md` (Keep a Changelog format) documents the `0.5.0` release and the explicit, documented path to `1.0` after real adopter feedback.
- [ ] **REL-04**: The getting-started quickstart is verified working from the **published** package — a fresh host installs from hex and reaches a first successful operator session (not just in-repo).

### Operability — Doctor

- [x] **OPS-03**: Operator can run `mix oban_powertools.doctor` to check Oban index presence and validity, including `INVALID` indexes left by a failed `CREATE INDEX CONCURRENTLY`, fully read-only over `pg_catalog`.
- [x] **OPS-04**: `mix oban_powertools.doctor` detects migration drift and validates configuration — honoring a custom Oban prefix/schema — and flags uniqueness-timeout risk.
- [x] **OPS-05**: `mix oban_powertools.doctor` returns honest exit codes (`0` ok / `1` warnings / `2` errors) suitable for CI, with actionable remediation hints in its output.

### Operability — Limiter CLI

- [ ] **OPS-06**: Operator can run `mix oban_powertools.limiter.explain` to explain a limiter's current blocking state, reusing the existing `Explain` API rather than duplicating limiter logic.
- [ ] **OPS-07**: Operator can run `mix oban_powertools.limiter.simulate` to preview limiter behavior for a given config without mutating any real limiter state.
- [ ] **OPS-08**: The limiter CLI ships the rate-limit glossary in its help/documentation output.

### Telemetry & SLOs

- [ ] **TEL-01**: Host can call `ObanPowertools.Telemetry.metrics/0` to obtain `Telemetry.Metrics` definitions over the frozen low-cardinality contract — opt-in and reporter-agnostic.
- [ ] **TEL-02**: `telemetry_metrics` and `telemetry_poller` are optional dependencies gated like the existing `oban_web` integration — no runtime cost or failure when absent.
- [ ] **TEL-03**: A Parapet/SLO telemetry guide documents golden-signals/SLO setup over the metrics surface, with no `oban_met` dependency.

## Future Requirements

Deferred to later milestones. Tracked but not in the v1.6 roadmap.

### Worker Lifecycle & Safety (→ v1.7)

- **WRK-04**: Observe-only worker hooks (`on_start`/`success`/`failure`/`discard`), crash-caught, never changing job outcome.
- **WRK-05**: Soft `deadline:` (pre-run cancel) + `timeout:` pass-through to Oban's own `timeout/1`.
- **WRK-06**: Output recording by generalizing `Workflow.Result` into a shared recordings table.
- **WRK-07**: `redact:` at-persist field drop via the existing `Redactor` seam.

### Batches & Composition (→ v1.8)

- **BAT-01**: Dedicated `batches`/`batch_jobs` tables with `completed` + `exhausted` callbacks via the generalized callback outbox.
- **BAT-02**: Native Batches page with Lifeline-routed bulk-retry of failed members.

### Observability / Live Counts (→ v1.9)

- **QRY-06**: Real-time job/queue counts with `oban_met` as an *optional* read source (never a hard dep, never a metric label).

### Native Job-Surface Polish (opportunistic)

- **QRY-05**: Args/meta filter on the native job surface.
- **QRY-07**: Lifeline→job deep-link.
- **QRY-08**: Cross-page select-all.
- **API-03**: Programmatic job query (`Operator.list/2`).

## Out of Scope

Explicitly excluded for v1.6. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| `oban_met` as a hard dependency / native generic-metrics dashboard | That's rebuilding Oban Web; only ever an optional read source for live counts (v1.9). |
| Field-level arg `encrypt:` | Collides with the args-hashing idempotency fingerprint, blinds the v1.5 job filter, leaks via meta/errors. Ship `redact:` instead (v1.7). No proven demand. |
| Prioritizer / autoscaler | Don't build until adoption proves demand. |
| Worker hooks / `deadline:` / output recording | Deferred to v1.7 (must precede Batches). |
| Batches (incl. nested/chunked/growable) | Deferred to v1.8; nested/chunked/growable are Sidekiq's worst reliability area. |
| Bundling any telemetry reporter (`telemetry_metrics_prometheus`, etc.) | Reporter choice is the host's; the library only exposes metric definitions. |
| Jumping straight to `1.0` | Premature API freeze before real adopter feedback; ship `0.5.0` first. |

## Process Convention (carried, not a REQ-ID)

Milestone verification/audit must assert a **clean working tree** (or per-phase commit existence), not validate working-tree-only state. Graduated from v1.5, where phases 44/45 audited `passed` while their implementation was uncommitted. Applies to phase verification and the milestone audit for v1.6.

## Traceability

Which phases cover which requirements. Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 47 | Complete |
| REL-02 | Phase 47 | Complete |
| REL-03 | Phase 47 | Complete |
| REL-04 | Phase 51 | Pending |
| OPS-03 | Phase 48 | Complete |
| OPS-04 | Phase 48 | Complete |
| OPS-05 | Phase 48 | Complete |
| OPS-06 | Phase 49 | Pending |
| OPS-07 | Phase 49 | Pending |
| OPS-08 | Phase 49 | Pending |
| TEL-01 | Phase 50 | Pending |
| TEL-02 | Phase 50 | Pending |
| TEL-03 | Phase 50 | Pending |

**Coverage:**

- v1.6 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-28*
*Last updated: 2026-05-28 — traceability populated after roadmap creation*
