# Dev-only module guard: defined only when dev_routes is enabled at the host's
# compile time (dev/test). In a prod build the flag is absent and the fallback
# `Mix.env() == :dev` is false, so these modules are NEVER compiled into a
# host's production app. Mirrors the router macro guard and the test guard. See
# .planning/phases/70-brand-book-identity-foundation/70-RESEARCH.md (§Dev-Only Gating).
if Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev) do
  defmodule ObanPowertools.Web.Dev.BrandBookMarkdown do
    @moduledoc false
    # Compile-time helper: walks an EarmarkParser AST into an HTML string.
    #
    # EarmarkParser only produces an AST (it has no `as_html`); we render it
    # ourselves rather than delegating to the internal `ExDoc.DocAST.to_html/1`,
    # so the render does not depend on an undocumented ExDoc internal
    # (70-RESEARCH.md Assumption A1). Defined as its own module so it is fully
    # compiled before BrandBookLive evaluates its compile-time @brand_book_html.
    #
    # AST nodes are either binaries (text — already HTML-escaped by
    # EarmarkParser) or `{tag, attrs, children, meta}` 4-tuples.

    @void_tags ~w(area base br col embed hr img input link meta param source track wbr)

    @doc false
    def render(ast) do
      ast
      |> List.wrap()
      |> Enum.map_join("", &node_to_html/1)
    end

    defp node_to_html(text) when is_binary(text), do: text

    defp node_to_html({tag, attrs, children, _meta}) do
      open = "<#{tag}#{attrs_to_html(attrs)}>"

      if tag in @void_tags do
        open
      else
        inner =
          children
          |> List.wrap()
          |> Enum.map_join("", &node_to_html/1)

        open <> inner <> "</#{tag}>"
      end
    end

    defp node_to_html(other) when is_list(other) do
      Enum.map_join(other, "", &node_to_html/1)
    end

    defp attrs_to_html([]), do: ""

    defp attrs_to_html(attrs) do
      Enum.map_join(attrs, "", fn {name, value} ->
        " #{name}=\"#{escape_attr(value)}\""
      end)
    end

    defp escape_attr(value) do
      value
      |> to_string()
      |> String.replace("&", "&amp;")
      |> String.replace("\"", "&quot;")
      |> String.replace("<", "&lt;")
      |> String.replace(">", "&gt;")
    end
  end

  defmodule ObanPowertools.Web.Dev.BrandBookLive do
    @moduledoc """
    Dev-only LiveView that renders the versioned brand book
    (`guides/brand-book.md`) as HTML.

    The Markdown is parsed and rendered to an HTML string **at compile time** via
    `EarmarkParser.as_ast/2` (already resolved as a transitive dev dependency of
    `ex_doc` — no new runtime dependency is added) and stored in a module
    attribute, so there is zero filesystem I/O on mount. `@external_resource`
    makes the compiler recompile this module when the brand book changes.

    The rendered content is **trusted, version-controlled Markdown** authored by
    the development team — there is no user-input path. `Phoenix.HTML.raw/1` is
    therefore used intentionally; this is NOT a sink for user-supplied data.
    """

    use Phoenix.LiveView

    alias ObanPowertools.Web.Dev.BrandBookMarkdown

    # Resolve the brand book relative to this source file's directory
    # (lib/oban_powertools/web/dev/ -> repo root guides/). This resolves at
    # compile time because Elixir compiles deps from source.
    @brand_book_path Path.join(__DIR__, "../../../../guides/brand-book.md")
    @external_resource @brand_book_path

    # Parse + render at COMPILE TIME into a module attribute.
    @brand_book_html (
                       {:ok, ast, _messages} =
                         @brand_book_path |> File.read!() |> EarmarkParser.as_ast()

                       BrandBookMarkdown.render(ast)
                     )

    @doc false
    # Exposes the compile-time-rendered HTML (also marks the module attribute as
    # used). Returns a pre-rendered, trusted HTML string.
    def brand_book_html, do: @brand_book_html

    @impl Phoenix.LiveView
    def mount(_params, _session, socket) do
      # Dev-only, read-only route: no auth state or mutations required.
      {:ok,
       socket
       |> assign(:page_title, "Brand Book")
       |> assign(:brand_book_html, brand_book_html())}
    end

    @impl Phoenix.LiveView
    def render(assigns) do
      ~H"""
      <div class="oban-powertools-brand-book prose">
        {Phoenix.HTML.raw(@brand_book_html)}
      </div>
      """
    end
  end
end
