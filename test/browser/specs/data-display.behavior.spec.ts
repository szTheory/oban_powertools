import { expect, test, type Locator, type Page } from '@playwright/test';
import { dataStories, themes, type ShowcaseDataStory } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { prepareShowcase, targetLocator } from '../support/showcase';

const secretSentinel = 'PHASE77-SECRET-SENTINEL';

if (!Array.isArray(dataStories) || dataStories.length === 0) {
  throw new Error('Phase 77 requires schema-5 generated dataStories in the showcase manifest');
}

function dataStory(id: string): ShowcaseDataStory {
  const story = dataStories.find((candidate) => candidate.id === id);

  if (!story) {
    throw new Error(`Missing data story in generated manifest: ${id}`);
  }

  return story;
}

async function prepareDataStory(
  page: Page,
  projectName: string,
  story: ShowcaseDataStory,
  theme = 'light'
): Promise<Locator> {
  await prepareShowcase(page, {
    theme,
    viewportName: viewportNameFromProject(projectName)
  });
  await expect(page.locator('[data-phx-main].phx-connected')).toHaveCount(1);

  const locator = targetLocator(page, story);
  await expect(locator).toBeVisible();
  return locator;
}

async function expectNoHorizontalOverflow(locator: Locator): Promise<void> {
  const overflow = await locator.evaluate((element) => ({
    story: Math.ceil(element.scrollWidth - element.clientWidth),
    body: Math.ceil(document.body.scrollWidth - document.body.clientWidth),
    document: Math.ceil(document.documentElement.scrollWidth - document.documentElement.clientWidth)
  }));

  expect(overflow.story).toBeLessThanOrEqual(1);
  expect(overflow.body).toBeLessThanOrEqual(1);
  expect(overflow.document).toBeLessThanOrEqual(1);
}

async function expectVisibleKeyboardFocus(
  page: Page,
  locator: Locator,
  label: string
): Promise<void> {
  await expect(locator, `${label} should be visible before keyboard focus`).toBeVisible();

  await locator.evaluate((element, sentinelLabel) => {
    const sentinel = document.createElement('button');
    const anchor = element.closest('details') ?? element;
    sentinel.type = 'button';
    sentinel.textContent = sentinelLabel;
    sentinel.setAttribute('data-obpt-data-focus-sentinel', sentinelLabel);
    anchor.parentElement?.insertBefore(sentinel, anchor);
    sentinel.focus();
  }, label);

  await page.keyboard.press('Tab');
  await expect(locator, `${label} should receive keyboard focus`).toBeFocused();

  const outline = await locator.evaluate((element) => {
    const style = window.getComputedStyle(element);
    return {
      style: style.outlineStyle,
      width: Number.parseFloat(style.outlineWidth),
      color: style.outlineColor
    };
  });

  expect(outline.style, `${label} should use a visible outline style`).not.toBe('none');
  expect(outline.width, `${label} should use a non-zero outline width`).toBeGreaterThan(0);
  expect(outline.color, `${label} should use a visible outline color`).not.toBe('rgba(0, 0, 0, 0)');

  await locator.evaluate(() => {
    document.querySelector('[data-obpt-data-focus-sentinel]')?.remove();
  });
}

test.describe('data data-display behavior contracts', () => {
  test('data data-table sorting is parent-owned for click, Enter, and Space with one aria-sort', async ({
    page
  }, testInfo) => {
    const story = await prepareDataStory(
      page,
      testInfo.project.name,
      dataStory('data-table-sort-states')
    );
    const worker = story.locator('button[phx-value-sort-key="worker"]');
    const state = story.locator('button[phx-value-sort-key="state"]');

    await expect(story.locator('table')).toHaveCount(1);
    await expect(story.locator('[role="grid"]')).toHaveCount(0);
    await expect(story.locator('th[aria-sort]')).toHaveCount(1);
    await expect(worker.locator('xpath=ancestor::th')).toHaveAttribute('aria-sort', 'ascending');

    await worker.click();
    await expect(story.locator('th[aria-sort]')).toHaveCount(1);
    await expect(worker.locator('xpath=ancestor::th')).toHaveAttribute('aria-sort', 'descending');

    await expectVisibleKeyboardFocus(page, state, 'State sort button');
    await page.keyboard.press('Enter');
    await expect(story.locator('th[aria-sort]')).toHaveCount(1);
    await expect(state.locator('xpath=ancestor::th')).toHaveAttribute('aria-sort', 'ascending');
    await expect(worker.locator('xpath=ancestor::th')).not.toHaveAttribute('aria-sort', /.+/);

    await expectVisibleKeyboardFocus(page, state, 'State sort button');
    await page.keyboard.press('Space');
    await expect(story.locator('th[aria-sort]')).toHaveCount(1);
    await expect(state.locator('xpath=ancestor::th')).toHaveAttribute('aria-sort', 'descending');
  });

  test('data 320 stacked rows keep one semantic DOM, one labelled selection per row, 44px targets, and no overflow', async ({
    page
  }, testInfo) => {
    const story = await prepareDataStory(
      page,
      testInfo.project.name,
      dataStory('data-table-320-stacked')
    );
    const table = story.locator('table');
    const rows = table.locator('tbody tr');
    const mobileLabels = story.locator('.obpt-data-table__mobile-label');
    const mobileProject = viewportNameFromProject(testInfo.project.name) === '320';

    await expect(table).toHaveCount(1);
    await expect(story.locator('[role="grid"]')).toHaveCount(0);
    await expect(rows).toHaveCount(3);
    await expect(story.getByRole('checkbox', { name: /Select job job-/ })).toHaveCount(3);
    await expectNoHorizontalOverflow(story);

    for (let index = 0; index < 3; index += 1) {
      const row = rows.nth(index);
      const checkbox = row.getByRole('checkbox', { name: `Select job job-000${index + 1}` });
      const choice = checkbox.locator('xpath=ancestor::label[contains(@class, "obpt-choice")]');

      await expect(checkbox).toHaveCount(1);
      await expect(
        row.locator('.obpt-data-table__mobile-label', { hasText: 'Worker' })
      ).toHaveCount(1);

      if (mobileProject) {
        await expect(row).toHaveCSS('display', 'grid');
        await expect(
          row.locator('.obpt-data-table__mobile-label', { hasText: 'Worker' })
        ).toBeVisible();
        const box = await choice.boundingBox();
        expect(
          box?.height ?? 0,
          `selection target ${index + 1} should be at least 44px`
        ).toBeGreaterThanOrEqual(44);
      }
    }

    if (mobileProject) {
      await expect(table).toHaveCSS('display', 'block');
      await expect(mobileLabels.first()).toBeVisible();
    } else {
      await expect(table).toHaveCSS('display', 'table');
      await expect(rows.first()).toHaveCSS('display', 'table-row');
      await expect(mobileLabels.first()).toBeHidden();
    }
  });

  test('data sort, selection, expansion, code, and dismiss controls expose keyboard focus in all themes', async ({
    page
  }, testInfo) => {
    for (const theme of themes) {
      await prepareDataStory(
        page,
        testInfo.project.name,
        dataStory('data-description-list-long-values'),
        theme
      );

      const sort = targetLocator(page, dataStory('data-table-sort-states')).locator(
        'button[phx-value-sort-key="worker"]'
      );
      const selection = targetLocator(page, dataStory('data-table-320-stacked'))
        .getByRole('checkbox', { name: 'Select job job-0001' })
        .first();
      const expansion = targetLocator(page, dataStory('data-description-list-long-values'))
        .locator('summary')
        .first();
      const code = targetLocator(page, dataStory('data-code-args-redaction'))
        .locator('pre[tabindex="0"]')
        .first();
      const dismiss = targetLocator(page, dataStory('data-empty-toast-flash'))
        .getByRole('button', { name: 'Dismiss notification' })
        .first();

      await expectVisibleKeyboardFocus(page, sort, `sort button in ${theme}`);
      await expectVisibleKeyboardFocus(page, selection, `selection checkbox in ${theme}`);
      await expectVisibleKeyboardFocus(page, expansion, `machine value expansion in ${theme}`);
      await expectVisibleKeyboardFocus(page, code, `code region in ${theme}`);
      await expectVisibleKeyboardFocus(page, dismiss, `toast dismiss button in ${theme}`);
    }
  });

  test('data long machine values preserve useful ends and expose native expansion', async ({
    page
  }, testInfo) => {
    const story = await prepareDataStory(
      page,
      testInfo.project.name,
      dataStory('data-description-list-long-values')
    );
    const details = story.locator('details');
    const moduleDetails = story.locator('#data-long-module details');
    const urlDetails = story.locator('#data-long-url details');

    await expect(details).toHaveCount(3);
    await expect(story.locator('#data-long-id summary')).toContainText(
      '01JZ8M5P999999999999999999'
    );
    await expect(moduleDetails.locator('summary')).toContainText('IntentionallyLongIdentifier');
    await expect(urlDetails.locator('summary')).toContainText('https://operator.example.test');
    await expect(urlDetails.locator('summary')).toContainText('attempt=20');

    await moduleDetails.locator('summary').click();
    await expect(moduleDetails).toHaveAttribute('open', '');
    await expect(moduleDetails.locator('.obpt-machine-value__full')).toHaveText(
      'MyApp.Workers.ReconcileAccountNotificationDeliveryWithAnIntentionallyLongIdentifier'
    );
    await expectNoHorizontalOverflow(story);
  });

  test('data code regions are focusable, internally scrollable, bounded, and do not move page overflow', async ({
    page
  }, testInfo) => {
    const story = await prepareDataStory(
      page,
      testInfo.project.name,
      dataStory('data-code-args-redaction')
    );
    const pre = story.locator('.obpt-code-block__region').first();

    await expect(pre).toHaveAttribute('tabindex', '0');
    await expectVisibleKeyboardFocus(page, pre, 'normalized args code region');

    const metrics = await pre.evaluate((element) => {
      const style = getComputedStyle(element);
      element.scrollLeft = element.scrollWidth;
      return {
        overflowX: style.overflowX,
        overflowY: style.overflowY,
        maxBlockSize: Number.parseFloat(style.maxBlockSize),
        blockSize: element.getBoundingClientRect().height,
        scrollWidth: element.scrollWidth,
        clientWidth: element.clientWidth,
        scrollLeft: element.scrollLeft
      };
    });

    expect(metrics.overflowX).toBe('auto');
    expect(metrics.overflowY).toBe('auto');
    expect(metrics.scrollWidth).toBeGreaterThan(metrics.clientWidth);
    expect(metrics.scrollLeft).toBeGreaterThan(0);
    expect(metrics.maxBlockSize).toBeGreaterThan(0);
    expect(metrics.blockSize).toBeLessThanOrEqual(metrics.maxBlockSize + 2);
    await expectNoHorizontalOverflow(story);
  });

  test('data redaction exposes exact safe copy and hides the sentinel from every disclosure channel', async ({
    page
  }, testInfo) => {
    const story = await prepareDataStory(
      page,
      testInfo.project.name,
      dataStory('data-code-args-redaction')
    );

    for (const copy of ['Redacted at enqueue', 'Hidden by display policy', '[redacted]']) {
      await expect(
        story.locator('.obpt-redacted-value__copy').getByText(copy, { exact: true }).first()
      ).toBeVisible();
    }

    await expect(story).not.toContainText(secretSentinel);
    await expect(story.getByRole('button', { name: /copy/i })).toHaveCount(0);
    await expect(story.locator('[data-clipboard-text]')).toHaveCount(0);

    const leaked = await story.evaluate((element, sentinel) => {
      const channels = [element.textContent ?? ''];

      for (const candidate of element.querySelectorAll<HTMLElement>('*')) {
        for (const attribute of Array.from(candidate.attributes)) {
          if (
            attribute.name === 'title' ||
            attribute.name.startsWith('data-') ||
            attribute.name.startsWith('aria-') ||
            attribute.name.includes('copy') ||
            attribute.name.includes('clipboard')
          ) {
            channels.push(attribute.value);
          }
        }
      }

      for (const details of element.querySelectorAll('details')) {
        channels.push(details.textContent ?? '');
      }

      return channels.some((value) => value.includes(sentinel));
    }, secretSentinel);

    expect(leaked).toBe(false);
  });

  test('data toast urgency and dismiss behavior preserve focus while progress and large rows stay truthful', async ({
    page
  }, testInfo) => {
    await prepareDataStory(page, testInfo.project.name, dataStory('data-empty-toast-flash'));

    const feedback = targetLocator(page, dataStory('data-empty-toast-flash'));
    const infoToast = feedback.locator(
      '#data-flash-group-aW5mbw[data-obpt-tone="info"][role="status"]'
    );
    const errorToast = feedback.locator(
      '#data-flash-group-ZXJyb3I[data-obpt-tone="danger"][role="alert"]'
    );
    const infoDismiss = infoToast.locator(
      'button[phx-click="lv:clear-flash"][phx-value-key="info"]'
    );
    const errorDismiss = errorToast.locator(
      'button[phx-click="lv:clear-flash"][phx-value-key="error"]'
    );
    const stableFocus = targetLocator(page, dataStory('data-table-sort-states')).locator(
      'button[phx-value-sort-key="worker"]'
    );

    await expect(feedback.getByRole('status')).toHaveCount(1);
    await expect(feedback.getByRole('alert')).toHaveCount(2);
    await expect(infoToast).toContainText('Filters cleared.');
    await expect(errorToast).toContainText('Job data did not load.');
    await expect(infoDismiss).toHaveCount(1);
    await expect(errorDismiss).toHaveCount(1);
    await expectVisibleKeyboardFocus(page, errorDismiss, 'toast dismiss button');
    await stableFocus.focus();
    await expect(stableFocus).toBeFocused();
    await errorDismiss.dispatchEvent('click');
    await expect(stableFocus).toBeFocused();
    await expect(errorToast).toHaveCount(0);
    await expect(infoToast).toBeVisible();
    await expect(infoDismiss).toHaveCount(1);

    const progress = targetLocator(page, dataStory('data-progress-metric-cards'));
    const determinate = progress.getByRole('progressbar', { name: 'Batch completion' });
    await expect(determinate).toHaveAttribute('max', '100');
    await expect(determinate).toHaveAttribute('value', '100');
    expect(await determinate.evaluate((element) => (element as HTMLProgressElement).value)).toBe(
      100
    );
    await expect(progress.getByText('100/100', { exact: true })).toBeVisible();
    await expect(progress.getByText('100%', { exact: true })).toBeVisible();
    const unavailable = progress.locator('#data-progress-unavailable');
    await expect(unavailable).toHaveAttribute('data-obpt-data-state', 'unavailable');
    await expect(unavailable.locator('progress')).toHaveCount(0);
    await expect(unavailable.locator('[aria-valuenow]')).toHaveCount(0);
    await expect(unavailable.locator('.obpt-progress__count')).toHaveCount(0);
    await expect(unavailable.locator('.obpt-progress__percent')).toHaveCount(0);
    await expect(unavailable).not.toContainText(/\b\d+\s*\/\s*\d+\b/);
    await expect(unavailable).not.toContainText(/\b\d+%/);
    await expect(unavailable.getByText('Progress unavailable', { exact: true })).toBeVisible();

    const largeRows = targetLocator(page, dataStory('data-table-thousands-row-stress'));
    const rows = largeRows.locator('#data-thousands-table tbody tr');
    await expect(largeRows).toContainText('2,500 jobs');
    await expect(rows).toHaveCount(20);
    expect(await rows.count()).toBeLessThanOrEqual(25);
    await expect(rows.first()).toHaveAttribute('id', 'data-thousands-table-row-job-0001');
    await expect(rows.last()).toHaveAttribute('id', 'data-thousands-table-row-job-0020');
  });
});
