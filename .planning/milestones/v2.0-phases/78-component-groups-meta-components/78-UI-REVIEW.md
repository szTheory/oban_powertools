# Phase 78 — UI Review

**Audited:** 2026-07-19
**Baseline:** Approved `78-UI-SPEC.md`, `78-CONTEXT.md`, Plans 78-01..78-08, and implemented summaries
**Screenshots:** Canonical 276-image group matrix inspected; representative corrected confirmation/detail overlays and attention, blocker, audit, and filter stories reviewed across light, dark, high-contrast, 320, tablet, and wide. No new capture was made because no project app server was available on 3000/5173/8080; port 8080 was Traefik.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | Core labels are specific, but the destructive and pending reference stories contain contradictory or duplicated safety copy. |
| 2. Visuals | 2/4 | Corrected overlays are coherent, but non-overlay stories are compressed into narrow grid cells and the showcase leaks styles into the components it is meant to prove. |
| 3. Color | 3/4 | Semantic tokens, restrained severity markers, and four-theme separation are strong; disabled action meaning still depends too heavily on desaturation. |
| 4. Typography | 2/4 | Component tokens are disciplined, but showcase overrides and audit-header allocation produce visibly degraded hierarchy and letter-by-letter status pills. |
| 5. Spacing | 2/4 | Overlay rhythm is sound, but story widths/row stretching create very tall captures and seven Phase 78 rules use the contract-excluded 12px token. |
| 6. Experience Design | 2/4 | Connected behavior is unusually thorough, yet sighted permission recovery is hidden and accepted confirmation feedback is visually repetitive. |

**Overall: 13/24**

**Ship classification:** No Phase 78 task-completion blocker was found under the audit rubric. The warnings below should be fixed before treating the showcase as the adoption reference for Phases 79–81. Phase 82 still owns the broader cross-page manual screen-reader, zoom, motion, and contextual page sweep.

---

## Top 3 Priority Fixes

1. **Isolate group stories and give them representative width** — Broad `.obpt-showcase-story` descendant rules currently restyle nested component headings and prose, while the generic `minmax(14rem, 1fr)` grid reduces “wide” non-overlay captures to about 271px. Scope metadata rules to direct children, make group story stages span a full row or use a group-specific layout, and set grid items to start rather than stretching to the tallest story. Regenerate the group baselines afterward.
2. **Correct confirmation reference copy and submitting presentation** — The destructive story says “Discard job” while retaining retry-specific support/reason copy; the pending story repeats the non-cancel sentence and leaves a disabled-looking Retry action visible. Supply action-specific fixture fields, keep `pending_copy` to the named work only, and visually replace the action row after acceptance.
3. **Protect compact status and permission-recovery layouts** — Audit outcome pills wrap to two lines at tablet and one character per line in wide story captures, and the long AttentionCard hides “Requires operator role” in screen-reader-only text. Stack audit status/time below the heading at constrained component widths and render the disabled reason visibly beside the action.

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING — destructive story vocabulary contradicts the action.** The shared fixture defines retry-specific support and reason text at `test/support/operator_pattern_story_catalog.ex:24-25`; `group-confirm-single-destructive` changes the title, consequence, reversibility, action, and pending copy but inherits those retry fields at `test/support/operator_pattern_story_catalog.ex:145-161`. The corrected light/wide capture therefore asks “Discard job?” while saying “A retry request does not mean the job completed” and pre-filling “Provider recovered; retry…”. This violates the locked noun/verb consistency and weakens an irreversible decision.
- **WARNING — accepted-state copy is duplicated.** The pending fixture includes the full non-cancel sentence in `pending_copy` at `test/support/operator_pattern_story_catalog.ex:187-201`, while the component independently renders the same sentence at `lib/oban_powertools/web/components/operator_patterns.ex:201-216`. The canonical pending overlay visibly repeats it.
- **WARNING — a provider-shaped identifier becomes the headline.** The long AttentionCard assigns the worker module as the title at `test/support/operator_pattern_story_catalog.ex:442-458`. In the 320/dark capture it becomes the largest, boldest text, contrary to the contract that machine/provider values remain supporting evidence. Use a human answer such as “Notification delivery requires operator review” and move the worker name to technical evidence.
- **Pass evidence:** Action labels such as “Retry 12 jobs”, “Keep current state”, “Apply filters”, “Clear filters”, “Open full details”, missing audit-field copy, and current-versus-snapshot terminology are specific and grammatical. No prohibited bare Confirm/Cancel, generic error, or `N/A` copy was found in the implemented group surface.

### Pillar 2: Visuals (2/4)

- **Pass evidence — corrected overlays now show the actual surfaces.** Commit `4462e54` replaced clipped story-card proxies for all ten overlay stories. The inspected wide destructive confirmation, 320 bulk confirmation, tablet partial result, wide inline detail, 320 modal detail, and tablet long-detail captures show complete overlay frames, visible headings, and action/close affordances. The confirmation hierarchy is especially clear: object, title, scope, consequence marker, reversibility, support boundary, form/result, then actions.
- **WARNING — the showcase is not visually isolated from its specimens.** Rules at `assets/oban_powertools/tokens.css:3392-3417` target any `h3` or `p` below `.obpt-showcase-story`, not only story metadata. Later rules at `assets/oban_powertools/tokens.css:3542-3548` target any nested `header p`, forcing the WhyBlocked explanation into uppercase 12px metadata styling. These selectors override Phase 78 component color, type, and margin rules inside the showcase.
- **WARNING — “wide” non-overlay stories are still narrow-card tests.** The generic story grid at `assets/oban_powertools/tokens.css:3515-3521` produces representative light captures of 224px at the 320 project, 313px at tablet, and only 271px at wide. The wide `group-detail-inline` surface is 237px. This is useful stress coverage, but it is not persuasive wide-layout aesthetic evidence and reverses the expected viewport relationship.
- **WARNING — the baseline frame contains substantial irrelevant area.** Examples such as wide `group-why-blocked-live-vs-snapshot` and audit stories are 271×3182, with large blank tails caused by equal-height grid rows/cropped story cards. Pixel stability remains valid, but the captured composition makes regressions harder to review and compare.

### Pillar 3: Color (3/4)

- **Pass evidence:** Phase 78 group rules resolve through semantic `--obpt-color-*` roles; raw palette values remain in the token layer. Light, dark, system, and high-contrast captures preserve readable surfaces, neutral-dominant chrome, and distinct warning/danger/success/info borders and pills. Attention severity uses a restrained 4px edge rather than saturated card fills.
- **Pass evidence:** State is paired with visible labels and glyphs (`Available`, `Retryable`, `Discarded`, `Completed`; `Neutral`, `Warning`, `Danger`, `Info`) rather than color alone. Confirmation danger and warning actions are visually distinct without coloring the whole dialog.
- **WARNING — disabled meaning is visually under-explained.** The permission-denied AttentionCard passes `disabled_reason` in `lib/oban_powertools/web/dev/showcase_live.ex:1411-1418`, but `Primitives.button` renders that reason only in `.obpt-sr-only` at `lib/oban_powertools/web/components/primitives.ex:66-81`. For sighted users, the muted button color is the only immediate explanation that the action is unavailable.

### Pillar 4: Typography (2/4)

- **Pass evidence:** The group CSS uses the contracted `sm`, `md`, `xl`, and computed 20px title treatment with only regular and semibold weights. Machine evidence uses mono while sentence copy remains sans.
- **WARNING — audit outcomes become illegible at constrained component width.** `assets/oban_powertools/tokens.css:2618-2630` gives the header `minmax(0, 1fr) auto`; with the long absolute time in the auto column, the status pill is squeezed. The tablet capture splits “Success” and “Failed” across lines, while the 271px wide capture places nearly every character on its own line. `overflow-wrap: anywhere` on the shared pill at `assets/oban_powertools/tokens.css:1192-1207` makes the failure deterministic rather than readable.
- **WARNING — showcase selector precedence changes the approved hierarchy.** The later `.obpt-showcase-story h3` rule forces nested component `h3` elements to 14px at `assets/oban_powertools/tokens.css:3409-3411`, overriding the 18px group-heading rule at `assets/oban_powertools/tokens.css:2457-2469`. The canonical WhyBlocked captures therefore under-emphasize blocker titles and section headings.
- **WARNING — long machine values are tested in headline roles.** The worker-module AttentionCard title and audit sentence/target density create walls of bold wrapped identifiers. Long-content resilience is proven, but the presentation does not preserve the contract’s human-answer-first hierarchy.

### Pillar 5: Spacing (2/4)

- **Pass evidence:** Confirmations use 24px wide padding and 16px mobile padding; 320 action rows stack with at least 8px separation. Detail surfaces preserve one scroll owner, 16px mobile padding, and clear header/body/evidence/footer boundaries. Cards generally maintain 16–24px section rhythm.
- **WARNING — Phase 78 uses a spacing token excluded by its own contract.** Within the group CSS, `--obpt-space-3` (12px) appears seven times: `assets/oban_powertools/tokens.css:2453`, `2611`, `2810`, `2828`, `2861`, `2883`, and `3233`. The approved Phase 78 subset is 4, 8, 16, 24, 32, and 48px. Replace these with the nearest contracted rhythm unless a documented exception is added.
- **WARNING — generic grid packing creates excessive vertical rhythm and blank capture space.** Four attention cards and three audit entries are stacked inside narrow story columns, while CSS Grid stretches neighboring stories to the tallest row. The result is multi-thousand-pixel artifacts that obscure the intended calm scan hierarchy.
- **Advisory:** Keep the hostile-width stress story, but add a separate full-width specimen or make each group story stage span the group grid. Narrow stress and wide composition are different visual questions and should not share one capture.

### Pillar 6: Experience Design (2/4)

- **Pass evidence:** The interaction design is strong: parent-owned draft/applied truth, destructive reason/count friction, modal versus inline detail behavior, result recovery, focus restoration, exact live regions, and one responsive DOM are all reflected in implementation and connected evidence. The 276-case axe pass and 37 connected behavior passes materially support keyboard and state quality.
- **WARNING — permission recovery is not visible to sighted operators.** The long AttentionCard is explicitly a permission-denied state, but its capture shows an unavailable action with no “Requires operator role” explanation. The secondary Audit/Forensics routes keep the task from being a release blocker, but this still violates the phase contract’s visible reason/recovery expectation.
- **WARNING — the accepted confirmation keeps an action-looking control.** `lib/oban_powertools/web/components/operator_patterns.ex:219-237` retains the submit button during `:submitting`; the canonical pending capture shows a muted “Retry job” button below the busy panel. Combined with duplicated non-cancel copy, this makes the terminal interaction state less decisive than the spec’s “replace action affordance with one named busy message” direction.
- **WARNING — VRT success should not be read as aesthetic approval.** Exact 276/276 comparison proves stability. It does not resolve the narrow story columns, CSS cascade bleed, vertical status pills, copy contradictions, or blank capture tails found here.
- **Phase 82 boundary:** Do not charge Phase 78 for production-page placement, real operator workflow density, cross-page navigation context, manual screen-reader narration quality, or the broader manual 200% zoom/motion sweep. Those remain downstream adoption/manual-review work.

---

## Scope Classification

### Phase 78 Blockers

None under the audit definition of a defect that prevents task completion. The corrected overlay capture blocker from fresh verification is closed by `4462e54`.

### Phase 78 Warnings

1. Destructive and pending confirmation fixture copy is internally inconsistent or duplicated.
2. Showcase descendant selectors leak metadata styling into group components.
3. Generic story-grid sizing makes wide non-overlay evidence narrower than tablet and produces blank stretched captures.
4. Audit outcome pills collapse to multi-line or single-character columns.
5. Permission-disabled reason is not visible to sighted operators.
6. Provider-shaped worker identifiers become primary headlines.
7. Seven group rules use the contract-excluded 12px spacing token.

### Advisory / Downstream

- Add a full-width group specimen/capture mode in addition to hostile narrow-card coverage.
- Reassess final page-level information density when Phases 79–81 adopt the groups.
- Complete the manual cross-page screen-reader, zoom, motion, and aesthetic sweep in Phase 82.

---

## Files Audited

- `.planning/phases/78-component-groups-meta-components/78-CONTEXT.md`
- `.planning/phases/78-component-groups-meta-components/78-UI-SPEC.md`
- `.planning/phases/78-component-groups-meta-components/78-01-PLAN.md` through `78-08-PLAN.md`
- `.planning/phases/78-component-groups-meta-components/78-01-SUMMARY.md` through `78-08-SUMMARY.md`
- `lib/oban_powertools/web/components/operator_patterns.ex`
- `lib/oban_powertools/web/components/primitives.ex`
- `lib/oban_powertools/web/components/data_display.ex`
- `lib/oban_powertools/web/control_plane_presenter.ex`
- `lib/oban_powertools/web/status_taxonomy.ex`
- `lib/oban_powertools/web/dev/showcase_live.ex`
- `assets/oban_powertools/tokens.css`
- `assets/oban_powertools/theme.js`
- `test/support/operator_pattern_story_catalog.ex`
- `test/browser/specs/operator-patterns.behavior.spec.ts`
- `test/browser/specs/showcase.structure.spec.ts`
- `test/browser/specs/showcase.a11y.spec.ts`
- `test/browser/specs/showcase.vrt.spec.ts`
- `test/browser/support/showcase.ts`
- `test/browser/support/manifest.ts`
- Canonical `test/browser/__screenshots__/chromium-{320,tablet,wide}/showcase/group-*/*.png` inventory, with representative visual inspection of confirmation, detail, filter, attention, WhyBlocked, and audit stories across themes and viewports.
