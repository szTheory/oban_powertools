import { expect, test } from '@playwright/test';
import { targets, themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { activateTarget, prepareShowcase } from '../support/showcase';

for (const theme of themes) {
  test.describe(`showcase vrt ${theme}`, () => {
    for (const target of targets) {
      test(`${target.kind} ${target.id}`, async ({ page }, testInfo) => {
        const viewportName = viewportNameFromProject(testInfo.project.name);

        await prepareShowcase(page, { theme, viewportName });
        const story = await activateTarget(page, target);
        await expect(story).toBeVisible();
        await expect(story).toHaveScreenshot([target.snapshot, `${theme}.png`], {
          timeout: 15_000
        });
      });
    }
  });
}
