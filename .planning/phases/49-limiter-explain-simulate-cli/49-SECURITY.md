---
phase: 49
slug: limiter-explain-simulate-cli
status: verified
threats_open: 0
asvs_level: 2
created: 2026-05-29
---

# Phase 49 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

**Register origin:** authored at plan time (`register_authored_at_plan_time: true`). Auditor verified mitigations exist — no retroactive-STRIDE scan required.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| reserve/3 → compute_reservation/4 | Internal refactor; pure decision extracted from side-effecting path | Bucket state, resource config (trusted, in-process) |
| simulate → compute_reservation/4 | Pure computation only; MUST NOT cross into side-effecting reserve path | Simulated bucket state (no persistence) |
| operator CLI → explain task | Untrusted flag input | `--repo`, `--worker` (module names), `--args` (JSON), `--format`, `--resource`, `--partition` |
| explain task → DB (via with_repo) | Read-only queries over Explain/Resource/State | Limiter state reads only; no writes |
| operator CLI → simulate task | Untrusted flag input | `--worker`, `--bucket-capacity`/`--bucket-span-ms`/`--weight`/`--count`, `--partition`, `--format`, `--repo` |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-49-01 | Tampering | `compute_reservation/4` side-effect leakage | mitigate | Function body (`limits.ex:148–168`) has zero `repo.`/`Telemetry.`/`record_history_fact`; side-effects isolated in `blocked/4` & `do_reserve`. Telemetry-handler test `limits_test.exs:165–191` refutes `[:oban_powertools, :limiter, :blocked]` events | closed |
| T-49-02 | Tampering | Refactor changing `reserve/3` semantics | mitigate | Pre-existing regression suite `limits_test.exs:37–107` (saturation, partition isolation, weight snapshot, cooldown, release) passes; `attempt_reservation/5` delegates to `compute_reservation/4`, normalizes bucket once (`limits.ex:248`) | closed |
| T-49-03 | Tampering/DoS | `--repo`/`--worker` module flags (explain) | mitigate | `Module.safe_concat` (`explain.ex:370,386`); 0 `String.to_atom`; source test `explain_test.exs:33–36`; unknown worker guarded via `Code.ensure_loaded?` → exit 2 (`explain.ex:387–397`, test `:185–201`) | closed |
| T-49-04 | Tampering | `--args` JSON untrusted keys | mitigate | `Jason.decode` (not `decode!`) at `explain.ex:409`; keys stay strings (no `keys: :atoms`); bad JSON → exit 2 (`explain.ex:227–229`) | closed |
| T-49-05 | Tampering | `--format` flag (explain) | mitigate | Closed `case "json" -> :json; _ -> :human` (`explain.ex:120–123`); no atom creation from input | closed |
| T-49-06 | Spoofing/Info | explain reads but never mutates state | accept | Read-only by construction: only `repo.one/2` (`explain.ex:178–184`); no update/insert/delete. See Accepted Risks | closed |
| T-49-07 | Tampering | simulate mutates observable state | mitigate | Loop calls only `Limits.compute_reservation/4` (`simulate.ex:234–256`); 0 matches for reserve/upsert/get_or_create/blocked. Telemetry flunk test `simulate_test.exs:298–323`; DB count-before/after `:327–344` | closed |
| T-49-08 | Tampering/DoS | `--worker` flag (simulate) | mitigate | `Module.safe_concat` (`simulate.ex:401`); 0 code-level `String.to_atom`; source test `simulate_test.exs:35–38` | closed |
| T-49-09 | DoS | Partition landmine (`limit_snapshot/2` raises on empty args) | mitigate | Reads `__powertools_limits__/0` directly via `function_exported?` (`simulate.ex:341–369`); `limit_snapshot` never called; nil-safe scope (`simulate.ex:354`); tests `simulate_test.exs:100–104,201–227` | closed |
| T-49-10 | Tampering | `--format` flag (simulate) | mitigate | Closed `case "json" -> :json; _ -> :human` (`simulate.ex:132–135`); no atom creation | closed |
| T-49-SC | Tampering | npm/pip/cargo installs | accept | No new runtime deps; `mix.exs` unchanged; no `deps/` additions. See Accepted Risks | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-49-01 | T-49-06 | The `explain` Mix task is an operator-facing diagnostic invoked from a privileged shell with direct DB access. AuthN/Z is delegated to the DB credential / repo layer (transfer). Read-only by construction; no secrets exposed. | gsd-security-auditor | 2026-05-29 |
| AR-49-02 | T-49-SC | Zero new runtime deps (REL-01): no `deps/` additions, no `mix.exs` changes. Untracked `package.json`/`package-lock.json` in repo root are unrelated to the Hex library artifact. | gsd-security-auditor | 2026-05-29 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-29 | 11 | 11 | 0 | gsd-security-auditor (ASVS L2, sonnet) |

---

## Unregistered Flags

None. SUMMARY.md `## Threat Flags` / `## Threat Surface Scan` sections for all three plans report no new attack surface: no new network endpoints, auth paths, file access patterns, or schema changes introduced.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-29
