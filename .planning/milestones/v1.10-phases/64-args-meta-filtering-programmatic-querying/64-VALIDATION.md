# Phase 64: Args/Meta Filtering & Programmatic Querying - Validation

## Goal
Operators and API consumers can precisely query jobs by argument and metadata values.

## Must-Haves
- [ ] `Operator.list/2` supports queries with `args` and `meta` map filters.
- [ ] The `jobs_live.ex` LiveView accepts JSON strings for args and meta filtering.
- [ ] Valid JSON strings update the URL, allowing filter bookmarking.
- [ ] Invalid JSON strings halt filter application and render an inline error without discarding input.

## Steps to Validate
1. Run the test suite: `mix test test/oban_powertools/jobs_test.exs test/oban_powertools/operator_test.exs test/oban_powertools/web/jobs_live_test.exs`
2. Ensure tests pass correctly.
3. Start the application (`mix phx.server`).
4. Navigate to the Jobs list in the Powertools dashboard.
5. In the "Args (JSON)" input, type `{"missing_key": true}`. The job list should filter and potentially show empty.
6. Verify the URL is updated with `&args=%7B%22missing_key%22%3Atrue%7D` (URL-encoded JSON).
7. Type `{"broken` and blur the input. An error message should appear, and the URL should remain unchanged.
8. Validate the same functionality for the "Meta (JSON)" input.
