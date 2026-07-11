import { expect, test } from '@playwright/test';
import { targets, themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { assertNoCriticalOrSerious, runAxeForTarget, writeAxeResult } from '../support/axe';
import { prepareShowcase, targetLocator } from '../support/showcase';

for (const theme of themes) {
  test.describe(`showcase axe ${theme}`, () => {
    for (const target of targets) {
      test(`${target.kind} ${target.id}`, async ({ page }, testInfo) => {
        const viewportName = viewportNameFromProject(testInfo.project.name);
        const resultName = `${theme}-${target.kind}-${target.id}`;

        await prepareShowcase(page, { theme, viewportName });
        await expect(targetLocator(page, target)).toBeVisible();

        const results = await runAxeForTarget(page, target.a11y);
        await writeAxeResult(testInfo, resultName, results);
        assertNoCriticalOrSerious(results, resultName);
      });
    }
  });
}
