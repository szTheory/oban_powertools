import { test } from "@playwright/test";
import {
  connectedPageFamilies,
  connectedPages,
} from "../support/connected-pages";

test.describe.configure({ mode: "serial" });
test.setTimeout(120_000);

for (const family of connectedPageFamilies) {
  test(`${family} connected production quality`, async ({
    page,
    request,
  }, testInfo) => {
    const session = await connectedPages[family].setup({
      page,
      request,
      project: testInfo.project.name,
    });

    await session.safeTraversal();
  });
}
