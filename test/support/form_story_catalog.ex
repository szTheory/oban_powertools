defmodule ObanPowertools.FormStoryCatalog do
  @moduledoc """
  Deterministic dev/test form stories for the Powertools showcase.

  This registry is deliberately separate from domain stress fixtures and from
  production packaging. It describes component evidence, never behavior owned
  by an operator LiveView.
  """

  @story_specs [
    %{
      id: "form-input-states",
      kind: :form,
      component: :input,
      components: [:input, :label, :hint, :error],
      name: "Input states",
      description: "Valid, invalid, required, and optional worker fields.",
      variant: [:default],
      state: [:valid, :invalid, :required, :optional],
      copy: %{
        label: "Worker name",
        hint: "Enter a full or partial worker module name.",
        required: "Required",
        optional: "Optional",
        error: "Enter a worker name."
      },
      test_targets: nil
    },
    %{
      id: "form-textarea-select",
      kind: :form,
      component: :textarea,
      components: [:textarea, :select],
      name: "Textarea and select",
      description: "Reason text and native queue selection at operator density.",
      variant: [:default],
      state: [:valid, :optional],
      copy: %{reason: "Operator note", queue: "Queue", optional: "Optional"},
      test_targets: nil
    },
    %{
      id: "form-checkbox-modes",
      kind: :form,
      component: :checkbox,
      components: [:checkbox],
      name: "Checkbox modes",
      description: "Named boolean submission beside event-driven row selection.",
      variant: [:named_boolean, :event_selection],
      state: [:valid],
      selection_modes: [:named_boolean, :event_selection],
      examples: %{
        named_boolean: %{hidden_unchecked: true},
        event_selection: %{hidden_unchecked: false}
      },
      test_targets: nil
    },
    %{
      id: "form-radio-group",
      kind: :form,
      component: :radio_group,
      components: [:radio_group, :field_group],
      name: "Radio group",
      description: "A native fieldset with an explicit clearing choice.",
      variant: [:native],
      state: [:required, :optional],
      copy: %{legend: "Job state", clear: "Any state"},
      test_targets: nil
    },
    %{
      id: "form-switch-states",
      kind: :form,
      component: :switch,
      components: [:switch],
      name: "Switch states",
      description: "Immediate reversible setting with visible on and off text.",
      variant: [:off, :on],
      state: [:valid, :pending],
      copy: %{label: "Pause queue processing", pending: "Updating queue setting."},
      test_targets: nil
    },
    %{
      id: "form-validation-wiring",
      kind: :form,
      component: :error,
      components: [:input, :label, :hint, :error],
      name: "Validation wiring",
      description: "Label, hint, caller description, and visible recovery error associations.",
      variant: [:described],
      state: [:invalid, :required],
      copy: %{
        label: "Worker name",
        hint: "Enter a full or partial worker module name.",
        error: "Enter a worker name.",
        recovery: "Reason must be at least 10 characters. Add more detail and try again."
      },
      test_targets: nil
    },
    %{
      id: "form-disabled-readonly",
      kind: :form,
      component: :input,
      components: [:input, :select],
      name: "Disabled and read-only",
      description: "Unavailable selection and immutable identity remain visibly distinct.",
      variant: [:default],
      state: [:disabled, :readonly],
      copy: %{
        disabled: "Queue selection is unavailable while this job is running.",
        readonly: "Job ID is assigned when the job is inserted and cannot be changed."
      },
      test_targets: nil
    },
    %{
      id: "form-filter-ready",
      kind: :form,
      component: :input,
      components: [:input, :select],
      name: "Filter-ready controls",
      description: "Ordinary native search and select controls ready for parent-owned filtering.",
      variant: [:filter],
      state: [:filter, :valid],
      copy: %{label: "Search jobs", action: "Apply filters"},
      test_targets: nil
    },
    %{
      id: "form-long-content",
      kind: :form,
      component: :textarea,
      components: [:textarea, :label, :hint],
      name: "Long content wrapping",
      description: "Hostile ordinary text and long operator values wrap safely at 320px.",
      variant: [:default],
      state: [:long_content],
      copy: %{
        label:
          "Worker module and operational context that must remain readable on a narrow viewport",
        value:
          "<script>alert('escaped')</script> ObanPowertools.Workers.ReconcileAccountNotificationDeliveryWithAnIntentionallyLongIdentifier",
        hint:
          "This value is displayed as ordinary escaped text and may wrap across several lines."
      },
      test_targets: nil
    }
  ]

  @stories Enum.map(@story_specs, fn story ->
             id = story.id

             %{
               story
               | test_targets: %{
                   story: "obpt-form-story-#{id}",
                   snapshot: "showcase/#{id}",
                   a11y: ~s([data-obpt-form-story="#{id}"])
                 }
             }
           end)

  @stories_by_id Map.new(@stories, &{&1.id, &1})

  def stories, do: @stories

  def story!(id) when is_binary(id) do
    Map.fetch!(@stories_by_id, id)
  rescue
    KeyError -> raise ArgumentError, "unknown form story: #{inspect(id)}"
  end

  def story!(id), do: raise(ArgumentError, "unknown form story: #{inspect(id)}")
  def snapshot_name(id), do: "showcase/#{story!(id).id}"
  def a11y_target(id), do: ~s([data-obpt-form-story="#{story!(id).id}"])
end
