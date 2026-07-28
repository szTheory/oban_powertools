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

const voiceOverStoryIds = [
  "page-overview-fixed-order-nonzero",
  "page-cron-pause-confirmation",
  "page-cron-expired-recovery",
  "page-limiters-blocked-evidence-layers",
  "page-audit-selected-missing-fields",
  "page-jobs-full-detail",
  "page-forensics-incident-partial-remediation",
] as const;

type VoiceOverStoryId = (typeof voiceOverStoryIds)[number];
type VoiceOverPageStory = ShowcasePageStory & { id: VoiceOverStoryId };

function storyById(id: VoiceOverStoryId): VoiceOverPageStory {
  const match = pageStories.find((candidate) => candidate.id === id);

  if (!match) {
    throw new Error(`missing exact VoiceOver page story ${id}`);
  }

  return match as VoiceOverPageStory;
}

const voiceOverStories = [
  ...voiceOverStoryIds.map(storyById),
];

const requiredTranscriptText: Readonly<
  Record<VoiceOverStoryId, readonly string[]>
> = {
  "page-overview-fixed-order-nonzero": [],
  "page-cron-pause-confirmation": [],
  "page-cron-expired-recovery": [],
  "page-limiters-blocked-evidence-layers": [],
  "page-audit-selected-missing-fields": [],
  "page-jobs-full-detail": ["Back to Jobs"],
  "page-forensics-incident-partial-remediation": [
    "Investigation summary",
    "Event log",
  ],
};

const maxTraversalSteps = 240;

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

    const requiredRole = pageStory.acceptance.roles.find(
      (contract) => contract.role === "dialog",
    ) ?? pageStory.acceptance.roles[0];
    const requiredPhrases = requiredTranscriptText[pageStory.id];

    await voiceOver.navigateToWebContent();

    let spokenPhrases: string[] = [];
    let itemText: string[] = [];
    let transcript = "";

    for (let index = 0; index < maxTraversalSteps; index += 1) {
      await voiceOver.next();

      if ((index + 1) % 5 !== 0 && index + 1 !== maxTraversalSteps) {
        continue;
      }

      spokenPhrases = await voiceOver.spokenPhraseLog();
      itemText = await voiceOver.itemTextLog();
      transcript = [...spokenPhrases, ...itemText].join("\n");

      const roleReached = transcript.includes(requiredRole.name);
      const acceptanceTruthReached =
        pageStory.acceptance.required_text.some((copy) =>
          transcript.includes(copy),
        );
      const pageTruthReached = requiredPhrases.every((copy) =>
        transcript.includes(copy),
      );

      if (roleReached && acceptanceTruthReached && pageTruthReached) {
        break;
      }
    }

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

    for (const requiredText of requiredPhrases) {
      expect(
        transcript,
        `VoiceOver transcript for ${pageStory.id} must contain ${requiredText}`,
      ).toContain(requiredText);
    }

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
