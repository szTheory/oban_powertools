# Phase 57: Doctor Manifest Fix - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Add `oban_powertools_job_records` to `@powertools_manifest` in `lib/oban_powertools/doctor/checks.ex` so Doctor detects when the output-recording table is absent. Update the test description at `checks_test.exs:104` from "all 4 groups present" to "all 5 groups present". No new dependencies, migrations, or API surface changes.

</domain>

<decisions>
## Implementation Decisions

### Manifest Change
- **D-01:** Add `"output-recording" => ["oban_powertools_job_records"]` as a new group entry in `@powertools_manifest` — group key matches the `record_output:` option name and `ObanPowertools.JobRecord` module naming convention.
- **D-02:** Insert the new group after the existing `"heartbeat-lifeline"` entry (chronological order — Phase 55 shipped after Phase 33's heartbeat-lifeline tables).

### Test Update
- **D-03:** Update `test/oban_powertools/doctor/checks_test.exs` line 104 test description from `"all 4 groups present"` to `"all 5 groups present"`.
- **D-04:** No other test changes expected — the manifest check test verifies group count and table presence; adding a new group with a correctly-migrated table passes automatically once the manifest entry exists.

### Scope Boundary
- **D-05:** No new SQL queries — the manifest-based `powertools_tables/1` check already iterates `@powertools_manifest` and queries `pg_catalog.pg_tables` for each entry. Adding a new group entry is sufficient.
- **D-06:** No changes to the Doctor CLI output format or JSON schema — the new table will appear inside existing `"powertools_tables"` check findings.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Implementation Target
- `lib/oban_powertools/doctor/checks.ex` — file containing `@powertools_manifest`; add `"output-recording"` group entry here
- `test/oban_powertools/doctor/checks_test.exs` — update line 104 test description from "all 4 groups present" to "all 5 groups present"

### Requirements
- `.planning/REQUIREMENTS.md` §INT-01 — exact change description and file targets
- `.planning/ROADMAP.md` §Phase 57 — success criteria (3 conditions must be true after the fix)

### Prior Phase Context
- `lib/oban_powertools/job_record.ex` — the `ObanPowertools.JobRecord` schema that introduced `oban_powertools_job_records` in Phase 55; confirms table name

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `@powertools_manifest` at `checks.ex:26` — existing map structure is the exact insertion point; each group key is a string, value is a list of table name strings.
- `powertools_tables/1` check function — already iterates the manifest and queries `pg_catalog.pg_tables`; no code changes to the check function itself are needed.

### Established Patterns
- Group names use kebab-case strings matching feature areas: `"foundation"`, `"smart-engine"`, `"workflow"`, `"heartbeat-lifeline"`.
- `"output-recording"` follows the same pattern and maps cleanly to the `record_output:` worker option and `ObanPowertools.JobRecord` naming.

### Integration Points
- Doctor test at `checks_test.exs:104` has the hardcoded "all 4 groups present" description — this is the only test change needed.
- The `examples/hex_consumer/` app verifies Doctor behavior against the live schema; adding the manifest entry means a fully-migrated consumer DB passes, an under-migrated one fails with a named error.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. The implementation is a pure data addition.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 57-Doctor Manifest Fix*
*Context gathered: 2026-06-13*
