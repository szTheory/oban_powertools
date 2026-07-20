import { expect, test, type Locator, type Page } from '@playwright/test';
import { primitiveStories, themes, type ShowcasePrimitiveStory } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { prepareShowcase, targetLocator } from '../support/showcase';

function primitiveStory(id: string): ShowcasePrimitiveStory {
  const story = primitiveStories.find((candidate) => candidate.id === id);

  if (!story) {
    throw new Error(`Missing primitive story in generated manifest: ${id}`);
  }

  return story;
}

async function preparePrimitiveStory(
  page: Page,
  projectName: string,
  story: ShowcasePrimitiveStory,
  theme = 'light'
): Promise<Locator> {
  const viewportName = viewportNameFromProject(projectName);

  await prepareShowcase(page, { theme, viewportName });

  const locator = targetLocator(page, story);
  await expect(locator).toBeVisible();

  return locator;
}

async function tabUntilFocused(page: Page, locator: Locator, label: string): Promise<void> {
  await expect(locator).toBeVisible();

  const tabBudget = await page.evaluate(
    () =>
      document.querySelectorAll(
        'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), summary, [tabindex]:not([tabindex="-1"])'
      ).length + 1
  );

  for (let index = 0; index < tabBudget; index += 1) {
    if (await locator.evaluate((element) => element === document.activeElement)) {
      return;
    }

    await page.keyboard.press('Tab');
  }

  throw new Error(`Could not reach ${label} with keyboard Tab navigation`);
}

async function expectVisibleFocus(locator: Locator, label: string): Promise<void> {
  await expect(locator, `${label} should receive focus`).toBeFocused();

  const outline = await locator.evaluate((element) => {
    const style = window.getComputedStyle(element);

    return {
      color: style.outlineColor,
      style: style.outlineStyle,
      width: Number.parseFloat(style.outlineWidth)
    };
  });

  expect(outline.style, `${label} should use a visible outline style`).not.toBe('none');
  expect(outline.width, `${label} should use a non-zero outline width`).toBeGreaterThan(0);
  expect(outline.color, `${label} should use a visible outline color`).not.toBe(
    'rgba(0, 0, 0, 0)'
  );
}

test.describe('primitive behavior contracts', () => {
  test('primitive icon buttons expose accessible names independent of tooltip text', async ({
    page
  }, testInfo) => {
    const story = await preparePrimitiveStory(
      page,
      testInfo.project.name,
      primitiveStory('primitive-icon-button-accessible-names')
    );

    const refresh = story.getByRole('button', { name: 'Refresh jobs' });
    const acknowledge = story.getByRole('button', { name: 'Acknowledge warning' });
    const cancel = story.getByRole('button', { name: 'Cancel selected job' });

    await expect(refresh).toHaveAccessibleName('Refresh jobs');
    await expect(refresh).toHaveAttribute('data-obpt-tooltip-text', 'Refresh the job list');
    await expect(acknowledge).toHaveAccessibleName('Acknowledge warning');
    await expect(cancel).toHaveAccessibleName('Cancel selected job');
    await expect(cancel).toHaveAttribute('aria-disabled', 'true');
  });

  for (const theme of themes) {
    test(`primitive interactive controls have visible keyboard focus in ${theme}`, async ({
      page
    }, testInfo) => {
      const buttonStory = await preparePrimitiveStory(
        page,
        testInfo.project.name,
        primitiveStory('primitive-button-matrix'),
        theme
      );
      const iconStory = targetLocator(page, primitiveStory('primitive-icon-button-accessible-names'));
      const metadataStory = targetLocator(page, primitiveStory('primitive-link-badge-tag-status'));
      const tooltipStory = targetLocator(page, primitiveStory('primitive-tooltip-open'));

      const retryButton = buttonStory.getByRole('button', { name: 'Retry job' });
      const refreshButton = iconStory.getByRole('button', { name: 'Refresh jobs' });
      const auditLink = metadataStory.getByRole('link', { name: 'View audit log' });
      const tooltipTrigger = tooltipStory.locator('[data-obpt-tooltip-trigger]');

      await tabUntilFocused(page, retryButton, 'Retry job button');
      await expectVisibleFocus(retryButton, 'Retry job button');

      await tabUntilFocused(page, refreshButton, 'Refresh jobs icon button');
      await expectVisibleFocus(refreshButton, 'Refresh jobs icon button');

      await tabUntilFocused(page, auditLink, 'View audit log link');
      await expectVisibleFocus(auditLink, 'View audit log link');

      await tabUntilFocused(page, tooltipTrigger, 'Retry job tooltip trigger');
      await expectVisibleFocus(tooltipTrigger, 'Retry job tooltip trigger');
    });
  }

  test('primitive tooltip opens on focus and hover, dismisses on Escape, and keeps focus', async ({
    page
  }, testInfo) => {
    const story = await preparePrimitiveStory(
      page,
      testInfo.project.name,
      primitiveStory('primitive-tooltip-open')
    );
    const tooltip = story.locator('[data-obpt-tooltip]');
    const trigger = tooltip.locator('[data-obpt-tooltip-trigger]');
    const content = tooltip.getByRole('tooltip');

    await tooltip.evaluate((element) => {
      element.removeAttribute('data-obpt-tooltip-open');
      element.removeAttribute('data-obpt-tooltip-dismissed');
    });

    await trigger.focus();
    await expect(content).toBeVisible();
    await expect(tooltip).toHaveAttribute('data-obpt-tooltip-open', 'true');

    await page.keyboard.press('Escape');
    await expect(content).toBeHidden();
    await expect(trigger).toBeFocused();
    await expect(tooltip).toHaveAttribute('data-obpt-tooltip-dismissed', 'true');

    await trigger.hover();
    await expect(content).toBeVisible();
    await expect(tooltip).not.toHaveAttribute('data-obpt-tooltip-dismissed', 'true');
  });

  test('primitive showcase content does not create horizontal page overflow', async ({
    page
  }, testInfo) => {
    await preparePrimitiveStory(
      page,
      testInfo.project.name,
      primitiveStory('primitive-button-matrix')
    );

    const overflow = await page.evaluate(() => ({
      body: document.body.scrollWidth - document.body.clientWidth,
      document: document.documentElement.scrollWidth - document.documentElement.clientWidth
    }));

    expect(overflow.document, 'document should not overflow horizontally').toBeLessThanOrEqual(1);
    expect(overflow.body, 'body should not overflow horizontally').toBeLessThanOrEqual(1);
  });

  test('primitive reduced-motion loading states remain visible without animation', async ({
    page
  }, testInfo) => {
    const story = await preparePrimitiveStory(
      page,
      testInfo.project.name,
      primitiveStory('primitive-spinner-skeleton-loading')
    );
    const root = page.locator('.obpt-root');
    const spinner = story.getByRole('status', { name: 'Loading job history' });
    const skeleton = story.getByRole('status', { name: 'Loading retryable job table' });

    await expect(root).toHaveAttribute('data-obpt-motion', 'reduce');
    await expect(spinner).toBeVisible();
    await expect(skeleton).toBeVisible();
    await expect(story.locator('.obpt-spinner-mark')).toBeVisible();
    await expect(story.locator('[data-obpt-skeleton-line]').first()).toBeVisible();

    const animations = await story.evaluate((element) => {
      const spinnerMark = element.querySelector('.obpt-spinner-mark');
      const skeletonLine = element.querySelector('[data-obpt-skeleton-line]');

      return {
        skeleton: skeletonLine ? window.getComputedStyle(skeletonLine).animationName : null,
        spinner: spinnerMark ? window.getComputedStyle(spinnerMark).animationName : null
      };
    });

    expect(animations.spinner).toBe('none');
    expect(animations.skeleton).toBe('none');
  });
});
