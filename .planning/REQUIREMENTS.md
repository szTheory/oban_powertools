# Requirements

## Milestone Goal

**v1.10 Observability & Native Job-Surface Polish**: Enhance the native operator surfaces with optional `oban_met` live counts, deep args/metadata filtering, seamless Lifeline-to-job navigation, cross-page bulk operations, and programmatic list APIs.

## v1.10 Requirements

### Observability
- **QRY-06**: Display real-time job counts in the native UI using `oban_met` as an optional read source (never a hard dependency).

### Native Job-Surface Polish
- **QRY-05**: Support filtering jobs by arguments and metadata on the native job list page.
- **QRY-07**: Provide deep links from the Lifeline repair/audit surfaces directly to the corresponding job detail page.
- **QRY-08**: Support cross-page "select all" for bulk operations on the native job list page.
- **API-03**: Expose a programmatic `Operator.list/2` Elixir API for querying jobs with the same filter semantics as the UI.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| QRY-05 | Phase 64 | Complete |
| API-03 | Phase 64 | Pending |
| QRY-07 | Phase 65 | Pending |
| QRY-08 | Phase 65 | Pending |
| QRY-06 | Phase 66 | Pending |
