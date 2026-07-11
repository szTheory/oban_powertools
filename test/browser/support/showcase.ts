import { expect, type Locator, type Page } from '@playwright/test';
import {
  targets,
  themes,
  viewports,
  type ShowcaseScenario,
  type ShowcaseTarget,
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
  return targetLocator(page, { kind: 'scenario', ...scenario });
}

export function targetLocator(page: Page, target: ShowcaseTarget): Locator {
  return page.locator(target.a11y);
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

  for (const target of targets) {
    const story = targetLocator(page, target);

    await expect(story).toHaveCount(1);
    await expect(story).toHaveAttribute('id', target.story);

    if (target.kind === 'scenario') {
      await expect(story).toHaveAttribute('data-obpt-domain', target.domain);
      await expect(story).toHaveAttribute('data-obpt-persona', renderedPersona(target));
      await expect(story).toHaveAttribute('data-obpt-state', /.+/);
    } else {
      await expect(story).toHaveAttribute('data-obpt-component', target.components.join(' '));
      await expect(story).toHaveAttribute('data-obpt-variant', target.variant.join(' '));
      await expect(story).toHaveAttribute('data-obpt-state', target.state.join(' '));
      await expect(story).toHaveAttribute('data-obpt-a11y-target', target.a11y);
    }
  }
}

function renderedPersona(scenario: ShowcaseScenario): string {
  return scenario.id === 'forensics-long-url-stacktrace' ? 'repair' : scenario.persona;
}
