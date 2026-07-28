defmodule ObanPowertools.Web.JobsParams do
  @moduledoc """
  Pure parsing and validation for the canonical Jobs URL and filter draft.

  Applied URL values are normalized into a safe `%ObanPowertools.Jobs{}` before
  any caller can query. Draft values are kept separately so invalid form text
  remains visible and never becomes applied query state.
  """

  alias ObanPowertools.Jobs

  @states ~w(available scheduled executing retryable cancelled discarded completed)
  @state_atoms %{
    "available" => :available,
    "scheduled" => :scheduled,
    "executing" => :executing,
    "retryable" => :retryable,
    "cancelled" => :cancelled,
    "discarded" => :discarded,
    "completed" => :completed
  }
  @url_keys ~w(state queue worker tags args meta page job)
  @draft_keys ~w(queue worker tags args meta)
  @page_size 20

  @tag_help "Separate tags with commas. Jobs must contain every listed tag."
  @json_help "Enter a JSON object. Filter values are stored in the URL; do not enter secrets."
  @invalid_json_error "Enter a valid JSON object."
  @invalid_url_notice "The invalid filter values were removed. Review the applied filters and try again."

  @doc """
  Parses untrusted Jobs URL params into safe applied query and navigation state.

  The returned quick-review ID is deliberately separate from the database
  filter. Unknown or invalid values are excluded from `canonical_params`.
  """
  def parse_url(params) when is_map(params) or is_list(params) do
    raw_params = string_keyed_map(params)
    unknown? = Enum.any?(Map.keys(raw_params), &(&1 not in @url_keys))

    {state, invalid_state?} = parse_state(raw_params["state"])
    {queue, invalid_queue?} = parse_optional_text(raw_params["queue"])
    {worker, invalid_worker?} = parse_optional_text(raw_params["worker"])
    {tags, invalid_tags?} = parse_tags(raw_params["tags"])
    {args, invalid_args?} = parse_json_object(raw_params["args"])
    {meta, invalid_meta?} = parse_json_object(raw_params["meta"])
    {page, invalid_page?} = parse_positive_integer(raw_params["page"], 1)
    {quick_review_id, invalid_review?} = parse_positive_integer(raw_params["job"], nil)

    query = %Jobs{
      state: state,
      queue: queue,
      worker: worker,
      tags: tags,
      args: args,
      meta: meta,
      page: page,
      page_size: @page_size
    }

    canonical_params = canonical_params(query, quick_review_id)

    invalid? =
      Enum.any?([
        unknown?,
        invalid_state?,
        invalid_queue?,
        invalid_worker?,
        invalid_tags?,
        invalid_args?,
        invalid_meta?,
        invalid_page?,
        invalid_review?
      ])

    %{
      query: query,
      canonical_params: canonical_params,
      quick_review_id: quick_review_id,
      replace?: raw_params != Map.new(canonical_params),
      notices: if(invalid?, do: [@invalid_url_notice], else: [])
    }
  end

  @doc """
  Validates retained optional-filter draft strings without creating patch intent.

  Invalid JSON objects make `applied` nil for the whole draft. Original strings,
  exact field errors, and locked help copy remain available to the caller.
  """
  def validate_draft(params) when is_map(params) or is_list(params) do
    raw_params = string_keyed_map(params)
    draft = Map.new(@draft_keys, &{&1, draft_value(raw_params, &1)})

    {queue, _invalid_queue?} = parse_optional_text(draft["queue"])
    {worker, _invalid_worker?} = parse_optional_text(draft["worker"])
    {tags, _invalid_tags?} = parse_tags(draft["tags"])
    {args, invalid_args?} = parse_json_object(draft["args"])
    {meta, invalid_meta?} = parse_json_object(draft["meta"])

    errors =
      %{}
      |> maybe_put_json_error(:args, invalid_args?)
      |> maybe_put_json_error(:meta, invalid_meta?)

    applied =
      if errors == %{} do
        %{queue: queue, worker: worker, tags: tags, args: args, meta: meta}
      end

    %{
      draft: draft,
      valid?: errors == %{},
      errors: errors,
      applied: applied,
      patch?: false,
      copy: %{tags_help: @tag_help, json_help: @json_help}
    }
  end

  @doc """
  Returns deterministic encoded state/filter identity without page or review.
  """
  def filter_identity(%Jobs{} = query) do
    query
    |> canonical_params(nil)
    |> filter_pairs()
    |> URI.encode_query()
  end

  def filter_identity(params) when is_map(params) or is_list(params) do
    params
    |> parse_url()
    |> Map.fetch!(:canonical_params)
    |> filter_pairs()
    |> URI.encode_query()
  end

  defp canonical_params(%Jobs{} = query, quick_review_id) do
    [
      {"state", Atom.to_string(query.state)},
      {"queue", query.queue},
      {"worker", query.worker},
      {"tags", encode_tags(query.tags)},
      {"args", encode_json(query.args)},
      {"meta", encode_json(query.meta)},
      {"page", if(query.page > 1, do: Integer.to_string(query.page))},
      {"job", if(quick_review_id, do: Integer.to_string(quick_review_id))}
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
  end

  defp filter_pairs(params) do
    Enum.take_while(params, fn {key, _value} -> key not in ["page", "job"] end)
  end

  defp parse_state(nil), do: {:available, false}

  defp parse_state(state) when state in @states,
    do: {Map.fetch!(@state_atoms, state), false}

  defp parse_state(_state), do: {:available, true}

  defp parse_optional_text(nil), do: {nil, false}

  defp parse_optional_text(value) when is_binary(value) do
    case String.trim(value) do
      "" -> {nil, false}
      normalized -> {normalized, false}
    end
  end

  defp parse_optional_text(_value), do: {nil, true}

  defp parse_tags(nil), do: {nil, false}

  defp parse_tags(value) when is_binary(value) do
    tags =
      value
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    {if(tags == [], do: nil, else: tags), false}
  end

  defp parse_tags(_value), do: {nil, true}

  defp parse_json_object(nil), do: {nil, false}

  defp parse_json_object(value) when is_binary(value) do
    case String.trim(value) do
      "" ->
        {nil, false}

      json ->
        case Jason.decode(json) do
          {:ok, decoded} when is_map(decoded) -> {decoded, false}
          _invalid -> {nil, true}
        end
    end
  end

  defp parse_json_object(_value), do: {nil, true}

  defp parse_positive_integer(nil, default), do: {default, false}

  defp parse_positive_integer(value, _default) when is_integer(value) and value > 0,
    do: {value, false}

  defp parse_positive_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> {parsed, false}
      _invalid -> {default, true}
    end
  end

  defp parse_positive_integer(_value, default), do: {default, true}

  defp encode_tags(nil), do: nil
  defp encode_tags([]), do: nil
  defp encode_tags(tags), do: Enum.join(tags, ",")

  defp encode_json(nil), do: nil
  defp encode_json(value), do: Jason.encode!(value)

  defp string_keyed_map(params) do
    Map.new(params, fn {key, value} -> {to_string(key), value} end)
  end

  defp draft_value(params, key) do
    case params[key] do
      value when is_binary(value) -> value
      _other -> ""
    end
  end

  defp maybe_put_json_error(errors, _field, false), do: errors
  defp maybe_put_json_error(errors, field, true), do: Map.put(errors, field, @invalid_json_error)
end
