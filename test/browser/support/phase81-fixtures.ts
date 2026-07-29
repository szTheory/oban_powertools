import {
  test,
  type APIRequestContext,
  type APIResponse,
  type Page,
} from "@playwright/test";

const endpoint = "/__phase81_browser_fixtures__";
const credentialVariable = "PHASE81_BROWSER_FIXTURE_SECRET";
const projects = ["chromium-320", "chromium-tablet", "chromium-wide"] as const;
const actors = ["ops", "restricted"] as const;
const raceCommands = [
  "revoke",
  "restore",
  "drift",
  "duplicate",
  "disconnect",
  "interrupt",
  "status",
] as const;
const raceStates = [
  "authorized",
  "revoke",
  "drift",
  "duplicate",
  "disconnect",
  "interrupt",
] as const;
const runPattern = /^[a-z0-9][a-z0-9_-]{0,47}$/;

export type Phase81Project = (typeof projects)[number];
export type Phase81Actor = (typeof actors)[number];
export type Phase81RaceCommand = (typeof raceCommands)[number];
export type Phase81RaceState = (typeof raceStates)[number];

export type Phase81FixtureState = {
  project: Phase81Project;
  run: string;
  actors: ["ops", "restricted"];
  counts: {
    workflows: 51;
    workflowSteps: 101;
    workflowResults: 51;
    workflowEvidence: 26;
    batchMembers: 51;
    batchCallbacks: 26;
    batchAudit: 26;
    incidents: 51;
    executors: 26;
    lifelineAudit: 51;
  };
  handles: {
    batchId: string;
    workflowId: string;
    workflowStep: string;
    incidentId: string;
  };
  race: { state: "authorized" };
};

const states = new Map<Phase81Project, Phase81FixtureState>();

export async function resetPhase81BrowserFixture(
  request: APIRequestContext,
  options: { secret: string; project?: string; run?: string },
): Promise<Phase81FixtureState> {
  const credential = requiredCredential(options.secret);
  const project = oneOf(
    options.project ?? test.info().project.name,
    projects,
    "Phase 81 fixture project is outside the closed Playwright project set",
  );
  const run = runName(options.run ?? defaultRunTag());
  const response = await post(request, "reset", { project, run }, credential);
  const state = validateReset(
    await successfulJson(response, "reset"),
    credential,
  );

  if (state.project !== project || state.run !== run) {
    throw new Error(
      "Phase 81 reset returned a mismatched project or run identity",
    );
  }

  states.set(project, state);
  return state;
}

export async function authenticatePhase81Actor(
  page: Page,
  options: { actor: Phase81Actor; secret: string },
): Promise<void> {
  const credential = requiredCredential(options.secret);
  const actor = oneOf(
    options.actor,
    actors,
    "Phase 81 actor is outside the closed actor set",
  );
  const state = currentState();
  const response = await post(
    page.request,
    "actor",
    { project: state.project, run: state.run, actor },
    credential,
  );
  const value = record(
    await successfulJson(response, "actor"),
    "actor response",
  );
  exactKeys(value, ["actor", "state"], "actor response");
  rejectSensitive(value, "actor response");
  exactString(value.actor, actor, "actor");
  exactString(value.state, "authenticated", "actor state");
}

export async function controlPhase81Race(
  request: APIRequestContext,
  options: { command: Phase81RaceCommand; secret: string },
): Promise<{ command: Phase81RaceCommand; state: Phase81RaceState }> {
  const credential = requiredCredential(options.secret);
  const command = oneOf(
    options.command,
    raceCommands,
    "Phase 81 race command is outside the set",
  );
  const fixture = currentState();
  const response = await post(
    request,
    "race",
    { project: fixture.project, run: fixture.run, command },
    credential,
  );
  const value = record(await successfulJson(response, "race"), "race response");
  exactKeys(value, ["command", "state"], "race response");
  rejectSensitive(value, "race response");

  return {
    command: oneOf(
      value.command,
      raceCommands,
      "Phase 81 race response command is invalid",
    ),
    state: oneOf(
      value.state,
      raceStates,
      "Phase 81 race response state is invalid",
    ),
  };
}

function validateReset(
  value: unknown,
  credential: string,
): Phase81FixtureState {
  const state = record(value, "reset response");
  exactKeys(
    state,
    ["actors", "counts", "handles", "project", "race", "run"],
    "reset response",
  );
  rejectSensitive(state, "reset response");

  if (JSON.stringify(state).includes(credential)) {
    throw new Error("Phase 81 reset response disclosed the fixture credential");
  }

  const actorValues = stringArray(state.actors, "reset actors");
  if (actorValues.join(",") !== actors.join(",")) {
    throw new Error("Phase 81 reset actors did not match the closed actor set");
  }

  const counts = record(state.counts, "reset counts");
  const handles = record(state.handles, "reset handles");
  const race = record(state.race, "reset race");
  const expectedCounts = {
    workflows: 51,
    workflowSteps: 101,
    workflowResults: 51,
    workflowEvidence: 26,
    batchMembers: 51,
    batchCallbacks: 26,
    batchAudit: 26,
    incidents: 51,
    executors: 26,
    lifelineAudit: 51,
  } as const;

  exactKeys(counts, Object.keys(expectedCounts), "reset counts");
  exactKeys(
    handles,
    ["batchId", "incidentId", "workflowId", "workflowStep"],
    "reset handles",
  );
  exactKeys(race, ["state"], "reset race");

  for (const [key, expected] of Object.entries(expectedCounts)) {
    if (counts[key] !== expected)
      throw new Error(`reset count ${key} did not match`);
  }

  return {
    project: oneOf(state.project, projects, "reset project is invalid"),
    run: runName(nonBlankString(state.run, "reset run")),
    actors: ["ops", "restricted"],
    counts: expectedCounts,
    handles: {
      batchId: nonBlankString(handles.batchId, "reset batch handle"),
      workflowId: nonBlankString(handles.workflowId, "reset workflow handle"),
      workflowStep: nonBlankString(handles.workflowStep, "reset workflow step"),
      incidentId: nonBlankString(handles.incidentId, "reset incident handle"),
    },
    race: {
      state: exactString(
        race.state,
        "authorized",
        "reset race state",
      ) as "authorized",
    },
  };
}

function currentState(): Phase81FixtureState {
  const project = oneOf(
    test.info().project.name,
    projects,
    "Phase 81 fixture project is outside the closed Playwright project set",
  );
  const state = states.get(project);
  if (!state)
    throw new Error(
      "Phase 81 fixture action requires a successful project reset first",
    );
  return state;
}

function requiredCredential(provided: string): string {
  const configured = process.env[credentialVariable]?.trim() ?? "";
  if (configured.length === 0)
    throw new Error("Phase 81 fixture credential is unavailable");
  if (provided.trim().length === 0 || provided !== configured) {
    throw new Error(
      "Phase 81 fixture credential does not match the process environment",
    );
  }
  return configured;
}

async function post(
  request: APIRequestContext,
  action: "reset" | "actor" | "race",
  data: Record<string, string>,
  credential: string,
): Promise<APIResponse> {
  return request.post(`${endpoint}/${action}`, {
    data,
    headers: { "x-phase81-fixture-secret": credential },
  });
}

async function successfulJson(
  response: APIResponse,
  action: string,
): Promise<unknown> {
  if (!response.ok()) {
    throw new Error(
      `Phase 81 ${action} request failed with status ${response.status()}`,
    );
  }

  try {
    return (await response.json()) as unknown;
  } catch {
    throw new Error(`Phase 81 ${action} response was not valid JSON`);
  }
}

function defaultRunTag(): string {
  const info = test.info();
  return `pw-${info.workerIndex}-${info.repeatEachIndex}-${info.retry}`;
}

function runName(value: string): string {
  if (!runPattern.test(value))
    throw new Error("Phase 81 fixture run must be a closed run tag");
  return value;
}

function record(value: unknown, label: string): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${label} must be an object`);
  }
  return value as Record<string, unknown>;
}

function exactKeys(
  value: Record<string, unknown>,
  expected: readonly string[],
  label: string,
): void {
  if (Object.keys(value).sort().join(",") !== [...expected].sort().join(",")) {
    throw new Error(`${label} did not match the closed public schema`);
  }
}

function rejectSensitive(value: unknown, label: string): void {
  if (Array.isArray(value)) {
    value.forEach((item, index) => rejectSensitive(item, `${label}[${index}]`));
    return;
  }
  if (!value || typeof value !== "object") return;

  for (const [key, nested] of Object.entries(
    value as Record<string, unknown>,
  )) {
    if (
      /(?:secret|token|hash|snapshot|credential|authority|raw.?error)/i.test(
        key,
      )
    ) {
      throw new Error(`${label} contained a prohibited response field`);
    }
    rejectSensitive(nested, `${label}.${key}`);
  }
}

function nonBlankString(value: unknown, label: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`${label} must be a nonblank string`);
  }
  return value;
}

function exactString(value: unknown, expected: string, label: string): string {
  const actual = nonBlankString(value, label);
  if (actual !== expected) throw new Error(`${label} did not match`);
  return actual;
}

function stringArray(value: unknown, label: string): string[] {
  if (!Array.isArray(value)) throw new Error(`${label} must be an array`);
  return value.map((item, index) => nonBlankString(item, `${label}[${index}]`));
}

function oneOf<const Values extends readonly string[]>(
  value: unknown,
  allowed: Values,
  label: string,
): Values[number] {
  if (typeof value !== "string" || !allowed.includes(value))
    throw new Error(label);
  return value as Values[number];
}
