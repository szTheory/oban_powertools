---
phase: 80
slug: page-migration-wave-2-jobs-forensics
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-27
updated: 2026-07-28
---

# Phase 80 — Validation Evidence Ledger

This ledger reconciles every implementation task and high threat from Plans 80-01
through 80-13 against fresh closure evidence. All automatable product, connected,
accessibility, artifact, and compare-only gates are green. The two production
VoiceOver transcript rows remain explicitly open because this Mac lacks the
one-time Guidepup OS setup required to start VoiceOver.

## Closure Snapshot

| Gate | Fresh result | Classification |
|---|---:|---|
| `mix format --check-formatted` | pass | green |
| `mix compile --warnings-as-errors` | pass | green |
| Phase 80 focused non-docs/non-host suite | 901 tests, 0 failures, 7 excluded | green |
| Jobs/Forensics quick suite | 109 tests, 0 failures | green |
| Full `mix test --seed 0` | 927 tests, 5 failures | inherited residual |
| Page manifest | schema 8, 49 page stories, 113 targets, 4 themes, 3 viewports | green |
| Tracked page artifacts | 147 ARIA YAML, 588 PNG | green |
| Fresh `npm run verify:pages` | 1,392 tests, 0 failures in 25.8 minutes | green |
| Exact VoiceOver discovery | 7 exact production-composed stories | green |
| Seven production-composed VoiceOver transcripts | 7 stopped before navigation at Guidepup OS startup | supported-environment gap; transcripts open |

The five full-suite failures reproduce the same out-of-scope dirty-worktree
contract debt recorded by Plan 80-12: one CI documentation contract observes
the user-edited `page_quality` lane instead of `visual_a11y`, and four generated
example-host contract lanes expose existing copy, dependency, migration-timeout,
and native-only dependency drift. The same run executes 922 tests successfully.
Removing the two unrelated contract files yields the fresh 901/901 green
product lane above; no Phase 80 failure is hidden by that focused command.

## Fresh Per-Plan Verification

| Plan | Tasks reconciled | Fresh closure evidence | Status |
|---|---|---|---|
| 80-01 | 80-01-01 bounded predicate-consistent Jobs APIs; 80-01-02 canonical Jobs params/URLs | Jobs, params, selectors: 38 tests, 0 failures; exact seven-key Jobs URL allowlist; bounded page/count/ID-window source audit | green |
| 80-02 | 80-02-01 closed row/review presenters; 80-02-02 bounded browse/review composition | presenter + JobsLive: 79 tests, 0 failures; semantic table count is exactly one; raw review fields excluded before render | green |
| 80-03 | 80-03-01 closed detail/action maps; 80-03-02 deterministic detail/return context; 80-03-03 Lifeline single actions | presenter + JobsLive + Lifeline: 103 tests, 0 failures; no direct Oban mutation calls; no raw exception inspection | green |
| 80-04 | 80-04-01 validated limit/supervisor; 80-04-02 frozen supervised coordinator; 80-04-03 Jobs bulk lifecycle | coordinator + auth + application + JobsLive: 67 tests, 0 failures; telemetry contains only surface/action/scope/result/count and duration buckets | green |
| 80-05 | 80-05-01 typed Forensics scope/URLs; 80-05-02 bounded Audit windows/incident measurement | Audit + Forensics + selectors: 55 tests, 0 failures; Audit alone: 9 tests, 0 failures; exact six-key scope grammar; SQL `LIMIT 51` | green |
| 80-06 | 80-06-01 typed evidence assembly and closed presenter | Forensics + evidence bundle + presenter: 66 tests, 0 failures; typed source dispatch, bounded histories, closed presentation map | green |
| 80-07 | 80-07-01 submit/canonical scope lifecycle; 80-07-02 diagnosis-first page/Event log | Forensics + bundle + ForensicsLive: 46 tests, 0 failures; one timeline, at most 50 entries, uniform unavailable output | green |
| 80-08 | 80-08-01 exact production-composed story registry | catalog + showcase: 49 tests, 0 failures; 49 unique ordered page stories = 19 existing + 18 Jobs + 12 Forensics; 113 targets | green |
| 80-09 | 80-09-01 schema-8 discovery and exact evidence cardinalities | manifest generated twice with stable schema/cardinality; smoke accepts 49 stories/113 targets/4 themes/3 viewports; browser targets derive from the Elixir registry | green |
| 80-10 | 80-10-01 opt-in isolated host seam; 80-10-02 launcher and fail-closed clients | route-off branch: 2 real tests, 0 failures; production router unchanged; fixture routes exist only for `Mix.env() == :test` plus explicit env opt-in | green |
| 80-11 | 80-11-01 connected Jobs/Forensics and aggregate ordering | retained evidence: Wave 2 24/24 and combined Wave 1+2 69/69; exact package order remains Wave 1, Wave 2, axe, VRT | green |
| 80-12 | 80-12-01 deterministic token-owned styles; 80-12-02 freeze 57 Wave 1 ARIA; 80-12-03 generate/review Phase 80 evidence | asset/theme suite: 23 tests, 0 failures; source/static CSS and JS byte-equal; 147/147 ARIA and 588/588 PNG validators; retained compare-only 1,323/1,323 | green |
| 80-13 | 80-13-01 closure ledger; 80-13-02 exact seven-story VoiceOver harness and locked browser closure | exact list 7/7; manifest hash stable; 147/588 validators green; final aggregate 1,392/1,392; Guidepup OS startup limitation recorded without invented transcripts | green with supported-environment gap |

All 25 tasks in Plans 80-01 through 80-13 are represented above. Their plan
summaries, atomic task commits, declared file scopes, and fresh owning commands
agree; there is no missing task, accepted RED state, skipped test, or summary-only
completion claim.

## Requirements Trace

| Requirement | Evidence | Status |
|---|---|---|
| PAGE-02 | Bounded Jobs queries; canonical browse/detail; single and frozen bulk actions; 18 production-composed stories; connected and artifact evidence | green |
| PAGE-09 | Four-family typed Forensics scope; bounded evidence; diagnosis-first page; 12 production-composed stories; connected and artifact evidence | green |
| FORM-03 | Submit-only canonical filters/scopes, exact field errors, and shared Lifeline confirmation/focus contracts | green |
| DATA-* | SQL-bounded reads, exact/has-more truth, structural redaction, fixed presentation maps, no raw error/payload/token fallback | green |
| PAGE-10 | One pure production page seam per page, shared components, no copied story markup, deterministic page manifest | green |
| A11Y-* | One semantic tree, exact table/timeline bounds, focus/reflow/target/axe/ARIA/VRT evidence; exact seven-story VoiceOver contract | automated green; real transcripts explicitly open on unsupported Guidepup setup |

## Source and Boundary Audit

- **Query bounds:** Jobs uses a 20-row page, exact count, one grouped state count,
  and limit-plus-one ID windows. Forensics uses 50-row windows and an incident
  probe of 51. Migrated paths contain no `Jobs.list_ids/1`, `Audit.list_all/1`,
  or application-side filtering of an unbounded result.
- **Mutation authority:** JobsLive and BatchCoordinator contain no direct
  `Oban.retry/1`, `Oban.cancel/1`, `Oban.discard/1`, or insert/update/delete
  mutation calls. Single and bulk actions retain Lifeline preview/reauthorization.
- **Confidentiality:** Production Phase 80 paths contain no `inspect/1` rendering
  fallback. Coordinator telemetry has an exact closed metadata map and bucketed
  counts/durations; IDs, filter identity, reason text, preview tokens, plan
  hashes, payloads, errors, and stack traces are absent.
- **Pure composition:** `JobsLive.page_content/1`,
  `JobsLive.detail_page_content/1`, and `ForensicsLive.page_content/1` contain no
  Repo/context read, `DateTime.utc_now/0`, or Task/process work. Reads and current
  time capture happen before assigns cross the render seam.
- **URL grammars:** Jobs accepts exactly `state queue worker tags args meta page
  job`; Forensics accepts exactly `resource_type resource_id workflow_id step
  incident_fingerprint view`. Unknown, duplicate, mixed, or malformed values
  canonicalize before reads.
- **Semantic-tree bounds:** LiveView and browser contracts prove exactly one Jobs
  table, exactly one Forensics timeline/list, at most one dialog, no paired
  mobile/desktop copy trees, and at most 50 event rows.
- **Scope boundary:** Baseline-to-closure committed diff adds no schema, migration,
  lockfile, dependency, or production public route. `package.json` adds only the
  ordered host/Docker page scripts. The example-host fixture route is compile-
  and env-gated to test and its route-off branch executes two real tests.
  Plan 80-13 implementation adds only the production-composed VoiceOver spec,
  this ledger, and a 15-second Playwright assertion/readiness window.

## Incident Predicate Evidence

The fresh local `EXPLAIN (ANALYZE, BUFFERS)` for
`metadata->>'incident_fingerprint'` shows:

```text
Limit ... rows=5
  -> Sort ... inserted_at DESC, id DESC
       -> Seq Scan on oban_powertools_audit_events
Execution Time: 0.033 ms
```

The captured parameterized SQL ends with `LIMIT $2` and binds the probe limit
`51`. This proves local bounded result transfer and records that the JSONB
predicate is unindexed. It is not a representative-host latency claim. Hosts
must run this query against representative cardinality/distribution and add a
host-owned expression index if their measured plan warrants it. No library
migration is implied.

## Final Browser and VoiceOver Evidence

- Repeated manifest generation produced the same SHA-256,
  `1d9ec00506ff3d4a67b872893302a30963540575a2900b1eb7524dc638f7956c`,
  with schema 8, 49 page stories, 113 targets, 4 themes, and 3 viewports.
- `npx playwright test --config=voiceover.config.ts --list` discovered exactly
  these seven fail-closed production story IDs:
  `page-overview-fixed-order-nonzero`, `page-cron-pause-confirmation`,
  `page-cron-expired-recovery`, `page-limiters-blocked-evidence-layers`,
  `page-audit-selected-missing-fields`, `page-jobs-full-detail`, and
  `page-forensics-incident-partial-remediation`.
- Exact validators reported 588 tracked page PNG paths and 147 tracked page
  ARIA YAML paths. No baseline update command ran and no baseline file changed.
- The first fresh aggregate passed 1,388/1,392; all four misses stopped at the
  same five-second LiveView readiness wait before acceptance, axe, or snapshot
  assertions. Exact isolated reruns passed 10/10 and 8/8.
- A second fresh aggregate passed 1,389/1,392 and reproduced three readiness-only
  timeouts. Plan 80-13 raised the shared Playwright assertion/readiness window
  from five to fifteen seconds without altering product behavior or evidence.
  The affected post-fix coverage passed 10/10 and 1/1, and the final exact
  `npm run verify:pages` passed 1,392/1,392 in 25.8 minutes.
- The exact VoiceOver wrapper first exposed a missing pinned WebKit executable.
  After installing Playwright WebKit v2311 in the local cache, the exact rerun
  reached all seven registered tests but stopped before page navigation with
  `VoiceOver cannot be started`; the common cause was
  `Failed to mount Guidepup preferences`. The diagnostic requires one-time
  `npx @guidepup/setup setup` OS configuration and
  `npx @guidepup/setup install` project assets. The Showcase wrapper completed
  its health gate, and there was no database, route, manifest, story lookup,
  selector, transcript, or product-page failure.
- Launcher dependency resolution also reports advisories in the existing locked
  Bandit, hpax, Mint, Oban Web, Phoenix, Plug, Postgrex, and Req graph. Plan
  80-13 changed no dependency or lockfile; this remains separately owned
  dependency-upgrade debt rather than a page-quality result.

## High-Threat Reconciliation

| Threat IDs | Closure evidence | Status |
|---|---|---|
| T-80-01-INJECT/TAMPER/DOS/FALSEGREEN | parameterized queries, closed URL keys, draft/applied separation, page/count/window bounds, complete fresh suites | mitigated |
| T-80-02-IDOR/LEAK/DOS/TAMPER/A11Y/FALSEGREEN | uniform unavailable review, finite presenter, bounded browse, canonical URL, one named semantic table, full focused files green | mitigated |
| T-80-03-IDOR/LEAK/REPLAY/NAV/TRUTH/INJECT | double authorization, structural allowlists, Lifeline single-use state, seven-key return reconstruction, finite receipts, escaped/code-safe rendering | mitigated |
| T-80-04-SCOPE/AUTH/LEAK/DOS/CRASH/REPLAY/CONFIG | frozen membership, per-target authority, closed telemetry/messages, max-four/timeout/result-page bounds, named nonlinked supervisor, durable audit, fail-fast config | mitigated |
| T-80-05-CONFUSION/IDOR/DOS/TRUTH/PERF | sum-type scope, scoped uniform results, 50/51 SQL limits, exact-vs-has-more split, recorded local Seq Scan limitation | mitigated; host measurement documented |
| T-80-06-CONFUSION/IDOR/LEAK/DOS/TRUTH | typed dispatch, scoped predicates, structural projection/sentinels, bounded histories, independent truth dimensions | mitigated |
| T-80-07-IDOR/TAMPER/LEAK/TRUTH/DOS/A11Y | reauthorization, parse-before-read, closed presenter, separated truth, one bounded tree, native semantics/focus | mitigated |
| T-80-08-FORK/LEAK/SCOPE/A11Y | production `page_content/1`, normalized fixtures and sentinels, exact single ordered registry, acceptance metadata/tree bounds | mitigated |
| T-80-09-PREFIX/SCOPE/FORK/THEME/A11Y | stable generated prefix contract, exact manifest-derived sets, no duplicate browser registry, four themes, 147/588 contract | mitigated |
| T-80-10-AUTH/DATA/LEAK/INJECT/ZERO/DOS/REGRESS | test-only secret gate, run isolation/cleanup, name-only secret, closed routes/schemas, real route-off tests, bounded launcher, dual-generation evidence | mitigated |
| T-80-11-FALSE/AUTH/LEAK/A11Y/MANIFEST/PORT | real production URLs/effects, auth races/frozen scope, cross-channel sentinels, keyboard/reflow/target assertions, exact Wave 1 prefix, one serial launcher | mitigated |
| T-80-12-OMIT/SCOPE/LEAK/THEME/HOST/A11Y | tracked exact sets, prefix/inventory hashes, closed stories, four-theme review, root-scoped byte-equal assets, axe/ARIA/VRT closure | mitigated |
| T-80-13-FALSEGREEN/SCOPE/LEAK/A11Y/VRT/GAP | fresh explicit counts, isolated timeout diagnosis and hardening, exact Phase 80 attribution, confidentiality reconciliation, exact seven-story discovery, unchanged 147/588 tracked sets, final 1,392/1,392 compare, and complete source audit | mitigated; real transcripts remain honestly open for supported environment |

No high threat from Plans 80-01 through 80-13 remains open. The only outstanding
accessibility observation is the platform-bound VoiceOver transcript gate below.

## Multi-Source Coverage Audit

| Source | ID | Feature / requirement | Plans | Status |
|---|---|---|---|---|
| GOAL | — | Jobs + Forensics rebuilt on FilterBar/DataTable/DetailSurface/Timeline with preserved URL/filter/search/bulk/deep links and adversarial VRT/a11y | 02-13 | covered |
| REQ | PAGE-02 | Jobs list/detail/filter/bulk/deep-link migration | 01-04, 08-13 | covered |
| REQ | PAGE-09 | Forensics bundle/timeline migration | 05-13 | covered |
| REQ | FORM-03 | Submit-mode URL-serialized Jobs/Forensics controls | 01, 02, 07, 10, 11, 13 | covered |
| REQ | DATA-* | Shared DataTable/Timeline/DescriptionList/args/status/explicit-state contracts | 01-09, 12, 13 | covered |
| REQ | PAGE-10 | Pure production composition, shared consistency, catalog/browser proof | 01-13 | covered |
| REQ | A11Y-* | Semantic controls, focus/dialog behavior, targets, reflow, tracked ARIA, axe, exact screen-reader contract | 01-13 | covered; transcripts environment-open |
| RESEARCH | — | Canonical applied/draft URL state and selector allowlists | 01, 02, 05, 07, 10, 11 | covered |
| RESEARCH | — | One grouped Jobs count, exact active count, bounded stable IDs | 01, 02, 04 | covered |
| RESEARCH | — | Frozen max-100/default, max-1000, max-four, timeout-safe supervised work | 04, 10, 11, 13 | covered |
| RESEARCH | — | Typed four-family Forensics scope and 50-event bounded Audit window | 05-07, 10, 11 | covered |
| RESEARCH | — | Structural redaction before assigns/logs/telemetry/DOM | 02-13 | covered |
| RESEARCH | — | Exact 49-story/schema-8/147-ARIA/588-PNG production-composition matrix | 08, 09, 12, 13 | covered |
| RESEARCH | — | Isolated authenticated connected fixtures and Docker-first proof | 10, 11, 13 | covered |
| RESEARCH | — | Jobs/Forensics VoiceOver transcript contract on supported environment | 13 | executable; transcripts environment-open |
| RESEARCH | — | No dependency, migration, new route shape, durable ledger, or second story system | 01-13 | covered |
| CONTEXT | D-01..D-08 | Product authority, journey, human vocabulary, page roles, evidence separation, native routes, exact nouns, explicit states | 01-13 | covered |
| CONTEXT | D-09..D-19 | Jobs browse/review/detail/action/history/focus/unavailable model | 02, 03, 08-13 | covered |
| CONTEXT | D-20..D-35 | Jobs state/filter/copy/table/order/count/query/reflow/index contract | 01, 02, 08-13 | covered |
| CONTEXT | D-36..D-52 | Frozen selection, preview, config, supervision, progress, result, disconnect, recovery | 04, 08-13 | covered |
| CONTEXT | D-53..D-62 | Forensics full-page hierarchy and typed chooser/scope grammar | 05-13 | covered |
| CONTEXT | D-63..D-72 | Event log, evidence dimensions/bounds/query ownership/redaction/copy/destinations | 05-13 | covered |
| CONTEXT | D-73..D-80 | LiveView/Ecto/OTP/DX/auth/telemetry/receipt/bound architecture | 01-13 | covered |
| CONTEXT | D-81..D-88 | Design pillars, control-room visuals, themes/motion, semantics/live regions, fixtures, complete verification | 02, 04, 07-13 | covered |

No goal, requirement, research constraint, or D-01 through D-88 decision is
missing. Deferred drawers, quick-review mutations, saved filters, qualifier DSL,
new filter dimensions, sorting/cursors, durable bulk resume, retry/export,
Forensics live/search/pagination/chart/source/encryption expansions, and arbitrary
job-to-Forensics links remain absent by design.

## Manual and Environment-Bound Evidence

| Behavior | Requirement | Evidence state | Required closure |
|---|---|---|---|
| VoiceOver transcript — Jobs production composition | A11Y-* | OPEN — SUPPORTED-ENVIRONMENT GAP | Exact story and `Back to Jobs` assertion are executable. Rerun after one-time Guidepup OS setup/project install; current run stopped at VoiceOver startup before navigation. |
| VoiceOver transcript — Forensics production composition | A11Y-* | OPEN — SUPPORTED-ENVIRONMENT GAP | Exact story and `Investigation summary`/`Event log` assertions are executable. Rerun after one-time Guidepup OS setup/project install; current run stopped at VoiceOver startup before navigation. |
| Incident JSONB predicate at representative host scale | PAGE-09 | SUPPORTED-RUNNER FOLLOW-UP | Local bounded SQL and Seq Scan are recorded above; evaluate on representative host data and add a host-owned expression index only if measurement warrants it. |

## Approval

**Approved with supported-environment transcript gap.** Plans 80-01 through
80-13 are approved by fresh automated, connected, source, manifest, ARIA, axe,
and compare-only visual evidence. The exact seven-story VoiceOver contract is
present and fail-closed, the Showcase health gate succeeds, and the remaining
failure is solely the documented Guidepup/macOS startup prerequisite. Jobs and
Forensics transcripts remain open and are not replaced by axe or invented
output. Nyquist remains true because the required observable gate and its exact
environment limitation are both recorded.

## Corrected Plan 80-16 Attempt — 2026-07-29

The corrected attribution retry stopped at the isolated calibration extractor,
before the full-suite, failed-test rerun, artifact, VoiceOver-discovery, or page
quality gates. This is a fail-closed result, not Phase 80 completion.

### Gates completed before the blocker

| Gate | Current result |
|---|---|
| Focused Jobs/Forensics command | PASS — 112 tests, 0 failures |
| Coordinator repeat 1 | PASS — 9 tests, 0 failures |
| Coordinator repeat 2 | PASS — 9 tests, 0 failures |
| Coordinator repeat 3 | PASS — 9 tests, 0 failures |
| `mix format --check-formatted` | PASS |
| `mix compile --warnings-as-errors --force` | PASS — 103 files compiled |
| Isolated calibration command | ExUnit exit 2 — 26 tests, 5 failures |
| Exact outer-heading extraction | **BLOCKED** — one heading has two eligible repository test locations |

CR-01, WR-01, WR-02, and V-TEST-01 remain closed by the fresh focused lane and
the three additional coordinator runs. PAGE-02, PAGE-09, FORM-03, DATA-01
through DATA-04, PAGE-10, and A11Y-01 through A11Y-04 remain represented by
their existing implementation and historical evidence, but no requirement is
promoted by this failed closeout attempt.

### Finite attribution blocker

The exact extractor contract recognizes this outer failure heading:

```text
  4) test control-plane lane proves overview, audit, and bridge-only follow-up through the canonical fixture (ObanPowertools.ExampleHostContractTest)
```

Before the next outer heading, the calibration log contains two lines matching
`^[[:space:]]*test/[^[:space:]:]+_test\.exs:[1-9][0-9]*[[:space:]]*$`:

```text
     test/oban_powertools/example_host_contract_test.exs:36
          test/phoenix_host_web/oban_powertools_control_plane_smoke_test.exs:6
```

The plan requires failure on zero or multiple matching locations. Therefore no
schema-valid `calibration.identities.tsv` can be created, and the authoritative
calibration/full/failed-rerun byte-equality protocol cannot legally continue.
The nested generated-host location cannot be silently ignored without changing
the plan's executable extractor contract.

### Provenance and scope

- Calibration log SHA-256:
  `38fd148adf60d1a18fa1b39618d93d46a0cd4c327bcb72aa39d087ae758300be`.
- Focused log SHA-256:
  `4b91672673a1d0cad2de13877e00d944d73b0bc2e4055a6d6b6e9b6423cedd89`.
- Coordinator log SHA-256 values:
  `7b825749a7f8ab558383bad503a7bf3401a230fa2162824849d4dcf17629f712`,
  `f2592b22c246bfdcf272c1c1be3cd837ea84057704430b3d1e1a40af3230549b`,
  and
  `5c480dcbc832069223459ed53180ad4a8620da7343dd3a9f2ba39583aa89bd8c`.
- The five owner/support hashes remained byte-identical:
  `92b3782b7444ae23df25fe4d7d91ae714b062b1c`,
  `6aa83b5905aaba06784fb37cafd18cd4d696486e`,
  `aa45f35937681c44511c83595f1893d65caf232c`,
  `cb7879daf34537c5db0c3307ae38135f08dd52f8`, and
  `98aea1fe7c12af679f0416bb185d116bdda5f9f7`.
- No production, test, CI, example-host, installer, dependency, manifest,
  generated asset, ARIA YAML, PNG baseline, schema, migration, or prior
  Plan/Summary file was changed by this attempt.
- Manifest, artifact validators, 147/588 inventory, seven-case VoiceOver
  discovery, and compare-only `npm run verify:pages` were not entered after the
  attribution prerequisite failed. No snapshot-update command or fabricated
  transcript was used.

### ASVS dispositions

| Threat | Current disposition |
|---|---|
| T-80-16-NESTED | open/blocking — exact extractor observes multiple eligible locations |
| T-80-16-COUNT | mitigated — count-only fallback was refused |
| T-80-16-SCOPE | mitigated — owner/support hashes stayed unchanged |
| T-80-16-BOOKKEEP | mitigated — ledgers remain snapshotted and no Summary exists |
| T-80-16-A11Y | open for this retry — downstream fresh gates were not entered |
| T-80-16-VRT | open for this retry — compare-only page gate was not entered |

The exact ROADMAP and REQUIREMENTS snapshots are unchanged. The next plan
revision must make the extractor's nested-output eligibility rule executable
without weakening module/title/path/line provenance, then rerun every Plan
80-16 gate from a fresh snapshot.

## Corrected Plan 80-16 Closure — 2026-07-29

Plans 80-01 through 80-16 now cover the 15 previously executed plans, the
historically failed Plan 80-16 comparator attempt above, and this corrected
Plan 80-16 closure. The historical attempt remains evidence of a fail-closed
stop; it did not complete the plan. This section records the fresh corrected
run from a new ROADMAP/REQUIREMENTS snapshot.

### Exact extractor calibration

The one extractor used for fixtures, isolated calibration, the full suite, and
the failed-test rerun recognizes only failure locations matching the literal
regex:

```text
^     test/[^[:space:]:]+_test\.exs:[1-9][0-9]*$
```

The prefix is exactly five ASCII spaces, with no arbitrary-whitespace prefix
and no trailing whitespace. It buffers all tuples until every outer heading is
valid. Ten-space generated-host locations are nested diagnostic output and are
mechanically ineligible.

| Fixture | Exact result |
|---|---|
| One five-space outer location plus one ten-space nested location | PASS — exit 0 and exact one-row tuple byte comparison |
| Ten-space nested location only | PASS — extractor exit 1 and existing zero-byte rejection TSV |
| Two five-space outer locations | PASS — extractor exit 1 and existing zero-byte rejection TSV |

The positive tuple was exactly:

```text
ObanPowertools.ExampleHostContractTest	control-plane lane proves overview, audit, and bridge-only follow-up through the canonical fixture	test/oban_powertools/example_host_contract_test.exs	36
```

### Product and repeatability gates

| Command / contract | Current result |
|---|---|
| Focused five-file Jobs/Forensics suite with `--seed 0` | PASS — 112 tests, 0 failures |
| Coordinator rerun 1 with `--seed 0` | PASS — 9 tests, 0 failures |
| Coordinator rerun 2 with `--seed 0` | PASS — 9 tests, 0 failures |
| Coordinator rerun 3 with `--seed 0` | PASS — 9 tests, 0 failures |
| `mix format --check-formatted` | PASS |
| `mix compile --warnings-as-errors --force` | PASS — 103 files compiled |

CR-01, WR-01, WR-02, and V-TEST-01 are closed. The focused lane preserves
relational workflow-step authority, bounded Jobs URL values, exact frozen batch
positions, and fail-closed reconciliation.

### Authoritative residual attribution

| Run | Command status | Terminal summary | Identity rows |
|---|---:|---|---:|
| Isolated calibration | 2 | `26 tests, 5 failures` | 5 |
| Full suite | 2 | `933 tests, 5 failures` | 5 |
| Immediate failed-test rerun | 2 | `5 tests, 5 failures` | 5 |

Each run produced an existing four-field TSV. Each stored failure count equals
the independently reparsed terminal summary, each positive failure total is
paired with command exit 2, every source line is positive, and every
module/path pair is allowlisted. The sorted TSVs are byte-identical:

```text
ObanPowertools.DocsContractTest	visual regression and a11y guardrails stay locked in docs and CI	test/oban_powertools/docs_contract_test.exs	195
ObanPowertools.ExampleHostContractTest	control-plane lane proves overview, audit, and bridge-only follow-up through the canonical fixture	test/oban_powertools/example_host_contract_test.exs	36
ObanPowertools.ExampleHostContractTest	native-only lane compiles and resets cleanly	test/oban_powertools/example_host_contract_test.exs	12
ObanPowertools.ExampleHostContractTest	upgrade lane proves ops-demo pauses nightly_sync with pause_cron_entry after the documented host updates	test/oban_powertools/example_host_contract_test.exs	51
ObanPowertools.FreshHostContractTest	fresh host lane installs, compiles, migrates, and boots	test/oban_powertools/fresh_host_contract_test.exs	11
```

The five residual owner/support hashes were unchanged before and after all
three commands:

```text
92b3782b7444ae23df25fe4d7d91ae714b062b1c
6aa83b5905aaba06784fb37cafd18cd4d696486e
aa45f35937681c44511c83595f1893d65caf232c
cb7879daf34537c5db0c3307ae38135f08dd52f8
98aea1fe7c12af679f0416bb185d116bdda5f9f7
```

Evidence-log SHA-256 values were:

```text
focused       517cd635986ddbb1aa8031f24034eb875cb8285015cb94b6067608cecdaf8f09
coordinator-1 1137e0b06694aae564b6157d93bc2ff49681442108ff6e2b1c0308bcdb976a9b
coordinator-2 936778604d04cd8a112ffd95a0e8183a3f49d550efe5ddfb0663b105be7a530a
coordinator-3 a96455e3e48e34773c6c3489eecae6ff090298c2edd4cfed80f9e452f34ebccb
calibration   5f885f71955c20460eefa4534d32999396b59799ffeba6c9331c1d9894e6e358
full          e8dec9f5f4db0ed56e830932821d4540ab20a0421390d91d665a8022442b5ad3
failed-rerun  04cc234b31feaf67ac0d70e214d3c54fbfc8a2d1a95299bb7a5788c9a0be27e7
```

### Artifact, accessibility, and page-quality gates

| Gate | Current result |
|---|---|
| `npm run showcase:manifest` | PASS — schema 8, 49 page stories, 113 targets |
| Exact page baseline validator | PASS — 588 tracked paths |
| Exact page ARIA validator | PASS — 147 snapshots |
| Git-tracked inventory | PASS — exactly 147 ARIA YAML and 588 page PNG files |
| VoiceOver `--list` discovery | PASS — exactly seven cases in one file, including one Jobs and one Forensics case |
| `npm run verify:pages` | PASS — 1,392 compare-only tests |

No snapshot-update command ran. The documented real VoiceOver transcripts remain
open in an unsupported local Guidepup/macOS environment; discovery is current,
and axe/ARIA output is not substituted for transcripts. This is the existing
supported-environment disposition, not a fabricated accessibility claim.

### Requirement and ASVS disposition

- PAGE-02 and FORM-03 retain canonical oversized-input recovery and exact
  frozen batch terminal truth.
- PAGE-09 and PAGE-10 retain relationally authorized workflow-step evidence in
  the shared production composition.
- DATA-01 through DATA-04 retain bounded reads, closed presenters, structural
  redaction, stable identity, and explicit result truth.
- A11Y-01 through A11Y-04 retain exact manifest, ARIA, axe, connected,
  compare-only visual, and supported-environment VoiceOver evidence.
- T-80-16-INVENTORY, STALE, COUNT, MISSING, NESTED, SCOPE, BOOKKEEP, A11Y,
  VRT, and DISCLOSE are mitigated by the corrected fixtures, exact identity
  reproduction, owner hashes, ledger snapshots, artifact counts, compare-only
  run, and finite report contents.

Before Summary creation, ROADMAP and REQUIREMENTS remained byte-identical to
their fresh snapshots, ROADMAP still reported 15/16 with Plan 80-16 unchecked,
the Summary was absent, and STATE contained no terminal Plan 80-16 marker.
