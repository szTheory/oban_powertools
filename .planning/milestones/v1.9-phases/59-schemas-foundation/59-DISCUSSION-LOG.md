# Phase 59 Discussion Log: Schemas & Foundation

*This file is an immutable append-only log of the discussion that produced CONTEXT.md. It is not consumed by downstream agents.*

## Discussion: Callback Outbox Evolution
**Options Presented:**
- Should we rename the existing `workflow_callback_outbox` table to preserve v1.2 records, or create a brand new `callbacks` table and deprecate the old one?

**User Selection:**
- Selected for deep research and synthesis.

**Notes:**
- A single generalized outbox (`callbacks`) is idiomatic Ecto, adheres to the principle of least surprise, and ensures uniform Lifeline recovery. Ecto migration allows renaming without data loss.

## Discussion: Progress Tracking Structure
**Options Presented:**
- BAT-03 mentions exactly-once tracking. Should we use explicit integer counters on the `batches` row (fast to read, requires row locks) or another method?

**User Selection:**
- Selected for deep research and synthesis.

**Notes:**
- Decided on explicit integer counters updated atomically via `Repo.update_all(inc: [...])` inside worker lifecycle hooks, preventing lock starvation while maintaining O(1) UI reads.

## Discussion: Chain Representation
**Options Presented:**
- Chains are described as "linear-DAG sugar". Do we model chains just via rows in the `callbacks` outbox, or do we need a separate `chains` schema?

**User Selection:**
- Selected for deep research and synthesis.

**Notes:**
- Chains will be modeled as syntactic sugar over the `callbacks` outbox and `batches` schema to prevent schema bloat. No `chains` table will be created.
