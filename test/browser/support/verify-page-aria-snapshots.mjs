import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const manifestPath = path.join(
  root,
  "test/browser/.generated/showcase-manifest.json",
);
const snapshotRoot = path.join(root, "test/browser/__aria_snapshots__");
const projects = ["chromium-320", "chromium-tablet", "chromium-wide"];
const expectedPages = [
  "overview",
  "cron",
  "limiters",
  "audit",
  "jobs",
  "forensics",
];
const expectedStoryCount = 49;
const expectedCount = expectedStoryCount * projects.length;

function fail(message) {
  throw new Error(`Invalid page ARIA snapshots: ${message}`);
}

if (!fs.existsSync(manifestPath)) {
  fail("missing generated manifest; run npm run showcase:manifest first");
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));

if (manifest.schema_version !== 8 || !Array.isArray(manifest.page_stories)) {
  fail("schema 8 with page_stories is required");
}

if (manifest.page_stories.length !== expectedStoryCount) {
  fail(
    `page_stories must contain ${expectedStoryCount} entries, got ${manifest.page_stories.length}`,
  );
}

for (const story of manifest.page_stories) {
  if (
    story.kind !== "page" ||
    !expectedPages.includes(story.page) ||
    !/^page-(overview|cron|limiters|audit|jobs|forensics)-[a-z0-9-]+$/.test(
      story.id,
    ) ||
    !story.id.startsWith(`page-${story.page}-`)
  ) {
    fail(`invalid page story ${JSON.stringify(story)}`);
  }
}

const pageFamilies = [
  ...new Set(manifest.page_stories.map((story) => story.page)),
];

if (JSON.stringify(pageFamilies) !== JSON.stringify(expectedPages)) {
  fail(
    `page families must be ${JSON.stringify(expectedPages)}, got ${JSON.stringify(pageFamilies)}`,
  );
}

const expected = new Set(
  projects.flatMap((project) =>
    manifest.page_stories.map((story) =>
      path.join(
        snapshotRoot,
        project,
        `${story.id}-aria.yml`,
      ),
    ),
  ),
);

if (expected.size !== expectedCount || expectedCount !== 147) {
  fail(
    `manifest-derived matrix must contain 49 * 3 = 147 unique paths, got ${expected.size}`,
  );
}

const args = process.argv.slice(2);
if (args.some((arg) => arg !== "--contract") || args.length > 1) {
  fail(
    "usage: node test/browser/support/verify-page-aria-snapshots.mjs [--contract]",
  );
}

if (args[0] === "--contract") {
  console.log(`page ARIA snapshot contract ok: ${expected.size} paths`);
  process.exit(0);
}

const actual = new Set();

if (fs.existsSync(snapshotRoot)) {
  for (const project of fs.readdirSync(snapshotRoot)) {
    const projectPath = path.join(snapshotRoot, project);
    if (!fs.statSync(projectPath).isDirectory()) continue;

    for (const file of fs.readdirSync(projectPath)) {
      const filePath = path.join(projectPath, file);
      if (fs.statSync(filePath).isFile()) actual.add(filePath);
    }
  }
}

const missing = [...expected].filter((file) => !actual.has(file));
const extra = [...actual].filter((file) => !expected.has(file));

if (missing.length > 0 || extra.length > 0) {
  fail(
    `expected ${expected.size} exact files; missing=${JSON.stringify(
      missing.map((file) => path.relative(root, file)),
    )}, extra=${JSON.stringify(
      extra.map((file) => path.relative(root, file)),
    )}`,
  );
}

for (const file of expected) {
  const contents = fs.readFileSync(file, "utf8").trim();
  if (contents.length === 0 || !contents.startsWith("- ")) {
    fail(`${path.relative(root, file)} is empty or not an ARIA snapshot`);
  }
}

console.log(`page ARIA snapshots ok: ${expected.size}`);
