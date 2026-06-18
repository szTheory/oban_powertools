# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **Semantic Versioning** headings like **`[0.5.0]`** for **published
Hex releases**. The maintainer tracks internal planning milestones (v1, v1.1, v1.2,
v1.3, v1.4, v1.5, etc.) in `.planning/` — those labels describe shipped tranches of
work, **not** a second installable version axis on Hex. The library stayed at `0.1.0`
internally through five milestones before its first Hex publication. Do not map planning
milestone numbers to Hex versions.

This library remains **0.x** on Hex until a real **1.0.0** after real adopter feedback.
See [Path to 1.0](#path-to-10) below for the explicit gate.

## [0.5.1](https://github.com/szTheory/oban_powertools/compare/v0.5.0...v0.5.1) (2026-05-30)


### Features

* **48-01:** implement index, migration-version, and powertools-table checks ([0489cb3](https://github.com/szTheory/oban_powertools/commit/0489cb3363bc5529c6ae3373479054c9d1e9a94f))
* **48-02:** implement Doctor.Formatter - human ANSI-degrading + JSON schema_version:1 output ([1c03bc1](https://github.com/szTheory/oban_powertools/commit/1c03bc1ce50fc47a87f205b768dd977455ae388a))
* **48-02:** implement Mix.Tasks.ObanPowertools.Doctor - flags, repo/prefix resolution, with_repo boot, exit codes ([e4b11a4](https://github.com/szTheory/oban_powertools/commit/e4b11a418d59d0ffc6c623db11ec2a99294e2970))
* **49-01:** add Glossary module with single-source rate-limit glossary string ([9586818](https://github.com/szTheory/oban_powertools/commit/95868185dbf3bf6c2ff1125c656858e9d8417e9a))
* **49-01:** extract pure compute_reservation/4 and refactor attempt_reservation/5 ([a83bc61](https://github.com/szTheory/oban_powertools/commit/a83bc615805289050f2b71995e35d37a0e7b9edd))
* **49-02:** add explain task tests + fix Module.safe_concat unknown-module guard ([ec55f37](https://github.com/szTheory/oban_powertools/commit/ec55f37e8916804ca7ae84cbaca9d12c78e1e2ee))
* **49-02:** create Mix.Tasks.ObanPowertools.Limiter.Explain ([be97468](https://github.com/szTheory/oban_powertools/commit/be974685e65948625254090970ef5eb1b12a84bf))
* **49-03:** add mix oban_powertools.limiter.simulate task (OPS-07) ([a4d9a7c](https://github.com/szTheory/oban_powertools/commit/a4d9a7cda2200050e710132cab0b379c4f796382))
* **50-02:** implement metrics/0 with Code.ensure_loaded? guard over frozen contract ([4820915](https://github.com/szTheory/oban_powertools/commit/482091585336f918439b9f64720c8a99a14c7803))
* **51-01:** create regenerate.sh maintainer companion with hex dep insertion ([354b839](https://github.com/szTheory/oban_powertools/commit/354b8396dfb7b43982b6a0d5339232d2e82d238a))
* **51-01:** scaffold hex_consumer config/, lib/, and host-owned seam modules ([f078b2e](https://github.com/szTheory/oban_powertools/commit/f078b2ea19e9a5bc7ddf84df08de4dd78e76843d))
* **51-01:** scaffold hex_consumer mix.exs, .formatter.exs, README, .gitignore ([da559c3](https://github.com/szTheory/oban_powertools/commit/da559c3cce3b9a7e79e76dadb90d64f65775f012))
* **51-02:** add test infrastructure and nightly_sync seed for hex_consumer ([a316de7](https://github.com/szTheory/oban_powertools/commit/a316de7310aeb7091399217641b46f41e7fd703f))
* **51-02:** create first-session test and missing web components for hex_consumer ([81b72e2](https://github.com/szTheory/oban_powertools/commit/81b72e21511daf6fb727221e9776362ad9a1414b))
* **51-03:** add verify-published job to release.yml (REL-04) ([a7a5e99](https://github.com/szTheory/oban_powertools/commit/a7a5e995c2092e4ab83a95638a58b0b92c7707b2))


### Bug Fixes

* **48-01:** wire [@eligible](https://github.com/eligible)_states constant into eligible-count query ([309bdda](https://github.com/szTheory/oban_powertools/commit/309bdda9e58630f0823990b8df168c6c8b7bf192))
* **48-02:** load app.config and harden --format mapping for real CLI runs ([2c1ec3e](https://github.com/szTheory/oban_powertools/commit/2c1ec3e3fbce8cf8b686635533793f183b8cd325))
* **48:** resolve code-review criticals — honest exit codes + safe parsing ([f6245e4](https://github.com/szTheory/oban_powertools/commit/f6245e422258df8dd46e91ad8b1245eac85a5fae))
* **48:** resolve research open questions + identifier-safe count query + DataCase test header ([c159517](https://github.com/szTheory/oban_powertools/commit/c1595172824166fffc5d2278f033a1c725c63787))
* **49:** address code review CR-01 + WR-01/02/03 (D-02 exit-code posture) ([357f68e](https://github.com/szTheory/oban_powertools/commit/357f68e47a7975134db97292dc591f911c079be0))
* **49:** inline D-08 glossary in explain [@moduledoc](https://github.com/moduledoc) for source-parity contract ([cd05b46](https://github.com/szTheory/oban_powertools/commit/cd05b46e2d3837c6da6bab1f344360400ae5b2d5))
* **49:** revise plans + validation/patterns/research per checker feedback ([18f98c7](https://github.com/szTheory/oban_powertools/commit/18f98c7041e53ace38a48859b8241ab6aed2d14a))
* **50-02:** replace import with apply/3 to fix prod-tree compile without telemetry_metrics ([8e87bdb](https://github.com/szTheory/oban_powertools/commit/8e87bdbae1e658821d05782e5c99bb19eb4e1593))


### Documentation

* **48-01:** complete plan-01 doctor core summary ([3b32af8](https://github.com/szTheory/oban_powertools/commit/3b32af80e0e40332821aea433b4bb14ade7206c3))
* **48-02:** complete plan-02 doctor formatter + CLI summary ([5079363](https://github.com/szTheory/oban_powertools/commit/5079363dc03ee26103af94241e376650cefc9ff5))
* **48:** add code review report ([f948528](https://github.com/szTheory/oban_powertools/commit/f9485283f712b7116b5c649977b7c3bfd00060c7))
* **48:** add validation strategy ([f967af9](https://github.com/szTheory/oban_powertools/commit/f967af931a86778b242a5813fd0e498bd6017ae3))
* **48:** capture phase context ([96abfdc](https://github.com/szTheory/oban_powertools/commit/96abfdcc27f02c50d44e15b7e5923bdff5bc8507))
* **48:** create doctor health-check phase plan ([2181da6](https://github.com/szTheory/oban_powertools/commit/2181da62d0abcab6ea951709369a91f453017385))
* **48:** create phase plan ([1d2e2a9](https://github.com/szTheory/oban_powertools/commit/1d2e2a9a2d8f4f79b19c64a1077a4664db5475ee))
* **48:** research doctor health-check task ([6957b5d](https://github.com/szTheory/oban_powertools/commit/6957b5de980d70724ea308a9ddc13867e929a546))
* **49-01:** complete pure-core extraction and glossary plan ([2edc645](https://github.com/szTheory/oban_powertools/commit/2edc64542b6772feea879ce63bbaad815d7d2da9))
* **49-02:** add self-check result to SUMMARY.md ([00f1a9b](https://github.com/szTheory/oban_powertools/commit/00f1a9bcbf76132c4cd07536db615146633e5383))
* **49-02:** complete limiter.explain plan summary ([81422dc](https://github.com/szTheory/oban_powertools/commit/81422dcc6c4075636f2b0af73a19de5d3a1594ed))
* **49-03:** complete limiter simulate CLI plan (OPS-07/OPS-08) ([4fcaf8d](https://github.com/szTheory/oban_powertools/commit/4fcaf8da0b075dfb36ce01c3f7600856d71b0ef4))
* **49:** capture phase context ([2f28432](https://github.com/szTheory/oban_powertools/commit/2f28432da230afe96ab81aef49d13a33bb753c3c))
* **49:** create phase plan ([f2c0c1d](https://github.com/szTheory/oban_powertools/commit/f2c0c1d3c4355f9fe6b3c77b3a8437323f3489db))
* **49:** create phase plan ([ad73394](https://github.com/szTheory/oban_powertools/commit/ad733945026cd75759e6f30260d413747d5b7a41))
* **49:** research limiter explain/simulate CLI phase ([9523292](https://github.com/szTheory/oban_powertools/commit/952329297f090130e92da2a9dc4220e5a968e413))
* **50-01:** complete Wave 0 foundation plan ([0919eea](https://github.com/szTheory/oban_powertools/commit/0919eea28d025cacfc6d033f32046ab96a493ac5))
* **50-02:** complete metrics/0 implementation plan summary ([f6ed3a7](https://github.com/szTheory/oban_powertools/commit/f6ed3a7ef4081c8f3946672dd207607b45b4f671))
* **50-03:** complete telemetry-and-slos guide plan ([c04e6a9](https://github.com/szTheory/oban_powertools/commit/c04e6a96cd50d20146a002488898465e9aad2e25))
* **50-03:** write 4-part telemetry-and-slos Operations guide (TEL-03) ([d64cb29](https://github.com/szTheory/oban_powertools/commit/d64cb298cb981008ed1488e5788ae40b91d30548))
* **50:** add code review report ([cf4d8ad](https://github.com/szTheory/oban_powertools/commit/cf4d8ad5a20d8eaff610ca95d779f417623aadd8))
* **50:** add pattern map ([5b1cd3c](https://github.com/szTheory/oban_powertools/commit/5b1cd3c8c5f157c5109a06884336ff48d9dbb708))
* **50:** add validation strategy ([3370081](https://github.com/szTheory/oban_powertools/commit/337008137f08cfb1e12b7beb535cbdf244df64c8))
* **50:** capture phase context ([1bf4764](https://github.com/szTheory/oban_powertools/commit/1bf4764db60e829d732b8119938c33076ccd5798))
* **50:** create phase plan ([5c1c179](https://github.com/szTheory/oban_powertools/commit/5c1c1793e9978408eaabe963b9eaf2ebf0246945))
* **50:** create phase plan ([9503c6c](https://github.com/szTheory/oban_powertools/commit/9503c6c17cf99255f7a9c1b6d8e23bd1f74292c5))
* **50:** research telemetry metrics and slo guide ([44a136c](https://github.com/szTheory/oban_powertools/commit/44a136c8144e354b89a6285ce29fe5bbf6d66efd))
* **51-01:** complete hex_consumer app scaffold plan ([c7527dd](https://github.com/szTheory/oban_powertools/commit/c7527dddbfa8a2a77b16c9060ac55ccdc061a724))
* **51-02:** complete first-session test and local proof plan ([091ebe1](https://github.com/szTheory/oban_powertools/commit/091ebe1ab26ef58de4173e60f8eedf7bdd4e9f18))
* **51-03:** complete verify-published CI job plan — REL-04 closed ([5e7257f](https://github.com/szTheory/oban_powertools/commit/5e7257f42ca92208b3286f1cf79fbac753b1e819))
* **51:** add code review report ([e978775](https://github.com/szTheory/oban_powertools/commit/e978775f365419a7549e8c133de13ed4ca8f3c1b))
* **51:** add pattern map ([358b147](https://github.com/szTheory/oban_powertools/commit/358b147f4cbeaca9a3acb706b8d8c6c1ad37da49))
* **51:** capture phase context ([28390ca](https://github.com/szTheory/oban_powertools/commit/28390cad1f05f24c156ff2ef7a3d331377a88a52))
* **51:** create phase plan ([b2b0a81](https://github.com/szTheory/oban_powertools/commit/b2b0a81c96ee4beecb5023121f40ef6a0fd7ce36))
* **51:** research published-package verification phase ([3da9995](https://github.com/szTheory/oban_powertools/commit/3da9995fa419d158e7e77faf9f487f17c5ced075))
* **changelog:** populate [Unreleased] with doctor, limiter CLI, and telemetry additions ([3f2d473](https://github.com/szTheory/oban_powertools/commit/3f2d473a11463b542ab5379e24d282cff65b5660))
* **phase-47:** add validation strategy ([e9b4ec2](https://github.com/szTheory/oban_powertools/commit/e9b4ec2f0af2710c1aa3b176534975d91a2359d8))
* **phase-48:** add security threat verification ([1a9f01d](https://github.com/szTheory/oban_powertools/commit/1a9f01ddc0fb501161570188833f587b4c8a0d5b))
* **phase-48:** complete phase execution ([ce280ab](https://github.com/szTheory/oban_powertools/commit/ce280ab255111f4675d73394a28c244cd73e90dd))
* **phase-48:** evolve PROJECT.md after phase completion ([814702d](https://github.com/szTheory/oban_powertools/commit/814702dafa4687f7ee3aaf29c00aca2856d0d345))
* **phase-48:** reconcile validation strategy with executed phase (Nyquist-compliant, 0 gaps) ([7e8000c](https://github.com/szTheory/oban_powertools/commit/7e8000c4bf8b787009cc4cb746c0a6ab7a98a821))
* **phase-48:** update tracking after wave 1 ([aa53e09](https://github.com/szTheory/oban_powertools/commit/aa53e09351fff1dcce9635b03d10edd79a31afb5))
* **phase-48:** update tracking after wave 2 ([5575519](https://github.com/szTheory/oban_powertools/commit/5575519ce158d6ad2892dca18468a23f05802f64))
* **phase-49:** add code review findings ([a9a6a98](https://github.com/szTheory/oban_powertools/commit/a9a6a989f201bfa918a7e8d68fde55a1dd8b8297))
* **phase-49:** add security threat verification ([a72c12a](https://github.com/szTheory/oban_powertools/commit/a72c12a970d85d9b8582b5742192de245cc67f81))
* **phase-49:** add validation strategy ([0e21de4](https://github.com/szTheory/oban_powertools/commit/0e21de419fefc5159fa578440ed539b7fc206e59))
* **phase-49:** complete phase execution ([69a1b33](https://github.com/szTheory/oban_powertools/commit/69a1b3322938da98dc83c7fc7a22396e9e2228ff))
* **phase-49:** evolve PROJECT.md after phase completion ([c82e694](https://github.com/szTheory/oban_powertools/commit/c82e694107da811afb32ca1d28bf836eb087ef06))
* **phase-49:** mark code review findings resolved ([754dcc4](https://github.com/szTheory/oban_powertools/commit/754dcc433faf4bca0fa59091147e52310bbe82be))
* **phase-49:** reconcile validation strategy to green (audit, 0 gaps) ([46832d3](https://github.com/szTheory/oban_powertools/commit/46832d36c0390461821a85a0d59b1f987c76a03e))
* **phase-49:** update tracking after wave 1 ([041c87a](https://github.com/szTheory/oban_powertools/commit/041c87a4eb8284dae4a8d0a80d13f28bc728fbb8))
* **phase-49:** update tracking after wave 2 ([9f59317](https://github.com/szTheory/oban_powertools/commit/9f5931775fd01a9fe1092fcc67389d4344e04b30))
* **phase-50:** complete phase execution ([a115951](https://github.com/szTheory/oban_powertools/commit/a1159515679d142a448f7efea6c5f01bde13d22a))
* **phase-50:** evolve PROJECT.md after phase completion ([b5ddf69](https://github.com/szTheory/oban_powertools/commit/b5ddf6983ec2318b018f61792d9a483571a440bd))
* **phase-50:** update tracking after wave 1 ([a3927e5](https://github.com/szTheory/oban_powertools/commit/a3927e5f329a993fcd3aac65e4585cc455d87fdc))
* **phase-51:** add validation strategy ([706f3ff](https://github.com/szTheory/oban_powertools/commit/706f3ffee7103ae83ced28039659eb2d057bc972))
* **phase-51:** complete phase execution ([f38638d](https://github.com/szTheory/oban_powertools/commit/f38638d8a7366e58384762faeeab644dae65d160))
* **phase-51:** evolve PROJECT.md after phase completion ([d57c9ab](https://github.com/szTheory/oban_powertools/commit/d57c9ab8c3f50168ab9ac0429b12972ebcfa0a61))
* **phase-51:** update tracking after wave 1 ([b858953](https://github.com/szTheory/oban_powertools/commit/b858953806b2e0b355a9bde47ff154e5f879f65d))
* **phase-51:** update tracking after wave 2 ([6df46ca](https://github.com/szTheory/oban_powertools/commit/6df46cac645502cdb070fed284d4f7954db31992))
* **phase-51:** update tracking after wave 3 ([4007aef](https://github.com/szTheory/oban_powertools/commit/4007aef10d6e5316159792bc2a4e0d9b3f7feb74))
* **state:** record phase 48 context session ([07ffb6d](https://github.com/szTheory/oban_powertools/commit/07ffb6d6d4f73fd6e318314c869931d39896c497))
* **state:** record phase 49 context session ([9be5555](https://github.com/szTheory/oban_powertools/commit/9be5555ba00c65b66eca366ff1970b791763f7da))
* **state:** record phase 50 context session ([521c937](https://github.com/szTheory/oban_powertools/commit/521c93775a6b30b7fe0a29c4d59fdd0a34b7f042))
* **state:** record phase 51 context session ([562d835](https://github.com/szTheory/oban_powertools/commit/562d835a3d97442b839d839b9dd7e57c961730fc))
* **v1.6:** milestone audit — gaps_found (3/13 satisfied, 3 phases unbuilt) ([7b45782](https://github.com/szTheory/oban_powertools/commit/7b45782f455ade285507d97f77557d9276110c6e))
* **v1.6:** re-audit milestone — 5/13 satisfied, hex 0.5.0 live, doctor not in published pkg ([50cb65b](https://github.com/szTheory/oban_powertools/commit/50cb65bd7aba8530b238c7508d1dc122bb9359d1))
* **v1.6:** re-audit milestone — Phase 49 built, 8/13 reqs satisfied, gaps_found ([2da44bd](https://github.com/szTheory/oban_powertools/commit/2da44bd3d201ada0bb662af62b405a881e344695))

## [Unreleased]

## [1.0.0] - 2026-06-18

### Changed
- Promoted package version to `1.0.0` following comprehensive stabilization sweep.
- Ecto migrations updated to utilize concurrent index generation (`concurrently: true` and `@disable_ddl_transaction true`) for high-throughput tables.
- Ran comprehensive static analysis with Dialyzer and Credo, resolving all code contract warnings.
- Introduced `powertools-vs-oban-pro.md` matrix and `upgrade-and-compatibility.md` documentation.

### Added

#### Health Check CLI

- `mix oban_powertools.doctor` — read-only health check task that inspects the Oban
  and Powertools database state without starting Oban or acquiring locks. Runs five
  checks over `pg_catalog` and `information_schema`:
  - **Index validity** — surfaces `INVALID` indexes left by a failed
    `CREATE INDEX CONCURRENTLY`, with `REINDEX INDEX CONCURRENTLY` remediation.
  - **Missing indexes** — detects absent v14 Oban indexes that degrade job throughput.
  - **Migration drift** — compares the in-DB Oban migration version against the
    installed library version and flags gaps.
  - **Powertools tables** — verifies all 24 Powertools tables are present, grouped by
    migration tranche with per-group remediation hints.
  - **Uniqueness-timeout risk** — warns when the GIN index is absent and a large
    backlog makes uniqueness checks expensive; escalates to error under `--strict`.
- Exit codes suitable for CI pipelines: `0` (all clear), `1` (warnings), `2` (errors).
- `--format json` output carries a `schema_version: 1` stability contract for
  machine-readable consumption.
- `--strict` flag elevates uniqueness-timeout risk from warning to error.
- `--prefix` flag for custom Oban schema support.
- End-to-end contract test in CI (`doctor` lane in `host-contract-proof.yml`) that
  exercises the real CLI against a freshly migrated example host, including
  `--format json` round-trip and absent-prefix error path.

#### Limiter CLI

- `mix oban_powertools.limiter.explain` — diagnoses a limiter's current blocking state
  by resource name or worker module, reusing `ObanPowertools.Explain` without
  duplicating limiter logic. Shows why a limiter is blocked, when it will clear, and
  what tokens are in use.
- `mix oban_powertools.limiter.simulate` — previews per-request reserved/blocked
  verdicts for a worker's declared limits without touching any real limiter state.
  Simulation is proven side-effect-free: no DB writes, no telemetry events, no
  token-bucket mutations.
- Both tasks embed the full rate-limit glossary (`token_bucket`, `bucket_capacity`,
  `bucket_span_ms`, `weight`, `weight_by`, `partition`, `partition_by`, `scope`,
  `cooldown`, `limit_reached`) in their `--help` output.
- `ObanPowertools.Limits.compute_reservation/4` — new public pure function (extracted
  from the internal reservation path) that determines reserve/block verdicts with zero
  side effects. Useful for unit-testing limiter behavior without a database.
- `ObanPowertools.Limits.Glossary` — single-source rate-limit glossary module; the
  glossary text is test-locked across the guide, explain task, and simulate task so
  term-level parity is enforced in CI.

#### Telemetry & SLOs

- `ObanPowertools.Telemetry.metrics/0` — returns 17 `Telemetry.Metrics.Counter`
  definitions over the frozen low-cardinality contract, covering five control-plane
  families: `operator_action` (2), `limiter` (3), `cron` (4), `workflow` (4), and
  `lifeline` (4). All tags are strict subsets of the frozen `@contract` — no
  `:job_id`, `:args`, or other high-cardinality fields.
- `telemetry_metrics` and `telemetry_poller` added as optional dependencies, gated
  like the existing `oban_web` integration. Zero runtime cost or failure when absent;
  `metrics/0` raises an actionable `RuntimeError` if called without the dep installed.
- **Operations guide:** `guides/telemetry-and-slos.md` — reporter-agnostic guide
  covering telemetry wiring, the Oban-core vs Powertools signal seam, control-plane
  SLIs, and burn-rate SLO framing with Parapet. No `oban_met` dependency required.

## [0.5.0] - 2026-05-29

First public release of Oban Powertools — an Ecto-native operations layer for
Oban-backed Phoenix applications that extends Oban with typed worker contracts,
durable idempotency, explicit limiter and cron controls, durable workflow semantics,
and native operator surfaces for diagnosis, repair, and audited manual operations.

### Added

#### Workers & Idempotency

- Typed worker arg schemas with `field/3` macro — compile-time validation of job
  arguments against declared types, with support for `required:`, `default:`, and
  `redact:` options.
- Synchronous enqueue validation — `insert/2` returns `{:error, changeset}` on
  invalid args before the job reaches the queue.
- Durable idempotency receipts — `idempotency_key/1` hashes worker args to produce
  a stable fingerprint; duplicate enqueues within the observation window are
  deduplicated at the DB level without requiring the caller to manage uniqueness
  tokens.

#### Limiters & Explain

- Global and partitioned rate limiters — `ObanPowertools.Limits` with configurable
  token-bucket windows, per-resource partitioning, and explicit `blocker_code`
  vocabulary for diagnosing blocked jobs.
- Explainable blocking state — `ObanPowertools.Explain` surfaces why a job is
  currently blocked (limiter, cron overlap, or queue depth) with structured output
  suitable for operator dashboards and CLI tooling.

#### Cron

- Dynamic cron with overlap policies — `ObanPowertools.Cron` manages named cron
  entries with explicit `overlap_policy` (`:skip`, `:replace`, `:run_anyway`) and
  `catch_up_policy` (`:run_once`, `:run_all`, `:skip`) so missed-fire behavior is
  documented and auditable, not silently dropped.

#### Workflows

- Explicit persisted workflow DAGs — `ObanPowertools.Workflow` stores step graphs in
  a dedicated `oban_powertools_workflows` table with durable terminal-cause vocabulary
  and additive semantics versioning.
- Coordinator signaling for rapid progression — `Workflow.signal/2` lets a completing
  step unblock its dependents without polling, reducing workflow latency under load.
- Native workflow state inspection UI — the `/ops/jobs` shell renders workflow
  progress, step outcomes, and terminal causes at `/ops/jobs/workflows`.

#### Lifeline & Repairs

- Heartbeat-backed executor health tracking — `ObanPowertools.Lifeline` monitors
  Oban queue health and surfaces stalled executors with structured incident classes.
- Dry-run repair center with durable closure behavior — all operator repairs go through
  a preview → reason → execute → audit pipeline; repairs are idempotent and
  self-closing.
- Audit logging for manual UI operations — every operator action writes a durable
  audit record via `ObanPowertools.AuditLog` with actor attribution, action type,
  target identity, and outcome.
- Archive-before-delete retention flows — `ObanPowertools.Archive` moves jobs and
  workflow records to retention tables before deletion, preserving forensic history.

#### Native `/ops/jobs` Shell

- Full native job lifecycle surface at `/ops/jobs/jobs` — browse jobs by state,
  queue, worker, and tags with URL-serialized filter state and `DisplayPolicy`
  redaction on args/meta; inspect full job detail.
- Single-job retry, cancel, and discard through the Lifeline preview/reason/execute/audit
  pipeline with a concurrent-modification guard.
- Bulk operations with independent per-job repairs and honest per-job
  success/failure reporting — no silent partial failures.
- `DisplayPolicy` behaviour for host-controlled field redaction and display formatting
  across all native operator surfaces.

#### Operator API (Single + Bulk)

- `ObanPowertools.Operator` — typed, actor-attributed programmatic surface for
  single-job mutations (retry, cancel, discard) routed through the Lifeline pipeline
  and emitting `source: "api"` telemetry within the frozen low-cardinality contract.
- Bulk Operator API — `Operator.retry_all/2`, `cancel_all/2`, `discard_all/2` run
  an independent repair per job and return per-job success/failure results; no single
  `Ecto.Multi` over N jobs, no silent bulk failure.

#### Telemetry Contract

- Frozen low-cardinality telemetry contract — `ObanPowertools.Telemetry` defines and
  publishes five event families under `[:oban_powertools, family, event_suffix]`:
  `:operator_action`, `:limiter`, `:cron`, `:workflow`, and `:lifeline`. The public
  measurement key is `:count`. Metadata keys are enumerated per family in the frozen
  `@contract` — IDs, job args, preview tokens, and free-form reasons are intentionally
  excluded.

#### Install & Migrations

- Igniter-powered installer — `mix oban_powertools.install` adds the dependency,
  configures the router, sets up auth hooks, and generates all required migrations via
  `Igniter.Libs.Ecto.gen_migration/4` directly into the host's `priv/repo/migrations/`.
- Deterministic Ecto migrations for all Powertools tables with a documented upgrade
  path and `mix ecto.migrate` idempotency.

#### Optional Oban Web Bridge

- Optional `oban_web` bridge — when `{:oban_web, optional: true}` is present, the
  `/ops/jobs` shell embeds the Oban Web dashboard at `/ops/jobs/oban` as a narrower,
  read-only complement to the native surfaces. The bridge is compile-time optional;
  the native shell is fully functional without it.

---

## Path to 1.0

Oban Powertools uses a **hybrid per-surface + stability-window gate** to determine
when each named public surface is ready to freeze at `1.0`. The library will NOT bump
to `1.0.0` until all four surfaces below have met their gate criteria — and in
practice, not until at least one **non-szTheory host** has exercised the install,
Operator API, and upgrade path in production.

**Gate criteria** (must be met for each surface):

1. The surface is **explicitly enumerated** (listed below).
2. The surface has been **exercised by at least one non-szTheory host** in a real application.
3. The surface is **free of any known breaking change** at time of evaluation.
4. The surface has survived **at least two consecutive 0.x minor releases** without a breaking change.

### Surface Checklist

#### Installer / Migration Contract

The `mix oban_powertools.install` Igniter task and the set of Ecto migrations it
generates — including the table schemas for `oban_powertools_workflows`,
`oban_powertools_workflow_steps`, `oban_powertools_audit_logs`, and all supporting
tables — constitute the installer/migration contract surface.

- [ ] Explicitly enumerated: YES (this document)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (as of 0.5.0)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

#### Operator Elixir API (Single + Bulk)

The public functions in `ObanPowertools.Operator` — `retry/2`, `cancel/2`,
`discard/2`, `retry_all/2`, `cancel_all/2`, `discard_all/2` — and their `actor:` and
`opts:` argument shapes constitute the Operator API surface.

- [ ] Explicitly enumerated: YES (this document)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (as of 0.5.0)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

#### Frozen Telemetry `@contract`

The five event families (`[:oban_powertools, family, event_suffix]`), the public
measurement key (`:count`), and the per-family allowed low-cardinality metadata keys
defined in `ObanPowertools.Telemetry.@contract` constitute the telemetry surface.
This surface was frozen at Phase 8 (v1.1) and has not changed since.

- [ ] Explicitly enumerated: YES (this document + `ObanPowertools.Telemetry` moduledoc)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (frozen since v1.1)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

#### Host-Ownership Boundary

The host-ownership boundary governs which concerns Oban Powertools owns vs. which
the host app must provide: the router mount point (`live "/ops/jobs", ...`), the auth
callback hook (`ObanPowertools.Auth` behaviour), `DisplayPolicy` module pointing, and
the supervision tree wiring. Changes to this boundary require host-app code changes.

- [ ] Explicitly enumerated: YES (this document + `guides/support-truth-and-ownership-boundaries.md`)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (as of 0.5.0)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

---

*The 1.0 clock starts when a non-szTheory host reports a successful install. At that
point, each surface enters the stability observation window and tracks
0.x minor releases without breaking changes toward the graduation gate.*
