import { expect, test } from '@playwright/test';
import { scenarios, themes } from '../support/manifest';
import { viewportNameFromProject } from '../support/deterministic';
import { assertShowcaseStructure, prepareShowcase, storyLocator } from '../support/showcase';

function renderedPersona(scenario: (typeof scenarios)[number]): string {
  return scenario.id === 'forensics-long-url-stacktrace' ? 'repair' : scenario.persona;
}

for (const theme of themes) {
  test(`showcase structure is stable for ${theme}`, async ({ page }, testInfo) => {
    const viewportName = viewportNameFromProject(testInfo.project.name);

    await prepareShowcase(page, { theme, viewportName });
    await assertShowcaseStructure(page);

    for (const scenario of scenarios) {
      const story = storyLocator(page, scenario);

      await expect(story).toBeVisible();
      await expect(story).toHaveAttribute('id', scenario.story);
      await expect(story).toHaveAttribute('data-obpt-domain', scenario.domain);
      await expect(story).toHaveAttribute('data-obpt-persona', renderedPersona(scenario));
      await expect(story).toHaveAttribute('data-obpt-state', /.+/);
    }
  });
}
