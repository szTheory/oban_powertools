# Roadmap

## Phases

- [x] **Phase 64: Args/Meta Filtering & Programmatic Querying** - API and UI support for precise filtering of jobs by arguments and metadata (completed 2026-06-17)
- [ ] **Phase 65: Cross-Page Bulk & Navigation Polish** - Lifeline deep links and cross-page selection for bulk actions
- [ ] **Phase 66: Optional Live Counts** - Real-time job and queue counts powered optionally by `oban_met`

## Phase Details

### Phase 64: Args/Meta Filtering & Programmatic Querying
**Goal**: Operators and API consumers can precisely query jobs by argument and metadata values
**Depends on**: Phase 63
**Requirements**: QRY-05, API-03
**Success Criteria** (what must be TRUE):
  1. API consumer can call `Operator.list/2` with args/meta filters and receive matching jobs.
  2. User can filter the native job list UI by specific arguments and metadata keys/values.
  3. UI URL updates to reflect the args/meta filters so they can be bookmarked and shared.
**Plans**: 2 plans
- [x] 64-01-PLAN.md — Domain layer: Jobs filtering & Operator API
- [x] 64-02-PLAN.md — Web layer: JobsLive filtering inputs
**UI hint**: yes

### Phase 65: Cross-Page Bulk & Navigation Polish
**Goal**: Operators can easily navigate repair contexts and execute bulk actions across large result sets
**Depends on**: Phase 64
**Requirements**: QRY-07, QRY-08
**Success Criteria** (what must be TRUE):
  1. User can click a job ID in Lifeline audit or reason views to jump directly to the job detail page.
  2. User can select a "Select all X matching jobs" option when results span multiple pages on the job list.
  3. Bulk actions applied to a cross-page selection correctly process the entire set.
**Plans**: TBD
**UI hint**: yes

### Phase 66: Optional Live Counts
**Goal**: Operators have real-time visibility into queue and state counts when supported
**Depends on**: Phase 65
**Requirements**: QRY-06
**Success Criteria** (what must be TRUE):
  1. User sees real-time job counts in the UI when `oban_met` is configured.
  2. The system functions normally without `oban_met` (no hard dependency is introduced).
  3. Counts automatically update without requiring a full page reload.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 64. Args/Meta Filtering & Programmatic Querying | 2/2 | Complete   | 2026-06-17 |
| 65. Cross-Page Bulk & Navigation Polish | 0/0 | Not started | - |
| 66. Optional Live Counts | 0/0 | Not started | - |
