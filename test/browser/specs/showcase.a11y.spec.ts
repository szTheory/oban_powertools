import { expect, test } from '@playwright/test';
import { scenarios, themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { assertNoCriticalOrSerious, runAxeForTarget, writeAxeResult } from '../support/axe';
import { prepareShowcase, storyLocator } from '../support/showcase';

for (const theme of themes) {
  test.describe(`showcase axe ${theme}`, () => {
    for (const scenario of scenarios) {
      test(`${scenario.id}`, async ({ page }, testInfo) => {
        const viewportName = viewportNameFromProject(testInfo.project.name);
        const resultName = `${theme}-${scenario.id}`;

        await prepareShowcase(page, { theme, viewportName });
        await expect(storyLocator(page, scenario)).toBeVisible();

        const results = await runAxeForTarget(page, scenario.a11y);
        await writeAxeResult(testInfo, resultName, results);
        assertNoCriticalOrSerious(results, resultName);
      });
    }
  });
}
