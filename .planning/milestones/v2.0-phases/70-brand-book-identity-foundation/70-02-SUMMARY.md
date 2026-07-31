---
phase: 70-brand-book-identity-foundation
plan: 02
subsystem: design-system
tags: [brand, dev-route, liveview, markdown, hexdocs, compile-env]
status: complete
requires:
  - "70-01: guides/brand-book.md (the brand book rendered by this route)"
provides:
  - "ObanPowertools.Web.Dev.BrandBookLive — dev-only LiveView rendering guides/brand-book.md at compile time"
  - "/ops/jobs/_brand_book route gated by Application.compile_env(:oban_powertools, :dev_routes)"
  - ":oban_powertools, :dev_routes config flag (dev + test; absent in prod)"
  - "README Brand Identity section (DOC-03 initial)"
affects:
  - "Phase 72 SHOW-01 reuses the same compile_env(:dev_routes) gating idiom for /ops/jobs/_showcase"
  - "Phase 83 DOC-03 full delivery extends the README Brand Identity section"
tech-stack:
  added: []
  patterns:
    - "Dev-only LiveView gated by a module-level Application.compile_env(:dev_routes, Mix.env()==:dev) guard"
    - "Compile-time Markdown render via EarmarkParser.as_ast/2 + a self-contained AST->HTML walk (zero runtime I/O on mount)"
    - "@external_resource on the source Markdown so the view recompiles when the brand book changes"
    - "compile_env-gated route inside the existing oban_powertools_routes/1 macro"
key-files:
  created:
    - lib/oban_powertools/web/dev/brand_book_live.ex
    - test/oban_powertools/web/live/brand_book_live_test.exs
  modified:
    - config/dev.exs
    - config/test.exs
    - lib/oban_powertools/web/router.ex
    - mix.exs
    - README.md
decisions:
  - "Rendered the AST with a self-contained BrandBookMarkdown.render/1 (not the internal ExDoc.DocAST.to_html/1) to avoid depending on an undocumented ExDoc internal (70-RESEARCH.md Assumption A1)"
  - "Split the AST->HTML walk into its own module so it is fully compiled before BrandBookLive evaluates its compile-time @brand_book_html attribute"
  - "Widened ex_doc to only: [:dev, :test] (still runtime: false) so earmark_parser is loadable in the test env where dev_routes: true — no new runtime dependency added"
metrics:
  duration: ~6m
  completed: 2026-06-18
  tasks: 4
  files: 7
---

# Phase 70 Plan 02: Brand Book Delivery Plumbing Summary

Built the dev-only delivery surface for the brand book: a `BrandBookLive` LiveView that renders `guides/brand-book.md` to HTML at compile time (zero new runtime deps, zero runtime I/O), mounted at `/ops/jobs/_brand_book` behind a `compile_env(:dev_routes)` guard so it is provably absent under `MIX_ENV=prod`, plus the dev/test config flag, a guarded render test, and the README "Brand Identity" section (DOC-03 initial).

## What Was Built

- **`lib/oban_powertools/web/dev/brand_book_live.ex`** — two modules inside one `if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)` guard:
  - `ObanPowertools.Web.Dev.BrandBookMarkdown` — a compile-time helper that walks an `EarmarkParser` AST (`{tag, attrs, children, meta}` tuples + text binaries) into an HTML string with a minimal void-tag-aware emitter and attribute escaping. Kept as its own module so it is fully compiled before `BrandBookLive` evaluates its compile-time attribute.
  - `ObanPowertools.Web.Dev.BrandBookLive` — `use Phoenix.LiveView`. Resolves the brand book via `Path.join(__DIR__, "../../../../guides/brand-book.md")`, sets `@external_resource`, parses + renders to HTML at compile time into `@brand_book_html` via `EarmarkParser.as_ast/2`, assigns it in `mount/3`, and renders it with `Phoenix.HTML.raw/1` (documented as intentional for trusted, version-controlled content — no user-input path).
- **`config/dev.exs` + `config/test.exs`** — `config :oban_powertools, dev_routes: true`. `config/prod.exs` left untouched, so the macro fallback (`Mix.env() == :dev`) keeps the route off in prod.
- **`lib/oban_powertools/web/router.ex`** — added `live("/_brand_book", ObanPowertools.Web.Dev.BrandBookLive, :index)` inside the existing `:oban_powertools_native` `live_session`, gated by `Application.compile_env` (Pitfall 1 — not a bare `Mix.env()` in the quote). The 12 native routes and the bridge are unchanged.
- **`test/oban_powertools/web/live/brand_book_live_test.exs`** — render test (uses `ObanPowertools.LiveCase` + the test router), gated by the same `compile_env(:dev_routes)` check so it compiles only where the route exists. Asserts `live(conn, "/ops/jobs/_brand_book")` returns HTML containing "Brand Book", "D-01", and "explain, then act".
- **`mix.exs`** — `ex_doc` widened from `only: :dev` to `only: [:dev, :test]` (still `runtime: false`). This makes its transitive `earmark_parser` loadable in the test env where `dev_routes: true` is set, with no new runtime dependency and no change to the prod load list.
- **`README.md`** — new "Brand Identity" section linking the static guide (`guides/brand-book.md`) and the dev route, the latter annotated as dev-only / not present in production builds.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Set dev_routes config flag (dev + test) | 2716438 | config/dev.exs, config/test.exs |
| 2 (RED) | Failing render test | d504ab9 | test/oban_powertools/web/live/brand_book_live_test.exs |
| 2 (GREEN) | BrandBookLive + compile-time Markdown render | ab230a8 | lib/oban_powertools/web/dev/brand_book_live.ex, mix.exs |
| 3 | Mount dev-only route in router macro | 1e40a5c | lib/oban_powertools/web/router.ex |
| 4 | README Brand Identity section (DOC-03 initial) | 3274273 | README.md |

## Verification Results

- **Render test:** `mix test test/oban_powertools/web/live/brand_book_live_test.exs` → 1 test, 0 failures (RED→GREEN sequence confirmed: RED failed with `Phoenix.Router.NoRouteError` before the route, GREEN passed after).
- **Full suite:** `mix test --exclude host_contract` → 588 tests, 0 failures (7 excluded). No regressions.
- **Prod exclusion (70-VALIDATION.md §4):** `MIX_ENV=prod mix compile` then `Code.ensure_loaded?(ObanPowertools.Web.Dev.BrandBookLive)` → returns false ("OK: absent in prod"); the `BrandBookLive` beam count in the entire `_build/prod` tree is 0.
- **Zero new runtime deps:** `mix.exs` deps/0 adds no dependency; the only change widens the env scope of the existing `ex_doc` dev tool dep (still `runtime: false`).
- **No forbidden API:** `grep` confirms `EarmarkParser.as_ast` is used and `as_html!` / `EarmarkParser.as_html` are absent.
- **README links (70-VALIDATION.md §6):** `grep -q 'guides/brand-book.md' README.md` and `grep -q '_brand_book' README.md` both succeed; dev-only annotation present.
- **9 operator pages untouched:** `git diff --name-only HEAD -- lib/oban_powertools/web/{engine_overview,jobs,batches,workflows,cron,limiters,lifeline,audit,forensics}_live.ex` → 0 files. The 12 native routes are unchanged.
- **`mix compile --warnings-as-errors`** (dev) → clean.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `earmark_parser` unavailable in the test env**
- **Found during:** Task 2 (GREEN). The plan set `dev_routes: true` in `config/test.exs` so `BrandBookLive` compiles in test, but `earmark_parser` is a transitive dep of `ex_doc`, which was declared `only: :dev`. Compiling the view in the test env raised `UndefinedFunctionError: EarmarkParser.as_ast/1 ... module EarmarkParser is not available`.
- **Fix:** Widened `ex_doc` to `only: [:dev, :test]` in `mix.exs` (kept `runtime: false`). This is not a new runtime dependency and does not change the prod load list — it only makes the existing dev tool (and its transitive `earmark_parser`) available where `dev_routes: true` requires the view to compile.
- **Files modified:** mix.exs
- **Commit:** ab230a8

**2. [Rule 3 - Blocking] Compile-time attribute could not call a function defined in the same module**
- **Found during:** Task 2 (GREEN). The first implementation evaluated `@brand_book_html` by calling an `ast_node_to_html/1` defined in the same `BrandBookLive` module; at attribute-evaluation time that function is not yet compiled (`UndefinedFunctionError`).
- **Fix:** Extracted the AST→HTML walk into a separate `BrandBookMarkdown` module (compiled before `BrandBookLive`), and exposed the compiled HTML via a `brand_book_html/0` function so the module attribute is also marked as used (avoids the `warnings-as-errors` "set but never used" failure).
- **Files modified:** lib/oban_powertools/web/dev/brand_book_live.ex
- **Commit:** ab230a8

## Out-of-Scope Observations (not fixed)

- `MIX_ENV=prod mix compile` initially failed inside the optional `oban_web` dependency (`lib/oban/web/assets.ex:34` could not read `phoenix.js` / `phoenix_html.js` from the prod build) because `phoenix_html` / `phoenix_live_view` were not yet built in the prod env. This is a pre-existing environmental gap in the optional-dep prod build, unrelated to this plan. I primed the prod build by force-compiling those web deps so the authoritative `Code.ensure_loaded?` prod-exclusion check could run; no source change was made for it. Logged here rather than fixed (SCOPE BOUNDARY).

## Known Stubs

None. `BrandBookLive` renders the full committed brand book; there are no placeholder data paths.

## Threat Surface Scan

No new security-relevant surface beyond what the plan threat model anticipated:
- **T-70-03 (dev route leaking into prod) — mitigated:** module + route gated by `Application.compile_env(:dev_routes, Mix.env() == :dev)`; prod-exclusion verified (`Code.ensure_loaded?` false, beam absent from `_build/prod`).
- **T-70-04 (XSS via `Phoenix.HTML.raw/1`) — accepted:** content is trusted, version-controlled Markdown with no user-input path; documented in the module. `EarmarkParser` HTML-escapes text nodes and the AST→HTML emitter escapes attribute values.
- **T-70-SC (package installs) — accepted:** no package installs; deps/0 adds no dependency (the `ex_doc` env-scope widen keeps `runtime: false`).

## Self-Check: PASSED

- FOUND: lib/oban_powertools/web/dev/brand_book_live.ex
- FOUND: test/oban_powertools/web/live/brand_book_live_test.exs
- FOUND: config/dev.exs (modified), config/test.exs (modified)
- FOUND: lib/oban_powertools/web/router.ex (modified), mix.exs (modified), README.md (modified)
- FOUND commit 2716438 (Task 1)
- FOUND commit d504ab9 (Task 2 RED)
- FOUND commit ab230a8 (Task 2 GREEN)
- FOUND commit 1e40a5c (Task 3)
- FOUND commit 3274273 (Task 4)
