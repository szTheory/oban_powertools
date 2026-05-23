---
phase: 15
slug: upgrade-lane-support-truth-public-docs-integrity
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-23
---

# Phase 15 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Archived upgrade source fixture -> upgrade proof harness | If the frozen source fixture drifts forward or accumulates undocumented changes, the supported upgrade claim becomes synthetic again. | Historical host shape, route ownership, and config contract details |
| Maintainer regeneration path -> public support promise | If provenance or replay boundaries are ambiguous, maintainers cannot later prove which upgrade source lane is actually supported. | Source commit identity, regeneration workflow, and support posture |
| Archived fixture -> upgrade harness | Hidden rewrites in the harness would cause the public upgrade guide and executable lane to diverge. | Upgrade actions, fixture contents, and proof setup |
| Public upgrade guide -> CI lane | If docs overstate or misdescribe the lane, integrators may trust an upgrade path the repo does not actually prove. | Support claims, prerequisites, and proof thresholds |
| Public docs -> host integrator assumptions | Blurry ownership language can push auth, routing, or policy responsibilities onto the wrong side of the contract. | Support-truth language, ownership boundaries, and production guidance |
| Narrative guides -> docs contract test | If tests snapshot prose instead of stable claims, maintainers either avoid improving docs or accidentally encode false guarantees. | Stable markers, lane names, and exact fail-fast runtime errors |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-15-01 | T | `examples/phoenix_host_upgrade_source/*` | mitigate | Freeze a dedicated pre-`display_policy` fixture with native `/ops/jobs`, required migrations, and explicit singular-lane documentation. Evidence: [config/config.exs](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/config/config.exs:19), [router.ex](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/lib/phoenix_host_web/router.ex:25), [README.md](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/README.md:16) | closed |
| T-15-02 | R | `examples/phoenix_host_upgrade_source/README.md` | mitigate | Record the exact source commit SHA and best-effort exclusions so provenance remains auditable. Evidence: [README.md](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/README.md:8), [README.md](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/README.md:29) | closed |
| T-15-03 | I | support-truth in archived fixture docs | mitigate | Mark regeneration as maintainer-only and explicitly outside CI so the repo does not imply broader replay support. Evidence: [README.md](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/README.md:35), [README.md](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/README.md:41), [regenerate.sh](/Users/jon/projects/oban_powertools/examples/phoenix_host_upgrade_source/regenerate.sh:34) | closed |
| T-15-04 | T | `test/support/example_host_contract.ex` | mitigate | Restrict upgrade prep to archived-fixture copy plus documented `display_policy` restoration; remove synthetic source mutation. Evidence: [example_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/example_host_contract.ex:4), [example_host_contract.ex](/Users/jon/projects/oban_powertools/test/support/example_host_contract.ex:149) | closed |
| T-15-05 | R | `guides/upgrade-and-compatibility.md` | mitigate | Define one host-shape-based upgrade lane with explicit prerequisites and best-effort exclusions, not internal phase chronology. Evidence: [upgrade-and-compatibility.md](/Users/jon/projects/oban_powertools/guides/upgrade-and-compatibility.md:7), [upgrade-and-compatibility.md](/Users/jon/projects/oban_powertools/guides/upgrade-and-compatibility.md:68) | closed |
| T-15-06 | E | native-vs-bridge support boundary | mitigate | Require native `ops-demo` -> `pause_cron_entry` proof and keep bridge-write implications out of the upgrade claim. Evidence: [upgrade-and-compatibility.md](/Users/jon/projects/oban_powertools/guides/upgrade-and-compatibility.md:47), [example_host_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/example_host_contract_test.exs:38), [upgrade-and-compatibility.md](/Users/jon/projects/oban_powertools/guides/upgrade-and-compatibility.md:85) | closed |
| T-15-07 | S | README and support-truth docs | mitigate | Repeat the five support-truth buckets and host-owned seams so host and library responsibilities cannot masquerade as each other. Evidence: [README.md](/Users/jon/projects/oban_powertools/README.md:74), [support-truth-and-ownership-boundaries.md](/Users/jon/projects/oban_powertools/guides/support-truth-and-ownership-boundaries.md:3) | closed |
| T-15-08 | E | optional bridge posture | mitigate | State that `/ops/jobs/oban` is read-only and narrower than the native surface, excluding bridge mutation parity from supported claims. Evidence: [README.md](/Users/jon/projects/oban_powertools/README.md:78), [support-truth-and-ownership-boundaries.md](/Users/jon/projects/oban_powertools/guides/support-truth-and-ownership-boundaries.md:11), [support-truth-and-ownership-boundaries.md](/Users/jon/projects/oban_powertools/guides/support-truth-and-ownership-boundaries.md:46) | closed |
| T-15-09 | R | compatibility and upgrade promise | mitigate | Assert `best-effort outside tested lanes` in docs and lock the marker in docs-contract coverage. Evidence: [README.md](/Users/jon/projects/oban_powertools/README.md:86), [docs_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/docs_contract_test.exs:42) | closed |
| T-15-10 | T | docs contract scope | mitigate | Keep docs-contract assertions limited to commands, paths, lane names, bucket labels, and exact runtime error strings. Evidence: [docs_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/docs_contract_test.exs:17), [docs_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/docs_contract_test.exs:57) | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-23 | 10 | 10 | 0 | `gsd-secure-phase` + `gsd-security-auditor` |

### Verification Notes

- No `## Threat Flags` section was present in the phase summary files, so there were no unregistered flags to carry forward.
- Local verification also passed for `mix test test/oban_powertools/docs_contract_test.exs` and `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof`.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-23
