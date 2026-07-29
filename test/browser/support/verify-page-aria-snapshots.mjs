import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

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
  "batches",
  "workflows",
  "lifeline",
];
const expectedStoryCount = 99;
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
    !/^page-(overview|cron|limiters|audit|jobs|forensics|batches|workflows|lifeline)-[a-z0-9-]+$/.test(
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
      path.join(snapshotRoot, project, `${story.id}-aria.yml`),
    ),
  ),
);

if (expected.size !== expectedCount || expectedCount !== 297) {
  fail(
    `manifest-derived matrix must contain 99 * 3 = 297 unique paths, got ${expected.size}`,
  );
}

const args = process.argv.slice(2);
if (
  args.some(
    (arg) =>
      arg !== "--contract" &&
      arg !== "--changed-scope" &&
      arg !== "--self-test",
  ) ||
  args.length > 1
) {
  fail(
    "usage: node test/browser/support/verify-page-aria-snapshots.mjs [--contract|--changed-scope|--self-test]",
  );
}

if (args[0] === "--contract") {
  console.log(`page ARIA snapshot contract ok: ${expected.size} paths`);
  process.exit(0);
}

function slash(value) {
  return value.split(path.sep).join("/");
}

function repoRelative(value) {
  return slash(path.relative(root, value));
}

function reportSetDifference(expectedPaths, actualPaths, label) {
  const missing = [...expectedPaths]
    .filter((file) => !actualPaths.has(file))
    .sort();
  const extra = [...actualPaths]
    .filter((file) => !expectedPaths.has(file))
    .sort();

  if (missing.length > 0 || extra.length > 0) {
    fail(
      `${label} must contain ${expectedPaths.size} exact files; missing=${JSON.stringify(
        missing.map(repoRelative),
      )}, extra=${JSON.stringify(extra.map(repoRelative))}`,
    );
  }

  if (actualPaths.size !== expectedCount) {
    fail(
      `${label} page ARIA cardinality must be ${expectedCount}, got ${actualPaths.size}`,
    );
  }
}

function trackedPagePaths() {
  const output = execFileSync(
    "git",
    ["ls-files", "-z", "--", "test/browser/__aria_snapshots__"],
    { cwd: root, encoding: "utf8" },
  );

  return new Set(
    output
      .split("\0")
      .filter(Boolean)
      .map((file) => path.join(root, file))
      .filter(
        (file) =>
          path.basename(file).startsWith("page-") && file.endsWith("-aria.yml"),
      ),
  );
}

function changedSnapshotEntries() {
  const output = execFileSync(
    "git",
    [
      "status",
      "--porcelain=v1",
      "-z",
      "--untracked-files=all",
      "--",
      "test/browser/__aria_snapshots__",
    ],
    { cwd: root, encoding: "utf8" },
  );
  const records = output.split("\0");
  const entries = [];

  for (let index = 0; index < records.length; index += 1) {
    const record = records[index];
    if (!record) continue;

    const status = record.slice(0, 2);
    const entry = {
      status,
      path: path.join(root, record.slice(3)),
      pairedPath: null,
    };

    if (status.includes("R") || status.includes("C")) {
      const pairedPath = records[index + 1];
      if (!pairedPath)
        fail(`malformed git status rename/copy record for ${record.slice(3)}`);
      entry.pairedPath = path.join(root, pairedPath);
      index += 1;
    }

    entries.push(entry);
  }

  return entries;
}

function validateChangedSnapshotEntries(entries, expectedPaths) {
  const renamedOrCopied = entries.filter(
    ({ status }) => status.includes("R") || status.includes("C"),
  );
  const untracked = entries.filter(({ status }) => status === "??");
  const changedPaths = entries.flatMap(({ path: file, pairedPath }) =>
    pairedPath ? [file, pairedPath] : [file],
  );
  const outside = [
    ...new Set(changedPaths.filter((file) => !expectedPaths.has(file))),
  ].sort();

  if (renamedOrCopied.length > 0) {
    fail(
      `renamed/copied ARIA snapshots are not accepted: ${renamedOrCopied
        .map(
          ({ status, path: file, pairedPath }) =>
            `${status} ${repoRelative(file)}${pairedPath ? ` -> ${repoRelative(pairedPath)}` : ""}`,
        )
        .join(", ")}`,
    );
  }

  if (untracked.length > 0) {
    fail(
      `untracked page ARIA snapshots must be reviewed and staged: ${untracked
        .map(({ path: file }) => repoRelative(file))
        .join(", ")}`,
    );
  }

  if (outside.length > 0) {
    fail(
      `changed ARIA snapshots outside page matrix (${outside.length}):\n${outside
        .map(repoRelative)
        .join("\n")}`,
    );
  }

  return changedPaths;
}

function expectFailure(label, callback) {
  try {
    callback();
  } catch {
    return;
  }
  fail(`self-test ${label} did not reject invalid input`);
}

function runSelfTest() {
  const sample = new Set([
    path.join(
      root,
      "test/browser/__aria_snapshots__/chromium-wide/page-a-aria.yml",
    ),
    path.join(
      root,
      "test/browser/__aria_snapshots__/chromium-wide/page-b-aria.yml",
    ),
  ]);

  expectFailure("missing", () =>
    reportSetDifference(sample, new Set([...sample].slice(0, 1)), "sample"),
  );
  expectFailure("extra", () =>
    reportSetDifference(
      sample,
      new Set([
        ...sample,
        path.join(root, "test/browser/__aria_snapshots__/page-c-aria.yml"),
      ]),
      "sample",
    ),
  );
  expectFailure("untracked", () =>
    validateChangedSnapshotEntries(
      [{ status: "??", path: [...sample][0], pairedPath: null }],
      sample,
    ),
  );
  expectFailure("renamed", () =>
    validateChangedSnapshotEntries(
      [{ status: "R ", path: [...sample][0], pairedPath: [...sample][1] }],
      sample,
    ),
  );
  expectFailure("unexpected scope", () =>
    validateChangedSnapshotEntries(
      [
        {
          status: "M ",
          path: path.join(root, "unexpected-aria.yml"),
          pairedPath: null,
        },
      ],
      sample,
    ),
  );

  console.log(
    "page ARIA self-test ok: missing, extra, untracked, renamed, and unexpected scope rejected",
  );
}

if (args[0] === "--self-test") {
  runSelfTest();
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

reportSetDifference(expected, actual, "filesystem");
reportSetDifference(expected, trackedPagePaths(), "tracked");

if (args[0] === "--changed-scope") {
  const changed = validateChangedSnapshotEntries(
    changedSnapshotEntries(),
    expected,
  );
  console.log(
    `page ARIA changed scope ok: ${changed.length} paths, all tracked within ${expectedCount}`,
  );
  process.exit(0);
}

for (const file of expected) {
  const contents = fs.readFileSync(file, "utf8").trim();
  if (contents.length === 0 || !contents.startsWith("- ")) {
    fail(`${path.relative(root, file)} is empty or not an ARIA snapshot`);
  }
}

console.log(`page ARIA snapshots ok: ${expected.size}`);
