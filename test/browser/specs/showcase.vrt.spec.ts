import { expect, test } from "@playwright/test";
import { targets, themes } from "../support/manifest";
import { viewportNameFromProject } from "../support/deterministic";
import {
  activateTarget,
  prepareShowcase,
  visualTargetLocator,
} from "../support/showcase";

test.setTimeout(90_000);

const vrtTargets =
  process.env.PAGE_QUALITY_ONLY === "1"
    ? targets.filter((target) => target.kind === "page")
    : targets;

for (const theme of themes) {
  test.describe(`showcase vrt ${theme}`, () => {
    for (const target of vrtTargets) {
      test(`${target.kind} ${target.id}`, async ({ page }, testInfo) => {
        const viewportName = viewportNameFromProject(testInfo.project.name);

        await prepareShowcase(page, { theme, viewportName });
        const story = await activateTarget(page, target);
        await expect(story).toBeVisible();
        const visualTarget = await visualTargetLocator(story, target);

        if (
          (target.kind === "group" && target.activation === "overlay") ||
          (target.kind === "page" && target.activation !== "none")
        ) {
          await expect(visualTarget.getByRole("heading").first()).toBeVisible();

          if (target.components.includes("confirm_action_dialog")) {
            const action = visualTarget
              .locator(".obpt-confirm-action__actions .obpt-button")
              .first();
            await expect(action).toBeVisible();
          }

          if (target.components.includes("detail_surface")) {
            await expect(
              visualTarget.locator("[data-obpt-detail-close]"),
            ).toBeVisible();
          }
        }

        await expect(visualTarget).toHaveScreenshot(
          [target.snapshot, `${theme}.png`],
          {
            timeout: 45_000,
          },
        );
      });
    }
  });
}
