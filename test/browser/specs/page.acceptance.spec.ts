import {
  expect,
  test,
  type AriaRole,
  type Locator,
} from "@playwright/test";
import {
  pageStories,
  type ShowcaseRoleContract,
} from "../support/manifest";
import {
  activateTarget,
  prepareShowcase,
} from "../support/showcase";

function viewportName(projectName: string): "320" | "tablet" | "wide" {
  if (projectName === "chromium-320") return "320";
  if (projectName === "chromium-tablet") return "tablet";
  if (projectName === "chromium-wide") return "wide";

  throw new Error(`unknown page acceptance project ${projectName}`);
}

async function assertTextContract(
  root: Locator,
  acceptance: (typeof pageStories)[number]["acceptance"],
): Promise<void> {
  for (const requiredText of acceptance.required_text) {
    await expect(
      root.getByText(requiredText, { exact: false }).first(),
      `required copy: ${requiredText}`,
    ).toBeVisible();
  }

  for (const forbiddenText of acceptance.forbidden_text) {
    await expect(
      root,
      `forbidden copy: ${forbiddenText}`,
    ).not.toContainText(forbiddenText);
  }

  const normalizedText = await root.evaluate((element) =>
    (element.textContent ?? "").replace(/\s+/g, " ").trim(),
  );
  let previousIndex = -1;

  for (const orderedText of acceptance.ordered_text) {
    const nextIndex = normalizedText.indexOf(orderedText, previousIndex + 1);
    expect(
      nextIndex,
      `${JSON.stringify(orderedText)} must follow the prior ordered acceptance text`,
    ).toBeGreaterThan(previousIndex);
    previousIndex = nextIndex;
  }
}

async function assertRoleContract(
  root: Locator,
  contract: ShowcaseRoleContract,
): Promise<void> {
  const options = {
    name: contract.name,
    exact: true,
    ...contract.states,
    ...(contract.level === undefined ? {} : { level: contract.level }),
  };
  const role = root.getByRole(contract.role as AriaRole, options);

  await expect(
    role,
    `${contract.role} named ${JSON.stringify(contract.name)}`,
  ).toHaveCount(1);
  await expect(role).toBeVisible();
}

async function assertPageStructure(
  stage: Locator,
  story: (typeof pageStories)[number],
): Promise<void> {
  await expect(stage.getByRole("heading", { level: 1 })).toHaveCount(1);
  await expect(stage.locator("[data-obpt-mobile-copy], [data-obpt-desktop-copy]")).toHaveCount(0);

  const dialogs = stage.locator('[role="dialog"], dialog[open]');
  await expect(dialogs).toHaveCount(story.activation === "none" ? 0 : 1);
  expect(
    await stage.locator('[role="dialog"][aria-modal="true"], dialog[open]').count(),
  ).toBeLessThanOrEqual(1);

  if (story.page === "jobs" && story.components.includes("data_table")) {
    await expect(stage.getByRole("table", { name: /^Jobs(?:\s|$)/ })).toHaveCount(1);
  }

  if (story.page === "jobs" && story.components.includes("progress_bar")) {
    await expect(stage.getByRole("progressbar")).toHaveCount(1);
  }

  if (story.page === "jobs" && story.components.includes("detail_surface")) {
    await expect(stage.getByRole("link", { name: "Open full job details", exact: true })).toHaveCount(
      1,
    );
  }

  if (story.page === "forensics" && story.components.includes("timeline")) {
    await expect(stage.getByRole("heading", { name: "Investigation summary", exact: true })).toHaveCount(
      1,
    );
    await expect(stage.getByRole("heading", { name: "What to do next", exact: true })).toHaveCount(1);
    await expect(stage.getByRole("heading", { name: "Event log", exact: true })).toHaveCount(1);
    await expect(
      stage.getByRole("heading", { name: "Evidence limits and sources", exact: true }),
    ).toHaveCount(1);
    await expect(stage.locator(".obpt-timeline__list")).toHaveCount(1);

    if (story.variant.includes("history_unavailable")) {
      await expect(stage.locator(".obpt-timeline__item")).toHaveCount(0);
    }

    expect(await stage.locator(".obpt-timeline__item").count()).toBeLessThanOrEqual(50);
  }

  const markup = await stage.evaluate((element) => element.outerHTML);
  for (const forbiddenField of [
    "preview_token",
    "plan_hash",
    "raw_exception",
    "raw_metadata",
    "stacktrace",
    "return_to",
  ]) {
    expect(markup, `forbidden rendered field: ${forbiddenField}`).not.toContain(forbiddenField);
  }
}

test.describe("Page acceptance contracts", () => {
  for (const story of pageStories) {
    test(`${story.id} copy roles order and ARIA tree`, async ({
      page,
    }, testInfo) => {
      await prepareShowcase(page, {
        theme: "system",
        viewportName: viewportName(testInfo.project.name),
      });
      const storyRoot = await activateTarget(page, story);
      const stage = storyRoot.locator(
        `[data-obpt-page-story-stage="${story.id}"]`,
      );

      await expect(stage).toBeVisible();
      await assertTextContract(stage, story.acceptance);
      await assertPageStructure(stage, story);

      for (const role of story.acceptance.roles) {
        await assertRoleContract(stage, role);
      }

      expect(await stage.ariaSnapshot()).toMatchSnapshot(
        `${story.id}.aria.yml`,
      );
    });
  }
});
