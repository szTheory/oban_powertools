import {
  expect,
  test,
  type APIRequestContext,
  type Locator,
  type Page,
} from "@playwright/test";
import * as manifestSupport from "../support/manifest";

type PageStory = {
  id: string;
  kind: "page";
  page: "overview" | "cron" | "limiters" | "audit";
  components: string[];
  variant: string[];
  state: string[];
  activation: "none" | "detail" | "confirmation";
  story: string;
  snapshot: string;
  a11y: string;
};

type ManifestPageStory = Omit<PageStory, "page"> & {
  page:
    | PageStory["page"]
    | "jobs"
    | "forensics"
    | "batches"
    | "workflows"
    | "lifeline";
};

type Phase79FixtureState = {
  project: "chromium-320" | "chromium-tablet" | "chromium-wide";
  run: string;
  cron: {
    firstEntry: string;
    secondEntry: string;
    pausedEntry: string;
    recoveryEntry: string;
  };
  limiters: {
    firstResource: string;
    secondResource: string;
    blockedResource: string;
  };
  audit: {
    firstEvent: string;
    secondEvent: string;
    boundaryPage: number;
  };
  counts: {
    cronEntries: number;
    limiterResources: number;
    auditFiltered: number;
    auditNewerUnrelated: number;
    overviewActive: number;
    overviewResolved: number;
  };
  actors: ["operator", "read_only"];
  confidentialitySentinels: string[];
};

type Phase79Actor = "operator" | "read_only";
type Phase79Recovery =
  "expired" | "drifted" | "consumed" | "skipped";

type Phase79FixtureHelpers = {
  resetPhase79BrowserFixture: (
    request: APIRequestContext,
    options: { secret: string; project: string },
  ) => Promise<Phase79FixtureState>;
  authenticatePhase79Actor: (
    page: Page,
    options: { actor: Phase79Actor; secret: string },
  ) => Promise<void>;
  setPhase79CronRecovery: (
    request: APIRequestContext,
    options: { entry: string; recovery: Phase79Recovery; secret: string },
  ) => Promise<void>;
};

type FutureManifestSupport = typeof manifestSupport & {
  pageStories?: ManifestPageStory[];
};

const schemaVersion = Number(
  (manifestSupport as unknown as { manifest?: { schema_version?: unknown } })
    .manifest?.schema_version,
);
const allPageStories = (manifestSupport as FutureManifestSupport).pageStories;

if (
  schemaVersion !== 8 ||
  !Array.isArray(allPageStories) ||
  allPageStories.length !== 99
) {
  throw new Error(
    "Phase 79 compatibility requires the schema-8 nine-family graph with exactly 99 page targets",
  );
}

const fixtureContract = {
  owner: "Plan 79-10 isolated authenticated reset/auth/recovery prerequisite",
  helperTask: "Task 79-10-03",
  helperModule: "../support/phase79-fixtures",
  secretEnvironmentVariable: "PHASE79_BROWSER_FIXTURE_SECRET",
} as const;

const fixtureHelperModule = fixtureContract.helperModule;
const expectedPageFamilyCounts = {
  overview: 3,
  cron: 8,
  limiters: 4,
  audit: 4,
} as const;
const wave1PageFamilies = [
  "overview",
  "cron",
  "limiters",
  "audit",
] as const;
const expectedWave1PageStoryIds = [
  "page-overview-all-quiet",
  "page-overview-fixed-order-nonzero",
  "page-overview-long-unicode",
  "page-cron-selected-detail",
  "page-cron-permission-denied",
  "page-cron-pause-confirmation",
  "page-cron-resume-confirmation",
  "page-cron-run-now-confirmation",
  "page-cron-expired-recovery",
  "page-cron-drifted-recovery",
  "page-cron-skipped-partial-recovery",
  "page-limiters-runnable-empty-current",
  "page-limiters-blocked-evidence-layers",
  "page-limiters-unavailable",
  "page-limiters-forensics-unavailable",
  "page-audit-empty",
  "page-audit-filtered-boundary-page",
  "page-audit-selected-long-unicode",
  "page-audit-selected-missing-fields",
] as const;

function isWave1PageStory(story: ManifestPageStory): story is PageStory {
  return wave1PageFamilies.some((page) => page === story.page);
}

const wave1PageStories = allPageStories.filter(isWave1PageStory);

if (
  JSON.stringify(wave1PageStories.map((story) => story.id)) !==
  JSON.stringify(expectedWave1PageStoryIds)
) {
  throw new Error(
    `Phase 79 compatibility requires the exact ordered 19-story Wave 1 set, got ${JSON.stringify(wave1PageStories.map((story) => story.id))}`,
  );
}

const pageFamilyCounts = wave1PageStories.reduce<Record<string, number>>(
  (counts, story) => {
    counts[story.page] = (counts[story.page] ?? 0) + 1;
    return counts;
  },
  {},
);

if (
  JSON.stringify(pageFamilyCounts) !== JSON.stringify(expectedPageFamilyCounts)
) {
  throw new Error(
    `Phase 79 pageStories must retain the UI-SPEC family counts, got ${JSON.stringify(pageFamilyCounts)}`,
  );
}

let fixtureHelpers: Phase79FixtureHelpers;
let fixtureState: Phase79FixtureState;
let fixtureSecret: string;

async function loadFixtureHelpers(): Promise<Phase79FixtureHelpers> {
  let imported: Partial<Phase79FixtureHelpers>;

  try {
    imported = (await import(
      fixtureHelperModule
    )) as Partial<Phase79FixtureHelpers>;
  } catch (error) {
    throw new Error(
      `${fixtureContract.owner} is missing ${fixtureContract.helperModule} from ${fixtureContract.helperTask}: ${String(error)}`,
    );
  }

  for (const helper of [
    "resetPhase79BrowserFixture",
    "authenticatePhase79Actor",
    "setPhase79CronRecovery",
  ] as const) {
    if (typeof imported[helper] !== "function") {
      throw new Error(
        `${fixtureContract.helperTask} must export ${helper}; connected page tests never fall back to ambient example-host seeds`,
      );
    }
  }

  return imported as Phase79FixtureHelpers;
}

test.beforeEach(async ({ page, request }, testInfo) => {
  fixtureSecret = process.env[fixtureContract.secretEnvironmentVariable] ?? "";
  if (fixtureSecret.length === 0) {
    throw new Error(
      `${fixtureContract.owner} requires ${fixtureContract.secretEnvironmentVariable}; the one-entry ambient seed is not a valid fallback`,
    );
  }

  fixtureHelpers = await loadFixtureHelpers();
  fixtureState = await fixtureHelpers.resetPhase79BrowserFixture(request, {
    secret: fixtureSecret,
    project: testInfo.project.name,
  });
  expect(fixtureState.project).toBe(testInfo.project.name);
  expect(fixtureState.run).toMatch(/^[a-z0-9][a-z0-9_-]{0,47}$/);
  expect(fixtureState.counts).toEqual({
    cronEntries: 3,
    limiterResources: 2,
    auditFiltered: 45,
    auditNewerUnrelated: 21,
    overviewActive: 1,
    overviewResolved: 1,
  });
  expect(fixtureState.actors).toEqual(["operator", "read_only"]);
  expect(new Set(Object.values(fixtureState.cron)).size).toBe(3);
  expect(fixtureState.cron.pausedEntry).toBe(fixtureState.cron.secondEntry);
  expect(new Set(Object.values(fixtureState.limiters)).size).toBe(2);
  expect(fixtureState.limiters.blockedResource).toBe(
    fixtureState.limiters.secondResource,
  );
  expect(fixtureState.audit.firstEvent).not.toBe(
    fixtureState.audit.secondEvent,
  );
  await fixtureHelpers.authenticatePhase79Actor(page, {
    actor: "operator",
    secret: fixtureSecret,
  });
});

async function openConnectedPage(page: Page, path: string): Promise<void> {
  await page.goto(path);
  await expect(page.locator("[data-phx-main]")).toHaveCount(1);
  await expect
    .poll(() =>
      page.evaluate(() =>
        Boolean(
          (
            window as unknown as {
              liveSocket?: { isConnected: () => boolean };
            }
          ).liveSocket?.isConnected(),
        ),
      ),
    )
    .toBe(true);
  expect(new URL(page.url()).pathname).not.toContain("_showcase");
}

function auditEvidenceButton(page: Page, eventId: string): Locator {
  return page
    .locator(`#audit-record-${eventId}`)
    .locator("xpath=ancestor::tr")
    .getByRole("button", { name: /View evidence/ });
}

async function expectNoHorizontalOverflow(root: Locator): Promise<void> {
  const overflow = await root.evaluate((element) => ({
    root: Math.ceil(element.scrollWidth - element.clientWidth),
    body: Math.ceil(document.body.scrollWidth - document.body.clientWidth),
    document: Math.ceil(
      document.documentElement.scrollWidth -
        document.documentElement.clientWidth,
    ),
  }));

  expect(overflow.root).toBeLessThanOrEqual(1);
  expect(overflow.body).toBeLessThanOrEqual(1);
  expect(overflow.document).toBeLessThanOrEqual(1);
}

async function expectVisibleFocus(
  locator: Locator,
  label: string,
): Promise<void> {
  await expect(locator, `${label} should be focused`).toBeFocused();

  const evidence = await locator.evaluate((element) => {
    const style = getComputedStyle(element);
    const rect = element.getBoundingClientRect();
    return {
      outlineStyle: style.outlineStyle,
      outlineWidth: Number.parseFloat(style.outlineWidth),
      visible:
        rect.width > 0 &&
        rect.height > 0 &&
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.right <= window.innerWidth &&
        rect.bottom <= window.innerHeight,
    };
  });

  expect(evidence.outlineStyle).not.toBe("none");
  expect(evidence.outlineWidth).toBeGreaterThan(0);
  expect(evidence.visible).toBe(true);
}

async function expectOneResponsiveTree(page: Page): Promise<void> {
  await expect(
    page.locator("[data-obpt-mobile-copy], [data-obpt-desktop-copy]"),
  ).toHaveCount(0);

  for (const selector of [
    "#cron-entry-detail",
    "#limiter-detail",
    "#audit-detail",
  ]) {
    expect(await page.locator(selector).count()).toBeLessThanOrEqual(1);
  }

  expect(await page.getByRole("dialog").count()).toBeLessThanOrEqual(1);
}

async function expectConfidentialityChannelsSafe(page: Page): Promise<void> {
  const sentinels = [...fixtureState.confidentialitySentinels, fixtureSecret];
  const leaks = await page
    .locator("html")
    .evaluate((documentElement, forbidden) => {
      const channels = [
        documentElement.textContent ?? "",
        documentElement.innerHTML,
        documentElement.outerHTML,
        document.URL,
      ];

      for (const element of documentElement.querySelectorAll<HTMLElement>(
        "*",
      )) {
        channels.push(
          element.innerText ?? "",
          element.getAttribute("value") ?? "",
          element.getAttribute("title") ?? "",
          element.getAttribute("href") ?? "",
          element.getAttribute("action") ?? "",
        );

        if (
          element instanceof HTMLInputElement ||
          element instanceof HTMLTextAreaElement ||
          element instanceof HTMLSelectElement
        ) {
          channels.push(element.value);
        }

        for (const attribute of Array.from(element.attributes)) {
          channels.push(`${attribute.name}=${attribute.value}`);
        }
      }

      return forbidden.filter((sentinel) =>
        channels.some((channel) => channel.includes(sentinel)),
      );
    }, sentinels);

  expect(leaks).toEqual([]);
}

async function apply200PercentZoom(page: Page): Promise<void> {
  const original = page.viewportSize();
  if (!original)
    throw new Error("200% zoom requires a configured Chromium viewport");

  const session = await page.context().newCDPSession(page);
  await session.send("Emulation.setDeviceMetricsOverride", {
    width: Math.floor(original.width / 2),
    height: Math.floor(original.height / 2),
    screenWidth: original.width,
    screenHeight: original.height,
    deviceScaleFactor: 2,
    mobile: false,
  });

  expect(
    await page.evaluate(() => ({
      ratio: window.devicePixelRatio,
      width: window.innerWidth,
    })),
  ).toEqual({ ratio: 2, width: Math.floor(original.width / 2) });
}

function exactUrl(path: string): RegExp {
  return new RegExp(`${path.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`);
}

test.describe("Phase 79 connected page contracts", () => {
  test("overview preserves fixed current-to-continuity order and named destinations", async ({
    page,
  }) => {
    await openConnectedPage(page, "/ops/jobs");
    const root = page.locator("#overview-page");

    await expect(
      root.getByRole("heading", { level: 1, name: "Overview" }),
    ).toHaveCount(1);
    await expect(
      root.getByRole("heading", { level: 2, name: "Current attention" }),
    ).toBeVisible();
    await expect(root.locator("#overview-needs-review")).toBeVisible();
    await expect(root.locator("#overview-blocked")).toBeVisible();
    await expect(root.locator("#overview-waiting")).toBeVisible();
    await expect(root.locator("#overview-bridge-follow-up")).toBeVisible();
    await expect(root.locator("#overview-runnable")).toBeVisible();
    await expect(root.locator("#overview-resolved-continuity")).toBeVisible();

    const order = await root
      .locator(
        "#overview-needs-review, #overview-blocked, #overview-waiting, #overview-bridge-follow-up, #overview-runnable, #overview-resolved-continuity",
      )
      .evaluateAll((elements) => elements.map((element) => element.id));
    expect(order).toEqual([
      "overview-needs-review",
      "overview-blocked",
      "overview-waiting",
      "overview-bridge-follow-up",
      "overview-runnable",
      "overview-resolved-continuity",
    ]);
    await expect(
      root.getByRole("link", { name: "Inspect in Oban Web" }),
    ).toBeVisible();
    await expect(root).not.toContainText(/recently|global total/i);
    await expect(root.locator('[role="alert"], [aria-live]')).toHaveCount(0);
  });

  test("cron first-open push, switch-close replace, Back, and direct reload preserve selection", async ({
    page,
  }) => {
    await openConnectedPage(page, "/ops/jobs/cron");

    await page
      .getByRole("link", { name: fixtureState.cron.firstEntry, exact: true })
      .click();
    await expect(page).toHaveURL(
      exactUrl(
        `/ops/jobs/cron?entry=${encodeURIComponent(fixtureState.cron.firstEntry)}`,
      ),
    );
    await expect(page.locator("#cron-entry-detail")).toBeVisible();

    const secondUrl = `/ops/jobs/cron?entry=${encodeURIComponent(fixtureState.cron.secondEntry)}`;
    const detail = page.locator("#cron-entry-detail");
    if ((await detail.getAttribute("data-obpt-detail-mode")) === "inline") {
      await page
        .getByRole("link", { name: fixtureState.cron.secondEntry, exact: true })
        .click();
      await expect(page).toHaveURL(exactUrl(secondUrl));
      await page.goBack();
      await expect(page).toHaveURL(exactUrl("/ops/jobs/cron"));
    } else {
      await detail.locator("[data-obpt-detail-close]").click();
      await expect(page).toHaveURL(exactUrl("/ops/jobs/cron"));
    }

    await page.goto(secondUrl);
    await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);
    await page.reload();
    await expect(page.locator("#cron-entry-detail")).toBeVisible();
    await page.locator("#cron-entry-detail [data-obpt-detail-close]").click();
    await expect(page).toHaveURL(exactUrl("/ops/jobs/cron"));
  });

  test("limiters use named table actions and canonical detail history without mutation affordances", async ({
    page,
  }) => {
    await openConnectedPage(page, "/ops/jobs/limiters");
    const firstAction = page.getByRole("link", {
      name: `Review blockers for ${fixtureState.limiters.firstResource}`,
    });
    const secondAction = page.getByRole("link", {
      name: `Review blockers for ${fixtureState.limiters.secondResource}`,
    });

    await firstAction.click();
    const detail = page.locator("#limiter-detail");
    await expect(detail).toBeVisible();
    if ((await detail.getAttribute("data-obpt-detail-mode")) === "inline") {
      await secondAction.click();
      await expect(page).toHaveURL(
        exactUrl(
          `/ops/jobs/limiters?resource=${encodeURIComponent(fixtureState.limiters.secondResource)}`,
        ),
      );
    }
    await detail.locator("[data-obpt-detail-close]").click();
    await expect(page).toHaveURL(exactUrl("/ops/jobs/limiters"));
    await expect(page.locator('input[type="checkbox"]')).toHaveCount(0);
    await expect(
      page.getByRole("button", { name: /pause|resume|run|retry|execute/i }),
    ).toHaveCount(0);
  });

  test("audit filter-page-selection composition preserves scope and immutable evidence history", async ({
    page,
  }) => {
    const pageNumber = fixtureState.audit.boundaryPage;
    await openConnectedPage(page, `/ops/jobs/audit?page=${pageNumber}`);
    await expect(page.locator("#audit-records")).toBeVisible();

    await page
      .getByRole("textbox", { name: "Resource type" })
      .fill("cron_entry");
    await page
      .getByRole("textbox", { name: "Resource ID" })
      .fill(fixtureState.cron.firstEntry);
    await page.getByRole("button", { name: "Apply filters" }).click();
    await expect(page).not.toHaveURL(/[?&]page=/);
    await expect(page).not.toHaveURL(/[?&]event=/);

    const firstEvidence = auditEvidenceButton(
      page,
      fixtureState.audit.firstEvent,
    );
    await expect(firstEvidence).toHaveAccessibleName(
      /View evidence for .+ on .+/,
    );
    await firstEvidence.click();
    await expect(page).toHaveURL(
      new RegExp(`[?&]event=${fixtureState.audit.firstEvent}(?:&|$)`),
    );
    await expect(page.locator("#audit-detail")).toBeVisible();

    const secondEvidence = auditEvidenceButton(
      page,
      fixtureState.audit.secondEvent,
    );
    await expect(secondEvidence).toHaveAccessibleName(
      /View evidence for .+ on .+/,
    );
    if (
      (await page
        .locator("#audit-detail")
        .getAttribute("data-obpt-detail-mode")) !== "inline"
    ) {
      await page.locator("#audit-detail [data-obpt-detail-close]").click();
    }
    await secondEvidence.click();
    await expect(page).toHaveURL(
      new RegExp(`[?&]event=${fixtureState.audit.secondEvent}(?:&|$)`),
    );
    await page.locator("#audit-detail [data-obpt-detail-close]").click();
    await expect(page).not.toHaveURL(/[?&]event=/);
    await page.goBack();
    await expect(page.locator("#audit-records")).toBeVisible();

    await page.goto(
      `/ops/jobs/audit?page=${pageNumber}&event=${encodeURIComponent(fixtureState.audit.firstEvent)}`,
    );
    await page.reload();
    await expect(page.locator("#audit-detail")).toBeVisible();
    await expect(page.locator("#audit-detail")).toContainText("Recorded at");
  });

  test("cron one-dialog confirmation traps focus, handles Escape, and restores its action", async ({
    page,
  }) => {
    await openConnectedPage(
      page,
      `/ops/jobs/cron?entry=${encodeURIComponent(fixtureState.cron.firstEntry)}`,
    );
    const invoker = page.getByRole("button", { name: "Pause cron entry" });
    await invoker.focus();
    await invoker.click();

    const dialog = page.locator("#cron-confirmation-dialog");
    await expect(dialog).toBeVisible();
    await expect(page.locator("#cron-entry-detail")).toHaveCount(0);
    await expect(page.getByRole("dialog")).toHaveCount(1);
    await expect(dialog.getByRole("heading", { level: 2 })).toBeFocused();
    await expect(
      dialog.getByRole("heading", { level: 3, name: "Consequence" }),
    ).toBeVisible();

    const controls = dialog.locator(
      'button:not([disabled]), input:not([disabled]), textarea:not([disabled]), [tabindex="0"]',
    );
    await controls.last().focus();
    await page.keyboard.press("Tab");
    expect(
      await dialog.evaluate((element) =>
        element.contains(document.activeElement),
      ),
    ).toBe(true);

    await page.keyboard.press("Escape");
    await expect(dialog).toHaveCount(0);
    await expect(page.locator("#cron-entry-detail")).toBeVisible();
    await expect(invoker).toBeFocused();
  });

  test("cron recovery remains explicit and safe across expired, drifted, consumed, and skipped results", async ({
    page,
    request,
  }, testInfo) => {
    for (const recovery of [
      "expired",
      "drifted",
      "consumed",
      "skipped",
    ] as Phase79Recovery[]) {
      fixtureState = await fixtureHelpers.resetPhase79BrowserFixture(request, {
        secret: fixtureSecret,
        project: testInfo.project.name,
      });
      await fixtureHelpers.authenticatePhase79Actor(page, {
        actor: "operator",
        secret: fixtureSecret,
      });
      await openConnectedPage(
        page,
        `/ops/jobs/cron?entry=${encodeURIComponent(fixtureState.cron.recoveryEntry)}`,
      );
      await page.getByRole("button", { name: "Run cron entry now" }).click();
      await fixtureHelpers.setPhase79CronRecovery(request, {
        entry: fixtureState.cron.recoveryEntry,
        recovery,
        secret: fixtureSecret,
      });
      await page
        .getByRole("textbox", { name: "Reason" })
        .fill("Preserve this safe reason");
      await page.getByRole("button", { name: "Run cron entry now" }).click();

      const dialog = page.locator("#cron-confirmation-dialog");
      await expect(dialog).toBeVisible();
      await expect(
        dialog.getByRole("button", { name: "Create new preview" }),
      ).toBeVisible();
      const recoveryCopy = {
        expired: /expired/i,
        drifted: /out of date|drifted/i,
        consumed: /already used|consumed/i,
        skipped: /skipped/i,
      }[recovery];
      await expect(dialog).toContainText(recoveryCopy);
      await expect(dialog).toContainText(
        "Reason draft: Preserve this safe reason",
      );
      await expect(page.locator("#cron-receipt")).toHaveCount(0);
      await expect(dialog).not.toContainText(
        /job ran successfully|action completed successfully/i,
      );
      await dialog.getByRole("button", { name: "Create new preview" }).click();
      await expect(dialog.getByRole("textbox", { name: "Reason" })).toHaveValue(
        "Preserve this safe reason",
      );
      await dialog
        .getByRole("button", { name: /Keep current schedule|Close/ })
        .click();
    }
  });

  test("cron duplicate activation produces one repository-backed receipt and Audit destination", async ({
    page,
  }) => {
    await openConnectedPage(
      page,
      `/ops/jobs/cron?entry=${encodeURIComponent(fixtureState.cron.firstEntry)}`,
    );
    await page.getByRole("button", { name: "Pause cron entry" }).click();
    await page
      .getByRole("textbox", { name: "Reason" })
      .fill("Planned maintenance");
    const confirm = page.getByRole("button", { name: "Pause cron entry" });
    await confirm.evaluate((button: HTMLButtonElement) => {
      button.click();
      button.click();
    });

    const receipt = page.locator("#cron-receipt");
    await expect(receipt).toHaveCount(1);
    await expect(receipt.getByRole("link", { name: /audit/i })).toHaveAttribute(
      "href",
      /\/ops\/jobs\/audit\?resource_type=cron_entry/,
    );
    await expect(page.locator("#cron-confirmation-dialog")).toHaveCount(0);
    await expect(page.locator("#cron-entry-detail")).toBeVisible();
  });

  test("wide details remain nonmodal and resize as one persistent tree without a focus trap", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1440, height: 1000 });
    await openConnectedPage(
      page,
      `/ops/jobs/limiters?resource=${encodeURIComponent(fixtureState.limiters.blockedResource)}`,
    );
    const detail = page.locator("#limiter-detail");
    await detail.evaluate((element) =>
      element.setAttribute("data-test-identity", "phase79-detail"),
    );
    await page.setViewportSize({ width: 900, height: 1000 });
    await page.setViewportSize({ width: 1440, height: 1000 });

    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "inline");
    await expect(detail).not.toHaveAttribute("aria-modal", /.+/);
    const overviewLink = page
      .getByLabel("Powertools surfaces")
      .getByRole("link", { name: "Overview", exact: true });
    await overviewLink.focus();
    await expect(overviewLink).toBeFocused();

    await page.setViewportSize({ width: 768, height: 1000 });
    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "drawer");
    await expect(detail).toHaveAttribute("aria-modal", "true");
    await expect(detail).toHaveAttribute(
      "data-test-identity",
      "phase79-detail",
    );
    await expectOneResponsiveTree(page);

    await page.setViewportSize({ width: 1440, height: 1000 });
    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "inline");
    await expect(detail).not.toHaveAttribute("aria-modal", /.+/);
    await expect(detail).toHaveAttribute(
      "data-test-identity",
      "phase79-detail",
    );
  });

  test("authorization keeps read-only pages nonmutating and cron controls server-derived", async ({
    page,
  }) => {
    await fixtureHelpers.authenticatePhase79Actor(page, {
      actor: "read_only",
      secret: fixtureSecret,
    });
    await openConnectedPage(
      page,
      `/ops/jobs/cron?entry=${encodeURIComponent(fixtureState.cron.firstEntry)}`,
    );
    await expect(
      page.getByRole("button", { name: "Pause cron entry" }),
    ).toBeDisabled();
    await expect(
      page.getByText(/Permission: read-only/i).first(),
    ).toBeVisible();
    await expect(page.locator("#cron-confirmation-dialog")).toHaveCount(0);

    await openConnectedPage(page, "/ops/jobs/audit");
    await expect(page.locator('input[type="checkbox"]')).toHaveCount(0);
    await expect(
      page.getByRole("button", { name: /pause|resume|run|retry|execute/i }),
    ).toHaveCount(0);
  });

  test("320 page reflow keeps named table actions, one tree, visible focus, and no overflow", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 320, height: 900 });

    for (const path of [
      "/ops/jobs",
      "/ops/jobs/cron",
      "/ops/jobs/limiters",
      `/ops/jobs/audit?page=${fixtureState.audit.boundaryPage}`,
    ]) {
      await openConnectedPage(page, path);
      const root = page.locator(
        "#overview-page, #cron-page, #limiters-page, #audit-page",
      );
      await expect(root).toHaveCount(1);
      await expect(root.getByRole("heading", { level: 1 })).toHaveCount(1);
      await expectOneResponsiveTree(page);
      await expectNoHorizontalOverflow(root);
    }

    await openConnectedPage(page, "/ops/jobs/limiters");
    const namedAction = page.getByRole("link", {
      name: `Review blockers for ${fixtureState.limiters.firstResource}`,
    });
    await namedAction.focus();
    await expectVisibleFocus(namedAction, "320 limiter table action");
  });

  test("200% zoom reflows wide detail with visible keyboard focus and no page overflow", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 1440, height: 1000 });
    await openConnectedPage(
      page,
      `/ops/jobs/audit?event=${encodeURIComponent(fixtureState.audit.firstEvent)}`,
    );
    await apply200PercentZoom(page);

    const detail = page.locator("#audit-detail");
    await expect(detail).toHaveAttribute("data-obpt-detail-mode", "drawer");
    const close = detail.locator("[data-obpt-detail-close]");
    await close.focus();
    await expectVisibleFocus(close, "200% zoom Audit close control");
    await expectOneResponsiveTree(page);
    await expectNoHorizontalOverflow(detail);
  });

  test("reduced motion keeps detail and confirmation immediate without hiding content", async ({
    page,
  }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await openConnectedPage(
      page,
      `/ops/jobs/cron?entry=${encodeURIComponent(fixtureState.cron.firstEntry)}`,
    );
    await page.getByRole("button", { name: "Pause cron entry" }).click();
    const dialog = page.locator("#cron-confirmation-dialog");
    await expect(dialog).toBeVisible();

    const motion = await dialog.evaluate((element) => {
      const style = getComputedStyle(element);
      const durations = `${style.transitionDuration},${style.animationDuration}`
        .split(",")
        .map((duration) => Number.parseFloat(duration) || 0);
      return Math.max(...durations);
    });
    expect(motion).toBeLessThanOrEqual(0.01);
    await expect(dialog.getByRole("textbox", { name: "Reason" })).toBeVisible();
    await expect(
      dialog.getByRole("button", { name: "Keep running" }),
    ).toBeEnabled();
  });

  test("confidentiality scans text markup URLs forms hidden nodes and attributes on every page", async ({
    page,
  }) => {
    for (const path of [
      "/ops/jobs",
      `/ops/jobs/cron?entry=${encodeURIComponent(fixtureState.cron.firstEntry)}`,
      `/ops/jobs/limiters?resource=${encodeURIComponent(fixtureState.limiters.blockedResource)}`,
      `/ops/jobs/audit?event=${encodeURIComponent(fixtureState.audit.firstEvent)}`,
    ]) {
      await openConnectedPage(page, path);
      await expectConfidentialityChannelsSafe(page);
    }
  });
});
