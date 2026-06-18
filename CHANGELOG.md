# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **Semantic Versioning** headings like **`[0.5.0]`** for **published
Hex releases**. The maintainer tracks internal planning milestones (v1, v1.1, v1.2,
v1.3, v1.4, v1.5, etc.) in `.planning/` — those labels describe shipped tranches of
work, **not** a second installable version axis on Hex. The library stayed at `0.1.0`
internally through five milestones before its first Hex publication. Do not map planning
milestone numbers to Hex versions.

This library remains **0.x** on Hex until a real **1.0.0** after real adopter feedback.
See [Path to 1.0](#path-to-10) below for the explicit gate.

## [0.5.0](https://github.com/szTheory/oban_powertools/compare/v1.0.0...v0.5.0) (2026-06-18)


### Features

* **43-01:** add ObanPowertools.Jobs context module with JobFilter struct ([6468cff](https://github.com/szTheory/oban_powertools/commit/6468cffcb15d60684866d5e592126bedfac91798))
* **43-01:** extend DisplayPolicy with render_job_field/3 and add Selectors.jobs_path/1 ([ad0759c](https://github.com/szTheory/oban_powertools/commit/ad0759cd40b06b1d7b7a0c8d5d5a712f92e71a93))
* **43-02:** extend LiveAuth with job permission atoms and add JobsLive routes ([7a03ef9](https://github.com/szTheory/oban_powertools/commit/7a03ef9404cde9ab9810d0eeb45c7982d2aefba8))
* **43-02:** implement ObanPowertools.Web.JobsLive :index action ([3e30909](https://github.com/szTheory/oban_powertools/commit/3e3090952b2a44c693752398657828c12c9375b4))
* **43-03:** implement :show action — job detail view with DisplayPolicy redaction ([2120fbf](https://github.com/szTheory/oban_powertools/commit/2120fbfe3c76f32d844485ea7b13d4112dd3aa60))
* **44+45:** native single-job and bulk action UI in JobsLive ([0ea569d](https://github.com/szTheory/oban_powertools/commit/0ea569d8cd3b22dda175fd908a2c14b9afe42cc8))
* **46-01:** implement single-job Operator API ([ca33d48](https://github.com/szTheory/oban_powertools/commit/ca33d48e223d484ff797e0dc4cd0dea3a14691e6))
* **46-01:** thread telemetry metadata through Lifeline ([4c022ee](https://github.com/szTheory/oban_powertools/commit/4c022ee5a83672cdface0ed920fffda7c5fa69d6))
* **46-02:** implement bulk operations in Operator API ([204d3f2](https://github.com/szTheory/oban_powertools/commit/204d3f26821847596b4b4e7715b638258828a54b))
* **47-02:** add [@version](https://github.com/version), package/0, igniter scope fix; hex tarball verified ([9def318](https://github.com/szTheory/oban_powertools/commit/9def318fe335e784ce29cc1cc1f85236d76e756d))
* **47-02:** add docs/0 source links pinned to v0.5.0, CHANGELOG extra, forensics group fix ([4fa16ac](https://github.com/szTheory/oban_powertools/commit/4fa16acf77f904f42e645aeb320c0b4ab7a6c501))
* **47-03:** add release-please pipeline (config, manifest@0.0.0, publish workflow) ([ad2ba53](https://github.com/szTheory/oban_powertools/commit/ad2ba5359a1c87f1fbd59d1b196995e474087eba))
* **48-01:** implement index, migration-version, and powertools-table checks ([0489cb3](https://github.com/szTheory/oban_powertools/commit/0489cb3363bc5529c6ae3373479054c9d1e9a94f))
* **48-02:** implement Doctor.Formatter - human ANSI-degrading + JSON schema_version:1 output ([1c03bc1](https://github.com/szTheory/oban_powertools/commit/1c03bc1ce50fc47a87f205b768dd977455ae388a))
* **48-02:** implement Mix.Tasks.ObanPowertools.Doctor - flags, repo/prefix resolution, with_repo boot, exit codes ([e4b11a4](https://github.com/szTheory/oban_powertools/commit/e4b11a418d59d0ffc6c623db11ec2a99294e2970))
* **49-01:** add Glossary module with single-source rate-limit glossary string ([9586818](https://github.com/szTheory/oban_powertools/commit/95868185dbf3bf6c2ff1125c656858e9d8417e9a))
* **49-01:** extract pure compute_reservation/4 and refactor attempt_reservation/5 ([a83bc61](https://github.com/szTheory/oban_powertools/commit/a83bc615805289050f2b71995e35d37a0e7b9edd))
* **49-02:** add explain task tests + fix Module.safe_concat unknown-module guard ([ec55f37](https://github.com/szTheory/oban_powertools/commit/ec55f37e8916804ca7ae84cbaca9d12c78e1e2ee))
* **49-02:** create Mix.Tasks.ObanPowertools.Limiter.Explain ([be97468](https://github.com/szTheory/oban_powertools/commit/be974685e65948625254090970ef5eb1b12a84bf))
* **49-03:** add mix oban_powertools.limiter.simulate task (OPS-07) ([a4d9a7c](https://github.com/szTheory/oban_powertools/commit/a4d9a7cda2200050e710132cab0b379c4f796382))
* **50-02:** implement metrics/0 with Code.ensure_loaded? guard over frozen contract ([4820915](https://github.com/szTheory/oban_powertools/commit/482091585336f918439b9f64720c8a99a14c7803))
* **51-01:** create regenerate.sh maintainer companion with hex dep insertion ([354b839](https://github.com/szTheory/oban_powertools/commit/354b8396dfb7b43982b6a0d5339232d2e82d238a))
* **51-01:** scaffold hex_consumer config/, lib/, and host-owned seam modules ([f078b2e](https://github.com/szTheory/oban_powertools/commit/f078b2ea19e9a5bc7ddf84df08de4dd78e76843d))
* **51-01:** scaffold hex_consumer mix.exs, .formatter.exs, README, .gitignore ([da559c3](https://github.com/szTheory/oban_powertools/commit/da559c3cce3b9a7e79e76dadb90d64f65775f012))
* **51-02:** add test infrastructure and nightly_sync seed for hex_consumer ([a316de7](https://github.com/szTheory/oban_powertools/commit/a316de7310aeb7091399217641b46f41e7fd703f))
* **51-02:** create first-session test and missing web components for hex_consumer ([81b72e2](https://github.com/szTheory/oban_powertools/commit/81b72e21511daf6fb727221e9776362ad9a1414b))
* **51-03:** add verify-published job to release.yml (REL-04) ([a7a5e99](https://github.com/szTheory/oban_powertools/commit/a7a5e995c2092e4ab83a95638a58b0b92c7707b2))
* **52-01:** add actionlint lane to ci.yml and wire into ci-gate ([45e8bf3](https://github.com/szTheory/oban_powertools/commit/45e8bf3b79d0440e315aa9d42d2d98f02e8bd0f8))
* **53-01:** add crash-safe worker hook dispatcher ([837b9ba](https://github.com/szTheory/oban_powertools/commit/837b9ba260ee550a920ba90311fd46d5c152ea7c))
* **53-01:** add worker hook telemetry contract ([25c81f2](https://github.com/szTheory/oban_powertools/commit/25c81f242f71e1bfb77929ba756caf4452b50e05))
* **53-01:** wire lifecycle hooks into generated workers ([97b0a3d](https://github.com/szTheory/oban_powertools/commit/97b0a3db960402b3f374e17e4f8b58340f4d8f34))
* **54-01:** implement worker timeout and deadline support ([085a127](https://github.com/szTheory/oban_powertools/commit/085a127db4c076a3e14bfbfa8db7dd57a1cdff1e))
* **54-02:** merge enqueue deadline metadata ([602b0ca](https://github.com/szTheory/oban_powertools/commit/602b0cacc7f82e5bb640d9b92274a414b1eec01e))
* **54-03:** add Doctor expired deadline warnings ([ef6cb50](https://github.com/szTheory/oban_powertools/commit/ef6cb50d59f994eb545f044d20a752a44e281989))
* **55-01:** add job record migrations ([9537656](https://github.com/szTheory/oban_powertools/commit/9537656ee5dac902183e4d3b9a8a7551dcf5e6e1))
* **55-01:** implement job record api ([96d16fc](https://github.com/szTheory/oban_powertools/commit/96d16fcb26e4391ff884b9bee5fdd1bc88ea75eb))
* **55-02:** add worker output recording options ([b874692](https://github.com/szTheory/oban_powertools/commit/b874692926bd819c1787a23dd25fd0f8f4d80d0b))
* **55-02:** record worker success payloads ([eed1435](https://github.com/szTheory/oban_powertools/commit/eed14355f3f336aee81ec072726cc1e4053b4993))
* **55-03:** render recorded output in jobs detail ([3e4f565](https://github.com/szTheory/oban_powertools/commit/3e4f56556cf04184616fd869a23e207e5457049c))
* **55-03:** support job recorded display policy ([0d3906a](https://github.com/szTheory/oban_powertools/commit/0d3906ab626f2c8bf0324ab6fdbee6eb1d705837))
* **55-04:** prune expired JobRecords through Lifeline ([ec89e1d](https://github.com/szTheory/oban_powertools/commit/ec89e1d5eff83f0b18f120273642b29abf547d6e))
* **56-01:** add fingerprint-ordering + meta-injection invariant tests in idempotency_test ([5d0699c](https://github.com/szTheory/oban_powertools/commit/5d0699cdbeea6c327c2f6b082e68dc4d15dba8bd))
* **56-01:** implement redaction engine — redact: opt, guards, new/2 override ([6518840](https://github.com/szTheory/oban_powertools/commit/6518840c377dd75e9cfc50242603f4f4fb13f8cc))
* **56-02:** route cron Powertools workers through new/2 for redaction ([593f5a4](https://github.com/szTheory/oban_powertools/commit/593f5a4415321015700ae7c41ff141d0b7114161))
* **56-03:** redaction disclosure block and :redacted_fields assigns in jobs_live.ex ([3dfc30c](https://github.com/szTheory/oban_powertools/commit/3dfc30c39f1edb7e5f987db18fbb6ac6a740e0e6))
* **56-03:** render_job_field(:job_args) overlay with Redacted at enqueue ([95b28a2](https://github.com/szTheory/oban_powertools/commit/95b28a2390f3e3a474dfb54f6a4dbe698b03e109))
* **56-04:** add At-rest argument redaction section to workers guide (GREEN) ([7f269fe](https://github.com/szTheory/oban_powertools/commit/7f269fe8d7552e508a288abf471e626e1853e94e))
* **57-01:** add output-recording group to [@powertools](https://github.com/powertools)_manifest ([6b251a2](https://github.com/szTheory/oban_powertools/commit/6b251a259ab5e8209ec74c974a3d38c55bfadc9b))
* **60-01:** add batch completion timestamp field ([8d828bf](https://github.com/szTheory/oban_powertools/commit/8d828bf4a0b07b5ebd7ee12ca12e4632281e98e5))
* **60-01:** add completed_at to batch migrations ([2041f51](https://github.com/szTheory/oban_powertools/commit/2041f512e7e2e83ef68f208129a91fcd125e6e26))
* **60-02:** implement exactly-once batch tracker ([5d3ff30](https://github.com/szTheory/oban_powertools/commit/5d3ff30a329f6e2f0c3c82617c18feb966d2e7d6))
* **60-03:** wire batch tracker into worker hooks ([8b3a411](https://github.com/szTheory/oban_powertools/commit/8b3a41131cee5125750400889c50b9dedea65d01))
* **61-01:** add durable batch insertion metadata ([77a9ba4](https://github.com/szTheory/oban_powertools/commit/77a9ba48a44dacefb12eaf2968bc9fcd18c7e4da))
* **61-01:** update installer batch metadata contract ([83f7277](https://github.com/szTheory/oban_powertools/commit/83f727753b42556a6d291dc970e127c512a53b7d))
* **61-02:** implement batch insert stream ([6f094e1](https://github.com/szTheory/oban_powertools/commit/6f094e10f35ccd9830ea0a2c99b41b394a1c5e0c))
* **61-03:** implement linear chain DSL ([5c8d3ab](https://github.com/szTheory/oban_powertools/commit/5c8d3ab020dda00e248b18facf2d71e9f6ab650a))
* **61-04:** dispatch chain progression callbacks ([6116d39](https://github.com/szTheory/oban_powertools/commit/6116d39285b1a02042a1494887efce25cdcbf877))
* **61-04:** scope host callback dispatch events ([faba574](https://github.com/szTheory/oban_powertools/commit/faba5749972463afe82138ef5d160df8e30f1ac4))
* **61-05:** implement durable chain output handoff ([c30ff59](https://github.com/szTheory/oban_powertools/commit/c30ff59e42bb51b2e33c00fd18acbcee12415afa))
* **62-02:** add batch permission copy ([0fae47b](https://github.com/szTheory/oban_powertools/commit/0fae47bf7a011ededa75e296a71b42b9e2c67cdb))
* **62-02:** add batch routes and selector helpers ([9ea3e92](https://github.com/szTheory/oban_powertools/commit/9ea3e9209190aa750785c9367c4ee0f3e1e56a55))
* **62-03:** add Batches read model ([8d8b0ae](https://github.com/szTheory/oban_powertools/commit/8d8b0ae159e7ffe1ca14c78152e256289d37ed16))
* **62-04:** add Lifeline callback retry ([1d8593f](https://github.com/szTheory/oban_powertools/commit/1d8593fe541cdbf9bf7190b08ad7cdbe5c83cd59))
* **62-05:** add native batches LiveView ([8e8a1cb](https://github.com/szTheory/oban_powertools/commit/8e8a1cbd5fd4af2c314b345d3c58c7cca64f0c99))
* **63-01:** implement and harden CallbackDispatcher Plugin ([89bc015](https://github.com/szTheory/oban_powertools/commit/89bc015417f0562487f1fd2a01a4e9c9f159003f))
* **64-01:** add args and meta JSONB filtering to Jobs ([aa62980](https://github.com/szTheory/oban_powertools/commit/aa6298050935373112463955fd3031ddc437990b))
* **64-01:** expose Operator.list programmatic API ([df1adf2](https://github.com/szTheory/oban_powertools/commit/df1adf2f5b91968329fd9e4274421d3fbdb3a8c0))
* **64-02:** add programmatic args and meta filtering to jobs list ([e86a6f0](https://github.com/szTheory/oban_powertools/commit/e86a6f05c63e9611db1d390dbdf8bc5ef12f2ed8))
* **69-01:** bump version numbers across configuration and docs ([03f2f38](https://github.com/szTheory/oban_powertools/commit/03f2f3849ecf1d7c032a7d64d6e67b7d3626f818))
* implement optional live counts with oban_met (Phase 66) ([d155cbd](https://github.com/szTheory/oban_powertools/commit/d155cbd74b96cfd6c55be80109a32d8cab6d0ced))
* **workflow:** execute phase 59 ([44e09c7](https://github.com/szTheory/oban_powertools/commit/44e09c72e636a1841bc7b05b1fca4f85d182e808))


### Bug Fixes

* **43-02:** use connected?/1 guard for push_patch and fix filter_path nil encoding ([6d73ada](https://github.com/szTheory/oban_powertools/commit/6d73adadeae97c5f2c9b5f914ce5becc5662a0a6))
* **43:** apply code review fixes for jobs browse ([a6ce9e3](https://github.com/szTheory/oban_powertools/commit/a6ce9e33f7324700e54cc6ef76498053d69520b2))
* **48-01:** wire [@eligible](https://github.com/eligible)_states constant into eligible-count query ([309bdda](https://github.com/szTheory/oban_powertools/commit/309bdda9e58630f0823990b8df168c6c8b7bf192))
* **48-02:** load app.config and harden --format mapping for real CLI runs ([2c1ec3e](https://github.com/szTheory/oban_powertools/commit/2c1ec3e3fbce8cf8b686635533793f183b8cd325))
* **48:** resolve code-review criticals — honest exit codes + safe parsing ([f6245e4](https://github.com/szTheory/oban_powertools/commit/f6245e422258df8dd46e91ad8b1245eac85a5fae))
* **48:** resolve research open questions + identifier-safe count query + DataCase test header ([c159517](https://github.com/szTheory/oban_powertools/commit/c1595172824166fffc5d2278f033a1c725c63787))
* **49:** address code review CR-01 + WR-01/02/03 (D-02 exit-code posture) ([357f68e](https://github.com/szTheory/oban_powertools/commit/357f68e47a7975134db97292dc591f911c079be0))
* **49:** inline D-08 glossary in explain [@moduledoc](https://github.com/moduledoc) for source-parity contract ([cd05b46](https://github.com/szTheory/oban_powertools/commit/cd05b46e2d3837c6da6bab1f344360400ae5b2d5))
* **49:** revise plans + validation/patterns/research per checker feedback ([18f98c7](https://github.com/szTheory/oban_powertools/commit/18f98c7041e53ace38a48859b8241ab6aed2d14a))
* **50-02:** replace import with apply/3 to fix prod-tree compile without telemetry_metrics ([8e87bdb](https://github.com/szTheory/oban_powertools/commit/8e87bdbae1e658821d05782e5c99bb19eb4e1593))
* **52.1-01:** close gap REL-04 — rm step, MIX_ENV compile, version-agnostic sed ([b95f212](https://github.com/szTheory/oban_powertools/commit/b95f212a4c29057b51800ded24baa6fa8ec45b55))
* **52:** pin actions/github-script to full SHA in release-pr-automerge.yml ([f0ad671](https://github.com/szTheory/oban_powertools/commit/f0ad6717afa1fe9ab7e9522342560431085cbc6b))
* **54:** revise plans based on checker feedback ([fba56c5](https://github.com/szTheory/oban_powertools/commit/fba56c5764c97ff4d1c7822ebff83b54a77da982))
* **55-01:** expose configured job record lookup ([277132a](https://github.com/szTheory/oban_powertools/commit/277132aeb8579dfa1852b41921bcb98eea3f129b))
* **55:** handle default workflow result display ([fe7eea9](https://github.com/szTheory/oban_powertools/commit/fe7eea9398043142c78ed8df89944f65ee274e91))
* **55:** preserve job record display policy booleans ([3e1c4a6](https://github.com/szTheory/oban_powertools/commit/3e1c4a605c485c539858b7e4b4c21daceb1bae70))
* **55:** preserve workflow display policy false values ([1deb219](https://github.com/szTheory/oban_powertools/commit/1deb2192e1e63bf15ad5686cfa2cc8d8d6199d9d))
* **55:** resolve job record review findings ([10e0a71](https://github.com/szTheory/oban_powertools/commit/10e0a71be8c9ef4d6f4d21e416f9006517858f65))
* **56:** CR-01 strip :repo from opts before Oban.Job.new/2 in merge_powertools_meta ([271ac8e](https://github.com/szTheory/oban_powertools/commit/271ac8e7fbb9eb8f98e790424848037dd7f35e6c))
* **56:** CR-02 remove String.to_atom on DB-sourced entry.queue in maybe_insert_job ([f06f428](https://github.com/szTheory/oban_powertools/commit/f06f428c415e524c4f61ddc3a4c71db3b4f084d4))
* **56:** WR-01 add action_word catch-all and whitelist guard on preview handler ([ae8e0f4](https://github.com/szTheory/oban_powertools/commit/ae8e0f48d722a6875a7bcd1ca648509cdd016e95))
* **56:** WR-02 normalize string keys to atoms in normalize_entry_attrs to prevent false-positive audit events ([2cc4ef8](https://github.com/szTheory/oban_powertools/commit/2cc4ef8e4d8c73cef3dced840a8128ba31aa8927))
* **56:** WR-03 add warning comment on defoverridable new:2 to prevent silent redaction bypass ([74033fa](https://github.com/szTheory/oban_powertools/commit/74033fa1c7aca1bd39f5ed9bc83e97cba595bcc0))
* **56:** WR-04 pass repo parameter through emit_claim_telemetry instead of reading from Application config ([c0072f1](https://github.com/szTheory/oban_powertools/commit/c0072f104fda4b194375259e07da7e2267a811a2))
* **57:** add oban_powertools_job_records migration to example host ([f6e63c8](https://github.com/szTheory/oban_powertools/commit/f6e63c85a0605de4b08542869e59064dc241ce6c))
* **60-03:** prefer callback identity for exhaustion ([013d0be](https://github.com/szTheory/oban_powertools/commit/013d0be390dab25174a0c35906b915694bbdcf85))
* **60:** revise plans based on checker feedback ([f29be18](https://github.com/szTheory/oban_powertools/commit/f29be181a75a6417578462418592866223f9a1ce))
* **61:** address code review blockers ([6763c87](https://github.com/szTheory/oban_powertools/commit/6763c87d5f82ca1207b6b7f6109683455bee2f5b))
* **61:** preserve downstream chain job options ([8c28e3c](https://github.com/szTheory/oban_powertools/commit/8c28e3c9329396bb6d3cd7bba17d4bce72d771bc))
* **61:** revise plans based on checker feedback ([60893ca](https://github.com/szTheory/oban_powertools/commit/60893cab92b8bd279c0da5d618b510e7c7ddd321))
* **62:** revise plans based on checker feedback ([573d886](https://github.com/szTheory/oban_powertools/commit/573d8863b2480245a76fa477fd972398375ca6e0))
* **64:** CR-01 fix LiveView Crash via Unvalidated JSON Primitive Types ([7d91200](https://github.com/szTheory/oban_powertools/commit/7d912005312e14965f3fbd87f90b2dca98ce26f5))
* **64:** WR-01 convert string keys to atoms for map filters ([f5478af](https://github.com/szTheory/oban_powertools/commit/f5478af994031ff23be9560264ef7627dfe382ca))
* **69-01:** finalize remaining 1.0.0 test assertions and changelog updates ([1e5fda7](https://github.com/szTheory/oban_powertools/commit/1e5fda75388154d50e4abff5d9b510b75374821a))
* ensure Ecto migrations use concurrent indexing where appropriate ([8feb649](https://github.com/szTheory/oban_powertools/commit/8feb649a4e0af1a46842cffadb08d04b07ee5944))
* make igniter installer compile for adopters (unscope from dev/test) ([#8](https://github.com/szTheory/oban_powertools/issues/8)) ([955dd23](https://github.com/szTheory/oban_powertools/commit/955dd23e5ac6e539e3ecb809f420b0b23f6caffd))
* resolve all credo warnings ([9f7c456](https://github.com/szTheory/oban_powertools/commit/9f7c4569564aaa1b4280d9fc0f8fea3040ac1e5d))
* **v1.9:** apply code review fixes for DoS, logic bug, and spin-loop ([3ed5da2](https://github.com/szTheory/oban_powertools/commit/3ed5da2ad7188eb21801d3b5dd73f885a1229f2f))


### Dependencies

* **deps:** bump oban_web from 2.12.4 to 2.12.5 ([#7](https://github.com/szTheory/oban_powertools/issues/7)) ([9c8eb03](https://github.com/szTheory/oban_powertools/commit/9c8eb03696306da55fcea6dd56e8f9cd71f92a4b))


### Documentation

* **43-01:** complete plan 01 data+helper contract layer ([c87cf8e](https://github.com/szTheory/oban_powertools/commit/c87cf8e9fc5f7e5ccec399a3bf6562c3b8d75724))
* **43-02:** complete plan 02 JobsLive route, auth atoms, and integration tests ([0dfed90](https://github.com/szTheory/oban_powertools/commit/0dfed906d62c11acd87c4cccd4ea231fc398f658))
* **43-03:** complete plan 03 job detail view ([cb43da0](https://github.com/szTheory/oban_powertools/commit/cb43da0ae8fbb239fa21814da9e13e13e6483da5))
* **43:** add code review report ([6db7186](https://github.com/szTheory/oban_powertools/commit/6db7186d83872585c5d6369326b9ac29e8dea6e8))
* **43:** capture phase context ([938cb71](https://github.com/szTheory/oban_powertools/commit/938cb719c9e57195f0067312d36062e6c90bcaa7))
* **43:** create phase plan ([801ca75](https://github.com/szTheory/oban_powertools/commit/801ca75c1a4e1e421a1d012da412793887fe5a7f))
* **43:** fix UI-SPEC typography weight constraint and add focal point + error copy ([bfd8215](https://github.com/szTheory/oban_powertools/commit/bfd8215181904152713a2f47d5e6b282fb38580c))
* **43:** research phase domain ([7d343e1](https://github.com/szTheory/oban_powertools/commit/7d343e1fdbf9873aa26ebbdd6459825d1e73fa9e))
* **43:** UI design contract ([1d7aaeb](https://github.com/szTheory/oban_powertools/commit/1d7aaeb6974347db390f8338135a7c99a68e544c))
* **43:** UI design contract for read-only job browse ([2a0192c](https://github.com/szTheory/oban_powertools/commit/2a0192c6b2f65297ffff8fe67d4d5c39287fac2d))
* **44-single-job-actions:** create phase plan .planning/phases/44-single-job-actions/44-01-PLAN.md .planning/phases/44-single-job-actions/44-02-PLAN.md .planning/ROADMAP.md ([750dc80](https://github.com/szTheory/oban_powertools/commit/750dc809deaff34c6d33e548a7f231081476cd62))
* **46-01:** complete operator-elixir-api plan 01 ([eeb4e04](https://github.com/szTheory/oban_powertools/commit/eeb4e047033d89b6a30f59caca21b4978ae0cb17))
* **46-02:** complete bulk operations plan .planning/phases/46-operator-elixir-api/46-02-SUMMARY.md .planning/STATE.md .planning/ROADMAP.md .planning/REQUIREMENTS.md ([625cd90](https://github.com/szTheory/oban_powertools/commit/625cd901e021fdc96dffed81ff8b3c589158096f))
* **46-operator-elixir-api:** create phase plan .planning/phases/46-operator-elixir-api/46-01-PLAN.md .planning/phases/46-operator-elixir-api/46-02-PLAN.md .planning/ROADMAP.md ([c2dbf60](https://github.com/szTheory/oban_powertools/commit/c2dbf6024d615bbed252168e522f6f6b51a69951))
* **47-01:** add verbatim Apache-2.0 LICENSE file at repo root ([4aa85f0](https://github.com/szTheory/oban_powertools/commit/4aa85f05caaf0a3bed5e57d37642b1fbbce95f3b))
* **47-01:** author CHANGELOG.md with 0.5.0 entry and path-to-1.0 gate ([2362167](https://github.com/szTheory/oban_powertools/commit/2362167bc1a05a2bbe6b09f918d8204bab0a6152))
* **47-01:** complete CHANGELOG.md and LICENSE plan ([a61ad31](https://github.com/szTheory/oban_powertools/commit/a61ad31c2ccac73026dba044eb2db66cf9343017))
* **47-02:** bump install snippet to ~&gt; 0.5 and add 0.x stability banner ([b24cebc](https://github.com/szTheory/oban_powertools/commit/b24cebccc5cfa5ac2f040a1e040b745548eab56c))
* **47-02:** complete hex package config and ExDoc source links plan ([06f4c2e](https://github.com/szTheory/oban_powertools/commit/06f4c2e6205aacb7fa42a50241cf31a60d10867c))
* **47-03:** add 47-03 summary, mark plan 3/3 complete pending operator Task 5 ([cb93991](https://github.com/szTheory/oban_powertools/commit/cb93991a0c5816d23ef40245b6c1a06b3e7b13df))
* **47:** capture phase context ([30511cf](https://github.com/szTheory/oban_powertools/commit/30511cf023b37b8cc991b8ba9f098b78175fe6cf))
* **47:** create phase plan ([77d3a34](https://github.com/szTheory/oban_powertools/commit/77d3a3457b3ca65097454498c9b108913f601985))
* **47:** create phase plan ([38173f7](https://github.com/szTheory/oban_powertools/commit/38173f7ed0e59b7a5a81f62fc717f09bb756643a))
* **47:** research phase domain ([7d58839](https://github.com/szTheory/oban_powertools/commit/7d58839f0200742f67008092cd4d81cb54b7b54b))
* **48-01:** complete plan-01 doctor core summary ([3b32af8](https://github.com/szTheory/oban_powertools/commit/3b32af80e0e40332821aea433b4bb14ade7206c3))
* **48-02:** complete plan-02 doctor formatter + CLI summary ([5079363](https://github.com/szTheory/oban_powertools/commit/5079363dc03ee26103af94241e376650cefc9ff5))
* **48:** add code review report ([f948528](https://github.com/szTheory/oban_powertools/commit/f9485283f712b7116b5c649977b7c3bfd00060c7))
* **48:** add validation strategy ([f967af9](https://github.com/szTheory/oban_powertools/commit/f967af931a86778b242a5813fd0e498bd6017ae3))
* **48:** capture phase context ([96abfdc](https://github.com/szTheory/oban_powertools/commit/96abfdcc27f02c50d44e15b7e5923bdff5bc8507))
* **48:** create doctor health-check phase plan ([2181da6](https://github.com/szTheory/oban_powertools/commit/2181da62d0abcab6ea951709369a91f453017385))
* **48:** create phase plan ([1d2e2a9](https://github.com/szTheory/oban_powertools/commit/1d2e2a9a2d8f4f79b19c64a1077a4664db5475ee))
* **48:** research doctor health-check task ([6957b5d](https://github.com/szTheory/oban_powertools/commit/6957b5de980d70724ea308a9ddc13867e929a546))
* **49-01:** complete pure-core extraction and glossary plan ([2edc645](https://github.com/szTheory/oban_powertools/commit/2edc64542b6772feea879ce63bbaad815d7d2da9))
* **49-02:** add self-check result to SUMMARY.md ([00f1a9b](https://github.com/szTheory/oban_powertools/commit/00f1a9bcbf76132c4cd07536db615146633e5383))
* **49-02:** complete limiter.explain plan summary ([81422dc](https://github.com/szTheory/oban_powertools/commit/81422dcc6c4075636f2b0af73a19de5d3a1594ed))
* **49-03:** complete limiter simulate CLI plan (OPS-07/OPS-08) ([4fcaf8d](https://github.com/szTheory/oban_powertools/commit/4fcaf8da0b075dfb36ce01c3f7600856d71b0ef4))
* **49:** capture phase context ([2f28432](https://github.com/szTheory/oban_powertools/commit/2f28432da230afe96ab81aef49d13a33bb753c3c))
* **49:** create phase plan ([f2c0c1d](https://github.com/szTheory/oban_powertools/commit/f2c0c1d3c4355f9fe6b3c77b3a8437323f3489db))
* **49:** create phase plan ([ad73394](https://github.com/szTheory/oban_powertools/commit/ad733945026cd75759e6f30260d413747d5b7a41))
* **49:** research limiter explain/simulate CLI phase ([9523292](https://github.com/szTheory/oban_powertools/commit/952329297f090130e92da2a9dc4220e5a968e413))
* **50-01:** complete Wave 0 foundation plan ([0919eea](https://github.com/szTheory/oban_powertools/commit/0919eea28d025cacfc6d033f32046ab96a493ac5))
* **50-02:** complete metrics/0 implementation plan summary ([f6ed3a7](https://github.com/szTheory/oban_powertools/commit/f6ed3a7ef4081c8f3946672dd207607b45b4f671))
* **50-03:** complete telemetry-and-slos guide plan ([c04e6a9](https://github.com/szTheory/oban_powertools/commit/c04e6a96cd50d20146a002488898465e9aad2e25))
* **50-03:** write 4-part telemetry-and-slos Operations guide (TEL-03) ([d64cb29](https://github.com/szTheory/oban_powertools/commit/d64cb298cb981008ed1488e5788ae40b91d30548))
* **50:** add code review report ([cf4d8ad](https://github.com/szTheory/oban_powertools/commit/cf4d8ad5a20d8eaff610ca95d779f417623aadd8))
* **50:** add pattern map ([5b1cd3c](https://github.com/szTheory/oban_powertools/commit/5b1cd3c8c5f157c5109a06884336ff48d9dbb708))
* **50:** add validation strategy ([3370081](https://github.com/szTheory/oban_powertools/commit/337008137f08cfb1e12b7beb535cbdf244df64c8))
* **50:** capture phase context ([1bf4764](https://github.com/szTheory/oban_powertools/commit/1bf4764db60e829d732b8119938c33076ccd5798))
* **50:** create phase plan ([5c1c179](https://github.com/szTheory/oban_powertools/commit/5c1c1793e9978408eaabe963b9eaf2ebf0246945))
* **50:** create phase plan ([9503c6c](https://github.com/szTheory/oban_powertools/commit/9503c6c17cf99255f7a9c1b6d8e23bd1f74292c5))
* **50:** research telemetry metrics and slo guide ([44a136c](https://github.com/szTheory/oban_powertools/commit/44a136c8144e354b89a6285ce29fe5bbf6d66efd))
* **51-01:** complete hex_consumer app scaffold plan ([c7527dd](https://github.com/szTheory/oban_powertools/commit/c7527dddbfa8a2a77b16c9060ac55ccdc061a724))
* **51-02:** complete first-session test and local proof plan ([091ebe1](https://github.com/szTheory/oban_powertools/commit/091ebe1ab26ef58de4173e60f8eedf7bdd4e9f18))
* **51-03:** complete verify-published CI job plan — REL-04 closed ([5e7257f](https://github.com/szTheory/oban_powertools/commit/5e7257f42ca92208b3286f1cf79fbac753b1e819))
* **51:** add code review report ([e978775](https://github.com/szTheory/oban_powertools/commit/e978775f365419a7549e8c133de13ed4ca8f3c1b))
* **51:** add pattern map ([358b147](https://github.com/szTheory/oban_powertools/commit/358b147f4cbeaca9a3acb706b8d8c6c1ad37da49))
* **51:** capture phase context ([28390ca](https://github.com/szTheory/oban_powertools/commit/28390cad1f05f24c156ff2ef7a3d331377a88a52))
* **51:** create phase plan ([b2b0a81](https://github.com/szTheory/oban_powertools/commit/b2b0a81c96ee4beecb5023121f40ef6a0fd7ce36))
* **51:** research published-package verification phase ([3da9995](https://github.com/szTheory/oban_powertools/commit/3da9995fa419d158e7e77faf9f487f17c5ced075))
* **52-01:** add plan execution summary ([f5aa347](https://github.com/szTheory/oban_powertools/commit/f5aa3470b4d12966058bb2a2de92deebead3f7bf))
* **52.1-01:** create SUMMARY.md for plan 52.1-01 ([4622508](https://github.com/szTheory/oban_powertools/commit/46225086c3dfa629ce9585b16c58ffca91a8e204))
* **52.1:** add code review report ([6281c19](https://github.com/szTheory/oban_powertools/commit/6281c197dffbbda203e5b6277059ada8a5c88793))
* **52.1:** capture phase context ([175e610](https://github.com/szTheory/oban_powertools/commit/175e610431d41f653bb869a05d04e49b6a603ef6))
* **52.1:** create phase plan ([2aed841](https://github.com/szTheory/oban_powertools/commit/2aed84123d364024b892e2036a20888a232b3ad2))
* **52.1:** create phase plan ([09c5d53](https://github.com/szTheory/oban_powertools/commit/09c5d53c1e93692930ebd0cb399891df696ff460))
* **52:** add code review report ([17d0d96](https://github.com/szTheory/oban_powertools/commit/17d0d96ee651023399d9fe242a3502db41ca01b0))
* **52:** add validation strategy ([1a2a638](https://github.com/szTheory/oban_powertools/commit/1a2a638227e0828e23e61bb83205b69ed63a3fda))
* **52:** capture phase context ([904ff2a](https://github.com/szTheory/oban_powertools/commit/904ff2ac1df4825319a4c0ef884cd54426df4a38))
* **52:** create phase plan ([22aa311](https://github.com/szTheory/oban_powertools/commit/22aa3110cc6ca022bfd7b5eaf00d868f288d2ac3))
* **52:** create zero-touch release automation phase plan ([5c9b6a7](https://github.com/szTheory/oban_powertools/commit/5c9b6a7545379286dcf626434cb96d62dac9a407))
* **52:** research phase domain ([d92f6e4](https://github.com/szTheory/oban_powertools/commit/d92f6e49f20ff01c53fbbd857eb3377e9d2ce138))
* **53-01:** complete worker lifecycle runtime plan ([39a0967](https://github.com/szTheory/oban_powertools/commit/39a0967dcb1bb239ad4c0f9aca15bb7a3bc1d817))
* **53-02:** complete worker lifecycle docs plan ([f9a8837](https://github.com/szTheory/oban_powertools/commit/f9a88377ff993564f0bb548c270878e1ff7cb1ca))
* **53-02:** document worker hook telemetry metric ([9b09241](https://github.com/szTheory/oban_powertools/commit/9b09241b7dd5cbd0faf2893681f3cf54440f086f))
* **53-02:** document worker lifecycle hook support truth ([30581d6](https://github.com/szTheory/oban_powertools/commit/30581d6dd5856da7393d1b73241b184aae7f77b7))
* **53:** add code review report ([02e8e0c](https://github.com/szTheory/oban_powertools/commit/02e8e0c3a06cef82ebd4e508532694ff57634bc4))
* **53:** add pattern map ([919d679](https://github.com/szTheory/oban_powertools/commit/919d679cdbb19e44ed8b08f7ae2df379242fcd5d))
* **53:** capture phase context ([2876f2f](https://github.com/szTheory/oban_powertools/commit/2876f2f05020cdb4b6e56c97d21f6878fdb339bb))
* **53:** create phase plan ([40c0c5d](https://github.com/szTheory/oban_powertools/commit/40c0c5d37ae86a57684c039bd3249fad59cf8566))
* **53:** finalize phase planning gates ([200775d](https://github.com/szTheory/oban_powertools/commit/200775d36cce7cf49f3241a39d7fe6fe61b91d64))
* **53:** research worker lifecycle hooks ([216ce16](https://github.com/szTheory/oban_powertools/commit/216ce1677209c47d2766ff24f65019fbffdea475))
* **53:** revise plan checker feedback ([9ec85b9](https://github.com/szTheory/oban_powertools/commit/9ec85b99274a10a7b88d163ded74effdc42a4999))
* **54-01:** complete worker timeout and deadline plan ([4a8a76a](https://github.com/szTheory/oban_powertools/commit/4a8a76a2ef41cad9e47d9ce695c09959a11aafc6))
* **54-02:** complete enqueue deadline metadata plan ([9717fc8](https://github.com/szTheory/oban_powertools/commit/9717fc819c8c356933f74df5ef96521bd33f3d8b))
* **54-03:** complete Doctor expired deadline plan ([a9e9906](https://github.com/szTheory/oban_powertools/commit/a9e990690bf40f9e4953b9078e16e2781e445cb7))
* **54-04:** complete support-truth docs plan ([1c82ebc](https://github.com/szTheory/oban_powertools/commit/1c82ebc321b78a99b1b70b81a4bc49650e797daa))
* **54-04:** document Doctor expired deadline warnings ([7be3455](https://github.com/szTheory/oban_powertools/commit/7be3455da100d880178909a32a9e41fb0e891555))
* **54-04:** document worker timeout and deadline semantics ([526c975](https://github.com/szTheory/oban_powertools/commit/526c9756ff714044ab42d0df72f65e4edde0dc52))
* **54:** add code review report ([8848a3c](https://github.com/szTheory/oban_powertools/commit/8848a3c56484589ab44b2d717b3c832a31035dcb))
* **54:** add pattern map ([daa997f](https://github.com/szTheory/oban_powertools/commit/daa997fc11a84bbd9ccfcf96204f85c510687464))
* **54:** capture phase context ([4b12891](https://github.com/szTheory/oban_powertools/commit/4b12891aa9bfde6754fe9589dc22ad197a254a7e))
* **54:** complete phase execution ([9babacd](https://github.com/szTheory/oban_powertools/commit/9babacdf045835aed0abccd86348b5c745309e49))
* **54:** create deadline timeout phase plans ([7ffc41d](https://github.com/szTheory/oban_powertools/commit/7ffc41d0801f9a83042a4151846a908c6e5accea))
* **54:** finalize phase plan ([e6ee0d2](https://github.com/szTheory/oban_powertools/commit/e6ee0d2c4ec59c579ceb6284ef687a037f2ed3d5))
* **54:** research deadline timeout pass-through ([0a3283a](https://github.com/szTheory/oban_powertools/commit/0a3283a428d755844d6906732c4a99289cecf91c))
* **55-01:** complete job record storage plan ([0dbe8af](https://github.com/szTheory/oban_powertools/commit/0dbe8af3acea6e50b2b5f1bcc4cd919262bef39b))
* **55-02:** complete worker recording injection plan ([e605a3e](https://github.com/szTheory/oban_powertools/commit/e605a3ec92e13a3adbe317a978c492eb15d1f833))
* **55-03:** complete jobs live recorded output plan ([ed50b70](https://github.com/szTheory/oban_powertools/commit/ed50b70d894d06efa5cbc36cad7b2121d62e45a5))
* **55-04:** complete lifeline job record pruning plan ([95f30fc](https://github.com/szTheory/oban_powertools/commit/95f30fc785b735da36ad5e8d33db9642a0752afc))
* **55-04:** document JobRecord output support truth ([6b92218](https://github.com/szTheory/oban_powertools/commit/6b9221820f07c391d276ad6ac51ad7fe53e8b32f))
* **55:** add code review report ([c0db27a](https://github.com/szTheory/oban_powertools/commit/c0db27aa29de4c5212d84a72f16469234d2f8ebf))
* **55:** capture phase context ([8f75460](https://github.com/szTheory/oban_powertools/commit/8f7546044cc93ef368222fe34d5b107067989027))
* **55:** create phase plan ([8dc9403](https://github.com/szTheory/oban_powertools/commit/8dc94037de4c3d3034be979cd0bdb637315875bb))
* **55:** research output recording jobrecord ([bd7d3bd](https://github.com/szTheory/oban_powertools/commit/bd7d3bd9e0aeae373b887db30dcc7bf0a3d8f881))
* **56-01:** complete redaction engine plan summary ([5d2cccb](https://github.com/szTheory/oban_powertools/commit/5d2cccbd3d37194886a8cc03e85d8f80227b835a))
* **56-02:** complete cron-path redaction plan ([8f27b8f](https://github.com/szTheory/oban_powertools/commit/8f27b8fbe44dd2c52bd83e37805e4a26c76fc91e))
* **56-03:** complete redaction display and disclosure plan ([3505956](https://github.com/szTheory/oban_powertools/commit/35059564ffa52051bb4139325a978b82fafee7a2))
* **56-04:** complete redact: support-truth documentation plan ([c8606be](https://github.com/szTheory/oban_powertools/commit/c8606beec2128df4459736c49ba8402b246703b9))
* **56:** add code review report ([3216ee8](https://github.com/szTheory/oban_powertools/commit/3216ee86d3f67cb9d36ac403e20f5b6ef7edfe1f))
* **56:** add code review report ([4153566](https://github.com/szTheory/oban_powertools/commit/4153566382e626e2aea2822ccc742486543bd1d9))
* **56:** apply plan-check revisions (OQ resolution, traceability, test tightening) ([9510b8f](https://github.com/szTheory/oban_powertools/commit/9510b8f885358f5341d00dbf608124f0835830d0))
* **56:** capture phase context ([f4560ae](https://github.com/szTheory/oban_powertools/commit/f4560aec771d37be5c51ea91c6f0072c1c9b072a))
* **56:** create phase plan ([04c1fba](https://github.com/szTheory/oban_powertools/commit/04c1fba2cc9df990ed5a0290da6c899a4894c6e3))
* **56:** create phase plan (decision coverage citations, state, roadmap) ([32716e3](https://github.com/szTheory/oban_powertools/commit/32716e395e9bf5a1559995c4ace8e6cbf63c500b))
* **56:** research phase redaction domain ([a06387a](https://github.com/szTheory/oban_powertools/commit/a06387a8ba365daa392c13b67814f43d09ec9206))
* **56:** UI design contract ([7180ae7](https://github.com/szTheory/oban_powertools/commit/7180ae772ee5f9b7ff7bfd625ddec0f4f015980a))
* **57-01:** complete doctor manifest fix plan summary ([9e50ee6](https://github.com/szTheory/oban_powertools/commit/9e50ee655efcec542a094302a460101c139964e3))
* **57:** add code review report ([a079fa9](https://github.com/szTheory/oban_powertools/commit/a079fa98d76f13540fea6ad94d732c5b1857b982))
* **57:** add validation strategy, patterns, and update state ([432e08f](https://github.com/szTheory/oban_powertools/commit/432e08fcd170bb77db42c6f2971aab3d46f9027e))
* **57:** capture phase context ([c761e4b](https://github.com/szTheory/oban_powertools/commit/c761e4ba7f8925ea7e2f675c587f47cfd60cf6fd))
* **57:** create phase plan ([c163a1c](https://github.com/szTheory/oban_powertools/commit/c163a1c49039dfae6ea742417f79b58acd84b632))
* **57:** research phase domain ([106ffb8](https://github.com/szTheory/oban_powertools/commit/106ffb8bf3930cf13077902c38ee1167bcf3b985))
* **58:** capture phase context ([16c9e08](https://github.com/szTheory/oban_powertools/commit/16c9e081ac06c4e7c22d37e983e36b05865a636d))
* **58:** create phase plan ([4b448c3](https://github.com/szTheory/oban_powertools/commit/4b448c3c34fb22c2770519141012ef540787d9fc))
* **59:** capture phase context ([5e96094](https://github.com/szTheory/oban_powertools/commit/5e96094813de0052c20ce6a7af414b5bae63159b))
* **59:** create phase plan ([4a93fce](https://github.com/szTheory/oban_powertools/commit/4a93fce160754fbdc9db2596aa79f43c9edc9df0))
* **60-01:** complete batch completion timestamp plan ([c2babc0](https://github.com/szTheory/oban_powertools/commit/c2babc0ccf7ebbe09622ef6fa46a76ef5e2f0025))
* **60-02:** complete batch tracker plan ([cf6a4cb](https://github.com/szTheory/oban_powertools/commit/cf6a4cbef67b0b6ef99d5eef84ff01c145ccce5d))
* **60-03:** complete worker hook tracker plan ([eae7e72](https://github.com/szTheory/oban_powertools/commit/eae7e723e6187da83223ad5f461aaa00b47c74c5))
* **60:** add phase review and verification ([995472d](https://github.com/szTheory/oban_powertools/commit/995472d6622b58d0aa7b066e5d97961690c8a758))
* **60:** capture phase context ([ba5b03e](https://github.com/szTheory/oban_powertools/commit/ba5b03ea6ef4c2290dde9c24ff65d22dc9a12277))
* **60:** UI design contract ([332f909](https://github.com/szTheory/oban_powertools/commit/332f9098354ee06635ff5bb6b33794874bd20b06))
* **60:** UI design contract ([1202b50](https://github.com/szTheory/oban_powertools/commit/1202b503b8299e714d708e4701bbd9cb5435bf5a))
* **60:** UI design contract updates ([b5ffdb8](https://github.com/szTheory/oban_powertools/commit/b5ffdb832eb91090c61c09866bab9126027d000a))
* **61-01:** complete durable batch metadata summary ([d578554](https://github.com/szTheory/oban_powertools/commit/d578554b363f560b6e6942c3d110914613d64217))
* **61-01:** update planning state for durable batch metadata ([bcfc695](https://github.com/szTheory/oban_powertools/commit/bcfc695cffab10bfb25fd7c63f7707880390bff5))
* **61-02:** complete batch insert stream summary ([9d99313](https://github.com/szTheory/oban_powertools/commit/9d99313fe4ccd1ddf0016bc0f61e4b596d7f621a))
* **61-02:** update planning state for batch insert stream ([20f62e2](https://github.com/szTheory/oban_powertools/commit/20f62e2b0f6f1ef3abff1c2073501ef7b3c8298b))
* **61-03:** complete chain DSL plan ([11e833b](https://github.com/szTheory/oban_powertools/commit/11e833bb9be00200bab36cafb69e1823de05a891))
* **61-04:** complete chain progression summary ([55cceab](https://github.com/szTheory/oban_powertools/commit/55cceabc4c238eba5c28af11805a196569c28019))
* **61-04:** update planning state for chain progression ([46d669f](https://github.com/szTheory/oban_powertools/commit/46d669fd45bc0b14e1dae1a05facccee13864e3f))
* **61-05:** complete durable chain output handoff plan ([9f02a9e](https://github.com/szTheory/oban_powertools/commit/9f02a9ef6bd22cc0d6c04da6418ea74c880af660))
* **61:** add code review report ([15a939e](https://github.com/szTheory/oban_powertools/commit/15a939e18c4ba5a5823ab32a6e615a8d5df3d1af))
* **61:** capture phase context ([ef12082](https://github.com/szTheory/oban_powertools/commit/ef1208272c35501a451a17bd835b3c1832588c28))
* **61:** create phase plan ([57e0184](https://github.com/szTheory/oban_powertools/commit/57e0184e88789cfaf6a81cb386b82b511978133a))
* **61:** finalize clean code review report ([44d9a35](https://github.com/szTheory/oban_powertools/commit/44d9a357c4dfebe126063c94d4befacacaa19c94))
* **61:** record phase planning state ([43928f9](https://github.com/szTheory/oban_powertools/commit/43928f9577a75992a77983dc045866a614f4189f))
* **61:** research phase domain ([80bf749](https://github.com/szTheory/oban_powertools/commit/80bf7494e64a7667b384e19f8c79ea74971194f3))
* **62-01:** complete validation scaffold plan ([8fdbec8](https://github.com/szTheory/oban_powertools/commit/8fdbec8432e8cff27a8cb6f33c200fb1deae9fa5))
* **62-02:** complete routes selectors auth plan ([c107405](https://github.com/szTheory/oban_powertools/commit/c107405ccc56dc696457ae6becdc1d773141547c))
* **62-03:** complete Batches read model plan ([4797de9](https://github.com/szTheory/oban_powertools/commit/4797de98742fda5ad69726129746540d4446ce37))
* **62-04:** complete Lifeline callback retry plan ([1bb965f](https://github.com/szTheory/oban_powertools/commit/1bb965f462fb3cbab82c4510d41b48e11627d6be))
* **62-05:** complete native batches LiveView plan ([c87f476](https://github.com/szTheory/oban_powertools/commit/c87f4765a12374901f0402f56dfb4a577224fe85))
* **62:** capture phase context ([9f84146](https://github.com/szTheory/oban_powertools/commit/9f841466655346396fa968c7fc80583069220089))
* **62:** create phase plan ([f409bb7](https://github.com/szTheory/oban_powertools/commit/f409bb7deb18b4feb48358360364ee98a4c52e5b))
* **62:** create phase plan ([454907e](https://github.com/szTheory/oban_powertools/commit/454907eb7a8cec954e669b5a2cd47fa3e8f4d742))
* **62:** map implementation patterns ([625df96](https://github.com/szTheory/oban_powertools/commit/625df96a9da744ea8f3b5ddc1a0bec5e28cfe89f))
* **62:** research phase domain ([fbf7c9a](https://github.com/szTheory/oban_powertools/commit/fbf7c9ab006d2048e1e35b07750fa06fd42bf985))
* **62:** UI design contract ([1130e8e](https://github.com/szTheory/oban_powertools/commit/1130e8e96d250216292ec6a5884d972b78d80143))
* **63-01:** complete Close gap: runtime callback and chain progression consumers plan ([95e33a6](https://github.com/szTheory/oban_powertools/commit/95e33a659340d61eaa9770b8b3ccdca91082d67e))
* **64-02:** complete args-meta-filtering plan ([72c62aa](https://github.com/szTheory/oban_powertools/commit/72c62aaf24c76154eb683c526ab68135c0855fc0))
* **64:** complete phase 64 ([8f78a49](https://github.com/szTheory/oban_powertools/commit/8f78a494b80c67f0489fe4d1785de91263146fd9))
* **64:** create phase plan ([4b19513](https://github.com/szTheory/oban_powertools/commit/4b1951327888a9b4a91366e6f695915f630874fa))
* **67:** create phase plan ([a5e9ed7](https://github.com/szTheory/oban_powertools/commit/a5e9ed751e7f43ca220f66fd8868760a02b213df))
* **68-01:** link powertools vs oban pro guide in mix.exs ([287328b](https://github.com/szTheory/oban_powertools/commit/287328b487df0f6fa62d0d8f52cc35adb9235c01))
* **68-01:** update 1.0 upgrade guide ([6cba85e](https://github.com/szTheory/oban_powertools/commit/6cba85ee0292546b2f61a2cc58c2cb85bf0f39dc))
* **68-01:** write powertools vs oban pro feature matrix ([5c11988](https://github.com/szTheory/oban_powertools/commit/5c119881dab6259a95dbf1ed5be2bdf48962636c))
* **changelog:** populate [Unreleased] with doctor, limiter CLI, and telemetry additions ([3f2d473](https://github.com/szTheory/oban_powertools/commit/3f2d473a11463b542ab5379e24d282cff65b5660))
* complete project research ([a44b568](https://github.com/szTheory/oban_powertools/commit/a44b568dde8fae69062be44103d9c14053a35007))
* complete v1.10 milestone audit and requirements traceability ([70a5aa9](https://github.com/szTheory/oban_powertools/commit/70a5aa996fc0be52143666b966fce1ee0791a80d))
* create milestone v1.5 roadmap (4 phases, 6 requirements) ([b04f06e](https://github.com/szTheory/oban_powertools/commit/b04f06ed623beb5495e5292f43526dc2b38361e7))
* create milestone v1.6 roadmap (5 phases) ([cf763fb](https://github.com/szTheory/oban_powertools/commit/cf763fb9855446c0681ed255912f4c887c0bb335))
* create milestone v1.7 roadmap (4 phases) ([8d62402](https://github.com/szTheory/oban_powertools/commit/8d62402650afe585a8104d4bbe9d7962c142a950))
* create milestone v1.8 roadmap (2 phases) ([78e8bca](https://github.com/szTheory/oban_powertools/commit/78e8bcaae11f748513892e6678777a491ee832e4))
* create milestone v1.9 roadmap (4 phases) ([c8a68be](https://github.com/szTheory/oban_powertools/commit/c8a68be91a4b957396146336117ee1e8550210a8))
* define milestone v1.5 requirements (QRY-01..04, API-01..02) ([dda12e8](https://github.com/szTheory/oban_powertools/commit/dda12e8bf2edce6b964439b42afc316b134438c3))
* define milestone v1.6 requirements ([b84b860](https://github.com/szTheory/oban_powertools/commit/b84b860f84267170f14a390b89bc48d5ab8fe55d))
* define milestone v1.7 requirements ([d86c829](https://github.com/szTheory/oban_powertools/commit/d86c82997eec3c2cd1ef11e5c94aba2cdfaefbfb))
* define milestone v1.8 requirements ([c049010](https://github.com/szTheory/oban_powertools/commit/c0490105f79adcaeb1a6fe0a7356730a55a77201))
* define milestone v1.9 requirements ([83bdbeb](https://github.com/szTheory/oban_powertools/commit/83bdbebf99274608e4708edf3b5a299df2a1eade))
* finalize Phase 68 documentation changes ([431d63e](https://github.com/szTheory/oban_powertools/commit/431d63eaad3a6aec1750ca2de5e16f2e1bcb6a4f))
* finalize v1.10 milestone assessment and configure v1.11 scope ([f6204c2](https://github.com/szTheory/oban_powertools/commit/f6204c20c1ab0bdd5bcb83de2e6d40340c01ce70))
* finalize v1.11 milestone audit ([0f5ded5](https://github.com/szTheory/oban_powertools/commit/0f5ded572d04f4669308e13438cafc517ed5fcb1))
* finalize v1.6 PITFALLS research ([6397f3e](https://github.com/szTheory/oban_powertools/commit/6397f3e62d3cabb18988934fb377315496151a8d))
* generate feature-freeze handoff artifact ([004df98](https://github.com/szTheory/oban_powertools/commit/004df98cea233b1cb441c9aad4ef2e04134b144c))
* generate handoff artifact for 1.0 publish ([26adc25](https://github.com/szTheory/oban_powertools/commit/26adc25e16492ae8e977a6fb870cc9b2cb5d4678))
* generate plan for Phase 68 ([1a8c2af](https://github.com/szTheory/oban_powertools/commit/1a8c2af122093155960c0d7039cf00db6d8c8d02))
* generate plan for Phase 69 (1.0 release) ([98d1c35](https://github.com/szTheory/oban_powertools/commit/98d1c350d52201b35b012f410f261fb68dcdefef))
* generate plans for Phase 67 ([c843384](https://github.com/szTheory/oban_powertools/commit/c84338427f3999cd6732c9f6df956450019f2145))
* generate post-1.0.0 end-of-roadmap assessment ([aaf7fc0](https://github.com/szTheory/oban_powertools/commit/aaf7fc04a824e746d70d95d564db97ca632ddbe8))
* initialize v1.11 Stability and 1.0 Release Prep milestone ([e198076](https://github.com/szTheory/oban_powertools/commit/e198076e15914064e347e362d3e03072429c8339))
* mark Phase 67 as complete ([052746f](https://github.com/szTheory/oban_powertools/commit/052746f6cecd951890adf9348f6af19cfe9e3a30))
* mark Phase 68 as complete ([c33f4e6](https://github.com/szTheory/oban_powertools/commit/c33f4e6314ec515e23c7e79833a309cd53a9a603))
* mark Phase 69 as complete ([0ae622e](https://github.com/szTheory/oban_powertools/commit/0ae622eaf3a52716dd1beab5d4203f5d5055fcac))
* **phase-42:** complete phase execution ([0a7453c](https://github.com/szTheory/oban_powertools/commit/0a7453c4cb45cb77ed066163eb87cbc814191712))
* **phase-42:** evolve PROJECT.md after phase completion ([191b497](https://github.com/szTheory/oban_powertools/commit/191b497f4a7ad83e7d23ab1df7500d3f01d675f0))
* **phase-43:** complete phase execution ([00e8ff5](https://github.com/szTheory/oban_powertools/commit/00e8ff559005ecbc04455ff54a58fcffc87063d9))
* **phase-43:** evolve PROJECT.md after phase completion ([6ae10bd](https://github.com/szTheory/oban_powertools/commit/6ae10bd430462133fd68ce92126df8dacc238f7f))
* **phase-43:** update tracking after wave 1 ([ea73a4a](https://github.com/szTheory/oban_powertools/commit/ea73a4a409f83ae4139e0222f1414909ebab1069))
* **phase-43:** update tracking after wave 2 ([a044329](https://github.com/szTheory/oban_powertools/commit/a04432900f856475640b6a8fb2959cd3cc729097))
* **phase-43:** update tracking after wave 3 ([bc7c8ac](https://github.com/szTheory/oban_powertools/commit/bc7c8ac6c57385fc5182fa6d098b17beabc7ea9e))
* **phase-47:** add validation strategy ([e9b4ec2](https://github.com/szTheory/oban_powertools/commit/e9b4ec2f0af2710c1aa3b176534975d91a2359d8))
* **phase-48:** add security threat verification ([1a9f01d](https://github.com/szTheory/oban_powertools/commit/1a9f01ddc0fb501161570188833f587b4c8a0d5b))
* **phase-48:** complete phase execution ([ce280ab](https://github.com/szTheory/oban_powertools/commit/ce280ab255111f4675d73394a28c244cd73e90dd))
* **phase-48:** evolve PROJECT.md after phase completion ([814702d](https://github.com/szTheory/oban_powertools/commit/814702dafa4687f7ee3aaf29c00aca2856d0d345))
* **phase-48:** reconcile validation strategy with executed phase (Nyquist-compliant, 0 gaps) ([7e8000c](https://github.com/szTheory/oban_powertools/commit/7e8000c4bf8b787009cc4cb746c0a6ab7a98a821))
* **phase-48:** update tracking after wave 1 ([aa53e09](https://github.com/szTheory/oban_powertools/commit/aa53e09351fff1dcce9635b03d10edd79a31afb5))
* **phase-48:** update tracking after wave 2 ([5575519](https://github.com/szTheory/oban_powertools/commit/5575519ce158d6ad2892dca18468a23f05802f64))
* **phase-49:** add code review findings ([a9a6a98](https://github.com/szTheory/oban_powertools/commit/a9a6a989f201bfa918a7e8d68fde55a1dd8b8297))
* **phase-49:** add security threat verification ([a72c12a](https://github.com/szTheory/oban_powertools/commit/a72c12a970d85d9b8582b5742192de245cc67f81))
* **phase-49:** add validation strategy ([0e21de4](https://github.com/szTheory/oban_powertools/commit/0e21de419fefc5159fa578440ed539b7fc206e59))
* **phase-49:** complete phase execution ([69a1b33](https://github.com/szTheory/oban_powertools/commit/69a1b3322938da98dc83c7fc7a22396e9e2228ff))
* **phase-49:** evolve PROJECT.md after phase completion ([c82e694](https://github.com/szTheory/oban_powertools/commit/c82e694107da811afb32ca1d28bf836eb087ef06))
* **phase-49:** mark code review findings resolved ([754dcc4](https://github.com/szTheory/oban_powertools/commit/754dcc433faf4bca0fa59091147e52310bbe82be))
* **phase-49:** reconcile validation strategy to green (audit, 0 gaps) ([46832d3](https://github.com/szTheory/oban_powertools/commit/46832d36c0390461821a85a0d59b1f987c76a03e))
* **phase-49:** update tracking after wave 1 ([041c87a](https://github.com/szTheory/oban_powertools/commit/041c87a4eb8284dae4a8d0a80d13f28bc728fbb8))
* **phase-49:** update tracking after wave 2 ([9f59317](https://github.com/szTheory/oban_powertools/commit/9f5931775fd01a9fe1092fcc67389d4344e04b30))
* **phase-50:** complete phase execution ([a115951](https://github.com/szTheory/oban_powertools/commit/a1159515679d142a448f7efea6c5f01bde13d22a))
* **phase-50:** evolve PROJECT.md after phase completion ([b5ddf69](https://github.com/szTheory/oban_powertools/commit/b5ddf6983ec2318b018f61792d9a483571a440bd))
* **phase-50:** update tracking after wave 1 ([a3927e5](https://github.com/szTheory/oban_powertools/commit/a3927e5f329a993fcd3aac65e4585cc455d87fdc))
* **phase-50:** update validation strategy — mark nyquist_compliant ([22b25d2](https://github.com/szTheory/oban_powertools/commit/22b25d27cba2d57b8ddaaf22ded68c5147241b10))
* **phase-51:** add validation strategy ([706f3ff](https://github.com/szTheory/oban_powertools/commit/706f3ffee7103ae83ced28039659eb2d057bc972))
* **phase-51:** complete phase execution ([f38638d](https://github.com/szTheory/oban_powertools/commit/f38638d8a7366e58384762faeeab644dae65d160))
* **phase-51:** evolve PROJECT.md after phase completion ([d57c9ab](https://github.com/szTheory/oban_powertools/commit/d57c9ab8c3f50168ab9ac0429b12972ebcfa0a61))
* **phase-51:** update tracking after wave 1 ([b858953](https://github.com/szTheory/oban_powertools/commit/b858953806b2e0b355a9bde47ff154e5f879f65d))
* **phase-51:** update tracking after wave 2 ([6df46ca](https://github.com/szTheory/oban_powertools/commit/6df46cac645502cdb070fed284d4f7954db31992))
* **phase-51:** update tracking after wave 3 ([4007aef](https://github.com/szTheory/oban_powertools/commit/4007aef10d6e5316159792bc2a4e0d9b3f7feb74))
* **phase-51:** update validation strategy — mark nyquist_compliant ([706c053](https://github.com/szTheory/oban_powertools/commit/706c053474c71487f84d9499cf1312efca36c3f2))
* **phase-52.1:** complete phase execution ([c97c5a3](https://github.com/szTheory/oban_powertools/commit/c97c5a3f9d8e1f493ef8e682edf54ab1a3f599c9))
* **phase-52.1:** evolve PROJECT.md after phase completion ([c32e364](https://github.com/szTheory/oban_powertools/commit/c32e36484cc0a5ce4d2aa394b22a1e8d6e21305c))
* **phase-52.1:** update tracking after wave 1 ([af2593d](https://github.com/szTheory/oban_powertools/commit/af2593dd6c4ce0dcb050a34b267f8143d13a9907))
* **phase-52:** add security threat verification ([64f17e6](https://github.com/szTheory/oban_powertools/commit/64f17e6b6c49cb84d6ed2a60fd310882104a252c))
* **phase-52:** complete phase execution ([b63df72](https://github.com/szTheory/oban_powertools/commit/b63df7291b997988898d9910e02a8201cf0baa63))
* **phase-52:** update tracking after wave 1 ([47b37cd](https://github.com/szTheory/oban_powertools/commit/47b37cdea8065fa0d6549635de6081adcc627385))
* **phase-52:** update validation strategy — mark nyquist-compliant ([b760380](https://github.com/szTheory/oban_powertools/commit/b760380a75cd93f7920fca2bc7482a00ece8e464))
* **phase-53:** add validation strategy ([439321b](https://github.com/szTheory/oban_powertools/commit/439321bbaa4195bc5f805860587ec9827ad3dd75))
* **phase-53:** complete phase execution ([acc88b0](https://github.com/szTheory/oban_powertools/commit/acc88b0091788241b0d8b0ad116441955e2d728f))
* **phase-53:** update validation strategy to complete with all requirements green ([c2c87fc](https://github.com/szTheory/oban_powertools/commit/c2c87fceea29851bb56e56e5380adc788ddbdf87))
* **phase-54:** add validation strategy ([57ecb9b](https://github.com/szTheory/oban_powertools/commit/57ecb9be02077f25d68ec96586790eb10b1af36d))
* **phase-55:** add validation strategy ([4976ac5](https://github.com/szTheory/oban_powertools/commit/4976ac5e5674a742bb18477b64018b24a691a6d4))
* **phase-55:** complete phase execution ([e297c9d](https://github.com/szTheory/oban_powertools/commit/e297c9da6a6fb63a06371b838c70b15b6b2288b9))
* **phase-56:** add pattern map ([7a4ce6d](https://github.com/szTheory/oban_powertools/commit/7a4ce6dbd0c6b02f0284821e6362182d0b13e077))
* **phase-56:** add validation strategy ([e9313cc](https://github.com/szTheory/oban_powertools/commit/e9313cc0610ba99250684b6c1ec443047943f6bc))
* **phase-56:** complete phase execution ([03a277f](https://github.com/szTheory/oban_powertools/commit/03a277f5e5c48dcd0c00a1f4d30360ccd0f2cf8c))
* **phase-56:** evolve PROJECT.md after phase completion ([df457fe](https://github.com/szTheory/oban_powertools/commit/df457fe1e816f873bf27abd8fd728fd9f6402945))
* **phase-56:** update tracking after wave 1 ([e950451](https://github.com/szTheory/oban_powertools/commit/e9504515538f000b55880aec4498a3a184d58142))
* **phase-56:** update tracking after wave 2 ([b24f3e9](https://github.com/szTheory/oban_powertools/commit/b24f3e94bb2bb25d4c63964db85a768701907396))
* **phase-57:** complete phase execution ([1c40c4a](https://github.com/szTheory/oban_powertools/commit/1c40c4a21a8f6fb0018cc478348b09c50977344e))
* **phase-57:** evolve PROJECT.md after phase completion ([1a50934](https://github.com/szTheory/oban_powertools/commit/1a5093462cde74a8a5e66385b88e1e74f4c62d47))
* **phase-57:** update tracking after wave 1 ([2b63954](https://github.com/szTheory/oban_powertools/commit/2b63954a3b2614ee3189b8f5f5a3bab72ff1b8d5))
* **phase-58:** add validation strategy ([1c809a6](https://github.com/szTheory/oban_powertools/commit/1c809a638c9af91ec83f9aa2e9698c5b486173d1))
* **phase-59:** add validation strategy ([8b3a22e](https://github.com/szTheory/oban_powertools/commit/8b3a22ed8e64bbeed346437f4508430c30cb53e0))
* **phase-59:** add/update validation strategy ([3aac84d](https://github.com/szTheory/oban_powertools/commit/3aac84d32e13f0ab6d9df4b23de7e82593250378))
* **phase-59:** complete phase execution ([00c56cc](https://github.com/szTheory/oban_powertools/commit/00c56cc296f85245d86dd7c90901a8e1ffd006b3))
* **phase-59:** evolve PROJECT.md after phase completion ([776a686](https://github.com/szTheory/oban_powertools/commit/776a686ffbd77a31a8765cb5e72b0fd73e008932))
* **phase-60:** add validation strategy ([d7deca0](https://github.com/szTheory/oban_powertools/commit/d7deca051b339aeb2967bd6cc62e67e9019079b5))
* **phase-60:** complete phase execution ([7c38300](https://github.com/szTheory/oban_powertools/commit/7c38300106479880f026601ff983f705a2e50551))
* **phase-60:** evolve PROJECT.md after phase completion ([19b133f](https://github.com/szTheory/oban_powertools/commit/19b133f334103b408e53c3e1419b73f3e971c39a))
* **phase-60:** update validation strategy ([eed6da0](https://github.com/szTheory/oban_powertools/commit/eed6da09c83c87c624a96a1862aa2534a336a3cb))
* **phase-61:** add validation strategy ([4d57fa5](https://github.com/szTheory/oban_powertools/commit/4d57fa5c7c795393fbe9243a0de4375c331dc825))
* **phase-61:** complete phase execution ([7cfd985](https://github.com/szTheory/oban_powertools/commit/7cfd9855e36301fa8bb509a56a6a4eb6ae72633e))
* **phase-61:** evolve PROJECT.md after phase completion ([7765abb](https://github.com/szTheory/oban_powertools/commit/7765abb71878d6668cf577e210b944fad8622663))
* **phase-61:** update validation audit ([45426ea](https://github.com/szTheory/oban_powertools/commit/45426eaa85713536cfd8cdd634951c753ce2c241))
* **phase-62:** add validation strategy ([7c80065](https://github.com/szTheory/oban_powertools/commit/7c8006583d4f8a7041104292bf2be4387de04211))
* **phase-63:** complete phase execution ([14d8425](https://github.com/szTheory/oban_powertools/commit/14d84257085ec7bc6c6deefdd93217e9983c736d))
* **phase-63:** evolve PROJECT.md after phase completion ([48c96d4](https://github.com/szTheory/oban_powertools/commit/48c96d4c33c952fda683a18792264e6f40c307ac))
* post-v1.4 adopter assessment and v1.5 ordering update ([66d113a](https://github.com/szTheory/oban_powertools/commit/66d113abc038b47e7307a166ac095c9f44ef4f92))
* post-v1.5 milestone assessment + next-step ordering ([9a13663](https://github.com/szTheory/oban_powertools/commit/9a136636eaa5f7a76ae9306403868e6aa4247d47))
* research for milestone v1.7 Worker Lifecycle & Safety ([d7870d0](https://github.com/szTheory/oban_powertools/commit/d7870d06e9081db16ac55edeec146120e9ca07a9))
* research for v1.8 Integration Fixes ([b7344a0](https://github.com/szTheory/oban_powertools/commit/b7344a00b7e69f916f9902ec4e86ad69fa1ee275))
* research milestone v1.6 Release & Operability ([7250d94](https://github.com/szTheory/oban_powertools/commit/7250d9425836a4ba9b612f390321eed8b18d5247))
* research v1.5 native job surface and operator API (4 dimensions + synthesis) ([3d7856d](https://github.com/szTheory/oban_powertools/commit/3d7856d825e58bb7b572b0e691a3e663560e51ac))
* start milestone v1.5 Native Job Surface & Automation API ([9080fd9](https://github.com/szTheory/oban_powertools/commit/9080fd952adafb58d32942a7f6614061ec2573d3))
* start milestone v1.6 Release & Operability ([4cea872](https://github.com/szTheory/oban_powertools/commit/4cea872c590407265db222398b8c1c2a8ec76048))
* start milestone v1.7 Worker Lifecycle & Safety ([024c9ab](https://github.com/szTheory/oban_powertools/commit/024c9abf00a9fb85e5c8b3108991df8de7a16e85))
* start milestone v1.8 Integration Fixes ([ccbf3cf](https://github.com/szTheory/oban_powertools/commit/ccbf3cf70e0b8dae03f2269fbcc7dde8ce06d232))
* start milestone v1.9 Batches & Composition ([972977c](https://github.com/szTheory/oban_powertools/commit/972977c6e14e3de7b0d1fcf67313e933c79c2248))
* **state:** align phase 53 hook routing ([3d345df](https://github.com/szTheory/oban_powertools/commit/3d345df9dc093adbd599e4ce5015a9828ed0bff6))
* **state:** fix phase 62 next action ([9962775](https://github.com/szTheory/oban_powertools/commit/9962775fc8c9a8299b609d5bd242d6aa734b245f))
* **state:** record phase 43 context session ([1cd0867](https://github.com/szTheory/oban_powertools/commit/1cd086738b66b8c08bba3b501bd1f3dcbab35a20))
* **state:** record phase 47 context session ([6e713d3](https://github.com/szTheory/oban_powertools/commit/6e713d3438c0b9f64627b96b12044ecca209f415))
* **state:** record phase 48 context session ([07ffb6d](https://github.com/szTheory/oban_powertools/commit/07ffb6d6d4f73fd6e318314c869931d39896c497))
* **state:** record phase 49 context session ([9be5555](https://github.com/szTheory/oban_powertools/commit/9be5555ba00c65b66eca366ff1970b791763f7da))
* **state:** record phase 50 context session ([521c937](https://github.com/szTheory/oban_powertools/commit/521c93775a6b30b7fe0a29c4d59fdd0a34b7f042))
* **state:** record phase 51 context session ([562d835](https://github.com/szTheory/oban_powertools/commit/562d835a3d97442b839d839b9dd7e57c961730fc))
* **state:** record phase 52 context session ([215e1cc](https://github.com/szTheory/oban_powertools/commit/215e1cce1e95b3242789fc16668ee8125aab9dd5))
* **state:** record phase 52.1 context session ([6cb1d89](https://github.com/szTheory/oban_powertools/commit/6cb1d89c712805a345f1d9db1f8736f7091bf53e))
* **state:** record phase 53 context session ([364057d](https://github.com/szTheory/oban_powertools/commit/364057d6b33f24f6cd2cd4944b6a3557f4cbfe81))
* **state:** record phase 54 context session ([c967169](https://github.com/szTheory/oban_powertools/commit/c967169b78c35aab6620f6c15843cc50f66a9833))
* **state:** record phase 55 context session ([f6b40ae](https://github.com/szTheory/oban_powertools/commit/f6b40ae0265d0359a0b18c7e92c2f1e79ad57702))
* **state:** record phase 56 context session ([20a2f31](https://github.com/szTheory/oban_powertools/commit/20a2f3134f4aed8c76fecec29200d5fb95f58619))
* **state:** record phase 57 context session ([f578917](https://github.com/szTheory/oban_powertools/commit/f5789177ac5ee82fc4ef6236f5dca35d8de0c9aa))
* **state:** record phase 58 context session ([0a0be69](https://github.com/szTheory/oban_powertools/commit/0a0be69fe0163a008dd23399ea2d74c1f6b49f00))
* **state:** record phase 59 context session ([a0482b9](https://github.com/szTheory/oban_powertools/commit/a0482b9935693d29682c47ff89b74c6f1ddcdf08))
* **state:** record phase 60 context session ([dd93de0](https://github.com/szTheory/oban_powertools/commit/dd93de0b65167eba79343914951978fd1bf65ff9))
* **state:** record phase 62 context session ([5d25c6e](https://github.com/szTheory/oban_powertools/commit/5d25c6eac55c48119034bd4df33e35af57fd5f45))
* **state:** record phase 62 context session ([6e349fa](https://github.com/szTheory/oban_powertools/commit/6e349fa52bf12146d73328bef8aa12e76e310b95))
* update retrospective for v1.5 ([9e59059](https://github.com/szTheory/oban_powertools/commit/9e59059b057c30231eed7d06ef6262a0019734db))
* **v1.4-audit:** close remaining artifact gaps — 11/11 phases, 11/11 Nyquist compliant ([b1a2f2d](https://github.com/szTheory/oban_powertools/commit/b1a2f2d467ea1419470f956eda5a12656c653bd7))
* **v1.4-audit:** re-audit after gap-closure phases 40-42 — 12/12 reqs satisfied ([23729b0](https://github.com/szTheory/oban_powertools/commit/23729b099853b9f6484aaa952611ffbb583eef7d))
* **v1.6:** insert phase 52.1 — close gap REL-04 verify-published CI fix ([c1d5a78](https://github.com/szTheory/oban_powertools/commit/c1d5a78268a917b44f0a1020102235ef906291f5))
* **v1.6:** milestone audit — gaps_found (3/13 satisfied, 3 phases unbuilt) ([7b45782](https://github.com/szTheory/oban_powertools/commit/7b45782f455ade285507d97f77557d9276110c6e))
* **v1.6:** re-audit milestone — 5/13 satisfied, hex 0.5.0 live, doctor not in published pkg ([50cb65b](https://github.com/szTheory/oban_powertools/commit/50cb65bd7aba8530b238c7508d1dc122bb9359d1))
* **v1.6:** re-audit milestone — Phase 49 built, 8/13 reqs satisfied, gaps_found ([2da44bd](https://github.com/szTheory/oban_powertools/commit/2da44bd3d201ada0bb662af62b405a881e344695))
* **v1.6:** update milestone audit — all 6 phases built, gaps_found (REL-04 broken, 47 unverified) ([fb241f0](https://github.com/szTheory/oban_powertools/commit/fb241f022066f758a28e0d99661ed78fb7198fe9))


### Miscellaneous

* bootstrap release-please at 0.5.0 ([#9](https://github.com/szTheory/oban_powertools/issues/9)) ([72b45aa](https://github.com/szTheory/oban_powertools/commit/72b45aa0d9c6e2f1193196c72c5de4d62c249909))

## [0.5.1](https://github.com/szTheory/oban_powertools/compare/v0.5.0...v0.5.1) (2026-05-30)


### Features

* **48-01:** implement index, migration-version, and powertools-table checks ([0489cb3](https://github.com/szTheory/oban_powertools/commit/0489cb3363bc5529c6ae3373479054c9d1e9a94f))
* **48-02:** implement Doctor.Formatter - human ANSI-degrading + JSON schema_version:1 output ([1c03bc1](https://github.com/szTheory/oban_powertools/commit/1c03bc1ce50fc47a87f205b768dd977455ae388a))
* **48-02:** implement Mix.Tasks.ObanPowertools.Doctor - flags, repo/prefix resolution, with_repo boot, exit codes ([e4b11a4](https://github.com/szTheory/oban_powertools/commit/e4b11a418d59d0ffc6c623db11ec2a99294e2970))
* **49-01:** add Glossary module with single-source rate-limit glossary string ([9586818](https://github.com/szTheory/oban_powertools/commit/95868185dbf3bf6c2ff1125c656858e9d8417e9a))
* **49-01:** extract pure compute_reservation/4 and refactor attempt_reservation/5 ([a83bc61](https://github.com/szTheory/oban_powertools/commit/a83bc615805289050f2b71995e35d37a0e7b9edd))
* **49-02:** add explain task tests + fix Module.safe_concat unknown-module guard ([ec55f37](https://github.com/szTheory/oban_powertools/commit/ec55f37e8916804ca7ae84cbaca9d12c78e1e2ee))
* **49-02:** create Mix.Tasks.ObanPowertools.Limiter.Explain ([be97468](https://github.com/szTheory/oban_powertools/commit/be974685e65948625254090970ef5eb1b12a84bf))
* **49-03:** add mix oban_powertools.limiter.simulate task (OPS-07) ([a4d9a7c](https://github.com/szTheory/oban_powertools/commit/a4d9a7cda2200050e710132cab0b379c4f796382))
* **50-02:** implement metrics/0 with Code.ensure_loaded? guard over frozen contract ([4820915](https://github.com/szTheory/oban_powertools/commit/482091585336f918439b9f64720c8a99a14c7803))
* **51-01:** create regenerate.sh maintainer companion with hex dep insertion ([354b839](https://github.com/szTheory/oban_powertools/commit/354b8396dfb7b43982b6a0d5339232d2e82d238a))
* **51-01:** scaffold hex_consumer config/, lib/, and host-owned seam modules ([f078b2e](https://github.com/szTheory/oban_powertools/commit/f078b2ea19e9a5bc7ddf84df08de4dd78e76843d))
* **51-01:** scaffold hex_consumer mix.exs, .formatter.exs, README, .gitignore ([da559c3](https://github.com/szTheory/oban_powertools/commit/da559c3cce3b9a7e79e76dadb90d64f65775f012))
* **51-02:** add test infrastructure and nightly_sync seed for hex_consumer ([a316de7](https://github.com/szTheory/oban_powertools/commit/a316de7310aeb7091399217641b46f41e7fd703f))
* **51-02:** create first-session test and missing web components for hex_consumer ([81b72e2](https://github.com/szTheory/oban_powertools/commit/81b72e21511daf6fb727221e9776362ad9a1414b))
* **51-03:** add verify-published job to release.yml (REL-04) ([a7a5e99](https://github.com/szTheory/oban_powertools/commit/a7a5e995c2092e4ab83a95638a58b0b92c7707b2))


### Bug Fixes

* **48-01:** wire [@eligible](https://github.com/eligible)_states constant into eligible-count query ([309bdda](https://github.com/szTheory/oban_powertools/commit/309bdda9e58630f0823990b8df168c6c8b7bf192))
* **48-02:** load app.config and harden --format mapping for real CLI runs ([2c1ec3e](https://github.com/szTheory/oban_powertools/commit/2c1ec3e3fbce8cf8b686635533793f183b8cd325))
* **48:** resolve code-review criticals — honest exit codes + safe parsing ([f6245e4](https://github.com/szTheory/oban_powertools/commit/f6245e422258df8dd46e91ad8b1245eac85a5fae))
* **48:** resolve research open questions + identifier-safe count query + DataCase test header ([c159517](https://github.com/szTheory/oban_powertools/commit/c1595172824166fffc5d2278f033a1c725c63787))
* **49:** address code review CR-01 + WR-01/02/03 (D-02 exit-code posture) ([357f68e](https://github.com/szTheory/oban_powertools/commit/357f68e47a7975134db97292dc591f911c079be0))
* **49:** inline D-08 glossary in explain [@moduledoc](https://github.com/moduledoc) for source-parity contract ([cd05b46](https://github.com/szTheory/oban_powertools/commit/cd05b46e2d3837c6da6bab1f344360400ae5b2d5))
* **49:** revise plans + validation/patterns/research per checker feedback ([18f98c7](https://github.com/szTheory/oban_powertools/commit/18f98c7041e53ace38a48859b8241ab6aed2d14a))
* **50-02:** replace import with apply/3 to fix prod-tree compile without telemetry_metrics ([8e87bdb](https://github.com/szTheory/oban_powertools/commit/8e87bdbae1e658821d05782e5c99bb19eb4e1593))


### Documentation

* **48-01:** complete plan-01 doctor core summary ([3b32af8](https://github.com/szTheory/oban_powertools/commit/3b32af80e0e40332821aea433b4bb14ade7206c3))
* **48-02:** complete plan-02 doctor formatter + CLI summary ([5079363](https://github.com/szTheory/oban_powertools/commit/5079363dc03ee26103af94241e376650cefc9ff5))
* **48:** add code review report ([f948528](https://github.com/szTheory/oban_powertools/commit/f9485283f712b7116b5c649977b7c3bfd00060c7))
* **48:** add validation strategy ([f967af9](https://github.com/szTheory/oban_powertools/commit/f967af931a86778b242a5813fd0e498bd6017ae3))
* **48:** capture phase context ([96abfdc](https://github.com/szTheory/oban_powertools/commit/96abfdcc27f02c50d44e15b7e5923bdff5bc8507))
* **48:** create doctor health-check phase plan ([2181da6](https://github.com/szTheory/oban_powertools/commit/2181da62d0abcab6ea951709369a91f453017385))
* **48:** create phase plan ([1d2e2a9](https://github.com/szTheory/oban_powertools/commit/1d2e2a9a2d8f4f79b19c64a1077a4664db5475ee))
* **48:** research doctor health-check task ([6957b5d](https://github.com/szTheory/oban_powertools/commit/6957b5de980d70724ea308a9ddc13867e929a546))
* **49-01:** complete pure-core extraction and glossary plan ([2edc645](https://github.com/szTheory/oban_powertools/commit/2edc64542b6772feea879ce63bbaad815d7d2da9))
* **49-02:** add self-check result to SUMMARY.md ([00f1a9b](https://github.com/szTheory/oban_powertools/commit/00f1a9bcbf76132c4cd07536db615146633e5383))
* **49-02:** complete limiter.explain plan summary ([81422dc](https://github.com/szTheory/oban_powertools/commit/81422dcc6c4075636f2b0af73a19de5d3a1594ed))
* **49-03:** complete limiter simulate CLI plan (OPS-07/OPS-08) ([4fcaf8d](https://github.com/szTheory/oban_powertools/commit/4fcaf8da0b075dfb36ce01c3f7600856d71b0ef4))
* **49:** capture phase context ([2f28432](https://github.com/szTheory/oban_powertools/commit/2f28432da230afe96ab81aef49d13a33bb753c3c))
* **49:** create phase plan ([f2c0c1d](https://github.com/szTheory/oban_powertools/commit/f2c0c1d3c4355f9fe6b3c77b3a8437323f3489db))
* **49:** create phase plan ([ad73394](https://github.com/szTheory/oban_powertools/commit/ad733945026cd75759e6f30260d413747d5b7a41))
* **49:** research limiter explain/simulate CLI phase ([9523292](https://github.com/szTheory/oban_powertools/commit/952329297f090130e92da2a9dc4220e5a968e413))
* **50-01:** complete Wave 0 foundation plan ([0919eea](https://github.com/szTheory/oban_powertools/commit/0919eea28d025cacfc6d033f32046ab96a493ac5))
* **50-02:** complete metrics/0 implementation plan summary ([f6ed3a7](https://github.com/szTheory/oban_powertools/commit/f6ed3a7ef4081c8f3946672dd207607b45b4f671))
* **50-03:** complete telemetry-and-slos guide plan ([c04e6a9](https://github.com/szTheory/oban_powertools/commit/c04e6a96cd50d20146a002488898465e9aad2e25))
* **50-03:** write 4-part telemetry-and-slos Operations guide (TEL-03) ([d64cb29](https://github.com/szTheory/oban_powertools/commit/d64cb298cb981008ed1488e5788ae40b91d30548))
* **50:** add code review report ([cf4d8ad](https://github.com/szTheory/oban_powertools/commit/cf4d8ad5a20d8eaff610ca95d779f417623aadd8))
* **50:** add pattern map ([5b1cd3c](https://github.com/szTheory/oban_powertools/commit/5b1cd3c8c5f157c5109a06884336ff48d9dbb708))
* **50:** add validation strategy ([3370081](https://github.com/szTheory/oban_powertools/commit/337008137f08cfb1e12b7beb535cbdf244df64c8))
* **50:** capture phase context ([1bf4764](https://github.com/szTheory/oban_powertools/commit/1bf4764db60e829d732b8119938c33076ccd5798))
* **50:** create phase plan ([5c1c179](https://github.com/szTheory/oban_powertools/commit/5c1c1793e9978408eaabe963b9eaf2ebf0246945))
* **50:** create phase plan ([9503c6c](https://github.com/szTheory/oban_powertools/commit/9503c6c17cf99255f7a9c1b6d8e23bd1f74292c5))
* **50:** research telemetry metrics and slo guide ([44a136c](https://github.com/szTheory/oban_powertools/commit/44a136c8144e354b89a6285ce29fe5bbf6d66efd))
* **51-01:** complete hex_consumer app scaffold plan ([c7527dd](https://github.com/szTheory/oban_powertools/commit/c7527dddbfa8a2a77b16c9060ac55ccdc061a724))
* **51-02:** complete first-session test and local proof plan ([091ebe1](https://github.com/szTheory/oban_powertools/commit/091ebe1ab26ef58de4173e60f8eedf7bdd4e9f18))
* **51-03:** complete verify-published CI job plan — REL-04 closed ([5e7257f](https://github.com/szTheory/oban_powertools/commit/5e7257f42ca92208b3286f1cf79fbac753b1e819))
* **51:** add code review report ([e978775](https://github.com/szTheory/oban_powertools/commit/e978775f365419a7549e8c133de13ed4ca8f3c1b))
* **51:** add pattern map ([358b147](https://github.com/szTheory/oban_powertools/commit/358b147f4cbeaca9a3acb706b8d8c6c1ad37da49))
* **51:** capture phase context ([28390ca](https://github.com/szTheory/oban_powertools/commit/28390cad1f05f24c156ff2ef7a3d331377a88a52))
* **51:** create phase plan ([b2b0a81](https://github.com/szTheory/oban_powertools/commit/b2b0a81c96ee4beecb5023121f40ef6a0fd7ce36))
* **51:** research published-package verification phase ([3da9995](https://github.com/szTheory/oban_powertools/commit/3da9995fa419d158e7e77faf9f487f17c5ced075))
* **changelog:** populate [Unreleased] with doctor, limiter CLI, and telemetry additions ([3f2d473](https://github.com/szTheory/oban_powertools/commit/3f2d473a11463b542ab5379e24d282cff65b5660))
* **phase-47:** add validation strategy ([e9b4ec2](https://github.com/szTheory/oban_powertools/commit/e9b4ec2f0af2710c1aa3b176534975d91a2359d8))
* **phase-48:** add security threat verification ([1a9f01d](https://github.com/szTheory/oban_powertools/commit/1a9f01ddc0fb501161570188833f587b4c8a0d5b))
* **phase-48:** complete phase execution ([ce280ab](https://github.com/szTheory/oban_powertools/commit/ce280ab255111f4675d73394a28c244cd73e90dd))
* **phase-48:** evolve PROJECT.md after phase completion ([814702d](https://github.com/szTheory/oban_powertools/commit/814702dafa4687f7ee3aaf29c00aca2856d0d345))
* **phase-48:** reconcile validation strategy with executed phase (Nyquist-compliant, 0 gaps) ([7e8000c](https://github.com/szTheory/oban_powertools/commit/7e8000c4bf8b787009cc4cb746c0a6ab7a98a821))
* **phase-48:** update tracking after wave 1 ([aa53e09](https://github.com/szTheory/oban_powertools/commit/aa53e09351fff1dcce9635b03d10edd79a31afb5))
* **phase-48:** update tracking after wave 2 ([5575519](https://github.com/szTheory/oban_powertools/commit/5575519ce158d6ad2892dca18468a23f05802f64))
* **phase-49:** add code review findings ([a9a6a98](https://github.com/szTheory/oban_powertools/commit/a9a6a989f201bfa918a7e8d68fde55a1dd8b8297))
* **phase-49:** add security threat verification ([a72c12a](https://github.com/szTheory/oban_powertools/commit/a72c12a970d85d9b8582b5742192de245cc67f81))
* **phase-49:** add validation strategy ([0e21de4](https://github.com/szTheory/oban_powertools/commit/0e21de419fefc5159fa578440ed539b7fc206e59))
* **phase-49:** complete phase execution ([69a1b33](https://github.com/szTheory/oban_powertools/commit/69a1b3322938da98dc83c7fc7a22396e9e2228ff))
* **phase-49:** evolve PROJECT.md after phase completion ([c82e694](https://github.com/szTheory/oban_powertools/commit/c82e694107da811afb32ca1d28bf836eb087ef06))
* **phase-49:** mark code review findings resolved ([754dcc4](https://github.com/szTheory/oban_powertools/commit/754dcc433faf4bca0fa59091147e52310bbe82be))
* **phase-49:** reconcile validation strategy to green (audit, 0 gaps) ([46832d3](https://github.com/szTheory/oban_powertools/commit/46832d36c0390461821a85a0d59b1f987c76a03e))
* **phase-49:** update tracking after wave 1 ([041c87a](https://github.com/szTheory/oban_powertools/commit/041c87a4eb8284dae4a8d0a80d13f28bc728fbb8))
* **phase-49:** update tracking after wave 2 ([9f59317](https://github.com/szTheory/oban_powertools/commit/9f5931775fd01a9fe1092fcc67389d4344e04b30))
* **phase-50:** complete phase execution ([a115951](https://github.com/szTheory/oban_powertools/commit/a1159515679d142a448f7efea6c5f01bde13d22a))
* **phase-50:** evolve PROJECT.md after phase completion ([b5ddf69](https://github.com/szTheory/oban_powertools/commit/b5ddf6983ec2318b018f61792d9a483571a440bd))
* **phase-50:** update tracking after wave 1 ([a3927e5](https://github.com/szTheory/oban_powertools/commit/a3927e5f329a993fcd3aac65e4585cc455d87fdc))
* **phase-51:** add validation strategy ([706f3ff](https://github.com/szTheory/oban_powertools/commit/706f3ffee7103ae83ced28039659eb2d057bc972))
* **phase-51:** complete phase execution ([f38638d](https://github.com/szTheory/oban_powertools/commit/f38638d8a7366e58384762faeeab644dae65d160))
* **phase-51:** evolve PROJECT.md after phase completion ([d57c9ab](https://github.com/szTheory/oban_powertools/commit/d57c9ab8c3f50168ab9ac0429b12972ebcfa0a61))
* **phase-51:** update tracking after wave 1 ([b858953](https://github.com/szTheory/oban_powertools/commit/b858953806b2e0b355a9bde47ff154e5f879f65d))
* **phase-51:** update tracking after wave 2 ([6df46ca](https://github.com/szTheory/oban_powertools/commit/6df46cac645502cdb070fed284d4f7954db31992))
* **phase-51:** update tracking after wave 3 ([4007aef](https://github.com/szTheory/oban_powertools/commit/4007aef10d6e5316159792bc2a4e0d9b3f7feb74))
* **state:** record phase 48 context session ([07ffb6d](https://github.com/szTheory/oban_powertools/commit/07ffb6d6d4f73fd6e318314c869931d39896c497))
* **state:** record phase 49 context session ([9be5555](https://github.com/szTheory/oban_powertools/commit/9be5555ba00c65b66eca366ff1970b791763f7da))
* **state:** record phase 50 context session ([521c937](https://github.com/szTheory/oban_powertools/commit/521c93775a6b30b7fe0a29c4d59fdd0a34b7f042))
* **state:** record phase 51 context session ([562d835](https://github.com/szTheory/oban_powertools/commit/562d835a3d97442b839d839b9dd7e57c961730fc))
* **v1.6:** milestone audit — gaps_found (3/13 satisfied, 3 phases unbuilt) ([7b45782](https://github.com/szTheory/oban_powertools/commit/7b45782f455ade285507d97f77557d9276110c6e))
* **v1.6:** re-audit milestone — 5/13 satisfied, hex 0.5.0 live, doctor not in published pkg ([50cb65b](https://github.com/szTheory/oban_powertools/commit/50cb65bd7aba8530b238c7508d1dc122bb9359d1))
* **v1.6:** re-audit milestone — Phase 49 built, 8/13 reqs satisfied, gaps_found ([2da44bd](https://github.com/szTheory/oban_powertools/commit/2da44bd3d201ada0bb662af62b405a881e344695))

## [Unreleased]

## [1.0.0] - 2026-06-18

### Changed
- Promoted package version to `1.0.0` following comprehensive stabilization sweep.
- Ecto migrations updated to utilize concurrent index generation (`concurrently: true` and `@disable_ddl_transaction true`) for high-throughput tables.
- Ran comprehensive static analysis with Dialyzer and Credo, resolving all code contract warnings.
- Introduced `powertools-vs-oban-pro.md` matrix and `upgrade-and-compatibility.md` documentation.

### Added

#### Health Check CLI

- `mix oban_powertools.doctor` — read-only health check task that inspects the Oban
  and Powertools database state without starting Oban or acquiring locks. Runs five
  checks over `pg_catalog` and `information_schema`:
  - **Index validity** — surfaces `INVALID` indexes left by a failed
    `CREATE INDEX CONCURRENTLY`, with `REINDEX INDEX CONCURRENTLY` remediation.
  - **Missing indexes** — detects absent v14 Oban indexes that degrade job throughput.
  - **Migration drift** — compares the in-DB Oban migration version against the
    installed library version and flags gaps.
  - **Powertools tables** — verifies all 24 Powertools tables are present, grouped by
    migration tranche with per-group remediation hints.
  - **Uniqueness-timeout risk** — warns when the GIN index is absent and a large
    backlog makes uniqueness checks expensive; escalates to error under `--strict`.
- Exit codes suitable for CI pipelines: `0` (all clear), `1` (warnings), `2` (errors).
- `--format json` output carries a `schema_version: 1` stability contract for
  machine-readable consumption.
- `--strict` flag elevates uniqueness-timeout risk from warning to error.
- `--prefix` flag for custom Oban schema support.
- End-to-end contract test in CI (`doctor` lane in `host-contract-proof.yml`) that
  exercises the real CLI against a freshly migrated example host, including
  `--format json` round-trip and absent-prefix error path.

#### Limiter CLI

- `mix oban_powertools.limiter.explain` — diagnoses a limiter's current blocking state
  by resource name or worker module, reusing `ObanPowertools.Explain` without
  duplicating limiter logic. Shows why a limiter is blocked, when it will clear, and
  what tokens are in use.
- `mix oban_powertools.limiter.simulate` — previews per-request reserved/blocked
  verdicts for a worker's declared limits without touching any real limiter state.
  Simulation is proven side-effect-free: no DB writes, no telemetry events, no
  token-bucket mutations.
- Both tasks embed the full rate-limit glossary (`token_bucket`, `bucket_capacity`,
  `bucket_span_ms`, `weight`, `weight_by`, `partition`, `partition_by`, `scope`,
  `cooldown`, `limit_reached`) in their `--help` output.
- `ObanPowertools.Limits.compute_reservation/4` — new public pure function (extracted
  from the internal reservation path) that determines reserve/block verdicts with zero
  side effects. Useful for unit-testing limiter behavior without a database.
- `ObanPowertools.Limits.Glossary` — single-source rate-limit glossary module; the
  glossary text is test-locked across the guide, explain task, and simulate task so
  term-level parity is enforced in CI.

#### Telemetry & SLOs

- `ObanPowertools.Telemetry.metrics/0` — returns 17 `Telemetry.Metrics.Counter`
  definitions over the frozen low-cardinality contract, covering five control-plane
  families: `operator_action` (2), `limiter` (3), `cron` (4), `workflow` (4), and
  `lifeline` (4). All tags are strict subsets of the frozen `@contract` — no
  `:job_id`, `:args`, or other high-cardinality fields.
- `telemetry_metrics` and `telemetry_poller` added as optional dependencies, gated
  like the existing `oban_web` integration. Zero runtime cost or failure when absent;
  `metrics/0` raises an actionable `RuntimeError` if called without the dep installed.
- **Operations guide:** `guides/telemetry-and-slos.md` — reporter-agnostic guide
  covering telemetry wiring, the Oban-core vs Powertools signal seam, control-plane
  SLIs, and burn-rate SLO framing with Parapet. No `oban_met` dependency required.

## [0.5.0] - 2026-05-29

First public release of Oban Powertools — an Ecto-native operations layer for
Oban-backed Phoenix applications that extends Oban with typed worker contracts,
durable idempotency, explicit limiter and cron controls, durable workflow semantics,
and native operator surfaces for diagnosis, repair, and audited manual operations.

### Added

#### Workers & Idempotency

- Typed worker arg schemas with `field/3` macro — compile-time validation of job
  arguments against declared types, with support for `required:`, `default:`, and
  `redact:` options.
- Synchronous enqueue validation — `insert/2` returns `{:error, changeset}` on
  invalid args before the job reaches the queue.
- Durable idempotency receipts — `idempotency_key/1` hashes worker args to produce
  a stable fingerprint; duplicate enqueues within the observation window are
  deduplicated at the DB level without requiring the caller to manage uniqueness
  tokens.

#### Limiters & Explain

- Global and partitioned rate limiters — `ObanPowertools.Limits` with configurable
  token-bucket windows, per-resource partitioning, and explicit `blocker_code`
  vocabulary for diagnosing blocked jobs.
- Explainable blocking state — `ObanPowertools.Explain` surfaces why a job is
  currently blocked (limiter, cron overlap, or queue depth) with structured output
  suitable for operator dashboards and CLI tooling.

#### Cron

- Dynamic cron with overlap policies — `ObanPowertools.Cron` manages named cron
  entries with explicit `overlap_policy` (`:skip`, `:replace`, `:run_anyway`) and
  `catch_up_policy` (`:run_once`, `:run_all`, `:skip`) so missed-fire behavior is
  documented and auditable, not silently dropped.

#### Workflows

- Explicit persisted workflow DAGs — `ObanPowertools.Workflow` stores step graphs in
  a dedicated `oban_powertools_workflows` table with durable terminal-cause vocabulary
  and additive semantics versioning.
- Coordinator signaling for rapid progression — `Workflow.signal/2` lets a completing
  step unblock its dependents without polling, reducing workflow latency under load.
- Native workflow state inspection UI — the `/ops/jobs` shell renders workflow
  progress, step outcomes, and terminal causes at `/ops/jobs/workflows`.

#### Lifeline & Repairs

- Heartbeat-backed executor health tracking — `ObanPowertools.Lifeline` monitors
  Oban queue health and surfaces stalled executors with structured incident classes.
- Dry-run repair center with durable closure behavior — all operator repairs go through
  a preview → reason → execute → audit pipeline; repairs are idempotent and
  self-closing.
- Audit logging for manual UI operations — every operator action writes a durable
  audit record via `ObanPowertools.AuditLog` with actor attribution, action type,
  target identity, and outcome.
- Archive-before-delete retention flows — `ObanPowertools.Archive` moves jobs and
  workflow records to retention tables before deletion, preserving forensic history.

#### Native `/ops/jobs` Shell

- Full native job lifecycle surface at `/ops/jobs/jobs` — browse jobs by state,
  queue, worker, and tags with URL-serialized filter state and `DisplayPolicy`
  redaction on args/meta; inspect full job detail.
- Single-job retry, cancel, and discard through the Lifeline preview/reason/execute/audit
  pipeline with a concurrent-modification guard.
- Bulk operations with independent per-job repairs and honest per-job
  success/failure reporting — no silent partial failures.
- `DisplayPolicy` behaviour for host-controlled field redaction and display formatting
  across all native operator surfaces.

#### Operator API (Single + Bulk)

- `ObanPowertools.Operator` — typed, actor-attributed programmatic surface for
  single-job mutations (retry, cancel, discard) routed through the Lifeline pipeline
  and emitting `source: "api"` telemetry within the frozen low-cardinality contract.
- Bulk Operator API — `Operator.retry_all/2`, `cancel_all/2`, `discard_all/2` run
  an independent repair per job and return per-job success/failure results; no single
  `Ecto.Multi` over N jobs, no silent bulk failure.

#### Telemetry Contract

- Frozen low-cardinality telemetry contract — `ObanPowertools.Telemetry` defines and
  publishes five event families under `[:oban_powertools, family, event_suffix]`:
  `:operator_action`, `:limiter`, `:cron`, `:workflow`, and `:lifeline`. The public
  measurement key is `:count`. Metadata keys are enumerated per family in the frozen
  `@contract` — IDs, job args, preview tokens, and free-form reasons are intentionally
  excluded.

#### Install & Migrations

- Igniter-powered installer — `mix oban_powertools.install` adds the dependency,
  configures the router, sets up auth hooks, and generates all required migrations via
  `Igniter.Libs.Ecto.gen_migration/4` directly into the host's `priv/repo/migrations/`.
- Deterministic Ecto migrations for all Powertools tables with a documented upgrade
  path and `mix ecto.migrate` idempotency.

#### Optional Oban Web Bridge

- Optional `oban_web` bridge — when `{:oban_web, optional: true}` is present, the
  `/ops/jobs` shell embeds the Oban Web dashboard at `/ops/jobs/oban` as a narrower,
  read-only complement to the native surfaces. The bridge is compile-time optional;
  the native shell is fully functional without it.

---

## Path to 1.0

Oban Powertools uses a **hybrid per-surface + stability-window gate** to determine
when each named public surface is ready to freeze at `1.0`. The library will NOT bump
to `1.0.0` until all four surfaces below have met their gate criteria — and in
practice, not until at least one **non-szTheory host** has exercised the install,
Operator API, and upgrade path in production.

**Gate criteria** (must be met for each surface):

1. The surface is **explicitly enumerated** (listed below).
2. The surface has been **exercised by at least one non-szTheory host** in a real application.
3. The surface is **free of any known breaking change** at time of evaluation.
4. The surface has survived **at least two consecutive 0.x minor releases** without a breaking change.

### Surface Checklist

#### Installer / Migration Contract

The `mix oban_powertools.install` Igniter task and the set of Ecto migrations it
generates — including the table schemas for `oban_powertools_workflows`,
`oban_powertools_workflow_steps`, `oban_powertools_audit_logs`, and all supporting
tables — constitute the installer/migration contract surface.

- [ ] Explicitly enumerated: YES (this document)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (as of 0.5.0)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

#### Operator Elixir API (Single + Bulk)

The public functions in `ObanPowertools.Operator` — `retry/2`, `cancel/2`,
`discard/2`, `retry_all/2`, `cancel_all/2`, `discard_all/2` — and their `actor:` and
`opts:` argument shapes constitute the Operator API surface.

- [ ] Explicitly enumerated: YES (this document)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (as of 0.5.0)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

#### Frozen Telemetry `@contract`

The five event families (`[:oban_powertools, family, event_suffix]`), the public
measurement key (`:count`), and the per-family allowed low-cardinality metadata keys
defined in `ObanPowertools.Telemetry.@contract` constitute the telemetry surface.
This surface was frozen at Phase 8 (v1.1) and has not changed since.

- [ ] Explicitly enumerated: YES (this document + `ObanPowertools.Telemetry` moduledoc)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (frozen since v1.1)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

#### Host-Ownership Boundary

The host-ownership boundary governs which concerns Oban Powertools owns vs. which
the host app must provide: the router mount point (`live "/ops/jobs", ...`), the auth
callback hook (`ObanPowertools.Auth` behaviour), `DisplayPolicy` module pointing, and
the supervision tree wiring. Changes to this boundary require host-app code changes.

- [ ] Explicitly enumerated: YES (this document + `guides/support-truth-and-ownership-boundaries.md`)
- [ ] Exercised by a non-szTheory host: NO
- [ ] Free of known breaking changes: YES (as of 0.5.0)
- [ ] Survived 2+ consecutive 0.x minor releases: NO (first release)

---

*The 1.0 clock starts when a non-szTheory host reports a successful install. At that
point, each surface enters the stability observation window and tracks
0.x minor releases without breaking changes toward the graduation gate.*
