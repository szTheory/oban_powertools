# Pitfalls Research

**Domain:** First hex release + read-only DB doctor task + limiter explain/simulate CLI + opt-in telemetry metrics, added to a mature unpublished Elixir/Phoenix/Oban ops library
**Researched:** 2026-05-28
**Confidence:** HIGH — derived from direct inspection of mix.exs, telemetry.ex, the frozen @contract, RETROSPECTIVE.md, post-v1.5 thread, and known Hex/Postgres/Mix task failure patterns.

---

## Critical Pitfalls

### Pitfall 1: `package` key absent from mix.exs — ships test/dev cruft or omits migrations

**What goes wrong:**
`mix hex.publish` includes everything not `.gitignore`d unless the project defines an explicit `:files` list inside a `package/0` key. This codebase has no `package/0` function in mix.exs. Without it, `examples/phoenix_host/`, `examples/phoenix_host_upgrade_source/`, `prompts/`, `test/`, `erl_crash.dump`, `.planning/`, and all guide source files go into the tarball. Worse, if migrations are ever placed under `priv/repo/migrations/` (which `doctor` may need), the absence of an explicit `:files` list is the one silent way they get omitted — the hex tarball can build cleanly in-repo while adopters get `{:error, :enoent}` at runtime when the installed package is missing those files.

**Why it happens:**
Developers test `mix hex.build` from the repo, where the filesystem has everything. The tarball contains more than intended (or less, if priv files are missed). The asymmetry only surfaces when someone installs from hex.

**How to avoid:**
- Add an explicit `package/0` to mix.exs before publishing: `files: ~w[lib guides priv .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]`.
- Run `mix hex.build && tar tf oban_powertools-*.tar` and audit every file.
- Confirm that no `test/support/` module is reachable from the published lib (the existing `elixirc_paths` guard is correct but must be verified against the published tarball, not just the dev build).
- `mix.lock` belongs in the tarball so adopters can reproduce exact transitive versions.

**Warning signs:**
- `mix.exs` has no `package/0` function (current state — confirmed via inspection).
- `mix hex.build` output says "All files included" without an explicit list.
- `mix hex.publish --dry-run` shows files under `test/`, `examples/`, or `prompts/`.

**Phase to address:**
Phase 47 (Hex Release Prep) — must be the first gate before any publishing step.

---

### Pitfall 2: Publishing at a version that implies API stability (`1.0.0`) before real adopter feedback

**What goes wrong:**
A `1.0.0` release signals SemVer stability. The library has 0 public adopters and 0 external validation. After five internal milestones, several APIs (Lifeline, Operator, Telemetry contract, migration internals) still reflect the needs of one szTheory host. Publishing at `1.0.0` then making a breaking rename forces a `2.0.0` bump within months, destroying the "stable ops library" positioning.

**Why it happens:**
The repo feels "done" internally after a successful v1.5 milestone audit. The milestone naming (`v1.x`) is internal and does not map to hex versions, but the milestone numbering creates a false impression of maturity.

**How to avoid:**
- Publish at `0.5.0` as documented in PROJECT.md. The `0.x` range signals "no API freeze yet" by SemVer convention, which is accurate.
- Commit to `1.0` only after at least one external adopter has exercised the install, Operator API, and upgrade path.
- Update `CHANGELOG.md` and `README.md` to state the `0.x` instability window explicitly.

**Warning signs:**
- Any plan or phase description that says "bump to 1.0" without citing external adopter evidence.

**Phase to address:**
Phase 47 (Hex Release Prep) — set the version, changelog, and README stability statement.

---

### Pitfall 3: Getting-started only works in-repo (not from the published hex package)

**What goes wrong:**
The Igniter installer (`mix oban_powertools.install`) and the getting-started guide are tested only with `path: "../oban_powertools"` or the in-repo dev alias. After publishing, adopters run the installer from the hex release. Bugs common in this scenario: the installer references a module that is test-only (excluded from the tarball), migrations are missing from `priv/`, a guide references a file path that doesn't exist after `mix deps.get`, or an `@moduledoc` references a guide that the hex tarball doesn't include at the expected relative path.

**Why it happens:**
CI runs against the repo checkout, not an isolated hex consumer. Nobody ever creates a fresh `mix new` project, adds `{:oban_powertools, "~> 0.5"}` to deps, runs `mix deps.get`, and follows the README from scratch.

**How to avoid:**
- Create an `examples/hex_consumer/` project (distinct from the existing `examples/phoenix_host`) that uses `{:oban_powertools, "~> 0.5"}` from hex (or `git:` with a version tag) — not a local `path:` dep.
- Run the full install + first-session flow in this isolated consumer as part of the release gate.
- Add a `source_url_pattern` to `docs/0` in mix.exs so ExDoc links point to the correct tagged commit on hex, not the `main` branch.

**Warning signs:**
- CI only tests against the local workspace (current state).
- No hex_consumer example project exists; `examples/phoenix_host` uses `path:` dep.
- `source_ref` in `docs/0` is absent or defaults to `main` (current state — `docs/0` in mix.exs has no `source_ref` key).

**Phase to address:**
Phase 47 (Hex Release Prep) adds the `source_ref`; Phase 48 (Getting-Started Verification) creates and exercises the isolated hex consumer.

---

### Pitfall 4: `doctor` task executing write operations or holding locks against pg_catalog

**What goes wrong:**
`mix oban_powertools.doctor` is marketed as read-only diagnostics. If any query inside doctor acquires an `AccessShareLock` that blocks DDL on a busy system, or worse, if a developer accidentally issues `CREATE INDEX` / `ALTER TABLE` / `ANALYZE` (all plausible when "fixing" a detected problem), adopters run doctor in production and cause an outage instead of diagnosing one.

**Why it happens:**
`pg_catalog` queries (`pg_indexes`, `pg_class`, `pg_attribute`, `pg_constraint`) are intrinsically read-only, but developers unfamiliar with Postgres internals sometimes also query live user tables (e.g., `SELECT COUNT(*) FROM oban_jobs`) inside the same task for "completeness." Count queries hold `AccessShareLock` for the duration and can pile up behind DDL. More subtle: `ANALYZE oban_jobs` looks like a diagnostic but is a write operation.

**How to avoid:**
- Restrict all doctor queries strictly to `pg_catalog` and `information_schema` views — never query `oban_jobs` or any application table directly.
- No `UPDATE`, `DELETE`, `CREATE`, `ALTER`, `ANALYZE`, or `VACUUM` in doctor code paths. Add a comment to each query asserting this.
- Open all Ecto queries inside an explicit `Repo.transaction(fn -> ... end, mode: :read_only)` to make the guarantee machine-checked.
- Skip `CREATE INDEX CONCURRENTLY` advice output from inside the task — just report the missing index and tell the operator what command to run.

**Warning signs:**
- Any query in `doctor` that references a non-catalog table name.
- Doctor taking more than ~200ms to run (catalog queries should be sub-5ms on a healthy system; slow doctor = lock contention or seq scan on live tables).

**Phase to address:**
Phase 49 (doctor task implementation) — the read-only constraint must be part of the implementation spec, not an afterthought.

---

### Pitfall 5: `doctor` assuming a fixed Oban prefix/schema and breaking multi-schema setups

**What goes wrong:**
Oban supports a configurable `prefix:` (default `"public"`). If `doctor` hardcodes `oban_jobs` without respecting the configured prefix, it silently reports "no index found" for hosts using `prefix: "myapp"`, which has `myapp.oban_jobs`. Worse, it may succeed against the `public` schema (where there's no Oban table) and return a false healthy status.

**Why it happens:**
Developers test against the default prefix only. The `pg_catalog` query for indexes against `oban_jobs` must qualify the table by schema; without the schema the query matches any table named `oban_jobs` in any schema the search path finds first.

**How to avoid:**
- Read the Oban prefix from `Application.get_env(:oban, Oban)` (or `Config.fetch_env!/2`) at task startup; default to `"public"`.
- Pass `schemaname = $1` to all `pg_indexes` and `pg_class` queries.
- Test doctor against both `prefix: "public"` and `prefix: "myapp"` in the doctor test suite.
- If multiple Oban instances are configured (multiple repos, multiple prefixes), doctor must either iterate over all or document that it only checks the primary configuration and exits non-zero if it can't resolve one.

**Warning signs:**
- `doctor` test suite only has a single `prefix: "public"` fixture.
- `pg_indexes` query body has no `schemaname` clause.

**Phase to address:**
Phase 49 (doctor implementation).

---

### Pitfall 6: `doctor` false positive on valid non-default or dynamic index setups

**What goes wrong:**
Doctor reports "missing index" for configurations that are intentionally different from Oban's default migration layout — for example: a host that uses a partial index instead of a full composite index, a host that ran a manual `CREATE INDEX CONCURRENTLY` without going through Oban's migration, or a custom index naming convention from an ORM migration. Doctor reports a failure; the host's DB is actually fine. The operator spends time chasing a phantom.

**Why it happens:**
Doctor checks for index existence by name or by column-set pattern. Partial indexes and non-default names are invisible to a name-based check.

**How to avoid:**
- Check for index coverage by definition (column set + predicate), not by Oban's expected migration-generated name. `pg_index` joined to `pg_attribute` lets you verify whether a covering index exists for the column set, regardless of name.
- Distinguish between "missing index" (covered columns not present in any index) and "non-standard index name" (covered columns present but named differently). Report the latter as INFO/warn, not ERROR.
- Provide an escape hatch: an env var or Mix config flag (e.g., `DOCTOR_SKIP_INDEX_CHECKS=1`) so hosts with custom index layouts can suppress that check in CI.

**Warning signs:**
- Doctor checks index names with a string match (e.g., `index_name = 'oban_jobs_state_scheduled_at_id_index'`) rather than checking covering columns.

**Phase to address:**
Phase 49 (doctor implementation).

---

### Pitfall 7: `doctor` exit code not honest — CI breaks on informational findings

**What goes wrong:**
If `doctor` exits non-zero for any finding — including INFO/warn-level items like "migration at version X, latest is Y" — hosts wire it into CI and every non-latest migration state breaks the build, even for intentionally pinned migration versions. Conversely, if doctor exits 0 even when it found a CRITICAL issue (e.g., uniqueness index missing), it gives the host false assurance.

**Why it happens:**
Exit code semantics are underspecified. Developers default to `Mix.raise/1` or `System.halt(1)` on any non-empty finding, which is too aggressive.

**How to avoid:**
- Define a three-tier exit code convention before writing a line of task code:
  - `0` — all checks passed with no ERROR-level findings
  - `1` — at least one ERROR-level finding (index missing, config invalid, migration drift exceeds threshold)
  - `2` — task itself failed to run (DB unreachable, config missing)
- INFO and WARN findings always exit 0.
- Document the exit codes in the task's `@shortdoc` and in the guide.

**Warning signs:**
- Task uses `Mix.raise/1` for non-fatal findings (this exits 1 for warnings).
- No test asserting exit code behavior.

**Phase to address:**
Phase 49 (doctor implementation).

---

### Pitfall 8: `doctor` running migrations as a side effect

**What goes wrong:**
A developer adds `Mix.Task.run("ecto.migrate", [])` or `Ecto.Migrator` calls inside doctor "to ensure a clean baseline before checking." This is catastrophic: doctor gets wired into a read-only staging check, then silently migrates production on the first run.

**Why it happens:**
The impulse is to be helpful — "fix detected migration drift automatically." In an ops library, helpful = dangerous.

**How to avoid:**
- doctor NEVER calls any task that modifies the DB schema, not even conditionally.
- Doctor outputs the migration commands the operator should run, as copy-pasteable strings.
- Add an explicit `# NO WRITES — read-only` comment block at the top of the doctor task module.

**Warning signs:**
- Any `Mix.Task.run` call inside doctor that is not itself a read-only task.
- Any `Ecto.Migrator` call inside doctor.

**Phase to address:**
Phase 49 (doctor implementation).

---

### Pitfall 9: Limiter CLI duplicating `Explain`/`Limits` logic instead of delegating to existing modules

**What goes wrong:**
`mix oban_powertools.limiter.explain` and `.simulate` re-implement blocker resolution or rate window arithmetic inline in the Mix task rather than calling `ObanPowertools.Explain` and `ObanPowertools.Limits`. The task output then drifts from runtime behavior within a few commits, producing a CLI that describes a subtly different limiter than the one actually running.

**Why it happens:**
Mix tasks feel like "plumbing code" and developers copy-paste core logic rather than requiring the app modules. In a Mix task, the app may not be started, so `Application.get_env` calls or GenServer calls into `Limits` appear to fail — the temptation is to inline the logic instead.

**How to avoid:**
- Call `Mix.Task.run("app.start")` (or target the repo only with `Mix.Task.run("app.config")`) at the top of the task, then delegate to `ObanPowertools.Explain.explain/1` and `ObanPowertools.Limits.query/1` directly — the same public functions the runtime uses.
- The task is responsible only for formatting output and parsing CLI flags. All logic lives in the existing modules.
- Add a test that calls the Mix task and asserts its output matches the output of calling `Explain.explain/1` directly with the same input.

**Warning signs:**
- The task module contains arithmetic involving rate windows, token buckets, or blocker codes.
- The task does not call `app.start` or `app.config` before querying limiter state.

**Phase to address:**
Phase 50 (limiter CLI implementation).

---

### Pitfall 10: `limiter.simulate` mutating real rate limiter state

**What goes wrong:**
`.simulate` is supposed to show what would happen if a job were enqueued. If simulate calls the actual `Limits.decrement/2` or `Limits.check_and_reserve/2` path, it consumes a real token from the limiter's running counter. Under load, a developer running simulate repeatedly to demo the feature accidentally depletes the live rate limit budget for production jobs.

**Why it happens:**
The simulate command is written against the real limiter without a dry-run path, because the limiter module has no dry-run variant yet.

**How to avoid:**
- `.simulate` must call only the read path (`Limits.explain/1` or equivalent) — never the reservation/decrement path.
- Implement simulate as: "fetch current limiter state, compute whether the hypothetical job would be admitted, print the result" — no state change.
- Document in the task `@shortdoc` and the guide that `.simulate` is read-only and never affects live counters.

**Warning signs:**
- `.simulate` calling any function whose name includes `reserve`, `decrement`, `acquire`, or `consume`.
- `.simulate` test assertions that check limiter counter state before and after the task runs.

**Phase to address:**
Phase 50 (limiter CLI implementation).

---

### Pitfall 11: Telemetry metrics using high-cardinality tags, violating the frozen `@contract`

**What goes wrong:**
`Telemetry.metrics/0` returns a list of `Telemetry.Metrics` structs. Each metric has a `:tags` key that pulls values from the event metadata. If a tag is `job_id`, `worker` (unbounded — any module name), `reason` (free text), or `args` (user data), the metrics backend (StatsD, Prometheus, etc.) creates one time series per distinct value. A host with 500 workers generates 500 distinct metric label combinations per event family, overwhelming most metric backends and violating the low-cardinality contract that is explicitly frozen in `telemetry.ex`.

**Why it happens:**
The `@contract` in `ObanPowertools.Telemetry` defines allowed metadata keys per event family. `Telemetry.metrics/0` is written by a different phase (or a different plan) without cross-checking the `@contract` allowed list. The available metadata map looks rich; the temptation is to expose it all.

**How to avoid:**
- `Telemetry.metrics/0` must only reference tag keys that are explicitly in `@contract.families` for each event family. Concretely:
  - `:operator_action` events: only `[:action, :source]` as tags
  - `:limiter` events: only `[:action, :blocker_code, :resource, :scope]`
  - `:cron` events: only `[:action, :source, :overlap_policy, :catch_up_policy]`
  - `:lifeline` events: only `[:action, :incident_class, :target_type, :outcome]` — note that `:archived_count` and `:pruned_count` are counts/measurements, not labels; they belong as metric values, not tags
  - `:workflow` events: only the keys listed per sub-event in `@contract.families.workflow`
- Add a compile-time assertion (or a test) that verifies every tag key used in `Telemetry.metrics/0` is present in `@contract.families` for the corresponding event.
- Never add `worker`, `job_id`, `reason`, `args`, `meta`, or any user-data-derived key as a tag.

**Warning signs:**
- A `Telemetry.Metrics.counter/2` call with `tags: [:worker]` or `tags: [:job_id]`.
- Any tag key in `Telemetry.metrics/0` that is not listed in `@contract`.

**Phase to address:**
Phase 51 (opt-in `Telemetry.metrics/0` implementation).

---

### Pitfall 12: `Telemetry.metrics/0` forcing a reporter dependency or being called unconditionally

**What goes wrong:**
The guide or the library calls `Telemetry.metrics/0` inside `Application.start/2` or wires it automatically during `mix oban_powertools.install`. This forces adopters to either ship a `telemetry_metrics_statsd` / `telemetry_metrics_prometheus` reporter they didn't choose, or it crashes at startup when no reporter is configured. This directly violates the "no new runtime deps" and "opt-in" constraints.

**Why it happens:**
Libraries that want to "just work" are tempted to include a default reporter. Oban itself takes the correct approach (no default reporter, just events). Departing from Oban's convention in an Oban extension is a footgun.

**How to avoid:**
- `Telemetry.metrics/0` is a pure function that returns a list of metric definitions. It does nothing at call time.
- The guide documents how to pass `ObanPowertools.Telemetry.metrics()` into the host's existing `Telemetry` supervisor (e.g., `TelemetryMetricsStatsd` or `TelemetryMetricsPrometheus`).
- The installer (`mix oban_powertools.install`) must not add any reporter to the host's supervision tree. It may add a commented-out example snippet.
- `mix.exs` must not list any `telemetry_metrics_*` package as a dep — not even `optional: true`. Keep the current `{:telemetry, "~> 1.4"}` as the only telemetry dep.

**Warning signs:**
- `mix oban_powertools.install` modifying `Application.start/2` or `application.ex` to wire a reporter.
- Any `telemetry_metrics` package appearing in `mix.exs`.
- `Telemetry.metrics/0` calling `:telemetry.attach` or `:telemetry.attach_many`.

**Phase to address:**
Phase 51 (opt-in telemetry metrics).

---

### Pitfall 13: Metric names in `Telemetry.metrics/0` diverging from `@contract` event names

**What goes wrong:**
`Telemetry.Metrics.counter("oban_powertools.operator_action.executed")` matches the event `[:oban_powertools, :operator_action, :executed]` only if the dotted name in the metric definition perfectly mirrors the list representation used in `:telemetry.execute/3`. If the metric uses `"oban_powertools.operator.action"` (wrong grouping) or `"powertools.operator_action.executed"` (wrong prefix), the metric is silently never incremented — no error, just zero counts forever.

**Why it happens:**
`Telemetry.Metrics` uses a dotted-string name that gets split on `.` to find the matching event. A typo or grouping error in the string produces a metric that attaches to an event that never fires.

**How to avoid:**
- Derive metric names programmatically from `@contract.families` keys rather than writing them as free-form strings. Use a helper that converts `[:oban_powertools, :limiter, :blocked]` to `"oban_powertools.limiter.blocked"`.
- Add tests that verify `Telemetry.metrics/0` returns a non-empty list and that each metric's event name matches a known event emitted by the telemetry module.
- Cross-check: for every `execute_*_event/3` call in `telemetry.ex`, there should be at most one corresponding `Telemetry.Metrics` entry in `metrics/0`.

**Warning signs:**
- Metric definitions written as raw string literals without a corresponding reference to the `@contract` map.
- `Telemetry.metrics/0` test that only checks `length(metrics) > 0` without checking event name accuracy.

**Phase to address:**
Phase 51 (opt-in telemetry metrics).

---

### Pitfall 14: `igniter` is a hard runtime dep instead of dev-only

**What goes wrong:**
The current `mix.exs` lists `{:igniter, "~> 0.8.0"}` without `only: :dev` or `runtime: false`. This means `igniter` — a code-generation/AST-transformation library — is a runtime dependency that every host app must compile and ship to production. Igniter is only needed during `mix oban_powertools.install`, not at runtime. Hex adopters will see igniter pulled into their production release, adding compilation time and a transitive dep footprint they didn't choose.

**Why it happens:**
Igniter is added as a dep to make the installer work during development, and developers forget to scope it because it "has to be available" when running mix tasks. In fact, Mix tasks run in the dev/test environment; the production release does not need installer machinery.

**How to avoid:**
- Scope igniter: `{:igniter, "~> 0.8.0", only: [:dev, :test], runtime: false}`.
- Verify after the change: `mix hex.build` should not include igniter as a runtime dep in the package manifest.
- Cross-check all deps in `mix.exs` for similar scope issues before publishing:
  - `ex_doc` already has `only: :dev, runtime: false` — correct.
  - `lazy_html` already has `only: :test` — correct.
  - `igniter` does not — fix before publish.

**Warning signs:**
- `mix hex.info oban_powertools` after publish shows igniter as a runtime dep.
- `mix hex.build` output lists igniter without a `(dev)` qualifier.

**Phase to address:**
Phase 47 (Hex Release Prep) — fix in the same edit that adds `package/0`.

---

### Pitfall 15: ExDoc `source_ref` absent — hex docs link to `main` instead of the release tag

**What goes wrong:**
ExDoc publishes documentation to hexdocs.pm. Without `source_ref` set to the published git tag (e.g., `"v0.5.0"`), all "View source" links in the published docs point to `main` on GitHub. For adopters reading the docs for `0.5.0`, source links open code on `main` that may have diverged. This is a first-impression trust issue for a library publishing for the first time.

**Why it happens:**
`source_ref` is an opt-in ExDoc config key. The current `docs/0` in mix.exs has no `source_ref` or `source_url_pattern` keys (confirmed by inspection).

**How to avoid:**
- Add to `docs/0`:
  ```elixir
  source_url: "https://github.com/szTheory/oban_powertools",
  source_ref: "v#{@version}",
  source_url_pattern: "https://github.com/szTheory/oban_powertools/blob/v#{@version}/%{path}#L%{line}"
  ```
- Define `@version` as a module attribute at the top of mix.exs referencing the version string.
- Verify links in `mix docs` output before publishing.

**Warning signs:**
- `docs/0` in mix.exs has no `source_ref` key (current state — confirmed).
- "View source" links in local `mix docs` output all resolve to `/main/` instead of a version tag.

**Phase to address:**
Phase 47 (Hex Release Prep).

---

### Pitfall 16: `CHANGELOG.md` absent — adopters can't evaluate version-to-version changes

**What goes wrong:**
Hex.pm surfaces the changelog on the package page. Adopters deciding whether to upgrade from `0.5.0` to `0.6.0` rely on it. Without one, the library appears unmaintained. Additionally, `mix hex.publish` warns if `CHANGELOG.md` is absent, and some CI pipelines treat that warning as an error.

**Why it happens:**
The project never had a public changelog because it was never published. Internal milestones use `RETROSPECTIVE.md` instead, which is internal and not in a hex-conventional format.

**How to avoid:**
- Create `CHANGELOG.md` before the first `mix hex.publish` with an `## [0.5.0] — 2026-05-28` section summarizing the first release contents.
- Include `CHANGELOG.md` in the `package/0` `:files` list.
- Add a `changelog:` key to `docs/0` so hexdocs renders it.

**Warning signs:**
- No `CHANGELOG.md` at repo root (current state — confirmed by directory listing).
- `mix hex.build --dry-run` emits a changelog warning.

**Phase to address:**
Phase 47 (Hex Release Prep).

---

### Pitfall 17: Audit/verification passing while working tree is dirty — v1.5 repeat risk

**What goes wrong:**
v1.5 phases 44 and 45 had SUMMARY files claiming "all tests passing" while the `JobsLive` implementation existed only as uncommitted working-tree changes. The audit reported `passed` because it validated working-tree state, not committed state. For v1.6, the hex publish step makes this materially worse: `mix hex.publish` ships whatever is in the working tree at publish time, not the last committed state. A dirty tree at publish time risks shipping uncommitted, partially-written, or partially-reverted code to hex adopters.

**Why it happens:**
Agents (and developers) verify "green tests" and "SUMMARY complete" as phase-done signals without asserting `git status --porcelain` is clean. The audit step also checks working-tree files for milestone verification instead of checking `git log` for the expected phase commit.

**How to avoid:**
- Every phase verification step must run `git status --porcelain` and assert empty output before declaring the phase complete. Non-empty output = phase is not done, regardless of test results.
- The milestone audit must include an explicit `git status --porcelain` clean-tree assertion as its first check, before any functional tests.
- Before `mix hex.publish` (Phase 47), add a CI gate that fails if `git status --porcelain` is non-empty.
- Per the post-v1.5 thread: this is a cross-phase GSD process rule that should be graduated into the audit/verification contract for all remaining milestones, not just noted in the retrospective.

**Warning signs:**
- A SUMMARY file for a phase says "tests pass" but there is no `feat(XX-*)` commit in `git log` for that phase.
- The milestone audit script does not invoke `git status`.
- `mix hex.publish` is executed without first asserting a clean tree.

**Phase to address:**
Phase 47 (Hex Release Prep) — add the clean-tree check as the first gate. All subsequent v1.6 phases must include `git status --porcelain` assertion in their verification steps as a standing contract.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skipping `package/0` in mix.exs | No extra config to write | Publishes test/dev cruft or silently omits priv files; only surfaces after install from hex | Never — add `package/0` before first publish |
| Testing installer only via `path:` dep | Fast iteration in dev | Installation from hex is never validated; adopters hit install bugs on day one | Never for the release gate; acceptable in pre-publish dev phases |
| Using metric tag keys not in `@contract` | Richer dashboards in dev | High-cardinality tag explosion in production metric backends; violates frozen contract | Never |
| Writing doctor queries against live `oban_jobs` table | Simpler code path | Table locks in production during operator diagnosis; defeats the read-only guarantee | Never |
| Checking working-tree state instead of committed state in audits | Slightly faster audit | Audit passes for uncommitted work; dirty-tree code ships to hex | Never |
| Scoping `igniter` as a runtime dep | No dep scoping needed | Every host's production release ships installer machinery; bloated release | Never — fix before first publish |
| Publishing at `1.0.0` before external validation | Appears stable and complete | Breaking rename forces `2.0.0` within months; undermines trust | Never — use `0.x` until adoption confirms stability |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|-----------------|
| Igniter installer + hex release | Installer tested with `path:` dep only; breaks from hex | Test with an isolated `examples/hex_consumer/` using the published package or a git tag ref |
| Frozen telemetry `@contract` + `Telemetry.metrics/0` | Writing metric tags without cross-checking `@contract.families` | Derive tag lists programmatically from `@contract`; add a test asserting tag keys are a subset of the allowed list |
| Oban prefix config + doctor | Hardcoding `"public"` schema in `pg_catalog` queries | Read `prefix` from Oban config at task startup; parameterize all catalog queries with `schemaname = $1` |
| `Limits`/`Explain` + limiter CLI | Inlining limiter arithmetic in the Mix task | Task delegates entirely to `Explain`/`Limits` modules; no arithmetic in the task module |
| `mix hex.publish` + dirty working tree | Publishing after a test-only fix without committing | Assert `git status --porcelain` empty as the first step in the publish checklist |
| ExDoc + hex publish | Source links resolve to `main` instead of the release tag | Set `source_ref: "v#{@version}"` and `source_url_pattern` in `docs/0` before first `mix hex.build` |
| `Telemetry.metrics/0` + optional reporters | Wiring a default reporter in the installer | `Telemetry.metrics/0` is a pure function; reporter wiring belongs entirely in the host's supervision tree |
| Deterministic host-owned migrations + doctor | Doctor triggering migrations or assuming migration sequence | Doctor reads migration table as a catalog query only; outputs commands for operators to run, never runs them |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `doctor` querying live `oban_jobs` for row counts | Doctor takes 10s+ on large job tables; holds `AccessShareLock` | Restrict to `pg_catalog` and `information_schema` only | Any production host with >100k jobs |
| `doctor` without `schemaname` in `pg_indexes` query | False healthy result on non-default Oban prefix; or false error on default prefix with a same-named table elsewhere | Always parameterize by `schemaname = $1` from Oban config | Any host using `prefix: "myapp"` |
| `limiter.simulate` calling the reservation path | Depletes live token budget under repeated CLI invocation | Read-only explain path only in simulate | Any host with a rate-limited resource under load |

---

## "Looks Done But Isn't" Checklist

- [ ] **Hex release:** `mix hex.build && tar tf *.tar` audited — no `test/`, `examples/`, `prompts/`, `.planning/` files; all `priv/` and `guides/` files present
- [ ] **Hex release:** `CHANGELOG.md` exists at repo root and is included in `package/0 :files`
- [ ] **Hex release:** `source_ref` set to the release tag in `docs/0`
- [ ] **Hex release:** `igniter` scoped to `only: [:dev, :test], runtime: false`
- [ ] **Hex release:** version is `0.5.0`, not `1.0.0`
- [ ] **Hex release:** `git status --porcelain` is empty before `mix hex.publish`
- [ ] **Getting-started verification:** install flow exercised from an isolated hex consumer (not a `path:` dep)
- [ ] **doctor:** all queries qualified by Oban prefix from config
- [ ] **doctor:** no query references a non-catalog table
- [ ] **doctor:** exit code 0/1/2 behavior has a test
- [ ] **doctor:** no `Mix.Task.run("ecto.migrate")` or `Ecto.Migrator` call anywhere in the task
- [ ] **limiter CLI:** `.simulate` calls no function with `reserve`, `decrement`, `acquire`, or `consume` in its name
- [ ] **limiter CLI:** task delegates to `Explain`/`Limits` modules; no arithmetic inlined in the task module
- [ ] **Telemetry.metrics/0:** every tag key is present in `@contract.families` for its event family
- [ ] **Telemetry.metrics/0:** `mix.exs` has no `telemetry_metrics_*` dep (even optional)
- [ ] **Telemetry.metrics/0:** installer does not wire a reporter or modify `Application.start/2`
- [ ] **All phases:** phase verification includes `git status --porcelain` clean-tree assertion before declaring done

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| `package/0` absent — cruft included or priv omitted | Phase 47 (Hex Release Prep) | `tar tf` audit of `mix hex.build` output |
| Version implies premature API stability (`1.0`) | Phase 47 | Version is `0.5.0` in mix.exs and CHANGELOG |
| `igniter` is a runtime dep | Phase 47 | `mix hex.build` output shows igniter as dev-only dep |
| ExDoc `source_ref` absent | Phase 47 | `mix docs` "View source" links resolve to tag, not `main` |
| `CHANGELOG.md` absent | Phase 47 | `CHANGELOG.md` present and in `package/0 :files` |
| Dirty-tree audit passes (v1.5 recurrence) | Phase 47 (release gate) + all phases (standing contract) | `git status --porcelain` assertion in every verification step |
| Getting-started only works in-repo | Phase 48 (Hex Consumer Verification) | Install + first session passes from `examples/hex_consumer/` with published package |
| `doctor` write operations or table locks | Phase 49 (doctor implementation) | All queries in `Repo.transaction(mode: :read_only)`; no non-catalog table refs |
| `doctor` fixed schema / multi-prefix blindness | Phase 49 | Test suite exercises both `"public"` and `"myapp"` prefixes |
| `doctor` false positive on valid non-default indexes | Phase 49 | Index check uses column coverage query, not name match |
| `doctor` exit code ambiguity breaks CI | Phase 49 | Exit 0/1/2 semantics tested with asserting task return value |
| `doctor` running migrations | Phase 49 | Code review gate: no `Ecto.Migrator` or `ecto.migrate` task call in doctor module |
| Limiter CLI duplicates logic | Phase 50 (limiter CLI) | Task delegates to `Explain`/`Limits`; no arithmetic in task module |
| `.simulate` mutates live state | Phase 50 | `.simulate` has no `reserve`/`decrement` call path; counter is unchanged after task run |
| Telemetry metrics high-cardinality tags | Phase 51 (opt-in metrics) | Test: every tag in `Telemetry.metrics/0` is a key in `@contract.families` for its event |
| Metric names diverge from `@contract` events | Phase 51 | Test: every metric event name matches a known `execute_*_event/3` call in telemetry.ex |
| `Telemetry.metrics/0` forces a reporter dep | Phase 51 | `mix.exs` has no `telemetry_metrics_*`; installer diff shows no reporter wiring |

---

## Sources

- Direct inspection: `/Users/jon/projects/oban_powertools/mix.exs` — confirmed `package/0` absent, `source_ref` absent, `igniter` unscoped as runtime dep, no `CHANGELOG.md`
- Direct inspection: `/Users/jon/projects/oban_powertools/lib/oban_powertools/telemetry.ex` — frozen `@contract` with per-family allowed metadata key lists; `:archived_count` and `:pruned_count` are measurement keys, not tag keys
- `/Users/jon/projects/oban_powertools/.planning/RETROSPECTIVE.md` — v1.5 uncommitted-phase lesson (phases 44/45 audited `passed` while never committed); v1.4 gap-closure tail from deferred proof artifacts
- `/Users/jon/projects/oban_powertools/.planning/threads/2026-05-28-post-v1.5-next-milestone.md` — clean-working-tree graduation candidate; overbuilding verdict; `igniter` and `oban_met` dep constraints; zero-new-deps requirement
- `/Users/jon/projects/oban_powertools/.planning/PROJECT.md` — "no new runtime deps", frozen low-cardinality telemetry constraint, host-ownership boundary, Decision Posture, defer-until-signal list

---
*Pitfalls research for: Oban Powertools v1.6 Release & Operability*
*Researched: 2026-05-28*
