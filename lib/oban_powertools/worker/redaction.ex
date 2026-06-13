defmodule ObanPowertools.Worker.Redaction do
  @moduledoc false

  # No-op clause: no redact config — delegate directly via the explicit Oban.Job.new path
  def apply(worker_mod, args, opts, []) do
    worker_mod.__powertools_new_delegate__(args, opts)
  end

  # Work clause: normalize keys, drop redacted fields, inject __redacted_fields__ meta
  def apply(worker_mod, args, opts, redact_keys) do
    redact_strings = redact_keys |> Enum.map(&Atom.to_string/1) |> Enum.sort()

    # Normalize string keys that correspond to declared redact atoms before dropping (D-16)
    normalized = normalize_to_atom_keys(args, redact_keys)

    # Drop the redacted fields by atom key (D-02: key-absent, never nil)
    clean_args = Map.drop(normalized, redact_keys)

    # Inject __redacted_fields__ into opts[:meta] without clobbering existing meta (D-04, D-17)
    opts_with_meta = inject_meta(opts, redact_strings)

    worker_mod.__powertools_new_delegate__(clean_args, opts_with_meta)
  end

  # Normalize only the declared redact atom-keys from string-keyed args; leave other keys untouched
  defp normalize_to_atom_keys(args, atom_keys) do
    str_to_atom = Map.new(atom_keys, fn k -> {Atom.to_string(k), k} end)

    Map.new(args, fn {k, v} ->
      case k do
        k when is_atom(k) ->
          {k, v}

        k when is_binary(k) ->
          case Map.get(str_to_atom, k) do
            # Unknown string key — leave as-is
            nil -> {k, v}
            # Known redactable key — convert to atom for the drop
            atom -> {atom, v}
          end
      end
    end)
  end

  defp inject_meta(opts, redact_strings) do
    existing_meta = Keyword.get(opts, :meta, %{})
    merged = deep_merge(existing_meta, %{"__redacted_fields__" => redact_strings})
    Keyword.put(opts, :meta, merged)
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, a, b -> deep_merge(a, b) end)
  end

  defp deep_merge(_left, right), do: right
end
