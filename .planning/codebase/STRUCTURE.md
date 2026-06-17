# Codebase Structure

**Analysis Date:** 2024-05-24

## Directory Layout

```
[project-root]/
├── lib/
│   ├── oban_powertools.ex           # Main Application API
│   └── oban_powertools/             # Core Logic
│       ├── batch.ex                 # Batch Schema & API
│       ├── batch/                   # Batch sub-components
│       │   └── tracker.ex           # Batch Progress Exactly-Once tracking
│       ├── chain.ex                 # Chain Builder API
│       ├── chain/                   # Chain sub-components
│       │   └── progression.ex       # Chain Dispatch step execution
│       ├── lifeline.ex              # Audited Operator actions
│       ├── lifeline/                # Audited actions logic
│       ├── plugin/                  # Oban Plugins
│       │   └── callback_dispatcher.ex # Polls & dispatches callbacks
│       ├── web/                     # Operator Console UI
│       │   ├── router.ex            # Route injections & optional Oban Web Bridge
│       │   ├── *_live.ex            # Phoenix LiveViews (e.g. batches_live.ex)
│       │   └── oban_web_bridge.ex   # Connects read-only dashboard to host
│       └── ...                      # Additional modules (workflow, forensics, etc)
```

## Directory Purposes

**`lib/oban_powertools/`:**
- Purpose: Contains all domain schemas, context managers, and business logic primitives.
- Contains: `Batch`, `Chain`, `Workflow`, `Lifeline`, `Cron` models and services.
- Key files: `batch.ex`, `chain.ex`, `lifeline.ex`.

**`lib/oban_powertools/plugin/`:**
- Purpose: Contains long-running Oban integrations via GenServer.
- Contains: Plugins that adhere to the `Oban.Plugin` behavior.
- Key files: `callback_dispatcher.ex`.

**`lib/oban_powertools/web/`:**
- Purpose: Houses the Operator Console Native UI and bridging utilities.
- Contains: `LiveView` modules, Web Router macros, Auth hooks, and read-models.
- Key files: `router.ex`, `batches_live.ex`, `lifeline_live.ex`, `jobs_live.ex`.

## Key File Locations

**Entry Points:**
- `lib/oban_powertools/web/router.ex`: Mounts the route tree to the host application.
- `lib/oban_powertools/plugin/callback_dispatcher.ex`: Background worker that sweeps `oban_powertools_callbacks` table.

**Configuration:**
- `lib/oban_powertools/runtime_config.ex`: Resolves dynamic repo and application configs securely.

**Core Logic:**
- `lib/oban_powertools/batch.ex`: Logic for defining and inserting large streams of jobs safely.
- `lib/oban_powertools/chain.ex`: Logic for strictly typed, verified job chain arrays.
- `lib/oban_powertools/batch/tracker.ex`: Handles `Oban.Worker` lifecycle hooks to verify job status correctly against batches.

**Testing:**
- `test/oban_powertools/`: Standard ExUnit tests mirroring the `lib/oban_powertools` hierarchy.

## Naming Conventions

**Files:**
- snake_case for standard elixir files: `callback_dispatcher.ex`
- web/ui components suffix with `_live`: `batches_live.ex`, `workflows_live.ex`

**Directories:**
- Plurality maps to domain boundaries internally (`batch/`, `chain/`, `workflow/`), while the root interface uses the same singular noun (`batch.ex`, `chain.ex`).

## Where to Add New Code

**New Feature (Domain Logic):**
- Primary code: `lib/oban_powertools/[feature].ex`
- Sub-components: `lib/oban_powertools/[feature]/[sub_component].ex`
- Tests: `test/oban_powertools/[feature]_test.exs`

**New Web Component/Module:**
- Implementation: `lib/oban_powertools/web/[feature]_live.ex`
- Routes: Update `oban_powertools_routes/1` inside `lib/oban_powertools/web/router.ex`

**Utilities:**
- Shared helpers should go inside contextual namespaces like `lib/oban_powertools/[context]/utils.ex` or remain internal `defp` within the relevant modules.

## Special Directories

**`examples/`:**
- Purpose: Contains functional sample applications demonstrating host integration (e.g. `phoenix_host`).
- Generated: No
- Committed: Yes

---

*Structure analysis: 2024-05-24*