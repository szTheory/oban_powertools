---
phase: 64
reviewed: 2026-06-17T18:21:56Z
depth: deep
files_reviewed: 3
files_reviewed_list:
  - lib/oban_powertools/jobs.ex
  - lib/oban_powertools/operator.ex
  - lib/oban_powertools/web/jobs_live.ex
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 64: Code Review Report

**Reviewed:** 2026-06-17T18:21:56Z
**Depth:** deep
**Files Reviewed:** 3
**Status:** issues_found

## Summary

The review focused on the introduction of `args` and `meta` JSON filtering across the Jobs domain, Operator API, and UI. While the core Ecto query generation using `@>` fragments is correctly implemented and safe from SQL injection, a critical type-casting gap exists at the UI boundary. The UI blindly trusts any valid JSON input, leading to a Denial of Service (DoS) vulnerability where valid JSON primitives (integers, booleans, arrays) bypass validation and crash the LiveView process when Ecto attempts to cast them as maps. Additional warnings were identified regarding programmatic API correctness and UI whitespace handling.

## Critical Issues

### CR-01: LiveView Crash (DoS) via Unvalidated JSON Primitive Types

**File:** `lib/oban_powertools/web/jobs_live.ex:955-969`
**Issue:** `Jason.decode/1` successfully parses valid JSON primitives (e.g., `123`, `true`, `["array"]`). Since `validate_json_input/1` and `decode_json_param/1` do not verify that the decoded result is a map, these primitive types bypass the UI validation and are assigned to `filter.args` or `filter.meta`. When passed to `Jobs.list/3`, Ecto's `type(^args, :map)` attempts to cast the primitive to a `:map` and raises `Ecto.Query.CastError`. This crashes the server process. If an attacker crafts a URL with `?args=123` or an operator accidentally types `123`, it triggers a 500 Internal Server Error and a persistent LiveView crash loop.
**Fix:** Enforce the `is_map/1` guard on the decoded JSON to guarantee type safety at the module boundary.

```elixir
    defp decode_json_param(nil), do: nil
    defp decode_json_param(""), do: nil
    defp decode_json_param(str) do
      case Jason.decode(String.trim(str)) do
        {:ok, decoded} when is_map(decoded) -> decoded
        _ -> nil
      end
    end

    defp validate_json_input(""), do: {:ok, nil}
    defp validate_json_input(str) do
      str = String.trim(str)
      if str == "" do
        {:ok, nil}
      else
        case Jason.decode(str) do
          {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
          _ -> {:error, :invalid}
        end
      end
    end
```

## Warnings

### WR-01: Programmatic API silently drops string-keyed map filters

**File:** `lib/oban_powertools/operator.ex:14-23`
**Issue:** `Operator.list/3` uses `struct(Jobs, map)` to convert a user-provided map into a `Jobs` filter struct. In Elixir, `struct/2` silently ignores all string keys. If a host application passes raw Phoenix controller parameters (e.g., `%{"state" => "completed"}`) directly to `Operator.list/3`, the struct conversion drops the filters, and the query silently falls back to the default state (`:available`, page 1). This is a correctness risk for the programmatic API.
**Fix:** Explicitly convert string keys to atoms or document the strict requirement for atom keys.

```elixir
  def list(repo, filters \\ %{}, opts \\ []) do
    filters =
      case filters do
        %Jobs{} = struct -> struct
        kw when is_list(kw) -> struct(Jobs, kw)
        map when is_map(map) ->
          atom_map =
            Map.new(map, fn
              {k, v} when is_binary(k) ->
                try do
                  {String.to_existing_atom(k), v}
                rescue
                  ArgumentError -> {k, v}
                end
              {k, v} -> {k, v}
            end)
          struct(Jobs, atom_map)
      end

    Jobs.list(repo, filters, opts)
  end
```

### WR-02: Whitespace-only JSON inputs cause validation errors instead of clearing

**File:** `lib/oban_powertools/web/jobs_live.ex:964-969`
**Issue:** If an operator clears the `args` or `meta` search input but leaves trailing whitespace (e.g., `"   "`), `Jason.decode/1` fails to parse it. This causes `validate_json_input/1` to return an error, locking the UI with an "Invalid JSON" error message instead of naturally clearing the filter as an empty string would.
**Fix:** Apply `String.trim/1` before evaluating emptiness, as incorporated in the fix snippet for CR-01.

---

_Reviewed: 2026-06-17T18:21:56Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
