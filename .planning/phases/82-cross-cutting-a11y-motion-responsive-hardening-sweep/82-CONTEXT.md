# Phase 82: Cross-Cutting A11y, Motion & Responsive Hardening Sweep - Context

**Gathered:** 2026-07-29
**Status:** Ready for planning
**Mode:** Autonomous smart discuss — recommended decisions accepted by user

<domain>
## Phase Boundary

Close cross-cutting accessibility, motion, responsive-reflow, and microcopy
gaps across the complete v2.0 operator UI now delivered by Phases 70–81. The
required surface is all nine production pages—Overview, Cron, Limiters, Audit,
Jobs, Forensics, Batches, Workflows, and Lifeline—plus every target in the
current generated showcase inventory. This phase may repair shared components,
page composition, tokens, copy, tests, fixtures, and quality gates, but it does
not add operator capability, change routes or authority boundaries, expand the
showcase catalog for Phase 83, or write the Phase 83 contributor documentation.

</domain>

<decisions>
## Implementation Decisions

### One Complete Quality Graph

- **D-01:** Treat the Elixir-owned catalog and its generated schema-8 manifest
  as the only showcase inventory. The sweep covers every currently registered
  primitive, form, data-display, group, and page-story target; it must not
  maintain a hand-written second target list or invent Phase 83 stories.
- **D-02:** Treat the nine authenticated production routes as a separate
  connected acceptance lane. Each route must be exercised through its real
  `AppShell` and production composition, not accepted solely because a
  deterministic showcase story passes.
- **D-03:** Extend the existing required, unfiltered `verify:pages` /
  `page_quality` graph and exact validators. Focused slices may speed local
  iteration, but milestone evidence comes from the complete graph with no
  grep, retry, ignored failure, update mode, or manually omitted target.
- **D-04:** Preserve the established deterministic evidence model: generated
  discovery, exact ARIA snapshots, connected keyboard/focus checks, axe,
  compare-only VRT, and structured VoiceOver evidence. A deliberate snapshot
  change is reviewed as an implementation change and followed by a fresh
  compare-only run; snapshot update mode is never completion evidence.

### WCAG, Contrast, Targets, and Focus

- **D-05:** Axe runs with WCAG 2.2 AA tags against every current showcase
  target in every supported theme and open-state variant, and against all nine
  connected production pages. Zero critical or serious violations is
  merge-blocking. Relevant moderate findings are not silently waived: either
  repair them or record a narrow, standards-backed exception with executable
  regression coverage.
- **D-06:** Add mechanical contrast verification at the token/component
  chokepoints and representative rendered states. Light and dark require WCAG
  AA text contrast (4.5:1 normal text, 3:1 large text) and 3:1 non-text
  contrast; muted text retains its 4.5:1 hard floor. High-contrast requires the
  brand-book enhanced target of at least 7:1 for body text, solid semantic
  boundaries, and a focus indicator at least 2 CSS px thick with at least 3:1
  contrast against both adjacent states. Meaning must remain complete without
  color.
- **D-07:** Enforce WCAG 2.2 2.5.8 mechanically: every pointer target is at
  least 24 by 24 CSS px or has standards-compliant spacing, with any inline or
  essential exception explicit and tested. Retain the shipped stronger
  comfort rule for operator controls: primary actions, icon controls,
  pagination, row actions, selection controls, theme/navigation controls, and
  dialog actions expose an effective 44px target in at least one axis without
  overlap.
- **D-08:** Verify WCAG 2.4.11 with actual keyboard focus after scroll,
  navigation, dialog open/close, validation error, LiveView patch, responsive
  mode change, and recovery. Focus may not be fully obscured by sticky/fixed
  chrome or overlays; it remains visibly outlined, logically ordered, and
  restored to the connected invoker or documented fallback.

### Keyboard, Reflow, and Motion

- **D-09:** Run full keyboard traversal on every production page, including
  skip link, navigation, filters, tables/lists, pagination, adaptive details,
  disclosures, dialogs, confirmations, validation errors, recovery, and
  destinations that exist on that page. Native/APG interaction behavior,
  Escape policy, focus containment, invoker restoration, and live-region
  announcements remain executable contracts; no single-key shortcut is added.
- **D-10:** Every page and current showcase target uses one semantic responsive
  tree from 320px through tablet and wide layouts and at 200% zoom. Page,
  document, and root horizontal overflow must be zero at 320px; duplicated
  mobile/desktop content is forbidden. Only bounded, labelled, keyboard-
  reachable machine-content regions may scroll horizontally, and nested
  scrolling may not make ordinary controls unusable.
- **D-11:** Keep DATA-03 behavior explicit while reflowing: tables/lists stack
  or use their established semantic fallback; long IDs, modules, URLs,
  Unicode/RTL text, and stack traces wrap, visibly truncate with an accessible
  expansion, or use a bounded labelled scroller. Empty, loading, unavailable,
  permission-denied, stale, and partial states remain distinguishable.
- **D-12:** Inventory every animation and transition in the token CSS,
  packaged CSS, components, and page composition. Motion must use token-owned
  duration/easing, communicate a state change rather than decorate, be
  interruptible, and never delay authority, action, focus, content, recovery,
  or feedback.
- **D-13:** Under both `prefers-reduced-motion: reduce` and the root-scoped
  explicit reduced-motion state, non-essential animation becomes instant or
  absent across every target and page. Spinners, skeletons, overlays,
  disclosures, responsive details, theme/nav controls, progress, and
  LiveView-updated content must remain visible and operable; reduced motion
  cannot substitute hidden content or suppress an announcement.

### BRAND-04 Copy and Honest Recovery

- **D-14:** Audit rendered copy and source literals against `guides/brand-book.md`
  D-16 through D-21: plain, consequence-first, precise, calm, honest,
  non-cute, non-hedging, active-voice language. Apply the coherence test to
  every changed string: it should make a stressed operator calmer and more
  certain about what will happen.
- **D-15:** Enforce one term per concept across all nine pages and shared
  components. Centralize repeated state, action, danger, dismissal, and
  recovery literals where doing so prevents drift; retain page-specific
  consequence and support-boundary text when generic copy would become less
  truthful. Do not perform an unrelated gettext or localization migration.
- **D-16:** Every destructive or state-changing confirmation names the object,
  exact count/scope, consequence, reversibility, support boundary, and required
  reason before its action-specific submit. The dismiss label describes the
  state being preserved and never uses ambiguous `Confirm`, `Cancel`, or “Are
  you sure?” wording.
- **D-17:** State and error copy is mechanically audited: empty states give a
  fact plus next action; loading names what is loading; stale, unavailable,
  permission-denied, partial, and empty remain distinct; errors say how to
  recover. Receipts describe only what Powertools actually requested,
  recorded, changed, or audited and never promise a host-owned downstream
  outcome.
- **D-18:** Add a fail-closed BRAND-04 copy contract to the normal quality
  graph. It should combine a finite glossary/forbidden-phrase registry,
  rendered nine-page and showcase scans, and focused ordering assertions for
  confirmations and recovery. It must report the exact page/story and string
  on failure rather than relying on a subjective manual sign-off.

### Remediation and Completion Policy

- **D-19:** Prefer fixes at the shared token, component, copy, presenter, or
  harness seam when the defect crosses pages. Use a page-local repair only
  where the page has genuinely unique semantics; do not create parallel focus,
  motion, responsive, status, copy, or target-size systems.
- **D-20:** Preserve all Phase 79–81 product contracts: routes and URL state,
  server-owned authorization, Lifeline preview/reason/reauthorize/execute/audit,
  redaction and confidentiality, bounded reads, support truth, one semantic
  tree, and production-composed stories. An accessibility fix may not move
  mutation authority into the client or expose raw/provider-shaped data.
- **D-21:** Keep source and packaged CSS byte-identical and repeat-build stable.
  New static validators must fail on inline motion timings, unscoped raw
  visual values, duplicated responsive trees, stale packaged assets, or
  unregistered quality targets.
- **D-22:** Phase completion requires a fresh green unfiltered quality graph,
  focused ExUnit/browser regression suites, formatting, warnings-as-errors
  compilation, exact artifact validators, source/package equality, and full
  repository tests. The validation ledger records exact commands, inventory
  counts, standards mappings, and any legitimate exceptions; no manual
  accessibility claim may stand in for executable evidence.

### Claude's Discretion

Exact plan slicing, helper names, validator decomposition, representative
contrast-state selection, and the internal copy-registry shape are
discretionary. Those choices must retain complete nine-page plus current-
showcase coverage, generated inventory ownership, the numeric standards above,
the existing required CI graph, and the product/authority boundaries already
locked by Phases 70–81.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product and milestone contract
- `.planning/PROJECT.md` — project principles, adopter-first completion posture,
  and host-owned operational-safety boundaries.
- `.planning/REQUIREMENTS.md` — A11Y-01..04, MOTION-01..02, NAV-02, DATA-03,
  COPY-01..02, and BRAND-04 acceptance contracts.
- `.planning/ROADMAP.md` § Phase 82 — fixed phase goal, dependency, and success
  criteria.
- `guides/brand-book.md` — locked D-01..D-22 visual, motion, accessibility, and
  voice source of truth; D-05, D-11..12, D-15..21 are central to this sweep.

### Shipped page and design-system contracts
- `.planning/phases/76-navigation-app-shell/76-UI-SPEC.md` — shell navigation,
  skip-link, theme, focus, target, and responsive design contract.
- `.planning/phases/76-navigation-app-shell/76-VERIFICATION.md` — passed shell
  behavior and evidence baseline that this sweep must preserve.
- `.planning/phases/77-data-display-operator-patterns/77-CONTEXT.md` — semantic
  data states, long-content, redaction, and operator-pattern decisions.
- `.planning/phases/79-page-migration-wave-1-overview-cron-limiters-audit/79-CONTEXT.md`
  — Overview, Cron, Limiters, Audit interaction/copy/reflow contracts.
- `.planning/phases/80-page-migration-wave-2-jobs-forensics/80-CONTEXT.md` —
  Jobs and Forensics interaction/copy/reflow contracts.
- `.planning/phases/81-page-migration-wave-3-batches-workflows-lifeline/81-CONTEXT.md`
  — Batches, Workflows, Lifeline interaction/copy/reflow contracts.
- `.planning/phases/81-page-migration-wave-3-batches-workflows-lifeline/81-UI-SPEC.md`
  — final page-composition, token, focus, target, motion, and theme contract.

### Current completion and quality evidence
- `.planning/phases/73-visual-regression-a11y-harness/73-VERIFICATION.md` —
  required VRT/axe harness and CI ownership.
- `.planning/phases/81-page-migration-wave-3-batches-workflows-lifeline/81-VALIDATION.md`
  — fresh full-graph commands and exact 99-page-story / 163-target /
  297-ARIA / 1,188-page-PNG inventory.
- `.planning/phases/81-page-migration-wave-3-batches-workflows-lifeline/81-VERIFICATION.md`
  — passed Phase 81 behavior and the explicitly deferred Phase 82 system sweep.
- `.planning/phases/81-page-migration-wave-3-batches-workflows-lifeline/81-UI-REVIEW.md`
  — passed six-pillar page review and final copy/reflow fixes.
- `.planning/phases/81-page-migration-wave-3-batches-workflows-lifeline/81-SECURITY.md`
  — closed authority, confidentiality, fixture, and artifact trust boundaries
  that hardening must preserve.

### Executable quality seams
- `assets/oban_powertools/tokens.css` — root-scoped theme, focus, responsive,
  target, and reduced-motion implementation.
- `package.json` — canonical `verify:pages`, VRT, axe, manifest, and VoiceOver
  entry points.
- `playwright.config.ts` — 320px, tablet, and wide browser projects and default
  reduced-motion behavior.
- `voiceover.config.ts` — structured real-VoiceOver project configuration.
- `test/support/page_story_catalog.ex` — Elixir-owned nine-page story inventory.
- `test/browser/specs/page.acceptance.spec.ts` — generated copy, role, order,
  one-tree, and ARIA contracts.
- `test/browser/specs/showcase.a11y.spec.ts` — manifest-driven axe coverage.
- `test/browser/specs/page-migration-wave-1.spec.ts` — connected Overview,
  Cron, Limiters, and Audit behavior/reflow/focus contracts.
- `test/browser/specs/page-migration-wave-2.spec.ts` — connected Jobs and
  Forensics behavior/reflow/focus contracts.
- `test/browser/specs/page-migration-wave-3.spec.ts` — connected Batches,
  Workflows, and Lifeline behavior/reflow/focus contracts.
- `test/browser/voiceover/page.voiceover.spec.ts` — structured page
  screen-reader evidence.
- `test/browser/support/verify-page-script-order.mjs` — required unfiltered CI
  script-order and gate validator.
- `.github/workflows/ci.yml` — merge-blocking page-quality and accessibility
  jobs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppShell`, `Primitives`, `Forms`, `DataDisplay`, and `OperatorPatterns`
  already centralize semantic markup, targets, focus, dialogs, data states,
  long-content handling, and shared operator copy.
- `StatusTaxonomy`, `ControlPlanePresenter`, and the existing copy-coherence
  tests provide finite, redaction-safe presentation and terminology seams.
- `PageStoryCatalog`, `ShowcaseLive`, the schema-8 manifest, three Playwright
  projects, four themes, exact artifact validators, and structured VoiceOver
  config already provide a generated audit surface.

### Established Patterns
- Production pages and showcase stories call the same pure page-composition
  functions while LiveViews retain URL, repository, authorization, preview,
  mutation, receipt, and recovery ownership.
- Root-scoped `--obpt-*` tokens are the only visual/motion contract; system,
  light, dark, and high-contrast themes do not mutate host-global styles.
- Required evidence is deterministic and fail-closed: exact discovery and
  artifact sets, compare-only screenshots, no duplicated responsive DOM, and
  no update mode counted as a pass.

### Integration Points
- Shared repairs belong primarily in `assets/oban_powertools/tokens.css`,
  `lib/oban_powertools/web/components/`, and finite presenter/copy seams.
- Cross-page browser coverage composes through `package.json`,
  `playwright.config.ts`, `test/browser/specs/`, manifest support, and the
  required `.github/workflows/ci.yml` gate.
- Page-specific regressions remain in the Phase 79, 80, and 81 connected
  production-route suites; whole-showcase checks remain manifest-driven.

</code_context>

<specifics>
## Specific Ideas

- The sweep is a standards-and-trust closure pass, not a visual redesign.
- Use both static audits and browser measurements: source scans catch untokened
  motion/copy drift while computed styles, geometry, scroll metrics, and real
  focus traversal prove rendered behavior.
- Failure output should name the exact route, story, theme, viewport, control,
  token pair, or phrase so maintainers can repair the owning seam quickly.
- Keep the full graph conceptually simple: current generated showcase inventory
  for exhaustive component/state coverage, plus nine connected routes for real
  shell, authority, focus, and reflow behavior.

</specifics>

<deferred>
## Deferred Ideas

- Adding missing showcase stories, a contributor guide, design-system
  documentation, and idempotency-guardrail documentation remains Phase 83.
- The final milestone audit and any archive/completion operation remains Phase
  84 / milestone-completion scope.
- New operator features, route changes, localization infrastructure, new
  runtime dependencies, or a redesign of the established page information
  architecture are outside Phase 82.

</deferred>

---

*Phase: 82-cross-cutting-a11y-motion-responsive-hardening-sweep*
*Context gathered: 2026-07-29*
