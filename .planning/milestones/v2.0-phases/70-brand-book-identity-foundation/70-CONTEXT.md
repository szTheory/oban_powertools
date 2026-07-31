# Phase 70: Brand Book & Identity Foundation - Context

**Gathered:** 2026-06-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Author the **brand book** — the single, versioned, in-repo source of truth for every visual and verbal decision in the v2.0 "Powertools Identity" milestone. Deliver it as Markdown **+ a dev-rendered route**, linked from the README (DOC-03 initial).

The brand book must cover: brand essence/positioning + the codified **"explain, then act"** principle (BRAND-01); the full color story across light/dark/high-contrast with documented contrast targets (BRAND-02); typography/spacing/radii/elevation/iconography/motion principles (BRAND-03); voice & microcopy rules (BRAND-04); and a **traceability table** so every later token/component traces back to a named brand decision — no orphan styles (BRAND-05).

**Documentation + intent ONLY.** No code/UI changes to the 9 operator pages this phase. The brand book defines *what* every downstream phase (71 tokens → 84 audit) must honor; it does not implement tokens, components, or pages.

This phase had no SPEC.md; the decisions below were established via deep per-area subagent research (brand strategy, color/a11y, typography, UX-writing) cross-referencing the project ground truth, and validated/locked with the user. The research **validated and sharpened** the working hypothesis: a calm, precise, trustworthy **control-room/console** identity is not a vibe choice — it is forced by the product's physics (operators mutating live production jobs under stress) and corroborated by ISA-101 High-Performance HMI discipline.
</domain>

<decisions>
## Implementation Decisions

### Brand Personality / Essence (BRAND-01)
- **D-01 — Essence (locked):** *"Oban Powertools is the calm control room for your background jobs — it explains the state of production in plain language, shows you exactly what an action will do before you do it, and keeps an honest record of what happened."* This is the brand book's header line.
- **D-02 — Archetype:** Air-traffic-controller / flight-engineer — **Sage** (truth, "explain") fused with a quiet **Caregiver** spine (protect the operator from self-inflicted harm). Explicitly **NOT** Hero ("crush it"), Magician (opaque automation), or Outlaw/Jester (PostHog whimsy).
- **D-03 — Five personality traits (gate every downstream decision):** **Calm · Precise · Trustworthy · Legible · Restrained.** If the team remembers one word: **calm**. Two: **calm + precise**.
- **D-04 — Rejected anchors (record the "why not" so they aren't reconsidered):**
  - *Modern dev-tool / Linear-gradient SaaS* — rejected: built for fast low-stakes personal productivity; gradients/glow/colorful chrome *fight* "color is signal" (a real alarm can't stand out). Steal only the craft-bar/component-consistency, never the palette.
  - *Terminal / hacker (mono-everything, green-on-black)* — rejected: signals "for hackers who already know," opposite of reducing operator fear; mono-everywhere harms prose scan-ability; collapses the severity palette and fails light/contrast. Steal only **mono-as-scoped-signal** for literal code/IDs.
  - *PostHog playful/sarcastic* — rejected as visual register (jokes at the moment someone discards 4,000 live jobs destroy trust). Steal the **opinionated, human, confident voice** — personality lives in the *clarity and confidence of words*, not whimsy.
- **D-05 — Codifiable, enforceable brand principles (write these as checkable rules; principles 1–3 are the high-leverage three):**
  1. **Color is information, never decoration.** ~90% of any surface is neutral/grayscale; saturated color is *reserved* to mean "look here — abnormal/operator-relevant." (ISA-101.) No decorative accent fills, gradients, or brand-color hero blocks.
  2. **Color is never the sole signal.** Every status/validation/severity is carried by ≥2 channels: color **+** (icon | text label | shape | position). A grayscale screenshot of any page must remain fully interpretable (make this an explicit VRT/a11y check).
  3. **Every destructive action explains scope before confirm.** Before confirm is enabled: named object(s) + exact count/scope + consequence + reversibility, and a required typed **reason**. No bare "Are you sure?".
  4. **Affordance honesty** — nothing looks interactive unless it is; interactive things always have hover + focus-visible + accessible name.
  5. **Motion is feedback, not flourish** — animation only for state change (appear/dismiss/progress/origin), interruptible, reduced-motion-safe; no idle/ambient motion.
  6. **One word per concept, everywhere** (see voice glossary D-16).
  7. **Honesty over polish** — explicit empty/loading/unavailable/permission-denied states; error copy says how to recover; never imply capability/support not owned.
- **D-06 — The single coherence test** for any future token/component/string: *"Does this make a stressed operator calmer and more certain about what will happen — or is it decoration, noise, or surprise?"* Latter = brand violation.

### Color Story (BRAND-02)
- **D-07 — Accent/brand hue: DIFFERENTIATE with a cool, indigo-leaning BLUE.** ⭐ **User-confirmed fork.** Do **NOT** harmonize with Oban's amber/orange. Three independent reasons (any one sufficient): (1) **semantic collision** — amber is already `warning`; an amber accent makes "is this an action or a caution?" ambiguous under incident stress; (2) **ownership honesty** — Powertools is a separate host-owned layer, not Oban's UI; a distinct accent states that boundary truthfully; (3) **convention/least-surprise** — blue is the universal "interactive / safe primary action" hue. Family-feel to Oban lives only in small warm touches (empty-state illustration, wordmark) and in being a good cool-chrome neighbor to Oban Web's amber in the bridge.
- **D-08 — Neutral base: COOL SLATE** (blue-undertone gray) for surface/elevated/border/text/muted. Keeps the *warm* spectrum free so amber/red alarms pop against cool chrome (max perceptual separation between frame and signal). Rejected: warm/stone (bleeds into warning/danger), true-neutral (reads undesigned).
- **D-09 — Semantic status roles locked by convention (least surprise):** `info`=blue (cyan-shifted, **distinct role+hue from the indigo accent** — accent never appears in a status pill, info never appears as a button) · `success`=green · `warning`=amber · `danger`=red. **Danger gets the highest chroma, reserved exclusively** for destructive/irreversible/error (never decoration, never "active/recording").
- **D-10 — Two-tier token philosophy:** Tier 1 primitive palette (full slate ramp + per-status hue ramps — **the only place raw hex lives**, theme-agnostic) → Tier 2 semantic roles (`--obpt-color-surface/elevated/border/text/muted/accent/info/success/warning/danger` + `-fg/-bg/-border/-solid` sub-roles). **Components reference Tier-2 roles only.** Theme switch = re-point Tier 2 at different Tier-1 primitives. Rationale: theming becomes re-pointing not rewriting; a11y/contrast enforced at one chokepoint; role names are a **semver-protected public contract**; "no raw hex in components" is grep/lint-checkable.
- **D-11 — Light / dark / high-contrast = three distinct token sets (NOT CSS filters).** Documented pitfalls the brand book must state: dark `surface` is near-black slate (~#0E1116) **never pure #000**; **elevation steps LIGHTER in dark** (surface→elevated→overlay), depth from lightness+border not shadow; desaturate accents/status ~10–20% on dark; **`muted` has a hard ≥4.5:1 floor** (most-failed dashboard a11y miss); **amber/yellow text must darken** (deep amber/brown-gold ~amber-700/800) to pass 4.5:1 in light mode — bright amber lives only in border/fill/glyph. High-contrast = enhanced ratios (body text ≥7:1, WCAG 1.4.6), solid borders over tinted fills, thicker focus, honors `prefers-contrast: more` + manual toggle.
- **D-12 — Contrast targets (intent — Phase 71 sets exact hexes):** text ≥7:1, muted ≥4.5:1 (hard floor), non-text/borders/inputs/focus ≥3:1 (WCAG 1.4.11), focus indicator ≥2px perimeter + ≥3:1 vs both states (2.4.11/2.4.13). **Colorblind safety mandatory** (success/danger are the red/green confusion pair, ~8% of male operators): distinct icon silhouettes (check / ✕-octagon / triangle-! / circle-i), luminance separation (grayscale must still distinguish), lean success→emerald and danger→true-red apart.

### Typography & Density (BRAND-03)
- **D-13 — System fonts only (locked constraint — do not relitigate).** Use **explicit Primer-style cascades, NOT bare `system-ui`** (it breaks non-Latin/Firefox rendering):
  - Sans: `-apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"`
  - Mono: `ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", "DejaVu Sans Mono", monospace`
  - Brand book must state plainly: *we accept per-OS letterform variance as the cost of zero webfont weight; the identity lives in color, spacing, hierarchy, mono-as-signal, and voice — not a typeface.*
- **D-14 — Monospace = SIGNAL, not default.** Mono scoped to *literal machine values*: job/batch/workflow IDs + fingerprints/hashes/trace IDs (**truncate the MIDDLE** — discriminating bytes are at both ends — + copy affordance + full value on tooltip/tap), module/worker names (preserve trailing segment, e.g. `…Workers.SendEmail`), args/JSON viewers, stacktraces, cron expressions, queue names, `Kbd`, inline code. **Numbers stay in SANS with `font-variant-numeric: tabular-nums`** (expose a `--obpt-numeric-tabular` feature token) for all numeric/metric/timestamp columns and live-updating counts (no horizontal digit jitter on refresh). Over-using mono destroys the signal and reads "everything is code."
- **D-15 — Type scale & density:**
  - rem-based ~1.2 minor-third ladder; **body 0.875rem/14px, dense-row 0.8125rem/13px**; unitless line-heights snapped to the 4px grid; **four weights** (400 body / 500 labels-emphasis / 600 headings; avoid 700+ "heavy" and 300 "light"). Display/h1/h2/h3 = 28/24/20/18px.
  - **Density posture: "calm but information-dense"** — denser than a marketing dashboard, calmer than a Bloomberg terminal. **4px spacing base** (`space-1..7` = 4/8/12/16/24/32/48), ~32–36px table rows (~15–20 rows visible without scroll). Density comes from **hierarchy + consistent rhythm**, never sub-readable fonts (12px floor for primary data). Model: Linear's "task-central elements in focus, navigation recedes."
  - **Long-content handling (DATA-03):** mandate the `min-width: 0` flex rule in DOC-01 (the #1 cause of broken ellipsis / 320px horizontal scroll); **always signal truncation visibly** (Sentry footgun); tables degrade to **stacked card/KeyValue fallback at 320px** (also WCAG-reflow-exempt path); page-level horizontal scroll never allowed (only bounded code/args blocks scroll internally). Verify every showcase story at 200% zoom (WCAG 1.4.4/1.4.10).

### Voice & Microcopy (BRAND-04)
- **D-16 — Register: plain, consequence-first, explanatory-without-chatter.** Canonical confirm template: **"Cancel 3 running jobs? They stop now and won't retry. This can't be undone."** Rejected clinical-terse ("Cancel 3 jobs?" — fails the "explain" half, confirms on incomplete info) and warm-reassuring ("Don't worry…" — condescends to expert operators, wastes scan-time).
- **D-17 — Five voice traits (each with a guardrail):** **Precise** (not cryptic) · **Calm** (not cute) · **Honest** (not hedging) · **Plain** (not jargon/passive) · **Respectful** (not infantilizing — friction is the typed count, not a scolding tone).
- **D-18 — "Explain, then act" as an enforceable copy contract** (baked into shared `ConfirmActionDialog`/`<.danger_form>` so the 9 pages compose, never re-author): a destructive confirmation MUST (1) name the object (id/worker, not "this item"), (2) state consequence + scope (incl. jobs *outside the current view* for bulk), (3) state reversibility, (4) require a typed **reason** → audit log. **Friction scales with blast radius:** single reversible (retry/pause) = reason + one-click, **warning-weight** button; single irreversible (cancel/discard) = required reason + confirm, **danger-weight**; bulk = required reason + **"type the count to confirm"** + out-of-view scope warning. **Dismiss button never mirrors the verb** (use "Keep running," never "Cancel" on a cancel-job dialog). Reversibility drives button weight (pause = warning, not danger).
- **D-19 — State copy (no cutesy empty/error states — calm, not cute):** empty = fact + next action; loading = name *what's* loading (skeletons for tables), never a bare spinner; **error MUST say how to recover** (banned: "Something went wrong" / "An error occurred"); permission-denied = render disabled with reason tooltip ("Cancel — requires operator role"), never silently hidden; distinguish stale vs unavailable vs empty vs permission-denied; success toasts confirm what *actually* happened in the action's vocabulary, only show Undo if it genuinely works.
- **D-20 — Honesty / support-truth rule:** voice never promises outcomes the library doesn't own. Say what *Powertools* did (requested, recorded, audited), not what the host's infra will do ("Retry requested. Job re-enters the default queue." NOT "Job fixed!"; "It stops at the next checkpoint." not "Job stopped."). One false "done!" burns the trust that is the whole adoption thesis.
- **D-21 — Canonical glossary — one term per concept across all 9 pages + audit log** (literals centralized in e.g. `ObanPowertools.Copy`/gettext, grep-enforceable, no inline string literals): **Cancel** (stop now, terminal, no retry) ≠ **Discard** (mark dead/exhausted, final) ≠ **Delete** (actual DB row removal, retention-only, rarely inline) — these mirror real Oban states so operators learn one model. **Retry** (re-enqueue), **Pause/Resume** (cron/queue, reversible), **Job/Worker**, **Blocked** + explain (paused queue / saturated limiter / unmet dependency), **Preview** (dry-run), **Repair** (Lifeline mutation), **Reason** (required justification → audit), **Audit log/trail**, **Limiter**. Reserve "stuck" for orphan detection; reserve "event log" for the forensics timeline (not audit).

### Traceability (BRAND-05)
- **D-22 — No orphan styles.** The brand book must include a **traceability table** mapping every planned downstream token category (color roles, type scale, spacing, radii, elevation, motion, status taxonomy, voice patterns) back to a named brand decision above. Phases 71–84 cite these decision IDs (D-xx) so `gsd-ui-review`/the milestone audit (Phase 84) can verify every shipped value has a brand-book parent.

### Claude's Discretion
- Exact prose, chapter ordering, and the visual layout of the dev-rendered brand-book route are left to research/planning, provided all decisions above are captured and the route renders the color/type/status/voice exemplars.
- Exact hex values, precise rem steps, and final spacing tokens are **deliberately deferred to Phase 71** (tokens) — this phase locks the *story, roles, scale-shape, and contrast intent*, not the literal values.
- Iconography library/style choice (outline vs filled, source) within the "distinct silhouettes per status" constraint (D-12).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone requirements & roadmap
- `.planning/REQUIREMENTS.md` — v2.0 "Powertools Identity" requirements; Phase 70 owns **BRAND-01..05** and **DOC-03 (initial)**; defines the full downstream category map (TOKEN/COMP/FORM/NAV/DATA/GROUP/PAGE/A11Y/MOTION/COPY/SHOW/VRT/FIX/DOC) every brand decision must serve. See also the **Out of Scope** table (no new operator capability; no PhoenixStorybook runtime dep; no host-theme hijack; no host Tailwind dep; **no custom webfont in the foundation**; no Wallaby/playwright-elixir; no behavior changes during visual migration).
- `.planning/ROADMAP.md` §"Phase 70" — goal + 4 success criteria (brand book renders at a dev route; every token category has a named brand decision; "explain, then act" + danger voice codified as enforceable rules; **no code/UI changes to the 9 pages**). Also the per-phase "deep-research input + adversarial-judge review" cadence that governs the whole milestone.
- `.planning/PROJECT.md` — shipped v1–v1.9 history, core value ("Ecto-native operational safety with explicit, inspectable behavior… honest host-ownership and support-truth boundaries"), and the existing "explain, then act" / Lifeline preview→reason→confirm→audit DNA the brand formalizes.

### Strategy & positioning research (read for grounding; brand book supersedes where it conflicts)
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid web strategy (native Powertools console vs embedded Oban Web bridge); verb/glossary section (~lines 540–590) seeds the canonical terminology (D-21). NOTE: this brief is feature/strategy-focused and does **not** contain a brand book — the brand book authored in this phase is the new source of truth for visual/verbal identity.
- `prompts/oban_powertools_context.md` — deep project context.
- `.planning/research/operator_ux.md` — operator/SRE persona, JTBD (triage/incident/repair/audit), incident-stress psychology (cognitive load is the real failure mode).
- `.planning/research/ecosystem_dna.md`, `.planning/research/domain_competitors.md` — Elixir/Phoenix idiom + competitor landscape (Oban Web, Sidekiq, Mission Control — Jobs).

### Existing operator surfaces (the 9 pages the identity will later re-found — NOT touched this phase)
- `lib/oban_powertools/web/{engine_overview,jobs,batches,workflows,cron,limiters,lifeline,audit,forensics}_live.ex`

### Codebase maps
- `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`

### External standards referenced by decisions (for the brand book's citations)
- WCAG 2.2 — SC 1.4.1 (use of color), 1.4.3/1.4.6 (contrast), 1.4.10 (reflow), 1.4.11 (non-text contrast), 2.4.11/2.4.13 (focus appearance/not-obscured), 1.4.4 (resize text).
- ISA-101 / High-Performance HMI (grayscale base, saturation = severity, "color = look here").
- Reference design systems for the brand book's "prior art" notes: Radix Colors (12-step scale), GitHub Primer (accent vs status separation; system font cascades), Datadog DRUIDS (curated status palette, mono-vs-tabular-nums split), IBM Carbon (dark layers step lighter), Stripe (contrast-validated tokens). UX-writing: NN/g confirmation dialogs, GOV.UK content design, GitHub "type-to-confirm."
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **The "explain, then act" flow already exists in behavior** — Lifeline's dry-run repair center (preview → reason → confirm → execute → audit) and audit logging are shipped (v1.1/v1.4). The brand book *formalizes the visual/verbal identity of a pattern the product already lives*; it does not invent new behavior. Downstream `ConfirmActionDialog`/`<.danger_form>` (Phase 78) will wrap this existing flow.
- **9 LiveView operator pages** (`lib/oban_powertools/web/*_live.ex`) are the migration targets for phases 79–81; this phase only documents the identity they will adopt.

### Established Patterns
- **Host-ownership / library-owned isolation** is a load-bearing product principle (shipped HST-/PKG-/POL- requirements). It *constrains the brand*: the identity must be self-contained (own palette, system fonts, `.obpt-root`-scoped `--obpt-*` tokens) — it cannot rely on or leak into the host's theme/Tailwind. This is why "differentiate from Oban's amber" (D-07) is coherent with the architecture, not just aesthetics.
- **Zero new runtime dependencies** posture across v1.6–v1.9 — the brand book should not imply any dependency that violates this (system fonts, precompiled CSS asset, dev-gated showcase all honor it).

### Integration Points
- Brand book route is **dev-rendered only** (foreshadows the Phase 72 `/ops/jobs/_showcase` dev-only gating; must never leak into a host's prod build — DOC-03 + SHOW-03 tarball check).
- Every downstream phase consumes this CONTEXT + the authored brand book by **decision ID (D-xx)** for traceability (BRAND-05 → Phase 84 audit).
</code_context>

<specifics>
## Specific Ideas

- User's explicit directive for this phase: *"think deeply, one-shot a perfect set of recommendations so I don't have to think"* — all four areas (personality, color, type/density, voice) were researched by parallel domain-expert subagents and locked decisively; the only fork surfaced to the user was the accent hue.
- **User-confirmed fork:** accent = **differentiate with blue** (not harmonize with Oban amber). Locked 2026-06-18.
- Brand book header line is fixed verbatim (D-01).
- "If the team remembers one word, it's **calm**" — keep this as a memorable north-star line in the brand book.
- The coherence test (D-06) and the "three high-leverage principles" framing (D-05) should appear prominently — they are the enforceable spine, not flavor text.
</specifics>

<deferred>
## Deferred Ideas

- **Comfortable/compact density toggle** (per-user table density preference) — a post-foundation enhancement, not a brand-book or Phase 70 deliverable. Revisit after pages migrate.
- **Custom webfont** — explicitly out of scope for the foundation (REQUIREMENTS Out of Scope); revisit only if the brand later demands it. The brand book should note the system-font decision is a deliberate, revisitable tradeoff.
- **Data-visualization color modes** (colorblind graph palettes à la Datadog) — relevant if/when richer charts appear; note the principle now, build later.
- All token *values*, component implementations, and page migrations — owned by phases 71–84, not this phase.

</deferred>

---

*Phase: 70-brand-book-identity-foundation*
*Context gathered: 2026-06-18*
