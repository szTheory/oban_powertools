---
phase: 69-the-1-0-release
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - mix.exs
  - .release-please-manifest.json
  - README.md
  - guides/installation.md
  - examples/hex_consumer/mix.exs
  - examples/hex_consumer/regenerate.sh
  - examples/hex_consumer/README.md
  - examples/hex_consumer_local_proof/regenerate.sh
  - examples/hex_consumer_local_proof/README.md
  - test/oban_powertools/hex_release_test.exs
  - CHANGELOG.md
autonomous: false
requirements: [REL-1.0]
must_haves:
  truths:
    - Version is bumped to 1.0.0 across the project codebase and tests
    - CHANGELOG is updated for the 1.0.0 release
    - Hex publish steps are documented and presented to the user
  artifacts:
    - path: mix.exs
      provides: 1.0.0 version configuration
  key_links: []
---

<objective>
Bump Oban Powertools to version 1.0.0 and prepare for hex publication.

Purpose: Officially mark the library as stable and complete the v1.11 milestone.
Output: Updated codebase version strings, updated CHANGELOG, and preparation for hex.publish.
</objective>

<context>
@.planning/ROADMAP.md
@.planning/MILESTONES.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Bump version numbers across configuration and docs</name>
  <files>
    mix.exs
    .release-please-manifest.json
    README.md
    guides/installation.md
    examples/hex_consumer/mix.exs
    examples/hex_consumer/regenerate.sh
    examples/hex_consumer/README.md
    examples/hex_consumer_local_proof/regenerate.sh
    examples/hex_consumer_local_proof/README.md
  </files>
  <action>
    Update version references from 0.5.0 and ~> 0.5 to 1.0.0 and ~> 1.0.
    1. `mix.exs`: update `@version "0.5.0"` to `@version "1.0.0"`.
    2. `.release-please-manifest.json`: update `"." : "0.5.0"` to `"." : "1.0.0"`.
    3. `README.md`: replace `{:oban_powertools, "~> 0.5"}` with `{:oban_powertools, "~> 1.0"}` in the install snippet. Replace "Adopt `~> 0.5` and expect occasional breaking changes until `1.0`" with "Oban Powertools is stable. Adopt `~> 1.0`".
    4. `guides/installation.md`: replace `~> 0.5` with `~> 1.0`.
    5. `examples/hex_consumer/mix.exs`: update `{:oban_powertools, "~> 0.5"}` to `{:oban_powertools, "~> 1.0"}`.
    6. `examples/hex_consumer/regenerate.sh`: update `{:oban_powertools, "~> 0.5"}` to `{:oban_powertools, "~> 1.0"}`.
    7. `examples/hex_consumer/README.md`: update `{:oban_powertools, "~> 0.5"}` to `{:oban_powertools, "~> 1.0"}`.
    8. `examples/hex_consumer_local_proof/regenerate.sh`: update `{:oban_powertools, "~> 0.5"}` to `{:oban_powertools, "~> 1.0"}`.
    9. `examples/hex_consumer_local_proof/README.md`: update `{:oban_powertools, "~> 0.5"}` to `{:oban_powertools, "~> 1.0"}`.
  </action>
  <verify>
    <automated>grep -q 'version "1.0.0"' mix.exs &amp;&amp; grep -q '"\.": "1.0.0"' .release-please-manifest.json &amp;&amp; grep -q '~> 1.0' README.md &amp;&amp; grep -q '{:oban_powertools, "~> 1.0"}' examples/hex_consumer/mix.exs</automated>
  </verify>
  <done>Version references are successfully bumped to 1.0 in code, configuration, and documentation examples.</done>
</task>

<task type="auto">
  <name>Task 2: Update Hex release tests and CHANGELOG</name>
  <files>
    test/oban_powertools/hex_release_test.exs
    CHANGELOG.md
  </files>
  <action>
    1. In `test/oban_powertools/hex_release_test.exs`:
       - Update the test "CHANGELOG contains the 0.5.0 release heading" to refer to "1.0.0". Update the assertion to expect `## [1.0.0]`.
       - Update tests checking for `v0.5.0` to check for `v1.0.0` (e.g. `test "docs source_ref is pinned to the release tag v1.0.0"`).
       - Update test "release-please-config.json has include-v-in-tag == true (produces v0.5.0 tag format)" to say `produces v1.0.0 tag format`.
       - Update test "README contains the ~> 0.5 install snippet" to expect `~> 1.0`, and update its internal assertion string accordingly.
       - Update test "README does NOT contain the old ~> 0.1.0 snippet" to assert it does NOT contain `~> 0.5`.
    2. In `CHANGELOG.md`:
       - Rename the `[Unreleased]` heading to `[1.0.0] - <CURRENT_DATE>` (use today's date formatted as YYYY-MM-DD).
       - Add a new empty `## [Unreleased]` section above it.
       - Ensure the 1.0.0 release summary notes the stability milestone.
  </action>
  <verify>
    <automated>OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs</automated>
  </verify>
  <done>Hex release tests pass with the new version constraints and CHANGELOG reflects the 1.0.0 release.</done>
</task>

<task type="checkpoint:human-action" gate="blocking">
  <name>Task 3: Execute Hex Publish</name>
  <action>
    Present the human operator with the final sequence of commands to execute the hex.publish manually. Do NOT execute this automatically.
    Instruct the operator to run:
    1. Ensure all tests pass: `mix test`
    2. Run: `mix hex.publish --yes`
  </action>
  <verify>
    <human-check>Confirm that the commands were executed manually and the package was successfully published to Hex.</human-check>
  </verify>
  <done>The 1.0.0 package is published to hex.pm.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Developer -> Hex.pm | The published artifact represents the final 1.0 release boundary sent to users. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-69-01 | Tampering | mix.exs / Hex Publish | mitigate | The publish is performed manually as a checkpoint by the authorized developer using verified tokens (`mix hex.publish`). Automated artifact validation checks (`hex_release_test.exs`) ensure no unintentional files leak into the package. |
</threat_model>

<verification>
Ensure all files have `1.0` references in place of `0.5` and that `hex_release_test.exs` is fully green. The `1.0.0` header must be prominently featured in the `CHANGELOG.md`.
</verification>

<success_criteria>
- The version string across the project reads `1.0.0`.
- All `hex_release_test.exs` tests pass.
- A human operator successfully published the package using `mix hex.publish --yes`.
</success_criteria>

<output>
Create `.planning/phases/69-the-1-0-release/69-01-SUMMARY.md` when done
</output>
