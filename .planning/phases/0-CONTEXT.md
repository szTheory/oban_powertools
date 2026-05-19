# Phase 0 Context: Foundation & Bridge

## Project DNA Alignment
Per the project roadmap and our deep ecosystem research, Oban Powertools follows the "szTheory SaaS-in-a-Box" DNA: **Host-Owned, Ecto-Native, and Operator-First**. The primary goal of Phase 0 is to lay down this infrastructure safely and cleanly, preparing the ground for advanced features in subsequent phases.

## Core Architectural Decisions

### 1. Igniter Installer Strategy (Host-Owned)
*   **Decision:** The `mix oban_powertools.install` command will generate explicit, editable code within the host application rather than relying on opaque macros.
*   **Scope:**
    *   Injects the `oban_powertools_audit_events` Ecto migration.
    *   Injects the `/ops/jobs` LiveView route scope into the host's `router.ex`.
    *   Generates a host-owned Auth module (see below).
    *   Generates the base Telemetry supervisor hook for Parapet integration.

### 2. The Oban Web Bridge (Runtime Detection)
*   **Decision:** We will employ a "Hybrid Web Strategy." `oban_web` remains an *optional* dependency.
*   **Mechanism:** Inside the injected `router.ex` scope, we will use `Code.ensure_loaded?(Oban.Web.Router)` to dynamically detect if Oban Web is installed.
*   **Integration:** If detected, we mount it at `/ops/jobs/oban` and wire it to use our host-owned Auth behaviour. This provides the mature generic job/queue UI from Oban Web immediately, while reserving the rest of `/ops/jobs/*` for our Native Powertools Shell (Limiters, Workflows, etc.).

### 3. Auth & Sigra Integration (Explicit Behaviours)
*   **Decision:** No black-box plugs. We define a strict `@behaviour ObanPowertools.Auth` requiring a `current_actor/1` callback.
*   **Mechanism:** Igniter generates `MyAppWeb.ObanPowertoolsAuth` which implements this behaviour. The developer wires this directly to their Sigra implementation. The Native Powertools Shell and the Oban Web Bridge will both share this single source of truth for access control and audit attribution.

### 4. Telemetry & Parapet (Low Cardinality)
*   **Decision:** Establish a strict `:telemetry` contract immediately.
*   **Mechanism:** Define base events (e.g., `[:oban_powertools, :operator_action, :complete]`). These must be strictly cardinality-safe (no raw IDs in metric labels) to prevent Prometheus explosions, acting as a paved road for Parapet SLIs. High-cardinality evidence is relegated to the `oban_powertools_audit_events` table.

## Next Steps
With these decisions locked in, we are ready to move to the planning stage for Phase 0 to outline the exact execution steps.