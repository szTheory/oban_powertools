import fs from "node:fs/promises";
import {
  expect,
  test,
  type Locator,
  type Page,
  type TestInfo,
} from "@playwright/test";
import {
  authenticatePhase80Actor,
  controlPhase80Batch,
  readPhase80Evidence,
  resetPhase80BrowserFixture,
  type Phase80FixtureState,
  type Phase80Target,
} from "../support/phase80-fixtures";

test.describe.configure({ mode: "serial" });
test.setTimeout(90_000);

const jobsPath = "/ops/jobs/jobs";
const forensicsPath = "/ops/jobs/forensics";
const serverLogPath = "test-results/showcase-server.log";

let fixtureSecret: string;
let fixtureState: Phase80FixtureState;
let browserChannels: string[];
let pendingResponseBodies: Promise<void>[];

test.beforeEach(async ({ page, request }, testInfo) => {
  fixtureSecret = process.env.PHASE80_BROWSER_FIXTURE_SECRET?.trim() ?? "";
  if (fixtureSecret.length === 0) {
    throw new Error(
      "Plan 80-10 must provide PHASE80_BROWSER_FIXTURE_SECRET; ambient seeds are not a Wave 2 fallback",
    );
  }

  browserChannels = [];
  pendingResponseBodies = [];
  captureBrowserChannels(page);

  fixtureState = await resetPhase80BrowserFixture(request, {
    secret: fixtureSecret,
    project: testInfo.project.name,
  });
  expect(fixtureState.project).toBe(testInfo.project.name);
  expect(fixtureState.counts).toEqual({
    jobs: 2500,
    workflowEvents: 55,
    incidentEvents: 55,
  });
  await authenticatePhase80Actor(page, {
    actor: "ops",
    secret: fixtureSecret,
  });
});

test.afterEach(async ({ request }) => {
  if (fixtureSecret) {
    await controlPhase80Batch(request, {
      command: "release",
      secret: fixtureSecret,
    }).catch(() => undefined);
  }
});

function captureBrowserChannels(page: Page): void {
  page.on("console", (message) => {
    browserChannels.push(`console:${message.type()}:${message.text()}`);
  });
  page.on("pageerror", (error) => {
    browserChannels.push(`pageerror:${error.message}`);
  });
  page.on("request", (request) => {
    browserChannels.push(
      `request:${request.method()}:${request.url()}:${request.postData() ?? ""}`,
    );
  });
  page.on("response", (response) => {
    const contentType = response.headers()["content-type"] ?? "";
    if (!/(html|json|text|javascript)/i.test(contentType)) return;

    const capture = response
      .text()
      .then((body) => {
        browserChannels.push(
          `response:${response.status()}:${response.url()}:${body}`,
        );
      })
      .catch(() => undefined);
    pendingResponseBodies.push(capture);
  });
  page.on("websocket", (socket) => {
    browserChannels.push(`websocket:${socket.url()}`);
    socket.on("framesent", (event) => {
      browserChannels.push(`websocket-sent:${String(event.payload)}`);
    });
    socket.on("framereceived", (event) => {
      browserChannels.push(`websocket-received:${String(event.payload)}`);
    });
  });
}

async function openConnectedPage(page: Page, path: string): Promise<void> {
  await page.goto(path);
  await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);
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

async function expectVisibleFocus(locator: Locator, label: string): Promise<void> {
  await expect(locator, `${label} should be focused`).toBeFocused();
  const evidence = await locator.evaluate((element) => {
    const style = getComputedStyle(element);
    const rect = element.getBoundingClientRect();
    return {
      outline: style.outlineStyle,
      outlineWidth: Number.parseFloat(style.outlineWidth),
      visible:
        rect.width > 0 &&
        rect.height > 0 &&
        rect.right > 0 &&
        rect.bottom > 0 &&
        rect.left < window.innerWidth &&
        rect.top < window.innerHeight,
    };
  });

  expect(evidence.outline).not.toBe("none");
  expect(evidence.outlineWidth).toBeGreaterThan(0);
  expect(evidence.visible).toBe(true);
}

async function expectMinimumTargets(
  root: Locator,
  selectors: string,
): Promise<void> {
  const targets = await root.locator(selectors).evaluateAll((elements) =>
    elements
      .filter((element) => {
        const style = getComputedStyle(element);
        const rect = element.getBoundingClientRect();
        return (
          style.visibility !== "hidden" &&
          style.display !== "none" &&
          rect.width > 0 &&
          rect.height > 0
        );
      })
      .map((element) => {
        const rect = element.getBoundingClientRect();
        return {
          id: element.id,
          label:
            element.getAttribute("aria-label") ??
            element.textContent?.trim() ??
            element.tagName,
          width: rect.width,
          height: rect.height,
        };
      }),
  );

  expect(targets.length).toBeGreaterThan(0);
  for (const target of targets) {
    expect(
      Math.max(target.width, target.height),
      `${target.id || target.label} needs a 44px target in at least one axis`,
    ).toBeGreaterThanOrEqual(44);
  }
}

async function apply200PercentZoom(page: Page): Promise<void> {
  const original = page.viewportSize();
  if (!original) throw new Error("200% zoom requires a configured viewport");

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
  ).toEqual({
    ratio: 2,
    width: Math.floor(original.width / 2),
  });
}

function confidentialitySentinels(): string[] {
  const key = `${fixtureState.project}:${fixtureState.run}`;
  return [
    `phase80-args-sentinel-${key}`,
    `phase80-meta-sentinel-${key}`,
    `phase80-output-sentinel-${key}`,
    `phase80-error-sentinel-${key}`,
    `phase80-reason-sentinel-${key}`,
    `phase80-runbook-sentinel-${key}`,
    fixtureSecret,
  ];
}

async function expectConfidentialityChannelsSafe(
  page: Page,
  fixturePublicEvidence: unknown = fixtureState,
): Promise<void> {
  await Promise.allSettled(pendingResponseBodies);

  const domChannels = await page.locator("html").evaluate((documentElement) => {
    const channels = [
      documentElement.textContent ?? "",
      documentElement.outerHTML,
      document.title,
      document.URL,
      JSON.stringify(performance.getEntriesByType("resource").map((entry) => entry.name)),
    ];

    for (const form of Array.from(document.forms)) {
      channels.push(form.action, form.method, new FormData(form).toString());
    }

    for (const element of Array.from(documentElement.querySelectorAll("*"))) {
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

    return channels;
  });

  let serverLog = "";
  try {
    serverLog = await fs.readFile(serverLogPath, "utf8");
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
  }

  const channels = [
    ...browserChannels,
    ...domChannels,
    JSON.stringify(fixtureState),
    JSON.stringify(fixturePublicEvidence),
    serverLog,
  ];
  const leaks = confidentialitySentinels().filter((sentinel) =>
    channels.some((channel) => channel.includes(sentinel)),
  );
  expect(leaks).toEqual([]);
}

function jobCheckbox(page: Page, id: number): Locator {
  return page.locator(`#job-select-${id}`);
}

function scopedJobsPath(params: {
  state?: string;
  queue?: string;
  worker?: string;
  tags?: string;
  args?: string;
  page?: number;
  job?: number;
} = {}): string {
  const query = new URLSearchParams();
  query.set("state", params.state ?? "available");
  if (params.queue) query.set("queue", params.queue);
  if (params.worker) query.set("worker", params.worker);
  if (params.tags) query.set("tags", params.tags);
  if (params.args) query.set("args", params.args);
  query.set(
    "meta",
    JSON.stringify({
      phase80_key: `${fixtureState.project}:${fixtureState.run}`,
    }),
  );
  if (params.page && params.page > 1) query.set("page", String(params.page));
  if (params.job) query.set("job", String(params.job));
  return `${jobsPath}?${query.toString()}`;
}

async function openRetryableTargetPage(page: Page): Promise<void> {
  for (const pageNumber of [1, 2, 3, 4, 5]) {
    await openConnectedPage(page, scopedJobsPath({
      state: "retryable",
      page: pageNumber,
    }));
    if (
      await jobCheckbox(page, fixtureState.jobs.targets.eligible).count()
    ) {
      return;
    }
  }

  throw new Error("Phase 80 target jobs were not found in the bounded retryable pages");
}

async function selectTargets(
  page: Page,
  targets: Phase80Target[],
): Promise<void> {
  await openRetryableTargetPage(page);
  for (const target of targets) {
    const checkbox = jobCheckbox(page, fixtureState.jobs.targets[target]);
    await expect(checkbox, `${target} target should share the target page`).toHaveCount(
      1,
    );
    await checkbox.check();
  }
  await expect(page.locator("#jobs-selection-summary")).toContainText(
    targets.length === 1
      ? "1 job selected"
      : `${targets.length} jobs selected`,
  );
}

async function waitForBulkDialog(page: Page): Promise<Locator> {
  const dialog = page.locator("#jobs-bulk-confirmation-dialog");
  await expect(dialog).toBeVisible();
  await expect(dialog).toHaveAttribute("data-obpt-confirm-state", /preview|failed/);
  return dialog;
}

async function assertOneProductionTree(page: Page): Promise<void> {
  await expect(
    page.locator("[data-obpt-mobile-copy], [data-obpt-desktop-copy]"),
  ).toHaveCount(0);
  expect(await page.locator("#jobs-page").count()).toBeLessThanOrEqual(1);
  expect(await page.locator("#forensics-page").count()).toBeLessThanOrEqual(1);
  expect(await page.locator("#jobs-results").count()).toBeLessThanOrEqual(1);
  expect(await page.locator("#job-quick-review").count()).toBeLessThanOrEqual(1);
  expect(await page.locator("#forensics-events").count()).toBeLessThanOrEqual(1);
  expect(await page.getByRole("dialog").count()).toBeLessThanOrEqual(1);
}

test.describe("Phase 80 connected production page contracts", () => {
  test("Jobs canonicalizes drafts, history, stale review, and allowlisted detail return context", async ({
    page,
  }) => {
    await openConnectedPage(page, scopedJobsPath({ state: "retryable" }));
    const reviewButtons = page.locator('[id^="job-review-"]');
    await expect(reviewButtons).toHaveCount(20);
    const firstId = Number((await reviewButtons.nth(0).getAttribute("id"))?.split("-").at(-1));
    const secondId = Number((await reviewButtons.nth(1).getAttribute("id"))?.split("-").at(-1));
    expect(firstId).toBeGreaterThan(0);
    expect(secondId).toBeGreaterThan(0);

    const initialHistoryLength = await page.evaluate(() => history.length);
    await reviewButtons.nth(0).click();
    await expect(page.locator("#job-quick-review")).toBeVisible();
    await expect
      .poll(() => new URL(page.url()).searchParams.get("job"))
      .toBe(String(firstId));
    expect(await page.evaluate(() => history.length)).toBe(initialHistoryLength + 1);

    await page.locator(`#job-review-${secondId}`).dispatchEvent("click");
    await expect(page.locator("#job-quick-review")).toContainText(String(secondId));
    await expect
      .poll(() => new URL(page.url()).searchParams.get("job"))
      .toBe(String(secondId));
    expect(await page.evaluate(() => history.length)).toBe(initialHistoryLength + 1);

    await page.getByRole("button", { name: "Close job review" }).click();
    await expect(page.locator("#job-quick-review")).toHaveCount(0);
    await expect.poll(() => new URL(page.url()).searchParams.has("job")).toBe(false);
    expect(await page.evaluate(() => history.length)).toBe(initialHistoryLength + 1);

    await page.goBack();
    await expect(page.locator("#jobs-page")).toBeVisible();
    await expect.poll(() => new URL(page.url()).searchParams.has("job")).toBe(false);

    await openConnectedPage(
      page,
      scopedJobsPath({ state: "retryable", job: 999999999999 }),
    );
    await expect.poll(() => new URL(page.url()).searchParams.has("job")).toBe(false);

    const draftUrl = page.url();
    const queue = page.getByRole("textbox", { name: "Queue" });
    await queue.fill(fixtureState.jobs.boundaryQueue);
    await expect(page.getByText("Changes not applied.")).toBeVisible();
    expect(page.url()).toBe(draftUrl);
    await page.getByRole("button", { name: "Apply filters" }).click();
    await expect
      .poll(() => new URL(page.url()).searchParams.get("queue"))
      .toBe(fixtureState.jobs.boundaryQueue);
    expect(new URL(page.url()).searchParams.has("page")).toBe(false);

    const args = page.getByRole("textbox", { name: "Args contain" });
    await args.fill("{invalid-json");
    await expect(page.getByText("Enter a valid JSON object.")).toBeVisible();
    const invalidDraftUrl = page.url();
    await page.getByRole("button", { name: "Apply filters" }).click();
    expect(page.url()).toBe(invalidDraftUrl);
    await expect(args).toHaveValue("{invalid-json");

    await openConnectedPage(
      page,
      `${jobsPath}?state=retryable&args=%7Bbad&unknown=1&page=0`,
    );
    await expect(page.getByRole("heading", { name: "Some filters were not applied" })).toBeVisible();
    await expect.poll(() => new URL(page.url()).search).toBe("?state=retryable");

    await openConnectedPage(page, scopedJobsPath({
      state: "retryable",
      queue: fixtureState.jobs.boundaryQueue,
      page: 2,
      job: firstId,
    }));
    await expect(page.locator("#job-quick-review")).toBeVisible();
    const detailLink = page.getByRole("link", { name: "Open full job details" });
    const detailHref = await detailLink.getAttribute("href");
    const expectedDetailQuery = new URL(scopedJobsPath({
      state: "retryable",
      queue: fixtureState.jobs.boundaryQueue,
      page: 2,
    }), "http://example.test").search;
    expect(detailHref).toBe(`${jobsPath}/${firstId}${expectedDetailQuery}`);
    await detailLink.click();
    await expect(page.locator("#job-detail-page")).toBeVisible();
    await expect(page.locator("#job-arguments")).toContainText(
      "[hidden by example host display policy]",
    );
    await page.getByRole("link", { name: "Back to Jobs" }).click();
    await expect.poll(() => new URL(page.url()).search).toBe(expectedDetailQuery);
    await expectConfidentialityChannelsSafe(page);
  });

  test("Jobs preserves cross-page selection, exact boundaries, scope choice, and overflow refusal", async ({
    page,
  }) => {
    const boundaryQuery = `state=retryable&queue=${encodeURIComponent(
      fixtureState.jobs.boundaryQueue,
    )}`;
    await openConnectedPage(page, `${jobsPath}?${boundaryQuery}`);
    await expect(page.locator("#jobs-filter-result-summary")).toHaveText(
      "40 retryable jobs",
    );
    await page.locator("#jobs-page-selection").check();
    await expect(page.locator("#jobs-selection-summary")).toContainText(
      "20 jobs selected",
    );
    await page.locator("#jobs-next-page").click();
    await expect.poll(() => new URL(page.url()).searchParams.get("page")).toBe("2");
    await expect(
      page.getByRole("navigation", { name: "Jobs pages" }),
    ).toContainText("Showing 21–40 of 40");
    await expect(page.locator("#jobs-next-page")).toBeDisabled();
    await page.locator('[id^="job-select-"]').first().check();
    await expect(page.locator("#jobs-selection-summary")).toContainText(
      "21 jobs selected",
    );
    await expect(page.locator("#jobs-page-selection")).toHaveAttribute(
      "data-obpt-page-selection",
      "mixed",
    );
    await expect
      .poll(() =>
        page
          .locator("#jobs-page-selection")
          .evaluate((element) => (element as HTMLInputElement).indeterminate),
      )
      .toBe(true);
    await page.locator("#jobs-page-selection").check();
    await expect(page.locator("#jobs-selection-summary")).toContainText(
      "40 jobs selected",
    );
    await expect
      .poll(() =>
        page
          .locator("#jobs-page-selection")
          .evaluate((element) => (element as HTMLInputElement).indeterminate),
      )
      .toBe(false);

    await page.getByRole("button", { name: "Clear selection" }).click();
    await page.locator("#jobs-previous-page").click();
    await page.locator("#jobs-page-selection").check();
    await expect(
      page.getByRole("button", {
        name: "Select all 40 jobs matching these filters",
      }),
    ).toBeVisible();
    await page
      .getByRole("button", {
        name: "Select all 40 jobs matching these filters",
      })
      .click();
    await expect(page.locator("#jobs-selection-summary")).toContainText(
      "All 40 jobs matching the applied filters",
    );

    await openConnectedPage(
      page,
      `${jobsPath}?state=retryable&queue=${encodeURIComponent(
        fixtureState.jobs.overLimitCount === 101
          ? `${fixtureState.jobs.boundaryQueue.replace(/-boundary$/, "")}-over-limit`
          : "",
      )}`,
    );
    await expect(page.locator("#jobs-filter-result-summary")).toHaveText(
      "101 retryable jobs",
    );
    await page.locator("#jobs-page-selection").check();
    await page
      .getByRole("button", {
        name: "Select all 101 jobs matching these filters",
      })
      .click();
    await expect(page.locator("#jobs-bulk-scope-error")).toContainText(
      "limited to 100 jobs",
    );
    await expect(page.locator("#jobs-bulk-confirmation-dialog")).toHaveCount(0);
    await assertOneProductionTree(page);
    await expectConfidentialityChannelsSafe(page);
  });

  test("Jobs freezes mixed bulk scope, validates confirmation, reports progress, and retains partial recovery", async ({
    page,
    request,
  }) => {
    const targets: Phase80Target[] = [
      "eligible",
      "excluded",
      "drifted",
      "expired",
      "consumed",
      "skipped",
      "failed",
    ];
    await selectTargets(page, targets);
    await page.getByRole("button", { name: "Retry jobs" }).click();
    const dialog = await waitForBulkDialog(page);
    await expect(dialog).toContainText(/selected, \d+ ready, \d+ excluded/);
    await expect(dialog).toContainText("New matching jobs will not be included.");
    const readyCount = Number(
      (await dialog.getByRole("heading", { level: 2 }).textContent())?.match(
        /Retry (\d+) ready jobs/,
      )?.[1],
    );
    expect(readyCount).toBeGreaterThan(0);

    await dialog.getByRole("textbox", { name: "Reason" }).fill("short");
    await dialog
      .getByRole("textbox", { name: `Type ${readyCount} to confirm` })
      .fill("0");
    await dialog.getByRole("button", { name: `Retry ${readyCount} jobs` }).click();
    await expect(dialog).toContainText("Enter at least 8 characters.");
    await expect(dialog).toContainText(`Type exactly ${readyCount} to confirm.`);

    for (const target of [
      "drifted",
      "expired",
      "consumed",
      "skipped",
      "failed",
    ] as const) {
      await controlPhase80Batch(request, {
        command: "perturb",
        target,
        secret: fixtureSecret,
      });
    }
    await controlPhase80Batch(request, {
      command: "hold",
      secret: fixtureSecret,
    });

    const announcements: string[] = [];
    await page.locator("#jobs-bulk-announcement").evaluate((element) => {
      const observed: string[] = [];
      (window as unknown as { phase80Announcements?: string[] }).phase80Announcements =
        observed;
      new MutationObserver(() => {
        const text = element.textContent?.trim() ?? "";
        if (text && observed.at(-1) !== text) observed.push(text);
      }).observe(element, { childList: true, subtree: true, characterData: true });
    });

    await dialog
      .getByRole("textbox", { name: "Reason" })
      .fill("Investigate deterministic mixed results");
    await dialog
      .getByRole("textbox", { name: `Type ${readyCount} to confirm` })
      .fill(String(readyCount));
    await dialog.getByRole("button", { name: `Retry ${readyCount} jobs` }).click();
    await expect(dialog).toHaveAttribute("data-obpt-confirm-state", "submitting");
    const progress = dialog.getByRole("progressbar");
    await expect(progress).toHaveCount(1);
    await expect(progress).toHaveAttribute("max", String(readyCount));
    await controlPhase80Batch(request, {
      command: "release",
      secret: fixtureSecret,
    });
    await expect(dialog).toHaveAttribute("data-obpt-confirm-state", "partial");
    await expect(page.locator("#jobs-bulk-fresh-preview")).toBeVisible();
    await expect(page.locator("#jobs-selection-summary")).toContainText(
      "Unresolved jobs retained for a fresh preview",
    );
    await expect(dialog.locator('[id*="-bulk-result-"]')).not.toHaveCount(0);
    announcements.push(
      ...(await page.evaluate(
        () =>
          (window as unknown as { phase80Announcements?: string[] })
            .phase80Announcements ?? [],
      )),
    );
    expect(new Set(announcements).size).toBeLessThanOrEqual(4);
    await expect(page.locator("#jobs-bulk-announcement")).toHaveCount(1);

    const evidence = await readPhase80Evidence(request, { secret: fixtureSecret });
    expect(evidence.counts.auditedEffects).toBeGreaterThan(0);
    expect(evidence.audit.complete).toBe(true);
    await expectConfidentialityChannelsSafe(page, evidence);
  });

  test("Jobs rejects renewed restricted authority and continues accepted work after disconnect", async ({
    page,
    request,
  }) => {
    const authorizationBaseline = await readPhase80Evidence(request, {
      secret: fixtureSecret,
    });
    await selectTargets(page, ["success"]);
    await page.getByRole("button", { name: "Retry jobs" }).click();
    let dialog = await waitForBulkDialog(page);
    await authenticatePhase80Actor(page, {
      actor: "restricted",
      secret: fixtureSecret,
    });
    await page.reload();
    await expect.poll(() => new URL(page.url()).pathname).toBe("/");
    const deniedEvidence = await readPhase80Evidence(request, {
      secret: fixtureSecret,
    });
    expect(deniedEvidence.counts.auditedEffects).toBe(
      authorizationBaseline.counts.auditedEffects,
    );
    expect(deniedEvidence.states.success).toBe(
      authorizationBaseline.states.success,
    );

    fixtureState = await resetPhase80BrowserFixture(request, {
      secret: fixtureSecret,
      project: fixtureState.project,
      run: fixtureState.run,
    });
    await authenticatePhase80Actor(page, {
      actor: "ops",
      secret: fixtureSecret,
    });
    const disconnectBaseline = await readPhase80Evidence(request, {
      secret: fixtureSecret,
    });
    await selectTargets(page, ["success"]);
    await controlPhase80Batch(request, {
      command: "hold",
      secret: fixtureSecret,
    });
    await page.getByRole("button", { name: "Retry jobs" }).click();
    dialog = await waitForBulkDialog(page);
    await dialog
      .getByRole("textbox", { name: "Reason" })
      .fill("Continue accepted work after disconnect");
    await dialog
      .getByRole("textbox", { name: "Type 1 to confirm" })
      .fill("1");
    await dialog.getByRole("button", { name: "Retry 1 jobs" }).click();
    await expect(dialog).toHaveAttribute("data-obpt-confirm-state", "submitting");
    await page.close();

    await controlPhase80Batch(request, {
      command: "release",
      secret: fixtureSecret,
    });
    await expect
      .poll(
        async () => {
          const evidence = await readPhase80Evidence(request, {
            secret: fixtureSecret,
          });
          return {
            audited: evidence.counts.auditedEffects,
            complete: evidence.audit.complete,
            state: evidence.states.success,
          };
        },
        { timeout: 15_000, intervals: [100, 250, 500, 1_000] },
      )
      .toEqual({
        audited: disconnectBaseline.counts.auditedEffects + 1,
        complete: true,
        state: "available",
      });
  });

  test("Jobs and Forensics make missing and page-unauthorized outcomes indistinguishable", async ({
    page,
  }) => {
    await openConnectedPage(page, `${jobsPath}/999999999999`);
    const missingJobCopy = await page.locator("#job-unavailable").innerText();
    expect(missingJobCopy).toContain(
      "may not exist, may no longer be available, or you may not have access",
    );

    await openConnectedPage(
      page,
      `${forensicsPath}?workflow_id=00000000-0000-0000-0000-000000000000`,
    );
    const missingForensicsCopy = await page
      .locator("#forensics-result-state")
      .innerText();
    expect(missingForensicsCopy).toContain(
      "may not exist, may no longer be retained, or you may not have access",
    );

    await authenticatePhase80Actor(page, {
      actor: "restricted",
      secret: fixtureSecret,
    });
    const deniedDestinations: string[] = [];
    for (const path of [
      `${jobsPath}/${fixtureState.jobs.targets.eligible}`,
      `${forensicsPath}?workflow_id=${fixtureState.forensics.workflowId}`,
    ]) {
      await page.goto(path);
      await expect.poll(() => new URL(page.url()).pathname).toBe("/");
      deniedDestinations.push(new URL(page.url()).pathname);
    }
    expect(deniedDestinations).toEqual(["/", "/"]);
  });

  test("Forensics canonicalizes the six-key grammar and renders all four bounded evidence sources", async ({
    page,
  }) => {
    await openConnectedPage(page, forensicsPath);
    const evidenceType = page.getByRole("combobox", { name: "Evidence type" });
    await evidenceType.selectOption("workflow");
    await expect(page.getByRole("textbox", { name: "Workflow ID" })).toBeVisible();
    await expect(page.getByRole("textbox", { name: "Step" })).toBeVisible();
    await evidenceType.selectOption("incident");
    await expect(
      page.getByRole("textbox", { name: "Incident fingerprint" }),
    ).toBeVisible();
    await expect(page.getByRole("combobox", { name: "Incident view" })).toBeVisible();
    await evidenceType.selectOption("cron");
    await expect(page.getByRole("textbox", { name: "Cron entry ID" })).toBeVisible();
    await evidenceType.selectOption("limiter");
    await expect(page.getByRole("textbox", { name: "Limiter ID" })).toBeVisible();

    const sixKey = new URLSearchParams([
      ["resource_type", "workflow_step"],
      ["resource_id", "phase80-step-resource"],
      ["workflow_id", fixtureState.forensics.workflowId],
      ["step", fixtureState.forensics.workflowStep],
      ["incident_fingerprint", fixtureState.forensics.incidentFingerprint],
      ["view", "active"],
    ]);
    await openConnectedPage(page, `${forensicsPath}?${sixKey.toString()}`);
    await expect(page.locator("#forensics-result-state")).toHaveAttribute(
      "data-obpt-state",
      "ready",
    );
    expect(new URL(page.url()).searchParams.toString()).toBe(sixKey.toString());

    for (const query of [
      new URLSearchParams([
        ["workflow_id", fixtureState.forensics.workflowId],
        ["step", fixtureState.forensics.workflowStep],
      ]),
      new URLSearchParams([
        ["incident_fingerprint", fixtureState.forensics.incidentFingerprint],
        ["view", "active"],
      ]),
      new URLSearchParams([
        ["resource_type", "cron_entry"],
        ["resource_id", fixtureState.forensics.cronEntry],
      ]),
      new URLSearchParams([
        ["resource_type", "limiter"],
        ["resource_id", fixtureState.forensics.limiterResource],
      ]),
    ]) {
      await openConnectedPage(page, `${forensicsPath}?${query.toString()}`);
      await expect(page.locator("#forensics-result-state")).toHaveAttribute(
        "data-obpt-state",
        "ready",
      );
      await expect(page.locator("#forensics-investigation-summary")).toBeVisible();
      await expect(page.locator("#forensics-event-log")).toBeVisible();
      await expect(page.locator("#forensics-evidence-coverage")).toBeVisible();
      await assertOneProductionTree(page);
    }

    await openConnectedPage(
      page,
      `${forensicsPath}?workflow_id=${encodeURIComponent(
        fixtureState.forensics.workflowId,
      )}&incident_fingerprint=${encodeURIComponent(
        fixtureState.forensics.incidentFingerprint,
      )}`,
    );
    await expect.poll(() => new URL(page.url()).search).toBe("");
    await expect(page.locator("#forensics-scope-errors")).toBeFocused();
    await expect(page.locator("#forensics-result-state")).toHaveAttribute(
      "data-obpt-state",
      "empty",
    );

    await openConnectedPage(
      page,
      `${forensicsPath}?step=${encodeURIComponent(
        fixtureState.forensics.workflowStep,
      )}`,
    );
    await expect.poll(() => new URL(page.url()).search).toBe("");
    await expect(page.locator("#forensics-scope-errors")).toContainText(
      "Conflicting scope values were not applied",
    );
    await expectConfidentialityChannelsSafe(page);
  });

  test("Forensics proves newest-first 50-of-55 evidence and omits unsafe duplicate links", async ({
    page,
  }) => {
    await openConnectedPage(
      page,
      `${forensicsPath}?workflow_id=${encodeURIComponent(
        fixtureState.forensics.workflowId,
      )}&step=${encodeURIComponent(fixtureState.forensics.workflowStep)}`,
    );
    const times = await page
      .locator("#forensics-events time")
      .evaluateAll((elements) =>
        elements.map((element) => element.getAttribute("datetime") ?? ""),
      );
    expect(times).toHaveLength(50);
    expect(times).toEqual(
      [...times].sort((left, right) => right.localeCompare(left)),
    );
    await expect(page.locator("#forensics-evidence-coverage")).toContainText(
      "Showing the newest 52 events; more evidence exists.",
    );
    await expect(page.locator("#forensics-evidence-coverage")).toContainText(
      "Newest 50 retained events; more evidence exists.",
    );
    await expect(page.locator("#forensics-evidence-coverage")).toContainText(
      "Bounded window",
    );

    const destinations = await page
      .locator(
        "#forensics-next-steps a[href], #forensics-events a[href], #forensics-evidence-coverage a[href]",
      )
      .evaluateAll((links) =>
        links.map((link) => ({
          href: link.getAttribute("href"),
          label: link.textContent?.trim(),
        })),
      );
    expect(destinations.length).toBeGreaterThan(0);
    expect(
      destinations.every(({ href }) =>
        /^\/ops\/jobs\/(workflows\/|lifeline|cron|limiters|audit)/.test(
          href ?? "",
        ),
      ),
    ).toBe(true);
    const guidanceDestinations = await page
      .locator("#forensics-next-steps a[href]")
      .evaluateAll((links) =>
        links.map(
          (link) =>
            `${link.textContent?.trim()}:${link.getAttribute("href")}`,
        ),
      );
    expect(new Set(guidanceDestinations).size).toBe(
      guidanceDestinations.length,
    );

    await expectConfidentialityChannelsSafe(page);
  });

  test("Jobs and Forensics reflow as one reduced-motion keyboard tree at 320px and 200% zoom", async ({
    page,
  }, testInfo: TestInfo) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await openConnectedPage(page, scopedJobsPath({ state: "retryable" }));
    const jobsRoot = page.locator("#jobs-page");
    await expect(jobsRoot).toHaveCount(1);
    await assertOneProductionTree(page);
    await expectNoHorizontalOverflow(jobsRoot);
    await expectMinimumTargets(
      jobsRoot,
      "#jobs-next-page, #jobs-previous-page, [data-obpt-filter-toggle]",
    );
    expect(
      await page.evaluate(() => matchMedia("(prefers-reduced-motion: reduce)").matches),
    ).toBe(true);
    const motionDuration = await jobsRoot.evaluate((element) =>
      Array.from(element.querySelectorAll<HTMLElement>("button, a"))
        .map((candidate) => {
          const style = getComputedStyle(candidate);
          return `${style.transitionDuration},${style.animationDuration}`
            .split(",")
            .map((duration) => Number.parseFloat(duration) || 0);
        })
        .flat()
        .reduce((maximum, duration) => Math.max(maximum, duration), 0),
    );
    expect(motionDuration).toBeLessThanOrEqual(0.01);
    await jobsRoot.getByRole("button", { name: /Review job/ }).first().focus();
    await expectVisibleFocus(
      jobsRoot.getByRole("button", { name: /Review job/ }).first(),
      "Jobs review action",
    );

    await jobsRoot.getByRole("button", { name: /Review job/ }).first().click();
    const detail = page.locator("#job-quick-review");
    const narrow = testInfo.project.name !== "chromium-wide";
    await expect(detail).toHaveAttribute(
      "data-obpt-detail-mode",
      narrow ? "drawer" : "inline",
    );
    if (narrow) {
      await expect(detail).toHaveJSProperty("open", true);
      const close = detail.getByRole("button", { name: "Close job review" });
      await close.focus();
      await page.keyboard.press("Tab");
      expect(
        await detail.evaluate((element) => element.contains(document.activeElement)),
      ).toBe(true);
      await page.keyboard.press("Escape");
      await expect(detail).toHaveCount(0);
      await expect(
        jobsRoot.getByRole("button", { name: /Review job/ }).first(),
      ).toBeFocused();
    } else {
      await expect(page.locator("body")).not.toHaveAttribute("inert", "");
      await detail.getByRole("button", { name: "Close job review" }).click();
    }

    await openConnectedPage(page, forensicsPath);
    const forensicsRoot = page.locator("#forensics-page");
    await expect(forensicsRoot).toHaveCount(1);
    await assertOneProductionTree(page);
    await expectNoHorizontalOverflow(forensicsRoot);
    await expectMinimumTargets(
      forensicsRoot,
      '[data-obpt-filter-toggle], button[type="submit"]',
    );
    const chooser = page.getByRole("combobox", { name: "Evidence type" });
    await chooser.focus();
    await expectVisibleFocus(chooser, "Forensics evidence chooser");

    await apply200PercentZoom(page);
    await openConnectedPage(
      page,
      `${forensicsPath}?workflow_id=${encodeURIComponent(
        fixtureState.forensics.workflowId,
      )}`,
    );
    await expect(page.locator("#forensics-page")).toHaveCount(1);
    await assertOneProductionTree(page);
    await expectNoHorizontalOverflow(page.locator("#forensics-page"));
    await expect(page.locator('[aria-live="polite"]')).toHaveCount(1);
    await expectConfidentialityChannelsSafe(page);
  });
});
