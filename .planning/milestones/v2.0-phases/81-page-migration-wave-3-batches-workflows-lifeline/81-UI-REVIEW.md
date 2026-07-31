# Phase 81 — UI Review

**Audited:** 2026-07-29
**Baseline:** `81-UI-SPEC.md` and `81-CONTEXT.md`
**Implementation baseline:** `fd4a7d0` (`fix(phase-81): remove duplicate forensic link`)
and `5786aa2` (`test(phase-81): assert one forensic destination`)
**Screenshots:** regenerated committed ARIA/PNG evidence inspected; no Phase 81
dev server was available for a fresh capture (`3000` and `5173` were closed;
`8080` returned an unrelated redirect)
**Status:** passed — no blockers or advisory warnings remain

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | All locked copy is present, and Workflows renders exactly one explicitly named forensic destination. |
| 2. Visuals | 4/4 | Batches and Workflows now have the required page hierarchy, and Batches uses the shared `why_blocked/1` composition. |
| 3. Color | 4/4 | Workflows ownership states now use root-scoped semantic token roles with text and `data-*` meaning; no raw ownership utility palette remains in the active page. |
| 4. Typography | 4/4 | Batches and Workflows bind title/intro tokens directly, and showcase metadata no longer reaches into nested production headers. |
| 5. Spacing | 4/4 | The 320px table treatment stacks label/value content without fragmenting ordinary labels or hiding actions. |
| 6. Experience Design | 4/4 | Confirmation stories are truthful production dialogs and all three stale Lifeline states expose the explicit fresh-preview recovery path. |

**Overall: 24/24**

---

## Final Closure Recheck

The sole remaining warning is resolved. `workflows_live.ex:298-302` renders one
forensics section with exactly one `forensic_path/2` link labelled
`Open forensic evidence`; the generic `evidence link` is absent. The focused
LiveView regression now asserts exactly one rendered `/ops/jobs/forensics?...`
destination (`workflows_live_test.exs:316-337`).

The focused component/theme/Batches/Workflows/Lifeline suite passed with
**103 tests, 0 failures**. No regression was found in the prior 23/24 results.

---

## Previous Finding Recheck

| Previous finding | Final result | Evidence |
|------------------|--------------|----------|
| Batches/Workflows page-title hierarchy was visually weak | **Resolved** | Active H1/intro markup uses `obpt-page__title` and `obpt-page__intro` (`batches_live.ex:352-362,690-694`; `workflows_live.ex:100-104`); the token selector is 28px/600 at `tokens.css:3753-3765`. Regenerated wide and 320px PNGs show the page title as the intended focal point. |
| Showcase metadata uppercased nested production introductions | **Resolved** | The selector is now direct-child-only: `.obpt-showcase-story > header > p` (`tokens.css:3565-3571`). Regenerated introductions are sentence case. |
| Workflows empty/unavailable recovery copy drifted | **Resolved** | Exact empty copy is at `workflows_live.ex:117-118`; exact non-enumerating unavailable copy and `Return to Workflows` recovery are at `workflows_live.ex:143-158` and in the regenerated ARIA snapshots. |
| Forensics destination did not use locked copy | **Resolved** | The production Workflows and Lifeline destinations read `Open forensic evidence` (`workflows_live.ex:298-302`; `lifeline_live.ex:388-390`). Workflows renders the destination exactly once, and the focused test enforces that cardinality. |
| Workflows used raw ownership color utilities | **Resolved** | `follow_up_row_class/1` returns semantic classes (`workflows_live.ex:607-612`); their root-scoped accent/neutral/warning roles are token-backed (`tokens.css:4229-4247`). No active Workflows indigo/slate/amber utility recipe remains. |
| Batches substituted generic surfaces for `why_blocked/1` | **Resolved** | `OperatorPatterns.why_blocked/1` is the active blocked explanation at `batches_live.ex:416-426`; bulk/callback ARIA exposes the complete labelled region. |
| Batches ordinary words fragmented at 320px | **Resolved** | The shared table reserves readable label space, disables arbitrary label breaking, and Phase 81 narrows to one-column cells (`tokens.css:1797-1824,4290-4302`). The regenerated 320px mixed-selection artifact keeps `Operator status`, `Progress`, `Callbacks`, `Updated`, and `Actions` intact. |
| Batches confirmation stories were not truthful dialogs | **Resolved** | All six reviewed ARIA snapshots contain the named dialog, exact consequence, Reason field, `Keep current state`, and action-specific submit. Wide PNGs show the real shared modal rather than static page copy. |
| Lifeline stale recovery omitted `Create new preview` | **Resolved** | The production recovery action is at `lifeline_live.ex:492-503`; all nine drifted/expired/consumed ARIA snapshots include it, and the focused LiveView test exercises the event path. |

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- The three page introductions match the locked contract
  (`batches_live.ex:691-694`, `workflows_live.ex:101-104`,
  `lifeline_live.ex:268-273`).
- Workflows now uses the exact empty and unavailable language, including the
  recovery route (`workflows_live.ex:117-118,143-158`).
- Batches dialog consequence, dismiss, and submit copy remains exact in all
  reviewed ARIA families. Lifeline stale copy names the specific stale
  condition and offers `Create new preview`.
- Workflows renders one `Open forensic evidence` link
  (`workflows_live.ex:298-302`) and no generic duplicate. The focused test
  asserts exactly one rendered forensics URL while preserving the workflow and
  step selectors (`workflows_live_test.exs:316-337`).

### Pillar 2: Visuals (4/4)

- Batches and Workflows titles now establish the page identity above support
  truth and primary data. Representative wide, 320px, light, and
  high-contrast artifacts show a clear H1/body/section hierarchy.
- Batches uses the shared `OperatorPatterns.why_blocked/1` region with summary,
  current evidence, clearing condition, impact, freshness, and completeness
  (`batches_live.ex:416-426`).
- Active Batches, Workflows, and Lifeline composition remains shared and
  single-tree; no new local table, badge, dialog, or blocked-state substitute
  was introduced by `2652bd0`.

### Pillar 3: Color (4/4)

- Workflows ownership rows use
  `obpt-runbook-ownership--native|bridge|host`
  (`workflows_live.ex:607-612`). Base/bridge is neutral, native uses semantic
  accent, and host-owned follow-up uses semantic warning
  (`tokens.css:4229-4247`).
- Meaning is also exposed as visible ownership text and
  `data-runbook-ownership` / `data-runbook-variant`; color is not the sole
  carrier.
- Source checks found no active Workflows indigo, slate, or amber utility
  ownership recipes. Reviewed light and high-contrast PNGs preserve readable
  borders, surfaces, and text.

### Pillar 4: Typography (4/4)

- Batches list/detail/unavailable H1s and introductions use the shared title
  and intro classes (`batches_live.ex:352-362,690-694`); Workflows does the
  same (`workflows_live.ex:100-104`).
- `obpt-page__title` resolves to the single shipped 28px/600 token family and
  `obpt-page__intro` resolves to the body/relaxed token family
  (`tokens.css:3753-3779`).
- The showcase selector is direct-child-only
  (`tokens.css:3565-3571`), so story metadata no longer changes nested
  production intro casing or weight.

### Pillar 5: Spacing (4/4)

- Shared DataTable cells use finite grid content and token gaps
  (`tokens.css:1659-1666`). At narrow widths, labels do not use arbitrary
  wrapping, ordinary values use `break-word`, and Phase 81 page cells stack
  label above value (`tokens.css:1797-1824,4290-4302`).
- The reviewed Batches 320px artifact keeps all field labels, values, status
  controls, filters, `Open batch`, and pagination reachable without ordinary
  word fragmentation or page-level clipping.
- Workflows high-contrast 320px remains a single readable semantic flow; long
  machine evidence wraps inside its bounded treatment.

### Pillar 6: Experience Design (4/4)

- Bulk and callback confirmation ARIA snapshots across all three viewports
  expose one named dialog, exact scope/consequence/support truth, a labelled
  reason field, safe dismissal, and the correct submit action.
- The reviewed wide bulk-confirmation PNG shows genuine modal containment and
  consequence-first ordering. The active production tests retain focus,
  Escape, restoration, authority, and confirmation contracts.
- Drifted, expired, and consumed Lifeline snapshots across all three
  viewports expose `Create new preview`; the 320px drifted PNG presents the
  exact condition, recovery action, and `Keep current state` without implying
  automatic replay.
- The focused component/theme/Batches/Workflows/Lifeline test command passed
  with **103 tests, 0 failures** after the duplicate-link fix.
  Exact validators passed for **297 ARIA snapshots**, **1,188 PNG paths**,
  **99 page stories**, and **163 manifest targets**. Source and packaged CSS
  are byte-identical.

---

## Blocking vs Advisory Summary

### Blockers

None.

### Advisory Warnings

None.

---

## Registry Safety

No `components.json` exists and the UI contract declares no shadcn or
third-party registry blocks. Registry audit skipped as not applicable.

## Files and Evidence Audited

- `81-CONTEXT.md`, `81-UI-SPEC.md`, all Phase 81 plans/summaries, and the prior
  `81-UI-REVIEW.md`
- commits `2652bd0`, `fd4a7d0`, and `5786aa2`
- `lib/oban_powertools/web/batches_live.ex`
- `lib/oban_powertools/web/workflows_live.ex`
- `lib/oban_powertools/web/lifeline_live.ex`
- `lib/oban_powertools/web/components/data_display.ex`
- `lib/oban_powertools/web/components/operator_patterns.ex`
- `assets/oban_powertools/tokens.css` and packaged CSS
- focused DataDisplay, theme-token, Batches, Workflows, and Lifeline tests
- representative wide and 320px Batches/Workflows/Lifeline PNGs in light and
  high-contrast themes
- all Batches bulk/callback and Lifeline drifted/expired/consumed ARIA families
- exact manifest, ARIA, and PNG validators
