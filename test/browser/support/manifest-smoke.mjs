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

equal(manifest.schema_version, 6, 'schema_version');
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
  equal(actual.a11y, `[data-obpt-primitive-story="${id}"]`, `primitive_stories[${index}].a11y`);

  expectedTargets.push({ ...actual });
}

const formStories = array(manifest.form_stories, 'form_stories');
equal(formStories.length, 9, 'form_stories.length');

for (const [index, story] of formStories.entries()) {
  const actual = record(story, `form_stories[${index}]`);
  const id = string(actual.id, `form_stories[${index}].id`);
  const components = array(actual.components, `form_stories[${index}].components`);
  const variant = array(actual.variant, `form_stories[${index}].variant`);
  const state = array(actual.state, `form_stories[${index}].state`);

  equal(actual.kind, 'form', `form_stories[${index}].kind`);
  if (!/^form-[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
    fail(`form_stories[${index}].id must be a slug-like form-* identifier`);
  }
  string(actual.component, `form_stories[${index}].component`);
  string(actual.name, `form_stories[${index}].name`);
  string(actual.description, `form_stories[${index}].description`);
  equal(components.length > 0, true, `form_stories[${index}].components non-empty`);
  equal(variant.length > 0, true, `form_stories[${index}].variant non-empty`);
  equal(state.length > 0, true, `form_stories[${index}].state non-empty`);
  equal(actual.story, `obpt-form-story-${id}`, `form_stories[${index}].story`);
  equal(actual.snapshot, `showcase/${id}`, `form_stories[${index}].snapshot`);
  equal(actual.a11y, `[data-obpt-form-story="${id}"]`, `form_stories[${index}].a11y`);

  expectedTargets.push({ ...actual });
}

const shellStories = array(manifest.shell_stories, 'shell_stories');
equal(shellStories.length, 6, 'shell_stories.length');

for (const [index, story] of shellStories.entries()) {
  const actual = record(story, `shell_stories[${index}]`);
  const id = string(actual.id, `shell_stories[${index}].id`);
  const components = array(actual.components, `shell_stories[${index}].components`);
  const variant = array(actual.variant, `shell_stories[${index}].variant`);
  const state = array(actual.state, `shell_stories[${index}].state`);

  equal(actual.kind, 'shell', `shell_stories[${index}].kind`);
  if (!/^shell-[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
    fail(`shell_stories[${index}].id must be a slug-like shell-* identifier`);
  }
  string(actual.component, `shell_stories[${index}].component`);
  string(actual.name, `shell_stories[${index}].name`);
  string(actual.description, `shell_stories[${index}].description`);
  equal(components.length > 0, true, `shell_stories[${index}].components non-empty`);
  equal(variant.length > 0, true, `shell_stories[${index}].variant non-empty`);
  equal(state.length > 0, true, `shell_stories[${index}].state non-empty`);
  if (actual.nav_state !== 'closed' && actual.nav_state !== 'open') {
    fail(`shell_stories[${index}].nav_state must be "closed" or "open"`);
  }
  equal(actual.story, `obpt-shell-story-${id}`, `shell_stories[${index}].story`);
  equal(actual.snapshot, `showcase/${id}`, `shell_stories[${index}].snapshot`);
  equal(actual.a11y, `[data-obpt-shell-story="${id}"]`, `shell_stories[${index}].a11y`);

  expectedTargets.push({ ...actual });
}

const dataStories = array(manifest.data_stories, 'data_stories');
equal(dataStories.length, 10, 'data_stories.length');

for (const [index, story] of dataStories.entries()) {
  const actual = record(story, `data_stories[${index}]`);
  const id = string(actual.id, `data_stories[${index}].id`);
  const components = array(actual.components, `data_stories[${index}].components`);
  const variant = array(actual.variant, `data_stories[${index}].variant`);
  const state = array(actual.state, `data_stories[${index}].state`);

  equal(actual.kind, 'data', `data_stories[${index}].kind`);
  if (!/^data-[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
    fail(`data_stories[${index}].id must be a slug-like data-* identifier`);
  }
  string(actual.component, `data_stories[${index}].component`);
  string(actual.name, `data_stories[${index}].name`);
  string(actual.description, `data_stories[${index}].description`);
  equal(components.length > 0, true, `data_stories[${index}].components non-empty`);
  equal(variant.length > 0, true, `data_stories[${index}].variant non-empty`);
  equal(state.length > 0, true, `data_stories[${index}].state non-empty`);
  equal(actual.story, `obpt-data-story-${id}`, `data_stories[${index}].story`);
  equal(actual.snapshot, `showcase/${id}`, `data_stories[${index}].snapshot`);
  equal(actual.a11y, `[data-obpt-data-story="${id}"]`, `data_stories[${index}].a11y`);

  expectedTargets.push({ ...actual });
}

const groupStories = array(manifest.group_stories, 'group_stories');
equal(groupStories.length, 23, 'group_stories.length');

const groupIds = new Set();

for (const [index, story] of groupStories.entries()) {
  const actual = record(story, `group_stories[${index}]`);
  const id = string(actual.id, `group_stories[${index}].id`);
  const components = array(actual.components, `group_stories[${index}].components`);
  const variant = array(actual.variant, `group_stories[${index}].variant`);
  const state = array(actual.state, `group_stories[${index}].state`);

  equal(actual.kind, 'group', `group_stories[${index}].kind`);
  if (!/^group-[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
    fail(`group_stories[${index}].id must be a slug-like group-* identifier`);
  }
  equal(groupIds.has(id), false, `group_stories[${index}].id unique`);
  groupIds.add(id);
  string(actual.component, `group_stories[${index}].component`);
  string(actual.name, `group_stories[${index}].name`);
  string(actual.description, `group_stories[${index}].description`);
  equal(components.length > 0, true, `group_stories[${index}].components non-empty`);
  equal(variant.length > 0, true, `group_stories[${index}].variant non-empty`);
  equal(state.length > 0, true, `group_stories[${index}].state non-empty`);
  if (actual.activation !== 'none' && actual.activation !== 'overlay') {
    fail(`group_stories[${index}].activation must be "none" or "overlay"`);
  }
  equal(actual.story, `obpt-group-story-${id}`, `group_stories[${index}].story`);
  equal(actual.snapshot, `showcase/${id}`, `group_stories[${index}].snapshot`);
  equal(actual.a11y, `[data-obpt-group-story="${id}"]`, `group_stories[${index}].a11y`);

  expectedTargets.push({ ...actual });
}

const targets = array(manifest.targets, 'targets');
equal(expectedTargets.length, 64, 'expected targets.length');
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

  if (expected.kind === 'form') {
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

  if (expected.kind === 'shell') {
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
    equal(actual.nav_state, expected.nav_state, `targets[${index}].nav_state`);
  }

  if (expected.kind === 'data') {
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

  if (expected.kind === 'group') {
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
    equal(actual.activation, expected.activation, `targets[${index}].activation`);
  }
}

console.log(
  `showcase manifest ok: ${scenarios.length} scenarios, ${primitiveStories.length} primitive stories, ${formStories.length} form stories, ${shellStories.length} shell stories, ${dataStories.length} data stories, ${groupStories.length} group stories, ${targets.length} targets, ${expectedThemes.length} themes, ${expectedViewports.length} viewports`
);
