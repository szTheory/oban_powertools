import { expect, test, type Locator, type Page } from '@playwright/test';
import {
  shellStories,
  themes,
  type ShowcaseShellStory,
  type ShowcaseTheme,
  type ViewportName
} from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { prepareShowcase, targetLocator } from '../support/showcase';

const navLabels = [
  'Overview',
  'Jobs',
  'Batches',
  'Workflows',
  'Cron',
  'Limiters',
  'Lifeline',
  'Audit',
  'Forensics'
];

if (!Array.isArray(shellStories)) {
  throw new Error('Missing shellStories export in generated showcase manifest support');
}

function shellStory(id: string): ShowcaseShellStory {
  const story = shellStories.find((candidate) => candidate.id === id);

  if (!story) {
    throw new Error(`Missing shell story in generated manifest: ${id}`);
  }

  return story;
}

async function prepareShellStory(
  page: Page,
  projectName: string,
  story: ShowcaseShellStory,
  theme: ShowcaseTheme = 'light',
  viewportName: ViewportName = viewportNameFromProject(projectName)
): Promise<Locator> {
  await prepareShowcase(page, { theme, viewportName });

  const locator = targetLocator(page, story);
  await expect(locator).toBeVisible();
  await expect(locator.locator('[data-obpt-app-shell]')).toHaveCount(1);

  return locator;
}

async function tabUntilFocused(page: Page, locator: Locator, label: string): Promise<void> {
  await expect(locator).toBeVisible();

  for (let index = 0; index < 100; index += 1) {
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

async function focusBefore(locator: Locator, label: string): Promise<void> {
  await locator.evaluate((element, sentinelLabel) => {
    const sentinel = document.createElement('button');
    sentinel.type = 'button';
    sentinel.textContent = sentinelLabel;
    sentinel.setAttribute('data-obpt-test-focus-sentinel', sentinelLabel);
    element.parentElement?.insertBefore(sentinel, element);
    sentinel.focus();
  }, label);
}

async function expectNoFocusedNavItem(story: Locator, label: string): Promise<void> {
  const navItemFocused = await story.locator('[data-obpt-nav-item]').evaluateAll((elements) =>
    elements.some((element) => element === document.activeElement)
  );

  expect(navItemFocused, `${label} should not focus a collapsed nav item`).toBe(false);
}

async function openShellNav(story: Locator): Promise<Locator> {
  const nav = story.locator('[data-obpt-primary-nav]');
  const toggle = story.getByRole('button', { name: 'Navigation' });

  if (!(await nav.isVisible()) && (await toggle.isVisible())) {
    await toggle.click();
  }

  const roleNav = story.getByRole('navigation', { name: 'Powertools surfaces' });
  await expect(roleNav).toBeVisible();
  return roleNav;
}

function isMobileProject(projectName: string): boolean {
  return viewportNameFromProject(projectName) === '320';
}

test.describe('shell behavior contracts', () => {
  test('primary nav exposes exactly the nine native surfaces in canonical order', async ({
    page
  }, testInfo) => {
    const story = await prepareShellStory(
      page,
      testInfo.project.name,
      shellStory('shell-nine-surface-nav')
    );
    const nav = await openShellNav(story);
    const links = nav.locator('[data-obpt-nav-item]');

    await expect(nav).toBeVisible();
    await expect(links).toHaveCount(9);
    await expect(links).toHaveText(navLabels);
    await expect(nav.getByRole('link', { name: 'Overview' })).toHaveAttribute(
      'href',
      /\/ops\/jobs$/
    );
    await expect(nav.getByRole('link', { name: 'Jobs' })).toHaveAttribute(
      'href',
      /\/ops\/jobs\/jobs$/
    );
    await expect(nav.getByRole('link', { name: 'Forensics' })).toHaveAttribute(
      'href',
      /\/ops\/jobs\/forensics$/
    );
    await expect(nav.getByRole('link', { name: /Oban Web/i })).toHaveCount(0);
    await expect(nav.locator('a[href*="/ops/jobs/oban"]')).toHaveCount(0);
  });

  test('active route and breadcrumb are server-rendered with aria-current', async ({
    page
  }, testInfo) => {
    const story = await prepareShellStory(
      page,
      testInfo.project.name,
      shellStory('shell-active-breadcrumb')
    );
    const nav = await openShellNav(story);
    const breadcrumb = story.getByRole('navigation', { name: 'Breadcrumb' });

    await expect(nav.getByRole('link', { name: 'Jobs' })).toHaveAttribute(
      'aria-current',
      'page'
    );
    await expect(
      targetLocator(page, shellStory('shell-mobile-expanded')).getByRole('link', { name: 'Jobs' })
    ).toHaveAttribute('aria-current', 'page');
    await expect(story.locator('[data-obpt-nav-item][aria-current="page"]')).toHaveCount(1);
    await expect(breadcrumb.locator('[data-obpt-breadcrumb="root"]')).toContainText('Overview');
    await expect(breadcrumb.locator('[data-obpt-breadcrumb="current"]')).toHaveAttribute(
      'aria-current',
      'page'
    );
    await expect(breadcrumb.locator('[data-obpt-breadcrumb="current"]')).toContainText(
      'Job detail'
    );
  });

  test('skip link moves keyboard focus to main content', async ({ page }, testInfo) => {
    const story = await prepareShellStory(
      page,
      testInfo.project.name,
      shellStory('shell-nine-surface-nav')
    );
    const skip = story.getByRole('link', { name: 'Skip to main content' });
    const main = story.locator('main.obpt-shell-main');
    const mainId = await main.getAttribute('id');

    expect(mainId).toMatch(/^obpt-main/);
    await expect(skip).toHaveAttribute('href', `#${mainId}`);

    await focusBefore(story, 'before shell skip link');
    await page.keyboard.press('Tab');
    await expect(skip).toBeFocused();
    await skip.focus();
    await expectVisibleFocus(skip, 'skip link');
    await page.keyboard.press('Enter');
    await expect(main).toBeFocused();
  });

  test('mobile disclosure toggles with keyboard, click, and Escape closes from nav focus', async ({
    page
  }, testInfo) => {
    test.skip(!isMobileProject(testInfo.project.name), 'mobile disclosure is a chromium-320 proof');

    const story = await prepareShellStory(
      page,
      testInfo.project.name,
      shellStory('shell-mobile-collapsed'),
      'light',
      '320'
    );
    const shell = story.locator('[data-obpt-app-shell]');
    const toggle = story.getByRole('button', { name: 'Navigation' });
    const nav = story.locator('[data-obpt-primary-nav]');
    const navId = await nav.getAttribute('id');
    const jobs = nav.getByRole('link', { name: 'Jobs' });

    await expect(shell).toHaveAttribute('data-obpt-nav-state', 'closed');
    expect(navId).toMatch(/^obpt-primary-nav/);
    await expect(toggle).toHaveAttribute('aria-controls', navId as string);
    await expect(toggle).toHaveAttribute('aria-expanded', 'false');
    await expect(nav).toBeHidden();

    await toggle.focus();
    await page.keyboard.press('Enter');
    await expect(toggle).toHaveAttribute('aria-expanded', 'true');
    await expect(shell).toHaveAttribute('data-obpt-nav-state', 'open');
    await expect(nav).toBeVisible();

    await page.keyboard.press('Space');
    await expect(toggle).toHaveAttribute('aria-expanded', 'false');
    await expect(shell).toHaveAttribute('data-obpt-nav-state', 'closed');
    await expect(nav).toBeHidden();

    await toggle.click();
    await expect(toggle).toHaveAttribute('aria-expanded', 'true');
    await expect(shell).toHaveAttribute('data-obpt-nav-state', 'open');
    await expect(nav).toBeVisible();

    await jobs.focus();
    await expect(jobs).toBeFocused();
    await page.keyboard.press('Escape');
    await expect(toggle).toHaveAttribute('aria-expanded', 'false');
    await expect(toggle).toBeFocused();
    await expect(shell).toHaveAttribute('data-obpt-nav-state', 'closed');
    await expect(nav).toBeHidden();
  });

  test('closed mobile disclosure removes nav links from Tab order', async ({ page }, testInfo) => {
    test.skip(!isMobileProject(testInfo.project.name), 'closed mobile tab order is a chromium-320 proof');

    const story = await prepareShellStory(
      page,
      testInfo.project.name,
      shellStory('shell-mobile-collapsed'),
      'light',
      '320'
    );
    const toggle = story.getByRole('button', { name: 'Navigation' });
    const nav = story.locator('[data-obpt-primary-nav]');

    await expect(nav).toBeHidden();
    await toggle.focus();

    for (let index = 0; index < navLabels.length + 4; index += 1) {
      await page.keyboard.press('Tab');
      await expectNoFocusedNavItem(story, 'closed mobile disclosure');
    }
  });

  test('expanded mobile story starts open and exposes reachable nav links', async ({
    page
  }, testInfo) => {
    test.skip(!isMobileProject(testInfo.project.name), 'expanded mobile nav is a chromium-320 proof');

    const story = await prepareShellStory(
      page,
      testInfo.project.name,
      shellStory('shell-mobile-expanded'),
      'light',
      '320'
    );
    const shell = story.locator('[data-obpt-app-shell]');
    const toggle = story.getByRole('button', { name: 'Navigation' });
    const jobs = story.getByRole('link', { name: 'Jobs' });

    await expect(shell).toHaveAttribute('data-obpt-nav-state', 'open');
    await expect(toggle).toHaveAttribute('aria-expanded', 'true');
    await tabUntilFocused(page, jobs, 'Jobs nav link');
    await expectVisibleFocus(jobs, 'Jobs nav link');
  });

  test('theme controls update scoped root state without host theme mutation', async ({
    page
  }, testInfo) => {
    const story = await prepareShellStory(
      page,
      testInfo.project.name,
      shellStory('shell-theme-actor-context'),
      'high-contrast'
    );
    const root = page.locator('.obpt-root');
    const highContrast = story.getByRole('button', { name: 'High contrast' });
    const light = story.getByRole('button', { name: 'Light' });

    await expect(root).toHaveAttribute('data-obpt-theme', 'high-contrast');
    await expect(highContrast).toHaveAttribute('data-obpt-theme-choice', 'high-contrast');
    await expect(highContrast).toHaveAttribute('aria-pressed', 'true');

    await light.click();
    await expect(root).toHaveAttribute('data-obpt-theme', 'light');
    await expect(light).toHaveAttribute('aria-pressed', 'true');
    await expect(highContrast).toHaveAttribute('aria-pressed', 'false');
    await expect(page.locator('html')).not.toHaveClass(/dark|high-contrast|obpt/);
    await expect(page.locator('html')).not.toHaveAttribute('data-obpt-theme', /.+/);
    await expect(story.getByText(/Actor:/)).toBeVisible();
  });

  for (const theme of themes) {
    test(`shell interactive controls expose visible keyboard focus in ${theme}`, async ({
      page
    }, testInfo) => {
      const story = await prepareShellStory(
        page,
        testInfo.project.name,
        shellStory('shell-nine-surface-nav'),
        theme
      );
      const toggle = story.getByRole('button', { name: 'Navigation' });
      const nav = story.locator('[data-obpt-primary-nav]');
      const jobs = story.getByRole('link', { name: 'Jobs' });
      const themeButton = story.getByRole('button', { name: 'System' });
      const skip = story.getByRole('link', { name: 'Skip to main content' });

      await focusBefore(story, `before shell skip link in ${theme}`);
      await page.keyboard.press('Tab');
      await expectVisibleFocus(skip, `skip link in ${theme}`);

      if (await toggle.isVisible()) {
        await tabUntilFocused(page, toggle, `Navigation toggle in ${theme}`);
        await expectVisibleFocus(toggle, `Navigation toggle in ${theme}`);

        await page.keyboard.press('Enter');
      }

      await expect(nav).toBeVisible();

      await tabUntilFocused(page, jobs, `Jobs nav link in ${theme}`);
      await expectVisibleFocus(jobs, `Jobs nav link in ${theme}`);

      await tabUntilFocused(page, themeButton, `System theme button in ${theme}`);
      await expectVisibleFocus(themeButton, `System theme button in ${theme}`);
    });
  }

  test('shell stories and page do not overflow horizontally at 320px', async ({
    page
  }, testInfo) => {
    test.skip(!isMobileProject(testInfo.project.name), '320px overflow is a chromium-320 proof');

    await prepareShellStory(
      page,
      testInfo.project.name,
      shellStory('shell-long-context-wrapping'),
      'light',
      '320'
    );

    const overflow = await page.evaluate(() => ({
      body: document.body.scrollWidth - document.body.clientWidth,
      document: document.documentElement.scrollWidth - document.documentElement.clientWidth,
      stories: Array.from(document.querySelectorAll('[data-obpt-shell-story]')).map(
        (element) => element.scrollWidth - element.clientWidth
      )
    }));

    expect(overflow.document).toBeLessThanOrEqual(1);
    expect(overflow.body).toBeLessThanOrEqual(1);
    expect(Math.max(...overflow.stories)).toBeLessThanOrEqual(1);
  });
});
