import { expect, test, type AriaRole, type Locator } from "@playwright/test";
import {
  manifest,
  pageStories,
  type ShowcaseRoleContract,
} from "../support/manifest";
import { activateTarget, prepareShowcase } from "../support/showcase";

const copyContract = manifest.copy_contract;

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
    await expect(root, `forbidden copy: ${forbiddenText}`).not.toContainText(
      forbiddenText,
    );
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

function exactPhrase(text: string, phrase: string): boolean {
  const escaped = phrase.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(
    `(^|[^\\p{L}\\p{N}_])${escaped}([^\\p{L}\\p{N}_]|$)`,
    "u",
  ).test(text);
}

async function assertRenderedCopyPolicy(
  root: Locator,
  storyId: string,
): Promise<void> {
  const renderedText = (await root.innerText()).replace(/\s+/g, " ").trim();
  const actionText = (
    await root
      .locator(
        'button, a[href], input[type="button"], input[type="submit"], [role="button"], [role="link"]',
      )
      .allInnerTexts()
  )
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
  const receiptText = (
    await root
      .locator('[role="status"], [role="alert"], [data-obpt-receipt]')
      .allInnerTexts()
  )
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
  const policyPhrases = [
    ...copyContract.forbidden_phrases.map(({ phrase, rule }) => ({
      phrase,
      rule,
    })),
    ...Object.entries(copyContract.canonical_terms).flatMap(
      ([concept, entry]) =>
        entry.forbidden.map((phrase) => ({
          phrase,
          rule: `canonical-term:${concept}`,
        })),
    ),
  ];
  const violations = policyPhrases.filter(({ phrase, rule }) => {
    const policyText =
      rule === "ambiguous-action"
        ? actionText
        : rule === "host-outcome-overclaim"
          ? receiptText
          : renderedText;
    return exactPhrase(policyText, phrase);
  });

  expect(
    violations,
    `${storyId} rendered copy policy violations: ${violations
      .map(({ phrase, rule }) => `${JSON.stringify(phrase)} (${rule})`)
      .join(", ")}`,
  ).toEqual([]);
}

async function assertConfirmationOrder(
  root: Locator,
  storyId: string,
): Promise<void> {
  const dialog = root.locator(".obpt-confirm-action");
  if ((await dialog.count()) === 0) return;

  const selectors: Record<string, string> = {
    object: ".obpt-confirm-action__object",
    scope: ".obpt-confirm-action__scope",
    consequence: ".obpt-confirm-action__consequence",
    reversibility: ".obpt-confirm-action__reversibility",
    support_boundary: ".obpt-confirm-action__support",
    reason: ".obpt-confirm-action__form textarea",
    actions: ".obpt-confirm-action__actions",
  };
  expect(
    Object.keys(selectors),
    `${storyId} confirmation order mapping must exactly consume the generated policy`,
  ).toEqual(copyContract.confirmation_order);

  const presentOrder = copyContract.confirmation_order.filter(
    (key) => selectors[key] !== undefined,
  );
  const formVisible = (await dialog.locator("form").count()) === 1;
  const requiredOrder = formVisible
    ? presentOrder
    : presentOrder.filter((key) => key !== "reason");

  for (const key of requiredOrder) {
    await expect(
      dialog.locator(selectors[key]),
      `${storyId} confirmation marker ${key}`,
    ).toHaveCount(1);
  }

  const ordered = await dialog.evaluate(
    (element, markers) => {
      const nodes = markers.map(({ key, selector }) => {
        const node = element.querySelector(selector);
        if (!node) throw new Error(`${key} marker ${selector} is missing`);
        return { key, node };
      });
      return nodes.every(
        ({ node }, index) =>
          index === 0 ||
          Boolean(
            nodes[index - 1].node.compareDocumentPosition(node) &
            Node.DOCUMENT_POSITION_FOLLOWING,
          ),
      );
    },
    requiredOrder.map((key) => ({ key, selector: selectors[key] })),
  );
  expect(
    ordered,
    `${storyId} confirmation must follow ${requiredOrder.join(" -> ")}`,
  ).toBe(true);

  if (formVisible) {
    const actions = dialog.locator(".obpt-confirm-action__actions");
    const submit = actions.locator('button[type="submit"]');
    const dismiss = actions.locator('button[type="button"]');
    await expect(submit, `${storyId} action-specific submit`).toHaveCount(1);
    const submitText = await submit.innerText();
    expect(submitText.trim(), `${storyId} submit label`).not.toBe("");
    if ((await dismiss.count()) === 1) {
      const dismissText = await dismiss.innerText();
      expect(dismissText.trim(), `${storyId} dismiss label`).not.toBe("");
      expect(
        submitText.trim(),
        `${storyId} action and dismiss labels`,
      ).not.toBe(dismissText.trim());
      expect(
        await actions.evaluate((element) => {
          const submitNode = element.querySelector('button[type="submit"]');
          const dismissNode = element.querySelector('button[type="button"]');
          return Boolean(
            submitNode &&
            dismissNode &&
            submitNode.compareDocumentPosition(dismissNode) &
              Node.DOCUMENT_POSITION_FOLLOWING,
          );
        }),
        `${storyId} submit must precede safe-state dismiss`,
      ).toBe(true);
    } else {
      await expect(
        dialog,
        `${storyId} may omit safe dismissal only after submission is accepted`,
      ).toHaveAttribute("data-obpt-confirm-state", "submitting");
      await expect(
        submit,
        `${storyId} accepted submit is disabled`,
      ).toBeDisabled();
    }
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
  await expect(
    stage.locator("[data-obpt-mobile-copy], [data-obpt-desktop-copy]"),
  ).toHaveCount(0);

  const dialogs = stage.locator('[role="dialog"], dialog[open]');
  await expect(dialogs).toHaveCount(story.activation === "none" ? 0 : 1);
  expect(
    await stage
      .locator('[role="dialog"][aria-modal="true"], dialog[open]')
      .count(),
  ).toBeLessThanOrEqual(1);

  if (story.page === "jobs" && story.components.includes("data_table")) {
    await expect(
      stage.getByRole("table", { name: /^Jobs(?:\s|$)/ }),
    ).toHaveCount(1);
  }

  if (story.page === "jobs" && story.components.includes("progress_bar")) {
    await expect(stage.getByRole("progressbar")).toHaveCount(1);
  }

  if (story.page === "jobs" && story.components.includes("detail_surface")) {
    await expect(
      stage.getByRole("link", { name: "Open full job details", exact: true }),
    ).toHaveCount(1);
  }

  if (story.page === "forensics" && story.components.includes("timeline")) {
    await expect(
      stage.getByRole("heading", {
        name: "Investigation summary",
        exact: true,
      }),
    ).toHaveCount(1);
    await expect(
      stage.getByRole("heading", { name: "What to do next", exact: true }),
    ).toHaveCount(1);
    await expect(
      stage.getByRole("heading", { name: "Event log", exact: true }),
    ).toHaveCount(1);
    await expect(
      stage.getByRole("heading", {
        name: "Evidence limits and sources",
        exact: true,
      }),
    ).toHaveCount(1);
    await expect(stage.locator(".obpt-timeline__list")).toHaveCount(1);

    if (story.variant.includes("history_unavailable")) {
      await expect(stage.locator(".obpt-timeline__item")).toHaveCount(0);
    }

    expect(
      await stage.locator(".obpt-timeline__item").count(),
    ).toBeLessThanOrEqual(50);
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
    expect(markup, `forbidden rendered field: ${forbiddenField}`).not.toContain(
      forbiddenField,
    );
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
      await assertRenderedCopyPolicy(stage, story.id);
      await assertConfirmationOrder(stage, story.id);
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
