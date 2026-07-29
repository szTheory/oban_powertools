import { devices, defineConfig } from "@playwright/test";
import { screenReaderConfig } from "@guidepup/playwright";

export default defineConfig({
  ...screenReaderConfig,
  testDir: "./test/browser/voiceover",
  outputDir: "./test-results/voiceover",
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 5 * 60 * 1000,
  reporter: [
    ["list"],
    [
      "html",
      {
        outputFolder: "playwright-report/voiceover",
        open: "never",
      },
    ],
    [
      "junit",
      {
        outputFile: "test-results/voiceover-junit.xml",
      },
    ],
  ],
  projects: [
    {
      name: "voiceover-webkit",
      use: {
        ...devices["Desktop Safari"],
        baseURL:
          process.env.PLAYWRIGHT_TEST_BASE_URL || "http://127.0.0.1:4000",
        headless: false,
        locale: "en-US",
        reducedMotion: "reduce",
        screenshot: "only-on-failure",
        trace: "retain-on-failure",
        video: "retain-on-failure",
        viewport: { width: 1440, height: 1000 },
      },
    },
  ],
});
