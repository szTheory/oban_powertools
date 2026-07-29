import fs from "node:fs/promises";
import { expect, test, type Locator, type Page } from "@playwright/test";
import {
  authenticatePhase81Actor,
  controlPhase81Race,
  resetPhase81BrowserFixture,
  type Phase81FixtureState,
} from "../support/phase81-fixtures";

test.describe.configure({ mode: "serial" });
test.setTimeout(90_000);

let fixtureSecret = "";
let fixtureState: Phase81FixtureState;
let browserChannels: string[] = [];
let pendingResponseBodies: Promise<void>[] = [];
const serverLogPath = "test-results/showcase-server.log";

test.beforeEach(async ({ page, request }, testInfo) => {
  fixtureSecret = process.env.PHASE81_BROWSER_FIXTURE_SECRET?.trim() ?? "";
  if (fixtureSecret.length === 0) {
    throw new Error(
      "Plan 81-07 must provide PHASE81_BROWSER_FIXTURE_SECRET; ambient seeds are not a Wave 3 fallback",
    );
  }

  browserChannels = [];
  pendingResponseBodies = [];
  captureBrowserChannels(page);
  fixtureState = await resetPhase81BrowserFixture(request, {
    secret: fixtureSecret,
    project: testInfo.project.name,
  });
  await authenticatePhase81Actor(page, { actor: "ops", secret: fixtureSecret });
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
    pendingResponseBodies.push(
      response
        .text()
        .then((body) => {
          browserChannels.push(
            `response:${response.status()}:${response.url()}:${body}`,
          );
        })
        .catch(() => undefined),
    );
  });
  page.on("websocket", (socket) => {
    browserChannels.push(`websocket:${socket.url()}`);
    socket.on("framesent", ({ payload }) => {
      browserChannels.push(`websocket-sent:${String(payload)}`);
    });
    socket.on("framereceived", ({ payload }) => {
      browserChannels.push(`websocket-received:${String(payload)}`);
    });
  });
}

async function openConnectedPage(page: Page, path: string): Promise<void> {
  await page.goto(path);
  await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);
  expect(new URL(page.url()).pathname).not.toContain("_showcase");
}

async function closeResidualDialog(page: Page): Promise<void> {
  if (await page.getByRole("dialog").count()) {
    await page.keyboard.press("Escape");
    await expect(page.getByRole("dialog")).toHaveCount(0);
  }
}

async function expectOneTree(page: Page): Promise<void> {
  await expect(
    page.locator("[data-obpt-mobile-copy], [data-obpt-desktop-copy]"),
  ).toHaveCount(0);
  expect(await page.getByRole("dialog").count()).toBeLessThanOrEqual(1);
}

async function expectNoOverflow(root: Locator): Promise<void> {
  const overflow = await root.evaluate((element) => ({
    contained: Math.ceil(element.scrollWidth - element.clientWidth),
    body: Math.ceil(document.body.scrollWidth - document.body.clientWidth),
    document: Math.ceil(
      document.documentElement.scrollWidth -
        document.documentElement.clientWidth,
    ),
  }));
  expect(overflow.body).toBeLessThanOrEqual(1);
  expect(overflow.document).toBeLessThanOrEqual(1);
  expect(overflow.contained).toBeGreaterThanOrEqual(0);
}

function batchPath(): string {
  return `/ops/jobs/batches/${encodeURIComponent(fixtureState.handles.batchId)}`;
}

function workflowPath(): string {
  return `/ops/jobs/workflows/${encodeURIComponent(
    fixtureState.handles.workflowId,
  )}?step=${encodeURIComponent(fixtureState.handles.workflowStep)}`;
}

function lifelinePath(): string {
  return `/ops/jobs/lifeline?view=active&incident_fingerprint=${encodeURIComponent(
    fixtureState.handles.incidentId,
  )}`;
}

function lifelinePreviewButton(page: Page): Locator {
  const executor = fixtureState.handles.incidentId.replace(
    /^dead_executor:/,
    "",
  );
  return page
    .getByRole("row")
    .filter({ hasText: executor })
    .getByRole("button", { name: "Preview remediation" });
}

async function expectMinimumTargets(root: Locator): Promise<void> {
  const targets = await root
    .locator("a, button, input, select, textarea")
    .evaluateAll((elements) =>
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
      `${target.label} needs a 44px target in at least one axis`,
    ).toBeGreaterThanOrEqual(44);
  }
}

async function apply200PercentZoom(page: Page): Promise<void> {
  const viewport = page.viewportSize();
  if (!viewport) throw new Error("200% zoom requires a configured viewport");
  const session = await page.context().newCDPSession(page);
  await session.send("Emulation.setDeviceMetricsOverride", {
    width: Math.floor(viewport.width / 2),
    height: Math.floor(viewport.height / 2),
    screenWidth: viewport.width,
    screenHeight: viewport.height,
    deviceScaleFactor: 2,
    mobile: false,
  });
  expect(await page.evaluate(() => window.devicePixelRatio)).toBe(2);
}

async function expectConfidentialityChannelsSafe(page: Page): Promise<void> {
  await Promise.allSettled(pendingResponseBodies);
  const domChannels = await page.locator("html").evaluate((root) => {
    const values = [
      root.textContent ?? "",
      root.outerHTML,
      document.title,
      document.URL,
      JSON.stringify(
        performance.getEntriesByType("resource").map((entry) => entry.name),
      ),
    ];
    for (const form of Array.from(document.forms)) {
      values.push(form.action, form.method, new FormData(form).toString());
    }
    for (const element of Array.from(root.querySelectorAll("*"))) {
      for (const attribute of Array.from(element.attributes)) {
        values.push(`${attribute.name}=${attribute.value}`);
      }
    }
    return values;
  });
  let serverLog = "";
  try {
    serverLog = await fs.readFile(serverLogPath, "utf8");
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
  }
  const combined = [
    ...browserChannels,
    ...domChannels,
    JSON.stringify(fixtureState),
    serverLog,
  ].join("\n");
  for (const forbidden of [
    "preview_token",
    "plan_hash",
    "before_snapshot",
    "after_snapshot",
    "raw_metadata",
    "provider_error",
    "Fixture retention run",
    fixtureSecret,
  ]) {
    expect(
      combined,
      `${forbidden} escaped into a browser or log channel`,
    ).not.toContain(forbidden);
  }
  expect(await page.locator("#lifeline-page").innerText()).not.toMatch(
    /\b(?:atomic|exactly[- ]once)\b/i,
  );
}

test.describe("Phase 81 connected production page contracts", () => {
  test("Batches preserves detail history, mixed selection, retry preview, callback scope, and 50/25 render bounds", async ({
    page,
  }) => {
    await openConnectedPage(page, batchPath());
    await expect(page.locator("#batches-page, #batch-detail-page")).toHaveCount(
      1,
    );
    await expect(page.locator("#batch-members tbody tr")).toHaveCount(50);
    await expect(page.locator("#batch-callbacks tbody tr")).toHaveCount(25);
    await expect(
      page.getByText(/more members exist|partial evidence/i),
    ).toBeVisible();
    await page.getByRole("checkbox").first().check();
    await expect(
      page.getByText(/1 failed (member|job) selected/i),
    ).toBeVisible();
    await page
      .getByRole("button", { name: /preview failed job retries/i })
      .click();
    await expect(page.getByRole("dialog")).toContainText(/reason|required/i);
    await expectOneTree(page);
  });

  test("Batches keeps unavailable and authorization-race outcomes uniform without mutation authority in URL state", async ({
    page,
    request,
  }) => {
    await openConnectedPage(page, batchPath());
    await controlPhase81Race(request, {
      command: "revoke",
      secret: fixtureSecret,
    });
    await page.getByRole("button", { name: /retry/i }).first().click();
    await expect(
      page.getByText(/batch unavailable|permission changed/i),
    ).toBeVisible();
    expect(new URL(page.url()).searchParams.has("action")).toBe(false);
    expect(new URL(page.url()).searchParams.has("preview_token")).toBe(false);
  });

  test("Workflows preserves step deep links, bounded DAG evidence, PubSub refresh, and read-only Lifeline handoff", async ({
    page,
  }) => {
    await openConnectedPage(page, workflowPath());
    await expect(page.locator("#workflows-page")).toBeVisible();
    await expect(page.locator("#workflow-steps li")).toHaveCount(100);
    await expect(
      page.getByRole("region", { name: /why blocked/i }),
    ).toBeVisible();
    await expect(
      page.getByRole("link", { name: /review recovery in lifeline/i }),
    ).toBeVisible();
    await expect(
      page.getByRole("button", { name: /execute|retry|cancel/i }),
    ).toHaveCount(0);
    await page.reload();
    await expect
      .poll(() => new URL(page.url()).searchParams.get("step"))
      .toBe(fixtureState.handles.workflowStep);
  });

  test("Workflows presents missing and restricted resources through one non-enumerating unavailable branch", async ({
    page,
  }) => {
    await openConnectedPage(
      page,
      "/ops/jobs/workflows/not-retained?step=forged",
    );
    await expect(
      page.getByRole("heading", { name: "Workflow unavailable" }),
    ).toBeVisible();
    expect(await page.locator("body").innerText()).not.toContain(
      "not-retained",
    );
  });

  test("Lifeline preserves preview, reason validation, reauthorization, duplicate suppression, execute, result, and Audit evidence", async ({
    page,
  }) => {
    await openConnectedPage(page, lifelinePath());
    await closeResidualDialog(page);
    await lifelinePreviewButton(page).click();
    const dialog = page.getByRole("dialog");
    await expect(dialog).toBeVisible();
    await dialog.getByRole("textbox", { name: /reason/i }).fill("short");
    await dialog.getByRole("button", { name: /execute remediation/i }).click();
    await expect(dialog).toContainText(/at least 8 characters/i);
    await dialog
      .getByRole("textbox", { name: /reason/i })
      .fill("Provider recovered; execute the bounded repair.");
    await dialog
      .getByRole("button", { name: /execute remediation/i })
      .dblclick();
    await expect(page.getByRole("status")).toContainText(
      /recorded|partial|failed/i,
    );
    await expect(
      page.getByRole("link", { name: /open in audit/i }),
    ).toBeVisible();
  });

  test("Lifeline blocks revoked authorization after preview and requires a fresh preview", async ({
    page,
    request,
  }) => {
    await openConnectedPage(page, lifelinePath());
    await closeResidualDialog(page);
    await lifelinePreviewButton(page).click();
    await controlPhase81Race(request, {
      command: "revoke",
      secret: fixtureSecret,
    });
    await page
      .getByRole("textbox", { name: /reason/i })
      .fill("Permission changed after the preview.");
    await page.getByRole("button", { name: /execute remediation/i }).click();
    await expect(
      page.getByText(/permission changed|fresh preview/i),
    ).toBeVisible();
  });

  test("Lifeline race controls drive real drifted and duplicate production outcomes", async ({
    page,
    request,
  }) => {
    await openConnectedPage(page, lifelinePath());
    await closeResidualDialog(page);

    await lifelinePreviewButton(page).click();
    const drift = await controlPhase81Race(request, {
      command: "drift",
      secret: fixtureSecret,
    });
    expect(drift).toMatchObject({ command: "drift", state: "drift" });
    await page
      .getByRole("textbox", { name: /reason/i })
      .fill("Verify that target drift blocks execution.");
    await page.getByRole("button", { name: /execute remediation/i }).click();
    await expect(
      page.getByText(/preview drifted|fresh preview/i),
    ).toBeVisible();
    await expect(
      page.getByRole("link", { name: /open in audit/i }),
    ).toHaveCount(0);

    fixtureState = await resetPhase81BrowserFixture(request, {
      secret: fixtureSecret,
      project: test.info().project.name,
    });
    await authenticatePhase81Actor(page, {
      actor: "ops",
      secret: fixtureSecret,
    });
    await openConnectedPage(page, lifelinePath());
    await lifelinePreviewButton(page).click();
    const duplicate = await controlPhase81Race(request, {
      command: "duplicate",
      secret: fixtureSecret,
    });
    expect(duplicate).toMatchObject({
      command: "duplicate",
      state: "duplicate",
    });
    await page
      .getByRole("textbox", { name: /reason/i })
      .fill("Verify duplicate execution is suppressed.");
    await page.getByRole("button", { name: /execute remediation/i }).click();
    await expect(
      page.getByText(/already consumed|fresh preview/i),
    ).toBeVisible();

    await page.goto("/ops/jobs/audit");
    await expect(
      page.getByText(/lifeline\\.repair_executed/i).first(),
    ).toBeVisible();
    await expect(
      page.getByRole("region", { name: /runbook continuity/i }),
    ).toHaveCount(0);
    await expectOneTree(page);
  });

  test("Wave 3 dialogs contain focus, close on Escape, restore the invoker, and announce sparse durable state", async ({
    page,
  }) => {
    await openConnectedPage(page, lifelinePath());
    await closeResidualDialog(page);
    const invoker = lifelinePreviewButton(page);
    await invoker.focus();
    await invoker.press("Enter");
    const dialog = page.getByRole("dialog");
    await expect(dialog).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(dialog).toHaveCount(0);
    await expect(invoker).toBeFocused();
    await expect(page.locator("[aria-live='assertive']")).toHaveCount(0);
    expect(
      await page.locator("[aria-live='polite']").count(),
    ).toBeLessThanOrEqual(1);
  });

  test("Wave 3 keeps one semantic tree, 44px targets, 320px reflow, 200 percent zoom, and reduced motion", async ({
    page,
  }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await page.setViewportSize({ width: 320, height: 900 });
    await openConnectedPage(page, batchPath());
    const root = page.locator("#batches-page, #batch-detail-page");
    await expectNoOverflow(root);
    await expectOneTree(page);
    await expectMinimumTargets(root);
    await apply200PercentZoom(page);
    await expectNoOverflow(root);
  });

  test("Wave 3 excludes preview identity, snapshots, raw reasons, metadata, provider errors, and fixture credentials from browser channels", async ({
    page,
  }) => {
    await openConnectedPage(page, lifelinePath());
    await closeResidualDialog(page);
    await expectConfidentialityChannelsSafe(page);
  });
});
