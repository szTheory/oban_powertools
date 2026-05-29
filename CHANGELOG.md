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

## 0.5.0 (2026-05-29)


### Features

* **0-01:** implement core contracts (Auth, Telemetry, Router) ([fe8ab1e](https://github.com/szTheory/oban_powertools/commit/fe8ab1ee6226cad6c8f038e6924eb1088d72737e))
* **0-01:** implement igniter installer task ([b64758a](https://github.com/szTheory/oban_powertools/commit/b64758a747f5e2c084af665b327f26e15b744127))
* **10-01:** move cron liveview onto durable previews ([f42b90d](https://github.com/szTheory/oban_powertools/commit/f42b90d9f313342f520ba9b363765d7c877f20f0))
* **10-01:** unify durable preview contract ([5ea33ef](https://github.com/szTheory/oban_powertools/commit/5ea33ef66f8eea611214113c40f12546f112cf5c))
* **10-02:** align read-only support-truth pages ([76b0ef0](https://github.com/szTheory/oban_powertools/commit/76b0ef0fe237782b57af973f910dec5c188c8b96))
* **10-02:** unify native operator mutation vocabulary ([3fdbc25](https://github.com/szTheory/oban_powertools/commit/3fdbc2585fa6d05013033a3d4d5cd78643c846ad))
* **10-03:** document read-only bridge contract ([fef6bba](https://github.com/szTheory/oban_powertools/commit/fef6bbaf3e1f37eb4c1946cb6c6695ac1990126b))
* **11-01:** add docs entry surface ([525c8c3](https://github.com/szTheory/oban_powertools/commit/525c8c3a6996665ceadd60a3127bc8beea95abb3))
* **12-02:** repair fixture migrations and first-session seeds ([b78e97f](https://github.com/szTheory/oban_powertools/commit/b78e97fcf8408071bdf1b2adecef4a351ecf49ce))
* **12-03:** implement first-session fixture proof ([af61f73](https://github.com/szTheory/oban_powertools/commit/af61f738e8bbd459e6f95e8da8954d7dd31dab6c))
* **12-03:** wire root first-session host proof ([6149fe0](https://github.com/szTheory/oban_powertools/commit/6149fe05d249ab15391652b7286e08270a65c20b))
* **12-04:** align host contract workflow with repaired proof stack ([b8762c0](https://github.com/szTheory/oban_powertools/commit/b8762c0f02b6b18dc1309692a8c8aa52e8f765a9))
* **15-01:** freeze archived upgrade source fixture ([c37a554](https://github.com/szTheory/oban_powertools/commit/c37a554ebfb7620ebad4fb5c7d0c8649d3667ca9))
* **15-02:** rebuild archived upgrade harness ([5306951](https://github.com/szTheory/oban_powertools/commit/5306951033308f83bf884974a3f8527188cf4219))
* **34-01:** implement bounded attention projection ([a12a585](https://github.com/szTheory/oban_powertools/commit/a12a585f22ef8962f49539969c3f1d25a097fe65))
* **34-01:** render overview attention details ([7168f5c](https://github.com/szTheory/oban_powertools/commit/7168f5cd75aab7bfe6b90e622640b87c65f83485))
* **34-01:** wire attention projection into overview buckets ([7eb4614](https://github.com/szTheory/oban_powertools/commit/7eb4614e0c16a5fbd9c473a078cd93b5df9d84b7))
* **34-02:** enrich forensic bundles with runbook entries ([0fac674](https://github.com/szTheory/oban_powertools/commit/0fac67448bdcf99f2847485a283e5b5a0e717d12))
* **34-02:** implement advisory runbook entry builder ([c444165](https://github.com/szTheory/oban_powertools/commit/c444165543620f47c8ef7f5e15d38513848c3ffa))
* **34-02:** render forensic runbook entries ([4d84642](https://github.com/szTheory/oban_powertools/commit/4d846422609c0fca25aabc84a169ce5fc0ddeb68))
* **34-03:** add compact cron and limiter runbook guidance ([7ed7c55](https://github.com/szTheory/oban_powertools/commit/7ed7c551b01d736e9b7f9df79fb74ee9a3bc6c67))
* **34-03:** add runbook presenter vocabulary helpers ([0b7a861](https://github.com/szTheory/oban_powertools/commit/0b7a861a883839ea36446c6c8fab954e4438a509))
* **34-03:** align workflow and lifeline runbook handoffs ([da25e31](https://github.com/szTheory/oban_powertools/commit/da25e31daa19c77c455c76b129a89b0f497bb393))
* **35-01:** preserve runbook continuity through lifeline remediation ([460e294](https://github.com/szTheory/oban_powertools/commit/460e2947c5d58c66e4b485d37a37fd1d5e0bb1c3))
* **35-01:** project remediation continuity into forensics views ([40fbc2e](https://github.com/szTheory/oban_powertools/commit/40fbc2e1fa90526bd70809b1ebe44e85683ef2bf))
* **35-01:** render runbook continuity-first remediation evidence ([8560664](https://github.com/szTheory/oban_powertools/commit/8560664b4cf01a0fc62beb3958a2671751ec5c2c))
* **35-02:** add host-owned escalation callback seam ([a8e9c17](https://github.com/szTheory/oban_powertools/commit/a8e9c17dbde1e80649400a09e9d70a9e2f836c57))
* **35-02:** emit host follow-up audit after remediation ([8838627](https://github.com/szTheory/oban_powertools/commit/88386271d9b642eefe0b915e4d8c97b79837c3e1))
* **35-02:** surface host follow-up status across runbook UI ([b578ff2](https://github.com/szTheory/oban_powertools/commit/b578ff27e13bc60425719bba5166d096a3ba56c7))
* **35-03:** unify ownership-boundary follow-up rendering ([cdbe1c7](https://github.com/szTheory/oban_powertools/commit/cdbe1c7b5caf5e84a3ea405129d54e5aab118dc1))
* **39-01:** add deterministic VER-04 continuity proof lanes ([454916d](https://github.com/szTheory/oban_powertools/commit/454916d7a29ef779cbc4c1afa3a113ae6f3e47d0))
* **39-02:** emit deterministic VER-04 claim evidence ([bebc8aa](https://github.com/szTheory/oban_powertools/commit/bebc8aab1ad7a411532975d2331c92fd751594c2))
* **39-02:** enforce continuity proof packet safety gates ([2613bab](https://github.com/szTheory/oban_powertools/commit/2613babedc4e5f69f7b9001e0cbda4600e317d09))
* **39-03:** close VER-04 traceability with phase 39 proof references ([773bd71](https://github.com/szTheory/oban_powertools/commit/773bd71b58d2c5d73633b4d1ba8c667a123e8425))
* **39-03:** publish deterministic VER-04 proof manifest ([b463fbd](https://github.com/szTheory/oban_powertools/commit/b463fbd0c9b59666f628dd01045e2ac6ff4a999c))
* **39-03:** publish VER-04 claim-to-evidence verification report ([d922965](https://github.com/szTheory/oban_powertools/commit/d9229652bcd3b474f96af34e521ee026d11db225))
* **40-01:** add automated proxies for Phase 34 visual scan and copy judgment ([820f9db](https://github.com/szTheory/oban_powertools/commit/820f9db701595c567cdde5a3e3022ce60cfb39f6))
* **40-02:** wire Phase 40 proxy tests into C3/C4 + publish gate report ([f6863ae](https://github.com/szTheory/oban_powertools/commit/f6863ae6759f66f4d15b30078df29e5248009eb5))
* **41-01:** add ObanPowertools.Lifeline.TargetType closed-enum dispatcher (Wave 1) ([6f4de57](https://github.com/szTheory/oban_powertools/commit/6f4de5756861dfcd8ec17b6d8575f3f71b142878))
* **41-01:** add ObanPowertools.Web.Selectors canonical URL encoder (Wave 1) ([5b93f8a](https://github.com/szTheory/oban_powertools/commit/5b93f8a324e1d33f39a0f86d9b704a9ba9ea423c))
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
* **6-01:** centralize runtime config resolution ([d92fb6a](https://github.com/szTheory/oban_powertools/commit/d92fb6aa93c1352a52d08dad6a9d14e9d06ccd03))
* **6-01:** emit explicit powertools runtime wiring ([3dbf59e](https://github.com/szTheory/oban_powertools/commit/3dbf59e8a26897306dbeda91caa1bd057cf9a89c))
* **6-02:** gate cron previews before side effects ([8fda253](https://github.com/szTheory/oban_powertools/commit/8fda25395dc7a2ff822d32ef635ef1d4372f8c33))
* **6-02:** render disabled cron actions with permission explanations ([f8bcc05](https://github.com/szTheory/oban_powertools/commit/f8bcc052e37c12160d1fa69d94575a7842d66ca8))
* **8-01:** document the host-owned install contract ([0cab09f](https://github.com/szTheory/oban_powertools/commit/0cab09f62baecd6d61eb26748b5bca6f6fc64464))
* **8-01:** gate heartbeat supervision on repo wiring ([d80e24d](https://github.com/szTheory/oban_powertools/commit/d80e24d13c2e0111d41cbf3a87479514f0e842a4))
* **8-03:** publish telemetry contract API ([e5f46f5](https://github.com/szTheory/oban_powertools/commit/e5f46f573aabdd539b5111acc85204fd9d74ff43))
* **9-01:** enforce principal checks in native live flows ([43d686e](https://github.com/szTheory/oban_powertools/commit/43d686e7ba6f79450688492be976c8f4a83eb055))
* **9-01:** freeze auth and audit principal contract ([c87c690](https://github.com/szTheory/oban_powertools/commit/c87c690c19014017e9edf4000621ec4967177b24))
* **9-02:** add shared display policy runtime seam ([55460bb](https://github.com/szTheory/oban_powertools/commit/55460bb9ebfa75b1d3e44c9910786ca9b755b114))
* **9-02:** apply display policy across native surfaces ([1cd20c8](https://github.com/szTheory/oban_powertools/commit/1cd20c83492bec7316a54966975273d691ebf65f))
* **9-03:** add bounded oban web bridge adapter ([591f85f](https://github.com/szTheory/oban_powertools/commit/591f85f6b9864d3408764b4a8c166816a505a0ec))
* add forensic timelines for cron and limiters ([1b36404](https://github.com/szTheory/oban_powertools/commit/1b364044df91eb63682eb5a4a1258f89c72c3248))
* **phase-4:** checkpoint lifeline backend slice ([af1fd9b](https://github.com/szTheory/oban_powertools/commit/af1fd9b65764b1709ecfba1c837c2e23ed979809))
* **phase-5:** restore milestone evidence chain ([30f8f0e](https://github.com/szTheory/oban_powertools/commit/30f8f0e1878b717a87836982e52a98d7b3293c42))
* **phase-7:** close lifeline incident retirement gap ([c94a0f8](https://github.com/szTheory/oban_powertools/commit/c94a0f832269916a54092999ed806f85e4a53707))
* **phases-2-4:** checkpoint operator surfaces and planning baseline ([0b21d0b](https://github.com/szTheory/oban_powertools/commit/0b21d0ba0b03fd3471aa3bc2eff9026bbbe917d8))
* **workflow:** freeze lifecycle semantics contract ([ec625df](https://github.com/szTheory/oban_powertools/commit/ec625df85ff676dfaec3a6fe66c68ed2ed3e7f86))
* **workflow:** land semantics stabilization boundary ([1f92965](https://github.com/szTheory/oban_powertools/commit/1f92965f37b38fb3204d257f50b1f20c2f116363))


### Bug Fixes

* **12-01:** emit the thin host install contract ([a1fed86](https://github.com/szTheory/oban_powertools/commit/a1fed8674ed0757e21ef376c1dae324cc3f8ca47))
* **12-01:** prove the fresh host install path ([a575ba6](https://github.com/szTheory/oban_powertools/commit/a575ba614d1f7b5cb5c750b58dc292b6920629c6))
* **12:** close review findings for proof gates ([85014d2](https://github.com/szTheory/oban_powertools/commit/85014d29055bba6ce99bc513a4aa1aaa4a21ae63))
* **15-02:** strengthen the upgrade proof lane ([b09c7bb](https://github.com/szTheory/oban_powertools/commit/b09c7bb1a0f30588a5a727b2ad276040c56e6288))
* **34-01:** add example host history migrations ([265be6c](https://github.com/szTheory/oban_powertools/commit/265be6c521e365b7dd2e73e30afd65aeda22c919))
* **34:** WR-01 encode overview incident links ([36063ad](https://github.com/szTheory/oban_powertools/commit/36063ad08bf55f9800839c19dc027d04e914e071))
* **34:** WR-02 whitelist forensic labels ([04ca431](https://github.com/szTheory/oban_powertools/commit/04ca43114fefff9165093a116e1591b4c0ec6b80))
* **41-01:** migrate all 14 selector+atom hazard sites to Selectors/TargetType helpers (Wave 2) ([7d13698](https://github.com/szTheory/oban_powertools/commit/7d13698addf6aa2e8649f2beac96017884efcf41))
* **41-01:** migrate control_plane_presenter.ex atom sites 1+2 to bounded conversion (Wave 2) ([9cb7d9d](https://github.com/szTheory/oban_powertools/commit/9cb7d9d7a667cde9cd8bfb0b82c7b78763558b3c))
* **41-01:** migrate evidence_bundle.ex normalize_related_evidence to bounded atom keys (Wave 2) ([b2b291b](https://github.com/szTheory/oban_powertools/commit/b2b291b94c7c88ae789af3e98b36c054e0decf45))
* **41:** CR-01 delegate audit_follow_up_path/1 to Selectors.audit_path/1 ([1496e6a](https://github.com/szTheory/oban_powertools/commit/1496e6a283358415688e745928c38f7d93428c22))
* **41:** CR-02 delegate forensic_path/2 to Selectors.forensic_path/1 ([dc52c7b](https://github.com/szTheory/oban_powertools/commit/dc52c7b7bc587e5c187b0532eb68aa2564eb6e33))
* **41:** CR-03 URI-encode step names in URL construction ([414eac2](https://github.com/szTheory/oban_powertools/commit/414eac25f36a27121cda0402fce687757d59d05d))
* **41:** CR-04 scope archive prune delete to exact archived event IDs ([3f3fb66](https://github.com/szTheory/oban_powertools/commit/3f3fb66a69e687e1bd588a9c8667b1788fc3f735))
* **41:** CR-05 use Integer.parse/1 for untrusted target_id param ([955df79](https://github.com/szTheory/oban_powertools/commit/955df79dfef59dd180875d0b5117b5c1d4ca8ca9))
* **41:** WR-01 add catch-all clause to incident_rows/2 ([2278751](https://github.com/szTheory/oban_powertools/commit/2278751b3f3b71ab53983519559a911cbed55680))
* **41:** WR-02 use Map.get/2 for workflow_id and step_name access ([58f2374](https://github.com/szTheory/oban_powertools/commit/58f2374ef131b9edbb6e09cabeda98d6ddca81fd))
* **41:** WR-03 add catch-all clause to Forensics.audit_path/1 ([4bf95e6](https://github.com/szTheory/oban_powertools/commit/4bf95e67904521ee4e8dfa1197eaf7a2b188c9ab))
* **41:** WR-04 handle error case in list_executor_health/2 and add note ([ed2395d](https://github.com/szTheory/oban_powertools/commit/ed2395db4904b4f14ddd751c6b46258c602afa5b))
* **41:** WR-05 use Audit helpers instead of direct field access in OverviewReadModel ([410c98b](https://github.com/szTheory/oban_powertools/commit/410c98b82069a9a9cedf535fc28fae10b189ae94))
* **43-02:** use connected?/1 guard for push_patch and fix filter_path nil encoding ([6d73ada](https://github.com/szTheory/oban_powertools/commit/6d73adadeae97c5f2c9b5f914ce5becc5662a0a6))
* **43:** apply code review fixes for jobs browse ([a6ce9e3](https://github.com/szTheory/oban_powertools/commit/a6ce9e33f7324700e54cc6ef76498053d69520b2))
* **ci:** align test harness with proof lanes ([1336dc2](https://github.com/szTheory/oban_powertools/commit/1336dc284a71f82276a1a3f6909d35af24711357))
* **ci:** install phx_new for fresh-host proof ([24211bd](https://github.com/szTheory/oban_powertools/commit/24211bd2d149ab26b4b9f2e4a25bd8d52addedf0))
* **ci:** skip repo boot in fresh-host lane ([e3876b0](https://github.com/szTheory/oban_powertools/commit/e3876b0048ae430a6cb672630607fef9b7d80dff))
* make igniter installer compile for adopters (unscope from dev/test) ([#8](https://github.com/szTheory/oban_powertools/issues/8)) ([955dd23](https://github.com/szTheory/oban_powertools/commit/955dd23e5ac6e539e3ecb809f420b0b23f6caffd))
* **test:** stabilize host proof lanes ([0ce1d75](https://github.com/szTheory/oban_powertools/commit/0ce1d7524bb2f16fa1816cb4203b02965db6895f))


### Dependencies

* **deps:** bump oban_web from 2.12.4 to 2.12.5 ([#7](https://github.com/szTheory/oban_powertools/issues/7)) ([9c8eb03](https://github.com/szTheory/oban_powertools/commit/9c8eb03696306da55fcea6dd56e8f9cd71f92a4b))


### Documentation

* **0-01:** complete 01-PLAN.md plan ([84bf554](https://github.com/szTheory/oban_powertools/commit/84bf55466198044772212b09c7edc2bea533b0c7))
* **10-01:** add execution summary ([bf8c9da](https://github.com/szTheory/oban_powertools/commit/bf8c9dabf5de27e8fd61865d1a80fbab3094e145))
* **10-02:** add operator vocabulary execution summary ([b27d81d](https://github.com/szTheory/oban_powertools/commit/b27d81d4da4972c793c7bb44f224603ee397dc94))
* **10-03:** add execution summary ([121808c](https://github.com/szTheory/oban_powertools/commit/121808c65ffa14a5e30dbc3688a3e2078c7e5d0a))
* **10-03:** publish bridge support truth ([c0d78ad](https://github.com/szTheory/oban_powertools/commit/c0d78adfc587577d613e80bf82f3c41c1fe06349))
* **11-01:** add day-0 operator guides ([3bc0118](https://github.com/szTheory/oban_powertools/commit/3bc0118432b1a99a7a0092561cc314b7c7ad27b6))
* **11-01:** add execution summary ([638fa4f](https://github.com/szTheory/oban_powertools/commit/638fa4f7680b0116ccd032daf554a6c386e77881))
* **12-01:** complete fresh host installer repair plan .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-01-SUMMARY.md .planning/STATE.md .planning/ROADMAP.md .planning/REQUIREMENTS.md ([13016e2](https://github.com/szTheory/oban_powertools/commit/13016e222a2a46ffff75b748ef57bd6d6328e8ee))
* **12-02:** complete fixture repair plan ([774d0bd](https://github.com/szTheory/oban_powertools/commit/774d0bd007ac04d5694402feca4d9066b1586f89))
* **12-02:** rewrite fixture provenance and regeneration story ([fbfb0fe](https://github.com/szTheory/oban_powertools/commit/fbfb0fe9f52b7653e680f91a2f175a4b810ca924))
* **12-03:** complete first-session proof plan ([1877638](https://github.com/szTheory/oban_powertools/commit/187763867049e14f10ceae044008e31190adbe7d))
* **12-04:** complete public contract alignment plan ([b628326](https://github.com/szTheory/oban_powertools/commit/b62832613c393ce1460e14a79b0987b84d92f200))
* **12-04:** rewrite repaired install and first-session contract ([4174a60](https://github.com/szTheory/oban_powertools/commit/4174a60e299725c6a06f588d96f90adb8c1589f4))
* **12:** capture phase context .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-DISCUSSION-LOG.md ([539bae8](https://github.com/szTheory/oban_powertools/commit/539bae807c4a430f95e4043f280ae5c352b85ab7))
* **14-01:** add retrospective summary corrections ([6ffd62d](https://github.com/szTheory/oban_powertools/commit/6ffd62d394f9bfb932062f66e126ae25e4f2c461))
* **14-01:** complete summary closure repair plan ([a65723e](https://github.com/szTheory/oban_powertools/commit/a65723e9bcf0c1a4cc0eae1c097c1bca0f6415f2))
* **14-01:** normalize phase 8 and 9 closure metadata ([94f9d98](https://github.com/szTheory/oban_powertools/commit/94f9d980a173b22126487a610ec01b595deb2912))
* **14-02:** capture fresh phase 9 proof results ([6c618a6](https://github.com/szTheory/oban_powertools/commit/6c618a6c99ee10db19cbaeadb580e7b72a003a7b))
* **14-02:** complete phase 9 verification repair plan ([2285e17](https://github.com/szTheory/oban_powertools/commit/2285e177e8da4141bccdc1892f68f0c93000a02f))
* **14-02:** rewrite phase 9 verification as req report ([5090570](https://github.com/szTheory/oban_powertools/commit/509057012541b24afaacf96fa7d4ff213f8555b5))
* **14-03:** capture phase 10 hst-02 proof reruns ([66ce62a](https://github.com/szTheory/oban_powertools/commit/66ce62aaee1c4f76356a406d0169acb9ae6e4a83))
* **14-03:** close phase 10 hst-02 verification ([25e2ba8](https://github.com/szTheory/oban_powertools/commit/25e2ba8e60dcaa776b676b73df640533440a2899))
* **14-03:** complete phase 10 verification closure plan ([d148a70](https://github.com/szTheory/oban_powertools/commit/d148a70fd6ca37d9d297cb20cc0dfa5fc307d331))
* **14-04:** complete closure memo plan ([41e14c5](https://github.com/szTheory/oban_powertools/commit/41e14c59c18ecf50f9151550413e66b7fc2ed8bf))
* **14-04:** explain closure memo posture ([c350c91](https://github.com/szTheory/oban_powertools/commit/c350c91df90ed6c252ce7a2ca2eda3e27d681913))
* **14-04:** map repaired closure artifacts ([8941ea2](https://github.com/szTheory/oban_powertools/commit/8941ea24804fe107ca56cd23595b03c54154ec44))
* **14-04:** refresh milestone audit closure state ([265ca98](https://github.com/szTheory/oban_powertools/commit/265ca989c494731dc5c20cabc35cef8cb7154162))
* **15-01:** complete archived upgrade source plan ([be9ee03](https://github.com/szTheory/oban_powertools/commit/be9ee03f2cc3ca07b86a633059f53b506e216992))
* **15-01:** document archived upgrade source provenance ([b976ccd](https://github.com/szTheory/oban_powertools/commit/b976ccd45175554f596d522a13aef56c300e0db4))
* **15-02:** align the upgrade guide to the real lane ([0c00af5](https://github.com/szTheory/oban_powertools/commit/0c00af5ce91a77dc307985084ee180bdc9d9b828))
* **15-02:** complete real upgrade lane plan ([eaff65e](https://github.com/szTheory/oban_powertools/commit/eaff65ebb999bb7f9a18f3e5152fc6f0e013dd4f))
* **15-03:** align hardening and troubleshooting guides ([32ed9b6](https://github.com/szTheory/oban_powertools/commit/32ed9b6aa2287fdc332c4fbea0820cc1df5209e6))
* **15-03:** complete support-truth docs integrity plan ([e1b3c90](https://github.com/szTheory/oban_powertools/commit/e1b3c9057afef462d7c24dbaef3c85d2d8af01a2))
* **15-03:** rewrite support-truth surfaces ([60134e6](https://github.com/szTheory/oban_powertools/commit/60134e60b1c89922cfcec67713befb8e07a8c24f))
* **15:** research phase domain .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-RESEARCH.md ([5d3550f](https://github.com/szTheory/oban_powertools/commit/5d3550fbf16138ee8453086407a7c22888a1d3a6))
* **18:** capture phase context .planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md .planning/phases/18-durable-callback-outbox-recovery-attempts/18-DISCUSSION-LOG.md ([54ec969](https://github.com/szTheory/oban_powertools/commit/54ec969a89ab4f0591455c97c1fe7013cbf86743))
* **22:** research phase domain .planning/phases/22-lifeline-integration-bounded-recovery-actions/22-RESEARCH.md ([9872787](https://github.com/szTheory/oban_powertools/commit/9872787e32ece3f2e58c6240c06a2881c6f8caed))
* **23:** capture phase context .planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-CONTEXT.md .planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-DISCUSSION-LOG.md ([715ecd5](https://github.com/szTheory/oban_powertools/commit/715ecd507e6c5f205f8c160c4a36b98175e998c6))
* **24-01:** backfill verification artifacts for workflow semantics ([96e3d46](https://github.com/szTheory/oban_powertools/commit/96e3d4632f69d0f8a66b5a18f5704d1d35a2ebcb))
* **24-02:** backfill workflow surface verification artifacts ([b56e61c](https://github.com/szTheory/oban_powertools/commit/b56e61cb560b0f869b2b742310afa55192144cba))
* **24-03:** backfill public proof verification artifacts ([1f9994c](https://github.com/szTheory/oban_powertools/commit/1f9994c562ca1c0374a5cbd0af909d71a32cf189))
* **25-01:** complete plan summary and tracking ([49dcefc](https://github.com/szTheory/oban_powertools/commit/49dcefcde7853ad49d234d0db2a049d1dd9fc1c5))
* **25-01:** repair v1.2 traceability ledger ([85673ba](https://github.com/szTheory/oban_powertools/commit/85673ba79392e3effc7e184378da4ebe4adc6d6e))
* **25-01:** sync roadmap traceability story ([b642a78](https://github.com/szTheory/oban_powertools/commit/b642a7884664dc3c049e6447169ecac6c36b6280))
* **25-02:** add canonical v1.2 rerun audit ([a904689](https://github.com/szTheory/oban_powertools/commit/a904689af615fa28ac8506c168fc6c1e7670bb0f))
* **25-02:** complete plan summary and tracking ([de26683](https://github.com/szTheory/oban_powertools/commit/de266831569b9f2d95b37f207377e367f91effbc))
* **25-02:** preserve failed v1.2 audit snapshot ([db1a6a1](https://github.com/szTheory/oban_powertools/commit/db1a6a18455964e6ce60537f26ed545514fdd29d))
* **25-03:** narrow project milestone framing ([499f3ec](https://github.com/szTheory/oban_powertools/commit/499f3ec2b879ae8edff1ed38b35716dd79b05f6e))
* **25-03:** refresh state continuity pointers ([bfa7dee](https://github.com/szTheory/oban_powertools/commit/bfa7dee674aba92c2365bff151266853b20c2a2f))
* **25:** research traceability audit consistency repair .planning/phases/25-traceability-audit-consistency-repair/25-RESEARCH.md ([35d6b87](https://github.com/szTheory/oban_powertools/commit/35d6b877592422ee59dc61e9650daa373be27afd))
* **26-01:** add phase 12 archival provenance note ([53e8e12](https://github.com/szTheory/oban_powertools/commit/53e8e12e56c6fa9693015eb4fad1ad5049fcd34f))
* **26-01:** normalize historical phase 12 uat artifact ([12155b0](https://github.com/szTheory/oban_powertools/commit/12155b060d0d3ccd4247b8abf01217ff9aa12e4e))
* **26-01:** record historical closeout normalization summary ([144ebce](https://github.com/szTheory/oban_powertools/commit/144ebce017f63c7aff998dbf48704327f1424583))
* **26-02:** record archival tooling hardening summary ([0994f36](https://github.com/szTheory/oban_powertools/commit/0994f361cb3cf7012709071f69b4d4e36b68335d))
* **26-03:** mark phase 26 roadmap plans complete ([9c389c6](https://github.com/szTheory/oban_powertools/commit/9c389c68d41420edd1864b6a67f25ed459624381))
* **26-03:** record milestone closeout handoff summary ([afa1f11](https://github.com/szTheory/oban_powertools/commit/afa1f11940917f59b4d171b4dd816f11b57a7d66))
* **29:** add phase planning artifacts ([88d55b6](https://github.com/szTheory/oban_powertools/commit/88d55b663779e9d8915b22afbdf91fc7696ab328))
* **30:** add validation strategy .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-VALIDATION.md ([b5c3aab](https://github.com/szTheory/oban_powertools/commit/b5c3aab64ce1118a4c786e9da62b8e9fb73c9a83))
* **30:** research phase domain .planning/phases/30-surface-cohesion-across-limiters-workflows-lifeline-cron/30-RESEARCH.md ([1f0bd3a](https://github.com/szTheory/oban_powertools/commit/1f0bd3a8fc6ae607e07d4564e2a9c1f34e53459e))
* **34-01:** complete historical attention projection plan .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-01-SUMMARY.md .planning/STATE.md .planning/ROADMAP.md .planning/REQUIREMENTS.md ([f1bd00c](https://github.com/szTheory/oban_powertools/commit/f1bd00c644ed68a1e76fc8c0d3a8252b3b9ea13d))
* **34-02:** complete runbook entry surfaces plan .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-02-SUMMARY.md .planning/STATE.md .planning/ROADMAP.md .planning/REQUIREMENTS.md ([ac53645](https://github.com/szTheory/oban_powertools/commit/ac53645530a13ef751a6248e8f4b412217b46308))
* **34-03:** complete runbook handoff alignment plan .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-03-SUMMARY.md .planning/STATE.md .planning/ROADMAP.md ([cff32cc](https://github.com/szTheory/oban_powertools/commit/cff32cc382675b02a3154dc82f576dbd0ebc6a48))
* **34:** add code review fix report ([b9b924d](https://github.com/szTheory/oban_powertools/commit/b9b924d89f4291d04071038f8b97f73dcb5fad11))
* **34:** add code review report ([fffd3ca](https://github.com/szTheory/oban_powertools/commit/fffd3ca20a5cffe7016bba25cfb50af12f39b961))
* **34:** add validation strategy .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-VALIDATION.md ([ed89e9a](https://github.com/szTheory/oban_powertools/commit/ed89e9aa6b1d008219e6ded76c6869efa5007f0f))
* **34:** capture phase context .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-CONTEXT.md .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-DISCUSSION-LOG.md ([4f62960](https://github.com/szTheory/oban_powertools/commit/4f6296061d893d3735ab348acc3c54584ecfe3d1))
* **34:** create phase plan .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-01-PLAN.md .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-02-PLAN.md .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-03-PLAN.md ([a01c759](https://github.com/szTheory/oban_powertools/commit/a01c7597b3f57d08d5d2b40b01505e1133096496))
* **34:** research historical attention runbook surfaces .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-RESEARCH.md ([7a457c7](https://github.com/szTheory/oban_powertools/commit/7a457c72c6666a8978d7554a553b49a64cfff858))
* **34:** resolve planning verification notes ([e116152](https://github.com/szTheory/oban_powertools/commit/e1161526f3c42137651e8d3b94d568d8f9742953))
* **34:** UI design contract .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-UI-SPEC.md ([50347fe](https://github.com/szTheory/oban_powertools/commit/50347fec9ff5bcdde008fa838078d7e0ce455e3f))
* **35-01:** record completion summary and tracking updates ([311191d](https://github.com/szTheory/oban_powertools/commit/311191dfff339d111d243b10ce26f44dcd9e5339))
* **35-02:** complete host escalation boundary plan ([725cebd](https://github.com/szTheory/oban_powertools/commit/725cebd359bb30f44aff252dd5e614c4c8923883))
* **35-03:** record completion and advance phase tracking ([9c3ced3](https://github.com/szTheory/oban_powertools/commit/9c3ced330cc9c0fefe69bd2e8e70718954522638))
* **35:** add validation strategy .planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-VALIDATION.md ([26e0ca1](https://github.com/szTheory/oban_powertools/commit/26e0ca10653f9d0def8f7d65587d1f11c539a456))
* **35:** capture phase context .planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-CONTEXT.md .planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-DISCUSSION-LOG.md ([9656c4a](https://github.com/szTheory/oban_powertools/commit/9656c4a282309f845c091a0f72e1bbbe31918063))
* **35:** research phase domain .planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-RESEARCH.md ([85028e6](https://github.com/szTheory/oban_powertools/commit/85028e6a9722b637142e8c248f7b92166572b7c2))
* **36:** capture phase context .planning/phases/36-docs-example-host-verification-support-truth-closure/36-CONTEXT.md .planning/phases/36-docs-example-host-verification-support-truth-closure/36-DISCUSSION-LOG.md ([3b10868](https://github.com/szTheory/oban_powertools/commit/3b10868d88911b5e9e91366d74a2652fb9e60f2a))
* **37-01:** backfill phase 32 FRN verification evidence ([8a742e1](https://github.com/szTheory/oban_powertools/commit/8a742e1389ce94e7e5e96290fa7ad5c19ae0f3e1))
* **37-01:** record execution summary for phase-32 verification backfill ([82075dc](https://github.com/szTheory/oban_powertools/commit/82075dcb214d976b1a50b230aeb1b1c53caefdb5))
* **37-02:** backfill phase 33 OPS verification evidence ([1b601ff](https://github.com/szTheory/oban_powertools/commit/1b601ff3b987ba4692c0a6555f7bce5f5ad7684d))
* **37-02:** record execution summary for phase-33 verification backfill ([a87d1fd](https://github.com/szTheory/oban_powertools/commit/a87d1fd28b5738965b8a716a7c42352685ed4c5a))
* **37-03:** reconcile FRN and OPS traceability to canonical verification reports ([80418c9](https://github.com/szTheory/oban_powertools/commit/80418c9780b9dde94a563fb1a0ec0b6e0cc43b71))
* **37-03:** record reconciliation summary for phase traceability backfill ([40a1abc](https://github.com/szTheory/oban_powertools/commit/40a1abce552fc714055e78d3579509f91aadc032))
* **38-01:** add canonical forensics handoff guide ([22bbda2](https://github.com/szTheory/oban_powertools/commit/22bbda24adbb93cffd3faa6c4c93692e32048c6a))
* **38-01:** align README and operator spokes to canonical journey ([5b98475](https://github.com/szTheory/oban_powertools/commit/5b984759de4f39aa508331797dc3021dd76bcca1))
* **38-01:** record execution summary ([69a02b2](https://github.com/szTheory/oban_powertools/commit/69a02b24d2123ec464c7c373847bc8ef5ee01677))
* **38-02:** add fixture forensics handoff walkthrough section ([a5d4cae](https://github.com/szTheory/oban_powertools/commit/a5d4cae1b3aa0bd94030ce7011c3701274d2cf32))
* **38-02:** lock fixture escalation and canonical handoff links ([a297476](https://github.com/szTheory/oban_powertools/commit/a297476a4f01d65fbf3c257a18ba714e6e5fa08e))
* **38-02:** record fixture docs alignment summary ([6728fbd](https://github.com/szTheory/oban_powertools/commit/6728fbd949207dbb95392a10fb26fcf04cc6384d))
* **38-03:** publish DOC-05 claim-to-evidence verification report ([59cf712](https://github.com/szTheory/oban_powertools/commit/59cf7120f5f0c146cba91e8d84c161aba6624074))
* **38-03:** reconcile DOC-05 traceability after verification ([997d304](https://github.com/szTheory/oban_powertools/commit/997d30426e6fe0c7fd0f51d817a0660f0bb109a4))
* **38-03:** record docs-contract closure summary ([04ab21c](https://github.com/szTheory/oban_powertools/commit/04ab21c94d41c1ca54419d436b3f5aaac4fac47b))
* **38:** capture phase context .planning/phases/38-docs-example-host-forensics-journey-closure/38-CONTEXT.md .planning/phases/38-docs-example-host-forensics-journey-closure/38-DISCUSSION-LOG.md ([205de7e](https://github.com/szTheory/oban_powertools/commit/205de7e5bcc68c546eb6b89f34e73d6ae5e8410e))
* **39-01:** complete continuity proof lane wiring plan ([6a24145](https://github.com/szTheory/oban_powertools/commit/6a24145d5116f89f07bea16ae16fa48631a7feea))
* **39-02:** complete continuity proof lane closure plan ([5ff1e31](https://github.com/szTheory/oban_powertools/commit/5ff1e318b122d39d60d2ff0a11e9abb642b65d1a))
* **39-03:** complete continuity proof lane closure plan ([69a0be5](https://github.com/szTheory/oban_powertools/commit/69a0be54abe89763853bc112d439fa030c2f94cc))
* **41-01:** complete runbook link fidelity and atom safety hardening plan summary ([ef5ea78](https://github.com/szTheory/oban_powertools/commit/ef5ea7892ec138e323b15a42c91ff625aff3aa80))
* **41:** add code review report ([dbaadeb](https://github.com/szTheory/oban_powertools/commit/dbaadeb092488fa06d17cb16c0313a3a8511e209))
* **41:** add validation strategy for selector and atom safety hardening ([fa4eef1](https://github.com/szTheory/oban_powertools/commit/fa4eef103afb2545c648c7d9f647bf0642d58e8b))
* **41:** capture phase context ([3ca5f32](https://github.com/szTheory/oban_powertools/commit/3ca5f3275c9e8b1a77d8554fd207a5ccf82faf2f))
* **41:** map analog files for selector and atom safety helpers ([2a357d4](https://github.com/szTheory/oban_powertools/commit/2a357d4c4fce5827575244fb13835dea63d01c71))
* **41:** replan 41-01 as single bundled hardening plan and update ROADMAP ([24aa22c](https://github.com/szTheory/oban_powertools/commit/24aa22cdcdc6c8cf3d341d1a8d9ca4ba6f94409d))
* **41:** research selector encoding and atom safety patterns ([f7bc4e6](https://github.com/szTheory/oban_powertools/commit/f7bc4e6776da1dbf92436be62207904225add645))
* **41:** update REVIEW.md status to fixed after applying all CR/WR fixes ([4632a62](https://github.com/szTheory/oban_powertools/commit/4632a627088dc8e60b704c188fab47da2bdbdf71))
* **42-01:** backfill and normalize validation artifacts for phases 33/34/38/39 ([723bfc3](https://github.com/szTheory/oban_powertools/commit/723bfc335102e0bbc1960f25a34350612204a187))
* **42-01:** complete Nyquist validation compliance sweep plan ([44965cb](https://github.com/szTheory/oban_powertools/commit/44965cb574dcf73dac3e173752815ec67349179e))
* **42-01:** publish Nyquist validation closure evidence report ([ba38b36](https://github.com/szTheory/oban_powertools/commit/ba38b361b84ca06cce2dd7b8efa6e4f0f53feced))
* **42:** add code review report ([8b8cd17](https://github.com/szTheory/oban_powertools/commit/8b8cd175ab723b9b185d0ee0a3a24e4fe46bc55e))
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
* **6-03:** close phase 6 verification evidence ([e6ed163](https://github.com/szTheory/oban_powertools/commit/e6ed1638d2b83c848aef8f8dfeaefc7c3a182546))
* **8-01:** record plan 01 execution summary ([32f6547](https://github.com/szTheory/oban_powertools/commit/32f65479dfce3725aec13e8864553d8a52541c59))
* **8-02:** complete route mount contract plan ([29039d4](https://github.com/szTheory/oban_powertools/commit/29039d4327a76f8397cbf6f17abff5de3b53d544))
* **8-02:** document host-owned router boundary ([d954292](https://github.com/szTheory/oban_powertools/commit/d9542923e02bd7b4ab920b31877edef091d29daa))
* **8-03:** publish host contract guidance ([061f9d9](https://github.com/szTheory/oban_powertools/commit/061f9d96d1e39d2e10bc4596f498cfaf9476e84a))
* **8-03:** record plan 03 execution summary ([9eb728d](https://github.com/szTheory/oban_powertools/commit/9eb728df857bd12c27e441e5bbe6ee7491141085))
* **9-01:** record plan 01 execution summary ([3a52568](https://github.com/szTheory/oban_powertools/commit/3a52568df4e854a1afce0aec8351f18ead8e46b7))
* **9-02:** record plan 02 execution summary ([f2508bf](https://github.com/szTheory/oban_powertools/commit/f2508bf247e28de0975a05be4a5f32b9305aa102))
* **9-03:** publish optional bridge support truth ([c9775b2](https://github.com/szTheory/oban_powertools/commit/c9775b221a6e7dffa07288bd822c06521db3394e))
* **9-03:** record plan 03 execution summary ([bd31dff](https://github.com/szTheory/oban_powertools/commit/bd31dff7309ebc36a7f8c070b75528061525b5dc))
* complete adopter-facing contract ([82fe354](https://github.com/szTheory/oban_powertools/commit/82fe3542cd29c9513ad8ffdf9d764136aa611c3a))
* complete project research .planning/research/ ([c335e8d](https://github.com/szTheory/oban_powertools/commit/c335e8df189d87717a52115e39b0b1f220c29d0f))
* create milestone v1.5 roadmap (4 phases, 6 requirements) ([b04f06e](https://github.com/szTheory/oban_powertools/commit/b04f06ed623beb5495e5292f43526dc2b38361e7))
* create milestone v1.6 roadmap (5 phases) ([cf763fb](https://github.com/szTheory/oban_powertools/commit/cf763fb9855446c0681ed255912f4c887c0bb335))
* define milestone v1.4 requirements ([baec750](https://github.com/szTheory/oban_powertools/commit/baec7509b7e5e2c9b5f395e0f26c1834dd6d7e00))
* define milestone v1.5 requirements (QRY-01..04, API-01..02) ([dda12e8](https://github.com/szTheory/oban_powertools/commit/dda12e8bf2edce6b964439b42afc316b134438c3))
* define milestone v1.6 requirements ([b84b860](https://github.com/szTheory/oban_powertools/commit/b84b860f84267170f14a390b89bc48d5ab8fe55d))
* finalize v1.6 PITFALLS research ([6397f3e](https://github.com/szTheory/oban_powertools/commit/6397f3e62d3cabb18988934fb377315496151a8d))
* **phase-10:** complete phase execution ([2d14633](https://github.com/szTheory/oban_powertools/commit/2d14633db82b06d14be50a3e3bdb581c313c7827))
* **phase-12:** complete phase execution ([9d1faa2](https://github.com/szTheory/oban_powertools/commit/9d1faa28078323bb8a27a8d3cea209dd230baf34))
* **phase-14:** complete phase execution ([4a50ca9](https://github.com/szTheory/oban_powertools/commit/4a50ca9028c3ca198deaf0fa93e2c9430f63f116))
* **phase-14:** fix review follow-up issues ([f0d2d67](https://github.com/szTheory/oban_powertools/commit/f0d2d67f2cab200a231c2f116ce576be0fda6957))
* **phase-15:** add/update security threat verification ([4d22f81](https://github.com/szTheory/oban_powertools/commit/4d22f8110c085aaa14dfa9328121b862739b100a))
* **phase-16:** complete phase execution ([d74ec52](https://github.com/szTheory/oban_powertools/commit/d74ec522154060d7c98fb258fb564ba726d644b1))
* **phase-25:** add planning artifacts ([16563ca](https://github.com/szTheory/oban_powertools/commit/16563ca12dfd6da7303e076ac02e5adf7f7faaff))
* **phase-25:** complete phase execution ([12aa2c0](https://github.com/szTheory/oban_powertools/commit/12aa2c04aeb3bb69cb9e3483fcc2f82cb56603c9))
* **phase-34:** complete phase execution .planning/ROADMAP.md .planning/STATE.md .planning/REQUIREMENTS.md .planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-VERIFICATION.md ([df06063](https://github.com/szTheory/oban_powertools/commit/df06063f70d37844f2103d6bb7f3afede0107ca3))
* **phase-34:** evolve PROJECT.md after phase completion .planning/PROJECT.md ([9f77ae8](https://github.com/szTheory/oban_powertools/commit/9f77ae80651b8481d1db960604d79028a4b8acae))
* **phase-35:** add/update security threat verification ([5807f89](https://github.com/szTheory/oban_powertools/commit/5807f890d01e61b67d0020ef2874ad307ed6d2bb))
* **phase-35:** complete phase execution .planning/ROADMAP.md .planning/STATE.md .planning/REQUIREMENTS.md .planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-VERIFICATION.md ([590f6f4](https://github.com/szTheory/oban_powertools/commit/590f6f48847c0537977b1f8937f878a3e32cbd3c))
* **phase-35:** evolve PROJECT.md after phase completion .planning/PROJECT.md ([188dc54](https://github.com/szTheory/oban_powertools/commit/188dc542b28c7210b5d1a3e1714ff7d80e586f72))
* **phase-36:** complete reconciliation closure execution ([6e12175](https://github.com/szTheory/oban_powertools/commit/6e1217550e38c7ec21f946c78c5c4cdaba8b3e5a))
* **phase-37:** complete verification backfill execution ([5c87975](https://github.com/szTheory/oban_powertools/commit/5c879751b7e3820211d97ee1da7656bb9c39b729))
* **phase-37:** evolve project state after verification backfill ([b52d775](https://github.com/szTheory/oban_powertools/commit/b52d7751aa630db4c09bd95bbf1aa20dcb99c06e))
* **phase-38:** complete phase execution tracking ([8b9c54e](https://github.com/szTheory/oban_powertools/commit/8b9c54e2eafc046384df16606955c1b9ec670b0f))
* **phase-38:** evolve PROJECT baseline after DOC-05 closure ([0308963](https://github.com/szTheory/oban_powertools/commit/0308963a1476bac2edb7e8cb17a3ef9e2d226208))
* **phase-39:** complete phase execution .planning/ROADMAP.md .planning/STATE.md .planning/phases/39-ci-continuity-proof-lane-closure/39-REVIEW.md ([0ff982a](https://github.com/szTheory/oban_powertools/commit/0ff982a812af52d1df91f0caed43cca34173f13a))
* **phase-40:** update tracking after automated-proxy closure ([e1e614f](https://github.com/szTheory/oban_powertools/commit/e1e614f887698ce61c9f131f5685dff2f384c34a))
* **phase-41:** complete phase execution ([79eaf4a](https://github.com/szTheory/oban_powertools/commit/79eaf4afc451c7b1e6a9846ec9ed0333216f7b62))
* **phase-41:** evolve PROJECT.md after phase completion ([1c9ab07](https://github.com/szTheory/oban_powertools/commit/1c9ab0734073899de25840d9a06f2159d9da6d79))
* **phase-41:** update tracking after wave 1 ([da8f28f](https://github.com/szTheory/oban_powertools/commit/da8f28f7e13ea04b85cf399b608826468bdeb5ef))
* **phase-42:** complete phase execution ([0a7453c](https://github.com/szTheory/oban_powertools/commit/0a7453c4cb45cb77ed066163eb87cbc814191712))
* **phase-42:** evolve PROJECT.md after phase completion ([191b497](https://github.com/szTheory/oban_powertools/commit/191b497f4a7ad83e7d23ab1df7500d3f01d675f0))
* **phase-42:** update tracking after wave 1 ([5dddbc3](https://github.com/szTheory/oban_powertools/commit/5dddbc3f31b076b17b34d3f5f11fb5360311d160))
* **phase-43:** complete phase execution ([00e8ff5](https://github.com/szTheory/oban_powertools/commit/00e8ff559005ecbc04455ff54a58fcffc87063d9))
* **phase-43:** evolve PROJECT.md after phase completion ([6ae10bd](https://github.com/szTheory/oban_powertools/commit/6ae10bd430462133fd68ce92126df8dacc238f7f))
* **phase-43:** update tracking after wave 1 ([ea73a4a](https://github.com/szTheory/oban_powertools/commit/ea73a4a409f83ae4139e0222f1414909ebab1069))
* **phase-43:** update tracking after wave 2 ([a044329](https://github.com/szTheory/oban_powertools/commit/a04432900f856475640b6a8fb2959cd3cc729097))
* **phase-43:** update tracking after wave 3 ([bc7c8ac](https://github.com/szTheory/oban_powertools/commit/bc7c8ac6c57385fc5182fa6d098b17beabc7ea9e))
* **phase-6:** restore planning artifacts ([59713cb](https://github.com/szTheory/oban_powertools/commit/59713cbab1c261a8ea8daf634d753d22284d6799))
* **phase-8:** complete phase execution ([dc24466](https://github.com/szTheory/oban_powertools/commit/dc2446604de3e29ff377765a6afee4d7402db139))
* **phase-9:** complete phase execution ([cef0055](https://github.com/szTheory/oban_powertools/commit/cef00552eb5db5508be7366b2c5c73f3339d9315))
* post-v1.4 adopter assessment and v1.5 ordering update ([66d113a](https://github.com/szTheory/oban_powertools/commit/66d113abc038b47e7307a166ac095c9f44ef4f92))
* post-v1.5 milestone assessment + next-step ordering ([9a13663](https://github.com/szTheory/oban_powertools/commit/9a136636eaa5f7a76ae9306403868e6aa4247d47))
* reconcile phase 33 planning state ([b7b99ec](https://github.com/szTheory/oban_powertools/commit/b7b99ecc3ddbb61a00929cb8cca50ad49be7978b))
* **requirements:** add deferred traceability rows ([9b96dbc](https://github.com/szTheory/oban_powertools/commit/9b96dbc168cf07a8481cc86a7e25925f3297fa32))
* research milestone v1.6 Release & Operability ([7250d94](https://github.com/szTheory/oban_powertools/commit/7250d9425836a4ba9b612f390321eed8b18d5247))
* research v1.5 native job surface and operator API (4 dimensions + synthesis) ([3d7856d](https://github.com/szTheory/oban_powertools/commit/3d7856d825e58bb7b572b0e691a3e663560e51ac))
* **roadmap:** add gap closure phases 12-15 ([51d768d](https://github.com/szTheory/oban_powertools/commit/51d768dac3f3c0d54253e7dc05edc152de590755))
* **roadmap:** add v1.4 gap-closure phases 40-42 ([50518a7](https://github.com/szTheory/oban_powertools/commit/50518a7036a8b6fb0f2ce996ff7789791328223a))
* start milestone v1.4 Operator Forensics & SRE Runbooks ([ca11617](https://github.com/szTheory/oban_powertools/commit/ca11617649a657ecc5e0b794be571176cba06a21))
* start milestone v1.5 Native Job Surface & Automation API ([9080fd9](https://github.com/szTheory/oban_powertools/commit/9080fd952adafb58d32942a7f6614061ec2573d3))
* start milestone v1.6 Release & Operability ([4cea872](https://github.com/szTheory/oban_powertools/commit/4cea872c590407265db222398b8c1c2a8ec76048))
* **state:** mark phase 34 ready to execute ([8fddf72](https://github.com/szTheory/oban_powertools/commit/8fddf7280c5d7c6f4ab779ca53467a7607928334))
* **state:** point handoff to phase 17 ([4d63a6f](https://github.com/szTheory/oban_powertools/commit/4d63a6f5a227de48cd6de0429d443d079c8b9576))
* **state:** record phase 34 context session .planning/STATE.md ([c93897a](https://github.com/szTheory/oban_powertools/commit/c93897a25553b35b9e34c47b3b581b2a4ec7bf45))
* **state:** record phase 35 context session .planning/STATE.md ([d6b0356](https://github.com/szTheory/oban_powertools/commit/d6b03565da8b24aa96be23e36d211427825669f6))
* **state:** record phase 36 context session .planning/STATE.md ([319c47b](https://github.com/szTheory/oban_powertools/commit/319c47b31547cc9e323374b95c5946a2348514b7))
* **state:** record phase 38 context session .planning/STATE.md ([0cbf641](https://github.com/szTheory/oban_powertools/commit/0cbf6414a4d305a2b938503e2a52336a85fe8d0d))
* **state:** record phase 41 context session ([ab00fac](https://github.com/szTheory/oban_powertools/commit/ab00fac697916923d5246463a6540f6d2d302183))
* **state:** record phase 43 context session ([1cd0867](https://github.com/szTheory/oban_powertools/commit/1cd086738b66b8c08bba3b501bd1f3dcbab35a20))
* **state:** record phase 47 context session ([6e713d3](https://github.com/szTheory/oban_powertools/commit/6e713d3438c0b9f64627b96b12044ecca209f415))
* **state:** record phase 6 completion ([8e6240e](https://github.com/szTheory/oban_powertools/commit/8e6240ea967a45779dbfd4c14ba359f4f5fc8b2d))
* update retrospective for v1.5 ([9e59059](https://github.com/szTheory/oban_powertools/commit/9e59059b057c30231eed7d06ef6262a0019734db))
* **v1.4-audit:** close remaining artifact gaps — 11/11 phases, 11/11 Nyquist compliant ([b1a2f2d](https://github.com/szTheory/oban_powertools/commit/b1a2f2d467ea1419470f956eda5a12656c653bd7))
* **v1.4-audit:** re-audit after gap-closure phases 40-42 — 12/12 reqs satisfied ([23729b0](https://github.com/szTheory/oban_powertools/commit/23729b099853b9f6484aaa952611ffbb583eef7d))
* **workflow:** document v2 compatibility baseline ([29b29f0](https://github.com/szTheory/oban_powertools/commit/29b29f05bebc96643c98f8d5700c6da2fd13f1aa))


### Miscellaneous

* bootstrap release-please at 0.5.0 ([#9](https://github.com/szTheory/oban_powertools/issues/9)) ([72b45aa](https://github.com/szTheory/oban_powertools/commit/72b45aa0d9c6e2f1193196c72c5de4d62c249909))

## [Unreleased]

<!-- Phases 48-51 accumulate entries here -->

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
