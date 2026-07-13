import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const root = process.cwd();
const manifestPath = path.join(
  root,
  "test/browser/.generated/showcase-manifest.json",
);
const screenshotRoot = path.join(root, "test/browser/__screenshots__");
const expectedCount = 120;
const expectedThemes = ["system", "light", "dark", "high-contrast"];
const viewportProjects = new Map([
  ["320", { project: "chromium-320", width: 320, height: 900 }],
  ["tablet", { project: "chromium-tablet", width: 768, height: 1000 }],
  ["wide", { project: "chromium-wide", width: 1440, height: 1000 }],
]);

function fail(message) {
  throw new Error(`Invalid data baselines: ${message}`);
}

function slash(value) {
  return value.split(path.sep).join("/");
}

function repoRelative(value) {
  return slash(path.relative(root, value));
}

function readManifest() {
  if (!fs.existsSync(manifestPath)) {
    fail(
      `missing ${repoRelative(manifestPath)}; run npm run showcase:manifest first`,
    );
  }

  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));

  if (manifest.schema_version !== 5) {
    fail(
      `schema_version must be 5, got ${JSON.stringify(manifest.schema_version)}`,
    );
  }

  for (const field of ["data_stories", "themes", "viewports"]) {
    if (!Array.isArray(manifest[field])) {
      fail(`${field} must be an array`);
    }
  }

  if (manifest.data_stories.length !== 10) {
    fail(
      `data_stories must contain 10 entries, got ${manifest.data_stories.length}`,
    );
  }

  if (JSON.stringify(manifest.themes) !== JSON.stringify(expectedThemes)) {
    fail(
      `themes must be ${JSON.stringify(expectedThemes)}, got ${JSON.stringify(manifest.themes)}`,
    );
  }

  if (manifest.viewports.length !== viewportProjects.size) {
    fail(
      `viewports must contain ${viewportProjects.size} entries, got ${manifest.viewports.length}`,
    );
  }

  return manifest;
}

function expectedPaths(manifest) {
  const expected = [];

  for (const viewport of manifest.viewports) {
    const expectedViewport = viewportProjects.get(viewport.name);
    if (!expectedViewport) {
      fail(
        `viewport ${JSON.stringify(viewport.name)} has no Chromium project mapping`,
      );
    }
    if (
      viewport.width !== expectedViewport.width ||
      viewport.height !== expectedViewport.height
    ) {
      fail(
        `viewport ${JSON.stringify(viewport.name)} must be ${expectedViewport.width}x${expectedViewport.height}, got ${viewport.width}x${viewport.height}`,
      );
    }

    for (const story of manifest.data_stories) {
      if (
        story.kind !== "data" ||
        !/^showcase\/data-[a-z0-9-]+$/.test(story.snapshot)
      ) {
        fail(`invalid data story snapshot ${JSON.stringify(story.snapshot)}`);
      }

      for (const theme of manifest.themes) {
        expected.push(
          `test/browser/__screenshots__/${expectedViewport.project}/${story.snapshot}/${theme}.png`,
        );
      }
    }
  }

  const unique = new Set(expected);
  if (expected.length !== expectedCount || unique.size !== expectedCount) {
    fail(
      `manifest-derived matrix must contain ${expectedCount} unique paths, got ${expected.length} paths and ${unique.size} unique paths`,
    );
  }

  return unique;
}

function walk(directory) {
  if (!fs.existsSync(directory)) return [];

  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const entryPath = path.join(directory, entry.name);
    return entry.isDirectory() ? walk(entryPath) : [entryPath];
  });
}

function actualDataPaths() {
  return new Set(
    walk(screenshotRoot)
      .filter((file) => file.endsWith(".png"))
      .map(repoRelative)
      .filter((file) =>
        file.split("/").some((segment) => segment.startsWith("data-")),
      ),
  );
}

function reportSetDifference(expected, actual) {
  const missing = [...expected].filter((file) => !actual.has(file)).sort();
  const extra = [...actual].filter((file) => !expected.has(file)).sort();

  if (missing.length > 0 || extra.length > 0) {
    const diagnostics = [];
    if (missing.length > 0)
      diagnostics.push(`missing (${missing.length}):\n${missing.join("\n")}`);
    if (extra.length > 0)
      diagnostics.push(`extra (${extra.length}):\n${extra.join("\n")}`);
    fail(diagnostics.join("\n"));
  }

  if (actual.size !== expectedCount) {
    fail(
      `actual data baseline cardinality must be ${expectedCount}, got ${actual.size}`,
    );
  }
}

function changedScreenshotPaths() {
  const output = execFileSync(
    "git",
    [
      "status",
      "--porcelain=v1",
      "-z",
      "--untracked-files=all",
      "--",
      "test/browser/__screenshots__",
    ],
    { cwd: root, encoding: "utf8" },
  );
  const records = output.split("\0");
  const paths = [];

  for (let index = 0; index < records.length; index += 1) {
    const record = records[index];
    if (!record) continue;

    const status = record.slice(0, 2);
    paths.push(slash(record.slice(3)));

    if (status.includes("R") || status.includes("C")) {
      const pairedPath = records[index + 1];
      if (!pairedPath)
        fail(`malformed git status rename/copy record for ${record.slice(3)}`);
      paths.push(slash(pairedPath));
      index += 1;
    }
  }

  return paths;
}

const args = process.argv.slice(2);
if (args.some((arg) => arg !== "--changed-scope") || args.length > 1) {
  fail(
    "usage: node test/browser/support/verify-data-baselines.mjs [--changed-scope]",
  );
}

const expected = expectedPaths(readManifest());

if (args[0] === "--changed-scope") {
  const changed = changedScreenshotPaths();
  const outside = [
    ...new Set(changed.filter((file) => !expected.has(file))),
  ].sort();

  if (outside.length > 0) {
    fail(
      `changed screenshots outside data matrix (${outside.length}):\n${outside.join("\n")}`,
    );
  }

  console.log(
    `data baseline changed scope ok: ${changed.length} paths, all within ${expectedCount}`,
  );
} else {
  const actual = actualDataPaths();
  reportSetDifference(expected, actual);
  console.log(`data baselines ok: ${actual.size}`);
}
