# Phase 46: Operator Elixir API

**Goal**: Host app code can programmatically retry, cancel, or discard jobs with the same audit guarantee as the UI
**Depends on**: Phase 45
**Requirements**: API-01, API-02

**Success Criteria** (what must be TRUE):
1. `ObanPowertools.Operator` exposes typed functions for single-job retry, cancel, and discard — each requires a non-nil actor and produces a durable audit record.
2. `ObanPowertools.Operator` exposes typed functions for bulk retry, cancel, and discard accepting a list of job IDs — returns per-job result reporting matching the UI behavior.
3. API functions call the same `Lifeline.execute_repair` pipeline the UI phases established — no parallel mutation path exists.
4. Telemetry emitted from API calls carries `source: "api"` metadata and remains within the frozen `@contract` (no new high-cardinality keys added).
