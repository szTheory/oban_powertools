# Phase 57: Doctor Manifest Fix - Research

**Researched:** 2026-06-13
**Domain:** Elixir module attribute map (compile-time data patch in existing check module)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Add `"output-recording" => ["oban_powertools_job_records"]` as a new group entry in `@powertools_manifest`.
- **D-02:** Insert the new group after the existing `"heartbeat-lifeline"` entry (chronological order).
- **D-03:** Update `test/oban_powertools/doctor/checks_test.exs` line 104 test description from `"all 4 groups present"` to `"all 5 groups present"`.
- **D-04:** No other test changes expected.
- **D-05:** No new SQL queries — `powertools_tables/1` already iterates `@powertools_manifest`.
- **D-06:** No changes to Doctor CLI output format or JSON schema.

### Claude's Discretion
None — all implementation decisions are locked.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INT-01 | Doctor detects missing `oban_powertools_job_records` table — add to `@powertools_manifest` under `"output-recording"` group in `lib/oban_powertools/doctor/checks.ex`; update test description to "5 groups present" | Exact insertion point confirmed at `checks.ex:52-58`; test line confirmed at `checks_test.exs:104`; table confirmed present in test DB (happy-path passes automatically) |
</phase_requirements>

---

## Summary

Phase 57 is a surgical two-file patch: add one map entry to a compile-time module attribute in `checks.ex`, and update one test description string in `checks_test.exs`. No new dependencies, no new migrations, no new query logic — the existing `powertools_tables/1` check already iterates `@powertools_manifest` and queries `information_schema.tables` for every entry.

The gap was introduced in Phase 55, which shipped the `oban_powertools_job_records` table and `ObanPowertools.JobRecord` schema but did not add the table to `@powertools_manifest`. As a result, an operator running `mix oban_powertools.doctor` on an under-migrated DB would get a clean bill of health even though the output-recording feature was non-functional. The fix closes this silent gap.

The happy-path test (`powertools_tables/1` returns `[]` on a fully-migrated DB) passes automatically once the manifest entry is present, because `oban_powertools_job_records` is confirmed present in the test database (`oban_powertools_test`). The only test file change required is updating the human-readable description string from "all 4 groups present" to "all 5 groups present".

**Primary recommendation:** Make both edits in a single plan wave. The changes are co-dependent (manifest + test description) and trivially small — there is no value in splitting them across multiple waves.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Table-presence detection | API / Backend (Mix task / Doctor check) | — | `powertools_tables/1` queries `information_schema.tables` at runtime; runs in the Mix task process |
| Manifest definition | Compile-time module attribute | — | `@powertools_manifest` is a compile-time constant in `checks.ex`; no runtime configuration |
| Test verification | Test suite | — | `checks_test.exs` exercises the live `powertools_tables/1` against the test DB |

---

## Standard Stack

### Core

No new libraries. This phase operates entirely within the existing project stack.

| File | Role | Change |
|------|------|--------|
| `lib/oban_powertools/doctor/checks.ex` | Module containing `@powertools_manifest` | Add one map entry |
| `test/oban_powertools/doctor/checks_test.exs` | Doctor check test suite | Update one description string |

### Installation

No packages to install. [VERIFIED: project has no new dependencies for this phase]

---

## Package Legitimacy Audit

No packages are installed in this phase.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### How `@powertools_manifest` Works

`@powertools_manifest` is a compile-time module attribute defined at `checks.ex:26-59`. It is a plain Elixir map where each key is a kebab-case string (the migration set name) and each value is a list of table name strings.

`powertools_tables/1` (`checks.ex:244-288`) works as follows:
1. Collects all table names: `Enum.flat_map(@powertools_manifest, fn {_group, tables} -> tables end)`
2. Queries `information_schema.tables` with `table_name = ANY($1)` against the `public` schema
3. Builds a `MapSet` of present tables
4. Iterates the manifest: for each group, finds missing tables and emits one `:error` finding per group with missing tables named

Adding a new entry to `@powertools_manifest` is sufficient — no changes to the check function, SQL query, or Finding construction.

[VERIFIED: direct source read of `lib/oban_powertools/doctor/checks.ex`]

### Existing Group Name Convention

Group names are kebab-case strings matching the feature area:
- `"foundation"` — audit events, idempotency receipts
- `"smart-engine"` — limit resources, cron, blockers
- `"workflow"` — workflow tables (10 tables)
- `"heartbeat-lifeline"` — heartbeats, lifeline, repair, archive

New entry: `"output-recording"` — matches the `record_output:` worker option and `ObanPowertools.JobRecord` module naming convention.

[VERIFIED: direct source read of `lib/oban_powertools/doctor/checks.ex:26-59`]

### Exact Insertion Point

Current `@powertools_manifest` ends at line 59:

```elixir
    "heartbeat-lifeline" => [
      "oban_powertools_heartbeats",
      "oban_powertools_lifeline_incidents",
      "oban_powertools_repair_previews",
      "oban_powertools_archive_runs",
      "oban_powertools_repair_archives"
    ]
  }
```

The new entry goes between the closing `]` of `"heartbeat-lifeline"` and the closing `}` of the map — i.e., the map gains a trailing comma after `"heartbeat-lifeline"` and the new group is appended before `}`.

[VERIFIED: direct source read of `lib/oban_powertools/doctor/checks.ex:52-59`]

### System Architecture Diagram

```
mix oban_powertools.doctor
        |
        v
ObanPowertools.Doctor.Run.run/2
        |
        v
Checks.powertools_tables(repo)
        |
        +-- collects all tables from @powertools_manifest (compile-time)
        |
        +-- queries information_schema.tables WHERE table_name = ANY($1)
        |
        +-- for each group in manifest:
        |       find missing tables → emit Finding if any
        |
        v
[findings] ([] = healthy, non-empty = error per missing group)
```

### Recommended Project Structure

No structural changes. Both touched files already exist:
```
lib/oban_powertools/doctor/
└── checks.ex          # @powertools_manifest — add "output-recording" entry

test/oban_powertools/doctor/
└── checks_test.exs    # line 104 description — "4 groups" → "5 groups"
```

### Anti-Patterns to Avoid

- **Do not add a new `powertools_tables` overload or clause** — the existing function iterates the manifest dynamically; a data change is sufficient.
- **Do not touch the SQL query** — `table_name = ANY($1)` already handles arbitrary-length lists.
- **Do not add a new test case** — the existing "returns [] on the migrated test DB" test automatically covers the happy path once `oban_powertools_job_records` is in the manifest and in the DB.
- **Do not search for other occurrences of "4 groups"** — confirmed only one occurrence at `checks_test.exs:104`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Table presence detection | Custom query or new function | Extend `@powertools_manifest` — existing `powertools_tables/1` handles it |
| Group-level error messages | New Finding construction | Existing `powertools_tables/1` emits correctly named findings per group |

**Key insight:** The manifest pattern was designed for exactly this extensibility. Adding a group entry is the intended mechanism.

---

## Common Pitfalls

### Pitfall 1: Forgetting the comma after the preceding group

**What goes wrong:** Elixir map syntax requires a comma between entries. Omitting the comma after the `"heartbeat-lifeline"` entry causes a compile error.

**How to avoid:** After inserting the new entry, ensure `"heartbeat-lifeline" => [...],` has a trailing comma.

**Warning signs:** `** (SyntaxError) lib/oban_powertools/doctor/checks.ex` on `mix compile`.

### Pitfall 2: Wrong table name string

**What goes wrong:** Using a variant name (e.g., `"oban_powertools_job_record"` without the `s`) causes the group to always report the table missing.

**How to avoid:** The canonical table name is `"oban_powertools_job_records"` (plural), confirmed by:
- `ObanPowertools.JobRecord` schema (`schema "oban_powertools_job_records"` at `job_record.ex:21`)
- Install task (`lib/mix/tasks/oban_powertools.install.ex:846,850`)
- PostgreSQL test DB (`\dt oban_powertools_job_records` — table confirmed present)

[VERIFIED: direct source reads of `lib/oban_powertools/job_record.ex:21` and `lib/mix/tasks/oban_powertools.install.ex:846`]

### Pitfall 3: Test description update missed

**What goes wrong:** Manifest is updated but test description at line 104 still says "4 groups present" — the test passes but misleads future readers.

**How to avoid:** Update both files in the same wave. The description change is cosmetic (the test logic does not check the count string) but is required by D-03 and success criterion 3.

---

## Code Examples

### Final shape of the updated `@powertools_manifest`

```elixir
# Source: lib/oban_powertools/doctor/checks.ex — after Phase 57 edit
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
  ],
  "output-recording" => [
    "oban_powertools_job_records"
  ]
}
```

[VERIFIED: derived from direct source read of `lib/oban_powertools/doctor/checks.ex:26-59`]

### Updated test description

```elixir
# Source: test/oban_powertools/doctor/checks_test.exs — after Phase 57 edit (line 104)
test "returns [] on the migrated test DB (all 5 groups present)" do
  result = Checks.powertools_tables(TestRepo)
  assert result == []
end
```

[VERIFIED: current line 104 reads `"all 4 groups present"` — confirmed by direct source read]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual check per table | Manifest-driven iteration | Phase design (prior) | New tables need only a manifest entry — no new query code |

**Deprecated/outdated:** None relevant to this phase.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

**All claims in this research were verified by direct source reads or test DB inspection. No assumed claims.**

---

## Open Questions

None. All implementation details are confirmed by direct code inspection.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — this is a code-only change to two existing files)

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/oban_powertools/doctor/checks_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INT-01 | `powertools_tables/1` returns `[]` on a fully-migrated DB with all 5 groups | integration | `mix test test/oban_powertools/doctor/checks_test.exs` | Yes |
| INT-01 | Error finding names `oban_powertools_job_records` when table is absent | integration | `mix test test/oban_powertools/doctor/checks_test.exs` | Yes (existing framework covers; no new test case needed per D-04) |

### Sampling Rate

- **Per task commit:** `mix test test/oban_powertools/doctor/checks_test.exs`
- **Phase gate:** `mix test` full suite green before `/gsd:verify-work`

### Wave 0 Gaps

None — existing test infrastructure covers all phase requirements. The existing `"returns [] on the migrated test DB"` test becomes the INT-01 happy-path validator once the manifest is updated and its description string is corrected.

---

## Security Domain

No security surface introduced or modified. This phase edits a compile-time data structure and a test description string. No input validation, auth, cryptography, or external data handling is involved.

`security_enforcement` is not explicitly set to `false` in `.planning/config.json` — but there is no applicable ASVS category for a compile-time map entry edit.

---

## Sources

### Primary (HIGH confidence)
- `lib/oban_powertools/doctor/checks.ex` (direct read) — `@powertools_manifest` structure, `powertools_tables/1` implementation, exact insertion point
- `test/oban_powertools/doctor/checks_test.exs` (direct read) — line 104 description confirmed
- `lib/oban_powertools/job_record.ex:21` (direct read) — canonical table name `"oban_powertools_job_records"` confirmed
- `lib/mix/tasks/oban_powertools.install.ex:846-870` (direct read) — install task confirms table name and migration set
- PostgreSQL test DB query — `oban_powertools_job_records` confirmed present in `oban_powertools_test`
- `mix test test/oban_powertools/doctor/checks_test.exs` (live run) — 18 tests, 0 failures on current code

### Secondary (MEDIUM confidence)
None needed — all claims derived from primary sources.

### Tertiary (LOW confidence)
None.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; existing module confirmed by direct read
- Architecture: HIGH — `powertools_tables/1` iteration logic confirmed by direct read
- Pitfalls: HIGH — syntax pitfall is standard Elixir; table name verified against three authoritative sources

**Research date:** 2026-06-13
**Valid until:** Stable indefinitely (compile-time constant edit; no external dependencies)
