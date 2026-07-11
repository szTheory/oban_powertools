defmodule ObanPowertools.Web.Components.Forms do
  @moduledoc """
  Stateless, field-first form components for Powertools operator surfaces.

  Parents retain ownership of form state, events, validation, and persistence.
  These components own native semantics, deterministic associations, and a
  closed token-backed visual contract.
  """

  use Phoenix.Component

  @input_types ~w[text search email number password tel url]
  @input_variants ~w[default filter]a

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: nil)
  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:type, :string, default: "text", values: @input_types)
  attr(:variant, :atom, default: :default, values: @input_variants)
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:rest, :global, default: %{})

  def input(assigns) do
    assigns = prepare_field(assigns, "obpt-input")

    ~H"""
    <div class="obpt-field" data-obpt-state={@state}>
      <.label for={@id} label={@label} required={@required} />
      <input
        id={@id}
        name={@name}
        value={@value}
        type={@type}
        class={"obpt-input obpt-input--#{@variant}"}
        disabled={@disabled}
        readonly={@readonly}
        required={@required}
        aria-invalid={@aria_invalid}
        aria-describedby={@describedby}
        {@rest}
      />
      <.hint :if={@hint} id={@hint_id} text={@hint} />
      <.error :for={{message, error_id} <- @error_items} id={error_id} error={message} />
    </div>
    """
  end

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: nil)
  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:readonly, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:rest, :global, default: %{})

  def textarea(assigns) do
    assigns = prepare_field(assigns, "obpt-textarea")

    ~H"""
    <div class="obpt-field" data-obpt-state={@state}>
      <.label for={@id} label={@label} required={@required} />
      <textarea id={@id} name={@name} class="obpt-textarea" disabled={@disabled} readonly={@readonly}
        required={@required} aria-invalid={@aria_invalid} aria-describedby={@describedby} {@rest}>{@value}</textarea>
      <.hint :if={@hint} id={@hint_id} text={@hint} />
      <.error :for={{message, error_id} <- @error_items} id={error_id} error={message} />
    </div>
    """
  end

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, required: true)
  attr(:options, :list, required: true)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: nil)
  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:variant, :atom, default: :default, values: @input_variants)
  attr(:disabled, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:rest, :global, default: %{})

  def select(assigns) do
    assigns = prepare_field(assigns, "obpt-select")

    ~H"""
    <div class="obpt-field" data-obpt-state={@state}>
      <.label for={@id} label={@label} required={@required} />
      <select id={@id} name={@name} class={"obpt-select obpt-select--#{@variant}"} disabled={@disabled}
        required={@required} aria-invalid={@aria_invalid} aria-describedby={@describedby} {@rest}>
        <option :for={{option_label, option_value} <- @options} value={option_value}
          selected={to_string(option_value) == to_string(@value)}>{option_label}</option>
      </select>
      <.hint :if={@hint} id={@hint_id} text={@hint} />
      <.error :for={{message, error_id} <- @error_items} id={error_id} error={message} />
    </div>
    """
  end

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: nil)
  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:checked, :boolean, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:rest, :global, default: %{})

  def checkbox(assigns) do
    assigns = prepare_choice(assigns, "obpt-checkbox")

    ~H"""
    <div class="obpt-field obpt-field--choice" data-obpt-state={@state}>
      <input :if={@named_boolean} type="hidden" name={@name} value="false" disabled={@disabled} />
      <label class="obpt-choice" for={@id}>
        <input type="checkbox" id={@id} name={@name} value="true" class="obpt-checkbox"
          checked={@checked} disabled={@disabled} required={@required} aria-invalid={@aria_invalid}
          aria-describedby={@describedby} {@rest} />
        <span>{@label}</span>
      </label>
      <.hint :if={@hint} id={@hint_id} text={@hint} />
      <.error :for={{message, error_id} <- @error_items} id={error_id} error={message} />
    </div>
    """
  end

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, required: true)
  attr(:options, :list, required: true)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: nil)
  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:required, :boolean, default: false)
  attr(:rest, :global, default: %{})

  def radio_group(assigns) do
    assigns = prepare_field(assigns, "obpt-radio-group")

    ~H"""
    <fieldset id={@id} class="obpt-field obpt-radio-group" disabled={@disabled}
      aria-invalid={@aria_invalid} aria-describedby={@describedby}>
      <legend class="obpt-label">{@label}<span :if={@required} class="obpt-field-status"> Required</span></legend>
      <div class="obpt-choice-list">
        <label :for={{{option_label, option_value}, index} <- Enum.with_index(@options)} class="obpt-choice"
          for={"#{@id}-#{index}"}>
          <input id={"#{@id}-#{index}"} type="radio" class="obpt-radio" name={@name} value={option_value}
            checked={to_string(option_value) == to_string(@value)} required={@required}
            aria-describedby={@describedby} {@rest} />
          <span>{option_label}</span>
        </label>
      </div>
      <.hint :if={@hint} id={@hint_id} text={@hint} />
      <.error :for={{message, error_id} <- @error_items} id={error_id} error={message} />
    </fieldset>
    """
  end

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:errors, :list, default: nil)
  attr(:id, :string, default: nil)
  attr(:name, :string, default: nil)
  attr(:value, :any, default: nil)
  attr(:checked, :boolean, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:rest, :global, default: %{})

  def switch(assigns) do
    assigns = prepare_choice(assigns, "obpt-switch")

    ~H"""
    <div class="obpt-field obpt-field--choice" data-obpt-state={@state}>
      <input :if={@named_boolean} type="hidden" name={@name} value="false" disabled={@disabled} />
      <label class="obpt-switch" for={@id}>
        <input id={@id} name={@name} value="true" type="checkbox" class="obpt-switch__input"
          checked={@checked} disabled={@disabled} aria-invalid={@aria_invalid}
          aria-describedby={@describedby} {@rest} />
        <span class="obpt-switch__track" aria-hidden="true"><span class="obpt-switch__thumb"></span></span>
        <span class="obpt-switch__label">{@label}</span>
        <span class="obpt-switch__state" aria-hidden="true">
          <span class="obpt-switch__state-label obpt-switch__state-label--off">Off</span>
          <span class="obpt-switch__state-label obpt-switch__state-label--on">On</span>
        </span>
      </label>
      <.hint :if={@hint} id={@hint_id} text={@hint} />
      <.error :for={{message, error_id} <- @error_items} id={error_id} error={message} />
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:hint, :string, default: nil)
  attr(:rest, :global, default: %{})
  slot(:inner_block, required: true)

  def field_group(assigns) do
    label = require_text!(assigns.label, "field_group legend")
    hint = present_text(assigns.hint)
    rest = visual_safe_rest(assigns.rest)

    describedby =
      merge_tokens(Map.get(rest, "aria-describedby"), if(hint, do: "#{assigns.id}-hint"))

    rest = drop_keys(rest, ["aria-describedby"])
    assigns = assign(assigns, label: label, hint: hint, describedby: describedby, rest: rest)

    ~H"""
    <fieldset id={@id} class="obpt-field-group" aria-describedby={@describedby} {@rest}>
      <legend class="obpt-label">{@label}</legend>
      <.hint :if={@hint} id={"#{@id}-hint"} text={@hint} />
      <div class="obpt-field-group__items">{render_slot(@inner_block)}</div>
    </fieldset>
    """
  end

  attr(:for, :string, required: true)
  attr(:label, :string, required: true)
  attr(:required, :boolean, default: false)

  def label(assigns) do
    assigns = assign(assigns, :label, require_text!(assigns.label, "label"))

    ~H"""
    <label for={@for} class="obpt-label">{@label}<span :if={@required} class="obpt-field-status"> Required</span></label>
    """
  end

  attr(:id, :string, required: true)
  attr(:text, :string, required: true)
  def hint(assigns), do: ~H|<p id={@id} class="obpt-hint">{@text}</p>|

  attr(:id, :string, required: true)
  attr(:error, :string, required: true)
  def error(assigns), do: ~H|<p id={@id} class="obpt-error"><span>Error:</span> {@error}</p>|

  defp prepare_choice(assigns, class) do
    explicit_name? = present?(Map.get(assigns, :name))
    assigns = prepare_field(assigns, class)
    checked = if is_boolean(assigns.checked), do: assigns.checked, else: truthy?(assigns.value)
    event_selection? = Map.has_key?(assigns.rest, "phx-click")
    name = if event_selection? and not explicit_name?, do: nil, else: assigns.name

    assign(assigns,
      name: name,
      checked: checked,
      named_boolean: present?(name) and not event_selection?
    )
  end

  defp prepare_field(assigns, _class) do
    label = require_text!(assigns.label, "visible field label")
    rest = visual_safe_rest(assigns.rest)
    {rest_id, rest} = pop_key(rest, "id")
    {caller_description, rest} = pop_key(rest, "aria-describedby")
    id = present_text(rest_id) || present_text(assigns.id) || assigns.field.id
    name = present_text(assigns.name) || assigns.field.name
    value = if is_nil(assigns.value), do: assigns.field.value, else: assigns.value
    hint = present_text(assigns.hint)
    errors = visible_errors(assigns.field, assigns.errors)
    hint_id = if hint, do: "#{id}-hint"
    error_ids = error_ids(id, errors)

    assigns
    |> assign(:label, label)
    |> assign(:id, id)
    |> assign(:name, name)
    |> assign(:value, value)
    |> assign(:hint, hint)
    |> assign(:hint_id, hint_id)
    |> assign(:error_id, List.first(error_ids))
    |> assign(:error_items, Enum.zip(errors, error_ids))
    |> assign(:visible_errors, errors)
    |> assign(:aria_invalid, if(errors == [], do: nil, else: "true"))
    |> assign(:describedby, merge_tokens([caller_description, hint_id | error_ids]))
    |> assign(:state, field_state(assigns, errors))
    |> assign(:rest, rest)
  end

  defp error_ids(_id, []), do: []
  defp error_ids(id, [_error]), do: ["#{id}-error"]

  defp error_ids(id, errors) do
    errors
    |> Enum.with_index(1)
    |> Enum.map(fn {_error, index} -> "#{id}-error-#{index}" end)
  end

  defp visible_errors(field, nil) do
    if used_input?(field), do: Enum.map(field.errors, &translate_error/1), else: []
  end

  defp visible_errors(_field, errors) when is_list(errors),
    do: Enum.map(errors, &translate_error/1)

  defp translate_error({message, options}),
    do:
      Enum.reduce(options, message, fn {key, value}, text ->
        String.replace(text, "%{#{key}}", to_string(value))
      end)

  defp translate_error(message), do: to_string(message)

  defp visual_safe_rest(rest) do
    popup_attributes =
      ["expanded", "controls", "active" <> "descendant"]
      |> Enum.map(&("aria-" <> &1))

    rest
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
    |> drop_keys(["class", "style", "role" | popup_attributes])
  end

  defp drop_keys(map, keys), do: Map.drop(map, keys)
  defp pop_key(map, key), do: Map.pop(map, key)

  defp merge_tokens(values) do
    values
    |> Enum.flat_map(fn value ->
      if present?(value), do: String.split(to_string(value)), else: []
    end)
    |> Enum.uniq()
    |> case do
      [] -> nil
      tokens -> Enum.join(tokens, " ")
    end
  end

  defp merge_tokens(first, second), do: merge_tokens([first, second])

  defp field_state(assigns, errors) do
    cond do
      errors != [] -> "invalid"
      Map.get(assigns, :disabled, false) -> "disabled"
      Map.get(assigns, :readonly, false) -> "readonly"
      true -> "default"
    end
  end

  defp require_text!(value, name) do
    present_text(value) || raise ArgumentError, "#{name} must be non-empty"
  end

  defp present_text(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      text -> text
    end
  end

  defp present_text(value) when is_atom(value), do: value |> to_string() |> present_text()
  defp present_text(_value), do: nil
  defp present?(value), do: not is_nil(value) and value != ""
  defp truthy?(value), do: value in [true, "true", "1", "on", 1]
end
