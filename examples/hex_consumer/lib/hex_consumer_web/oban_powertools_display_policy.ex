defmodule HexConsumerWeb.ObanPowertoolsDisplayPolicy do
  @moduledoc """
  Thin host-owned display policy seam for the canonical example host.
  """

  def display(:actor_label, actor, _context) when is_map(actor) do
    actor[:label] || actor["label"] || actor[:id] || actor["id"] || "ops-demo"
  end

  def display(:reason, reason, _context) when is_binary(reason), do: reason

  def display(kind, _value, context)
      when kind in [:job_args, :job_meta, :job_recorded] and is_map(context) do
    "[hidden by example host display policy]"
  end

  def display(:workflow_result, result, _context) when is_map(result) do
    %{
      summary: Map.get(result, :summary, Map.get(result, "summary", "Result available")),
      payload: "[hidden by example host display policy]",
      redacted?: true,
      status: Map.get(result, :status, Map.get(result, "status"))
    }
  end

  def display(_kind, _value, _context), do: nil
end
