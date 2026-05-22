# Phase 10: Operator UX Coherence & Mutation Safety - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 15
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/lifeline/repair_preview.ex` | model | CRUD | `lib/oban_powertools/lifeline/repair_preview.ex` | exact |
| `lib/oban_powertools/lifeline.ex` | service | request-response | `lib/oban_powertools/lifeline.ex` | exact |
| `lib/oban_powertools/cron.ex` | service | request-response | `lib/oban_powertools/cron.ex` + `lib/oban_powertools/lifeline.ex` | strong |
| `lib/oban_powertools/web/live_auth.ex` | middleware | request-response | `lib/oban_powertools/web/live_auth.ex` | exact |
| `lib/oban_powertools/web/cron_live.ex` | component | request-response | `lib/oban_powertools/web/cron_live.ex` + `lib/oban_powertools/web/lifeline_live.ex` | strong |
| `lib/oban_powertools/web/lifeline_live.ex` | component | request-response | `lib/oban_powertools/web/lifeline_live.ex` | exact |
| `lib/oban_powertools/web/audit_live.ex` | component | request-response | `lib/oban_powertools/web/audit_live.ex` + `lib/oban_powertools/web/lifeline_live.ex` | strong |
| `lib/oban_powertools/web/workflows_live.ex` | component | request-response | `lib/oban_powertools/web/workflows_live.ex` | exact |
| `lib/oban_powertools/web/oban_web_bridge.ex` | adapter | request-response | `lib/oban_powertools/web/oban_web_bridge.ex` | exact |
| `lib/oban_powertools/runtime_config.ex` | utility | request-response | `lib/oban_powertools/runtime_config.ex` | exact |
| `README.md` | docs | static | `README.md` | exact |
| `test/oban_powertools/cron_test.exs` | test | request-response | `test/oban_powertools/cron_test.exs` + `test/oban_powertools/lifeline_test.exs` | strong |
| `test/oban_powertools/lifeline_test.exs` | test | request-response | `test/oban_powertools/lifeline_test.exs` | exact |
| `test/oban_powertools/web/live/cron_live_test.exs` | test | request-response | `test/oban_powertools/web/live/cron_live_test.exs` | exact |
| `test/oban_powertools/web/live/lifeline_live_test.exs` | test | request-response | `test/oban_powertools/web/live/lifeline_live_test.exs` | exact |

## Pattern Assignments

### `lib/oban_powertools/lifeline/repair_preview.ex`

**Strongest analogs**
- Current schema fields already cover `preview_token`, action, target identity, status, before/after state, affected counts, reason requirement, and expiry.  
- `changeset/2` is the existing durable-preview choke point.

**Apply this**
- Prefer generalizing this schema/API over inventing a second preview persistence model.
- Keep status and reason fields grep-able and explicit.
- If additional shared preview data is required, add it in bounded schema fields or metadata rather than duplicating preview persistence in LiveViews.

### `lib/oban_powertools/lifeline.ex`

**Strongest analogs**
- `preview_repair/4` and `execute_repair/5` already implement the target pattern: authorize, persist/reuse preview, validate reason, re-check preview safety, mutate in `Ecto.Multi`, then write audit evidence.

**Apply this**
- Treat Lifeline as the mutation-safety reference implementation for Phase 10.
- Extract reusable preview lifecycle helpers from here rather than rewriting cron-specific logic from scratch.

### `lib/oban_powertools/cron.ex`

**Strongest analogs**
- Existing operator actions thread durable audit writes explicitly but have no durable preview row.
- `run_now/4` already proves cron has a two-step audit story (`previewed` then `run_now`) that can be upgraded into the shared preview model.

**Apply this**
- Bring cron onto the durable preview lifecycle without weakening its existing audit/telemetry behavior.
- Keep mutation execution and audit writes in service code, not LiveView-only helpers.

### `lib/oban_powertools/web/live_auth.ex`

**Strongest analogs**
- Centralized page authorization, action authorization, and principal derivation already exist here.

**Apply this**
- Keep read-only vs mutation capability gating centralized at this layer where possible.
- If Phase 10 needs shared read-only messages or status normalization, prefer helpers here or alongside it rather than per-page reinvention.

### `lib/oban_powertools/web/cron_live.ex`

**Strongest analogs**
- Disabled-with-explanation buttons and preview-first UX already exist.
- Lifeline provides the stronger durable-preview version of the same operator pattern.

**Apply this**
- Replace socket-only preview state with a durable preview contract while preserving the existing page-level read-only posture.
- Move page-local preview/error vocabulary into shared helpers once the contract is explicit.

### `lib/oban_powertools/web/lifeline_live.ex`

**Strongest analogs**
- Preview, execute, drift, consumed, and reason-required states are already operator-visible here.
- Inline audit visibility and post-execute continuity are the strongest current UI precedents.

**Apply this**
- Reuse Lifeline’s user-visible mutation states as the vocabulary baseline for other native mutation pages.
- Avoid regressing its explicit inline evidence just to simplify the shared contract.

### `lib/oban_powertools/web/audit_live.ex`

**Strongest analogs**
- Thin, policy-aware read-only audit table over durable evidence.

**Apply this**
- Keep it read-only, but align its copy and provenance framing with the same vocabulary native mutation pages use.
- Use it to prove “global audit remains useful, but evidence also stays near the acted-on resource.”

### `lib/oban_powertools/web/workflows_live.ex`

**Strongest analogs**
- Read-only workflow diagnosis surface with shared display-policy rendering and an Oban Web deep link.

**Apply this**
- Keep workflows read-only and focused on provenance/support-truth.
- Align read-only framing and deep-link copy with the bridge story used elsewhere.

### `lib/oban_powertools/web/oban_web_bridge.ex`

**Strongest analogs**
- Current resolver-based `:read_only` access mapping and display-policy formatting hooks are already the correct technical posture.

**Apply this**
- Preserve `:read_only` as the bridge contract.
- Tighten messaging/tests around the bridge instead of widening the adapter.

### `lib/oban_powertools/runtime_config.ex`

**Strongest analogs**
- Existing config seam helpers for `auth_module` and `display_policy`.

**Apply this**
- Only add new runtime configuration if Phase 10 absolutely needs a bounded host override.
- Prefer library-owned defaults and shared helpers before expanding public config surface area.

## Shared Patterns

- **Lifeline is the preview/mutation pattern library:** durable preview rows, preview drift, consumed preview, reason validation, and post-execute audit continuity already exist there.
- **Cron is the simplest convergence target:** it already shows disabled controls and a preview-first UX, so it is the right first native surface to pull onto the shared preview contract.
- **Read-only surfaces should stay evidence-first:** audit and workflows already read raw durable state and render through `DisplayPolicy`; Phase 10 should align vocabulary, not invent mutation flows there.
- **Bridge remains thin and nested:** `ObanPowertools.Web.ObanWebBridge` plus `router_test.exs` are the existing bounded pattern.
- **Focused contract tests are the repo norm:** backend tests prove service semantics; LiveView tests prove rendered trust behavior.

## Anti-Patterns

- Do not create a second durable preview persistence model beside the existing Lifeline preview table unless reuse is impossible.
- Do not leave cron as the only mutation surface using socket-only preview state.
- Do not add bridge writes or bridge-only policy seams.
- Do not solve read-only coherence with hidden controls instead of disabled-with-explanation controls.
- Do not move mutation safety checks out of services and into LiveView-only code.

## Metadata

**Analog search scope:** `lib/oban_powertools/**/*.ex`, `test/oban_powertools/**/*.exs`, `README.md`  
**Files scanned:** 18  
**Pattern extraction date:** 2026-05-21
