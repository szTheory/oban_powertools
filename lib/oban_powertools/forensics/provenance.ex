defmodule ObanPowertools.Forensics.Provenance do
  @durable_values [:durable, :supporting, :bridge_only, :missing]
  @completeness_values [:complete, :partial_evidence, :history_unavailable, :unknown]

  def provenance_values, do: @durable_values
  def completeness_values, do: @completeness_values

  def normalize_provenance(value) when is_binary(value), do: value |> String.to_atom() |> normalize_provenance()
  def normalize_provenance(value) when value in @durable_values, do: value
  def normalize_provenance(_value), do: :missing

  def normalize_completeness(value) when is_binary(value),
    do: value |> String.to_atom() |> normalize_completeness()

  def normalize_completeness(value) when value in @completeness_values, do: value
  def normalize_completeness(_value), do: :unknown

  def strength_rank(:durable), do: 0
  def strength_rank(:supporting), do: 1
  def strength_rank(:bridge_only), do: 2
  def strength_rank(:missing), do: 3
  def strength_rank(other), do: other |> normalize_provenance() |> strength_rank()
end
