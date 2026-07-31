---
phase: 79
slug: page-migration-wave-1-overview-cron-limiters-audit
status: verified
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: 2026-07-23
audited: 2026-07-24
---

# Phase 79 — Security

> Retroactive ASVS L1 verification of the 72 high-severity threats declared in the twelve Phase 79 plans. The audit verifies declared mitigations only; it does not expand the threat register.

---

## Scope and Method

- Register source: `79-01-PLAN.md` through `79-12-PLAN.md` (72 threats, all high, all `mitigate`).
- Implementation scope: the four migrated LiveViews and their read models/presenters, shared operator patterns and CSS, the page-story catalog/showcase, manifest/browser support, test-only browser fixtures, package guards, and Phase 79 verification artifacts.
- Verification level: ASVS L1. Because `block_on: high`, any open registered threat blocks security approval.
- Evidence method: source tracing to concrete enforcement points, targeted ExUnit execution, independent manifest/baseline verification, asset equality, and direct adversarial probes for confidentiality, overlay, and recovery-state claims.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser/session → LiveView | Authenticated page mounts and fixed LiveView events cross into server-owned authorization, selection, and mutation logic | Actor, filters, resource/event identifiers, reason text, preview lifecycle |
| LiveView → repository/read model | Server-normalized values cross into bounded Ecto queries and finite read models | Audit filters and IDs, Cron entries, limiter resources/state, Overview exemplars |
| Audit schema → presenter → DOM | Persisted audit data crosses normalization and display policy before escaped HEEx output | Event fields, changes/evidence, timestamps, destinations |
| Test client → fixture controller → test database | A per-run secret and closed request vocabulary authorize deterministic mutation of an exact isolated test database | Project, actor, run tag, recovery mode, public fixture response |
| Test catalog → showcase/manifest/browser | Deterministic support fixtures become rendered page stories and closed browser metadata | Story IDs, activation kind, selectors, themes, viewports |
| Source assets → packaged assets/Hex | Scoped CSS and runtime assets cross the package boundary; test support must not | CSS/JS bytes, package file list, local-only catalogs and fixtures |

---

## Threat Register

| Threat ID | Category | Severity | Disposition | Verified mitigation / evidence | Status |
|-----------|----------|----------|-------------|--------------------------------|--------|
| T-79-01-AUTH | Access control | high | mitigate | Page gates remain server-owned (`engine_overview_live.ex:13-18`, `cron_live.ex:16-21`, `limiters_live.ex:26-31`, `audit_live.ex:25-30`); Cron reauthorizes with the current principal at execution (`cron_live.ex:107-108`). | closed |
| T-79-01-REPLAY | Business logic | high | mitigate | Cron retains explicit fresh-preview recovery and server-side durable execution (`cron_live.ex:87-131`, `cron_live.ex:635-651`); targeted replay/duplicate contracts pass. | closed |
| T-79-01-INJECT | Injection | high | mitigate | Events use fixed names and finite presenters, while output remains escaped HEEx (`audit_live.ex:48-71`, `cron_live.ex:58-131`, `control_plane_presenter.ex:112-322`). | closed |
| T-79-01-LEAK | Data protection | high | mitigate | The final presenter boundary recursively removes evidence entries whose `field` or `label` normalizes to a sensitive identifier while preserving safe siblings (`control_plane_presenter.ex:991-1022`); presenter and connected Audit DOM regressions cover password, access token, API key, plan hash, and credential aliases (`operator_pattern_presenter_test.exs:243-280`, `audit_live_test.exs:222-288`). | closed |
| T-79-01-SCOPE | Access control | high | mitigate | Selection is resolved by the same active filters and ID in one query, returning one indistinguishable error (`audit.ex:140-154`, `audit_live.ex:528-532`). | closed |
| T-79-01-DOS | Availability | high | mitigate | Audit uses a fixed 20-row SQL page and Overview takes at most three bridge rows (`audit.ex:13`, `audit.ex:107-132`, `overview_read_model.ex:209-220`). | closed |
| T-79-01-A11Y | Accessibility | high | mitigate | Migrated pages retain one H1 and semantic table/detail/dialog structures (`engine_overview_live.ex:33-123`, `limiters_live.ex:118-295`, `audit_live.ex:117-282`, `operator_patterns.ex:300-427`). | closed |
| T-79-02-INJECT | Injection | high | mitigate | Presenter outputs are finite maps and components render escaped values without a raw-HTML path (`control_plane_presenter.ex:112-322`, `operator_patterns.ex:706-978`). | closed |
| T-79-02-LEAK | Data protection | high | mitigate | Structural allowlisting now composes with semantic `field`/`label` classification at the final presenter boundary; sensitive entries are removed before component serialization and safe allowlisted siblings remain (`control_plane_presenter.ex:991-1022`, `operator_pattern_presenter_test.exs:243-280`). | closed |
| T-79-02-SCOPE | Access control | high | mitigate | Retrieval and count share the exact normalized filter query; presentation maps do not decide authority (`audit.ex:107-154`, `audit.ex:272-304`, `audit_live.ex:288-307`). | closed |
| T-79-02-DOS | Availability | high | mitigate | Page size is fixed at 20 with exact count, page clamp, stable offset, and stable ordering (`audit.ex:13`, `audit.ex:107-132`, `audit.ex:272-276`). | closed |
| T-79-02-TRUTH | Business logic | high | mitigate | Finite Audit detail/result copy preserves neutral historical evidence and explicit timestamps (`control_plane_presenter.ex:261-322`, `operator_patterns.ex:706-978`). | closed |
| T-79-02-COMPAT | API integrity | high | mitigate | Existing Audit and operator-pattern callers compile and the focused compatibility suite passes: 151 tests, 0 failures; no schema or public Cron contract changed. | closed |
| T-79-03-AUTH | Access control | high | mitigate | Overview mount requires page authorization and exposes no mutation event (`engine_overview_live.ex:13-18`, `engine_overview_live.ex:33-123`). | closed |
| T-79-03-LEAK | Data protection | high | mitigate | Overview renders finite buckets/exemplars from bounded read-model output, not raw schemas or metadata (`overview_read_model.ex:19-182`, `control_plane_presenter.ex:112-260`). | closed |
| T-79-03-DOS | Availability | high | mitigate | The read model captures one `now`, bounds Audit support retrieval, and caps representative bridge rows (`overview_read_model.ex:17-34`, `overview_read_model.ex:209-220`). | closed |
| T-79-03-TRUTH | Business logic | high | mitigate | Six explicit buckets, representative bridge rows, and empty-evidence states keep continuity distinct from completeness (`overview_read_model.ex:58-220`). | closed |
| T-79-03-XSS | Injection | high | mitigate | Exemplars cross finite presenter maps into ordinary escaped HEEx with no raw rendering (`engine_overview_live.ex:178-199`, `control_plane_presenter.ex:112-260`). | closed |
| T-79-03-A11Y | Accessibility | high | mitigate | One H1, fixed six-region DOM order, named navigation, and a single responsive tree are present (`engine_overview_live.ex:33-123`, `tokens.css:3689-3949`). | closed |
| T-79-04-AUTH | Access control | high | mitigate | Cron authorizes before preview and again immediately before execution using the current principal (`cron_live.ex:107-108`, `cron_live.ex:377-410`). | closed |
| T-79-04-REPLAY | Business logic | high | mitigate | Expired/drifted/consumed/single-use failures retain explicit recovery rather than silent refresh (`cron_live.ex:87-131`, `cron_live.ex:460-489`, `cron_live.ex:635-651`). | closed |
| T-79-04-CSRF | Request integrity | high | mitigate | Mutations remain fixed LiveView server events within the existing session boundary; no GET mutation/action URL was introduced (`cron_live.ex:58-131`, `cron_live.ex:694-696`). | closed |
| T-79-04-INJECT | Injection | high | mitigate | Reason input is trimmed/nonblank and action identity comes from server preview state, not arbitrary client action parameters (`cron_live.ex:505-508`, `cron_live.ex:635-651`, `cron_live.ex:694-696`). | closed |
| T-79-04-LEAK | Data protection | high | mitigate | Preview token/hash/principal remain in server assigns/commands, while the page receives finite presenter data and escaped reason copy (`cron_live.ex:460-508`, `cron_live.ex:635-651`). | closed |
| T-79-04-DUP | Business logic | high | mitigate | Confirmation submission has a submitting state/disabled controls while durable execution remains single-use (`operator_patterns.ex:47-259`, `cron_live.ex:87-118`). | closed |
| T-79-04-A11Y | Accessibility | high | mitigate | One confirmation dialog implements labelled states, focus wrapping, Escape rules, result focus, and 44px responsive actions (`operator_patterns.ex:47-259`, `tokens.css:3902-3949`). | closed |
| T-79-05-AUTH | Access control | high | mitigate | Limiter page auth and Forensics visibility remain server-side; event selection itself grants no authority (`limiters_live.ex:26-31`, `limiters_live.ex:52-72`, `limiters_live.ex:641-645`). | closed |
| T-79-05-LEAK | Data protection | high | mitigate | Current evidence is projected into bounded finite maps; snapshot/history are separate structures (`limiters_live.ex:416-480`, `limiters_live.ex:536-563`). | closed |
| T-79-05-IDOR | Access control | high | mitigate | Requested resource identity is resolved against the loaded resource index before detail queries or destinations (`limiters_live.ex:354-399`). | closed |
| T-79-05-DOS | Availability | high | mitigate | Resource/State reads are grouped, detail history is bounded, and current blockers are capped (`limiters_live.ex:303-341`, `limiters_live.ex:444-480`, `limiters_live.ex:536-563`). | closed |
| T-79-05-TRUTH | Business logic | high | mitigate | Runnable is emitted only for complete-empty current evidence; incomplete/current/snapshot/history states stay distinct (`limiters_live.ex:416-480`). | closed |
| T-79-05-XSS | Injection | high | mitigate | Consumer copy is rendered through finite presenter/component fields and escaped HEEx (`limiters_live.ex:178-295`, `control_plane_presenter.ex:112-260`). | closed |
| T-79-05-A11Y | Accessibility | high | mitigate | Native table, resource-specific action labels, ordered current/snapshot/history/destination sections, and one adaptive detail tree remain (`limiters_live.ex:118-295`). | closed |
| T-79-06-AUTH | Access control | high | mitigate | Audit page auth is server-side, selection is scope-resolved, and only read-only filter/select/close events exist (`audit_live.ex:25-30`, `audit_live.ex:48-71`, `audit_live.ex:528-532`). | closed |
| T-79-06-IDOR | Access control | high | mitigate | `fetch_in_scope/3` combines normalized filters and ID in one query and returns `:error` for malformed, absent, or mismatched IDs (`audit.ex:140-154`). | closed |
| T-79-06-INJECT | Injection | high | mitigate | Filter values are Ecto parameters and presentation remains finite/escaped; no raw query grammar or runtime atom creation was added (`audit.ex:272-304`, `audit_live.ex:277-307`). | closed |
| T-79-06-LEAK | Data protection | high | mitigate | Audit normalization remains bounded, and the final presenter now rejects semantic secret-bearing change/evidence entries before `AuditEntry` can serialize them; the connected selected-detail test proves synthetic secret values are absent while safe queue evidence renders (`control_plane_presenter.ex:991-1022`, `audit_live_test.exs:222-288`). | closed |
| T-79-06-DOS | Availability | high | mitigate | SQL paging is fixed at 20 with exact count and one selected lookup; the LiveView has no stream, infinite scroll, or refresh event (`audit.ex:107-154`, `audit_live.ex:48-71`). | closed |
| T-79-06-TRUTH | Business logic | high | mitigate | Detail copy uses immutable past tense, “Recorded at,” neutral outcome, and no inferred current-state/causality fields (`control_plane_presenter.ex:261-322`, `operator_patterns.ex:706-978`). | closed |
| T-79-06-A11Y | Accessibility | high | mitigate | The page retains native table/filter/pagination semantics and one labelled adaptive detail tree (`audit_live.ex:117-282`, `operator_patterns.ex:300-427`). | closed |
| T-79-07-HOST | Security configuration | high | mitigate | Phase page rules are scoped below `.obpt-root`; themes remain token-owned and packaged JavaScript is unchanged (`tokens.css:1-149`, `tokens.css:3689-3949`). | closed |
| T-79-07-SUPPLY | Supply chain | high | mitigate | Source and packaged CSS are byte-equal; no dependency addition was introduced. Equality was independently rechecked with `cmp -s`. | closed |
| T-79-07-A11Y | Accessibility | high | mitigate | Page CSS supplies wrapping, visible focus, high-contrast tokens, 320px reflow, and reduced-motion overrides in one tree (`tokens.css:233-260`, `tokens.css:3689-3949`). | closed |
| T-79-08-AUTH | Access control | high | mitigate | Connected page contracts and source retain page/resource/action authorization, scoped Audit lookup, and Cron confirm-time current-principal checks (`cron_live.ex:107-108`, `audit.ex:140-154`, `limiters_live.ex:354-399`). | closed |
| T-79-08-REPLAY | Business logic | high | mitigate | Expired/drifted/consumed/single-use/duplicate paths are covered by the focused ExUnit contracts, which pass; this threat does not claim skipped/partial browser distinctness. | closed |
| T-79-08-INJECT | Injection | high | mitigate | Hostile strings remain escaped across finite page presenters/components; catalog tests reject forbidden raw/error fields (`page_story_catalog_test.exs:56-66`, `page_story_catalog_test.exs:180-211`). | closed |
| T-79-08-LEAK | Data protection | high | mitigate | The adversarial semantic fixtures for password, `accessToken`, `APIKey`, `plan_hash`, and credential aliases are absent from complete connected Audit HTML, while safe sibling evidence remains; the real connected Chromium confidentiality suite also passes (`audit_live_test.exs:222-288`, `page-migration-wave-1.spec.ts:778`). | closed |
| T-79-08-DOS | Availability | high | mitigate | Bounded queries/DOM and exact baseline inventory are independently verified: 228 expected PNGs pass `verify-page-baselines.mjs` (`audit.ex:107-154`, `overview_read_model.ex:209-220`). | closed |
| T-79-08-FOCUS | Accessibility | high | mitigate | Shared dialog/detail patterns implement focus containment/restore and CSS supplies focus/reflow/reduced-motion behavior (`operator_patterns.ex:47-427`, `tokens.css:3850-3949`). | closed |
| T-79-08-SUPPLY | Supply chain | high | mitigate | CSS source/package bytes match, manifest smoke validates schema 7/83 targets, all 228 PNGs verify, and page support is package-excluded (`hex_release_test.exs:190-217`). | closed |
| T-79-09-AUTH | Access control | high | mitigate | Explicit actor fixture modes feed server-owned page/action authorization; Cron still authorizes both preview and execution (`phase79_browser_fixtures.ex:14-17`, `cron_live.ex:107-108`, `cron_live.ex:377-410`). | closed |
| T-79-09-REPLAY | Business logic | high | mitigate | The fixture exposes four truthful backend conditions only; nominal `partial` fails closed, while a real skipped slot claim is explicitly asserted as the UI's `:partial` recovery container with no success receipt (`phase79_browser_fixtures.ex:14-16,62-75,363-383`, `phase79_browser_fixtures_test.exs:138-204`, `phase79-fixtures.spec.ts:13-24,94-129`). | closed |
| T-79-09-INJECT | Injection | high | mitigate | Fixture values use closed vocabularies/run regex; catalog fields are normalized and rendered by escaped HEEx (`phase79_browser_fixtures.ex:14-17`, `page_story_catalog_test.exs:180-211`). | closed |
| T-79-09-LEAK | Data protection | high | mitigate | Browser/catalog fixtures exclude forbidden authority/secret/error fields and catalog source is package-excluded (`page_story_catalog_test.exs:56-66`, `page_story_catalog_test.exs:180-211`, `hex_release_test.exs:190-217`). | closed |
| T-79-09-DOS | Availability | high | mitigate | Browser scope is exactly 228 baselines; page queries/exemplars remain bounded and activation asserts a single rendered page target (`showcase.ts:106-112`, `audit.ex:107-132`, `overview_read_model.ex:209-220`). | closed |
| T-79-09-A11Y | Accessibility | high | mitigate | Connected helpers assert overlay bounds and the shared patterns/CSS retain keyboard, focus, wide/320px, target, and reduced-motion contracts (`showcase.ts:126-153`, `operator_patterns.ex:47-427`, `tokens.css:3850-3949`). | closed |
| T-79-09-SUPPLY | Supply chain | high | mitigate | Independent manifest validation enforces exact IDs/order/count and baseline verifier enforces the exact 228 page PNG inventory (`showcase_manifest.exs:179-199`, `manifest-smoke.mjs:356-539`). | closed |
| T-79-10-AUTH | Access control | high | mitigate | Fixture routes exist only in the test route block, accept explicit closed actors, require constant-time per-request secret verification, and return the same empty 404 on denial (`router.ex:36-44`, `phase79_browser_fixtures.ex:449-508`). | closed |
| T-79-10-INJECT | Injection | high | mitigate | Project/actor/recovery allowlists and anchored run regex reject arbitrary inputs; response maps are closed scalars (`phase79_browser_fixtures.ex:14-17`, `phase79_browser_fixtures.ex:62-81`). | closed |
| T-79-10-LEAK | Data protection | high | mitigate | Docker forwards the secret by name only; the controller returns public fields and performs constant-time comparison without echoing secret/backend identities (`playwright-docker.sh:13-15`, `phase79_browser_fixtures.ex:419-425`, `phase79_browser_fixtures.ex:449-508`). | closed |
| T-79-10-DATA | Data integrity | high | mitigate | Reset/recovery use transactions and cleanup is limited to exact run-tag-derived entry/resource names (`phase79_browser_fixtures.ex:21-35`, `phase79_browser_fixtures.ex:108-146`). | closed |
| T-79-10-DB | Security configuration | high | mitigate | Harness validates an exact phase-specific test database name before create/drop, runs `MIX_ENV=test`, and removes only a validated phase build path (`with-showcase-server.sh:13-38`, `with-showcase-server.sh:51-113`). | closed |
| T-79-10-REPLAY | Business logic | high | mitigate | Recovery names now map one-to-one to real perturbations; `"partial"` is outside the closed request vocabulary and receives the same empty 404 as invalid fixture requests, while `"skipped"` creates exactly one active job and drives the recoverable partial-result UI (`phase79_browser_fixtures.ex:14-16,62-75,363-383`, `phase79_browser_fixtures_test.exs:172-204`). | closed |
| T-79-10-SUPPLY | Supply chain | high | mitigate | Fixture support remains under example-host test paths, routes are test-only, catalogs are excluded from Hex, and no dependency/lock/package expansion occurred (`router.ex:36-44`, `hex_release_test.exs:190-217`). | closed |
| T-79-11-INJECT | Injection | high | mitigate | Catalog fields and fixtures are closed, normalized deterministic data with forbidden authority/error markers rejected; page output remains escaped HEEx (`page_story_catalog_test.exs:35-89`, `page_story_catalog_test.exs:180-211`). | closed |
| T-79-11-LEAK | Data protection | high | mitigate | Catalog tests reject secrets/authority and Hex tests prove page catalog support is local-only and absent from production modules/package files (`page_story_catalog_test.exs:180-211`, `hex_release_test.exs:190-217`). | closed |
| T-79-11-OVERLAY | UI integrity | high | mitigate | Valid page activation atomically clears group overlay and transient state; valid group activation clears the active page story. Connected group→page→group regression proves exactly one active surface, and browser support no longer repairs server state (`showcase_live.ex:158-172,1694-1725`, `showcase_live_test.exs:737-755`, `showcase.ts:88-150`). | closed |
| T-79-11-SUPPLY | Supply chain | high | mitigate | Showcase page catalog loading is optional/validated and package tests prove catalog support is excluded with no production-page dependency (`showcase_live.ex:791-897`, `hex_release_test.exs:190-217`). | closed |
| T-79-12-INJECT | Injection | high | mitigate | Elixir emits a closed manifest and independent TS/Node validators enforce exact keys, finite activation, types, order, and counts (`showcase_manifest.exs:134-199`, `manifest.ts:121-303`, `manifest-smoke.mjs:356-539`). | closed |
| T-79-12-LEAK | Data protection | high | mitigate | Manifest page targets contain metadata/selectors/activation only; fixture payloads remain in the local catalog and forbidden fields are rejected (`showcase_manifest.exs:134-199`, `page_story_catalog_test.exs:56-66`). | closed |
| T-79-12-OVERLAY | UI integrity | high | mitigate | Closed page/group activation is enforced server-side in both directions, including group transient-state reset. The unmasked helper asserts the global overlay bound, and all four connected Showcase structure theme runs pass (`showcase_live.ex:158-172,1694-1725`, `showcase_live_test.exs:737-755`, `showcase.ts:88-150`). | closed |
| T-79-12-SUPPLY | Supply chain | high | mitigate | Manifest is source-derived, independently validated as schema 7 with 83 targets, and repeated smoke/baseline checks are byte-stable; no dependency was added (`showcase_manifest.exs:179-199`, `manifest-smoke.mjs:356-539`). | closed |

*Status: open (blocking) · closed*  
*Disposition: mitigate · accept · transfer*

---

## Closure Verification

The eight findings from the initial audit were resolved through implementation and regression coverage; none were accepted or transferred.

| Threats closed | Mitigation | Fresh verification |
|----------------|------------|--------------------|
| T-79-01-LEAK, T-79-02-LEAK, T-79-06-LEAK, T-79-08-LEAK | Shape-aware semantic redaction at the final presenter boundary removes secret-bearing entries before DOM serialization. | Presenter regression and connected AuditLive DOM regression pass for password, `accessToken`, `APIKey`, `plan_hash`, and credential aliases while retaining safe queue evidence. |
| T-79-09-REPLAY, T-79-10-REPLAY | The fixture vocabulary was collapsed to four real backend conditions; nominal `partial` fails closed and skipped truthfully owns the partial-result UI container. | Six host-fixture tests pass; the real Chromium recovery test passes all four current-run conditions with no success receipt. |
| T-79-11-OVERLAY, T-79-12-OVERLAY | Server activation atomically replaces the opposite surface and resets group transient state; browser support no longer closes overlays before activation. | Connected LiveView group→page→group regression passes; all four Chromium-wide Showcase structure theme runs pass without state repair. |

## Accepted Risks Log

No Phase 79 risks were accepted or transferred.

## Verification Evidence

| Check | Result |
|-------|--------|
| Targeted presenter, AuditLive, and ShowcaseLive regressions | 60 tests, 0 failures (`--seed 0`) |
| Isolated Phase 79 host-fixture contract | 6 tests, 0 failures (`--force --seed 0`) |
| Full root regression (`--exclude host_contract`) | 850 tests, 0 failures, 7 excluded (`--seed 0`) |
| Connected host Chromium-wide page, fixture, and Showcase structure suites | 23 tests, 0 failures across all four Showcase themes |
| Playwright discovery after TypeScript contract changes | 69 tests in 3 files |
| `node test/browser/support/manifest-smoke.mjs` | Schema 7; 19 page stories; 83 targets; 4 themes; 3 viewports |
| `node test/browser/support/verify-page-baselines.mjs` | `page baselines ok: 228` |
| Source/package CSS equality | Byte-equal (`cmp -s`) |
| Direct Audit semantic-confidentiality regressions | All synthetic semantic secret values removed; safe sibling evidence preserved |
| Formatting and whitespace | `mix format --check-formatted` and `git diff --check` pass |

Docker was unavailable at the configured local socket, so the same generated fixture server and browser suites were executed through the repository's host-browser path instead; all 23 selected connected tests passed.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Accepted | Run By |
|------------|---------------|--------|------|----------|--------|
| 2026-07-23 | 72 | 64 | 8 | 0 | Codex (`gsd-security-auditor`) |
| 2026-07-24 | 72 | 72 | 0 | 0 | Codex (mitigation verification) |

---

## Sign-Off

- [x] All 72 registered threats have a disposition.
- [x] All findings map to declared Phase 79 threats; no new threat was added.
- [x] Accepted-risks log reviewed; no risk was accepted or transferred.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified on 2026-07-24.
