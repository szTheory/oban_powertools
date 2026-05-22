# Phase 9: Policy Boundaries & Optional Bridge Contracts - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 16
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/auth.ex` | interface | request-response | `lib/oban_powertools/auth.ex` + `lib/oban_powertools/web/live_auth.ex` | exact |
| `lib/oban_powertools/runtime_config.ex` | utility | request-response | `lib/oban_powertools/runtime_config.ex` + `lib/oban_powertools/auth.ex` | exact |
| `lib/oban_powertools/web/live_auth.ex` | middleware | request-response | `lib/oban_powertools/web/live_auth.ex` + `lib/oban_powertools/web/cron_live.ex` | exact |
| `lib/oban_powertools/web/router.ex` | route | request-response | `lib/oban_powertools/web/router.ex` + `test/oban_powertools/web/router_test.exs` | exact |
| `lib/oban_powertools/audit.ex` | model | CRUD | `lib/oban_powertools/audit.ex` + `lib/oban_powertools/workflow/runtime.ex` | exact |
| `lib/oban_powertools/web/cron_live.ex` | component | request-response | `lib/oban_powertools/web/cron_live.ex` + `lib/oban_powertools/web/lifeline_live.ex` | exact |
| `lib/oban_powertools/web/lifeline_live.ex` | component | request-response | `lib/oban_powertools/web/lifeline_live.ex` | exact |
| `lib/oban_powertools/web/audit_live.ex` | component | request-response | `lib/oban_powertools/web/audit_live.ex` + `lib/oban_powertools/web/lifeline_live.ex` | exact |
| `lib/oban_powertools/web/workflows_live.ex` | component | request-response | `lib/oban_powertools/web/workflows_live.ex` + `lib/oban_powertools/workflow/result.ex` | exact |
| `lib/oban_powertools/workflow/result.ex` | model | CRUD | `lib/oban_powertools/workflow/result.ex` | exact |
| `lib/oban_powertools/workflow/runtime.ex` | service | event-driven | `lib/oban_powertools/workflow/runtime.ex` + `lib/oban_powertools/audit.ex` | exact |
| `test/oban_powertools/auth_test.exs` | test | request-response | `test/oban_powertools/auth_test.exs` | exact |
| `test/oban_powertools/web/router_test.exs` | test | request-response | `test/oban_powertools/web/router_test.exs` + `test/support/test_router.ex` | exact |
| `test/oban_powertools/web/live/cron_live_test.exs` | test | request-response | `test/oban_powertools/web/live/cron_live_test.exs` | exact |
| `test/oban_powertools/web/live/lifeline_live_test.exs` | test | request-response | `test/oban_powertools/web/live/lifeline_live_test.exs` | exact |
| `test/support/test_auth.ex` | test-support | request-response | `test/support/test_auth.ex` | exact |

## Pattern Assignments

### `lib/oban_powertools/auth.ex`

**Strongest analogs**
- `lib/oban_powertools/auth.ex:11-17` for the public behaviour callback block.
- `lib/oban_powertools/auth.ex:21-37` for the RuntimeConfig-backed delegate posture.
- `lib/oban_powertools/auth.ex:42-48` for the permissive audit-id fallback that Phase 9 should replace.

**Apply this**
- Evolve the behaviour in place instead of introducing a second host seam. Keep `current_actor/1` as the entrypoint and extend the same module with explicit authorization and audit-principal callbacks.
- Preserve the narrow delegate surface through `RuntimeConfig`, so every caller still comes through `ObanPowertools.Auth` rather than reaching into host modules directly.
- Replace the current `actor_id/1` fallback ladder with an explicit principal contract. Phase 9 should remove `inspect/1`-style permissive attribution, not add new fallbacks beside it.

### `lib/oban_powertools/runtime_config.ex`

**Strongest analogs**
- `lib/oban_powertools/runtime_config.ex:8-22` for centralized optional/required config getters.
- `lib/oban_powertools/runtime_config.ex:24-44` for stable, asserted setup-error copy.

**Apply this**
- Add any new Phase 9 host-owned policy seam here, adjacent to `auth_module/1`, instead of scattering `Application.get_env/2` calls through LiveViews or router code.
- Keep the current split between non-bang accessors for optional paths and bang accessors for fail-fast public contract points.
- If Phase 9 adds `display_policy`, match the existing `auth_module` shape exactly: `foo/1`, `foo!/1`, and a dedicated `setup_error/1` clause with grep-able copy.

### `lib/oban_powertools/web/live_auth.ex`

**Strongest analogs**
- `lib/oban_powertools/web/live_auth.ex:10-13` for the shared `on_mount` actor assignment.
- `lib/oban_powertools/web/live_auth.ex:15-29` for centralized page-level and event-level authorization helpers.
- `lib/oban_powertools/web/cron_live.ex:30-50` and `lib/oban_powertools/web/lifeline_live.ex:54-92` for how LiveViews consume these helpers before preview state is assigned.

**Apply this**
- Keep all native LiveView auth plumbing centralized here: actor resolution on mount, page authorization on mount, and mutation authorization on events.
- Shift this module from boolean consumption to explicit `:ok` or `{:error, reason}` handling, because both native pages and the bridge need the same least-surprise outcome contract.
- If principal assignment or bridge actor handoff becomes a shared concern, put the adapter here rather than in each LiveView.

### `lib/oban_powertools/web/router.ex`

**Strongest analogs**
- `lib/oban_powertools/web/router.ex:28-49` for the exact nested route shape, `live_session`, and optional `oban_dashboard/2` mount.
- `test/oban_powertools/web/router_test.exs:11-73` for the invariants the router contract already proves.

**Apply this**
- Preserve the Phase 8 ownership boundary exactly: host owns the outer `/ops/jobs` scope and browser pipeline; Powertools owns only the inner route tree and nested `/oban` bridge mount.
- Add bridge hooks only at the nested `oban_dashboard/2` call site. Resolver, formatter, and bridge auth wiring should stay thin and localized there.
- Keep `on_mount: [ObanPowertools.Web.LiveAuth]` as the shared native-and-bridge hook, even if Phase 9 adds more bridge options beside it.

### `lib/oban_powertools/audit.ex`

**Strongest analogs**
- `lib/oban_powertools/audit.ex:12-25` for the minimal durable schema and changeset contract.
- `lib/oban_powertools/audit.ex:27-39` for the normalized `record/4` write seam.
- `lib/oban_powertools/audit.ex:41-65` for resource normalization and read APIs.

**Apply this**
- Keep audit writes explicit and parameter-driven. The public contract should continue to accept principal data through arguments, not through process-local state.
- Extend the existing schema/writer in a bounded way. Prefer threading typed principal fields through `metadata` or explicit params over introducing permissive late normalization.
- Route repo lookup through the same centralized runtime-config posture as the rest of the phase if audit becomes a more visible public seam.

### `lib/oban_powertools/web/cron_live.ex`

**Strongest analogs**
- `lib/oban_powertools/web/cron_live.ex:11-23` for mount-time page authorization before any assigns are exposed.
- `lib/oban_powertools/web/cron_live.ex:26-50` for preview authorization before telemetry or preview state.
- `lib/oban_powertools/web/cron_live.ex:66-85` and `190-197` for confirm-time re-authorization and explicit actor threading into mutation calls.
- `lib/oban_powertools/web/cron_live.ex:216-274` for row-level capability rendering plus recent-audit lookup.

**Apply this**
- Keep the preview-first and authorize-before-preview ordering intact. Phase 9 policy changes should layer onto this flow, not reorder it.
- Replace direct `Auth.actor_id(actor)` mutation plumbing with explicit principal derivation once the auth contract grows that seam.
- Any redaction or display-policy-sensitive copy should move into shared helpers instead of expanding the page-local `source_label/1`, `overlap_label/1`, or audit rendering patterns.

### `lib/oban_powertools/web/lifeline_live.ex`

**Strongest analogs**
- `lib/oban_powertools/web/lifeline_live.ex:15-30` for mount-time authorization and explicit assign bootstrapping.
- `lib/oban_powertools/web/lifeline_live.ex:51-92` for preview authorization before durable preview creation.
- `lib/oban_powertools/web/lifeline_live.ex:103-154` for confirm-time authorization, reason gating, and explicit error branches.
- `lib/oban_powertools/web/lifeline_live.ex:324-390` for the operator-facing audit/principal copy and manual intervention history.
- `lib/oban_powertools/web/lifeline_live.ex:644-808` for shared copy helpers, audit-event selection, and explicit user-facing error text.

**Apply this**
- Use this file as the strongest pattern for Phase 9 native operator flows. It already separates page auth, preview auth, execute auth, durable preview state, and operator-readable audit evidence.
- Replace page-local actor/resource rendering helpers with shared policy-aware display helpers rather than teaching each LiveView its own redaction story.
- Preserve the current explicit failure modes for unauthorized, preview drift, consumed previews, and too-short reasons. Phase 9 should tighten attribution, not hide mutation failures.

### `lib/oban_powertools/web/audit_live.ex`

**Strongest analogs**
- `lib/oban_powertools/web/audit_live.ex:11-20` for simple page-gated loading.
- `lib/oban_powertools/web/audit_live.ex:56-80` for the current audit table rendering contract.
- `lib/oban_powertools/web/lifeline_live.ex:385-390` for richer audit-history presentation already used elsewhere in the UI.

**Apply this**
- Keep this screen as a thin reader over `Audit.list_all/1`; Phase 9 policy work should concentrate on display helpers and principal rendering rather than bespoke query logic here.
- Replace direct `event.actor_id` and `event.metadata["reason"]` rendering with shared formatting/redaction helpers so audit, native pages, and the bridge cannot drift.
- Reuse the existing timestamp formatting posture instead of introducing a second audit-time renderer.

### `lib/oban_powertools/web/workflows_live.ex`

**Strongest analogs**
- `lib/oban_powertools/web/workflows_live.ex:13-32` for page authorization plus optional PubSub subscription.
- `lib/oban_powertools/web/workflows_live.ex:142-175` for the current step-detail rendering posture.
- `lib/oban_powertools/web/workflows_live.ex:187-233` for loading raw `Result` rows and dependency snapshots into display state.

**Apply this**
- Keep workflow inspection read-only and evidence-driven in this phase. If Phase 9 surfaces result payloads or summaries, load the durable data here and apply policy at render time.
- Preserve the current workflow-detail refresh pattern: query raw rows, build a map in-memory, and select the highlighted step deterministically.
- Use the same display-policy seam for workflow results that native audit and bridge pages will use. Do not add workflow-only redaction rules.

### `lib/oban_powertools/workflow/result.ex`

**Strongest analogs**
- `lib/oban_powertools/workflow/result.ex:11-26` for the raw-evidence schema shape.
- `lib/oban_powertools/workflow/result.ex:28-57` for bounded validation on payload metadata and the existing `redacted` marker.

**Apply this**
- Keep storing raw workflow result evidence plus bounded metadata like `payload_bytes`, `summary`, and `redacted`.
- Treat `redacted` as evidence metadata, not as proof that UI rendering is complete. Phase 9 display policy should render from raw payload plus policy context rather than mutating stored payloads into presentation strings.
- If principal or display hooks need more workflow context, attach that context at read/render time before changing this schema.

### `lib/oban_powertools/workflow/runtime.ex`

**Strongest analogs**
- `lib/oban_powertools/workflow/runtime.ex:16-63` for the `Ecto.Multi` mutation pipeline plus audit and telemetry follow-up.
- `lib/oban_powertools/workflow/runtime.ex:105-176` for dependency-driven step transitions with explicit audit events.
- `lib/oban_powertools/workflow/runtime.ex:207-267` for normalized dependency snapshots and payload normalization.

**Apply this**
- Copy the existing `Multi`-first service structure for any Phase 9 workflow mutation changes, but thread explicit principal data through it. This is the right place to tighten audit durability around workflow writes.
- Preserve low-cardinality telemetry behavior by keeping rich payloads, reasons, and principal labels out of telemetry metadata.
- Reuse `normalize_payload/1` and snapshot-building patterns for display-policy inputs. Do not add ad hoc workflow-specific stringification inside runtime writes.

### `test/oban_powertools/auth_test.exs`

**Strongest analogs**
- `test/oban_powertools/auth_test.exs:9-14` for behaviour callback assertions.
- `test/oban_powertools/auth_test.exs:16-40` for runtime-config lookup and per-call override tests.
- `test/oban_powertools/auth_test.exs:43-63` for stable setup-error assertions.

**Apply this**
- Extend this file first when the auth behaviour grows. Assert new callbacks, delegate helpers, and missing-config error copy directly here.
- Keep config override tests narrow and repo-local by using `Application.put_env/3` and restoring state in `on_exit/1`.
- Add explicit tests for the new authorization outcome and audit-principal failure posture instead of relying on LiveView tests alone.

### `test/oban_powertools/web/router_test.exs`

**Strongest analogs**
- `test/oban_powertools/web/router_test.exs:11-47` for route-shape assertions on the native pages.
- `test/oban_powertools/web/router_test.exs:49-73` for the optional bridge boundary and current `resolver:` absence assertion.

**Apply this**
- Keep route tests focused on public contract shape, not implementation internals. Assert paths, `on_mount`, and bridge options through `Phoenix.Router.route_info/4`.
- When Phase 9 adds a supported bridge resolver/formatter contract, replace the current `refute ... =~ "resolver:"` assertion with positive route-shape assertions for the allowed options.
- Continue proving that `/oban` never escapes the host-owned `/ops/jobs` shell.

### `test/oban_powertools/web/live/cron_live_test.exs`

**Strongest analogs**
- `test/oban_powertools/web/live/cron_live_test.exs:27-72` for preview-first mutation, telemetry, and audit verification.
- `test/oban_powertools/web/live/cron_live_test.exs:74-124` for unauthorized preview rejection before state or telemetry.
- `test/oban_powertools/web/live/cron_live_test.exs:126-162` for inline disabled-action explanations.

**Apply this**
- Extend this file to prove policy parity on the cron screen: same auth outcome, same principal requirements, and same redaction/formatting behavior before and after preview.
- Keep assertions operator-visible. The existing tests read rendered text, telemetry, and durable audit state directly; Phase 9 should keep that style.
- Add negative-path coverage for “authorized actor but missing audit principal” here if cron remains the simplest mutation path.

### `test/oban_powertools/web/live/lifeline_live_test.exs`

**Strongest analogs**
- `test/oban_powertools/web/live/lifeline_live_test.exs:11-14` for unauthorized mount handling.
- `test/oban_powertools/web/live/lifeline_live_test.exs:37-65` for durable preview plus reason gating.
- `test/oban_powertools/web/live/lifeline_live_test.exs:98-147` and `149-179` for post-execute audit continuity and unauthorized execute behavior.

**Apply this**
- Use this file as the main contract proof for explicit principal attribution and operator-readable audit copy on mutation-heavy flows.
- Preserve the current end-to-end posture: preview creation, reason entry, execute, remount, and audit-history assertions in one focused test.
- Add Phase 9 cases here for principal validation and shared display-policy rendering, because Lifeline already exercises the richest audit UI.

### `test/support/test_auth.ex`

**Strongest analogs**
- `test/support/test_auth.ex:4-8` for the minimal session/socket actor resolver.
- `test/support/test_auth.ex:10-16` for the permission-driven authorization double.

**Apply this**
- Keep the host-auth test double intentionally small and explicit. Extend it in place to mirror the new public auth behaviour rather than adding hidden testing shortcuts elsewhere.
- Return the same outcome shapes the real contract requires. If Phase 9 moves to `:ok` and `{:error, reason}`, this test double should become the first consumer of that change.
- Add audit-principal test helpers here if the contract requires them, so LiveView tests can keep using realistic host-owned seams.

## Shared Patterns

- **One host-owned policy seam, library-owned adapters:** `lib/oban_powertools/auth.ex:21-37`, `lib/oban_powertools/runtime_config.ex:8-44`, and `lib/oban_powertools/web/live_auth.ex:10-29` are the baseline. New policy config belongs in `RuntimeConfig`; all call sites should keep going through `Auth` or `LiveAuth`.
- **Authorize on mount and on mutation:** `lib/oban_powertools/web/cron_live.ex:11-23`, `26-50`, and `66-85`, plus `lib/oban_powertools/web/lifeline_live.ex:15-30`, `51-92`, and `103-154`, define the established defense-in-depth posture.
- **Keep bridge scope narrow and nested:** `lib/oban_powertools/web/router.ex:28-49` and `test/oban_powertools/web/router_test.exs:49-73` freeze the host-owned outer shell and the Powertools-owned nested `/ops/jobs/oban` bridge.
- **Durable evidence stays raw; policy applies at render time:** `lib/oban_powertools/workflow/result.ex:11-57`, `lib/oban_powertools/workflow/runtime.ex:29-40`, and `lib/oban_powertools/web/workflows_live.ex:187-233` show the repo’s current evidence-first posture. Phase 9 should render through shared helpers rather than persisting presentation strings.
- **Rich operator evidence belongs in audit/UI, not telemetry:** `lib/oban_powertools/web/cron_live.ex:34-37`, `lib/oban_powertools/workflow/runtime.ex:50-58`, and the Phase 8 telemetry boundary remain the governing pattern.
- **Focused contract tests beat broad harnesses:** `test/oban_powertools/auth_test.exs`, `test/oban_powertools/web/router_test.exs`, `test/oban_powertools/web/live/cron_live_test.exs`, and `test/oban_powertools/web/live/lifeline_live_test.exs` already prove public behavior with minimal scaffolding. Extend those first.

## Anti-Patterns

- Do not add a second auth or bridge-specific host policy module. Phase 9 should evolve `auth_module` and adapt it, not fork the contract by surface.
- Do not keep or expand permissive attribution fallbacks like `Auth.actor_id/1` using `inspect/1`, `nil`, or session heuristics for durable audit writes.
- Do not move policy-sensitive formatting into page-local helpers on `CronLive`, `LifelineLive`, `AuditLive`, or `WorkflowsLive`.
- Do not widen the bridge contract past documented hooks on the nested `oban_dashboard/2` mount.
- Do not put actor ids, labels, reasons, or rendered payloads into telemetry metadata.
- Do not persist presentation-only redacted strings into workflow result rows when raw evidence plus display policy is sufficient.
- Do not weaken the existing authorize-before-preview and authorize-before-execute ordering on native mutation flows.

## Metadata

**Analog search scope:** `lib/oban_powertools/**/*.ex`, `test/oban_powertools/**/*.exs`, `test/support/*.ex`
**Files scanned:** 22
**Pattern extraction date:** 2026-05-21
