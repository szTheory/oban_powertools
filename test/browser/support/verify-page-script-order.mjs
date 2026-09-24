import assert from "node:assert/strict";
import fs from "node:fs";

const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8"));
const hostLauncher = fs.readFileSync("scripts/with-showcase-server.sh", "utf8");
const dockerLauncher = fs.readFileSync("scripts/playwright-docker.sh", "utf8");
const ciSuiteRunner = fs.readFileSync("scripts/playwright-ci-suite.sh", "utf8");
const ciWorkflow = fs.readFileSync(".github/workflows/ci.yml", "utf8");
const voiceOverConfig = fs.readFileSync("voiceover.config.ts", "utf8");

const orderedSpecs = [
  "test/browser/specs/page-migration-wave-1.spec.ts",
  "test/browser/specs/page-migration-wave-2.spec.ts",
  "test/browser/specs/phase81-fixtures.spec.ts",
  "test/browser/specs/page-migration-wave-3.spec.ts",
  "test/browser/specs/system-quality-contract.spec.ts",
  "test/browser/specs/system-quality.spec.ts",
  "test/browser/specs/page.acceptance.spec.ts",
  "test/browser/specs/showcase.a11y.spec.ts",
  "test/browser/specs/showcase.vrt.spec.ts",
];

const validatorPrefix = [
  "npm run showcase:manifest",
  "node test/browser/support/verify-phase82-quality.mjs > test/browser/.generated/phase82-quality-report.json",
  "node test/browser/support/verify-page-baselines.mjs",
  "node test/browser/support/verify-page-aria-snapshots.mjs",
  "node test/browser/support/verify-page-script-order.mjs",
  "scripts/with-showcase-server.sh npm run verify:pages:docker --",
];

const unsafeEvidenceMode =
  /(?:--grep|--grep-invert|--update-snapshots|--watch|--ui|--retries(?:=|\s)|\|\|\s*true)\b/;
const detachedEvidence = /(?:^|[^&])&(?:[^&]|$)/;

function validatePackageScripts(scripts, voiceOverSource) {
  const verifyPages = scripts?.["verify:pages"];
  assert.equal(typeof verifyPages, "string", "verify:pages must exist");
  assertOrdered(verifyPages, validatorPrefix, "verify:pages validator graph");
  assert.equal(
    verifyPages,
    validatorPrefix.join(" && "),
    "verify:pages must be the exact manifest-first quality graph",
  );

  for (const fragment of validatorPrefix) {
    assert.equal(
      verifyPages.split(fragment).length - 1,
      1,
      `verify:pages must include ${fragment} exactly once`,
    );
  }

  for (const scriptName of ["verify:pages:host", "verify:pages:docker"]) {
    const command = scripts?.[scriptName];
    assert.equal(typeof command, "string", `${scriptName} must exist`);
    assert.match(
      command,
      /^PAGE_QUALITY_ONLY=1 /,
      `${scriptName} must be page-only`,
    );
    assert.doesNotMatch(
      command,
      unsafeEvidenceMode,
      `${scriptName} must never filter, mutate, retry, watch, or ignore evidence`,
    );
    assert.doesNotMatch(
      command,
      detachedEvidence,
      `${scriptName} must never detach evidence`,
    );

    if (scriptName === "verify:pages:host") {
      const actualSpecs = command
        .split(/\s+/)
        .filter((token) => token.startsWith("test/browser/specs/"));
      assert.deepEqual(
        actualSpecs,
        orderedSpecs,
        `${scriptName} spec order changed`,
      );

      for (const spec of orderedSpecs) {
        assert.equal(
          command.split(spec).length - 1,
          1,
          `${scriptName} must include ${spec} exactly once`,
        );
      }
    }
  }

  assert.match(
    scripts["verify:pages:host"],
    /^PAGE_QUALITY_ONLY=1 npx playwright test /,
    "host quality must own the native Playwright command",
  );
  assert.match(
    scripts["verify:pages:docker"],
    /^PAGE_QUALITY_ONLY=1 scripts\/playwright-docker\.sh bash scripts\/playwright-ci-suite\.sh pages$/,
    "Docker quality must use the isolated CI suite runner",
  );
  assert.equal(
    scripts["visual:a11y:docker"],
    "scripts/playwright-docker.sh bash scripts/playwright-ci-suite.sh full",
    "Full visual and accessibility CI must use the isolated CI suite runner",
  );
  assertOrdered(
    ciSuiteRunner,
    orderedSpecs,
    "CI suite runner must retain the complete page quality spec graph",
  );
  assert.match(
    ciSuiteRunner,
    /--fully-parallel[\s\S]*--workers=3/,
    "Only the showcase suite may opt into bounded parallel workers",
  );
  assert.match(
    ciSuiteRunner,
    /run_playwright "\$\{specs\[@\]\}"[\s\S]*showcase\.a11y\.spec\.ts/,
    "Connected fixture specs must finish before showcase parallelism starts",
  );

  const voiceOverCommand = scripts["verify:voiceover"];
  assert.equal(
    voiceOverCommand,
    "npx playwright test --config=voiceover.config.ts",
    "VoiceOver evidence must use only the canonical config",
  );
  assert.doesNotMatch(
    voiceOverCommand,
    unsafeEvidenceMode,
    "VoiceOver command must not override retry or evidence mode",
  );

  const retryDeclarations = [
    ...voiceOverSource.matchAll(/^\s*retries\s*:\s*([^,\n]+),?\s*$/gm),
  ];
  assert.equal(
    retryDeclarations.length,
    1,
    "VoiceOver config must declare retries exactly once",
  );
  assert.equal(
    retryDeclarations[0][1].trim(),
    "0",
    "VoiceOver retries must be explicit numeric zero",
  );
}

validatePackageScripts(packageJson.scripts, voiceOverConfig);

function expectPackageMutationFailure(name, mutate) {
  const scripts = structuredClone(packageJson.scripts);
  const fixture = { scripts, voiceOverConfig };
  const mutated = mutate(fixture);
  assert.notDeepEqual(
    mutated,
    { scripts: packageJson.scripts, voiceOverConfig },
    `${name} mutation fixture must change package/config input`,
  );
  assert.throws(
    () => validatePackageScripts(mutated.scripts, mutated.voiceOverConfig),
    undefined,
    `${name} mutation must fail the package/config validator`,
  );
}

expectPackageMutationFailure("omitted Phase 82 validator", (input) => {
  input.scripts["verify:pages"] = input.scripts["verify:pages"].replace(
    `${validatorPrefix[1]} && `,
    "",
  );
  return input;
});
expectPackageMutationFailure("reordered connected sweep", (input) => {
  const command = input.scripts["verify:pages:host"];
  input.scripts["verify:pages:host"] = command
    .replace(orderedSpecs[4], "__contract__")
    .replace(orderedSpecs[5], orderedSpecs[4])
    .replace("__contract__", orderedSpecs[5]);
  return input;
});
expectPackageMutationFailure("duplicated connected sweep", (input) => {
  input.scripts["verify:pages:docker"] += ` ${orderedSpecs[5]}`;
  return input;
});
for (const unsafe of [
  "--grep @phase82",
  "--update-snapshots=changed",
  "--watch",
  "--ui",
  "--retries=1",
  "|| true",
  "&",
]) {
  expectPackageMutationFailure(`${unsafe} browser bypass`, (input) => {
    input.scripts["verify:pages:host"] += ` ${unsafe}`;
    return input;
  });
}
for (const retryValue of [undefined, '"0"', "1", "process.env.CI ? 1 : 0"]) {
  expectPackageMutationFailure(
    `VoiceOver retry ${String(retryValue)}`,
    (input) => {
      input.voiceOverConfig =
        retryValue === undefined
          ? input.voiceOverConfig.replace(/^\s*retries\s*:.*\n/m, "")
          : input.voiceOverConfig.replace(
              /^(\s*)retries\s*:.*$/m,
              `$1retries: ${retryValue},`,
            );
      return input;
    },
  );
}
expectPackageMutationFailure("VoiceOver command retry override", (input) => {
  input.scripts["verify:voiceover"] += " --retries=1";
  return input;
});

/*
 * The package contract above intentionally runs before launcher checks. A
 * manifest or policy failure must stop before credentials, fixtures, or any
 * browser evidence can start.
 */
for (const scriptName of ["verify:pages:host", "verify:pages:docker"]) {
  const command = packageJson.scripts?.[scriptName];
  assert.equal(typeof command, "string", `${scriptName} must exist`);

  if (scriptName === "verify:pages:host") {
    const actualSpecs = command
      .split(/\s+/)
      .filter((token) => token.startsWith("test/browser/specs/"));
    assert.deepEqual(
      actualSpecs,
      orderedSpecs,
      `${scriptName} spec order changed`,
    );
    for (const spec of orderedSpecs) {
      assert.equal(
        command.split(spec).length - 1,
        1,
        `${scriptName} must include ${spec} exactly once`,
      );
    }
  }
}

function assertOrdered(source, fragments, label) {
  let cursor = -1;
  for (const fragment of fragments) {
    const next = source.indexOf(fragment, cursor + 1);
    assert.notEqual(next, -1, `${label} is missing ${fragment}`);
    assert.ok(next > cursor, `${label} must preserve 79→80→81 order`);
    cursor = next;
  }
}

assertOrdered(
  hostLauncher,
  [
    "PHASE79_BROWSER_FIXTURES=1",
    "PHASE80_BROWSER_FIXTURES=1",
    "PHASE81_BROWSER_FIXTURES=1",
  ],
  "host fixture flags",
);
assertOrdered(
  hostLauncher,
  [
    'PHASE79_BROWSER_FIXTURE_SECRET="$(openssl rand -hex 32)"',
    'PHASE80_BROWSER_FIXTURE_SECRET="$(openssl rand -hex 32)"',
    'PHASE81_BROWSER_FIXTURE_SECRET="$(openssl rand -hex 32)"',
  ],
  "host credential generation",
);
assertOrdered(
  hostLauncher.slice(hostLauncher.lastIndexOf("PLAYWRIGHT_TEST_BASE_URL=")),
  [
    'PHASE79_BROWSER_FIXTURE_SECRET="${PHASE79_BROWSER_FIXTURE_SECRET}"',
    'PHASE80_BROWSER_FIXTURE_SECRET="${PHASE80_BROWSER_FIXTURE_SECRET}"',
    'PHASE81_BROWSER_FIXTURE_SECRET="${PHASE81_BROWSER_FIXTURE_SECRET}"',
  ],
  "host command credential forwarding",
);
assert.doesNotMatch(
  hostLauncher,
  /(?:echo|printf).*(?:PHASE79|PHASE80|PHASE81)_BROWSER_FIXTURE_SECRET/,
  "host launcher must not print credentials",
);

assertOrdered(
  dockerLauncher,
  [
    "PHASE79_BROWSER_FIXTURE_SECRET",
    "PHASE80_BROWSER_FIXTURE_SECRET",
    "PHASE81_BROWSER_FIXTURE_SECRET",
  ],
  "Docker credential forwarding",
);
assert.match(
  dockerLauncher,
  /DOCKER_ARGS\+=\(-e PAGE_QUALITY_ONLY\)/,
  "Docker launcher must forward page-only mode",
);

function leadingSpaces(line) {
  return line.match(/^ */)[0].length;
}

function scalar(value) {
  const trimmed = value.trim();

  if (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return trimmed.slice(1, -1);
  }

  if (trimmed === "true") return true;
  if (trimmed === "false") return false;

  return trimmed;
}

function inlineList(value, label) {
  const trimmed = value.trim();
  assert.match(trimmed, /^\[.*\]$/, `${label} must be an inline YAML list`);

  const body = trimmed.slice(1, -1).trim();
  if (body === "") return [];

  return body.split(",").map((item) => scalar(item));
}

function parseStep(lines, start, end, label) {
  const step = {
    source: lines.slice(start, end).join("\n"),
  };
  const first = lines[start].match(/^ {6}-\s*(.*)$/);
  assert.ok(first, `${label} must start with a YAML sequence item`);

  const fields = [];
  if (first[1] !== "") fields.push({ line: start, source: first[1] });

  for (let index = start + 1; index < end; index += 1) {
    if (/^ {8}[A-Za-z0-9_-]+:/.test(lines[index])) {
      fields.push({ line: index, source: lines[index].slice(8) });
    }
  }

  for (const field of fields) {
    const match = field.source.match(/^([A-Za-z0-9_-]+):(?:\s*(.*))?$/);
    assert.ok(match, `${label} has an unsupported field: ${field.source}`);

    const [, key, rawValue = ""] = match;
    if (key === "run" && /^[>|][-+]?\d*$/.test(rawValue)) {
      const blockIndent = field.line === start ? 8 : 10;
      const block = [];

      for (let index = field.line + 1; index < end; index += 1) {
        if (lines[index].trim() === "") {
          block.push("");
          continue;
        }
        if (leadingSpaces(lines[index]) < blockIndent) break;
        block.push(lines[index].slice(blockIndent));
      }

      step.run = block.join("\n").trim();
    } else if (
      ["run", "name", "if", "uses", "continue-on-error"].includes(key)
    ) {
      step[key] = scalar(rawValue);
    }
  }

  return step;
}

function parseCiJobs(source) {
  const lines = source.replace(/\r\n/g, "\n").split("\n");
  assert.ok(
    lines.every((line) => !line.startsWith("\t")),
    "CI YAML must not use tab indentation",
  );

  const jobsLine = lines.findIndex((line) => line === "jobs:");
  assert.notEqual(jobsLine, -1, "CI YAML must define a top-level jobs mapping");

  const jobs = {};
  for (let index = jobsLine + 1; index < lines.length; index += 1) {
    const jobMatch = lines[index].match(/^ {2}([A-Za-z0-9_-]+):\s*$/);
    if (!jobMatch) continue;

    const jobName = jobMatch[1];
    assert.equal(jobs[jobName], undefined, `duplicate CI job ${jobName}`);

    let end = index + 1;
    while (
      end < lines.length &&
      (lines[end].trim() === "" || leadingSpaces(lines[end]) > 2)
    ) {
      end += 1;
    }

    const job = { needs: [], steps: [] };
    for (let cursor = index + 1; cursor < end; cursor += 1) {
      const property = lines[cursor].match(
        /^ {4}([A-Za-z0-9_-]+):(?:\s*(.*))?$/,
      );
      if (!property) continue;

      const [, key, rawValue = ""] = property;
      if (key === "needs") {
        if (rawValue.trim() !== "") {
          job.needs = inlineList(rawValue, `${jobName}.needs`);
        } else {
          const needs = [];
          let needsCursor = cursor + 1;
          while (needsCursor < end) {
            const item = lines[needsCursor].match(/^ {6}-\s*(.+)$/);
            if (!item) break;
            needs.push(scalar(item[1]));
            needsCursor += 1;
          }
          job.needs = needs;
        }
      } else if (key === "continue-on-error") {
        job.continueOnError = scalar(rawValue);
      } else if (key === "steps") {
        let stepCursor = cursor + 1;
        while (stepCursor < end) {
          if (!/^ {6}-\s*/.test(lines[stepCursor])) {
            stepCursor += 1;
            continue;
          }

          let stepEnd = stepCursor + 1;
          while (
            stepEnd < end &&
            (lines[stepEnd].trim() === "" || leadingSpaces(lines[stepEnd]) > 6)
          ) {
            stepEnd += 1;
          }

          job.steps.push(
            parseStep(
              lines,
              stepCursor,
              stepEnd,
              `${jobName}.steps[${job.steps.length}]`,
            ),
          );
          stepCursor = stepEnd;
        }
      }
    }

    jobs[jobName] = job;
    index = end - 1;
  }

  return jobs;
}

const requiredPageCommand = "npm run verify:pages";
const requiredVisualCommand = "npm run visual:a11y";
const requiredGateNeeds = [
  "format",
  "compile",
  "test",
  "page_quality",
  "visual_a11y",
  "docs_package",
  "actionlint",
];

function validateCiWorkflow(source) {
  const jobs = parseCiJobs(source);
  assert.ok(jobs.page_quality, "CI must define jobs.page_quality");
  assert.ok(jobs.visual_a11y, "CI must define jobs.visual_a11y");
  assert.ok(jobs["ci-gate"], "CI must define jobs.ci-gate");

  function findCommandSteps(requiredCommand) {
    return Object.entries(jobs).flatMap(([jobName, job]) =>
      job.steps
        .filter(
          (step) =>
            typeof step.run === "string" && step.run.includes(requiredCommand),
        )
        .map((step) => ({ jobName, job, step })),
    );
  }

  const commandSteps = findCommandSteps(requiredPageCommand);

  assert.equal(
    commandSteps.length,
    1,
    `${requiredPageCommand} must occur in exactly one structured run step`,
  );

  const [{ jobName, job, step }] = commandSteps;
  assert.equal(
    step.run,
    requiredPageCommand,
    `${requiredPageCommand} must be exact and unfiltered`,
  );
  assert.equal(
    jobName,
    "page_quality",
    `${requiredPageCommand} must belong to jobs.page_quality`,
  );
  assert.notEqual(
    job.continueOnError,
    true,
    "jobs.page_quality must not ignore failure",
  );
  assert.notEqual(
    step["continue-on-error"],
    true,
    `${requiredPageCommand} must not ignore failure`,
  );

  const visualCommandSteps = findCommandSteps(requiredVisualCommand);
  assert.equal(
    visualCommandSteps.length,
    1,
    `${requiredVisualCommand} must occur in exactly one structured run step`,
  );
  const [{ jobName: visualJobName, job: visualJob, step: visualStep }] =
    visualCommandSteps;
  assert.equal(
    visualStep.run,
    requiredVisualCommand,
    `${requiredVisualCommand} must be exact and unfiltered`,
  );
  assert.equal(
    visualJobName,
    "visual_a11y",
    `${requiredVisualCommand} must belong to jobs.visual_a11y`,
  );
  assert.notEqual(
    visualJob.continueOnError,
    true,
    "jobs.visual_a11y must not ignore failure",
  );
  assert.notEqual(
    visualStep["continue-on-error"],
    true,
    `${requiredVisualCommand} must not ignore failure`,
  );

  const pageArtifactSteps = jobs.page_quality.steps.filter(
    (candidate) =>
      candidate.source.includes(
        "uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02",
      ),
  );
  assert.equal(
    pageArtifactSteps.length,
    1,
    "page_quality must have exactly one pinned artifact upload",
  );
  const [pageArtifacts] = pageArtifactSteps;
  assert.equal(
    pageArtifacts.if,
    "failure()",
    "page_quality artifacts must upload only on failure",
  );
  for (const artifactPath of [
    "playwright-report/",
    "test-results/",
    "test/browser/.generated/showcase-manifest.json",
    "test/browser/.generated/phase82-quality-report.json",
  ]) {
    assert.match(
      pageArtifacts.source,
      new RegExp(
        `^\\s+${artifactPath.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\s*$`,
        "m",
      ),
      `page_quality artifacts must include bounded path ${artifactPath}`,
    );
  }
  assert.match(
    pageArtifacts.source,
    /^\s+retention-days:\s*7\s*$/m,
    "page_quality artifacts must retain bounded evidence for seven days",
  );

  const gateNeeds = jobs["ci-gate"].needs;
  assert.deepEqual(
    [...new Set(gateNeeds)],
    gateNeeds,
    "ci-gate.needs must not contain duplicate dependencies",
  );
  assert.deepEqual(
    gateNeeds,
    requiredGateNeeds,
    "ci-gate.needs must contain exactly the seven required jobs in canonical order",
  );
  assert.equal(
    gateNeeds.filter((dependency) => dependency === "page_quality").length,
    1,
    "jobs.page_quality must be a direct ci-gate.needs dependency exactly once",
  );
  assert.equal(
    gateNeeds.filter((dependency) => dependency === "visual_a11y").length,
    1,
    "jobs.visual_a11y must be a direct ci-gate.needs dependency exactly once",
  );
}

validateCiWorkflow(ciWorkflow);

function expectCiMutationFailure(name, mutate) {
  const mutated = mutate(ciWorkflow);
  assert.notEqual(
    mutated,
    ciWorkflow,
    `${name} mutation fixture must change CI`,
  );
  assert.throws(
    () => validateCiWorkflow(mutated),
    undefined,
    `${name} mutation must fail the CI validator`,
  );
}

expectCiMutationFailure("duplicate verify:pages", (source) =>
  source.replace(
    "      - run: npm run verify:pages",
    "      - run: npm run verify:pages\n      - run: npm run verify:pages",
  ),
);
expectCiMutationFailure("filtered verify:pages", (source) =>
  source.replace(
    "      - run: npm run verify:pages",
    "      - run: npm run verify:pages -- --grep page-batches",
  ),
);
expectCiMutationFailure("filtered visual:a11y", (source) =>
  source.replace(
    "      - run: npm run visual:a11y",
    "      - run: npm run visual:a11y -- --grep @phase82",
  ),
);
expectCiMutationFailure("wrong verify:pages job", (source) =>
  source.replace("  page_quality:\n", "  detached_page_quality:\n"),
);
expectCiMutationFailure("wrong visual:a11y job", (source) =>
  source.replace("  visual_a11y:\n", "  detached_visual_a11y:\n"),
);
expectCiMutationFailure("optional page_quality job", (source) =>
  source.replace(
    "  page_quality:\n    name: Page Quality",
    "  page_quality:\n    continue-on-error: true\n    name: Page Quality",
  ),
);
expectCiMutationFailure("optional visual_a11y job", (source) =>
  source.replace(
    "  visual_a11y:\n    name: Full Showcase Visual & A11y",
    "  visual_a11y:\n    continue-on-error: true\n    name: Full Showcase Visual & A11y",
  ),
);
expectCiMutationFailure("missing bounded Phase 82 report", (source) =>
  source.replace(
    "            test/browser/.generated/phase82-quality-report.json\n",
    "",
  ),
);
expectCiMutationFailure("missing page_quality gate dependency", (source) =>
  source.replace(
    "needs: [format, compile, test, page_quality, visual_a11y, docs_package, actionlint]",
    "needs: [format, compile, test, visual_a11y, docs_package, actionlint]",
  ),
);
expectCiMutationFailure("duplicate page_quality gate dependency", (source) =>
  source.replace(
    "needs: [format, compile, test, page_quality, visual_a11y, docs_package, actionlint]",
    "needs: [format, compile, test, page_quality, page_quality, visual_a11y, docs_package, actionlint]",
  ),
);
expectCiMutationFailure("incorrect ci-gate cardinality", (source) =>
  source.replace(
    "needs: [format, compile, test, page_quality, visual_a11y, docs_package, actionlint]",
    "needs: [format, compile, test, page_quality, visual_a11y, docs_package]",
  ),
);

console.log(
  "page quality contract passed: Wave 3 follows Wave 2 and exact full CI is merge-blocking",
);
