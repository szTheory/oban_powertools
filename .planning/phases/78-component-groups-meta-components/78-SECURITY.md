---
phase: 78
slug: component-groups-meta-components
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: 2026-07-19
---

# Phase 78 — Security

> Verification of the plan-time ASVS L1 threat register against the shipped implementation and connected evidence.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller → presenter/component | Public component assigns and finite presentation maps cross into escaped HEEx | Operator labels, normalized evidence, destinations, state |
| Parent LiveView → component/client | Parent retains authorization, mutation, freshness, URL, and audit authority | Draft/applied filters, preview identity, result receipts, detail state |
| Test catalog → showcase/package | Deterministic support fixtures feed the connected showcase but must not ship in Hex | Redacted fixtures, story metadata, manifest targets |
| Browser → connected showcase | Client events activate one story and synchronize disclosure/dialog behavior | Story IDs, focus/history events, viewport/theme state |
| Source assets → packaged assets | Scoped CSS/JS is copied into the release boundary | Controller behavior and component styling |
| Phase diff → protected repository seams | Phase work may change only declared component/showcase/test paths | No dependency, migration, schema, auth, route, or production-page expansion |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-78-ATTR | Tampering / elevation | Public component API | mitigate | Closed attrs/maps and render/source tests reject semantic, visual, and action escape hatches. | closed |
| T-78-XSS | Injection | HEEx rendering | mitigate | Hostile HTML/Unicode fixtures remain escaped; no raw HTML or raw-error rendering exists. | closed |
| T-78-LEAK | Information disclosure | DOM and fixture channels | mitigate | Full-DOM sentinel tests cover text, attrs, disclosure, destinations, tokens, hashes, and reasons. | closed |
| T-78-AUTH | Spoofing / tampering | Connected parent authority | mitigate | Parent revalidates authorization, reason/count/scope, freshness, and single-use before execution. | closed |
| T-78-REPLAY | Tampering | Lifeline execution | mitigate | Real expired, drifted, and consumed previews reject; connected tests require explicit refresh and one receipt. | closed |
| T-78-FOCUS | Denial of service / accessibility | Dialog/disclosure lifecycle | mitigate | Connected tests cover containment, Escape, restore/fallback, wide no-trap, and no stacked dialogs. | closed |
| T-78-HOST | Supply/host boundary | Host integration | mitigate | Scoped/idempotent controllers require no host hook, storage, logging, or production catalog. | closed |
| T-78-02-ATOM | Denial of service | Presenter normalization | mitigate | Finite string keys and compile-time atoms are source/test guarded; no runtime atom creation was added. | closed |
| T-78-02-XSS | Injection | Presenter/component copy | mitigate | Presentation copy uses escaped HEEx and excludes arbitrary attrs/raw HTML. | closed |
| T-78-02-LEAK | Information disclosure | Presenter evidence | mitigate | Audit evidence now projects through an explicit presentation allowlist; secret-like/arbitrary maps are rejected. | closed |
| T-78-02-TRUTH | Spoofing | Status/completeness copy | mitigate | Unknown remains unknown; current/snapshot, status/severity, and audit/current truth stay distinct. | closed |
| T-78-02-ACTION | Elevation of privilege | Action slots | mitigate | Slots are constrained presentation only; permission and mutation authority remain parent-owned. | closed |
| T-78-02-SUPPLY | Tampering | Assets/dependencies | mitigate | Repeat-build asset equality passes and no dependency/schema/package boundary changed. | closed |
| T-78-03-URL | Tampering | Filter state/history | mitigate | Parent parses stable domain values and owns canonical patch/replace destinations. | closed |
| T-78-03-AUTH | Elevation of privilege | FilterBar | mitigate | Component only renders constrained fields/actions; filtering and authorization remain server-owned. | closed |
| T-78-03-XSS | Injection | Filter copy/errors | mitigate | Labels, values, summaries, and errors are escaped; caller HTML/attrs are not projected. | closed |
| T-78-03-LEAK | Information disclosure | Filter controller | mitigate | Controller stores/logs no query/results; display values and canonical destinations are normalized. | closed |
| T-78-03-FOCUS | Denial of service / accessibility | Filter disclosure | mitigate | One-tree disclosure synchronizes expanded/controlled/hidden/tab state in connected browser tests. | closed |
| T-78-03-HOST | Tampering | Filter controller | mitigate | Nearest-root scoped idempotent behavior has no host hook map or global state dependency. | closed |
| T-78-04-AUTH | Spoofing / elevation | Confirmation parent | mitigate | Parent authorizes preview/execution and revalidates reason, exact count, scope, and current authority. | closed |
| T-78-04-REPLAY | Tampering | Confirmation execution | mitigate | Expiry, drift, consumed, and single-use failures stay open for explicit fresh preview. | closed |
| T-78-04-DUP | Tampering | Confirmation submission | mitigate | Submitting is non-dismissible/disabled and connected call-count tests prove one accepted transition. | closed |
| T-78-04-XSS | Injection | Confirmation results/copy | mitigate | Complete copy/results render escaped; hostile values and raw-error absence are tested. | closed |
| T-78-04-LEAK | Information disclosure | Confirmation DOM/logs | mitigate | Tokens, hashes, raw reasons/errors, and secrets are absent from DOM, attrs, and logs. | closed |
| T-78-04-TRUTH | Spoofing | Confirmation receipt | mitigate | Copy distinguishes requested/recorded work from completion and preserves finite partial/failed/skipped/stale outcomes. | closed |
| T-78-04-FOCUS | Denial of service / accessibility | Confirmation focus | mitigate | FocusWrap, initial/result focus, Escape, submitting lock, and invoker/fallback restore execute live. | closed |
| T-78-05-AUTH | Elevation of privilege | Detail parent | mitigate | Parent owns selection, fetch, authorization, redaction, routes, and actions; client never loads/authorizes data. | closed |
| T-78-05-LEAK | Information disclosure | Detail DOM | mitigate | One tree plus normalized body/evidence and DOM sentinels prevents hidden sensitive duplicates. | closed |
| T-78-05-XSS | Injection | Detail content | mitigate | Title/state/body copy is escaped; slots are constrained and no raw HTML/eval/unsafe attrs exist. | closed |
| T-78-05-FOCUS | Denial of service / accessibility | Adaptive detail | mitigate | Native constrained modality, wide modeless mode, resize close-before-reopen, Escape, and restore are tested. | closed |
| T-78-05-STATE | Tampering | Detail requested/open state | mitigate | Parent requested state/URL remains authoritative and native cancel synchronizes back to the parent. | closed |
| T-78-05-HOST | Tampering | Detail controller | mitigate | Fixed nearest-root selectors and idempotent synchronization avoid host hooks, globals, storage, and polyfills. | closed |
| T-78-05-NEST | Denial of service | Overlay composition | mitigate | Source/harness/browser contracts prohibit nested dialogs and close detail before confirmation. | closed |
| T-78-06-FIXTURE | Information disclosure | Story catalog | mitigate | Fixtures are deterministic, normalized, sentinel-tested, and excluded from Hex. | closed |
| T-78-06-PACKAGE | Tampering / disclosure | Optional loader/package | mitigate | Loader validates list shape/fails closed in child VMs; package tests prove support source absent. | closed |
| T-78-06-ACTIVATE | Denial of service / accessibility | Showcase activation | mitigate | Initial overlays are closed; validated one-ID activation and fresh pages enforce at most one overlay. | closed |
| T-78-06-MANIFEST | Tampering | Schema-6 manifest | mitigate | Elixir owns order/IDs and independent TS/Node validators enforce activation, duplicates, and exact counts. | closed |
| T-78-06-XSS | Injection | Showcase fixtures | mitigate | Catalog copy renders through escaped components; hostile fixtures and DOM sentinels pass. | closed |
| T-78-06-AUTH | Elevation of privilege | Showcase parent | mitigate | Showcase models deterministic test interaction only and adds no production authorization/mutation ability. | closed |
| T-78-06-SUPPLY | Tampering | Generated/test support | mitigate | No dependency/lock/script change; catalog stays test support and manifest remains derived/ignored. | closed |
| T-78-07-AUTH | Spoofing / elevation | Connected behavior | mitigate | Invalid/valid/stale/permission transitions prove server authority rather than client affordances. | closed |
| T-78-07-REPLAY | Tampering | Connected execution | mitigate | Duplicate and stale/fresh-preview cases assert exact call/result/receipt cardinality. | closed |
| T-78-07-LEAK | Information disclosure | Browser DOM | mitigate | Browser scans all rendered channels, details, URLs, and copy for secret/token/hash/raw-error sentinels. | closed |
| T-78-07-FOCUS | Denial of service / accessibility | Browser interaction | mitigate | Real focus/inertness/resize/restore/no-wide-trap/nested-dialog contracts pass. | closed |
| T-78-07-ZOOM | Denial of service / accessibility | 200% reflow | mitigate | Five connected cases assert scale, reflow, wrapping, in-bounds focus, one tree, and no ordinary overflow. | closed |
| T-78-07-TRUTH | Spoofing | Browser copy/cardinality | mitigate | Exact assertions reject false receipts, inferred causality, hidden missing audit fields, and duplicate announcements. | closed |
| T-78-07-URL | Tampering | Browser history | mitigate | Connected push/replace/Back/direct tests retain canonical parent-owned filter/detail history. | closed |
| T-78-08-VISUAL | Spoofing | VRT/axe matrix | mitigate | All 276 cases execute in Docker; 120 overlays capture exact roots and assert headings/required controls. | closed |
| T-78-08-SCOPE | Tampering | Screenshot inventory | mitigate | Manifest-derived verification reports exactly 276 and rejects non-group changed paths; final overlay scope is 120/120. | closed |
| T-78-08-FOCUS | Denial of service / accessibility | Final connected gate | mitigate | Behavior/structure precede axe/VRT; screenshots never substitute for focus/history/modality evidence. | closed |
| T-78-08-ZOOM | Denial of service / accessibility | Final zoom gate | mitigate | The exact five connected zoom cases pass; broader manual sweep remains explicitly Phase 82. | closed |
| T-78-08-SUPPLY | Tampering | Package/protected diff | mitigate | Asset equality, package fallback/Hex exclusion, unchanged locks, and cumulative/worktree audits pass. | closed |
| T-78-08-LEAK | Information disclosure | Final regression gate | mitigate | Focused component/connected/browser/package tests retain secret/token/hash/raw-error absence. | closed |
| T-78-08-CLAIM | Spoofing | Evidence reporting | mitigate | VALIDATION/VERIFICATION record exact results and preserve unrelated residual/manual boundaries without aggregate overclaim. | closed |

*Status: open · closed*  
*Disposition: mitigate · accept · transfer*

---

## Accepted Risks Log

No accepted Phase 78 risks. Existing dependency advisories and three repository-wide host-lane test residuals are unchanged, explicitly out of this phase's protected scope, and are not treated as Phase 78 mitigations or aggregate-green evidence.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-19 | 54 | 54 | 0 | Codex (gsd-secure-phase) |

---

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks log reviewed; no Phase 78 accepted risk is required.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-07-19
