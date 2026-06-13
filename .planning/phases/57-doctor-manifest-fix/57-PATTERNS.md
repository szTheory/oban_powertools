# Phase 57: Doctor Manifest Fix - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 2 (both modified, neither created)
**Analogs found:** 2 / 2 (self-referential — each file is its own analog; the pattern is already in situ)

---

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/doctor/checks.ex` | config (compile-time module attribute) | batch (manifest-driven iteration) | `lib/oban_powertools/doctor/checks.ex` lines 26-59 (existing entries) | exact — extend in place |
| `test/oban_powertools/doctor/checks_test.exs` | test | request-response | `test/oban_powertools/doctor/checks_test.exs` lines 103-115 (existing describe block) | exact — update description string in place |

---

## Pattern Assignments

### `lib/oban_powertools/doctor/checks.ex` (config, batch)

**Analog:** Same file, lines 26-59 — the existing `@powertools_manifest` entries are the direct pattern to extend.

**Module attribute definition pattern** (lines 24-59):

```elixir
# Powertools table manifest grouped by migration set (D-12)
# Source: lib/mix/tasks/oban_powertools.install.ex migration functions (authoritative)
@powertools_manifest %{
  "foundation" => [
    "oban_powertools_audit_events",
    "oban_powertools_idempotency_receipts"
  ],
  "smart-engine" => [
    "oban_powertools_limit_resources",
    "oban_powertools_limit_states",
    "oban_powertools_cron_entries",
    "oban_powertools_cron_slots",
    "oban_powertools_blocker_snapshots",
    "oban_powertools_limiter_history_facts",
    "oban_powertools_cron_coverages"
  ],
  "workflow" => [
    "oban_powertools_workflows",
    "oban_powertools_workflow_steps",
    "oban_powertools_workflow_edges",
    "oban_powertools_workflow_results",
    "oban_powertools_workflow_awaits",
    "oban_powertools_workflow_signals",
    "oban_powertools_workflow_recovery_sessions",
    "oban_powertools_workflow_recovery_attempts",
    "oban_powertools_workflow_callback_outbox",
    "oban_powertools_workflow_command_attempts"
  ],
  "heartbeat-lifeline" => [
    "oban_powertools_heartbeats",
    "oban_powertools_lifeline_incidents",
    "oban_powertools_repair_previews",
    "oban_powertools_archive_runs",
    "oban_powertools_repair_archives"
  ]
}
```

**What to copy — exact insertion:**
- Add a trailing comma after the closing `]` of the `"heartbeat-lifeline"` entry (currently line 58).
- Append the new group before the closing `}` of the map:

```elixir
  "output-recording" => [
    "oban_powertools_job_records"
  ]
```

**Group name convention:** kebab-case string matching the feature area (`"foundation"`, `"smart-engine"`, `"workflow"`, `"heartbeat-lifeline"`, now `"output-recording"`). Each value is a plain list of snake_case PostgreSQL table name strings.

**Pitfall — trailing comma:** After the edit, `"heartbeat-lifeline" => [...],` must carry a trailing comma. Omitting it produces a compile-time `SyntaxError`.

**Pitfall — table name:** The canonical table name is `"oban_powertools_job_records"` (plural `s`). Confirmed by `lib/oban_powertools/job_record.ex:21` (`schema "oban_powertools_job_records"`).

---

### `test/oban_powertools/doctor/checks_test.exs` (test, request-response)

**Analog:** Same file, lines 103-115 — the existing `powertools_tables/1` describe block is the direct pattern.

**Current test block** (lines 103-115):

```elixir
describe "powertools_tables/1" do
  test "returns [] on the migrated test DB (all 4 groups present)" do
    result = Checks.powertools_tables(TestRepo)
    assert result == []
  end

  test "queries public schema regardless of prefix — the function takes repo only" do
    # The function signature is powertools_tables(repo) — no prefix argument.
    # Verify it compiles and runs correctly.
    result = Checks.powertools_tables(TestRepo)
    assert is_list(result)
  end
end
```

**What to copy — exact change:**
- Line 104: change `"returns [] on the migrated test DB (all 4 groups present)"` to `"returns [] on the migrated test DB (all 5 groups present)"`.
- No other lines in this block change.

**Test structure convention (for reference):** Tests in this file use `assert result == []` for the happy path and `assert length(result) >= 1` plus `Enum.any?/2` for error-finding assertions. This pattern is already established and no new test cases are added in Phase 57.

---

## Shared Patterns

### Module Attribute (Compile-Time Data)

**Source:** `lib/oban_powertools/doctor/checks.ex` lines 26-59
**Apply to:** `lib/oban_powertools/doctor/checks.ex` (the edit target itself)

The `@powertools_manifest` attribute is a plain Elixir map literal — no runtime configuration, no `Application.get_env`, no external input. Adding a new key-value pair is the entire change. The `powertools_tables/1` function at line 244 iterates this map dynamically via `Enum.flat_map` and does not require any modification when a group is added.

### ExUnit Test Description String

**Source:** `test/oban_powertools/doctor/checks_test.exs` line 104
**Apply to:** `test/oban_powertools/doctor/checks_test.exs` line 104

Test descriptions in this file are human-readable strings embedded in the `test/2` macro call. The count in the description (`"all 4 groups present"`) is a documentation string, not a value asserted by the test itself. The test logic (`assert result == []`) is unchanged; only the string is updated to reflect the new group count.

---

## No Analog Found

None. Both modified files are well-established in the codebase and each file's existing content is the direct analog for the edit.

---

## Metadata

**Analog search scope:** `lib/oban_powertools/doctor/`, `test/oban_powertools/doctor/`
**Files scanned:** 2 (the two edit targets, read in full)
**Pattern extraction date:** 2026-06-13

**Notes:**
- Phase 57 is a pure data addition — no new modules, functions, imports, or dependencies.
- The existing manifest-iteration logic in `powertools_tables/1` (lines 244-288) requires zero changes.
- Both edits are co-dependent and must be made in a single wave.
- Validation command: `mix test test/oban_powertools/doctor/checks_test.exs`
