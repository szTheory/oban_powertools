import fs from 'node:fs';
import path from 'node:path';

const manifestPath =
  process.env.SHOWCASE_MANIFEST_PATH ??
  path.join(process.cwd(), 'test/browser/.generated/showcase-manifest.json');
const allowedThemes = ['system', 'light', 'dark', 'high-contrast'] as const;
const allowedPages = [
  'overview',
  'cron',
  'limiters',
  'audit',
  'jobs',
  'forensics',
  'batches',
  'workflows',
  'lifeline'
] as const;
const expectedViewports = [
  { name: '320', width: 320, height: 900 },
  { name: 'tablet', width: 768, height: 1000 },
  { name: 'wide', width: 1440, height: 1000 }
] as const;

export type ShowcaseTheme = (typeof allowedThemes)[number];
export type ViewportName = (typeof expectedViewports)[number]['name'];
export type ShowcasePageName = (typeof allowedPages)[number];

export type ShowcaseRoleState = {
  checked?: boolean;
  disabled?: boolean;
  expanded?: boolean;
  pressed?: boolean;
  selected?: boolean;
};

export type ShowcaseRoleContract = {
  role: string;
  name: string;
  level?: number;
  states: ShowcaseRoleState;
};

export type ShowcaseAcceptance = {
  required_text: string[];
  forbidden_text: string[];
  ordered_text: string[];
  roles: ShowcaseRoleContract[];
};

export type ShowcaseViewport = {
  name: ViewportName;
  width: number;
  height: number;
};

export type ShowcaseCopyContract = {
  canonical_terms: Record<string, { term: string; forbidden: string[] }>;
  confirmation_order: string[];
  exclusions: string[];
  forbidden_phrases: Array<{
    phrase: string;
    replacement: string;
    rule: string;
  }>;
  receipt_verbs: string[];
  source_roots: string[];
  state_requirements: Record<string, string[]>;
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

export type ShowcasePrimitiveStory = {
  id: string;
  kind: 'primitive';
  component: string;
  components: string[];
  name: string;
  description: string;
  variant: string[];
  state: string[];
  story: string;
  snapshot: string;
  a11y: string;
};

export type ShowcaseFormStory = Omit<ShowcasePrimitiveStory, 'kind'> & {
  kind: 'form';
};

export type ShowcaseShellStory = Omit<ShowcasePrimitiveStory, 'kind'> & {
  kind: 'shell';
  nav_state: 'closed' | 'open';
};

export type ShowcaseDataStory = Omit<ShowcasePrimitiveStory, 'kind'> & {
  kind: 'data';
};

export type ShowcaseGroupStory = Omit<ShowcasePrimitiveStory, 'kind'> & {
  kind: 'group';
  activation: 'none' | 'overlay';
};

export type ShowcasePageStory = Omit<ShowcasePrimitiveStory, 'kind'> & {
  kind: 'page';
  page: ShowcasePageName;
  activation: 'none' | 'detail' | 'confirmation';
  acceptance: ShowcaseAcceptance;
};

export type ShowcaseTarget =
  | (ShowcaseScenario & { kind: 'scenario' })
  | ShowcasePrimitiveStory
  | ShowcaseFormStory
  | ShowcaseShellStory
  | ShowcaseDataStory
  | ShowcaseGroupStory
  | ShowcasePageStory;

export type ShowcaseManifest = {
  schema_version: 8;
  themes: ShowcaseTheme[];
  viewports: ShowcaseViewport[];
  copy_contract: ShowcaseCopyContract;
  scenarios: ShowcaseScenario[];
  primitive_stories: ShowcasePrimitiveStory[];
  form_stories: ShowcaseFormStory[];
  shell_stories: ShowcaseShellStory[];
  data_stories: ShowcaseDataStory[];
  group_stories: ShowcaseGroupStory[];
  page_stories: ShowcasePageStory[];
  targets: ShowcaseTarget[];
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

  assertExactRecordFields(
    manifest,
    [
      'schema_version',
      'themes',
      'viewports',
      'copy_contract',
      'scenarios',
      'primitive_stories',
      'form_stories',
      'shell_stories',
      'data_stories',
      'group_stories',
      'page_stories',
      'targets'
    ],
    'manifest'
  );
  assertEqual(manifest.schema_version, 8, 'schema_version');

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
  const copyContract = validateCopyContract(manifest.copy_contract);

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

  const primitiveStories = assertArray(manifest.primitive_stories, 'primitive_stories').map(
    (story, index) => {
      const actual = assertRecord(story, `primitive_stories[${index}]`);
      const id = assertString(actual.id, `primitive_stories[${index}].id`);

      assertEqual(actual.kind, 'primitive', `primitive_stories[${index}].kind`);

      if (!/^primitive-[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
        throw new Error(
          `primitive_stories[${index}].id must be a slug-like primitive-* identifier`
        );
      }

      const component = assertString(actual.component, `primitive_stories[${index}].component`);
      const components = assertStringArray(
        actual.components,
        `primitive_stories[${index}].components`
      );
      const name = assertString(actual.name, `primitive_stories[${index}].name`);
      const description = assertString(
        actual.description,
        `primitive_stories[${index}].description`
      );
      const variant = assertStringArray(actual.variant, `primitive_stories[${index}].variant`);
      const state = assertStringArray(actual.state, `primitive_stories[${index}].state`);
      const storyTarget = assertString(actual.story, `primitive_stories[${index}].story`);
      const snapshot = assertString(actual.snapshot, `primitive_stories[${index}].snapshot`);
      const a11y = assertString(actual.a11y, `primitive_stories[${index}].a11y`);

      assertEqual(storyTarget, `obpt-primitive-story-${id}`, `primitive_stories[${index}].story`);
      assertEqual(snapshot, `showcase/${id}`, `primitive_stories[${index}].snapshot`);
      assertEqual(a11y, `[data-obpt-primitive-story="${id}"]`, `primitive_stories[${index}].a11y`);

      if (components.length === 0) {
        throw new Error(`primitive_stories[${index}].components must not be empty`);
      }

      if (variant.length === 0) {
        throw new Error(`primitive_stories[${index}].variant must not be empty`);
      }

      if (state.length === 0) {
        throw new Error(`primitive_stories[${index}].state must not be empty`);
      }

      return {
        id,
        kind: 'primitive' as const,
        component,
        components,
        name,
        description,
        variant,
        state,
        story: storyTarget,
        snapshot,
        a11y
      };
    }
  );

  assertEqual(primitiveStories.length, 7, 'primitive_stories.length');

  const formStories = assertArray(manifest.form_stories, 'form_stories').map(
    (story, index) =>
      validateComponentStory(story, index, 'form_stories', 'form') as ShowcaseFormStory
  );

  assertEqual(formStories.length, 9, 'form_stories.length');

  const shellStories = assertArray(manifest.shell_stories, 'shell_stories').map(
    (story, index) =>
      validateComponentStory(story, index, 'shell_stories', 'shell') as ShowcaseShellStory
  );

  assertEqual(shellStories.length, 6, 'shell_stories.length');

  const dataStories = assertArray(manifest.data_stories, 'data_stories').map(
    (story, index) =>
      validateComponentStory(story, index, 'data_stories', 'data') as ShowcaseDataStory
  );

  assertEqual(dataStories.length, 10, 'data_stories.length');

  const groupStories = assertArray(manifest.group_stories, 'group_stories').map(
    (story, index) =>
      validateComponentStory(story, index, 'group_stories', 'group') as ShowcaseGroupStory
  );

  assertEqual(groupStories.length, 23, 'group_stories.length');
  assertUniqueList(
    groupStories.map((story) => story.id),
    'group_stories ids'
  );

  const pageStories = assertArray(manifest.page_stories, 'page_stories').map((story, index) =>
    validatePageStory(story, index, 'page_stories')
  );

  assertEqual(pageStories.length, 99, 'page_stories.length');
  assertUniqueList(
    pageStories.map((story) => story.id),
    'page_stories ids'
  );
  assertExactList(
    [...new Set(pageStories.map((story) => story.page))],
    [...allowedPages],
    'page_stories families'
  );

  const targets = assertArray(manifest.targets, 'targets').map((target, index) =>
    validateTarget(target, index)
  );
  const expectedTargets: ShowcaseTarget[] = [
    ...scenarios.map((scenario) => ({
      kind: 'scenario' as const,
      ...scenario
    })),
    ...primitiveStories,
    ...formStories,
    ...shellStories,
    ...dataStories,
    ...groupStories,
    ...pageStories
  ];

  assertPageTargetOrder(targets, pageStories, 64);
  assertEqual(expectedTargets.length, 163, 'expected targets.length');
  assertEqual(targets.length, expectedTargets.length, 'targets.length');

  for (const [index, expectedTarget] of expectedTargets.entries()) {
    const actualTarget = targets[index];

    assertEqual(actualTarget.kind, expectedTarget.kind, `targets[${index}].kind`);
    assertEqual(actualTarget.id, expectedTarget.id, `targets[${index}].id`);
    assertEqual(actualTarget.story, expectedTarget.story, `targets[${index}].story`);
    assertEqual(actualTarget.snapshot, expectedTarget.snapshot, `targets[${index}].snapshot`);
    assertEqual(actualTarget.a11y, expectedTarget.a11y, `targets[${index}].a11y`);

    if (actualTarget.kind === 'scenario' && expectedTarget.kind === 'scenario') {
      assertEqual(actualTarget.domain, expectedTarget.domain, `targets[${index}].domain`);
      assertEqual(actualTarget.persona, expectedTarget.persona, `targets[${index}].persona`);
      assertExactList(actualTarget.states, expectedTarget.states, `targets[${index}].states`);
    }

    if (
      (actualTarget.kind === 'primitive' ||
        actualTarget.kind === 'form' ||
        actualTarget.kind === 'shell' ||
        actualTarget.kind === 'data' ||
        actualTarget.kind === 'group') &&
      actualTarget.kind === expectedTarget.kind
    ) {
      assertEqual(actualTarget.component, expectedTarget.component, `targets[${index}].component`);
      assertExactList(
        actualTarget.components,
        expectedTarget.components,
        `targets[${index}].components`
      );
      assertEqual(actualTarget.name, expectedTarget.name, `targets[${index}].name`);
      assertEqual(
        actualTarget.description,
        expectedTarget.description,
        `targets[${index}].description`
      );
      assertExactList(actualTarget.variant, expectedTarget.variant, `targets[${index}].variant`);
      assertExactList(actualTarget.state, expectedTarget.state, `targets[${index}].state`);

      if (actualTarget.kind === 'shell' && expectedTarget.kind === 'shell') {
        assertEqual(
          actualTarget.nav_state,
          expectedTarget.nav_state,
          `targets[${index}].nav_state`
        );
      }

      if (actualTarget.kind === 'group' && expectedTarget.kind === 'group') {
        assertEqual(
          actualTarget.activation,
          expectedTarget.activation,
          `targets[${index}].activation`
        );
      }
    }

    if (actualTarget.kind === 'page' && expectedTarget.kind === 'page') {
      assertEqual(actualTarget.component, expectedTarget.component, `targets[${index}].component`);
      assertExactList(
        actualTarget.components,
        expectedTarget.components,
        `targets[${index}].components`
      );
      assertEqual(actualTarget.name, expectedTarget.name, `targets[${index}].name`);
      assertEqual(
        actualTarget.description,
        expectedTarget.description,
        `targets[${index}].description`
      );
      assertExactList(actualTarget.variant, expectedTarget.variant, `targets[${index}].variant`);
      assertExactList(actualTarget.state, expectedTarget.state, `targets[${index}].state`);
      assertEqual(actualTarget.page, expectedTarget.page, `targets[${index}].page`);
      assertEqual(
        actualTarget.activation,
        expectedTarget.activation,
        `targets[${index}].activation`
      );
      assertEqual(
        JSON.stringify(actualTarget.acceptance),
        JSON.stringify(expectedTarget.acceptance),
        `targets[${index}].acceptance`
      );
    }
  }

  return {
    schema_version: 8,
    themes,
    viewports,
    copy_contract: copyContract,
    scenarios,
    primitive_stories: primitiveStories,
    form_stories: formStories,
    shell_stories: shellStories,
    data_stories: dataStories,
    group_stories: groupStories,
    page_stories: pageStories,
    targets
  };
}

function validateCopyContract(value: unknown): ShowcaseCopyContract {
  const contract = assertRecord(value, 'copy_contract');
  assertExactRecordFields(
    contract,
    [
      'canonical_terms',
      'confirmation_order',
      'exclusions',
      'forbidden_phrases',
      'receipt_verbs',
      'source_roots',
      'state_requirements'
    ],
    'copy_contract'
  );

  const canonicalTermsRecord = assertRecord(
    contract.canonical_terms,
    'copy_contract.canonical_terms'
  );
  const canonicalTerms: ShowcaseCopyContract['canonical_terms'] = {};
  const terms: string[] = [];

  for (const [concept, value] of Object.entries(canonicalTermsRecord)) {
    if (!/^[a-z][a-z0-9_]*$/.test(concept)) {
      throw new Error(`copy_contract.canonical_terms.${concept} must use a finite identifier`);
    }

    const entry = assertRecord(value, `copy_contract.canonical_terms.${concept}`);
    assertExactRecordFields(
      entry,
      ['term', 'forbidden'],
      `copy_contract.canonical_terms.${concept}`
    );
    const term = assertString(entry.term, `copy_contract.canonical_terms.${concept}.term`);
    const forbidden = assertStringArray(
      entry.forbidden,
      `copy_contract.canonical_terms.${concept}.forbidden`
    );

    if (forbidden.length === 0 || forbidden.includes(term)) {
      throw new Error(
        `copy_contract.canonical_terms.${concept}.forbidden must be non-empty and exclude its canonical term`
      );
    }

    assertUniqueList(forbidden, `copy_contract.canonical_terms.${concept}.forbidden`);
    terms.push(term);
    canonicalTerms[concept] = { term, forbidden };
  }

  if (terms.length === 0) {
    throw new Error('copy_contract.canonical_terms must not be empty');
  }
  assertUniqueList(terms, 'copy_contract canonical terms');

  const confirmationOrder = assertStringArray(
    contract.confirmation_order,
    'copy_contract.confirmation_order'
  );
  const exclusions = assertStringArray(contract.exclusions, 'copy_contract.exclusions');
  const receiptVerbs = assertStringArray(contract.receipt_verbs, 'copy_contract.receipt_verbs');
  const sourceRoots = assertStringArray(contract.source_roots, 'copy_contract.source_roots');
  for (const [label, values] of [
    ['copy_contract.confirmation_order', confirmationOrder],
    ['copy_contract.exclusions', exclusions],
    ['copy_contract.receipt_verbs', receiptVerbs],
    ['copy_contract.source_roots', sourceRoots]
  ] as const) {
    if (values.length === 0) throw new Error(`${label} must not be empty`);
    assertUniqueList(values, label);
  }
  assertExactList(sourceRoots, [...sourceRoots].sort(), 'copy_contract.source_roots order');

  const forbiddenPhrases = assertArray(
    contract.forbidden_phrases,
    'copy_contract.forbidden_phrases'
  ).map((value, index) => {
    const entry = assertRecord(value, `copy_contract.forbidden_phrases[${index}]`);
    assertExactRecordFields(
      entry,
      ['phrase', 'replacement', 'rule'],
      `copy_contract.forbidden_phrases[${index}]`
    );
    return {
      phrase: assertString(entry.phrase, `copy_contract.forbidden_phrases[${index}].phrase`),
      replacement: assertString(
        entry.replacement,
        `copy_contract.forbidden_phrases[${index}].replacement`
      ),
      rule: assertString(entry.rule, `copy_contract.forbidden_phrases[${index}].rule`)
    };
  });
  if (forbiddenPhrases.length === 0) {
    throw new Error('copy_contract.forbidden_phrases must not be empty');
  }
  assertUniqueList(
    forbiddenPhrases.map(({ phrase }) => phrase),
    'copy_contract forbidden phrases'
  );

  const stateRequirementsRecord = assertRecord(
    contract.state_requirements,
    'copy_contract.state_requirements'
  );
  const stateRequirements: Record<string, string[]> = {};
  for (const [state, value] of Object.entries(stateRequirementsRecord)) {
    const requirements = assertStringArray(value, `copy_contract.state_requirements.${state}`);
    if (!/^[a-z][a-z0-9_]*$/.test(state) || requirements.length === 0) {
      throw new Error(`copy_contract.state_requirements.${state} must be finite and non-empty`);
    }
    assertUniqueList(requirements, `copy_contract.state_requirements.${state}`);
    stateRequirements[state] = requirements;
  }
  if (Object.keys(stateRequirements).length === 0) {
    throw new Error('copy_contract.state_requirements must not be empty');
  }

  const serialized = JSON.stringify(contract);
  if (/obpt-(?:page-)?story-|page-[a-z0-9]+-/.test(serialized)) {
    throw new Error('copy_contract must not contain showcase target or story ids');
  }

  return {
    canonical_terms: canonicalTerms,
    confirmation_order: confirmationOrder,
    exclusions,
    forbidden_phrases: forbiddenPhrases,
    receipt_verbs: receiptVerbs,
    source_roots: sourceRoots,
    state_requirements: stateRequirements
  };
}

function validateTarget(value: unknown, index: number): ShowcaseTarget {
  const actual = assertRecord(value, `targets[${index}]`);
  const kind = assertString(actual.kind, `targets[${index}].kind`);
  const id = assertString(actual.id, `targets[${index}].id`);
  const story = assertString(actual.story, `targets[${index}].story`);
  const snapshot = assertString(actual.snapshot, `targets[${index}].snapshot`);
  const a11y = assertString(actual.a11y, `targets[${index}].a11y`);

  if (kind === 'scenario') {
    const domain = assertString(actual.domain, `targets[${index}].domain`);
    const persona = assertString(actual.persona, `targets[${index}].persona`);
    const states = assertStringArray(actual.states, `targets[${index}].states`);

    return { kind, id, domain, persona, states, story, snapshot, a11y };
  }

  if (kind === 'page') {
    return validatePageStory(value, index, 'targets');
  }

  if (
    kind === 'primitive' ||
    kind === 'form' ||
    kind === 'shell' ||
    kind === 'data' ||
    kind === 'group'
  ) {
    const component = assertString(actual.component, `targets[${index}].component`);
    const components = assertStringArray(actual.components, `targets[${index}].components`);
    const name = assertString(actual.name, `targets[${index}].name`);
    const description = assertString(actual.description, `targets[${index}].description`);
    const variant = assertStringArray(actual.variant, `targets[${index}].variant`);
    const state = assertStringArray(actual.state, `targets[${index}].state`);
    const target = {
      kind,
      id,
      component,
      components,
      name,
      description,
      variant,
      state,
      story,
      snapshot,
      a11y
    };

    if (kind === 'shell') {
      return {
        ...target,
        nav_state: assertNavState(actual.nav_state, `targets[${index}].nav_state`)
      };
    }

    if (kind === 'group') {
      return {
        ...target,
        activation: assertActivation(actual.activation, `targets[${index}].activation`)
      };
    }

    return target;
  }

  throw new Error(
    `targets[${index}].kind must be "scenario", "primitive", "form", "shell", "data", "group", or "page"`
  );
}

function validatePageStory(
  value: unknown,
  index: number,
  collection: 'page_stories' | 'targets'
): ShowcasePageStory {
  const label = `${collection}[${index}]`;
  const actual = assertRecord(value, label);

  assertExactRecordFields(
    actual,
    [
      'id',
      'kind',
      'page',
      'component',
      'components',
      'name',
      'description',
      'variant',
      'state',
      'activation',
      'acceptance',
      'story',
      'snapshot',
      'a11y'
    ],
    label
  );

  const id = assertString(actual.id, `${label}.id`);
  assertEqual(actual.kind, 'page', `${label}.kind`);

  if (!/^page-[a-z0-9]+(?:-[a-z0-9]+)*$/.test(id)) {
    throw new Error(`${label}.id must be a slug-like page-* identifier`);
  }

  const page = assertPageName(actual.page, `${label}.page`);
  assertEqual(id.startsWith(`page-${page}-`), true, `${label}.id page prefix`);
  const component = assertString(actual.component, `${label}.component`);
  const components = assertStringArray(actual.components, `${label}.components`);
  const name = assertString(actual.name, `${label}.name`);
  const description = assertString(actual.description, `${label}.description`);
  const variant = assertStringArray(actual.variant, `${label}.variant`);
  const state = assertStringArray(actual.state, `${label}.state`);
  const activation = assertPageActivation(actual.activation, `${label}.activation`);
  const acceptance = validateAcceptance(actual.acceptance, `${label}.acceptance`);
  const story = assertString(actual.story, `${label}.story`);
  const snapshot = assertString(actual.snapshot, `${label}.snapshot`);
  const a11y = assertString(actual.a11y, `${label}.a11y`);

  if (components.length === 0 || variant.length === 0 || state.length === 0) {
    throw new Error(`${label} components, variant, and state must not be empty`);
  }

  assertEqual(component, components[0], `${label}.component`);
  assertEqual(story, `obpt-page-story-${id}`, `${label}.story`);
  assertEqual(snapshot, `showcase/${id}`, `${label}.snapshot`);
  assertEqual(a11y, `[data-obpt-page-story="${id}"]`, `${label}.a11y`);

  return {
    id,
    kind: 'page',
    page,
    component,
    components,
    name,
    description,
    variant,
    state,
    activation,
    acceptance,
    story,
    snapshot,
    a11y
  };
}

function validateAcceptance(value: unknown, label: string): ShowcaseAcceptance {
  const actual = assertRecord(value, label);

  assertExactRecordFields(
    actual,
    ['required_text', 'forbidden_text', 'ordered_text', 'roles'],
    label
  );

  const requiredText = assertStringArray(actual.required_text, `${label}.required_text`);
  const forbiddenText = assertStringArray(actual.forbidden_text, `${label}.forbidden_text`);
  const orderedText = assertStringArray(actual.ordered_text, `${label}.ordered_text`);
  const roles = assertArray(actual.roles, `${label}.roles`).map((role, index) =>
    validateRoleContract(role, `${label}.roles[${index}]`)
  );

  if (
    requiredText.length === 0 ||
    forbiddenText.length === 0 ||
    orderedText.length === 0 ||
    roles.length === 0
  ) {
    throw new Error(`${label} text and role contracts must not be empty`);
  }

  return {
    required_text: requiredText,
    forbidden_text: forbiddenText,
    ordered_text: orderedText,
    roles
  };
}

function validateRoleContract(value: unknown, label: string): ShowcaseRoleContract {
  const actual = assertRecord(value, label);
  const expectedFields =
    actual.level === undefined ? ['role', 'name', 'states'] : ['role', 'name', 'level', 'states'];

  assertExactRecordFields(actual, expectedFields, label);

  const role = assertString(actual.role, `${label}.role`);
  const name = assertString(actual.name, `${label}.name`);
  const states = assertRecord(actual.states, `${label}.states`);
  const allowedStateFields = ['checked', 'disabled', 'expanded', 'pressed', 'selected'];

  for (const [state, enabled] of Object.entries(states)) {
    if (!allowedStateFields.includes(state) || typeof enabled !== 'boolean') {
      throw new Error(`${label}.states.${state} must be a supported boolean role state`);
    }
  }

  if (actual.level === undefined) {
    return { role, name, states: states as ShowcaseRoleState };
  }

  if (
    !Number.isInteger(actual.level) ||
    (actual.level as number) < 1 ||
    (actual.level as number) > 6
  ) {
    throw new Error(`${label}.level must be an integer from 1 through 6`);
  }

  return {
    role,
    name,
    level: actual.level as number,
    states: states as ShowcaseRoleState
  };
}

function validateComponentStory(
  value: unknown,
  index: number,
  collection:
    'primitive_stories' | 'form_stories' | 'shell_stories' | 'data_stories' | 'group_stories',
  kind: 'primitive' | 'form' | 'shell' | 'data' | 'group'
):
  | ShowcasePrimitiveStory
  | ShowcaseFormStory
  | ShowcaseShellStory
  | ShowcaseDataStory
  | ShowcaseGroupStory {
  const actual = assertRecord(value, `${collection}[${index}]`);
  const id = assertString(actual.id, `${collection}[${index}].id`);
  const prefix = kind;

  assertEqual(actual.kind, kind, `${collection}[${index}].kind`);
  if (!new RegExp(`^${prefix}-[a-z0-9]+(?:-[a-z0-9]+)*$`).test(id)) {
    throw new Error(`${collection}[${index}].id must be a slug-like ${prefix}-* identifier`);
  }

  const component = assertString(actual.component, `${collection}[${index}].component`);
  const components = assertStringArray(actual.components, `${collection}[${index}].components`);
  const name = assertString(actual.name, `${collection}[${index}].name`);
  const description = assertString(actual.description, `${collection}[${index}].description`);
  const variant = assertStringArray(actual.variant, `${collection}[${index}].variant`);
  const state = assertStringArray(actual.state, `${collection}[${index}].state`);
  const story = assertString(actual.story, `${collection}[${index}].story`);
  const snapshot = assertString(actual.snapshot, `${collection}[${index}].snapshot`);
  const a11y = assertString(actual.a11y, `${collection}[${index}].a11y`);

  assertEqual(story, `obpt-${prefix}-story-${id}`, `${collection}[${index}].story`);
  assertEqual(snapshot, `showcase/${id}`, `${collection}[${index}].snapshot`);
  assertEqual(a11y, `[data-obpt-${prefix}-story="${id}"]`, `${collection}[${index}].a11y`);

  if (components.length === 0 || variant.length === 0 || state.length === 0) {
    throw new Error(`${collection}[${index}] components, variant, and state must not be empty`);
  }

  const result = {
    id,
    kind,
    component,
    components,
    name,
    description,
    variant,
    state,
    story,
    snapshot,
    a11y
  };

  if (kind === 'shell') {
    return {
      ...result,
      nav_state: assertNavState(actual.nav_state, `${collection}[${index}].nav_state`)
    };
  }

  if (kind === 'group') {
    return {
      ...result,
      activation: assertActivation(actual.activation, `${collection}[${index}].activation`)
    };
  }

  return result;
}

function assertActivation(value: unknown, label: string): 'none' | 'overlay' {
  const activation = assertString(value, label);

  if (activation !== 'none' && activation !== 'overlay') {
    throw new Error(`${label} must be "none" or "overlay"`);
  }

  return activation;
}

function assertPageActivation(value: unknown, label: string): 'none' | 'detail' | 'confirmation' {
  const activation = assertString(value, label);

  if (activation !== 'none' && activation !== 'detail' && activation !== 'confirmation') {
    throw new Error(`${label} must be "none", "detail", or "confirmation"`);
  }

  return activation;
}

function assertPageName(value: unknown, label: string): ShowcasePageName {
  const page = assertString(value, label);

  if (!allowedPages.includes(page as ShowcasePageName)) {
    throw new Error(`${label} must be one of ${JSON.stringify(allowedPages)}`);
  }

  return page as ShowcasePageName;
}

function assertNavState(value: unknown, label: string): 'closed' | 'open' {
  const navState = assertString(value, label);

  if (navState !== 'closed' && navState !== 'open') {
    throw new Error(`${label} must be "closed" or "open"`);
  }

  return navState;
}

function assertRecord(value: unknown, label: string): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${label} must be an object`);
  }

  return value as Record<string, unknown>;
}

function assertExactRecordFields(
  value: Record<string, unknown>,
  expectedFields: string[],
  label: string
): void {
  const actualFields = Object.keys(value);
  const missing = expectedFields.filter((field) => !actualFields.includes(field));
  const unknown = actualFields.filter((field) => !expectedFields.includes(field));

  if (missing.length > 0 || unknown.length > 0) {
    throw new Error(
      `${label} fields must match the schema; missing=${JSON.stringify(missing)}, unknown=${JSON.stringify(unknown)}`
    );
  }
}

function assertPageTargetOrder(
  actualTargets: ShowcaseTarget[],
  expectedPageStories: ShowcasePageStory[],
  firstPageIndex: number
): void {
  const actualPageTargets = actualTargets.filter(
    (target): target is ShowcasePageStory => target.kind === 'page'
  );
  const actualIds = actualPageTargets.map((target) => target.id);
  const expectedIds = expectedPageStories.map((story) => story.id);
  const missing = expectedIds.filter((id) => !actualIds.includes(id));
  const extra = actualIds.filter((id) => !expectedIds.includes(id));

  if (missing.length > 0 || extra.length > 0) {
    throw new Error(
      `targets page ids differ; missing=${JSON.stringify(missing)}, extra=${JSON.stringify(extra)}`
    );
  }

  assertEqual(actualIds.length, expectedIds.length, 'targets page count');

  for (const [index, expectedId] of expectedIds.entries()) {
    assertEqual(
      actualTargets[firstPageIndex + index]?.id,
      expectedId,
      `targets page order[${index}]`
    );
  }
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

function assertUniqueList(actual: string[], label: string): void {
  assertEqual(new Set(actual).size, actual.length, `${label} unique length`);
}

export const manifest = loadManifest();
export const themes = manifest.themes;
export const viewports = manifest.viewports;
export const scenarios = manifest.scenarios;
export const primitiveStories = manifest.primitive_stories;
export const formStories = manifest.form_stories;
export const shellStories = manifest.shell_stories;
export const dataStories = manifest.data_stories;
export const groupStories = manifest.group_stories;
export const pageStories = manifest.page_stories;
export const targets = manifest.targets;
