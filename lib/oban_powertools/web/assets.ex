defmodule ObanPowertools.Web.Assets do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn

  @static_path Application.app_dir(:oban_powertools, ["priv", "static", "oban_powertools"])

  @external_resource css_path = Path.join(@static_path, "oban_powertools.css")
  @css File.read!(css_path)
  @css_hash Base.encode16(:crypto.hash(:md5, @css), case: :lower)

  @external_resource js_path = Path.join(@static_path, "oban_powertools.js")
  @js File.read!(js_path)
  @js_hash Base.encode16(:crypto.hash(:md5, @js), case: :lower)

  @impl Plug
  def init(asset), do: asset

  @impl Plug
  def call(conn, :asset) do
    case parse_asset(conn.path_params["filename"]) do
      {:ok, asset, hash} -> serve_if_current(conn, asset, hash)
      :error -> not_found(conn)
    end
  end

  def call(conn, asset) when asset in [:css, :js] do
    requested_hash =
      conn.path_params["hash"] || hash_from_filename(conn.path_params["filename"], asset)

    serve_if_current(conn, asset, requested_hash)
  end

  def call(conn, _asset), do: not_found(conn)

  defp serve_if_current(conn, asset, requested_hash) do
    if requested_hash == current_hash(asset) do
      serve_asset(conn, body(asset), content_type(asset))
    else
      not_found(conn)
    end
  end

  def current_hash(:css), do: @css_hash
  def current_hash(:js), do: @js_hash

  def path(:css), do: "/ops/jobs/_assets/oban_powertools-#{@css_hash}.css"
  def path(:js), do: "/ops/jobs/_assets/oban_powertools-#{@js_hash}.js"

  defp body(:css), do: @css
  defp body(:js), do: @js

  defp content_type(:css), do: "text/css; charset=utf-8"
  defp content_type(:js), do: "text/javascript; charset=utf-8"

  defp parse_asset("oban_powertools-" <> rest) do
    cond do
      String.ends_with?(rest, ".css") ->
        {:ok, :css, String.replace_suffix(rest, ".css", "")}

      String.ends_with?(rest, ".js") ->
        {:ok, :js, String.replace_suffix(rest, ".js", "")}

      true ->
        :error
    end
  end

  defp parse_asset(_filename), do: :error

  defp hash_from_filename(filename, expected_asset) do
    case parse_asset(filename) do
      {:ok, ^expected_asset, hash} -> hash
      _ -> nil
    end
  end

  defp serve_asset(conn, body, content_type) do
    conn
    |> put_resp_header("content-type", content_type)
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> put_private(:plug_skip_csrf_protection, true)
    |> send_resp(200, body)
    |> halt()
  end

  defp not_found(conn) do
    conn
    |> send_resp(404, "not found")
    |> halt()
  end
end
