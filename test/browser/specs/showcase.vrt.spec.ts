import { expect, test } from '@playwright/test';
import { targets, themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { prepareShowcase, targetLocator } from '../support/showcase';

for (const theme of themes) {
  test.describe(`showcase vrt ${theme}`, () => {
    for (const target of targets) {
      test(`${target.kind} ${target.id}`, async ({ page }, testInfo) => {
        const viewportName = viewportNameFromProject(testInfo.project.name);
        const story = targetLocator(page, target);

        await prepareShowcase(page, { theme, viewportName });
        await expect(story).toBeVisible();
        await expect(story).toHaveScreenshot([target.snapshot, `${theme}.png`]);
      });
    }
  });
}
