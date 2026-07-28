import { expect } from "@playwright/test";
import { voiceOverTest as test } from "@guidepup/playwright";
import {
  pageStories,
  type ShowcasePageStory,
} from "../support/manifest";
import {
  activateTarget,
  prepareShowcase,
} from "../support/showcase";

test.use({ voiceOverStartOptions: { capture: true } });

const voiceOverStories = [
  storyById("page-overview-fixed-order-nonzero"),
  storyById("page-cron-pause-confirmation"),
  storyById("page-cron-expired-recovery"),
  storyById("page-limiters-blocked-evidence-layers"),
  storyById("page-audit-selected-missing-fields"),
  storyById("page-jobs-full-detail"),
  storyById("page-forensics-incident-partial-remediation"),
];

async function isolateAccessibleStage(
  stage: import("@playwright/test").Locator,
): Promise<void> {
  await stage.evaluate((activeStage) => {
    let branch: Element = activeStage;

    while (branch.parentElement) {
      const parent = branch.parentElement;
      for (const sibling of parent.children) {
        if (sibling !== branch) sibling.setAttribute("aria-hidden", "true");
      }
      branch = parent;
    }
  });
}

for (const pageStory of voiceOverStories) {
  test(`${pageStory.id} ${pageStory.name} exposes truthful VoiceOver navigation`, async ({
    page,
    voiceOver,
  }, testInfo) => {
    await prepareShowcase(page, {
      theme: "system",
      viewportName: "wide",
    });
    const storyRoot = await activateTarget(page, pageStory);
    const stage = storyRoot.locator(
      `[data-obpt-page-story-stage="${pageStory.id}"]`,
    );
    await expect(stage).toBeVisible();
    await isolateAccessibleStage(stage);

    await voiceOver.navigateToWebContent();

    for (let index = 0; index < 40; index += 1) {
      await voiceOver.next();
    }

    const spokenPhrases = await voiceOver.spokenPhraseLog();
    const itemText = await voiceOver.itemTextLog();
    const transcript = [...spokenPhrases, ...itemText].join("\n");
    const requiredRole = pageStory.acceptance.roles.find(
      (contract) => contract.role === "dialog",
    ) ?? pageStory.acceptance.roles[0];

    expect(
      transcript,
      `VoiceOver transcript must announce ${requiredRole.role} ${requiredRole.name}`,
    ).toContain(requiredRole.name);

    const announcedTruth = pageStory.acceptance.required_text.some((copy) =>
      transcript.includes(copy),
    );
    expect(
      announcedTruth,
      "VoiceOver transcript must contain at least one story acceptance truth",
    ).toBe(true);

    await testInfo.attach(`${pageStory.id}-voiceover-transcript`, {
      body: Buffer.from(
        JSON.stringify(
          {
            story: pageStory.id,
            spokenPhrases,
            itemText,
          },
          null,
          2,
        ),
      ),
      contentType: "application/json",
    });

    const cursorScreenshot = await voiceOver.takeCursorScreenshot();
    await testInfo.attach(`${pageStory.id}-voiceover-cursor`, {
      path: cursorScreenshot,
      contentType: "image/png",
    });
  });
}
