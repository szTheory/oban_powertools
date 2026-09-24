import { defineConfig } from '@playwright/test';

const baseUse = {
  browserName: 'chromium' as const,
  colorScheme: 'light' as const,
  deviceScaleFactor: 1,
  locale: 'en-US',
  reducedMotion: 'reduce' as const,
  timezoneId: 'UTC',
  trace: 'retain-on-failure' as const,
  screenshot: 'only-on-failure' as const,
  baseURL: process.env.PLAYWRIGHT_TEST_BASE_URL || 'http://127.0.0.1:4000'
};

export default defineConfig({
  testDir: './test/browser/specs',
  outputDir: './test-results',
  fullyParallel: false,
  workers: process.env.CI ? 1 : undefined,
  snapshotPathTemplate: 'test/browser/__aria_snapshots__{/projectName}/{arg}{ext}',
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['junit', { outputFile: 'test-results/playwright-junit.xml' }]
  ],
  expect: {
    timeout: 15_000,
    toHaveScreenshot: {
      animations: 'disabled',
      caret: 'hide',
      pathTemplate: 'test/browser/__screenshots__{/projectName}/{arg}{ext}',
      scale: 'css',
      stylePath: './test/browser/styles/screenshot.css'
    }
  },
  use: baseUse,
  projects: [
    {
      name: 'chromium-320',
      use: {
        ...baseUse,
        viewport: { width: 320, height: 900 }
      }
    },
    {
      name: 'chromium-tablet',
      use: {
        ...baseUse,
        viewport: { width: 768, height: 1000 }
      }
    },
    {
      name: 'chromium-wide',
      use: {
        ...baseUse,
        viewport: { width: 1440, height: 1000 }
      }
    }
  ]
});
