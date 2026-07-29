import { expect, test, type APIRequestContext } from "@playwright/test";
import {
  authenticatePhase81Actor,
  controlPhase81Race,
  resetPhase81BrowserFixture,
} from "../support/phase81-fixtures";

test.use({ trace: "off", screenshot: "off" });
test.describe.configure({ mode: "serial" });

const endpoint = "/__phase81_browser_fixtures__";

function credential(): string {
  const value = process.env.PHASE81_BROWSER_FIXTURE_SECRET?.trim() ?? "";
  if (value.length === 0)
    throw new Error("Phase 81 fixture credential is unavailable");
  return value;
}

test("resets deterministically with the exact saturated bounds and a connected production route", async ({
  page,
  request,
}) => {
  const secret = credential();
  const first = await resetPhase81BrowserFixture(request, { secret });
  const second = await resetPhase81BrowserFixture(request, { secret });
  expect(second).toEqual(first);
  expect(second.counts).toEqual({
    workflows: 51,
    workflowSteps: 101,
    workflowResults: 51,
    workflowEvidence: 26,
    batchMembers: 51,
    batchCallbacks: 26,
    batchResults: 51,
    batchAudit: 26,
    incidents: 51,
    executors: 26,
    lifelineAudit: 51,
    archiveRows: 26,
  });

  await authenticatePhase81Actor(page, { actor: "ops", secret });
  await page.goto("/ops/jobs/oban/batches");
  await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);
});

test("keeps project identities isolated", async ({ request }, testInfo) => {
  const secret = credential();
  const active = await resetPhase81BrowserFixture(request, { secret });
  const otherProject =
    testInfo.project.name === "chromium-wide"
      ? "chromium-tablet"
      : "chromium-wide";
  const other = await resetPhase81BrowserFixture(request, {
    secret,
    project: otherProject,
    run: `isolation-${testInfo.project.name}`,
  });

  expect(other.handles.batchId).not.toBe(active.handles.batchId);
  expect(other.handles.workflowId).not.toBe(active.handles.workflowId);
});

test("sets both actors and exposes every explicit race state", async ({
  page,
  request,
}) => {
  const secret = credential();
  await resetPhase81BrowserFixture(request, { secret });

  for (const actor of ["ops", "restricted"] as const) {
    await authenticatePhase81Actor(page, { actor, secret });
  }

  for (const command of [
    "revoke",
    "drift",
    "duplicate",
    "disconnect",
    "interrupt",
    "restore",
  ] as const) {
    const result = await controlPhase81Race(request, { command, secret });
    expect(result.command).toBe(command);
    expect(result.state).toBe(command === "restore" ? "authorized" : command);
  }
});

test("fails locally before network access without a credential", async () => {
  const previous = process.env.PHASE81_BROWSER_FIXTURE_SECRET;
  let requests = 0;
  const request = {
    post: async () => {
      requests += 1;
      throw new Error("network access must not occur");
    },
  } as unknown as APIRequestContext;

  try {
    delete process.env.PHASE81_BROWSER_FIXTURE_SECRET;
    await expect(
      resetPhase81BrowserFixture(request, { secret: "" }),
    ).rejects.toThrow("Phase 81 fixture credential is unavailable");
    expect(requests).toBe(0);
  } finally {
    if (previous === undefined)
      delete process.env.PHASE81_BROWSER_FIXTURE_SECRET;
    else process.env.PHASE81_BROWSER_FIXTURE_SECRET = previous;
  }
});

test("returns indistinguishable empty denials for absent and wrong credentials", async ({
  request,
}) => {
  credential();
  const data = { project: "chromium-wide", run: "denial-proof" };
  const absent = await request.post(`${endpoint}/reset`, { data });
  const wrong = await request.post(`${endpoint}/reset`, {
    data,
    headers: { "x-phase81-fixture-secret": "invalid-fixture-credential" },
  });

  expect(absent.status()).toBe(404);
  expect(wrong.status()).toBe(404);
  expect(await absent.body()).toEqual(Buffer.alloc(0));
  expect(await wrong.body()).toEqual(Buffer.alloc(0));
});

test("never leaks the credential through response bodies", async ({
  request,
}) => {
  const secret = credential();
  const response = await request.post(`${endpoint}/reset`, {
    data: { project: "chromium-wide", run: "channel-proof" },
    headers: { "x-phase81-fixture-secret": secret },
  });
  const body = await response.text();

  expect(response.ok()).toBe(true);
  expect(body).not.toContain(secret);
  expect(body).not.toMatch(/secret|token|snapshot|credential|authority/i);
});
