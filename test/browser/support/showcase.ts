import { expect, type Locator, type Page } from '@playwright/test';
import {
  scenarios,
  themes,
  viewports,
  type ShowcaseScenario,
  type ShowcaseTheme,
  type ViewportName
} from './manifest';

declare global {
  interface Window {
    ObanPowertoolsTheme?: {
      setTheme: (theme: string) => void;
    };
  }
}

export const sectionIds = [
  'tokens',
  'primitives',
  'forms',
  'data-display',
  'operator-groups',
  'pages',
  'stress-fixtures'
] as const;

export async function prepareShowcase(
  page: Page,
  opts: { theme: ShowcaseTheme; viewportName: ViewportName }
): Promise<void> {
  await page.emulateMedia({ colorScheme: 'light', reducedMotion: 'reduce' });
  await page.goto('/ops/jobs/_showcase');

  const root = page.locator('.obpt-root');
  await expect(root).toHaveCount(1);

  const themeApplied = await page.evaluate((theme) => {
    if (window.ObanPowertoolsTheme?.setTheme) {
      window.ObanPowertoolsTheme.setTheme(theme);
      return true;
    }

    return false;
  }, opts.theme);

  if (!themeApplied) {
    await page.locator(`[data-obpt-theme-choice="${opts.theme}"]`).click();
  }

  await expect(root).toHaveAttribute('data-obpt-theme', opts.theme);
  await expect(root).toHaveAttribute(
    'data-obpt-effective-theme',
    opts.theme === 'system' ? 'light' : opts.theme
  );

  const viewportControl = page.locator(`[data-obpt-viewport="${opts.viewportName}"]`);
  await expect(viewportControl).toHaveCount(1);
  await viewportControl.click();

  const expectedViewport = viewports.find((viewport) => viewport.name === opts.viewportName);
  const actualViewport = page.viewportSize();

  expect(actualViewport?.width).toBe(expectedViewport?.width);
  expect(actualViewport?.height).toBe(expectedViewport?.height);

  await page.waitForLoadState('networkidle');
  await page.evaluate(() => document.fonts.ready);
}

export function storyLocator(page: Page, scenario: ShowcaseScenario): Locator {
  return page.locator(scenario.a11y);
}

export async function assertShowcaseStructure(page: Page): Promise<void> {
  await expect(page.locator('.obpt-root')).toHaveCount(1);
  await expect(page.locator('[data-obpt-showcase]')).toHaveCount(1);

  const cssHref = await page
    .locator('link[rel="stylesheet"][href*="/ops/jobs/_assets/oban_powertools-"]')
    .getAttribute('href');
  expect(cssHref).toMatch(/\/ops\/jobs\/_assets\/oban_powertools-[a-f0-9]{32}\.css$/);

  const scriptSrc = await page
    .locator('script[src*="/ops/jobs/_assets/oban_powertools-"]')
    .getAttribute('src');
  expect(scriptSrc).toMatch(/\/ops\/jobs\/_assets\/oban_powertools-[a-f0-9]{32}\.js$/);

  for (const theme of themes) {
    await expect(page.locator(`[data-obpt-theme-choice="${theme}"]`)).toHaveCount(1);
  }

  for (const viewport of viewports) {
    await expect(page.locator(`[data-obpt-viewport="${viewport.name}"]`)).toHaveCount(1);
  }

  for (const sectionId of sectionIds) {
    await expect(page.locator(`[data-obpt-section="${sectionId}"]`)).toHaveCount(1);
    await expect(page.locator(`a[href="#${sectionId}"]`)).toHaveCount(1);
  }

  for (const scenario of scenarios) {
    await expect(storyLocator(page, scenario)).toHaveCount(1);
  }
}
