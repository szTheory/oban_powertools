defmodule ObanPowertoolsTest do
  use ExUnit.Case
  doctest ObanPowertools

  test "top-level module documents the supported surface" do
    docs = Code.fetch_docs(ObanPowertools)

    assert {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} = docs
    assert moduledoc =~ "ObanPowertools.Worker"
    assert moduledoc =~ "ObanPowertools.Workflow"
  end
end
