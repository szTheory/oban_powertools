import { expect, test, type Locator, type Page } from "@playwright/test";
import { viewportNameFromProject } from "../support/deterministic";
import * as manifestSupport from "../support/manifest";
import * as showcaseSupport from "../support/showcase";

type ShowcaseGroupStory = {
  id: string;
  kind: "group";
  component: string;
  components: string[];
  name: string;
  description: string;
  variant: string[];
  state: string[];
  activation: "none" | "overlay";
  story: string;
  snapshot: string;
  a11y: string;
};

type GroupManifestSupport = typeof manifestSupport & {
  groupStories?: ShowcaseGroupStory[];
};

type GroupShowcaseSupport = typeof showcaseSupport & {
  activateTarget?: (page: Page, story: ShowcaseGroupStory) => Promise<void>;
};

const groupStories = (manifestSupport as GroupManifestSupport).groupStories;
const activateTarget = (showcaseSupport as GroupShowcaseSupport).activateTarget;
const secretSentinel = "PHASE78-GROUP-SECRET-SENTINEL";

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

  const outline = await locator.evaluate((element) => {
    const style = getComputedStyle(element);
    return {
      color: style.outlineColor,
      style: style.outlineStyle,
      width: Number.parseFloat(style.outlineWidth),
    };
  });

  expect(outline.style, `${label} should have an outline style`).not.toBe(
    "none",
  );
  expect(
    outline.width,
    `${label} should have a non-zero outline`,
  ).toBeGreaterThan(0);
  expect(outline.color, `${label} should have a visible outline`).not.toBe(
    "rgba(0, 0, 0, 0)",
  );
}

async function expectOneResponsiveTree(
  story: Locator,
  selector: string,
): Promise<void> {
  await expect(story.locator(selector)).toHaveCount(1);
  await expect(story.locator("[data-obpt-mobile-copy]")).toHaveCount(0);
  await expect(story.locator("[data-obpt-desktop-copy]")).toHaveCount(0);
}

async function expectSecretAbsent(page: Page, story: Locator): Promise<void> {
  await expect(story).not.toContainText(secretSentinel);

  const leaked = await story.evaluate((element, sentinel) => {
    const channels = [element.textContent ?? "", element.innerHTML];

    for (const candidate of element.querySelectorAll<HTMLElement>("*")) {
      for (const attribute of Array.from(candidate.attributes)) {
        if (
          attribute.name === "title" ||
          attribute.name === "value" ||
          attribute.name.startsWith("data-") ||
          attribute.name.startsWith("aria-") ||
          attribute.name.includes("href")
        ) {
          channels.push(attribute.value);
        }
      }
    }

    return channels.some((value) => value.includes(sentinel));
  }, secretSentinel);

  expect(leaked).toBe(false);
  expect(await page.locator(`text=${secretSentinel}`).count()).toBe(0);
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
    const stage = await prepareGroupStory(page, testInfo.project.name, story);
    const dialog = stage.getByRole("dialog");
    const reason = dialog.getByRole("textbox", { name: "Reason" });
    const focusable = dialog.locator(
      'button:not([disabled]), a[href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex="0"]',
    );
    const first = focusable.first();
    const last = focusable.last();

    await expect(dialog).toHaveAttribute("aria-modal", "true");
    await expect(reason).toBeFocused();

    await first.focus();
    await page.keyboard.press("Shift+Tab");
    await expect(last).toBeFocused();
    await page.keyboard.press("Tab");
    await expect(first).toBeFocused();

    await page.keyboard.press("Escape");
    await expect(dialog).toHaveCount(0);
    await expect(
      page.locator(`[data-obpt-activate-target="${story.id}"]`),
    ).toBeFocused();

    await activateTarget(page, story);
    await page
      .locator(`[data-obpt-activate-target="${story.id}"]`)
      .evaluate((element) => element.remove());
    await page.keyboard.press("Escape");
    await expect(page.locator("[data-obpt-logical-fallback]")).toBeFocused();
  });

  test("group confirmation keeps server truth for busy, duplicate, partial order, and one receipt", async ({
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
      pendingDialog.getByRole("button", { name: /Retry/ }),
    ).toBeDisabled();
    await expect(
      pendingDialog.getByRole("button", { name: /Keep current state/ }),
    ).toHaveCount(0);

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
    const rows = partial.locator("[data-obpt-operator-result]");
    await expect(rows).toHaveCount(3);
    await expect(rows).toContainText(["Success", "Failed", "Skipped"]);
    await expect(
      partial.locator("[data-obpt-confirm-result-heading]"),
    ).toBeFocused();
    await expect(
      partial.getByText("Create a fresh preview.", { exact: true }),
    ).toBeVisible();

    const valid = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory(
        "single reversible confirmation",
        "confirm",
        "single",
        "reversible",
      ),
    );
    await valid
      .getByRole("textbox", { name: "Reason" })
      .fill("Incident response retry");
    const submit = valid.getByRole("button", { name: /Retry/ });
    await submit.dispatchEvent("click");
    await submit.dispatchEvent("click");
    await expect(page.getByRole("status", { name: /receipt/i })).toHaveCount(1);
    await expect(page.locator("[data-obpt-mutation-receipt]")).toHaveCount(1);
    await expectSecretAbsent(page, partial);
    await expectSecretAbsent(page, valid);
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

  test("group 200% zoom confirmation reflows actions and preserves visible keyboard focus", async ({
    page,
  }, testInfo) => {
    const stage = await prepareGroupStory(
      page,
      testInfo.project.name,
      groupStory("bulk confirmation", "confirm", "bulk"),
    );
    await apply200PercentZoom(page);

    const confirm = stage.getByRole("button", { name: /Retry/ });
    await confirm.focus();
    await expectVisibleFocus(confirm, "200% zoom confirmation action");
    await expect(stage.locator("[data-obpt-confirm-actions]")).toHaveCSS(
      "flex-direction",
      "column",
    );
    await expectOneResponsiveTree(stage, "[data-obpt-confirm-action]");
    await expectNoHorizontalOverflow(stage);
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
