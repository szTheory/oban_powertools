defmodule ObanPowertools do
  @moduledoc """
  Phoenix-first operator primitives for Oban-backed applications.

  Oban Powertools is intentionally split into two layers:

  - the library owns durable runtime helpers, native `/ops/jobs` pages, and bounded adapters
  - the host app owns routing scope, browser pipeline, auth, display policy, runtime config, and
    whether the optional Oban Web bridge is exposed

  The public builder-facing primitives live in these modules:

  - `ObanPowertools.Worker` for typed arguments, synchronous validation, and idempotent enqueue
  - `ObanPowertools.Batch` for fixed-size batch grouping and bounded stream insertion
  - `ObanPowertools.Chain` for strictly linear job composition over batch metadata
  - `ObanPowertools.Limits` and `ObanPowertools.Explain` for durable limiter reservations and
    blocker inspection
  - `ObanPowertools.Workflow` for durable DAG definitions plus dependency reconciliation
  - `ObanPowertools.Lifeline` for executor health, incident projection, and preview-backed repair

  Start with `README.md` for the install and operator path, then use the guides in `guides/`
  for builder-facing examples of each primitive.
  """
end
