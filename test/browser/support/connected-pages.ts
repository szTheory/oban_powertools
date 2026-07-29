import {
  expect,
  type APIRequestContext,
  type Locator,
  type Page,
} from "@playwright/test";
import { pageStories, type ShowcasePageName } from "./manifest";
import {
  authenticatePhase79Actor,
  resetPhase79BrowserFixture,
} from "./phase79-fixtures";
import {
  authenticatePhase80Actor,
  resetPhase80BrowserFixture,
} from "./phase80-fixtures";
import {
  authenticatePhase81Actor,
  resetPhase81BrowserFixture,
} from "./phase81-fixtures";

export type ConnectedPageContext = {
  page: Page;
  request: APIRequestContext;
  project: string;
};

export type ConnectedPageSession = {
  path: string;
  root: Locator;
  safeTraversal: () => Promise<void>;
};

export type ConnectedPageContract = {
  setup: (context: ConnectedPageContext) => Promise<ConnectedPageSession>;
};

type Phase79State = Awaited<ReturnType<typeof resetPhase79BrowserFixture>>;
type Phase80State = Awaited<ReturnType<typeof resetPhase80BrowserFixture>>;
type Phase81State = Awaited<ReturnType<typeof resetPhase81BrowserFixture>>;

const phase79Secret = "PHASE79_BROWSER_FIXTURE_SECRET";
const phase80Secret = "PHASE80_BROWSER_FIXTURE_SECRET";
const phase81Secret = "PHASE81_BROWSER_FIXTURE_SECRET";

function credential(name: string): string {
  const value = process.env[name]?.trim() ?? "";
  if (!value) {
    throw new Error(
      `${name} is required for connected production-page evidence`,
    );
  }
  return value;
}

async function openConnected(
  page: Page,
  path: string,
  rootSelector: string,
): Promise<ConnectedPageSession> {
  await page.goto(path);
  await expect(page.locator("[data-phx-main].phx-connected")).toHaveCount(1);
  expect(new URL(page.url()).pathname).not.toContain("_showcase");

  const root = page.locator(rootSelector);
  await expect(root).toHaveCount(1);
  await expect(root.getByRole("heading", { level: 1 })).toBeVisible();

  return {
    path,
    root,
    safeTraversal: async () => {
      const skipLink = page.getByRole("link", { name: "Skip to main content" });
      await skipLink.focus();
      await expect(skipLink).toBeFocused();
      await skipLink.press("Enter");
      await expect(page.locator("#obpt-main")).toBeFocused();
    },
  };
}

async function phase79(
  context: ConnectedPageContext,
): Promise<{ state: Phase79State; secret: string }> {
  const secret = credential(phase79Secret);
  const state = await resetPhase79BrowserFixture(context.request, {
    secret,
    project: context.project,
  });
  await authenticatePhase79Actor(context.page, { actor: "operator", secret });
  return { state, secret };
}

async function phase80(
  context: ConnectedPageContext,
): Promise<{ state: Phase80State; secret: string }> {
  const secret = credential(phase80Secret);
  const state = await resetPhase80BrowserFixture(context.request, {
    secret,
    project: context.project,
  });
  await authenticatePhase80Actor(context.page, { actor: "ops", secret });
  return { state, secret };
}

async function phase81(
  context: ConnectedPageContext,
): Promise<{ state: Phase81State; secret: string }> {
  const secret = credential(phase81Secret);
  const state = await resetPhase81BrowserFixture(context.request, {
    secret,
    project: context.project,
  });
  await authenticatePhase81Actor(context.page, { actor: "ops", secret });
  return { state, secret };
}

export const connectedPages: Record<ShowcasePageName, ConnectedPageContract> = {
  overview: {
    setup: async (context) => {
      await phase79(context);
      return openConnected(context.page, "/ops/jobs", "#overview-page");
    },
  },
  cron: {
    setup: async (context) => {
      const { state } = await phase79(context);
      return openConnected(
        context.page,
        `/ops/jobs/cron?entry=${encodeURIComponent(state.cron.firstEntry)}`,
        "#cron-page",
      );
    },
  },
  limiters: {
    setup: async (context) => {
      const { state } = await phase79(context);
      return openConnected(
        context.page,
        `/ops/jobs/limiters?resource=${encodeURIComponent(state.limiters.blockedResource)}`,
        "#limiters-page",
      );
    },
  },
  audit: {
    setup: async (context) => {
      const { state } = await phase79(context);
      return openConnected(
        context.page,
        `/ops/jobs/audit?event=${encodeURIComponent(state.audit.firstEvent)}`,
        "#audit-page",
      );
    },
  },
  jobs: {
    setup: async (context) => {
      await phase80(context);
      return openConnected(context.page, "/ops/jobs/jobs", "#jobs-page");
    },
  },
  forensics: {
    setup: async (context) => {
      const { state } = await phase80(context);
      return openConnected(
        context.page,
        `/ops/jobs/forensics?workflow_id=${encodeURIComponent(state.forensics.workflowId)}`,
        "#forensics-page",
      );
    },
  },
  batches: {
    setup: async (context) => {
      await phase81(context);
      return openConnected(context.page, "/ops/jobs/batches", "#batches-page");
    },
  },
  workflows: {
    setup: async (context) => {
      const { state } = await phase81(context);
      return openConnected(
        context.page,
        `/ops/jobs/workflows/${encodeURIComponent(state.handles.workflowId)}?step=${encodeURIComponent(state.handles.workflowStep)}`,
        "#workflows-page",
      );
    },
  },
  lifeline: {
    setup: async (context) => {
      const { state } = await phase81(context);
      return openConnected(
        context.page,
        `/ops/jobs/lifeline?view=active&incident_fingerprint=${encodeURIComponent(state.handles.incidentId)}`,
        "#lifeline-page",
      );
    },
  },
};

export const connectedPageFamilies = [
  ...new Set(pageStories.map((story) => story.page)),
] as ShowcasePageName[];

const connectedKeys = Object.keys(connectedPages);
if (
  connectedKeys.length !== connectedPageFamilies.length ||
  connectedKeys.some((family, index) => family !== connectedPageFamilies[index])
) {
  throw new Error(
    `Connected page families differ from manifest order; expected=${JSON.stringify(
      connectedPageFamilies,
    )}, actual=${JSON.stringify(connectedKeys)}`,
  );
}
