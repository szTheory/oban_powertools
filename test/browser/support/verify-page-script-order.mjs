import assert from "node:assert/strict";
import fs from "node:fs";

const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8"));
const hostLauncher = fs.readFileSync("scripts/with-showcase-server.sh", "utf8");
const dockerLauncher = fs.readFileSync("scripts/playwright-docker.sh", "utf8");

const orderedSpecs = [
  "test/browser/specs/page-migration-wave-1.spec.ts",
  "test/browser/specs/page-migration-wave-2.spec.ts",
  "test/browser/specs/phase81-fixtures.spec.ts",
  "test/browser/specs/page-migration-wave-3.spec.ts",
  "test/browser/specs/page.acceptance.spec.ts",
  "test/browser/specs/showcase.a11y.spec.ts",
  "test/browser/specs/showcase.vrt.spec.ts",
];

for (const scriptName of ["verify:pages:host", "verify:pages:docker"]) {
  const command = packageJson.scripts?.[scriptName];
  assert.equal(typeof command, "string", `${scriptName} must exist`);
  assert.match(
    command,
    /^PAGE_QUALITY_ONLY=1 /,
    `${scriptName} must be page-only`,
  );
  assert.doesNotMatch(
    command,
    /(?:--update-snapshots|--watch|--ui)\b/,
    `${scriptName} must never mutate or watch evidence`,
  );

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

assert.match(
  packageJson.scripts["verify:pages:host"],
  /^PAGE_QUALITY_ONLY=1 npx playwright test /,
  "host quality must own the native Playwright command",
);
assert.match(
  packageJson.scripts["verify:pages:docker"],
  /^PAGE_QUALITY_ONLY=1 scripts\/playwright-docker\.sh npx playwright test /,
  "Docker quality must use the authoritative Docker launcher",
);

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

console.log(
  "page quality script contract passed: Wave 3 follows Wave 2 in host and Docker flows",
);
