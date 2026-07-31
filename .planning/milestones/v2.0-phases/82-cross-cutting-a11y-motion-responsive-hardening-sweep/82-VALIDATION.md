---
phase: 82
slug: cross-cutting-a11y-motion-responsive-hardening-sweep
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-29
updated: 2026-07-31
---

# Phase 82 — Validation Ledger

This ledger is the fail-closed evidence contract for the complete schema-8
quality graph. It preserves the current **163 targets**, **99 page stories**,
**297 page ARIA snapshots**, and **1,956 full-showcase PNG baselines**. Phase 82
does not add Phase 83 stories or a second target inventory.

## Wave 0 contract

| Contract | Plan | Automated evidence | Initial state |
|---|---|---|---|
| Contrast algorithms | 82-01 | `system-quality-contract.spec.ts` covers exact sRGB, alpha composition, 4.5/3/7 thresholds, muted floor, non-text adjacency, and unknown-color failure | GREEN |
| Target geometry | 82-01 | 24×24-or-spacing, explicit exceptions, collision, overlap, and separate 44px comfort cases | GREEN |
| Focus and occlusion | 82-01 | active-element, 2px/3:1 indicator, viewport, sticky/top-layer hit-test, detached focus, and restoration cases | GREEN |
| Reflow and zoom | 82-01 | root/body/document/page overflow, registered machine scroller, duplicate-tree, and `finally` restoration cases | GREEN |
| Motion | 82-01 | raw timing/easing, unknown keyframes, missing either reduction path, hidden content, and delayed action/focus cases | GREEN |
| Motion source closure | 82-01, 82-03, 82-05, 82-10 | Plan 82-03 is the sole fail-closed Node owner for production `.ex`/`.heex`, client `.js`/`.ts`, source/package CSS, per-root mutations, exact exclusions, and path:line diagnostics; 82-05 and 82-10 consume it unchanged | GREEN |
| System theme runtime | 82-01, 82-04 | light/no-preference→explicit light, dark/no-preference→explicit dark, contrast-more under both schemes→explicit high-contrast; computed-role equality and `finally` restoration | GREEN |
| Axe policy | 82-01 | critical/serious/moderate blocking plus exact, expiring, used exception cases | GREEN |
| Copy policy | 82-02 | source/rendered forbidden phrases, glossary drift, confirmation order, state/recovery, receipt truth, and stale exclusion cases | GREEN |
| Manifest and routes | 82-01, 82-17 | schema-8 inventory ownership and exact nine-family route-key fixtures | GREEN |
| ARIA reconciliation | 82-16 | exactly 297 manifest-derived snapshots reviewed after semantic/copy repairs and before compare-only runtime; update mode is generation-only | GREEN |
| Required CI graph | 82-01, 82-03, 82-10 | omission, reorder, filter, duplicate, update/watch, ignored failure, detached job, and missing gate-edge mutations | GREEN |

Wave 0 is complete only when the RED tests fail for the intended missing
Phase 82 seams and then pass without weakening their assertions.

## Requirement-to-evidence map

| Requirement | Mechanical evidence | Plans |
|---|---|---|
| A11Y-01 | WCAG 2.2 tags over all 1,956 existing showcase axe activations plus connected route axe; moderate findings fail closed unless exact executable exception | 01, 03, 04, 08, 09, 10, 16 |
| A11Y-02 | Shared strict keyboard/focus/dialog/announcement helpers; all nine connected journeys; existing Wave 1–3 dangerous transitions reused | 01, 04, 06, 07, 08, 09, 12, 13, 14, 15, 16 |
| A11Y-03 | Exact contrast, target-size, focus-indicator, focus-not-obscured, and system-theme computed-role equivalence algorithms | 01, 04, 05, 06, 08, 09, 10, 12 |
| A11Y-04 | 297 exact reconciled ARIA snapshots, ten real-VoiceOver targets, reduced-motion and recovery evidence | 01, 03, 04, 06, 08, 09, 10, 13, 16 |
| MOTION-01 | Sole Node-owned parsed production source/package declaration inventory; token-owned duration/easing; exact exclusions; byte equality | 01, 03, 05, 10 |
| MOTION-02 | Independent OS and root reduction paths with content/action/focus/announcement availability | 01, 03, 04, 05, 08, 09, 10 |
| NAV-02 | One semantic tree, 320/tablet/wide and 200% zoom, no ordinary page overflow | 01, 03, 04, 05, 06, 08, 09, 10, 12 |
| DATA-03 | Long/Unicode/RTL/machine content and distinct state semantics across generated and connected surfaces | 01, 03, 07, 08, 09, 10, 12, 14, 15 |
| COPY-01 | One Elixir-owned glossary/forbidden registry plus source, 163-target, and nine-route scans | 02, 03, 07, 08, 09, 10, 14, 15, 16, 17 |
| COPY-02 | Generic confirmation ordering plus action-specific consequence, support, reason, dismiss, and recovery truth | 02, 03, 07, 08, 09, 10, 13, 14, 15, 16, 17 |

## Exact inventory and execution contract

| Evidence family | Exact contract |
|---|---|
| Manifest | schema 8; 163 targets; 99 page stories; kind and family order remain Elixir-owned |
| Showcase axe/mechanical lane | reuse the existing 1,956 target × theme × viewport activations; no second navigation matrix |
| Connected lane | exactly 9 families × 3 Playwright projects = 27 project-expanded cases, with four themes looped in each case |
| System theme matrix | each showcase/connected `system` activation: OS light/no-preference equals explicit light; OS dark/no-preference equals explicit dark; contrast-more under both schemes equals explicit high-contrast; compare finite computed roles and restore media/root state |
| Phase 82 pre-completion runtime | host-backed `manifest-first-per-kind` showcase slice derived only from the generated manifest plus full 99-story chromium-wide page acceptance; no handwritten IDs |
| ARIA | exactly 99 × 3 = 297 reviewed snapshots |
| VRT | exactly 163 × 4 × 3 = 1,956 compare-only PNGs, including 1,188 page PNGs |
| VoiceOver | exact existing ten targets; real Guidepup execution only on supported configured macOS |

## Execution waves and ownership

| Wave | Plans | Ownership |
|---|---|---|
| 1 | 82-01, 82-02 | RED browser/Node and copy/component contracts |
| 2 | 82-03, 82-04, 82-17 | sole Node policy owner, browser auditors, and Elixir copy/manifest owner |
| 3 | 82-05, 82-06, 82-13 | tokens/assets plus primitive/forms and operator shared-component slices |
| 4 | 82-12 | shell/data shared-component slice after shared CSS |
| 5 | 82-07 | Overview/Cron/Limiters/Audit page wave |
| 6 | 82-14 | Jobs/Forensics page wave |
| 7 | 82-15 | Batches/Workflows/Lifeline page wave |
| 8 | 82-16 | exact ARIA reconciliation and semantic review |
| 9 | 82-08, 82-09 | real compare-only showcase/page and connected-route runtime |
| 10 | 82-10 | package/VoiceOver/CI graph consuming the sole Node owner |
| 11 | 82-11 | exact artifact and repository closure |

## Final commands

```bash
mix test test/oban_powertools/web/theme_tokens_test.exs \
  test/oban_powertools/web/assets_test.exs \
  test/oban_powertools/web/copy_contract_test.exs --seed 0
npm run showcase:manifest
node test/browser/support/manifest-smoke.mjs
node test/browser/support/verify-phase82-quality.mjs
node test/browser/support/verify-page-aria-snapshots.mjs
node test/browser/support/verify-page-baselines.mjs
node test/browser/support/verify-page-script-order.mjs
scripts/with-showcase-server.sh npx playwright test \
  test/browser/specs/system-quality-contract.spec.ts \
  test/browser/specs/system-quality.spec.ts --project=chromium-wide
scripts/with-showcase-server.sh env \
  PHASE82_RUNTIME_SLICE=manifest-first-per-kind \
  npx playwright test test/browser/specs/showcase.a11y.spec.ts \
  --project=chromium-wide
scripts/with-showcase-server.sh npx playwright test \
  test/browser/specs/page.acceptance.spec.ts --project=chromium-wide
mix format --check-formatted
MIX_ENV=test mix compile --warnings-as-errors
cmp -s assets/oban_powertools/tokens.css \
  priv/static/oban_powertools/oban_powertools.css
mix test --seed 0
CI=1 npm run verify:pages
CI=1 npm run visual:a11y
npx playwright test --config=voiceover.config.ts --list
```

`npm run verify:voiceover` is required only on a configured supported macOS
Guidepup/VoiceOver host. `voiceover.config.ts`, the canonical macOS command,
and every CI browser evidence path must resolve retries to explicit numeric
zero; `verify-page-script-order.mjs` mutation-proves omission, inheritance,
string, and nonzero retry values fail. Discovery is required everywhere. Snapshot update
mode, grep filters, retries, ignored failures, watch/UI mode, manually omitted
targets, or synthesized transcripts are never completion evidence.

## Completion record

Completed 2026-07-31 with the following fresh, unfiltered evidence:

- `CI=1 npm run visual:a11y`: **4,652 passed, 28 expected viewport-only
  skips**, exit 0, retries 0, compare-only, and no update/filter/watch mode.
- `CI=1 npm run verify:pages`: **2,919 passed**, exit 0, retries 0,
  compare-only, and no update/filter/watch mode.
- `mix test --seed 0`: **973 tests, 0 failures**; the example host separately
  passed **15 tests, 0 failures**.
- Manifest and exact-set validators: schema 8, 163 targets, 99 page stories,
  297 ARIA snapshots, 1,956 PNGs (1,188 page PNGs), four themes, three
  viewports, nine route families, and zero exceptions.
- `mix format --check-formatted`, root and host
  `MIX_ENV=test mix compile --warnings-as-errors`, and both `mix hex.audit`
  commands exited 0; both audits reported no retired or advisory packages.
- Source and packaged CSS are byte-identical with SHA-256
  `8396723a7625c077ad75f75669373adfae8fc92a422e6e211f7fa8da1de51899`.
  Repeated asset builds remained byte-stable; packaged JS SHA-256 is
  `d8117f39cdeb22208a7bf0b2958c0a59cb50e070a6fae43cdcdcf459d88a2849`.
- VoiceOver discovery lists exactly ten manifest-owned targets under the
  canonical explicit `retries: 0` configuration. Real Guidepup/VoiceOver was
  not invoked because this session did not assume macOS Accessibility
  permission; no transcript or cursor evidence is claimed.

The runtime contracts map WCAG 2.2 AA/enhanced contrast, 2.4.11 focus not
obscured, 2.5.8 target size, keyboard/dialog/APG behavior, reduced motion,
reflow, and finite copy rules directly to executable assertions. No exception,
retry, ignored failure, snapshot update, or synthesized assistive-technology
evidence was used.
