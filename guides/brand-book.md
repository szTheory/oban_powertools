# Oban Powertools Brand Book

> **Oban Powertools is the calm control room for your background jobs — it explains the state of production in plain language, shows you exactly what an action will do before you do it, and keeps an honest record of what happened.**

> **Version:** v2.0.0-draft · **Status:** Locked (2026-06-18) · **Owner:** Phase 70
>
> Every downstream phase (71–84) cites decision IDs (D-01..D-22) from this document.
> Changes require a new version header entry in the table below.

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v2.0.0-draft | 2026-06-18 | Initial authoring — 22 decisions locked |

This is a CHANGELOG-style header, not a full semver frontmatter system. The version
tracks the brand book's own content version, distinct from the library's published Hex
version. The phrase "Locked (2026-06-18)" signals that downstream phases may cite these
decisions as stable.

### How to read this book

This is the single, versioned, in-repo source of truth for every visual and verbal
decision in the v2.0 "Powertools Identity" milestone. Each section cites its decision ID
(**D-01 … D-22**) inline so that downstream phases — tokens (71), components, forms,
pages, and the final milestone audit (84) — can map every shipped value back to a named
brand-book parent. No orphan styles.

Nothing here is up for re-derivation. The decisions were established via deep per-area
research (brand strategy, color/accessibility, typography, UX-writing) cross-referencing
the project ground truth, then validated and locked with the maintainer. This book
**transcribes and organizes** those locked decisions; it does not relitigate, simplify, or
defer any of them. Where exact hex values, precise rem steps, and final spacing tokens are
intentionally left to Phase 71, the book says so explicitly — it locks the *story, roles,
scale-shape, and contrast intent*, not the literal numbers.

---

## 1. Identity Statement

### D-01 — Essence (locked)

> **Oban Powertools is the calm control room for your background jobs — it explains the
> state of production in plain language, shows you exactly what an action will do before
> you do it, and keeps an honest record of what happened.**

This sentence is the brand book's header line. It is fixed verbatim. Everything else in
this book exists to make that sentence true on every page.

### D-02 — Archetype

The Powertools operator console is an **air-traffic-controller / flight-engineer**: a
**Sage** (truth — "explain") fused with a quiet **Caregiver** spine (protect the operator
from self-inflicted harm).

It is explicitly **NOT**:

- **Hero** ("crush it," "ship fast") — we are not here to make operators feel powerful;
  we are here to make them certain.
- **Magician** (opaque automation that "just works") — we explain, we never conceal.
- **Outlaw / Jester** (PostHog-style whimsy) — there are no jokes at the moment someone
  discards 4,000 live jobs.

### D-03 — Five personality traits

Five traits gate every downstream decision:

**Calm · Precise · Trustworthy · Legible · Restrained.**

> **If the team remembers one word, it is _calm_. Two: _calm + precise_.**

Keep that north-star line in mind for every token, component, and string. A choice that
makes a stressed operator calmer and more certain is on-brand; a choice that adds noise,
decoration, or surprise is not.

---

## 2. What We Are Not

We record the rejected anchors — and *why* they were rejected — so they are not quietly
reconsidered later.

### D-04 — Rejected anchors

- **Modern dev-tool / Linear-gradient SaaS** — *rejected.* Built for fast, low-stakes
  personal productivity; gradients, glow, and colorful chrome **fight** our "color is
  signal" principle (a real alarm can't stand out against decorative color). Steal only
  the craft-bar and component-consistency discipline, never the palette.
- **Terminal / hacker (mono-everything, green-on-black)** — *rejected.* Signals "for
  hackers who already know," which is the opposite of reducing operator fear;
  mono-everywhere harms prose scan-ability; it collapses the severity palette and fails
  light-mode and contrast requirements. Steal only **mono-as-scoped-signal** for literal
  code and IDs.
- **PostHog playful / sarcastic** — *rejected* as a visual register (jokes at the moment
  someone discards live jobs destroy trust). Steal the **opinionated, human, confident
  voice** — personality lives in the *clarity and confidence of the words*, not in
  whimsy.

---

## 3. Codified Brand Principles

These are written as checkable rules, not flavor text. **Principles 1–3 are the
high-leverage three** — the enforceable spine of the identity.

### D-05 — The seven principles

1. **Color is information, never decoration.** *(high-leverage)* Roughly 90% of any
   surface is neutral / grayscale; saturated color is *reserved* to mean "look here —
   this is abnormal or operator-relevant" (ISA-101 High-Performance HMI). No decorative
   accent fills, gradients, or brand-color hero blocks.
2. **Color is never the sole signal.** *(high-leverage)* Every status, validation, and
   severity is carried by **≥2 channels**: color **+** (icon | text label | shape |
   position). A grayscale screenshot of any page must remain fully interpretable — make
   this an explicit VRT / accessibility check.
3. **Every destructive action explains scope before confirm.** *(high-leverage)* Before
   confirm is enabled: the named object(s) + exact count/scope + consequence +
   reversibility, and a required typed **reason**. No bare "Are you sure?".
4. **Affordance honesty** — nothing looks interactive unless it is; interactive things
   always have hover + focus-visible + an accessible name.
5. **Motion is feedback, not flourish** — animation only for state change (appear /
   dismiss / progress / origin), always interruptible, reduced-motion-safe; no idle or
   ambient motion.
6. **One word per concept, everywhere** (see the voice glossary, D-21).
7. **Honesty over polish** — explicit empty / loading / unavailable / permission-denied
   states; error copy says how to recover; never imply a capability or support boundary
   we do not own.

### D-06 — The single coherence test

For any future token, component, or string, apply one test, quoted verbatim:

> **"Does this make a stressed operator calmer and more certain about what will happen —
> or is it decoration, noise, or surprise?"**

The latter is a brand violation.

---

## 4. Color Story

> Exact hex values are **deliberately deferred to Phase 71**. This chapter locks the
> *story, roles, contrast intent, and theming architecture* — not the literal hexes.

### D-07 — Accent / brand hue: differentiate with a cool, indigo-leaning blue

The accent is a **cool, indigo-leaning blue**. ⭐ This was the one fork surfaced to the
maintainer, and it is locked: do **NOT** harmonize with Oban's amber/orange. Three
independent reasons, any one sufficient:

1. **Semantic collision** — amber is already `warning`; an amber accent makes "is this an
   action or a caution?" ambiguous under incident stress.
2. **Ownership honesty** — Powertools is a separate, host-owned layer, not Oban's UI; a
   distinct accent states that boundary truthfully.
3. **Convention / least surprise** — blue is the universal "interactive / safe primary
   action" hue.

Family-feel to Oban lives only in small warm touches (empty-state illustration, wordmark)
and in being a good cool-chrome neighbor to Oban Web's amber in the bridge.

### D-08 — Neutral base: cool slate

The neutral base is **cool slate** (blue-undertone gray) for surface, elevated, border,
text, and muted roles. This keeps the *warm* spectrum free so amber and red alarms pop
against cool chrome — maximum perceptual separation between the frame and the signal.
Rejected: warm/stone (bleeds into warning/danger) and true-neutral (reads undesigned).

### D-09 — Semantic status roles (locked by convention)

- `info` = **blue, cyan-shifted** — a **distinct role and hue from the indigo accent**.
  The accent never appears in a status pill; `info` never appears as a button.
- `success` = **green**.
- `warning` = **amber**.
- `danger` = **red**, given the **highest chroma and reserved exclusively** for
  destructive / irreversible / error states — never decoration, never "active/recording."

### D-10 — Two-tier token philosophy

- **Tier 1 — primitive palette:** the full slate ramp + per-status hue ramps. This is
  **the only place raw hex lives**, and it is theme-agnostic.
- **Tier 2 — semantic roles:** `--obpt-color-surface / elevated / border / text / muted /
  accent / info / success / warning / danger`, plus `-fg / -bg / -border / -solid`
  sub-roles.

**Components reference Tier-2 roles only.** A theme switch re-points Tier 2 at different
Tier-1 primitives — theming becomes re-pointing, not rewriting. Accessibility/contrast is
enforced at one chokepoint; the role names are a **semver-protected public contract**; and
"no raw hex in components" is grep- and lint-checkable.

### D-11 — Light / dark / high-contrast = three distinct token sets (NOT CSS filters)

Three real token sets, never CSS filters over one. Documented pitfalls this book commits
to:

- Dark `surface` is a **near-black slate (~#0E1116), never pure #000**.
- **Elevation steps go LIGHTER in dark** (surface → elevated → overlay); depth comes from
  lightness + border, not shadow.
- **Desaturate accents and status ~10–20% on dark.**
- **`muted` has a hard ≥4.5:1 floor** — the most-failed dashboard accessibility miss.
- **Amber/yellow text must darken** (deep amber / brown-gold, ~amber-700/800) to pass
  4.5:1 in light mode; bright amber lives only in border, fill, or glyph.
- **High-contrast** is enhanced ratios (body text ≥7:1, WCAG 1.4.6), solid borders over
  tinted fills, thicker focus; it honors `prefers-contrast: more` plus a manual toggle.

### D-12 — Contrast targets and colorblind safety

Contrast intent (Phase 71 sets the exact hexes that satisfy these):

- Text **≥7:1**.
- `muted` **≥4.5:1** (hard floor).
- Non-text / borders / inputs / focus **≥3:1** (WCAG 1.4.11).
- Focus indicator **≥2px** perimeter **+ ≥3:1** versus both states (WCAG 2.4.11 / 2.4.13).

**Colorblind safety is mandatory** (success/danger are the red/green confusion pair, ~8%
of male operators):

- Distinct **icon silhouettes** (check / ✕-octagon / triangle-! / circle-i).
- **Luminance separation** — grayscale must still distinguish status.
- Lean **success → emerald** and **danger → true-red** apart.

---

## 5. Typography & Density

> Exact rem steps and final spacing values are **deferred to Phase 71**. This chapter
> locks the font strategy, the mono-as-signal rule, the scale shape, and the density
> posture.

### D-13 — System fonts only (locked constraint)

Use **explicit Primer-style cascades, NOT bare `system-ui`** (it breaks non-Latin and
Firefox rendering). Verbatim cascades:

- **Sans:** `-apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"`
- **Mono:** `ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", "DejaVu Sans Mono", monospace`

We state plainly: *we accept per-OS letterform variance as the cost of zero webfont
weight; the identity lives in color, spacing, hierarchy, mono-as-signal, and voice — not a
typeface.* (Custom webfonts are out of scope for the foundation; the system-font decision
is a deliberate, revisitable tradeoff.)

### D-14 — Monospace = signal, not default

Mono is scoped to *literal machine values* only:

- Job / batch / workflow IDs and fingerprints / hashes / trace IDs. **Truncate the
  MIDDLE** — the discriminating bytes are at both ends — plus a copy affordance and the
  full value on tooltip/tap.
- Module / worker names (preserve the trailing segment, e.g. `…Workers.SendEmail`).
- Args / JSON viewers, stacktraces, cron expressions, queue names, `Kbd`, inline code.

**Numbers stay in SANS with `font-variant-numeric: tabular-nums`** (expose a
`--obpt-numeric-tabular` feature token) for all numeric/metric/timestamp columns and
live-updating counts — no horizontal digit jitter on refresh. Over-using mono destroys the
signal and reads "everything is code."

### D-15 — Type scale & density

- A rem-based **~1.2 minor-third ladder**; **body 0.875rem/14px, dense-row
  0.8125rem/13px**; unitless line-heights snapped to the 4px grid; **four weights** (400
  body / 500 labels-emphasis / 600 headings; avoid 700+ "heavy" and 300 "light").
  Display/h1/h2/h3 = 28 / 24 / 20 / 18px.
- **Density posture: "calm but information-dense"** — denser than a marketing dashboard,
  calmer than a Bloomberg terminal. **4px spacing base** (`space-1..7` = 4 / 8 / 12 / 16 /
  24 / 32 / 48), ~32–36px table rows (~15–20 rows visible without scroll). Density comes
  from **hierarchy + consistent rhythm**, never sub-readable fonts (12px floor for primary
  data). Model: Linear's "task-central elements in focus, navigation recedes."
- **Long-content handling (DATA-03):** mandate the **`min-width: 0` flex rule** (the #1
  cause of broken ellipsis / 320px horizontal scroll); **always signal truncation
  visibly** (the Sentry footgun); tables degrade to a **stacked card / KeyValue fallback
  at 320px** (also the WCAG-reflow-exempt path); page-level horizontal scroll is never
  allowed (only bounded code/args blocks scroll internally). Verify every showcase story
  at **200% zoom** (WCAG 1.4.4 / 1.4.10).

---

## 6. Voice & Microcopy

### D-16 — Register and the canonical confirm template

Register: **plain, consequence-first, explanatory-without-chatter.**

Canonical confirm template (verbatim):

> **Cancel 3 running jobs? They stop now and won't retry. This can't be undone.**

Rejected: clinical-terse ("Cancel 3 jobs?" — fails the "explain" half, confirms on
incomplete information) and warm-reassuring ("Don't worry…" — condescends to expert
operators and wastes scan-time).

### D-17 — Five voice traits (each with a guardrail)

- **Precise** — not cryptic.
- **Calm** — not cute.
- **Honest** — not hedging.
- **Plain** — not jargon, not passive.
- **Respectful** — not infantilizing. The friction is the typed count, not a scolding
  tone.

### D-18 — "Explain, then act" as an enforceable copy contract

The **"explain, then act"** principle is baked into the shared `ConfirmActionDialog` /
`<.danger_form>` so the 9 pages compose it and never re-author it.

A destructive confirmation **MUST**:

1. **Name the object** (id / worker, not "this item").
2. **State consequence + scope** — including jobs *outside the current view* for bulk
   actions.
3. **State reversibility.**
4. **Require a typed reason** → audit log.

**Friction scales with blast radius:**

- Single reversible (retry / pause) = reason + one-click, **warning-weight** button.
- Single irreversible (cancel / discard) = required reason + confirm, **danger-weight**.
- Bulk = required reason + **"type the count to confirm"** + an out-of-view scope warning.

**The dismiss button never mirrors the verb** — use "Keep running," never "Cancel," on a
cancel-job dialog. Reversibility drives button weight (pause = warning, not danger).

### D-19 — State copy (calm, not cute)

- **Empty** = fact + next action.
- **Loading** = name *what's* loading (skeletons for tables), never a bare spinner.
- **Error MUST say how to recover** — banned: "Something went wrong" / "An error
  occurred."
- **Permission-denied** = render disabled with a reason tooltip ("Cancel — requires
  operator role"), never silently hidden.
- Distinguish **stale vs unavailable vs empty vs permission-denied**.
- **Success toasts** confirm what *actually* happened in the action's vocabulary; only
  show Undo if it genuinely works.

### D-20 — Honesty / support-truth rule

Voice never promises outcomes the library doesn't own. Say what *Powertools* did
(requested, recorded, audited), not what the host's infra will do:

- "Retry requested. Job re-enters the default queue." — **not** "Job fixed!"
- "It stops at the next checkpoint." — **not** "Job stopped."

One false "done!" burns the trust that is the whole adoption thesis.

### D-21 — Canonical glossary (one term per concept)

Literals are centralized (e.g. `ObanPowertools.Copy` / gettext, grep-enforceable, no
inline string literals) so the same word means the same thing across all 9 pages and the
audit log.

| Term | Meaning | Not to be confused with |
|------|---------|-------------------------|
| **Cancel** | Stop now; terminal; no retry. | Discard, Delete |
| **Discard** | Mark dead / exhausted; final. | Cancel, Delete |
| **Delete** | Actual DB row removal; retention-only; rarely inline. | Cancel, Discard |
| **Retry** | Re-enqueue. | — |
| **Pause / Resume** | Cron / queue; reversible. | — |
| **Job / Worker** | The unit of work / its module. | — |
| **Blocked** | + explain: paused queue / saturated limiter / unmet dependency. | "stuck" (reserved) |
| **Preview** | Dry-run. | — |
| **Repair** | Lifeline mutation. | — |
| **Reason** | Required justification → audit. | — |
| **Audit log / trail** | The record of operator actions. | "event log" (reserved) |
| **Limiter** | The rate/concurrency control. | — |

`Cancel ≠ Discard ≠ Delete` mirror real Oban states so operators learn one model. Reserve
**"stuck"** for orphan detection; reserve **"event log"** for the forensics timeline (not
the audit log).

---

## 7. Traceability Table

### D-22 — No orphan styles

Every planned downstream token category maps back to a named brand decision above. Phases
71–84 cite these decision IDs so `gsd-ui-review` and the milestone audit (Phase 84) can
verify every shipped value has a brand-book parent. This satisfies **BRAND-05**.

| Downstream token category | Mandating decision ID(s) | What it constrains |
|---------------------------|--------------------------|--------------------|
| Color roles (accent / neutral) | D-07, D-08, D-10 | Indigo-blue accent, cool-slate neutral base, two-tier role names referenced by components |
| Status taxonomy | D-09, D-12 | info/success/warning/danger roles, reserved-danger-chroma, colorblind silhouettes & luminance separation |
| Theme sets (light/dark/high-contrast) | D-11, D-12 | Three distinct token sets, dark elevation-lighter, muted ≥4.5:1 floor, contrast targets |
| Type scale | D-13, D-15 | System-font cascades, ~1.2 minor-third ladder, body 14px / dense-row 13px, four weights |
| Spacing | D-15 | 4px base, `space-1..7` (4/8/12/16/24/32/48), 32–36px rows, "calm but information-dense" posture |
| Radii | D-03, D-06 | Restrained, calm geometry; subject to the coherence test (no decorative flourish) |
| Elevation | D-11 | Depth from lightness + border (not shadow); elevation steps lighter in dark |
| Motion | D-05 (principle 5) | Feedback only (appear/dismiss/progress/origin), interruptible, reduced-motion-safe, no ambient motion |
| Mono-vs-tabular | D-14 | Mono scoped to literal machine values; numbers stay in sans with tabular-nums |
| Voice patterns | D-16, D-17, D-18, D-19, D-20 | Register, five traits, "explain, then act" copy contract, state copy, support-truth honesty |
| Terminology / glossary | D-21 | One term per concept; Cancel ≠ Discard ≠ Delete; reserved words |
| Coherence gate (applies to all) | D-01, D-03, D-06 | Essence, five traits, and the single coherence test that every token/component/string must pass |

---

*Phase: 70-brand-book-identity-foundation · Brand book v2.0.0-draft · Locked 2026-06-18*
