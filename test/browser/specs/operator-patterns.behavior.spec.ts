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
): Promise<{ story: Locator; trigger: Locator }> {
  await showcaseSupport.prepareShowcase(page, {
    theme: "light",
    viewportName: viewportNameFromProject(projectName),
  });

  const controlledId = `showcase-${story.id}-dialog`;
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

  test("group FilterBar disclosure, draft, Apply, remove, clear, URL, and status stay parent-owned", async ({
    page,
  }, testInfo) => {
    const story = groupStory("submit filter", "filter", "submit");
    const stage = await prepareGroupStory(page, testInfo.project.name, story);
    const toggle = stage.getByRole("button", { name: /Filters/ });
    const queue = stage.getByRole("combobox", { name: "Queue" });
    const state = stage.getByRole("combobox", { name: "State" });
    const originalUrl = page.url();

    await toggle.focus();
    await page.keyboard.press("Enter");
    await expect(toggle).toHaveAttribute("aria-expanded", "true");
    await page.keyboard.press("Space");
    await expect(toggle).toHaveAttribute("aria-expanded", "false");
    await toggle.click();

    await queue.selectOption("critical");
    await state.selectOption("retryable");
    await expect(page).toHaveURL(originalUrl);
    await expect(
      stage.getByText("Changes not applied.", { exact: true }),
    ).toBeVisible();

    await stage.getByRole("button", { name: "Apply filters" }).click();
    await expect(page).toHaveURL(/queue=critical.*state=retryable/);
    await expect(page).not.toHaveURL(/[?&]page=/);
    await expect(stage.getByRole("status")).toHaveText(
      "12 jobs match the applied filters.",
    );

    await stage
      .getByRole("link", { name: "Remove Queue: critical filter" })
      .click();
    await expect(page).not.toHaveURL(/queue=critical/);
    await stage.getByRole("link", { name: "Clear filters" }).click();
    await expect(page).not.toHaveURL(/queue=|state=/);
  });

  test("group detail tablet-adaptive mode is modal, inert, history-aware, and restores focus", async ({
    page,
  }, testInfo) => {
    test.skip(
      viewportNameFromProject(testInfo.project.name) !== "tablet",
      "tablet-adaptive behavior runs in chromium-tablet",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("adaptive modal detail", "detail", "modal"),
    );
    const trigger = stage.getByRole("button", { name: /Job 101 details/ });
    const detail = stage.locator("[data-obpt-detail-surface]");

    await trigger.click();
    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "modal");
    await expect(detail).toHaveAttribute("aria-modal", "true");
    await expect(page.locator("[data-obpt-showcase-main]")).toHaveAttribute(
      "inert",
      "",
    );
    await expect(page).toHaveURL(/detail=101/);

    await stage.getByRole("button", { name: /Job 202 details/ }).click();
    await expect(page).toHaveURL(/detail=202/);
    await detail.getByRole("button", { name: "Close job details" }).click();
    await expect(page).not.toHaveURL(/detail=/);
    await expect(trigger).toBeFocused();

    const backStage = await prepareGroupStory(
      page,
      testInfo.project.name,
      story,
    );
    const backDetail = backStage.locator("[data-obpt-detail-surface]");
    await backStage.getByRole("button", { name: /Job 101 details/ }).click();
    await page.goBack();
    await expect(backDetail).toHaveCount(0);
  });

  test("group detail wide behavior never traps focus and switches one tree on resize", async ({
    page,
  }, testInfo) => {
    test.skip(
      viewportNameFromProject(testInfo.project.name) !== "wide",
      "wide detail behavior runs in chromium-wide",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("wide inline detail", "detail", "inline"),
    );
    const detail = stage.locator("[data-obpt-detail-surface]");
    const after = page.locator("[data-obpt-after-group-stage]");

    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "inline");
    await expect(detail).not.toHaveAttribute("aria-modal", /.+/);
    await expectOneResponsiveTree(stage, "[data-obpt-detail-surface]");

    await detail.getByRole("link", { name: /full details/i }).focus();
    await page.keyboard.press("Tab");
    await expect(after).toBeFocused();

    await page.setViewportSize({ width: 768, height: 1000 });
    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "modal");
    await expectOneResponsiveTree(stage, "[data-obpt-detail-surface]");
  });

  test("group explanation and audit expose non-color truth, unknown evidence, absolute time, and no secrets", async ({
    page,
  }, testInfo) => {
    const explanation = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory(
        "attention status severity matrix",
        "attention",
        "status",
        "severity",
      ),
    );

    await expect(
      explanation.getByText("Unknown", { exact: true }),
    ).toBeVisible();
    await expect(
      explanation.locator("[data-obpt-status-label]"),
    ).not.toHaveCount(0);
    await expect(
      explanation.locator("[data-obpt-severity-label]"),
    ).not.toHaveCount(0);
    await expect(explanation.locator("time[datetime]")).not.toHaveCount(0);

    const auditStory = groupStory(
      "missing-field audit entry",
      "audit",
      "missing",
    );
    await activateTarget(page, auditStory);
    const audit = page.locator(auditStory.a11y);
    await expect(
      audit.getByText("No operator reason recorded", { exact: true }),
    ).toBeVisible();
    await expect(
      audit.getByText("Outcome not recorded", { exact: true }),
    ).toBeVisible();
    await expect(audit.locator('time[datetime^="2026-"]')).not.toHaveCount(0);
    await expect(audit).not.toContainText("N/A");
    await expectSecretAbsent(page, explanation);
    await expectSecretAbsent(page, audit);
  });

  test("group 320 behavior keeps one responsive tree, stacked actions, long content, and no overflow", async ({
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
    await expectOneResponsiveTree(stage, "[data-obpt-group-content]");
    await expect(stage.locator("[data-obpt-group-actions]")).toHaveCSS(
      "flex-direction",
      "column",
    );
    await expect(stage).toContainText("01JZ8M5P999999999999999999");
    await expectNoHorizontalOverflow(stage);
  });

  test("group tablet-adaptive behavior chooses the modal detail branch with one body tree", async ({
    page,
  }, testInfo) => {
    test.skip(
      viewportNameFromProject(testInfo.project.name) !== "tablet",
      "tablet-adaptive proof runs in chromium-tablet",
    );

    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("modal detail", "detail", "modal"),
    );
    await expect(stage.locator("[data-obpt-detail-surface]")).toHaveAttribute(
      "data-obpt-detail-mode",
      "modal",
    );
    await expectOneResponsiveTree(stage, ".obpt-detail-surface__body");
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
    await expect(stage.locator("[data-obpt-primary-action]")).toHaveCount(1);
    await expectNoHorizontalOverflow(stage);
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

  test("group 200% zoom filter reflows fields without losing draft and applied truth", async ({
    page,
  }, testInfo) => {
    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("invalid unapplied filter", "filter", "unapplied", "invalid"),
    );
    await apply200PercentZoom(page);

    await expect(stage.locator("[data-obpt-filter-fields]")).toHaveCSS(
      "grid-template-columns",
      /1fr/,
    );
    await expect(
      stage.getByText("Changes not applied.", { exact: true }),
    ).toBeVisible();
    await expectOneResponsiveTree(stage, "[data-obpt-filter-fields]");
    await expectNoHorizontalOverflow(stage);
  });

  test("group 200% zoom detail keeps one wrapped body and usable close focus", async ({
    page,
  }, testInfo) => {
    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("long detail", "detail", "long"),
    );
    await apply200PercentZoom(page);

    const close = stage.getByRole("button", { name: "Close job details" });
    await close.focus();
    await expectVisibleFocus(close, "200% zoom detail close");
    await expectOneResponsiveTree(stage, ".obpt-detail-surface__body");
    await expectNoHorizontalOverflow(stage);
  });

  test("group 200% zoom explanation wraps current and snapshot evidence in one tree", async ({
    page,
  }, testInfo) => {
    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("live versus snapshot blockers", "why", "live", "snapshot"),
    );
    await apply200PercentZoom(page);

    await expect(
      stage.getByText("Current state", { exact: true }),
    ).toBeVisible();
    await expect(
      stage.getByText("Block-start snapshot", { exact: true }),
    ).toBeVisible();
    await expectOneResponsiveTree(stage, "[data-obpt-why-blocked]");
    await expectNoHorizontalOverflow(stage);
  });

  test("group 200% zoom audit preserves absolute time, missing copy, and safe wrapping", async ({
    page,
  }, testInfo) => {
    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("missing audit fields", "audit", "missing"),
    );
    await apply200PercentZoom(page);

    await expect(stage.locator('time[datetime^="2026-"]')).toBeVisible();
    await expect(
      stage.getByText("No operator reason recorded", { exact: true }),
    ).toBeVisible();
    await expectOneResponsiveTree(stage, "article.obpt-audit-entry");
    await expectNoHorizontalOverflow(stage);
    await expectSecretAbsent(page, stage);
  });
});
