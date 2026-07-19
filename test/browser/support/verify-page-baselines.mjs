import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const root = process.cwd();
const manifestPath = path.join(
  root,
  "test/browser/.generated/showcase-manifest.json",
);
const screenshotRoot = path.join(root, "test/browser/__screenshots__");
const expectedStoryCount = 19;
const expectedThemes = ["system", "light", "dark", "high-contrast"];
const viewportProjects = new Map([
  ["320", { project: "chromium-320", width: 320, height: 900 }],
  ["tablet", { project: "chromium-tablet", width: 768, height: 1000 }],
  ["wide", { project: "chromium-wide", width: 1440, height: 1000 }],
]);
const expectedCount =
  expectedStoryCount * expectedThemes.length * viewportProjects.size;

function fail(message) {
  throw new Error(`Invalid page baselines: ${message}`);
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

  if (manifest.schema_version !== 7) {
    fail(
      `schema_version must be 7, got ${JSON.stringify(manifest.schema_version)}`,
    );
  }

  for (const field of ["page_stories", "themes", "viewports"]) {
    if (!Array.isArray(manifest[field])) {
      fail(`${field} must be an array`);
    }
  }

  if (manifest.page_stories.length !== expectedStoryCount) {
    fail(
      `page_stories must contain ${expectedStoryCount} entries, got ${manifest.page_stories.length}`,
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

function validatePageStory(story) {
  if (
    story.kind !== "page" ||
    !/^page-(overview|cron|limiters|audit)-[a-z0-9-]+$/.test(story.id) ||
    story.story !== `obpt-page-story-${story.id}` ||
    story.snapshot !== `showcase/${story.id}` ||
    story.a11y !== `[data-obpt-page-story="${story.id}"]` ||
    !["none", "detail", "confirmation"].includes(story.activation)
  ) {
    fail(
      `invalid page story ${JSON.stringify({
        id: story.id,
        kind: story.kind,
        story: story.story,
        snapshot: story.snapshot,
        a11y: story.a11y,
        activation: story.activation,
      })}`,
    );
  }
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

    for (const story of manifest.page_stories) {
      validatePageStory(story);

      for (const theme of manifest.themes) {
        expected.push(
          `test/browser/__screenshots__/${expectedViewport.project}/${story.snapshot}/${theme}.png`,
        );
      }
    }
  }

  const unique = new Set(expected);
  if (
    expectedCount !== 228 ||
    expected.length !== expectedCount ||
    unique.size !== expectedCount
  ) {
    fail(
      `manifest-derived matrix must contain 19 * 4 * 3 = 228 unique paths, got ${expected.length} paths and ${unique.size} unique paths`,
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

function actualPagePaths() {
  return new Set(
    walk(screenshotRoot)
      .filter((file) => file.endsWith(".png"))
      .map(repoRelative)
      .filter((file) =>
        file.split("/").some((segment) => segment.startsWith("page-")),
      ),
  );
}

function reportSetDifference(expected, actual) {
  const missing = [...expected].filter((file) => !actual.has(file)).sort();
  const extra = [...actual].filter((file) => !expected.has(file)).sort();

  if (missing.length > 0 || extra.length > 0) {
    const diagnostics = [];
    if (missing.length > 0) {
      diagnostics.push(`missing (${missing.length}):\n${missing.join("\n")}`);
    }
    if (extra.length > 0) {
      diagnostics.push(`extra (${extra.length}):\n${extra.join("\n")}`);
    }
    fail(diagnostics.join("\n"));
  }

  if (actual.size !== expectedCount) {
    fail(
      `actual page baseline cardinality must be ${expectedCount}, got ${actual.size}`,
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
      if (!pairedPath) {
        fail(`malformed git status rename/copy record for ${record.slice(3)}`);
      }
      paths.push(slash(pairedPath));
      index += 1;
    }
  }

  return paths;
}

const args = process.argv.slice(2);
if (args.some((arg) => arg !== "--changed-scope") || args.length > 1) {
  fail(
    "usage: node test/browser/support/verify-page-baselines.mjs [--changed-scope]",
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
      `changed screenshots outside page matrix (${outside.length}):\n${outside.join("\n")}`,
    );
  }

  console.log(
    `page baseline changed scope ok: ${changed.length} paths, all within ${expectedCount}`,
  );
} else {
  const actual = actualPagePaths();
  reportSetDifference(expected, actual);
  console.log(`page baselines ok: ${actual.size}`);
}
