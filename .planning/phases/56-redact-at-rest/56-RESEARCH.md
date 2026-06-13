# Phase 56: redact: At-Rest — Research

**Researched:** 2026-06-13
**Domain:** Elixir macro compile-time guards, Ecto changeset seams, Oban worker `new/2` override, JSONB at-rest redaction, Phoenix LiveView disclosure
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

D-01 through D-17 are fully locked. Do not reopen them. Summary of most planner-critical:

- **D-01:** Redaction lives in a macro-overridden `new/1,2` in `ObanPowertools.Worker.__using__`, covering both the `Idempotency.transaction/3` path and direct `MyWorker.new(args) |> Oban.insert()` path.
- **D-02:** Redaction is `Map.drop(args, redacted_fields)` — key-absent, never nil or placeholder.
- **D-03:** Fingerprint ordering is invariant: fingerprint computed from full args at `idempotency.ex:46`, then `worker_mod.new/2` called at `idempotency.ex:81`. Override drops fields AFTER fingerprinting by construction.
- **D-04:** `__redacted_fields__` meta injected exactly once in overridden `new/2`; transaction/3 must NOT also inject it.
- **D-05:** Fix `cron.ex:422` bare `Oban.Job.new` bypass — route through `entry.worker.new/2` when entry.worker is an ObanPowertools.Worker.
- **D-06:** Auto-exempt redacted fields from `validate_required` at the perform re-cast.
- **D-07:** Compile-time typo guard: raise `ArgumentError` if a `redact:` field is not declared in `args`.
- **D-08:** Top-level keys only for v1.7 (`Map.drop`).
- **D-09:** Compile-time partition-key guard: raise if a `redact:` field overlaps with `partition_by: {:args, field}`.
- **D-10:** `JobRecord.redacted` stays `false` — do not touch recording layer.
- **D-11:** Document in guides that `redact:` does not scrub recorded outputs.
- **D-12:** UI annotation at the args panel via `meta["__redacted_fields__"]`.
- **D-13:** No new top-level card; "Fields redacted at enqueue: [:ssn, :token]" near Meta card; inline per-field disclosure in Args card.
- **D-14:** `DisplayPolicy.render_job_field/3` default shows "Redacted at enqueue" for listed fields; fallback stays `[redacted]`.
- **D-15:** Doctor bypass-detection advisory deferred.
- **D-16:** Drop on atom-keyed map; normalize incoming args in `new/2` override before dropping.
- **D-17:** `__redacted_fields__` stored in meta as strings (`["ssn", "token"]`), sorted for stability.

### Claude's Discretion

All gray areas resolved in prior research. Two user-confirmed findings: cron-path bypass (D-05) and required-field collision (D-06). Downstream agents implement decisions, do not reopen.

### Deferred Ideas (OUT OF SCOPE)

- `encrypt:` at-rest
- Retroactive redaction (`Redactor.scrub_past_jobs/2`)
- Nested redaction paths (`[[:user, :ssn]]`)
- `required: false` per-field modifier
- Doctor redact-bypass advisory
- Auto-scrubbing recorded output payloads

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REDACT-01 | Worker declares `redact: [:field]`; fields dropped from `args` via `Map.drop` at enqueue time, strictly after idempotency fingerprint | D-01/D-03: override `new/1,2`; fingerprint already runs at idempotency.ex:46 before new/2 at line 81 |
| REDACT-02 | Redacted field names stored in job meta as `__redacted_fields__` at enqueue | D-04/D-17: inject in overridden `new/2` as sorted string list; merge via existing `deep_merge` |
| REDACT-03 | `/ops/jobs` detail view renders "Fields redacted at enqueue: [:ssn, :token]" from `meta["__redacted_fields__"]` | D-13: near Meta card, no new top-level card; jobs_live.ex already reads job.meta |
| REDACT-04 | `DisplayPolicy.render_job_field/3` default shows "Redacted at enqueue" for fields in `__redacted_fields__` | D-14: extend render_job_field/3 at runtime_config.ex:206 with pre-check on meta context |

</phase_requirements>

---

## Summary

Phase 56 adds compile-time, opt-in at-rest argument redaction to `ObanPowertools.Worker`. The critical design constraint is that redaction is a persistence concern, not a runtime concern: the worker's in-memory `Args` struct retains all values during execution; only the JSONB written to `oban_jobs.args` has the listed fields dropped. The idempotency fingerprint is always computed from the full unredacted args, which is guaranteed by the existing call ordering in `Idempotency.transaction/3` (fingerprint at line 46, `worker_mod.new/2` at line 81 — the override runs after fingerprinting).

The implementation has five concrete code seams: (1) `worker.ex __using__` for opt parsing, compile-time guards, `__powertools_redact__/0` generation, required-field exemption, and the `new/1,2` override; (2) `idempotency.ex merge_powertools_meta` for coordinating the single `__redacted_fields__` meta injection without double-injection; (3) `cron.ex:422` for routing scheduled enqueue through `entry.worker.new/2` instead of bare `Oban.Job.new`; (4) `runtime_config.ex render_job_field/3` for default "Redacted at enqueue" display; (5) `jobs_live.ex` for the disclosure near the Meta card.

The atom-vs-string key boundary is the primary ordering risk: args reach `new/2` as atom-keyed maps from the `transaction/3` path (via `Map.from_struct`), but a direct `MyWorker.new(%{"ssn" => "123"})` call may pass string keys. The override must normalize to atom keys before dropping, using the declared `args_config` keys as the canonical atom set.

**Primary recommendation:** Override `new/1,2` in `__using__` following the existing `defoverridable` pattern; put redaction/normalize/meta-inject logic in a small internal helper `ObanPowertools.Worker.Redaction` to keep quoted macro code small.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| At-enqueue arg drop | Worker macro (`__using__`) | Idempotency (`transaction/3`) coordination | `new/2` is the universal changeset builder; `transaction/3` already calls it |
| Fingerprint ordering | Idempotency (`transaction/3`) | — | Line 46/81 ordering already enforces this; do not move fingerprint |
| `__redacted_fields__` meta injection | Worker macro (`new/2` override) | Idempotency (`merge_powertools_meta`) | Inject once in `new/2`; `transaction/3` calls `new/2` and inherits it |
| Cron bypass fix | Cron (`maybe_insert_job`) | — | cron.ex:422 is the only bypass path identified |
| Compile-time guards | Worker macro (`__using__`) | — | Co-located with other compile-time guards (`normalize_limits_config!`) |
| Required-field exemption | Worker macro (`perform/1` → `Args.changeset/2`) | — | Changeset's `validate_required` is the site of the collision |
| Operator disclosure | LiveView (`jobs_live.ex`) | DisplayPolicy (`runtime_config.ex`) | Meta card rendering in existing job detail view |
| Per-field "Redacted at enqueue" | DisplayPolicy (`render_job_field/3`) | LiveView args card | Extends existing policy dispatch; fallback stays `[redacted]` |

---

## Standard Stack

### Core

No new runtime dependencies. This phase uses only existing project stack.

| Library | Purpose | Why Standard |
|---------|---------|--------------|
| `ObanPowertools.Worker` (macro) | Primary integration point | All prior phases follow `__using__` pattern |
| `Ecto.Changeset` (`cast`/`validate_required`) | Args casting at perform-time | Already imported in generated module |
| `Map.drop/2` | At-rest field removal | Elixir stdlib; key-absent semantics |
| `Jason` | Meta encoding | Already project dependency |

### No Installation Required

Zero new runtime dependencies per v1.7 constraint. [VERIFIED: codebase inspection — mix.exs unchanged]

---

## Package Legitimacy Audit

Not applicable. No new packages are introduced in this phase.

---

## Architecture Patterns

### System Architecture Diagram

```
Worker.enqueue(args) / MyWorker.new(args)
        |
        v
ObanPowertools.Worker.__using__ generated new/2 override
        |
        |-- normalize_args_keys(args, atom_keys_from_config)
        |-- redacted_keys = __powertools_redact__()
        |-- redacted_fields_str = Enum.map(redacted_keys, &to_string/1) |> Enum.sort()
        |-- clean_args = Map.drop(normalized_args, redacted_keys)
        |-- base_opts_with_meta = inject __redacted_fields__ into opts[:meta] via deep_merge
        |-- super(clean_args, base_opts_with_meta)   <-- calls Oban.Worker's generated new/2
              |
              v
        Oban.Job.new(clean_args, merged_opts)  <-- JSONB stored without redacted fields
        
Idempotency.transaction/3 path:
  fingerprint = generate_fingerprint(worker_mod, full_casted_args)  [line 46]
  ...
  worker_mod.new(args_map, opts_with_powertools_meta)               [line 81]
                 ^-- new/2 override fires HERE (after fingerprint)
                 ^-- drops fields, injects __redacted_fields__ in meta

Cron path (FIXED):
  cron.ex:422: was: Oban.Job.new(args, worker: ..., queue: ...)
               now: if powertools_worker?(entry.worker),
                      do: String.to_existing_atom(entry.worker).new(args, queue: ...),
                      else: Oban.Job.new(args, worker: ..., queue: ...)

At runtime (perform/1):
  job.args is now JSONB with string keys, redacted fields absent
  validate(args) -> Args.changeset(struct, params)
                 -> fields = Keyword.keys(args_config)
                 -> required = fields -- redacted_fields    [D-06]
                 -> cast(params, fields)
                 -> validate_required(required)

DisplayPolicy path:
  render_job_field(:job_args, job.args, %{job: job})
    -> check if job.meta["__redacted_fields__"] exists
    -> for each redacted field not in job.args:
         render inline as "field: Redacted at enqueue"
    -> render remaining fields as normal JSON
```

### Recommended Project Structure

No new top-level modules required. One small internal helper module recommended:

```
lib/oban_powertools/worker/
├── deadlines.ex      # existing
├── hooks.ex          # existing
├── redaction.ex      # NEW — normalize_args/2, drop_redacted/3, inject_meta/3
```

### Pattern 1: `new/2` Override with `super`

**What:** Override `new/2` in the `__using__`-generated code, call `super(clean_args, opts_with_meta)` to delegate to `Oban.Worker`'s generated `new/2`.

**When to use:** The only correct pattern for the override. `defoverridable Worker` already marks all callbacks overridable in `deps/oban/lib/oban/worker.ex:496`.

```elixir
# In __using__ quoted block, AFTER use Oban.Worker and defoverridable setup:

@powertools_redact unquote(redact_config)

@impl Oban.Worker
def new(args, opts \\ []) when is_map(args) and is_list(opts) do
  ObanPowertools.Worker.Redaction.apply_redaction(
    __MODULE__,
    args,
    opts,
    @powertools_redact
  )
end

defoverridable new: 1, new: 2
```

```elixir
# In ObanPowertools.Worker.Redaction:

def apply_redaction(worker_mod, args, opts, []) do
  # No redact config — call super path directly
  worker_mod.__powertools_new_super__(args, opts)
end

def apply_redaction(worker_mod, args, opts, redact_keys) do
  redact_strings = redact_keys |> Enum.map(&Atom.to_string/1) |> Enum.sort()
  normalized = normalize_keys(args, redact_keys)
  clean_args = Map.drop(normalized, redact_keys)
  opts_with_meta = inject_redacted_fields_meta(opts, redact_strings)
  worker_mod.__powertools_new_super__(clean_args, opts_with_meta)
end
```

**Key insight:** `super` inside `__using__`-generated code calls the `Oban.Worker`-generated `new/2`, which itself calls `Oban.Job.new(args, Worker.merge_opts(__opts__(), opts))`. The override receives clean args + meta-enriched opts and delegates correctly.

**Implementation note:** Using `super` requires the override to be inside a `quote do ... end` block. The cleanest pattern is a helper module that the override calls, keeping macro-quoted code minimal.

### Pattern 2: `defoverridable` Layering — How It Works in This Codebase

`use Oban.Worker` generates `new/2` and immediately calls `defoverridable Worker`. When `ObanPowertools.Worker.__using__` then generates its own `new/2` after that, the Powertools `new/2` becomes the new implementation, and calling `super` dispatches to the Oban-generated `new/2`.

The existing codebase already uses this pattern successfully for `perform/1` (the Powertools `perform/1` overrides Oban's, calls `process/1`). The `new/2` override follows the identical mechanic.

**Critical ordering in `__using__`:**
```
use Oban.Worker, unquote(oban_opts)        # generates new/2, defoverridable Worker
...
@powertools_redact unquote(redact_config)  # module attribute set at compile time
...
@impl Oban.Worker
def new(args, opts \\ []) ...             # THIS overrides the Oban-generated new/2
defoverridable new: 1, new: 2             # allow host workers to override further
```

### Pattern 3: Atom-vs-String Key Normalization at `new/2` Boundary

**What:** Normalize incoming args to atom keys using the declared `args_config` as the key spec.

**When to use:** Always, in the override, before `Map.drop`. The `transaction/3` path passes atom keys (`Map.from_struct`), but direct callers may pass string keys.

```elixir
# Source: codebase inspection — idempotency.ex:78-81
# args_map from Map.from_struct(casted_struct) -> atom keys
# but MyWorker.new(%{"ssn" => "123"}) -> string keys

def normalize_keys(args, atom_keys) do
  Enum.reduce(atom_keys, %{}, fn key, acc ->
    str_key = Atom.to_string(key)
    cond do
      Map.has_key?(args, key) -> Map.put(acc, key, Map.get(args, key))
      Map.has_key?(args, str_key) -> Map.put(acc, key, Map.get(args, str_key))
      true -> acc
    end
  end)
  |> then(&Map.merge(args, &1))
  # The merge retains any extra keys not in args_config (e.g. Oban internal opts passed as args)
  # but ensures all args_config keys are atom-keyed for the drop
end
```

**Simpler alternative:** `Map.new(args, fn {k, v} -> {normalize_key(k), v} end)` where `normalize_key` converts known string keys to atoms and leaves others alone. This is safer for the common case where all keys are either all-atom or all-string.

### Pattern 4: `__redacted_fields__` Meta Injection

**What:** Inject `"__redacted_fields__" => ["ssn", "token"]` into the job meta exactly once inside `new/2` override.

**Why:** `transaction/3` calls `new/2` with opts that already include `merge_powertools_meta`'s result (fingerprint, limits, deadline meta). The override must merge `__redacted_fields__` into those opts without clobbering them.

```elixir
def inject_redacted_fields_meta(opts, redact_strings) do
  existing_meta = Keyword.get(opts, :meta, %{})
  redaction_meta = %{"__redacted_fields__" => redact_strings}
  merged_meta = deep_merge(existing_meta, redaction_meta)
  Keyword.put(opts, :meta, merged_meta)
end

# Use the existing deep_merge from Idempotency — or duplicate the two-clause version:
defp deep_merge(left, right) when is_map(left) and is_map(right),
  do: Map.merge(left, right, fn _key, a, b -> deep_merge(a, b) end)
defp deep_merge(_left, right), do: right
```

**D-04 enforcement:** Since `transaction/3` calls `merge_powertools_meta` (builds fingerprint/limits/deadline meta) and THEN calls `worker_mod.new(args_map, merged_opts)`, the `new/2` override receives opts that already have `meta: %{...powertools meta...}`. The override merges `__redacted_fields__` into that existing meta. This is correct and will not clobber the idempotency fingerprint or deadline keys.

### Pattern 5: Cron Bypass Fix at `cron.ex:422`

**What:** Detect whether `entry.worker` is an `ObanPowertools.Worker` and route through `entry.worker.new/2` instead of bare `Oban.Job.new/2`.

**How to detect:** Use `function_exported?(worker_module, :__powertools_redact__, 0)` — this function is only generated by `ObanPowertools.Worker.__using__`, not by plain `Oban.Worker`. Alternative: check `function_exported?(worker_module, :__powertools_limits__, 0)` which already exists for all Powertools workers regardless of limits config.

```elixir
# cron.ex:421-423 — BEFORE:
defp maybe_insert_job(repo, entry, args, _decision) do
  repo.insert(Oban.Job.new(args, worker: entry.worker, queue: String.to_atom(entry.queue)))
end

# AFTER:
defp maybe_insert_job(repo, entry, args, _decision) do
  worker_module = String.to_existing_atom("Elixir." <> entry.worker)
  changeset =
    if function_exported?(worker_module, :__powertools_limits__, 0) do
      # ObanPowertools.Worker — route through new/2 to inherit redaction
      worker_module.new(args, queue: String.to_atom(entry.queue))
    else
      # Plain Oban.Worker — keep existing behavior
      Oban.Job.new(args, worker: entry.worker, queue: String.to_atom(entry.queue))
    end
  repo.insert(changeset)
end
```

**Risk:** `String.to_existing_atom("Elixir." <> entry.worker)` will raise if the atom was never loaded. Since `entry.worker` is the registered worker module name, it must be loaded at runtime (otherwise the cron entry itself would be invalid). This is safe, but add a rescue/fallback to bare `Oban.Job.new` as a degradation path for resilience.

**Alternative detection:** `function_exported?(worker_module, :__powertools_redact__, 0)` is more specific but only generated when `redact:` is declared. Using `__powertools_limits__/0` which is generated for ALL Powertools workers (even with `limits: []`) is the better sentinel. [VERIFIED: worker.ex:82 — `def __powertools_limits__, do: @powertools_limits` is always generated]

### Pattern 6: Required-Field Exemption (D-06)

**What:** At the perform re-cast, `Args.changeset/2` must not validate redacted fields as required, since they are intentionally absent from stored args.

**Where the collision occurs:** `worker.ex:97-101`:
```elixir
def changeset(struct, params) do
  fields = unquote(Keyword.keys(args_config))
  struct
  |> cast(params, fields)
  |> validate_required(fields)   # <-- ALL fields required, including redacted ones
end
```

**Fix:** Generate `Args.changeset/2` with the redacted fields removed from the `validate_required` list:

```elixir
# In __using__ quote block:
required_fields = Keyword.keys(args_config) -- redact_config

defmodule Args do
  use Ecto.Schema
  @primary_key false
  embedded_schema do
    unquote(fields)
  end

  def changeset(struct, params) do
    all_fields = unquote(Keyword.keys(args_config))
    required = unquote(required_fields)   # redacted fields excluded
    struct
    |> cast(params, all_fields)           # still cast all fields (present ones fill in)
    |> validate_required(required)        # only non-redacted fields required
  end
end
```

**Important:** `cast/3` must still list ALL fields (including redacted ones) because a retry that somehow has them (e.g., testing, backfill) should still cast correctly. Only `validate_required` shrinks.

### Pattern 7: Compile-Time Guards (D-07, D-09)

**Where:** In `__using__` at the same site as `validate_args_config!`, before the `quote do` block generates module code.

```elixir
# After validate_args_config! and normalize_limits_config!:
validate_redact_config!(redact_config, args_config, normalized_limits, __CALLER__)
```

```elixir
defp validate_redact_config!(redact_config, args_config, limits_config, _caller) do
  declared_arg_keys = Keyword.keys(args_config)

  # D-07: typo guard
  Enum.each(redact_config, fn key ->
    unless key in declared_arg_keys do
      raise ArgumentError,
            "redact: key #{inspect(key)} is not declared in :args schema. " <>
            "Declared fields: #{inspect(declared_arg_keys)}"
    end
  end)

  # D-09: partition-key collision guard
  partition_key =
    case Keyword.get(limits_config, :partition_by) do
      {:args, field} -> field
      _ -> nil
    end

  if partition_key && partition_key in redact_config do
    raise ArgumentError,
          "redact: field #{inspect(partition_key)} is also used as " <>
          "partition_by: {:args, #{inspect(partition_key)}}. " <>
          "A redacted field cannot be a partition key because the partition " <>
          "key value would be written to job meta."
  end
end
```

### Anti-Patterns to Avoid

- **Redacting inside `Args.changeset/2`:** The in-memory struct must retain values for `process/1`. Redaction at changeset time breaks execution.
- **Redacting before `generate_fingerprint`:** Would cause false dedup collisions for jobs with same non-redacted args but different redacted values.
- **Using Ecto's `field(:ssn, :string, redact: true)`:** This only affects `Inspect` output, not DB persistence.
- **Injecting `__redacted_fields__` in `transaction/3` in addition to `new/2`:** D-04 prohibits double injection. `transaction/3` calls `new/2` which handles it.
- **Using `Map.put(args, :ssn, nil)`:** D-02 requires key-absent, not nil. `Map.drop` is the only correct primitive.
- **Dropping on the post-JSONB string-keyed map:** Redaction must happen on the atom-keyed map BEFORE `Oban.Job.new` encodes to JSONB.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Map key normalization | Custom recursive normalizer | `Map.new/2` + atom resolution using known args_config keys | Simpler, less surface for bugs |
| Deep map merge | Custom merge | Existing `deep_merge/2` from `idempotency.ex` (or duplicate) | Already tested in production for fingerprint/limits/deadline meta |
| Meta injection ordering | Custom meta builder | Keyword-level merge into `opts[:meta]` using `deep_merge` | Same pattern as deadline meta (`merge_powertools_meta`) |
| Worker type detection | Module introspection | `function_exported?(mod, :__powertools_limits__, 0)` | Already generated for all Powertools workers |

---

## Common Pitfalls

### Pitfall 1: Double Meta Injection

**What goes wrong:** `__redacted_fields__` appears twice in the JSONB meta, or the second injection clobbers the first with an empty list.
**Why it happens:** If `transaction/3` also tries to inject `__redacted_fields__` (e.g., by checking `function_exported?(worker_mod, :__powertools_redact__, 0)`), and `new/2` also injects it, both paths fire.
**How to avoid:** Inject only in `new/2` override. `transaction/3` calls `new/2` — by construction the injection is single.
**Warning signs:** Tests showing `meta["__redacted_fields__"]` as a list-of-lists, or duplicated entries.

### Pitfall 2: Redaction Before Fingerprint on the Direct `new/2` Path

**What goes wrong:** The direct `MyWorker.new(args) |> Oban.insert()` path drops fields BEFORE fingerprinting IF Idempotency isn't involved. However, the direct path doesn't use `Idempotency.transaction/3` at all — it goes straight to `Oban.insert`, so there IS no Powertools fingerprint for the direct path. This is acceptable (direct insert bypasses idempotency by definition).
**Why it matters:** The fingerprint ordering invariant (D-03) applies only to the `transaction/3` path, where fingerprint happens at line 46 and `new/2` at line 81. The direct path has no fingerprint to protect.
**How to avoid:** Document that `MyWorker.new(args) |> Oban.insert()` gets redaction but no Powertools idempotency fingerprint — that is expected and consistent with how all direct-insert workers work.

### Pitfall 3: String-Key Args from Direct Callers

**What goes wrong:** Host calls `MyWorker.new(%{"ssn" => "123", "user_id" => 1})` with string keys. `Map.drop(args, [:ssn])` drops the atom key `:ssn` which does not exist — the `"ssn"` string key survives, and PII is stored.
**Why it happens:** The override uses atom keys from `args_config` for the drop, but the incoming map has string keys.
**How to avoid:** Normalize to atom keys before dropping. The normalization function must handle mixed-key maps: for each `{string_key, value}` pair where `string_key` corresponds to an atom in `args_config`, re-key to the atom.
**Warning signs:** Test with string-key args and assert the field is absent from the changeset.

### Pitfall 4: `validate_required` Collision on Retry

**What goes wrong:** A job with `args: [ssn: :string]` and `redact: [:ssn]` fails `validate/1` on every attempt because `ssn` is required but absent from stored args.
**Why it happens:** `Args.changeset/2` calls `validate_required(Keyword.keys(args_config))` which includes `:ssn`.
**How to avoid:** D-06 — generate `required_fields = Keyword.keys(args_config) -- redact_config`. The fix must happen at compile time in the generated `Args.changeset/2`.
**Warning signs:** A redact-typed worker that is always stuck in `retryable` state and never completes a second attempt.

### Pitfall 5: Cron Path PII Leak

**What goes wrong:** A cron-scheduled `redact:`-declaring worker is enqueued via `cron.ex:422` which calls `Oban.Job.new(args, worker: ...)` directly, bypassing `worker_mod.new/2`. The `__redacted_fields__` drop never fires for scheduled jobs.
**Why it happens:** The original cron path has no knowledge of the Powertools worker abstraction.
**How to avoid:** D-05 fix — detect Powertools workers in `maybe_insert_job` and route through `entry.worker.new/2`.
**Warning signs:** Integration test: enqueue via cron path for a `redact:` worker and assert the field is absent from the DB row.

### Pitfall 6: `render_job_field/3` Context Missing Redacted Field List

**What goes wrong:** The default renderer for `:job_args` doesn't know which fields are redacted because the context map doesn't include the meta.
**Why it happens:** `render_job_field(:job_args, job.args, %{job: job})` is already called with `%{job: job}` — the `job` struct includes `job.meta`. The renderer can access `job.meta["__redacted_fields__"]` from the context if it pattern-matches `%{job: job}`.
**How to avoid:** In the extended `render_job_field/3` for `:job_args`, extract `get_in(context, [:job, Access.key(:meta, %{}), "__redacted_fields__"])`. If non-nil, inject those field rows into the display.
**Warning signs:** UI test where a redacted-field worker's job detail shows an empty args panel with no disclosure rather than the "Redacted at enqueue" row.

### Pitfall 7: Partition Key Leak into Meta

**What goes wrong:** A worker declares `redact: [:user_id]` and `limits: [partition_by: {:args, :user_id}, ...]`. The limiter snapshot writes `"partition_key" => user_id_value` into `job.meta["oban_powertools"]["limits"]["partition_key"]`, defeating the redaction goal.
**Why it happens:** `merge_powertools_meta` resolves the partition key from the full args and writes it to meta before `new/2` drops the field from args.
**How to avoid:** D-09 compile-time guard raises before any of this can happen. The guard in `validate_redact_config!` is the safety net.
**Warning signs:** Compile-time test — a worker with overlapping `redact:` and `partition_by:` should fail at compile time.

---

## Code Examples

### Example 1: Complete `__using__` additions

```elixir
# Source: worker.ex (to be added)

# In defmacro __using__(opts):
redact_config = Keyword.get(opts, :redact, [])

oban_opts =
  opts
  |> Keyword.delete(:args)
  |> Keyword.delete(:limits)
  |> Keyword.delete(:timeout)
  |> Keyword.delete(:deadline)
  |> Keyword.delete(:record_output)
  |> Keyword.delete(:output_limit)
  |> Keyword.delete(:output_retention)
  |> Keyword.delete(:redact)    # NEW

validate_args_config!(args_config)
normalized_limits = normalize_limits_config!(limits_config, __CALLER__.module)
# ... existing normalizers ...
validate_redact_config!(redact_config, args_config, normalized_limits, __CALLER__)  # NEW

# In quote block:
@powertools_redact unquote(redact_config)   # NEW
def __powertools_redact__, do: @powertools_redact  # NEW

required_fields = Keyword.keys(args_config) -- redact_config  # NEW — for changeset

# Args module changeset updated:
def changeset(struct, params) do
  all_fields = unquote(Keyword.keys(args_config))
  required = unquote(required_fields)         # NEW — excludes redacted fields
  struct
  |> cast(params, all_fields)
  |> validate_required(required)
end

# new/2 override (NEW):
@impl Oban.Worker
def new(args, opts \\ []) when is_map(args) and is_list(opts) do
  ObanPowertools.Worker.Redaction.apply(args, opts, @powertools_redact, &super/2)
end

defoverridable new: 1, new: 2
```

### Example 2: `ObanPowertools.Worker.Redaction.apply/4`

```elixir
# Source: lib/oban_powertools/worker/redaction.ex (NEW file)

defmodule ObanPowertools.Worker.Redaction do
  @moduledoc false

  def apply(args, opts, [], super_fn) do
    super_fn.(args, opts)
  end

  def apply(args, opts, redact_keys, super_fn) do
    redact_strings = redact_keys |> Enum.map(&Atom.to_string/1) |> Enum.sort()

    # Normalize mixed key shapes: ensure redact_keys can be dropped
    normalized = normalize_to_atom_keys(args, redact_keys)
    clean_args = Map.drop(normalized, redact_keys)

    # Inject __redacted_fields__ into meta (merge, don't clobber)
    opts_with_meta = inject_meta(opts, redact_strings)

    super_fn.(clean_args, opts_with_meta)
  end

  defp normalize_to_atom_keys(args, atom_keys) do
    # Build a string -> atom mapping for known redact keys
    str_to_atom = Map.new(atom_keys, fn k -> {Atom.to_string(k), k} end)

    Map.new(args, fn {k, v} ->
      case k do
        k when is_atom(k) -> {k, v}
        k when is_binary(k) ->
          case Map.get(str_to_atom, k) do
            nil -> {k, v}        # unknown string key — leave as-is
            atom -> {atom, v}    # known redactable key — convert to atom
          end
      end
    end)
  end

  defp inject_meta(opts, redact_strings) do
    existing_meta = Keyword.get(opts, :meta, %{})
    merged = deep_merge(existing_meta, %{"__redacted_fields__" => redact_strings})
    Keyword.put(opts, :meta, merged)
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right),
    do: Map.merge(left, right, fn _k, a, b -> deep_merge(a, b) end)
  defp deep_merge(_left, right), do: right
end
```

### Example 3: `render_job_field/3` extension for redaction disclosure

```elixir
# Source: runtime_config.ex — extending existing render_job_field/3

# Existing at line 206:
def render_job_field(kind, value, context) do
  case apply_policy(kind, value, context) do
    nil -> {:raw_json, Jason.encode!(value || %{}, pretty: true)}
    text when is_binary(text) -> {:string, text}
    %{} = redacted_map -> {:raw_json, Jason.encode!(redacted_map, pretty: true)}
    other -> raise ArgumentError, invalid_return_message(kind, other)
  end
rescue
  _ -> {:fallback, "[redacted]"}
end

# Extended approach: intercept :job_args before apply_policy
# when context has __redacted_fields__ in meta:

def render_job_field(:job_args, value, context) do
  redacted_fields = get_redacted_fields(context)

  if redacted_fields == [] do
    # no redaction — existing behavior
    render_job_field_default(:job_args, value, context)
  else
    case apply_policy(:job_args, value, context) do
      nil ->
        # Default: inject redacted field rows into the JSON display
        annotated = build_redacted_args_map(value || %{}, redacted_fields)
        {:raw_json, Jason.encode!(annotated, pretty: true)}
      text when is_binary(text) -> {:string, text}
      %{} = rendered_map ->
        annotated = build_redacted_args_map(rendered_map, redacted_fields)
        {:raw_json, Jason.encode!(annotated, pretty: true)}
      other -> raise ArgumentError, invalid_return_message(:job_args, other)
    end
  end
rescue
  _ -> {:fallback, "[redacted]"}
end

defp get_redacted_fields(%{job: %Oban.Job{meta: meta}}) do
  Map.get(meta || %{}, "__redacted_fields__", [])
end
defp get_redacted_fields(_), do: []

defp build_redacted_args_map(args_map, redacted_fields) do
  redacted_overlay = Map.new(redacted_fields, fn f -> {f, "Redacted at enqueue"} end)
  Map.merge(args_map, redacted_overlay)
end
```

### Example 4: `jobs_live.ex` redaction disclosure near Meta card

```elixir
# In load_job_detail/2 — add alongside args_display/meta_display:
redacted_fields =
  case get_in(job.meta, ["__redacted_fields__"]) do
    fields when is_list(fields) -> fields
    _ -> []
  end

socket
|> assign(:args_display, args_display)
|> assign(:meta_display, meta_display)
|> assign(:redacted_fields, redacted_fields)   # NEW
...

# In render/1 template — near Meta card:
<%= if @redacted_fields != [] do %>
  <div class="rounded-lg border bg-white p-4">
    <p class="text-xs font-semibold text-zinc-500">
      Fields redacted at enqueue:
      <%= Enum.map(@redacted_fields, &":#{&1}") |> Enum.join(", ") %>
    </p>
  </div>
<% end %>
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Oban OSS: no at-rest redaction | `redact:` drops fields from JSONB before storage | Compliance-clean; field never written |
| Oban Pro: `encrypted:` (scrambles args) | `redact:` (deletes args) | Key-absent is cleaner for compliance audits |
| Display-time masking via `DisplayPolicy` | At-persist deletion PLUS display annotation | Two complementary features; `redact:` is persistence; `DisplayPolicy` is display |

**Deprecated/outdated:**
- Ecto `field(:ssn, :string, redact: true)`: display-only, NOT at-persist protection — do not use.

---

## Runtime State Inventory

Not applicable. This is a greenfield feature addition, not a rename/refactor/migration phase. No existing stored data, live service config, OS-registered state, secrets, or build artifacts reference `__redacted_fields__` or the `redact:` config. The `JobRecord.redacted` field (which must remain `false`) is an existing column that is explicitly left untouched (D-10).

---

## Open Questions

1. **`super` vs delegating to a named helper**
   - What we know: The existing `perform/1` override uses `__powertools_perform__` as a private dispatch helper rather than `super`. This avoids `super` scoping complexities inside quote blocks.
   - What's unclear: Whether using `super` inside a `quote do` block in `__using__` is idiomatic or requires a workaround (e.g., capturing the Oban-generated `new/2` into a module-attribute function reference before overriding).
   - Recommendation: Use the helper-module pattern (`ObanPowertools.Worker.Redaction.apply/4` takes a `super_fn` lambda) which avoids `super` complications entirely. The lambda captures `&super/2` at the macro expansion site where it is valid.
   - **Note for planner:** The safest implementation is `Oban.Worker.new(args, opts)` directly (calling the original generator's logic) but that bypasses `__opts__` merge. The correct approach is to call `Oban.Job.new(args, Oban.Worker.merge_opts(__opts__(), opts))` explicitly, mirroring what Oban's generated `new/2` does. This sidesteps `super` entirely and is explicit.

2. **Cron path: `String.to_existing_atom` safety**
   - What we know: `entry.worker` is a string like `"MyApp.MyWorker"` — the module atom must exist since the cron entry was registered.
   - What's unclear: Edge case where a cron entry references a recently removed worker module that is no longer loaded.
   - Recommendation: Wrap in `rescue ArgumentError -> Oban.Job.new(args, ...)` fallback so a missing/unloaded worker gracefully degrades rather than crashing the cron run. Log a warning.

3. **`apply_policy` for `:job_args` kind in existing `DisplayPolicy`**
   - What we know: `render_job_field/3` dispatches `apply_policy(:job_args, job.args, context)` to the host display policy. Some hosts may override `:job_args` rendering entirely.
   - What's unclear: If a host's policy returns a custom `%{}` for `:job_args`, should the Powertools default still inject "Redacted at enqueue" rows into their custom map?
   - Recommendation: Only inject redacted rows when policy returns `nil` (default path). If the host policy returns a custom map, pass it through as-is — the host is responsible for handling `__redacted_fields__` in their policy. Document this in DX guide (D-11).

---

## Environment Availability

Step 2.6: SKIPPED. No external tool or service dependencies introduced. Pure Elixir/Ecto/Phoenix code changes.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/oban_powertools/worker_test.exs test/oban_powertools/idempotency_test.exs test/oban_powertools/cron_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REDACT-01 | `redact: [:ssn]` → ssn absent from enqueued job's args JSONB; fingerprint computed from full args | integration (real Postgres) | `mix test test/oban_powertools/worker_test.exs -r "redact"` | Wave 0 gap |
| REDACT-01 | Direct `MyWorker.new(%{ssn: "123", user_id: 1}) |> Repo.insert()` → ssn absent | integration | see above | Wave 0 gap |
| REDACT-01 | String-key args `%{"ssn" => "123"}` → ssn absent | unit | see above | Wave 0 gap |
| REDACT-01 | Fingerprint from full args (two jobs with different ssn, same user_id → different fingerprints if non-redacted; same fingerprint via idempotency if full args same) | integration | `mix test test/oban_powertools/idempotency_test.exs -r "redact"` | Wave 0 gap |
| REDACT-01 | Typed+redacted worker runs and retries cleanly (no validate_required failure on stored args) | integration | `mix test test/oban_powertools/worker_test.exs -r "required.*redact"` | Wave 0 gap |
| REDACT-01 | D-07 typo guard: `redact: [:typo_field]` raises ArgumentError at compile time | unit | compile-time assertion test | Wave 0 gap |
| REDACT-01 | D-09 partition-key guard: `redact: [:user_id]` + `partition_by: {:args, :user_id}` raises ArgumentError | unit | compile-time assertion test | Wave 0 gap |
| REDACT-02 | Enqueued job has `meta["__redacted_fields__"] == ["ssn", "token"]` (sorted strings) | integration | `mix test test/oban_powertools/worker_test.exs -r "__redacted_fields__"` | Wave 0 gap |
| REDACT-02 | `__redacted_fields__` meta not clobbered by existing fingerprint/limits/deadline meta | integration | `mix test test/oban_powertools/idempotency_test.exs -r "meta.*redact"` | Wave 0 gap |
| REDACT-02 | `__redacted_fields__` injected exactly once (not doubled via transaction path) | integration | assert meta field is a flat list, not list-of-lists | Wave 0 gap |
| REDACT-02 | Cron-enqueued job for `redact:` worker has `__redacted_fields__` in meta and field absent from args | integration | `mix test test/oban_powertools/cron_test.exs -r "redact"` | Wave 0 gap |
| REDACT-03 | `/ops/jobs` detail view renders "Fields redacted at enqueue: [:ssn, :token]" | LiveView / integration | `mix test test/oban_powertools/web/live/jobs_live_test.exs -r "redact"` | Wave 0 gap |
| REDACT-03 | Empty state: job with no `__redacted_fields__` in meta shows no redaction disclosure | LiveView | see above | Wave 0 gap |
| REDACT-04 | `render_job_field(:job_args, args, %{job: job_with_meta})` returns map with "Redacted at enqueue" for listed field | unit | `mix test test/oban_powertools/worker_test.exs -r "render_job_field"` | Wave 0 gap |
| REDACT-04 | Fallback still `[redacted]` when display policy raises | unit | see above | existing pattern |
| REDACT-04 | Host policy returning custom map is not overridden with Powertools default | unit | policy override test | Wave 0 gap |

### Redaction Invariant Validation

| Invariant | Proof Required | Test Type |
|-----------|---------------|-----------|
| Fingerprint-before-drop | Two jobs with same user_id but different ssn produce different Powertools fingerprints; redaction does not cause false dedup | integration |
| Key-absent-not-nil | `Map.has_key?(job.args, "ssn") == false` (not `job.args["ssn"] == nil`) | integration (Repo.get(Oban.Job, id).args) |
| Single meta injection | `job.meta["__redacted_fields__"]` is a `List.t(String.t())`, not nested | integration |
| Cron coverage | Cron-scheduled job for redact-worker has field absent from stored args | integration |
| Required-field exemption | Worker with `args: [ssn: :string, user_id: :integer], redact: [:ssn]` validates and processes job where stored args has only `%{"user_id" => 1}` | integration |
| Partition-key guard | `use ObanPowertools.Worker, args: [u: :integer], redact: [:u], limits: [partition_by: {:args, :u}, ...]` raises at compile time | compile-time test (assert_raise inside a quoted Module.create) |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/worker_test.exs test/oban_powertools/idempotency_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/oban_powertools/worker_test.exs` — add redaction test group covering REDACT-01/02/04 and all invariants (required-field exemption, string-key normalization, typo guard, partition-key guard)
- [ ] `test/oban_powertools/idempotency_test.exs` — add redaction tests (fingerprint ordering, meta single-injection, meta non-clobber)
- [ ] `test/oban_powertools/cron_test.exs` — add cron-path redaction coverage (field absent, meta present for scheduled Powertools workers)
- [ ] `test/oban_powertools/web/live/jobs_live_test.exs` — add redaction disclosure tests (REDACT-03 copy, empty state, REDACT-04 render_job_field)
- [ ] No new framework installation needed — ExUnit + DataCase + sandbox already in place

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Compile-time `validate_redact_config!` guards |
| V6 Cryptography | no | Redaction is deletion, not encryption |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fingerprint brute-force via small-domain redacted fields (e.g., 4-digit PIN) | Information Disclosure | Document risk in guides; recommend redacting high-entropy fields or pre-hashing before enqueue |
| PII leakage via `oban_jobs.errors` column (exception messages may include inspected args) | Information Disclosure | Document explicitly: `redact:` protects `oban_jobs.args` only; errors column not in scope |
| PII leakage via limiter partition key in `oban_powertools.limits.partition_key` meta | Information Disclosure | D-09 compile-time guard prevents this configuration |
| Cron bypass: scheduled job enqueued via bare `Oban.Job.new` bypasses worker's `new/2` | Security Feature Bypass | D-05 fix in `cron.ex:422` |

---

## Sources

### Primary (HIGH confidence)

- `lib/oban_powertools/worker.ex` — direct codebase read; all line numbers verified
- `lib/oban_powertools/idempotency.ex` — direct codebase read; fingerprint at line 46, `worker_mod.new` at line 81, `deep_merge` pattern
- `lib/oban_powertools/cron.ex:422` — direct codebase read; bare `Oban.Job.new` bypass confirmed
- `lib/oban_powertools/runtime_config.ex` — direct codebase read; `render_job_field/3` at line 206
- `deps/oban/lib/oban/worker.ex:482-496` — direct source read; generated `new/2` and `defoverridable Worker`
- `.planning/phases/56-redact-at-rest/56-CONTEXT.md` — locked decisions D-01 through D-17
- `.planning/phases/56-redact-at-rest/56-UI-SPEC.md` — approved UI contract
- `.planning/research/FEATURES.md` §"At-rest Redaction (redact:)" — authoritative framing
- `.planning/research/PITFALLS.md` §"At-rest Redaction" — pitfall catalog

### Secondary (MEDIUM confidence)

- `.planning/phases/53-worker-lifecycle-hooks/53-CONTEXT.md` — wrapper ordering (D-20/D-21: redaction at enqueue/recording boundaries)
- `.planning/phases/55-output-recording-jobrecord/55-CONTEXT.md` — D-10/D-36 basis for leaving `JobRecord.redacted` untouched

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `function_exported?(mod, :__powertools_limits__, 0)` is a reliable sentinel for "is this an ObanPowertools.Worker" because it is always generated regardless of limits config | Cron fix (Pattern 5) | If a plain Oban.Worker somehow defines `__powertools_limits__/0`, it would be routed through `worker_module.new/2` which would fail. Probability: negligible — this is a Powertools-specific generated function. |
| A2 | `String.to_existing_atom("Elixir." <> entry.worker)` succeeds at cron execution time because the worker module is loaded | Cron fix (Pattern 5) | If an unloaded module is referenced, raises `ArgumentError`. Mitigated by the rescue/fallback recommendation. |
| A3 | The `super` / lambda capture approach for delegating `new/2` to Oban's implementation works cleanly in the `__using__` quote context | Pattern 1 | If `super` is syntactically unavailable inside `quote do`, the explicit `Oban.Job.new(args, Oban.Worker.merge_opts(__opts__(), opts))` fallback is the definitive safe path. |

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all seams are existing, verified code
- Architecture: HIGH — all integration points read from source; ordering verified at exact line numbers
- Pitfalls: HIGH — derived from direct code inspection and PITFALLS.md (authoritative, researched for this milestone)
- UI: HIGH — verified against existing jobs_live.ex template and runtime_config.ex patterns

**Research date:** 2026-06-13
**Valid until:** 2026-07-13 (30 days — all claims against stable local codebase)
