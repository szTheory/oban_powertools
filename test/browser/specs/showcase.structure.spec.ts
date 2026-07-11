import { expect, test } from '@playwright/test';
import { targets, themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { assertShowcaseStructure, prepareShowcase, targetLocator } from '../support/showcase';

for (const theme of themes) {
  test(`showcase structure is stable for ${theme}`, async ({ page }, testInfo) => {
    const viewportName = viewportNameFromProject(testInfo.project.name);

    await prepareShowcase(page, { theme, viewportName });
    await assertShowcaseStructure(page);

    for (const target of targets) {
      await expect(targetLocator(page, target)).toBeVisible();
    }
  });
}
