---
phase: 81
slug: page-migration-wave-3-batches-workflows-lifeline
status: verified
threats_total: 45
threats_closed: 45
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: 2026-07-29
audited: 2026-07-29
---

# Phase 81 — Security

> ASVS L1 verification of every threat declared in the fifteen Phase 81 plans.
> The audit verifies the plan-time register; it does not silently accept or
> transfer risks.

---

## Scope and Method

- Register source: `81-01-PLAN.md` through `81-15-PLAN.md`.
- Register size: 45 threats — 7 critical and 38 high; all have disposition
  `mitigate`.
- Blocking policy: `block_on: high`; therefore any unverified registered threat
  would set `threats_open` above zero and block security approval.
- Verification method: direct source tracing, exact-map and LiveView tests,
  enabled/disabled fixture tests, connected production-route execution,
  generated-inventory and artifact validators, CI-graph mutation tests, and
  source/package CSS comparison.
- Implementation files were treated as read-only by this audit.

## Trust Boundaries

| Boundary | Description | Data crossing |
|---|---|---|
| Browser URL/event → LiveView | Untrusted selectors and events become canonical selection or fixed server events | IDs, filters, step names, row IDs, reason text |
| LiveView → authorization/domain mutation | Current actor, selected resource, and private preview cross server-owned authorization immediately before mutation | Batch/callback/job/incident identity, preview capability, reason |
| Repo/domain → presenter/DOM | Operational records cross exact finite presentation maps and display policy | Status, evidence, errors, history, destinations |
| Test client → fixture controller | An ephemeral credential and closed command schema authorize deterministic test-only state | Project/run, actor, race command |
| Catalog → showcase/manifest/browser | Deterministic safe fixtures become one production-composed page tree and exact evidence inventory | Story IDs, page family, activation, ARIA/PNG paths |
| CI/artifact graph → merge decision | Exact compare-only commands and tracked evidence sets become merge-blocking proof | 99 stories, 163 targets, 297 ARIA files, 1,188 PNGs |

## Verification Evidence

| Ref | Concrete evidence |
|---|---|
| E01 | Fresh combined Phase 81 presenter/selector/LiveView/catalog/showcase run: **141 tests, 0 failures** on 2026-07-29. Principal files: `operator_pattern_presenter_test.exs:89-481`, `batches_live_test.exs:100-275`, `workflows_live_test.exs:44-363`, `lifeline_live_test.exs:286-854`. |
| E02 | Closed URLs and authority-bearing-key rejection: `selectors.ex:49-55,77-85,130-156`; adversarial encoding and `action`/`preview_token` tests: `selectors_test.exs:275-302`. |
| E03 | Batches selection is restricted to the current eligible set, preview and execute reauthorize, and every retained window is finite: `batches_live.ex:89-168,216-317,930-1003`; focused tests: `batches_live_test.exs:100-275`. |
| E04 | Workflows parses UUIDs, authorizes before safe lookup, uses one unavailable branch, bounds all four reads, and exposes no mutation form: `workflows_live.ex:339-447`; tests: `workflows_live_test.exs:44-100,139-169,236-264,334-363`. |
| E05 | Exact closed projections, taxonomy, bounded collections, uniform unavailable incident maps, private repair capability, non-atomic copy, and success-only Audit receipt: `control_plane_presenter.ex:11-21,253-405,499-659,663-755,3147-3154`; exact/confidentiality tests: `operator_pattern_presenter_test.exs:89-481`. |
| E06 | Lifeline authorizes preview, authorizes again immediately before execute, passes the private preview value server-side, clears it after success, and keeps drifted/expired/consumed outcomes distinct: `lifeline_live.ex:80-232,1289-1335,1522-1534,1657-1677`; focused tests: `lifeline_live_test.exs:286-498,818-854`. |
| E07 | Lifeline incidents, executor evidence, and Audit evidence are bounded and current/history truth remains separate: `lifeline_live.ex:998-1067,1259-1267`; corrected filtered/bounded behavior is covered by commits `e461169`, `23d8b3b`, and the fresh E01 run. |
| E08 | Fixture authority is compile/test/flag gated, POST-only, constant-time credential checked, closed-schema, finite, and non-echoing: `router.ex:57-64`, `phase81_browser_fixtures.ex:4-7,143-519,694-703`, `phase81-fixtures.ts:12-27,115-147,151-185,255-319`. Fresh host evidence: flag off **2/2**, flag on **5/5**. |
| E09 | Connected production-route security cases cover bounded Batches scope, non-enumerating Workflows, Lifeline reauthorization/stale/duplicate outcomes, focus/modality, reflow/motion, and cross-channel confidentiality: `page-migration-wave-3.spec.ts:251-589`. Fresh host execution passed all **10/10** production-page cases. |
| E10 | The Elixir catalog is the single exact 18/12/20 Wave 3 inventory and now contains only supported Lifeline drifted/expired/consumed execution states: `page_story_catalog.ex:2362-2424,2956-2972`; correction commit `305ae84`; fresh E01 catalog/showcase coverage passed. |
| E11 | Schema 8 and exact browser inventory are derived and fail closed at 99 stories / 163 targets: `showcase_manifest.exs:176-186`, `manifest.ts:305-333`, `manifest-smoke.mjs:418-450`. Fresh manifest generation and smoke validation passed. |
| E12 | Exact artifact validators enforce 297 ARIA and 1,188 PNG paths and reject missing, extra, untracked, renamed/copied, or unexpected-scope evidence: `verify-page-aria-snapshots.mjs:23-79,136-219,270-296`; `verify-page-baselines.mjs:11-158,214-295,334-360`. Both fresh validators passed. |
| E13 | Wave 3 CSS is root-scoped, one-tree, 44px-targeted, responsive, focus-visible, and reduced-motion-safe: `tokens.css:4081-4299`; token/asset contracts: `theme_tokens_test.exs:764-872`, `assets_test.exs:143-173`. Fresh `cmp -s` proved source and packaged CSS are byte-identical. |
| E14 | The required command graph places Phase 81 after Wave 2, forbids update/watch modes, structurally owns one unfiltered `npm run verify:pages`, and requires it directly in the exact seven-job gate: `package.json:9-13`, `ci.yml:109-149,248-277`, `verify-page-script-order.mjs:7-58,278-398`. Fresh validator passed all live and mutation checks. |
| E15 | VoiceOver targets resolve exactly once from the manifest and transcripts are captured only by actual Guidepup execution: `page.voiceover.spec.ts:14-50,99-180`. Fresh discovery listed 10 tests with exactly the three Wave 3 targets. |
| E16 | Review fixes were traced through current source and tests: `81-REVIEW.md`, `81-REVIEW-FIX.md`, commits `b7c31f9` through `305ae84`. The current validation and verification artifacts report 35/35 truths and no unresolved Phase 81 behavior gap. |

## Threat Register

| Threat ID | Category | Severity | Disposition | Verified mitigation / evidence | Status |
|---|---|---|---|---|---|
| T-81-01-URL-AUTH | Elevation of privilege | high | mitigate | Canonical selectors drop authority-bearing Batch keys; fixed LiveView events remain authoritative — E02, E03, E06 | closed |
| T-81-01-DOM-LEAK | Information disclosure | high | mitigate | Exact presenter maps and cross-channel sentinel scans exclude tokens, snapshots, provider data, and exceptions — E05, E09 | closed |
| T-81-01-STALE-EXEC | Tampering | high | mitigate | Execute-time authorization, private fresh previews, and consumed/drifted/expired recovery are executable contracts — E03, E06, E09 | closed |
| T-81-01-UNBOUNDED | Denial of service | high | mitigate | Exact limit-plus-one SQL/source windows and rendered caps exist for all twelve collections — E03, E04, E05, E07 | closed |
| T-81-02-SCOPE | Elevation of privilege | high | mitigate | Batch selection is page-local, eligible-only, and filtered again immediately before per-target preview/execute — E03 | closed |
| T-81-02-EVIDENCE-LEAK | Information disclosure | high | mitigate | Batch presenters structurally allowlist member/callback/result/Audit fields before rendering — E05 | closed |
| T-81-02-STALE-AUTH | Elevation of privilege | high | mitigate | Batch and callback execution reauthorize and regenerate/consume server previews — E03, E09 | closed |
| T-81-02-SCAN-DOS | Denial of service | high | mitigate | Batch member/callback repository reads and all four render windows are finite — E03, E05 | closed |
| T-81-03-ENUM | Elevation of privilege | high | mitigate | UUID cast → authorization → safe lookup, with one unavailable branch — E04, E09 | closed |
| T-81-03-RAW-EVIDENCE | Information disclosure | high | mitigate | Workflow maps omit input/context/raw result data and use display policy — E04, E05 | closed |
| T-81-03-FALSE-CAUSALITY | Spoofing | high | mitigate | Semantic dependency lists keep diagnosis, dependency, callback, and recovery truth distinct — E04, E10 | closed |
| T-81-03-MUTATION | Elevation of privilege | high | mitigate | Workflows remains read-only and exposes only a Lifeline handoff — E04, E09 | closed |
| T-81-04-CAPABILITY | Information disclosure | critical | mitigate | RepairPreview token/hash/snapshots are never copied into confirmation maps — E05, E06 | closed |
| T-81-04-INCIDENT-ENUM | Information disclosure | high | mitigate | Unauthorized/malformed incidents resolve to the same finite unavailable maps — E05 | closed |
| T-81-04-FALSE-SUCCESS | Spoofing | high | mitigate | Only clean success receives receipt/Audit; every other result requires recovery — E05, E10 | closed |
| T-81-04-HISTORY-DOS | Denial of service | high | mitigate | Incident/Audit/result histories are hard-capped with explicit completeness — E05, E07 | closed |
| T-81-05-FORGED-EXEC | Elevation of privilege | critical | mitigate | Fixed event, server-private preview, reason validation, principal lookup, and immediate action authorization precede execute — E06, E09 | closed |
| T-81-05-CHANNEL-LEAK | Information disclosure | critical | mitigate | DOM, URL, request/response, WebSocket, console, error, and server-log sentinels are scanned — E05, E09 | closed |
| T-81-05-MODAL-SAFETY | UI integrity | high | mitigate | One dialog, Escape/containment/invoker restore/result focus, and 44px targets are connected contracts — E09, E13 | closed |
| T-81-05-OUTCOME-TRUTH | Spoofing | high | mitigate | Authorization refusal, drifted, expired, consumed, and success-with-Audit remain distinct; unsupported aggregate states were removed — E06, E10, E16 | closed |
| T-81-06-FIXTURE-LEAK | Information disclosure | high | mitigate | Catalog fixtures are closed plain maps, contain no authority, and render through production seams — E01, E10 | closed |
| T-81-06-DUPLICATE-DOM | Information disclosure | high | mitigate | Showcase activates one page tree and at most one real dialog; CSS does not duplicate responsive DOM — E01, E10, E13 | closed |
| T-81-07-PROD-FIXTURE | Security misconfiguration | critical | mitigate | Fixture module and routes require test compilation plus explicit flag; route-off tests pass — E08 | closed |
| T-81-07-FORGED-COMMAND | Elevation of privilege | high | mitigate | POST-only exact schemas, constant-time credential check, and uniform empty denial are enforced — E08 | closed |
| T-81-07-CREDENTIAL-LEAK | Information disclosure | high | mitigate | Launchers pass an ephemeral secret by environment name; clients and responses redact/reject it — E08 | closed |
| T-81-07-SEED-DOS | Denial of service | high | mitigate | Fixture commands and deterministic saturated sets are fixed and bounded — E08 | closed |
| T-81-08-CLIENT-AUTH | Elevation of privilege | critical | mitigate | Connected forged, revoked, drifted, expired, and duplicate cases reach real production LiveViews and fail closed — E09 | closed |
| T-81-08-OBSERVER-LEAK | Information disclosure | critical | mitigate | Full browser-channel confidentiality scan passes on the production routes — E09 | closed |
| T-81-08-UI-ACTION | UI integrity | high | mitigate | Connected keyboard, focus, reflow, zoom, target, and reduced-motion mechanics pass — E09, E13 | closed |
| T-81-08-CI-OMISSION | Repudiation | high | mitigate | Exact script order and direct merge-gate dependency are mutation-tested — E14 | closed |
| T-81-09-BLESS-DEFECT | Tampering | high | mitigate | Batches artifacts have exact family cardinality, tracked-set validation, and compare-only evidence — E12, E16 | closed |
| T-81-09-ARTIFACT-LEAK | Information disclosure | high | mitigate | Closed fixtures plus ARIA review/validators and connected sentinel scans protect persisted evidence — E09, E10, E12 | closed |
| T-81-10-DUPLICATE-TREE | Information disclosure | high | mitigate | Root-scoped responsive CSS reflows one semantic tree and one modal — E13 | closed |
| T-81-10-ASSET-TAMPER | Tampering | high | mitigate | Packaged CSS is generated from and byte-identical to reviewed source — E13 | closed |
| T-81-10-MOTION-FOCUS | UI integrity | high | mitigate | Token-only focus/motion rules and both reduced-motion controls are tested — E09, E13 | closed |
| T-81-11-BLESS-DEFECT | Tampering | high | mitigate | Workflows artifacts have exact family cardinality, tracked-set validation, and compare-only evidence — E12, E16 | closed |
| T-81-11-EVIDENCE-LEAK | Information disclosure | high | mitigate | Closed workflow fixtures, semantic blocked-state assertions, ARIA validators, and channel scans are present — E04, E09, E10, E12 | closed |
| T-81-12-BLESS-DEFECT | Tampering | high | mitigate | Lifeline artifacts have exact family cardinality, tracked-set validation, and compare-only evidence after the truth fix — E10, E12, E16 | closed |
| T-81-12-REPAIR-ARTIFACT | Information disclosure | critical | mitigate | Corrected stories persist no capability/reason/snapshot or false success; exact artifacts and confidentiality checks pass — E09, E10, E12 | closed |
| T-81-13-PARTIAL-CI | Repudiation | high | mitigate | One unfiltered full page-quality command is structurally required by `ci-gate` — E14 | closed |
| T-81-13-INVENTED-TRANSCRIPT | Repudiation | high | mitigate | Manifest discovery is exact; transcript assertions/attachments execute only through Guidepup VoiceOver — E15 | closed |
| T-81-14-STALE-LEDGER | Repudiation | high | mitigate | Nyquist flags were promoted only after exact fresh commands/counts; post-review evidence is recorded — E11, E12, E14, E16 | closed |
| T-81-14-UPDATE-AS-PROOF | Tampering | high | mitigate | Required commands prohibit update/watch/filter/ignored-failure modes and validators detect scope drift — E12, E14 | closed |
| T-81-15-INVENTORY-DRIFT | Tampering | high | mitigate | Elixir-owned schema-8 inventory is independently checked at 99 stories / 163 targets — E10, E11 | closed |
| T-81-15-ARTIFACT-EVASION | Tampering | high | mitigate | Exact filesystem and git-state validators reject missing, extra, untracked, renamed/copied, and unexpected files — E12 | closed |

*Status: open (blocking) · closed*
*Disposition: mitigate · accept · transfer*

## Accepted Risks Log

No Phase 81 plan-time threat is accepted or transferred.

## Unregistered Flags

| Flag | Classification | Evidence | Disposition |
|---|---|---|---|
| UF-81-01 | `unregistered_flag` — stale test contract, resolved | Commit `ad3ccaf` replaced the obsolete supported-command advertising with the exact `status`/`revoke`/`restore`/`drift`/`expire`/`duplicate` client controls, asserts every resulting state through the real endpoint, and separately proves `disconnect`/`interrupt`/`execute` are rejected locally with zero network calls. The fixture contract now uses an isolated run identity so its mutable controls cannot race the connected page suite. Fresh Playwright discovery found exactly 16 tests; the authoritative native launcher passed all 16 connected fixture plus production-page cases, and the enabled example-host fixture suite passed 5/5. | Resolved. Exact-schema rejection remains fail closed, and the fresh full Phase 81 connected regression is green. |
| UF-81-02 | `unregistered_flag` — pre-existing dependency advisories | The fresh host launcher reported current advisories in locked Bandit, hpax, Mint, Oban Web, Phoenix, Plug, Postgrex, and Req versions; `deferred-items.md` already routes these to the dependency-upgrade/security-review workflow. Phase 81 added no dependency. | Not accepted as Phase 81 risk and not counted in the plan-time register. Requires repository-level dependency remediation before release sign-off. |

## Post-Review Audit Trail

- Critical query-ordering and bounding fixes were verified in current source:
  failed Batch members are filtered before limiting (`b7c31f9`), workflow
  results choose the latest per step (`169bb5d`), Lifeline incidents are ordered
  before capping (`e461169`), and Audit evidence is filtered before bounding
  (`23d8b3b`).
- Fixture storage and connected stale-state corrections (`1632c5d`, `7971830`,
  `08c5a7f`, `213a9fe`) were incorporated into E08/E09.
- Unsupported Lifeline showcase outcomes were removed by `305ae84`; the
  drifted/expired/consumed story triplet is current and exact.
- The stale fixture-control contract was corrected by `ad3ccaf`; fresh
  two-file discovery remained exact at 16 tests, the authoritative native
  connected run passed 16/16 with two workers, and the enabled host fixture
  suite passed 5/5.
- No `## Threat Flags` section exists in any Phase 81 summary. The two
  unregistered observations above come from fresh audit execution and
  `deferred-items.md`, not from silently expanding or rewriting the plan-time
  register.

## Security Audit Trail

| Audit date | Threats total | Closed | Blocking open | Accepted | Run by |
|---|---:|---:|---:|---:|---|
| 2026-07-29 | 45 | 45 | 0 | 0 | Codex gsd-security-auditor |

## Sign-Off

- [x] All 45 plan-time threats have a disposition.
- [x] Every declared mitigation has direct source or executable-test evidence.
- [x] No accepted or transferred risk was used to close a threat.
- [x] `threats_open: 0` confirmed at `block_on: high`.
- [x] Two unregistered observations are explicitly recorded and not waived.

**Approval:** registered Phase 81 threat mitigations verified on 2026-07-29.
