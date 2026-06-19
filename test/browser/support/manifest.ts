import fs from 'node:fs';
import path from 'node:path';

const manifestPath = path.join(process.cwd(), 'test/browser/.generated/showcase-manifest.json');
const allowedThemes = ['system', 'light', 'dark', 'high-contrast'] as const;
const expectedViewports = [
  { name: '320', width: 320, height: 900 },
  { name: 'tablet', width: 768, height: 1000 },
  { name: 'wide', width: 1440, height: 1000 }
] as const;

export type ShowcaseTheme = (typeof allowedThemes)[number];
export type ViewportName = (typeof expectedViewports)[number]['name'];

export type ShowcaseViewport = {
  name: ViewportName;
  width: number;
  height: number;
};

export type ShowcaseScenario = {
  id: string;
  domain: string;
  persona: string;
  states: string[];
  story: string;
  snapshot: string;
  a11y: string;
};

export type ShowcaseManifest = {
  schema_version: 1;
  themes: ShowcaseTheme[];
  viewports: ShowcaseViewport[];
  scenarios: ShowcaseScenario[];
};

export function loadManifest(filePath = manifestPath): ShowcaseManifest {
  if (!fs.existsSync(filePath)) {
    throw new Error(
      `Missing showcase manifest at ${filePath}. Run \`npm run showcase:manifest\` first.`
    );
  }

  const parsed = JSON.parse(fs.readFileSync(filePath, 'utf8')) as unknown;
  return validateManifest(parsed, filePath);
}

function validateManifest(value: unknown, filePath: string): ShowcaseManifest {
  const manifest = assertRecord(value, filePath);

  assertEqual(manifest.schema_version, 1, 'schema_version');

  const themes = assertStringArray(manifest.themes, 'themes') as ShowcaseTheme[];
  assertExactList(themes, [...allowedThemes], 'themes');

  const viewports = assertArray(manifest.viewports, 'viewports').map((viewport, index) => {
    const expected = expectedViewports[index];
    const actual = assertRecord(viewport, `viewports[${index}]`);

    assertEqual(actual.name, expected.name, `viewports[${index}].name`);
    assertEqual(actual.width, expected.width, `viewports[${index}].width`);
    assertEqual(actual.height, expected.height, `viewports[${index}].height`);

    return actual as ShowcaseViewport;
  });

  assertEqual(viewports.length, expectedViewports.length, 'viewports.length');

  const scenarios = assertArray(manifest.scenarios, 'scenarios').map((scenario, index) => {
    const actual = assertRecord(scenario, `scenarios[${index}]`);
    const id = assertString(actual.id, `scenarios[${index}].id`);

    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
      throw new Error(`scenarios[${index}].id must be a slug-like identifier`);
    }

    const domain = assertString(actual.domain, `scenarios[${index}].domain`);
    const persona = assertString(actual.persona, `scenarios[${index}].persona`);
    const states = assertStringArray(actual.states, `scenarios[${index}].states`);
    const story = assertString(actual.story, `scenarios[${index}].story`);
    const snapshot = assertString(actual.snapshot, `scenarios[${index}].snapshot`);
    const a11y = assertString(actual.a11y, `scenarios[${index}].a11y`);

    assertEqual(story, `obpt-story-${id}`, `scenarios[${index}].story`);
    assertEqual(snapshot, `showcase/${id}`, `scenarios[${index}].snapshot`);
    assertEqual(a11y, `[data-obpt-story="${id}"]`, `scenarios[${index}].a11y`);

    if (states.length === 0) {
      throw new Error(`scenarios[${index}].states must not be empty`);
    }

    return { id, domain, persona, states, story, snapshot, a11y };
  });

  assertEqual(scenarios.length, 9, 'scenarios.length');

  return {
    schema_version: 1,
    themes,
    viewports,
    scenarios
  };
}

function assertRecord(value: unknown, label: string): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${label} must be an object`);
  }

  return value as Record<string, unknown>;
}

function assertArray(value: unknown, label: string): unknown[] {
  if (!Array.isArray(value)) {
    throw new Error(`${label} must be an array`);
  }

  return value;
}

function assertStringArray(value: unknown, label: string): string[] {
  const array = assertArray(value, label);

  for (const [index, item] of array.entries()) {
    assertString(item, `${label}[${index}]`);
  }

  return array as string[];
}

function assertString(value: unknown, label: string): string {
  if (typeof value !== 'string' || value.length === 0) {
    throw new Error(`${label} must be a non-empty string`);
  }

  return value;
}

function assertEqual(actual: unknown, expected: unknown, label: string): void {
  if (actual !== expected) {
    throw new Error(`${label} must be ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

function assertExactList(actual: string[], expected: string[], label: string): void {
  assertEqual(actual.length, expected.length, `${label}.length`);

  for (const [index, expectedValue] of expected.entries()) {
    assertEqual(actual[index], expectedValue, `${label}[${index}]`);
  }
}

export const manifest = loadManifest();
export const themes = manifest.themes;
export const viewports = manifest.viewports;
export const scenarios = manifest.scenarios;
