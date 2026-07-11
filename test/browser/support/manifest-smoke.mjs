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

equal(manifest.schema_version, 2, 'schema_version');
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

const expectedTargets = [];

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

  expectedTargets.push({ kind: 'scenario', ...actual });
}

const primitiveStories = array(manifest.primitive_stories, 'primitive_stories');
equal(primitiveStories.length, 7, 'primitive_stories.length');

for (const [index, story] of primitiveStories.entries()) {
  const actual = record(story, `primitive_stories[${index}]`);
  const id = string(actual.id, `primitive_stories[${index}].id`);
  const components = array(actual.components, `primitive_stories[${index}].components`);
  const variant = array(actual.variant, `primitive_stories[${index}].variant`);
  const state = array(actual.state, `primitive_stories[${index}].state`);

  equal(actual.kind, 'primitive', `primitive_stories[${index}].kind`);

  if (!/^primitive-[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
    fail(`primitive_stories[${index}].id must be a slug-like primitive-* identifier`);
  }

  string(actual.component, `primitive_stories[${index}].component`);
  string(actual.name, `primitive_stories[${index}].name`);
  string(actual.description, `primitive_stories[${index}].description`);
  equal(components.length > 0, true, `primitive_stories[${index}].components non-empty`);
  equal(variant.length > 0, true, `primitive_stories[${index}].variant non-empty`);
  equal(state.length > 0, true, `primitive_stories[${index}].state non-empty`);
  equal(actual.story, `obpt-primitive-story-${id}`, `primitive_stories[${index}].story`);
  equal(actual.snapshot, `showcase/${id}`, `primitive_stories[${index}].snapshot`);
  equal(
    actual.a11y,
    `[data-obpt-primitive-story="${id}"]`,
    `primitive_stories[${index}].a11y`
  );

  expectedTargets.push({ ...actual });
}

const targets = array(manifest.targets, 'targets');
equal(targets.length, expectedTargets.length, 'targets.length');

for (const [index, target] of targets.entries()) {
  const actual = record(target, `targets[${index}]`);
  const expected = expectedTargets[index];

  equal(actual.kind, expected.kind, `targets[${index}].kind`);
  equal(actual.id, expected.id, `targets[${index}].id`);
  equal(actual.story, expected.story, `targets[${index}].story`);
  equal(actual.snapshot, expected.snapshot, `targets[${index}].snapshot`);
  equal(actual.a11y, expected.a11y, `targets[${index}].a11y`);

  if (expected.kind === 'scenario') {
    equal(actual.domain, expected.domain, `targets[${index}].domain`);
    equal(actual.persona, expected.persona, `targets[${index}].persona`);
    exactList(
      array(actual.states, `targets[${index}].states`),
      expected.states,
      `targets[${index}].states`
    );
  }

  if (expected.kind === 'primitive') {
    equal(actual.component, expected.component, `targets[${index}].component`);
    exactList(
      array(actual.components, `targets[${index}].components`),
      expected.components,
      `targets[${index}].components`
    );
    equal(actual.name, expected.name, `targets[${index}].name`);
    equal(actual.description, expected.description, `targets[${index}].description`);
    exactList(
      array(actual.variant, `targets[${index}].variant`),
      expected.variant,
      `targets[${index}].variant`
    );
    exactList(
      array(actual.state, `targets[${index}].state`),
      expected.state,
      `targets[${index}].state`
    );
  }
}

console.log(
  `showcase manifest ok: ${scenarios.length} scenarios, ${primitiveStories.length} primitive stories, ${targets.length} targets, ${expectedThemes.length} themes, ${expectedViewports.length} viewports`
);
