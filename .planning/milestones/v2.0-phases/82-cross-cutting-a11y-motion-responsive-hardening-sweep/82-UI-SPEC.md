---
phase: 82
slug: cross-cutting-a11y-motion-responsive-hardening-sweep
status: approved
shadcn_initialized: false
preset: not applicable
created: 2026-07-29
reviewed_at: 2026-07-29
---

# Phase 82 — UI Design Contract

> Approved visual and interaction contract for the cross-cutting accessibility, motion, responsive, and microcopy hardening sweep.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Existing Oban Powertools design system: `.obpt-root`-scoped semantic CSS custom properties in `assets/oban_powertools/tokens.css`; shadcn is not applicable. |
| Preset | Not applicable. This is an Elixir/Phoenix LiveView library with no React, Next.js, Vite, Tailwind, `components.json`, or registry dependency. |
| Component library | Shipped stateless `Phoenix.Component` modules `AppShell`, `Primitives`, `Forms`, `DataDisplay`, and `OperatorPatterns`. |
| Presenter and copy boundary | `StatusTaxonomy`, `ControlPlanePresenter`, and finite shared copy helpers own repeated presentation and terminology. LiveViews retain URL, repository, authorization, preview, execution, receipt, and recovery authority. |
| Icon library | None. Retain component-owned glyphs with decorative glyphs hidden from assistive technology. Meaning always has visible text and programmatic semantics. |
| Font | `--obpt-font-sans` for prose, controls, state, counts, and timestamps; `--obpt-font-mono` only for literal machine values. |
| Theme boundary | `system`, `light`, `dark`, and `high-contrast` resolve on the nearest `.obpt-root`; never mutate `<html>` or host-global styles. |
| Inventory authority | The generated schema-8 manifest derived from Elixir catalogs. Current contract: exactly 163 targets—7 primitive, 9 form, 6 shell, 10 data, 23 group, 9 scenario, and 99 page targets. |
| Connected authority | Nine authenticated production routes: Overview, Cron, Limiters, Audit, Jobs, Forensics, Batches, Workflows, and Lifeline. |

This phase is a hardening pass, not a redesign. Preserve the shipped information hierarchy, routes, URL state, bounded reads, confidentiality, authorization, confirmation, and recovery behavior. Repair a cross-page defect at its shared token, component, presenter, copy, or harness chokepoint. Use a page-local change only for genuinely page-specific semantics. Do not add stories reserved for Phase 83.

Source: `82-CONTEXT.md` D-01..D-22; `81-UI-SPEC.md`; `81-UI-REVIEW.md`; `81-VERIFICATION.md`; `guides/brand-book.md` D-05, D-11..D-21.

---

## Spacing Scale

New Phase 82 repairs use only the 4/8/16/24/32/48px subset of the shipped
scale. No Phase 82 repair introduces a parallel spacing system or new 12px
usage.

| Token | Value | Usage |
|-------|-------|-------|
| `--obpt-space-1` | 4px | Inline icon/text gaps and focus offsets. |
| `--obpt-space-2` | 8px | Compact control gaps and minimum separation between adjacent controls. |
| `--obpt-space-4` | 16px | 320px page/dialog inset and ordinary component spacing. |
| `--obpt-space-5` | 24px | Surface padding and section rhythm. |
| `--obpt-space-6` | 32px | Wide layout gutters and major group gaps. |
| `--obpt-space-7` | 48px | Page-level separation only. |

Existing pre-Phase-82 component internals that already use the public
`--obpt-space-3` 12px token are grandfathered to preserve the shipped design
identity and need not be redesigned by this hardening sweep. That
non-regression exception does not permit any new 12px use.

Exceptions and hard bounds:

- Every pointer target satisfies WCAG 2.2 SC 2.5.8: at least 24×24 CSS px, or a tested spacing/inline/essential exception.
- Primary actions, icon controls, pagination, row actions, selection controls, theme and navigation controls, and dialog actions retain the stronger operator-comfort contract: at least 44 CSS px in one axis, without overlap.
- Native inline text links may use the 2.5.8 inline exception; links presented as controls, nav items, table actions, or pagination do not.
- Dense 32–36px table rows may remain dense, but interactive descendants retain their own 44px effective target.
- Focus indicators use at least a 2 CSS px perimeter and remain separated enough to be distinguishable against both focused and unfocused adjacent states.
- At 320px and at 200% zoom, ordinary content must wrap or reflow. Only a bounded, visibly labelled, keyboard-reachable machine-content region may scroll horizontally.

---

## Typography

Phase-owned typography uses four sizes and two weights. Existing component internals may retain the shipped 12px auxiliary floor and 500 emphasis where already part of their public contract; the sweep does not create new size or weight roles.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Dense metadata | 13px (`--obpt-font-size-sm`) | 400 | 1.4286 (`--obpt-line-height-base`) |
| Body, control, table value | 14px (`--obpt-font-size-md`) | 400 | 1.4286 |
| Section heading | 18px (`--obpt-font-size-xl`) | 600 | 1.25 (`--obpt-line-height-tight`) |
| Page H1 | 28px (`--obpt-font-size-page-title`) | 600 | 1.25 |

Rules:

- Retain exactly one H1 per route and page story.
- Do not reduce text to solve overflow. Long English, Unicode, RTL text, URLs, modules, IDs, and stack traces use wrapping, accessible expansion, visibly signalled truncation, or a bounded labelled scroller.
- Mono is not used for state, reason, consequence, guidance, counts, timestamps, or operator-facing prose.
- All numeric columns and changing counts use sans plus `--obpt-numeric-tabular`.
- Text at 200% zoom remains readable and operable without loss, clipping, overlap, or page-level two-dimensional scrolling.

---

## Color

All component and page styling uses semantic Tier-2 `--obpt-color-*` roles. Raw hex remains confined to the primitive token palette.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--obpt-color-surface`, `--obpt-color-text` | Root/page surface and primary content. |
| Secondary (30%) | `--obpt-color-elevated`, `--obpt-color-overlay`, `--obpt-color-border`, `--obpt-color-border-strong`, `--obpt-color-muted`, `--obpt-color-subtle` | Shell, cards, tables, grouped evidence, secondary prose. |
| Accent (10%) | `--obpt-color-accent-*`, `--obpt-color-focus` | Current selection, safe primary navigation/action, supported destinations, and keyboard focus. |
| Destructive | `--obpt-color-danger-*` | Destructive actions and genuine error/danger states only. |

Accent reserved for: current route/view/selection, safe primary actions, supported detail/evidence destinations, fresh-preview recovery, and focus-visible treatment.

Contrast contract:

- In `light` and `dark`, normal text is at least 4.5:1, large text at least 3:1, and non-text boundaries/controls/focus at least 3:1 against adjacent colors.
- Muted text retains a hard 4.5:1 floor in every theme.
- In `high-contrast`, body text is at least 7:1; semantic boundaries are solid rather than tint-only; the focus indicator is at least 2 CSS px thick and at least 3:1 against both adjacent states.
- `system` must be tested with both light and dark OS color schemes and with `prefers-contrast: more`; its computed roles must resolve to the corresponding explicit theme contract.
- Each status, validation, severity, selection, progress, and outcome uses at least two channels. A grayscale rendering remains understandable.
- Contrast evidence reports the semantic token pair and rendered route/story/control, not only a raw palette pair.

---

## Copywriting Contract

Phase 82 introduces no new product CTA. Existing page-specific verbs remain unchanged unless they violate the finite BRAND-04 taxonomy.

| Element | Contract |
|---------|----------|
| Primary CTA | Preserve the action-specific verb and object: `Preview …`, `Retry …`, `Pause …`, `Resume …`, `Cancel …`, `Discard …`, or `Execute remediation`. Never use bare `Confirm`, `Submit`, or `OK`. |
| Empty state heading | Fact: `No {resource} …`. |
| Empty state body | State what current evidence shows and one truthful next action; never imply global absence. |
| Loading | Name the resource being loaded. A spinner or skeleton has the same accessible name and does not replace content under reduced motion. |
| Error state | Name what failed and give a legal recovery path such as retry, Audit, Forensics, or host logs. |
| Unavailable | Preserve the non-enumerating missing/retained/permission branch where required. Do not collapse unavailable into empty. |
| Permission denied | State the required role or changed permission without exposing authorization internals. |
| Stale / partial | State what evidence is stale or incomplete, what changed or did not change, and the next legal action. |
| Destructive confirmation | Name object, exact count/scope, consequence, reversibility, support boundary, and required reason before the action-specific submit. |
| Destructive dismiss | Describe preserved state, for example `Keep current state` or `Keep running`; never ambiguous `Cancel`. |
| Receipt | State only what Powertools requested, recorded, changed, or audited. Never promise host-owned downstream success. |

Finite taxonomy:

| Canonical term | Meaning | Forbidden substitution |
|----------------|---------|------------------------|
| `Cancel` | Stop now; terminal; no retry. | `Discard`, `Delete` |
| `Discard` | Mark dead/exhausted; final. | `Cancel`, `Delete` |
| `Delete` | Remove a database row. | `Cancel`, `Discard` |
| `Retry` | Re-enqueue. | `Repair` when the action is only retry |
| `Pause` / `Resume` | Reversible queue or cron state. | `Stop` / `Start` |
| `Blocked` | Explain paused, saturated, or unmet dependency. | `stuck`, except orphan detection |
| `Preview` | Dry run. | `plan` in rendered operator copy |
| `Repair` | Lifeline mutation. | Generic success claim |
| `Reason` | Required audit justification. | `note`, `comment` |
| `Audit log` / `Audit trail` | Operator-action record. | `event log` |
| `Event log` | Forensics timeline. | `audit log` |
| `Limiter` | Rate/concurrency control. | ad hoc synonyms |

Fail-closed forbidden phrases include `Are you sure?`, bare `Confirm`, ambiguous dismiss `Cancel`, `Something went wrong`, `An error occurred`, `N/A`, `fixed`, `root cause` without proof, `exactly once`, and unsupported `atomic` or guaranteed-outcome claims. The audit also rejects raw atoms, codes, exception text, preview identity, provider metadata, and fixture secrets in rendered channels.

The copy validator must combine:

1. a finite glossary and forbidden-phrase registry;
2. source-literal scanning with narrow documented exclusions;
3. rendered scans of all 163 current showcase targets;
4. rendered scans and interaction assertions for all nine connected routes; and
5. ordering assertions proving scope/consequence/reversibility/support/reason precede submit, with recovery copy adjacent to the failed or stale state.

Failures name the exact source location or route/story and offending string.

---

## Responsive and Reflow Contract

One semantic tree serves every viewport. CSS may change grid placement, stacking, disclosure visibility, and adaptive-detail geometry; it must not duplicate mobile and desktop data, controls, IDs, dialogs, or confidential values.

| Mode | Contract |
|------|----------|
| 320px × 900 | Zero root, document, body, page, or ordinary-component horizontal overflow beyond a 1px rounding tolerance. Single-column flow; 16px inset; controls wrap/stack without overlap; navigation remains operable. |
| Tablet 768px × 1000 | One semantic tree; list/detail and filter layouts may use the shipped intermediate composition; focus order follows DOM and remains logical if columns appear. |
| Wide 1440px × 1000 | Preserve current information-dense hierarchy and adaptive detail behavior. Wide layout may not change reading or keyboard order into a contradictory sequence. |
| 200% zoom | Exercise the same content at an effective 320 CSS px minimum. No loss of text, controls, status, reason, recovery, or dialog actions; no page-level two-dimensional scrolling. |

DATA-03 rules:

- Responsive tables retain a single native table tree and expose the shipped in-cell mobile labels; never render a second card list.
- Ordinary IDs, modules, URLs, Unicode/RTL prose, and stack traces use `min-width: 0`, safe wrapping, or the shipped accessible long-value treatment.
- Truncation is visibly signalled and the complete value is keyboard/touch accessible without relying on `title`.
- Only code, args, JSON, or stack-trace regions may horizontally scroll. Each has a visible label, programmatic name, keyboard focus, bounded dimensions, and no trapped arrow-key interaction.
- Empty, loading, unavailable, permission-denied, stale, and partial states remain visually and programmatically distinct at every width.
- Dialogs, drawers, filter disclosures, and adaptive details retain one DOM instance across mode changes.

---

## Focus, Keyboard, and Target Contract

Every production route has a deterministic, full keyboard journey beginning at browser chrome entry:

1. skip link becomes visible on focus and moves focus to `main#obpt-main`;
2. nav toggle and nine-surface navigation expose native button/link behavior and truthful expanded/current state;
3. theme controls, filters, tables/lists, sorting, selection, pagination, detail triggers, disclosures, and supported destinations follow logical DOM order;
4. adaptive details and dialogs receive focus at their labelled heading or first invalid field;
5. Tab/Shift+Tab remain contained only while a modal dialog is active;
6. Escape follows the shipped close policy;
7. close restores the connected invoker, or a documented logical fallback when the invoker was removed;
8. validation moves focus to the invalid field or error summary and keeps its accessible description;
9. LiveView patch, pagination, responsive-mode change, stale preview, partial result, and recovery retain or deliberately restore focus; and
10. sparse `status`/`alert` regions announce durable state once without duplicate or hidden announcements.

Use native/APG behavior; do not add single-key shortcuts. Disabled actions remain perceivable and expose why they are unavailable. Rows are not whole-row click targets. Hover-only and pointer-only access is prohibited.

Focus-not-obscured evidence measures the actual focused element after scroll, sticky shell overlap, dialog open/close, validation, LiveView patch, responsive mode change, and recovery. The focused rectangle must intersect the visual viewport fully enough to identify and operate it, must not be fully covered by fixed/sticky chrome or overlays, and must expose the required visible outline.

Target-size evidence measures rendered bounding boxes and nearest-target spacing. Each failure reports route/story, accessible name, selector, measured width/height, overlap, and whether a standards exception was applied.

---

## Motion Contract

Allowed motion communicates state change only: focus/hover feedback, disclosure or overlay appearance, toast appearance/dismissal, progress/loading feedback, or origin-preserving adaptive detail. There is no idle, ambient, celebratory, parallax, count-up, or decorative motion.

| Token | Normal value | Purpose |
|-------|--------------|---------|
| `--obpt-motion-duration-instant` | 1ms | Stable effectively-instant fallback. |
| `--obpt-motion-duration-fast` | 120ms | Hover, focus, compact control state. |
| `--obpt-motion-duration-base` | 180ms | Overlay, tooltip, toast, detail state. |
| `--obpt-motion-duration-slow` | 240ms | Spinner and skeleton feedback only. |
| `--obpt-motion-ease-linear` | linear | Continuous loading indicator only. |
| `--obpt-motion-ease-standard` | `cubic-bezier(0.2, 0, 0, 1)` | Ordinary state change. |
| `--obpt-motion-ease-enter` | `cubic-bezier(0, 0, 0.2, 1)` | Entry. |
| `--obpt-motion-ease-exit` | `cubic-bezier(0.4, 0, 1, 1)` | Exit. |

Hard rules:

- Every duration/easing comes from a motion token; no inline timing or page-local raw milliseconds/seconds/cubic-bezier values.
- Motion is interruptible and never delays authorization, submit, focus, content, feedback, dialog dismissal, or recovery.
- Both mechanisms work independently: OS `prefers-reduced-motion: reduce` with no root override, and root-scoped `data-obpt-motion="reduce"` while the OS preference is `no-preference`.
- Under either mechanism, non-essential animation is absent and transitions are none or effectively instant.
- Spinner, skeleton, overlay, disclosure, responsive detail, theme/nav control, progress, and LiveView-updated content remain visible, semantically named, and operable. Reduced motion never hides content or suppresses a status/alert announcement.
- Static source validation inventories every `animation`, `transition`, `@keyframes`, duration, and easing in source and packaged CSS. Computed browser evidence proves both mechanisms for every current target and all nine connected routes.

---

## Route Interaction Matrix

The connected lane uses authenticated production composition through `ThemeShell -> AppShell`; showcase success alone cannot satisfy it.

| Route | Required keyboard/focus/reflow journey |
|-------|------------------------------------------|
| Overview | Skip/nav/theme; diagnosis cards and supported drill-downs; active/resolved view; 320px and zoom reflow. |
| Cron | Filters/pagination; detail; pause, resume, and run-now confirmation; validation; stale/partial recovery; Escape and invoker restoration. |
| Limiters | Filtered list; blocked detail and `Why blocked?`; unavailable/Forensics boundary; long evidence handling. |
| Audit | Filters/pagination; bounded event detail; missing/long fields; Audit terminology and immutable-evidence copy. |
| Jobs | Filters, selection, detail, pagination, long values; preview/reason/confirmation/recovery; signed-int64 deep links. |
| Forensics | Diagnosis, timeline/event log, evidence limits, partial/unavailable remediation handoff; bounded machine evidence. |
| Batches | Table/detail, mixed selection, progress, failed-member and callback preview, exact scope, partial result, Audit evidence. |
| Workflows | Read-only list/DAG/step traversal, blocked explanation, stable deep link, unavailable branch, Lifeline handoff; no local mutation controls. |
| Lifeline | Incident/detail, preview, required reason, reauthorization, duplicate suppression, execute/result, drift/expiry/consumed recovery, Audit handoff. |

Every route is checked under all four themes and all three viewport projects for baseline shell, target, overflow, contrast, axe, and copy behavior. Stateful interactions use the smallest deterministic theme/viewport set that exercises each distinct branch, while exact manifest/route matrices ensure no route or branch silently disappears.

---

## Machine-Verifiable Evidence Matrix

Current inventory counts are contractual inputs read from the generated manifest, not constants to maintain by hand. Validators fail on missing, extra, renamed, duplicated, or unregistered targets and on stale artifacts.

| Concern | Required scope | Pass condition | Failure identity |
|---------|----------------|----------------|------------------|
| Inventory | Schema-8 generated manifest; current 163 targets and 99 page stories | Exact kind counts and Elixir-owned ordering; no second target list | schema, kind, target ID |
| Axe | All 163 targets × 4 themes × 3 viewports; all 9 connected routes × 4 themes × 3 viewports, including registered open states | WCAG 2.2 AA tags; zero critical/serious; moderate repaired or narrow standards-backed executable exception | route/story, theme, viewport, rule, node |
| ARIA | 99 page stories × 3 viewports = 297 exact snapshots, plus connected interaction assertions | Exact reviewed snapshots; one H1/tree/dialog; roles, names, states, copy, order, announcements | story/route, viewport, snapshot or role |
| Visual | All 163 targets × 4 themes × 3 viewports = 1,956 compare-only baselines; page subset remains 99 × 4 × 3 = 1,188 | No missing/extra/stale PNG; compare-only green; update mode never evidence | target, theme, viewport, PNG |
| Contrast | Semantic token-pair matrix in light/dark/high-contrast plus computed representative rendered states; system resolved light/dark/more | Numeric thresholds in Color section; no color-only meaning | token pair and rendered control |
| Reflow | All 163 targets and all 9 connected routes at 320/tablet/wide; 200% zoom sweep | ≤1px root/body/document/page overflow; only registered bounded machine scrollers overflow; one tree | target/route, mode, overflow owner |
| Targets | Every rendered pointer target in showcase and connected routes | 2.5.8 24×24-or-spacing; named comfort controls ≥44px one axis; no overlaps | accessible name, box, spacing, exception |
| Keyboard | All nine connected route journeys plus target-specific component/APG behaviors | Native operation, logical order, no trap outside modal, Escape, restore/fallback, announcements | route, step, active element |
| Focus not obscured | After skip, scroll, nav, dialog open/close, invalid submit, LiveView patch, responsive switch, stale/partial recovery | Actual focus visible, outlined, operable, not fully covered | route/story, transition, rect/occluder |
| Motion | Static inventory plus all 163 targets and 9 routes under OS-reduce and explicit-root-reduce independently | Token-owned normal motion; no non-essential reduced motion; no hidden/delayed content/action/focus/announcement | selector, property, mechanism, target |
| BRAND-04 copy | Source registry + all 163 rendered targets + all nine connected journeys | Canonical glossary, forbidden phrases absent, state distinctions and confirmation/recovery order exact | source/route/story and string |
| VoiceOver | Structured representative set covering shell, tables, filters, adaptive detail, dialogs, validation, stale/partial recovery across all nine page families | Required role/name/state/consequence/recovery phrases reached within bounded traversal; transcript and cursor artifact attached | story/route, expected phrase/role |
| Packaging | Source/package CSS, manifest, ARIA, PNGs, scripts, CI order | Byte-identical CSS, repeat-build stability, exact artifacts, unfiltered required graph | source/package path or graph step |

No focused grep, retry, ignored failure, update/watch mode, manual omission, or subjective-only sign-off is completion evidence. Snapshot changes require review as implementation changes and a fresh compare-only run.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | Not applicable—shadcn is not initialized or used. |
| Third-party | none | No registry code enters this phase. |

No new runtime dependency is required or permitted by this contract.

---

## Non-Regression Boundaries

- Keep all nine routes, route parameters, canonical URL state, and authenticated shell behavior unchanged.
- Keep repository/domain reads bounded and server-owned.
- Keep authorization and mutation authority in LiveViews/domain APIs, never CSS, JavaScript, fixtures, stories, or shared presentation components.
- Keep Lifeline preview, reason, reauthorization, execute, duplicate suppression, receipt, and Audit pipeline intact.
- Keep redaction structural: raw/provider-shaped data, preview identity, before/after snapshots, exceptions, reasons, credentials, and fixture sentinels do not leak through text, HTML, attributes, URLs, forms, logs, resources, screenshots, or accessibility artifacts.
- Keep one semantic responsive tree; accessibility repairs do not add duplicate hidden content.
- Keep source and packaged CSS byte-identical and repeat-build stable.
- Do not add Phase 83 showcase stories, contributor documentation, localization infrastructure, a new route, a new operator capability, or a new client-side authority system.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** APPROVED — gsd-ui-checker, 2026-07-29; no flags.
