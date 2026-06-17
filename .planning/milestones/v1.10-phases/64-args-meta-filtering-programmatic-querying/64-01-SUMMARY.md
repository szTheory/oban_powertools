---
phase: 64-args-meta-filtering-programmatic-querying
plan: 01
---

## Wave 1 Complete

**01: Add args and meta filtering to Jobs domain**
Added `args` and `meta` to `%ObanPowertools.Jobs{}` struct and updated `list/3` and `count_by_state/2` to pipe through JSONB containment filters (`@>`) using Ecto fragments. Provided comprehensive test coverage for JSONB containment logic.

**02: Expose Operator.list programmatic API**
Exposed `Operator.list/3` taking map, keyword, or `%Jobs{}` struct, delegating directly to `Jobs.list/3` with seamless support for the new `args` and `meta` filters.

### Key Files Created/Modified
- `lib/oban_powertools/jobs.ex`
- `lib/oban_powertools/operator.ex`
- `test/oban_powertools/jobs_test.exs`
- `test/oban_powertools/operator_test.exs`

### Noteworthy Decisions
- `args` and `meta` filters are mapped to literal JSONB containment macros `@>`. The caller is responsible for formatting their input map appropriately for strict containment logic.
- Documented in module doc that host applications should create `GIN` indexes on `oban_jobs.args` and `oban_jobs.meta` for high performance querying, as the powertools library leaves indexing up to the host application boundaries.