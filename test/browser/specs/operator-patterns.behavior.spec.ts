import { expect, test, type Locator, type Page } from "@playwright/test";
import { viewportNameFromProject } from "../support/deterministic";
import * as manifestSupport from "../support/manifest";
import type { ShowcaseGroupStory } from "../support/manifest";
import * as showcaseSupport from "../support/showcase";

type GroupManifestSupport = typeof manifestSupport & {
  groupStories?: ShowcaseGroupStory[];
};

type GroupShowcaseSupport = typeof showcaseSupport & {
  activateTarget?: (page: Page, story: ShowcaseGroupStory) => Promise<void>;
};

const groupStories = (manifestSupport as GroupManifestSupport).groupStories;
const activateTarget = (showcaseSupport as GroupShowcaseSupport).activateTarget;
const confidentialitySentinels = [
  "PHASE78-GROUP-SECRET-SENTINEL",
  "PHASE78-GROUP-TOKEN-SENTINEL",
  "PHASE78-GROUP-HASH-SENTINEL",
  "PHASE78-GROUP-RAW-ERROR-SENTINEL",
] as const;

if (!Array.isArray(groupStories) || groupStories.length !== 23) {
  throw new Error(
    "Phase 78 requires schema-6 generated groupStories in the showcase manifest",
  );
}

if (typeof activateTarget !== "function") {
  throw new Error(
    "Phase 78 requires schema-6 group activation support in showcase helpers",
  );
}

function groupStory(label: string, ...idTokens: string[]): ShowcaseGroupStory {
  const matches = groupStories.filter((candidate) =>
    idTokens.every((token) => candidate.id.includes(token)),
  );

  if (matches.length !== 1) {
    throw new Error(
      `${label} must resolve one generated group story, got ${matches.map((story) => story.id).join(", ")}`,
    );
  }

  return matches[0];
}

async function prepareGroupStory(
  page: Page,
  projectName: string,
  story: ShowcaseGroupStory,
): Promise<Locator> {
  await showcaseSupport.prepareShowcase(page, {
    theme: "light",
    viewportName: viewportNameFromProject(projectName),
  });
  await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);

  await activateTarget(page, story);
  const locator = page.locator(story.a11y);
  await expect(locator).toBeVisible();
  return locator;
}

function activationTrigger(page: Page, story: ShowcaseGroupStory): Locator {
  return page
    .locator(story.a11y)
    .locator(`[phx-click="activate-group-story"][phx-value-id="${story.id}"]`);
}

async function prepareControlledGroupStory(
  page: Page,
  projectName: string,
  story: ShowcaseGroupStory,
  controlledId = `showcase-${story.id}-dialog`,
): Promise<{ story: Locator; trigger: Locator }> {
  await showcaseSupport.prepareShowcase(page, {
    theme: "light",
    viewportName: viewportNameFromProject(projectName),
  });

  const trigger = page.locator(
    '.obpt-showcase-controls [data-obpt-theme-choice="light"]',
  );
  await activateFromControlledInvoker(page, trigger, story, controlledId);

  const storyLocator = page.locator(story.a11y);
  await expect(storyLocator).toHaveAttribute(
    "data-obpt-overlay-active",
    "true",
  );
  await expect(storyLocator.getByRole("dialog")).toBeVisible();
  return { story: storyLocator, trigger };
}

async function bindParentEvent(
  control: Locator,
  event: string,
  values: Record<string, string>,
): Promise<void> {
  await control.evaluate(
    (element, contract) => {
      element.setAttribute("phx-click", contract.event);
      for (const [name, value] of Object.entries(contract.values)) {
        element.setAttribute(`phx-value-${name}`, value);
      }
      element.addEventListener("click", (click) => click.preventDefault(), {
        once: true,
      });
    },
    { event, values },
  );
}

async function expectNativeModal(
  detail: Locator,
  expected: boolean,
): Promise<void> {
  expect(await detail.evaluate((element) => element.matches(":modal"))).toBe(
    expected,
  );
}

async function activateFromControlledInvoker(
  page: Page,
  trigger: Locator,
  story: ShowcaseGroupStory,
  controlledId = `showcase-${story.id}-dialog`,
): Promise<void> {
  await trigger.evaluate((button, id) => {
    button.setAttribute("aria-controls", id);
  }, controlledId);
  await trigger.focus();
  await page.keyboard.press("Enter");
  await activationTrigger(page, story).dispatchEvent("click");
}

async function expectNoHorizontalOverflow(story: Locator): Promise<void> {
  const overflow = await story.evaluate((element) => ({
    story: Math.ceil(element.scrollWidth - element.clientWidth),
    body: Math.ceil(document.body.scrollWidth - document.body.clientWidth),
    document: Math.ceil(
      document.documentElement.scrollWidth -
        document.documentElement.clientWidth,
    ),
  }));

  expect(overflow.story).toBeLessThanOrEqual(1);
  expect(overflow.body).toBeLessThanOrEqual(1);
  expect(overflow.document).toBeLessThanOrEqual(1);
}

async function expectVisibleFocus(
  locator: Locator,
  label: string,
): Promise<void> {
  await expect(locator, `${label} should be focused`).toBeFocused();

  const focusPresentation = await locator.evaluate((element) => {
    const style = getComputedStyle(element);
    const rect = element.getBoundingClientRect();
    return {
      color: style.outlineColor,
      style: style.outlineStyle,
      width: Number.parseFloat(style.outlineWidth),
      inViewport:
        rect.width > 0 &&
        rect.height > 0 &&
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= window.innerHeight &&
        rect.right <= window.innerWidth,
    };
  });

  expect(
    focusPresentation.style,
    `${label} should have an outline style`,
  ).not.toBe("none");
  expect(
    focusPresentation.width,
    `${label} should have a non-zero outline`,
  ).toBeGreaterThan(0);
  expect(
    focusPresentation.color,
    `${label} should have a visible outline`,
  ).not.toBe("rgba(0, 0, 0, 0)");
  expect(
    focusPresentation.inViewport,
    `${label} should remain inside the visual viewport`,
  ).toBe(true);
}

async function focusWithKeyboard(
  page: Page,
  locator: Locator,
  label: string,
): Promise<void> {
  await page.evaluate(() => {
    if (document.activeElement instanceof HTMLElement) {
      document.activeElement.blur();
    }
  });

  for (let attempt = 0; attempt < 200; attempt += 1) {
    await page.keyboard.press("Tab");
    if (
      await locator.evaluate((element) => element === document.activeElement)
    ) {
      await expectVisibleFocus(locator, label);
      return;
    }
  }

  throw new Error(`${label} was not reachable through the page Tab order`);
}

async function expectOneResponsiveTree(
  story: Locator,
  selector: string,
): Promise<void> {
  await expect(story.locator(selector)).toHaveCount(1);
  await expect(story.locator("[data-obpt-mobile-copy]")).toHaveCount(0);
  await expect(story.locator("[data-obpt-desktop-copy]")).toHaveCount(0);
}

async function expectConfidentialityChannelsSafe(page: Page): Promise<void> {
  const leaks = await page.locator("html").evaluate(
    (documentElement, sentinels) => {
      const channels = [
        documentElement.textContent ?? "",
        documentElement.innerHTML,
        document.documentElement.outerHTML,
        document.URL,
      ];

      for (const candidate of documentElement.querySelectorAll<HTMLElement>(
        "*",
      )) {
        channels.push(
          candidate.innerText ?? "",
          candidate.getAttribute("value") ?? "",
          candidate.getAttribute("title") ?? "",
        );

        if (
          candidate instanceof HTMLInputElement ||
          candidate instanceof HTMLTextAreaElement ||
          candidate instanceof HTMLSelectElement
        ) {
          channels.push(candidate.value);
        }

        for (const attribute of Array.from(candidate.attributes)) {
          channels.push(`${attribute.name}=${attribute.value}`);
        }
      }

      return sentinels.filter((sentinel) =>
        channels.some((channel) => channel.includes(sentinel)),
      );
    },
    [...confidentialitySentinels],
  );

  expect(leaks).toEqual([]);
}

async function apply200PercentZoom(page: Page): Promise<void> {
  const original = page.viewportSize();
  if (!original)
    throw new Error("200% zoom requires a configured Chromium viewport");

  const effectiveWidth = Math.floor(original.width / 2);
  const effectiveHeight = Math.floor(original.height / 2);
  const session = await page.context().newCDPSession(page);

  await session.send("Emulation.setDeviceMetricsOverride", {
    width: effectiveWidth,
    height: effectiveHeight,
    screenWidth: original.width,
    screenHeight: original.height,
    deviceScaleFactor: 2,
    mobile: false,
  });

  const metrics = await page.evaluate(() => ({
    deviceScaleFactor: window.devicePixelRatio,
    effectiveWidth: window.innerWidth,
    effectiveHeight: window.innerHeight,
  }));

  expect(metrics.deviceScaleFactor).toBe(2);
  expect(metrics.effectiveWidth).toBe(effectiveWidth);
  expect(metrics.effectiveHeight).toBe(effectiveHeight);
}

test.describe("group operator-pattern connected behavior contracts", () => {
  test("group confirmation traps focus, handles Escape, and restores the invoker or fallback", async ({
    page,
  }, testInfo) => {
    const story = groupStory(
      "single destructive confirmation",
      "confirm",
      "single",
      "destructive",
    );
    const controlled = await prepareControlledGroupStory(
      page,
      testInfo.project.name,
      story,
    );
    const dialog = controlled.story.getByRole("dialog");
    const title = dialog.locator(`#showcase-${story.id}-title`);
    const focusable = dialog.locator(
      'button:not([disabled]), a[href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex="0"]',
    );
    const first = focusable.first();
    const last = focusable.last();

    await expect(dialog).toHaveAttribute("aria-modal", "true");
    await expectVisibleFocus(title, "confirmation title on mount");

    await first.focus();
    await page.keyboard.press("Shift+Tab");
    await expect(last).toBeFocused();
    await last.focus();
    await page.keyboard.press("Tab");
    expect(
      await dialog.evaluate((element) =>
        element.contains(document.activeElement),
      ),
      "forward Tab from the final control should remain in the modal",
    ).toBe(true);

    await page.keyboard.press("Escape");
    await expect(dialog).toHaveCount(0);
    await expect(controlled.trigger).toBeFocused();

    await activateFromControlledInvoker(page, controlled.trigger, story);
    const reopened = controlled.story.getByRole("dialog");
    await expect(reopened).toBeVisible();
    await reopened.getByRole("button", { name: "Keep current state" }).focus();
    await page.keyboard.press("Enter");
    await expect(reopened).toHaveCount(0);
    await expect(controlled.trigger).toBeFocused();

    await activateFromControlledInvoker(page, controlled.trigger, story);
    const fallback = page.locator("#form-input-required");
    await controlled.story
      .getByRole("dialog")
      .evaluate((element) =>
        element.setAttribute("data-obpt-focus-fallback", "form-input-required"),
      );
    await controlled.trigger.evaluate((element) => element.remove());
    await page.keyboard.press("Escape");
    await expect(fallback).toBeFocused();
  });

  test("group confirmation rejects blank, short, and wrong-count input before one duplicate-safe receipt", async ({
    page,
  }, testInfo) => {
    const valid = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("bulk confirmation", "confirm", "bulk", "count"),
    );
    const reason = valid.getByRole("textbox", { name: "Reason" });
    const count = valid.getByRole("textbox", { name: "Type 12 to confirm" });
    const submit = valid.getByRole("button", { name: "Retry 12 jobs" });

    await reason.fill("");
    await count.fill("");
    await submit.click();
    expect(
      await reason.evaluate((element) => element.matches(":invalid")),
    ).toBe(true);
    expect(await count.evaluate((element) => element.matches(":invalid"))).toBe(
      true,
    );
    await expect(valid.getByRole("dialog")).toBeVisible();
    await expect(page.locator("#obpt-group-receipt")).toHaveCount(0);

    await reason.fill("short");
    await count.fill("11");
    await expect(reason).toHaveValue("short");
    await expect(count).toHaveValue("11");
    await submit.click();
    await expect(valid.getByRole("dialog")).toBeVisible();
    await expect(page.locator("#obpt-group-receipt")).toHaveCount(0);

    await reason.fill("Provider recovered; retry safely.");
    await count.fill("12");
    await valid.locator("form").evaluate((form) => {
      const evidence = { busyTransitions: 0, busy: false };
      (
        window as typeof window & { __phase78Busy?: typeof evidence }
      ).__phase78Busy = evidence;
      const observer = new MutationObserver(() => {
        const busy = form.classList.contains("phx-submit-loading");
        if (busy && !evidence.busy) evidence.busyTransitions += 1;
        evidence.busy = busy;
      });
      observer.observe(form, { attributes: true, attributeFilter: ["class"] });
    });
    await submit.evaluate((button: HTMLButtonElement) => {
      button.click();
      button.click();
    });

    const receipt = page.locator("#obpt-group-receipt");
    const exactReceipt =
      "Retry requested for 12 jobs. Audit evidence recorded.";
    await expect(receipt).toHaveAttribute("data-obpt-group-receipt-count", "1");
    await expect(receipt).toHaveText(exactReceipt);
    await expect(page.getByText(exactReceipt, { exact: true })).toHaveCount(1);
    await expect(receipt).not.toContainText(/completed|fixed/i);
    expect(
      await page.evaluate(
        () =>
          (
            window as typeof window & {
              __phase78Busy?: { busyTransitions: number };
            }
          ).__phase78Busy?.busyTransitions,
      ),
    ).toBe(1);
    await expect(
      page.locator("[data-obpt-group-story][data-obpt-overlay-active='true']"),
    ).toHaveCount(0);
    await expectConfidentialityChannelsSafe(page);
  });

  test("group confirmation keeps nondismissible busy, ordered partial, and stale replay truth", async ({
    page,
  }, testInfo) => {
    const pending = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("pending confirmation", "confirm", "pending"),
    );
    const pendingDialog = pending.getByRole("dialog");
    await expect(pendingDialog).toHaveAttribute("aria-busy", "true");
    await expect(
      pendingDialog.locator(".obpt-confirm-action__busy"),
    ).toContainText(
      "Retrying 1 job… This action has been accepted and can no longer be canceled.",
    );
    await expect(
      pendingDialog.getByText(
        "This action has been accepted and can no longer be canceled.",
        { exact: true },
      ),
    ).toBeVisible();
    await expect(
      pendingDialog.getByRole("button", { name: /Retry/ }),
    ).toBeDisabled();
    await expect(
      pendingDialog.getByRole("button", { name: /Keep current state/ }),
    ).toHaveCount(0);
    await page.keyboard.press("Escape");
    await expect(pendingDialog).toBeVisible();
    await expectConfidentialityChannelsSafe(page);

    const partialStory = groupStory(
      "partial confirmation results",
      "confirm",
      "partial",
    );
    const partial = await prepareGroupStory(
      page,
      testInfo.project.name,
      partialStory,
    );
    const resultHeading = partial.locator(
      `#showcase-${partialStory.id}-result-heading`,
    );
    await expect(resultHeading).toHaveText(
      "Retry requests finished with mixed results. Review failed and skipped jobs before trying again.",
    );
    await expect(resultHeading).toBeFocused();
    const rows = partial.locator("[data-obpt-result]");
    await expect(rows).toHaveCount(3);
    expect(
      await rows.evaluateAll((elements) =>
        elements.map((element) => ({
          id: element.id,
          outcome: element.getAttribute("data-obpt-result"),
        })),
      ),
    ).toEqual([
      {
        id: "showcase-group-confirm-partial-results-job-result-success",
        outcome: "success",
      },
      {
        id: "showcase-group-confirm-partial-results-job-result-failed",
        outcome: "failed",
      },
      {
        id: "showcase-group-confirm-partial-results-job-result-skipped",
        outcome: "skipped",
      },
    ]);
    await expect(rows.nth(0)).toContainText("Success");
    await expect(rows.nth(1)).toContainText("Failed");
    await expect(rows.nth(2)).toContainText("Skipped");
    await expect(
      partial.getByRole("button", { name: "Create new preview" }),
    ).toBeVisible();
    await expect(
      partial.getByRole("link", { name: "Open audit evidence" }).first(),
    ).toBeVisible();
    await expect(partial.getByRole("dialog")).toBeVisible();
    await expectConfidentialityChannelsSafe(page);

    const stale = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("stale confirmation", "confirm", "drifted"),
    );
    const staleHeading = stale.locator(
      "#showcase-group-confirm-drifted-error-result-heading",
    );
    await expect(staleHeading).toHaveText(
      "This preview is out of date because the job changed. Create a new preview before retrying.",
    );
    await expect(staleHeading).toBeFocused();
    await expect(page.locator("#obpt-group-receipt")).toHaveCount(0);

    await stale.getByRole("button", { name: "Create new preview" }).click();
    const staleReason = stale.getByRole("textbox", { name: "Reason" });
    await expect(staleReason).toHaveValue(
      "Provider recovered; retry the customer notification.",
    );
    await stale.getByRole("button", { name: "Retry job" }).click();
    await expect(staleHeading).toBeFocused();
    await expect(page.locator("#obpt-group-receipt")).toHaveCount(0);
    await stale.getByRole("button", { name: "Create new preview" }).click();
    await expect(staleReason).toHaveValue(
      "Provider recovered; retry the customer notification.",
    );
    await expectConfidentialityChannelsSafe(page);
  });

  test("group filter disclosure keeps collapsed fields out of narrow keyboard order", async ({
    page,
  }, testInfo) => {
    test.skip(
      viewportNameFromProject(testInfo.project.name) !== "320",
      "narrow filter disclosure runs in chromium-320",
    );

    const story = groupStory("submit filter", "filter", "submit");
    const stage = await prepareGroupStory(page, testInfo.project.name, story);
    const toggle = stage.getByRole("button", { name: /Filters/ });
    const fields = stage.locator("[data-obpt-filter-fields]");
    const queue = stage.getByRole("textbox", { name: "Queue" });
    const fieldsId = await fields.getAttribute("id");

    await expect(toggle).toHaveAttribute("aria-expanded", "false");
    await expect(toggle).toHaveAttribute("aria-controls", fieldsId as string);
    await expect(fields).toBeHidden();
    await expect(fields).toHaveAttribute("inert", "");
    await expect(stage.getByRole("status")).toHaveText(
      "248 jobs match the applied filters.",
    );

    await toggle.focus();
    await page.keyboard.press("Tab");
    expect(
      await fields.evaluate((element) =>
        element.contains(document.activeElement),
      ),
    ).toBe(false);

    await toggle.focus();
    await page.keyboard.press("Enter");
    await expect(toggle).toHaveAttribute("aria-expanded", "true");
    await expect(fields).toBeVisible();
    await expect(fields).not.toHaveAttribute("inert", /.+/);
    await page.keyboard.press("Tab");
    await expect(queue).toBeFocused();

    await toggle.focus();
    await page.keyboard.press("Space");
    await expect(toggle).toHaveAttribute("aria-expanded", "false");
    await expect(fields).toBeHidden();
    await expect(fields).toHaveAttribute("inert", "");
    await expectOneResponsiveTree(stage, "[data-obpt-filter-fields]");
    await expectNoHorizontalOverflow(stage);
  });

  test("group filter draft, Apply, named remove, Clear, canonical URL, and one status stay parent-owned", async ({
    page,
  }, testInfo) => {
    const story = groupStory("submit filter", "filter", "submit");
    const stage = await prepareGroupStory(page, testInfo.project.name, story);
    const fields = stage.locator("[data-obpt-filter-fields]");
    const queue = stage.getByRole("textbox", { name: "Queue" });
    const state = stage.getByRole("textbox", { name: "State" });
    const results = stage.locator(`#${story.id}-results`);
    const originalBrowserUrl = page.url();

    if (!(await fields.isVisible())) {
      await stage.getByRole("button", { name: /Filters/ }).click();
    }

    await queue.fill("critical-mailer");
    await state.fill("retryable");
    await expect(page).toHaveURL(originalBrowserUrl);
    await expect(results).toHaveAttribute(
      "data-obpt-group-filter-url",
      "/ops/jobs/_showcase",
    );
    await expect(stage.getByRole("status")).toHaveText(
      "248 jobs match the applied filters.",
    );
    await expect(
      stage.getByText("Changes not applied.", { exact: true }),
    ).toBeVisible();

    await stage.getByRole("button", { name: "Apply filters" }).click();
    const appliedUrl =
      "/ops/jobs/_showcase?queue=critical-mailer&state=retryable";
    await expect(results).toHaveAttribute(
      "data-obpt-group-filter-url",
      appliedUrl,
    );
    await expect(results).toHaveAttribute(
      "data-obpt-group-filter-history",
      `push:${appliedUrl}`,
    );
    await expect(results).not.toHaveAttribute(
      "data-obpt-group-filter-url",
      /[?&]page=/,
    );
    await expect(stage.getByRole("status")).toHaveText(
      "42 jobs match the applied filters.",
    );
    await expect(stage.getByRole("status")).toHaveCount(1);
    await expect(stage.locator(".obpt-filter-bar__active-filter")).toHaveCount(
      2,
    );

    const removeQueue = stage.getByRole("link", {
      name: "Remove Queue: critical-mailer filter",
    });
    await bindParentEvent(removeQueue, "remove-group-filter", {
      id: story.id,
      field: "queue",
    });
    await removeQueue.click();
    await expect(results).toHaveAttribute(
      "data-obpt-group-filter-url",
      "/ops/jobs/_showcase?state=retryable",
    );
    await expect(stage.locator(".obpt-filter-bar__active-filter")).toHaveCount(
      1,
    );

    const clear = stage.getByRole("link", { name: "Clear filters" });
    await bindParentEvent(clear, "clear-group-filters", { id: story.id });
    await clear.click();
    await expect(results).toHaveAttribute(
      "data-obpt-group-filter-url",
      "/ops/jobs/_showcase",
    );
    await expect(stage.getByRole("status")).toHaveText(
      "248 jobs match the applied filters.",
    );
    await expect(stage.getByRole("status")).toHaveCount(1);
    await expect(stage.locator(".obpt-filter-bar__applied")).toHaveCount(0);
    await expect(page).toHaveURL(originalBrowserUrl);
    await expectConfidentialityChannelsSafe(page);
  });

  test("group filter instant mode applies one criterion without inventing Apply semantics", async ({
    page,
  }, testInfo) => {
    const story = groupStory("instant filter", "filter", "instant");
    const stage = await prepareGroupStory(page, testInfo.project.name, story);
    const fields = stage.locator("[data-obpt-filter-fields]");
    const results = stage.locator(`#${story.id}-results`);

    if (!(await fields.isVisible())) {
      await stage.getByRole("button", { name: /Filters/ }).click();
    }

    await expect(
      stage.getByRole("button", { name: "Apply filters" }),
    ).toHaveCount(0);
    await stage.getByRole("textbox", { name: "State" }).fill("available");
    await expect(results).toHaveAttribute(
      "data-obpt-group-filter-url",
      "/ops/jobs/_showcase?state=available",
    );
    await expect(results).toHaveAttribute(
      "data-obpt-group-filter-history",
      "replace:/ops/jobs/_showcase?state=available",
    );
    await expect(stage.getByRole("status")).toHaveText(
      "42 jobs match the applied filters.",
    );
    await expect(
      stage.getByRole("button", { name: "Apply filters" }),
    ).toHaveCount(0);
  });

  test("group detail constrained drawer is native-modal, contained, history-aware, dismissible, and restorable", async ({
    page,
  }, testInfo) => {
    test.skip(
      viewportNameFromProject(testInfo.project.name) !== "tablet",
      "constrained native modality runs in chromium-tablet",
    );

    const story = groupStory("modal detail", "detail", "modal");
    const surfaceId = `showcase-${story.id}-surface`;
    const controlled = await prepareControlledGroupStory(
      page,
      testInfo.project.name,
      story,
      surfaceId,
    );
    const detail = controlled.story.locator("[data-obpt-detail-surface]");
    await expect(detail.locator("[data-obpt-detail-body]")).toHaveAttribute(
      "tabindex",
      "0",
    );
    const results = controlled.story.locator(
      "[data-obpt-group-detail-history]",
    );
    const firstResource = "01JZ8M5P999999999999999999";
    const nextResource = "01JZ8M5P999999999999999998";

    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "drawer");
    await expect(detail).toHaveAttribute("aria-modal", "true");
    await expectNativeModal(detail, true);
    await expect(results).toHaveAttribute(
      "data-obpt-group-detail-history",
      `push:/ops/jobs/_showcase?detail=${firstResource}`,
    );
    await expect(detail.getByRole("status")).toHaveText(
      `Job ${firstResource} details loaded.`,
    );

    const outside = page.locator("#form-input-required");
    await outside.focus();
    expect(
      await detail.evaluate((element) =>
        element.contains(document.activeElement),
      ),
      "native modal should prevent background focus",
    ).toBe(true);

    await detail.getByRole("link", { name: "Open full details" }).focus();
    await page.keyboard.press("Tab");
    expect(
      await detail.evaluate(
        (element) =>
          document.activeElement === document.body ||
          element.contains(document.activeElement),
      ),
      "native modal Tab should not enter background content",
    ).toBe(true);
    await expect(outside).not.toBeFocused();
    await page.keyboard.press("Tab");
    expect(
      await detail.evaluate((element) =>
        element.contains(document.activeElement),
      ),
      "native modal Tab should cycle back into the detail tree",
    ).toBe(true);

    await detail.getByRole("button", { name: "Select next job" }).click();
    await expect(detail.getByRole("heading", { level: 2 })).toHaveText(
      `Job ${nextResource} details`,
    );
    await expect(detail.getByRole("status")).toHaveText(
      `Job ${nextResource} details loaded.`,
    );
    await expect(results).toHaveAttribute(
      "data-obpt-group-detail-history",
      `push:/ops/jobs/_showcase?detail=${firstResource}|replace:/ops/jobs/_showcase?detail=${nextResource}`,
    );

    await page.keyboard.press("Escape");
    await expect(detail).toHaveCount(0);
    await expect(controlled.trigger).toBeFocused();

    await activateFromControlledInvoker(
      page,
      controlled.trigger,
      story,
      surfaceId,
    );
    const reopened = controlled.story.locator("[data-obpt-detail-surface]");
    await reopened.getByRole("button", { name: "Close job details" }).click();
    await expect(reopened).toHaveCount(0);
    await expect(controlled.trigger).toBeFocused();

    await activateFromControlledInvoker(
      page,
      controlled.trigger,
      story,
      surfaceId,
    );
    const fallback = page.locator("#form-input-required");
    await controlled.story
      .locator("[data-obpt-detail-surface]")
      .evaluate((element) =>
        element.setAttribute("data-obpt-focus-fallback", "form-input-required"),
      );
    await controlled.trigger.evaluate((element) => element.remove());
    await controlled.story
      .getByRole("button", { name: "Close job details" })
      .click();
    await expect(fallback).toBeFocused();
  });

  test("group detail wide adaptive mode is modeless and switches one tree safely across resize", async ({
    page,
  }, testInfo) => {
    test.skip(
      viewportNameFromProject(testInfo.project.name) !== "wide",
      "wide detail behavior runs in chromium-wide",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("long adaptive detail", "detail", "long"),
    );
    const detail = stage.locator("[data-obpt-detail-surface]");
    await detail.evaluate((element) =>
      element.setAttribute("data-obpt-test-tree-identity", "phase78-detail"),
    );

    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "inline");
    await expect(detail).not.toHaveAttribute("aria-modal", /.+/);
    await expectNativeModal(detail, false);
    await expectOneResponsiveTree(stage, "[data-obpt-detail-surface]");

    const outside = page.locator("#form-input-required");
    await outside.focus();
    await expect(outside).toBeFocused();

    await page.setViewportSize({ width: 768, height: 1000 });
    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "drawer");
    await expect(detail).toHaveAttribute("aria-modal", "true");
    await expectNativeModal(detail, true);
    await expectOneResponsiveTree(stage, "[data-obpt-detail-surface]");
    await expect(detail).toHaveAttribute(
      "data-obpt-test-tree-identity",
      "phase78-detail",
    );

    await page.setViewportSize({ width: 320, height: 900 });
    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "drawer");
    await expectNativeModal(detail, true);
    await expectOneResponsiveTree(stage, "[data-obpt-detail-surface]");

    await page.setViewportSize({ width: 1440, height: 1000 });
    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "inline");
    await expect(detail).not.toHaveAttribute("aria-modal", /.+/);
    await expectNativeModal(detail, false);
    await expectOneResponsiveTree(stage, "[data-obpt-detail-surface]");
    await expect(detail).toHaveAttribute(
      "data-obpt-test-tree-identity",
      "phase78-detail",
    );
    await expectNoHorizontalOverflow(stage);
  });

  test("group detail exposes explicit unavailable and long content without nesting confirmation", async ({
    page,
  }, testInfo) => {
    const unavailable = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("unavailable detail", "detail", "loading", "unavailable"),
    );
    const unavailableSurface = unavailable.locator(
      "[data-obpt-detail-surface]",
    );
    await expect(unavailableSurface).toHaveAttribute(
      "data-obpt-detail-state",
      "unavailable",
    );
    await expect(
      unavailableSurface.getByText("Data unavailable", { exact: true }),
    ).toBeVisible();
    await expect(
      unavailableSurface.getByText("Refresh data", { exact: true }),
    ).toBeVisible();

    const long = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("long detail", "detail", "long"),
    );
    await expect(long).toContainText("01JZ8M5P999999999999999999");
    await expect(long).toContainText("مرحبا ✅");
    await expectOneResponsiveTree(long, ".obpt-detail-surface__body");
    await expectNoHorizontalOverflow(long);

    await long.getByRole("button", { name: "Preview retry" }).click();
    await expect(
      page.locator(
        '[data-obpt-group-story="group-confirm-single-reversible"][data-obpt-overlay-active="true"]',
      ),
    ).toHaveCount(1);
    await expect(page.locator("dialog[open]")).toHaveCount(0);
    await expect(page.getByRole("dialog")).toHaveCount(1);
    await expectConfidentialityChannelsSafe(page);
  });

  test("group explanation keeps static attention calm and exposes status, severity, permission, and long-content truth", async ({
    page,
  }, testInfo) => {
    const story = groupStory(
      "attention status severity matrix",
      "attention",
      "status",
      "severity",
    );
    const stage = await prepareGroupStory(page, testInfo.project.name, story);
    const attention = stage.locator(".obpt-attention-card");
    const focusAnchor = page.locator("#form-input-required");

    await focusAnchor.focus();
    await activateTarget(page, story);
    await expect(focusAnchor).toBeFocused();
    await expect(attention).not.toHaveAttribute("role", /.+/);
    await expect(attention).toHaveAttribute("data-obpt-severity", "warning");
    await expect(attention).toHaveAttribute(
      "data-obpt-completeness",
      "complete",
    );
    const pills = attention.locator(".obpt-status-pill");
    await expect(pills).toHaveCount(2);
    await expect(pills.locator(".obpt-status-pill-label")).toHaveText([
      "Retryable",
      "Warning",
    ]);
    await expect(pills.locator("[data-obpt-icon]")).toHaveCount(2);
    await expect(pills.nth(0)).toContainText("Job state:");
    await expect(pills.nth(1)).toContainText("Attention severity:");
    expect(
      await attention.evaluate(
        (element) =>
          Number.parseFloat(getComputedStyle(element).borderInlineStartWidth) >
          0,
      ),
    ).toBe(true);
    await expect(attention.locator("time")).toHaveAttribute(
      "datetime",
      "2026-07-18T14:05:00Z",
    );

    const longStage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory(
        "long attention content and actions",
        "attention",
        "long",
        "actions",
      ),
    );
    const longAttention = longStage.locator(".obpt-attention-card");
    const denied = longAttention.getByRole("button", {
      name: "Open retryable notification jobs",
    });
    await expect(denied).toHaveAttribute("aria-disabled", "true");
    const reasonId = await denied.getAttribute("aria-describedby");
    expect(reasonId).toBeTruthy();
    await expect(longAttention.locator(`#${reasonId}`)).toHaveText(
      "Requires operator role.",
    );
    await expect(denied).not.toHaveAttribute("phx-click", /.+/);
    await expect(longAttention).toContainText(
      "<script>alert('group')</script>",
    );
    await expect(longAttention).toContainText("مرحبا ✅");
    await expect(longAttention).toContainText("01JZ8M5P999999999999999999");
    await expect(longAttention).not.toHaveAttribute("role", /.+/);
    await expectNoHorizontalOverflow(longStage);
    await expectConfidentialityChannelsSafe(page);
  });

  test("group explanation preserves every blocker and distinguishes current, snapshot, and unavailable evidence", async ({
    page,
  }, testInfo) => {
    const multiple = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("multiple blockers", "why", "multiple", "causes"),
    );
    const rows = multiple.locator(".obpt-why-blocked__blocker");
    await expect(rows).toHaveCount(2);
    expect(
      await rows.evaluateAll((elements) =>
        elements.map((element) =>
          element.getAttribute("data-obpt-evidence-kind"),
        ),
      ),
    ).toEqual(["current", "current"]);
    expect(
      await rows.evaluateAll((elements) =>
        elements.map((element) => element.getAttribute("data-obpt-blocker-id")),
      ),
    ).toEqual(["sync-support", "notify-disconnected"]);
    await expect(rows.locator(".obpt-why-blocked__blocker-title")).toHaveText([
      "Support sync has not completed",
      "Notification step is disconnected",
    ]);
    await expect(rows.nth(0)).toContainText(
      "The support sync must record a terminal result.",
    );
    await expect(rows.nth(0)).toContainText("Current workflow state");
    await expect(rows.nth(0)).toContainText("step_retryable");
    await expect(rows.nth(1)).toContainText(
      "Restore an executable predecessor connection.",
    );
    await expect(rows.nth(1)).toContainText("Current workflow graph");
    await expect(rows.nth(1)).toContainText("predecessor_disconnected");
    await expect(multiple).not.toContainText(/root cause/i);

    const mixed = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("current and snapshot blockers", "why", "live", "snapshot"),
    );
    const mixedRows = mixed.locator(".obpt-why-blocked__blocker");
    expect(
      await mixedRows.evaluateAll((elements) =>
        elements.map((element) =>
          element.getAttribute("data-obpt-evidence-kind"),
        ),
      ),
    ).toEqual(["current", "block_start_snapshot"]);
    await expect(
      mixed.getByText("Current state", { exact: true }),
    ).toBeVisible();
    await expect(
      mixed.getByText("Block-start snapshot", { exact: true }),
    ).toBeVisible();
    const evidence = mixed.locator(".obpt-why-blocked__evidence");
    const evidenceSummary = evidence.locator("summary");
    await expect(evidence).not.toHaveAttribute("open", /.+/);
    await focusWithKeyboard(
      page,
      evidenceSummary,
      "blocker technical evidence disclosure",
    );
    await page.keyboard.press("Enter");
    await expect(evidence).toHaveAttribute("open", "");
    await expect(evidence).toContainText(
      "The support sync remains retryable at July 18, 2026 at 14:05 UTC.",
    );
    await expect(evidence).toContainText(
      "At block start, the support sync was executing.",
    );
    await expect(evidence.locator("pre")).toHaveAttribute("tabindex", "0");

    const unavailable = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("unavailable blockers", "why", "unavailable", "evidence"),
    );
    const unavailableWhy = unavailable.locator(".obpt-why-blocked");
    await expect(unavailableWhy).toHaveAttribute(
      "data-obpt-evidence-state",
      "unavailable",
    );
    await expect(unavailableWhy).toHaveAttribute(
      "data-obpt-completeness",
      "unknown",
    );
    await expect(
      unavailableWhy.locator(".obpt-why-blocked__blocker"),
    ).toHaveCount(0);
    await expect(unavailableWhy).toContainText(
      "Current blocker evidence is unavailable. Refresh the workflow or open Forensics.",
    );
    await expect(unavailableWhy).toContainText(
      "Current blocker evidence is unknown. Refresh the workflow before acting.",
    );
    await expect(unavailableWhy).not.toContainText(/no blockers|root cause/i);
    await expect(
      unavailableWhy.getByRole("button", { name: "Open workflow evidence" }),
    ).toBeVisible();
    await expectConfidentialityChannelsSafe(page);
  });

  test("group audit exposes immutable actors, outcomes, absolute time, missing copy, and redacted evidence", async ({
    page,
  }, testInfo) => {
    const matrix = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("audit actor outcome matrix", "audit", "actor", "outcome"),
    );
    const entries = matrix.locator("article.obpt-audit-entry");
    await expect(entries).toHaveCount(3);
    await expect(entries.locator("h2")).toHaveCount(3);
    expect(
      await entries
        .locator("time")
        .evaluateAll((elements) =>
          elements.map((element) => element.getAttribute("datetime")),
        ),
    ).toEqual([
      "2026-07-18T14:05:00Z",
      "2026-07-18T14:05:00Z",
      "2026-07-18T14:05:00Z",
    ]);
    await expect(entries.locator("time")).toHaveText([
      "July 18, 2026 at 14:05 UTC",
      "July 18, 2026 at 14:05 UTC",
      "July 18, 2026 at 14:05 UTC",
    ]);
    for (const [index, actor, outcome, state, label, tone, icon] of [
      [0, "Miyazaki Haruka", "Retry requested", "success", "Success", "success", "check"],
      [1, "Powertools system", "Request failed", "failed", "Failed", "danger", "alert"],
      [2, "Queue policy", "Request skipped", "skipped", "Skipped", "warning", "alert"],
    ] as const) {
      const entry = entries.nth(index);
      const status = entry.locator(".obpt-status-pill");
      await expect(entry).toContainText(actor);
      await expect(entry).toContainText(outcome);
      await expect(entry).toHaveAttribute("data-obpt-audit-outcome", state);
      await expect(status).toHaveAttribute("data-obpt-tone", tone);
      await expect(status.locator(".obpt-status-pill-icon")).toHaveAttribute(
        "data-obpt-icon",
        icon,
      );
      await expect(status.locator(".obpt-status-pill-label")).toHaveText(label);
    }

    const missing = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("missing audit fields", "audit", "missing"),
    );
    const missingEntry = missing.locator("article.obpt-audit-entry");
    await expect(missingEntry).toHaveCount(1);
    await expect(missingEntry.locator("h2")).toHaveText(
      "Powertools system evaluated job 01JZ8M5P999999999999999999.",
    );
    await expect(missingEntry).toContainText("No operator reason recorded");
    await expect(missingEntry).toContainText("Outcome not recorded");
    await expect(missingEntry).toContainText("Correlation not recorded");
    await expect(missingEntry.locator("time")).toHaveAttribute(
      "datetime",
      "2026-07-18T14:05:00Z",
    );
    await expect(missingEntry).not.toContainText("N/A");

    const redacted = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("redacted audit changes", "audit", "redacted", "changes"),
    );
    const redactedEntry = redacted.locator("article.obpt-audit-entry");
    const evidence = redactedEntry.locator(".obpt-audit-entry__evidence");
    const evidenceSummary = evidence.locator("summary");
    await expect(evidence).not.toHaveAttribute("open", /.+/);
    await focusWithKeyboard(
      page,
      evidenceSummary,
      "audit technical evidence disclosure",
    );
    await page.keyboard.press("Enter");
    await expect(evidence).toHaveAttribute("open", "");
    await expect(evidence).toContainText("credential");
    await expect(evidence).toContainText("[redacted]");
    await expect(evidence).toContainText("critical-mailer");
    await expect(evidence).toContainText("default");
    await expectConfidentialityChannelsSafe(page);
  });

  test("group 320 behavior keeps one explanation-to-audit chain, stacked actions, keyboard focus, and no overflow", async ({
    page,
  }, testInfo) => {
    test.skip(
      viewportNameFromProject(testInfo.project.name) !== "320",
      "320 behavior runs in chromium-320",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("narrow explanation and audit", "explain", "audit", "narrow"),
    );
    await expectOneResponsiveTree(stage, ".obpt-attention-card");
    await expectOneResponsiveTree(stage, ".obpt-why-blocked");
    await expectOneResponsiveTree(stage, "article.obpt-audit-entry");
    await expect(stage.getByRole("dialog")).toHaveCount(0);
    await expect(
      stage.locator(".obpt-attention-card__primary-action"),
    ).toHaveCSS("flex-direction", "column");
    await expect(
      stage.locator(".obpt-attention-card__secondary-actions"),
    ).toHaveCSS("flex-direction", "column");
    await expect(stage.locator(".obpt-why-blocked__next-action")).toHaveCSS(
      "flex-direction",
      "column",
    );
    await expect(stage).toContainText("01JZ8M5P999999999999999999");
    await expect(stage).toContainText("お客様通知 ✅");
    const action = stage.getByRole("button", { name: "Open retryable jobs" });
    await focusWithKeyboard(page, action, "320 explanation primary action");
    await expectNoHorizontalOverflow(stage);
    await expectConfidentialityChannelsSafe(page);
  });

  test("group wide behavior keeps explanation and action hierarchy readable without a modal", async ({
    page,
  }, testInfo) => {
    test.skip(
      viewportNameFromProject(testInfo.project.name) !== "wide",
      "wide behavior runs in chromium-wide",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory(
        "long attention content and actions",
        "attention",
        "long",
        "actions",
      ),
    );
    await expect(stage.getByRole("dialog")).toHaveCount(0);
    await expect(
      stage.locator(".obpt-attention-card__primary-action"),
    ).toHaveCount(1);
    await expect(
      stage.locator(".obpt-attention-card__secondary-actions"),
    ).toHaveCount(1);
    await expect(stage).toContainText("مرحبا ✅");
    await expectNoHorizontalOverflow(stage);
    await expectConfidentialityChannelsSafe(page);
  });

  test("group confirmation 200% zoom reflows long copy and preserves visible keyboard focus", async ({
    page,
  }, testInfo) => {
    const viewport = viewportNameFromProject(testInfo.project.name);
    test.skip(
      viewport !== "wide",
      "200% zoom proof executes only in chromium-wide",
    );
    expect(viewport, "the exact zoom grep must execute rather than skip").toBe(
      "wide",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("bulk confirmation", "confirm", "bulk"),
    );
    await apply200PercentZoom(page);
    await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);

    const dismiss = stage.getByRole("button", { name: "Keep current state" });
    const confirm = stage.getByRole("button", { name: /Retry/ });
    await stage.getByRole("textbox", { name: "Reason" }).focus();
    await page.keyboard.press("Tab");
    await page.keyboard.press("Tab");
    await expectVisibleFocus(dismiss, "200% zoom safe dismiss action");
    await page.keyboard.press("Tab");
    await expectVisibleFocus(confirm, "200% zoom confirmation action");
    const actions = stage.locator(".obpt-confirm-action__actions");
    await expect(actions).toHaveCSS("flex-wrap", "wrap");

    const geometry = await actions.evaluate((element) => {
      const parent = element.getBoundingClientRect();
      return Array.from(element.querySelectorAll<HTMLElement>("button")).map(
        (button) => {
          const rect = button.getBoundingClientRect();
          return {
            inside:
              rect.left >= parent.left - 1 &&
              rect.right <= parent.right + 1 &&
              rect.width > 0 &&
              rect.height > 0,
          };
        },
      );
    });
    expect(geometry).toHaveLength(2);
    expect(geometry.every(({ inside }) => inside)).toBe(true);

    const wrapped = await stage
      .locator(
        ".obpt-confirm-action__scope p, .obpt-confirm-action__consequence p, .obpt-confirm-action__reversibility p, .obpt-field label, .obpt-field-hint",
      )
      .evaluateAll((elements) =>
        elements.map((element) => {
          const style = getComputedStyle(element);
          return {
            clipped: element.scrollWidth > element.clientWidth + 1,
            whiteSpace: style.whiteSpace,
          };
        }),
      );
    expect(wrapped.length).toBeGreaterThan(0);
    expect(wrapped.every(({ clipped }) => !clipped)).toBe(true);
    expect(wrapped.every(({ whiteSpace }) => whiteSpace !== "nowrap")).toBe(
      true,
    );
    await expect(page.getByRole("dialog")).toHaveCount(1);
    await expectOneResponsiveTree(stage, ".obpt-confirm-action");
    await expectNoHorizontalOverflow(stage.getByRole("dialog"));
    await expectConfidentialityChannelsSafe(page);
  });

  test("group filter 200% zoom keeps disclosure, fields, actions, and applied truth usable", async ({
    page,
  }, testInfo) => {
    const viewport = viewportNameFromProject(testInfo.project.name);
    test.skip(
      viewport !== "wide",
      "200% zoom proof executes only in chromium-wide",
    );
    expect(viewport, "the exact zoom grep must execute rather than skip").toBe(
      "wide",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("active filter", "filter", "active", "clear"),
    );
    await apply200PercentZoom(page);
    await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);

    const toggle = stage.getByRole("button", { name: /Filters/ });
    await expect(toggle).toBeVisible();
    await toggle.focus();
    await page.keyboard.press("Enter");
    await expect(toggle).toHaveAttribute("aria-expanded", "true");
    await page.keyboard.press("Tab");
    await expectVisibleFocus(
      stage.getByRole("textbox", { name: "Queue" }),
      "200% zoom first filter field",
    );

    const fields = stage.locator("[data-obpt-filter-fields]");
    expect(
      await fields.evaluate(
        (element) =>
          getComputedStyle(element)
            .gridTemplateColumns.split(" ")
            .filter(Boolean).length,
      ),
    ).toBe(1);
    await expect(
      stage.getByRole("button", { name: "Apply filters" }),
    ).toBeVisible();
    await expect(stage.locator(".obpt-filter-bar__active-filter")).toHaveCount(
      2,
    );
    await expect(
      stage.getByRole("link", {
        name: "Remove Queue: critical-mailer filter",
      }),
    ).toBeVisible();

    const wrapping = await stage
      .locator(
        ".obpt-label, .obpt-filter-bar__active-value, .obpt-filter-bar__result-summary, .obpt-button, .obpt-link",
      )
      .evaluateAll((elements) =>
        elements.map((element) => ({
          clipped: element.scrollWidth > element.clientWidth + 1,
          nowrap: getComputedStyle(element).whiteSpace === "nowrap",
        })),
      );
    expect(wrapping.every(({ clipped, nowrap }) => !clipped && !nowrap)).toBe(
      true,
    );
    await expectOneResponsiveTree(stage, "[data-obpt-filter-fields]");
    await expectNoHorizontalOverflow(stage);
    await expectConfidentialityChannelsSafe(page);
  });

  test("group detail 200% zoom becomes one modal body with usable close focus", async ({
    page,
  }, testInfo) => {
    const viewport = viewportNameFromProject(testInfo.project.name);
    test.skip(
      viewport !== "wide",
      "200% zoom proof executes only in chromium-wide",
    );
    expect(viewport, "the exact zoom grep must execute rather than skip").toBe(
      "wide",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("long detail", "detail", "long"),
    );
    await apply200PercentZoom(page);
    await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);

    const detail = stage.locator("[data-obpt-detail-surface]");
    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "drawer");
    await expectNativeModal(detail, true);
    const close = stage.getByRole("button", { name: "Close job details" });
    await detail.getByRole("heading", { level: 2 }).focus();
    await page.keyboard.press("Tab");
    await expectVisibleFocus(close, "200% zoom detail close");
    await expect(detail.locator(".obpt-detail-surface__body")).toHaveCSS(
      "overflow-y",
      "auto",
    );
    await expect(stage).toContainText("01JZ8M5P999999999999999999");
    await expectOneResponsiveTree(stage, ".obpt-detail-surface__body");
    await expect(page.locator("dialog[open]")).toHaveCount(1);
    await expectNoHorizontalOverflow(detail);
    await expectConfidentialityChannelsSafe(page);
  });

  test("group explanation 200% zoom wraps current and snapshot evidence in one keyboard-usable tree", async ({
    page,
  }, testInfo) => {
    const viewport = viewportNameFromProject(testInfo.project.name);
    test.skip(
      viewport !== "wide",
      "200% zoom proof executes only in chromium-wide",
    );
    expect(viewport, "the exact zoom grep must execute rather than skip").toBe(
      "wide",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("live versus snapshot blockers", "why", "live", "snapshot"),
    );
    await apply200PercentZoom(page);
    await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);

    await expect(
      stage.getByText("Current state", { exact: true }),
    ).toBeVisible();
    await expect(
      stage.getByText("Block-start snapshot", { exact: true }),
    ).toBeVisible();
    const evidence = stage.locator(".obpt-why-blocked__evidence");
    const summary = evidence.locator("summary");
    await focusWithKeyboard(page, summary, "200% zoom blocker evidence");
    await page.keyboard.press("Enter");
    await expect(evidence).toHaveAttribute("open", "");
    await expect(evidence).toContainText(
      "At block start, the support sync was executing.",
    );
    const prose = stage.locator(
      ".obpt-why-blocked__title, .obpt-why-blocked__summary, .obpt-why-blocked__blocker-title, .obpt-why-blocked__blocker-summary, .obpt-why-blocked__facts dt, .obpt-why-blocked__facts dd, .obpt-why-blocked__impact p, .obpt-why-blocked__freshness p",
    );
    const wrapping = await prose.evaluateAll((elements) =>
      elements.map((element) => ({
        clipped: element.scrollWidth > element.clientWidth + 1,
        nowrap: getComputedStyle(element).whiteSpace === "nowrap",
      })),
    );
    expect(wrapping.length).toBeGreaterThan(0);
    expect(wrapping.every(({ clipped, nowrap }) => !clipped && !nowrap)).toBe(
      true,
    );
    await expectOneResponsiveTree(stage, ".obpt-why-blocked");
    await expectNoHorizontalOverflow(stage);
    await expectConfidentialityChannelsSafe(page);
  });

  test("group audit 200% zoom preserves absolute time, redacted evidence, keyboard focus, and safe wrapping", async ({
    page,
  }, testInfo) => {
    const viewport = viewportNameFromProject(testInfo.project.name);
    test.skip(
      viewport !== "wide",
      "200% zoom proof executes only in chromium-wide",
    );
    expect(viewport, "the exact zoom grep must execute rather than skip").toBe(
      "wide",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("redacted audit changes", "audit", "redacted", "changes"),
    );
    await apply200PercentZoom(page);
    await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);

    await expect(stage.locator("time")).toHaveAttribute(
      "datetime",
      "2026-07-18T14:05:00Z",
    );
    await expect(stage.locator("time")).toHaveText(
      "July 18, 2026 at 14:05 UTC",
    );
    const evidence = stage.locator(".obpt-audit-entry__evidence");
    const summary = evidence.locator("summary");
    await focusWithKeyboard(page, summary, "200% zoom audit evidence");
    await page.keyboard.press("Enter");
    await expect(evidence).toHaveAttribute("open", "");
    await expect(evidence).toContainText("[redacted]");
    await expect(evidence).toContainText("critical-mailer");
    const prose = stage.locator(
      ".obpt-audit-entry__title, .obpt-audit-entry__time, .obpt-description-list dt, .obpt-description-list dd, .obpt-audit-entry__evidence summary",
    );
    const wrapping = await prose.evaluateAll((elements) =>
      elements.map((element) => ({
        clipped: element.scrollWidth > element.clientWidth + 1,
        nowrap: getComputedStyle(element).whiteSpace === "nowrap",
      })),
    );
    expect(wrapping.length).toBeGreaterThan(0);
    expect(wrapping.every(({ clipped, nowrap }) => !clipped && !nowrap)).toBe(
      true,
    );
    await expectOneResponsiveTree(stage, "article.obpt-audit-entry");
    await expectNoHorizontalOverflow(stage);
    await expectConfidentialityChannelsSafe(page);
  });
});
