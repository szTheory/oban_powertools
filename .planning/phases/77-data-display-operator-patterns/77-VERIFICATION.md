---
phase: 77-data-display-operator-patterns
verified: 2026-07-13T00:40:36Z
status: gaps_found
score: "14/16 must-haves verified"
behavior_unverified: 0
overrides_applied: 0
next_action: "Create and execute a focused Phase 77 gap-closure plan for Phoenix flash normalization/per-item dismissal and nil progress semantics, then re-run verification."
next_command: "/gsd-plan-phase 77 --gaps"
---

# Phase 77: Data-Display & Operator Patterns Verification Report

**Phase Goal:** Build shared data-display components and unify the status taxonomy.
**Verified:** 2026-07-13T00:40:36Z
**Status:** gaps_found
**Re-verification:** No - initial verification

## Goal Achievement

Phase 77 is substantially implemented. The shared component module, closed status taxonomy, one-DOM responsive table, normalized redaction path, deterministic showcase catalog, schema-5 manifest, browser behavior suite, and exact 120-screenshot data matrix are present and exercised. The focused 60-test ExUnit suite, warning-clean compile, manifest smoke, CSS source/package equality, baseline equality, and browser discovery all pass.

Two code-review warnings are nevertheless reproducible production defects and violate explicit Phase 77 contracts. A normal string-keyed Phoenix `@flash` map loses tone/urgency, creates duplicate ids, and cannot use the default LiveView event for per-item dismissal. An omitted progress value is rendered as measured `0/100` and `0%` rather than unknown/unavailable. Because these are failures of the shared Toast/Flash and ProgressBar components named in the phase goal and must-haves, neither can be deferred as page-migration work.

The continued presence of page-local badge helpers is not a Phase 77 gap. `77-UI-SPEC.md` explicitly places migration of the nine page bodies out of scope, and Roadmap Phases 79-81 own that adoption. Phase 77's DATA-02 boundary is the shared exhaustive taxonomy and StatusPill API; page migration is not silently claimed here.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The complete shared DataDisplay API ships as Phoenix function components. | VERIFIED | `data_display.ex` exports all 14 planned components; focused render tests pass. |
| 2 | One pure domain-aware taxonomy covers every approved/source-audited status without dynamic atom creation. | VERIFIED | `StatusTaxonomy.spec/2` and `all_specs/0` are string-keyed; 122 audit entries are deterministic; taxonomy tests and source scan pass. |
| 3 | Shared StatusPill delegates taxonomy specs to the Phase 74 primitive and suppresses semantic/action overrides. | VERIFIED | `status_pill/1` calls `StatusTaxonomy.spec/2` and `Primitives.status_pill/1`; hostile-rest render tests pass. |
| 4 | DataTable renders one semantic table DOM with stable rows and parent-owned sorting. | VERIFIED | Component source uses one `table`; active `th` alone owns `aria-sort`; LiveView and recorded browser behavior exercise click/Enter/Space sorting. |
| 5 | The same table DOM reflows at 320px with visible labels, named selection, 44px targets, and no page overflow. | VERIFIED | Root-scoped 24rem CSS, focused static tests, browser contract, and validation evidence cover the one-DOM mobile path. |
| 6 | Table, DescriptionList, and Timeline expose explicit ready/loading/empty/error/unavailable/permission-denied states. | VERIFIED | Shared `state_message/1`, native owning regions, component tests, axe evidence, and state stories are green. |
| 7 | DescriptionList, KeyValue, and Timeline preserve native `dl/dt/dd` and ordered-list semantics. | VERIFIED | Actual HEEx and render tests prove one `dl` model and ordered event log with escaped details. |
| 8 | ProgressBar is determinate only when a real value exists; unknown/unavailable progress never claims a fake percentage. | GAP | `value` defaults to `nil`, but `clamp_progress(nil, _max)` returns `0`; direct render probe emits `<progress value="0">`, `0/100`, and `0%`. This contradicts Plan 04 and the approved UI-SPEC. |
| 9 | Machine values preserve useful ends and provide explicit non-sensitive expansion without title-only disclosure. | VERIFIED | Kind-aware truncation/details implementation and render/browser tests pass. |
| 10 | ArgsViewer accepts normalized DisplayPolicy tuples/maps through one shared confidentiality-safe dispatcher. | VERIFIED | Tuple/map clauses preserve false availability, omit redacted payload access, and pass the whole-HTML sentinel matrix. |
| 11 | CodeBlock is labelled, escaped, focusable, bounded, and is the only new internally scrolling data surface. | VERIFIED | Native figure/figcaption/pre/code markup, scoped CSS, source guards, and browser overflow/focus assertions pass. |
| 12 | EmptyState and standalone Toast preserve required copy, urgency, focus, and parent-owned action semantics. | VERIFIED | Component tests and focused browser evidence cover empty-only composition, toast roles, visible focus, and no focus steal. |
| 13 | FlashGroup correctly consumes Phoenix `@flash`, preserves tone/urgency and unique identity, and supports per-item default dismissal. | GAP | Real `%{"info" => "OK", "error" => "BAD"}` probe renders two `neutral`/`status` toasts with duplicate `probe-flash-neutral` ids. Buttons omit `phx-value-key`; local Phoenix LiveView source confirms `lv:clear-flash` clears one item only when `%{"key" => key}` is sent, otherwise it clears all. |
| 14 | All data-display CSS is `.obpt-root` scoped, token-backed, responsive, and deterministically packaged. | VERIFIED | Theme/assets tests pass and `cmp` confirms source CSS equals packaged CSS. |
| 15 | Ten deterministic real-component stories flow through schema-5 generated browser targets with bounded 2,500-row evidence. | VERIFIED | Catalog tests, ShowcaseLive tests, manifest smoke, and 21-test behavior discovery pass; Elixir remains the ID source. |
| 16 | Focused structure/axe/VRT and security evidence closes the component/showcase scope without refreshing unrelated baselines or migrating pages. | VERIFIED | Validation records live structure 12/12, axe 120/120, Docker VRT 120/120; independent verifier finds exactly 120 data PNGs; the 108 scenario-only residual remains explicitly unclaimed. |

**Score:** 14/16 truths verified, 0 behavior-unverified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/oban_powertools/web/status_taxonomy.ex` | Pure exhaustive status registry | VERIFIED | Substantive `spec/2` and `all_specs/0`; atom-safety and exact mapping tests pass. |
| `lib/oban_powertools/web/components/data_display.ex` | Complete shared data-display API | PARTIAL | All exports and most semantics are substantive; FlashGroup and nil ProgressBar paths fail explicit contracts. |
| `assets/oban_powertools/tokens.css` | Scoped data-display styling | VERIFIED | Root-scoped table/state/detail/progress/code/toast families; focused tests pass. |
| `priv/static/oban_powertools/oban_powertools.css` | Deterministic packaged CSS | VERIFIED | Byte-identical to source CSS. |
| `test/support/data_display_story_catalog.ex` | Ten deterministic data stories | VERIFIED | Exact locked order, complete component/taxonomy coverage, 20-row bounded window with truthful 2,500 total. |
| `lib/oban_powertools/web/dev/showcase_live.ex` | Real stories and parent-owned sorting | VERIFIED | Runtime catalog loading, real component bodies, and finite sort event/assigns are wired. |
| `scripts/showcase_manifest.exs` and browser manifest support | Schema-5 generated data targets | VERIFIED | Smoke reports 10 data stories and 41 total targets; no browser-side full ID registry. |
| `test/browser/specs/data-display.behavior.spec.ts` | Live behavior and disclosure proof | VERIFIED WITH COVERAGE GAP | 21 tests discover and recorded 320/wide runs pass; it exercises explicit unavailable progress and atom-key fixture flash, not the two failing default/framework shapes. |
| Data VRT baselines | 120 data-only PNGs | VERIFIED | Independent manifest-derived equality reports `data baselines ok: 120`; current change-scope check reports no unrelated screenshot changes. |
| `77-VALIDATION.md` | Nyquist evidence record | VERIFIED FOR EXECUTED GATES | Commands and recorded focused evidence are internally consistent, but the record did not include the two now-reproduced edge paths. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `DataDisplay.status_pill/1` | `StatusTaxonomy` / `Primitives.status_pill/1` | Pure spec lookup and component delegation | WIRED | Source and hostile render tests pass. |
| `DataDisplay.data_table/1` | parent LiveView | `phx-click` plus opaque `phx-value-sort-key` | WIRED | ShowcaseLive owns sort key/direction and browser evidence exercises the transition. |
| DataDisplay HEEx | `tokens.css` | `.obpt-data-*`, detail, progress, code, redaction, and toast class families | WIRED | Selectors are present below `.obpt-root`; source/package CSS match. |
| `ArgsViewer` | normalized DisplayPolicy outputs | finite tuple/map dispatcher | WIRED | No component callback or raw+display dual input; disclosure tests pass. |
| `DataDisplayStoryCatalog` | ShowcaseLive / manifest | runtime support catalog and generated schema 5 | WIRED | ExUnit and manifest smoke pass. |
| Phoenix `@flash` | `DataDisplay.flash_group/1` | string-keyed flash map | NOT CORRECTLY WIRED | Component tone clauses accept atoms only and discard the source key before rendering. |
| Flash dismiss button | LiveView `lv:clear-flash` | `phx-value-key` | NOT WIRED | No key is emitted, so the default event clears the full map rather than one notification. |

## Requirements Coverage

| Requirement | Source Plans | Status | Evidence / Blocking Issue |
|---|---|---|---|
| DATA-01 | 77-01, 77-03..77-07 | BLOCKED | The full component set exists, but two named shared components have reproducible false semantics in ordinary/default inputs: FlashGroup with Phoenix `@flash`, and ProgressBar with omitted value. |
| DATA-02 | 77-01, 77-02, 77-06, 77-07 | SATISFIED FOR PHASE 77 SCOPE | One exhaustive shared StatusPill/taxonomy maps every audited Oban/Powertools state. Page-local helper removal is explicitly deferred to Phases 79-81 by the UI-SPEC and roadmap. |
| DATA-03 | 77-01, 77-03, 77-04, 77-06, 77-07 | SATISFIED | One-DOM 320px table reflow, explicit table/list states, long-value handling, focus targets, and overflow evidence are green. |
| DATA-04 | 77-01, 77-05..77-07 | SATISFIED | One normalized ArgsViewer/RedactedValue route owns redaction presentation; sentinel evidence passes. |
| A11Y-02 | 77-01..77-07 | BLOCKED FOR PHASE 77 COMPONENT SCOPE | Most keyboard/focus/non-color contracts pass, but normal string-keyed error flash is announced as polite neutral status and multiple items receive duplicate ids. Broader page/dialog/manual scope remains Phase 82. |

**Coverage:** 3/5 phase requirements fully satisfied; all five IDs are accounted for.

`.planning/REQUIREMENTS.md` marks DATA-01..04 and A11Y-02 checked while its traceability table still says Phase 77 `Pending`. Those bookkeeping states do not override the reproduced component gaps; this verification report is the completion gate.

## Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---|---|---|
| `status_taxonomy_test.exs` | DATA-02, A11Y-02 | Yes | 0 | No | Exact mapping, source safety, ordering/parity | PASS |
| `data_display_test.exs` | DATA-01, DATA-03, DATA-04, A11Y-02 | Yes | 0 | No | Rendered native semantics and source guards | INSUFFICIENT on real string-key flash and default/nil progress paths |
| `data_display_story_catalog_test.exs` | DATA-01..04 | Yes | 0 | No | Exact registry/fixtures/window | PASS |
| `showcase_live_test.exs` | DATA-01..04, A11Y-02 | Yes | 0 | No | Live rendering and parent sort transition | PASS, but flash fixture is atom-keyed |
| `data-display.behavior.spec.ts` | DATA-01..04, A11Y-02 | Yes | 0 | No | Live sorting/reflow/focus/redaction/progress/toast/row bounds | PASS for covered shapes; does not exercise the two failing inputs |

No requirement is supported only by skipped or circular tests. The coverage omissions allowed production defects to pass the focused suite, but the direct verifier probes fail independently of test construction.

## Behavioral Spot-Checks

| Check | Result |
|---|---|
| Focused Phase 77 ExUnit suite | PASS - 60 tests, 0 failures |
| `mix compile --warnings-as-errors` | PASS |
| Manifest generation and independent smoke | PASS - schema 5, 10 data stories, 41 targets |
| Baseline equality | PASS - exactly 120 data PNGs |
| Baseline changed scope | PASS - current 0 changed screenshot paths, all within expected matrix |
| CSS source/package equality | PASS |
| Playwright data behavior discovery | PASS - 21 tests listed |
| String-keyed Phoenix flash render probe | FAIL - neutral tones, polite roles, duplicate ids, no per-item key |
| Default/nil progress render probe | FAIL - determinate `value=0`, `0/100`, and `0%` |

Server-backed Docker browser matrices were not rerun in this verifier pass. Their final live execution is recorded in `77-VALIDATION.md`; current source, test discovery, target generation, and exact baseline matrix were rechecked locally. Both blocking gaps are deterministic server-rendered HEEx defects and were reproduced directly without requiring a browser.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `data_display.ex` | 529-535, 754-765 | Flash source key discarded; atom-only tone clauses | BLOCKER | Real Phoenix flashes lose severity, collide on DOM id, and cannot dismiss one item. |
| `data_display.ex` | 304-337, 652 | Optional nil measurement coerced to zero | BLOCKER | Unknown progress is falsely announced as measured 0%. |
| `data_display_test.exs` / story catalog | flash/progress fixtures | Only atom-key flash and explicit-state unavailable progress | WARNING | Focused tests miss ordinary framework/default inputs. |

No placeholder implementation, dynamic atom creation, raw HTML rendering, table JS hook, raw/redacted dual assign, or unrelated data screenshot drift was found.

## Human Verification Required

None. Both gaps are deterministic and programmatically reproduced; visual/manual judgment is not needed before fixing them.

## Gaps Summary

### Critical Gaps (Block Progress)

1. **WR-01: FlashGroup does not honor Phoenix flash shape or per-item dismissal**
   - Missing: normalized atom/binary flash keys, source-key-preserving items, collision-safe ids, and `phx-value-key` for default `lv:clear-flash` dismissal.
   - Impact: info/error messages are presented with false severity and duplicate ids, while dismissing one clears all flash messages.
   - Fix: normalize keys without atom creation, derive tone/urgency from the canonical key, retain the key through rendering, give each item a unique id, and emit the key for the LiveView default event. Add component and connected LiveView regression coverage using string-keyed `@flash`.

2. **WR-02: Nil progress is falsely determinate**
   - Missing: a fail-closed contract for omitted/`nil` progress.
   - Impact: assistive technology and visible copy report a measurement that does not exist, directly violating the approved unknown-progress contract.
   - Fix: either require a value whenever state is ready or automatically route nil to the non-numeric unavailable branch. Add a regression test proving no `<progress>`, value, count, or percentage is rendered for nil.

## Recommended Fix Plans

### 77-08-PLAN.md: Correct Flash and Progress Edge Semantics

**Objective:** Close WR-01 and WR-02 without changing the public data-display ownership boundary.

**Tasks:**
1. Normalize Phoenix flash keys, preserve item identity, and implement collision-safe per-item default dismissal in `DataDisplay.flash_group/1`; add string-keyed render and connected LiveView tests.
2. Make nil progress unavailable (or require determinate input) and add default/nil regression coverage.
3. Re-run the focused Phase 77 suite, browser notification/progress behavior, axe, compile, manifest smoke, and phase verification.

**Estimated scope:** Small

## Verification Metadata

**Verification approach:** Goal-backward from Roadmap Phase 77 success criteria and all seven PLAN must-haves.
**Files reviewed:** All Phase 77 PLAN/SUMMARY files, REQUIREMENTS, UI-SPEC, VALIDATION, REVIEW, primary production components/taxonomy, catalogs, showcase/manifest/browser wiring, and focused tests.
**Automated checks:** 7 green checks, 2 failing direct behavior probes.
**Human checks required:** 0.

---
*Verified: 2026-07-13T00:40:36Z*
*Verifier: the agent (gsd-verifier)*
