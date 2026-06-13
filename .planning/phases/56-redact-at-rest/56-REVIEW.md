---
phase: 56-redact-at-rest
reviewed: 2026-06-13T12:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - lib/oban_powertools/worker/redaction.ex
  - lib/oban_powertools/worker.ex
  - lib/oban_powertools/cron.ex
  - lib/oban_powertools/runtime_config.ex
  - lib/oban_powertools/web/jobs_live.ex
  - test/oban_powertools/worker_redact_test.exs
  - test/oban_powertools/idempotency_test.exs
  - test/oban_powertools/cron_test.exs
  - test/oban_powertools/web/live/jobs_live_test.exs
  - guides/workers-and-idempotency.md
  - test/oban_powertools/docs_contract_test.exs
findings:
  critical: 2
  warning: 4
  info: 2
  total: 8
status: issues_found
---

# Phase 56: Code Review Report

**Reviewed:** 2026-06-13T12:00:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

This phase delivers at-rest argument redaction (`redact:`) for `ObanPowertools.Worker`. Reviewed
scope covers the core `Redaction` module, the worker macro changes (required-field exclusion,
compile-time guards, `new/2` override), the cron-path routing fix, the `DisplayPolicy` overlay and
disclosure UI, and the complete test suite for the feature.

The core mechanics are sound: `Redaction.apply/4` correctly drops declared keys (handling both atom
and string forms), the fingerprint ordering is correct (computed from casted args before the drop),
`__redacted_fields__` meta injection uses a safe deep-merge, compile-time typo and partition guards
work, and the cron path correctly routes `ObanPowertools.Worker` modules through `worker_mod.new/2`.

Two blockers are present. First, the `:repo` keyword option passed by callers of `enqueue/2` is not
stripped before being forwarded to `Oban.Job.new/2`, which rejects unknown options with a changeset
error — silently failing every enqueue that uses the `repo:` injection pattern. Second, `String.to_atom/1`
is called on a database-sourced queue name in `cron.ex`, contradicting the codebase's own T-48-05
rule and creating an unbounded atom table growth vector.

Four warnings cover a false-positive audit event path (string-keyed `sync_entry` attrs), a missing
catch-all on `action_word/1` that can crash the LiveView, a `defoverridable new: 2` that silently
disables redaction if a host module overrides it, and an inconsistent double-query in
`recorded_output_display/1`.

---

## Critical Issues

### CR-01: `:repo` opt not stripped before `Oban.Job.new/2` — every `repo:`-injected enqueue silently fails

**File:** `lib/oban_powertools/idempotency.ex:150`

**Issue:** `merge_powertools_meta/4` strips only the `:now` key from opts before passing the
remainder to `worker_mod.new/2`:

```elixir
opts_for_job = Keyword.delete(opts, :now)
```

`:repo` is not stripped. `worker_mod.new/2` delegates through `Redaction.apply/4` to
`worker_mod.__powertools_new_delegate__(clean_args, opts_with_meta)`, which calls:

```elixir
Oban.Job.new(args, Oban.Worker.merge_opts(__opts__(), opts))
```

`Oban.Job.new/2` calls `validate_keys/3` against `@permitted_params`. `:repo` is not in that list,
so a base changeset error `"unknown option :repo provided"` is added. The resulting invalid changeset
causes `repo.insert(job_changeset)` to fail inside the Ecto Multi, propagating as
`{:error, _name, changeset, _}` which surfaces as `{:error, changeset}` to the caller.

Any call to `enqueue/2` or `Idempotency.transaction/3` that passes `repo:` (the test-isolation
injection pattern visible in the idempotency module's own interface) will return `{:error, changeset}`
instead of `{:ok, job}`. The test suite avoids this by using `Application.put_env` for test repo
injection instead of the `opts[:repo]` path — so this bug is untested and undetected.

**Fix:**

```elixir
# lib/oban_powertools/idempotency.ex — merge_powertools_meta/4
defp merge_powertools_meta(opts, worker_mod, args, fingerprint) do
  meta = Keyword.get(opts, :meta, %{})
  now = Keyword.get(opts, :now, DateTime.utc_now())

  # Strip ALL Powertools-internal opts before passing remainder to Oban.Job.new
  opts_for_job =
    opts
    |> Keyword.delete(:now)
    |> Keyword.delete(:repo)

  # ... rest of function unchanged
  Keyword.put(opts_for_job, :meta, merged_meta)
end
```

Any future Powertools-internal opts added to `enqueue/2` must also be stripped here.

---

### CR-02: `String.to_atom/1` on database-controlled `entry.queue` — unbounded atom table growth

**File:** `lib/oban_powertools/cron.ex:422`

**Issue:**

```elixir
queue = String.to_atom(entry.queue)
```

`entry.queue` is a `string` column populated from operator input via `sync_entry/2`. BEAM atoms are
never garbage collected; the atom table defaults to approximately 1 million entries. Converting an
arbitrary database string to an atom can exhaust the table and terminate the BEAM. This directly
contradicts the codebase's own documented T-48-05 rule: comments in three other files
(`oban_powertools.limiter.simulate.ex`, `oban_powertools.limiter.explain.ex`,
`oban_powertools.doctor.ex`) explicitly warn "never `String.to_atom/1` on user-supplied input."

`Oban.Job.new/2` accepts `queue: atom() | binary()` per its own typespec, so converting to atom
is unnecessary. Passing the string directly works.

**Fix:**

```elixir
# lib/oban_powertools/cron.ex:422 — pass string directly; no conversion needed
# was: queue = String.to_atom(entry.queue)
queue = entry.queue
```

If an atom is required for some downstream reason, use `String.to_existing_atom/1` instead, which
raises `ArgumentError` for queue names that were never declared as atoms, preventing unbounded
growth.

---

## Warnings

### WR-01: `action_word/1` has no catch-all clause — FunctionClauseError crash on valid-to-Lifeline actions

**File:** `lib/oban_powertools/web/jobs_live.ex:269-271`

**Issue:**

```elixir
defp action_word("job_retry"), do: "retried"
defp action_word("job_cancel"), do: "cancelled"
defp action_word("job_discard"), do: "discarded"
```

`Lifeline.preview_repair/3` validates action against `["job_rescue", "job_retry", "job_cancel",
"job_discard"]`. A client that sends `phx-value-action="job_rescue"` to the `"preview"` event
passes through `handle_event/3` without a whitelist check, gets a valid preview from Lifeline, has
that preview stored in `socket.assigns.preview`, and upon a successful `"execute"` fires:

```elixir
action_word(socket.assigns.preview.action)  # action_word("job_rescue") — no clause matches
```

This raises `FunctionClauseError`, crashing the LiveView process. The bug requires only that the
client construct a WebSocket message with `action=job_rescue` — no authentication bypass needed,
just a non-standard but valid-to-Lifeline action string.

**Fix:** Add a catch-all clause and validate the action at the `"preview"` event entry point:

```elixir
defp action_word("job_retry"), do: "retried"
defp action_word("job_cancel"), do: "cancelled"
defp action_word("job_discard"), do: "discarded"
defp action_word(action), do: action  # safe fallback

# AND in handle_event("preview", ...):
@allowed_preview_actions ~w(job_retry job_cancel job_discard)

def handle_event("preview", %{"action" => action}, socket)
    when action in @allowed_preview_actions do
  # ... existing body
end

def handle_event("preview", _, socket), do: {:noreply, socket}
```

---

### WR-02: `normalize_entry_attrs/1` silently fails to apply defaults when `attrs` uses string keys — false-positive reconfiguration audit events

**File:** `lib/oban_powertools/cron.ex:325-337`

**Issue:** The function body opens with a no-op identity transform:

```elixir
|> Map.new(fn {key, value} -> {key, value} end)
```

All subsequent `Map.put_new/3` calls use atom keys. If `attrs` arrives with string keys (e.g., from
a JSON payload or an operator integration: `%{"queue" => "billing", "expression" => "0 * * * *"}`),
`Map.put_new(:queue, @default_queue)` does not detect the existing `"queue"` string key and inserts
a separate `:queue => "default"` atom key alongside the caller's `"queue" => "billing"`.

Ecto's `cast/3` resolves this correctly (string keys win for changeset purposes), so no data is
corrupted on insert/update. However, `cron_config_diff/2` calls `Map.get(normalized, key)` with atom
keys. It reads the spuriously inserted `:queue => "default"` instead of the caller-supplied
`"queue" => "billing"`, producing a false diff. On every `sync_entry` update with string-keyed
attrs, a spurious `"cron.reconfigured"` audit event is emitted for all six tracked fields
(`expression`, `timezone`, `overlap_policy`, `catch_up_policy`, `max_catch_up`, `queue`) even
when nothing actually changed.

The existing tests always pass atom-keyed maps, so this path is untested.

**Fix:** Normalize keys to atoms at the top of `normalize_entry_attrs/1`:

```elixir
defp normalize_entry_attrs(attrs) do
  known_keys = ~w(name source worker queue expression timezone args opts overlap_policy
                  catch_up_policy max_catch_up paused_at last_run_at metadata)a

  # Convert known string keys to atoms; leave unknown keys unchanged
  normalized =
    Map.new(attrs, fn {k, v} ->
      atom_key = if is_binary(k), do: try_to_existing_atom(k), else: k
      {atom_key, v}
    end)

  normalized
  |> Map.put_new(:queue, @default_queue)
  |> Map.put_new(:timezone, @default_timezone)
  # ... rest unchanged
end

defp try_to_existing_atom(str) do
  String.to_existing_atom(str)
rescue
  ArgumentError -> str
end
```

---

### WR-03: `defoverridable new: 2` permits host modules to silently bypass redaction

**File:** `lib/oban_powertools/worker.ex:147`

**Issue:**

```elixir
defoverridable new: 1, new: 2
```

Making `new/2` overridable means any host worker module that defines its own `new/2` silently
replaces the Redaction layer. Because the override is silent — no compiler warning, no runtime
detection — a developer who customizes `new/2` in a worker with `redact:` configured will lose
all redaction without any indication. This is a data-safety regression path with no guard.

The `defoverridable` for `new/1` is inherited from `Oban.Worker` and reasonable; the risk is
specifically `new: 2`, which is the entry point for the security-critical redaction call.

**Fix:** At minimum, add a documentation comment at the override site explaining the consequence:

```elixir
# WARNING: Overriding new/2 in a worker that declares redact: will bypass
# ObanPowertools.Worker.Redaction.apply/4. Do NOT override new/2 in redacting workers.
defoverridable new: 1, new: 2
```

A stronger fix is to remove `new: 2` from `defoverridable` entirely. If Oban's `use Oban.Worker`
generates its own `new/2` and marks it overridable, the `ObanPowertools.Worker` macro already
redefines it with `@impl Oban.Worker` — this new definition is the canonical one, and hosts should
not need to override it.

---

### WR-04: `emit_claim_telemetry/3` bypasses the caller-provided `repo` — untestable and inconsistent

**File:** `lib/oban_powertools/cron.ex:487`

**Issue:**

```elixir
Audit.record(
  "cron.slot_claimed",
  %{type: :cron_entry, id: entry.name},
  %{"slot_at" => slot.slot_at, "decision" => decision, "source" => entry.source},
  repo: Application.get_env(:oban_powertools, :repo)
)
```

Every other `Audit.record` call in `Cron` receives the `repo` passed to the public functions
(`claim_slot/4`, `pause_cron_entry/4`, etc.). `emit_claim_telemetry/3` is called from inside the
`claim_slot/4` transaction result handler (after the transaction commits) but reads repo from
application config directly. This means:

1. In tests that inject a test repo via the `repo` parameter, the audit record for `cron.slot_claimed`
   is written to the wrong repo (the globally configured one, or `nil` if unconfigured — causing a
   crash).
2. A future deployment that changes `:repo` at runtime after startup could silently write this
   audit event to a stale repo.
3. The function is not testable in isolation without mutating global application config.

**Fix:**

```elixir
# Add repo as parameter
defp emit_claim_telemetry(repo, entry, slot, %{decision: decision}) do
  Telemetry.execute_cron_event(:slot_claimed, %{count: 1}, %{
    action: decision,
    source: entry.source,
    overlap_policy: entry.overlap_policy,
    catch_up_policy: entry.catch_up_policy
  })

  Audit.record(
    "cron.slot_claimed",
    %{type: :cron_entry, id: entry.name},
    %{"slot_at" => slot.slot_at, "decision" => decision, "source" => entry.source},
    repo: repo
  )
end
```

Update the call site in `claim_slot/4` to pass `repo`:

```elixir
maybe_record_coverage(repo, entry, slot_at, manual?)
emit_claim_telemetry(repo, entry, slot, decision)
```

---

## Info

### IN-01: `normalize_entry_attrs/1` identity `Map.new` is a dead no-op

**File:** `lib/oban_powertools/cron.ex:327`

**Issue:** `Map.new(fn {key, value} -> {key, value} end)` returns a structurally identical map. It
allocates a new map and traverses all entries to produce no change. The likely intent was key
normalization (which it does not accomplish — see WR-02). The call should be removed or replaced
with the actual normalization logic.

**Fix:** Remove or replace with the key-normalizing version from WR-02.

---

### IN-02: `recorded_output_display/1` calls `fetch_result` then `fetch_record` — redundant round-trip with TOCTOU window

**File:** `lib/oban_powertools/web/jobs_live.ex:763-776`

**Issue:**

```elixir
case JobRecord.fetch_result(repo(), job.id) do
  {:ok, _payload} ->
    case JobRecord.fetch_record(repo(), job.id) do
      {:ok, record} -> DisplayPolicy.render_job_field(:job_recorded, record, context)
      {:error, :not_found} -> DisplayPolicy.render_job_field(:job_recorded, nil, context)
    end

  {:error, :not_found} ->
    DisplayPolicy.render_job_field(:job_recorded, nil, context)
end
```

`fetch_result` queries the record and extracts only the payload field. The immediately following
`fetch_record` queries the same record again for the full struct. Between the two calls a retention
pruner could delete the record — causing `fetch_record` to return `{:error, :not_found}` despite
`fetch_result` having succeeded, rendering the "No recorded output" empty state for a job that
has one. The first call is redundant: `fetch_record` subsumes it.

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

_Reviewed: 2026-06-13T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
