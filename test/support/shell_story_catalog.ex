defmodule ObanPowertools.ShellStoryCatalog do
  @moduledoc """
  Deterministic dev/test AppShell stories for the Powertools showcase.

  This registry is deliberately separate from stress fixtures, primitive
  stories, and form stories. It describes shell evidence, never behavior owned
  by an operator LiveView.
  """

  @nav_items [
    {"Overview", "/ops/jobs"},
    {"Jobs", "/ops/jobs/jobs"},
    {"Batches", "/ops/jobs/batches"},
    {"Workflows", "/ops/jobs/workflows"},
    {"Cron", "/ops/jobs/cron"},
    {"Limiters", "/ops/jobs/limiters"},
    {"Lifeline", "/ops/jobs/lifeline"},
    {"Audit", "/ops/jobs/audit"},
    {"Forensics", "/ops/jobs/forensics"}
  ]

  @shell_copy [
    "Oban Powertools",
    "Navigation",
    "Skip to main content",
    "Actor:",
    "Actor context unavailable",
    "System",
    "Light",
    "Dark",
    "High contrast",
    "Job detail",
    "Batch detail",
    "Workflow detail"
  ]

  @dom_hooks ~w[
    data-obpt-app-shell
    data-obpt-nav-toggle
    data-obpt-primary-nav
    data-obpt-nav-state
    data-obpt-nav-item
    data-obpt-breadcrumb
  ]

  @operator_actor %{
    id: "ops-1",
    audit_principal: %{id: "ops-1", type: :user, label: "ops@example.test"}
  }

  @story_specs [
    %{
      id: "shell-nine-surface-nav",
      kind: :shell,
      component: :app_shell,
      components: [:app_shell],
      name: "Nine-surface navigation",
      description: "The closed native primary nav model across all Powertools surfaces.",
      variant: :wide,
      state: :default,
      current_path: "/ops/jobs",
      actor: @operator_actor,
      context_label: "Native route context: Overview",
      nav_state: :closed,
      nav_items: @nav_items,
      shell_copy: @shell_copy,
      dom_hooks: @dom_hooks,
      test_targets: nil
    },
    %{
      id: "shell-mobile-collapsed",
      kind: :shell,
      component: :app_shell,
      components: [:app_shell],
      name: "Mobile collapsed navigation",
      description: "A 320px disclosure-ready shell with closed primary navigation.",
      variant: :mobile,
      state: :collapsed,
      current_path: "/ops/jobs/jobs",
      actor: nil,
      context_label: "Mobile viewport: collapsed",
      nav_state: :closed,
      nav_items: @nav_items,
      shell_copy: @shell_copy,
      dom_hooks: @dom_hooks,
      test_targets: nil
    },
    %{
      id: "shell-mobile-expanded",
      kind: :shell,
      component: :app_shell,
      components: [:app_shell],
      name: "Mobile expanded navigation",
      description: "A 320px disclosure-ready shell with open primary navigation.",
      variant: :mobile,
      state: :expanded,
      current_path: "/ops/jobs/jobs",
      actor: @operator_actor,
      context_label: "Mobile viewport: expanded",
      nav_state: :open,
      nav_items: @nav_items,
      shell_copy: @shell_copy,
      dom_hooks: @dom_hooks,
      test_targets: nil
    },
    %{
      id: "shell-active-breadcrumb",
      kind: :shell,
      component: :app_shell,
      components: [:app_shell],
      name: "Active route and breadcrumb",
      description: "A job detail route with current nav and breadcrumb fallback copy.",
      variant: :detail_route,
      state: :detail,
      current_path: "/ops/jobs/jobs/01JZ8M5PF4Q2V6N7X8Y9Z0ABCD",
      actor: @operator_actor,
      context_label: "Detail route context: Job detail",
      nav_state: :closed,
      nav_items: @nav_items,
      shell_copy: @shell_copy,
      dom_hooks: @dom_hooks,
      test_targets: nil
    },
    %{
      id: "shell-theme-actor-context",
      kind: :shell,
      component: :app_shell,
      components: [:app_shell],
      name: "Theme and actor context",
      description: "Theme choices beside explicit test actor and route context copy.",
      variant: :context,
      state: :actor_context,
      current_path: "/ops/jobs/audit",
      actor: @operator_actor,
      context_label: "Operator context: Showcase fixture",
      nav_state: :closed,
      nav_items: @nav_items,
      shell_copy: @shell_copy,
      dom_hooks: @dom_hooks,
      test_targets: nil
    },
    %{
      id: "shell-long-context-wrapping",
      kind: :shell,
      component: :app_shell,
      components: [:app_shell],
      name: "Long context wrapping",
      description: "Hostile ordinary text and long operator context wrap safely at 320px.",
      variant: :mobile,
      state: :long_context,
      current_path: "/ops/jobs/forensics",
      actor: nil,
      context_label:
        "<script>alert('shell')</script> ObanPowertools.Context.ReconcileForensicsNavigationWithAnIntentionallyLongIdentifier",
      nav_state: :closed,
      nav_items: @nav_items,
      shell_copy: @shell_copy,
      dom_hooks: @dom_hooks,
      test_targets: nil
    }
  ]

  @stories Enum.map(@story_specs, fn story ->
             id = story.id

             %{
               story
               | test_targets: %{
                   story: "obpt-shell-story-#{id}",
                   snapshot: "showcase/#{id}",
                   a11y: ~s([data-obpt-shell-story="#{id}"])
                 }
             }
           end)

  @stories_by_id Map.new(@stories, &{&1.id, &1})

  def stories, do: @stories

  def story!(id) when is_binary(id) do
    Map.fetch!(@stories_by_id, id)
  rescue
    KeyError -> raise ArgumentError, "unknown shell story: #{inspect(id)}"
  end

  def story!(id), do: raise(ArgumentError, "unknown shell story: #{inspect(id)}")
  def snapshot_name(id), do: "showcase/#{story!(id).id}"
  def a11y_target(id), do: ~s([data-obpt-shell-story="#{story!(id).id}"])
end
