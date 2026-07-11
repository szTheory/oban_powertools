defmodule ObanPowertools.Web.Components.Primitives do
  @moduledoc """
  Token-owned primitive function components for Powertools operator surfaces.

  These components are intentionally stateless. Parent LiveViews own data,
  authorization, events, and mutations; primitives own semantic markup,
  accessible names, closed visual variants, and safe caller attributes.
  """

  use Phoenix.Component
  import Phoenix.Component, except: [link: 1]

  @button_variants ~w[neutral primary warning danger ghost]a
  @tones ~w[neutral info success warning danger]a
  @sizes ~w[sm md]a
  @surface_variants ~w[plain elevated inset attention]a
  @icon_names ~w[alert check info dot]a

  @doc """
  Renders a semantic action button.

  The default `type` is `"button"`. When `disabled_reason` is present, the
  button remains perceivable through `aria-disabled`, exposes the reason, and
  suppresses caller action attributes.
  """
  attr :variant, :atom, default: :neutral, values: @button_variants
  attr :size, :atom, default: :md, values: @sizes
  attr :type, :string, default: "button"
  attr :disabled, :boolean, default: false
  attr :disabled_reason, :string, default: nil
  attr :rest, :global, default: %{}
  slot :inner_block, required: true

  def button(assigns) do
    variant = normalize_closed!(assigns.variant, @button_variants, "unsupported button variant")
    size = normalize_closed!(assigns.size, @sizes, "unsupported button size")
    disabled_reason = present_text(assigns.disabled_reason)
    described? = not is_nil(disabled_reason)

    rest =
      assigns.rest
      |> visual_safe_rest(suppress_actions?: described?)

    {describedby, rest} =
      if described? do
        reason_id = disabled_reason_id(rest, "obpt-button")
        merge_describedby(rest, reason_id)
      else
        {nil, rest}
      end

    assigns =
      assigns
      |> assign(:variant, variant)
      |> assign(:size, size)
      |> assign(:class, "obpt-button obpt-button--#{variant}")
      |> assign(:rest, rest)
      |> assign(:disabled_reason, disabled_reason)
      |> assign(:reason_id, if(described?, do: disabled_reason_id(rest, "obpt-button")))
      |> assign(:describedby, describedby)
      |> assign(:aria_disabled, if(described?, do: "true"))
      |> assign(:native_disabled, assigns.disabled and not described?)

    ~H"""
    <button
      type={@type}
      class={@class}
      data-obpt-variant={@variant}
      data-obpt-size={@size}
      disabled={@native_disabled}
      aria-disabled={@aria_disabled}
      aria-describedby={@describedby}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    <span :if={@disabled_reason} id={@reason_id} class="obpt-sr-only">
      {@disabled_reason}
    </span>
    """
  end

  @doc """
  Renders an icon-only button with a required accessible label.

  Icon slot content is decorative and hidden from assistive technology. Tooltip
  text can supplement the control, but never supplies the accessible name.
  """
  attr :label, :string, required: true
  attr :tooltip, :string, default: nil
  attr :variant, :atom, default: :neutral, values: @button_variants
  attr :size, :atom, default: :md, values: @sizes
  attr :disabled, :boolean, default: false
  attr :disabled_reason, :string, default: nil
  attr :rest, :global, default: %{}
  slot :inner_block, required: true

  def icon_button(assigns) do
    label = require_text!(assigns.label, "icon_button label")
    variant = normalize_closed!(assigns.variant, @button_variants, "unsupported button variant")
    size = normalize_closed!(assigns.size, @sizes, "unsupported button size")
    disabled_reason = present_text(assigns.disabled_reason)
    described? = not is_nil(disabled_reason)

    rest =
      assigns.rest
      |> visual_safe_rest(suppress_actions?: described?)

    {describedby, rest} =
      if described? do
        reason_id = disabled_reason_id(rest, "obpt-icon-button")
        merge_describedby(rest, reason_id)
      else
        {nil, rest}
      end

    assigns =
      assigns
      |> assign(:label, label)
      |> assign(:variant, variant)
      |> assign(:size, size)
      |> assign(:class, "obpt-icon-button obpt-icon-button--#{variant}")
      |> assign(:rest, rest)
      |> assign(:disabled_reason, disabled_reason)
      |> assign(:reason_id, if(described?, do: disabled_reason_id(rest, "obpt-icon-button")))
      |> assign(:describedby, describedby)
      |> assign(:aria_disabled, if(described?, do: "true"))
      |> assign(:native_disabled, assigns.disabled and not described?)

    ~H"""
    <button
      type="button"
      class={@class}
      data-obpt-variant={@variant}
      data-obpt-size={@size}
      data-obpt-tooltip-text={@tooltip}
      aria-label={@label}
      aria-disabled={@aria_disabled}
      aria-describedby={@describedby}
      disabled={@native_disabled}
      {@rest}
    >
      <span aria-hidden="true">{render_slot(@inner_block)}</span>
    </button>
    <span :if={@disabled_reason} id={@reason_id} class="obpt-sr-only">
      {@disabled_reason}
    </span>
    """
  end

  @doc """
  Renders a navigation link.

  Exactly one navigation target is required: `href`, `patch`, or `navigate`.
  Mutation events are suppressed so link styling cannot become an action affordance.
  """
  attr :href, :string, default: nil
  attr :patch, :string, default: nil
  attr :navigate, :string, default: nil
  attr :rest, :global, default: %{}
  slot :inner_block, required: true

  def link(assigns) do
    target_count = Enum.count([assigns.href, assigns.patch, assigns.navigate], &present?/1)

    if target_count != 1 do
      raise ArgumentError, "link requires href, patch, or navigate"
    end

    assigns =
      assigns
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <Phoenix.Component.link :if={present?(@href)} href={@href} class="obpt-link" {@rest}>
      {render_slot(@inner_block)}
    </Phoenix.Component.link>
    <Phoenix.Component.link :if={present?(@patch)} patch={@patch} class="obpt-link" {@rest}>
      {render_slot(@inner_block)}
    </Phoenix.Component.link>
    <Phoenix.Component.link :if={present?(@navigate)} navigate={@navigate} class="obpt-link" {@rest}>
      {render_slot(@inner_block)}
    </Phoenix.Component.link>
    """
  end

  @doc """
  Renders a non-interactive metadata badge.

  Badges expose a visible label and a closed semantic tone. Caller action attrs
  are suppressed because the primitive is descriptive, not interactive.
  """
  attr :label, :string, required: true
  attr :tone, :atom, default: :neutral, values: @tones
  attr :size, :atom, default: :md, values: @sizes
  attr :rest, :global, default: %{}

  def badge(assigns) do
    assigns =
      assigns
      |> assign(:label, require_text!(assigns.label, "badge label"))
      |> assign(:tone, normalize_closed!(assigns.tone, @tones, "unsupported tone"))
      |> assign(:size, normalize_closed!(assigns.size, @sizes, "unsupported badge size"))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <span class="obpt-badge" data-obpt-tone={@tone} data-obpt-size={@size} {@rest}>
      {@label}
    </span>
    """
  end

  @doc """
  Renders a non-interactive tag.

  Tags are static metadata with visible text and closed semantic tones. Use later
  form/filter components for selected, removable, or clickable chip behavior.
  """
  attr :label, :string, required: true
  attr :tone, :atom, default: :neutral, values: @tones
  attr :size, :atom, default: :md, values: @sizes
  attr :rest, :global, default: %{}

  def tag(assigns) do
    assigns =
      assigns
      |> assign(:label, require_text!(assigns.label, "tag label"))
      |> assign(:tone, normalize_closed!(assigns.tone, @tones, "unsupported tone"))
      |> assign(:size, normalize_closed!(assigns.size, @sizes, "unsupported tag size"))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <span class="obpt-tag" data-obpt-tone={@tone} data-obpt-size={@size} {@rest}>
      {@label}
    </span>
    """
  end

  @doc """
  Renders a non-interactive status pill from explicit presentation data.

  `spec` may provide `label`, `tone`, `icon`, and `sr_prefix`. The primitive does
  not own a domain state registry; callers pass the presentation they selected.
  """
  attr :spec, :any, default: nil
  attr :label, :string, default: nil
  attr :tone, :atom, default: :neutral, values: @tones
  attr :icon, :atom, default: nil
  attr :sr_prefix, :string, default: nil
  attr :size, :atom, default: :md, values: @sizes
  attr :rest, :global, default: %{}

  def status_pill(assigns) do
    assigns = apply_status_spec(assigns)
    icon = normalize_icon(assigns.icon)

    assigns =
      assigns
      |> assign(:label, require_text!(assigns.label, "status_pill label"))
      |> assign(:tone, normalize_closed!(assigns.tone, @tones, "unsupported tone"))
      |> assign(:size, normalize_closed!(assigns.size, @sizes, "unsupported status_pill size"))
      |> assign(:icon, icon)
      |> assign(:icon_text, icon_text(icon))
      |> assign(:sr_prefix, present_text(assigns.sr_prefix))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <span class="obpt-status-pill" data-obpt-tone={@tone} data-obpt-size={@size} {@rest}>
      <span :if={@sr_prefix} class="obpt-sr-only">{@sr_prefix}: </span>
      <span :if={@icon} class="obpt-status-pill-icon" data-obpt-icon={@icon} aria-hidden="true">
        {@icon_text}
      </span>
      <span class="obpt-status-pill-label">{@label}</span>
    </span>
    """
  end

  @doc """
  Renders a restrained structural surface.

  Surfaces are not interactive by default and expose only closed structural
  variants backed by Powertools classes and `data-obpt-variant`.
  """
  attr :variant, :atom, default: :plain, values: @surface_variants
  attr :rest, :global, default: %{}
  slot :inner_block, required: true

  def surface(assigns) do
    assigns =
      assigns
      |> assign(:variant, normalize_closed!(assigns.variant, @surface_variants, "unsupported surface variant"))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <section class="obpt-surface" data-obpt-variant={@variant} {@rest}>
      {render_slot(@inner_block)}
    </section>
    """
  end

  @doc """
  Renders a restrained content card.

  Cards are structural containers. They use the same closed variants as surfaces
  without creating an interactive affordance.
  """
  attr :variant, :atom, default: :plain, values: @surface_variants
  attr :rest, :global, default: %{}
  slot :inner_block, required: true

  def card(assigns) do
    assigns =
      assigns
      |> assign(:variant, normalize_closed!(assigns.variant, @surface_variants, "unsupported card variant"))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <article class="obpt-card" data-obpt-variant={@variant} {@rest}>
      {render_slot(@inner_block)}
    </article>
    """
  end

  @doc """
  Renders a token-owned separator.

  Use `decorative: true` when the separator is only visual; otherwise it remains
  a semantic `hr`.
  """
  attr :decorative, :boolean, default: false
  attr :rest, :global, default: %{}

  def divider(assigns) do
    assigns =
      assigns
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))
      |> assign(:aria_hidden, if(assigns.decorative, do: "true"))

    ~H"""
    <hr class="obpt-divider" aria-hidden={@aria_hidden} {@rest} />
    """
  end

  @doc """
  Renders a named loading spinner.

  The `label` names what is loading. Bare, unnamed spinner motion is rejected.
  """
  attr :label, :string, required: true
  attr :size, :atom, default: :md, values: @sizes
  attr :rest, :global, default: %{}

  def spinner(assigns) do
    assigns =
      assigns
      |> assign(:label, require_text!(assigns.label, "loading label"))
      |> assign(:size, normalize_closed!(assigns.size, @sizes, "unsupported spinner size"))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <span class="obpt-spinner" data-obpt-size={@size} role="status" {@rest}>
      <span class="obpt-spinner-mark" aria-hidden="true"></span>
      <span class="obpt-sr-only">{@label}</span>
    </span>
    """
  end

  @doc """
  Renders a named skeleton loading region.

  Skeletons represent progressive content loading and expose `aria-busy` plus a
  required loading label.
  """
  attr :label, :string, required: true
  attr :lines, :integer, default: 1
  attr :rest, :global, default: %{}

  def skeleton(assigns) do
    assigns =
      assigns
      |> assign(:label, require_text!(assigns.label, "loading label"))
      |> assign(:lines, max(assigns.lines || 1, 1))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <div class="obpt-skeleton" role="status" aria-busy="true" aria-label={@label} {@rest}>
      <span class="obpt-sr-only">{@label}</span>
      <span :for={_line <- 1..@lines} class="obpt-skeleton-line" data-obpt-skeleton-line></span>
    </div>
    """
  end

  @doc """
  Renders a text-only tooltip relationship.

  The trigger receives a stable id and `aria-describedby`; the tooltip content
  receives the matching description id and `role`.
  """
  attr :id, :string, required: true
  attr :text, :string, required: true
  attr :rest, :global, default: %{}
  slot :inner_block, required: true

  def tooltip(assigns) do
    id = require_text!(assigns.id, "tooltip id")

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:text, require_text!(assigns.text, "tooltip text"))
      |> assign(:trigger_id, "#{id}-trigger")
      |> assign(:content_id, "#{id}-content")
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <span class="obpt-tooltip" data-obpt-tooltip {@rest}>
      <span
        id={@trigger_id}
        class="obpt-tooltip-trigger"
        tabindex="0"
        aria-describedby={@content_id}
        data-obpt-tooltip-trigger
      >
        {render_slot(@inner_block)}
      </span>
      <span
        id={@content_id}
        class="obpt-tooltip-content"
        role="tooltip"
        data-obpt-tooltip-content
      >
        {@text}
      </span>
    </span>
    """
  end

  @doc """
  Renders a keyboard literal.

  Use this primitive only for keyboard shortcuts or literal machine input, not as
  status metadata.
  """
  attr :text, :string, required: true
  attr :rest, :global, default: %{}

  def kbd(assigns) do
    assigns =
      assigns
      |> assign(:text, require_text!(assigns.text, "kbd text"))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <kbd class="obpt-kbd" {@rest}>{@text}</kbd>
    """
  end

  @doc """
  Renders a compact metric.

  Metrics use visible label and value text, with optional trend copy so color is
  never the only channel for direction or severity.
  """
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :trend, :string, default: nil
  attr :tone, :atom, default: :neutral, values: @tones
  attr :rest, :global, default: %{}

  def stat(assigns) do
    assigns =
      assigns
      |> assign(:label, require_text!(assigns.label, "stat label"))
      |> assign(:value, require_text!(assigns.value, "stat value"))
      |> assign(:tone, normalize_closed!(assigns.tone, @tones, "unsupported tone"))
      |> assign(:trend, present_text(assigns.trend))
      |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

    ~H"""
    <dl class="obpt-stat" data-obpt-tone={@tone} {@rest}>
      <div>
        <dt class="obpt-stat-label">{@label}</dt>
        <dd class="obpt-stat-value">{@value}</dd>
        <dd :if={@trend} class="obpt-stat-trend">{@trend}</dd>
      </div>
    </dl>
    """
  end

  defp visual_safe_rest(rest, opts) do
    rest
    |> normalize_rest()
    |> Enum.reject(fn {key, _value} -> key in ["class", "style"] end)
    |> Enum.reject(fn {key, _value} -> Keyword.get(opts, :suppress_actions?, false) and action_attr?(key) end)
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == false end)
    |> Map.new()
  end

  defp normalize_rest(nil), do: %{}

  defp normalize_rest(rest) when is_map(rest) do
    Map.new(rest, fn {key, value} -> {to_string(key), value} end)
  end

  defp action_attr?(key) do
    String.starts_with?(key, "phx-") or String.starts_with?(key, "on")
  end

  defp normalize_closed!(value, allowed, message) when is_atom(value) do
    if value in allowed do
      value
    else
      raise ArgumentError, "#{message}: #{inspect(value)}"
    end
  end

  defp normalize_closed!(value, allowed, message) when is_binary(value) do
    atom_value = String.to_existing_atom(value)

    if atom_value in allowed do
      atom_value
    else
      raise ArgumentError, "#{message}: #{inspect(value)}"
    end
  rescue
    ArgumentError -> raise ArgumentError, "#{message}: #{inspect(value)}"
  end

  defp normalize_closed!(value, _allowed, message) do
    raise ArgumentError, "#{message}: #{inspect(value)}"
  end

  defp require_text!(value, name) do
    case present_text(value) do
      nil -> raise ArgumentError, "#{name} is required"
      text -> text
    end
  end

  defp present_text(nil), do: nil

  defp present_text(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      text -> text
    end
  end

  defp present_text(value), do: value |> to_string() |> present_text()

  defp present?(value), do: not is_nil(present_text(value))

  defp disabled_reason_id(rest, fallback) do
    "#{Map.get(rest, "id", fallback)}-disabled-reason"
  end

  defp merge_describedby(rest, description_id) do
    existing = rest |> Map.get("aria-describedby") |> present_text()

    describedby =
      [existing, description_id]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")

    {describedby, Map.delete(rest, "aria-describedby")}
  end

  defp apply_status_spec(%{spec: spec} = assigns) when is_map(spec) do
    assigns
    |> assign(:label, Map.get(spec, :label) || Map.get(spec, "label") || assigns.label)
    |> assign(:tone, Map.get(spec, :tone) || Map.get(spec, "tone") || assigns.tone)
    |> assign(:icon, Map.get(spec, :icon) || Map.get(spec, "icon") || assigns.icon)
    |> assign(:sr_prefix, Map.get(spec, :sr_prefix) || Map.get(spec, "sr_prefix") || assigns.sr_prefix)
  end

  defp apply_status_spec(assigns), do: assigns

  defp normalize_icon(nil), do: nil
  defp normalize_icon(icon) when icon in @icon_names, do: icon

  defp normalize_icon(icon) when is_binary(icon) do
    atom_value = String.to_existing_atom(icon)

    if atom_value in @icon_names do
      atom_value
    else
      raise ArgumentError, "unsupported icon: #{inspect(icon)}"
    end
  rescue
    ArgumentError -> raise ArgumentError, "unsupported icon: #{inspect(icon)}"
  end

  defp normalize_icon(icon), do: raise(ArgumentError, "unsupported icon: #{inspect(icon)}")

  defp icon_text(nil), do: nil
  defp icon_text(:alert), do: "!"
  defp icon_text(:check), do: "+"
  defp icon_text(:info), do: "i"
  defp icon_text(:dot), do: "•"
end
