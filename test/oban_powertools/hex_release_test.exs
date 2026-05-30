defmodule ObanPowertools.HexReleaseTest do
  use ExUnit.Case, async: true

  # Phase 47 hex-release-foundation — durable artifact contracts.
  # These tests guard static config/doc artifacts so future edits cannot
  # silently break REL-01 (packaging + pipeline), REL-02 (ExDoc source links),
  # or REL-03 (CHANGELOG + LICENSE).
  #
  # Run without a database: OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs

  @current_version Mix.Project.config()[:version]

  @changelog_path "CHANGELOG.md"
  @license_path "LICENSE"
  @readme_path "README.md"
  @mixexs_path "mix.exs"
  @rp_config_path "release-please-config.json"
  @rp_manifest_path ".release-please-manifest.json"
  @release_workflow_path ".github/workflows/release.yml"

  # ---------------------------------------------------------------------------
  # REL-03  CHANGELOG + LICENSE
  # ---------------------------------------------------------------------------

  describe "REL-03 CHANGELOG + LICENSE" do
    test "CHANGELOG contains the 0.5.0 release heading" do
      source = File.read!(@changelog_path)

      assert source =~ "## [0.5.0]",
             "CHANGELOG.md must have a ## [0.5.0] section heading"
    end

    test "CHANGELOG contains the Unreleased section" do
      source = File.read!(@changelog_path)

      assert source =~ "## [Unreleased]",
             "CHANGELOG.md must have a ## [Unreleased] section"
    end

    test "CHANGELOG contains a Path to 1.0 heading" do
      source = File.read!(@changelog_path)

      assert String.downcase(source) =~ "path to 1.0",
             "CHANGELOG.md must contain a 'Path to 1.0' heading (case-insensitive)"
    end

    test "CHANGELOG references keepachangelog" do
      source = File.read!(@changelog_path)

      assert String.downcase(source) =~ "keepachangelog",
             "CHANGELOG.md must reference keepachangelog in the preamble"
    end

    test "CHANGELOG contains NO [1.x.y] SemVer headings (no backfilled 1.x milestones)" do
      source = File.read!(@changelog_path)

      refute source =~ ~r/## \[1\.\d+\.\d+\]/,
             "CHANGELOG.md must NOT contain any ## [1.x.y] headings — internal planning milestones must not appear as Hex releases (D-13)"
    end

    test "LICENSE contains the Apache License header" do
      source = File.read!(@license_path)

      assert source =~ "Apache License",
             "LICENSE must contain 'Apache License'"
    end

    test "LICENSE contains the version 2.0 January 2004 line" do
      source = File.read!(@license_path)

      assert source =~ "Version 2.0, January 2004",
             "LICENSE must contain 'Version 2.0, January 2004'"
    end

    test "LICENSE contains the canonical Apache URL" do
      source = File.read!(@license_path)

      assert source =~ "http://www.apache.org/licenses/LICENSE-2.0",
             "LICENSE must contain the canonical Apache-2.0 URL"
    end

    test "LICENSE contains the APPENDIX section" do
      source = File.read!(@license_path)

      assert source =~ "APPENDIX",
             "LICENSE must contain the APPENDIX section (verbatim Apache-2.0 requirement)"
    end
  end

  # ---------------------------------------------------------------------------
  # REL-01  packaging (mix.exs)
  # ---------------------------------------------------------------------------

  describe "REL-01 packaging (mix.exs)" do
    test "mix.exs @version matches current release" do
      version = Mix.Project.config()[:version]

      assert version == @current_version,
             "expected Mix.Project.config()[:version] == #{inspect(@current_version)}, got #{inspect(version)}"
    end

    test "package licenses is [\"Apache-2.0\"]" do
      licenses = Mix.Project.config()[:package][:licenses]

      assert licenses == ["Apache-2.0"],
             "package :licenses must be [\"Apache-2.0\"] for SPDX compliance, got #{inspect(licenses)}"
    end

    test "package :files includes lib, guides, mix.exs, mix.lock, README.md, CHANGELOG.md, LICENSE" do
      files = Mix.Project.config()[:package][:files]
      assert "lib" in files, ":files must include \"lib\""
      assert "guides" in files, ":files must include \"guides\""
      assert "mix.exs" in files, ":files must include \"mix.exs\""
      assert "mix.lock" in files, ":files must include \"mix.lock\""
      assert "README.md" in files, ":files must include \"README.md\""
      assert "CHANGELOG.md" in files, ":files must include \"CHANGELOG.md\""
      assert "LICENSE" in files, ":files must include \"LICENSE\""
    end

    test "package :files does NOT include priv, test, or .planning" do
      files = Mix.Project.config()[:package][:files]

      refute "priv" in files,
             ":files must NOT include \"priv\" — no priv/ directory exists (Igniter generates inline)"

      refute "test" in files,
             ":files must NOT include \"test\" (dev artifact must be excluded from tarball)"

      refute ".planning" in files,
             ":files must NOT include \".planning\" (internal planning must never ship to adopters)"
    end

    test "igniter dep has runtime: false (keeps code-gen machinery out of adopter prod)" do
      deps = Mix.Project.config()[:deps]
      igniter_dep = Enum.find(deps, fn dep -> elem(dep, 0) == :igniter end)
      assert igniter_dep != nil, "igniter dep must be present in deps"
      # Dep tuple is {:igniter, "~> 0.8.0", [runtime: false]}
      opts = elem(igniter_dep, 2)

      assert Keyword.get(opts, :runtime) == false,
             "igniter must have runtime: false so it does not start in adopter prod apps, got opts: #{inspect(opts)}"

      # Per reconciliation 2: only: [:dev,:test] was removed (igniter must load to compile
      # lib/mix/tasks/oban_powertools.install.ex which uses Igniter.Mix.Task).
      # We intentionally do NOT assert only: [:dev,:test].
    end
  end

  # ---------------------------------------------------------------------------
  # REL-02  ExDoc source links
  # ---------------------------------------------------------------------------

  describe "REL-02 ExDoc source links" do
    test "docs source_ref is pinned to the release tag v0.5.0" do
      source_ref = Mix.Project.config()[:docs][:source_ref]

      assert source_ref == "v#{@current_version}",
             "docs :source_ref must be \"v#{@current_version}\" to pin links to the release tag, got #{inspect(source_ref)}"
    end

    test "docs source_url_pattern contains /blob/v0.5.0/" do
      pattern = Mix.Project.config()[:docs][:source_url_pattern]

      assert pattern =~ "/blob/v#{@current_version}/",
             "docs :source_url_pattern must contain \"/blob/v#{@current_version}/\" to link source to the correct tag, got #{inspect(pattern)}"
    end

    test "docs extras includes CHANGELOG.md" do
      extras = Mix.Project.config()[:docs][:extras]

      assert "CHANGELOG.md" in extras,
             "docs :extras must include \"CHANGELOG.md\" so the changelog renders on hexdocs"
    end

    test "docs extras includes README.md" do
      extras = Mix.Project.config()[:docs][:extras]

      assert "README.md" in extras,
             "docs :extras must include \"README.md\""
    end

    test "mix.exs source text contains no changelog: key (ExDoc has no such key — extras is the mechanism)" do
      source = File.read!(@mixexs_path)

      refute source =~ ~r/\n\s*changelog:/,
             "mix.exs must NOT have a `changelog:` key — ExDoc does not support it; CHANGELOG.md belongs in extras (RECONCILIATION D-12)"
    end
  end

  # ---------------------------------------------------------------------------
  # REL-01  README install snippet + 0.x stability
  # ---------------------------------------------------------------------------

  describe "REL-01 README install snippet + stability" do
    test "README contains the ~> 0.5 install snippet" do
      source = File.read!(@readme_path)

      assert source =~ ~s({:oban_powertools, "~> 0.5"}),
             "README.md must show {:oban_powertools, \"~> 0.5\"} as the install snippet"
    end

    test "README does NOT contain the old ~> 0.1.0 snippet" do
      source = File.read!(@readme_path)

      refute source =~ ~s("~> 0.1.0"),
             "README.md must NOT still reference \"~> 0.1.0\" — it was replaced with \"~> 0.5\""
    end

    test "README contains a 0.x stability note" do
      source = File.read!(@readme_path)
      lower = String.downcase(source)

      assert lower =~ "0.x",
             "README.md must contain a 0.x stability note"

      assert lower =~ "stability" or lower =~ "api freeze",
             "README.md 0.x stability note must mention 'stability' or 'api freeze'"
    end
  end

  # ---------------------------------------------------------------------------
  # REL-01  release-please pipeline (config + manifest + workflow)
  # ---------------------------------------------------------------------------

  describe "REL-01 release-please pipeline" do
    test "release-please-config.json has release-type == elixir" do
      config = rp_config()

      assert config["release-type"] == "elixir",
             "release-please-config.json must have \"release-type\": \"elixir\""
    end

    test "release-please-config.json has include-v-in-tag == true (produces v0.5.0 tag format)" do
      config = rp_config()

      assert config["include-v-in-tag"] == true,
             "release-please-config.json must have \"include-v-in-tag\": true to match mix.exs source_ref format"
    end

    test "release-please-config.json has a bootstrap-sha present and non-empty" do
      config = rp_config()
      sha = config["bootstrap-sha"]
      assert sha != nil, "release-please-config.json must have a \"bootstrap-sha\" key"
      assert sha != "", "release-please-config.json \"bootstrap-sha\" must be non-empty"
    end

    test "release-please-config.json has NO release-as key (deprecated; version set via commit footer)" do
      config = rp_config()

      refute Map.has_key?(config, "release-as"),
             "release-please-config.json must NOT have a \"release-as\" key (deprecated — use Release-As: footer commit instead)"
    end

    test "release-please-config.json packages['.'] has correct changelog-path and package-name" do
      config = rp_config()
      dot_pkg = get_in(config, ["packages", "."])
      assert dot_pkg != nil, "release-please-config.json must have packages[\".\"]"

      assert dot_pkg["changelog-path"] == "CHANGELOG.md",
             "packages[\".\"][\"changelog-path\"] must be \"CHANGELOG.md\", got #{inspect(dot_pkg["changelog-path"])}"

      assert dot_pkg["package-name"] == "oban_powertools",
             "packages[\".\"][\"package-name\"] must be \"oban_powertools\", got #{inspect(dot_pkg["package-name"])}"
    end

    test ".release-please-manifest.json '.' value equals the current mix.exs @version" do
      # The manifest must stay in sync with mix.exs @version so the next release-please run
      # proposes the correct bump. We assert dynamically so this test survives version bumps.
      manifest = rp_manifest()
      dot_version = manifest["."]

      assert dot_version == @current_version,
             ".release-please-manifest.json \".\" must equal the current @version (#{@current_version}), got #{inspect(dot_version)}"
    end

    test "release.yml workflow contains the release-please action" do
      source = File.read!(@release_workflow_path)

      assert source =~ "googleapis/release-please-action",
             "#{@release_workflow_path} must use the googleapis/release-please-action"
    end

    test "release.yml workflow gates publish on release_created output" do
      source = File.read!(@release_workflow_path)

      assert source =~ "release_created",
             "#{@release_workflow_path} must gate the publish job on the release_created output"
    end

    test "release.yml workflow publishes to Hex with mix hex.publish" do
      source = File.read!(@release_workflow_path)

      assert source =~ "mix hex.publish",
             "#{@release_workflow_path} must run mix hex.publish as the publish step"
    end

    test "release.yml workflow uses HEX_API_KEY secret" do
      source = File.read!(@release_workflow_path)

      assert source =~ "HEX_API_KEY",
             "#{@release_workflow_path} must reference HEX_API_KEY for authenticated hex publish"
    end

    test "release.yml workflow uses erlef/setup-beam to configure BEAM" do
      source = File.read!(@release_workflow_path)

      assert source =~ "erlef/setup-beam",
             "#{@release_workflow_path} must use erlef/setup-beam to set up Elixir/OTP"
    end

    test "release.yml workflow pins Elixir 1.19.5" do
      source = File.read!(@release_workflow_path)

      assert source =~ "1.19.5",
             "#{@release_workflow_path} must pin elixir-version 1.19.5"
    end

    test "release.yml workflow pins OTP 27.3" do
      source = File.read!(@release_workflow_path)

      assert source =~ "27.3",
             "#{@release_workflow_path} must pin otp-version 27.3"
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp rp_config do
    @rp_config_path
    |> File.read!()
    |> Jason.decode!()
  end

  defp rp_manifest do
    @rp_manifest_path
    |> File.read!()
    |> Jason.decode!()
  end
end
