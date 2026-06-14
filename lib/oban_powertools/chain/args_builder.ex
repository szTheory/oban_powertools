defmodule ObanPowertools.Chain.ArgsBuilder do
  @moduledoc """
  Marker behaviour for persisted chain args builders.

  Chain progression may execute builder references after a BEAM restart. Modules
  must opt in with this behaviour so persisted MFA references cannot point at
  arbitrary loaded code.
  """

  @callback build(map(), list()) :: {:ok, map()} | {:error, term()} | map()
  @optional_callbacks build: 2

  defmacro __using__(_opts) do
    quote do
      @behaviour ObanPowertools.Chain.ArgsBuilder

      def __powertools_chain_args_builder__, do: true
    end
  end
end
