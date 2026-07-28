import { expect, test, type APIRequestContext } from '@playwright/test';
import {
  authenticatePhase80Actor,
  controlPhase80Batch,
  readPhase80Evidence,
  resetPhase80BrowserFixture
} from '../support/phase80-fixtures';

test.use({ trace: 'off', screenshot: 'off' });
test.describe.configure({ mode: 'serial' });

const endpoint = '/__phase80_browser_fixtures__';

function requiredCredential(): string {
  const value = process.env.PHASE80_BROWSER_FIXTURE_SECRET?.trim() ?? '';
  if (value.length === 0) throw new Error('Phase 80 fixture credential is unavailable');
  return value;
}

test('resets the active project twice and exposes a connected production page', async ({
  page,
  request
}) => {
  const credential = requiredCredential();
  const first = await resetPhase80BrowserFixture(request, { secret: credential });
  const second = await resetPhase80BrowserFixture(request, { secret: credential });

  expect(second).toEqual(first);
  expect(second.counts).toEqual({
    jobs: 2500,
    workflowEvents: 55,
    incidentEvents: 55
  });
  expect(second.jobs).toMatchObject({
    pageSize: 20,
    totalCount: 2500,
    finalPage: 125,
    finalPageCount: 20,
    underLimitCount: 3,
    overLimitCount: 101
  });

  await authenticatePhase80Actor(page, { actor: 'ops', secret: credential });
  await page.goto('/ops/jobs/oban/jobs?state=available');
  await expect(page.locator('[data-phx-main].phx-connected')).toHaveCount(1);
});

test('keeps project identities isolated across authenticated resets', async ({ request }, testInfo) => {
  const credential = requiredCredential();
  const active = await resetPhase80BrowserFixture(request, { secret: credential });
  const otherProject = testInfo.project.name === 'chromium-wide' ? 'chromium-tablet' : 'chromium-wide';
  const other = await resetPhase80BrowserFixture(request, {
    secret: credential,
    project: otherProject,
    run: `isolation-${testInfo.project.name}`
  });

  expect(other.project).toBe(otherProject);
  expect(other.jobs.boundaryQueue).not.toBe(active.jobs.boundaryQueue);
  expect(other.forensics.workflowId).not.toBe(active.forensics.workflowId);

  const activeAgain = await resetPhase80BrowserFixture(request, {
    secret: credential,
    project: active.project,
    run: active.run
  });
  expect(activeAgain).toEqual(active);
});

test('sets ops and restricted actors through the same browser context', async ({ page, request }) => {
  const credential = requiredCredential();
  await resetPhase80BrowserFixture(request, { secret: credential });

  await authenticatePhase80Actor(page, { actor: 'ops', secret: credential });
  await page.goto('/ops/jobs/_showcase');
  await expect(page.getByText('Actor: ops', { exact: true })).toBeVisible();

  await authenticatePhase80Actor(page, { actor: 'restricted', secret: credential });
  await page.goto('/ops/jobs/_showcase');
  await expect(page.getByText('Actor: restricted', { exact: true })).toBeVisible();
});

test('holds, observes, and releases the batch barrier with bounded public evidence polling', async ({
  request
}) => {
  const credential = requiredCredential();
  const state = await resetPhase80BrowserFixture(request, { secret: credential });

  await expect(controlPhase80Batch(request, { command: 'status', secret: credential })).resolves.toEqual(
    { command: 'status', state: 'idle' }
  );
  await expect(controlPhase80Batch(request, { command: 'hold', secret: credential })).resolves.toEqual(
    { command: 'hold', state: 'held' }
  );
  await expect(controlPhase80Batch(request, { command: 'status', secret: credential })).resolves.toEqual(
    { command: 'hold', state: 'held' }
  );
  await expect(
    controlPhase80Batch(request, { command: 'release', secret: credential })
  ).resolves.toEqual({ command: 'release', state: 'released' });
  await expect(controlPhase80Batch(request, { command: 'status', secret: credential })).resolves.toEqual(
    { command: 'release', state: 'released' }
  );

  await expect
    .poll(
      async () => {
        const evidence = await readPhase80Evidence(request, { secret: credential });
        return {
          project: evidence.project,
          run: evidence.run,
          jobs: evidence.counts.jobs,
          stateKeys: Object.keys(evidence.states).sort()
        };
      },
      { timeout: 5_000, intervals: [100, 250, 500] }
    )
    .toEqual({
      project: state.project,
      run: state.run,
      jobs: 2500,
      stateKeys: [
        'consumed',
        'drifted',
        'eligible',
        'excluded',
        'expired',
        'failed',
        'skipped',
        'success'
      ]
    });
});

test('fails locally before network access when the fixture credential is absent', async () => {
  const previous = process.env.PHASE80_BROWSER_FIXTURE_SECRET;
  let requests = 0;
  const request = {
    post: async () => {
      requests += 1;
      throw new Error('network access must not occur');
    }
  } as unknown as APIRequestContext;

  try {
    delete process.env.PHASE80_BROWSER_FIXTURE_SECRET;
    await expect(resetPhase80BrowserFixture(request, { secret: '' })).rejects.toThrow(
      'Phase 80 fixture credential is unavailable'
    );
    expect(requests).toBe(0);
  } finally {
    if (previous === undefined) delete process.env.PHASE80_BROWSER_FIXTURE_SECRET;
    else process.env.PHASE80_BROWSER_FIXTURE_SECRET = previous;
  }
});

test('returns indistinguishable empty 404 responses for absent and wrong headers', async ({
  request
}) => {
  requiredCredential();
  const data = { project: 'chromium-wide', run: 'denial-proof' };
  const absent = await request.post(`${endpoint}/reset`, { data });
  const wrong = await request.post(`${endpoint}/reset`, {
    data,
    headers: { 'x-phase80-fixture-secret': 'invalid-fixture-credential' }
  });

  expect(absent.status()).toBe(404);
  expect(wrong.status()).toBe(404);
  expect(await absent.body()).toEqual(Buffer.alloc(0));
  expect(await wrong.body()).toEqual(Buffer.alloc(0));
});
