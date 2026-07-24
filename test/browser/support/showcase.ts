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
  'app-shell',
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
  await expect(page.locator('[data-phx-main].phx-connected')).toHaveCount(1);

  const viewportControl = page.locator(`[data-obpt-viewport="${opts.viewportName}"]`);
  await expect(viewportControl).toHaveCount(1);
  await viewportControl.click();
  await expect(viewportControl).toHaveClass(/obpt-button--primary/);

  const themeApplied = await page.evaluate((theme) => {
    if (window.ObanPowertoolsTheme?.setTheme) {
      window.ObanPowertoolsTheme.setTheme(theme);
      return true;
    }

    return false;
  }, opts.theme);

  if (!themeApplied) {
    await page
      .locator(
        `[data-obpt-showcase] [data-obpt-theme-controls] [data-obpt-theme-choice="${opts.theme}"]`
      )
      .click();
  }

  await expect(root).toHaveAttribute('data-obpt-theme', opts.theme);
  await expect(root).toHaveAttribute(
    'data-obpt-effective-theme',
    opts.theme === 'system' ? 'light' : opts.theme
  );

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

export async function activateTarget(page: Page, target: ShowcaseTarget): Promise<Locator> {
  await expect(page.locator('[data-phx-main].phx-connected')).toHaveCount(1);

  const story = targetLocator(page, target);

  if (target.kind === 'page') {
    const root = page.locator('.obpt-root');
    const requestedTheme = (await root.getAttribute('data-obpt-theme')) ?? 'system';

    const stage = story.locator(`[data-obpt-page-story-stage="${target.id}"]`);
    const trigger = story.locator(
      `[phx-click="activate-page-story"][phx-value-id="${target.id}"]`
    );

    await expect(trigger).toHaveCount(1);
    await trigger.dispatchEvent('click');
    await expect(story).toHaveAttribute('data-obpt-page-active', 'true');
    await expect(stage).toHaveAttribute('data-obpt-page-active', 'true');
    await expect(stage).toHaveCount(1);
    await expect(stage).toBeVisible();
    await expect(page.locator('[data-obpt-page-story][data-obpt-page-active="true"]')).toHaveCount(
      1
    );

    const themeRestored = await page.evaluate((theme) => {
      if (!window.ObanPowertoolsTheme?.setTheme) {
        return false;
      }

      window.ObanPowertoolsTheme.setTheme(theme);
      return true;
    }, requestedTheme);

    expect(themeRestored).toBe(true);
    await expect(root).toHaveAttribute('data-obpt-theme', requestedTheme);

    const pageDialog = story.locator('[role="dialog"], dialog[open]');
    const expectedOverlayCount = target.activation === 'none' ? 0 : 1;
    await expect(pageDialog).toHaveCount(expectedOverlayCount);

    if (expectedOverlayCount === 1) {
      await expect(pageDialog.first()).toBeVisible();
    }

    const activeOverlayCount = await page
      .locator(
        '[data-obpt-group-story][data-obpt-overlay-active="true"], [data-obpt-page-story][data-obpt-page-active="true"] [role="dialog"], [data-obpt-page-story][data-obpt-page-active="true"] dialog[open]'
      )
      .count();
    expect(activeOverlayCount).toBeLessThanOrEqual(1);

    const dialogCount = await page
      .locator(
        '[data-obpt-group-story] [role="dialog"], [data-obpt-group-story] dialog[open], [data-obpt-page-story] [role="dialog"], [data-obpt-page-story] dialog[open]'
      )
      .count();
    expect(dialogCount).toBeLessThanOrEqual(1);

    const modalCount = await page
      .locator(
        '[data-obpt-group-story] [role="dialog"][aria-modal="true"], [data-obpt-group-story] dialog[open], [data-obpt-page-story] [role="dialog"][aria-modal="true"], [data-obpt-page-story] dialog[open]'
      )
      .count();
    expect(modalCount).toBeLessThanOrEqual(1);

    return story;
  }

  if (target.kind !== 'group' || target.activation === 'none') {
    return story;
  }

  const stage = story.locator(`[data-obpt-group-story-stage="${target.id}"]`);
  const trigger = story.locator(`[phx-click="activate-group-story"][phx-value-id="${target.id}"]`);

  await expect(trigger).toHaveCount(1);
  await trigger.dispatchEvent('click');
  await expect(story).toHaveAttribute('data-obpt-overlay-active', 'true');
  await expect(stage).toHaveAttribute('data-obpt-overlay-active', 'true');
  await expect(stage).toHaveCount(1);

  const storyDialog = story.locator('[role="dialog"], dialog[open]');
  if ((await storyDialog.count()) > 0) {
    await expect(storyDialog.first()).toBeVisible();
  } else {
    await expect(stage).toBeVisible();
  }

  await expect(
    page.locator('[data-obpt-group-story][data-obpt-overlay-active="true"]')
  ).toHaveCount(1);

  const modalCount = await page
    .locator(
      '[data-obpt-group-story] [role="dialog"][aria-modal="true"], [data-obpt-group-story] dialog[open]'
    )
    .count();
  expect(modalCount).toBeLessThanOrEqual(1);

  return story;
}

export async function visualTargetLocator(
  story: Locator,
  target: ShowcaseTarget
): Promise<Locator> {
  if (
    (target.kind !== 'group' && target.kind !== 'page') ||
    target.activation === 'none'
  ) {
    return story;
  }

  const overlay = story.locator(
    '[data-obpt-confirm-state][role="dialog"], dialog[data-obpt-detail-surface][open]'
  );

  await expect(overlay).toHaveCount(1);
  await expect(overlay).toBeVisible();

  return overlay;
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
    await expect(
      page.locator(
        `[data-obpt-showcase] [data-obpt-theme-controls] [data-obpt-theme-choice="${theme}"]`
      )
    ).toHaveCount(1);
  }

  for (const viewport of viewports) {
    await expect(page.locator(`[data-obpt-viewport="${viewport.name}"]`)).toHaveCount(1);
  }

  for (const sectionId of sectionIds) {
    await expect(page.locator(`[data-obpt-section="${sectionId}"]`)).toHaveCount(1);
    await expect(page.locator(`a[href="#${sectionId}"]`)).toHaveCount(1);
  }

  const groupTargets = targets.filter((target) => target.kind === 'group');
  const pageTargets = targets.filter((target) => target.kind === 'page');
  const targetIds = targets.map((target) => target.story);

  expect(new Set(targetIds).size).toBe(targetIds.length);
  await expect(page.locator('[data-obpt-group-story]')).toHaveCount(groupTargets.length);
  await expect(page.locator('[data-obpt-page-story]')).toHaveCount(pageTargets.length);
  await expect(
    page.locator('[data-obpt-group-story][data-obpt-overlay-active="true"]')
  ).toHaveCount(0);
  await expect(page.locator('[data-obpt-page-story][data-obpt-page-active="true"]')).toHaveCount(
    0
  );

  for (const target of targets) {
    const story = await activateTarget(page, target);

    await expect(story).toHaveCount(1);
    await expect(story).toBeVisible();
    await expect(story).toHaveAttribute('id', target.story);

    if (target.kind === 'scenario') {
      await expect(story).toHaveAttribute('data-obpt-domain', target.domain);
      await expect(story).toHaveAttribute('data-obpt-persona', target.persona);
      await expect(story).toHaveAttribute('data-obpt-state', /.+/);
    } else if (target.kind === 'primitive') {
      await expect(story).toHaveAttribute('data-obpt-primitive-story', target.id);
      await expect(story).toHaveAttribute('data-obpt-component', target.components.join(' '));
      await expect(story).toHaveAttribute('data-obpt-variant', target.variant.join(' '));
      await expect(story).toHaveAttribute('data-obpt-state', target.state.join(' '));
      await expect(story).toHaveAttribute('data-obpt-a11y-target', target.a11y);
    } else if (target.kind === 'form') {
      await expect(story).toHaveAttribute('data-obpt-form-story', target.id);
      await expect(story).toHaveAttribute('data-obpt-component', target.components.join(' '));
      await expect(story).toHaveAttribute('data-obpt-variant', target.variant.join(' '));
      await expect(story).toHaveAttribute('data-obpt-state', target.state.join(' '));
      await expect(story).toHaveAttribute('data-obpt-a11y-target', target.a11y);
    } else if (target.kind === 'data') {
      await expect(story).toHaveAttribute('data-obpt-data-story', target.id);
      await expect(story).toHaveAttribute('data-obpt-component', target.components.join(' '));
      await expect(story).toHaveAttribute('data-obpt-variant', target.variant.join(' '));
      await expect(story).toHaveAttribute('data-obpt-state', target.state.join(' '));
      await expect(story).toHaveAttribute('data-obpt-a11y-target', target.a11y);
    } else if (target.kind === 'group') {
      const active = target.activation === 'overlay' ? 'true' : 'false';
      const stage = story.locator(`[data-obpt-group-story-stage="${target.id}"]`);

      await expect(story).toHaveAttribute('data-obpt-group-story', target.id);
      await expect(story).toHaveAttribute('data-obpt-component', target.components.join(' '));
      await expect(story).toHaveAttribute('data-obpt-variant', target.variant.join(' '));
      await expect(story).toHaveAttribute('data-obpt-state', target.state.join(' '));
      await expect(story).toHaveAttribute('data-obpt-activation', target.activation);
      await expect(story).toHaveAttribute('data-obpt-overlay-active', active);
      await expect(story).toHaveAttribute('data-obpt-a11y-target', target.a11y);
      await expect(stage).toHaveCount(1);
      await expect(stage).toHaveAttribute('data-obpt-overlay-active', active);
      await expect(story.locator('[data-obpt-mobile-copy], [data-obpt-desktop-copy]')).toHaveCount(
        0
      );
    } else if (target.kind === 'page') {
      const stage = story.locator(`[data-obpt-page-story-stage="${target.id}"]`);

      await expect(story).toHaveAttribute('data-obpt-page-story', target.id);
      await expect(story).toHaveAttribute('data-obpt-page', target.page);
      await expect(story).toHaveAttribute('data-obpt-component', target.components.join(' '));
      await expect(story).toHaveAttribute('data-obpt-variant', target.variant.join(' '));
      await expect(story).toHaveAttribute('data-obpt-state', target.state.join(' '));
      await expect(story).toHaveAttribute('data-obpt-activation', target.activation);
      await expect(story).toHaveAttribute('data-obpt-page-active', 'true');
      await expect(story).toHaveAttribute('data-obpt-a11y-target', target.a11y);
      await expect(stage).toHaveCount(1);
      await expect(stage).toHaveAttribute('data-obpt-page-active', 'true');
      await expect(story.locator('[data-obpt-mobile-copy], [data-obpt-desktop-copy]')).toHaveCount(
        0
      );
    } else {
      await expect(story).toHaveAttribute('data-obpt-shell-story', target.id);
      await expect(story).toHaveAttribute('data-obpt-component', target.components.join(' '));
      await expect(story).toHaveAttribute('data-obpt-variant', target.variant.join(' '));
      await expect(story).toHaveAttribute('data-obpt-state', target.state.join(' '));
      await expect(story).toHaveAttribute('data-obpt-nav-state', target.nav_state);
      await expect(story).toHaveAttribute('data-obpt-a11y-target', target.a11y);
    }
  }
}
