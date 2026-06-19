import fs from 'node:fs';
import path from 'node:path';

const manifestPath = path.join(process.cwd(), 'test/browser/.generated/showcase-manifest.json');
const expectedThemes = ['system', 'light', 'dark', 'high-contrast'];
const expectedViewports = [
  { name: '320', width: 320, height: 900 },
  { name: 'tablet', width: 768, height: 1000 },
  { name: 'wide', width: 1440, height: 1000 }
];

function fail(message) {
  throw new Error(`Invalid showcase manifest: ${message}`);
}

function record(value, label) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    fail(`${label} must be an object`);
  }

  return value;
}

function array(value, label) {
  if (!Array.isArray(value)) {
    fail(`${label} must be an array`);
  }

  return value;
}

function string(value, label) {
  if (typeof value !== 'string' || value.length === 0) {
    fail(`${label} must be a non-empty string`);
  }

  return value;
}

function equal(actual, expected, label) {
  if (actual !== expected) {
    fail(`${label} must be ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

function exactList(actual, expected, label) {
  equal(actual.length, expected.length, `${label}.length`);

  expected.forEach((expectedValue, index) => {
    equal(actual[index], expectedValue, `${label}[${index}]`);
  });
}

function loadManifest() {
  if (!fs.existsSync(manifestPath)) {
    fail(`missing ${manifestPath}; run npm run showcase:manifest first`);
  }

  return record(JSON.parse(fs.readFileSync(manifestPath, 'utf8')), 'manifest');
}

const manifest = loadManifest();

equal(manifest.schema_version, 1, 'schema_version');
exactList(array(manifest.themes, 'themes'), expectedThemes, 'themes');

const viewports = array(manifest.viewports, 'viewports');
equal(viewports.length, expectedViewports.length, 'viewports.length');

viewports.forEach((viewport, index) => {
  const actual = record(viewport, `viewports[${index}]`);
  const expected = expectedViewports[index];

  equal(actual.name, expected.name, `viewports[${index}].name`);
  equal(actual.width, expected.width, `viewports[${index}].width`);
  equal(actual.height, expected.height, `viewports[${index}].height`);
});

const scenarios = array(manifest.scenarios, 'scenarios');
equal(scenarios.length, 9, 'scenarios.length');

for (const [index, scenario] of scenarios.entries()) {
  const actual = record(scenario, `scenarios[${index}]`);
  const id = string(actual.id, `scenarios[${index}].id`);
  const states = array(actual.states, `scenarios[${index}].states`);

  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
    fail(`scenarios[${index}].id must be a slug-like identifier`);
  }

  string(actual.domain, `scenarios[${index}].domain`);
  string(actual.persona, `scenarios[${index}].persona`);
  equal(states.length > 0, true, `scenarios[${index}].states non-empty`);
  equal(actual.story, `obpt-story-${id}`, `scenarios[${index}].story`);
  equal(actual.snapshot, `showcase/${id}`, `scenarios[${index}].snapshot`);
  equal(actual.a11y, `[data-obpt-story="${id}"]`, `scenarios[${index}].a11y`);
}

console.log(
  `showcase manifest ok: ${scenarios.length} scenarios, ${expectedThemes.length} themes, ${expectedViewports.length} viewports`
);
