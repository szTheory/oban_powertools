import { test, type APIRequestContext, type APIResponse, type Page } from '@playwright/test';

const endpoint = '/__phase80_browser_fixtures__';
const credentialEnvironmentVariable = 'PHASE80_BROWSER_FIXTURE_SECRET';
const projects = ['chromium-320', 'chromium-tablet', 'chromium-wide'] as const;
const actors = ['ops', 'restricted'] as const;
const commands = ['hold', 'release', 'status', 'perturb'] as const;
const jobStates = [
  'available',
  'scheduled',
  'executing',
  'retryable',
  'cancelled',
  'discarded',
  'completed'
] as const;
const targets = [
  'eligible',
  'excluded',
  'drifted',
  'expired',
  'consumed',
  'skipped',
  'failed',
  'success'
] as const;
const runPattern = /^[a-z0-9][a-z0-9_-]{0,47}$/;

export type Phase80Project = (typeof projects)[number];
export type Phase80Actor = (typeof actors)[number];
export type Phase80BatchCommand = (typeof commands)[number];
export type Phase80Target = (typeof targets)[number];
export type Phase80JobState = (typeof jobStates)[number];

export type Phase80FixtureState = {
  project: Phase80Project;
  run: string;
  actors: ['ops', 'restricted'];
  batch: { state: 'idle' };
  counts: {
    jobs: 2500;
    workflowEvents: 55;
    incidentEvents: 55;
  };
  jobs: {
    pageSize: 20;
    totalCount: 2500;
    finalPage: 125;
    finalPageCount: 20;
    boundaryQueue: string;
    crossPageIds: [number, number];
    underLimitIds: [number, number, number];
    underLimitCount: 3;
    overLimitCount: 101;
    stateIds: Record<Phase80JobState, number>;
    targets: Record<Phase80Target, number>;
  };
  forensics: {
    workflowId: string;
    workflowStep: string;
    incidentFingerprint: string;
    cronEntry: string;
    limiterResource: string;
    eventWindow: 55;
  };
};

export type Phase80BatchState = {
  command: Phase80BatchCommand;
  state: 'idle' | 'held' | 'released' | 'prepared';
};

export type Phase80Evidence = {
  project: Phase80Project;
  run: string;
  audit: { complete: boolean };
  counts: { jobs: number; auditedEffects: number };
  states: Record<Phase80Target, string>;
};

type FixtureOptions = {
  secret: string;
  project?: string;
  run?: string;
};

const fixtureStates = new Map<Phase80Project, Phase80FixtureState>();

export async function resetPhase80BrowserFixture(
  request: APIRequestContext,
  options: FixtureOptions
): Promise<Phase80FixtureState> {
  const credential = requiredCredential(options.secret);
  const project = projectName(options.project ?? test.info().project.name);
  const run = runName(options.run ?? defaultRunTag());
  const response = await postFixture(request, 'reset', { project, run }, credential);
  const value = await successfulJson(response, 'reset');
  const state = validateFixtureState(value, credential);

  if (state.project !== project || state.run !== run) {
    throw new Error('Phase 80 reset returned a mismatched project or run identity');
  }

  fixtureStates.set(project, state);
  return state;
}

export async function authenticatePhase80Actor(
  page: Page,
  options: { actor: Phase80Actor; secret: string }
): Promise<void> {
  const credential = requiredCredential(options.secret);
  const actor = actorName(options.actor);
  const state = currentState();
  const response = await postFixture(
    page.request,
    'actor',
    { project: state.project, run: state.run, actor },
    credential
  );
  const value = record(await successfulJson(response, 'actor'), 'actor response');

  exactKeys(value, ['actor', 'state'], 'actor response');
  rejectSensitiveKeys(value, 'actor response');
  exactString(value.actor, actor, 'actor response actor');
  exactString(value.state, 'authenticated', 'actor response state');
}

export async function controlPhase80Batch(
  request: APIRequestContext,
  options: { command: Phase80BatchCommand; secret: string; target?: Phase80Target }
): Promise<Phase80BatchState> {
  const credential = requiredCredential(options.secret);
  const command = commandName(options.command);
  const state = currentState();
  const data: Record<string, string> = {
    project: state.project,
    run: state.run,
    command
  };

  if (command === 'perturb') {
    data.target = targetName(options.target);
  } else if (options.target !== undefined) {
    throw new Error('Phase 80 batch target is only allowed for perturb');
  }

  const response = await postFixture(request, 'batch', data, credential);
  const value = record(await successfulJson(response, 'batch'), 'batch response');

  exactKeys(value, ['command', 'state'], 'batch response');
  rejectSensitiveKeys(value, 'batch response');

  const returnedCommand = commandName(nonBlankString(value.command, 'batch response command'));
  const returnedState = oneOf(
    value.state,
    ['idle', 'held', 'released', 'prepared'] as const,
    'batch response state'
  );

  if (command === 'hold' && (returnedCommand !== 'hold' || returnedState !== 'held')) {
    throw new Error('Phase 80 hold response did not match the expected state');
  }
  if (command === 'release' && (returnedCommand !== 'release' || returnedState !== 'released')) {
    throw new Error('Phase 80 release response did not match the expected state');
  }
  if (command === 'perturb' && (returnedCommand !== 'perturb' || returnedState !== 'prepared')) {
    throw new Error('Phase 80 perturb response did not match the expected state');
  }
  if (
    command === 'status' &&
    !(
      (returnedCommand === 'status' && returnedState === 'idle') ||
      (returnedCommand === 'hold' && returnedState === 'held') ||
      (returnedCommand === 'release' && returnedState === 'released')
    )
  ) {
    throw new Error('Phase 80 status response did not match a closed barrier state');
  }

  return { command: returnedCommand, state: returnedState };
}

export async function readPhase80Evidence(
  request: APIRequestContext,
  options: { secret: string }
): Promise<Phase80Evidence> {
  const credential = requiredCredential(options.secret);
  const state = currentState();
  const response = await postFixture(
    request,
    'evidence',
    { project: state.project, run: state.run },
    credential
  );
  const value = record(await successfulJson(response, 'evidence'), 'evidence response');

  exactKeys(value, ['audit', 'counts', 'project', 'run', 'states'], 'evidence response');
  rejectSensitiveKeys(value, 'evidence response');

  const audit = record(value.audit, 'evidence audit');
  const counts = record(value.counts, 'evidence counts');
  const evidenceStates = record(value.states, 'evidence states');

  exactKeys(audit, ['complete'], 'evidence audit');
  exactKeys(counts, ['auditedEffects', 'jobs'], 'evidence counts');
  exactKeys(evidenceStates, [...targets], 'evidence states');

  const project = projectName(nonBlankString(value.project, 'evidence project'));
  const run = runName(nonBlankString(value.run, 'evidence run'));
  if (project !== state.project || run !== state.run) {
    throw new Error('Phase 80 evidence returned a mismatched project or run identity');
  }

  return {
    project,
    run,
    audit: { complete: booleanValue(audit.complete, 'evidence audit completion') },
    counts: {
      jobs: nonNegativeInteger(counts.jobs, 'evidence job count'),
      auditedEffects: nonNegativeInteger(counts.auditedEffects, 'evidence audit count')
    },
    states: mapRecord(
      evidenceStates,
      targets,
      (item, target) => nonBlankString(item, `evidence state ${target}`)
    )
  };
}

function currentState(): Phase80FixtureState {
  const project = projectName(test.info().project.name);
  const state = fixtureStates.get(project);
  if (!state) throw new Error('Phase 80 fixture action requires a successful project reset first');
  return state;
}

function requiredCredential(provided: string): string {
  const configured = process.env[credentialEnvironmentVariable]?.trim() ?? '';

  if (configured.length === 0) {
    throw new Error('Phase 80 fixture credential is unavailable');
  }

  if (provided.trim().length === 0 || provided !== configured) {
    throw new Error('Phase 80 fixture credential does not match the process environment');
  }

  return configured;
}

function projectName(value: string): Phase80Project {
  return oneOf(
    value,
    projects,
    'Phase 80 fixture project is outside the closed Playwright project set'
  );
}

function actorName(value: string): Phase80Actor {
  return oneOf(value, actors, 'Phase 80 actor is outside the closed actor set');
}

function commandName(value: string): Phase80BatchCommand {
  return oneOf(value, commands, 'Phase 80 command is outside the closed command set');
}

function targetName(value: Phase80Target | undefined): Phase80Target {
  if (value === undefined) throw new Error('Phase 80 perturb requires a closed target');
  return oneOf(value, targets, 'Phase 80 perturb target is outside the closed target set');
}

function runName(value: string): string {
  if (!runPattern.test(value)) {
    throw new Error('Phase 80 fixture run must be a closed lowercase run tag');
  }
  return value;
}

function defaultRunTag(): string {
  const info = test.info();
  return `pw-${info.workerIndex}-${info.repeatEachIndex}-${info.retry}`;
}

async function postFixture(
  request: APIRequestContext,
  action: 'reset' | 'actor' | 'batch' | 'evidence',
  data: Record<string, string>,
  credential: string
): Promise<APIResponse> {
  return request.post(`${endpoint}/${action}`, {
    data,
    headers: { 'x-phase80-fixture-secret': credential }
  });
}

async function successfulJson(response: APIResponse, action: string): Promise<unknown> {
  if (!response.ok()) {
    throw new Error(`Phase 80 ${action} request failed with status ${response.status()}`);
  }

  try {
    return (await response.json()) as unknown;
  } catch (_error) {
    throw new Error(`Phase 80 ${action} response was not valid JSON`);
  }
}

function validateFixtureState(value: unknown, credential: string): Phase80FixtureState {
  const state = record(value, 'reset response');
  exactKeys(
    state,
    ['actors', 'batch', 'counts', 'forensics', 'jobs', 'project', 'run'],
    'reset response'
  );
  rejectSensitiveKeys(state, 'reset response');

  const actorValues = stringArray(state.actors, 'reset actors');
  if (actorValues.join(',') !== actors.join(',')) {
    throw new Error('Phase 80 reset actors did not match the closed actor set');
  }

  const batch = record(state.batch, 'reset batch');
  const counts = record(state.counts, 'reset counts');
  const jobs = record(state.jobs, 'reset jobs');
  const forensics = record(state.forensics, 'reset forensics');
  const stateIds = record(jobs.stateIds, 'reset job state IDs');
  const targetIds = record(jobs.targets, 'reset target IDs');

  exactKeys(batch, ['state'], 'reset batch');
  exactKeys(counts, ['incidentEvents', 'jobs', 'workflowEvents'], 'reset counts');
  exactKeys(
    jobs,
    [
      'boundaryQueue',
      'crossPageIds',
      'finalPage',
      'finalPageCount',
      'overLimitCount',
      'pageSize',
      'stateIds',
      'targets',
      'totalCount',
      'underLimitCount',
      'underLimitIds'
    ],
    'reset jobs'
  );
  exactKeys(stateIds, [...jobStates], 'reset job state IDs');
  exactKeys(targetIds, [...targets], 'reset target IDs');
  exactKeys(
    forensics,
    [
      'cronEntry',
      'eventWindow',
      'incidentFingerprint',
      'limiterResource',
      'workflowId',
      'workflowStep'
    ],
    'reset forensics'
  );

  if (JSON.stringify(state).includes(credential)) {
    throw new Error('Phase 80 reset response disclosed the fixture credential');
  }

  return {
    project: projectName(nonBlankString(state.project, 'reset project')),
    run: runName(nonBlankString(state.run, 'reset run')),
    actors: ['ops', 'restricted'],
    batch: { state: exactString(batch.state, 'idle', 'reset batch state') as 'idle' },
    counts: {
      jobs: exactNumber(counts.jobs, 2500, 'reset job count') as 2500,
      workflowEvents: exactNumber(
        counts.workflowEvents,
        55,
        'reset workflow event count'
      ) as 55,
      incidentEvents: exactNumber(
        counts.incidentEvents,
        55,
        'reset incident event count'
      ) as 55
    },
    jobs: {
      pageSize: exactNumber(jobs.pageSize, 20, 'reset page size') as 20,
      totalCount: exactNumber(jobs.totalCount, 2500, 'reset total count') as 2500,
      finalPage: exactNumber(jobs.finalPage, 125, 'reset final page') as 125,
      finalPageCount: exactNumber(jobs.finalPageCount, 20, 'reset final page count') as 20,
      boundaryQueue: nonBlankString(jobs.boundaryQueue, 'reset boundary queue'),
      crossPageIds: numericTuple(jobs.crossPageIds, 2, 'reset cross-page IDs'),
      underLimitIds: numericTuple(jobs.underLimitIds, 3, 'reset under-limit IDs'),
      underLimitCount: exactNumber(jobs.underLimitCount, 3, 'reset under-limit count') as 3,
      overLimitCount: exactNumber(jobs.overLimitCount, 101, 'reset over-limit count') as 101,
      stateIds: mapRecord(stateIds, jobStates, positiveInteger),
      targets: mapRecord(targetIds, targets, positiveInteger)
    },
    forensics: {
      workflowId: nonBlankString(forensics.workflowId, 'reset workflow ID'),
      workflowStep: nonBlankString(forensics.workflowStep, 'reset workflow step'),
      incidentFingerprint: nonBlankString(
        forensics.incidentFingerprint,
        'reset incident fingerprint'
      ),
      cronEntry: nonBlankString(forensics.cronEntry, 'reset cron entry'),
      limiterResource: nonBlankString(forensics.limiterResource, 'reset limiter resource'),
      eventWindow: exactNumber(forensics.eventWindow, 55, 'reset event window') as 55
    }
  };
}

function rejectSensitiveKeys(value: unknown, label: string): void {
  if (Array.isArray(value)) {
    value.forEach((item, index) => rejectSensitiveKeys(item, `${label}[${index}]`));
    return;
  }
  if (!value || typeof value !== 'object') return;

  for (const [key, nested] of Object.entries(value as Record<string, unknown>)) {
    if (/(?:secret|token|hash|reason|metadata|credential|raw.?error)/i.test(key)) {
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

function exactKeys(value: Record<string, unknown>, expected: readonly string[], label: string): void {
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

function positiveInteger(value: unknown, label: string): number {
  if (!Number.isSafeInteger(value) || (value as number) < 1) {
    throw new Error(`${label} must be a positive safe integer`);
  }
  return value as number;
}

function nonNegativeInteger(value: unknown, label: string): number {
  if (!Number.isSafeInteger(value) || (value as number) < 0) {
    throw new Error(`${label} must be a nonnegative safe integer`);
  }
  return value as number;
}

function booleanValue(value: unknown, label: string): boolean {
  if (typeof value !== 'boolean') throw new Error(`${label} must be a boolean`);
  return value;
}

function oneOf<const Values extends readonly string[]>(
  value: unknown,
  allowed: Values,
  label: string
): Values[number] {
  if (typeof value !== 'string' || !allowed.includes(value)) {
    throw new Error(label);
  }
  return value as Values[number];
}

function numericTuple(
  value: unknown,
  length: 2,
  label: string
): [number, number];
function numericTuple(
  value: unknown,
  length: 3,
  label: string
): [number, number, number];
function numericTuple(value: unknown, length: number, label: string): number[] {
  if (!Array.isArray(value) || value.length !== length) {
    throw new Error(`${label} did not match the closed tuple length`);
  }
  const numbers = value.map((item, index) => positiveInteger(item, `${label}[${index}]`));
  if (new Set(numbers).size !== numbers.length) {
    throw new Error(`${label} must contain distinct IDs`);
  }
  return numbers;
}

function mapRecord<const Keys extends readonly string[], Value>(
  value: Record<string, unknown>,
  keys: Keys,
  validate: (item: unknown, label: string) => Value
): Record<Keys[number], Value> {
  return Object.fromEntries(
    keys.map((key) => [key, validate(value[key], key)])
  ) as Record<Keys[number], Value>;
}
