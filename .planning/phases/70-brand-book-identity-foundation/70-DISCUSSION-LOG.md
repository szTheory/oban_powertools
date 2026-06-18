# Phase 70: Brand Book & Identity Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 70-brand-book-identity-foundation
**Areas discussed:** Brand Personality, Color Direction, Typography & Density, Voice & Microcopy

---

## Flow

The user selected all four gray areas and issued an explicit directive: research each via subagents (pros/cons/tradeoffs with examples; idiomatic Elixir/Phoenix/ecosystem; cross-ecosystem lessons incl. other languages — what they did right/wrong/footguns; great DX/UX; consider the `prompts/` research; apply expert lenses — software-architecture/SRE for the engineering, UI/UX/graphic-design/creative-direction + user-psychology for the design; tie to persona/JTBD/user-flow) and **"think deeply, one-shot a perfect set of recommendations so I don't have to think,"** coherent with each other and the project vision.

Four parallel `general-purpose` research subagents were dispatched (one per area), each grounded in `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, the `prompts/` strategy briefs, and `.planning/research/*`, with web-search for cross-ecosystem lessons. All four independently converged on — and the personality stream validated/sharpened — the same anchor: a **calm, precise, trustworthy control-room/console** identity (corroborated by ISA-101 High-Performance HMI discipline). The streams cross-cohere (color "is signal" ↔ personality principle #1; mono-as-signal ↔ density; plain-explanatory voice ↔ "explain, then act").

A synthesized recommendation set was presented; only one genuine fork was surfaced to the user for decision.

---

## Brand Personality / Essence

Research validated the working hypothesis (control-room console) over the alternatives and recommended it decisively.

| Option | Description | Selected |
|--------|-------------|----------|
| Calm control-room / console | Neutral, organized-dense, color-as-signal, plain explanation, restrained motion (Grafana/Honeycomb/ISA-101 lineage) | ✓ |
| Modern dev-tool / Linear-gradient SaaS | Gradients/glow/colorful chrome, marketing polish | (rejected — fights color-as-signal; built for low-stakes) |
| Terminal / hacker (mono, green-on-black) | Ultra-dense TUI aesthetic | (rejected — signals "for hackers," harms prose, fails contrast) |
| PostHog playful/sarcastic | Meme-y, mascot, jokey | (rejected as visual register; steal only the human/confident *voice*) |

**User's choice:** Accepted the synthesized recommendation (calm/precise/trustworthy control-room; Sage+Caregiver archetype; 5 traits; 3 enforceable principles).
**Notes:** User's "one-shot, don't make me think" directive — locked without further interrogation.

---

## Color Direction

| Option | Description | Selected |
|--------|-------------|----------|
| Differentiate (blue) | Cool indigo-leaning accent; amber stays "warning"; states the host-owned-layer boundary; blue = universal "safe primary action" | ✓ |
| Harmonize (amber) | Adopt Oban's amber as accent for family-feel | (rejected — collides with warning semantics; implies "this is Oban's UI") |
| Differentiate (other hue, e.g. teal/violet) | Differentiate but not blue | (not chosen — teal sits near info/success; violet reads consumer-SaaS) |

**User's choice:** **Differentiate (blue)** — the one fork explicitly surfaced and chosen by the user.
**Notes:** Also locked (research-recommended, low-controversy): cool-slate neutral base; convention status roles (info-blue/success-green/warning-amber/danger-red); two-tier `--obpt-*` tokens; light/dark/high-contrast as distinct token sets with documented dark-mode + amber-text + muted-floor pitfalls; WCAG 2.2 AA targets + mandatory colorblind redundancy.

---

## Typography & Density

| Option | Description | Selected |
|--------|-------------|----------|
| Calm-but-dense + mono-as-signal + tabular-sans | Explicit system cascades; mono only for IDs/code; numbers in sans w/ tabular-nums; 14/13px; 4px grid | ✓ |
| Comfortable/spacious | 16px body, generous padding | (rejected — wastes viewport, hides signal in incidents) |
| Bloomberg-dense / mono-everything | 11px, all-mono, tiny gutters | (rejected — chaotic, fatiguing, fails 320px/AA, kills mono-as-signal) |

**User's choice:** Accepted the synthesized recommendation.
**Notes:** System-fonts-only constraint reaffirmed; explicit Primer cascades over bare `system-ui`; middle-truncation for IDs; `min-width:0` flex rule + visible-truncation signal; 320px stacked-card fallback.

---

## Voice & Microcopy

| Option | Description | Selected |
|--------|-------------|----------|
| Plain, consequence-first, explanatory-without-chatter | "Cancel 3 running jobs? They stop now and won't retry. This can't be undone." | ✓ |
| Clinical-terse | "Cancel 3 jobs?" | (rejected — fails the "explain" half; blind-fire risk) |
| Warm-explanatory / reassuring | "Don't worry, this is easy!" | (rejected — condescends to expert operators) |

**User's choice:** Accepted the synthesized recommendation.
**Notes:** "Explain, then act" codified as an enforceable copy contract (name object · consequence+scope · reversibility · required reason); friction scales with blast radius (bulk = type-the-count); honesty/support-truth rule (requested ≠ done); one-term-per-concept canonical glossary (cancel ≠ discard ≠ delete).

---

## Claude's Discretion

- Brand-book prose, chapter ordering, and dev-route layout (provided all decisions captured).
- Exact hex values, precise rem steps, final spacing tokens — deliberately deferred to Phase 71 (tokens). This phase locks the story/roles/scale-shape/contrast-intent only.
- Iconography library/style within the "distinct silhouette per status" constraint.

## Deferred Ideas

- Comfortable/compact per-user density toggle — post-foundation.
- Custom webfont — out of scope for the foundation; revisit only if the brand demands it.
- Data-visualization colorblind graph palettes — note the principle now, build with richer charts later.
- Token values / component implementations / page migrations — phases 71–84.
