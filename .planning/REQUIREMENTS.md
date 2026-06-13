# Requirements — v1.8 Integration Fixes

## Milestone Goal

Close the two non-blocking integration gaps deferred from the v1.7 audit. Both fixes are targeted, low-risk edits to existing files with no new dependencies or public API changes.

## v1.8 Requirements

### Integration Fixes

- [x] **INT-01**: Doctor detects missing `oban_powertools_job_records` table — add to `@powertools_manifest` under `"output-recording"` group in `lib/oban_powertools/doctor/checks.ex`; update test description to "5 groups present"
- [ ] **INT-02**: Cron-scheduled `deadline:`-configured workers inject `__deadline_at__` meta at enqueue — thread `now` through all 4 `maybe_insert_job` clause heads in `lib/oban_powertools/cron.ex`; inject `Deadlines.build_meta` inside existing `function_exported?` branch; verify `redact:` + `deadline:` compose (both meta keys present on cron path)

## Future Requirements (deferred)

Carried backlog (not in v1.8): QRY-05 args/meta filter, QRY-06 real-time counts, QRY-07 Lifeline→job deep-link, QRY-08 cross-page select-all, API-03 programmatic job query.

v1.9: Batches & Composition — dedicated `batches` / `batch_jobs` tables, `completed` + `exhausted` callbacks, chains as linear-DAG sugar, native Batches page.

## Out of Scope

- No new features in this milestone.
- No new migrations or tables.
- No new runtime dependencies.
- No changes to the public API surface.

## Traceability

| REQ-ID | Phase | Plan |
|--------|-------|------|
| INT-01 | Phase 57 | TBD  |
| INT-02 | Phase 58 | TBD  |
