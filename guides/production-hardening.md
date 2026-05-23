# Production Hardening

Use this checklist after the first successful operator session.

## Checklist

- Confirm the host browser pipeline around `/ops/jobs` matches your real auth boundary. The
  native shell assumes the same session/auth posture your operators already use elsewhere in the
  host application.
- Treat `auth_module` as host-owned application logic, not a generated placeholder. The library
  depends on it for current-actor lookup and authorization decisions, but the policy remains your
  responsibility.
- Treat actor/session lookup as a host-owned seam. Verify that the same operator identity reaches
  native pages, LiveView mounts, and any optional bridge request path.
- Treat `display_policy` as a production redaction boundary. It should reflect the data your
  operators may inspect and the fields you need to hide.
- Verify `repo` wiring and process supervision in the same environment where operators work so
  persistence-backed native pages can boot cleanly.
- Decide whether the optional `/ops/jobs/oban` bridge belongs in production at all. If you do
  expose it, keep it aligned with the narrower read-only support posture.
- Review reverse-proxy and WebSocket behavior before rollout. LiveView transport failures at the
  edge will make `/ops/jobs` feel broken even when the library is configured correctly.
- Review telemetry consumers against the public low-cardinality telemetry contract and avoid
  coupling downstream dashboards to private payload details.

## Telemetry

Powertools telemetry is public API. Keep consumers aligned to the published low-cardinality
event families and do not depend on job args, preview tokens, or free-form reasons appearing in
telemetry payloads.

## Policy seams

The host owns authorization, actor identity, display-policy output, the outer router scope, and
the browser pipeline in front of `/ops/jobs`. Do not ship production defaults until those seams
reflect your real operator, redaction, and deployment rules.
