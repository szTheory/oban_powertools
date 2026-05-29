# Research Summary: Oban Powertools v1.6 — Release & Operability

**Project:** Oban Powertools
**Domain:** Elixir/Phoenix Hex library — operator control plane for Oban
**Researched:** 2026-05-28
**Confidence:** HIGH

---

> **Note on research files:** The four research files (STACK.md, FEATURES.md, ARCHITECTURE.md,
> PITFALLS.md) in this directory were produced by the v1.5 milestone research pass (2026-05-27)
> and cover the native job surface and operator API shipped in that milestone. They are committed
> here as the standing research corpus. The v1.6 synthesis below is derived from those files
> **plus** the post-v1.5 milestone-ordering assessment
> (`.planning/threads/2026-05-28-post-v1.5-next-milestone.md`), which supersedes them for
> scoping and priority decisions. The research files themselves are accurate as v1.5 deliverable
> records and remain valid reference for v1.6 build context.

---

## Executive Summary

Oban Powertools has shipped five milestones of production-quality operator infrastructure —
typed workers, idempotency, limiters, cron, durable workflows, Lifeline repair,
forensics/runbooks, and a native job browse/action surface with a full Elixir API. It is 87%
"done" for its stated scope, coherent, tested (40 test files, 4 CI lanes, 13 guides), and
carries a frozen low-cardinality telemetry contract. **The single largest barrier to adopter
value is not a missing feature: the library is `0.1.0` and unpublished on Hex after five
milestones.** v1.6 fixes that with zero new runtime dependencies and near-zero risk to existing
surfaces.

v1.6 "Release & Operability" has exactly four deliverables: (1) first public Hex release at
`0.5.0` with getting-started verified from the published package; (2) a read-only
`mix oban_powertools.doctor` health-check Mix task; (3) `mix oban_powertools.limiter.explain`
and `mix oban_powertools.limiter.simulate` CLI commands wrapping the existing `Explain`+`Limits`
modules; and (4) an opt-in `ObanPowertools.Telemetry.metrics/0` function plus a Parapet/SLO
telemetry guide over the existing frozen low-cardinality contract. No new runtime dependencies
are introduced. `oban_met` is explicitly out of scope. ExDoc is the only dev-only addition.

The ordering principle is: prepare the release metadata first (hex files whitelist, ExDoc,
moduledocs, `mix hex.publish --dry-run`), then deliver the three operability features in build
order (doctor, limiter CLI, telemetry guide + metrics/0), then verify getting-started from the
published tarball and cut the release. Every change is additive and read-only at runtime. The
clean-working-tree rule — established as a graduation criterion in the post-v1.5 assessment —
applies here: all phases must commit before audit/verify, and the working tree must be clean at
release time.

---

## Key Findings

### Recommended Stack

The locked stack (Oban 2.22.1, Phoenix LiveView 1.1.30, Ecto SQL 3.13.5, Telemetry 1.4,
Jason 1.4, Postgrex 0.22.2) requires no additions at runtime for v1.6. ExDoc is the only new
dependency, added as `{:ex_doc, only: :dev}` to generate the Hex package documentation that
adopters will read on hexdocs.pm.

`telemetry_metrics` and `telemetry_poller` are optional additions if `Telemetry.metrics/0`
returns typed `Telemetry.Metrics` structs rather than plain maps. Given the frozen contract,
`metrics/0` can be implemented using only the `telemetry` package already in the stack. Whether
to add `telemetry_metrics` as an optional or dev-only dep is a requirements-time design decision,
not a mandatory v1.6 dependency.

**Core technologies for v1.6 additions:**

- `ExDoc` (dev-only) — hex package docs, `@moduledoc`, `@doc`, guides linked as `extras:` in
  `mix.exs`; required for hexdocs.pm publication
- `Telemetry 1.4` (already locked) — `Telemetry.metrics/0` emits no new events; it exposes the
  frozen contract as metric descriptors so Parapet/SLO setups can consume them without guessing
- `Mix.Task` (stdlib) — doctor and limiter CLI are Mix tasks; no new library required
- `Ecto.Repo` + `pg_catalog` (already locked) — doctor health checks query `pg_catalog.pg_indexes`
  and `pg_stat_activity` read-only via the host's configured Repo; no migrations, no writes

**What NOT to add:**

| Avoid | Why |
|-------|-----|
| `oban_met` | Explicitly deferred to v1.9; would pull in a significant optional dep and drift toward rebuilding Oban Web |
| `telemetry_metrics` as a hard dep | `metrics/0` can return plain maps without a hard dep; decide at requirements time |
| `telemetry_poller` as a hard dep | Polling is a host concern; the guide teaches hosts to configure it; Powertools does not own the polling loop |
| Any new runtime dep for doctor | `pg_catalog` is reachable via the host's existing Repo; no extra client needed |

### Expected Features

The four deliverables map to distinct feature sets. All are additive; none modify existing
runtime behavior.

**Deliverable 1 — Hex Publication (`0.5.0`) — table stakes:**

- `version: "0.5.0"` in `mix.exs` with `description:`, `licenses:`, `links:`, `package:`
- `files:` whitelist — must include `lib/`, `mix.exs`, `README.md`, `CHANGELOG.md`, `guides/`;
  must EXCLUDE `.planning/`, `test/`, `priv/dev-seeds`, internal scripts
- All public modules have `@moduledoc` and `@doc` strings suitable for hexdocs.pm
- `mix hex.publish --dry-run` passes cleanly; tarball file list inspected and confirmed correct
- Getting-started verified from the published tarball (install via `mix deps.get`, configure,
  mount routes, see overview) — NOT from the local development path dep
- Clean working tree at publish time (enforced by the graduation rule)
- CHANGELOG.md `0.5.0` entry
- Semantic versioning commitment documented: `0.x` = evolving API; `1.0` only after real adopter
  feedback from at least three independent production adopters

**Deliverable 2 — `mix oban_powertools.doctor` — table stakes:**

- Read-only health checks only; zero writes, zero schema changes, zero Oban engine mutations
- Checks: index presence (Powertools-expected indexes), invalid indexes (`indisvalid = false`),
  uniqueness timeout risk, config sanity (required Application env keys present), migration drift
  (expected tables: `oban_powertools_audit_events`, `oban_powertools_repair_previews`,
  `oban_powertools_repair_archives`)
- Exit code 0 (clean), 1 (warnings), 2 (errors) — scriptable for CI health gates
- Human-readable PASS/WARN/FAIL per check; optional `--format json`
- Queries `pg_catalog.pg_indexes` and `pg_stat_user_indexes` via the host Repo
- No Oban engine interaction; no `Oban.*` function calls from within the task

**Deliverable 3 — `mix oban_powertools.limiter.explain` / `.simulate` — table stakes:**

- `.explain` — CLI surface over existing `ObanPowertools.Explain` and `ObanPowertools.Limits`;
  prints effective rate-limit policy for a queue (or all queues), slot windows, and computed
  throughput ceiling; no new business logic
- `.simulate` — same modules; dry-run projection for a hypothetical job count; no writes
- Rate-limit glossary embedded in task `@moduledoc` / help output
- Both tasks: `--repo MyApp.Repo`, `--queue <name>`, `--format json` options
- Graceful WARN (not crash) when no limiter config is found

**Deliverable 4 — `Telemetry.metrics/0` + SLO guide — table stakes:**

- `ObanPowertools.Telemetry.metrics/0` — new public function; returns metric descriptors
  for all events in the frozen `@contract`; zero runtime side effects; no polling loop
- `guides/telemetry_slo.md` — how to wire `metrics/0` into Parapet, SLO examples for operator
  action latency and repair success rate, explicit "what is NOT included" section
- Test: assert `metrics/0` descriptors cover exactly the events in `@contract` (no more, no less)
- Explicitly states: no per-job/per-queue/per-worker cardinality; no `oban_met`; no live counts

**Explicitly out of scope (deferred until signal):**

- `oban_met` / live job/queue counts (v1.9)
- `encrypt:` (collides with args-hash idempotency, blinds job filter)
- Prioritizer/autoscaler (deferred until adoption proves demand)
- Batches (v1.8), Worker lifecycle hooks (v1.7)
- args/meta search qualifiers, cross-page select-all, nested batches
- Native metrics dashboard (= rebuild Oban Web)

### Architecture Approach

v1.6 adds only Mix tasks and one new public function. No LiveView changes. No new schemas or
migrations. No new GenServers. All four deliverables are additive to existing, well-understood
modules.

**Major components added in v1.6:**

1. `Mix.Tasks.ObanPowertools.Doctor` — reads host Repo and `pg_catalog`; outputs health report;
   uses `ObanPowertools.RuntimeConfig.repo!/1` for repo resolution (with fallback to `--repo`
   option for Mix task context where the application may not be started)
2. `Mix.Tasks.ObanPowertools.Limiter.Explain` — thin CLI wrapper over `ObanPowertools.Explain`
   and `ObanPowertools.Limits`; formatting and option parsing only; no new logic
3. `Mix.Tasks.ObanPowertools.Limiter.Simulate` — same modules as above; dry-run projection path
4. `ObanPowertools.Telemetry.metrics/0` — new public function on the existing `Telemetry` module;
   returns metric descriptors derived from `@contract`; no side effects

**Files modified (surgical additions only):**

| File | Change |
|------|--------|
| `mix.exs` | version, description, licenses, links, package, files whitelist, ex_doc dev dep |
| `lib/oban_powertools/telemetry.ex` | Add `metrics/0` public function |
| `README.md` | Installation + getting-started from hex |
| New: `lib/mix/tasks/oban_powertools.doctor.ex` | Doctor Mix task |
| New: `lib/mix/tasks/oban_powertools.limiter.explain.ex` | Explain CLI task |
| New: `lib/mix/tasks/oban_powertools.limiter.simulate.ex` | Simulate CLI task |
| New: `guides/telemetry_slo.md` | Parapet/SLO guide (hex extras) |

No new migrations, LiveViews, schemas, or GenServers.

### Critical Pitfalls

1. **Hex `files:` whitelist omissions or over-inclusions** — If `files:` is not set, Hex
   publishes everything including `.planning/`, secrets, internal tooling. If too narrow, the
   published package breaks on install. Verify with `mix hex.publish --dry-run` and inspect the
   tarball file list. Whitelist must be explicit: `["lib", "mix.exs", "README.md",
   "CHANGELOG.md", "guides"]`.

2. **Doctor task performing writes or Oban engine calls** — Any write in a "read-only health
   check" tool destroys operator trust instantly. Query only `pg_catalog.*` and Powertools table
   existence (read-only). No `Oban.*` calls. No `Repo.update` or `Repo.insert`. Enforce with a
   test that mocks the Repo and asserts zero writes.

3. **Premature `1.0` version** — Publishing at `1.0` signals a stable API contract. Zero real
   adopter feedback exists. Ship at `0.5.0` and document the `1.0` graduation criteria explicitly
   (three independent production adopters, no breaking API changes for two milestones). Putting
   `1.0` in `mix.exs` on first publish is the single most consequential mistake of this milestone.

4. **Low-cardinality contract drift in `Telemetry.metrics/0`** — `metrics/0` must return
   descriptors that exactly match the frozen `@contract`. Adding a descriptor for a
   high-cardinality dimension (`worker`, `queue`, `job_id`, `reason`) silently teaches adopters
   to configure those as label dimensions. Treat `@contract` as the single source of truth;
   generate `metrics/0` output from it, not independently.

5. **Getting-started verified only from local dev, not from the published package** — The most
   common hex publish failure: the local checkout has files on the load path that the tarball
   omits, or the guide assumes `config/dev.exs` context a fresh adopter won't have. Verification
   must run against `mix deps.get` from a blank Phoenix app listing the published hex package.

6. **Clean working tree rule not enforced at release** — The post-v1.5 assessment graduated a
   process rule: all changes must be committed before audit/verify. This is a hard gate before
   `mix hex.publish` — not advisory. Add it as an explicit checklist step in the release phase.

7. **Limiter CLI crashing when no limiter config is present** — Adopters who run the explain or
   simulate tasks before configuring any limiters must see a helpful WARN, not a nil match error.
   Default to "no limiter rules configured; nothing to explain" and exit 0.

---

## Implications for Roadmap

Based on the four deliverables and their dependencies, the recommended phase structure is:

### Phase 1: Hex Publication Prep

**Rationale:** Everything else in v1.6 is worthless if the package doesn't install cleanly. Hex
metadata, `files:` whitelist, ExDoc, `@moduledoc`/`@doc` strings, and CHANGELOG must come before
feature work so subsequent phases build on a publishable base.

**Delivers:**
- `mix.exs`: `version: "0.5.0"`, `description`, `licenses`, `links`, `package`, `files`
  whitelist, `ex_doc` dev dep, `extras:` for guides
- All public modules with complete `@moduledoc` and `@doc` strings
- `mix hex.publish --dry-run` passes; tarball file list confirmed correct
- CHANGELOG.md `0.5.0` entry placeholder
- README.md installation section updated to hex-based instructions

**Avoids:** files whitelist pitfall (Pitfall 1); premature 1.0 pitfall (Pitfall 3).

**Research flag:** Standard hex packaging — well-documented, no deeper research needed.

---

### Phase 2: `mix oban_powertools.doctor`

**Rationale:** The doctor task is the highest-leverage zero-dep operability feature. It
establishes the Mix task file structure and repo-resolution pattern (`RuntimeConfig.repo!/1`)
that the limiter CLI tasks will reuse. Build it first so Phase 3 can copy the pattern.

**Delivers:**
- `lib/mix/tasks/oban_powertools.doctor.ex`
- Checks: index presence, invalid indexes, uniqueness timeout risk, config sanity, migration drift
- Exit codes: 0 (clean), 1 (warnings), 2 (errors)
- Output: human-readable PASS/WARN/FAIL per check; optional `--format json`
- Zero writes, zero Oban engine calls — pure `pg_catalog` reads via host Repo
- Test coverage: mock Repo asserting zero writes; each check covered by a unit test

**Avoids:** doctor-writes pitfall (Pitfall 2).

**Research flag:** `pg_catalog.pg_indexes` + `pg_stat_user_indexes` query patterns are
well-documented in Postgres docs. Mix task repo resolution in non-started-app context may need a
quick check (see Gaps section). No broader research needed.

---

### Phase 3: Limiter CLI Tasks

**Rationale:** Wraps existing `Explain` + `Limits` modules — no new logic, just a CLI surface.
Depends on the Mix task file structure established in Phase 2. Ships the rate-limit glossary
footgun documented in the product context.

**Delivers:**
- `lib/mix/tasks/oban_powertools.limiter.explain.ex`
- `lib/mix/tasks/oban_powertools.limiter.simulate.ex`
- Rate-limit glossary in task `@moduledoc` / help output
- `--repo`, `--queue`, `--format json` options on both tasks
- Graceful WARN when no limiter config exists
- Integration tests against `Explain`/`Limits` with a seeded config

**Avoids:** limiter CLI crash pitfall (Pitfall 7).

**Research flag:** No new research needed — `ObanPowertools.Explain` and `ObanPowertools.Limits`
are existing, tested modules. The CLI is a formatting layer only.

---

### Phase 4: Telemetry Guide + `Telemetry.metrics/0`

**Rationale:** Single public function on an existing module — low implementation risk. The guide
is the high-value deliverable; it teaches adopters how to wire the frozen contract into
Parapet/Prometheus/Datadog without needing `oban_met`.

**Delivers:**
- `ObanPowertools.Telemetry.metrics/0` returning metric descriptors for all `@contract` events
- `guides/telemetry_slo.md` — Parapet wire-up, SLO examples, explicit "not included" section
- `mix.exs` `extras:` updated to include the guide in hexdocs
- Test: assert `metrics/0` covers exactly the events in `@contract`, nothing more

**Avoids:** low-cardinality contract drift pitfall (Pitfall 4).

**Research flag:** If returning typed `Telemetry.Metrics` structs, verify the struct API and
whether to add `telemetry_metrics` as optional or dev-only. If returning plain maps, no research
needed. This is a Phase 4 requirements-time decision.

---

### Phase 5: Getting-Started Verification + Release

**Rationale:** Verification must be the last phase, not an afterthought. Working tree must be
clean. Getting-started must be verified from the published tarball.

**Delivers:**
- Getting-started verified from a fresh Phoenix app using `{:oban_powertools, "~> 0.5"}` in
  `mix.exs` (not a path dep)
- Clean working tree confirmed (zero uncommitted changes — graduation rule enforced)
- CHANGELOG.md `0.5.0` entry finalized
- `mix hex.publish` executed (or staged for the maintainer)
- Git tag `v0.5.0` committed and pushed

**Avoids:** getting-started from dev pitfall (Pitfall 5); clean working tree pitfall (Pitfall 6).

**Research flag:** Standard hex publish flow. No research needed.

---

### Phase Ordering Rationale

- Phase 1 (hex prep) before everything: the publishable base must exist before features are added
  to the package; `files:` whitelist and ExDoc are Phase 1 outputs all subsequent phases depend on
- Phase 2 (doctor) before Phase 3 (limiter CLI): doctor establishes Mix task file structure and
  repo-resolution pattern that limiter CLI reuses
- Phases 2 and 3 before Phase 4 (telemetry): operability features first; telemetry guide is
  additive and can safely be the last feature phase
- Phase 5 (verification + release) always last: clean working tree rule requires all commits to
  precede the publish step; getting-started must reflect the final published package
- No phase can be skipped: Phase 1 establishes the publishable base; Phase 5 is the release gate

### Research Flags

Phases with standard patterns (no deeper research needed):
- **Phase 1** — hex packaging is well-documented in Hex docs and ExDoc guides
- **Phase 2** — `pg_catalog` query patterns are standard Postgres; Mix.Task is stdlib
- **Phase 3** — thin CLI over existing modules; no novel patterns
- **Phase 5** — `mix hex.publish` flow is documented in Hex docs

Phases that may benefit from a targeted verification pass:
- **Phase 4** — if returning typed `Telemetry.Metrics` structs rather than plain maps, verify
  the `telemetry_metrics` struct API and optional-dep implications; this is a design decision at
  requirements time, not a blocking research gap
- **Phase 2** — confirm Mix task repo resolution works when the OTP application is not started
  (see Gaps section); quick test or Hex forum check, not a research milestone

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new runtime deps; verified against locked mix.lock; ExDoc is standard; all four deliverables use existing primitives |
| Features | HIGH | Derived from post-v1.5 assessment grounded in repo source, tests, planning history, and 3 deep research agents |
| Architecture | HIGH | All four deliverables are additive to existing, well-understood modules; no new runtime architecture |
| Pitfalls | HIGH | Hex publish, read-only doctor, and cardinality pitfalls are well-known patterns in the Elixir/Hex ecosystem |

**Overall confidence: HIGH**

### Gaps to Address

1. **`Telemetry.metrics/0` return type decision** — Plain maps vs. `Telemetry.Metrics` structs.
   Plain maps avoid any new dep; structs are more ergonomic for Parapet users. Decide at Phase 4
   requirements time. If structs, confirm whether `telemetry_metrics` goes in as `optional: true`
   or `only: :dev`.

2. **Doctor task repo resolution in Mix task context** — Confirm whether
   `ObanPowertools.RuntimeConfig.repo!/1` works when the OTP application is not started (Mix task
   default). May require `Mix.Task.run("app.start")` before querying, or a `--repo MyApp.Repo`
   option that bypasses `RuntimeConfig`. Resolve at Phase 2 requirements time with a quick test.

3. **`files:` whitelist exact paths** — Verify whether guides live in `guides/` in the existing
   repo layout before writing the whitelist. Check for any Mix task files outside `lib/` (they
   must be inside `lib/` or `priv/` to be included cleanly). Resolve at Phase 1 requirements time
   by running `ls` on the repo root.

---

## Explicitly Out of Scope (Defer-Until-Signal)

The following items were considered and explicitly deferred. Do not re-introduce them in v1.6
requirements or roadmap phases:

| Item | Reason Deferred |
|------|-----------------|
| `oban_met` integration | v1.9; optional read source gated like `oban_web`; never a hard dep |
| Live job/queue counts (QRY-06) | Requires `oban_met` path; out of scope for a health milestone |
| `encrypt:` | Collides with args-hash idempotency; blinds v1.5 job filter; no proven demand |
| Prioritizer / autoscaler | Deferred until adoption proves demand |
| Batches | v1.8 |
| Worker lifecycle hooks | v1.7 |
| args/meta search qualifiers (QRY-05) | Post-v1.5 polish; not its own milestone |
| Cross-page bulk select-all (QRY-08) | Post-v1.5 polish |
| Nested batches / chunks / growable batches | Sidekiq's worst reliability area; defer indefinitely |
| Native metrics dashboard | = rebuild Oban Web; contradicts bounded scope |

---

## Sources

### Primary (HIGH confidence)

- `.planning/threads/2026-05-28-post-v1.5-next-milestone.md` — post-v1.5 milestone ordering
  assessment; grounded in repo source, tests, planning history, and 3 deep research agents;
  primary scoping authority for v1.6
- `.planning/research/STACK.md` (2026-05-27) — v1.5 stack research; confirms locked dep versions
  and no new runtime deps needed for v1.6
- `.planning/research/FEATURES.md` (2026-05-27) — v1.5 feature research; establishes anti-feature
  list (oban_met, delete, unbounded queries) carried forward to v1.6 defer list
- `.planning/research/ARCHITECTURE.md` (2026-05-27) — v1.5 architecture; component boundaries and
  integration patterns for modules doctor and limiter CLI will call
- `.planning/research/PITFALLS.md` (2026-05-27) — v1.5 pitfalls; telemetry cardinality contract
  and Lifeline pipeline constraints remain relevant as v1.6 build context
- `lib/oban_powertools/telemetry.ex` — frozen `@contract`; authoritative for `metrics/0` design
- `lib/oban_powertools/runtime_config.ex` — `repo!/1` pattern for Mix task repo resolution
- `prompts/oban_powertools_context.md` — product vision; names doctor and limiter CLI as
  explicit deliverables

### Secondary (MEDIUM confidence)

- Hex packaging documentation (hexdocs.pm/hex) — `files:` whitelist, `mix hex.publish --dry-run`
- ExDoc documentation (hexdocs.pm/ex_doc) — `extras:`, `@moduledoc`, guide configuration
- `Telemetry.Metrics` documentation (hexdocs.pm/telemetry_metrics) — struct API, if used for
  `metrics/0` return type

---

*Research completed: 2026-05-28*
*Ready for roadmap: yes*
