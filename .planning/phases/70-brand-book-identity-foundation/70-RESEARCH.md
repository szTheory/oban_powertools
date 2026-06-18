# Phase 70: Brand Book & Identity Foundation — Research

**Researched:** 2026-06-18
**Domain:** Elixir/Phoenix library — dev-only LiveView route mounting, Markdown rendering without new runtime deps, Hex tarball exclusion
**Confidence:** HIGH

---

## Summary

The brand book Markdown itself belongs in `guides/brand-book.md` — the `guides/` glob is already in the package `files:` list, so the document ships with the Hex package as first-class documentation, linkable from HexDocs and the README. The dev-rendered route belongs in a new `lib/dev/` source tree gated by an `elixirc_paths(:dev)` clause: a `BrandBookLive` LiveView module at `lib/oban_powertools/web/dev/brand_book_live.ex` compiles only in dev, and the router macro mounts it only when a compile-time config flag (`Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)`) is true. No new runtime dependencies are needed: `earmark_parser` is already resolved in `mix.lock` as a transitive dev dependency of `ex_doc`, and `EarmarkParser.as_ast/2` plus a small inline AST-to-HTML walk (or a delegated call to `ExDoc.DocAST.to_html/1`) can render the Markdown at LiveView mount time — entirely within the dev compilation graph.

**Primary recommendation:** Ship the Markdown at `guides/brand-book.md` (included in the Hex tarball as documentation), gate the rendering LiveView to `lib/oban_powertools/web/dev/` (compiled only in dev via `elixirc_paths`), and add the route to `oban_powertools_routes/1` behind a `compile_env` guard. Zero new runtime dependencies are added.

---

## Web Layer & Route Mounting

### How routes work in this library [VERIFIED: codebase]

The library exposes routes exclusively via a `defmacro oban_powertools_routes(path)` defined in `lib/oban_powertools/web/router.ex`. The macro is `require`-d in the host's router, then called inside a host-owned `scope "/ops/jobs"` block that already has `pipe_through :browser`. The macro itself calls `Phoenix.LiveView.Router.live_session/3` with `on_mount: [ObanPowertools.Web.LiveAuth]` and registers 12 `live/3` routes within the `:oban_powertools_native` session.

The host-side mount looks like:

```elixir
# examples/phoenix_host/lib/phoenix_host_web/router.ex
scope "/ops/jobs" do
  pipe_through :browser
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

The macro guards all route registration behind `if Code.ensure_loaded?(Phoenix.LiveView.Router)`, which is the existing idiom for optional Phoenix dependency detection in this library.

### Adding the brand-book route [RECOMMENDED]

Add one `live/3` call inside the existing `:oban_powertools_native` `live_session` block in the router macro, conditional on a `compile_env` flag:

```elixir
# lib/oban_powertools/web/router.ex  (inside the quote block)

if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  live("/_brand_book", ObanPowertools.Web.Dev.BrandBookLive, :index)
end
```

This makes the route available at `/ops/jobs/_brand_book` within the host's existing `/ops/jobs` scope. The leading underscore signals "internal/dev-only" by convention (same convention as the upcoming `/_showcase` in Phase 72 — SHOW-01 specifies `/ops/jobs/_showcase`).

**Why `compile_env` rather than a bare `Mix.env()` check inside the macro:**
`Application.compile_env/3` is tracked by the Elixir compiler. If the host changes the flag, the compiler will recompile the router. `Mix.env()` evaluated at macro expansion time would be the library's own env during `mix deps.compile`, not the host's env at host compile time — a subtle but real distinction that would make the route compile into host prod when the library was compiled with dev. The `compile_env` pattern is what Phoenix itself uses (`Application.compile_env(@otp_app, [__MODULE__, :code_reloader], false)` in `Phoenix.Endpoint`). [VERIFIED: codebase — deps/phoenix/lib/phoenix/endpoint.ex:426]

**The flag is set by the host in dev config** (the phoenix_host example app already follows this pattern — `config :phoenix_host, dev_routes: true` is in its `dev.exs`). The library's own `config/dev.exs` should set:
```elixir
config :oban_powertools, dev_routes: true
```
And `config/test.exs` may also set it (so the test router compiles the route), while `config/prod.exs` leaves it absent (defaults to false via the `Mix.env() == :dev` fallback in the macro).

---

## Dev-Only Gating & Hex-Tarball Exclusion

### Source-level gating via `elixirc_paths` [VERIFIED: codebase]

The existing `mix.exs` already uses the `elixirc_paths/1` pattern:

```elixir
# mix.exs (current)
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_),     do: ["lib"]
```

Add a `:dev` clause:

```elixir
defp elixirc_paths(:dev),  do: ["lib", "lib/dev"]
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_),     do: ["lib"]
```

Place the brand-book LiveView at:
```
lib/dev/oban_powertools/web/dev/brand_book_live.ex
```

Wait — `lib/dev/` would be a source root added to `elixirc_paths`. Files inside it are compiled in dev but not in prod or test. **The module namespace is independent of the directory**: the module can be `ObanPowertools.Web.Dev.BrandBookLive` regardless of whether its source file sits under `lib/` or `lib/dev/`.

However, a cleaner approach that avoids creating a parallel source tree is to put the file directly in `lib/` but gate the module body with `if Code.ensure_loaded?/1` — but that doesn't prevent compilation of the module itself.

**The cleanest and most idiomatic approach** (matching what SHOW-01 mandates for the later showcase): place the file at:
```
lib/oban_powertools/web/dev/brand_book_live.ex
```
This file lives within the standard `lib/` source tree. Because `lib/` is always in `elixirc_paths`, this file **will** compile in all envs unless the module is guarded. Use a compile-time guard at the module level:

```elixir
# lib/oban_powertools/web/dev/brand_book_live.ex
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  defmodule ObanPowertools.Web.Dev.BrandBookLive do
    use Phoenix.LiveView
    # ...
  end
end
```

This is the exact pattern Phoenix and Oban Web use for optional modules (`if Code.ensure_loaded?(Phoenix.LiveView.Router) do ... end` in the library's own router). The module is defined only when `dev_routes` is true at compile time, so in a host's prod build the module does not exist.

### Hex tarball exclusion [VERIFIED: codebase]

The `mix.exs` package `files:` list is:
```elixir
files: ~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]
```

`lib/` is a glob that includes everything under `lib/` — so `lib/oban_powertools/web/dev/brand_book_live.ex` **will be present** in the published Hex tarball. This is acceptable and expected: the .ex source file ships (adopters can read it), but the module is not compiled by the host's prod build because `compile_env(:oban_powertools, :dev_routes)` will be false/absent in a prod host.

**The brand book Markdown at `guides/brand-book.md` also ships in the tarball** — this is explicitly desired. It renders on HexDocs (ex_doc includes `guides/*.md` via the `extras:` list) and is the static-Markdown half of BRAND-01.

### Tarball check for the route (SHOW-03 precursor) [ASSUMED]

The verification for "the route does not exist in host prod" is not a tarball content check (the source file being present is fine) — it is a **compilation check**: build the examples/hex_consumer with `MIX_ENV=prod mix compile` and assert that `ObanPowertools.Web.Dev.BrandBookLive` is not in the compiled module list, and that `Phoenix.Router.route_info/4` returns `:error` for `GET /ops/jobs/_brand_book`. This is the pattern SHOW-03 specifies as "tarball check" — a runtime proof that the route is absent, not a file-content check. Document this as the verification step.

---

## Markdown Rendering Approach (zero new runtime deps)

### Dependency inventory [VERIFIED: codebase — mix.lock]

| Package | In mix.lock? | Dev-only? | Can render Markdown? |
|---------|-------------|-----------|---------------------|
| `earmark_parser` 1.4.44 | YES | Transitively (via `ex_doc :only :dev`) | Produces AST only (`EarmarkParser.as_ast/2`) |
| `earmark` (full, with `Earmark.as_html!/1`) | NO | — | Would add `as_html!` convenience |
| `ex_doc` 0.40.3 | YES | `:only :dev, runtime: false` | Has `ExDoc.DocAST.to_html/1` (internal, but callable) |
| `mdex` | NO | — | Not present |

### Recommended option: EarmarkParser + inline AST walk [VERIFIED: codebase]

`EarmarkParser` is already compiled in dev (via `ex_doc`). Its public API is `EarmarkParser.as_ast/2`, which returns `{:ok, ast, messages}`. The AST is a list of tuples `{tag_string, attrs, children, meta}`.

`ExDoc.DocAST.to_html/1` (at `deps/ex_doc/lib/ex_doc/doc_ast.ex:34`) accepts this AST format and returns an HTML string. It is an internal module (no `@moduledoc`) but its function is simple and stable. Alternatively, write a 15-line `ast_to_html/1` function directly in `BrandBookLive` — the AST format is well-documented and stable.

**Recommended approach:**

```elixir
defmodule ObanPowertools.Web.Dev.BrandBookLive do
  use Phoenix.LiveView

  @brand_book_path Application.app_dir(:oban_powertools, "../../guides/brand-book.md")
  @external_resource @brand_book_path

  # Render at compile time so there is zero runtime I/O on mount.
  @brand_book_html (
    {:ok, ast, _} = EarmarkParser.as_ast(File.read!(@brand_book_path))
    ast_to_html(ast)  # private function below
  )

  def render(assigns) do
    ~H"""
    <div class="brand-book prose">
      <%= Phoenix.HTML.raw(@brand_book_html) %>
    </div>
    """
  end

  # ... minimal ast_to_html/1 implementation
end
```

Using `@external_resource` makes the Elixir compiler recompile the LiveView if `brand-book.md` changes (same mechanism HEEx templates use). Rendering at compile time via a module attribute is zero-overhead at request time and requires no runtime filesystem access.

**Why not a runtime dep like `earmark` or `mdex`:**
- `earmark` would be a new `:dev`-only dep — acceptable but unnecessary since `earmark_parser` is already present.
- `mdex` is a NIF (Rust-backed), which contradicts the library's "zero new runtime deps" posture and would add cross-compilation complexity.
- The content is trusted (no user input), so the XSS concern that normally motivates sanitization libraries is moot.

**Dev-only dep declaration if needed:**
If `earmark_parser` were NOT already in the lock file, the correct approach would be:
```elixir
{:earmark_parser, "~> 1.4", only: :dev, runtime: false}
```
But since it is already resolved as a transitive dependency of `ex_doc`, no `mix.exs` change is needed. The module is available in dev without any explicit dep declaration.

---

## In-Repo Location & Versioning

### File location [RECOMMENDED]

```
guides/brand-book.md          ← Markdown source of truth (ships in Hex tarball)
guides/brand-book.md          ← Also rendered by HexDocs under "Brand" extras group
```

This path fits the existing `guides/` pattern: the `mix.exs` `extras:` list already uses `Path.wildcard("guides/*.md")` and groups them by convention. Add a `"Brand"` group or add `brand-book.md` to an existing "Operations" group.

Alternative considered: `priv/brand_book.md` — rejected because `priv/` is not in the package `files:` list and the content should be human-readable in the Hex tarball.

Alternative considered: `docs/brand-book.md` at the repo root — rejected because `docs/` is not in the package `files:` list (would need an explicit entry) and is less idiomatic than `guides/` for this library.

### Versioning convention [RECOMMENDED]

Add a version header as the first section of the brand book:

```markdown
# Oban Powertools Brand Book

> **Version:** v2.0.0-draft · **Status:** Locked (2026-06-18) · **Owner:** Phase 70
>
> Every downstream phase (71–84) cites decision IDs (D-01..D-22) from this document.
> Changes require a new version header entry in the table below.

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v2.0.0-draft | 2026-06-18 | Initial authoring — 22 decisions locked |
```

This is a CHANGELOG-style header, not a full semver frontmatter system. The version tracks the brand book's own content version, distinct from the library's published Hex version. The phrase "Locked (date)" signals that downstream phases may cite these decisions as stable.

---

## README Linking (DOC-03)

### Linking strategy [RECOMMENDED]

DOC-03's "initial" delivery in Phase 70 is a single sentence in the README pointing to both the HexDocs-rendered guide and the dev route. The README already renders on Hex.pm (static Markdown) and GitHub.

Add to the README (after the "60-Second Install" section, in a "Design System" or "Brand" subsection):

```markdown
## Brand Identity

The Oban Powertools brand book is the single source of truth for all visual and verbal
decisions across the v2.0 design system.

- **Read it:** [`guides/brand-book.md`](guides/brand-book.md) — rendered on HexDocs and
  viewable on GitHub
- **Render it locally:** Start the `examples/phoenix_host` dev server and visit
  [`http://localhost:4000/ops/jobs/_brand_book`](http://localhost:4000/ops/jobs/_brand_book)
  (dev-only route, not present in production builds)
```

The static Markdown link (`guides/brand-book.md`) works on GitHub (relative path) and on HexDocs (ex_doc renders it as a guide page). The dev route link is annotated as dev-only so adopters are not confused when it is absent in their prod app.

Phase 83 (DOC-03 full delivery) will update this section with links to the full showcase and contributor guide once those exist.

---

## Prior Art

### Phoenix-generated apps (dev_routes pattern) [VERIFIED: codebase]

`phx.new`-generated apps (Phoenix 1.7+) use exactly the `Application.compile_env(app, :dev_routes, false)` pattern in their `router.ex` to gate `live_dashboard` and `live_reload` routes. The `examples/phoenix_host/config/dev.exs` already contains `config :phoenix_host, dev_routes: true`, proving this pattern is understood and expected in this codebase. [VERIFIED: codebase — examples/phoenix_host/config/dev.exs]

### Oban Web (oban_dashboard macro) [VERIFIED: codebase — deps/oban_web]

`Oban.Web.Router.oban_dashboard/2` is a macro similar to `oban_powertools_routes/1` — it mounts routes inside a host-owned scope. Oban Web does not have dev-only showcase routes; the entire dashboard is production-enabled. The pattern to borrow is the macro-based injection, not the dev-gating.

### Phoenix LiveDashboard [ASSUMED]

LiveDashboard is the canonical prior art for a library-owned dev-only diagnostic route. It mounts via `live_dashboard/2` in the host router, gated by a `if Mix.env() == :dev do ... end` block in the host's router (not inside the library macro). This differs slightly from the recommended approach: gating inside the library macro via `compile_env` is cleaner because it doesn't require the host to do anything special — the route simply doesn't exist in prod.

### PhoenixStorybook [OUT OF SCOPE per REQUIREMENTS.md]

Out of scope as a runtime dependency. Noted for awareness only: it uses a `storybook/` directory pattern with compile-time story discovery. The brand book route is simpler (one route, one LiveView, one Markdown file) and does not need a story catalog system.

---

## Recommended Task Breakdown

**Task 1 — elixirc_paths + compile_env infrastructure (delivery plumbing)**
- Add `elixirc_paths(:dev) -> ["lib", "lib/dev"]` clause to `mix.exs` (if using a separate `lib/dev/` tree) OR simply rely on `compile_env` guard in the module.
- Set `config :oban_powertools, dev_routes: true` in `config/dev.exs` and `config/test.exs`.
- Verify `config/prod.exs` does NOT set this key (defaults to false).
- Update `README.md` with the note that `dev_routes: true` should be set in host dev config.

**Task 2 — BrandBookLive module (route plumbing)**
- Create `lib/oban_powertools/web/dev/brand_book_live.ex` with the `compile_env` module guard.
- Implement `@external_resource` + compile-time `EarmarkParser.as_ast/2` + `ast_to_html/1` helper.
- Implement `mount/3` (no auth required — dev-only route, no mutations) and `render/1`.
- Add `live("/_brand_book", ObanPowertools.Web.Dev.BrandBookLive, :index)` inside the `oban_powertools_routes/1` macro behind the same `compile_env` guard.

**Task 3 — Author brand book Markdown (`guides/brand-book.md`) — the main deliverable**
The brand book must encode all 22 locked decisions (D-01..D-22). Suggested chapter order:
1. **Identity Statement** — D-01 (essence verbatim), D-02 (archetype), D-03 (five traits, "if one word: calm")
2. **What We Are Not** — D-04 (rejected anchors with "why not" rationale)
3. **Codified Brand Principles** — D-05 (seven checkable rules, principles 1–3 flagged as high-leverage), D-06 (coherence test, quoted verbatim)
4. **Color Story** — D-07 (accent = indigo blue, rationale), D-08 (neutral base = cool slate), D-09 (semantic roles: info/success/warning/danger), D-10 (two-tier token philosophy: where raw hex lives, what components reference), D-11 (light/dark/HC as three distinct token sets + documented pitfalls), D-12 (contrast targets + colorblind safety)
5. **Typography & Density** — D-13 (system font cascades, verbatim), D-14 (mono = signal, not default; scoped uses; truncate-middle rule; tabular-nums), D-15 (scale: rem ladder, body/dense-row sizes; four weights; 4px base; density posture; long-content mandates)
6. **Voice & Microcopy** — D-16 (register + canonical confirm template), D-17 (five voice traits + guardrails), D-18 ("explain, then act" as copy contract; friction ladder; dismiss-button rule), D-19 (state copy: empty/loading/error/permission-denied), D-20 (honesty/support-truth rule), D-21 (canonical glossary — Cancel ≠ Discard ≠ Delete etc.)
7. **Traceability Table** — D-22: a table mapping every downstream token category to the decision ID(s) that mandate it (satisfies BRAND-05)

**Task 4 — README linking (DOC-03 initial)**
- Add "Brand Identity" section to README as described in the README Linking section.
- Add `brand-book.md` to the `extras:` list in `mix.exs` docs config under a new `"Design System"` group.

**Task 5 — Verify no changes to the 9 pages (zero-diff check)**
- Run `git diff --name-only` and assert none of the 9 `*_live.ex` files under `lib/oban_powertools/web/` appear.

---

## Risks & Pitfalls

### Pitfall 1: `compile_env` evaluated in library env, not host env
**What goes wrong:** Using `Mix.env()` inside the `quote` block of the router macro evaluates the library's own `Mix.env()` at macro expansion time (during `mix deps.compile`), not the host's env at host compile time. The route would always be absent in a host even in dev.
**Why it happens:** Macro expansion happens at the library's compile time, not the host's.
**How to avoid:** Use `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)` as the fallback. This is evaluated at the host's compile time and tracked by the compiler.
**Warning signs:** The route is absent in dev host even after `config :oban_powertools, dev_routes: true`.

### Pitfall 2: `earmark_parser` only provides AST, not HTML
**What goes wrong:** Calling `EarmarkParser.as_html!(markdown)` fails with `UndefinedFunctionError` because that function is on the `Earmark` module (full package), not `EarmarkParser`.
**Why it happens:** `EarmarkParser` is a parser backend; HTML generation was extracted to the `Earmark` wrapper package.
**How to avoid:** Use `EarmarkParser.as_ast/2` and implement a small `ast_to_html/1` function, or delegate to `ExDoc.DocAST.to_html/1` (internal but stable).

### Pitfall 3: Brand book Markdown accidentally excluded from HexDocs
**What goes wrong:** `mix docs` does not render `guides/brand-book.md` because it is not in the `extras:` list.
**Why it happens:** `mix.exs` uses `Path.wildcard("guides/*.md")` for extras, but if `brand-book.md` is added before the `groups_for_extras` mapping is updated, it renders without a group (still visible but not grouped).
**How to avoid:** Add a `"Design System": ["guides/brand-book.md"]` entry to `groups_for_extras` in `mix.exs` at the same time as creating the file.

### Pitfall 4: Route leaking into host prod
**What goes wrong:** A host that does not set `config :oban_powertools, dev_routes: false` in prod sees the brand book route compiled in.
**Why it happens:** The `Application.compile_env/3` fallback is `Mix.env() == :dev`, which evaluates correctly. BUT if a host's `prod.exs` explicitly sets `dev_routes: true` (by copy-paste error), the route compiles in.
**How to avoid:** Document in the install guide that `dev_routes: true` belongs only in `dev.exs`. The tarball-check CI step in Phase 72/73 will catch this.

### Pitfall 5: `@external_resource` path breaks in host app compilation
**What goes wrong:** The brand book LiveView tries to read `guides/brand-book.md` relative to the library's app directory, but the path is wrong in the host's compiled environment.
**Why it happens:** `Application.app_dir/2` resolves to the OTP app's priv directory at runtime, not the source directory. At compile time in the library, `__DIR__` and relative paths work; in a compiled dep, the source tree is not present.
**How to avoid:** Use `@brand_book_path Path.join(__DIR__, "../../../guides/brand-book.md")` where `__DIR__` is the compile-time source directory of `brand_book_live.ex`. In deps, this resolves correctly during compilation because Elixir compiles from source. Alternatively, embed the content as a string literal using `@moduledoc false` and a dedicated Mix task that regenerates the literal — but the `Path.join(__DIR__, ...)` approach is simpler.

### Pitfall 6: XSS from `Phoenix.HTML.raw/1`
**What goes wrong:** If the brand book Markdown content ever contained user-supplied data, rendering it as raw HTML would be a security issue.
**Risk level:** LOW — the brand book is trusted, committed Markdown authored by the development team. No user input path exists.
**How to avoid:** Document in the module that `raw/1` is used intentionally for trusted, version-controlled content, not for user-supplied data.

---

## Validation Architecture

This section specifies how to validate Phase 70's deliverables. All checks should be runnable in CI without a database.

### 1. Brand book Markdown content checks (automated)

Run as a CI-compatible shell + grep assertion (no Phoenix server needed):

```bash
# All 22 decisions present by their IDs
for d in D-01 D-02 D-03 D-04 D-05 D-06 D-07 D-08 D-09 D-10 \
          D-11 D-12 D-13 D-14 D-15 D-16 D-17 D-18 D-19 D-20 \
          D-21 D-22; do
  grep -q "$d" guides/brand-book.md || echo "MISSING: $d"
done

# BRAND-05 traceability table is present
grep -q "Traceability" guides/brand-book.md || echo "MISSING: traceability table"

# "explain, then act" principle is codified
grep -qi "explain.*then.*act\|explain, then act" guides/brand-book.md || echo "MISSING: explain-then-act"

# Coherence test (D-06) is quoted
grep -q "D-06" guides/brand-book.md || echo "MISSING: D-06 coherence test"

# Canonical confirm template (D-16) is present
grep -q "Cancel 3 running jobs" guides/brand-book.md || echo "MISSING: canonical confirm template"
```

### 2. No changes to the 9 operator pages (automated)

```bash
# After all commits for Phase 70, verify none of the 9 pages changed
for page in engine_overview batches workflows cron limiters lifeline audit forensics jobs; do
  git diff main -- "lib/oban_powertools/web/${page}_live.ex" | grep -q . \
    && echo "FAIL: ${page}_live.ex was modified"
done
```

If running on a branch, compare against `main` or the pre-phase commit.

### 3. Dev route renders (manual — dev server required)

```bash
# Start phoenix_host in dev, then:
curl -s http://localhost:4000/ops/jobs/_brand_book | grep -q "Brand Book\|Oban Powertools Brand" \
  || echo "FAIL: brand book route did not render"
```

Alternatively, use the existing LiveView test harness in `test/support/live_case.ex` to write an ExUnit test:
```elixir
# test/oban_powertools/web/live/brand_book_live_test.exs (new file)
# Only runs in dev/test env where BrandBookLive is compiled
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  test "brand book route renders", %{conn: conn} do
    {:ok, _live, html} = live(conn, "/ops/jobs/_brand_book")
    assert html =~ "Brand Book"
    assert html =~ "D-01"
    assert html =~ "explain, then act"
  end
end
```

### 4. Route absent in prod (compile-time check — automated)

```bash
# Compile the library with prod env and verify the module is not defined
MIX_ENV=prod mix compile --force
MIX_ENV=prod mix run --no-start -e \
  'if Code.ensure_loaded?(ObanPowertools.Web.Dev.BrandBookLive), do: (IO.puts("FAIL: BrandBookLive compiled in prod"); System.halt(1))'
```

This is the "tarball check" precursor that Phase 72 (SHOW-03) will formalize. Run it in CI against the published Hex tarball or the library's own prod compile.

### 5. HexDocs includes brand-book.md (automated)

```bash
MIX_ENV=dev mix docs
# Check that the generated doc includes the brand book
ls doc/guides/ | grep brand-book || echo "FAIL: brand-book not in generated docs"
grep -r "Brand Book\|brand-book" doc/index.html || echo "FAIL: brand book not linked from doc index"
```

### 6. README links are present (automated)

```bash
grep -q "brand-book\|_brand_book" README.md || echo "FAIL: README does not link brand book"
grep -q "guides/brand-book.md" README.md    || echo "FAIL: README missing static Markdown link"
```

### Summary table

| Deliverable | Check type | Command / assertion |
|-------------|-----------|---------------------|
| All D-01..D-22 in brand-book.md | grep assertion | loop over `D-01` through `D-22` |
| BRAND-05 traceability table present | grep | `grep -q "Traceability" guides/brand-book.md` |
| "explain, then act" codified | grep | `grep -qi "explain.*then.*act"` |
| 9 pages unchanged | git diff | `git diff main -- lib/oban_powertools/web/*_live.ex` |
| Dev route renders | ExUnit LiveView test | `live(conn, "/ops/jobs/_brand_book")` |
| Route absent in prod | `MIX_ENV=prod mix run` | `Code.ensure_loaded?(BrandBookLive)` returns false |
| HexDocs includes guide | `mix docs` + ls | `ls doc/guides/ | grep brand-book` |
| README links brand book | grep | `grep -q "brand-book" README.md` |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ExDoc.DocAST.to_html/1` is stable enough to call from `BrandBookLive` as an internal function | Markdown Rendering | If ExDoc refactors, the compile-time render breaks; mitigation: write own 15-line `ast_to_html/1` instead |
| A2 | Phoenix LiveDashboard gates its route inside the host's router `if Mix.env() == :dev do ... end`, not inside the library macro | Prior Art | Low impact — the compile_env approach is independently confirmed by Phoenix core source |
| A3 | `@external_resource` + `Path.join(__DIR__, ...)` resolves correctly for a dep compiled from source in the host | Markdown Rendering | If wrong, the brand book file path fails to read at dep compile time; mitigation: embed content as a module attribute string literal during `mix deps.compile` |

---

## Sources

### Primary (HIGH confidence)
- `lib/oban_powertools/web/router.ex` — router macro structure, `live_session`, `live/3` registration, `Code.ensure_loaded?` pattern [VERIFIED: codebase]
- `mix.exs` — `elixirc_paths/1` pattern, package `files:` list, `ex_doc` as `:dev`-only dep [VERIFIED: codebase]
- `mix.lock` — `earmark_parser` 1.4.44 present as transitive dep of `ex_doc` [VERIFIED: codebase]
- `examples/phoenix_host/config/dev.exs` — `dev_routes: true` pattern [VERIFIED: codebase]
- `examples/phoenix_host/lib/phoenix_host_web/router.ex` — host-side route mounting [VERIFIED: codebase]
- `deps/phoenix/lib/phoenix/endpoint.ex:426` — `Application.compile_env` pattern in Phoenix core [VERIFIED: codebase]
- `deps/ex_doc/lib/ex_doc/doc_ast.ex` — `ExDoc.DocAST.to_html/1` function [VERIFIED: codebase]
- `deps/ex_doc/lib/ex_doc/markdown/earmark.ex` — `EarmarkParser.as_ast/2` usage pattern [VERIFIED: codebase]
- `deps/earmark_parser/lib/earmark_parser.ex` — `as_ast/2` public API, no `as_html` function [VERIFIED: codebase]
- `test/support/test_router.ex` — test router pattern [VERIFIED: codebase]
- `.planning/REQUIREMENTS.md` SHOW-01 — `compile_env + elixirc_paths` gating mandate [VERIFIED: codebase]

### Secondary (MEDIUM confidence)
- `.planning/phases/70-brand-book-identity-foundation/70-CONTEXT.md` — 22 locked decisions, delivery constraints [VERIFIED: codebase]
- `.planning/ROADMAP.md` — Phase 70 success criteria, downstream phase context [VERIFIED: codebase]
- `.planning/codebase/ARCHITECTURE.md`, `STRUCTURE.md` — architectural patterns [VERIFIED: codebase]
