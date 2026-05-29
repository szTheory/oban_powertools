defmodule ObanPowertools.Limits.GlossaryTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Limits.Glossary

  @guide_path Path.join(__DIR__, "../../../guides/limits-and-explain.md")
              |> Path.expand()

  # D-08 required terms — single source of truth
  @required_terms [
    "token_bucket",
    "bucket_capacity",
    "bucket_span_ms",
    "weight",
    "weight_by",
    "partition",
    "partition_by",
    "scope",
    "cooldown",
    "limit_reached"
  ]

  describe "Glossary.text/0" do
    test "returns a binary (string)" do
      assert is_binary(Glossary.text())
    end

    for term <- @required_terms do
      test "contains required term: #{term}" do
        assert String.contains?(Glossary.text(), unquote(term)),
               "Expected Glossary.text() to contain \"#{unquote(term)}\""
      end
    end
  end

  describe "guides/limits-and-explain.md" do
    test "guide file exists" do
      assert File.exists?(@guide_path), "Expected guide file to exist at #{@guide_path}"
    end

    test "guide contains a Rate-Limit Glossary section" do
      guide = File.read!(@guide_path)
      assert String.contains?(guide, "## Rate-Limit Glossary"),
             "Expected guide to contain a '## Rate-Limit Glossary' section"
    end

    for term <- @required_terms do
      test "guide contains required term: #{term}" do
        guide = File.read!(@guide_path)

        assert String.contains?(guide, unquote(term)),
               "Expected guides/limits-and-explain.md to contain \"#{unquote(term)}\""
      end
    end
  end
end
