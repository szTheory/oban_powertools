---
phase: 48
slug: doctor-health-check-task
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-29
---

# Phase 48 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Register authored at plan time (48-01, 48-02). Mitigations independently
> verified against the implementation by gsd-security-auditor on 2026-05-29.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CLI flags → SQL | `--prefix` (and prefix from app env) flows into pg_catalog / information_schema queries | schema/prefix identifier (low sensitivity) |
| CLI flags → atoms/modules | `--repo`, `--oban-name`, `--format` become modules/atoms | untrusted string → atom |
| DB → process | Catalog query results read into the BEAM and rendered | schema/index/version metadata |
| process → stdout | Findings rendered to human/JSON output | metadata + remediation strings |
| Mix task → runtime | Boot path must start only the repo, never Oban | n/a (control-flow boundary) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-48-01 | Tampering | prefix value in `Checks.*` SQL | mitigate | All prefix/schema values bound as `$1`, table arrays as `$2` via `repo.query/3`; eligible-count identifier gated by `valid_identifier?` regex; no `#{}` interpolation of CLI/env input | closed |
| T-48-02 | Information Disclosure | catalog queries reading wrong schema | mitigate | Every pg_catalog query filters `n.nspname = $1`; Powertools tables pinned to `table_schema = 'public'` | closed |
| T-48-03 | Repudiation/Integrity | cannot-run silently passing a gate | mitigate | Every `{:error, reason}` from `repo.query/3` → `:error`-severity Finding; never returns `[]` on failure | closed |
| T-48-04 | Elevation/Side-effect | accidental Oban start or write path | mitigate | No `@requirements`, no `Oban.start_link`, no INSERT/UPDATE/DELETE; all checks SELECT-only | closed |
| T-48-05 | Tampering/DoS | `--repo`/`--oban-name` → atom creation | mitigate | `Module.safe_concat` + `String.to_existing_atom` (rescue ArgumentError); `--format` explicit case map; no `String.to_atom/1` on CLI input | closed |
| T-48-06 | Elevation/Side-effect | repo-only boot must not start Oban | mitigate | `Ecto.Migrator.with_repo/2` sole boot; no `@requirements ["app.start"]`, no `Oban.start_link` | closed |
| T-48-07 | Repudiation/Integrity | exit code must be honest | mitigate | `System.halt/1` with `exit_code_for/1`; no-repo/db-unreachable halts 2, never 0; no `raise`/`exit` for exit code | closed |
| T-48-08 | Information Disclosure | JSON/human output content | accept | Output is schema/index/version metadata + authored remediation only; no PII, no job args/meta read or rendered (see Accepted Risks) | closed |
| T-48-SC | Tampering | supply chain (npm/pip/cargo installs) | mitigate | No package installs; Jason/oban/ecto_sql/postgrex pre-declared; no `mix.exs`/`mix.lock` changes in phase 48 | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Verification Evidence

- **T-48-01** — `checks.ex:81,86,118,123,218,221,343,348` bind prefix as `$1`; eligible-count query at `checks.ex:388` gated by `valid_identifier?` regex `~r/^[a-z_][a-z0-9_]*$/` (`checks.ex:446`); negative grep for `nspname = '#{` finds nothing.
- **T-48-02** — `checks.ex:81,118,218,343` filter `n.nspname = $1`; `checks.ex:250` hardcodes `table_schema = 'public'`.
- **T-48-03** — `checks.ex:90,138,278,368,415` each map `{:error, reason}` → `:error` Finding; nil db_version consumed by `oban_migration_version` `is_nil` guard at `checks.ex:164` → error Finding.
- **T-48-04** — grep for `@requirements`/`Oban.start_link`/`INSERT`/`UPDATE`/`DELETE` in `doctor.ex` + `checks.ex` returns nothing; all queries SELECT-only.
- **T-48-05** — `doctor.ex:143` `Module.safe_concat`; `--oban-name` via `String.to_existing_atom` in `try/rescue ArgumentError` (`doctor.ex:164-168`); `--format` explicit case map (`doctor.ex:94-97`).
- **T-48-06** — `doctor.ex:80` sole boot is `Ecto.Migrator.with_repo/2`; `Mix.Task.run("app.config")` (`doctor.ex:73`) loads config without starting apps.
- **T-48-07** — `doctor.ex:115,124` both `System.halt` calls in `case` arms after `with_repo` returns (`doctor.ex:111`); error path halts 2.
- **T-48-08** — no query selects `args`/`meta`; count query at `checks.ex:395` selects only `count(*)`; formatter renders Finding fields only.
- **T-48-SC** — `mix.exs:50-53` deps pre-existed; `git log ce280ab..HEAD -- mix.exs mix.lock` is empty.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-48-01 | T-48-08 | Doctor output contains only schema/index/version metadata, aggregate counts, and operator-authored remediation strings. Verified in code: no SQL query selects `args`/`meta`; the sole `oban_jobs` data query (`checks.ex:395`) selects only `count(*)`; formatter renders only `Finding` struct fields. No PII or job content is read or rendered. Residual risk: low. | gsd-security-auditor (verified) | 2026-05-29 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-29 | 9 | 9 | 0 | gsd-security-auditor (sonnet) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-29
