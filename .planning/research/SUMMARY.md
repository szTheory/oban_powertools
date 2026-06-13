# Research Summary: v1.8 Integration Fixes

**Project:** Oban Powertools
**Domain:** Elixir library — surgical bug fixes to close integration gaps deferred from v1.7
**Researched:** 2026-06-13
**Confidence:** HIGH

## Executive Summary

This milestone addresses two integration gaps deferred from v1.7. Both are narrowly scoped: a one-line data change to a compile-time manifest and a three-line addition to a private function. No new modules, no new tables, no new migrations, no public API changes. The combined touch surface is four files (two production, two test).

INT-01 adds `oban_powertools_job_records` to `@powertools_manifest` in `doctor/checks.ex`, closing a gap where Doctor never warned when the Phase 55 output-recording table was missing from an adopter's database. The manifest's generic iteration logic (`Enum.flat_map`) picks up the new group automatically — the fix is purely a data addition. INT-02 injects `__deadline_at__` meta on the cron scheduling path in `cron.ex`, closing a gap where cron-enqueued jobs from `deadline:`-configured Powertools workers never had their deadline written into job meta, even though the non-cron path (`Idempotency.transaction/3`) handled this correctly.

The primary risk in both fixes is meta key collision in INT-02: deadline meta must be injected into opts before `worker_module.new/2` is called so that `Redaction.apply/4` merges `__redacted_fields__` on top rather than clobbering the deadline key. The existing `deep_merge` pattern from `Idempotency` and `Redaction` is the established safe pattern and must be followed. INT-01 carries no meaningful risk beyond a table name typo, which the existing happy-path test catches immediately.

## Key Findings

### Recommended Stack (from STACK.md)

Two targeted edits to existing production files. All logic reuses established in-library APIs with no new imports or dependencies.

**Files modified:**
- `lib/oban_powertools/doctor/checks.ex` — INT-01: add one map key to `@powertools_manifest` after line 58
- `lib/oban_powertools/cron.ex` — INT-02: add deadline injection inside the `function_exported?` Powertools branch of `maybe_insert_job/4`; thread `now` as a fifth parameter through all four clause heads and the Multi.run call site

**Reused APIs (no changes to these):**
- `ObanPowertools.Worker.Deadlines.build_meta/2` — takes `(nil | integer, DateTime)`, returns `%{}` or `%{"__deadline_at__" => iso_string}`
- `ObanPowertools.Worker.Deadlines.meta_key/0` — returns `"__deadline_at__"`
- `ObanPowertools.Worker.Redaction.apply/4` — already handles `__redacted_fields__` via `deep_merge`; composes safely with deadline meta placed in opts before the call

**Key implementation note:** `now` in `claim_slot/4` is already bound at line 52 and injectable via the Multi.run closure — no new clock parameter is needed at the public API level.

### Expected Features (from FEATURES.md)

Both fixes are internal correctness gaps, not user-visible features.

**Must have (table stakes):**
- INT-01: When `oban_powertools_job_records` is absent from the DB, `powertools_tables/1` returns an error finding naming the table and its migration set — operators need actionable Doctor output
- INT-01: When all tables are present, `powertools_tables/1` returns `[]` — no regression on the happy path
- INT-02: Powertools cron workers with `deadline:` produce `meta["__deadline_at__"]` in the stored job — parity with the non-cron enqueue path
- INT-02: Powertools cron workers without `deadline:` produce no `__deadline_at__` key — nil build_meta returns `%{}`, safe no-op
- INT-02: Workers with both `redact:` and `deadline:` produce both `__redacted_fields__` and `__deadline_at__` in meta — composition must work

**Defer (not in scope):**
- Any Doctor check on column structure (not schema-aware by design)
- Deadline injection into the `rescue ArgumentError` fallback path for unloaded worker modules (intentional graceful degrade)
- Idempotency path changes (already correct; reference only)

### Architecture Approach (from ARCHITECTURE.md)

INT-01 is a pure data change to a compile-time module attribute. The manifest's `Enum.flat_map` consumer requires zero logic changes — a new key is sufficient.

INT-02 requires understanding the call chain in `maybe_insert_job/4`:

```
claim_slot/4
  -> Multi.run(:job, fn repo, %{decision: decision} ->
       maybe_insert_job(repo, entry, args, decision, now)
     end)
     -> maybe_insert_job (3 skip clauses ignore `_now`)
     -> maybe_insert_job active clause:
          worker_module = String.to_existing_atom(...)
          if function_exported?(worker_module, :__powertools_limits__, 0) do
            deadline_ms = worker_module.__powertools_deadline_ms__()
            deadline_meta = ObanPowertools.Worker.Deadlines.build_meta(deadline_ms, now)
            worker_module.new(args, queue: queue, meta: deadline_meta)
              -> Redaction.apply merges __redacted_fields__ into deadline_meta
              -> __powertools_new_delegate__ -> Oban.Job.new with both keys in meta
          else
            Oban.Job.new(args, worker: entry.worker, queue: queue)  # plain worker, no injection
          end
     rescue ArgumentError -> Oban.Job.new(...)  # unloaded module, no injection
```

**Major components (modified):**
1. `Doctor.Checks.@powertools_manifest` — compile-time data registry; add `"output-recording"` group
2. `Cron.maybe_insert_job/4` — job insertion path; add `now` parameter and deadline injection
3. `Worker.Deadlines.build_meta/2` — reused unchanged; handles nil safely
4. `Worker.Redaction.apply/4` — reused unchanged; deep_merge composes with deadline meta

### Critical Pitfalls (from PITFALLS.md)

1. **Meta clobber via wrong merge order (INT-02)** — Do not post-process the changeset after `worker_module.new/2`. Build deadline meta first, pass it in opts before the call. `Redaction.apply/4` then merges `__redacted_fields__` on top. The failure mode is using `Keyword.put(:meta, ...)` instead of passing `meta: deadline_meta` in opts, which would cause redaction to overwrite the deadline key.

2. **Deadline meta leaking into plain-worker fallback path (INT-02)** — Deadline injection must be inside the `function_exported?(:__powertools_limits__, 0)` true branch only. Computing deadline meta before the branch and accidentally threading it into the `else` or `rescue` paths puts `__deadline_at__` on plain Oban worker jobs, which could trigger false Doctor expiry findings. Add `refute Map.has_key?(stored_job.meta, "__deadline_at__")` to the existing plain-worker cron test.

3. **`now` not injectable without signature change (INT-02)** — Using `DateTime.utc_now()` directly inside `maybe_insert_job` makes deadline values non-deterministic in tests. Thread `now` as a fifth parameter from `claim_slot/4` (already bound at line 52) through the Multi.run lambda. All four `maybe_insert_job` clause heads need the `_now` parameter including the three no-op skip clauses.

4. **Table name typo in manifest produces false-positive errors on healthy installs (INT-01)** — The string `"oban_powertools_job_records"` is matched against `information_schema.tables.table_name`. Any typo produces a constant error finding on every adopter who ran Phase 55 migrations. The existing `"returns [] on migrated test DB"` test is the immediate canary.

5. **Test description drift on INT-01** — The test at `checks_test.exs:104` says "all 4 groups present". After adding the fifth group, update the description to "all 5 groups present" to prevent future confusion.

## Implications for Roadmap

These fixes are fully independent and can be built in either order or as a single phase. Given their minimal scope, a single implementation phase covering both is appropriate.

### Phase 1: Doctor Manifest Fix (INT-01)

**Rationale:** Trivial, highest confidence, zero risk. Establishes a clean test baseline before touching cron.
**Delivers:** Doctor correctly warns when `oban_powertools_job_records` is absent from the DB.
**Addresses:** Add `"output-recording" => ["oban_powertools_job_records"]` to `@powertools_manifest`; update test description; add one missing-table test using the DROP/restore pattern from the `missing_indexes` test.
**Avoids:** Table name typo (caught immediately by happy-path test); stale "4 groups" test description.

### Phase 2: Cron Deadline Injection (INT-02)

**Rationale:** More code changes than INT-01 (parameter threading, new inject logic, 3-4 new tests) but still surgical. Building after INT-01 gives a green test suite baseline to diff against.
**Delivers:** Cron-scheduled Powertools workers with `deadline:` produce `__deadline_at__` in job meta, matching the non-cron path behavior.
**Implements:** Thread `now` through `maybe_insert_job`; inject `Deadlines.build_meta` result into opts before `worker_module.new/2`; add `CronDeadlineWorker` test fixture and 3-4 tests covering: deadline present, deadline absent, redact+deadline composition, plain-worker unchanged.
**Avoids:** Meta clobber (use `meta: deadline_meta` in opts, not post-changeset mutation); deadline leaking to plain workers (inject inside the `function_exported?` true branch only); non-deterministic test timestamps (thread `now` from `claim_slot`).

### Phase Ordering Rationale

- INT-01 and INT-02 are fully independent with no shared code paths.
- INT-01 is lower risk (data change only) and produces immediate test feedback via existing happy-path assertions.
- INT-02 requires parameter-signature changes across four function clauses and careful merge ordering — doing it second on a green baseline reduces debugging surface.
- Either order is safe; the above order is recommended for confidence.

### Research Flags

No further research needed. Both fixes have HIGH-confidence implementation plans based on direct code inspection of all affected files. The implementation details in STACK.md and ARCHITECTURE.md are prescriptive and ready to execute.

**Skip research-phase for both phases** — patterns are well-established in the existing codebase (`idempotency.ex` as reference implementation for INT-02; existing manifest structure for INT-01).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Direct code reading of all affected files; exact line numbers confirmed |
| Features | HIGH | Both fixes are correctness gaps with clear done criteria and test assertions specified |
| Architecture | HIGH | Full call chain traced; data flow confirmed in ARCHITECTURE.md |
| Pitfalls | HIGH | All pitfalls identified from direct reading of production code and test files |

**Overall confidence:** HIGH

### Gaps to Address

- **Group name `"output-recording"` for INT-01** — MEDIUM confidence. Logical choice matching the `record_output:` option and `ObanPowertools.JobRecord` schema, consistent with existing naming convention (feature-domain labels). No pre-existing authoritative string to copy from the installer. Acceptable; document with a comment in the manifest citing `setup_job_record_migrations/1`.
- **Test time-window for INT-02 deadline assertion** — use a `±30s` window around `now + deadline_ms` to eliminate flake without being meaninglessly wide. Test implementation detail, not a code correctness concern.

## Sources

### Primary (HIGH confidence — direct code inspection)

- `lib/oban_powertools/doctor/checks.ex` lines 24-59, 244-288 — `@powertools_manifest`, `powertools_tables/1`
- `lib/mix/tasks/oban_powertools.install.ex` lines 842-874 — `setup_job_record_migrations/1`
- `lib/oban_powertools/cron.ex` lines 50-104, 432-459 — `claim_slot/4`, `maybe_insert_job/4`
- `lib/oban_powertools/idempotency.ex` lines 147-181 — `merge_powertools_meta/4` (reference implementation for INT-02)
- `lib/oban_powertools/worker/deadlines.ex` lines 4-23 — `build_meta/2`, `meta_key/0`
- `lib/oban_powertools/worker/redaction.ex` lines 1-56 — `apply/4`, `inject_meta/2`
- `lib/oban_powertools/worker.ex` lines 138-151 — `new/2` override, `__powertools_new_delegate__/2`
- `test/oban_powertools/doctor/checks_test.exs` line 104 — existing happy-path test
- `test/oban_powertools/cron_test.exs` lines 212-274 — existing Phase 56 redaction tests
- `.planning/PROJECT.md` — INT-01/INT-02 deferred-gap descriptions

---
*Research completed: 2026-06-13*
*Ready for roadmap: yes*
