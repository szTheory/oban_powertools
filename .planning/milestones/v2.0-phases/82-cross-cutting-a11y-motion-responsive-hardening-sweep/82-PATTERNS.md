# Phase 82: Cross-Cutting A11y, Motion & Responsive Hardening Sweep - Pattern Map

**Mapped:** 2026-07-29
**Binding inputs:** `82-CONTEXT.md`, `82-RESEARCH.md`, `82-UI-SPEC.md`
**Scope:** harden the complete generated showcase inventory and nine connected production pages without adding product behavior, routes, stories, or dependencies

## Scope and Repository Notes

- No root `CLAUDE.md`, `.claude/skills/`, or `.agents/skills/` exists in this repository.
- The worktree is active and dirty from the milestone closure. Executors must re-read every assigned file immediately before editing and preserve unrelated changes.
- The catalog-derived schema-8 manifest remains the sole showcase inventory. Phase 82 may add a validated non-inventory copy-policy field, but must not create a second TypeScript target/story list.
- The nine connected routes are a separate, exact family-to-route acceptance map. Assert its keys against the unique page families from the generated manifest.
- Reuse the already active target in `showcase.a11y.spec.ts` for mechanical quality checks. Do not create a second 1,956-navigation showcase matrix.
- The Phase 79–81 connected suites contain the browser behaviors to preserve, but their local overflow, focus, target, and zoom helpers are intentionally the weak patterns to extract and replace.
- Production authorization, bounded reads, mutations, preview identity, reasons, receipts, and redaction stay in existing LiveViews/domain modules. Browser auditors observe; they never gain authority.

## Architecture and Data Flow

```text
Elixir catalogs + ObanPowertools.Web.Copy
                  |
                  v
         generated schema-8 manifest
             /               \
            /                 \
  163 showcase targets      exact 9-family route map
  existing axe traversal    authenticated fixture routes
            \                 /
             v               v
          shared system-quality auditors
       axe | contrast | target | focus | reflow
            motion | one-tree | rendered copy
                       |
                       v
          exact package scripts + CI validator
                       |
                       v
       page_quality + visual_a11y -> ci-gate
```

Repairs flow back to the narrowest owner:

```text
cross-theme ratio/focus/motion defect -> tokens.css
cross-page semantic defect            -> shared component
repeated terminology/recovery drift   -> Copy / presenter
unique page truth                     -> owning page presenter/composition
harness omission                      -> shared browser support / exact validator
```

## File Classification

| New/Modified File | Role | Data Flow | Closest Existing Analog | Match |
|---|---|---|---|---|
| `lib/oban_powertools/web/copy.ex` | production policy/utility | finite policy -> closed copy terms and ordering rules | `control_plane_presenter.ex` finite maps; `status_taxonomy.ex` closed registry | composite |
| `test/oban_powertools/web/copy_contract_test.exs` | ExUnit contract test | source files + policy -> exact diagnostics | `runbook_copy_contract_test.exs`; `control_plane_copy_coherence_test.exs` | exact composite |
| `scripts/showcase_manifest.exs` | generated manifest adapter | Elixir catalogs/policy -> JSON | current page-story projection and manifest assembly | exact |
| `test/browser/support/manifest.ts` | runtime schema validator | JSON file -> closed typed inventory/policy | current exact-field and reconstructed-target validation | exact |
| `test/browser/support/manifest-smoke.mjs` | independent static validator | JSON file -> fail-closed diagnostics | current independent schema/count/order checks | exact |
| `test/browser/support/system-quality.ts` | browser audit utility | computed DOM/style/geometry -> structured failures | local helpers in Wave 1–3 specs; `axe.ts` result/report pattern | composite |
| `test/browser/support/connected-pages.ts` | connected-route config | generated page families + fixture handles -> safe route journeys | Wave 1 family map; Phase 81 path helpers | role match |
| `test/browser/specs/system-quality.spec.ts` | connected Playwright suite | 9 families × 3 projects, looping themes -> 27 cases | `page-migration-wave-3.spec.ts` authenticated serial composition | exact composite |
| `test/browser/support/axe.ts` | axe policy/report utility | axe results + exact exception policy -> pass/report/fail | same file | exact |
| `test/browser/specs/showcase.a11y.spec.ts` | exhaustive generated browser suite | 163 targets × themes/projects -> axe + mechanical evidence | same file's active-target loop | exact |
| `test/browser/specs/page.acceptance.spec.ts` | generated semantic/copy suite | 99 page stories -> copy/order/roles/ARIA | same file | exact |
| `test/browser/specs/page-migration-wave-{1,2,3}.spec.ts` | connected regression suites | fixture-authenticated journeys -> focus/reflow/recovery proof | their current local helpers, replaced by shared imports | exact refactor |
| `assets/oban_powertools/tokens.css` | scoped design token/style source | semantic tokens + component states -> rendered themes/reflow/motion | existing token/focus/reduced-motion blocks | exact |
| `priv/static/oban_powertools/oban_powertools.css` | generated package asset | source CSS build -> byte-identical package CSS | `mix oban_powertools.assets.build` | exact |
| shared component modules under `lib/oban_powertools/web/components/` | stateless presentation components | closed assigns -> semantic HTML | existing `Primitives`, `Forms`, `DataDisplay`, `OperatorPatterns`, `AppShell` | exact |
| `lib/oban_powertools/web/control_plane_presenter.ex` and page presenters | presentation/redaction boundary | authorized facts -> safe finite copy/maps | existing presenter functions and closed fallbacks | exact |
| `test/oban_powertools/web/theme_tokens_test.exs` | static CSS contract | CSS declarations -> token/scope/contrast/motion invariants | same file | exact |
| `test/oban_powertools/web/assets_test.exs` | package contract | build outputs -> hashes/equality/stability | same file | exact |
| corresponding component/presenter/LiveView tests | semantic regression tests | hostile/edge inputs -> escaped honest HTML | existing same-module suites | exact |
| `test/browser/support/verify-phase82-quality.mjs` | exact policy/artifact validator | source/package/manifest/registries -> structured report/failure | `manifest-smoke.mjs`; `verify-page-script-order.mjs` | composite |
| `package.json` | quality graph config | scripts -> ordered Playwright/validator execution | current `verify:pages*` scripts | exact |
| `test/browser/support/verify-page-script-order.mjs` | CI graph validator | package/shell/YAML text -> exact graph + mutation proof | same file | exact |
| `.github/workflows/ci.yml` | merge-blocking CI | required jobs/artifacts -> `ci-gate` | current `page_quality`, `visual_a11y`, `ci-gate` | exact |
| `test/browser/voiceover/page.voiceover.spec.ts` | structured assistive-tech evidence | existing ten targets -> role/name/state transcript assertions | same file | exact; only if contract needs strengthening |

## Pattern Assignments

### 1. `ObanPowertools.Web.Copy`: copy the finite-registry pattern, not page prose

**Analogs:** `lib/oban_powertools/web/status_taxonomy.ex`; finite state/result
maps at `lib/oban_powertools/web/control_plane_presenter.ex:23-163`.

Create one production module that exposes immutable data/functions for:

- canonical concept terms and disallowed substitutions;
- forbidden phrases and outcome-overclaim stems;
- shared state headings and recovery requirements;
- safe-state dismiss-label rules;
- confirmation section order;
- exact source-scan roots and narrow exclusions;
- any axe/target/copy exception registry entries, each with exact scope, owner,
  rationale, expiry, and compensating assertion ID.

Follow the existing closed-map posture:

```elixir
@canonical_terms %{
  retry: %{term: "Retry", forbidden: ["Repair"]},
  pause: %{term: "Pause", forbidden: ["Stop"]},
  audit_log: %{term: "Audit log", forbidden: ["Event log"]}
}

@confirmation_order ~w[object scope consequence reversibility support_boundary reason actions]a

def contract do
  %{
    canonical_terms: @canonical_terms,
    forbidden_phrases: @forbidden_phrases,
    confirmation_order: @confirmation_order
  }
end
```

Use compile-time literals, returned in deterministic order. Validate that all
keys and values are finite binaries/atoms from the module itself. Do not accept
runtime text, dynamically create atoms, or centralize unique consequences and
support boundaries that belong to page presenters.

Security boundary:

- The contract contains policy, never rendered fixture values, raw reasons,
  preview identity, provider metadata, exception text, or credentials.
- Diagnostics may report the offending rendered phrase and route/story label,
  but must not dump the full DOM or browser channels.

### 2. Copy contract tests: combine source scanning with semantic ordering

**Analogs:**

- `test/oban_powertools/web/live/runbook_copy_contract_test.exs:39-146` for a
  finite forbidden list and exact negative assertions.
- `test/oban_powertools/web/live/control_plane_copy_coherence_test.exs:103-214`
  for `assert_occurs_in_order/2` across real connected LiveViews.
- `test/oban_powertools/web/components/operator_patterns_test.exs:565-673` for
  confirmation semantics and authority exclusions.

Reuse the order assertion shape:

```elixir
Enum.reduce(markers, {text, 0}, fn marker, {remaining, offset} ->
  assert String.contains?(remaining, marker),
         "expected #{inspect(marker)} after byte offset #{offset}"

  {index, _len} = :binary.match(remaining, marker)
  next_offset = offset + index + byte_size(marker)
  {binary_part(remaining, index + byte_size(marker),
               byte_size(remaining) - index - byte_size(marker)), next_offset}
end)
```

The new source scanner should:

1. read only declared production web/component/presenter roots;
2. exclude `copy.ex` and exact negative-fixture paths;
3. report `path:line`, phrase, and expected canonical concept;
4. fail on an unused/stale exclusion;
5. distinguish bare ambiguous `Cancel` from the legitimate action term
   “Cancel job”;
6. keep page-specific consequence truth beside its presenter.

Add focused tests for forbidden phrase, synonym drift, ambiguous dismiss,
missing/out-of-order confirmation section, empty without next action, loading
without resource, error without recovery, overclaimed receipt, and stale
exception.

### 3. Manifest policy exposure: extend the existing exact generated schema seam

**Analogs:**

- `scripts/showcase_manifest.exs:152-203` derives 99 stories, reconstructs all
  163 targets, and emits one manifest.
- `test/browser/support/manifest.ts:115-160,301-432` validates exact fields,
  reconstructs targets from the kind arrays, and checks exact family order.
- `test/browser/support/manifest-smoke.mjs:205-260,417-461` independently
  rejects missing/extra fields and inventory drift.

Add a deterministic non-inventory field such as `copy_contract` directly from
`ObanPowertools.Web.Copy.contract/0`:

```elixir
manifest = %{
  schema_version: 8,
  themes: themes,
  viewports: viewports,
  copy_contract: ObanPowertools.Web.Copy.contract(),
  # existing catalog-derived arrays unchanged
  targets: targets
}
```

Then extend both validators' exact top-level field lists and validate every
nested policy field. Preserve schema version 8 unless implementation discovers
that all schema consumers require a deliberate version bump.

Keep these existing ownership invariants:

```ts
const pageStories = assertArray(manifest.page_stories, "page_stories").map(...);
assertExactList(
  [...new Set(pageStories.map((story) => story.page))],
  [...allowedPages],
  "page_stories families"
);
const expectedTargets = [
  ...scenarios.map((scenario) => ({ kind: "scenario" as const, ...scenario })),
  ...primitiveStories, ...formStories, ...shellStories,
  ...dataStories, ...groupStories, ...pageStories
];
```

Do not copy target IDs into the policy or browser support. A validator fixture
must prove that a hand-written second target list is rejected.

### 4. `system-quality.ts`: factor and strengthen the Wave 1–3 helpers

**Analogs:**

- `page-migration-wave-3.spec.ts:74-116` connected-page, one-tree, and overflow
  helpers.
- `page-migration-wave-3.spec.ts:145-194` target sizing and CDP zoom.
- `page-migration-wave-1.spec.ts:252-309` overflow, visible focus, and
  responsive-tree helpers.
- `page-migration-wave-2.spec.ts:123-190` the equivalent duplicated helpers.
- `test/browser/support/axe.ts:27-70` bounded artifact writing and safe filename
  pattern.

Export small functions with structured diagnostics, for example:

```ts
export async function auditSystemQuality(
  root: Locator,
  context: QualityContext,
  options: QualityOptions
): Promise<QualityReport>

export async function expectFocusedAndUnobscured(
  page: Page,
  focused: Locator,
  context: QualityContext
): Promise<void>

export async function with200PercentZoom<T>(
  page: Page,
  run: () => Promise<T>
): Promise<T>
```

The CDP helper must restore metrics and detach the session in `finally`; the
current Wave 3 helper sets metrics without restoration and is not the pattern
to preserve.

#### Contrast

Implement exact sRGB luminance without rounding before comparison. Parse
computed `rgb()`/`rgba()`, alpha-compose through ancestors, and fail closed on
gradient/image/unresolved adjacency. Reports identify semantic pair plus
route/story/control.

Thresholds:

- normal text 4.5:1;
- large text 3:1;
- muted text always 4.5:1;
- meaningful non-text boundaries and focus indicator 3:1;
- high-contrast body text 7:1;
- focus indicator at least 2 CSS px and 3:1 against both adjacent states.

#### Target size

Replace the existing comfort-only logic:

```ts
expect(Math.max(target.width, target.height)).toBeGreaterThanOrEqual(44);
```

with the normative 24×24-or-spacing algorithm, explicit reviewed exceptions,
overlap detection, and then the project's separate 44px-in-one-axis comfort
rule for named operator controls. Never infer `inline` or `essential` from the
tag name. Fail on unknown, stale, broad, or unused exception records.

#### Focus not obscured

Require connected/enabled `document.activeElement`, visible author focus,
outline/equivalent thickness and contrast, viewport intersection, and hit-test
visibility. Sample deterministic inset points with `elementsFromPoint`; report
overlapping fixed/sticky/top-layer selectors. Re-run the same strict helper
after scroll, navigation, dialog open/close, validation, LiveView patch,
responsive change, and recovery.

#### Reflow and one tree

Retain the current exact metric:

```ts
Math.ceil(document.documentElement.scrollWidth -
          document.documentElement.clientWidth) <= 1
```

but apply it to root/body/document/page and inspect every overflowing
descendant. Only explicitly registered, labelled, focusable, bounded
machine-content regions may overflow horizontally; they may not contain
ordinary actions/navigation. Reject `[data-obpt-mobile-copy]`,
`[data-obpt-desktop-copy]`, duplicated adaptive-detail identities, multiple
dialogs, or multiple vertical scroll owners.

#### Motion

Inventory computed animation/transition properties for visible active-target
descendants. Test independently:

1. OS `prefers-reduced-motion: reduce` with no root override;
2. normal media plus `.obpt-root[data-obpt-motion="reduce"]`.

Under either mechanism, non-essential animation is absent/instant, while
spinner/skeleton names, overlays, disclosure, progress, focus, and live-region
content remain present and operable. Restore media/root state after each probe.

Bound all DOM walks and diagnostic arrays to prevent artifact/DOM denial of
service. Never attach full DOM, response bodies, credentials, or fixture state.

### 5. Axe: preserve the tag set, make moderate findings fail closed

**Analog:** `test/browser/support/axe.ts:7-65`.

Keep:

```ts
const axeTags = [
  "wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"
] as const;
```

Replace `blockingImpacts = new Set(["critical", "serious"])` with a policy that:

- always blocks critical/serious;
- blocks moderate by default;
- accepts a moderate only through a finite exact rule + target/story/route
  scope, standards rationale, owner, expiry, and compensating assertion;
- fails stale, expired, broad, unmatched, duplicate, or unused exceptions;
- records minor findings without silently promoting them beyond scope;
- reports every affected selector, not the current first-five truncation.

Preserve structured per-target JSON attachment, but add a redacted compact
Phase 82 summary rather than raw browser-channel data.

### 6. Piggyback exhaustive quality on `showcase.a11y.spec.ts`

**Analog:** `test/browser/specs/showcase.a11y.spec.ts:7-29`.

The current loop already owns the exact generated traversal:

```ts
for (const theme of themes) {
  for (const target of a11yTargets) {
    test(`${target.kind} ${target.id}`, async ({ page }, testInfo) => {
      await prepareShowcase(page, { theme, viewportName });
      const story = await activateTarget(page, target);
      await expect(story).toBeVisible();
      // axe today
    });
  }
}
```

After activation, call the shared auditor on `target.a11y`. Keep axe on every
target/theme/project. Reuse the prepared page for target, contrast, base reflow,
rendered-copy, and reduced-motion assertions. Per the researched runtime plan:

- base reflow and media-reduced checks run in every existing case;
- explicit-root reduced motion runs for `system`;
- 200% zoom runs for `system` + `chromium-wide`;
- representative rendered contrast chokepoints may be selected by manifest
  kind/component while axe remains exhaustive;
- VRT axes and PNG counts do not change.

Failure labels must include target ID, kind, theme, project/viewport, selector,
property/rule, and measured values.

### 7. `connected-pages.ts` and `system-quality.spec.ts`: one exact 27-case lane

**Analogs:**

- `page-migration-wave-3.spec.ts:19-78` for secret-gated fixture reset,
  authenticated actor, and real `[data-phx-main].phx-connected` proof.
- `page-migration-wave-3.spec.ts:118-142` for fixture-owned route builders.
- Wave 1's family map at `page-migration-wave-1.spec.ts:115-175`, but **not**
  its hand-written story-ID array.

Use one exact map keyed by the nine product families:

```ts
const connectedPages: Record<ShowcasePageName, ConnectedPageContract> = {
  overview: { path: () => "/ops/jobs", ... },
  cron: { path: fixtureCronPath, ... },
  limiters: { path: fixtureLimiterPath, ... },
  audit: { path: fixtureAuditPath, ... },
  jobs: { path: fixtureJobsPath, ... },
  forensics: { path: fixtureForensicsPath, ... },
  batches: { path: fixtureBatchPath, ... },
  workflows: { path: fixtureWorkflowPath, ... },
  lifeline: { path: fixtureLifelinePath, ... }
};
```

Assert `Object.keys(connectedPages)` exactly equals the unique ordered
`pageStories.map(story => story.page)` family set. Values own only route/fixture
setup and safe traversal callbacks; they do not copy story targets.

Create one test per family, expanded by the three configured projects: exactly
27 project-expanded tests. Within each case, loop the four themes without
reloading fixture state when safe. Prove real `AppShell`, axe, focus, targets,
reflow, motion, copy, and route-specific keyboard journey. Dangerous mutation
branches stay in the existing Wave 1–3 regression suites.

Use the existing serial posture:

```ts
test.describe.configure({ mode: "serial" });
test.setTimeout(90_000);
```

Do not increase workers, add retries/sleeps, expose a GET fixture API, or
authenticate by bypassing the fixture actor.

### 8. Refactor Wave 1–3 specs to shared strict helpers

**Analogs to replace:**

- Wave 1 `expectNoHorizontalOverflow`, `expectVisibleFocus`,
  `expectOneResponsiveTree`;
- Wave 2 `expectNoHorizontalOverflow`, `expectVisibleFocus`,
  `expectMinimumTargets`, `assertOneProductionTree`;
- Wave 3 `expectOneTree`, `expectNoOverflow`, `expectMinimumTargets`,
  `apply200PercentZoom`.

Keep the existing route-specific dialog, URL/history, patch, validation,
stale/partial recovery, and authority journeys. Swap only their mechanical
assertion implementation to imports from `system-quality.ts`. This turns
already valuable interaction tests into strict 2.4.11/2.5.8/reflow evidence
without duplicating dangerous flows.

The Phase 81 focus flow at `page-migration-wave-3.spec.ts:533-550` is the core
interaction analog:

```ts
await invoker.focus();
await invoker.press("Enter");
await expect(dialog).toBeVisible();
await page.keyboard.press("Escape");
await expect(dialog).toHaveCount(0);
await expect(invoker).toBeFocused();
```

Add `expectFocusedAndUnobscured` at each state transition, including the
restored invoker.

### 9. `page.acceptance.spec.ts`: preserve generated ARIA, add generic copy policy

**Analog:** `test/browser/specs/page.acceptance.spec.ts:24-55,76-160`.

Reuse:

- manifest-derived `pageStories`;
- `assertTextContract` required/forbidden/ordered text;
- one H1, one responsive tree, at most one modal;
- exact role contracts;
- exact `ariaSnapshot()` output.

Add policy-driven rendered copy scanning from `manifest.copy_contract`, plus a
generic open-confirmation order assertion:

```text
object -> scope/count -> consequence -> reversibility
-> support boundary -> reason/hint/error -> submit + safe-state dismiss
```

Do not add page-family target arrays or repeat the policy literals in
TypeScript. Failures identify story ID and offending text/order marker.

### 10. CSS and component repairs: copy the scoped token-owned patterns

**Analogs:**

- motion tokens at `assets/oban_powertools/tokens.css:95-102`;
- media/root reduction pairs at `:360-365`, `:1498-1515`, `:3180-3191`;
- 2px focus treatments at `:458-465`, `:865-871`, `:1039-1046`;
- production page one-tree selectors at `:3940+` and `:4113+`;
- `theme_tokens_test.exs:853-952`;
- source/package repeatability at `assets_test.exs:50-64`.

Every repair must remain below `.obpt-root`, use semantic Tier-2 color and
motion tokens, and include both reduction paths. Prefer `border-strong` where a
boundary conveys control/state, because ordinary `border` is decorative and
below 3:1 in light/dark.

For semantic component repairs, preserve the existing closed API pattern in
`OperatorPatterns.confirm_action_dialog/1`:

```elixir
attr(:object_label, :string, required: true)
attr(:scope, :string, required: true)
attr(:consequence, :string, required: true)
attr(:reversibility, :string, required: true)
attr(:support_boundary, :string, required: true)
attr(:confirm_label, :string, required: true)
attr(:dismiss_label, :string, required: true)
```

Its rendered order at `operator_patterns.ex:132-214` is the generic
confirmation structure to enforce, not fork.

Use corresponding same-module tests:

- `theme_tokens_test.exs` for exact parsed token pairs, motion declarations,
  root scope, no raw timing, and both reduction paths;
- `primitives_test.exs` / `forms_test.exs` for focus and target fixes;
- `data_display_test.exs` for one table tree, long content, labelled machine
  scrollers, and distinct data states;
- `operator_patterns_test.exs` for focus/order/recovery;
- `app_shell_test.exs` for skip/nav/theme/focus;
- page LiveView/presenter tests only for genuinely page-specific copy.

After source CSS changes:

```bash
mix oban_powertools.assets.build
cmp -s assets/oban_powertools/tokens.css \
  priv/static/oban_powertools/oban_powertools.css
```

Never edit packaged CSS independently or update baselines unless a reviewed
visual change actually occurred.

### 11. `verify-phase82-quality.mjs`: compose exact static and artifact checks

**Analogs:**

- `manifest-smoke.mjs` for independent `record`/`array`/`exactFields` helpers
  and fail-closed messages;
- `verify-page-script-order.mjs:9-49` for exact ordered spec membership and
  one-occurrence checks;
- `verify-page-script-order.mjs:278-400` for structured CI parsing and mutation
  tests;
- `verify-page-baselines.mjs` and `verify-page-aria-snapshots.mjs` for exact
  generated artifact set comparison.

The Phase 82 validator should produce a compact deterministic JSON report and
fail on:

- missing/extra/duplicate generated targets or route families;
- raw CSS timing/easing, unknown keyframes, unscoped declarations, missing
  media/root reductions, or source/package drift;
- unknown/stale/unused axe, target, copy, or scroller exception entries;
- hard-coded browser target lists;
- missing/extra Phase 82 spec in host/Docker scripts;
- grep, retry, watch/UI/update mode, ignored failure, duplicate execution, or
  detached required job;
- artifact count/set drift.

Use mutation fixtures for each bypass. A mutation test must first assert that
the mutation changed the source, then assert the validator throws, matching:

```js
assert.notEqual(mutated, original, `${name} mutation fixture must change input`);
assert.throws(() => validate(mutated), undefined,
              `${name} mutation must fail the validator`);
```

Do not put fixture secrets, reasons, DOM dumps, provider payloads, or preview
identity in the JSON report.

### 12. Package and CI: extend the existing direct required graph atomically

**Analogs:**

- `package.json:5-13` for manifest-first, exact validators, then ordered specs;
- `verify-page-script-order.mjs:9-49` for canonical spec order;
- `.github/workflows/ci.yml:109-217` for direct `page_quality` and unfiltered
  `visual_a11y`;
- `.github/workflows/ci.yml:248-277` for exact direct `ci-gate` dependencies.

Recommended order:

```text
showcase:manifest
-> exact manifest / Phase 82 / ARIA / PNG validators
-> Wave 1
-> Wave 2
-> Phase 81 fixture
-> Wave 3
-> Phase 82 connected system sweep
-> page acceptance
-> exhaustive showcase axe + mechanical quality
-> compare-only VRT
```

Add `system-quality.spec.ts` exactly once to both host and Docker commands.
Keep `PAGE_QUALITY_ONLY=1` exact and preserve the full unfiltered
`visual:a11y` job. Ensure both `page_quality` and `visual_a11y` directly reach
`ci-gate`. Add the compact Phase 82 report to failure artifacts alongside the
manifest and existing Playwright results.

No `continue-on-error`, retries, `--grep`, `--update-snapshots`, watch/UI mode,
or optional detached lane is acceptable.

### 13. VoiceOver: extend assertions only, never synthesize evidence

**Analog:** `test/browser/voiceover/page.voiceover.spec.ts` existing exact ten
targets spanning all nine page families.

Keep the current target inventory and real Guidepup execution. Strengthen
expected role/name/state/consequence/recovery phrases only where Phase 82 copy
repairs change the executable contract. Discovery must remain available on all
hosts; transcript execution remains supported-macOS-only. Never fabricate or
manually author a transcript as passing evidence.

## Shared Patterns

### Generated Ownership

- Showcase loops come from `manifest.targets`.
- Page semantic loops come from `manifest.page_stories`.
- Connected route keys are asserted against manifest-derived unique families.
- Counts are validator evidence, not hand-written test selection.

### Fail-Closed Registries

Every exception entry has exact rule/category, exact target scope, rationale,
owner, expiry, and executable compensating assertion. Unknown, stale, broad,
duplicate, expired, unmatched, and unused entries fail.

### Browser State Restoration

Media emulation, root motion attributes, viewport/CDP metrics, theme, open
overlays, and fixture perturbations are restored in `finally`. Serial execution
does not excuse cross-test contamination.

### Diagnostics

Report exact route/story, project, theme, selector/accessibility name, rule,
measured value, exception decision, and expected threshold. Bound lists, redact
secrets, and avoid full DOM/browser-channel dumps.

### Authority and Confidentiality

Auditors do not click arbitrary mutation controls. Existing connected suites
own dangerous transitions through fixture-controlled flows. Preserve the Phase
79–81 channel scans and never render/log/store preview tokens, reasons,
before/after snapshots, provider payloads, credentials, raw exceptions, or
fixture sentinels in accessibility artifacts.

### One Semantic Tree

Responsive repairs alter CSS placement/visibility in one DOM. They never add
parallel mobile/desktop tables, dialogs, data, IDs, controls, or confidential
values.

## Tests and Wave-0 Fixtures

Write RED contracts before implementation:

1. Contrast: alpha composition, normal/large thresholds, muted floor,
   non-text boundary, high-contrast 7:1, unrounded failure, unknown gradient.
2. Target: 24×24, spacing circles, collisions, overlap, explicit exceptions,
   stale exceptions, and separate 44px comfort rule.
3. Focus: detached focus, viewport intersection, sticky/full occlusion,
   partial visibility, modal overlay, 2px outline, adjacent contrast,
   restoration fallback.
4. Reflow: root/body/document overflow, labelled machine scroller, unnamed
   scroller, ordinary action inside scroller, duplicate tree, zoom restoration.
5. Motion: raw timing/easing, unknown keyframe, missing either reduction path,
   hidden content, delayed focus/action, normal inventory.
6. Copy: every forbidden/order/state/recovery/receipt case plus stale
   exclusions.
7. Manifest/routes: missing/duplicate target, missing/extra route family,
   hard-coded target list.
8. CI: omitted/reordered/filtered/duplicated spec, update mode, ignored
   failure, detached job, missing gate edge.

Place pure geometry/color helpers behind exported functions that can accept
small deterministic fixtures. Do not require full connected navigation for
algorithm unit cases.

## Security Checklist

- Exact generated inventory prevents false-green omission.
- Closed, expiring, executable exception registries prevent waiver laundering.
- Required graph mutation tests prevent CI bypass.
- Compare-only evidence and update-mode rejection prevent artifact laundering.
- Bounded diagnostics and active-target DOM scans prevent resource exhaustion.
- Computed visibility, activeElement, rects, and hit testing prevent geometry
  spoofing.
- Unknown color adjacency fails rather than guessing.
- Test-only authenticated fixtures remain secret-gated, POST-only, and
  production-disabled.
- Accessibility helpers do not acquire mutation or authorization authority.
- Source/package equality prevents asset split-brain.
- Hostile long/Unicode/RTL content remains escaped and bounded.

## Anti-Patterns to Reject

- A second target/story array in TypeScript.
- Treating the nine route map as a replacement showcase inventory.
- A separate 1,956-case quality spec that repeats navigation already owned by
  `showcase.a11y.spec.ts`.
- Calling the existing one-axis 44px helper a WCAG 2.5.8 implementation.
- `toBeFocused()` without occlusion and indicator checks.
- Testing only OS reduced motion or only explicit-root reduced motion.
- Raw regex grep with broad exclusions as the sole copy/CSS parser.
- Screenshot-pixel contrast when computed colors and adjacency are available.
- Page-local focus, motion, target, status, copy, or responsive systems.
- Baseline updates presented as compare-only completion evidence.
- Retries, sleeps, parallel shared-fixture workers, or ignored failures.

## Files That Should Not Change

- dependency manifests or lockfiles;
- routes, permission names, schemas, or migrations;
- domain mutation modules;
- page story IDs/counts except a proven false story;
- Phase 83 contributor documentation or new showcase stories;
- screenshots/ARIA snapshots when no reviewed visual/semantic change occurred;
- production fixture exposure.

## Metadata

**Analog search scope:** Phase 73/79/80/81 planning artifacts; `lib/oban_powertools/web`; `assets/oban_powertools`; `test/oban_powertools/web`; `test/browser`; `scripts`; `package.json`; `.github/workflows`
**Primary analogs:** 18 files/file families
**Expected new files:** 6
**Expected modified seams:** 14 file families, many conditional on RED failures
**Pattern extraction date:** 2026-07-29
