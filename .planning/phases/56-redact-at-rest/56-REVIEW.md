---
phase: 56-redact-at-rest
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - guides/workers-and-idempotency.md
  - lib/oban_powertools/cron.ex
  - lib/oban_powertools/runtime_config.ex
  - lib/oban_powertools/web/jobs_live.ex
  - lib/oban_powertools/worker.ex
  - lib/oban_powertools/worker/redaction.ex
  - test/oban_powertools/cron_test.exs
  - test/oban_powertools/docs_contract_test.exs
  - test/oban_powertools/idempotency_test.exs
  - test/oban_powertools/web/live/jobs_live_test.exs
  - test/oban_powertools/worker_redact_test.exs
findings:
  critical: 2
  warning: 3
  info: 2
  total: 7
status: issues_found
---

# Phase 56: Code Review Report

**Reviewed:** 2026-06-13T00:00:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

This phase introduces at-rest argument redaction (`redact:`) for `ObanPowertools.Worker`, covering
enqueue-time field dropping, idempotency fingerprint ordering, `__redacted_fields__` meta injection,
cron-path routing through `worker_mod.new/2`, and the detail-page overlay and disclosure UI.

The core redaction mechanics — `Redaction.apply/4`, the `required_fields` exclusion, the compile-time
typo and partition guards, and the cron `__powertools_limits__` routing — are correctly implemented.
The test suite is thorough for the happy paths and the stated contracts.

Two blockers and three warnings are present. The most serious is that the `:repo` option, when
passed by callers of `enqueue/2` for test isolation, flows all the way to `Oban.Job.new/2` where
it causes a changeset validation error, silently failing every such enqueue. The second blocker is
an atom table leak in `Cron.maybe_insert_job/4`.

---

## Critical Issues

### CR-01: `:repo` opt leaks into `Oban.Job.new/2`, producing a validation error on every enqueue call that passes `repo:`

**File:** `lib/oban_powertools/idempotency.ex:147-175`

**Issue:** `merge_powertools_meta/4` strips only the `:now` key before building `opts_for_job`,
then returns those opts to be passed directly to `worker_mod.new(args_map, opts_for_job)`.
`worker_mod.new/2` delegates to `worker_mod.__powertools_new_delegate__(clean_args, opts_with_meta)`
which calls `Oban.Job.new(args, Oban.Worker.merge_opts(__opts__(), opts))`.
`Oban.Job.new/2` calls `validate_keys/3` which adds a changeset error `"unknown option :repo
provided"` for any key not in its `@permitted_params` list. `:repo` is not a permitted param.

The result: any caller that passes `repo:` to `enqueue/2` (the documented test-isolation pattern
visible in `idempotency_test.exs` and the internal `Idempotency.transaction/3` signature) would
receive `{:error, %Ecto.Changeset{}}` instead of `{:ok, job}`. The test suite never passes `repo:`
directly to `enqueue/2` (it sets `Application.put_env` instead), so this is masked.

**Fix:**

```elixir
# lib/oban_powertools/idempotency.ex — merge_powertools_meta/4
defp merge_powertools_meta(opts, worker_mod, args, fingerprint) do
  meta = Keyword.get(opts, :meta, %{})
  now = Keyword.get(opts, :now, DateTime.utc_now())
  # Strip ALL Powertools-internal opts before passing to Oban.Job.new
  opts_for_job =
    opts
    |> Keyword.delete(:now)
    |> Keyword.delete(:repo)

  # ... rest unchanged
  Keyword.put(opts_for_job, :meta, merged_meta)
end
```

Any other Powertools-internal opts (e.g., future `:scheduled_by` helpers) should be stripped here
as well rather than relied upon passing through `validate_keys`.

---

### CR-02: `String.to_atom/1` called on a database-controlled `entry.queue` value — unbounded atom table growth

**File:** `lib/oban_powertools/cron.ex:422`

**Issue:** `maybe_insert_job/4` converts `entry.queue` (a string stored in the database) to an
atom via `String.to_atom/1`. The BEAM atom table is limited (default ~1 million atoms) and atoms
are never garbage collected. Any string stored in `oban_powertools_cron_entries.queue` — including
values from operator UI, imports, or a compromised cron entry row — creates a permanent atom.
An attacker who can insert cron entries (or who can write to the DB directly) can exhaust the atom
table and crash the BEAM.

The correct fix is `String.to_existing_atom/1` which raises `ArgumentError` for unknown atoms
rather than creating them. Queue names that have been used in any `use Oban.Worker, queue:` or
`Oban.Queue` declaration will already exist as atoms.

```elixir
# lib/oban_powertools/cron.ex:422 — before
queue = String.to_atom(entry.queue)

# after
queue = String.to_existing_atom(entry.queue)
```

If there is a legitimate need to support queue names that may not yet be atoms, the right approach
is to maintain an explicit allowlist or validate queue values against the running Oban configuration
rather than creating unbounded atoms.

---

## Warnings

### WR-01: `normalize_entry_attrs/1` silently fails to apply defaults when `attrs` uses string keys

**File:** `lib/oban_powertools/cron.ex:325-337`

**Issue:** The function opens with `Map.new(fn {key, value} -> {key, value} end)` — a no-op
identity transform that preserves existing key types. All subsequent `Map.put_new/3` calls use
atom keys. If `attrs` is passed with string keys (e.g., from a JSON decode: `%{"queue" => "billing",
"expression" => "0 * * * *"}`), the `Map.put_new(:queue, @default_queue)` call does not detect the
existing `"queue"` string key and inserts a separate `:queue => "default"` atom key. The map then
contains both `"queue" => "billing"` and `:queue => "default"`.

Ecto's `cast/3` resolves this correctly for the insert/update path (it prefers string keys), so no
data corruption occurs. However, `cron_config_diff/2` uses `Map.get(normalized, key)` with atom
keys, so it always reads the atom-keyed defaults rather than the string-keyed user values. This
causes every `sync_entry` update call with string-keyed attrs to generate a false-positive
reconfiguration audit event for every tracked field (`expression`, `timezone`, `overlap_policy`,
`catch_up_policy`, `max_catch_up`, `queue`).

**Fix:** Normalize all keys to atoms at the start:

```elixir
defp normalize_entry_attrs(attrs) do
  attrs
  |> Map.new(fn {key, value} -> {to_existing_atom_or_keep(key), value} end)
  |> Map.put_new(:queue, @default_queue)
  # ... rest unchanged
end

defp to_existing_atom_or_keep(key) when is_atom(key), do: key
defp to_existing_atom_or_keep(key) when is_binary(key) do
  try do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> key
  end
end
```

Or, more simply, enumerate and explicitly convert the known entry fields from string to atom keys
at the top of `sync_entry/2` before passing to `normalize_entry_attrs/1`.

---

### WR-02: `recorded_output_display/1` issues two separate queries when one suffices — TOCTOU window

**File:** `lib/oban_powertools/web/jobs_live.ex:763-776`

**Issue:** The function calls `JobRecord.fetch_result(repo(), job.id)` and on success immediately
calls `JobRecord.fetch_record(repo(), job.id)`. `fetch_result` internally calls `fetch_record` and
extracts only the payload field. The second `fetch_record` call is a redundant round-trip. Between
the two calls, a record could be deleted (e.g., by a retention pruner), causing `fetch_record` to
return `{:error, :not_found}` despite `fetch_result` having succeeded — resulting in the
"No recorded output" empty state being shown for a job that has a record.

The fallback is harmless and does not crash, but the pattern is logically inconsistent: the check
and the fetch should be the same call.

**Fix:**

```elixir
defp recorded_output_display(%Oban.Job{} = job) do
  context = %{surface: :jobs, field: :recorded, job: job}

  case JobRecord.fetch_record(repo(), job.id) do
    {:ok, record} -> DisplayPolicy.render_job_field(:job_recorded, record, context)
    {:error, :not_found} -> DisplayPolicy.render_job_field(:job_recorded, nil, context)
  end
end
```

---

### WR-03: `emit_claim_telemetry/3` in `Cron` bypasses the `repo` parameter and reads config directly

**File:** `lib/oban_powertools/cron.ex:475-489`

**Issue:** All other audit calls in `Cron` accept `repo` as a parameter and pass it through.
`emit_claim_telemetry/3` calls `Audit.record/4` with
`repo: Application.get_env(:oban_powertools, :repo)` — a direct config read that bypasses the
`repo` parameter passed to `claim_slot/4`. This is inconsistent with the module's own convention,
makes the function untestable in isolation (it can't have a test-repo injected), and could silently
use a stale or misconfigured repo if the application config is changed at runtime.

**Fix:**

```elixir
# Add repo as a parameter (or capture it from the outer scope via a closure)
defp emit_claim_telemetry(repo, entry, slot, %{decision: decision}) do
  Telemetry.execute_cron_event(...)
  Audit.record(
    "cron.slot_claimed",
    %{type: :cron_entry, id: entry.name},
    %{"slot_at" => slot.slot_at, "decision" => decision, "source" => entry.source},
    repo: repo
  )
end
```

And update the call site in `claim_slot/4` to pass `repo`:

```elixir
emit_claim_telemetry(repo, entry, slot, decision)
```

---

## Info

### IN-01: `normalize_entry_attrs/1` identity `Map.new` is dead code

**File:** `lib/oban_powertools/cron.ex:327`

**Issue:** `Map.new(fn {key, value} -> {key, value} end)` transforms each entry to itself. It is
a no-op that adds a full map allocation and enumeration without producing any change to the map.
Its presence suggests the intention was to normalize keys (which it does not do — see WR-01).

**Fix:** Remove the call entirely, or replace with actual key normalization as described in WR-01.
If it was intended as a documentation hint about the expected map structure, a comment is clearer.

---

### IN-02: `normalize_to_atom_keys/2` in `Redaction` does not handle maps with both atom and string forms of the same redacted key

**File:** `lib/oban_powertools/worker/redaction.ex:27-43`

**Issue:** If a caller passes `args` containing both `"ssn" => "a"` (string key) and `:ssn => "b"`
(atom key) for the same field, `Map.new/2` processes all entries and the last write wins per the
iteration order. The result is non-deterministic: one value is silently discarded. In practice,
well-formed callers don't produce such maps, but there is no guard or warning.

This is a documentation gap rather than an exploitable bug, since the redaction behavior (drop the
field) still applies to the surviving key.

**Fix:** No code change is required if the documented contract is "args must use consistent key
types." Add a comment to `normalize_to_atom_keys/2` noting the assumption, or add a guard:

```elixir
# Normalize only declared redact atom-keys from string-keyed args; leave other keys untouched.
# Precondition: args does not contain both atom and string forms of the same key.
# If both forms are present, one value is silently dropped by Map.new/2.
```

---

_Reviewed: 2026-06-13T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
