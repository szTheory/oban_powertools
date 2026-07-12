import { expect, test, type Locator, type Page } from '@playwright/test';
import { dataStories, themes, type ShowcaseDataStory } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { prepareShowcase, targetLocator } from '../support/showcase';

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

  const locator = targetLocator(page, story);
  await expect(locator).toBeVisible();
  return locator;
}

async function expectNoHorizontalOverflow(locator: Locator): Promise<void> {
  const overflow = await locator.evaluate((element) => ({
    elementDelta: Math.ceil(element.scrollWidth - element.clientWidth),
    bodyDelta: Math.ceil(document.body.scrollWidth - document.documentElement.clientWidth)
  }));

  expect(overflow.elementDelta).toBeLessThanOrEqual(1);
  expect(overflow.bodyDelta).toBeLessThanOrEqual(1);
}

async function expectVisibleFocus(locator: Locator): Promise<void> {
  await locator.focus();
  await expect(locator).toBeFocused();

  const outline = await locator.evaluate((element) => {
    const style = window.getComputedStyle(element);
    return {
      style: style.outlineStyle,
      width: Number.parseFloat(style.outlineWidth),
      color: style.outlineColor
    };
  });

  expect(outline.style).not.toBe('none');
  expect(outline.width).toBeGreaterThan(0);
  expect(outline.color).not.toBe('rgba(0, 0, 0, 0)');
}

test.describe('data data-display behavior contracts', () => {
  test('data data-table sorting is parent-owned and exposes one aria-sort', async ({
    page
  }, testInfo) => {
    const story = await prepareDataStory(page, testInfo.project.name, dataStory('data-table-sort-states'));
    const worker = story.getByRole('button', { name: /Worker/ });
    const state = story.getByRole('button', { name: /State/ });

    await expect(story.locator('table')).toHaveCount(1);
    await expect(story.locator('th[aria-sort]')).toHaveCount(1);
    await worker.click();
    await expect(story.locator('th[aria-sort]')).toHaveCount(1);
    await expect(worker.locator('xpath=ancestor::th')).toHaveAttribute('aria-sort', /ascending|descending/);
    await state.focus();
    await page.keyboard.press('Enter');
    await expect(state.locator('xpath=ancestor::th')).toHaveAttribute('aria-sort', /ascending|descending/);
    await page.keyboard.press('Space');
    await expect(story.locator('th[aria-sort]')).toHaveCount(1);
  });

  test('data 320 stacked table keeps one semantic DOM, labels, hit targets, and no overflow', async ({
    page
  }, testInfo) => {
    const story = await prepareDataStory(page, testInfo.project.name, dataStory('data-table-320-stacked'));

    await expect(story.locator('table')).toHaveCount(1);
    await expect(story.locator('[data-obpt-mobile-label="Worker"]')).toBeVisible();
    await expect(story.getByRole('checkbox', { name: /Select job/ })).toHaveCount(1);
    await expectNoHorizontalOverflow(story);

    const checkboxBox = await story.getByRole('checkbox', { name: /Select job/ }).boundingBox();
    expect(Math.max(checkboxBox?.width ?? 0, checkboxBox?.height ?? 0)).toBeGreaterThanOrEqual(24);
  });

  test('data focus remains visible for data controls in all themes', async ({ page }, testInfo) => {
    for (const theme of themes) {
      const story = await prepareDataStory(page, testInfo.project.name, dataStory('data-code-args-redaction'), theme);
      await expectVisibleFocus(story.locator('pre[tabindex="0"]').first());
    }
  });

  test('data redaction hides sentinels from text, title, data, details, and copy channels', async ({
    page
  }, testInfo) => {
    const story = await prepareDataStory(page, testInfo.project.name, dataStory('data-code-args-redaction'));

    await expect(story.getByText('Redacted at enqueue')).toBeVisible();
    await expect(story.getByText('Hidden by display policy')).toBeVisible();
    await expect(story).not.toContainText('PHASE77-SECRET-SENTINEL');

    const leaked = await story.evaluate((element) => {
      const haystacks = [element.textContent ?? ''];
      for (const candidate of element.querySelectorAll<HTMLElement>('*')) {
        haystacks.push(candidate.getAttribute('title') ?? '');
        haystacks.push(candidate.getAttribute('data-secret') ?? '');
        haystacks.push(candidate.getAttribute('data-value') ?? '');
        haystacks.push(candidate.getAttribute('aria-label') ?? '');
        haystacks.push(candidate.getAttribute('data-clipboard-text') ?? '');
      }
      return haystacks.some((value) => value.includes('PHASE77-SECRET-SENTINEL'));
    });

    expect(leaked).toBe(false);
  });

  test('data code regions, toast urgency, progress, and large rows stay bounded', async ({
    page
  }, testInfo) => {
    const code = await prepareDataStory(page, testInfo.project.name, dataStory('data-code-args-redaction'));
    const pre = code.locator('pre').first();
    await expect(pre).toBeVisible();
    await expectVisibleFocus(pre);
    await expectNoHorizontalOverflow(code);

    const feedback = targetLocator(page, dataStory('data-empty-toast-flash'));
    await expect(feedback.getByRole('status')).toBeVisible();
    await expect(feedback.getByRole('alert')).toBeVisible();
    const focusedBeforeDismiss = await page.evaluate(() => document.activeElement?.tagName ?? '');
    await feedback.getByRole('button', { name: /Dismiss/ }).first().click();
    expect(await page.evaluate(() => document.activeElement?.tagName ?? '')).toBe(focusedBeforeDismiss);

    const progress = targetLocator(page, dataStory('data-progress-metric-cards'));
    await expect(progress.locator('progress[value="100"]')).toBeVisible();
    await expect(progress.getByText('Progress unavailable')).toBeVisible();
    await expect(progress.locator('[aria-valuenow]')).toHaveCount(1);

    const largeRows = targetLocator(page, dataStory('data-table-thousands-row-stress'));
    await expect(largeRows.getByText(/1,000/)).toBeVisible();
    await expect(largeRows.locator('tbody tr')).toHaveCount(25);
  });
});
