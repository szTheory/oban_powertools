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

## [1.1.0](https://github.com/szTheory/oban_powertools/compare/v1.0.0...v1.1.0) (2026-09-25)


### Features

* **76-03:** add scoped AppShell disclosure JS ([9cbcd1c](https://github.com/szTheory/oban_powertools/commit/9cbcd1cb22893f224eb637a5a8da20bcb38837b6))
* **76-03:** add token-backed AppShell CSS ([4db12a5](https://github.com/szTheory/oban_powertools/commit/4db12a524d582bb9955e4052152a672af0d00ee5))
* **76-04:** add shell targets to showcase manifest ([3307108](https://github.com/szTheory/oban_powertools/commit/3307108f2e9781335a9ade3409aadaaefa6bebe6))
* **76-04:** render app shell stories in showcase ([72698fe](https://github.com/szTheory/oban_powertools/commit/72698fe401be8ca3c851882fe264d90f1de72ea3))
* **77-02:** implement unified status taxonomy and wrapper ([02d1d82](https://github.com/szTheory/oban_powertools/commit/02d1d822bf42775be310da212617d27cd1ac0ff7))
* **77-03:** add responsive DataTable styling ([5b89019](https://github.com/szTheory/oban_powertools/commit/5b89019da1f418385d8edddbdb76c9725ebb6402))
* **77-03:** implement semantic DataTable ([04f3e2d](https://github.com/szTheory/oban_powertools/commit/04f3e2d896ca7b6926505f21b0ecd7ac1fb9cb1d))
* **77-04:** implement secondary display components ([fac597e](https://github.com/szTheory/oban_powertools/commit/fac597eed80510b60e5a850ee95d7d22e0e68ca6))
* **77-04:** style secondary display components ([60d01bf](https://github.com/szTheory/oban_powertools/commit/60d01bffd23a5de78acb3125bc47e312c40b43c5))
* **77-05:** render normalized displays safely ([0f04752](https://github.com/szTheory/oban_powertools/commit/0f047527c12d7e01ed5113421c781214df071083))
* **77-05:** style bounded redaction displays ([b39ab79](https://github.com/szTheory/oban_powertools/commit/b39ab795d50e8af7ef6d7873d59311c09734e5d6))
* **77-06:** generate schema 5 data targets ([7a9a790](https://github.com/szTheory/oban_powertools/commit/7a9a7908b0e813c4759e6a928b055cfb81c9b2c7))
* **77-06:** render deterministic data showcase stories ([b1f8699](https://github.com/szTheory/oban_powertools/commit/b1f8699a4d1d5b4774fe883e83bb17597650df81))
* **78-02:** add finite operator presentation foundation ([131647e](https://github.com/szTheory/oban_powertools/commit/131647ec975f41ae63acbeddd87bf2378f21d9cd))
* **78-02:** add operator explanation groups ([a2818e1](https://github.com/szTheory/oban_powertools/commit/a2818e11b13ef5c79983326c0ac819b4c1634eca))
* **78-03:** add stateless FilterBar composition ([4b76cfc](https://github.com/szTheory/oban_powertools/commit/4b76cfc0a65fbd4aeb2312e67ee32721d9569098))
* **78-04:** add authoritative confirmation composition ([f4e3422](https://github.com/szTheory/oban_powertools/commit/f4e34220689b0ecddb04c3fe3fb753db47cbb248))
* **78-05:** add adaptive detail surface ([8769fb1](https://github.com/szTheory/oban_powertools/commit/8769fb1b88c5b5c06ae7bd75f7f8e26d08583a09))
* **78-05:** synchronize native detail dialogs ([f946bfd](https://github.com/szTheory/oban_powertools/commit/f946bfd561684087a93ab13ccf4104ecf4707d61))
* **78-06:** add deterministic operator story catalog ([724e86b](https://github.com/szTheory/oban_powertools/commit/724e86bc3ebcfa357ee0b00c5a8ed9165e47e002))
* **78-06:** add schema 6 group manifest ([7e6a938](https://github.com/szTheory/oban_powertools/commit/7e6a938749934cbedbae6f90eecc6b0e865017ae))
* **78-06:** connect operator stories to showcase ([a1b37fe](https://github.com/szTheory/oban_powertools/commit/a1b37fe3e3fc1a20aea516f4aca09bc9db156d39))
* **79-02:** add bounded audit pagination ([a2e3489](https://github.com/szTheory/oban_powertools/commit/a2e3489f2043b9c3860463cf209d383fa49ff56b))
* **79-02:** add finite page presenters ([6bf0be3](https://github.com/szTheory/oban_powertools/commit/6bf0be3bf786ad75c9b6021776f8bfdc2e36369e))
* **79-02:** extend shared evidence components ([52ba43b](https://github.com/szTheory/oban_powertools/commit/52ba43bb7a6ba944cd4f7e78e3e9c8d99fd6242e))
* **79-03:** compose stable overview hierarchy ([023019d](https://github.com/szTheory/oban_powertools/commit/023019d80bfa1e1e00fcf29955bced05d10a6fb5))
* **79-03:** make overview input deterministic ([e8b2dc2](https://github.com/szTheory/oban_powertools/commit/e8b2dc2d8eeebf4415bcec2d49f053ca00c22f6b))
* **79-04:** add selection-first cron detail ([cfe0c8f](https://github.com/szTheory/oban_powertools/commit/cfe0c8f11fe2033a849d5ce62b1fe880f963d37a))
* **79-04:** expose reusable cron page composition ([951114d](https://github.com/szTheory/oban_powertools/commit/951114d4c2c53795535eb001c71b8d0e1464da34))
* **79-04:** preserve durable cron confirmation authority ([704bfeb](https://github.com/szTheory/oban_powertools/commit/704bfeb7b806866ba7f8bb5d5a18bd04ccc27266))
* **79-05:** batch limiter evidence reads ([a225bce](https://github.com/szTheory/oban_powertools/commit/a225bcecc602e06ca4bbc0b6272ef20da782cf15))
* **79-05:** compose limiter scan and detail ([628829c](https://github.com/szTheory/oban_powertools/commit/628829c97a59e1709cee63a5e820b2b394fc85b7))
* **79-06:** add scoped Audit selection and URL state ([f50e4b1](https://github.com/szTheory/oban_powertools/commit/f50e4b1e4cf5557261f368dcb8102aa32b345a20))
* **79-06:** compose reusable Audit scan and detail ([6b15e1f](https://github.com/szTheory/oban_powertools/commit/6b15e1f990472c6cf34ac94f4b0ad591d5a2e3e2))
* **79-06:** normalize bounded Audit presentation state ([b29672f](https://github.com/szTheory/oban_powertools/commit/b29672fcf1cd8cce81c090f26f33cddc81b8951d))
* **79-07:** add deterministic page composition CSS ([62d3e9d](https://github.com/szTheory/oban_powertools/commit/62d3e9de6236ce11b89cbae781f5df713ef5e4f4))
* **79-10:** add fail-closed fixture browser proof ([8558b1b](https://github.com/szTheory/oban_powertools/commit/8558b1babc43093e8f05b774f9eb3a8d28c00b23))
* **79-10:** add isolated browser fixture seam ([02a020c](https://github.com/szTheory/oban_powertools/commit/02a020c17a27f0ab6a1df4da0f8689a06803e646))
* **79-11:** add production-composed page stories ([61d4900](https://github.com/szTheory/oban_powertools/commit/61d4900dbb5742e903de985f8d60b2f1c4a37e86))
* **79-12:** add schema 7 page showcase targets ([a12ead3](https://github.com/szTheory/oban_powertools/commit/a12ead3ad801580da450451d77143d51be25b496))
* **80-01:** add bounded Jobs query primitives ([7445f6c](https://github.com/szTheory/oban_powertools/commit/7445f6cfa095847b0d50cc5b1e9e0e9ec49beb88))
* **80-01:** add canonical Jobs URL contracts ([cd2e112](https://github.com/szTheory/oban_powertools/commit/cd2e112880489faa9cabcedb6ef08bf56214db9f))
* **80-02:** add closed Jobs browse presenters ([d8f5bf6](https://github.com/szTheory/oban_powertools/commit/d8f5bf6e4b96520136d833d7fb6c7d5fb9ba9382))
* **80-02:** compose bounded Jobs quick review ([ade3e88](https://github.com/szTheory/oban_powertools/commit/ade3e885d8b60445aaf5762c15c87c98f1134fda))
* **80-03:** compose canonical redacted job detail ([6a2f082](https://github.com/szTheory/oban_powertools/commit/6a2f082cbc52c207d46563275d366bedeecb76eb))
* **80-03:** present bounded job detail and actions ([bcbbda3](https://github.com/szTheory/oban_powertools/commit/bcbbda3e1eb484717db42bd8c5fa8640e0bba84d))
* **80-03:** share Lifeline job confirmation ([4ce9aa8](https://github.com/szTheory/oban_powertools/commit/4ce9aa8b8efc4ab33647cade0cd7771597f8b981))
* **80-04:** bound supervised Jobs bulk work ([e52d0c8](https://github.com/szTheory/oban_powertools/commit/e52d0c8a648b25be84f38ad9925629acb829ab68))
* **80-04:** coordinate frozen Jobs batch work ([e81c8ba](https://github.com/szTheory/oban_powertools/commit/e81c8baa6ba576da95a5568392377d0f2dc8b62e))
* **80-04:** integrate supervised Jobs bulk recovery ([c50731e](https://github.com/szTheory/oban_powertools/commit/c50731e7e4ab9eb88af417153a2e0c9e82aaff98))
* **80-05:** add bounded forensic audit windows ([91138cb](https://github.com/szTheory/oban_powertools/commit/91138cbdbe0c7cb7f82ad82e8cb75829278cb837))
* **80-05:** implement typed forensic scope grammar ([bb86617](https://github.com/szTheory/oban_powertools/commit/bb866172b7b155c441c22573c8e558905d08a134))
* **80-06:** assemble bounded forensic evidence ([21a479b](https://github.com/szTheory/oban_powertools/commit/21a479bc26d392157db5b5a0199b92a90391d76f))
* **80-07:** add typed forensics scope state ([ca3d992](https://github.com/szTheory/oban_powertools/commit/ca3d992a0afda6e96860577d8e4957fa083ec936))
* **80-07:** render diagnosis-first forensics page ([0004e8a](https://github.com/szTheory/oban_powertools/commit/0004e8ae5793598cc7c7fdd0ac959bfb9ba406fa))
* **80-08:** compose jobs and forensics stories ([b2e0581](https://github.com/szTheory/oban_powertools/commit/b2e0581d08537d8acffb792a422d5cde896aa7c2))
* **80-09:** generate expanded page manifest ([7d37ef1](https://github.com/szTheory/oban_powertools/commit/7d37ef1309a0c066fe0a86dfa1172f521cae7531))
* **80-10:** add isolated Phase 80 fixture seam ([cc93a15](https://github.com/szTheory/oban_powertools/commit/cc93a15b67b1131acb377c5a2d2e870408ee0ade))
* **80-10:** bridge Phase 80 browser fixtures ([d729608](https://github.com/szTheory/oban_powertools/commit/d72960866d84704eb1cc1179e0f3f5f48e9d2391))
* **80-12:** compose Jobs and Forensics pages ([7c201d5](https://github.com/szTheory/oban_powertools/commit/7c201d54c1a9dacda174b80aa7eae9b171ed15ee))
* **80-13:** extend production VoiceOver coverage ([e4f0879](https://github.com/szTheory/oban_powertools/commit/e4f087990858cfb23fcff0fefbfde83eb166f39a))
* **81-02:** add closed batch presentation maps ([ec83e5a](https://github.com/szTheory/oban_powertools/commit/ec83e5a23d112cb6554ae7fd477d59eaecf21069))
* **81-02:** migrate bounded Batches composition ([778d46f](https://github.com/szTheory/oban_powertools/commit/778d46fa8f61995d22354b7caf97435b278b2546))
* **81-03:** close workflow selector and presenter maps ([5e0ca51](https://github.com/szTheory/oban_powertools/commit/5e0ca51389d59bd0684bf8acb0ba33d395495427))
* **81-03:** migrate bounded Workflows composition ([a03d92d](https://github.com/szTheory/oban_powertools/commit/a03d92d0aa4ebb64dd766f802640348ea3b7e0e7))
* **81-04:** close Lifeline presentation maps ([61f8bca](https://github.com/szTheory/oban_powertools/commit/61f8bca8f03ae84eee928014259804c6aac41d4f))
* **81-05:** migrate Lifeline shared composition ([2feba66](https://github.com/szTheory/oban_powertools/commit/2feba6644ebe52e2b2825d2b304d3a6849fa9f68))
* **81-06:** compose Wave 3 showcase stories ([682c392](https://github.com/szTheory/oban_powertools/commit/682c392d7a9a9dae38bc9ac9f2c359b01dc1d9e6))
* **81-10:** add Wave 3 page composition CSS ([dbf0144](https://github.com/szTheory/oban_powertools/commit/dbf01440cc264e412b20d5bf9081f8ab0dae21fb))
* **82-03:** add sole quality policy validator ([707be93](https://github.com/szTheory/oban_powertools/commit/707be93c4e0931a5b1e564edc0b5eec04b777ff6))
* **82-04:** enforce fail-closed axe policy ([86e59a4](https://github.com/szTheory/oban_powertools/commit/86e59a49e6b98e740fee0dd2a05ee7222b5d859a))
* **82-04:** implement bounded system quality auditors ([40dced1](https://github.com/szTheory/oban_powertools/commit/40dced1a68bf096c70beb650c404d8e3ffd4fc1c))
* **82-10:** wire strict page quality graph ([64665de](https://github.com/szTheory/oban_powertools/commit/64665de27d4a502192827d7162d46a361c086a05))
* **82-17:** add finite copy policy ([bd44ec5](https://github.com/szTheory/oban_powertools/commit/bd44ec527730aac96fb1da7ba410a47f626ba0f7))
* **82-17:** project copy policy in manifest ([71635f7](https://github.com/szTheory/oban_powertools/commit/71635f747cff9d26e177eb871209b9d12f09c523))


### Bug Fixes

* **76-05:** finalize shell browser behavior proof ([bfee582](https://github.com/szTheory/oban_powertools/commit/bfee58248bb0008a61412c721f2810a1d3830bb7))
* **76:** resolve app shell review warnings ([057d20d](https://github.com/szTheory/oban_powertools/commit/057d20d4f84033d321a1689aed8a62f8fc42f91d))
* **77-06:** exercise progress clamp in showcase ([6f1c46b](https://github.com/szTheory/oban_powertools/commit/6f1c46bc039f9755cab8aafa7e07628cb03529a5))
* **77-07:** await live showcase readiness ([a79714b](https://github.com/szTheory/oban_powertools/commit/a79714bc1bae5c4897c0179875362c6e12c3edc6))
* **77-07:** enable live showcase browser events ([d1b5a3c](https://github.com/szTheory/oban_powertools/commit/d1b5a3c91ab9f6f53969c0978f9a11dbad1cdda5))
* **77-08:** fail closed for absent progress values ([67a41cc](https://github.com/szTheory/oban_powertools/commit/67a41cc3a7e2cddd3a40d9b835ebf37ccb973d1a))
* **77-08:** preserve keyed Phoenix flash dismissal ([a97f964](https://github.com/szTheory/oban_powertools/commit/a97f9642455a9dee7568d6ebf490a042752079e8))
* **77-09:** fail closed for optional data catalogs ([a180a6a](https://github.com/szTheory/oban_powertools/commit/a180a6ac40feaa9a6b36ae138efc337dea535170))
* **78-04:** suppress sensitive harness event logs ([51f3830](https://github.com/szTheory/oban_powertools/commit/51f383091f17a4dee0b5373b5c4c2b1c0e8bab29))
* **78-08:** make detail scrolling keyboard accessible ([b8ca6af](https://github.com/szTheory/oban_powertools/commit/b8ca6afa210f875e41ca9f736c48f0136e35b229))
* **78:** capture complete overlay visual targets ([4462e54](https://github.com/szTheory/oban_powertools/commit/4462e5448391abbc28a83fa004ee58cdf703d261))
* **78:** CR-01 close audit evidence schema ([abd3370](https://github.com/szTheory/oban_powertools/commit/abd3370fe590ac8d9c746fb6b2c5df6fb3c33e79))
* **78:** CR-01 reject sensitive audit evidence fields ([13a722b](https://github.com/szTheory/oban_powertools/commit/13a722ba64625f608e9087ffef5f3b48ae8dbc5c))
* **78:** finalize canonical group browser evidence ([8f071d4](https://github.com/szTheory/oban_powertools/commit/8f071d4a18ab6e01fe74ed6f8f5a054b0cbb5760))
* **78:** focus scrollable confirmation dialogs ([156d8a9](https://github.com/szTheory/oban_powertools/commit/156d8a9f1aa45951088b14591661699438eb5097))
* **78:** WR-01 lock submitting confirmations ([89f687b](https://github.com/szTheory/oban_powertools/commit/89f687bed22b56551c95e1f7c9cb30a1e4bde06d))
* **78:** WR-02 preserve audit outcome semantics ([473df91](https://github.com/szTheory/oban_powertools/commit/473df91c4f51073f6a4880d4760bd38a168e29b3))
* **78:** WR-03 render full attention matrix ([c960fc9](https://github.com/szTheory/oban_powertools/commit/c960fc98f7893bfcae92ff13cd650b3d1b49a06b))
* **78:** WR-04 refresh attention matrix baselines ([59d51e4](https://github.com/szTheory/oban_powertools/commit/59d51e423ff1dd4726d78836e664283be7216a26))
* **78:** WR-04 stabilize canonical attention baselines ([1f1e4b5](https://github.com/szTheory/oban_powertools/commit/1f1e4b57948a78cf965d030a5de5dd20328f32a5))
* **79-10:** allow fixture browser websocket origin ([3bd6af2](https://github.com/szTheory/oban_powertools/commit/3bd6af2255fc8cc637ea44e09683a8bf3ec92c17))
* **79-10:** clean isolated fixture builds reliably ([3ac956e](https://github.com/szTheory/oban_powertools/commit/3ac956e1a1ddc39a97c17a6f79c96b18aa5dd496))
* **79-10:** isolate concurrent browser projects ([acda8db](https://github.com/szTheory/oban_powertools/commit/acda8db22ddd963b565d7220322aeaeb3c0c492e))
* **79-10:** isolate fixture server build cache ([e2031e3](https://github.com/szTheory/oban_powertools/commit/e2031e349d66d8066de3f4af4ed82269d53e7353))
* **79-10:** perturb active cron previews ([5958c50](https://github.com/szTheory/oban_powertools/commit/5958c509763cd4f871762ff2b0b20d4e2c4b37ed))
* **79-10:** recompile opt-in fixture gates ([d12c3f7](https://github.com/szTheory/oban_powertools/commit/d12c3f755b5428b2e57c9e28fc3b1598bdef7669))
* **79-10:** retry fixture build cleanup quietly ([e5cb1bd](https://github.com/szTheory/oban_powertools/commit/e5cb1bd9fb226b789a8fe98d7ae8ad3119c66873))
* **80-02:** label the Jobs results region ([7169c6c](https://github.com/szTheory/oban_powertools/commit/7169c6c594c9c350f044046453c88325de8f1f8a))
* **80-07:** pin forensics page semantics ([55c4c3b](https://github.com/szTheory/oban_powertools/commit/55c4c3b86a0cb8b52bfc528cc5976a9499d8a7ae))
* **80-08:** correct page story contracts ([c1b19b4](https://github.com/szTheory/oban_powertools/commit/c1b19b4da1d6fc5e1e435eed0930df3d2eab1569))
* **80-09:** correct page acceptance harness ([62b799c](https://github.com/szTheory/oban_powertools/commit/62b799ccfbc977da94ed06b495984d93ea799509))
* **80-12:** preserve Jobs table scan density ([9fd66c8](https://github.com/szTheory/oban_powertools/commit/9fd66c81c630e8277c7ddd17800af526642993bb))
* **80-12:** synchronize Jobs page tri-state ([851b04d](https://github.com/szTheory/oban_powertools/commit/851b04da1b454acfb2d7860a74782984253f6c1d))
* **80-14:** bind step evidence to validated workflow ([e3a5072](https://github.com/szTheory/oban_powertools/commit/e3a5072ccea137cb7d4e0bd431831548428591aa))
* **80-15:** bound Jobs URL database integers ([4e3d33b](https://github.com/szTheory/oban_powertools/commit/4e3d33b761e3bbe2fefd1c4d15643d78f500a2a4))
* **80-15:** preserve frozen batch result identity ([7e4f7d0](https://github.com/szTheory/oban_powertools/commit/7e4f7d0b6768d932e1c233506f7e2d057b539f37))
* **80-17:** bound canonical Jobs detail IDs ([8a8fd81](https://github.com/szTheory/oban_powertools/commit/8a8fd812d119da2554e7079a8cbe30ece980059b))
* **80:** align page story evidence contracts ([0a117b5](https://github.com/szTheory/oban_powertools/commit/0a117b5cae9cbfa447c98c08e4003bc199259cc4))
* **81-05:** close connected Lifeline fixture flow ([c5f805c](https://github.com/szTheory/oban_powertools/commit/c5f805c2e101e82bcd4be5eec23cf293fcefe97e))
* **81-08:** isolate connected Lifeline target ([723fbc9](https://github.com/szTheory/oban_powertools/commit/723fbc97de41b796b296dcd4fd485778d62bd74a))
* **81-08:** scope Lifeline visible-copy scan ([9febd6e](https://github.com/szTheory/oban_powertools/commit/9febd6eb3a9b47eee37b2e0088516e0ed3317cc1))
* **81-09:** align Wave 3 activation metadata ([a3ebe4d](https://github.com/szTheory/oban_powertools/commit/a3ebe4d5206c9c303c3f0e1fa9090b019867363e))
* **81-11:** make Workflows stories semantically distinct ([c753e65](https://github.com/szTheory/oban_powertools/commit/c753e6579789ea265a94585d6293ccce4de2f1d4))
* **81-14:** accept nine-family page graph in Wave 1 gate ([872218e](https://github.com/szTheory/oban_powertools/commit/872218e182f7585754680080ceee2c2133cefcaa))
* **81-14:** close final format and ARIA gates ([37365c1](https://github.com/szTheory/oban_powertools/commit/37365c1718a47e821759ea259bc2c0f7b979912b))
* **81-14:** close package and host contract gates ([fa1ef20](https://github.com/szTheory/oban_powertools/commit/fa1ef207458275d9cf12964c49d1769bbfcf4cf8))
* **81-14:** restore Lifeline dialog focus ([5618805](https://github.com/szTheory/oban_powertools/commit/561880526ab8cf6d01b5b78ecb17f7d416aa49df))
* **81:** CR-01 filter failed batch members before limiting ([b7c31f9](https://github.com/szTheory/oban_powertools/commit/b7c31f914e598a38ad7f15708dd7144f0d007f20))
* **81:** CR-02 select latest workflow result per step ([169bb5d](https://github.com/szTheory/oban_powertools/commit/169bb5d67948d38f0b22142d92893883996ccbae))
* **81:** CR-03 bound lifeline incidents by display priority ([e461169](https://github.com/szTheory/oban_powertools/commit/e461169ad11d157fc9b9c074715f030cee45c1fe))
* **81:** CR-04 filter lifeline audits before bounding ([23d8b3b](https://github.com/szTheory/oban_powertools/commit/23d8b3b0ffcf8c7bfca51c97d4b67ec835493d2b))
* **81:** CR-05 describe callback retry targets accurately ([dc7ddb0](https://github.com/szTheory/oban_powertools/commit/dc7ddb059ee0114c5959a6ff38905a0a7a091f91))
* **81:** make Lifeline showcase outcomes truthful ([305ae84](https://github.com/szTheory/oban_powertools/commit/305ae849c1a5d7f1f49b920e7080534f01d5d6c3))
* **81:** remediate wave 3 UI review findings ([28b721e](https://github.com/szTheory/oban_powertools/commit/28b721e62d7a32ffe3460366b6bdef26194e4011))
* **81:** WR-01 drive connected Lifeline race outcomes ([7971830](https://github.com/szTheory/oban_powertools/commit/7971830bf8067b00a581ebb809e16dcdd6941d00))
* **81:** WR-01 prove supported Lifeline outcomes ([213a9fe](https://github.com/szTheory/oban_powertools/commit/213a9fe6b1d44b22adb1a9745de25f9bf1ed0a62))
* **81:** WR-02 correct Audit event matcher ([08c5a7f](https://github.com/szTheory/oban_powertools/commit/08c5a7f133f6c8c5f4ec131d8c76a400b4f679a8))
* **81:** WR-02 seed and prove bounded fixture families ([1632c5d](https://github.com/szTheory/oban_powertools/commit/1632c5d5f037c26c05338aa52d45643990879069))
* **81:** WR-03 remove false archive window contract ([e97f3a8](https://github.com/szTheory/oban_powertools/commit/e97f3a88c6f663adadf3287b83e54cd6218bb3bf))
* **82-04:** redact axe URL and exception failures ([5c158af](https://github.com/szTheory/oban_powertools/commit/5c158af5c8390522ddc9e283b29ff6c85e02545e))
* **82-05:** harden shared accessibility tokens ([1caab7f](https://github.com/szTheory/oban_powertools/commit/1caab7f1d91afcc7dcd844c7d1a8e2f7407943fe))
* **82-06:** preserve shared control semantics ([c40581d](https://github.com/szTheory/oban_powertools/commit/c40581db906f1fdabe82ec7f98356b248b170acb))
* **82-07:** harden first page copy and recovery ([adbef12](https://github.com/szTheory/oban_powertools/commit/adbef12afcc3e21a5e899e173ceafaa8af41fe66))
* **82-11:** enforce primitive link target size ([61eac16](https://github.com/szTheory/oban_powertools/commit/61eac169b61f33d55cb8e1735fac1a38e027f1f2))
* **82-11:** harden exhaustive quality artifacts ([51dfbfa](https://github.com/szTheory/oban_powertools/commit/51dfbfaaf9bb9d02456b37126326e0d5eacbac8f))
* **82-11:** make Lifeline projection race-safe ([69045b5](https://github.com/szTheory/oban_powertools/commit/69045b5ba515ac7640f45ff2bf64cdda11dbe82e))
* **82-11:** meet audit disclosure target size ([73dee90](https://github.com/szTheory/oban_powertools/commit/73dee90c228bfb5de3842f45a20509ee1e060de0))
* **82-11:** preserve placeholder contrast ([02bbdef](https://github.com/szTheory/oban_powertools/commit/02bbdef9a56ad39ef6b915bf4c0561cffe923919))
* **82-11:** retain client theme across patches ([a85ae36](https://github.com/szTheory/oban_powertools/commit/a85ae368c0b78f2a41ef300bbe494e5fb507b457))
* **82-12:** close shell and responsive data semantics ([1e7587a](https://github.com/szTheory/oban_powertools/commit/1e7587acc2bf7179fd273d1c8fbbfe89983014c3))
* **82-13:** close operator dialog semantics ([68cc2a8](https://github.com/szTheory/oban_powertools/commit/68cc2a8847a5a0c04d83292ce3ec24d7cb76e53c))
* **82-14:** align Forensics story copy ([14b0be5](https://github.com/szTheory/oban_powertools/commit/14b0be5c63e99ca6e5e748b95200e94a31641c43))
* **82-14:** harden Jobs and Forensics copy truth ([1194681](https://github.com/szTheory/oban_powertools/commit/1194681873f9cd4d0cfaba50bebcc17e32347937))
* **82-15:** harden Wave 3 operator copy ([e086504](https://github.com/szTheory/oban_powertools/commit/e086504648bca46c304e7958f39e262b4f5e3064))
* address release CI host proof failures ([#29](https://github.com/szTheory/oban_powertools/issues/29)) ([345b8a2](https://github.com/szTheory/oban_powertools/commit/345b8a25b04380b2538add7848d726dfd63d8c07))
* **phase-79:** close security mitigation gaps ([6e3ec22](https://github.com/szTheory/oban_powertools/commit/6e3ec22d520dfe9938f9399a6b898f8093128b17))
* **phase-81:** close UI review advisories ([2652bd0](https://github.com/szTheory/oban_powertools/commit/2652bd033d2229924edca4e382d74f75465a4ca4))
* **phase-81:** remove duplicate forensic link ([fd4a7d0](https://github.com/szTheory/oban_powertools/commit/fd4a7d0eee8560aadf3b0dc320be95973f43cc9e))
* resolve post-merge conflicts from wave 3 ([9fbd429](https://github.com/szTheory/oban_powertools/commit/9fbd429b316432c05a22fdf42800859fc7fb92c1))
* resolve post-merge conflicts from wave 4 ([e60da24](https://github.com/szTheory/oban_powertools/commit/e60da247e6d9e1047c70c60f865e49ddcd12abc5))
* resolve post-merge conflicts from wave 6 ([7891381](https://github.com/szTheory/oban_powertools/commit/7891381e922a1a59fa7d8051666d6643f8b57e19))


### Documentation

* **76-03:** complete AppShell CSS and disclosure assets plan ([c78d6a2](https://github.com/szTheory/oban_powertools/commit/c78d6a2a55150f6fc1a9abe266306a6e2a0f5763))
* **76-04:** complete shell story manifest plan ([237daba](https://github.com/szTheory/oban_powertools/commit/237daba5a58061eb60020fe31448b365e706ffc4))
* **76-05:** complete navigation app shell plan ([d44b773](https://github.com/szTheory/oban_powertools/commit/d44b773772e062c3654366fddfefc82970a9b6a7))
* **76-05:** normalize summary verification wording ([a0dbe51](https://github.com/szTheory/oban_powertools/commit/a0dbe51c9122c56a27eec47ff99a78574b866201))
* **76:** add code review report ([f0d8c12](https://github.com/szTheory/oban_powertools/commit/f0d8c12d5679c3b6dc7cac70525c172470324031))
* **76:** refresh clean code review ([9241ba2](https://github.com/szTheory/oban_powertools/commit/9241ba2e04cea34d2d51f5f94734f8898bd008a1))
* **77-01:** complete red contract plan ([b13dfdb](https://github.com/szTheory/oban_powertools/commit/b13dfdb57e02738789eb8ab919ea94a5177c366c))
* **77-02:** complete unified status taxonomy plan ([34f1e35](https://github.com/szTheory/oban_powertools/commit/34f1e356646e686b6d9887a3b322854b0d27d2d5))
* **77-03:** complete semantic DataTable plan ([34632a8](https://github.com/szTheory/oban_powertools/commit/34632a87fd7709e183d65a733009e9553d1dde09))
* **77-04:** complete secondary display plan ([0e003b8](https://github.com/szTheory/oban_powertools/commit/0e003b81572987e223375ed630843dc8c6a205f5))
* **77-05:** complete confidentiality-safe display plan ([8343dc3](https://github.com/szTheory/oban_powertools/commit/8343dc3dfaf46e662bcaa4bb838279144a1e70f3))
* **77-05:** validate plan summary metadata ([60c0a62](https://github.com/szTheory/oban_powertools/commit/60c0a62ac23ccff793cfb134de3df842449171cc))
* **77-06:** complete data showcase manifest plan ([f8105dd](https://github.com/szTheory/oban_powertools/commit/f8105ddb18844102323aed4674ac030b40ca6fae))
* **77-06:** satisfy summary self-check parser ([896c5e8](https://github.com/szTheory/oban_powertools/commit/896c5e8046574b8b5e2ac351a427f40b86262391))
* **77-07:** complete live data evidence plan ([0bed25d](https://github.com/szTheory/oban_powertools/commit/0bed25d387bb70c38d56a461589e997d9dbb7d43))
* **77-08:** complete flash progress gap closure plan ([a4bb1bb](https://github.com/szTheory/oban_powertools/commit/a4bb1bbdd47f0e9939e0f8a9155377d196568097))
* **77-09:** complete optional data catalog package-boundary plan ([9fb81b7](https://github.com/szTheory/oban_powertools/commit/9fb81b729d6134d902aca1701e81fc91f08e6e2f))
* **77-09:** record package-boundary closure evidence ([f5da92c](https://github.com/szTheory/oban_powertools/commit/f5da92cf6e2f43803b3a82e718ff92dc468e740b))
* **77:** add code review report ([3b80366](https://github.com/szTheory/oban_powertools/commit/3b80366519051e623ef8e4630c351524cdedd2b6))
* **77:** add code review report ([e23e903](https://github.com/szTheory/oban_powertools/commit/e23e903affc786a234d5fd67b49788a8d19c482e))
* **77:** add code review report ([8ba0d63](https://github.com/szTheory/oban_powertools/commit/8ba0d6384434c858610ba1de8361d3d83c1b2836))
* **77:** approve UI design contract ([3366f0b](https://github.com/szTheory/oban_powertools/commit/3366f0b2c3f9a7e7b81778c874ff09da377da05c))
* **77:** capture phase context ([b8766c6](https://github.com/szTheory/oban_powertools/commit/b8766c6536cfb6e8f3726bf90341c432b2e36c4b))
* **77:** create data-display operator plans ([2022ca7](https://github.com/szTheory/oban_powertools/commit/2022ca7adb72dea37cdf2c6a2a25dada6a4a811f))
* **77:** create gap-closure plan ([44a6430](https://github.com/szTheory/oban_powertools/commit/44a64307e3808058e812744034ec0e1978546ec1))
* **77:** create phase gap-closure plan ([ab4871c](https://github.com/szTheory/oban_powertools/commit/ab4871ccd9ec1c88a78ca0dbedd77613061f2b65))
* **77:** record verification gaps ([9b089d2](https://github.com/szTheory/oban_powertools/commit/9b089d20eed72fb6066426fa3b24d3192dc90556))
* **77:** UI design contract ([3397a59](https://github.com/szTheory/oban_powertools/commit/3397a59b3d104e97b23c9e31dc0bf27e6f41d12c))
* **77:** UI design contract ([91f7b2c](https://github.com/szTheory/oban_powertools/commit/91f7b2c769220e3b600c86eb6f69e9666c0cbe74))
* **78-01:** advance Phase 78 execution tracking ([9e4a324](https://github.com/szTheory/oban_powertools/commit/9e4a324460ea1b533a155a31a59371989ae4e5e8))
* **78-01:** clarify closeout boundary audit ([498fba2](https://github.com/szTheory/oban_powertools/commit/498fba221d7d8f254efd7c1dea1ebe6047b01c5a))
* **78-01:** complete Wave 0 RED contracts plan ([c9d8c98](https://github.com/szTheory/oban_powertools/commit/c9d8c98b71625731910d5232869a19379566913c))
* **78-02:** advance phase tracking ([40d2b11](https://github.com/szTheory/oban_powertools/commit/40d2b11587bed6bd1f160f685ff425533506ac7e))
* **78-02:** complete presentation foundation plan ([7969714](https://github.com/szTheory/oban_powertools/commit/7969714749bd590e09da2523e679836fd7859172))
* **78-03:** advance phase tracking ([76dfe6c](https://github.com/szTheory/oban_powertools/commit/76dfe6c854d2ad283772508d6a5d8d0fc939515a))
* **78-03:** complete FilterBar plan ([3cdcb61](https://github.com/szTheory/oban_powertools/commit/3cdcb61c0af4073767b764aafff8b1eabdb4890e))
* **78-04:** advance phase tracking ([43d85a0](https://github.com/szTheory/oban_powertools/commit/43d85a04b5a0a7ef25f36abd28ab42cf6d794ea3))
* **78-04:** summarize confirmation composition ([b676409](https://github.com/szTheory/oban_powertools/commit/b67640907f96672778a5ed434abf49034b3f69a2))
* **78-05:** complete detail surface plan ([d9fc009](https://github.com/szTheory/oban_powertools/commit/d9fc009e316280c8cb2f2f2a654b7f12200013ce))
* **78-05:** update execution tracking ([4645a4b](https://github.com/szTheory/oban_powertools/commit/4645a4b484fb0609ccbad38eaabe2564c26c6802))
* **78-06:** advance phase tracking ([d3ee958](https://github.com/szTheory/oban_powertools/commit/d3ee9583b31ccc03d1dfeef82960028a6c948e50))
* **78-06:** complete operator group showcase plan ([0e33e09](https://github.com/szTheory/oban_powertools/commit/0e33e09aba3c24f6f49e5be02de9b7c0208b471f))
* **78-07:** advance phase tracking ([c37260a](https://github.com/szTheory/oban_powertools/commit/c37260a3a7479175aa202234a98dabb5de43905f))
* **78-07:** complete connected behavior proof plan ([ad0497f](https://github.com/szTheory/oban_powertools/commit/ad0497f489b0e7981be8c84bddd6a83fede6b414))
* **78-08:** complete accessibility and visual gate ([f424b95](https://github.com/szTheory/oban_powertools/commit/f424b952872c82f701c9af7cdc9c0614aac95674))
* **78-08:** reconcile final validation evidence ([dfe4044](https://github.com/szTheory/oban_powertools/commit/dfe40442300d25299d91ec8c1fec7f553052eebb))
* **78:** add code review fix report ([0e04485](https://github.com/szTheory/oban_powertools/commit/0e04485a0e80a2935a4fbf12aa960936b06a4050))
* **78:** add code review report ([8158739](https://github.com/szTheory/oban_powertools/commit/8158739d162c5b52942a3ae9097b55c4e9ff130d))
* **78:** capture phase context ([d53d94e](https://github.com/szTheory/oban_powertools/commit/d53d94e725c9e44a3f895a8517d5bb1c8d00057a))
* **78:** create phase plan ([f2e1c98](https://github.com/szTheory/oban_powertools/commit/f2e1c98944197c90265d7599ae2493ede153c97f))
* **78:** record completed execution plans ([7aa113d](https://github.com/szTheory/oban_powertools/commit/7aa113d94b1007c5360a93af94627c9000d39a1f))
* **78:** record verification and UI audit ([4f69c1a](https://github.com/szTheory/oban_powertools/commit/4f69c1a0606833b9d1ec825e44627319a22c7138))
* **78:** UI design contract ([e7d581d](https://github.com/szTheory/oban_powertools/commit/e7d581d1cdde29aed250fa93ac02cbd1286dba3a))
* **79-01:** complete RED contract plan ([317ab77](https://github.com/szTheory/oban_powertools/commit/317ab77824ac3f3eeec654e7cf7079b88c9fe57b))
* **79-01:** update execution progress ([a267540](https://github.com/szTheory/oban_powertools/commit/a2675402840474cb21a80aa809e508b79000435c))
* **79-02:** complete bounded presentation foundation ([ebf7ec1](https://github.com/szTheory/oban_powertools/commit/ebf7ec12e41e876f9c5756f803913d79c6975c2c))
* **79-02:** update execution progress ([ef61c2f](https://github.com/szTheory/oban_powertools/commit/ef61c2f67894adf552672a5ade41a094d81e2581))
* **79-03:** complete stable overview migration ([9b112c0](https://github.com/szTheory/oban_powertools/commit/9b112c094c99e537143695af3efaed1d46374382))
* **79-03:** update execution progress ([1bcdb94](https://github.com/szTheory/oban_powertools/commit/1bcdb942c5a837027cacc251f113eee88f88c060))
* **79-04:** complete cron page migration plan ([e1b7bb5](https://github.com/szTheory/oban_powertools/commit/e1b7bb5e5383919d03a91b7de657464481d88fe3))
* **79-05:** complete limiter migration plan ([06f8fb4](https://github.com/szTheory/oban_powertools/commit/06f8fb4b5498496c9e3b64cbb89b592fdd2f538e))
* **79-05:** update execution progress ([f949c20](https://github.com/szTheory/oban_powertools/commit/f949c20053430d02b1b48f7facf952f0ae84893d))
* **79-06:** complete Audit scan and immutable evidence plan ([9804776](https://github.com/szTheory/oban_powertools/commit/98047760d70e2132c238bc59473727f268a3b466))
* **79-07:** complete page composition assets plan ([94258e4](https://github.com/szTheory/oban_powertools/commit/94258e4a415cf2bf544ad0a94cd016cba5670000))
* **79-08:** complete page evidence plan ([7b1807f](https://github.com/szTheory/oban_powertools/commit/7b1807f7b11e4edb1f2f9c728493314f4dcfd7a7))
* **79-08:** reconcile phase validation evidence ([47a0d2a](https://github.com/szTheory/oban_powertools/commit/47a0d2aa616190854853c843c53ea05f0c4cee16))
* **79-08:** update execution tracking ([576c8be](https://github.com/szTheory/oban_powertools/commit/576c8bed5e037ef8a5c91b676437a41b932ca854))
* **79-09:** complete page evidence RED contract plan ([7c27072](https://github.com/szTheory/oban_powertools/commit/7c27072bdf0f198a2bddf28ed78986f9c3ef0f2b))
* **79-09:** update execution progress ([0240c7f](https://github.com/szTheory/oban_powertools/commit/0240c7f8d66764348168c805e250f299dc655b9f))
* **79-10:** summarize browser fixture harness ([74f7931](https://github.com/szTheory/oban_powertools/commit/74f7931a7d6dae012f8094d8362db27c0eca48fd))
* **79-10:** update plan tracking ([c13b386](https://github.com/szTheory/oban_powertools/commit/c13b386a05c674425e4c1a91ac904848c329fcb4))
* **79-11:** complete page catalog plan ([308630c](https://github.com/szTheory/oban_powertools/commit/308630c8cb5f939abf6bc29f4ff6722a21b0f2a9))
* **79-11:** update execution tracking ([30f8ec8](https://github.com/szTheory/oban_powertools/commit/30f8ec80d1d046879cc0d2479df214cdca153e2e))
* **79-12:** complete schema 7 page targets plan ([89649db](https://github.com/szTheory/oban_powertools/commit/89649dbe4c59a099dc2b7484d478acb25869ece7))
* **79-12:** update execution tracking ([167c4d2](https://github.com/szTheory/oban_powertools/commit/167c4d2e8321336217878547e5594468e868b746))
* **79:** add code review report ([472e45a](https://github.com/szTheory/oban_powertools/commit/472e45a69b4fe1c09553d25dbc1aade580718126))
* **79:** approve UI design contract ([8ea021d](https://github.com/szTheory/oban_powertools/commit/8ea021d85a52b72e375e7d6db31e0c8bf2ad86c9))
* **79:** capture phase context ([37f93a0](https://github.com/szTheory/oban_powertools/commit/37f93a024e0627a04222a53658ee21607b8f26f4))
* **79:** create phase plan ([80bd681](https://github.com/szTheory/oban_powertools/commit/80bd68128f3501233a0891f464f03a1287412e16))
* **79:** record verification gaps ([9e210c6](https://github.com/szTheory/oban_powertools/commit/9e210c648657dbd1524421169c87d5666bf928ae))
* **79:** research phase domain ([79c1c99](https://github.com/szTheory/oban_powertools/commit/79c1c996f5e430a93346888d9ddab74b085e3f4f))
* **79:** UI design contract ([28397f7](https://github.com/szTheory/oban_powertools/commit/28397f7bc0d7fddaf8580ee64e70d2feea901e9c))
* **80-01:** complete Jobs foundation plan ([c0c62c9](https://github.com/szTheory/oban_powertools/commit/c0c62c9b7f2b46c61296be99c5a205d58055dd86))
* **80-02:** complete Jobs browse plan ([ef1ac52](https://github.com/szTheory/oban_powertools/commit/ef1ac52da0623f94b51c61574f9257c132405826))
* **80-03:** complete canonical Jobs detail plan ([a13e06b](https://github.com/szTheory/oban_powertools/commit/a13e06b2cbe3d743b9d8a8449eff4745600b3dbe))
* **80-04:** complete Jobs bulk execution plan ([31188a6](https://github.com/szTheory/oban_powertools/commit/31188a60d72f1a2ac8d57527962edc09e67d7678))
* **80-05:** complete forensic scope query foundation ([c33006e](https://github.com/szTheory/oban_powertools/commit/c33006e0eebec4d9fa5c2b1579dc9566f859f611))
* **80-06:** complete forensic assembly plan ([7fa223a](https://github.com/szTheory/oban_powertools/commit/7fa223a522b56f94f1386a1d58ac6f53ced949c2))
* **80-07:** summarize typed forensics page ([e7a4711](https://github.com/szTheory/oban_powertools/commit/e7a4711fe3b9111ada654bc390fc0ab922043936))
* **80-08:** summarize jobs and forensics stories ([15d547b](https://github.com/szTheory/oban_powertools/commit/15d547b539b7a1768b91cbb8a3f3ec5f99108ac5))
* **80-09:** complete manifest expansion plan ([b3af0ea](https://github.com/szTheory/oban_powertools/commit/b3af0ea9491de018933e96a900de34dfec819ae7))
* **80-09:** update roadmap progress ([f216442](https://github.com/szTheory/oban_powertools/commit/f2164426a5473b2779bbb1f250ef3aaf939c6290))
* **80-10:** complete fixture bridge plan ([4856647](https://github.com/szTheory/oban_powertools/commit/48566471ec2a1a2d34e584baa3c7c3979fcdd239))
* **80-10:** update roadmap progress ([bbe00bd](https://github.com/szTheory/oban_powertools/commit/bbe00bde4dded9fc3986d26121db37a9988482b2))
* **80-11:** document connected page verification ([61f7ea4](https://github.com/szTheory/oban_powertools/commit/61f7ea4ce4025af0da6e8d0f2a076a61f77dd9c3))
* **80-11:** update roadmap progress ([8d7b558](https://github.com/szTheory/oban_powertools/commit/8d7b55894c8de7db803fe50bd30ac2d6f400bca8))
* **80-12:** document page evidence closure ([13aa5e1](https://github.com/szTheory/oban_powertools/commit/13aa5e11071dcbc5ea82dff724bb1d53c1bd0d52))
* **80-13:** reconcile closure evidence ([271e48b](https://github.com/szTheory/oban_powertools/commit/271e48b08d77e4a0b4650e527adbb26b53d8e47f))
* **80-13:** record final closure evidence ([ec56f4e](https://github.com/szTheory/oban_powertools/commit/ec56f4e277b3b7006368c78dce44bd8856dcca9a))
* **80-13:** summarize phase closure ([70ed6c8](https://github.com/szTheory/oban_powertools/commit/70ed6c8a047fa4eae901cc937c27a912c2a17ab8))
* **80-14:** advance phase tracking ([c498746](https://github.com/szTheory/oban_powertools/commit/c4987461a9b2a0d3917430bc0d2003603323b198))
* **80-14:** clarify summary verification results ([f7248f0](https://github.com/szTheory/oban_powertools/commit/f7248f0e5a5e33bdd73b8986fda81d6108ea45d5))
* **80-14:** complete workflow-step evidence authority plan ([2f079b8](https://github.com/szTheory/oban_powertools/commit/2f079b8333aefcb0beaab46d666553a5a1282fc0))
* **80-15:** complete Jobs boundary gap closure plan ([ed0e192](https://github.com/szTheory/oban_powertools/commit/ed0e192ca2d0b08e442ae6fade67709fe99848ff))
* **80-15:** record phase plan progress ([0688558](https://github.com/szTheory/oban_powertools/commit/0688558a81034f0f00dfeef560c17d3991e48840))
* **80-16:** complete exact residual attribution plan ([c800494](https://github.com/szTheory/oban_powertools/commit/c8004942bef2bfb55623c723dd3c40ae0f613a74))
* **80-16:** record corrected phase closure evidence ([751c425](https://github.com/szTheory/oban_powertools/commit/751c4253bbc1434072c28521dbfab4e88683012e))
* **80-16:** record phase plan progress ([5f7aaae](https://github.com/szTheory/oban_powertools/commit/5f7aaaead8e67cb0296a0fdad11ec2d125d4fb99))
* **80-16:** split pending phase requirement rows ([a87fb61](https://github.com/szTheory/oban_powertools/commit/a87fb61182342d9330aecf61efb61a4fd5b8089d))
* **80-17:** complete canonical Jobs detail ID plan ([99b2e52](https://github.com/szTheory/oban_powertools/commit/99b2e526d60f63c860d56f04d7474078459f8d66))
* **80-17:** record phase plan progress ([959133c](https://github.com/szTheory/oban_powertools/commit/959133ccbc04510ff57c2a62094e24915ea60570))
* **80:** add code review report ([902c72a](https://github.com/szTheory/oban_powertools/commit/902c72a2e6ec20e48ac3481f1506bc78c8c62525))
* **80:** add code review report ([436a7cd](https://github.com/szTheory/oban_powertools/commit/436a7cdf2b289afba048944f34b5fa4f93c35888))
* **80:** add code review report ([c17f201](https://github.com/szTheory/oban_powertools/commit/c17f2014c879884f2555a0fdca14be549a085ed8))
* **80:** advance page migration progress ([1e4597f](https://github.com/szTheory/oban_powertools/commit/1e4597f38f6d436c4fbe38f611e685a48d6f7c3c))
* **80:** approve UI design contract ([877c4c9](https://github.com/szTheory/oban_powertools/commit/877c4c9839598cf78155d5450d9de4e69befbb17))
* **80:** capture phase context ([835aa89](https://github.com/szTheory/oban_powertools/commit/835aa89e8dad23f6bc5edac51a69970f7929424e))
* **80:** create gap closure plan ([ffe712d](https://github.com/szTheory/oban_powertools/commit/ffe712dd032feaab234379bc83edf7494fb5dc49))
* **80:** create gap closure plans ([b8491aa](https://github.com/szTheory/oban_powertools/commit/b8491aa51e8bf2226754ab46d19f955990b3a693))
* **80:** create phase gap-closure plan ([0d57dfa](https://github.com/szTheory/oban_powertools/commit/0d57dfa19ca769860f48bf8d198df0ed6a32b105))
* **80:** create phase plan ([d437717](https://github.com/szTheory/oban_powertools/commit/d43771793a46d278bb26fd613b21931a2392af73))
* **80:** reconcile plan progress after wave 6 ([3d27fad](https://github.com/szTheory/oban_powertools/commit/3d27fadb4b62c2f07af61111c39788e74dab9e27))
* **80:** record verification gap ([a94a4f7](https://github.com/szTheory/oban_powertools/commit/a94a4f7daa64ed665719218afe99f472102f181b))
* **80:** record verification gaps ([a1afb72](https://github.com/szTheory/oban_powertools/commit/a1afb72d044d0621a82675daa8ce626bfb666f83))
* **80:** revise gap-closure plan ([2f78d5e](https://github.com/szTheory/oban_powertools/commit/2f78d5e897592b9b3b571bdffc13f45f2c968fdd))
* **80:** revise UI spacing contract ([0eff25d](https://github.com/szTheory/oban_powertools/commit/0eff25dad85572bb98c787cd02779005f15171d5))
* **80:** synchronize UI checker sign-off ([aed5957](https://github.com/szTheory/oban_powertools/commit/aed5957164587c46083f7ec358eeaa9fe39eda1e))
* **80:** UI design contract ([4174ff4](https://github.com/szTheory/oban_powertools/commit/4174ff4ce0d4c720dc06121a674469987bc305f4))
* **80:** update plan progress ([0dfd50b](https://github.com/szTheory/oban_powertools/commit/0dfd50b1355f47eed8a909ab832f2e9a413e11f2))
* **80:** update plan progress ([85d9fe2](https://github.com/szTheory/oban_powertools/commit/85d9fe2cc48c7a57c0972f5915958f3f96a03acb))
* **80:** update plan progress ([d1762d8](https://github.com/szTheory/oban_powertools/commit/d1762d81877ed7e47b7b4267ea873e9058eb8187))
* **80:** update plan progress ([f2ebe85](https://github.com/szTheory/oban_powertools/commit/f2ebe85dd34d1bd6bdd2693add8779c348e33288))
* **81-01:** complete Wave 3 RED contracts plan ([743e3d9](https://github.com/szTheory/oban_powertools/commit/743e3d955263238bfe5b719c616e910e53de681a))
* **81-02:** complete Batches migration plan ([7cf4834](https://github.com/szTheory/oban_powertools/commit/7cf4834b701268b7466346fc4d92a44e10856be5))
* **81-03:** complete Workflows migration plan ([957bba5](https://github.com/szTheory/oban_powertools/commit/957bba550b1caa305a4e08721b4c53c495f4e667))
* **81-04:** complete closed Lifeline presenter plan ([528e11b](https://github.com/szTheory/oban_powertools/commit/528e11bd394243f2b2554122e3d308a708000205))
* **81-05:** complete Lifeline migration plan ([8269d0f](https://github.com/szTheory/oban_powertools/commit/8269d0fc6a4a4010a9df6790eebcd22f1d2650d8))
* **81-05:** record connected Lifeline evidence ([ee4f0a8](https://github.com/szTheory/oban_powertools/commit/ee4f0a86e768b94e9c3df78c3ecc1ab8225e98f3))
* **81-05:** update plan execution state ([f47ab48](https://github.com/szTheory/oban_powertools/commit/f47ab48c88778b3c56074039395de4c784b18326))
* **81-06:** advance execution state ([c5f137d](https://github.com/szTheory/oban_powertools/commit/c5f137d7ef5db6ed08a36236709502d7b80b9ed3))
* **81-06:** complete Wave 3 catalog plan ([d2c6d7e](https://github.com/szTheory/oban_powertools/commit/d2c6d7eff0309fa85b4013626164549feb0b5984))
* **81-07:** complete connected fixture bridge plan ([0786997](https://github.com/szTheory/oban_powertools/commit/0786997f950174e2adf1411e4c53be6bd894617d))
* **81-07:** record TDD gate compliance ([756a070](https://github.com/szTheory/oban_powertools/commit/756a0705e55aca6fd7d086b0c42681d4bcfeffc5))
* **81-08:** complete connected acceptance plan ([756744b](https://github.com/szTheory/oban_powertools/commit/756744bcd297e9e3221bc600179e92eb4e6c5e8e))
* **81-09:** complete Batches artifacts plan ([fb6897e](https://github.com/szTheory/oban_powertools/commit/fb6897eb359cf16473f7074a1718ea4e6faf2533))
* **81-10:** complete Wave 3 CSS packaging plan ([9b70bc1](https://github.com/szTheory/oban_powertools/commit/9b70bc1285e94d23ee704567d2d604c677e68789))
* **81-11:** complete Workflows artifacts plan ([d91126a](https://github.com/szTheory/oban_powertools/commit/d91126ac3ac91a8be5e038940e626625d25f7b43))
* **81-12:** complete Lifeline artifacts plan ([d9f3450](https://github.com/szTheory/oban_powertools/commit/d9f3450234ef9f5c8db9ab3d206a4049b2a4fe41))
* **81-13:** complete VoiceOver and CI gate plan ([18fae98](https://github.com/szTheory/oban_powertools/commit/18fae983fa29e4b9d2b4b16f448d153b0375fd10))
* **81-14:** approve final Nyquist ledger ([24f7e56](https://github.com/szTheory/oban_powertools/commit/24f7e569e3e8f0269b59c5b3ce544f2321c058d6))
* **81-15:** complete browser contract plan ([87ac6f2](https://github.com/szTheory/oban_powertools/commit/87ac6f2b3f5780e99dfdda4e88d39b92fdd8dac0))
* **81:** add code review fix report ([7a738a6](https://github.com/szTheory/oban_powertools/commit/7a738a648f5c5590bf56f8ad6e98878d58ca4f95))
* **81:** add code review report ([d010354](https://github.com/szTheory/oban_powertools/commit/d0103549c8a369f8a9732ae5276549d62acde271))
* **82-01:** advance phase progress ([f6add7a](https://github.com/szTheory/oban_powertools/commit/f6add7a681f052fdac15975e22cbae20ab338912))
* **82-01:** complete system quality RED plan ([5d7fb20](https://github.com/szTheory/oban_powertools/commit/5d7fb201763591cd24da8f74e7a02014f4447a4e))
* **82-02:** complete finite copy RED plan ([86e1709](https://github.com/szTheory/oban_powertools/commit/86e170968767da8b79c81357f4d474cc3dfe7787))
* **82-03:** complete sole static quality policy plan ([02f54d7](https://github.com/szTheory/oban_powertools/commit/02f54d73f5fb49e34f617b95f9396b4b07f691ba))
* **82-04:** complete shared browser auditors plan ([8e235dc](https://github.com/szTheory/oban_powertools/commit/8e235dc1fb2d9e7b38ff40f11d4b7c1b8f61de87))
* **82-04:** record security hardening evidence ([e0c1635](https://github.com/szTheory/oban_powertools/commit/e0c1635bc6eaaaf4cc29b5d3a1feac1e89590adf))
* **82-05:** align execution state ([20150a9](https://github.com/szTheory/oban_powertools/commit/20150a923ff9f0e821cc4efd50f4f2de7d37c8ee))
* **82-05:** complete shared accessibility CSS plan ([9c1976a](https://github.com/szTheory/oban_powertools/commit/9c1976a9306d8c78fe657ec56c5f8d4af09b5c64))
* **82-06:** complete primitive and form semantics plan ([ae58cc0](https://github.com/szTheory/oban_powertools/commit/ae58cc0e2a8cc71b3c508f3fa0b7c769353cf23a))
* **82-07:** complete first page copy plan ([41ba067](https://github.com/szTheory/oban_powertools/commit/41ba0676298d68791cec541f06d9b9777521dce3))
* **82-08:** complete exhaustive quality integration ([957c46a](https://github.com/szTheory/oban_powertools/commit/957c46acdd89e34ef3ddc8094e958033f99d5e2f))
* **82-09:** complete connected quality plan ([54e242c](https://github.com/szTheory/oban_powertools/commit/54e242ca8139d1898487f45eba39083c627ef7d2))
* **82-09:** update phase progress ([4722381](https://github.com/szTheory/oban_powertools/commit/4722381b90e31581da29bc6bd3516e0cd988fbce))
* **82-10:** complete merge-blocking quality graph plan ([5c51147](https://github.com/szTheory/oban_powertools/commit/5c511477fefbeaf4753b776bcd8648223f09e216))
* **82-10:** update phase progress ([e7e0078](https://github.com/szTheory/oban_powertools/commit/e7e0078d1c25ed6af0597e030849768dba37d8ac))
* **82-12:** complete shell and responsive data plan ([cf63792](https://github.com/szTheory/oban_powertools/commit/cf6379204e560badd3805d765d333841d8fb647e))
* **82-13:** complete operator dialog semantics plan ([8c3685d](https://github.com/szTheory/oban_powertools/commit/8c3685ded94f05818984eb83447ea55ed13fdb1e))
* **82-14:** complete Jobs and Forensics copy plan ([19dd086](https://github.com/szTheory/oban_powertools/commit/19dd0867bc958ddb81348d311ac7ba810abd9de5))
* **82-15:** complete Wave 3 copy hardening plan ([6a37aaa](https://github.com/szTheory/oban_powertools/commit/6a37aaae2c2e0b9a5acfc3924719cf349b36673e))
* **82-16:** complete exact ARIA reconciliation plan ([0f4f4a6](https://github.com/szTheory/oban_powertools/commit/0f4f4a6c8f65dbcb06d00a9ec0485d80ace43cbd))
* **82-16:** record ARIA reconciliation ([0fcaeed](https://github.com/szTheory/oban_powertools/commit/0fcaeedd28bb6432d061dcc51d8be55a8aa096ed))
* **82-17:** complete copy policy projection plan ([e331d90](https://github.com/szTheory/oban_powertools/commit/e331d90892a11c2981cb4eb7cc07db067bff0ab9))
* finalize v2.0 requirements archive ([a854a00](https://github.com/szTheory/oban_powertools/commit/a854a0059601f176ac459d9e491afe33039b0498))
* **gsd:** align roadmap and handoff for Codex ([9606756](https://github.com/szTheory/oban_powertools/commit/960675633f3b76dbb302b78713e0a5d9c6574442))
* **gsd:** close v2.0 milestone audit ([4fd94be](https://github.com/szTheory/oban_powertools/commit/4fd94be4da44a03a7f29da8b673bdb903f8f17ed))
* **gsd:** record current CI handoff ([ee78570](https://github.com/szTheory/oban_powertools/commit/ee785709bcc1a7171ca3e60b7d74df6cdf3b3f2b))
* **phase-72:** update validation strategy ([4d9885c](https://github.com/szTheory/oban_powertools/commit/4d9885c0d920fa653fc1acdad699696bb6ec84d9))
* **phase-76:** complete phase execution ([217562e](https://github.com/szTheory/oban_powertools/commit/217562e37f2b425fe07340dd1e18ccbde174be8a))
* **phase-77:** add/update security threat verification ([7aa9374](https://github.com/szTheory/oban_powertools/commit/7aa9374953e150aca328a5708e02560bf14153de))
* **phase-77:** complete phase execution ([8c24e89](https://github.com/szTheory/oban_powertools/commit/8c24e89059307ef491f7c019a037d25b84f24295))
* **phase-77:** evolve PROJECT.md after phase completion ([1e05d75](https://github.com/szTheory/oban_powertools/commit/1e05d75fcbaa6991d0a7196d843ba2b70bd1d268))
* **phase-77:** keep verification-gap progress pending ([592f159](https://github.com/szTheory/oban_powertools/commit/592f1596009879c80c72748a2dbcc79abba8ac4b))
* **phase-77:** record remaining verification gap ([e42998d](https://github.com/szTheory/oban_powertools/commit/e42998d5120a4b93e4cfd0ba81d491a082aca1c5))
* **phase-77:** update validation strategy ([274f4ee](https://github.com/szTheory/oban_powertools/commit/274f4ee840ae7ff1915f9c364a39ddb8c4965709))
* **phase-78:** add security threat verification ([9d10fac](https://github.com/szTheory/oban_powertools/commit/9d10fac118f6542188aea10c375fb51502b86b15))
* **phase-78:** add validation strategy ([fcf3969](https://github.com/szTheory/oban_powertools/commit/fcf396996a2ea264611f578a3b52e540a3f2c3d6))
* **phase-78:** complete phase execution ([be20cad](https://github.com/szTheory/oban_powertools/commit/be20cad6510db8463c8df325f5e11dc8da9b8372))
* **phase-78:** update validation strategy ([dcaa455](https://github.com/szTheory/oban_powertools/commit/dcaa455d5eb4d4c9ef8976d80e81817ff478c883))
* **phase-79:** add validation strategy ([57d4d8d](https://github.com/szTheory/oban_powertools/commit/57d4d8d809a8c1a2386406f5f448cc17568b6783))
* **phase-79:** add/update security threat verification ([417da25](https://github.com/szTheory/oban_powertools/commit/417da25b6cf919f6a0cabaec19d09d9ce6700658))
* **phase-79:** update validation strategy ([9859fce](https://github.com/szTheory/oban_powertools/commit/9859fce207b68b94d6d8b4d1b44177065347c975))
* **phase-80:** add research and validation strategy ([268c80b](https://github.com/szTheory/oban_powertools/commit/268c80baf682ce4b47306ba0cc2e35e3876ee6ca))
* **phase-80:** add/update security threat verification ([ad5e3d7](https://github.com/szTheory/oban_powertools/commit/ad5e3d780debe74f843ef05bf4a0af7359b76532))
* **phase-80:** complete phase execution ([9410ac7](https://github.com/szTheory/oban_powertools/commit/9410ac70e25272059b5a2a7221f3086757a89f04))
* **phase-80:** evolve PROJECT.md after phase completion ([472cbfa](https://github.com/szTheory/oban_powertools/commit/472cbfa286b38859f86d9051bce49f84b0a2cdbd))
* **phase-80:** update validation strategy ([3f270e0](https://github.com/szTheory/oban_powertools/commit/3f270e0a784734e73ec2ec516c0e79f0a7ac7659))
* **phase-81:** complete phase execution ([a51c7f6](https://github.com/szTheory/oban_powertools/commit/a51c7f60f1aa189f2ce9819df49436e0dbff9e03))
* publish design system contribution guide ([0ecd013](https://github.com/szTheory/oban_powertools/commit/0ecd01359c1ffbe29c9cd5985b601e2841539269))
* **roadmap:** mark phase 80 plan 08 complete ([56f05dd](https://github.com/szTheory/oban_powertools/commit/56f05dd21dfe5b5a3ce5d62a591add157d13aff2))
* **state:** record phase 77 context session ([6d28c01](https://github.com/szTheory/oban_powertools/commit/6d28c017a92b061898d7fc0d330054277f2c2a78))
* **state:** record phase 77 UI-SPEC approval ([3928639](https://github.com/szTheory/oban_powertools/commit/39286391625d43cc0e3c336623065f154d11c22b))
* **state:** record phase 78 discussion ([b79430a](https://github.com/szTheory/oban_powertools/commit/b79430ab7893e3c832e09ec5c24eb4fb00b561fd))
* **state:** record phase 79 context session ([6e584b0](https://github.com/szTheory/oban_powertools/commit/6e584b09b54ce439c92bf26512efadd4ae734ab6))
* **state:** record phase 80 context session ([7be0f11](https://github.com/szTheory/oban_powertools/commit/7be0f11de3df033979788bef0a373e1c0fec201d))
* update retrospective for v2.0 ([3a110c1](https://github.com/szTheory/oban_powertools/commit/3a110c168c24fe6b40066d70f5e4ac2557707e52))

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
