defmodule ObanPowertools.Web.Components.AppShell do
  @moduledoc """
  Server-rendered Powertools app shell.

  The shell owns only navigation, route context, actor display, and theme-choice
  controls. Page LiveViews keep authorization, data, events, and mutations.
  """

  use Phoenix.Component

  alias ObanPowertools.Auth

  @root_path "/ops/jobs"
  @bridge_path @root_path <> "/oban"
  @nav_state_values ~w[closed open]
  @nav_items [
    %{key: "overview", label: "Overview", path: @root_path, detail_label: nil},
    %{key: "jobs", label: "Jobs", path: @root_path <> "/jobs", detail_label: "Job detail"},
    %{
      key: "batches",
      label: "Batches",
      path: @root_path <> "/batches",
      detail_label: "Batch detail"
    },
    %{
      key: "workflows",
      label: "Workflows",
      path: @root_path <> "/workflows",
      detail_label: "Workflow detail"
    },
    %{key: "cron", label: "Cron", path: @root_path <> "/cron", detail_label: nil},
    %{key: "limiters", label: "Limiters", path: @root_path <> "/limiters", detail_label: nil},
    %{key: "lifeline", label: "Lifeline", path: @root_path <> "/lifeline", detail_label: nil},
    %{key: "audit", label: "Audit", path: @root_path <> "/audit", detail_label: nil},
    %{key: "forensics", label: "Forensics", path: @root_path <> "/forensics", detail_label: nil}
  ]
  @theme_choices [
    %{label: "System", value: "system"},
    %{label: "Light", value: "light"},
    %{label: "Dark", value: "dark"},
    %{label: "High contrast", value: "high-contrast"}
  ]

  attr(:current_path, :string, default: @root_path)
  attr(:current_uri, :string, default: nil)
  attr(:current_actor, :any, default: nil)
  attr(:actor_label, :string, default: nil)
  attr(:context_label, :string, default: nil)
  attr(:nav_state, :any, default: :closed)
  attr(:nav_items, :list, default: nil)
  attr(:id_scope, :string, default: nil)
  attr(:rest, :global, default: %{})
  slot(:inner_block, required: true)

  def app_shell(assigns) do
    current_path = current_path(assigns.current_path, assigns.current_uri)
    nav_state = normalize_nav_state!(assigns.nav_state)
    nav_items = assigns.nav_items |> nav_items_for_render(current_path)
    breadcrumbs = breadcrumb_items(current_path)
    actor_label = present_text(assigns.actor_label) || actor_label(assigns.current_actor)
    primary_nav_id = scoped_id("obpt-primary-nav", assigns.id_scope)
    main_id = scoped_id("obpt-main", assigns.id_scope)

    assigns =
      assigns
      |> assign(:current_path, current_path)
      |> assign(:nav_state, nav_state)
      |> assign(:nav_expanded, nav_state == "open")
      |> assign(:nav_items, nav_items)
      |> assign(:breadcrumbs, breadcrumbs)
      |> assign(:primary_nav_id, primary_nav_id)
      |> assign(:main_id, main_id)
      |> assign(:theme_choices, theme_choices())
      |> assign(:actor_label, actor_label)
      |> assign(:context_label, present_text(assigns.context_label))
      |> assign(:rest, visual_safe_rest(assigns.rest))

    ~H"""
    <div
      class="obpt-app-shell"
      data-obpt-app-shell
      data-obpt-nav-state={@nav_state}
      {@rest}
    >
      <a class="obpt-app-shell__skip" href={"##{@main_id}"}>Skip to main content</a>

      <header class="obpt-app-shell__header">
        <div class="obpt-app-shell__brand">Oban Powertools</div>

        <button
          type="button"
          class="obpt-app-shell__nav-toggle"
          data-obpt-nav-toggle
          aria-expanded={to_string(@nav_expanded)}
          aria-controls={@primary_nav_id}
        >
          Navigation
        </button>

        <nav
          id={@primary_nav_id}
          class="obpt-primary-nav"
          aria-label="Powertools surfaces"
          data-obpt-primary-nav
        >
          <ul class="obpt-primary-nav__list">
            <li :for={item <- @nav_items} class="obpt-primary-nav__item">
              <a
                class={nav_link_class(item.current?)}
                href={item.path}
                data-obpt-nav-item={item.key}
                data-obpt-current={if item.current?, do: "true"}
                aria-current={if item.current?, do: "page"}
              >
                {item.label}
              </a>
            </li>
          </ul>
        </nav>

        <div class="obpt-actor-context">
          <span>{@actor_label}</span>
          <span :if={@context_label}>{@context_label}</span>
        </div>

        <div class="obpt-theme-choices" role="group" aria-label="Theme choices">
          <button
            :for={choice <- @theme_choices}
            type="button"
            class="obpt-theme-choice"
            data-obpt-theme-choice={choice.value}
            aria-pressed={to_string(choice.value == "system")}
          >
            {choice.label}
          </button>
        </div>

        <nav class="obpt-breadcrumb" aria-label="Breadcrumb">
          <ol class="obpt-breadcrumb__list">
            <li :for={crumb <- @breadcrumbs} class="obpt-breadcrumb__item">
              <a
                :if={crumb.path}
                href={crumb.path}
                data-obpt-breadcrumb={crumb.kind}
                aria-current={if crumb.current?, do: "page"}
              >{crumb.label}</a>
              <span
                :if={is_nil(crumb.path)}
                data-obpt-breadcrumb={crumb.kind}
                aria-current={if crumb.current?, do: "page"}
              >{crumb.label}</span>
            </li>
          </ol>
        </nav>
      </header>

      <main id={@main_id} class="obpt-shell-main" tabindex="-1">
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end

  def nav_items, do: @nav_items

  def nav_items(_assigns), do: nav_items()

  def theme_choices, do: @theme_choices

  def theme_choices(_assigns), do: theme_choices()

  def breadcrumb_items(current_path_or_uri) do
    current_path = current_path(current_path_or_uri, nil)
    active_item = active_nav_item(current_path)
    detail? = detail_path?(current_path, active_item)

    cond do
      active_item.key == "overview" ->
        [
          crumb("root", "Overview", @root_path, false),
          crumb("current", "Overview", nil, true)
        ]

      detail? and present?(active_item.detail_label) ->
        [
          crumb("root", "Overview", @root_path, false),
          crumb(active_item.key, active_item.label, active_item.path, false),
          crumb("current", active_item.detail_label, nil, true)
        ]

      true ->
        [
          crumb("root", "Overview", @root_path, false),
          crumb("current", active_item.label, nil, true)
        ]
    end
  end

  def actor_label(actor) do
    case audit_principal(actor) do
      {:ok, principal} ->
        display =
          principal
          |> Map.get(:label)
          |> present_text()
          |> Kernel.||(principal |> Map.get(:id) |> present_text())

        if display, do: "Actor: #{display}", else: "Actor context unavailable"

      {:error, _reason} ->
        "Actor context unavailable"
    end
  end

  defp nav_items_for_render(nil, current_path), do: nav_items_for_render(@nav_items, current_path)

  defp nav_items_for_render(items, current_path) when is_list(items) do
    normalized = Enum.map(items, &normalize_nav_item!/1)
    active_key = active_nav_item(current_path, normalized).key

    Enum.map(normalized, fn item ->
      Map.put(item, :current?, item.key == active_key)
    end)
  end

  defp nav_items_for_render(_items, _current_path) do
    raise ArgumentError, "nav_items must be a list"
  end

  defp normalize_nav_item!(item) when is_map(item) do
    label = require_safe_label!(Map.get(item, :label) || Map.get(item, "label"), "nav label")
    path = require_safe_path!(Map.get(item, :path) || Map.get(item, "path"))
    key = Map.get(item, :key) || Map.get(item, "key") || key_from_path(path)

    %{
      key: require_safe_key!(key),
      label: label,
      path: path,
      detail_label: present_text(Map.get(item, :detail_label) || Map.get(item, "detail_label"))
    }
  end

  defp normalize_nav_item!(_item) do
    raise ArgumentError, "nav item must be a map with label and path"
  end

  defp active_nav_item(current_path, items \\ @nav_items) do
    current_path = current_path(current_path, nil)

    items
    |> Enum.sort_by(fn item -> String.length(item.path) end, :desc)
    |> Enum.find(fn item ->
      item.path == current_path or String.starts_with?(current_path, item.path <> "/")
    end) || hd(items)
  end

  defp detail_path?(current_path, item), do: String.starts_with?(current_path, item.path <> "/")

  defp current_path(nil, current_uri), do: current_path(@root_path, current_uri)

  defp current_path(path, current_uri) do
    path = present_text(path) || path_from_uri(current_uri) || @root_path

    cond do
      path == "/" -> @root_path
      String.ends_with?(path, "/") and path != @root_path -> String.trim_trailing(path, "/")
      true -> path
    end
  end

  defp normalize_nav_state!(value) when is_atom(value),
    do: normalize_nav_state!(Atom.to_string(value))

  defp normalize_nav_state!(value) when is_binary(value) do
    state = String.trim(value)

    if state in @nav_state_values do
      state
    else
      raise ArgumentError, "unsupported nav_state: #{inspect(value)}"
    end
  end

  defp normalize_nav_state!(value) do
    raise ArgumentError, "unsupported nav_state: #{inspect(value)}"
  end

  defp scoped_id(base, nil), do: base

  defp scoped_id(base, scope) do
    case present_text(scope) do
      nil ->
        base

      scope ->
        if Regex.match?(~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/, scope) do
          "#{base}-#{scope}"
        else
          raise ArgumentError, "id_scope must be a stable slug"
        end
    end
  end

  defp path_from_uri(uri) do
    uri
    |> present_text()
    |> case do
      nil -> nil
      uri -> URI.parse(uri).path
    end
    |> present_text()
  end

  defp audit_principal(nil), do: {:error, :missing_actor}

  defp audit_principal(actor) do
    Auth.audit_principal(actor)
  rescue
    ArgumentError -> {:error, :invalid_actor}
  end

  defp crumb(kind, label, path, current?) do
    %{kind: kind, label: label, path: path, current?: current?}
  end

  defp nav_link_class(true), do: "obpt-primary-nav__link obpt-primary-nav__link--current"
  defp nav_link_class(false), do: "obpt-primary-nav__link"

  defp visual_safe_rest(rest) do
    rest
    |> normalize_rest()
    |> Enum.reject(fn {key, _value} -> key in ["class", "style"] end)
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == false end)
    |> Map.new()
  end

  defp normalize_rest(nil), do: %{}

  defp normalize_rest(rest) when is_map(rest) do
    Map.new(rest, fn {key, value} -> {to_string(key), value} end)
  end

  defp require_safe_label!(value, name) do
    value = require_text!(value, name)

    if String.contains?(value, ["<", ">"]) do
      raise ArgumentError, "#{name} cannot contain markup"
    end

    value
  end

  defp require_safe_path!(value) do
    path = require_text!(value, "nav path")

    cond do
      path == @bridge_path ->
        raise ArgumentError, "bridge path is not a primary nav surface"

      path != @root_path and not String.starts_with?(path, @root_path <> "/") ->
        raise ArgumentError, "nav path must stay under #{@root_path}"

      String.contains?(path, ["<", ">", " "]) ->
        raise ArgumentError, "nav path cannot contain unsafe characters"

      true ->
        path
    end
  end

  defp require_safe_key!(value) do
    key = value |> to_string() |> require_text!("nav key")

    if Regex.match?(~r/^[a-z0-9]+(?:-[a-z0-9]+)*$/, key) do
      key
    else
      raise ArgumentError, "nav key must be a stable slug"
    end
  end

  defp key_from_path(@root_path), do: "overview"

  defp key_from_path(path) do
    path
    |> String.replace_prefix(@root_path <> "/", "")
    |> String.split("/", parts: 2)
    |> hd()
  end

  defp require_text!(value, name) do
    present_text(value) || raise ArgumentError, "#{name} is required"
  end

  defp present_text(nil), do: nil

  defp present_text(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      text -> text
    end
  end

  defp present_text(value), do: value |> to_string() |> present_text()
  defp present?(value), do: not is_nil(present_text(value))
end
