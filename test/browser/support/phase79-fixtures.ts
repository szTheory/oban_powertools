import { test, type APIRequestContext, type APIResponse, type Page } from '@playwright/test';

const endpoint = '/__phase79_browser_fixtures__';
const credentialEnvironmentVariable = 'PHASE79_BROWSER_FIXTURE_SECRET';
const projects = ['chromium-320', 'chromium-tablet', 'chromium-wide'] as const;
const actors = ['operator', 'read_only'] as const;
const recoveries = ['expired', 'drifted', 'consumed', 'skipped'] as const;
const runPattern = /^[a-z0-9][a-z0-9_-]{0,47}$/;

export type Phase79Project = (typeof projects)[number];
export type Phase79Actor = (typeof actors)[number] | 'ops';
export type Phase79Recovery = (typeof recoveries)[number];

export type Phase79FixtureState = {
  project: Phase79Project;
  run: string;
  cron: {
    firstEntry: string;
    secondEntry: string;
    pausedEntry: string;
    recoveryEntry: string;
  };
  limiters: {
    firstResource: string;
    secondResource: string;
    blockedResource: string;
  };
  audit: {
    firstEvent: string;
    secondEvent: string;
    boundaryPage: number;
  };
  counts: {
    cronEntries: number;
    limiterResources: number;
    auditFiltered: number;
    auditNewerUnrelated: number;
    overviewActive: number;
    overviewResolved: number;
  };
  actors: ['operator', 'read_only'];
  confidentialitySentinels: [string, string];
};

type FixtureOptions = {
  secret: string;
  project?: string;
  run?: string;
};

const fixtureStates = new Map<Phase79Project, Phase79FixtureState>();

export async function resetPhase79BrowserFixture(
  request: APIRequestContext,
  options: FixtureOptions
): Promise<Phase79FixtureState> {
  const credential = requiredCredential(options.secret);
  const project = projectName(options.project ?? test.info().project.name);
  const run = runName(options.run ?? defaultRunTag());
  const response = await postFixture(request, 'reset', { project, run }, credential);
  const value = await successfulJson(response, 'reset');
  const state = validateFixtureState(value, credential);

  if (state.project !== project || state.run !== run) {
    throw new Error('Phase 79 reset returned a mismatched project or run identity');
  }

  fixtureStates.set(project, state);
  return state;
}

export async function authenticatePhase79Actor(
  page: Page,
  options: { actor: Phase79Actor; secret: string }
): Promise<void> {
  const credential = requiredCredential(options.secret);
  const project = projectName(test.info().project.name);
  const state = fixtureStates.get(project);

  if (!state) {
    throw new Error('Phase 79 actor authentication requires a successful project reset first');
  }

  const actor = options.actor === 'ops' ? 'operator' : options.actor;
  if (!actors.includes(actor)) throw new Error('Phase 79 actor is outside the closed actor set');

  const response = await postFixture(
    page.request,
    'actor',
    { project: state.project, run: state.run, actor },
    credential
  );
  const value = record(await successfulJson(response, 'actor'), 'actor response');

  exactKeys(value, ['actor', 'state'], 'actor response');
  exactString(value.actor, actor, 'actor response actor');
  exactString(value.state, 'authenticated', 'actor response state');
}

export async function setPhase79CronRecovery(
  request: APIRequestContext,
  options: { entry: string; recovery: Phase79Recovery; secret: string }
): Promise<void> {
  const credential = requiredCredential(options.secret);
  const entry = nonBlankString(options.entry, 'recovery entry');

  if (!recoveries.includes(options.recovery)) {
    throw new Error('Phase 79 recovery is outside the closed recovery set');
  }

  const response = await postFixture(
    request,
    'recovery',
    { entry, recovery: options.recovery },
    credential
  );
  const value = record(await successfulJson(response, 'recovery'), 'recovery response');

  exactKeys(value, ['recovery', 'state'], 'recovery response');
  exactString(value.recovery, options.recovery, 'recovery response recovery');
  exactString(value.state, 'prepared', 'recovery response state');
}

function requiredCredential(provided: string): string {
  const configured = process.env[credentialEnvironmentVariable]?.trim() ?? '';

  if (configured.length === 0) {
    throw new Error('Phase 79 fixture credential is unavailable');
  }

  if (provided.trim().length === 0 || provided !== configured) {
    throw new Error('Phase 79 fixture credential does not match the process environment');
  }

  return configured;
}

function projectName(value: string): Phase79Project {
  if (!projects.includes(value as Phase79Project)) {
    throw new Error('Phase 79 fixture project is outside the closed Playwright project set');
  }

  return value as Phase79Project;
}

function runName(value: string): string {
  if (!runPattern.test(value)) {
    throw new Error('Phase 79 fixture run must be a closed lowercase run tag');
  }

  return value;
}

function defaultRunTag(): string {
  const info = test.info();
  return `pw-${info.workerIndex}-${info.repeatEachIndex}-${info.retry}`;
}

async function postFixture(
  request: APIRequestContext,
  action: 'reset' | 'actor' | 'recovery',
  data: Record<string, string>,
  credential: string
): Promise<APIResponse> {
  return request.post(`${endpoint}/${action}`, {
    data,
    headers: { 'x-phase79-fixture-secret': credential }
  });
}

async function successfulJson(response: APIResponse, action: string): Promise<unknown> {
  if (!response.ok()) {
    throw new Error(`Phase 79 ${action} request failed with status ${response.status()}`);
  }

  try {
    return (await response.json()) as unknown;
  } catch (_error) {
    throw new Error(`Phase 79 ${action} response was not valid JSON`);
  }
}

function validateFixtureState(value: unknown, credential: string): Phase79FixtureState {
  const state = record(value, 'reset response');
  exactKeys(
    state,
    [
      'actors',
      'audit',
      'confidentialitySentinels',
      'counts',
      'cron',
      'limiters',
      'project',
      'run'
    ],
    'reset response'
  );
  rejectSensitiveKeys(state, 'reset response');

  const project = projectName(nonBlankString(state.project, 'reset project'));
  const run = runName(nonBlankString(state.run, 'reset run'));
  const cron = record(state.cron, 'reset cron');
  const limiters = record(state.limiters, 'reset limiters');
  const audit = record(state.audit, 'reset audit');
  const counts = record(state.counts, 'reset counts');

  exactKeys(cron, ['firstEntry', 'pausedEntry', 'recoveryEntry', 'secondEntry'], 'reset cron');
  exactKeys(
    limiters,
    ['blockedResource', 'firstResource', 'secondResource'],
    'reset limiters'
  );
  exactKeys(audit, ['boundaryPage', 'firstEvent', 'secondEvent'], 'reset audit');
  exactKeys(
    counts,
    [
      'auditFiltered',
      'auditNewerUnrelated',
      'cronEntries',
      'limiterResources',
      'overviewActive',
      'overviewResolved'
    ],
    'reset counts'
  );

  const actorValues = stringArray(state.actors, 'reset actors');
  if (actorValues.join(',') !== actors.join(',')) {
    throw new Error('Phase 79 reset actors did not match the closed actor set');
  }

  const sentinels = stringArray(state.confidentialitySentinels, 'reset sentinels');
  if (sentinels.length !== 2 || new Set(sentinels).size !== 2) {
    throw new Error('Phase 79 reset must return exactly two distinct confidentiality sentinels');
  }

  if (JSON.stringify(state).includes(credential)) {
    throw new Error('Phase 79 reset response disclosed the fixture credential');
  }

  const firstEvent = numericString(audit.firstEvent, 'reset first event');
  const secondEvent = numericString(audit.secondEvent, 'reset second event');
  if (firstEvent === secondEvent) throw new Error('Phase 79 reset event identities must differ');

  return {
    project,
    run,
    cron: {
      firstEntry: nonBlankString(cron.firstEntry, 'reset first cron entry'),
      secondEntry: nonBlankString(cron.secondEntry, 'reset second cron entry'),
      pausedEntry: nonBlankString(cron.pausedEntry, 'reset paused cron entry'),
      recoveryEntry: nonBlankString(cron.recoveryEntry, 'reset recovery cron entry')
    },
    limiters: {
      firstResource: nonBlankString(limiters.firstResource, 'reset first limiter'),
      secondResource: nonBlankString(limiters.secondResource, 'reset second limiter'),
      blockedResource: nonBlankString(limiters.blockedResource, 'reset blocked limiter')
    },
    audit: {
      firstEvent,
      secondEvent,
      boundaryPage: exactNumber(audit.boundaryPage, 3, 'reset boundary page')
    },
    counts: {
      cronEntries: exactNumber(counts.cronEntries, 3, 'reset cron count'),
      limiterResources: exactNumber(counts.limiterResources, 2, 'reset limiter count'),
      auditFiltered: exactNumber(counts.auditFiltered, 45, 'reset filtered audit count'),
      auditNewerUnrelated: exactNumber(
        counts.auditNewerUnrelated,
        21,
        'reset unrelated audit count'
      ),
      overviewActive: exactNumber(counts.overviewActive, 1, 'reset active overview count'),
      overviewResolved: exactNumber(
        counts.overviewResolved,
        1,
        'reset resolved overview count'
      )
    },
    actors: ['operator', 'read_only'],
    confidentialitySentinels: [sentinels[0], sentinels[1]]
  };
}

function rejectSensitiveKeys(value: unknown, label: string): void {
  if (Array.isArray(value)) {
    value.forEach((item, index) => rejectSensitiveKeys(item, `${label}[${index}]`));
    return;
  }

  if (!value || typeof value !== 'object') return;

  for (const [key, nested] of Object.entries(value as Record<string, unknown>)) {
    if (/(?:secret|token|hash|metadata|credential|raw.?error)/i.test(key)) {
      throw new Error(`${label} contained a prohibited response field`);
    }
    rejectSensitiveKeys(nested, `${label}.${key}`);
  }
}

function record(value: unknown, label: string): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${label} must be an object`);
  }
  return value as Record<string, unknown>;
}

function exactKeys(value: Record<string, unknown>, expected: string[], label: string): void {
  const actual = Object.keys(value).sort();
  const wanted = [...expected].sort();
  if (actual.join(',') !== wanted.join(',')) {
    throw new Error(`${label} did not match the closed public schema`);
  }
}

function nonBlankString(value: unknown, label: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`${label} must be a nonblank string`);
  }
  return value;
}

function numericString(value: unknown, label: string): string {
  const text = nonBlankString(value, label);
  if (!/^[1-9][0-9]*$/.test(text)) throw new Error(`${label} must be a positive integer string`);
  return text;
}

function stringArray(value: unknown, label: string): string[] {
  if (!Array.isArray(value)) throw new Error(`${label} must be an array`);
  return value.map((item, index) => nonBlankString(item, `${label}[${index}]`));
}

function exactString(value: unknown, expected: string, label: string): string {
  const text = nonBlankString(value, label);
  if (text !== expected) throw new Error(`${label} did not match the expected state`);
  return text;
}

function exactNumber(value: unknown, expected: number, label: string): number {
  if (value !== expected) throw new Error(`${label} did not match the expected count`);
  return expected;
}
