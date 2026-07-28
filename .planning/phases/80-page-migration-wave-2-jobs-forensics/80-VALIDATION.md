---
phase: 80
slug: page-migration-wave-2-jobs-forensics
status: executing
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-27
updated: 2026-07-28
---

# Phase 80 — Validation Evidence Ledger

This ledger reconciles every implementation task and high threat from Plans 80-01
through 80-12 against fresh closure evidence. Plan 80-13 VoiceOver and final
compare-only evidence remains explicitly open until Task 80-13-02 completes.

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
| Fresh `npm run verify:pages` | pending Task 80-13-02 | open |
| Seven production-composed VoiceOver transcripts | pending Task 80-13-02 | open |

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

All 23 tasks in Plans 80-01 through 80-12 are represented above. Their plan
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
| A11Y-* | One semantic tree, exact table/timeline bounds, focus/reflow/target/axe/ARIA/VRT evidence | automated green; real VoiceOver open |

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

No high threat from Plans 80-01 through 80-12 remains open. The only outstanding
accessibility observation is the platform-bound VoiceOver transcript gate below.

## Manual and Environment-Bound Evidence

| Behavior | Requirement | Evidence state | Required closure |
|---|---|---|---|
| VoiceOver transcript — Jobs production composition | A11Y-* | OPEN | Run the seven-story production-composed harness and require `Back to Jobs` in every Jobs transcript. An environmental classification is allowed only after showcase health succeeds and the residual is specifically macOS/VoiceOver/Guidepup capability. |
| VoiceOver transcript — Forensics production composition | A11Y-* | OPEN | Run the same harness and require both `Investigation summary` and `Event log` in every Forensics transcript under the same narrow classification rule. |
| Incident JSONB predicate at representative host scale | PAGE-09 | SUPPORTED-RUNNER FOLLOW-UP | Local bounded SQL and Seq Scan are recorded above; evaluate on representative host data and add a host-owned expression index only if measurement warrants it. |

## Approval

**Pending Task 80-13-02.** Plans 80-01 through 80-12 are approved by fresh
automated and source evidence. Final Phase 80 approval requires a fresh
compare-only page run plus either observed seven-story VoiceOver transcripts or
an explicitly supported environmental gap after successful showcase health.
