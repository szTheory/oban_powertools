import { expect, test } from '@playwright/test';
import { scenarios, themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { prepareShowcase, storyLocator } from '../support/showcase';

for (const theme of themes) {
  test.describe(`showcase vrt ${theme}`, () => {
    for (const scenario of scenarios) {
      test(`${scenario.id}`, async ({ page }, testInfo) => {
        const viewportName = viewportNameFromProject(testInfo.project.name);
        const story = storyLocator(page, scenario);

        await prepareShowcase(page, { theme, viewportName });
        await expect(story).toBeVisible();
        await expect(story).toHaveScreenshot([scenario.snapshot, `${theme}.png`]);
      });
    }
  });
}
