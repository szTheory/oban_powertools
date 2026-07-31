---
phase: 80
slug: page-migration-wave-2-jobs-forensics
status: verified
threats_open: 0
asvs_level: 1
created: 2026-07-29
---

# Phase 80 — Security

> Retrospective ASVS L1 verification of all plan-authored threat mitigations.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|---|---|---|
| Browser URL/form → Jobs/Forensics parsers | Untrusted selectors, filters, JSON, page and job identifiers become finite canonical state | Operator-controlled URL and form values |
| Parsed scope → Repo/authorization | Only bounded, typed, authorized identities may reach Ecto reads or Lifeline mutation | Job IDs, filters, forensic source identity |
| Repo/source records → presenters/DOM | Raw payloads, failures, reasons, tokens and source maps are projected through closed presentation schemas | Operational and potentially confidential data |
| Jobs UI → batch coordinator/Lifeline | Frozen bounded membership and server-owned capabilities govern supervised work | Job IDs, preview capabilities, outcomes |
| Showcase/fixture/browser harness → host | Test-only authenticated routes and deterministic catalogs produce isolated evidence | Fixture commands, credentials, ARIA and PNG artifacts |
| Generated evidence → repository | Exact manifest-derived sets and compare-only checks protect evidence integrity | 147 ARIA snapshots, 588 PNG baselines |

---

## Verification Evidence

Evidence labels below resolve every threat row to concrete implementation or executable-test locations. The fresh focused audit command covering the principal Elixir evidence completed with **156 tests, 0 failures** on 2026-07-29.

| Ref | Concrete evidence |
|---|---|
| E01 | Bounded, parameterized Jobs queries: `lib/oban_powertools/jobs.ex:87`, `lib/oban_powertools/jobs.ex:99`, `lib/oban_powertools/jobs.ex:139`; predicate/group/window tests: `test/oban_powertools/jobs_test.exs:107`, `test/oban_powertools/jobs_test.exs:208`, `test/oban_powertools/jobs_test.exs:339`; canonical/draft rejection: `test/oban_powertools/web/jobs_params_test.exs:82`, `test/oban_powertools/web/jobs_params_test.exs:195`. |
| E02 | Browse/review authorization, closed state, bounded rendering and semantic controls: `test/oban_powertools/web/live/jobs_live_test.exs:169`, `test/oban_powertools/web/live/jobs_live_test.exs:215`, `test/oban_powertools/web/live/jobs_live_test.exs:352`, `test/oban_powertools/web/live/jobs_live_test.exs:385`. |
| E03 | Full-detail/action authorization, allowlisted return context, redaction, single-use recovery and finite receipts: `test/oban_powertools/web/live/jobs_live_test.exs:498`, `test/oban_powertools/web/live/jobs_live_test.exs:647`, `test/oban_powertools/web/live/jobs_live_test.exs:1061`, `test/oban_powertools/web/live/jobs_live_test.exs:1122`, `test/oban_powertools/web/live/jobs_live_test.exs:1230`, `test/oban_powertools/web/live/jobs_live_test.exs:1298`, `test/oban_powertools/web/live/jobs_live_test.exs:1425`. |
| E04 | Frozen membership, per-target authorization, max-four execution, timeout/crash isolation, Audit evidence and bounded results: `test/oban_powertools/jobs/batch_coordinator_test.exs:11`, `test/oban_powertools/jobs/batch_coordinator_test.exs:70`, `test/oban_powertools/jobs/batch_coordinator_test.exs:179`, `test/oban_powertools/jobs/batch_coordinator_test.exs:276`, `test/oban_powertools/jobs/batch_coordinator_test.exs:406`, `test/oban_powertools/jobs/batch_coordinator_test.exs:471`, `test/oban_powertools/jobs/batch_coordinator_test.exs:515`; fail-fast configuration: `test/oban_powertools/application_test.exs:67`. |
| E05 | Typed scope rejection, zero-read invalid handling, bounded Audit window and relational source authority: `lib/oban_powertools/audit.ex:15`, `lib/oban_powertools/audit.ex:183`, `lib/oban_powertools/forensics.ex:25`, `lib/oban_powertools/forensics.ex:26`, `test/oban_powertools/forensics_test.exs:144`, `test/oban_powertools/forensics_test.exs:202`, `test/oban_powertools/forensics_test.exs:234`, `test/oban_powertools/forensics_test.exs:288`. |
| E06 | Closed evidence projection, bounded chronology and independent truth dimensions: `test/oban_powertools/forensics/evidence_bundle_test.exs:34`, `test/oban_powertools/forensics/evidence_bundle_test.exs:68`, `test/oban_powertools/forensics_test.exs:424`, `test/oban_powertools/forensics_test.exs:570`, `test/oban_powertools/forensics_test.exs:656`, `test/oban_powertools/forensics_test.exs:845`. |
| E07 | Live scope reauthorization, parse-before-read, uniform unavailable state, closed pure composition and one bounded Timeline: `test/oban_powertools/web/live/forensics_live_test.exs:60`, `test/oban_powertools/web/live/forensics_live_test.exs:177`, `test/oban_powertools/web/live/forensics_live_test.exs:199`, `test/oban_powertools/web/live/forensics_live_test.exs:227`, `test/oban_powertools/web/live/forensics_live_test.exs:330`, `test/oban_powertools/web/live/forensics_live_test.exs:427`. |
| E08 | Exact production-composed story registry, bounded adversarial fixtures and confidentiality scan: `test/oban_powertools/page_story_catalog_test.exs:139`, `test/oban_powertools/page_story_catalog_test.exs:217`, `test/oban_powertools/page_story_catalog_test.exs:254`, `test/oban_powertools/page_story_catalog_test.exs:271`, `test/oban_powertools/web/live/showcase_live_test.exs:692`, `test/oban_powertools/web/live/showcase_live_test.exs:883`. |
| E09 | Exact schema-8 catalog derivation and independent manifest validation: `scripts/showcase_manifest.exs:176`, `scripts/showcase_manifest.exs:185`, `test/browser/support/manifest.ts:295`, `test/browser/support/manifest.ts:323`, `test/oban_powertools/showcase_catalog_test.exs:177`. |
| E10 | Test-only constant-time fixture authorization, closed targets, cleanup and indistinguishable 404s: `examples/phoenix_host/test/support/phase80_browser_fixtures.ex:39`, `examples/phoenix_host/test/support/phase80_browser_fixtures.ex:193`, `examples/phoenix_host/test/support/phase80_browser_fixtures.ex:863`, `examples/phoenix_host/test/support/phase80_browser_fixtures.ex:869`, `examples/phoenix_host/test/support/phase80_browser_fixtures.ex:872`, `test/browser/specs/phase80-fixtures.spec.ts:10`, `test/browser/specs/phase80-fixtures.spec.ts:157`. |
| E11 | Connected production URL/effect, cross-channel confidentiality, frozen-scope, focus/reflow/target and serial execution checks: `test/browser/specs/page-migration-wave-2.spec.ts:18`, `test/browser/specs/page-migration-wave-2.spec.ts:191`, `test/browser/specs/page-migration-wave-2.spec.ts:287`, `test/browser/specs/page-migration-wave-2.spec.ts:378`, `test/browser/specs/page-migration-wave-2.spec.ts:738`, `test/browser/specs/page-migration-wave-2.spec.ts:925`. |
| E12 | Root-scoped theme/layout checks and exact artifact validators: `test/oban_powertools/web/theme_tokens_test.exs:342`, `test/oban_powertools/web/theme_tokens_test.exs:648`, `test/oban_powertools/web/theme_tokens_test.exs:708`, `test/browser/support/verify-page-aria-snapshots.mjs:77`, `test/browser/support/verify-page-baselines.mjs:150`. |
| E13 | Exact seven-story production-composed VoiceOver contract and fail-closed required transcript text: `test/browser/voiceover/page.voiceover.spec.ts:20`, `test/browser/voiceover/page.voiceover.spec.ts:27`, `test/browser/voiceover/page.voiceover.spec.ts:49`, `test/browser/voiceover/page.voiceover.spec.ts:75`, `test/browser/voiceover/page.voiceover.spec.ts:142`; fresh compare-only and inventory evidence: `80-VALIDATION.md:29`, `80-VALIDATION.md:30`, `80-VALIDATION.md:31`. |
| E14 | Three-predicate workflow-step authority and identical mismatch presentation: `test/oban_powertools/forensics_test.exs:288`, `test/oban_powertools/web/live/forensics_live_test.exs:227`, with authoritative lookup before Audit in `lib/oban_powertools/forensics.ex:94` and `lib/oban_powertools/forensics.ex:106`. |
| E15 | Bounded URL integers, exact positional reconciliation and fail-closed malformed results: `test/oban_powertools/web/jobs_params_test.exs:102`, `test/oban_powertools/web/jobs_params_test.exs:150`, `test/oban_powertools/jobs/batch_coordinator_test.exs:335`, `test/oban_powertools/jobs/batch_coordinator_test.exs:390`, `test/oban_powertools/web/live/jobs_live_test.exs:1922`; closed result schema: `lib/oban_powertools/jobs/batch_coordinator.ex:895`. |
| E16 | Corrected exact-five-space extractor calibration, byte-equal identity attribution, unchanged owner hashes, exact artifacts and compare-only closure: `80-VALIDATION.md:342`, `80-VALIDATION.md:349`, `80-VALIDATION.md:376`, `80-VALIDATION.md:423`, `80-VALIDATION.md:424`, `80-VALIDATION.md:425`, `80-VALIDATION.md:427`, `80-VALIDATION.md:444`. These are the executable/report artifacts implemented by Plan 80-16; the earlier failed attempt remains preserved as fail-closed history. |
| E17 | Signed-int64 parser and zero-query overflow boundary: `test/oban_powertools/web/jobs_params_test.exs:103`, `test/oban_powertools/web/jobs_params_test.exs:150`, `test/oban_powertools/web/live/jobs_live_test.exs:521`, `test/oban_powertools/web/live/jobs_live_test.exs:543`, `test/oban_powertools/web/live/jobs_live_test.exs:563`, `test/oban_powertools/web/live/jobs_live_test.exs:598`, `test/oban_powertools/web/live/jobs_live_test.exs:622`. |

---

## Threat Register

| Threat ID | Category | Severity | Disposition | Mitigation verification | Status |
|---|---|---|---|---|---|
| T-80-01-INJECT | Injection | high | mitigate | JSON validation, parameterized predicates, closed URL order and delimiter rejection — E01 | closed |
| T-80-01-TAMPER | Tampering | high | mitigate | Draft/applied separation and pre-query canonicalization — E01 | closed |
| T-80-01-DOS | Denial of service | high | mitigate | Fixed page, grouped count and limit-plus-one bounds — E01 | closed |
| T-80-01-FALSEGREEN | Repudiation | high | mitigate | Complete focused query/parser suites — E01 | closed |
| T-80-02-IDOR | Elevation of privilege | high | mitigate | Server authorization and uniform unavailable review — E02 | closed |
| T-80-02-LEAK | Information disclosure | high | mitigate | Closed row/review projections and sentinel coverage — E02 | closed |
| T-80-02-DOS | Denial of service | high | mitigate | Bounded browse queries and finite maps — E02 | closed |
| T-80-02-TAMPER | Tampering | high | mitigate | Canonical applied URL; change does not query or patch — E02 | closed |
| T-80-02-A11Y | Spoofing | high | mitigate | Named semantic controls/table and programmatic state — E02 | closed |
| T-80-02-FALSEGREEN | Repudiation | high | mitigate | Complete JobsLive focused suite — E02 | closed |
| T-80-03-IDOR | Elevation of privilege | high | mitigate | Uniform unavailable state and execute-time authorization — E03 | closed |
| T-80-03-LEAK | Information disclosure | high | mitigate | Structural allowlists and redacted bounded detail — E03 | closed |
| T-80-03-REPLAY | Tampering | high | mitigate | Single-use Lifeline preview recovery states — E03 | closed |
| T-80-03-NAV | Spoofing | high | mitigate | Allowlisted detail return reconstruction — E03 | closed |
| T-80-03-TRUTH | Repudiation | high | mitigate | Finite receipts and durable Audit linkage — E03 | closed |
| T-80-03-INJECT | Injection | high | mitigate | Escaped closed rendering and safe field projection — E03 | closed |
| T-80-04-SCOPE | Tampering | high | mitigate | Frozen bounded unique membership — E04 | closed |
| T-80-04-AUTH | Elevation of privilege | high | mitigate | Page/action/target authorization plus Lifeline reauthorization — E04 | closed |
| T-80-04-LEAK | Information disclosure | high | mitigate | Closed preview/result/message data — E04 | closed |
| T-80-04-DOS | Denial of service | high | mitigate | Configured scope, concurrency, timeout and result-page bounds — E04 | closed |
| T-80-04-CRASH | Denial of service | high | mitigate | Supervised nonlinked crash/timeout isolation — E04 | closed |
| T-80-04-REPLAY | Repudiation | high | mitigate | Single-use previews, stable results and per-target Audit — E04 | closed |
| T-80-04-CONFIG | Security misconfiguration | high | mitigate | Invalid bulk limit fails startup — E04 | closed |
| T-80-05-CONFUSION | Tampering | high | mitigate | Sum-type parser rejects mixed/orphan scopes before reads — E05 | closed |
| T-80-05-IDOR | Elevation of privilege | high | mitigate | Scoped predicates and uniform unavailable result — E05 | closed |
| T-80-05-DOS | Denial of service | high | mitigate | 50/51 Audit and eight-history bounds — E05 | closed |
| T-80-05-TRUTH | Repudiation | high | mitigate | Exact workflow totals and incident has-more truth — E05 | closed |
| T-80-05-PERF | Security misconfiguration | high | mitigate | Host-sensitive incident predicate is explicitly bounded and not overclaimed — E05 | closed |
| T-80-06-CONFUSION | Tampering | high | mitigate | Typed Scope alone selects a source; invalid input reads zero — E05, E06 | closed |
| T-80-06-IDOR | Elevation of privilege | high | mitigate | Scoped source predicates and uniform unavailable result — E05, E06 | closed |
| T-80-06-LEAK | Information disclosure | high | mitigate | Closed nested projection and sentinel tests — E06 | closed |
| T-80-06-DOS | Denial of service | high | mitigate | Bounded source histories and display maps — E05, E06 | closed |
| T-80-06-TRUTH | Repudiation | high | mitigate | Independent status, provenance, completeness and history — E06 | closed |
| T-80-07-IDOR | Elevation of privilege | high | mitigate | Scope reauthorization and identical unavailable output — E07 | closed |
| T-80-07-TAMPER | Tampering | high | mitigate | Parse before read; invalid replace; change reads zero — E07 | closed |
| T-80-07-LEAK | Information disclosure | high | mitigate | Closed presenter-only assigns and DOM sentinels — E06, E07 | closed |
| T-80-07-TRUTH | Repudiation | high | mitigate | Current/history/provenance/completeness remain distinct — E06, E07 | closed |
| T-80-07-DOS | Denial of service | high | mitigate | One bounded semantic Timeline — E07 | closed |
| T-80-07-A11Y | Spoofing | high | mitigate | Native form/list/time/disclosure and durable error semantics — E07 | closed |
| T-80-08-FORK | Tampering | high | mitigate | Showcase directly exercises production page composition — E08 | closed |
| T-80-08-LEAK | Information disclosure | high | mitigate | Normalized fixtures and serialized sentinel scan — E08 | closed |
| T-80-08-SCOPE | Tampering | high | mitigate | Exact ordered 49-story registry — E08 | closed |
| T-80-08-A11Y | Elevation of privilege | high | mitigate | Acceptance metadata and one-tree/overlay bounds — E08 | closed |
| T-80-09-PREFIX | Tampering | high | mitigate | Deterministic schema-8 generation and exact prefix contract — E09 | closed |
| T-80-09-SCOPE | Tampering | high | mitigate | Exact manifest-derived story/target evidence sets — E09 | closed |
| T-80-09-FORK | Tampering | high | mitigate | Browser discovery derives from generated registry — E09 | closed |
| T-80-09-THEME | Spoofing | high | mitigate | Four exact themes validated independently — E09, E12 | closed |
| T-80-09-A11Y | Elevation of privilege | high | mitigate | Exact acceptance/ARIA/tree contracts — E09, E12 | closed |
| T-80-10-AUTH | Elevation of privilege | high | mitigate | Test-only constant-time secret gate and empty denial — E10 | closed |
| T-80-10-DATA | Tampering | high | mitigate | Closed targets and exact isolated cleanup — E10 | closed |
| T-80-10-LEAK | Information disclosure | high | mitigate | Name-only secret use and closed empty responses — E10 | closed |
| T-80-10-INJECT | Injection | high | mitigate | Closed command/target schemas and exact routes — E10 | closed |
| T-80-10-ZERO | Repudiation | high | mitigate | Real serial route-on/off fixture tests — E10 | closed |
| T-80-10-DOS | Denial of service | high | mitigate | Bounded disposable fixture lifecycle — E10 | closed |
| T-80-10-REGRESS | Repudiation | high | mitigate | Wave 1 and 2 share the validated fixture lifecycle — E10, E11 | closed |
| T-80-11-FALSE | Repudiation | high | mitigate | Connected specs use production URLs and real effects — E11 | closed |
| T-80-11-AUTH | Elevation of privilege | high | mitigate | Missing/unauthorized equality and server-owned frozen scope — E11 | closed |
| T-80-11-LEAK | Information disclosure | high | mitigate | Cross-channel sentinel scan — E11 | closed |
| T-80-11-A11Y | Elevation of privilege | high | mitigate | Keyboard, focus, reflow, zoom and target behavior — E11 | closed |
| T-80-11-MANIFEST | Tampering | high | mitigate | Exact ordered Wave 1 compatibility against expanded manifest — E09, E11 | closed |
| T-80-11-PORT | Denial of service | high | mitigate | Serial shared launcher/lifecycle — E10, E11 | closed |
| T-80-12-OMIT | Tampering | high | mitigate | Exact tracked 147 ARIA set — E12 | closed |
| T-80-12-SCOPE | Tampering | high | mitigate | Manifest-derived 147/588 validators reject scope drift — E12 | closed |
| T-80-12-LEAK | Information disclosure | high | mitigate | Closed story inputs and connected confidentiality scans — E08, E11 | closed |
| T-80-12-THEME | Spoofing | high | mitigate | Four-theme source and evidence checks — E09, E12 | closed |
| T-80-12-HOST | Security misconfiguration | high | mitigate | Root-scoped token/asset ownership — E12 | closed |
| T-80-12-A11Y | Elevation of privilege | high | mitigate | Exact ARIA, axe-oriented semantics, focus/target/reflow checks — E11, E12 | closed |
| T-80-13-FALSEGREEN | Spoofing | high | mitigate | Fresh exact inventories, focused tests and compare-only result — E13 | closed |
| T-80-13-SCOPE | Tampering | high | mitigate | Exact source/evidence scope accounting — E13 | closed |
| T-80-13-LEAK | Information disclosure | high | mitigate | Cross-channel and package/fixture confidentiality reconciliation — E10, E11, E13 | closed |
| T-80-13-A11Y | Elevation of privilege | high | mitigate | Connected semantics, exact ARIA and executable VoiceOver stories — E11, E12, E13 | closed |
| T-80-13-VRT | Repudiation | high | mitigate | Exact 588 tracked set and fresh compare-only pass — E12, E13 | closed |
| T-80-13-GAP | Tampering | high | mitigate | Complete source/requirement/decision audit retained — E13 | closed |
| T-80-14-CR01 | Elevation of privilege | critical | mitigate | Resource/workflow/name predicates bind Step authority before Audit — E14 | closed |
| T-80-14-CONF | Information disclosure | critical | mitigate | Relational mismatches stop before Audit and render unavailable — E14 | closed |
| T-80-14-SPOOF | Spoofing | high | mitigate | Audit identity derives from authoritative Step record — E14 | closed |
| T-80-14-ENUM | Information disclosure | high | mitigate | Missing/unauthorized/mismatched scopes share output and destinations — E14 | closed |
| T-80-14-BOUND | Denial of service | high | mitigate | Exact Step lookup plus bounded Audit window — E14 | closed |
| T-80-15-WR01 | Denial of service | high | mitigate | Bounded page/job parsers reject unsafe bindings — E15 | closed |
| T-80-15-WR02 | Tampering | high | mitigate | Originating target positions are unique and revalidated — E15 | closed |
| T-80-15-RECOVERY | Repudiation | high | mitigate | Malformed result sets fail closed with interruption truth — E15 | closed |
| T-80-15-CONF | Information disclosure | high | mitigate | Closed result schema excludes raw exits/IDs/tokens/errors — E15 | closed |
| T-80-15-REPLAY | Elevation of privilege | high | mitigate | Reconciliation failure cannot reuse execution capabilities — E04, E15 | closed |
| T-80-15-FLAKE | Security misconfiguration | high | mitigate | Bounded integration timeout and repeatability evidence — E15, E16 | closed |
| T-80-16-INVENTORY | Tampering | high | mitigate | Single corrected completion path and exact inventory — E16 | closed |
| T-80-16-STALE | Repudiation | high | mitigate | Fresh calibrated identities replace stale fixed attribution — E16 | closed |
| T-80-16-COUNT | Spoofing | high | mitigate | Byte-equal module/title/path/line identities; counts alone rejected — E16 | closed |
| T-80-16-MISSING | Spoofing | high | mitigate | Attribution files and zero-byte semantics are explicit — E16 | closed |
| T-80-16-NESTED | Spoofing | high | mitigate | Exact-five-space eligibility and nested/duplicate fixtures — E16 | closed |
| T-80-16-SCOPE | Tampering | high | mitigate | Owner hashes and dirty-file audit preserve out-of-scope files — E16 | closed |
| T-80-16-BOOKKEEP | Tampering | high | mitigate | Ledger snapshots and Summary gating preserve fail-closed state — E16 | closed |
| T-80-16-A11Y | Repudiation | high | mitigate | Seven-case discovery plus exact ARIA/page gates; transcript limitation disclosed — E13, E16 | closed |
| T-80-16-VRT | Tampering | high | mitigate | Exact 147/588 inventories and compare-only aggregate — E12, E16 | closed |
| T-80-16-DISCLOSE | Information disclosure | high | mitigate | Finite identities/hashes only in closure reports — E16 | closed |
| T-80-17-DOS | Denial of service | high | mitigate | Above-int64 IDs rejected before authorization/Repo — E17 | closed |
| T-80-17-AUTH | Tampering | high | mitigate | Authorization receives only canonical decimal or nil sentinel — E17 | closed |
| T-80-17-ENUM | Information disclosure | high | mitigate | Overflow, malformed and missing IDs share finite unavailable output — E17 | closed |
| T-80-17-DRIFT | Repudiation | medium | mitigate | Maximum and maximum-plus-one tests bind PostgreSQL bigint range — E17 | closed |
| T-80-17-SCOPE | Tampering | medium | mitigate | Focused parser/LiveView boundary adds no route or persistence expansion — E17 | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Unregistered Flags

None. No Phase 80 Summary contains a `## Threat Flags` section.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---:|---:|---:|---|
| 2026-07-29 | 99 | 99 | 0 | Codex gsd-security-auditor |

---

## Sign-Off

- [x] All 99 threats have a disposition.
- [x] Every declared mitigation has concrete implementation or executable-test evidence.
- [x] Accepted risks documented: none.
- [x] `threats_open: 0` confirmed at `block_on: high`.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-07-29
