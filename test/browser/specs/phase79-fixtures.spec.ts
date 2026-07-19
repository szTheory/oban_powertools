import { expect, test, type APIRequestContext } from '@playwright/test';
import {
  authenticatePhase79Actor,
  resetPhase79BrowserFixture,
  setPhase79CronRecovery,
  type Phase79Recovery
} from '../support/phase79-fixtures';

test.use({ trace: 'off', screenshot: 'off' });
test.describe.configure({ mode: 'serial' });

const endpoint = '/__phase79_browser_fixtures__';

function requiredCredential(): string {
  const value = process.env.PHASE79_BROWSER_FIXTURE_SECRET?.trim() ?? '';
  if (value.length === 0) throw new Error('Phase 79 fixture credential is unavailable');
  return value;
}

test('resets the active project twice and exposes connected showcase state', async ({
  page,
  request
}) => {
  const credential = requiredCredential();
  const first = await resetPhase79BrowserFixture(request, { secret: credential });
  const second = await resetPhase79BrowserFixture(request, { secret: credential });

  expect(second).toEqual(first);
  expect(second.counts).toEqual({
    cronEntries: 3,
    limiterResources: 2,
    auditFiltered: 45,
    auditNewerUnrelated: 21,
    overviewActive: 1,
    overviewResolved: 1
  });

  await authenticatePhase79Actor(page, { actor: 'operator', secret: credential });
  await page.goto('/ops/jobs/_showcase');
  await expect(page.locator('[data-phx-main].phx-connected')).toHaveCount(1);
  await expect(page.locator('[data-obpt-showcase]')).toHaveCount(1);
});

test('keeps project identities isolated across authenticated resets', async ({ request }, testInfo) => {
  const credential = requiredCredential();
  const active = await resetPhase79BrowserFixture(request, { secret: credential });
  const otherProject = testInfo.project.name === 'chromium-wide' ? 'chromium-tablet' : 'chromium-wide';
  const other = await resetPhase79BrowserFixture(request, {
    secret: credential,
    project: otherProject,
    run: 'isolation-proof'
  });

  expect(other.project).toBe(otherProject);
  expect(other.cron.firstEntry).not.toBe(active.cron.firstEntry);
  expect(other.limiters.blockedResource).not.toBe(active.limiters.blockedResource);

  const activeAgain = await resetPhase79BrowserFixture(request, {
    secret: credential,
    project: active.project,
    run: active.run
  });
  expect(activeAgain).toEqual(active);
});

test('sets operator and read-only actors through the same browser context', async ({
  page,
  request
}) => {
  const credential = requiredCredential();
  const state = await resetPhase79BrowserFixture(request, { secret: credential });

  await authenticatePhase79Actor(page, { actor: 'operator', secret: credential });
  await page.goto(`/ops/jobs/cron?entry=${encodeURIComponent(state.cron.firstEntry)}`);
  await expect(page.getByRole('button', { name: 'Pause cron entry' })).toBeEnabled();

  await authenticatePhase79Actor(page, { actor: 'read_only', secret: credential });
  await page.reload();
  await expect(page.getByRole('button', { name: 'Pause cron entry' })).toBeDisabled();
});

test('prepares every locked real-preview recovery without a success receipt', async ({
  page,
  request
}) => {
  const credential = requiredCredential();
  const state = await resetPhase79BrowserFixture(request, { secret: credential });

  await authenticatePhase79Actor(page, { actor: 'operator', secret: credential });

  for (const recovery of [
    'expired',
    'drifted',
    'consumed',
    'skipped',
    'partial'
  ] as Phase79Recovery[]) {
    await setPhase79CronRecovery(request, {
      entry: state.cron.recoveryEntry,
      recovery,
      secret: credential
    });

    await page.goto(`/ops/jobs/cron?entry=${encodeURIComponent(state.cron.recoveryEntry)}`);
    await page.getByRole('button', { name: 'Run cron entry now' }).click();
    await page.getByRole('textbox', { name: 'Reason' }).fill('Preserve this safe reason');
    await page.getByRole('button', { name: 'Run cron entry now' }).click();

    const dialog = page.locator('#cron-confirmation-dialog');
    await expect(dialog).toBeVisible();
    await expect(dialog.getByRole('button', { name: 'Create new preview' })).toBeVisible();
    await expect(dialog).toContainText(new RegExp(recovery, 'i'));
    await expect(page.locator('#cron-receipt')).toHaveCount(0);
  }
});

test('fails locally before network access when the fixture credential is absent', async () => {
  const previous = process.env.PHASE79_BROWSER_FIXTURE_SECRET;
  let requests = 0;
  const request = {
    post: async () => {
      requests += 1;
      throw new Error('network access must not occur');
    }
  } as unknown as APIRequestContext;

  try {
    delete process.env.PHASE79_BROWSER_FIXTURE_SECRET;
    await expect(resetPhase79BrowserFixture(request, { secret: '' })).rejects.toThrow(
      'Phase 79 fixture credential is unavailable'
    );
    expect(requests).toBe(0);
  } finally {
    if (previous === undefined) delete process.env.PHASE79_BROWSER_FIXTURE_SECRET;
    else process.env.PHASE79_BROWSER_FIXTURE_SECRET = previous;
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
    headers: { 'x-phase79-fixture-secret': 'invalid-fixture-credential' }
  });

  expect(absent.status()).toBe(404);
  expect(wrong.status()).toBe(404);
  expect(await absent.body()).toEqual(Buffer.alloc(0));
  expect(await wrong.body()).toEqual(Buffer.alloc(0));
});
