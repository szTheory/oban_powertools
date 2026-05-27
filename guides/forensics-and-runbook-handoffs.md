# Forensics and Runbook Handoffs

This guide is the canonical v1.4 source for how operators move from diagnosis to
follow-up while keeping ownership and support-truth boundaries explicit.

## Operator Journey Spine

`DOC05-C1`: The canonical operator journey is `/ops/jobs` -> `/ops/jobs/forensics`
-> ownership-labeled next path -> `/ops/jobs/audit`.

Use that path when moving from native diagnosis to follow-up and then back to
auditable evidence.

## Evidence Boundaries

`DOC05-C2`: Forensics evidence can be complete or incomplete, and operators must
treat these labels as authoritative:

- `partial evidence`
- `history unavailable`
- `unknown`

If a label shows incomplete evidence, prefer explicit follow-up instead of
assuming hidden certainty.

## Ownership-Labeled Next Paths

At each decision point, keep the next path label explicit:

- `Powertools-native` - native page flow for `Audited action`.
- `Oban Web bridge` - `Inspection only`.
- `host-owned follow-up` - downstream investigation or escalation outside
  Powertools ownership.

## Escalation Status Truth

`DOC05-C3`: Powertools can only claim host follow-up status visibility for
`unconfigured`, `invoked`, and `failed`.

These statuses describe what Powertools can observe, not downstream provider
outcomes.

## What Powertools Does Not Claim

Powertools does not claim provider delivery certainty, and it does not claim
external runbook truth. Paging delivery, ticket completion, and downstream
human/process outcomes remain host-owned responsibilities.
