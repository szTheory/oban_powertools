# Phase 6: Runtime Config & Authorization Hardening - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/oban_powertools.install.ex` | utility | file-I/O | `lib/mix/tasks/oban_powertools.install.ex` | exact |
| `lib/oban_powertools/auth.ex` | interface | request-response | `lib/oban_powertools/auth.ex` | exact |
| `lib/oban_powertools/runtime_config.ex` | utility | request-response | `lib/oban_powertools/auth.ex` + `lib/oban_powertools/audit.ex` | role-match |
| `lib/oban_powertools/application.ex` | config | event-driven | `lib/oban_powertools/application.ex` | exact |
| `lib/oban_powertools/web/live_auth.ex` | utility | request-response | `lib/oban_powertools/web/live_auth.ex` | exact |
| `lib/oban_powertools/web/cron_live.ex` | component | request-response | `lib/oban_powertools/web/cron_live.ex` + `lib/oban_powertools/web/lifeline_live.ex` | role-match |
| `test/mix/tasks/oban_powertools.install_test.exs` | test | file-I/O | `test/mix/tasks/oban_powertools.install_test.exs` | exact |
| `test/oban_powertools/auth_test.exs` | test | request-response | `test/oban_powertools/auth_test.exs` | exact |
| `test/oban_powertools/web/live/cron_live_test.exs` | test | request-response | `test/oban_powertools/web/live/cron_live_test.exs` + `test/oban_powertools/web/live/lifeline_live_test.exs` | role-match |
| `config/test.exs` | config | request-response | `config/test.exs` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` | exact |
| `.planning/phases/6-runtime-config-authorization-hardening/6-VERIFICATION.md` | config | transform | `.planning/phases/5-05-SUMMARY.md` + `.planning/phases/5-PLAN-CHECK.md` | partial |

## Pattern Assignments

### Installer contract: extend the existing Igniter task rather than inventing a second setup path

**Strongest analog**
- `lib/mix/tasks/oban_powertools.install.ex`

**Apply this**
- Keep the installer as the single paved-road host integration entrypoint.
- Add explicit runtime config injection adjacent to the auth-module scaffolding and router scope setup so the generated integration contract stays grep-able.
- Verify by source assertions in `test/mix/tasks/oban_powertools.install_test.exs`, matching the repo’s established installer-test style.

### Runtime config helper: follow `Auth` / `Audit` public-helper posture

**Strongest analogs**
- `lib/oban_powertools/auth.ex`
- `lib/oban_powertools/audit.ex`

**Apply this**
- Expose narrow public helpers like `repo!/0`, `repo/1`, `auth_module!/0`, or explicit `require_repo!/1` style functions from one module.
- Return explicit tagged tuples where callers need recoverable setup checks; raise purpose-built setup errors where the surface must fail fast.
- Keep error copy stable and grep-able because Phase 6 verification will assert on the exact setup contract.

### Preview authorization: copy the `LifelineLive` ordering, not the current `CronLive` ordering

**Strongest analogs**
- `lib/oban_powertools/web/lifeline_live.ex`
- `lib/oban_powertools/web/live_auth.ex`

**Apply this**
- Authorize the preview event before assigning preview state.
- Only after authorization succeeds should the page assign `@preview`, accept a reason, or emit preview telemetry.
- Preserve confirm-time authorization as defense in depth, but it becomes a second check rather than the first check.

### Disabled-with-explanation actions: compute capability up front and keep render-state explicit

**Strongest analogs**
- `lib/oban_powertools/web/lifeline_live.ex` for explicit unauthorized messages
- `lib/oban_powertools/web/cron_live.ex` for row-level action rendering

**Apply this**
- Build row-level action metadata that includes `enabled?`, `label`, `action`, and `disabled_reason`.
- Render the same action set for viewers/operators, but bind `disabled` plus inline explanatory copy when the actor lacks permission.
- Keep the explanation server-rendered and text-based so it is visible in LiveView tests without depending on hover-only affordances.

### Verification style: extend focused repo-local tests rather than adding broad integration harnesses first

**Strongest analogs**
- `test/mix/tasks/oban_powertools.install_test.exs`
- `test/oban_powertools/web/live/cron_live_test.exs`
- `test/oban_powertools/web/live/lifeline_live_test.exs`

**Apply this**
- Prefer targeted assertions on installer source, setup helper behavior, preview telemetry, preview-state rendering, and unauthorized messages.
- Add one or two host-like config tests by temporarily overriding application env in test cases, rather than building a fake demo app.

## Shared Patterns

- Keep host config explicit and library behavior boring; the same rule already governs the auth scaffolding and prior phase decisions.
- Reuse page-level auth and compact native LiveView surfaces; do not expand Phase 6 into a broader UI redesign.
- Prefer tagged tuples and consistent error copy over implicit nil/false control flow.

## Anti-Patterns

- No second installer or runtime bootstrap path outside `mix oban_powertools.install`.
- No preview-state assignment before authorization.
- No tooltip-only or CSS-only permission explanation.
- No verification story that passes solely because `config/test.exs` globally supplies the missing runtime keys.

