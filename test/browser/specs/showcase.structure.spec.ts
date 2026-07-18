import { test } from '@playwright/test';
import { themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { assertShowcaseStructure, prepareShowcase } from '../support/showcase';

for (const theme of themes) {
  test(`showcase structure is stable for ${theme} across scenario primitive form shell data and group targets`, async ({
    page
  }, testInfo) => {
    const viewportName = viewportNameFromProject(testInfo.project.name);

    await prepareShowcase(page, { theme, viewportName });
    await assertShowcaseStructure(page);
  });
}
